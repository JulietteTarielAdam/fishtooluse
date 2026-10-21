library(rairtable)
library(tidyverse)

base_id <- "app3cz3P4JaF2rq5q"

# Participants 
participants_raw <- airtable("Participants",base_id) %>% 
  read_airtable(.)
participants <- participants_raw %>% 
  filter(`Name-obs` == "Yes") %>% 
  arrange(`Date-first-contact`) %>% 
  transmute(Participant,`Social-media-reference` = replace_na(`Social-media-reference`, ""))

write.csv(participants, row.names = FALSE, "airtable/participants.csv")

# Fish
fish_raw <- airtable("Fish",base_id) %>%
  read_airtable(.)
fish <- fish_raw %>% 
  unnest(Picture) %>% 
  select(Species, `Vernacular-name`, `Link-Fishbase`, `Link-Wikipedia`, `Link-iNaturalist`, `Link-Doris`, filename)

write.csv(fish, row.names = FALSE, "airtable/fish.csv")

# Last contribution
observations_raw <- airtable("Observations",base_id) %>%
  read_airtable(.)

videos_raw <- airtable("Videos", base_id) %>%
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

