# shinysurveyjs<img src="man/figures/SSJS-Hex.svg" align="right" width="275" height="275"/>

The goal of this package is to integrate the flexible frontend of the [SurveyJS](https://surveyjs.io/) library with the reactive backend of [Shiny](https://shiny.posit.co/) to interface with a database and create dynamic user experiences. Whether you need a simple feedback form or a complex survey system for your organization, this package is designed to scale with you.

## Key Features

-   Host a single survey or multiple surveys in one app

-   Design surveys and create json objects with a user-friendly [visual editor](https://surveyjs.io/create-free-survey)

-   Dynamically populate field choices (i.e., response options) from a database table and create dependent fields (e.g., select a car brand and filter available models)

-   URL query tokens and one-time access tokens for secure survey distribution

-   Asynchronous worker to handle database updates in near real-time

🚧 **Warning**: These features are under construction and being moved from my [template](https://github.com/dylanpieper/ShinySurveyJS-Template).

## Installation

``` r
# Install from GitHub
pak::pkg_install("dylanpieper/shinysurveyjs")
```

## Basic Usage

### Single Survey

Read the survey from a json object to host a single survey. Data is stored in a PostgreSQL database table.

``` r
library(shinysurveyjs)

survey <- '{
  "title": "R Package Feedback",
  "pages": [
    {
      "name": "userInfo",
      "elements": [
        {
          "type": "rating",
          "name": "rating",
          "title": "Please rate the shinysurveyjs 📦:",
          "rateValues": [
            {"value": 1, "text": "⭐"},
            {"value": 2, "text": "⭐⭐"},
            {"value": 3, "text": "⭐⭐⭐"},
            {"value": 4, "text": "⭐⭐⭐⭐"},
            {"value": 5, "text": "⭐⭐⭐⭐⭐"}
          ],
          "rateMax": 5
        },
        {
          "type": "comment",
          "name": "feedback",
          "visibleIf": "{rating} notempty",
          "title": "Why did you rate it {rating} stars?",
          "rows": 2
        }
      ]
    }
  ]
}'


survey_single(
  json = survey,
  table_name = "survey_package_feedback",
  show_response = TRUE,
  theme_color = "#00AD6E",
  theme_mode = "dark",
  shiny_config = list(
    host = "0.0.0.0",
    port = 3838,
    workers = 100,
    sanitize_errors = TRUE,
    autoreload = FALSE
  ),
  db_config = list(
    host = "pooler.supabase.com",
    port = 5432,
    dbname = "postgres",
    user = "username",
    password = "password"
  )
)
```