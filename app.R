# Install pak (package manager)
# if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")

# Install required packages
# pak::pkg_install(c("shiny", "jsonlite", "shinyjs", "httr", "DBI", "RPostgres", "yaml"))

# Load required packages
library(shiny)
library(jsonlite)
library(shinyjs)
library(httr)
library(DBI)
library(RPostgres)
library(yaml)

# Source shiny functions
source("shiny/survey.R")
source("shiny/messages.R")
source("shiny/database.R")

# Setup database tables
setup_database()

# Define UI
ui <- fluidPage(
  useShinyjs(),
  messageUI(),
  div(id = "surveyContainer",
      surveyUI("survey", theme = "modern")
  ),
  tableOutput("surveyData")
)

# Define server
server <- function(input, output, session) {
  # Global logic for activating URL token
  token_active <- TRUE
  
  if(token_active){
    # Read tokens at start of session
    token_table <- read_table("tokens")
    token_reactive <- reactiveVal(token_table)
    
    # Handle URL parameters with tokens
    handle_url_parameters(session, token_reactive)
    
    # Run survey server with tokens
    survey_data <- surveyServer(input, output, session, token_active, token_table)
  }else{
    # Handle URL parameters without tokens
    handle_url_parameters_tokenless(session, token_reactive)
    
    # Run survey server without tokens
    survey_data <- surveyServer(input, output, session, token_active)
  }
}

# Run app
shinyApp(ui = ui, server = server)