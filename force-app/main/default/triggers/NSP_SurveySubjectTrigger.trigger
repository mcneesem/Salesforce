//this trigger method handles insert operations
trigger NSP_SurveySubjectTrigger on SurveySubject (after insert) {
    NSP_TriggerDispatcher.run(new NSP_SurveySubjectTriggerHandler(), 'NSP_Survey_Subject_Trigger');
}