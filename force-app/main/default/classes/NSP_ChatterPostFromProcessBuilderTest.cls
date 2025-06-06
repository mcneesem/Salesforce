@isTest
private class NSP_ChatterPostFromProcessBuilderTest {

    @isTest
    private static void testChatterPost(){
       CollaborationGroup newCollaborationGroup;
       List<CollaborationGroup> newCollaborationGroupList = [SELECT Id, Name from CollaborationGroup WHERE Name =:System.Label.NSP_ReportDevelopmentGroupName LIMIT 1];
       if(newCollaborationGroupList.size() > 0 ){
        newCollaborationGroup = newCollaborationGroupList[0];
       } else {
            newCollaborationGroup   = (CollaborationGroup)NSP_TestExtendedDataFactory.createSObject(new CollaborationGroup(), 'NSP_TestDataFactory.CollaborationGroupDefaults', false);
            newCollaborationGroup.Name = System.Label.NSP_ReportDevelopmentGroupName;
            //inserting new collaboration group
            insert newCollaborationGroup;
       }

        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert newAccount;

         //creating new contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.Account = newAccount;
        //inserting contact
        insert newContact;

       Group newGroup = [Select ID from Group WHERE DeveloperName ='NSP_ReportDevelopment'];
        if(newGroup == null ){
            newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false);
            newGroup.Type ='Queue';
            newGroup.name ='Report Development';
            newGroup.DeveloperName ='NSP_ReportDevelopment' ;
            insert newGroup;
            QueuesObject testQueue = new QueueSObject(QueueID = newGroup.id, SObjectType = 'Case');
            System.runAs(new User(Id = UserInfo.getUserId())){
                //creating new queue
            insert testQueue;}
        }

    // getting case peo recordtype id
       Id recordTypePEOID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
       //creating a new case
       Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
       newCase.RecordTypeId = recordTypePEOID;
       newCase.OwnerId = newGroup.Id;
       newCase.ContactId = newContact.Id;
       newCase.AccountId = newAccount.Id;
       insert newCase;

        List<Case> caseList = new List<Case>();
        caseList.add(newCase);

        List<FeedItem> chatterFeed = [SELECT Id FROM FeedItem  WHERE ParentId = : newCase.Id];
        try {
            NSP_ChatterPostFromProcessBuilder.sendReportDevelopmentPost(caseList);
        } catch ( Exception e ) {
            System.debug( ' ~ CATCH ~ e=' + e );
        }
        //verifying the chatter posted on the Case object record
        System.assertEquals(false,chatterFeed.size() >0 );

     }

}
//