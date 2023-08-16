global class NSP_ChatterPostHRSurveyWizard {

        @InvocableMethod(label='HR Survey') 
         /***********************************************************************************************
         * MethodName: sendSperationAgreementPost
         * Params:      List<Case> caseList
         * ********************************************************************************************/
        global static void sendSperationAgreementPost(List<Case> caseList){
            String hrSurveyGroupName = System.Label.NSP_HrSurveyGroupName;
            Id hrSurveyGroupNameId ;
             if(hrSurveyGroupName !=null && String.isNotBlank(hrSurveyGroupName)){
                hrSurveyGroupNameId = [SELECT Id, Name from CollaborationGroup WHERE Name = : hrSurveyGroupName LIMIT 1 ].Id;
             }
         
             if(hrSurveyGroupNameId != null){
                String chatMsg= 'New HR Survey Request Case created and assigned to team';
                NSP_ChatterPostFromProcessBuilder.postChatterFeed(caseList, hrSurveyGroupNameId,chatMsg);
         
             }
         }
    }
