## CCRCN Data Library
# contact: lonnemanm@si.edu

## 1. Citations  ###############
# Data Citation
# Thorne, K. 2015. Field and model data for studying the effects of sea-level rise on eight tidal marshes in coastal Washington and Oregon. 
# US Geological Survey Data Release. 10.5066/F7SJ1HNC.
# https://www.sciencebase.gov/catalog/item/55ae7d09e4b066a24924239f

# Publication Citation
# Karen Thorne, Glen MacDonald, Glenn Guntenspergen, Richard Ambrose, Kevin Buffington, Bruce Dugger, Chase Freeman, 
# Christopher Janousek, Lauren Brown, Jordan Rosencranz, James Holmquist, John Smol, Kathryn Hargan, and John Takekawa, 2018, 
# U.S. Pacific coastal wetland resilience and vulnerability to sea-level rise: Science Advances, v. 4, iss. 2.

## 2. Prep workspace #######################
library(tidyverse)
library(lubridate)
library(readxl)
library(RefManageR)
# the following packages are needed to convert UTM to lat/long
library(sp)
library(rgdal)
library(DataCombine)

## 3. Read in data #########################
# The soil core and depthseries data is spread across multiple sheets in an excel file. 
# Each core's depth series has it's own page but there is no core ID in the table. 
# Instead, the sheet name is the associated core name. 
# Each sheet will need to be read in as part of a loop

## ... 3A Assemble vector of core names and import ##################
core_ids <- c("BM01", "BM03", "BM05", "CB00", "CB03", 'CB06', "GH01", "GH03", "GH06", 
              "NQ01", "NQ04", "NQ06", "PS02", "PS04", 'PS05', "SZ02", "SZ03", "SZ05",
              "SK02", "SK04", "SK06", "WB01", "WB04", "WB06")

num_cores <- length(core_ids)

for(i in 1:num_cores) {
  d <- read_excel("./data/Thorne_2015_a/original/NWCSC Sediment Core Data.xlsx", sheet=as.character(core_ids[i]))
  d <- d %>%
    mutate(core_id = core_ids[i]) %>%
    rename(depth_min = "Depth (cm)",
           fraction_organic_matter = "Organic Content", 
           dry_bulk_density = "Bulk Density") %>%
    mutate(fraction_organic_matter = as.double(fraction_organic_matter),
           dry_bulk_density = as.double(dry_bulk_density))
  assign(core_ids[i],d)
}

## ... 3B Import core-level data 
raw_core_data <- read_excel("./data/Thorne_2015_a/original/NWCSC Sediment Core Data.xlsx", sheet="CoreSurveys_CS137")

## 4 Curate Data ##################

## ... 4A Append depthseries data, add appropriate core ID, and curate ############
depthseries_data <- data.frame(matrix(nrow=0, ncol=4))
colnames(depthseries_data) <- colnames(BM01)

core_ids <- list(BM01, BM03, BM05, CB00, CB03, CB06, GH01, GH03, GH06, 
              NQ01, NQ04, NQ06, PS02, PS04, PS05, SZ02, SZ03, SZ05,
              SK02, SK04, SK06, WB01, WB04, WB06)

depthseries_data <- depthseries_data %>%
  bind_rows(core_ids) %>%
  mutate(depth_max = depth_min + 1, 
         fraction_organic_matter = fraction_organic_matter / 100,
         study_id = "Thorne_et_al_2015") %>%
  # turn negative fraction_organic_matter values to 0
  mutate(fraction_organic_matter = ifelse(fraction_organic_matter < 0, 0, fraction_organic_matter)) %>%
  select(study_id, core_id, depth_min, depth_max, fraction_organic_matter, dry_bulk_density)

# add site IDs to depthseries 
sites <- raw_core_data %>%
  mutate(core_id = paste(SiteCode, Core, sep="0")) %>%
  rename(site_id = Site) %>%
  select(core_id, site_id) 

depthseries_data <- depthseries_data %>% 
  merge(sites, 
        by="core_id", 
        all.x=TRUE, all.y=FALSE) %>%
  select(study_id, site_id, core_id, depth_min, depth_max, fraction_organic_matter, dry_bulk_density)

