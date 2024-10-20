# Function to check if a URL exists and returns valid content
checkURL <- function(url) {
  message("Testing: ", url)
  tryCatch({
    response <- GET(url)
    status_code <- status_code(response)
    is_valid <- status_code == 200
    message("Status: ", status_code, " ", ifelse(is_valid, "\U2705", "\U274C"))
    return(is_valid)
  }, error = function(e) {
    message("\U26A0 Failed to access URL")
    return(FALSE)
  })
}

# Function to verify both JS and CSS files for a version
verifyVersionFiles <- function(version, package_name) {
  message("\nVerifying ", package_name, " v", version)
  
  # Check JS file
  js_url <- paste0("https://unpkg.com/", package_name, "@", version, "/", 
                   ifelse(package_name == "survey-jquery", "survey.jquery.min.js", ""))
  js_exists <- checkURL(js_url)
  
  # For survey-core, also check CSS files
  if (package_name == "survey-core") {
    css_default_url <- paste0("https://unpkg.com/", package_name, "@", version, "/defaultV2.fontless.css")
    css_modern_url <- paste0("https://unpkg.com/", package_name, "@", version, "/modern.css")
    
    css_default_exists <- checkURL(css_default_url)
    css_modern_exists <- checkURL(css_modern_url)
    
    css_exists <- css_default_exists && css_modern_exists
    message("Files status: ", ifelse(js_exists && css_exists, "\U2705", "\U274C"))
    return(js_exists && css_exists)
  }
  
  message("Files status: ", ifelse(js_exists, "\U2705", "\U274C"))
  return(js_exists)
}

# Get the survey version
getSurveyVersion <- function(package_name = "survey-jquery", base_version = "1.12.6") {
  message("\nVersion check: ", package_name)
  message("Base version: ", base_version)
  
  tryCatch({
    # Function to increment version, skipping x.0.0 releases
    incrementVersion <- function(version) {
      parts <- as.numeric(strsplit(version, "\\.")[[1]])
      
      if (parts[3] < 9) {
        parts[3] <- parts[3] + 1
      } else {
        parts[2] <- parts[2] + 1
        parts[3] <- 1
      }
      
      if (parts[2] == 0 && parts[3] == 0) {
        parts[2] <- 1
        parts[3] <- 1
      }
      
      new_version <- paste(parts, collapse = ".")
      message("Testing increment: ", version, " -> ", new_version)
      return(new_version)
    }
    
    current_version <- base_version
    last_working_version <- base_version
    max_attempts <- 10
    attempt <- 1
    
    message("\nStarting version search:")
    while (attempt <= max_attempts) {
      message("\nAttempt ", attempt, "/", max_attempts)
      
      if (!verifyVersionFiles(current_version, package_name)) {
        message("Found latest working version: ", last_working_version)
        return(last_working_version)
      }
      
      last_working_version <- current_version
      current_version <- incrementVersion(current_version)
      attempt <- attempt + 1
    }
    
    message("Max attempts reached. Using version: ", last_working_version)
    return(last_working_version)
    
  }, error = function(e) {
    message("\U26A0 Error in version check")
    message("Defaulting to base version: ", base_version)
    return(base_version)
  })
}