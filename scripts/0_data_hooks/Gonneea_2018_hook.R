## CCRCN Data Library
# contact: klingesd@si.edu

# Data citation: 
# Gonneea, M.E., O'Keefe Suttles, J.A., and Kroeger, K.D., 2018, 
# Collection, analysis, and age-dating of sediment cores from salt marshes on the south shore of Cape Cod, Massachusetts, from 2013 through 2014: 
# U.S. Geological Survey data release, https://doi.org/10.5066/F7H41QPP.


# This script hooks in data from the Gonneea et al 2018 data release

## Assumptions made about data ###############

# that lat and long is in WGS84


## Prep workspace #######################
# Load RCurl, a package used to download files from a URL
library(RCurl)
library(tidyverse)
library(lubridate)
library(RefManageR)

## Download data ########################
# The Gonneea et al (2018) data release features a diverse suite of file types:
#   a .jpg, a .xlsx, a .csv, and a .xml
# So we'll need to have a custom hook for each file

url_list <- list("https://www.sciencebase.gov/catalog/file/get/5a748e35e4b00f54eb19f96c?f=__disk__6f%2F73%2F4b%2F6f734b0239c27f78c7f347dcf277c491a4a47903",
                 "https://www.sciencebase.gov/catalog/file/get/5a748e35e4b00f54eb19f96c?f=__disk__7d%2Fe4%2Fdc%2F7de4dc002db596e1d7fbe8254de9ccc3af05ae3b",
                 "https://www.sciencebase.gov/catalog/file/get/5a748e35e4b00f54eb19f96c?f=__disk__70%2F1e%2F99%2F701e99829e5860c1a0dc512056e5d71ff292dc19",
                 "https://www.sciencebase.gov/catalog/file/get/5a748e35e4b00f54eb19f96c?f=__disk__3e%2F2d%2Ff5%2F3e2df544c537a35007214d1fe595b45499df2f4a")

# Extract Saltmarsh_AR.jpg
download.file(url_list[[1]], "./data/Gonneea_2018/original/Saltmarsh_AR.jpg",
              mode = "wb")

# Extract Waquoit_Core_data_release.xlsx
download.file(url_list[[2]], "./data/Gonneea_2018/original/Waquoit_Core_data_release.xlsx",
              mode = "wb")

# Extract Waquoit_Core_data_release.csv
download.file(url_list[[3]], "./data/Gonneea_2018/original/Waquoit_Core_data_release.csv",
              mode = "wb")

# Extract Waquoit_Core_data_release_meta.xml
download.file(url_list[[4]], "./data/Gonneea_2018/original/Waquoit_Core_data_release_meta.xml",
              mode = "wb")


## Curate data to CCRCN Structure ########################

# Import data file into R
Gonneea_2018 <- read_csv("./data/primary_studies/Gonneea_2018/original/Waquoit_Core_data_release.csv", 
                         col_names = TRUE)

# Change column names to values of first row
# Why? Because the top 2 rows were both dedicated to column headers
new_colnames <- c(Gonneea_2018 %>%
  slice(1))
colnames(Gonneea_2018) <- new_colnames
Gonneea_2018 <- Gonneea_2018 %>%
  slice(2:561)

# Change all no data values to "NA"
Gonneea_2018 <- Gonneea_2018 %>%
  na_if(-99999) # Changes all "-99999" values to "NA"

# Curate data: 
Gonneea_2018 <- Gonneea_2018 %>%
  rename(core_id = "ID",
         core_date = "Date", 
         depth = "Depth",
         core_latitude = "Lat",
         core_longitude = "Lon",
         dry_bulk_density = "DBD",
         age = "Age",
         total_pb210_activity = "210Pb",
         ra226_activity = "226Ra",
         excess_pb210_activity = "210Pbex",
         cs137_activity = "137Cs",
         be7_activity = "7Be", 
         total_pb210_activity_sd = `210Pb_e`, 
         ra226_activity_sd = `226Ra_e`,
         excess_pb210_activity_sd = `210Pbex_e`,
         cs137_activity_sd = `137Cs_e`, 
         be7_activity_sd = `7Be_e`,
         age_sd = Age_e) %>%
  mutate(study_id = "Gonneea_et_al_2018") %>%
  mutate(core_latitude = as.numeric(core_latitude)) %>%
  mutate(core_longitude = as.numeric(core_longitude)) %>%
  mutate(dry_bulk_density = as.numeric(dry_bulk_density)) %>%
  mutate(age = as.numeric(age)) %>%
  mutate(total_pb210_activity = as.numeric(total_pb210_activity)) %>%
  mutate(ra226_activity = as.numeric(ra226_activity)) %>%
  mutate(excess_pb210_activity = as.numeric(excess_pb210_activity)) %>%
  mutate(cs137_activity = as.numeric(cs137_activity)) %>%
  mutate(be7_activity = as.numeric(be7_activity)) %>%
  # Change core_date column to date objects
  mutate(core_date = as.Date(as.numeric(core_date), origin = "1899-12-30"), 
         depth = as.numeric(depth))

# according to the publication, the first 30 cm are 1 cm intervals, 
# the proceeding interals are at 2 cm 
# Convert mean interval depth to min and max interval depth
Gonneea_2018 <- Gonneea_2018 %>%
  mutate(depth_min = ifelse(depth < 30, depth - .5, 
                            ifelse(depth < 100, depth - 1, depth - 5)), 
         depth_max = ifelse(depth < 30, depth + .5, 
                            ifelse(depth < 100, depth + 1, depth + 5)))

