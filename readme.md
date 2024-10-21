# ShinySurveyJS

A template for creating and managing multiple dynamic surveys within a single Shiny app with all the power and flexibility of [SurveyJS](https://surveyjs.io/) at your fingerips.

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

-   Without tokenization (token_active \<- FALSE): `http://your-app-url.com/?survey=dynamicSurvey&entity=Google`

-   With tokenization (token_active \<- TRUE): `http://your-app-url.com/?survey=TriangleBirdTwoHundredFiftyFourPlanetBrown&entity=PulsarTurquoisePyramidCheetahEightHundredNinetyNine`

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
http://your-app-url.com/?survey=<generated-token>
```

## URL Parameter System

-   Automatically generates and stores unique tokens in `token.csv`
-   Supports multiple parameters (survey, entity, custom parameters)
-   Enhances security by obscuring direct parameter access

## Roadmap

-   ✔️ Friendly initialization UI
-   ✔️ URL parameter tokenization
-   ⬜ SQL integration
