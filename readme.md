# ShinySurveyJS

A template for hosting multiple dynamic surveys using **Shiny**, **SurveyJS**, and **PostgreSQL**.

## Key Features

-   Visual survey creation using [SurveyJS Editor](https://surveyjs.io/create-free-survey)
-   Multiple surveys in a single app
-   URL query tokens to prevent manipulation of public surveys
-   Dynamic fields update choices using URL query parameters and database tables

## Getting Started

1.  Clone the repository:

``` bash  
git clone https://github.com/dylanpieper/ShinySurveyJS.git
```

2.  Create your `db_config.yml` file, modifying the following template with your database credentials:

``` yaml    
db:
  host: "your-database-hostname"
  port: 1234
  dbname: "your-database-name"
  user: "your-username"
  password: "your-password"
```

3.  Setup the database:

Create a table called `entities` in your database to explore the example surveys and dynamic field feature. You can use the following SQL commands to create the table and insert some sample data, assuming your schema is called `public`, which is the default schema name in Supabase:

``` sql
CREATE TABLE "public"."entities" (
    "entity" VARCHAR(255),
    "location" VARCHAR(255)
);

INSERT INTO "public"."entities" ("entity", "location") 
VALUES 
    ('Anthropic', 'San Francisco, CA'),
    ('Anthropic', 'Seattle, WA'),
    ('Anthropic', 'New York City, NY'),
    ('Google', 'San Francisco, CA'),
    ('Google', 'Boulder, CO'),
    ('Google', 'Chicago, IL');
```

In `app.R`, use the following line to create the necessary tables and generate the tokens for all survey objects and dynamic field groups:

``` r
setup_database()
```

Consider commenting out this line after the first run. Re-run the line if you want to update the tokens or setup the database again. Keeping this line will slow down the app initialization.

4.  Run the app:

``` r
runApp()
```

5.  Access survey with URL query parameters:

-   Without tokens (`token_active <- FALSE`): `/?survey=dynamicSurvey&entity=Google`

-   With tokens (`token_active <- TRUE`): `/?survey=TriangleBirdTwoHundredFiftyFourPlanetBrown&entity=PulsarTurquoisePyramidCheetahEightHundredNinetyNine`

Tokenization is the default. Be aware that using tokens is a slower process and may not be necessary for your use case. You can modify the tokenization algorithm in `shiny/token.R`.

## Project Structure

```         
ShinySurveyJS/
├── app.R                       # Main Shiny app script
├── db_config.yml               # Database configuration file
├── dynamic_fields_config.yml   # Dynamic fields configuration for surveys
├── www/                        # Web assets
│   ├── _custom.css             # CSS file for UI customizations
│   ├── _survey.js              # JavaScript for client-side survey operations
│   ├── dynamicSurvey1.json     # JSON configuration for dynamic survey 1
│   ├── dynamicSurvey2.json     # JSON configuration for dynamic survey 2
│   └── staticSurvey.json       # JSON configuration for a static survey
└── shiny/                      # Shiny modules for app functionality
    ├── database.R              # Database interaction and utility functions
    ├── messages.R              # Functions for handling app messages
    ├── survey.R                # UI and server logic for surveys
    └── token.R                 # Token algorithm for URL query
```

## Creating New Surveys

1.  Generate survey JSON using [SurveyJS Editor](https://surveyjs.io/create-free-survey)
2.  Save JSON file in `www/` directory
3.  Access using generated token:

```         
/?survey=token
```

## URL Query Token System

-   Automatically generates and stores unique tokens in the database
-   Supports multiple parameters and configurations
-   Enhances security by obscuring direct parameter access thereby preventing user manipulation of public surveys

## Roadmap

-   ✔️ Friendly initialization UI
-   ✔️ URL parameter tokenization
-   PostgreSQL
    -   ✔️ Tokens and dynamic fields handled in database
    -   Survey data is written to database
-   App is managed in a container
-   System to generate links for sharing surveys