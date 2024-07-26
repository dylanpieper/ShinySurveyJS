# Add required packages
if (!require(pacman)) install.packages("pacman")
pacman::p_load(shiny, jsonlite, shinydashboard, shinyjs)

# Source survey.R
source("shiny/survey_dashboard.R")

# UI
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Survey Dashboard"),
  
  # Sidebar
  dashboardSidebar(
    selectInput("survey", "Choose a survey:", choices = list.files("www/", pattern = "*.json", full.names = FALSE)),
    textInput("paramName", "Enter URL parameter name:", value = ""),
    textInput("paramValue", "Enter URL parameter value:", value = ""),
    actionButton("generateURL", "Generate URL"),
    uiOutput("displayURL")
  ),
  
  # Body
  dashboardBody(
    useShinyjs(),
    fluidRow(
      surveyUI("survey", theme = "modern"), 
      tableOutput("surveyData")
    ),
    tags$script('
      Shiny.addCustomMessageHandler("reloadWithURL", function(url) {
        window.location.href = url;
      });
    ')
  )
)

# Server
server <- function(input, output, session) {
  
  survey_data <- surveyServer(input, output, session)
  
  # Reactive value to store the generated URL
  generated_url <- reactiveVal("")
  
  observeEvent(input$generateURL, {
    param <- paste(input$paramName, input$paramValue, sep = "=")
    surveyParam <- paste("survey", input$survey, sep = "=")
    
    # Get the current URL without query parameters
    base_url <- session$clientData$url_protocol
    base_url <- paste0(base_url, "//", session$clientData$url_hostname)
    if (!is.null(session$clientData$url_port) && session$clientData$url_port != "") {
      base_url <- paste0(base_url, ":", session$clientData$url_port)
    }
    base_url <- paste0(base_url, session$clientData$url_pathname)
    
    # Construct the new URL
    url <- paste0(base_url, "?", surveyParam, "&", param)
    
    # Store the generated URL
    generated_url(url)
    
    # Display the URL
    output$displayURL <- renderUI({
      tagList(
        h4("Generated URL:"),
        verbatimTextOutput("url"),
        actionButton("openURL", "Open URL")
      )
    })
    
    output$url <- renderText({ url })
  })
  
  observeEvent(input$openURL, {
    # Use the stored URL to reload the page
    session$sendCustomMessage("reloadWithURL", generated_url())
  })
  
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if ("survey" %in% names(query)) {
      updateSelectInput(session, "survey", selected = query$survey)
    }
    if (length(query) > 1) {
      updateTextInput(session, "paramName", value = names(query)[2])
      updateTextInput(session, "paramValue", value = query[[2]])
    }
  })
}

shinyApp(ui = ui, server = server)