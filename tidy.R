library(dplyr)
library(sp)

dated_woods_raw <- read.csv("./data/belab.csv",
                            header = T,
                            stringsAsFactors = F,
                            sep = ";")
wood_list_raw <- read.csv("./data/Gesamtholzliste_Bielersee.csv",
                            na.strings = c("-","---", "----"), header=T,
                            stringsAsFactors = F, sep=";",
                            fileEncoding="utf8") # %>% enc2utf8()

wood_list <- wood_list_raw %>%
    dplyr::select(Gemeinde,Flur,DNr,Qf,Fo,xLK,yLK,xLK95,yLK95) %>%
    dplyr::rename(Nr = DNr) %>%
    dplyr::mutate(Nr = as.integer(Nr), Qf = as.integer(Qf), Fo = as.integer(Fo)) %>%
    dplyr::mutate(xLK = as.numeric(xLK), yLK = as.numeric(yLK), xLK95 = as.numeric(xLK95), yLK95 = as.numeric(yLK95)) %>%
    dplyr::filter(!is.na(Nr))

LK95 <- wood_list %>%
    dplyr::filter(!is.na(xLK95))

LK95nrs <- LK95$Nr

LK03 <- wood_list %>%
    dplyr::filter(!is.na(xLK)) %>%
    dplyr::filter(!Nr %in% LK95nrs)

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

combined_coordsLK03_dates <- dplyr::left_join(dated_woods,LK03,by="Nr") %>% filter(!is.na(yLK))
combined_coordsLK95_dates <- dplyr::left_join(dated_woods,LK95,by="Nr") %>% filter(!is.na(yLK95))

# Initialize a spatial points object with the CH95 projection
coordsLK95 <- SpatialPoints(cbind(combined_coordsLK95_dates$xLK95,combined_coordsLK95_dates$yLK95), proj4string = CRS("+init=epsg:2056"))
coordsLK03 <- SpatialPoints(cbind(combined_coordsLK03_dates$xLK,combined_coordsLK03_dates$yLK), proj4string = CRS("+init=epsg:21781"))

#Transform to WGS84:
coords95 <- spTransform(coordsLK95, CRS("+init=epsg:4326"))
coords03 <- spTransform(coordsLK03, CRS("+init=epsg:4326"))

# Combine to a spdataframe together with the attributes
spatial_data_LK95 <- SpatialPointsDataFrame(coords95,
                                       combined_coordsLK95_dates[,-c(13,14,15,16)])
spatial_data_LK03 <- SpatialPointsDataFrame(coords03,
                                            combined_coordsLK03_dates[,-c(13,14,15,16)])

spatial_data <- rbind(spatial_data_LK95,spatial_data_LK03)

saveRDS(spatial_data,file="./PrehistoricSeeland/data/woods_sp.Rds")
