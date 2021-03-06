# Dataset: Factors influencing blue carbon accumulation across a 32‐year chronosequence of created coastal marshes
# 
# Authors: Katherine M Abbott <kmabbott@umass.edu>, Tracy Quirk, Ronald D DeLaune
# 
# Any use of this dataset must include a citation. The DOI: 10.25573/data.10005215
# 
# The data release contains tidal wetland soil carbon profiles. The data itself is housed in fiv separate .csv files which can by joined by the core_id and/or site_id attributes. 
# 
# abbott_et_al_2019_materials_and_methods.csv - Contains information on materials and methods broken down by study 
# abbott_et_al_2019_cores.csv - Contains positional and descriptive information on core locations.
# abbott_et_al_2019_depthseries.csv - Contains raw depth-series information for all cores.
# abbott_et_al_2019_species.csv - Contains information on the dominant plant species at coring locations.
# abbott_et_al_2019_impacts.csv - Contains information on the anthropogenic impacts at coring locations.
# 
# metadata.xml - Contains a full suite of descriptive metadata with all attribute and variables defined, units clarified, and geographic, temporal, and taxonomic coverages described according to Ecological Metadata Language Standards.
# 
# metadata.html - Is a simplified, visual and interactive version of metadata.xml for display purposes.
# 
# map.html - Is a map widget showing the geographic coverages described in the metadata. It can be accessed on its own or through metadata.html.
# 
# custom.css - Contains display information for metadata.html.
# 
# abbott_et_al_2019_associated_publications.bib - A citation in bibtex style for associated publications to this data release

library(tidyverse)
library(RefManageR)

cores_raw <- read_csv("./data/primary_studies/Abbott_2019/original/abbott_et_al_2019_cores.csv")
depthseries_raw <- read.csv("./data/primary_studies/Abbott_2019/original/abbott_et_al_2019_depthseries.csv")
impacts_raw <-read_csv("./data/primary_studies/Abbott_2019/original/abbott_et_al_2019_impacts.csv")
species_raw <- read_csv("./data/primary_studies/Abbott_2019/original/abbott_et_al_2019_species.csv")
methods <- read_csv("./data/primary_studies/Abbott_2019/original/abbott_et_al_2019_material_and_methods.csv")

## Curate data ####
# Remove uncontrolled vocab
cores <- cores_raw %>%
  select(study_id, site_id, core_id, core_date, core_longitude, core_latitude, core_position_method,
         core_elevation, core_elevation_method, salinity_class, vegetation_class)

depthseries <- depthseries_raw %>%
  select(-fraction_nitrogen)

species <- species_raw %>%
  mutate(species_code = paste(genus, species, sep=" ")) %>%
  select(-c(genus, species))

# Create bibtex file
data_release_doi <- "10.25573/data.10005215"
associated_pub_doi <- "10.1002/ecs2.2828"
study_id <- "Abbott_et_al_2019"

data_bib_raw <- GetBibEntryWithDOI(c(data_release_doi, associated_pub_doi))

bib <- as.data.frame(data_bib_raw) %>%
  rownames_to_column("key") %>%
  mutate(study_id = study_id) %>%
  mutate(doi = tolower(doi),
         bibliography_id = study_id,
         key = ifelse(bibtype == "Misc", "Abbott_et_al_2019_data", key),
         publication_type = bibtype) 

# Curate biblio so ready to read out as a BibTex-style .bib file
study_citations <- bib %>%
  select(study_id, bibliography_id, publication_type, key, bibtype, everything()) %>%
  mutate(year = as.numeric(year),
         volume = as.numeric(volume))

# Write .bib file
bib_file <- study_citations %>%
  select(-study_id, -bibliography_id, -publication_type) %>%
  distinct() %>%
  column_to_rownames("key")

WriteBib(as.BibEntry(bib_file), "data/primary_studies/Abbott_2019/derivative/Abbott_et_al_2019.bib")

write_csv(cores, "data/primary_studies/abbott_2019/derivative/abbott_et_al_2019_cores.csv") 
write_csv(depthseries, "data/primary_studies/abbott_2019/derivative/abbott_et_al_2019_depthseries.csv")
write_csv(study_citations, "data/primary_studies/abbott_2019/derivative/abbott_et_al_2019_study_citations.csv")
write_csv(species, "data/primary_studies/abbott_2019/derivative/abbott_et_al_2019_species.csv")
write_csv(methods, "data/primary_studies/abbott_2019/derivative/abbott_et_al_2019_methods.csv")

