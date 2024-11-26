# Define the Shiny UI and server functions for rendering surveys
surveyUI <- function(id = NULL, theme = "defaultV2") {
  # Determine the CSS file based on the selected theme to style the survey UI
  css_file <- switch(theme,
                     "defaultV2" = paste0("https://unpkg.com/survey-core/defaultV2.fontless.css"),
                     "modern" = paste0("https://unpkg.com/survey-core/modern.css")
  )
  
  # Construct the UI components, including loading necessary scripts and stylesheets for rendering surveys
  tagList(
    tags$head(
      tags$script(src = paste0("https://unpkg.com/survey-jquery/survey.jquery.min.js")),
      tags$link(rel = "stylesheet", href = css_file),
      tags$link(rel = "stylesheet", href = "_custom.css"),
      tags$script(src = "_survey.js")
    ),
    tags$div(id = "surveyContainer")  # Placeholder for rendering the survey
  )
}

# Define the server function for handling survey data and dynamic field configurations
surveyServer <- function(input = NULL, 
                         output = NULL, 
                         session = NULL, 
                         token_active = NULL, 
                         token_table = NULL) {
  survey_data <- reactiveVal()
  
  observe({
    if (token_active) {
      # Parse and validate the survey token from the URL query
      query <- parseQueryString(session$clientData$url_search)
      survey <- query$survey
      
      if (!is.null(survey)) {
        # Lookup the survey object associated with the token, if it exists
        survey_lookup <- token_table[token_table$token == survey, "object"]
        
        if (length(survey_lookup) == 0) {
          warning("Survey lookup returned no results")
          survey_lookup <- NULL
        }
      } else {
        warning("No survey parameter in query")
        survey_lookup <- NULL
      }
      
      if (!is.null(survey_lookup)) {
        # Load dynamic field configurations to adjust UI based on survey specifics
        config <- read_yaml("dynamic_fields_config.yml")
        
        for (field in seq_along(config$fields)) {
          field_config <- config$fields[[field]]
          
          # Load data tables associated with the survey, if applicable
          if (!is.null(survey_lookup) && survey_lookup %in% field_config$surveys) {
            table_name <- field_config$table_name
            table_data <- read_table(table_name)
            assign(table_name, table_data, envir = .GlobalEnv)
          }
        }
        
        if (!is.null(survey)) {
          # Load and send the survey JSON to the client for rendering, if available
          survey_json_path <- file.path("www", paste0(survey_lookup, ".json"))
          
          if (file.exists(survey_json_path)) {
            survey_json <- fromJSON(survey_json_path, simplifyVector = FALSE)
            session$sendCustomMessage("loadSurvey", survey_json)
          } else {
            warning(paste("Survey JSON file not found:", survey_json_path))
          }
        }
        
        for (field in seq_along(config$fields)) {
          field_config <- config$fields[[field]]
          
          if (!is.null(survey_lookup) && survey_lookup %in% field_config$surveys) {
            table_name <- field_config$table_name
            group_col <- field_config$group_col
            table_data <- get(table_name, envir = .GlobalEnv)
            
            # Filter data based on group tokens from the query to dynamically update survey choices
            if (!is.null(group_col) && !is.null(query[[group_col]])) {
              group_token <- query[[group_col]]
              group_lookup <- token_table[token_table$token == group_token, "object"]
              
              if (length(group_lookup) > 0 && group_lookup %in% table_data[[group_col]]) {
                choices_col <- field_config$choices_col
                filtered_data <- table_data[table_data[[group_col]] == group_lookup, ]
                
                if (!is.null(choices_col) && choices_col %in% names(filtered_data)) {
                  session$sendCustomMessage("updateChoices", 
                                            list("targetQuestion" = choices_col, 
                                                 "choices" = as.list(unique(filtered_data[[choices_col]]))))
                } else {
                  warning("Choices column not found in filtered data")
                }
              } else {
                warning("Group not found in table")
              }
            }
          }
        }
      }
    } else {
      # Handle cases where token-based survey lookup is not active
      query <- parseQueryString(session$clientData$url_search)
      survey <- query$survey
      
      if (!is.null(survey)) {
        survey_json_path <- file.path("www", paste0(survey, ".json"))
        
        if (file.exists(survey_json_path)) {
          survey_json <- fromJSON(survey_json_path, simplifyVector = FALSE)
          session$sendCustomMessage("loadSurvey", survey_json)
        } else {
          warning(paste("Survey JSON file not found:", survey_json_path))
        }
      }
      
      config <- read_yaml("dynamic_fields_config.yml")
      
      for (field in seq_along(config$fields)) {
        field_config <- config$fields[[field]]
        
        if (!is.null(survey) && survey %in% field_config$surveys) {
          table_name <- field_config$table_name
          group_col <- field_config$group_col
          table_data <- read_table(table_name)
          
          if (!is.null(group_col) && !is.null(query[[group_col]])) {
            group_value <- query[[group_col]]
            
            if (group_value %in% table_data[[group_col]]) {
              choices_col <- field_config$choices_col
              filtered_data <- table_data[table_data[[group_col]] == group_value, ]
              
              if (!is.null(choices_col) && choices_col %in% names(filtered_data)) {
                session$sendCustomMessage("updateChoices", 
                                          list("targetQuestion" = choices_col, 
                                               "choices" = as.list(unique(filtered_data[[choices_col]]))))
              } else {
                warning("Choices column not found in filtered data")
              }
            } else {
              warning("Group not found in table")
            }
          }
        }
      }
    }
  })
  
  observeEvent(input$surveyData, {
    # Capture and render survey data submitted by the user
    survey_data(fromJSON(input$surveyData))
    output$surveyData <- renderTable({
      req(survey_data())
      survey_data()
    })
  })
  
  return(survey_data)
}

