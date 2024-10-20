# ShinySurveyJS

ShinySurveyJS is a flexible and powerful framework that allows you to create and manage multiple dynamic surveys within a single Shiny app. By leveraging the capabilities of both Shiny and JavaScript ([SurveyJS](https://surveyjs.io/)), it provides a user-friendly experience for both survey creators and respondents.

## Motivation

This app framework is designed with a primary goal in mind: to create a robust, accessible, and secure platform that can host multiple public surveys without built-in user management. Each of the features mentioned below contributes to achieving this overarching objective:

-   **Integration with SurveyJS**: Integration with the [SurveyJS](https://surveyjs.io/create-free-survey) visual editor, a free survey builder tool, makes survey creation more accessible for users without advanced technical skills. This feature lowers the entry barrier for survey creators, encouraging a broader range of users to utilize the platform.

-   **Automatic Parameter Token**: In a public survey platform, security is paramount. Automatic parameter token deters unauthorized access or modification of survey data by converting URL parameters to token strings. This feature is crucial for maintaining the integrity of the survey results and ensuring the privacy of the respondents.

-   **Multiple Survey Management**: The ability to host and manage multiple surveys within a single app is essential for a public survey platform. This feature provides flexibility for survey creators, allowing them to cater to different audiences or research goals within the same platform.

-   **Dynamic Field Updates**: Dynamic field updates based on URL parameters offer a high degree of customization for each survey. This feature enhances the user experience by tailoring the survey to the individual respondent, which can lead to more accurate and meaningful survey results.

## Getting Started

1.  Clone this repository, or create a new project using the version control option in RStudio:

    ```         
    git clone https://github.com/dylanpieper/ShinySurveyJS.git
    ```

2.  Run the app:

    ``` r
    runApp()
    ```

3.  Access the app using a URL with appropriate parameter token:

    In `app.R`, if token_active \<- FALSE

    ```         
    http://your-app-url.com/?survey=dynamicSurvey&entity=Google
    ```

    In `app.R`, if token_active \<- TRUE

    ```         
    http://your-app-url.com/?survey=RhinocerosOvalTwoHundredTwentySevenTealStardust&entity=MeteorOctagonSlothRedFourHundredFiftySeven
    ```

    This is an example, and your token values will be different.

## File Structure

The file structure is modular and organized to facilitate easy customization and extension of the app. The key components are the `app.R` file, the `token.csv` file, the `www/` directory for web assets, and the `shiny/` directory for Shiny functions.

```         
ShinySurveyJS/
│
├── app.R                 # Main Shiny app file
├── token.csv           # Stores mappings between objects and URL tokens
│
├── www/                  # Directory for web assets
│   ├── _survey.js            # Client-side survey operations
│   ├── dynamicSurvey.json    # Example dynamic survey
│   └── staticSurvey.json     # Example static survey
│
└── shiny/                # Directory for Shiny functions
    ├── survey.R          # Defines surveyUI and surveyServer functions
    └── messages.R        # Defines messageUI and server message functions
    └── token.R         # Defines the token functions  
    └── versionJS.R       # Defines the version checking functions for the JS dependencies    
```

## URL Parameters and Token System

The token system for URL parameters enhances the security of the surveys by making it more challenging to directly access or modify URL parameters. The token functions can be easily modified or swapped in  `token.R.

### How it Works

When a new parameter (such as a survey, entity, or any custom parameter) is introduced, a unique token is generated and stored in `token.csv`, which is structured into two columns: `object` for the actual name or identifier, and `token` for the unique token.

## Creating Multiple Surveys

1.  Use the [SurveyJS](https://surveyjs.io/create-free-survey) visual editor to generate a survey JSON.
2.  Save the JSON as a new file (e.g., `newSurvey.json`) in the `www/` directory.
3.  The system will automatically detect the new survey and update `token.csv` with a unique token.
4.  Access the new survey using its token as a URL parameter:

```         
http://your-app-url.com/?survey=ThirtySevenCometLionHexagonLime
```

`ThirtySevenCometLionHexagonLime` is the automatically generated token for the new survey.

## Dynamically Updating Fields

The app can dynamically update fields based on various URL parameters. Modify and extend this functionality in `shiny/survey.R` to suit your needs.

Example of using multiple parameters:

```         
http://your-app-url.com/?survey=RhinocerosOvalTwoHundredTwentySevenTealStardust&entity=MeteorOctagonSlothRedFourHundredFiftySeven
```

The app will use these parameters to update relevant fields or settings based on your defined logic.

## To-do ✔️

-   Friendly initialization UI ✔️
-   Tokenize the URL query parameters ✔️
-   Integrate with a db server (supabase)
-   Add reCAPTCHA integration
