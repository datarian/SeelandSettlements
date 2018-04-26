library(shiny)
library(leaflet)
library(dplyr)
library(shinyjs)
library(logging)
library(htmltools)
library(sp)

# Define UI for application that draws a histogram
ui <- shinyUI(
    fillPage(
        tags$head(tags$style(
            HTML('
             #controls {background-color: rgba(255,255,255,0.8);
                        padding: 4em;
                        z-index:2000;}'
            ))),
        titlePanel("Prehistoric Seeland settlements in time"),

        leafletOutput("map", width="100%", height="100%"),

        absolutePanel(id = "controls", class = "panel panel-default",
                      fixed = TRUE, draggable = TRUE, top = 60,
                      left = "auto", right = 20, bottom = "auto",
                      width = 330, height = "auto",
                      uiOutput("year_range"),
                      br(),
                      uiOutput("speed_value"))
    ))

# Prepare data:
spatial_data <- readRDS("./data/woods_sp.Rds") # Read spdataframe
spatial_data$show <- rep(0,nrow(spatial_data))

display <- spatial_data[FALSE,] # initialize empty display data.frame
min_yr <- min(spatial_data$Dat)
max_yr <- max(spatial_data$Dat)

center_lng <- mean(spatial_data@coords[,1])
center_lat <- mean(spatial_data@coords[,2])

server <- shinyServer(function(input, output, session) {


    adjustDisplay <- function(d){
        d$show <- ifelse(d$show > 0.1, d$show-0.1, d$show)
    }

    markers <- eventReactive(input$year,{
        req(input$year)

        if(nrow(display) > 0){
            apply(display@data, 1, adjustDisplay)
        }

        if(nrow(display) > 0){
            display <- adjustDisplay(display)
        }

        newDisplay <- spatial_data[spatial_data$Dat == input$year,]
        if(nrow(newDisplay) > 0){
            newDisplay$show <- 1.0 # set show to initial value
            display <- rbind(display,newDisplay)
        }

        display
    })

    speedChange <- eventReactive(input$speed,{
        print(input$speed)
        1000/input$speed
    })

        output$year_range <- renderUI({
            sliderInput("year",
                        "Time range",
                        min = min_yr,
                        max = max_yr,
                        value = min_yr,
                        step = 1,
                        animate = animationOptions(interval = speedChange(),
                                                   loop = T))
        })

    output$speed_value <- renderUI({
        sliderInput("speed",
                    "Animation speed multiplier",
                    min = 1,
                    max= 5,
                    value = 1)
    })

    output$map <- renderLeaflet({
        leaflet() %>%
            addProviderTiles(providers$Stamen.TonerLite,
                             options = providerTileOptions(noWrap = TRUE)
            ) %>%
            setView(lng = center_lng, lat = center_lat,zoom=12)
            #fitBounds(sp::bbox(spatial_data)[1,1],sp::bbox(spatial_data)[1,2],
                      #sp::bbox(spatial_data)[2,1],sp::bbox(spatial_data)[2,2])
    })

    # Each independent set of things that can change
    # should be managed in its own observer.
    observe({
        leafletProxy("map", data = markers()) %>%
            clearMarkers() %>%
            clearMarkerClusters() %>%
            addCircleMarkers(stroke=FALSE,
                             #lat = ~lat,
                             #lng = ~lng,
                             fillOpacity=~show,
                             fillColor = ~ifelse(is.na(WK),"#C33","#096"),
                             radius = 5,
                             clusterOptions = markerClusterOptions(
                                 spiderfyOnMaxZoom = T,
                                 zoomToBoundsOnClick = T))
    })
})

shinyApp(ui, server)