# Install pacman (package manager)
if (!require(pacman)) install.packages("pacman")

# Install/load required packages
pacman::p_load(shiny, jsonlite)

# Source shiny functions
source("shiny/survey.R")

# Define UI
ui <- fluidPage(
  surveyUI("survey", theme = "modern"),
  tableOutput("surveyData") # Add a table output
)

# Define server logic
server <- function(input, output, session) {
  survey_data <- surveyServer(input, output, session)
}

# Run app
shinyApp(ui = ui, server = server)
