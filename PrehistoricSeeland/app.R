library(shiny)
library(leaflet)
library(dplyr)
library(shinyjs)
library(logging)
library(htmltools)
library(sp)

# Prepare data:
spatial_data <- readRDS("./data/woods_sp.Rds") # Read spdataframe
spatial_data$alpha <- rep(0,nrow(spatial_data))


display <- spatial_data[FALSE,] # initialize empty display data.frame
min_yr <- min(spatial_data$Dat)
max_yr <- max(spatial_data$Dat)

center_lng <- mean(spatial_data@coords[,1])
center_lat <- mean(spatial_data@coords[,2])

colorWood <- colorFactor(palette='Spectral',levels=c(0,1))

# Define UI for application that draws a histogram
ui <- shinyUI(
    fillPage(
        tags$head(tags$style(
            HTML('
             #controls {background-color: rgba(255,255,255,0.8);
                        padding: 4em;
                        z-index:2000;}
             .glyphicon {font-size: 2em;}'
            ))),
        titlePanel("Prehistoric Seeland settlements in time"),

        leafletOutput("map", width="100%", height="100%"),

        absolutePanel(id = "controls", class = "panel panel-default",
                      fixed = TRUE, draggable = TRUE, top = 60,
                      left = "auto", right = 20, bottom = "auto",
                      width = 330, height = "auto",
                      uiOutput("year_range"),
                      br(),
                      uiOutput("speed_value"),
                      br(),
                      uiOutput("select_wood"),
                      br())
    ))



server <- shinyServer(function(input, output, session) {

    output$year_range <- renderUI({
        sliderInput("year",
                    "Zeit",
                    min = min_yr,
                    max = max_yr,
                    value = min_yr,
                    step = 1,
                    animate = animationOptions(interval = speedChange(),
                                               loop = T,
                                               playButton = HTML('<span class="play">
                                                                  <i class="glyphicon glyphicon-play"></i>
                                                                  </span>'),
                                               pauseButton = HTML('<span class="pause">
                                                                   <i class="glyphicon glyphicon-pause"></i>
                                                                   </span>')))
    })

    output$speed_value <- renderUI({
        sliderInput("speed",
                    "Geschwindigkeit der Animation",
                    min = 1,
                    max= 5,
                    value = 1)
    })

    output$select_wood <- renderUI({
        radioButtons("wood_type",
                     label = "Holzauswahl",
                     choices = list("Alle" = 1, "Waldkante" = 2, "Splintholz" = 3),
                     selected = 1)
    })

    calcAlpha <- function(currentYear, sampleYear){
        difference <- (currentYear - sampleYear + 1)
        alpha <- ifelse(difference < 10, (10 - difference)/10,0)
    }

    markers <- eventReactive(c(input$year,input$wood_type),{
        req(input$year)
        req(input$wood_type)

        if(nrow(display) > 0){
            for (i in 1:nrow(display)) {
                display$alpha[i] <- calcAlpha(input$year, display$Dat[i])
            }
            display <<- display[display$alpha >= 1e-5,]
        }

        newDisplay <- spatial_data[spatial_data$Dat == input$year &
                                       !(spatial_data$Nr %in% display$Nr),]

        if(nrow(newDisplay) > 0){
            newDisplay$alpha <- 1.0 # set alpha to initial value
            display <<- rbind(display,newDisplay)
        }

        markers <- display

        if(input$wood_type == 2){ # Only show WK woods
            markers <- markers[!is.na(markers$WK),]
        } else if(input$wood_type == 3){ # only show non-WK woods
            markers <- markers[is.na(markers$WK),]
        }

        markers
    })

    speedChange <- eventReactive(input$speed,{
        1000/input$speed
    })



    map <- renderLeaflet({
        leaflet(options = leafletOptions(maxZoom = 20)) %>%
            addProviderTiles(providers$Stamen.TonerLite,
                             options = providerTileOptions(noWrap = TRUE)
            ) %>%
            setView(lng = center_lng, lat = center_lat,zoom=12)
    })

    output$map <- map

    # Each independent set of things that can change
    # should be managed in its own observer.
    observe({
        leafletProxy("map", data = markers()) %>%
            clearMarkers() %>%
            clearMarkerClusters() %>%
            addCircleMarkers(stroke=FALSE,
                             fillOpacity=~alpha,
                             fillColor = ~colorWood(as.numeric(!is.na(WK))),
                             radius = 5,
                             label = ~HTML(paste(sep = "<br />",
                                              span(strong(Titel)),
                                              span(paste0("Nr.: ",Nr)))),
                             clusterOptions = markerClusterOptions(
                                 spiderfyOnMaxZoom = F,
                                 disableClusteringAtZoom = 19,
                                 zoomToBoundsOnClick = T))
    })
})

shinyApp(ui, server)
