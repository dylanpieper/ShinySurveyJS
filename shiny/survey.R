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
    tags$div(id = "surveyContainer"),
  )
}

# Define server logic for the survey
surveyServer <- function(input, output, session, hash_active) {
  # Initialize reactive value for survey data
  survey_data <- reactiveVal()

  # Define entities and locations
  entities <- data.frame(
    entity = c("Entity1", "Entity1", "Entity1", "Entity2", "Entity2", "Entity2"),
    location = c("Location1", "Location2", "Location3", "Location4", "Location5", "Location6")
  )

  # Process query string parameters
  observe({
    if (hash_active) {
      all_surveys <- sub("\\.json$", "", list.files("www/", pattern = "*.json", full.names = FALSE))
      all_entities <- unique(entities$entity)
      hash_objects <- c(all_surveys, all_entities)
      hash_local <- read.csv("hash.csv")
      original_nrow <- nrow(hash_local)

      # Function to generate a unique hash
      generate_unique_hash <- function(existing_hashes) {
        repeat {
          # Generate a hash with three random letters and three random numbers
          new_hash <- paste0(sample(letters, 5, replace = TRUE),
            sample(0:9, 5, replace = TRUE),
            collapse = ""
          )

          # Check if the hash is unique
          if (!(new_hash %in% existing_hashes)) {
            return(new_hash)
          }
        }
      }

      # Iterate over hash_objects and add new rows for new objects
      for (obj in hash_objects) {
        if (!(obj %in% hash_local$object)) {
          # Generate a unique hash
          new_hash <- generate_unique_hash(hash_local$hash)

          # Append new row to hash_local
          hash_local <- rbind(hash_local, data.frame(object = obj, hash = new_hash))
        }
      }

      # Check if new rows were added
      if (nrow(hash_local) > original_nrow) {
        # Save the updated hash_local back to hash.csv only if new rows were added
        write.csv(hash_local, "hash.csv", row.names = FALSE)
      }

      # Look up the survey and entity parameters
      query <- parseQueryString(session$clientData$url_search)
      survey <- query$survey
      entity <- query$entity
      survey_lookup <- hash_local[hash_local$hash == survey, "object"]
      entity_lookup <- hash_local[hash_local$hash == entity, "object"]
      
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
