surveyUI <- function(id, theme = "defaultV2") {
  css_file <- switch(theme,
                     "defaultV2" = "https://unpkg.com/survey-core@1.11.8/defaultV2.fontless.css",
                     "modern" = "https://unpkg.com/survey-core@1.11.8/modern.css"
  ) # Select the CSS file based on the theme selected
  
  tagList(
    tags$head(
      tags$script(src = "https://unpkg.com/survey-jquery@1.11.8/survey.jquery.min.js"), # Include the survey.jquery library
      tags$link(rel = "stylesheet", href = css_file), # Include the CSS file
      tags$script(src = "_survey.js") # Include the custom JavaScript file
    ),
    tags$div(id = "surveyContainer"), # Create a div to hold the survey
  )
}

surveyServer <- function(input, output, session) {
  survey_data <- reactiveVal() # Create a reactive value to hold the survey data
  entities <- data.frame(
    entity = c("Entity1", "Entity1", "Entity1", "Entity2", "Entity2", "Entity2"),
    location = c("Location1", "Location2", "Location3", "Location4", "Location5", "Location6")
  ) # Create a data frame of entities and their locations
  
  # Observe changes to the query string
  observe({
    query <- parseQueryString(session$clientData$url_search) # Parse the query string
    entity <- query$entity # Extract the entity parameter
    survey <- query$survey # Extract the survey parameter
    all_surveys <- print(sub("\\.json$", "", list.files("www/", pattern = "*.json", full.names = FALSE)))
    all_entities <- unique(entities$entity) # Get the unique entities
    all_hash_objects <- c(all_surveys, all_entities) # Combine the surveys and entities into a single vector
    
    # If a survey parameter was provided
    if (!is.null(survey)) {
      survey_json_path <- file.path("www", paste0(survey, ".json")) # Create the path to the survey JSON file
      if (file.exists(survey_json_path)) {
        survey_json <- fromJSON(survey_json_path, simplifyVector = FALSE) # If the file exists, load the JSON
        session$sendCustomMessage("loadSurvey", survey_json) # Send the JSON to the client
      } else {
        warning(paste("Survey JSON file not found:", survey_json_path)) # If the file does not exist, print a warning
      }
    }
    
    # If an entity parameter was provided
    if (!is.null(entity)) {
      locations <- entities[entities$entity == entity, "location"] # Get the locations for the entity
      session$sendCustomMessage("updateChoices", list("targetQuestion" = "location", "choices" = as.list(locations))) # Update the choices for the location question
    } else {
      session$sendCustomMessage("updateChoices", list("targetQuestion" = "location", "choices" = list("No locations available"))) # If no entity was provided, set the location choices to "No locations available"
    }
  })
  
  # Observe changes to the surveyData input
  observeEvent(input$surveyData, {
    survey_data(fromJSON(input$surveyData)) # Update the survey_data reactive value with the data from the input
    output$surveyData <- renderTable({ # Render a table of the survey data
      req(survey_data()) # Require that survey_data is not NULL
      survey_data() 
    })
  })
  
  return(survey_data) # Return the survey_data reactive value
}