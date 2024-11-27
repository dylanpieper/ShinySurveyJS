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

# Initialize database (run once)
# setup_database("initial")

# Set up future plan for background execution (adjust for your environment)
plan(multisession) # or plan(multicore) on Linux/macOS

ui <- fluidPage(
  useShinyjs(),
  messageUI(),
  div(id = "surveyContainer",
      surveyUI("survey", theme = "modern")
  ),
  tableOutput("surveyData")
)

server <- function(input, output, session) {
  
  token_active <- TRUE
  
  observe({
    if (token_active) {
      token_table <- read_table("tokens")
      token_reactive <- reactiveVal(token_table)
      handle_url_parameters(session, token_reactive)
      survey_data <- surveyServer(input, output, session, token_active, token_table)
      
      # Run setup_database() asynchronously to speed up app initialization
      # Use promises to gather feedback from future's result
      # This setup process generates any tokens that are missing from the database
      # If new tokens are created, users can access them on the next page load
      future({
        Sys.sleep(2)
        setup_database("tokens", token_table)
      }) %...>% {
        message("Database setup completed")
      } %...!% {
        message("Error during database setup: Remove `future` to view the error message and debug the issue")
      }
    } else {
      handle_url_parameters_tokenless(session, token_reactive)
      survey_data <- surveyServer(input, output, session, token_active)
    }
  })
}

shinyApp(ui = ui, server = server)
