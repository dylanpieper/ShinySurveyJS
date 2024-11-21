# Function to connect to database
db_connect <- function() {
  # Read database configuration from YAML file
  config <- read_yaml("db_config.yml")
  
  # Extract Supabase credentials
  db_config <- config$db
  
  # Create a connection
  con <- dbConnect(
    Postgres(),
    host = db_config$host,
    port = db_config$port,
    dbname = db_config$dbname,
    user = db_config$user,
    password = db_config$password
  )
  return(con)
}

# Function to create the tokens table
create_tokens_table <- function() {
  # Establish a database connection
  con <- db_connect()
  
  # Ensure connection is closed when function exits
  on.exit(dbDisconnect(con), add = TRUE)
  
  # SQL query to create "tokens" table if it doesn't exist
  create_table_query <- "
    CREATE TABLE IF NOT EXISTS tokens (
      object VARCHAR(255),
      token VARCHAR(255),
      type VARCHAR(255)
    );
  "
  
  # Execute query
  tryCatch({
    dbExecute(con, create_table_query)
    message("Table 'tokens' has been created (or already exists)")
  }, error = function(e) {
    message("An error occurred: ", e$message)
  })
}

# Function to write data to the tokens table
write_to_tokens_table <- function(data) {
  # Check if input data frame has required fields
  required_fields <- c("object", "token", "type")
  if (!all(required_fields %in% names(data))) {
    stop("The data frame must contain fields: 'object', 'token', and 'type'")
  }
  
  # Establish a database connection
  con <- db_connect()
  
  # Ensure connection is closed when function exits
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Write data frame to tokens table
  tryCatch({
    dbWriteTable(
      con,
      name = "tokens",
      value = data,
      append = TRUE,
      row.names = FALSE
    )
    message("Successfully wrote to 'tokens' table")
  }, error = function(e) {
    message("An error occurred while writing to 'tokens' table: ", e$message)
  })
}

# Function to delete rows from the tokens table
delete_from_tokens_table <- function(objects_to_remove) {
  # Connect to database
  con <- db_connect()
  on.exit(dbDisconnect(con))
  
  # Create numbered placeholders for PostgreSQL ($1, $2, etc.)
  placeholders <- paste(sprintf("$%d", seq_along(objects_to_remove)), collapse = ",")
  
  # Construct and execute the DELETE query
  query <- sprintf("DELETE FROM tokens WHERE object IN (%s)", placeholders)
  
  # Execute the query
  tryCatch({
    result <- dbExecute(con, query, objects_to_remove)
    message(sprintf("Successfully deleted %d rows from tokens table", result))
    return(result)
  }, error = function(e) {
    message("An error occurred while deleting from tokens table: ", e$message)
    return(0)
  })
}

# Function to write data to the tokens table
write_to_tokens_table <- function(data) {
  # Check if input data frame has required fields
  required_fields <- c("object", "token", "type")
  if (!all(required_fields %in% names(data))) {
    stop("The data frame must contain fields: 'object', 'token', and 'type'")
  }
  
  # Establish a database connection
  con <- db_connect()
  
  # Ensure connection is closed when function exits
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Write data frame to tokens table
  tryCatch({
    dbWriteTable(
      con,
      name = "tokens",
      value = data,
      append = TRUE,
      row.names = FALSE
    )
    message("Successfully wrote to 'tokens' table")
  }, error = function(e) {
    message("An error occurred while writing to 'tokens' table: ", e$message)
  })
}

# Function to generate a unique token
create_dynamic_field_tables <- function() {
  # Load YAML configuration file
  config <- read_yaml("dynamic_fields_config.yml")
  
  # Validate that 'fields' section exists and is a list
  if (!"fields" %in% names(config) || !is.list(config$fields)) {
    stop("The configuration file must include a 'fields' list")
  }
  
  # Iterate over each field configuration
  for (field_config in config$fields) {
    # Validate required fields for each entry
    required_fields <- c("table_name", "group_col", "choices_col")
    if (!all(required_fields %in% names(field_config))) {
      stop(sprintf(
        "Each field configuration must include following fields: %s",
        paste(required_fields, collapse = ", ")
      ))
    }
    
    # Extract table name and fields for each entry
    table_name <- field_config$table_name
    group_col <- field_config$group_col
    choices_col <- field_config$choices_col
    
    # Ensure fields are not null or empty
    if (any(sapply(list(table_name, group_col, choices_col), function(x) is.null(x) || x == ""))) {
      stop("All configuration fields ('table_name', 'group_col', and 'choices_col') must have valid values")
    }
    
    # Construct SQL CREATE TABLE statement
    fields <- c(group_col, choices_col)
    create_table_query <- sprintf(
      "CREATE TABLE IF NOT EXISTS %s (%s);",
      table_name,
      paste(sprintf("%s VARCHAR(255)", fields), collapse = ", ")
    )
    
    # Establish a database connection
    con <- db_connect()
    
    # Ensure connection is closed after function exits
    on.exit(dbDisconnect(con), add = TRUE)
    
    # Execute query
    tryCatch({
      dbExecute(con, create_table_query)
      message(sprintf("Table '%s' has been created (or already exists)", table_name))
    }, error = function(e) {
      message("An error occurred while creating table: ", e$message)
    })
  }
}

# Function to generate a unique token
read_table <- function(table_name) {
  # Establish a database connection
  con <- db_connect()
  
  # Ensure connection is closed when function exits
  on.exit(dbDisconnect(con), add = TRUE)
  
  # SQL query to read the specified table
  query <- paste0("SELECT * FROM ", table_name, ";")
  
  # Fetch data and convert to a data frame
  tryCatch({
    table_df <- dbGetQuery(con, query)
    message("Successfully read '", table_name, "' table")
    return(table_df)
  }, error = function(e) {
    message("An error occurred while reading '", table_name, "' table: ", e$message)
    return(NULL)
  })
}

setup_database <- function() {
  create_tokens_table()
  create_dynamic_field_tables()
  generate_tokens()
}