# Generate a unique token for all surveys and dynamic field groups
generate_tokens <- function(token_table = NULL) {
  # Load required scripts and configurations for token management
  source("shiny/token.R")
  source("shiny/database.R")
  config <- read_yaml("dynamic_fields_config.yml")
  
  # Aggregate all unique groups from configured tables for token generation
  all_groups <- tryCatch({
    unique(unlist(lapply(config$fields, function(field_config) {
      table_data <- read_table(field_config$table_name)
      table_data[[field_config$group_col]]
    })))
  }, error = function(e) {
    message("Error reading table data: ", e$message)
    return(NULL)
  })
  
  # If reading the table data failed, do not proceed
  if (is.null(all_groups)) {
    message("Function aborted due to error in reading table data")
    return(invisible(token_table))
  }
  
  # Identify all survey files to include in `tokens` table
  all_surveys <- sub("\\.json$", "", list.files("www/", pattern = "*.json", full.names = FALSE))
  
  # Create a data frame of current survey and group objects
  current_objects <- unique(data.frame(
    object = c(all_surveys, all_groups),
    type = c(rep("Survey", length(all_surveys)), rep("Group", length(all_groups))),
    stringsAsFactors = FALSE
  ))
  
  # Check for obsolete objects and new objects
  objects_to_remove <- setdiff(token_table$object, current_objects$object)
  new_objects <- current_objects[!(current_objects$object %in% token_table$object), ]
  
  # Exit early if no updates are needed
  if (length(objects_to_remove) == 0 && nrow(new_objects) == 0) {
    message("No updates needed for `tokens` table")
    return(invisible(token_table))
  }
  
  # Remove any duplicate entries from `tokens` table
  if (any(duplicated(token_table$object))) {
    token_table <- token_table[!duplicated(token_table$object), ]
  }
  
  # Remove obsolete objects from `tokens` table
  if (length(objects_to_remove) > 0) {
    delete_from_tokens_table(objects_to_remove)
    token_table <- token_table[!(token_table$object %in% objects_to_remove), ]
    message(sprintf("Removed %d obsolete entries from `tokens` table", length(objects_to_remove)))
  }
  
  # Generate and add new tokens for any new survey or group objects
  if (nrow(new_objects) > 0) {
    existing_tokens <- token_table$token
    new_tokens <- replicate(nrow(new_objects), {
      repeat {
        token <- generate_unique_token(existing_tokens)
        if (!(token %in% existing_tokens)) {
          existing_tokens <- c(existing_tokens, token)
          break
        }
      }
      token
    })
    
    new_entries <- data.frame(
      object = new_objects$object,
      token = new_tokens,
      type = new_objects$type,
      stringsAsFactors = FALSE
    )
    
    write_to_tokens_table(new_entries)
    message(sprintf("Added %d new entries to `tokens` table", nrow(new_entries)))
    token_table <- rbind(token_table, new_entries)
  }
  
  # Final integrity checks for duplicate entries in `tokens` table
  if (any(duplicated(token_table$object))) {
    warning("Unexpected duplicate objects found in final `tokens` table")
  }
  if (any(duplicated(token_table$token))) {
    warning("Unexpected duplicate tokens found in final `tokens` table")
  }
  
  invisible(token_table)
}
