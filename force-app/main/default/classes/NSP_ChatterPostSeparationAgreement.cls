/**
* Name : NSP_ChatterPostSeparationAgreement
* 
*/
global  class NSP_ChatterPostSeparationAgreement {

    @InvocableMethod(label='Separation Agreement') 
    global static void sendSperationAgreementPost(List<Case> caseList){
        String separationAgreementGroupName = System.Label.NSP_SeparationAgreementGroupName;
        Id separationAgreementGroupNameId ;
         if(separationAgreementGroupName !=null && String.isNotBlank(separationAgreementGroupName)){
            separationAgreementGroupNameId = [SELECT Id, Name from CollaborationGroup WHERE Name = : separationAgreementGroupName LIMIT 1 ].Id;
         }
     
         if(separationAgreementGroupNameId != null){
            String chatMsg= 'New HR Separation Agreement Request Case created and assigned to team';
            NSP_ChatterPostFromProcessBuilder.postChatterFeed(caseList, separationAgreementGroupNameId,chatMsg);
     
         }
     }
}