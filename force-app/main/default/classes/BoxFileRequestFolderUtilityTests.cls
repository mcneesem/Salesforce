@isTest
private class BoxFileRequestFolderUtilityTests {

    @testSetup
    private static void prepare() {
        BoxFileRequest__c settings = BoxFileRequest__c.getOrgDefaults();
        settings.IsEnabled__c = True;
        settings.BoxTemplateFolderId__c = '225207143235';
        settings.BoxApiEndpoint__c = 'https://api.box.com/2.0/collaborations/';
        settings.BoxFileRequestFolderName__c = 'Insperity File Request';
        upsert settings;

        Account acc = new Account();
        acc.name = 'test acc';
        acc.description = 'test description';
        insert acc;

        Contact con = new Contact();
        con.LastName = 'test con';
        con.Email = 'test@test.com';
        insert con;
    }

    @isTest
    private static void testQueueable() {
        Test.startTest();
        Opportunity opp = new Opportunity();
        opp.name = 'test';
        opp.StageName = 'Qualification';
        opp.AccountId = [ SELECT Id FROM Account LIMIT 1 ].Id;
        opp.CloseDate = Date.newInstance( 2023 , 12 , 9 );
        opp.Create_Box_com_Folder_s__c = True;
        insert opp;
        BoxFileRequestFolderUtility.enqueueJob( opp.Id );
        Test.stopTest();
    }

    @isTest
    private static void testOpportunityInsert() {
        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.name = 'test';
        opp.StageName = 'Qualification';
        opp.AccountId = [ SELECT Id FROM Account LIMIT 1 ].Id;
        opp.CloseDate = Date.newInstance( 2023 , 12 , 9 );
        opp.Create_Box_com_Folder_s__c = True;
        insert opp;

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = [ SELECT Id FROM Contact LIMIT 1 ].Id;
        ocr.OpportunityId = opp.Id;
        ocr.IsPrimary = True;
        insert ocr;

        Test.stopTest();
    }

    @isTest
    private static void testOpportunityUpdate() {
        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.name = 'test';
        opp.StageName = 'Qualification';
        opp.AccountId = [ SELECT Id FROM Account LIMIT 1 ].Id;
        opp.CloseDate = Date.newInstance( 2023 , 12 , 9 );
        opp.Create_Box_com_Folder_s__c = False;
        insert opp;

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = [ SELECT Id FROM Contact LIMIT 1 ].Id;
        ocr.OpportunityId = opp.Id;
        ocr.IsPrimary = True;
        insert ocr;

        opp.Create_Box_com_Folder_s__c = True;
        update opp;

        Test.stopTest();
    }

}
//
