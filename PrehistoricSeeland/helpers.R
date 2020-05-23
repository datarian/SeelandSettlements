library(dplyr)
library(sp)
library(leaflet)

# Prepare data:
spatial_data <- readRDS("./data/woods_sp.Rds") # Read spdataframe
spatial_data$alpha <- rep(0,nrow(spatial_data))

min_yr <- min(spatial_data$Dat) - 5
max_yr <- max(spatial_data$Dat) + 5

WK_PREFIX = "wk_"
SP_PREFIX = "sp_"
KE_PREFIX = "ke_"

colorWood <- colorFactor(palette=c("#000000", "#ffcc00", "#9d5152"),levels=c("Wk","Sp", "Ke"))

calcAlpha <- function(currentYear, sampleYear){
    difference <- (currentYear - sampleYear)
    alpha <- ifelse(difference < 10, (10 - difference)/10,0)
}

clusterCreateFunction <- JS("function (cluster) {
    var childCount = cluster.getChildCount();
    
    var c = ' marker-cluster-custom';
    
    return new L.DivIcon({ html: '<div><span>' + childCount + '</span></div>', className: 'marker-cluster' + c, iconSize: new L.Point(40, 40) });
}")


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

        year_markers = spatial_data[spatial_data$Dat %in% (y-10):y,]
        year_markers_wk = year_markers[year_markers$wood_type == "Wk",]
        year_markers_sp = year_markers[year_markers$wood_type == "Sp",]
        year_markers_ke = year_markers[year_markers$wood_type == "Ke",]

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
                                            fillColor = ~colorWood("Wk"),
                                            radius = 5,
                                            label = ~Titel,
                                            clusterOptions = markerClusterOptions(
                                                spiderfyOnMaxZoom = F,
                                                disableClusteringAtZoom = 19,
                                                zoomToBoundsOnClick = T,
                                                iconCreateFunction = clusterCreateFunction))
            hideGroup(map, g_wk)
        }
        if(nrow(year_markers_sp) > 0){
            g_sp = paste0(SP_PREFIX, g)
            all_groups <- append(all_groups, g_sp)
            for (i in 1:nrow(year_markers_sp)) {
                year_markers_sp$alpha[i] <- calcAlpha(y, year_markers_sp$Dat[i])
            }
            map <- map %>% addCircleMarkers(data=year_markers_sp,
                                            stroke=FALSE,
                                            group = g_sp,
                                            fillOpacity=~alpha,
                                            fillColor = ~colorWood("Sp"),
                                            radius = 5,
                                            label = ~Titel,
                                            clusterOptions = markerClusterOptions(
                                                spiderfyOnMaxZoom = F,
                                                disableClusteringAtZoom = 19,
                                                zoomToBoundsOnClick = T,
                                                iconCreateFunction = clusterCreateFunction))
            hideGroup(map, g_sp)
        }
        if(nrow(year_markers_ke) > 0){
            g_ke = paste0(KE_PREFIX, g)
            all_groups <- append(all_groups, g_ke)
            for (i in 1:nrow(year_markers_ke)) {
                year_markers_ke$alpha[i] <- calcAlpha(y, year_markers_ke$Dat[i])
            }
            map <- map %>% addCircleMarkers(data=year_markers_ke,
                                            stroke=FALSE,
                                            group = g_ke,
                                            fillOpacity=~alpha,
                                            fillColor = ~colorWood("Ke"),
                                            radius = 5,
                                            label = ~Titel,
                                            clusterOptions = markerClusterOptions(
                                                spiderfyOnMaxZoom = F,
                                                disableClusteringAtZoom = 19,
                                                zoomToBoundsOnClick = T,
                                                iconCreateFunction = clusterCreateFunction))
            hideGroup(map, g_ke)
        }
    }
    results <- list("all_groups" = all_groups, "map" = map)
    return(results)
}
