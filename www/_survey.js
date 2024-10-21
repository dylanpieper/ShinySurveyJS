$(document).ready(function() {
  var survey; // Holds the survey object

  function initializeSurvey(surveyJSON) {
    try {
      // Parse surveyJSON string into an object, if necessary
      if (typeof surveyJSON === 'string') {
        surveyJSON = JSON.parse(surveyJSON);
      }
      
      // Initialize the survey model with the JSON
      survey = new Survey.Model(surveyJSON);
      
      // Setup to send survey results to server upon completion
      survey.onComplete.add(function(result) {
        Shiny.setInputValue("surveyData", JSON.stringify(result.data));
      });
      
      // Display the survey in the designated container
      $("#surveyContainer").Survey({ model: survey });
      
    } catch (error) {
      // Log initialization errors
      console.error("Error initializing survey:", error);
    }
  }

  // Handle survey loading requests
  Shiny.addCustomMessageHandler("loadSurvey", function(surveyJSON) {
    initializeSurvey(surveyJSON);
  });

  // Handle requests to update survey choices dynamically
  Shiny.addCustomMessageHandler("updateChoices", function(data) {
    if (survey) {
      var targetQuestion = survey.getQuestionByName(data.targetQuestion);
      if (targetQuestion) {
        // Update question choices based on incoming data
        targetQuestion.choices = data.choices.map(choice => ({ value: choice, text: choice }));
        survey.render(); // Refresh the survey display
      }
    }
  });
});