library(rairtable)
library(tidyverse)

AIRTABLE_BASE_ID <- Sys.getenv("AIRTABLE_BASE_ID")
if (AIRTABLE_BASE_ID == "") stop("AIRTABLE_BASE_ID is not set")

AIRTABLE_BASE_ID <- Sys.getenv("AIRTABLE_API_KEY")
if (AIRTABLE_API_KEY == "") stop("AIRTABLE_API_KEY is not set")

# Participants 
participants_raw <- airtable("Participants",AIRTABLE_BASE_ID) %>% 
  read_airtable(.)
participants <- participants_raw %>% 
  filter(`Name-obs` == "Yes") %>% 
  arrange(`Date-first-contact`) %>% 
  transmute(Participant,`Social-media-reference` = replace_na(`Social-media-reference`, ""))

write.csv(participants, row.names = FALSE, "airtable/participants.csv")

# Fish
fish_raw <- airtable("Fish",AIRTABLE_BASE_ID) %>%
  read_airtable(.)
fish <- fish_raw %>% 
  unnest(Picture) %>% 
  select(Species, `Vernacular-name`, `Link-Fishbase`, `Link-Wikipedia`, `Link-iNaturalist`, `Link-Doris`, filename)

write.csv(fish, row.names = FALSE, "airtable/fish.csv")

# Last contribution
observations_raw <- airtable("Observations",AIRTABLE_BASE_ID) %>%
  read_airtable(.)

videos_raw <- airtable("Videos", AIRTABLE_BASE_ID) %>%
  read_airtable(.)

if (max(videos_raw$Created) > max(observations_raw$Created)){
  last.obs <- videos_raw[which(videos_raw$Created == max(videos_raw$Created)), ]
} else {
  last.obs <- observations_raw[which(observations_raw$Created == max(observations_raw$Created)), ]
}

last.obs <- last.obs |> unnest(c(`Name associated`,`Name (from Participants)`,`Species (from Fish)`)) |> 
  transmute(Contributor = if_else(`Name associated` == "Yes", `Name (from Participants)`,"Anonymous"),
            Location, 
            Country,
            Species = `Species (from Fish)`)  |> 
  left_join(fish |> select(Species, `Vernacular-name`,filename),by = "Species")

write.csv(last.obs, row.names = FALSE, "airtable/last-observation.csv")

