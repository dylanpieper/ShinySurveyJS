# ShinySurveyJS

A template for hosting multiple surveys using **Shiny**, **SurveyJS**, and **PostgreSQL**.

## Why SurveyJS?

SurveyJS is a mature, open-source survey creation library that redefines how online questionnaires are designed. Unlike other Shiny-based survey tools like [surveydown](https://github.com/surveydown-dev/surveydown) or [shinysurveys](https://github.com/jdtrat/shinysurveys), SurveyJS provides an [advanced visual editor](https://surveyjs.io/create-free-survey) with built-in support for branching logic and validation, allowing users to easily create dynamic and interactive questionnaires. Additional features include support for diverse question types and robust customization options like theming, adding panels and pages, and suporting multiple languages. Balancing security, performance, and flexibility, SurveyJS is a powerful tool for academic and commercial use cases.

## Key Features

-   Visual survey creation using [SurveyJS Editor](https://surveyjs.io/create-free-survey)
-   Multiple surveys in a single app
-   URL query tokens prevent user manipulation of public surveys
    -   Automatically generates and stores unique tokens in the database
    -   Supports multiple parameters and configurations
    -   Enhances security by obscuring direct parameter access
-   Dynamic fields that update choices (survey response options) using URL query parameters and database tables

## Get Started

1.  Clone the repository:

``` bash
git clone https://github.com/dylanpieper/ShinySurveyJS.git
```

2.  Create your `db_config.yml` file, modifying the following template with your database credentials:

``` yaml
db:
  host: "database-hostname"
  port: 1234
  dbname: "database-name"
  user: "username"
  password: "password"
```

3.  Install the required R packages:

``` r
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pkg_install(c("shiny", "jsonlite", "shinyjs", "httr", "DBI", "RPostgres", "yaml", "future", "promises"))
```

I recommend using [Supabase](https://supabase.com/) for a free PostgreSQL database.

## Setup Dynamic Fields

1.  Create the table `entities` in your database to explore the example surveys and dynamic fields functionality. You can execute the following queries to create the table and insert the sample data, assuming your schema name is `public`.

``` sql
CREATE TABLE entities (
    entity VARCHAR(255),
    location VARCHAR(255)
);

INSERT INTO entities (entity, location) 
VALUES 
    ('Anthropic', 'San Francisco, CA'),
    ('Anthropic', 'Seattle, WA'),
    ('Anthropic', 'New York City, NY'),
    ('Google', 'San Francisco, CA'),
    ('Google', 'Boulder, CO'),
    ('Google', 'Chicago, IL');
```

2.  Optionally, create and manage your own dynamic fields table by adding your table and mapping your fields to the `dynamic_fields_config.yml` file. The `group_col` is the column that will be used to filter the dynamic fields, which is assigned a token and used in the URL query parameter. The `choices_col` is the column that will be used to locate the field name and populate the survey choices. The `surveys` field is a list of surveys that the dynamic field applies to.

``` yaml
fields:
  - table_name: "entities"
    group_col: "entity"
    choices_col: "location"
    surveys: ["dynamicSurvey1", "dynamicSurvey2"]
```

## Run Survey App

1.  In `app.R`, use the following line to create the necessary tables and generate the tokens for all survey objects and dynamic field groups:

``` r
setup_database()
```

Consider commenting out this line. Run only if you want to update the tokens after adding a new (1) survey, (2) dynamic field configuration in `dynamic_fields_config.yml`, or (3) unique value for `group_col` in a dynamic fields table. Keeping this line will slow down the app initialization. **These processes will be automated in a future version of the template.**

2.  Run the app:

``` r
runApp()
```

3.  Access survey with URL query parameters:

Generic: - Without tokens (same as JSON file name): `/?survey=name` - With tokens: `/?survey=token`

Examples with dynamic fields: - Without tokens (`token_active <- FALSE`): `/?survey=dynamicSurvey&entity=Google` - With tokens (`token_active <- TRUE`): `/?survey=LimeMeteorSevenHundredThirtyTwo&entity=LimeSixHundredThirtyFiveSun`

Tokenization is used by default. Be aware that using tokens is a slower process and may not be necessary for your use case. You can customize the tokenization algorithm in `shiny/token.R`.

## Use Other Databases

Easily change the database driver in `db.R` to use any database system compatible with the `DBI` package (see [list of backends](https://github.com/r-dbi/backends#readme)). The `RPostgres` package is used by default.

## Roadmap

-   ✔️ Friendly initialization UI
-   ✔️ URL parameter tokenization
-   PostgreSQL
    -   ✔️ Tokens and dynamic fields handled in database
    -   Survey data is written to database
-   App is managed in a container
-   System to generate links for sharing surveys
