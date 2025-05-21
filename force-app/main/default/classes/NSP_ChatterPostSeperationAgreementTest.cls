@isTest
private class NSP_ChatterPostSeperationAgreementTest {

    @isTest
    private static void testChatterPost(){
        List<CollaborationGroup> collabList = [SELECT Id, Name from CollaborationGroup WHERE Name =:System.Label.NSP_SeparationAgreementGroupName LIMIT 1];
        if(collabList.isEmpty()){
            CollaborationGroup newCollaborationGroup = new CollaborationGroup();
            newCollaborationGroup = (CollaborationGroup)NSP_TestExtendedDataFactory.createSObject(new CollaborationGroup(), 'NSP_TestDataFactory.CollaborationGroupDefaults', false);
            newCollaborationGroup.Name = System.Label.NSP_SeparationAgreementGroupName;
            insert newCollaborationGroup;
        }

        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert newAccount;
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.Account = newAccount;
        insert newContact;

        Group newGroup = [Select ID from Group WHERE DeveloperName ='NSP_SeparationAgreement'];
        if(newGroup == null ){
            newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
            newGroup.Type ='Queue';
            newGroup.name ='Separation Agreement Team	';
            newGroup.DeveloperName ='NSP_SeparationAgreement' ;
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

        List<FeedItem> chatterFeed = [SELECT Id FROM FeedItem  WHERE ParentId = : newCase.Id];
        //verifying the chatter posted on the Case object record
        System.assertEquals(false,chatterFeed.size() >0 );

     }

}
//