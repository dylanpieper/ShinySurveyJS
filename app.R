# ShinySurveyJS app

# if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
# pak::pkg_install(c("shiny", "jsonlite", "shinyjs", "httr", "DBI", "RPostgres", "yaml", "future", "promises"))

library(shiny)
library(jsonlite)
library(shinyjs)
library(httr)
library(DBI)
library(RPostgres)
library(yaml)
library(future)
library(promises)

source("shiny/survey.R")
source("shiny/messages.R")
source("shiny/database.R")

# Initialize the database (run once)
# setup_database("initial")

# Set up future plan for background execution (adjust for your environment)
plan(multisession) # or plan(multicore) on Linux/macOS

ui <- fluidPage(
  useShinyjs(),
  messageUI(),
  div(id = "surveyContainer",
      surveyUI("survey", theme = "modern")
  ),
  tableOutput("surveyData")  # No need for any dynamic feedback in this example
)

server <- function(input, output, session) {
  
  token_active <- TRUE
  
  # Asynchronous database setup triggered at app start (no feedback to user)
  observe({
    if (token_active) {
      token_table <- read_table("tokens")
      token_reactive <- reactiveVal(token_table)
      handle_url_parameters(session, token_reactive)
      survey_data <- surveyServer(input, output, session, token_active, token_table)
      
      # Run setup_database asynchronously in the background
      # Using promises to handle the future's result
      future({
        setup_database("tokens", token_table)
      }) %...>% {
        # Log success message
        message("Database setup completed")
      } %...!% {
        # Log error message if future fails
        message("Error during database setup")
      }
    } else {
      handle_url_parameters_tokenless(session, token_reactive)
      survey_data <- surveyServer(input, output, session, token_active)
    }
  })
}

shinyApp(ui = ui, server = server)
