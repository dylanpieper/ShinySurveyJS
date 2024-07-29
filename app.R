# Install pacman (package manager)
if (!require(pacman)) install.packages("pacman")

# Install/load required packages
pacman::p_load(shiny, jsonlite, shinyjs)

# Source shiny functions
source("shiny/survey.R")

# Define UI
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$style(HTML("
      #waitingMessage, #surveyNotFoundMessage, #surveyNotDefinedMessage {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: white;
        z-index: 9999;
        display: flex;
        justify-content: center;
        align-items: center;
      }
    "))
  ),
  div(id = "waitingMessage", "Loading survey..."),
  div(id = "surveyNotFoundMessage", style = "display: none;", "Survey not found. Please check the URL and try again."),
  div(id = "surveyNotDefinedMessage", style = "display: none;", "No survey defined. Please provide a survey parameter in the URL."),
  div(id = "surveyContainer",
      surveyUI("survey", theme = "modern")
  ),
  tableOutput("surveyData")
)

# Define server logic
server <- function(input, output, session) {
  # Read hash.csv at the start of the session
  hash_local <- reactiveVal(read.csv("hash.csv"))
  
  # Check URL parameters and show appropriate message
  observeEvent(session$clientData$url_search, {
    query <- parseQueryString(session$clientData$url_search)
    
    if (is.null(query$survey)) {
      shinyjs::hide("waitingMessage", anim = TRUE, animType = "fade", time = .75)
      shinyjs::show("surveyNotDefinedMessage", anim = TRUE, animType = "fade", time = .75)
    } else {
      # Check if the survey file exists
      survey_lookup <- hash_local()[hash_local()$hash == query$survey, "object"]
      if (length(survey_lookup) == 0) {
        # If the hash is not found in hash_local
        shinyjs::hide("waitingMessage", anim = TRUE, animType = "fade", time = .75)
        shinyjs::show("surveyNotFoundMessage", anim = TRUE, animType = "fade", time = .75)
      } else {
        survey_json_path <- file.path("www", paste0(survey_lookup, ".json"))
        
        if (file.exists(survey_json_path)) {
          # Survey file exists, proceed with loading
          shinyjs::hide("waitingMessage", anim = TRUE, animType = "fade", time = .75)
        } else {
          # Survey file doesn't exist
          shinyjs::hide("waitingMessage", anim = TRUE, animType = "fade", time = .75)
          shinyjs::show("surveyNotFoundMessage", anim = TRUE, animType = "fade", time = .75)
        }
      }
    }
  }, ignoreInit = FALSE)
  
  survey_data <- surveyServer(input, output, session)
}

# Run app
shinyApp(ui = ui, server = server)