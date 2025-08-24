library(shiny)
library(leaflet)
library(shinyjs)
library(logging)
library(htmltools)
library(shinythemes)

source("helpers.R")

init <- prepareMap(spatial_data)

# Define UI for application that draws a histogram
ui <- fillPage(
  theme = shinytheme("cosmo"),
  useShinyjs(),
  tags$head(
    singleton(tags$script(src = 'shiny-events.js'))),
  includeCSS("www/custom.css"),
  titlePanel("Prehistoric Seeland Settlements in Time"),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(
    id = "controls",
    class = "panel panel-default row align-items-center",
    fixed = TRUE,
    draggable = TRUE,
    top = "auto",
    right = "2%",
    left = "2%",
    bottom = "10",
    width = "96%",
    height = "8em",
    div(class="col-sm-6",
      uiOutput("year_range")),
    div(class="col-sm-3",
    sliderInput(
      "speed",
      "Geschwindigkeit der Animation",
      min = 1,
      max = 10,
      value = 1,
      step = 2,
      ticks = F
    )),
    div(class="col-sm-3",
      uiOutput("select_wood"))
  )
)


server <- shinyServer(function(input, output, session) {
  output$map <- renderLeaflet(init$map)
  
  # update animation interval
  animation <- reactiveValues(speed = 100, year = min_yr)

  output$year_range <- renderUI({
    sliderInput(
      "year",
      "Zeit",
      min = min_yr,
      max = max_yr,
      value = min_yr+1,
      step = 1,
      sep = "'",
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


  observeEvent(input$speed, {
    invalidateLater(500, session)
    animation$speed <- 1000 / input$speed
    animation$year <- input$year
  })

  observeEvent(input$speed, {
    session$sendCustomMessage('resume', TRUE)
  })
  
  output$select_wood <- renderUI({
    checkboxGroupInput(
      "wood_type",
      label = "Holzauswahl",
      choiceNames = list(
        HTML("Waldkante <span class='dot' style='background-color: #000000'></span>"),
        HTML("Splintholz <span class='dot' style='background-color: #ffcc00'></span>"),
        HTML("Kernholz <span class='dot' style='background-color: #9d5152'></span>")
      ),
      choiceValues = list(
        "Wk",
        "Sp",
        "Ke"
      ),
      selected = c("Wk", "Sp")
    )
  })

  speedChange <- eventReactive(input$speed, {
    1000 / input$speed
  })

  # Each independent set of things that can change
  # should be managed in its own observer.
  observeEvent(input$year, {
    g_wk <- paste0(WK_PREFIX, as.character(input$year))
    g_sp <- paste0(SP_PREFIX, as.character(input$year))
    g_ke <- paste0(KE_PREFIX, as.character(input$year))
    hide_groups <-
      init$all_groups[!init$all_groups %in% c(g_wk, g_sp, g_ke)]
    
    if("Wk" %in% input$wood_type) {
      if (g_wk %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_wk)
      }
    } else {
      hide_groups <- c(hide_groups, g_wk)
    }
    
    if("Sp" %in% input$wood_type) {
      if (g_sp %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_sp)
      }
    } else {
      hide_groups <- c(hide_groups, g_sp)
    }
    
    if("Ke" %in% input$wood_type) {
      if (g_ke %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_ke)
      }
    } else {
      hide_groups <- c(hide_groups, g_ke)
    }
    leafletProxy("map") %>%
      hideGroup(hide_groups)
  })
  
  observeEvent(input$wood_type, {
    g_wk <- paste0(WK_PREFIX, as.character(input$year))
    g_sp <- paste0(SP_PREFIX, as.character(input$year))
    g_ke <- paste0(KE_PREFIX, as.character(input$year))
    
    hide_groups <-
      init$all_groups[!init$all_groups %in% c(g_wk, g_sp, g_ke)]
    
    if("Wk" %in% input$wood_type) {
      if (g_wk %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_wk)
      }

    } else {
      hide_groups <- c(hide_groups, g_wk)
    }
    if("Sp" %in% input$wood_type) {
      if (g_sp %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_sp)
      }
    } else {
      hide_groups <- c(hide_groups, g_sp)
    }
    
    if("Ke" %in% input$wood_type) {
      if (g_ke %in% init$all_groups) {
        leafletProxy("map") %>%
          showGroup(g_ke)
      }
    } else {
      hide_groups <- c(hide_groups, g_ke)
    }
    leafletProxy("map") %>%
      hideGroup(hide_groups)
  })
})


shinyApp(ui, server)
