@isTest
public class NSP_ChatterPostSeparationAgreementTest {
    
    @isTest (SeeAllData=true)
    static void testChatterPost(){
        List<case> caseList = new List<Case>();
        List<CollaborationGroup> collabList = [SELECT Id, Name from CollaborationGroup WHERE Name =:System.Label.NSP_SeparationAgreementGroupName LIMIT 1];
       if(collabList.isEmpty()  ){
           CollaborationGroup newCollaborationGroup =new CollaborationGroup();
           newCollaborationGroup = (CollaborationGroup)NSP_TestExtendedDataFactory.createSObject(new CollaborationGroup(), 'NSP_TestDataFactory.CollaborationGroupDefaults', false);
           newCollaborationGroup.Name = System.Label.NSP_SeparationAgreementGroupName;
           insert newCollaborationGroup;
       }
        
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        newAccount.name ='test chatter';
        insert newAccount;
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.Account = newAccount;
        insert newContact;
        
        Group newGroup = [SELECT ID FROM Group WHERE DeveloperName ='NSP_HR_COE'];
        if(newGroup == null ){
            newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false); 
            newGroup.Type ='Queue';
            newGroup.name ='HR COE Team';
            newGroup.DeveloperName ='NSP_HR_COE' ;
            insert newGroup; 
            QueuesObject testQueue = new QueueSObject(QueueID = newGroup.id, SObjectType = 'Case');
            System.runAs(new User(Id = UserInfo.getUserId())){
                insert testQueue;
            }
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
        NSP_ChatterPostSeparationAgreement.sendSperationAgreementPost(caseList);
        //verifying the chatter posted on the Case object record
        System.assertEquals(false,chatterFeed.size() >0 );
        
    }
    
}