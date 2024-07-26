surveyUI <- function(id, theme = "defaultV2") {
  css_file <- switch(theme,
                     "defaultV2" = "https://unpkg.com/survey-core@1.11.8/defaultV2.fontless.css",
                     "modern" = "https://unpkg.com/survey-core@1.11.8/modern.css"
  )
  
  tagList(
    tags$head(
      tags$script(src = "https://unpkg.com/survey-jquery@1.11.8/survey.jquery.min.js"),
      tags$link(rel = "stylesheet", href = css_file),
      tags$script(src = "_survey.js")
    ),
    tags$div(id = "surveyContainer"),
  )
}

surveyServer <- function(input, output, session) {
  survey_data <- reactiveVal()
  entities <- data.frame(
    entity = c("Entity1", "Entity1", "Entity1", "Entity2", "Entity2", "Entity2"),
    location = c("Location1", "Location2", "Location3", "Location4", "Location5", "Location6")
  )
  
  observe({
    query <- parseQueryString(session$clientData$url_search)
    entity <- query$entity
    survey <- input$survey
    
    if (!is.null(survey)) {
      survey_json_path <- file.path("www", survey)
      if (file.exists(survey_json_path)) {
        survey_json <- fromJSON(survey_json_path, simplifyVector = FALSE)
        session$sendCustomMessage("loadSurvey", survey_json)
      } else {
        warning(paste("Survey JSON file not found:", survey_json_path))
      }
    }
    
    if (!is.null(entity)) {
      locations <- entities[entities$entity == entity, "location"]
      session$sendCustomMessage("updateChoices", list("targetQuestion" = "location", "choices" = as.list(locations)))
    } else {
      session$sendCustomMessage("updateChoices", list("targetQuestion" = "location", "choices" = list("No locations available")))
    }
  })
  
  observeEvent(input$surveyData, {
    survey_data(fromJSON(input$surveyData))
    output$surveyData <- renderTable({
      req(survey_data())
      survey_data()
    })
  })
  
  return(survey_data)
}