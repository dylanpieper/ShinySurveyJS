# Establish a connection to the database using credentials from a YAML configuration file
db_connect <- function() {
  config <- read_yaml("db_config.yml")
  db_config <- config$db
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

# Create the 'tokens' table if it doesn't exist, ensuring it has the necessary columns
create_tokens_table <- function() {
  con <- db_connect()
  on.exit(dbDisconnect(con), add = TRUE)
  create_table_query <- "
    CREATE TABLE IF NOT EXISTS tokens (
      object VARCHAR(255),
      token VARCHAR(255),
      type VARCHAR(255)
    );
  "
  tryCatch({
    dbExecute(con, create_table_query)
    message("Table 'tokens' has been created (or already exists)")
  }, error = function(e) {
    message("An error occurred: ", e$message)
  })
}

# Validate the input data frame for required fields and append it to the 'tokens' table
write_to_tokens_table <- function(data) {
  required_fields <- c("object", "token", "type")
  if (!all(required_fields %in% names(data))) {
    stop("The data frame must contain fields: 'object', 'token', and 'type'")
  }
  con <- db_connect()
  on.exit(dbDisconnect(con), add = TRUE)
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

# Delete specified objects from the 'tokens' table using a parameterized query
delete_from_tokens_table <- function(objects_to_remove) {
  con <- db_connect()
  on.exit(dbDisconnect(con))
  placeholders <- paste(sprintf("$%d", seq_along(objects_to_remove)), collapse = ",")
  query <- sprintf("DELETE FROM tokens WHERE object IN (%s)", placeholders)
  tryCatch({
    result <- dbExecute(con, query, objects_to_remove)
    message(sprintf("Successfully deleted %d rows from tokens table", result))
    return(result)
  }, error = function(e) {
    message("An error occurred while deleting from tokens table: ", e$message)
    return(0)
  })
}

# Read dynamic field configurations and create corresponding tables with specified columns if they don't exist
create_dynamic_field_tables <- function() {
  config <- read_yaml("dynamic_fields_config.yml")
  if (!"fields" %in% names(config) || !is.list(config$fields)) {
    stop("The configuration file must include a 'fields' list")
  }
  for (field_config in config$fields) {
    required_fields <- c("table_name", "group_col", "choices_col")
    if (!all(required_fields %in% names(field_config))) {
      stop(sprintf(
        "Each field configuration must include following fields: %s",
        paste(required_fields, collapse = ", ")
      ))
    }
    table_name <- field_config$table_name
    group_col <- field_config$group_col
    choices_col <- field_config$choices_col
    if (any(sapply(list(table_name, group_col, choices_col), function(x) is.null(x) || x == ""))) {
      stop("All configuration fields ('table_name', 'group_col', and 'choices_col') must have valid values")
    }
    fields <- c(group_col, choices_col)
    create_table_query <- sprintf(
      "CREATE TABLE IF NOT EXISTS %s (%s);",
      table_name,
      paste(sprintf("%s VARCHAR(255)", fields), collapse = ", ")
    )
    con <- db_connect()
    on.exit(dbDisconnect(con), add = TRUE)
    tryCatch({
      dbExecute(con, create_table_query)
      message(sprintf("Table '%s' has been created (or already exists)", table_name))
    }, error = function(e) {
      message("An error occurred while creating table: ", e$message)
    })
  }
}

# Retrieve all records from the specified table and return them as a data frame
read_table <- function(table_name) {
  con <- db_connect()
  on.exit(dbDisconnect(con), add = TRUE)
  query <- paste0("SELECT * FROM ", table_name, ";")
  tryCatch({
    table_df <- dbGetQuery(con, query)
    message("Successfully read '", table_name, "' table")
    return(table_df)
  }, error = function(e) {
    message("An error occurred while reading '", table_name, "' table: ", e$message)
    return(NULL)
  })
}

# Set up the database by creating necessary tables and generating tokens
setup_database <- function() {
  create_tokens_table()
  create_dynamic_field_tables()
  generate_tokens()
}
