library(dplyr)
library(sf)

dated_woods_raw <- read.csv("./data/belab1.csv",
                            header = T,
                            stringsAsFactors = F,
                            sep = ";")
wood_list_raw <- read.csv("./data/Gesamtholzliste_Bielersee_resave.csv",
                          na.strings = c("-","---", "----"), header=T,
                          stringsAsFactors = F, sep=",",
                          fileEncoding="utf8") #%>% enc2utf8()

wood_list <- wood_list_raw %>%
  dplyr::select(Gemeinde,Flur,DNr,Qf,Fo,xLK,yLK,xLK95,yLK95) %>%
  dplyr::rename(Nr = DNr) %>%
  dplyr::mutate(Nr = as.integer(Nr), Qf = as.integer(Qf), Fo = as.integer(Fo)) %>%
  dplyr::mutate(xLK = as.numeric(xLK), yLK = as.numeric(yLK), xLK95 = as.numeric(xLK95), yLK95 = as.numeric(yLK95)) %>%
  dplyr::filter(!is.na(Nr))

LK95 <- wood_list %>%
  dplyr::filter(!is.na(xLK95))

dated_woods <- dated_woods_raw %>%
  dplyr::filter(!is.na(Dat)) %>%
  dplyr::select(Nr,Dat,Sp_Dat, Wk_Dat,WK,Sp,Anz,Ma,Art,Titel) %>%
  dplyr::mutate(wood_type = case_when(
    !is.na(Sp_Dat) ~ "Sp",
    !is.na(Wk_Dat) ~ "Wk",
    TRUE ~ "Ke"
  )) %>%
  dplyr::mutate(Dat = case_when(
    !is.na(Sp_Dat) ~ Sp_Dat,
    !is.na(Wk_Dat) ~ Wk_Dat,
    TRUE ~ Dat
  )) %>%
  dplyr::mutate(Titel = as.character(Titel)) %>%
  dplyr::select(-one_of(c('Sp_Dat', 'Wk_Dat')))

dated_woods$WK <- as.integer(dated_woods$WK)
#levels(dated_woods$WK) <- sub("^>[0-9]{1,3}", "",levels(dated_woods$WK))

combined_coordsLK95_dates <- dplyr::left_join(dated_woods,LK95,by="Nr") %>% filter(!is.na(yLK95))

# Create an sf object with the CH95 projection
spatial_data_LK95 <- st_as_sf(combined_coordsLK95_dates, 
                              coords = c("xLK95", "yLK95"), 
                              crs = 2056,
                              remove = FALSE)

# Transform to WGS84:
spatial_data_LK95 <- st_transform(spatial_data_LK95, 4326)

# Remove the original coordinate columns that were kept with remove = FALSE
# to match the original script's behavior (which excluded columns 13,14,15,16)
spatial_data_LK95 <- spatial_data_LK95 %>%
  select(-c(xLK, yLK, xLK95, yLK95))

# Before saving, ensure UTF-8 encoding
char_cols <- names(spatial_data_LK95)[sapply(st_drop_geometry(spatial_data_LK95), is.character)]
for(col in char_cols) {
  spatial_data_LK95[[col]] <- iconv(spatial_data_LK95[[col]], from = "latin1", to = "UTF-8", sub = "")
}

saveRDS(spatial_data_LK95, file="./PrehistoricSeeland/data/woods_sp.Rds")
