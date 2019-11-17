library(dplyr)
library(sp)

# Prepare data:
spatial_data <- readRDS("./data/woods_sp.Rds") # Read spdataframe
spatial_data$alpha <- rep(0,nrow(spatial_data))

min_yr <- min(spatial_data$Dat) - 5
max_yr <- max(spatial_data$Dat) + 5

WK_PREFIX = "wk_"
NWK_PREFIX = "nwk_"

colorWood <- colorFactor(palette='Spectral',levels=c(0,1))

calcAlpha <- function(currentYear, sampleYear){
    difference <- (currentYear - sampleYear)
    alpha <- ifelse(difference < 10, (10 - difference)/10,0)
}


# Initialize map and build up all layers and groups

prepareMap <- function(spatial_data){

    center_lng <- mean(spatial_data@coords[,1])
    center_lat <- mean(spatial_data@coords[,2])

    min_yr <- min(spatial_data$Dat) - 5
    max_yr <- max(spatial_data$Dat) + 5

    all_groups <- c()

    map <- leaflet(options = leafletOptions(maxZoom = 20)) %>%
        addProviderTiles(providers$Stamen.TonerLite,
                         options = providerTileOptions(noWrap = TRUE)
        ) %>%
        setView(lng = center_lng, lat = center_lat,zoom=10)

    for (y in min_yr:max_yr){

        year_markers = spatial_data[spatial_data$Dat %in% (y-10):y, ]
        year_markers_wk = year_markers[!is.na(year_markers$WK),]
        year_markers_nwk = year_markers[is.na(year_markers$WK),]

        g = as.character(y)

        if(nrow(year_markers_wk) > 0){
            g_wk = paste0(WK_PREFIX, g)
            all_groups <- append(all_groups, g_wk)
            for (i in 1:nrow(year_markers_wk)) {
                year_markers_wk$alpha[i] <- calcAlpha(y, year_markers_wk$Dat[i])
            }
            map <- map %>% addCircleMarkers(data=year_markers_wk,
                                            stroke=FALSE,
                                            group = g_wk,
                                            fillOpacity=~alpha,
                                            fillColor = ~colorWood(as.numeric(!is.na(WK))),
                                            radius = ~alpha*5,
                                            label = ~Titel,
                                            clusterOptions = markerClusterOptions(
                                                spiderfyOnMaxZoom = F,
                                                disableClusteringAtZoom = 19,
                                                zoomToBoundsOnClick = T))
            hideGroup(map, g_wk)
        }
        if(nrow(year_markers_nwk) > 0){
            g_nwk = paste0(NWK_PREFIX, g)
            all_groups <- append(all_groups, g_nwk)
            for (i in 1:nrow(year_markers_nwk)) {
                year_markers_nwk$alpha[i] <- calcAlpha(y, year_markers_nwk$Dat[i])
            }
            map <- map %>% addCircleMarkers(data=year_markers_nwk,
                                            stroke=FALSE,
                                            group = g_nwk,
                                            fillOpacity=~alpha,
                                            fillColor = ~colorWood(as.numeric(!is.na(WK))),
                                            radius = ~alpha*5,
                                            label = ~Titel,
                                            clusterOptions = markerClusterOptions(
                                                spiderfyOnMaxZoom = F,
                                                disableClusteringAtZoom = 19,
                                                zoomToBoundsOnClick = T))
            hideGroup(map, g_nwk)
        }
    }
    results <- list("all_groups" = all_groups, "map" = map)
    return(results)
}
