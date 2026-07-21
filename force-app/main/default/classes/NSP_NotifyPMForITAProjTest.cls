@isTest
private class NSP_NotifyPMForITAProjTest {

    //test setup method
    @testSetup
    private static void setUpData() {

        //create Account Record
        Account accoutObject = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        insert accoutObject;

        //create Asset Record
        Id woAssetRecordType = NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
        Asset assetObj1 = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        assetObj1.NSP_Client__c = 'asset1';
        assetObj1.name = 'assetLinkedWithPlanSubPlan';
        assetObj1.NSP_Client_Segment_type__c = 'Core';
        assetObj1.RecordTypeId = woAssetRecordType;
        assetObj1.accountID = accoutObject.ID;
        insert assetObj1;

        //Create proj
        Id retProjectRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'PEO_Project');
        pse__Proj__c newProj = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        newProj.pse__Is_Template__c = false;
        newProj.pse__Project_Status__c = 'Active';
        newProj.TemplateName__c = NSP_ServiceConstants.ITA_IMPLEMENTATION ;
        newProj.pse__Account__c =accoutObject.ID;
        newProj.pse__Project_Type__c = 'Implementation';
        newProj.RecordTypeId = retProjectRecordTypeId;
        newProj.pse__End_Date__c = Date.Today().addDays(30);
        insert newProj;

        //new user record
        User userRec = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        //create contact rec
        Contact con = new Contact();
        con.AccountId = accoutObject.Id;
        con.lastName= 'Test';
        con.pse__Salesforce_User__c=userRec.Id;
        con.NSP_Work_email__c='test@insperity.com';
        //insert contact rec
        insert con;

        List<Implementation_Profile__c> listIP = new List<Implementation_Profile__c>();
        Id ipFSORecordTypeId = NSP_GenericRecordType.getRecordTypeId('Implementation_Profile__c', NSP_ServiceConstants.FSOProfile);
        for(integer i=0;i<2;i++){
        //create Ip rec
        Implementation_Profile__c impl = new Implementation_Profile__c();
        impl.RecordTypeId = ipFSORecordTypeId;
        //impl.NSP_Project__c = newProj.Id;
        impl.NSP_Form_Completed__c = True;
        impl.Client_Profile_Information__c = 'Related Clients';
        impl.Account__c = accoutObject.Id;
        impl.NSP_Payroll_Specialist__c = con.Id;
        impl.NSP_Project_Manager__c = con.Id;
        impl.Type_of_retirement_plan_client_has_today__c = '403B';
        impl.Client_working_with_an_NSP_RS_rep__c = NSP_ServiceConstants.YES;
        impl.Retirement_services_notes__c = 'TEST' + i;
        impl.Employees_work_in_the_following_states__c = 'AK';
        impl.NSP_Project_Manager__c = con.ID;
        //insert Ip rec
        listIP.add(impl);
        }
        insert listIP;

        List<User> deploymentManagers = [
            SELECT Id
            FROM User
            WHERE ( Id = '0054x0000056lRZAAY' )
            LIMIT 1
        ];
        Assert.isNotNull( deploymentManagers , 'Null Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() > 0 ) , 'No Deployment Manager query results.' );
        Assert.isTrue( ( deploymentManagers.size() == 1 ) , 'Incorrect Deployment Manager query results.' );
        User deploymentManager = deploymentManagers[0];
        System.runas( deploymentManager ) {
            Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
            emailSetting.IsEnabledOutbound__c = true;
            upsert emailSetting;
        }
    }

    @isTest
    private static void nspNotifyPMForITAProjTestmethod() {
        //when
        Test.startTest();

        EmailTemplate template = new EmailTemplate ();
        template.developerName = NSP_ServiceConstants.ITA_Project_Creation_Email;
        template.FolderId=userInfo.getUserId();
        template.TemplateType='Text';
        template.Name='TestEmailTempalte_Unique';
        insert template;
        NSP_NotifyPMForITAProjBatch.schedule();
        Database.executeBatch(new NSP_NotifyPMForITAProjBatch(),200);
        Test.stopTest();
        List<String> PROJECT_FIELDS = new List<String>{
            'Id',
            'Name',
            'pse__Project_Status__c',
            'pse__End_Date__c',
            'pse__Account__c',
            'NSP_Is_ITA_Mail_Sent__c',
            'pse__Start_Date__c'
        };

        String projQuery = new NSP_QueryBuilder(NSP_ServiceConstants.PROJECT_SOBJECT_NAME, PROJECT_FIELDS)
            .addFilter('TemplateName__c', NSP_ServiceConstants.ITA_IMPLEMENTATION)
            .addLimit(1)
            .build();
        pse__Proj__c projTemplate = Database.query(projQuery);
    }

}
//
