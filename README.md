# BlueCloud-zooplankton
repository to share BlueCloud Demonstrator #1 - zooplankton scripts

## Dataset
This script is used to format the Continuous Plankton Recorder dataset from the Marine Biological Association.
https://www.dassh.ac.uk/ipt/resource?r=cpr_public

Johns D, Broughton D (2019): The CPR Survey. v1.2. Marine Biological Association. Dataset/Samplingevent. https://doi.org/10.17031/1629

This dataset is formatted in DarwinCore Event Core. It will very soon be ingested by EurOBIS.

## Preprocessing

In the file `read_cpr.r` we preprocess the data so it can be easily ingested for the BlueCloud product generation:

* we merge the DwC occurrences and events table
* we select a subset of all columns
* we add the aphia id as extra variable
* we filter on the target species: *Temora longicornis, Calanus finmarchicus, Calanus helgolandicus, Metridia lucens.* and add the aphia id
* for *Acartia* and *Oithona* subspecies, we combine all subspecies to genus level *Acartia* and *Oithona*
* we convert the counts and sample size (volume) to abundance in individuals/m³ (ind/m³)
* we calculate the log(abundance + 1)
* we export the data to data/derived_data/data.csv
