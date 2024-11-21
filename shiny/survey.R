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
surveyServer <- function(input, output, session, token_active, token_table = NULL) {
  # Initialize reactive value for survey data
  survey_data <- reactiveVal()
  
  # Process query string
  observe({
    if (token_active) {
      # Source shiny functions
      source("shiny/token.R")
      source("shiny/database.R")
      
      # Process query
      query <- parseQueryString(session$clientData$url_search)
      survey <- query$survey
      
      if (!is.null(survey)) {
        survey_lookup <- token_table[token_table$token == survey, "object"]
        
        if (length(survey_lookup) == 0) {
          warning("Survey lookup returned no results")
        }
      } else {
        warning("No survey parameter in query")
      }
      
      # Iterate over the fields in config and load corresponding tables
      for (field in seq_along(config$fields)) {
        field_config <- config$fields[[field]]
        
        # Check if the current field is relevant to the survey
        if (!is.null(survey_lookup) && survey_lookup %in% field_config$surveys) {
          table_name <- field_config$table_name
          
          # Load the table and assign it to the global environment
          table_data <- read_table(table_name)
          assign(table_name, table_data, envir = .GlobalEnv)
        }
      }
      
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
      
      # Process dynamic query parameters based on config
      for (field in seq_along(config$fields)) {
        field_config <- config$fields[[field]]
        
        # Check if the current field is relevant to the survey
        if (!is.null(survey_lookup) && survey_lookup %in% field_config$surveys) {
          table_name <- field_config$table_name
          group_col <- field_config$group_col
          
          # Get the table data that was previously loaded
          table_data <- get(table_name, envir = .GlobalEnv)
          
          # Check if there's a query parameter matching this group column
          if (!is.null(group_col) && !is.null(query[[group_col]])) {
            # Look up the group token
            group_token <- query[[group_col]]
            group_lookup <- token_table[token_table$token == group_token, "object"]
            
            # If we found a matching group
            if (length(group_lookup) > 0 && group_lookup %in% table_data[[group_col]]) {
              # Get the choices column for this field
              choices_col <- field_config$choices_col
              
              # Filter the data based on the group_lookup
              filtered_data <- table_data[table_data[[group_col]] == group_lookup, ]
              
              # Update choices if the choices column exists
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
      
    } else {
      query <- parseQueryString(session$clientData$url_search)
      survey <- query$survey
      
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
      
      # Load config file to process group-based queries
      config <- read_yaml("dynamic_fields_config.yml")
      
      # Iterate through the fields in config
      for (field in seq_along(config$fields)) {
        field_config <- config$fields[[field]]
        
        # Check if the current field is relevant to the survey
        if (!is.null(survey) && survey %in% field_config$surveys) {
          table_name <- field_config$table_name
          group_col <- field_config$group_col
          
          # Read the table data
          table_data <- read_table(table_name)
          
          # Check if there's a query parameter matching this group column
          if (!is.null(group_col) && !is.null(query[[group_col]])) {
            group_value <- query[[group_col]]
            
            # Check if the group value exists in the table
            if (group_value %in% table_data[[group_col]]) {
              # Get the choices column for this field
              choices_col <- field_config$choices_col
              
              # Filter the data based on the group value
              filtered_data <- table_data[table_data[[group_col]] == group_value, ]
              
              # Update choices if the choices column exists
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

# Generate tokens for survey URLs and group queries
generate_tokens <- function() {
  # Source shiny functions
  source("shiny/token.R")
  source("shiny/database.R")
  
  # Load YAML configuration file
  config <- read_yaml("dynamic_fields_config.yml")
  
  # Initialize all_groups vector
  all_groups <- c()
  
  # Iterate over the fields in config and load all groups
  for (field in seq_along(config$fields)) {
    field_config <- config$fields[[field]]
    
    table_name <- field_config$table_name
    table_data <- read_table(table_name)
    
    table_group_col <- field_config$group_col
    table_groups <- table_data[[table_group_col]]
    
    all_groups <- unique(c(all_groups, table_groups))
  }
  
  # Retrieve all available surveys
  all_surveys <- sub("\\.json$", "", list.files("www/", pattern = "*.json", full.names = FALSE))
  
  # Combine surveys and groups into one object list
  current_objects <- data.frame(
    object = c(all_surveys, all_groups),
    type = c(rep("Survey", length(all_surveys)), rep("Group", length(all_groups))),
    stringsAsFactors = FALSE
  )
  
  # Remove any duplicates from current_objects
  current_objects <- unique(current_objects)
  
  # Read tokens table
  con <- db_connect()
  token_table <- dbReadTable(con, "tokens")
  dbDisconnect(con)
  
  # Check for duplicate objects in the database
  if (any(duplicated(token_table$object))) {
    # Remove duplicates, keeping the first occurrence
    token_table <- token_table[!duplicated(token_table$object), ]
    
    # Delete all rows and rewrite the deduplicated data
    delete_from_tokens_table(token_table$object)
    write_to_tokens_table(token_table)
    message("Removed duplicate entries from tokens table")
  }
  
  # Identify objects to remove (those in token_table but not in current_objects)
  objects_to_remove <- token_table$object[!(token_table$object %in% current_objects$object)]
  
  if (length(objects_to_remove) > 0) {
    # Delete obsolete entries from database
    rows_deleted <- delete_from_tokens_table(objects_to_remove)
    message(sprintf("Removed %d obsolete entries from tokens table", rows_deleted))
    
    # Update our local copy of token_table
    token_table <- token_table[!(token_table$object %in% objects_to_remove), ]
  }
  
  # Identify new objects to add (those in current_objects but not in token_table)
  new_objects <- current_objects[!(current_objects$object %in% token_table$object), ]
  
  if (nrow(new_objects) > 0) {
    # Generate unique tokens for new objects
    existing_tokens <- token_table$token
    new_tokens <- sapply(seq_len(nrow(new_objects)), function(x) {
      repeat {
        token <- generate_unique_token(existing_tokens)
        if (!(token %in% existing_tokens)) {
          existing_tokens <- c(existing_tokens, token)  # Update existing tokens list
          return(token)
        }
      }
    })
    
    # Create new entries
    new_entries <- data.frame(
      object = new_objects$object,
      token = new_tokens,
      type = new_objects$type,
      stringsAsFactors = FALSE
    )
    
    # Write new entries to database
    write_to_tokens_table(new_entries)
    message(sprintf("Added %d new entries to tokens table", nrow(new_entries)))
    
    # Update our local copy of token_table
    token_table <- rbind(token_table, new_entries)
  }
  
  if (length(objects_to_remove) == 0 && nrow(new_objects) == 0) {
    message("No updates needed for tokens table")
  }
  
  # Final verification of uniqueness
  if (any(duplicated(token_table$object))) {
    warning("Unexpected duplicate objects found in final token table")
  }
  if (any(duplicated(token_table$token))) {
    warning("Unexpected duplicate tokens found in final token table")
  }
  
  # Return updated token table invisibly
  invisible(token_table)
}