# Provide units and notes for dating techniques 
Gonneea_2018 <- Gonneea_2018 %>%
  mutate(pb210_unit = "disintegrations_per_minute_per_gram",
         cs137_unit = "disintegrations_per_minute_per_gram",
         be7_unit = "disintegrations_per_minute_per_gram",
         ra226_unit = "disintegrations_per_minute_per_gram") %>%
  # if 0, below detection limits
  mutate(dating_interval_notes = ifelse(cs137_activity == 0 & be7_activity == 0, "cs137 and be7 activity below detection limits",
                                        ifelse(cs137_activity == 0, "cs137 activity below detection limits", 
                                               ifelse(be7_activity == 0, "be7 activity below detection limits", NA)))) 

# Convert percent weights to fractions
Gonneea_2018 <- Gonneea_2018 %>%
  mutate(fraction_carbon = as.numeric(wtC) / 100)
  
## Parcel data into separate files according to data level #################
# Core data

# Gonneea elevation is calculated for each depth interval. We only want elevation
#   at the top of the core
core_elevation <- Gonneea_2018 %>%
  group_by(core_id) %>%
  summarize(core_elevation = max(as.numeric(Elevation)))
  
Gonneea_2018_core_Data <- Gonneea_2018 %>%
  group_by(study_id, core_id, core_date) %>%
  summarize(core_latitude = first(core_latitude), core_longitude = first(core_longitude)) %>%
  left_join(core_elevation) %>%
  # convert elevation from cm to meters
  mutate(core_elevation = core_elevation * .01)

# Depth Series data
Gonneea_2018_depth_series_data <- Gonneea_2018 %>%
  select(study_id, core_id, depth_min, depth_max, 
         dry_bulk_density, fraction_carbon, 
         cs137_activity, cs137_activity_sd, cs137_unit, 
         total_pb210_activity, total_pb210_activity_sd, pb210_unit, 
         ra226_activity, ra226_activity_sd, ra226_unit,
         excess_pb210_activity, excess_pb210_activity_sd,  
         be7_activity, be7_activity_sd, be7_unit, 
         age, age_sd, dating_interval_notes) %>%
  filter(depth_min >= 0)


## Add site data ################
# The data is missing site IDs but we have records of them from the Holmquist et al. 2018 data release. 

Gonneea_2018_core_Data <- Gonneea_2018_core_Data %>%
  mutate(site_id = recode_factor(core_id, 
                                 "EPA" = "Eel_Pond", 
                                 "EPB" = "Eel_Pond",
                                 "GPA" = "Great_Pond", 
                                 "GPB" = "Great_Pond", 
                                 "GPC" = "Great_Pond", 
                                 "HBA" = "Hamblin_Pond",
                                 "HBB" = "Hamblin_Pond",
                                 "HBC" = "Hamblin_Pond", 
                                 "SLPA" = "Sage_Log_Pond", 
                                 "SLPB" = "Sage_Log_Pond",
                                 "SLPC" = "Sage_Log_Pond"
  ))


Gonneea_2018_depth_series_data <- Gonneea_2018_depth_series_data %>%
  mutate(site_id = recode_factor(core_id, 
                                 "EPA" = "Eel_Pond", 
                                 "EPB" = "Eel_Pond",
                                 "GPA" = "Great_Pond", 
                                 "GPB" = "Great_Pond", 
                                 "GPC" = "Great_Pond", 
                                 "HBA" = "Hamblin_Pond",
                                 "HBB" = "Hamblin_Pond",
                                 "HBC" = "Hamblin_Pond", 
                                 "SLPA" = "Sage_Log_Pond", 
                                 "SLPB" = "Sage_Log_Pond",
                                 "SLPC" = "Sage_Log_Pond"
  )) %>%
  select(study_id, site_id, core_id, everything())

## Create study-level data ######
doi <- "10.5066/F7H41QPP"
study <- "Gonneea_et_al_2018"

# Get bibtex citation from DOI
biblio_raw <- GetBibEntryWithDOI(doi)
biblio_df <- as.data.frame(biblio_raw)
study_citations <- biblio_df %>%
  rownames_to_column("key") %>%
  mutate(bibliography_id = study, 
         study_id = study,
         key = study,
         publication_type = "data release", 
         year = as.numeric(year)) %>%
  select(study_id, bibliography_id, publication_type, everything())

# Write .bib file
bib_file <- study_citations %>%
  select(-study_id, -bibliography_id, -publication_type) %>%
  column_to_rownames("key")

WriteBib(as.BibEntry(bib_file), "./data/Gonneea_2018/derivative/Gonneea_et_al_2018.bib")


## QA/QC of data ################
source("./scripts/1_data_formatting/qa_functions.R")

# Make sure column names are formatted correctly: 
test_colnames("core_level", Gonneea_2018_core_Data)
test_colnames("depthseries", Gonneea_2018_depth_series_data)

# Test relationships between core_ids at core- and depthseries-levels
# the test returns all core-level rows that did not have a match in the depth series data
results <- test_core_relationships(Gonneea_2018_core_Data, Gonneea_2018_depth_series_data)


## Export files ##############################
  
# Export core data
write_csv(Gonneea_2018_core_Data, "./data/Gonneea_2018/derivative/Gonneea_et_al_2018_cores.csv")

# Export depth series data
write_csv(Gonneea_2018_depth_series_data, "./data/primary_studies/Gonneea_2018/derivative/Gonneea_et_al_2018_depthseries.csv")
  
# Export master data
# write_csv(Gonneea_2018, "./data/Gonneea_2018/derivative/Gonneea_2018.csv")

# Export study-citation table
write_csv(study_citations, "./data/Gonneea_2018/derivative/Gonneea_et_al_2018_study_citations.csv")

