# BlueCloud-zooplankton
repository to share BlueCloud Demonstrator #1 - zooplankton scripts

## Dataset
This script is used to format the Continuous Plankton Recorder dataset from the Marine Biological Association. https://www.dassh.ac.uk/ipt/resource?r=cpr_public

Johns D, Broughton D (2019): The CPR Survey. v1.2. Marine Biological Association. Dataset/Samplingevent. https://doi.org/10.17031/1629

This dataset is formatted in DarwinCore Event Core. It is incorporated in EurOBIS and available through the EMODnet-Biology portal. The following WFS request returns the raw data used by `read_cpr.r`:

```
http://geo.vliz.be/geoserver/wfs/ows?service=WFS&version=1.1.0&request=GetFeature&typeName=Dataportal%3Aeurobis-obisenv&resultType=results&viewParams=where%3Adatasetid+IN+%28216%29%3Bcontext%3A0100%3Baphiaid%3A104108%5C%2C104878%5C%2C104464%5C%2C104466%5C%2C104633%5C%2C106485&propertyName=datasetid%2Cdatecollected%2Cdecimallatitude%2Cdecimallongitude%2Ccoordinateuncertaintyinmeters%2Cscientificname%2Caphiaid%2Cscientificnameaccepted%2Cmodified%2Cinstitutioncode%2Ccollectioncode%2Cyearcollected%2Cstartyearcollected%2Cendyearcollected%2Cmonthcollected%2Cstartmonthcollected%2Cendmonthcollected%2Cdaycollected%2Cstartdaycollected%2Cenddaycollected%2Cseasoncollected%2Ctimeofday%2Cstarttimeofday%2Cendtimeofday%2Ctimezone%2Cwaterbody%2Ccountry%2Cstateprovince%2Ccounty%2Crecordnumber%2Cfieldnumber%2Cstartdecimallongitude%2Cenddecimallongitude%2Cstartdecimallatitude%2Cenddecimallatitude%2Cgeoreferenceprotocol%2Cminimumdepthinmeters%2Cmaximumdepthinmeters%2Coccurrenceid%2Cscientificnameauthorship%2Cscientificnameid%2Ctaxonrank%2Ckingdom%2Cphylum%2Cclass%2Corder%2Cfamily%2Cgenus%2Csubgenus%2Cspecificepithet%2Cinfraspecificepithet%2Caphiaidaccepted%2Coccurrenceremarks%2Cbasisofrecord%2Ctypestatus%2Ccatalognumber%2Creferences%2Crecordedby%2Cidentifiedby%2Cyearidentified%2Cmonthidentified%2Cdayidentified%2Cpreparations%2Csamplingeffort%2Csamplingprotocol%2Cqc%2Ceventid%2Cparameter%2Cparameter_value%2Cparameter_group_id%2Cparameter_measurementtypeid%2Cparameter_bodcterm%2Cparameter_bodcterm_definition%2Cparameter_standardunit%2Cparameter_standardunitid%2Cparameter_imisdasid%2Cparameter_ipturl%2Cparameter_original_measurement_type%2Cparameter_original_measurement_unit%2Cparameter_conversion_factor_to_standard_unit%2Cevent%2Cevent_type%2Cevent_type_id&outputFormat=csv
```

## Preprocessing

In the file `read_cpr.r` we preprocess the data so it can be easily ingested for the BlueCloud product generation:

* we select a subset of all columns
* we filter on the target species: *Temora longicornis, Calanus finmarchicus, Calanus helgolandicus, Metridia lucens.*
* for *Acartia* and *Oithona* species, we combine all species to genus level *Acartia* and *Oithona*
* we add the aphia id as extra variable
* we convert the counts and sample size (volume) to abundance in individuals/m³ (ind/m³)
* we calculate the log(abundance + 1)
* we export the data to `data/derived_data/data_cpr.csv`


## Troubleshooting
* There are a number of records without counts available. Thus, abundances and log abundances could not be calculated. These are added to the processed data in `data/derived_data/data_cpr.csv` with `NA` values
