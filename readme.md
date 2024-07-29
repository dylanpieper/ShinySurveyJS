# ShinySurveyJS

ShinySurveyJS is a flexible and powerful framework that allows you to create and manage multiple dynamic surveys within a single Shiny app. By leveraging the capabilities of both Shiny and JavaScript ([SurveyJS](https://surveyjs.io/)), it provides a user-friendly experience for both survey creators and respondents.

## Motivation

This app framework is designed with a primary goal in mind: to create a robust, accessible, and secure platform that can host multiple public surveys without built-in user management. Each of the features mentioned above contributes to achieving this overarching objective.

-   **Automatic Parameter Hashing**: In a public survey platform, security is paramount. Automatic parameter hashing deters unauthorized access or modification of survey data by obfuscating URL parameters. This feature is crucial for maintaining the integrity of the survey results and ensuring the privacy of the respondents.

-   **Multiple Survey Management**: The ability to host and manage multiple surveys within a single app is essential for a public survey platform. This feature provides flexibility for survey creators, allowing them to cater to different audiences or research goals within the same platform.

-   **Dynamic Field Updates**: Dynamic field updates based on URL parameters offer a high degree of customization for each survey. This feature enhances the user experience by tailoring the survey to the individual respondent, which can lead to more accurate and meaningful survey results.

-   **Integration with SurveyJS**: Integration with the [SurveyJS](https://surveyjs.io/create-free-survey) visual editor, a free survey builder tool, makes survey creation more accessible for users without advanced technical skills. This feature lowers the entry barrier for survey creators, encouraging a broader range of users to utilize the platform.

-   **Result Presentation**: The ability to display survey results with tables and figures is a powerful tool for data analysis. This feature allows survey creators to draw insights from their data directly within the platform, streamlining the research process.

In summary, each of these features is necessary for creating a robust, user-friendly, and secure platform for hosting multiple public surveys. By focusing on security, accessibility, flexibility, and data analysis, ShinySurveyJS aims to be a comprehensive solution for public survey hosting.

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

ShinySurveyJS has an automated hashing system for URL parameters to enhance security by making it more challenging to directly access or modify URL parameters. It's important to highlight, though, that the current configuration does not eliminate the possibility of the hashes being programmatically discovered.

### Key Features

1.  **Automatic Hash Generation and Storage:** When a new parameter (such as a survey, entity, or any custom parameter) is introduced, a unique hash is generated and stored in `hash.csv`, which is structured into two columns: `object` for the actual name or identifier, and `hash` for the unique hash.

2.  **Hash Composition:** The hashes are made up of 10 random alphanumeric characters (e.g., "a1b2c3d4e5"), ensuring each hash is unique within the `hash.csv` file and managed automatically by the system.

3.  **URL Parameter Security:** By using these unique hashes in URLs instead of the actual object names or identifiers, the system enhances security and limits direct access or manipulation.

You can disable the hashing mechanism by setting `hash_active = FALSE` in `app.R`. It is recommended to keep this feature enabled to ensure the security of your app. If you disable the hashing mechanism, specify the name of the json file in the survey parameter:

```         
http://your-app-url.com/?survey=dynamicSurvey
```

## Creating Multiple Surveys

1.  Use the [SurveyJS](https://surveyjs.io/create-free-survey) visual editor to generate a survey JSON.
2.  Save the JSON as a new file (e.g., `NewSurvey.json`) in the `www/` directory.
3.  The system will automatically detect the new survey and update `hash.csv` with a unique hash.
4.  Access the new survey using its hash as a URL parameter:

```         
http://your-app-url.com/?survey=a1b2c3d4e5
```

Where `a1b2c3d4e5` is the automatically generated hash for the new survey.

## Dynamically Updating Fields

The app can dynamically update fields based on various URL parameters. Modify and extend this functionality in `shiny/survey.R` to suit your needs.

Example of using multiple parameters:

```         
http://your-app-url.com/?survey=a1b2c3d4e5&entity=f4d9z0g0o1
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
    http://your-app-url.com/?survey=a1b2c3d4e5&entity=f4d9z0g0o1
    ```

## To-do ✔️

-   Friendly initialization UI ✔️
-   Hash the URL query parameters ✔️
-   Create a dynamic JSON file option
    -   Paste JSON file fragments (e.g., demographics)
    -   Ability to paste data from db into JSON fields
-   Integrate with a db server (self-hosted MySQL/MariaDB server or Supabase)
-   Explore reCAPTCHA integration and bot prevention
