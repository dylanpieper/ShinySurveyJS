# Install pacman (package manager)
if (!require(pacman)) install.packages("pacman")

# Install/load required packages
pacman::p_load(shiny, jsonlite, shinyjs)

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
  # Read hash.csv at the start of the session
  hash_local <- reactiveVal(read.csv("hash.csv"))
  
  # Use the new function to handle URL parameters
  handle_url_parameters(session, hash_local)
  
  survey_data <- surveyServer(input, output, session)
}

# Run app
shinyApp(ui = ui, server = server)