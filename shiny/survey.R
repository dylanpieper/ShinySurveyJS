# Define the survey UI
surveyUI <- function(id, theme = "defaultV2") {
  
  # Determine CSS file based on theme and version
  css_file <- switch(theme,
                     "defaultV2" = paste0("https://unpkg.com/survey-core/defaultV2.fontless.css"),
                     "modern" = paste0("https://unpkg.com/survey-core/modern.css")
  )
  
  # Load necessary resources and create survey container
  tagList(
    tags$head(
      tags$script(src = paste0("https://unpkg.com/survey-jquery/survey.jquery.min.js")),
      tags$link(rel = "stylesheet", href = css_file),
      tags$link(rel = "stylesheet", href = "_custom.css"),
      tags$script(src = "_survey.js")
    ),
    tags$div(id = "surveyContainer")
  )
}

# Define server logic for survey
surveyServer <- function(input, output, session, token_active) {
  # Initialize reactive value for survey data
  survey_data <- reactiveVal()
  
  # Process query string parameters
  observe({
    if (token_active) {
      # Handle case when token is active
      source("shiny/token.R")
      source("shiny/database.R")
      
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
        type = c(rep("Survey", length(all_surveys)), rep("Entity", length(all_entities)))
      )
      
      # Read tokens table
      token_local <- read_tokens_table()
      original_nrow <- nrow(token_local)
      
      # Iterate over token_objects and add new rows for new objects
      for (i in seq_along(token_objects$object)) {
        obj <- token_objects$object[i]
        obj_type <- token_objects$type[i]
        
        # Check if the object already exists in the tokens table
        if (!(obj %in% token_local$object)) {
          # Generate a unique token
          new_token <- generate_unique_token(token_local$token)
          
          # Append new object, token, and type to token_local data frame
          token_local <- rbind(token_local, data.frame(object = obj, token = new_token, type = obj_type))
        }
      }
      
      # Check if new rows were added
      if (nrow(token_local) > original_nrow) {
        # Save updated token_local back to tokens table if new rows were added
        write_to_tokens_table(token_local)
      }
      
      # Look up survey and entity parameters
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
      }
      
    } else {
      # Handle case when token is not active
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
