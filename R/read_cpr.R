# Download the CPR data
downloader::download("https://www.dassh.ac.uk/ipt/archive.do?r=cpr_public&v=1.2", dest = file.path("data","raw_data", "dataset.zip"), mode = "wb")
unzip(file.path("data","raw_data", "dataset.zip"),
      exdir = file.path("data","raw_data")
)

# Read the files
events <- read.table(file.path("data","raw_data", "event.txt"), header = TRUE, sep = "\t", fileEncoding = "UTF-8")
occurrences <- read.table(file.path("data","raw_data", "occurrence.txt"), header = TRUE, sep = "\t", fileEncoding = "UTF-8")

# Join data
data <- merge(events, occurrences, by = "id")

# Select specific columns
var <- c("id", "eventDate",
         "decimalLatitude", "decimalLongitude", "geodeticDatum",
         "minimumDepthInMeters", "maximumDepthInMeters", "scientificName",
         "scientificNameID", "individualCount", "sampleSizeValue")
data <- data[var]

# Add aphiaID as another variable
data$aphiaID <- as.integer(gsub("urn:lsid:marinespecies.org:taxname:", "", data$scientificNameID))

# Get a dataset with only the present species
species <- unique(
  data.frame(
    scientificName = data$scientificName, 
    aphiaID = as.integer(gsub("urn:lsid:marinespecies.org:taxname:", "", data$scientificNameID))
  )
)

# Set the target species - Include all species of the genuses Acartia and Oithona
target_species <- data.frame(
  scientificName = c("Temora longicornis", 
                     "Calanus finmarchicus", 
                     "Calanus helgolandicus", 
                     "Metridia lucens"), 
  aphiaID = as.integer(c(104878, 
                         104464, 
                         104466, 
                         104633))
)
target_species <- rbind(
  target_species, 
  species[grep("Acartia", species$scientificName, ignore.case = TRUE), ],
  species[grep("Oithona", species$scientificName, ignore.case = TRUE), ]
)

# Subset dataset to target species
data <- subset(data, data$aphiaID %in% target_species$aphiaID)
rm(list = c("species", "target_species"))

# Convert factors to character vectors
data[] <- lapply(data, as.character)

# Low Acartia and Oithona species taxonomy to genus
data$scientificName[grep("Acartia", data$scientificName, ignore.case = TRUE)] <- "Acartia"
data$scientificNameID[grep("Acartia", data$scientificName, ignore.case = TRUE)] <- "urn:lsid:marinespecies.org:taxname:104108"
data$aphiaID[grep("Acartia", data$scientificName, ignore.case = TRUE)] <- 104108

data$scientificName[grep("Oithona", data$scientificName, ignore.case = TRUE)] <- "Oithona"
data$scientificNameID[grep("Oithona", data$scientificName, ignore.case = TRUE)] <- "urn:lsid:marinespecies.org:taxname:106485"
data$aphiaID[grep("Oithona", data$scientificName, ignore.case = TRUE)] <- 106485

# Aggregate counts using dplyr v 0.8.3
library(dplyr)
packageVersion("dplyr")

data <- data %>% mutate(individualCount = as.integer(individualCount)
           ) %>% group_by(id, aphiaID
           ) %>% mutate(individualCount = sum(individualCount)
           ) %>% distinct(
           ) %>% ungroup()

# Calculate number of individuals per cubic meter - new abundance column 
data$abundance <- as.integer(data$individualCount) / as.integer(data$sampleSizeValue)
data$abundanceUnit <- "ind/m3"
data$abundanceMeasurementTypeID <- "http://vocab.nerc.ac.uk/collection/P01/current/SDBIOL01/"
data$abundanceMeasurementUnitID <- "http://vocab.nerc.ac.uk/collection/P06/current/UPMM/"

# Calculate the log abundance
data$logAbundance <- log(data$abundance + 1)

# Save as csv
write.csv(data,
          file.path("data","derived_data", "data.csv"),
          fileEncoding = 'UTF-8',
          row.names = FALSE,
          na = ""
)
