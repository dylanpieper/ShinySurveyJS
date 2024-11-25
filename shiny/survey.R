surveyUI <- function(id, theme = "defaultV2") {
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

surveyServer <- function(input, output, session, token_active, token_table = NULL) {
  survey_data <- reactiveVal()
  
  observe({
    if (token_active) {
      # Parse and validate the survey token from the URL query to ensure it's valid for the session
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
generate_tokens <- function() {
  # Load required scripts and configurations for token management
  source("shiny/token.R")
  source("shiny/database.R")
  config <- read_yaml("dynamic_fields_config.yml")
  all_groups <- c()
  
  # Aggregate all unique groups from configured tables for token generation
  for (field in seq_along(config$fields)) {
    field_config <- config$fields[[field]]
    table_name <- field_config$table_name
    table_data <- read_table(table_name)
    table_group_col <- field_config$group_col
    table_groups <- table_data[[table_group_col]]
    all_groups <- unique(c(all_groups, table_groups))
  }
  
  # Identify all survey files to include in the token table
  all_surveys <- sub("\\.json$", "", list.files("www/", pattern = "*.json", full.names = FALSE))
  
  # Create a data frame of current survey and group objects
  current_objects <- data.frame(
    object = c(all_surveys, all_groups),
    type = c(rep("Survey", length(all_surveys)), rep("Group", length(all_groups))),
    stringsAsFactors = FALSE
  )
  
  current_objects <- unique(current_objects)
  
  # Connect to the database to manage the tokens table
  con <- db_connect()
  token_table <- dbReadTable(con, "tokens")
  dbDisconnect(con)
  
  # Remove any duplicate entries from the tokens table to maintain integrity
  if (any(duplicated(token_table$object))) {
    token_table <- token_table[!duplicated(token_table$object), ]
    delete_from_tokens_table(token_table$object)
    write_to_tokens_table(token_table)
    message("Removed duplicate entries from tokens table")
  }
  
  # Identify and remove obsolete objects from the tokens table
  objects_to_remove <- token_table$object[!(token_table$object %in% current_objects$object)]
  
  if (length(objects_to_remove) > 0) {
    rows_deleted <- delete_from_tokens_table(objects_to_remove)
    message(sprintf("Removed %d obsolete entries from tokens table", rows_deleted))
    token_table <- token_table[!(token_table$object %in% objects_to_remove), ]
  }
  
  # Generate and add new tokens for any new survey or group objects
  new_objects <- current_objects[!(current_objects$object %in% token_table$object), ]
  
  if (nrow(new_objects) > 0) {
    existing_tokens <- token_table$token
    new_tokens <- sapply(seq_len(nrow(new_objects)), function(x) {
      repeat {
        token <- generate_unique_token(existing_tokens)
        if (!(token %in% existing_tokens)) {
          existing_tokens <- c(existing_tokens, token)
          return(token)
        }
      }
    })
    
    new_entries <- data.frame(
      object = new_objects$object,
      token = new_tokens,
      type = new_objects$type,
      stringsAsFactors = FALSE
    )
    
    write_to_tokens_table(new_entries)
    message(sprintf("Added %d new entries to tokens table", nrow(new_entries)))
    token_table <- rbind(token_table, new_entries)
  }
  
  # Notify if no updates are needed for the tokens table
  if (length(objects_to_remove) == 0 && nrow(new_objects) == 0) {
    message("No updates needed for tokens table")
  }
  
  # Final integrity checks for duplicate entries in the tokens table
  if (any(duplicated(token_table$object))) {
    warning("Unexpected duplicate objects found in final token table")
  }
  if (any(duplicated(token_table$token))) {
    warning("Unexpected duplicate tokens found in final token table")
  }
  
  invisible(token_table)  # Return the updated token table invisibly
}
