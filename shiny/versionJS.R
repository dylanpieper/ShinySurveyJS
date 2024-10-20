# Function to check if a URL exists and returns valid content
checkURL <- function(url) {
  tryCatch({
    response <- GET(url)
    status_code <- status_code(response)
    return(status_code == 200)
  }, error = function(e) {
    return(FALSE)
  })
}

# Function to verify both JS and CSS files for a version
verifyVersionFiles <- function(version, package_name) {
  # Check JS file
  js_url <- paste0("https://unpkg.com/", package_name, "@", version, "/", 
                   ifelse(package_name == "survey-jquery", "survey.jquery.min.js", ""))
  js_exists <- checkURL(js_url)
  
  # For survey-core, also check CSS files
  if (package_name == "survey-core") {
    css_default_url <- paste0("https://unpkg.com/", package_name, "@", version, "/defaultV2.fontless.css")
    css_modern_url <- paste0("https://unpkg.com/", package_name, "@", version, "/modern.css")
    
    css_exists <- checkURL(css_default_url) && checkURL(css_modern_url)
    return(js_exists && css_exists)
  }
  
  return(js_exists)
}

# Get the survey version
getSurveyVersion <- function(package_name = "survey-jquery", base_version = "1.12.6") {
  tryCatch({
    # Load required packages
    if (!requireNamespace("httr", quietly = TRUE)) {
      install.packages("httr")
    }
    
    library(httr)
    
    # Function to increment version, skipping x.0.0 releases
    incrementVersion <- function(version) {
      parts <- as.numeric(strsplit(version, "\\.")[[1]])
      
      if (parts[3] < 9) {
        parts[3] <- parts[3] + 1
      } else {
        parts[2] <- parts[2] + 1
        parts[3] <- 1  # Skip the x.y.0 versions
      }
      
      # Check if it's a x.0.0 release, skip to x.1.1
      if (parts[2] == 0 && parts[3] == 0) {
        parts[2] <- 1
        parts[3] <- 1
      }
      
      paste(parts, collapse = ".")
    }
    
    # Start with known working version
    current_version <- base_version
    last_working_version <- base_version
    max_attempts <- 10  # Prevent infinite loop
    attempt <- 1
    
    # Keep incrementing until we find a non-working version
    while (attempt <= max_attempts) {
      if (!verifyVersionFiles(current_version, package_name)) {
        # Found first non-working version, return the last working one
        message("Using latest version of ", package_name, ": ", last_working_version)
        return(last_working_version)
      }
      
      # Current version works, save it and try next version
      last_working_version <- current_version
      current_version <- incrementVersion(current_version)
      attempt <- attempt + 1
    }
    
    # If we hit max attempts, return the last known working version
    message("Hit maximum attempts, using version: ", last_working_version)
    return(last_working_version)
    
  }, error = function(e) {
    warning("Error checking version. Using base version ", base_version)
    return(base_version)
  })
}