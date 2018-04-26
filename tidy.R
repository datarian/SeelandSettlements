library(dplyr)
library(sp)

dated_woods_raw <- read.delim("./data/belab.txt",header = T,stringsAsFactors = F)
wood_list_raw <- read.delim("./data/Gesamtholzliste_Bielersee.txt",
                            na.strings = c("-","---"),header=T,stringsAsFactors = F)


wood_list <- wood_list_raw %>%
    dplyr::filter(!is.na(xLK95)) %>%
    dplyr::select(Gemeinde,Flur,DNr,Qf,Fo,xLK95,yLK95) %>%
    dplyr::rename(Nr = DNr) %>%
    dplyr::mutate(Nr = as.integer(Nr)) %>%
    dplyr::filter(!is.na(Nr))

dated_woods <- dated_woods_raw %>%
    dplyr::filter(!is.na(Dat)) %>%
    dplyr::select(Nr,Dat,WK,Sp,Anz,Ma,Art,Titel) %>%
    dplyr::mutate(Titel = as.character(Titel))

dated_woods$WK <- as.integer(dated_woods$WK)
#levels(dated_woods$WK) <- sub("^>[0-9]{1,3}", "",levels(dated_woods$WK))

combined_coords_dates <- dplyr::left_join(dated_woods,wood_list,by="Nr") %>% filter(!is.na(xLK95))
summary(combined_coords_dates)

# Initialize a spatial points object with the CH95 projection
coords <- SpatialPoints(cbind(combined_coords_dates$xLK95,combined_coords_dates$yLK95), proj4string = CRS("+init=epsg:2056"))

#Transform to WGS84:
coords <- spTransform(spatial_object, CRS("+init=epsg:4326"))

# Combine to a spdataframe together with the attributes
spatial_data <- SpatialPointsDataFrame(coords,
                                       combined_coords_dates[,-c(13,14)])

saveRDS(spatial_data,file="PrehistoricSeeland/data/woods_sp.Rds")


# LK95WGS_lat <- function (y, x){
#
#     y_aux <- (y -  2600000)/1000000
#     x_aux <- (x - 1200000)/1000000
#
#     ## Process lat
#     lat <- {16.9023892 +
#             3.238272 * x_aux -
#             0.270978 * (y_aux^2) -
#             0.002528 * (x_aux^2) -
#             0.0447   * (y_aux^2) * x_aux -
#             0.0140   * (x_aux^3)}
#     lat <- lat * 100/36
#     return(lat)
# }
#
# LK95WGS_lng <- function (y, x){
#
#     y_aux <- (y - 2600000)/1000000
#     x_aux <- (x - 1200000)/1000000
#
#     ## Process long
#     lng <- {2.6779094 +
#             4.728982 * y_aux +
#             0.791484 * y_aux * x_aux +
#             0.1306   * y_aux * (x_aux^2) -
#             0.0436   * (y_aux^3)}
#     lng <- lng * 100/36
#     return(lng)
# }
#
# combined_coords_dates$lat <- LK95WGS_lat(combined_coords_dates$xLK95,
#                                            combined_coords_dates$yLK95)
# combined_coords_dates$lng <- LK95WGS_lng(combined_coords_dates$xLK95,
#                                            combined_coords_dates$yLK95)
# combined_coords_dates <- combined_coords_dates %>% dplyr::select(-xLK95,-yLK95)
#
#
#
# saveRDS(combined_coords_dates, file = "./PrehistoricSeeland/data/wood.Rds")
