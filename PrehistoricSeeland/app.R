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
  absolutePanel(
    id = "year_display",
    class = "draggable-year",
    fixed = TRUE,
    top = "10px",
    right = "10px",
    textOutput("current_year_display"),
    div(id = "year_input_container", style = "display: none;",
      tags$input(type = "text", id = "year_jump_input", placeholder = "-3500", 
                 style = "font-size: 2.2em; font-weight: 700; text-align: center; 
                         background: rgba(255,255,255,0.95); border: 2px solid #007bff; 
                         border-radius: 8px; padding: 8px 12px; color: #2c3e50; 
                         width: 120px; outline: none;")
    )
  ),
  leafletOutput("map", width = "100%", height = "100%"),
  absolutePanel(
    id = "controls",
    class = "panel panel-default",
    fixed = TRUE,
    draggable = TRUE,
    top = "auto",
    right = "2%",
    left = "2%",
    bottom = "10",
    width = "96%",
    height = "auto",
    
    div(class = "container-fluid",
      div(class = "row align-items-center",
        # Year slider section
        div(class = "col-md-5",
          div(class = "control-section",
            div(class = "slider-container",
              uiOutput("year_range"),
              div(id = "animation_controls",
                div(id = "play_pause_container"),
                div(id = "manual_controls", style = "display: none;",
                  actionButton("year_back", "", icon = icon("chevron-left"), 
                               class = "btn btn-secondary control-btn"),
                  actionButton("year_forward", "", icon = icon("chevron-right"), 
                               class = "btn btn-secondary control-btn")
                )
              )
            )
          )
        ),
        
        # Speed control section  
        div(class = "col-md-3",
          div(class = "control-section",
            sliderInput(
              "speed",
              "Geschwindigkeit",
              min = 1,
              max = 10,
              value = 1,
              step = 1,
              ticks = F
            )
          )
        ),
        
        # Wood selection section
        div(class = "col-md-4",
          div(class = "control-section text-right",
            uiOutput("select_wood")
          )
        )
      )
    )
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
      value = isolate(input$year) %||% (min_yr+1),
      step = 1,
      sep = "'",
      animate = animationOptions(
        interval = 2000,  # Start with default speed
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
    # Calculate new speed using exponential scaling for better distribution
    new_speed <- 2000 * (0.7 ^ (input$speed - 1))
    
    # Send speed update to JavaScript
    session$sendCustomMessage('update_animation_speed', list(speed = new_speed))
  })
  
  output$current_year_display <- renderText({
    if(is.null(input$year)) {
      as.character(min_yr)
    } else {
      as.character(input$year)
    }
  })
  
  # Handle manual year navigation
  observeEvent(input$year_forward, {
    current_year <- input$year %||% (min_yr + 1)
    new_year <- if(current_year >= max_yr) min_yr else current_year + 1
    updateSliderInput(session, "year", value = new_year)
  })
  
  observeEvent(input$year_back, {
    current_year <- input$year %||% (min_yr + 1)
    new_year <- if(current_year <= min_yr) max_yr else current_year - 1
    updateSliderInput(session, "year", value = new_year)
  })
  
  # Handle year jumping from custom message
  observeEvent(input$year_jump_value, {
    year_value <- input$year_jump_value
    if (!is.null(year_value) && !is.na(year_value)) {
      # Clamp the value to the valid range
      clamped_year <- max(min_yr, min(max_yr, year_value))
      updateSliderInput(session, "year", value = clamped_year)
      
      # Send message to hide input
      session$sendCustomMessage('hide_year_input', TRUE)
    }
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
