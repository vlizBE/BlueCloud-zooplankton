library(readr)
library(dplyr)

##---- RUN ONCE ----
# Request CPR data of "Temora longicornis", "Calanus finmarchicus", "Calanus helgolandicus", "Metridia lucens", "Acartia sp." and "Oithona sp."
# aphiaid: 104878, 104464, 104466, 104633, 106485, 104108
wfs_request <- "http://geo.vliz.be/geoserver/wfs/ows?service=WFS&version=1.1.0&request=GetFeature&typeName=Dataportal%3Aeurobis-obisenv&resultType=results&viewParams=where%3Adatasetid+IN+%28216%29%3Bcontext%3A0100%3Baphiaid%3A104108%5C%2C104878%5C%2C104464%5C%2C104466%5C%2C104633%5C%2C106485&propertyName=datasetid%2Cdatecollected%2Cdecimallatitude%2Cdecimallongitude%2Ccoordinateuncertaintyinmeters%2Cscientificname%2Caphiaid%2Cscientificnameaccepted%2Cmodified%2Cinstitutioncode%2Ccollectioncode%2Cyearcollected%2Cstartyearcollected%2Cendyearcollected%2Cmonthcollected%2Cstartmonthcollected%2Cendmonthcollected%2Cdaycollected%2Cstartdaycollected%2Cenddaycollected%2Cseasoncollected%2Ctimeofday%2Cstarttimeofday%2Cendtimeofday%2Ctimezone%2Cwaterbody%2Ccountry%2Cstateprovince%2Ccounty%2Crecordnumber%2Cfieldnumber%2Cstartdecimallongitude%2Cenddecimallongitude%2Cstartdecimallatitude%2Cenddecimallatitude%2Cgeoreferenceprotocol%2Cminimumdepthinmeters%2Cmaximumdepthinmeters%2Coccurrenceid%2Cscientificnameauthorship%2Cscientificnameid%2Ctaxonrank%2Ckingdom%2Cphylum%2Cclass%2Corder%2Cfamily%2Cgenus%2Csubgenus%2Cspecificepithet%2Cinfraspecificepithet%2Caphiaidaccepted%2Coccurrenceremarks%2Cbasisofrecord%2Ctypestatus%2Ccatalognumber%2Creferences%2Crecordedby%2Cidentifiedby%2Cyearidentified%2Cmonthidentified%2Cdayidentified%2Cpreparations%2Csamplingeffort%2Csamplingprotocol%2Cqc%2Ceventid%2Cparameter%2Cparameter_value%2Cparameter_group_id%2Cparameter_measurementtypeid%2Cparameter_bodcterm%2Cparameter_bodcterm_definition%2Cparameter_standardunit%2Cparameter_standardunitid%2Cparameter_imisdasid%2Cparameter_ipturl%2Cparameter_original_measurement_type%2Cparameter_original_measurement_unit%2Cparameter_conversion_factor_to_standard_unit%2Cevent%2Cevent_type%2Cevent_type_id&outputFormat=csv"
download.file(wfs_request, dest = file.path("data","raw_data", "data_cpr.csv"), mode = "wb")

#---- Workflow  ----
# Read data
data_cpr1 <- readr::read_csv(file.path("data","raw_data", "data_cpr.csv"))

# Rename to terms in previous script. See commit 21024fe

# Change names to previous terms, add missing values and select columns
data_cpr <- data_cpr %>% transmute(
  eventDate = datecollected,
  decimalLatitude = decimallatitude,
  decimalLongitude = decimallongitude,
  minimumDepthInMeters = minimumdepthinmeters,
  maximumDepthInMeters = maximumdepthinmeters,
  geodeticDatum = "EPSG:4326",
  scientificName = scientificname,
  scientificNameID = scientificnameid,
  aphiaID = as.integer(gsub("http://marinespecies.org/aphia.php?p=taxdetails&id=", "", aphiaid, fixed = TRUE)),
  individualCount = parameter_value,
  sampleSizeValue = 3, # Volume was always 3m^3 according to metadata
  countMeasurementTypeID = parameter_measurementtypeid
)

# Low Acartia and Oithona species taxonomy to genus
data_cpr$scientificName[grep("Acartia", data_cpr$scientificName, ignore.case = TRUE)] <- "Acartia"
data_cpr$scientificNameID[grep("Acartia", data_cpr$scientificName, ignore.case = TRUE)] <- "urn:lsid:marinespecies.org:taxname:104108"
data_cpr$aphiaID[grep("Acartia", data_cpr$scientificName, ignore.case = TRUE)] <- 104108

data_cpr$scientificName[grep("Oithona", data_cpr$scientificName, ignore.case = TRUE)] <- "Oithona"
data_cpr$scientificNameID[grep("Oithona", data_cpr$scientificName, ignore.case = TRUE)] <- "urn:lsid:marinespecies.org:taxname:106485"
data_cpr$aphiaID[grep("Oithona", data_cpr$scientificName, ignore.case = TRUE)] <- 106485

# Split occurrences with and without Count
data_cpr_na <- subset(data_cpr, data_cpr$countMeasurementTypeID != "http://vocab.nerc.ac.uk/collection/P01/current/OCOUNT01/" | is.na(data_cpr$countMeasurementTypeID))
data_cpr <- subset(data_cpr, data_cpr$countMeasurementTypeID == "http://vocab.nerc.ac.uk/collection/P01/current/OCOUNT01/")

# Save data_cpr_na as csv, without count, abundance nor log abundance
data_cpr_na %>% mutate(abundance = NA,
                       abundanceUnit = NA,
                       abundanceMeasurementUnitID = NA,
                       abundanceMeasurementTypeID = NA,
                       logAbundance = ""
          ) %>% dplyr::arrange(eventDate, decimalLatitude, decimalLongitude, aphiaID
          ) %>% write.csv(file.path("data","derived_data", "data_cpr_na.csv"), fileEncoding = 'UTF-8', row.names = FALSE, na = "")

# Aggregate counts
data_cpr <- data_cpr %>% dplyr::group_by(eventDate, decimalLatitude, decimalLongitude, aphiaID
                   ) %>% dplyr::arrange(eventDate, decimalLatitude, decimalLongitude, aphiaID
                   ) %>% dplyr::mutate(individualCount = sum(individualCount)
                   ) %>% dplyr::distinct(
                   ) %>% dplyr::ungroup()


# Calculate number of individuals per cubic meter. Calculate log abundance
data_cpr <- data_cpr %>% mutate(
  abundance = as.integer(data_cpr$individualCount) / sampleSizeValue,
  abundanceUnit = "ind/m3",
  abundanceMeasurementTypeID = "http://vocab.nerc.ac.uk/collection/P01/current/SDBIOL01/",
  abundanceMeasurementUnitID = "http://vocab.nerc.ac.uk/collection/P06/current/UPMM/"
) %>% mutate(
  logAbundance = log(abundance + 1)
)

# Save as csv
write.csv(data_cpr, file.path("data","derived_data", "data_cpr.csv"), fileEncoding = 'UTF-8', row.names = FALSE, na = "")





