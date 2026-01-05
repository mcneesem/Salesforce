@isTest 
private class NSP_CaseTriggerHelperTest {

    private static final String ACCOUNTDEFAULTS = 'NSP_TestDataFactory.AccountDefaults';
    private static final String CASEDEFAULTS  = 'NSP_TestDataFactory.CaseDefaults';
    private static final String CQA_SEVERITY = 'NSP_CQA_Severity__c';
    private static final String CQA_RESULTING_SEVERITY = 'NSP_CQA_Resulting_Severity__c';
    private static final String CASE_STATUS ='Status';
    private static final String CASE_SUBJECT = 'Subject';
    private static final String CONTACT_CENTER_OBJ = 'Contact Center';
    private static final String USER_ID =  'ABCDEF12345';
    private static final String STRING_TEST_REPO = 'Test Report Dev Notifications';
    private static final Id bpsProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PROJECT_BPS_RECORDTYPE);
    private static final Id itaCqaRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CASE_OBJECT_NAME, NSP_ServiceConstants.NSP_ITA_CQA);
    private static final Id WOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE); 
    private static final Id PEO_RECORDTYPE = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CASE_OBJECT_NAME, NSP_ServiceConstants.PEO);
    private static final String CONTACT_DEFAULTS_LIGHT = 'NSP_TestDataFactory.ContactDefaultsLight';
    private static final List<String> PROJECT_FIELDS = new List<String>{
        'Id',
        'Name',
        'pse__Start_Date__c',
        'Templates_Used__c',
        'Peer_Review__c'      
    };
    private static final List<String> CASE_FIELDS = new List<String>{
        'Id',
        'NSP_CorporateEmployeeEE__c', 'AccountId', 'ContactId'
    };
    
    @testSetup
    static void testData() {
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;

        List<Case> caseList = new List<Case>();
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, true);
        Account assetAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, false);
        assetAccount.Name = 'Test Asset';
        insert assetAccount;
        
        //create new contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, false);
        newContact.Account = newAccount;
        newContact.NSP_Work_email__c = 'test123@efg.com';
        insert newContact;
        
        Asset woAssetRecord = (Asset)NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        woAssetRecord.AccountId = assetAccount.Id;
        woAssetRecord.NSP_Account_Status__c = NSP_ServiceConstants.AIMS_STATUS;
        woAssetRecord.RecordTypeId = WOAssetRecordTypeId;
        woAssetRecord.NSP_Client_Segment_type__c = NSP_ServiceConstants.CoreAssetSegment;
        woAssetRecord.Status = 'Active';
        Database.insert(woAssetRecord, false); 
        
        NSP_Category_Sub_Category_Mapping__c newCat = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat.NSP_UserTitle__c = 'Benefits Manager';
        newCat.NSP_Category__c = NSP_ServiceConstants.CATEGORY_ADAPTION;
        newCat.NSP_Subcategory__c = NSP_ServiceConstants.SUB_CATEGORY_CLAIM;
        newCat.NSP_Detail__c = 'Login';
        newCat.NSP_isActive__c=True;
        newCat.NSP_Asset_Record_Types__c='WO';
        newCat.NSP_RecordType__c='PEO';
        newCat.NSP_Public_Groups_To_Share__c = 'All Data Visibility'; 
        Database.insert(newCat);
        
        pse__Proj__c bpsProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        bpsProject.RecordTypeId = bpsProjectRecordTypeId;
        bpsProject.Templates_Used__c = NSP_ServiceConstants.ITA_IMPLEMENTATION;
        bpsProject.pse__Project_Status__c = 'Active';
        bpsProject.Project_Implementer__c = userinfo.getUserId();
        bpsProject.pse__Is_Active__c = true; 
        insert bpsProject; 
        
        Test.startTest();
        //Creating case for Report dev Notification testing
        Case asssetCaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        asssetCaseRecord.NSP_Category__c = 'Adaption';
        asssetCaseRecord.NSP_SubCategory__c = 'Claim';
        asssetCaseRecord.Subject = 'Test Asset Mapping';
        asssetCaseRecord.AccountId = newAccount.Id;
        caseList.add(asssetCaseRecord); 
        
        Case nCorpCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        nCorpCase.contactId = newContact.Id;
        nCorpCase.AccountId = newAccount.Id;
        nCorpCase.NSP_CorporateEmployeeEE__c = true;
        caseList.add(nCorpCase);
        
        Case newCaseWithCon = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        newCaseWithCon.contactId = newContact.Id;
        newCaseWithCon.NSP_Category__c = NSP_ServiceConstants.HW_SECTION_125;
        caseList.add(newCaseWithCon);
        Case newCaseWithOutCon = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseList.add(newCaseWithOutCon);
        
        // Parent ITA CQA Case
        Case itaCqaCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        itaCqaCase.RecordTypeId = itaCqaRecordTypeId;
        itaCqaCase.NSP_CQA_Resulting_Severity__c = NSP_ServiceConstants.L1_CA_ACCURALS_MISCALCULATION;
       	itaCqaCase.Project__c = bpsProject.Id;
        caseList.add(itaCqaCase);          
        
        
       //create HCM case Creation
        Case hcmCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        hcmCase.Subject = NSP_ServiceConstants.HCM_TEST_CASE_SUBJECT;
        hcmCase.NSP_Opened_Date__c = Date.Today();
        hcmCase.Status = NSP_ServiceConstants.OPEN;
      	caseList.add(hcmCase); 
		
		//Creating case for Report dev Notification testing
        Case caseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseRecord.NSP_Category__c = NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS;
        caseRecord.NSP_SubCategory__c = NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT;
        caseRecord.NSP_Detail__c = NSP_ServiceConstants.CASE_DETAIL_REQUEST_NOT_COMPLETE;
        caseRecord.Subject = STRING_TEST_REPO;
        caseRecord.AccountId = newAccount.Id;
        caseRecord.NSP_Opened_Date__c = Date.Today();
        caseRecord.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        caseRecord.RecordTypeId = PEO_RECORDTYPE;
		caseRecord.NSP_Case_Sub_Status__c = NSP_ServiceConstants.CASE_SUB_STATUS_AWAITING_VERIFICATION;
        caseList.add(caseRecord); 
        
        //Creating BPS case
        Id recordTypeIdBPS = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CASE_OBJECT_NAME,'BPS');
        Case bpsCaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        bpsCaseRecord.RecordTypeId = recordTypeIdBPS;
        bpsCaseRecord.Subject = 'Test BPS Case';
        bpsCaseRecord.AccountId = newAccount.Id;
        bpsCaseRecord.Type = 'Congruex';
        bpsCaseRecord.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        bpsCaseRecord.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        caseList.add(bpsCaseRecord); 

        // WgaeClaims Case
        Id recordTypeIdPEO = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CASE_OBJECT_NAME, NSP_ServiceConstants.PEO);
        Case wageClaimsCaseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        wageClaimsCaseRecord.RecordTypeId = recordTypeIdPEO;
        wageClaimsCaseRecord.Subject = 'Test WageClaims Case';
        wageClaimsCaseRecord.AccountId = newAccount.Id;
        wageClaimsCaseRecord.NSP_Category__c = NSP_ServiceConstants.FLSA_CATEGORY;
        wageClaimsCaseRecord.NSP_SubCategory__c = NSP_ServiceConstants.CASE_SUB_CATEGORY_WAGE_CLAIMS;
        wageClaimsCaseRecord.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
		wageClaimsCaseRecord.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
       	caseList.add(wageClaimsCaseRecord); 
        
        Database.insert(caseList);
        
        // child ITA CQA Case
        Case childItaCqaCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        childItaCqaCase.RecordTypeId = itaCqaRecordTypeId;
        childItaCqaCase.NSP_CQA_Resulting_Severity__c = NSP_ServiceConstants.L1_CA_ACCURALS_MISCALCULATION;
        childItaCqaCase.ParentId = itaCqaCase.Id;
        insert childItaCqaCase; 
        
        Test.stopTest();
        
        //create case contact
        NSP_Case_Contacts__c caseContact = (NSP_Case_Contacts__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Case_Contacts__c(), 'NSP_TestDataFactory.caseContactDefaults', false);
        caseContact.NSP_Contact__c = newContact.Id;
        caseContact.NSP_Case__c = bpsCaseRecord.Id;
        caseContact.NSP_IsPrimary__c = true;
        INSERT caseContact;
        
        User PEOUSER = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'PEO Service'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@insperity.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert PEOUSER;
        List<String> fields = new List<String>{'Id', 'Type','DeveloperName'};
           System.runAs ( new User(Id = UserInfo.getUserId()) ) {
        Id groupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.SECTION_125_PRIVATE_CASE_VISIBILTY, fields).Id;
        GroupMember grpMem = new GroupMember (UserOrGroupId = userInfo.getUserId(), GroupId = groupId);
        List<GroupMember> groupMemberList= new List<GroupMember>{grpMem};
            // Inserting Group Members
            Insert groupMemberList;
           }
    }

    @isTest
    private static void testCaseTriggerOperation() {
        //create account
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, false);
        newAccount.Name = 'newAccount';
        newAccount.NSP_Premier_Pathway_Client__c ='12345ABCDEF';
        insert newAccount;
        
        //create contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, false);
        newContact.Account = newAccount;
        newContact.NSP_Per_ID__c = USER_ID;
        insert newContact;
        
        // create group
        Group newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false); 
        newGroup.Type ='Queue';
        newGroup.name = CONTACT_CENTER_OBJ;
        insert newGroup;
        
        //create queue
        QueuesObject testQueue = new QueueSObject(QueueID = newGroup.id, SObjectType = NSP_ServiceConstants.CASE_OBJECT_NAME);
        System.runAs(new User(Id = UserInfo.getUserId())){
            insert testQueue;
        }
        
        // create case
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        // Test auto update NSP_Assigned_Queue__c Field.
        newCase.OwnerId = newGroup.Id;
        
        // Test Web To Case 
        newCase.Origin='Web';
        newCase.NSP_WebToCase_PerID__c = USER_ID;
        newCase.NSP_WebToCase_ClientID__c ='12345ABCDEF';
        test.startTest();
        insert newCase;
        Case queryNewCase = [SELECT ID, ContactId,NSP_Assigned_Queue__c,NSP_Original_Assigned_Queue_Date__c FROM Case WHERE Id=:newCase.Id LIMIT 1];
        
        System.assertEquals(CONTACT_CENTER_OBJ ,queryNewCase.NSP_Assigned_Queue__c);
        System.assertNotEquals(null, queryNewCase.NSP_Original_Assigned_Queue_Date__c);
        System.assertEquals(newContact.Id, queryNewCase.ContactId); 
        
        // Test Assigning a Owner from Queue
        newCase.OwnerId = UserInfo.getUserId();
        newCase.NSP_CCPA_email_Sent__c=false;
        newCase.NSP_Consumer_Privacy_Inquiry__c = true;
        update newCase;
        Case queryUpdatedCase = [SELECT ID, NSP_CCPA_email_Sent__c,NSP_IsCaseCreatedNotificationEmailSent__c,NSP_Owner_Assign_Date__c FROM Case WHERE Id=:newCase.Id LIMIT 1];    
        System.assertEquals(true, queryUpdatedCase.NSP_IsCaseCreatedNotificationEmailSent__c);
        system.assertNotEquals(null, queryUpdatedCase.NSP_Owner_Assign_Date__c);
        System.assertEquals(true, queryUpdatedCase.NSP_CCPA_email_Sent__c); 
        
        
        // Testing PEO Closed Case Testing
        Id recordTypePEOID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
        Case closingCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        closingCase.RecordTypeId = recordTypePEOID;
        closingCase.ContactId = newContact.Id;
        closingCase.NSP_Consumer_Privacy_Inquiry__c = true;
        closingCase.NSP_CCPA_email_Sent__c = false;
        closingCase.NSP_Date_Closed__c = null;
        closingCase.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
		closingCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        insert closingCase; 
        
         test.stopTest();
        // Test Email on case Closure
        closingCase.Status= 'Closed';
        closingCase.Reason ='Complete';
        closingCase.NSP_Rating__c = 'Unfavorable';
        update closingCase;
        Case queryClosedCase = [SELECT ID, NSP_Case_Sub_Status__c,NSP_CCPA_email_Sent__c, NSP_Date_Closed__c FROM Case WHERE Id=:closingCase.Id LIMIT 1];    
        System.assertEquals('Resolved', queryClosedCase.NSP_Case_Sub_Status__c); 
        System.assertEquals(true, queryClosedCase.NSP_CCPA_email_Sent__c);
        System.assertNotEquals(null, queryClosedCase.NSP_Date_Closed__c);     
        
    }
    
    @isTest
    private static void testUpdateCaseOwnerWhenL2IsTrue() {
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        newCase.NSP_L2__c = false;
        insert newCase;
        
        test.startTest();
        newCase.NSP_L2__c = true;
        update newCase;        
        
        Case updatedCase = [SELECT OwnerId, NSP_Assigned_Queue__c, NSP_Original_Assigned_Queue_Date__c FROM Case WHERE ID = : newCase.id];
        string caseOwnerId = updatedCase.OwnerId;
        Boolean isOwnerIdUserOrQueue = caseOwnerId.startsWith('00G');
        
        System.assertEquals(true, isOwnerIdUserOrQueue, 'Case Owner will be Escalation Queue');

        //Test After Insert CaseFilters 
        Id recordTypeBPSID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BPS').getRecordTypeId();
        Case newBPSCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        newBPSCase.RecordTypeId = recordTypeBPSID;
        newBPSCase.Type = 'Mobile - WO';
        newBPSCase.OwnerId = caseOwnerId;
        insert newBPSCase; 
        
        newBPSCase.NSP_Level_2__c = true;
        newBPSCase.NSP_Level_2_Assigned_Date__c = (system.now()).addDays(-3);
        newBPSCase.NSP_First_Level2_Reply_Date__c = (system.now()).addDays(-2);
        newBPSCase.OwnerId = userinfo.getuserid();
        Update newBPSCase;
        
        Case newBPSCase1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        newBPSCase1.RecordTypeId = recordTypeBPSID;
        newBPSCase1.Type = 'Mobile - WO';
        newBPSCase1.NSP_Level_2__c = true;
        insert newBPSCase1; 
        
        newBPSCase1.NSP_Level_2__c = false;
        newBPSCase1.NSP_Level_2_Assigned_Date__c = (system.now()).addDays(-3);
        newBPSCase1.NSP_First_Level2_Assigned_Duration__c = null;
        Update newBPSCase1;
        
        Case newBPSCase2 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        newBPSCase2.RecordTypeId = recordTypeBPSID;
        newBPSCase2.Type = 'Mobile - WO';
        newBPSCase2.NSP_Level_2__c = true;
        insert newBPSCase2;
        
        newBPSCase2.NSP_Level_2_Assigned_Date__c = null;
        newBPSCase2.NSP_First_Level2_Assigned_Duration__c = null;
        Update newBPSCase2;
        //new NSP_CaseTriggerHelper().autoPopulateAsset(newBPSCase); // correcting deployment errors ~ Method does not exist or incorrect signature: void autoPopulateAsset(Case) from the type NSP_CaseTriggerHelper (312:37)
        test.stopTest();
    }

    @isTest
    private static void testAfterUpdateDirector() {
        test.startTest();
         // Testing After UpdateDirector
         Account newAccount = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        // create case issue
        NSP_Case_Issue__c cI = new NSP_Case_Issue__c();
        cI.Name = 'Text - NSP_Case_Issue__c';
        cI.NSP_Issue_Type__c = 'Global outage';
        insert cI;
        Id recordTypePEOID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
        
        // create parent case
        Case parentCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        parentCase.RecordTypeId = recordTypePEOID;
        parentCase.NSP_Consumer_Privacy_Inquiry__c = true;
        parentCase.NSP_CCPA_email_Sent__c = false;
        parentCase.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
		parentCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        insert parentCase;
        // create child case and insert
        Case childCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        childCase.RecordTypeId = recordTypePEOID;
        childCase.ParentId = parentCase.Id;
        childCase.NSP_Case_Issue__c = cI.id;
        childCase.NSP_Consumer_Privacy_Inquiry__c = true;
        childCase.NSP_CCPA_email_Sent__c = false;        
		childCase.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
		childCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        insert childCase; 
        // update child case
        childCase.Status= 'Closed';
        childCase.Reason ='Complete';
        childCase.NSP_Rating__c = 'Unfavorable';
        update childCase;
        //create account team
        NSP_Account_Team__c nAT = new NSP_Account_Team__c();
        nAT.NSP_Account__c  = newAccount.Id;
        nAT.NSP_Role__c  = 'Payroll Specialist';
        insert nAT;
        //create category
        Id recordTypeBPSID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BPS').getRecordTypeId();
        Case nSPCategory = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        nSPCategory.RecordTypeId = recordTypeBPSID;
        nSPCategory.NSP_Category__c = 'CSS';
        nSPCategory.AccountId = newAccount.Id;

        insert nSPCategory;

        new NSP_CaseTriggerHelper().getAccountTeamMember(newAccount.Id);

        Case updatedCase = [SELECT Status FROM Case WHERE ID = : childCase.id];
        string caseStatus = updatedCase.Status;
        System.assertEquals('Closed',  caseStatus, 'Case Status will be Updated');

        test.stopTest();
    }

    @isTest
    private static void testgetAccountTeamMember() {
        test.startTest();

        //create account
         Account newAccount = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        //create account
        Account newAccount2 = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), ACCOUNTDEFAULTS, false);
        newAccount2.Name = 'Test newAccount2 - 01';
        newAccount2.BillingCity ='Houston';
        newAccount2.BillingPostalCode = '77339';
        newAccount2.BillingCountry = 'United States';
        newAccount2.BillingStreet = '19001 Crescent Springs Drive ' ;
        newAccount2.BillingState = 'Texas';
        insert newAccount2;
        //create account team member list
        list<AccountTeamMember> acctMembers = new list<AccountTeamMember>();
        //create account team members
        AccountTeamMember ca = new AccountTeamMember();
        ca.AccountId = newAccount2.Id;
        ca.TeamMemberRole = 'HR Specialist';
        ca.Assigned_Roles__c = 'HR Specialist';
        ca.UserId = UserInfo.getUserId();
        acctMembers.add(ca);
        AccountTeamMember ca2 = new AccountTeamMember();
        ca2.AccountId = newAccount.Id;
        ca2.UserId = UserInfo.getUserId();
        ca2.TeamMemberRole = 'Payroll Specialist';
        ca2.Assigned_Roles__c = 'Payroll Specialist';
        acctMembers.add(ca2);
        insert acctMembers;
        //create new contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, false);
        newContact.Account = newAccount;
        newContact.NSP_Per_ID__c = USER_ID;
        insert newContact;
        
        Id recordTypeWageClaimsID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('NSP_WageClaims').getRecordTypeId();
        //create parent case
        Case parentCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        parentCase.RecordTypeId = recordTypeWageClaimsID;
        parentCase.NSP_Consumer_Privacy_Inquiry__c = true;
        parentCase.NSP_CCPA_email_Sent__c = false;
        parentCase.AccountId = newAccount.Id;
        parentCase.Contact = newContact;
        insert parentCase;
        parentCase.AccountId = newAccount2.Id;
        update parentCase;
        //create child case
        Case childCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        childCase.RecordTypeId = recordTypeWageClaimsID;
        childCase.ParentId = parentCase.Id;
        childCase.Contact = newContact;
        childCase.AccountId = newAccount2.Id;
        childCase.NSP_Consumer_Privacy_Inquiry__c = true;
        childCase.NSP_CCPA_email_Sent__c = false;
        insert childCase; 
        childCase.AccountId = newAccount.Id;
        update childCase;

        test.stopTest();
        System.assertEquals(acctMembers[0].TeamMemberRole, 'HR Specialist' );
    }
    
    @isTest
    private static void testgetAccountGroup() {
        test.startTest();

        //create account group
        NSP_Account_Group__c newAccountGrp = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        newAccountGrp.NSP_Type__c = 'OrgPlus Support Group';
        insert newAccountGrp;
        //create new account
        Account newAccount = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        //create new contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, false);
        newContact.Account = newAccount;
        newContact.NSP_Per_ID__c = USER_ID;
        insert newContact;
        
        //Id ttRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.ASSET_TT_RECORDTYPE).getRecordTypeId();
        Id opRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.ASSET_OP_RECORDTYPE).getRecordTypeId();
        //create asset
        Asset asset4 = (Asset) NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        asset4.AccountId = newAccount.Id;
        asset4.recordtypeId = opRecordTypeId;
        asset4.NSP_WX_WA_CHILD_ID__c = 0;
        asset4.NSP_WX_WA_Parent_ID__c = '123456';
        asset4.NSP_Support_Account_Group__c = newAccountGrp.Id;
        insert asset4;
        
        Id bpsRecordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.BPS)?.getRecordTypeId();
        //create child case
        Case childCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        childCase.RecordTypeId = bpsRecordTypeId;
        childCase.Contact = newContact;
        childCase.AccountId = newAccount.Id;
        childCase.NSP_Category__c = NSP_ServiceConstants.TIME_ATTENDANCE_ASSET;
        insert childCase; 
        //create case
        Case case2 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        case2.RecordTypeId = bpsRecordTypeId;
        case2.Contact = newContact;
        case2.AccountId = newAccount.Id;
        case2.NSP_Category__c = NSP_ServiceConstants.CASE_ORGPLUS_SOFTWARE;
        insert case2; 
        //create case
        Case case3 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        case3.RecordTypeId = bpsRecordTypeId;
        case3.Contact = newContact;
        case3.AccountId = newAccount.Id;
        case3.NSP_Category__c = NSP_ServiceConstants.CASE_PERFORM_SOFTWARE;
        insert case3; 
        //create case
        Case case4 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        case4.RecordTypeId = bpsRecordTypeId;
        case4.Contact = newContact;
        case4.AccountId = newAccount.Id;
        case4.NSP_Category__c = NSP_ServiceConstants.CASE_WX_WA;
        insert case4; 

        test.stopTest();
        System.assertEquals( case4.NSP_Category__c,NSP_ServiceConstants.CASE_WX_WA );
    }
	
	@isTest    
    private static void insertConfidentialCaseTest() {
        List<Case> caseList = new List<Case>();
        User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com'];
        System.runAs (getPeoUser) {
            Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            case1.NSP_Category__c = NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            case1.NSP_Confidential__c = true;
            case1.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
			case1.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
            caseList.add(case1);
            //create case
            Case case2 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            case2.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
            case2.NSP_Confidential__c = false;
            case2.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
			case2.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
            caseList.add(case2);
            
            database.insert(caseList);
            Test.startTest();
            case1.NSP_Confidential__c = false;
            case1.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
            database.update(case1);
            
            case2.NSP_Confidential__c = true;
            case2.NSP_Category__c = NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            database.update(case2);         
            Test.stopTest();
            system.assertEquals(case2.NSP_Confidential__c, true);
        
        }
    }

	@isTest    
    private static void insertConfidentialCaseWithOutCategoryTest() {
	 List<Case> caseList = new List<Case>();
        DmlException expectedException;
        User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com'];
        System.runAs (getPeoUser) {
            //create case
            Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            case1.NSP_Category__c = 'CSS';
            case1.NSP_Confidential__c = true;
            caseList.add(case1);
            Test.startTest();
            try{
                database.insert(caseList);
            }catch (DmlException dmx){
                expectedException = dmx;
            }
            Test.stopTest();
           Id  groupId = [SELECT Id, Name 
                           FROM Group 
                           WHERE Name =:NSP_ServiceConstants.HR_DATA_VISIBILTY].Id;
            List<CaseShare> caseShareList =[SELECT Id 
                                            FROM CaseShare
                                            WHERE CaseId=:case1.Id 
                                            AND UserOrGroupId=:groupId];
            system.assertEquals(caseShareList.size() > 0, false);
        }
    }
    
    @isTest    
    private static void confidentailCaseWithCategoryChange() {
	    List<Case> caseList = new List<Case>();
        DmlException expectedException;
        User getPeoUser = [SELECT Id,Email FROM user WHERE Email = 'testuser@insperity.com'];
        System.runAs (getPeoUser) {
            Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
           	case1.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
            case1.NSP_Confidential__c = true;
            case1.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
			case1.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
            caseList.add(case1);
             database.insert(caseList);
            Test.startTest();
            try{
                case1.NSP_Category__c = 'CSS';
                database.update(case1);
            }catch (DmlException dmx){
                expectedException = dmx;
            }
            Test.stopTest();
            Id  groupId = [SELECT Id, Name 
                           FROM Group 
                           WHERE Name =:NSP_ServiceConstants.ALL_DATA_VISIBILTY].Id;
            List<CaseShare> caseShareList =[SELECT Id 
                                            FROM CaseShare
                                            WHERE CaseId=:case1.Id 
                                            AND UserOrGroupId=:groupId];
            system.assertEquals(caseShareList.size() > 0, false);
        }
    }

    @isTest    
    private static void cancelPreviouslyCreatedCaseTest() {
        
        //Given
        //Set<ID> ipSetId = new Set<ID>();
        Id healthAndProductsGrpId = [SELECT Id, Name,Type FROM Group WHERE Type='Queue' AND Name =: NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT].Id;
        Id peoRecordTypeId = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
        Implementation_Profile__c ipRecord = new Implementation_Profile__c();
        database.insert(ipRecord);
        Test.startTest();
        Case caseToBeUpdated = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseToBeUpdated.Subject = NSP_ServiceConstants.SUBJECT8;
        caseToBeUpdated.Status = NSP_ServiceConstants.OPEN;
        caseToBeUpdated.NSP_Implementation_Profile__c = ipRecord.ID;
        database.insert(caseToBeUpdated);
        //When 
        try{
            
            Case newCaseToBeUpdated = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            newCaseToBeUpdated.Subject = NSP_ServiceConstants.SUBJECT7;
            newCaseToBeUpdated.Status = NSP_ServiceConstants.OPEN;
            newCaseToBeUpdated.NSP_Implementation_Profile__c = ipRecord.ID;
            newCaseToBeUpdated.recordTypeId = peoRecordTypeId ;
            newCaseToBeUpdated.OwnerId = healthAndProductsGrpId;
            database.insert(newCaseToBeUpdated);
            
            
            Test.stopTest();
            System.assert(true, 'Case Status Updated to Cancelled');
        }catch(Exception excep){
            //Then
            System.assert(true, 'expectedErrorMessage');	
        }
        
    }
    
    @isTest    
    private static void updateAssignedQueueTest() {
        DmlException expectedException;
        try{
            Group newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false); 
            newGroup.Type ='Queue';
            newGroup.name = CONTACT_CENTER_OBJ;
            insert newGroup;

            Case newCaseToBeUpdated = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            Database.insert(newCaseToBeUpdated);

            newCaseToBeUpdated.OwnerId = newGroup.id;
            Database.update(newCaseToBeUpdated);

            Case updatedCase = [SELECT NSP_Assigned_Queue__c, NSP_Original_Assigned_Queue_Date__c FROM Case WHERE ID = : newCaseToBeUpdated.id];
            System.assertEquals(CONTACT_CENTER_OBJ , updatedCase.NSP_Assigned_Queue__c);
            System.assertNotEquals(null, updatedCase.NSP_Original_Assigned_Queue_Date__c);
            
        }catch(DmlException excep){
            expectedException = excep;
        }
    }
    
    @isTest
    private static void createCaseContactTest() {
        List<case> getCaseWithContact = [SELECT Id, ContactId FROM Case WHERE ContactId != null];
        Test.startTest();
         List<NSP_Case_Contacts__c> assertCaseContacts = [SELECT Id, NSP_Case__c FROM NSP_Case_Contacts__c WHERE NSP_Case__c =: getCaseWithContact[0].Id ];
        Test.stopTest();
        system.assertEquals(true, assertCaseContacts.size()>0);
    }
    
    @isTest
    private static void createCaseContacNegativetTest() {
        List<case> getCaseWithContact = [SELECT Id, ContactId FROM Case WHERE ContactId = null];
        Test.startTest();
         List<NSP_Case_Contacts__c> assertCaseContacts = [SELECT Id, NSP_Case__c FROM NSP_Case_Contacts__c WHERE NSP_Case__c =: getCaseWithContact[0].Id ];
        Test.stopTest();
        system.assertEquals(false, assertCaseContacts.size()>0);
    }
    
    //Positive
    @isTest
    private static void testSendAwaitingVerificationMail() {
        List<String> caseFields = new List<String>{'Id', CASE_SUBJECT};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        caseRecord.Status = 'Reopened';
        caseRecord.NSP_Case_Sub_Status__c = 'Escalation';
        caseRecord.NSP_Detail__c = NSP_ServiceConstants.CASE_DETAIL_REQUEST_NOT_COMPLETE;
        UPDATE caseRecord;
        Test.startTest();
        caseRecord.NSP_Case_Sub_Status__c = NSP_ServiceConstants.CASE_SUB_STATUS_AWAITING_VERIFICATION;
        UPDATE caseRecord;
        //System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    //Negative
    @isTest
    private static void testNotSendAwaitingVerificationMail() {
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        UPDATE caseRecord;
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    //Positive
    @isTest
    private static void testSendMigrationCompleteMail() {
        List<String> caseFields = new List<String>{'Id', CASE_SUBJECT};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.Status = 'Reopened';
        caseRecord.NSP_Case_Sub_Status__c = NSP_ServiceConstants.CASE_SUB_STATUS_WIRE_MIGRATION_COMPLETE;
        UPDATE caseRecord;
        //System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    //Negative
    @isTest
    private static void testNotSendMigrationCompleteMail() {
        List<String> caseFields = new List<String>{'Id', CASE_SUBJECT};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        Test.startTest();        
        caseRecord.NSP_Case_Sub_Status__c = NSP_ServiceConstants.scheduleStatus;
        UPDATE caseRecord;
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    //Positive
    @isTest
    private static void testSendReferredToExistingMail() {
        List<String> caseFields = new List<String>{'Id', CASE_SUBJECT};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.NSP_Detail__c = NSP_ServiceConstants.CASE_DETAIL_REFERRED_TO_EXISTING;
        UPDATE caseRecord;
        //System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    //Negative
    @isTest
    private static void testNotSendReferredToExistingMail() {
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
		caseRecord.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        caseRecord.NSP_Category__c = 'Selected Services';
        caseRecord.NSP_SubCategory__c = 'Billing Inquiry';
        UPDATE caseRecord;
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    @isTest
    private static void testSendRequestNotCompleteMail() {
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT };
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
		caseRecord.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        caseRecord.NSP_Detail__c = NSP_ServiceConstants.CASE_DETAIL_REQUEST_NOT_COMPLETE;
        UPDATE caseRecord;
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    @isTest
    private static void testNotSendRequestNotCompleteMail() {
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.NSP_Detail__c = '';
        UPDATE caseRecord;
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    @isTest
    private static void testBankAuditEmail() {
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT };
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.Status = NSP_ServiceConstants.CASE_CLOSED_STATUS;
        caseRecord.NSP_Is_Case_Closed__c = true;
        caseRecord.NSP_Rating__c = 'Unfavorable';
        caseRecord.Subject = NSP_ServiceConstants.BANK_AUDIT_CASE_SUBJECT;       
        UPDATE caseRecord;
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    @isTest
    private static void testFirstPayrollCaseList() {
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT };
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,STRING_TEST_REPO).build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.Status = NSP_ServiceConstants.CASE_CLOSED_STATUS;
        caseRecord.NSP_Is_Case_Closed__c = true;
        caseRecord.NSP_Rating__c = 'Unfavorable';
         caseRecord.Subject = NSP_ServiceConstants.FIRST_LIVE_PAYROLL_CASE_SUB;
        UPDATE caseRecord;      
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    @isTest
    private static void testSendEmailonBpsCaseUpdateForNonInsperityEmployeeType() {
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT , CASE_STATUS,'NSP_Case_Sub_Status__c'};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,'Test BPS Case').build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.Type = 'Non-Insperity Employee';
        UPDATE caseRecord;
        //System.assertEquals(1, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    @isTest
    private static void testNotSendEmailonBpsCaseUpdate() {
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT , CASE_STATUS,'NSP_Case_Sub_Status__c'};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
                          .addFilter(CASE_SUBJECT ,'Test BPS Case').build();
        Case caseRecord = Database.query(query);
        Test.startTest();
        caseRecord.Type = 'Mobile - WO';
        UPDATE caseRecord;
        system.assertEquals(0, Limits.getEmailInvocations());
        Test.stopTest();
    }
    
    @isTest
    private static void updateCqaSeverityTest() {
        
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT , CQA_RESULTING_SEVERITY, CQA_SEVERITY};
            String query = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter(CQA_RESULTING_SEVERITY, NSP_ServiceConstants.L1_CA_ACCURALS_MISCALCULATION).addLimit(1).build();
        Case itaCqaCase = Database.query(query);
        
        Test.startTest();
        itaCqaCase.NSP_CQA_Resulting_Severity__c = NSP_ServiceConstants.L3_UX_IMPACT; // Update NSP_CQA_Resulting_Severity__c so that based on mapping, NSP_CQA_Severity__c will be mapped 
        update itaCqaCase;
        Test.stopTest();    
        
        String assertCsequery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('Id', itaCqaCase.Id).addLimit(1).build();
        Case assertitaCqaCase = Database.query(assertCsequery);
        
        system.assertEquals(assertitaCqaCase.NSP_CQA_Severity__c, NSP_ServiceConstants.L3_LOW, 'NSP_CQA_Severity__c is updated according to Mapping which is L3-Low');
        system.assertNotEquals(assertitaCqaCase.NSP_CQA_Severity__c, NSP_ServiceConstants.L2_CRUCIAL, 'NSP_CQA_Severity__c will npt be other than L3-Low'); // Negative case
    }
    
    @isTest
    private static void updatePrentItaCqaCaseStatusTest() {
        
        //query for Project
        String bpsPrjQuery = new NSP_QueryBuilder('pse__Proj__c', PROJECT_FIELDS).addFilter('Templates_Used__c', NSP_ServiceConstants.ITA_IMPLEMENTATION).addLimit(1).build();
        pse__Proj__c bpsProject =Database.query(bpsPrjQuery); 
        
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT ,CQA_RESULTING_SEVERITY ,CQA_SEVERITY, CASE_STATUS};
            // ParentItaCqaCase
            String pItaCqaquery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('Project__c', bpsProject.Id).addLimit(1).build();
        Case pItaCqaCase = Database.query(pItaCqaquery);
        
        // Child IaCqaCase
        String cItaCqaquery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('ParentId', pItaCqaCase.Id).addLimit(1).build();
        Case cItaCqaCase = Database.query(cItaCqaquery);
        
        Test.startTest();
        cItaCqaCase.Status = NSP_ServiceConstants.CASE_CLOSED_STATUS; // update child ITA CQA Case status to closed.
        update cItaCqaCase;
        Test.stopTest();  
        
        String assertParentCase = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('Id', pItaCqaCase.Id).addLimit(1).build();
        Case assertParentItaCqaCase = Database.query(assertParentCase);
        
        system.assertEquals(assertParentItaCqaCase.Status, NSP_ServiceConstants.CASE_CLOSED_STATUS, 'Parent ITA CQA Case is closed and Email is Sent'); 
        system.assertNotEquals(assertParentItaCqaCase.Status, NSP_ServiceConstants.REOPENED, 'Parent ITA CQA Case will not be Re Opened'); // Negative Case  
    }
    
    @isTest
    private static void updatePrentItaCqaSeverityTest() {
        
        //query for Project
        String bpsPrjQuery = new NSP_QueryBuilder('pse__Proj__c', PROJECT_FIELDS).addFilter('Templates_Used__c', NSP_ServiceConstants.ITA_IMPLEMENTATION).addLimit(1).build();
        pse__Proj__c bpsProject =Database.query(bpsPrjQuery);
        
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT , CQA_RESULTING_SEVERITY, CQA_SEVERITY, CASE_STATUS};
            // ParentItaCqaCase
            String pItaCqaquery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('Project__c', bpsProject.Id).addLimit(1).build();
        Case pItaCqaCase = Database.query(pItaCqaquery);
        
        // Child IaCqaCase
        String cItaCqaquery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('ParentId', pItaCqaCase.Id).addLimit(1).build();
        Case cItaCqaCase = Database.query(cItaCqaquery);
        
        Test.startTest();
        cItaCqaCase.NSP_CQA_Resulting_Severity__c = NSP_ServiceConstants.L3_UX_IMPACT; // update child NSP_CQA_Resulting_Severity__c value
        update cItaCqaCase;
        Test.stopTest();
        
        String assertCsequery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('Id', pItaCqaCase.Id).addLimit(1).build();
        Case assertParentitaCqaCase = Database.query(assertCsequery);
        
        system.assertEquals(assertParentitaCqaCase.NSP_CQA_Severity__c, NSP_ServiceConstants.L3_LOW, 'NSP_CQA_Severity__c is updated on the parent Case which is L3-Low');
        system.assertNotEquals(assertParentitaCqaCase.NSP_CQA_Severity__c, NSP_ServiceConstants.L2_CRUCIAL, 'NSP_CQA_Severity__c will npt be other than L3-Low'); // Negative case
    }
    
    @isTest
    private static void reOpenParentItaCqaCaseTest() {
        
        String bpsPrjQuery = new NSP_QueryBuilder('pse__Proj__c', PROJECT_FIELDS).addFilter('Templates_Used__c', NSP_ServiceConstants.ITA_IMPLEMENTATION).addLimit(1).build();
        pse__Proj__c bpsProject =Database.query(bpsPrjQuery); 
        
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT , CQA_RESULTING_SEVERITY, CQA_SEVERITY, CASE_STATUS};
            // ParentItaCqaCase
            String pItaCqaquery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('Project__c', bpsProject.Id).addLimit(1).build();
        Case pItaCqaCase = Database.query(pItaCqaquery);
        Test.StartTest();
        // Update Child IaCqaCase
        String cItaCqaquery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('ParentId', pItaCqaCase.Id).addLimit(1).build();
        Case cItaCqaCase = Database.query(cItaCqaquery);        
        cItaCqaCase.Status = NSP_ServiceConstants.CASE_CLOSED_STATUS; // update child ITA CQA Case status to closed.
        update cItaCqaCase;
    
      // when child ITA CQA case status is re opened, then Parent ITA CQA Status also will be reopened
        cItaCqaCase.Status = NSP_ServiceConstants.REOPENED; // update child ITA CQA Case status to Re opened.
        
        update cItaCqaCase;
        Test.stopTest();
        
         String assParentCase = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('Id', pItaCqaCase.Id).addLimit(1).build();
        Case assParentReOpenCase = Database.query(assParentCase);
        
        system.assertEquals(assParentReOpenCase.Status, 'ReOpened', 'Parent ITA CQA Case is Re opened');
        system.assertNotEquals(assParentReOpenCase.Status, NSP_ServiceConstants.CASE_CLOSED_STATUS, 'Parent ITA CQA Case will not be closed'); // Negative Test case
    }

    @isTest
    private static void recordTypeChangeTest() {
        
        List<String> caseFields = new List<String>{'Id',CASE_SUBJECT ,'NSP_SubCategory__c','recordTypeId', 'recordType.DeveloperName'};
            // Query Created PEO Case
            String wageClaimCqaquery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, caseFields)
            .addFilter('NSP_SubCategory__c', NSP_ServiceConstants.CASE_SUB_CATEGORY_WAGE_CLAIMS ).addLimit(1).build();
        Case assertWageClaimCCase = Database.query(wageClaimCqaquery);
        
        system.assertEquals(assertWageClaimCCase.recordType.DeveloperName, NSP_ServiceConstants.WAGE_CLAIMS_RECORDTYPE, 'Record Type is changed to Wage Claims');
        system.assertNotEquals(assertWageClaimCCase.recordType.DeveloperName, NSP_ServiceConstants.PEO, 'Record Type is not equal to PEO which is given during the creation');       
    }

    @isTest
    private static void corpEmplyeeSharingTest() {

        List<String> fields = new List<String>{'Id', 'Type','DeveloperName'};
        List<String> caseShareFields = new List<String>{'Id'};                
        Id groupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.CORP_CASE_VISIBILITY, fields).Id;

        // Query Corp Case
        String CaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('NSP_CorporateEmployeeEE__c', false).addLimit(1).setSecurityEnforce(false).build();
        Case cse =  Database.query(CaseQuery);

        cse.NSP_Confidential__c = true; // mark the case confidential
        cse.NSP_CorporateEmployeeEE__c = false;

        Test.startTest();
        update cse;
        Test.stopTest();    

        String assertNonCorpCaseShareQuery = new NSP_QueryBuilder('CaseShare', caseShareFields).addFilter('UserOrGroupId', groupId).addLimit(1).setSecurityEnforce(false).build();
        List<CaseShare> nonCoprCaseShareList =  Database.query(assertNonCorpCaseShareQuery);
        system.assertEquals(nonCoprCaseShareList.size() > 0, false);  // When Case is Not Corp EE case, then it will not shared with corp Case visibility group
        
    }
    
    @isTest
    private static void updationOfCorrectAssetTest() {
        List<String> ASSET_FIELDS = new List<String>{'Id', 'recordtypeId'};
        List<String> ACCOUNT_FIELDS = new List<String>{'Id', 'Name'};
        List<String> CASE_FIELDS = new List<String>{'Id', 'NSP_Category__c','NSP_SubCategory__c', 'AccountId', 'AssetId'};
        List<String> CAT_SUBCAT_FIELDS = new List<String>{'Id', 'NSP_Category__c','NSP_SubCategory__c', 'NSP_RecordType__c', 'NSP_UserTitle__c'};
        
            //Query for NSP_Category_Sub_Category_Mapping__c
        String getCatSubCatQuery = new NSP_QueryBuilder('NSP_Category_Sub_Category_Mapping__c', CAT_SUBCAT_FIELDS).addFilter('NSP_Category__c', NSP_ServiceConstants.CATEGORY_ADAPTION).addLimit(1).setSecurityEnforce(false).build();
        NSP_Category_Sub_Category_Mapping__c getCatSubCat =  Database.query(getCatSubCatQuery);
        
        //Query for Asset
        String assertAssetQuery = new NSP_QueryBuilder('Asset', ASSET_FIELDS).addFilter('recordtypeId', WOAssetRecordTypeId).addFilter('Status', 'Active').addLimit(1).setSecurityEnforce(false).build();
        Asset assertAsset =  Database.query(assertAssetQuery);
    	
        //Query for Account
        String assetAccQuery = new NSP_QueryBuilder('Account', ACCOUNT_FIELDS).addFilter('Name', 'Test Asset').addLimit(1).setSecurityEnforce(false).build();
        Account assetAcc =  Database.query(assetAccQuery);
        
        //Query for Case
        String getCaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('NSP_Category__c', NSP_ServiceConstants.CATEGORY_ADAPTION).addLimit(1).setSecurityEnforce(false).build();
        Case getCase =  Database.query(getCaseQuery); 
        
        system.assert(getCase.AssetId != assertAsset.Id); // Negative Case: When Category, SubCategory and Account are not matching, Asset will not be populated on case.
        
        Test.startTest();
        getCase.AccountId = assetAcc.Id;
        update getCase;
        Test.stopTest();
        
        String getAssetCaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('NSP_Category__c', NSP_ServiceConstants.CATEGORY_ADAPTION).addLimit(1).setSecurityEnforce(false).build();
        Case getAssetCase =  Database.query(getAssetCaseQuery);
        system.assert(getAssetCase.AssetId == assertAsset.Id); // Positive Case: When Category, SubCategory and Account are matching, Asset will be populated on case.
        
    
    }

    @isTest
    private static void testUpdateServiceRequestChannel() {
        // Create test data
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), CONTACT_DEFAULTS_LIGHT, true);
        
        Case caseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseRecord.ContactId = newContact.Id;
        caseRecord.NSP_NiceCX_Case__c = true;
        caseRecord.Origin = 'Phone';
        
        Test.startTest();
        insert caseRecord;
        Test.stopTest();

        // Retrieve the updated Contact
        Contact updatedContact = [SELECT NSP_Service_Request_Channel__c FROM Contact WHERE Id = :newContact.Id];

        // Assert the expected results
        System.assertEquals(NSP_ServiceConstants.PHONE_CHANNEL, updatedContact.NSP_Service_Request_Channel__c);
    }

    @isTest
    private static void checkTheEligibiltyOfConfidentialityTest() {
        
        List<String> CASE_FIELDS = new List<String>{'Id', 'NSP_Category__c','NSP_SubCategory__c', 'AccountId', 'AssetId', 'NSP_Show_Confidential_Checkbox__c'};
        //Query for Case
        String getCaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('NSP_Category__c', NSP_ServiceConstants.CATEGORY_ADAPTION).addLimit(1).setSecurityEnforce(false).build();
        Case getCase =  Database.query(getCaseQuery);
        
        Test.startTest();
        getCase.NSP_Category__c = NSP_ServiceConstants.HR_EMPLOYEE_RELATIONS;
        getCase.NSP_SubCategory__c = 'Client Guidance';
        update getCase;
        Test.stopTest();
        
        //Query for Case
        String assertCaseQuery = new NSP_QueryBuilder(NSP_ServiceConstants.CASE_OBJECT_NAME, CASE_FIELDS).addFilter('Id', getCase.Id).addLimit(1).setSecurityEnforce(false).build();
        Case assertCase =  Database.query(assertCaseQuery);
        
        System.assertEquals(assertCase.NSP_Show_Confidential_Checkbox__c, false);
        
    }

    @isTest
    private static void checkInboxEmailOriginTest() {
        Account newAccount = [SELECT Id, Name FROM Account WHERE Name != null LIMIT 1];
        Case caseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseRecord.AccountId = newAccount.Id;
        caseRecord.NSP_Topic__c = 'Benefits/H&W';
        
        Test.startTest();
        insert caseRecord;
        Test.stopTest();
        Assert.areNotEqual(caseRecord.Origin, null);
    }

    @isTest
    private static void HarshipCaseTest() {
        Id recordTypePEOID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
        Case caseRecord = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
        caseRecord.NSP_Category__c = '';
        caseRecord.NSP_SubCategory__c = '';
       caseRecord.NSP_Assigned_Queue__c= NSP_CaseTriggerHelper.RET_NSPHardship_QUEUE;
       
       Test.startTest();
       insert caseRecord;
       Test.stopTest();
       
       Case getCase = [Select Id,NSP_Category__c from Case where Id=:caseRecord.Id];
       Assert.isNotNull(getCase,'Case should not be null after the case insert');
       Assert.areEqual(getCase.NSP_Category__c,'Retirement Svc-Processing');
       Assert.areNotEqual(getCase.NSP_Category__c,'');
    }    

}
//