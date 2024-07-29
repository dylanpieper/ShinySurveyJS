# ShinySurveyJS

ShinySurveyJS is a flexible and powerful framework that allows you to create and manage multiple dynamic surveys within a single Shiny app. By leveraging the capabilities of both Shiny and JavaScript ([SurveyJS](https://surveyjs.io/)), it provides a user-friendly experience for both survey creators and respondents.

## Features

-   **Automatic Parameter Hashing**: Enhance security with automatically generated hashes for URL parameters.
-   **Multiple Survey Management**: Create and manage multiple surveys within a single app.
-   **Dynamic Field Updates**: Update survey fields dynamically based on URL parameters.
-   **Integration with SurveyJS**: Utilize the [free survey builder tool](https://surveyjs.io/create-free-survey) to generate survey JSON files.
-   **Result Presentation**: Display survey results with tables and figures.

## File Structure

```         
ShinySurveyJS/
│
├── app.R                 # Main Shiny app file
├── hash.csv              # Stores mappings between objects and hashes
│
├── www/                  # Directory for web assets
│   ├── _survey.js            # Client-side survey operations
│   ├── dynamicSurvey.json    # Example dynamic survey
│   └── staticSurvey.json     # Example static survey
│
└── shiny/                # Directory for Shiny functions
    ├── survey.R          # Defines surveyUI and surveyServer functions
    └── messages.R        # Defines messageUI and server message functions
```

## Hashing Process and URL Parameters

ShinySurveyJS uses an automatic hashing system for URL parameters to enhance security and prevent direct access to the survey environment (e.g., users modifying readable URL parameters). However, a word of caution, the current infrastructure does not prevent the programmatic identification of hashes.

### Functionality:

1.  When a new parameter (survey, entity, or any custom parameter) is added to the system, a unique hash is automatically generated and stored in `hash.csv`.
2.  `hash.csv` contains two columns: `object` (the actual name or identifier) and `hash` (the corresponding hash).
3.  URL parameters use these hashes instead of actual object names.

### Automatic Hash Generation:

-   Hashes consist of a combination of three random letters and three random numbers (e.g., "a1b2c3").
-   The system ensures each hash is unique within `hash.csv`.
-   Hashes are automatically generated and managed by the system.

## Creating Multiple Surveys

1.  Use the [SurveyJS](https://surveyjs.io/create-free-survey) visual editor to generate a survey JSON.
2.  Save the JSON as a new file (e.g., `NewSurvey.json`) in the `www/` directory.
3.  The system will automatically detect the new survey and update `hash.csv` with a unique hash.
4.  Access the new survey using its hash as a URL parameter:

```         
http://your-app-url.com/?survey=a1b2c3
```

Where `a1b2c3` is the automatically generated hash for the new survey.

## Dynamically Updating Fields

The app can dynamically update fields based on various URL parameters. Modify and extend this functionality in `shiny/survey.R` to suit your needs.

Example of using multiple parameters:

```         
http://your-app-url.com/?survey=a1b2c3&entity=g9g4p2
```

The app will use these parameters to update relevant fields or settings based on your defined logic.

## Getting Started

1.  Clone this repository, or create a new project using the version control option in RStudio:

    ```         
    git clone https://github.com/dylanpieper/ShinySurveyJS.git
    ```

2.  Run the app:

    ``` r
    runApp()
    ```

3.  Access the app using a URL with appropriate parameter hashes:

    ```         
    http://your-app-url.com/?survey=a1b2c3
    ```

## To-do ✔️

-   Friendly initialization UI ✔️
-   Hash the URL query parameters ✔️
-   Create a dynamic JSON file option
    -   Paste JSON file fragments (e.g., demographics)
    -   Ability to paste data from db into JSON fields
-   Integrate with a db server (self-hosted MySQL/MariaDB server or Supabase)
-   Explore reCAPTCHA integration and bot prevention
