@isTest
private with sharing class NSP_ChatterPostController_Test {

    @isTest
    private static void testChatterPost(){
        Id recordTypePEOID = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.PEO);

        Account newAccount = new Account();
        newAccount.Name = 'Test Account';
        insert newAccount;

        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCase.AccountId = newAccount.Id;
        newCase.RecordTypeId = recordTypePEOID;
        newCase.NSP_Category__c = NSP_SalesConstants.HR_SERVICES;
        newCase.NSP_SubCategory__c = NSP_SalesConstants.Discuss_Paid_Sick_Leave;
        newCase.Status = NSP_SalesConstants.OPEN;
        newCase.Subject = 'Employees work in New Jersey, California, New York, Chicago';
        insert newCase; 
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name= 'PEO Service' LIMIT 1];
        String uniqueUserName = 'PEOSerivceUserNSP' + DateTime.now().getTime() + '@testorg.com';

        User user = new User(Alias = 'standt', 
                             Email='standarduser@insperity.com',
                             EmailEncodingKey='UTF-8', 
                             LastName='Testing',
                             LanguageLocaleKey='en_US',
                             LocaleSidKey='en_US', 
                             ProfileId = profileId.Id,
                             TimeZoneSidKey = 'America/Los_Angeles',
                             UserName = uniqueUserName);
        insert user;
               
        Test.startTest();
        NSP_ChatterPostController.InputResponse inputParameters = new NSP_ChatterPostController.InputResponse();
        inputParameters.relatedId =  newCase.Id;
        inputParameters.userIds = new List<String>{ user.Id };
        inputParameters.subject = 'Employees work in New Jersey, California, New York, Chicago has been assigned to the';
        NSP_ChatterPostController.postChatterFeed(new List<NSP_ChatterPostController.InputResponse>{inputParameters});
        Test.stopTest();

        List<FeedItem> chatterFeeds = [
            SELECT Id , Body
            FROM FeedItem
            WHERE ParentId = :newCase.Id
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        FeedItem chatterFeed = null;
        if ( ( chatterFeeds != null ) && !chatterFeeds.isEmpty() ) {
            chatterFeed = chatterFeeds[0];
        }
        if ( chatterFeed != null ) {
            Boolean containsBody = chatterFeed.body.contains('Employees work in New Jersey, California, New York, Chicago has been assigned to the');
            //verifying the chatter posted on the Case object record
            System.assertEquals(containsBody,true);
        }
    }

}
//