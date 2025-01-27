library(tidyverse)
library(sf)
library(camcorder)

gg_record(here::here("30daymap-temp"), width = 12, height = 12, dpi = 320)

# Data https://volcano.si.edu
# Global Volcanism Program, 2022. [Database] Volcanoes of the World (v. 5.0.0; 1 Nov 2022). Distributed by Smithsonian Institution, compiled by Venzke, E. https://doi.org/10.5479/si.GVP.VOTW5-2022.5.0
volc <- read_sf(here::here("2022/data/Global_2013_HoloceneVolcanoes_SmithsonianVOTW_41/Smithsonian_VOTW_Holocene_VolcanoesPoint.shp")) %>% 
  mutate(
    evidence = case_when(
      str_detect(Evidence_C, "Confirmed|Dated|Observed|Credible") ~ "Confirmed or credible",
      str_detect(Evidence_C, "Uncertain") ~ "Uncertain",
      TRUE ~ Evidence_C
    )
  )

crs_string <- "+proj=ortho +lat_0=30 +lon_0=150 +x_0=0 +y_0=0 +a=6371000 +b=6371000 +units=m +no_defs"

ocean <- st_point(x = c(0, 0)) %>%
  st_buffer(dist = 6371000) %>%
  st_sfc(crs = crs_string)

volc_ortho <- volc %>% 
  st_intersection(ocean %>% st_transform(4326)) %>% # select visible area only
  st_transform(crs = crs_string) # reproject to ortho

coast <- read_sf(here::here("2022/data/ne_10m_land/ne_10m_land.shp")) %>% 
  st_intersection(ocean %>% st_transform(4326)) %>% 
  st_transform(crs = crs_string)
  
plates <- read_sf(here::here("2021/data/fraxen tectonicplates master GeoJSON/PB2002_boundaries.json"))  %>% 
  st_intersection(ocean %>% st_transform(4326)) %>% 
  st_transform(crs = crs_string)

ggplot() +
  geom_sf(data = ocean, fill = "azure3", color = NA) +
  geom_sf(data = coast, linewidth = 0.15, fill = "cornsilk2", color = NA) +
  geom_sf(data = plates, linewidth = 0.25, linetype = "dashed") +
  geom_sf(data = volc_ortho, aes(shape = evidence), color = "purple4", size = 1, alpha = 0.6) +
  scale_shape_manual(values = c(2, 4, 8)) +
  labs(
    title = "Volcanoes\nof the World",
    caption = "Source: Smithsonian Institution · Graphic: Georgios Karamanis",
    shape = "Evidence for volcanic eruption"
  ) +
  theme_void(base_family = "Outfit") +
  theme(
    legend.position = c(0.875, 0.925),
    plot.background = element_rect(fill = "grey97", color = NA),
    plot.title = element_text(margin = margin(20, 0, -70, 0), hjust = 0.045, size = 26, face = "bold"),
    plot.caption = element_text(margin = margin(-30, 0, 0, 20), hjust = 0.98)
  )
