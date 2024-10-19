# Define the UI for the survey
surveyUI <- function(id, theme = "defaultV2") {
  # Determine CSS file based on theme
  css_file <- switch(theme,
                     "defaultV2" = "https://unpkg.com/survey-core@1.11.8/defaultV2.fontless.css",
                     "modern" = "https://unpkg.com/survey-core@1.11.8/modern.css"
  )
  
  # Load necessary resources and create survey container
  tagList(
    tags$head(
      tags$script(src = "https://unpkg.com/survey-jquery@1.11.8/survey.jquery.min.js"),
      tags$link(rel = "stylesheet", href = css_file),
      tags$script(src = "_survey.js")
    ),
    tags$div(id = "surveyContainer")
  )
}

# Define server logic for the survey
surveyServer <- function(input, output, session, encrypt_active) {
  # Initialize reactive value for survey data
  survey_data <- reactiveVal()

  # Process query string parameters
  observe({
    if (encrypt_active) {
      source("shiny/encrypt.R")
      
      # Define entities and locations (convert to db later)
      entities <- data.frame(
        entity = c("Google", "Google", "Google", "Anthropic", "Anthropic", "Anthropic"),
        location = c("San Francisco, CA", "Boulder, CO", "Chicago, IL", "San Francisco, CA", "Seattle, WA", "New York City, NY")
      )
      
      all_surveys <- sub("\\.json$", "", list.files("www/", pattern = "*.json", full.names = FALSE))
      all_entities <- unique(entities$entity)
      encrypt_objects <- c(all_surveys, all_entities)
      encrypt_local <- read.csv("encrypt.csv")
      original_nrow <- nrow(encrypt_local)
      
      # Iterate over encrypt_objects and add new rows for new objects
      for (obj in encrypt_objects) {
        if (!(obj %in% encrypt_local$object)) {
          # Generate a unique encrypt
          new_encrypt <- generate_unique_encrypt(encrypt_local$encrypt)
          
          # Append new row to encrypt_local
          encrypt_local <- rbind(encrypt_local, data.frame(object = obj, encrypt = new_encrypt))
        }
      }
      
      # Check if new rows were added
      if (nrow(encrypt_local) > original_nrow) {
        # Save the updated encrypt_local back to encrypt.csv only if new rows were added
        write.csv(encrypt_local, "encrypt.csv", row.names = FALSE)
      }
      
      # Look up the survey and entity parameters
      query <- parseQueryString(session$clientData$url_search)
      survey <- query$survey
      entity <- query$entity
      survey_lookup <- encrypt_local[encrypt_local$encrypt == survey, "object"]
      entity_lookup <- encrypt_local[encrypt_local$encrypt == entity, "object"]
      
      # Load and send survey JSON if survey parameter is provided
      if (!is.null(survey)) {
        survey_json_path <- file.path("www", paste0(survey_lookup, ".json"))
        if (file.exists(survey_json_path)) {
          survey_json <- fromJSON(survey_json_path, simplifyVector = FALSE)
          session$sendCustomMessage("loadSurvey", survey_json)
        } else {
          warning(paste("Survey JSON file not found:", survey_json_path))
        }
      }
      
      # Update location choices based on entity parameter
      if (!is.null(entity)) {
        locations <- entities[entities$entity == entity_lookup, "location"]
        session$sendCustomMessage("updateChoices", list("targetQuestion" = "location", "choices" = as.list(locations)))
      } else {
        session$sendCustomMessage("updateChoices", list("targetQuestion" = "location", "choices" = list("No locations available")))
      }
      
    }else{
      # Look up the survey and entity parameters
      query <- parseQueryString(session$clientData$url_search)
      survey <- query$survey
      entity <- query$entity
      
      # Load and send survey JSON if survey parameter is provided
      if (!is.null(survey)) {
        survey_json_path <- file.path("www", paste0(survey, ".json"))
        if (file.exists(survey_json_path)) {
          survey_json <- fromJSON(survey_json_path, simplifyVector = FALSE)
          session$sendCustomMessage("loadSurvey", survey_json)
        } else {
          warning(paste("Survey JSON file not found:", survey_json_path))
        }
      }
      
      # Update location choices based on entity parameter
      if (!is.null(entity)) {
        locations <- entities[entities$entity == entity, "location"]
        session$sendCustomMessage("updateChoices", list("targetQuestion" = "location", "choices" = as.list(locations)))
      } else {
        session$sendCustomMessage("updateChoices", list("targetQuestion" = "location", "choices" = list("No locations available")))
      }
    }
  })

  # Update survey data on input change
  observeEvent(input$surveyData, {
    survey_data(fromJSON(input$surveyData))
    output$surveyData <- renderTable({
      req(survey_data())
      survey_data()
    })
  })

  return(survey_data)
}
