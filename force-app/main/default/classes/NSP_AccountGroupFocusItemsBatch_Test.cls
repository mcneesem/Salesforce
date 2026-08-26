@isTest
private class NSP_AccountGroupFocusItemsBatch_Test {
    private static final string SYSTEM_GENERATED_FOCUS_ITEM = 'NSP_System_Generated_Focus_Item';
    private static final string FOCUS_ITEM_OBJECT = 'NSP_Focus_Item__c';

    @testSetup
    private static void setupProjectData(){
        Id recordTypeWoAsset =  NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        // Create Acc records with external id
        Account charlieAcc = new Account(Name = 'Charlie', NSP_OneVoice_External_ID__c = 'charlieAcc');
        Account charlieAccRef = new Account(NSP_OneVoice_External_ID__c = 'charlieAcc');

        // Create Asset Records
        Asset woAsset = new Asset(Name = 'WO', recordtypeId = recordTypeWoAsset, NSP_Asset_External_ID__c = 'woAsset', NSP_Client__c='3355345', NSP_AIMS_Original_First_Pay_Date__c = system.today().addMonths(-12), Account = charlieAccRef);

        // Create the accounts, Assets.
        Test.startTest();
        Database.SaveResult[] results = Database.insert(new SObject[] {
            charlieAcc, woAsset
        });
        Test.stopTest();
    }

    @isTest
    private static void testMethodForFocusBatch() {
        Test.startTest();
        Database.executeBatch(new NSP_AccountGroupFocusItemsBatch());
        Test.stopTest();
        system.assertEquals(2, Database.Query(new NSP_QueryBuilder( FOCUS_ITEM_OBJECT, new List<String>{'Id'}).addLimit(15).build()).size(), '12 Focus Items');
    }

