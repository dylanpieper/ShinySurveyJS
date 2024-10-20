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
  # Global logic for activating the URL token
  token_active <- TRUE
  
  if(token_active){
    # Read token.csv at the start of the session
    token_local <- reactiveVal(read.csv("token.csv"))
    # Use the new function to handle URL parameters
    handle_url_parameters(session, token_local)
  }else{
    handle_url_parameters_tokenless(session, token_local)
  }
  
  survey_data <- surveyServer(input, output, session, token_active)
}

# Run app
shinyApp(ui = ui, server = server)