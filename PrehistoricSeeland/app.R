library(shiny)
library(leaflet)
library(shinyjs)
library(logging)
library(htmltools)

source("helpers.R")

init <- prepareMap(spatial_data)

# Define UI for application that draws a histogram
ui <- fillPage(
  useShinyjs(),
  tags$head(tags$style(
    HTML(
      '
       #controls {background-color: rgba(255,255,255,0.8);
                  padding: 4em;
                  z-index:2000;}
       .glyphicon {font-size: 2em;}'
    )
  )),
  tags$head(singleton(tags$script(src = 'shiny-events.js'))),
  titlePanel("Prehistoric Seeland settlements in time"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(
    id = "controls",
    class = "panel panel-default",
    fixed = TRUE,
    draggable = TRUE,
    top = 60,
    left = "auto",
    right = 20,
    bottom = "auto",
    width = 330,
    height = "auto",
    uiOutput("year_range"),
    br(),
    sliderInput(
      "speed",
      "Geschwindigkeit der Animation",
      min = 1,
      max = 10,
      value = 1,
      step = 2,
      ticks = F
    ),
    br(),
    uiOutput("select_wood"),
    br()
  )
)


server <- shinyServer(function(input, output, session) {
  output$map <- renderLeaflet(init$map)

  output$year_range <- renderUI({
    sliderInput(
      "year",
      "Zeit",
      min = min_yr,
      max = max_yr,
      value = isolate(animation$year),
      step = 1,
      animate = animationOptions(
        interval = animation$speed,
        loop = T,
        playButton = HTML(
          '<span class="play">
             <i class="glyphicon glyphicon-play"></i>
           </span>'
        ),
        pauseButton = HTML(
          '<span class="pause">
             <i class="glyphicon glyphicon-pause"></i>
           </span>'
        )
      )
    )
  })

  # update animation interval
  animation <- reactiveValues(speed = 100, year = min_yr)

  observeEvent(input$speed, {
    invalidateLater(500, session)
    animation$speed <- 1000 / input$speed
    animation$year <- input$year
  })

  observeEvent(input$speed, {
    session$sendCustomMessage('resume', TRUE)
  })

  output$select_wood <- renderUI({
    radioButtons(
      "wood_type",
      label = "Holzauswahl",
      choices = list(
        "Alle" = 1,
        "Waldkante" = 2,
        "Splintholz" = 3
      ),
      selected = 1
    )
  })

  speedChange <- eventReactive(input$speed, {
    1000 / input$speed
  })

  # Each independent set of things that can change
  # should be managed in its own observer.
  observeEvent(input$year, {
    g_wk <- paste0(WK_PREFIX, as.character(input$year))
    g_nwk <- paste0(NWK_PREFIX, as.character(input$year))
    hide_groups <-
      init$all_groups[!init$all_groups %in% c(g_wk, g_nwk)]
    if (g_wk %in% init$all_groups) {
      leafletProxy("map") %>%
        showGroup(g_wk)
    }
    if (g_nwk %in% init$all_groups) {
      leafletProxy("map") %>%
        showGroup(g_nwk)
    }
    leafletProxy("map") %>%
      hideGroup(hide_groups)
  })
  
  observeEvent(input$wood_type, {
    g_wk <- paste0(WK_PREFIX, as.character(input$year))
    g_nwk <- paste0(NWK_PREFIX, as.character(input$year))
    
    hide_groups <-
      init$all_groups[!init$all_groups %in% c(g_wk, g_nwk)]
    
    if(input$wood_type == 2) {
      if (g_nwk %in% init$all_groups) {
        leafletProxy("map") %>%
          hideGroup(g_nwk)
      }
      if (g_wk %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_wk)
      }  
    } else if(input$wood_type == 3) {
      if (g_nwk %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_nwk)
      }
      if (g_wk %in% init$all_groups) {
        leafletProxy("map") %>%
          hideGroup(g_wk)
      }
    } else {
      if (g_wk %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_wk)
      }
      if (g_nwk %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_nwk)
      }
    }
    leafletProxy("map") %>%
      hideGroup(hide_groups)
  })
})

shinyApp(ui, server)
