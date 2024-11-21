# ShinySurveyJS

A template for hosting multiple dynamic surveys using **Shiny**, **SurveyJS**, and **SQL**.

## Key Features

-   Visual survey creation using [SurveyJS Editor](https://surveyjs.io/create-free-survey)
-   Secure URL parameter tokenization
-   Multiple survey management in a single app
-   Dynamic field updates based on URL parameters

## Getting Started

1.  Clone the repository:

```         
git clone https://github.com/dylanpieper/ShinySurveyJS.git
```

2.  Run the app:

``` r
runApp()
```

3.  Access survey with URL parameters:

-   Without tokenization (token_active \<- FALSE): `/?survey=dynamicSurvey&entity=Google`

-   With tokenization (token_active \<- TRUE): `/?survey=TriangleBirdTwoHundredFiftyFourPlanetBrown&entity=PulsarTurquoisePyramidCheetahEightHundredNinetyNine`

## Project Structure

```         
ShinySurveyJS/
├── app.R                # Main Shiny app
├── token.csv            # URL token mappings
├── www/                 # Web assets
│   ├── _custom.css         # UI customizations
│   ├── _survey.js          # Client-side operations
│   ├── dynamicSurvey.json
│   └── staticSurvey.json
└── shiny/               # R functions
    ├── survey.R            # Survey UI/Server
    ├── messages.R          # Message handling
    ├── token.R             # Token system
```

## Creating New Surveys

1.  Generate survey JSON using [SurveyJS Editor](https://surveyjs.io/create-free-survey)
2.  Save JSON file in `www/` directory
3.  Access using generated token:

```         
/?survey=<generated-token>
```

## URL Parameter System

-   Automatically generates and stores unique tokens in `token.csv`
-   Supports multiple parameters (survey, entity)
-   Enhances security by obscuring direct parameter access

## Roadmap

-   ✔️ Friendly initialization UI
-   ✔️ URL parameter tokenization
-   ⬜ SQL integration
-   ⬜ Pass full JSON in the URL parameter
-   ⬜ Modular/programmatic JSON generation using SQL tables
