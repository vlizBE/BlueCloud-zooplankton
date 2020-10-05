library(readr)
library(dplyr)

##---- RUN ONCE ----
# Request CPR data of "Temora longicornis", "Calanus finmarchicus", "Calanus helgolandicus", "Metridia lucens", "Acartia sp." and "Oithona sp."
# aphiaid: 104878, 104464, 104466, 104633, 106485, 104108
wfs_request <- "http://geo.vliz.be/geoserver/wfs/ows?service=WFS&version=1.1.0&request=GetFeature&typeName=Dataportal%3Aeurobis-obisenv&resultType=results&viewParams=where%3Adatasetid+IN+%28216%29%3Bcontext%3A0100%3Baphiaid%3A104108%5C%2C104878%5C%2C104464%5C%2C104466%5C%2C104633%5C%2C106485&propertyName=datasetid%2Cdatecollected%2Cdecimallatitude%2Cdecimallongitude%2Ccoordinateuncertaintyinmeters%2Cscientificname%2Caphiaid%2Cscientificnameaccepted%2Cmodified%2Cinstitutioncode%2Ccollectioncode%2Cyearcollected%2Cstartyearcollected%2Cendyearcollected%2Cmonthcollected%2Cstartmonthcollected%2Cendmonthcollected%2Cdaycollected%2Cstartdaycollected%2Cenddaycollected%2Cseasoncollected%2Ctimeofday%2Cstarttimeofday%2Cendtimeofday%2Ctimezone%2Cwaterbody%2Ccountry%2Cstateprovince%2Ccounty%2Crecordnumber%2Cfieldnumber%2Cstartdecimallongitude%2Cenddecimallongitude%2Cstartdecimallatitude%2Cenddecimallatitude%2Cgeoreferenceprotocol%2Cminimumdepthinmeters%2Cmaximumdepthinmeters%2Coccurrenceid%2Cscientificnameauthorship%2Cscientificnameid%2Ctaxonrank%2Ckingdom%2Cphylum%2Cclass%2Corder%2Cfamily%2Cgenus%2Csubgenus%2Cspecificepithet%2Cinfraspecificepithet%2Caphiaidaccepted%2Coccurrenceremarks%2Cbasisofrecord%2Ctypestatus%2Ccatalognumber%2Creferences%2Crecordedby%2Cidentifiedby%2Cyearidentified%2Cmonthidentified%2Cdayidentified%2Cpreparations%2Csamplingeffort%2Csamplingprotocol%2Cqc%2Ceventid%2Cparameter%2Cparameter_value%2Cparameter_group_id%2Cparameter_measurementtypeid%2Cparameter_bodcterm%2Cparameter_bodcterm_definition%2Cparameter_standardunit%2Cparameter_standardunitid%2Cparameter_imisdasid%2Cparameter_ipturl%2Cparameter_original_measurement_type%2Cparameter_original_measurement_unit%2Cparameter_conversion_factor_to_standard_unit%2Cevent%2Cevent_type%2Cevent_type_id&outputFormat=csv"
download.file(wfs_request, dest = file.path("data","raw_data", "data_cpr.csv"), mode = "wb")

#---- Workflow  ----
# Read data
data_cpr <- readr::read_csv('./data/raw_data/data_cpr.csv')

# Select columns
data_cpr <- data_cpr %>% select(
  datecollected, decimallatitude, decimallongitude,
  minimumdepthinmeters, maximumdepthinmeters, scientificname, scientificnameid,
  parameter, parameter_value, parameter_measurementtypeid, parameter_bodcterm, parameter_original_measurement_type
)

# Low Acartia and Oithona species taxonomy to genus
data_cpr$scientificname[grep("Acartia", data_cpr$scientificname, ignore.case = TRUE)] <- "Acartia"
data_cpr$scientificnameid[grep("Acartia", data_cpr$scientificname, ignore.case = TRUE)] <- "urn:lsid:marinespecies.org:taxname:104108"

data_cpr$scientificname[grep("Oithona", data_cpr$scientificname, ignore.case = TRUE)] <- "Oithona"
data_cpr$scientificnameid[grep("Oithona", data_cpr$scientificname, ignore.case = TRUE)] <- "urn:lsid:marinespecies.org:taxname:106485"

# Add aphiaid column
data_cpr$aphiaid <- as.integer(gsub("urn:lsid:marinespecies.org:taxname:", "", data_cpr$scientificnameid))

# Split occurrences with and without Count
data_cpr_na <- subset(data_cpr, data_cpr$parameter_measurementtypeid != "http://vocab.nerc.ac.uk/collection/P01/current/OCOUNT01/" | is.na(data_cpr$parameter_measurementtypeid))
data_cpr <- subset(data_cpr, data_cpr$parameter_measurementtypeid == "http://vocab.nerc.ac.uk/collection/P01/current/OCOUNT01/")

# Aggregate counts
data_cpr <- data_cpr %>% dplyr::group_by(datecollected, decimallatitude, decimallongitude, aphiaid
                   ) %>% dplyr::arrange(datecollected, decimallatitude, decimallongitude, aphiaid
                   ) %>% dplyr::mutate(parameter_value = sum(parameter_value)
                   ) %>% dplyr::distinct(
                   ) %>% dplyr::ungroup()

# Calculate number of individuals per cubic meter - Volume was always 3m^3 according to metadata
data_cpr$abundance <- as.integer(data_cpr$parameter_value) / 3
data_cpr$abundanceUnit <- "ind/m3"
data_cpr$abundanceMeasurementTypeID <- "http://vocab.nerc.ac.uk/collection/P01/current/SDBIOL01/"
data_cpr$abundanceMeasurementUnitID <- "http://vocab.nerc.ac.uk/collection/P06/current/UPMM/"

# Calculate the log abundance
data_cpr$logAbundance <- log(data_cpr$abundance + 1)

# Add occurrences without count, abundance nor log abundance
data_cpr <- data_cpr_na %>% dplyr::mutate(abundance = NA, abundanceUnit = NA, abundanceMeasurementUnitID = NA, abundanceMeasurementTypeID = NA, logAbundance = NA
                      ) %>% rbind(data_cpr
                      ) %>% dplyr::arrange(datecollected, aphiaid)

# Save as csv
write.csv(data_cpr, file.path("data","derived_data", "data_cpr.csv"), fileEncoding = 'UTF-8', row.names = FALSE, na = "")





