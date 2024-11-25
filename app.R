# ShinySurveyJS app

# if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
# pak::pkg_install(c("shiny", "jsonlite", "shinyjs", "httr", "DBI", "RPostgres", "yaml"))

library(shiny)
library(jsonlite)
library(shinyjs)
library(httr)
library(DBI)
library(RPostgres)
library(yaml)

source("shiny/survey.R")
source("shiny/messages.R")
source("shiny/database.R")

setup_database()

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
  
  if(token_active){
    token_table <- read_table("tokens")
    token_reactive <- reactiveVal(token_table)
    handle_url_parameters(session, token_reactive)
    survey_data <- surveyServer(input, output, session, token_active, token_table)
  }else{
    handle_url_parameters_tokenless(session, token_reactive)
    survey_data <- surveyServer(input, output, session, token_active)
  }
}

shinyApp(ui = ui, server = server)