# Install pacman (package manager)
if (!require(pacman)) install.packages("pacman")

# Install/load required packages
pacman::p_load(shiny, jsonlite, shinyjs, arrow)

# Source shiny functions
source("shiny/survey.R")

# Define UI
ui <- fluidPage(
  useShinyjs(), # Initialize shinyjs
  div(id = "waitingMessage", "ShinySurveyJS server is online. Define a survey in the URL query parameter."),
  surveyUI("survey", theme = "modern"),
  tableOutput("surveyData") # Add a table output
)

# Define server logic
server <- function(input, output, session) {
  # Initialize reactive values
  values <- reactiveValues(surveyDefined = FALSE)
  
  # Check URL parameters at the start
  observe({
    query <- parseQueryString(session$clientData$url_search)
    if (!is.null(query$survey)) {
      values$surveyDefined <- TRUE
    }
  })
  
  # Hide the waiting message when a survey is defined
  observe({
    if (values$surveyDefined) {
      shinyjs::hide("waitingMessage")
    }
  })
  
  survey_data <- surveyServer(input, output, session)
}

# Run app
shinyApp(ui = ui, server = server)