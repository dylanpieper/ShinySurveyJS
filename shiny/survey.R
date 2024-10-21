# Define server logic for the survey
surveyServer <- function(input, output, session, token_active) {
  # Initialize reactive value for survey data
  survey_data <- reactiveVal()
  
  # Process query string parameters
  observe({
    if (token_active) {
      source("shiny/token.R")
      
      # Define entities and locations (convert to db later)
      entities <- data.frame(
        entity = c("Google", "Google", "Google", "Anthropic", "Anthropic", "Anthropic"),
        location = c("San Francisco, CA", "Boulder, CO", "Chicago, IL", "San Francisco, CA", "Seattle, WA", "New York City, NY")
      )
      
      # Retrieve all available surveys
      all_surveys <- sub("\\.json$", "", list.files("www/", pattern = "*.json", full.names = FALSE))
      all_entities <- unique(entities$entity)
      
      # Combine surveys and entities into one object list
      token_objects <- data.frame(
        object = c(all_surveys, all_entities),
        type = c(rep("Survey", length(all_surveys)), rep("Entity", length(all_entities)))  # Distinguish between surveys and entities
      )
      
      # Read the token.csv file
      token_local <- read.csv("token.csv")
      original_nrow <- nrow(token_local)
      
      # Iterate over token_objects and add new rows for new objects
      for (i in seq_along(token_objects$object)) {
        obj <- token_objects$object[i]
        obj_type <- token_objects$type[i]
        
        # Check if the object already exists in the token.csv file
        if (!(obj %in% token_local$object)) {
          # Generate a unique token
          new_token <- generate_unique_token(token_local$token)
          
          # Append the new object, token, and type to the token_local data frame
          token_local <- rbind(token_local, data.frame(object = obj, token = new_token, type = obj_type))
        }
      }
      
      # Check if new rows were added
      if (nrow(token_local) > original_nrow) {
        # Save the updated token_local back to token.csv only if new rows were added
        write.csv(token_local, "token.csv", row.names = FALSE)
      }
      
      # Look up the survey and entity parameters
      query <- parseQueryString(session$clientData$url_search)
      survey <- query$survey
      entity <- query$entity
      survey_lookup <- token_local[token_local$token == survey, "object"]
      entity_lookup <- token_local[token_local$token == entity, "object"]
      
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
      
    } else {
      # Handle case when token is not active (same as before)
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