## ... 4B Curate core-level data #############
core_data <- raw_core_data %>%
  rename(core_elevation = `Elevation (m, NAVD88)`,
         cs137_peak_cm = `CS137 Peak (cm)`) %>%
  
  # Whomever uploaded this dataset to its public repository forgot a digit from
  #   a coordinate....
  mutate(Northing = ifelse(SiteCode == "CB" & Core == 5, (Northing * 10), Northing)) %>%
  mutate(core_id = paste(SiteCode, Core, sep="0"),
         study_id = "Thorne_et_al_2015", 
         core_position_method = "RTK", 
         core_elevation_datum = "NAVD88",
         zone = 10) 

# convert UTM to lat long
source("./scripts/1_data_formatting/curation_functions.R") 
output <- convert_UTM_to_latlong(core_data$Easting, core_data$Northing, core_data$zone, core_data$core_id)

# merge coordinates to core table and clean up table
core_data <- core_data %>%
  merge(output, by="core_id") %>%
  rename(site_id = Site) %>%
  select(study_id, site_id, core_id, core_latitude, core_longitude, core_position_method, core_elevation, core_elevation_datum, cs137_peak_cm)

# There are some cores that have no information other than coordinates. ML and DK
#   agreed that there isn't much value in including these, and they inappropriately
#   inflate our total number of cores stats, so we'll remove
core_data <- core_data %>%
  filter(core_id %in% depthseries_data$core_id)

## ... 4C Add cs137 TRUE/FALSE value to depthseries #####
# If a given interval contains the cs137 peak, give it a TRUE value. 

peaks <- core_data %>%
  filter(cs137_peak_cm >= 0) %>%
  select(core_id, cs137_peak_cm)

depthseries_data <- depthseries_data %>%
  merge(peaks, by="core_id", all.x=TRUE, all.y=TRUE) %>%
  mutate(cs137_peak_present = ifelse(is.na(cs137_peak_cm)==TRUE, FALSE, ifelse(cs137_peak_cm == depth_min, TRUE, FALSE))) %>%
  select(-cs137_peak_cm)

core_data <- select(core_data, -cs137_peak_cm)

## ... 4D Generate study-citation link ############
study <- "Thorne_et_al_2015"
doi <- "10.5066/F7SJ1HNC"

biblio_raw <- BibEntry(bibtype = "Misc", 
                             key = "Thorne_et_al_2015", 
                             title = "Marshes to Mudflats: Climate Change Effects Along a Latitudinal Gradient in the Pacific Northwest",
                             author = "U.S. Geological Survey {Karen Thorne}", 
                             doi = "10.5066/f7sj1hnc",
                             publisher = "U.S. Geological Survey",
                             year = "2015", 
                             url = "https://www.sciencebase.gov/catalog/item/5006e99ee4b0abf7ce733f58"
)
biblio_df <- as.data.frame(biblio_raw)

study_citations <- biblio_df %>%
  rownames_to_column("key") %>%
  mutate(bibliography_id = study, 
         study_id = study,
         publication_type = "data release", 
         year = as.numeric(year)) %>%
  select(study_id, bibliography_id, publication_type, everything())

# Write .bib file
bib_file <- study_citations %>%
  select(-study_id, -bibliography_id, -publication_type) %>%
  column_to_rownames("key")

WriteBib(as.BibEntry(bib_file), "./data/Thorne_2015_a/derivative/Thorne_et_al_2015.bib")

## 5. QA/QC of data ################
source("./scripts/1_data_formatting/qa_functions.R")

# Make sure column names are formatted correctly: 
test_colnames("core_level", core_data)
test_colnames("depthseries", depthseries_data)

test_varnames(core_data)
test_varnames(depthseries_data)

numeric_test_results <- test_numeric_vars(depthseries_data)

# Test relationships between core_ids at core- and depthseries-levels
# the test returns all core-level rows that did not have a match in the depth series data
results <- test_core_relationships(core_data, depthseries_data)

## 6. Export data
write_csv(core_data, "./data/Thorne_2015_a/derivative/Thorne_et_al_2015_cores.csv")
write_csv(depthseries_data, "./data/Thorne_2015_a/derivative/Thorne_et_al_2015_depthseries.csv")
write_csv(study_citations, "./data/Thorne_2015_a/derivative/Thorne_et_al_2015_study_citations.csv")

