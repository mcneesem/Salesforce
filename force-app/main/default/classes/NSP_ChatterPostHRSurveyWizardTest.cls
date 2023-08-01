/**
Apex Class Name      :  NSP_ChatterPostHRSurveyWizardTest
Version              :  1.0     
Author               :   Jatin                                                                     
Created Date         :  06/01/22  
Function             :  This class is used as a test class to  NSP_ChatterPostHRSurveyWizardTest
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Tejas                 8/5/2022           First Iteration
*/

@isTest
public class NSP_ChatterPostHRSurveyWizardTest {

    @isTest(SeeAllData=true)
    static void testChatterPost(){
         List<case> caseList = new List<Case>();
        
        CollaborationGroup newCollaborationGroup;
        List<CollaborationGroup> newCollaborationGroupList = [SELECT Id, Name from CollaborationGroup WHERE Name =:System.Label.NSP_HrSurveyGroupName LIMIT 1];
       if(newCollaborationGroupList.size() > 0 ){
        newCollaborationGroup = newCollaborationGroupList[0];
       } else {
           newCollaborationGroup = (CollaborationGroup)NSP_TestExtendedDataFactory.createSObject(new CollaborationGroup(), 'NSP_TestDataFactory.CollaborationGroupDefaults', false);
        	newCollaborationGroup.Name = System.Label.NSP_HrSurveyGroupName;
        	insert newCollaborationGroup;
       }
       
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        //insert newAccount;
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.AccountId = newAccount.Id;
       insert newContact;
     
       Group newGroup = [Select ID from Group WHERE DeveloperName ='NSP_HR_COE'];
        if(newGroup == null ){
            newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false); 
            newGroup.Type ='Queue';
            newGroup.name ='HR COE Team';
            newGroup.DeveloperName ='NSP_HR_COE' ;
            insert newGroup; 
            QueuesObject testQueue = new QueueSObject(QueueID = newGroup.id, SObjectType = 'Case');
            System.runAs(new User(Id = UserInfo.getUserId())){
            insert testQueue;}
        }
    
       Id recordTypePEOID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
       Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
       newCase.RecordTypeId = recordTypePEOID;
       newCase.OwnerId = newGroup.Id;
       newCase.ContactId = newContact.Id;
       newCase.AccountId = newAccount.Id; 
       insert newCase;
       caseList.add(newCase);
       List<FeedItem> chatterFeed = [SELECT Id FROM FeedItem  WHERE ParentId = : newCase.Id];
        NSP_ChatterPostHRSurveyWizard.sendSperationAgreementPost(caseList);
       //verifying the chatter posted on the Case object record
       System.assertEquals(false,chatterFeed.size() >0 );

     }

}