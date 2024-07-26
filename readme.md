# ShinySurveyJS

ShinySurveyJS is a flexible framework that allows you to create and manage multiple surveys in a single app. It leverages the power of both Shiny and JavaScript ([SurveyJS](https://surveyjs.io/)) to provide a user-friendly experience, including a [free survey builder tool](https://surveyjs.io/create-free-survey) that generates a JSON file.

## File Structure

1.  `app.R`: This is the primary app file where the Shiny app is created and launched.

2.  `www/`: This directory holds the JS and JSON files for the surveys. Each survey should have its own JSON file in this directory.

    -   `_survey.js`: This JS file handles the client-side operations for the survey, such as initializing the survey and updating question choices.
    -   `dynamicSurvey.json`: This JSON file contains the first example survey, which includes an example of a dynamically updating question choices.
    -   `staticSurvey.json`: This JSON file contains the second example survey, which can be used to demonstrate switching between surveys.

3.  `shiny/`: This directory contains the Shiny UI and Server functions for the survey. These functions are defined in the `survey.R` file. Additional functions can be stored and sourced from files from this directory.

    -   `survey.R`: This file defines the `surveyUI` and `surveyServer` functions, which are responsible for creating the survey UI and managing the server-side operations.

## Creating Multiple Surveys

You can create multiple surveys within the same app by using different JSON files for each survey. Each JSON file should define the structure and questions for a survey.

To initialize or switch between surveys, use the `survey` query parameter in the URL. For example, if you have two surveys defined in `dynamicSurvey.json` and `staticSurvey.json`, you can switch between them using the URLs:

```
http://your-app-url.com/?survey=dyanmicSurvey
```
OR
```         
http://your-app-url.com/?survey=staticSurvey
```

## Dynamically Updating Fields

The app also has the ability to dynamically update question fields based on the `entity` query parameter. This query parameter can be modified and extended in the `shiny/survey.R` file to suit your needs.

For example, if you have a question in your survey that asks for the location of an entity, you can pre-populate the choices for this question based on the entity specified in the URL.

To specify an entity, use the `entity` query parameter in the URL:

```         
http://your-app-url.com/?survey=dyanmicSurvey&entity=Entity1
```

In this case, the choices for the `location` question will be updated based on the locations associated with `Entity1`.

## Getting Started

To get started with the Shiny Survey App, simply clone this repository, install the required R packages, and run `app.R`. You must define a survey in the query parameter in the URL to initialize a survey, e.g., `?survey=dyanmicSurvey`.

## Conclusion

ShinySurveyJS provides a powerful flexible platform for creating and managing surveys. With its ability to handle multiple surveys and dynamically update fields, and leverage all of features in the [SurveyJS](https://surveyjs.io/) library, it is an ideal solution for a wide range of survey needs.

------------------------------------------------------------------------

## To-do ✔️

-   Automatically retreive the most recent version SurveyJS from UNPKG

-   Integrate with a db server (self-hosted MySQL/MariaDB server or Supabase)
