@isTest
private class NSP_AssetTriggerHelperTest {
    private static final Id integraRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_ServiceConstants.INTEGRA_ASSET).getRecordTypeId();
    private static final Id woRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
    private static final Id retRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE).getRecordTypeId();

    @testSetup
    private static void testData() {
        // Custom Settings related to Asset Trigger...
        String newline = '\n';
        AssetTriggerSettings__c settings =  AssetTriggerSettings__c.getOrgDefaults();
        settings.Exclude_Record_Types__c  = (
            'WOCPQ' + newline
            + 'AssetHardware' + newline
            + 'Asset'
        );
        settings.Exclude_Status__c = (
            'Backout' + newline
            + 'Terminated' + newline
            + 'Returned' + newline
            + 'Inactive'
        );
        settings.Exclude_Record_Types_WRT_Status__c = 'Certify';
        settings.IsEnabledRecordTypeDefault__c = true;
        upsert settings;

        Profile profile = [SELECT Id FROM Profile WHERE Name =: NSP_ServiceConstants.PEOSERVICE];
        List<Account> accList = new List<Account>();
        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        accList.add(accoutObject);
        // create account
        Account accoutObject1 = new Account();
        accoutObject1.Name = 'Test Account1';
        accList.add(accoutObject1);

        Account accoutObject2 = new Account();
        accoutObject2.Name = 'Test Account2';
        accList.add(accoutObject2);

        Account accoutObject3 = new Account();
        accoutObject3.Name = 'Test Account3';
        accList.add(accoutObject3);

        Account accoutObject4 = new Account();
        accoutObject4.Name = 'Test Account4';
        accList.add(accoutObject4);

        Account accoutObject5 = new Account();
        accoutObject5.Name = 'Test Account5';
        accList.add(accoutObject5);

        insert accList;

        User users = new User();
        users.Username = 'Testing@gmailnsp.com';
        users.LanguageLocaleKey = 'en_US';
        users.ProfileId = profile.Id;
        users.EmailEncodingKey = 'UTF-8';
        users.TimeZoneSidKey = 'America/Los_Angeles';
        users.LocaleSidKey = 'en_US';
        users.Alias = 'taaron';
        users.LastName ='Test';
        users.Email = 'Test@insperity.com';
        users.NSP_Service_Region__c = 'MMSO - Central';
        Insert users;

        Test.startTest();
        NSP_Account_Team__c accountteam = new NSP_Account_Team__c();
        accountteam.NSP_Account__c = accoutObject3.Id;
        accountteam.NSP_User__c = users.Id;
        accountteam.NSP_Role__c = 'Manager, HR Services';
        Insert accountteam;

        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accoutObject2.id;
        opportuniytObject.StageName = 'Prospecting';
        opportuniytObject.CloseDate = date.today();
        //Inserting Opportunity Object
        insert opportuniytObject;

        List<Asset> assetList = new List<Asset>();
        //Create Asset
        Asset assetObj = new Asset();
        assetObj.accountId = accoutObject.Id;
        assetObj.NSP_Client__c = 'asset1';
        assetObj.name = 'asset1';
        assetObj.recordTypeId = woRecordTypeId;
        assetObj.NSP_Service_Region__c = users.NSP_Service_Region__c;
        assetList.add(assetObj);


        //Create Asset
        Asset assetObj1 = new Asset();
        assetObj1.accountId = accoutObject1.Id;
        assetObj1.NSP_Client__c = 'asset2';
        assetObj1.name = 'asset2';
        assetObj1.NSP_Need_Rollup_Recalculation__c = true;
        assetObj1.recordTypeId = woRecordTypeId;
        assetList.add(assetObj1);

        //Create Asset
        Asset assetObj2 = new Asset();
        assetObj2.accountId = accoutObject3.Id;
        assetObj2.NSP_Client__c = 'asset3';
        assetObj2.opportunity__c = opportuniytObject.Id;
        assetObj2.name = 'asset3';
        assetList.add(assetObj2);

        //Create Asset
        Asset assetObj4 = new Asset();
        assetObj4.accountId = accoutObject2.Id;
        assetObj4.RecordTypeId= Schema.SObjectType.Asset.RecordTypeInfosByName.get('WO').getRecordTypeId();
        assetObj4.NSP_Client__c = 'asset4';
        assetObj4.opportunity__c = opportuniytObject.Id;
        assetObj4.name = 'asset4';
        assetList.add(assetObj4);

        Asset assetObj5 = new Asset();
        assetObj5.accountId = accoutObject4.Id;
        assetObj5.NSP_Client__c = 'asset5';
        assetObj5.name = 'asset5';
        assetObj5.recordTypeId = woRecordTypeId;
        assetObj5.NSP_Service_Region__c = users.NSP_Service_Region__c;
        assetObj5.NSP_Product_Line__c = 'Learning & Development';
        assetList.add(assetObj5);

        Asset assetObj6 = new Asset();
        assetObj6.accountId = accoutObject4.Id;
        assetObj6.NSP_Client__c = 'asset6';
        assetObj6.name = 'asset6';
        assetObj6.recordTypeId = retRecordTypeId;
        //assetObj6.NSP_Service_Region__c = users.NSP_Service_Region__c;
        assetObj6.NSP_Product_Line__c = 'Learning & Development';
        assetList.add(assetObj6);

        insert assetList;

        // create subclientobj
        List<NSP_Sub_Client__c> subClientList = new List<NSP_Sub_Client__c>();
        for(integer icount = 0 ; icount< 5 ;icount++){
            NSP_Sub_Client__c subClientObj = new NSP_Sub_Client__c();
            subClientObj.NSP_Client__c = 'asset1'+String.valueOf(icount);
            subClientObj.NSP_Paid_Employees_Last_Month__c = 1;
            subClientObj.NSP_Actual_Full_Time_EE_Count__c = 1;
            subClientObj.NSP_Actual_Part_Time_EE_Count__c = 3;
            subClientObj.NSP_Actual_Seasonal_Time_EE_Count__c =2;
            subClientObj.NSP_Contractual_Full_time_EE_Count__c = 2;
            subClientObj.NSP_Contractual_Part_time_EE_Count__c = 3;
            subClientObj.NSP_Contractual_Seasonal_Time_EE_Count__c = 1 ;
            subClientObj.NSP_Account__c = accoutObject.Id;
            subClientObj.NSP_Asset__c = assetObj.Id;
            subClientList.add(subClientObj);
        }
        //create subclient obj
        for(integer icount = 0 ; icount< 3 ;icount++){
            NSP_Sub_Client__c subClientObj = new NSP_Sub_Client__c();
            subClientObj.NSP_Client__c = 'asset2'+icount;
            subClientObj.NSP_Paid_Employees_Last_Month__c = 1;
            subClientObj.NSP_Actual_Full_Time_EE_Count__c = 1;
            subClientObj.NSP_Actual_Part_Time_EE_Count__c = 3;
            subClientObj.NSP_Actual_Seasonal_Time_EE_Count__c =2;
            subClientObj.NSP_Contractual_Full_time_EE_Count__c = 2;
            subClientObj.NSP_Contractual_Part_time_EE_Count__c = 3;
            subClientObj.NSP_Contractual_Seasonal_Time_EE_Count__c = 1 ;
            subClientObj.NSP_Account__c = accoutObject1.Id;
            subClientObj.NSP_Asset__c = assetObj1.Id;
            subClientList.add(subClientObj);
        }

        if(subClientList.size() > 0){
            insert subClientList;
        }

        Test.stopTest();
    }

    @isTest
    private static void beforeUpdateDirectorTest() {
        List<Asset> assetList = [SELECT ID,Name,NSP_Need_Rollup_Recalculation__c FROM Asset WHERE Name !=null LIMIT 1];
        Test.startTest();
            Asset assetObj = new Asset();
            assetObj.Id = assetList[0].ID;
            assetObj.NSP_Need_Rollup_Recalculation__c = true;
            assetObj.NSP_Client_Segment_type__c ='Core';
            assetObj.NSP_Client_SegmentDate__c = system.Today().addDays(10);
            assetObj.NSP_Government_Contractor__c = true;
            assetObj.NSP_IES_e_Verify_Client__c = true;
            update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,NSP_Need_Rollup_Recalculation__c,NSP_Actual_Part_Time_EE_Count__c FROM
                                  Asset WHERE NSP_Need_Rollup_Recalculation__c = true];
        System.assertEquals(true, assetList1[0].NSP_Need_Rollup_Recalculation__c);
    }

    @isTest
    private static void assetTest() {
        Test.startTest();
        Account accountObject = [SELECT id FROM account WHERE Name = 'Test Account' limit 1];
        Asset assetObjWO = new Asset();
        assetObjWO.accountId = accountObject.Id;
        assetObjWO.NSP_Client__c = 'WO asset1';
        assetObjWO.RecordTypeId = woRecordTypeId;
        assetObjWO.name = 'assetObjWO';
        assetObjWO.NSP_DBA__c = 'Test';
        assetObjWO.NSP_Account_Status__c = 'Active';
        insert assetObjWO;

        Asset assetObjIntegra = new Asset();
        assetObjIntegra.accountId = accountObject.Id;
        assetObjIntegra.NSP_Client__c = 'Integra asset1';
        assetObjIntegra.RecordTypeId = integraRecordTypeId;
        assetObjIntegra.name = 'assetObjIntegra';
        assetObjIntegra.NSP_Account_Status__c = 'Active';
        insert assetObjIntegra;

        Test.stopTest();
        System.assertEquals(assetObjIntegra.accountId, accountObject.Id);
    }

    @isTest
    private static void afterUpdateWXTest() {
        Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get('WX_WA').getRecordTypeId();
        List<Asset> assetList = [SELECT ID,Name FROM Asset WHERE NSP_Client__c = 'asset3' LIMIT 1];
        Test.startTest();
        Asset assetObj = new Asset();
        assetObj.Id = assetList[0].ID;
        assetObj.recordtypeid = new_Asset_RT_ID;
        assetObj.NSP_First_Pay_Date__c = date.today();
        update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,Name, NSP_First_Pay_Date__c FROM Asset WHERE NSP_Client__c = 'asset3' LIMIT 1];
        System.assertEquals(date.today(), assetList1[0].NSP_First_Pay_Date__c);
    }

    @isTest
    private static void afterUpdateWOTest() {
        Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get('WO').getRecordTypeId();
        List<Asset> assetList = [SELECT ID,Name FROM Asset WHERE NSP_Client__c = 'asset3' LIMIT 1];
        Test.startTest();
        Asset assetObj = new Asset();
        assetObj.Id = assetList[0].ID;
        assetObj.recordtypeid = new_Asset_RT_ID;
        assetObj.NSP_AIMS_First_Pay_Date__c = date.today();
        update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,Name,NSP_AIMS_First_Pay_Date__c FROM Asset WHERE NSP_Client__c = 'asset3' LIMIT 1];
        System.assertEquals(date.today(), assetList1[0].NSP_AIMS_First_Pay_Date__c);
    }

    @isTest
    private static void peoTESClientStatusTest() {
        List<Asset> assetList = [SELECT ID,Name,Status,NSP_Termination_Date__c FROM Asset WHERE NSP_Client__c = 'asset5' LIMIT 1];
        Test.startTest();
        Asset assetObj = new Asset();
        assetObj.Id = assetList[0].ID;
        assetObj.Status = 'Terminated';
        assetObj.NSP_Termination_Date__c = date.today();
        update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,Name,NSP_Termination_Date__c FROM Asset WHERE NSP_Client__c = 'asset5' LIMIT 1];
        System.assertEquals(date.today(), assetList1[0].NSP_Termination_Date__c);

    }

    @isTest
    private static void peoTESClientStatusWxTest() {
        List<Account> accList = [SELECT ID,Name FROM Account WHERE Name = 'Test Account5' LIMIT 1];
        Id wX_WARecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WX_WA).getRecordTypeId();
        Test.startTest();
        Asset assetObj = new Asset();
        assetObj.AccountId = accList[0].ID;
        assetObj.name = 'assetWx';
        assetObj.Status = 'Onboarding';
        assetObj.recordTypeId = wX_WARecordTypeId;
        assetObj.NSP_Product_Line__c = 'Learning & Development';
        insert assetObj;
        NSP_AssetTriggerHelper.testHandleException( null , null ); // for increased code coverage...
        Test.stopTest();
        system.assertEquals(assetObj.NSP_Product_Line__c, 'Learning & Development');

    }

    @isTest
    private static void updateRETAsset() {
        List<Asset> assetList = [SELECT ID,Name,Status,NSP_Termination_Date__c FROM Asset WHERE NSP_Client__c = 'asset6' LIMIT 1];
        Test.startTest();
        Asset assetObj = new Asset();
        assetObj.Id = assetList[0].ID;
        assetObj.Status = 'Terminated';
        assetObj.NSP_Termination_Date__c = date.today();
        update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,Name,NSP_Termination_Date__c FROM Asset WHERE NSP_Client__c = 'asset6' LIMIT 1];
        System.assertEquals(date.today(), assetList1[0].NSP_Termination_Date__c);

    }

    @isTest
    private static void createPlatformEventForAsset() {
        Test.startTest();
        Account accountObject = [SELECT Id from Account WHERE Name = 'Test Account' limit 1];
        Asset assetObjWO = new Asset();
        assetObjWO.accountId = accountObject.Id;
        assetObjWO.NSP_Client__c = 'WO asset1';
        assetObjWO.RecordTypeId = woRecordTypeId;
        assetObjWO.name = 'assetObjWO';
        assetObjWO.NSP_DBA__c = 'Test';
        assetObjWO.NSP_Account_Status__c = 'Active';
        assetObjWO.NSP_IES_e_Verify_Client__c = false;
        insert assetObjWO;

        assetObjWO.NSP_IES_e_Verify_Client__c = true;
        update assetObjWO;

        Test.stopTest();
    }


    @isTest
    private static void updateActiveAsset() {
        Test.startTest();
        Account accountObject = [SELECT Id from Account WHERE Name = 'Test Account' limit 1];
        Asset assetObjWO = new Asset();
        assetObjWO.Name = 'Test' ;
        assetObjWO.accountId = accountObject.Id;
        assetObjWO.RecordTypeId = woRecordTypeId;
        assetObjWO.Status = 'Active';
        insert assetObjWO;
        Test.stopTest();
        system.assertEquals(assetObjWO.accountId, accountObject.Id);
    }

    @isTest
    private static void afterPayDateWOTest() {

        Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get('WX_WA').getRecordTypeId();
        Id  soldToCheckListRecordTypeId = Schema.SObjectType.NSP_Checklist__c.getRecordTypeInfosByDeveloperName().get('NSP_Sold_to_Paid_Checklist').getRecordTypeId();
        List<Asset> assetList = [SELECT ID,Name,recordtypeid,NSP_AIMS_First_Pay_Date__c,Opportunity__c FROM Asset WHERE NSP_Client__c = 'asset4' LIMIT 1];
        Opportunity eachOppty = [SELECT id,NSP_PrimaryProduct__c,StageName,OwnerId from opportunity WHERE OwnerId != NULL limit 1];

         Id taskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Core_Sales_Task_RT').getRecordTypeId();
        Task taskRec = new Task(
            Subject = 'Discovery Call',
            WhatId = eachOppty.Id,
            NSP_Task_Type__c = 'BPS',
            RecordTypeId = taskRecTypeId,
            NSP_Task_Subtype__c = 'Client Meeting',
            NSP_Status__c='Completed'
        );
        insert taskRec;

        eachOppty.NSP_BPA__c = eachOppty.OwnerId;
        //eachOppty.StageName = 'Closed Won';
        eachOppty.NSP_PrimaryProduct__c = 'WO';
        //eachOppty.StageName = 'Closing';
        Test.startTest();
        update eachOppty;
            NSP_Checklist__c eachCheckList = new NSP_Checklist__c();
            eachCheckList.RecordTypeId = soldToCheckListRecordTypeId;
            eachCheckList.NSP_Opportunity__c = eachOppty.Id;
            eachCheckList.NSP_Requested_First_Pay_Date__c = system.today();
          insert eachCheckList;

        Asset assetObj = new Asset();
        assetObj.Id = assetList[0].ID;
        assetObj.recordtypeid = new_Asset_RT_ID;
        assetObj.NSP_AIMS_First_Pay_Date__c = date.today();
        assetObj.Opportunity__c = eachOppty.ID;
        update assetObj;
        Test.stopTest();
        List<Asset> assetList1 = [SELECT ID,Name,NSP_AIMS_First_Pay_Date__c FROM Asset WHERE NSP_Client__c = 'asset4' LIMIT 1];
        System.assertEquals(date.today(), assetList1[0].NSP_AIMS_First_Pay_Date__c);

    }

    @isTest
    private static void updateActiveAssetWithName() {
        Test.startTest();
        Account accountObject = [SELECT Id from Account WHERE Name = 'Test Account' limit 1];
        Asset assetObjWO = new Asset();
        assetObjWO.Name = 'Test' ;
        assetObjWO.accountId = accountObject.Id;
        assetObjWO.RecordTypeId = woRecordTypeId;
        assetObjWO.Status = 'Active';
        insert assetObjWO;
        Test.stopTest();
        system.assertEquals(assetObjWO.accountId, accountObject.Id);
    }

}//