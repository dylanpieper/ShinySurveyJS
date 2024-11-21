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

create_tokens_table <- function() {
  # Establish a database connection
  con <- db_connect()
  
  # Ensure the connection is closed when the function exits
  on.exit(dbDisconnect(con), add = TRUE)
  
  # SQL query to create the "tokens" table if it doesn't exist
  create_table_query <- "
    CREATE TABLE IF NOT EXISTS tokens (
      object VARCHAR(255),
      token VARCHAR(255),
      type VARCHAR(255)
    );
  "
  
  # Execute the query
  tryCatch({
    dbExecute(con, create_table_query)
    message("Table 'tokens' has been created (or already exists)")
  }, error = function(e) {
    message("An error occurred: ", e$message)
  })
}

read_tokens_table <- function() {
  # Establish a database connection
  con <- db_connect()
  
  # Ensure the connection is closed when the function exits
  on.exit(dbDisconnect(con), add = TRUE)
  
  # SQL query to read the "tokens" table
  query <- "SELECT * FROM tokens;"
  
  # Fetch the data and convert to a data frame
  tryCatch({
    tokens_df <- dbGetQuery(con, query)
    message("Successfully read the 'tokens' table")
    return(tokens_df)
  }, error = function(e) {
    message("An error occurred while reading the 'tokens' table: ", e$message)
    return(NULL)
  })
}

write_to_tokens_table <- function(data) {
  # Check if the input data frame has the required fields
  required_fields <- c("object", "token", "type")
  if (!all(required_fields %in% names(data))) {
    stop("The data frame must contain the fields: 'object', 'token', and 'type'")
  }
  
  # Establish a database connection
  con <- db_connect()
  
  # Ensure the connection is closed when the function exits
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Write the data frame to the tokens table
  tryCatch({
    dbWriteTable(
      con,
      name = "tokens",
      value = data,
      append = TRUE,
      row.names = FALSE
    )
    message("Successfully wrote to the 'tokens' table")
  }, error = function(e) {
    message("An error occurred while writing to the 'tokens' table: ", e$message)
  })
}

create_dynamic_field_tables <- function() {
  # Load the YAML configuration file
  config <- read_yaml("dynamic_fields_config.yml")
  
  # Validate that the 'fields' section exists and is a list
  if (!"fields" %in% names(config) || !is.list(config$fields)) {
    stop("The configuration file must include a 'fields' list")
  }
  
  # Iterate over each field configuration
  for (field_config in config$fields) {
    # Validate required fields for each entry
    required_fields <- c("table_name", "group_col", "choices_col")
    if (!all(required_fields %in% names(field_config))) {
      stop(sprintf(
        "Each field configuration must include the following fields: %s",
        paste(required_fields, collapse = ", ")
      ))
    }
    
    # Extract the table name and fields for each entry
    table_name <- field_config$table_name
    group_col <- field_config$group_col
    choices_col <- field_config$choices_col
    
    # Ensure fields are not null or empty
    if (any(sapply(list(table_name, group_col, choices_col), function(x) is.null(x) || x == ""))) {
      stop("All configuration fields ('table_name', 'group_col', and 'choices_col') must have valid values")
    }
    
    # Construct the SQL CREATE TABLE statement
    fields <- c(group_col, choices_col)
    create_table_query <- sprintf(
      "CREATE TABLE IF NOT EXISTS %s (%s);",
      table_name,
      paste(sprintf("%s VARCHAR(255)", fields), collapse = ", ")
    )
    
    # Establish a database connection
    con <- db_connect()
    
    # Ensure the connection is closed after function exits
    on.exit(dbDisconnect(con), add = TRUE)
    
    # Execute the query
    tryCatch({
      dbExecute(con, create_table_query)
      message(sprintf("Table '%s' has been created (or already exists)", table_name))
    }, error = function(e) {
      message("An error occurred while creating the table: ", e$message)
    })
  }
}
