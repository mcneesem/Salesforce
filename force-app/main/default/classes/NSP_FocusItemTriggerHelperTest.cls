@istest
private class NSP_FocusItemTriggerHelperTest {

    @testSetup
    private static void testData() {
        Id autoCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_CPQConstants.ACCOUNTGROUP_APINAME,'Automatically_Created');
        Id manuallyCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_CPQConstants.ACCOUNTGROUP_APINAME,'Manually_Created');

        NSP_Account_Group__c accountGroupRec = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        accountGroupRec.Name = NSP_CPQConstants.ACCOUNTGROUP_NAME2;
        accountGroupRec.NSP_Tag__c = 'Test Grp 1';
        accountGroupRec.NSP_Type__c = 'Account Health';
        accountGroupRec.RecordTypeId = autoCreatedRecordTypeId;
        INSERT accountGroupRec;

        NSP_Account_Group__c accountGroupRec2 = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        accountGroupRec2.Name = NSP_CPQConstants.ACCOUNTGROUP_NAME1;
        accountGroupRec2.NSP_Tag__c = 'Test Grp 2';
        accountGroupRec2.NSP_Type__c = 'OrgPlus Support Group';
        accountGroupRec2.RecordTypeId = manuallyCreatedRecordTypeId;
        INSERT accountGroupRec2;

        //Creating Account record
        Account accountRecord = (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
        accountRecord.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.Account_Status;
        accountRecord.NSP_First_Pay_Date__c = system.Today();
        INSERT accountRecord;

        //Creating Asset record
        Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Asset assetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset());
        assetRecord.AccountId = accountRecord.Id;
        assetRecord.NSP_AIMS_First_Pay_Date__c = system.Today();
        assetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        assetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.BTAssetSegment;
        assetRecord.RecordTypeId = woAssetRecordTypeId;
        assetRecord.NSP_Client__c = NSP_CPQConstants.ASSET_NSPCLIENT;
        assetRecord.NSP_Renewal_Date__c = system.Today();
        INSERT assetRecord;


    }

    //Positive
    @isTest
    private static void testCaseCreationForBusinessRestructureFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME2).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.BUSINESS_RESTRUCTURE;
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(1, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

    //Negative
    @isTest
    private static void testNoCaseCreationForBusinessRestructureFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME1).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.BUSINESS_RESTRUCTURE;
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(0, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

    //Positive
    @isTest
    private static void testCaseCreationForExtensiveSalaryReductionFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME2).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.FINANCIAL_RISK;
        focusItem.NSP_Detail__c = NSP_ServiceConstants.EXTENSIVE_SLALARY_REDUCTION;
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(1, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

    //Negative
    @isTest
    private static void testNoCaseCreationForExtensiveSalaryReductionFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME1).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.FINANCIAL_RISK;
        focusItem.NSP_Detail__c = NSP_ServiceConstants.EXTENSIVE_SLALARY_REDUCTION;
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(0, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

    //Positive
    @isTest
    private static void testCaseCreationForEconomicShiftFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME2).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.ECONOMIC_SHIFTS;
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(1, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

    //Negative
    @isTest
    private static void testNoCaseCreationForEconomicShiftFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME1).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.ECONOMIC_SHIFTS;
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(0, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

    //Positive
    @isTest
    private static void testCaseCreationForRiskMitigationFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME2).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.RISK_MITIGATION;
        focusItem.NSP_Detail__c = 'Client operates outside the compliance guidance provided by Insperity';
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(1, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

    //Negative
    @isTest
    private static void testNoCaseCreationForRiskMitigationFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME1).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.RISK_MITIGATION;
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(0, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

    @isTest
    private static void testCaseCreationForRapidGrowthOrDeclineFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME2).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.RAPID_GROWTH_OR_DECLINE;
        focusItem.NSP_Detail__c = NSP_ServiceConstants.DECLINING_20_PERCENT_OR_MORE;
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(1, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

    //Negative
    @isTest
    private static void testNoCaseCreationForRiskMitigationWithDetailFocusItem() {
        List<String> accountGroupFields = new List<String>{'Id',NSP_CPQConstants.NAME};
        String query = new NSP_QueryBuilder(NSP_CPQConstants.ACCOUNTGROUP_APINAME, accountGroupFields)
                        .addFilter(NSP_CPQConstants.NAME,NSP_CPQConstants.ACCOUNTGROUP_NAME1).build();
        NSP_Account_Group__c accGrpRecord = Database.query(query);

        List<String> assetFields = new List<String>{'Id',NSP_CPQConstants.NSPCLIENT_APINAME};
        String assetQuery = new NSP_QueryBuilder(NSP_CPQConstants.ASSET, assetFields)
                        .addFilter(NSP_CPQConstants.NSPCLIENT_APINAME,NSP_CPQConstants.ASSET_NSPCLIENT).build();
        Asset assetRecord = Database.query(assetQuery);

        Test.startTest();
        NSP_Focus_Item__c focusItem = (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), NSP_CPQConstants.FOCUSITEM_DEFAULTS, false);
        focusItem.Name = NSP_CPQConstants.FOCUSITEM_NAME;
        focusItem.NSP_Asset__c = assetRecord.Id;
        focusItem.Focus_Item__c = NSP_ServiceConstants.RAPID_GROWTH_OR_DECLINE;
        focusItem.NSP_Detail__c = NSP_ServiceConstants.DECLINING_20_PERCENT_OR_MORE;
        focusItem.NSP_Status__c = NSP_CPQConstants.ACTIVE;
        focusItem.NSP_Account_Group__c = accGrpRecord.Id;
        INSERT focusItem;
        System.assertEquals(0, [SELECT Count() FROM Case WHERE NSP_ClientNumber__c =: assetRecord.NSP_Client__c]);
        Test.StopTest();
    }

}
//
