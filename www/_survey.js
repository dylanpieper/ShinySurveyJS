$(document).ready(function() {
  var survey; // Create a variable to hold the survey object

  function initializeSurvey(surveyJSON) {
    try {
      if (typeof surveyJSON === 'string') {
        surveyJSON = JSON.parse(surveyJSON); // If the surveyJSON is a string, parse it into a JSON object
      }
      
      survey = new Survey.Model(surveyJSON); // Create a new survey model
      survey.onComplete.add(function(result) {
        Shiny.setInputValue("surveyData", JSON.stringify(result.data)); // When the survey is complete, send the data to the server
      });
      $("#surveyContainer").Survey({ model: survey }); // Render the survey in the surveyContainer div
    } catch (error) {
      console.error("Error initializing survey:", error); // If there is an error initializing the survey, print it to the console
    }
  }

  Shiny.addCustomMessageHandler("loadSurvey", function(surveyJSON) {
    initializeSurvey(surveyJSON); // When a loadSurvey message is received, initialize the survey with the provided JSON
  });

  Shiny.addCustomMessageHandler("updateChoices", function(data) {
    if (survey) {
      var targetQuestion = survey.getQuestionByName(data.targetQuestion); // Get the question to be updated
      if (targetQuestion) {
        targetQuestion.choices = data.choices.map(choice => ({ value: choice, text: choice })); // Update the choices for the question
        survey.render(); // Re-render the survey
      }
    }
  });
});