    @isTest
    private static void testMethodForSchedule() {
        DateTime runtime = System.now().addDays( 1 );
        String cronExp = '0 0 0 ' + runtime.day() + ' ' + runtime.month() + ' ? ' + runtime.year();
        Test.startTest();
        String jobId = System.schedule('NSP_AccountGroupFocusItemsBatchTest',
                                       cronExp,
                                       new NSP_AccountGroupFocusItemsBatch ()
                                      );

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,
                          NextFireTime
                          FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(cronExp,  ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }

    @isTest
    private static void testMethodExistingFocusItems() {
        List<NSP_Account_Group__c> lstAccGrp = Database.Query(new NSP_QueryBuilder( 'NSP_Account_Group__c', new List<String>{'Id'}).addFilter('NSP_Type__c', new List<String>{'Account Health','Renewal Probability'} , NSP_QueryBuilder.Operator.INCLUDES).addLimit(2).build());
        List<NSP_Focus_Item__c> lstFocusItems = new List<NSP_Focus_Item__c>();
        lstFocusItems.add(new NSP_Focus_Item__c (
            Area_of_Focus__c = NSP_ServiceConstants.CUSTOMER_RELATIONSHIP,
            Focus_Item__c = NSP_ServiceConstants.NO_INSPERITY_401K,
            RecordTypeId = NSP_GenericRecordType.getRecordTypeId(FOCUS_ITEM_OBJECT, SYSTEM_GENERATED_FOCUS_ITEM),
            NSP_Detail__c = '',
            NSP_Estimated_Impact__c = NSP_ServiceConstants.UNFAVORABLE,
            NSP_Status__c = NSP_ServiceConstants.STATUS_ACTIVE,
            NSP_Start_Date__c = System.Today(),
            NSP_System_Generated__c = 'Y',
            NSP_Account_Group__c = lstAccGrp[0].Id
        ));
        lstFocusItems.add(new NSP_Focus_Item__c (
            Area_of_Focus__c = NSP_ServiceConstants.CUSTOMER_RELATIONSHIP,
            Focus_Item__c = NSP_ServiceConstants.EARLY_TENURE,
            RecordTypeId = NSP_GenericRecordType.getRecordTypeId(FOCUS_ITEM_OBJECT, SYSTEM_GENERATED_FOCUS_ITEM),
            NSP_Detail__c = NSP_ServiceConstants.EARLY_TENURE_CLIENT,
            NSP_Estimated_Impact__c = NSP_ServiceConstants.SOME_WHAT_UNFAVORABLE,
            NSP_Status__c = NSP_ServiceConstants.STATUS_ACTIVE,
            NSP_Start_Date__c = System.Today(),
            NSP_System_Generated__c = 'Y',
            NSP_Account_Group__c = lstAccGrp[1].Id
        ));
        insert lstFocusItems;
        Test.startTest();
        Database.executeBatch(new NSP_AccountGroupFocusItemsBatch());
        Test.stopTest();
        system.assertEquals(3, Database.Query(new NSP_QueryBuilder( FOCUS_ITEM_OBJECT, new List<String>{'Id'}).addLimit(15).build()).size(), '4 Focus Items');
    }

    @isTest
    private static void testMethodExistingFocusItemsClosed() {
        Asset asset = Database.Query(new NSP_QueryBuilder( 'Asset', new List<String>{'Id', 'NSP_Account_Status__c'}).addLimit(1).build());
        asset.NSP_AIMS_Original_First_Pay_Date__c = NULL;
        update asset;

        List<NSP_Account_Group__c> lstAccGrp = Database.Query(new NSP_QueryBuilder( 'NSP_Account_Group__c', new List<String>{'Id'}).addFilter('NSP_Type__c', new List<String>{'Account Health','Renewal Probability'} , NSP_QueryBuilder.Operator.INCLUDES).addLimit(2).build());
        List<NSP_Focus_Item__c> lstFocusItems = new List<NSP_Focus_Item__c>();
        lstFocusItems.add(new NSP_Focus_Item__c (
            Area_of_Focus__c = NSP_ServiceConstants.CUSTOMER_RELATIONSHIP,
            Focus_Item__c = NSP_ServiceConstants.NO_INSPERITY_401K,
            RecordTypeId = NSP_GenericRecordType.getRecordTypeId(FOCUS_ITEM_OBJECT, SYSTEM_GENERATED_FOCUS_ITEM),
            NSP_Detail__c = '',
            NSP_Estimated_Impact__c = NSP_ServiceConstants.UNFAVORABLE,
            NSP_Status__c = NSP_ServiceConstants.STATUS_ACTIVE,
            NSP_Start_Date__c = System.Today(),
            NSP_System_Generated__c = 'Y',
            NSP_Account_Group__c = lstAccGrp[0].Id
        ));
        lstFocusItems.add(new NSP_Focus_Item__c (
            Area_of_Focus__c = NSP_ServiceConstants.CUSTOMER_RELATIONSHIP,
            Focus_Item__c = NSP_ServiceConstants.EARLY_TENURE,
            RecordTypeId = NSP_GenericRecordType.getRecordTypeId(FOCUS_ITEM_OBJECT, SYSTEM_GENERATED_FOCUS_ITEM),
            NSP_Detail__c = NSP_ServiceConstants.EARLY_TENURE_CLIENT,
            NSP_Estimated_Impact__c = NSP_ServiceConstants.SOME_WHAT_UNFAVORABLE,
            NSP_Status__c = NSP_ServiceConstants.STATUS_ACTIVE,
            NSP_Start_Date__c = System.Today(),
            NSP_System_Generated__c = 'Y',
            NSP_Account_Group__c = lstAccGrp[1].Id
        ));
        insert lstFocusItems;
        Test.startTest();
        Database.executeBatch(new NSP_AccountGroupFocusItemsBatch());
        Test.stopTest();
        system.assertEquals(2, Database.Query(new NSP_QueryBuilder( FOCUS_ITEM_OBJECT, new List<String>{'Id'}).addLimit(15).build()).size(), '4 Focus Items');
    }

}
//