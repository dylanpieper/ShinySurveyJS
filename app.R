# Install pacman (package manager)
if (!require(pacman)) install.packages("pacman")

# Install/load required packages
pacman::p_load(shiny, jsonlite, shinyjs, httr)

# Source shiny functions
source("shiny/survey.R")
source("shiny/messages.R")

# Define the UI
ui <- fluidPage(
  useShinyjs(),
  messageUI(),
  div(id = "surveyContainer",
      surveyUI("survey", theme = "modern")
  ),
  tableOutput("surveyData")
)

# Define the server
server <- function(input, output, session) {
  # Global logic for activating the URL encryption
  encrypt_active <- TRUE
  
  if(encrypt_active){
    # Read encrypt.csv at the start of the session
    encrypt_local <- reactiveVal(read.csv("encrypt.csv"))
    # Use the new function to handle URL parameters
    handle_url_parameters(session, encrypt_local)
  }else{
    handle_url_parameters_encryptless(session, encrypt_local)
  }
  
  survey_data <- surveyServer(input, output, session, encrypt_active)
}

# Run app
shinyApp(ui = ui, server = server)