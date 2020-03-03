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
var <- c("id", "occurrenceID", "eventDate",
         "decimalLatitude", "decimalLongitude", "geodeticDatum",
         "minimumDepthInMeters", "maximumDepthInMeters", "scientificName",
         "scientificNameID", "individualCount")
data <- data[var]

# Save as csv
write.csv(data,
          file.path("data","derived_data", "data.csv")
)
