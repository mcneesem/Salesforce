/**
    * Apex Class Name : NSP_ServicePlanProjectTaskBatch_Test
    * Function        : Represents test class for NSP_ServicePlanProjectTaskBatch class
    */
    
    @isTest(SeeAllData=false)
    public class NSP_ServicePlanProjectTaskBatch_Test 
    {
        public static pse__Proj__c projectRecord;
        
        //== Preparing Test Data
        @testSetup static void testData() 
        {
            //Creating Account record
            Account accountRecord 								= (Account)NSP_TestExtendedDataFactory.createSObject(new Account());
            accountRecord.NSP_Sales_Service_Account_Status__c 	= NSP_ServiceConstants.Account_Status;
            accountRecord.NSP_First_Pay_Date__c 				= system.Today();
            
            INSERT accountRecord;
            
            //Creating Asset record
            String woAssetRecordTypeId 					= NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, 
                                                                                                NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
            Asset assetRecord 							= (Asset)NSP_TestDataFactory.createSObject(new Asset());
            assetRecord.AccountId 						= accountRecord.Id;
            assetRecord.NSP_AIMS_First_Pay_Date__c 		= system.Today();
            assetRecord.NSP_Account_Status__c 			= NSP_ServiceConstants.AIMS_STATUS;
            assetRecord.NSP_Client_Segment_type__c 		= NSP_ServiceConstants.BTAssetSegment;
            assetRecord.RecordTypeId 					= woAssetRecordTypeId;
            assetRecord.NSP_Renewal_Date__c 			= system.Today();
            
            INSERT assetRecord;
            
            //Creating Sub Client record
            NSP_Sub_Client__c subClientRecord 		= (NSP_Sub_Client__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client__c());
            subClientRecord.NSP_Asset__c 			= assetRecord.Id;
            subClientRecord.NSP_Account__c 			= accountRecord.Id;
            subClientRecord.NSP_Renewal_Date__c 	= system.Today();
            subClientRecord.NSP_Client__c 			= NSP_ServiceConstants.ZERO_ZERO_SUFFIX;
            subClientRecord.NSP_Account_Status__c 	= NSP_ServiceConstants.AIMS_STATUS;
            subClientRecord.NSP_Sub_Client__c 		= '120000';
            
            INSERT subClientRecord;
            
            //Creating Project record
            projectRecord 							= new pse__Proj__c();
            projectRecord 							= (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c());
            projectRecord.pse__Account__c 			= accountRecord.Id;
            projectRecord.TemplateName__c 			= NSP_ServiceConstants.PROJECT_TEMPLATE_NAME;
            projectRecord.pse__Is_Template__c 		= False;
            projectRecord.pse__Project_Status__c 	= NSP_ServiceConstants.STATUS_ACTIVE;
            projectRecord.pse__Start_Date__c 		= Date.Today();
            projectRecord.pse__Project_Type__c 		= NSP_ServiceConstants.PROJECT_TYPE_SERVICE;
            
            INSERT projectRecord;
            
            // Create Project Task
            pse__Project_Task__c projTaskRecord = new pse__Project_Task__c();
            projTaskRecord.pse__Project__c 		= projectRecord.Id;
            projTaskRecord.Name 				= NSP_ServiceConstants.QTP1;
            
            INSERT projTaskRecord;
            
            // ASSERTS 
            Assert.isTrue(accountRecord != null);
            Assert.isTrue(woAssetRecordTypeId != null);
            Assert.isTrue(assetRecord != null);
            Assert.isTrue(subClientRecord != null);
            Assert.isTrue(projectRecord != null);
            Assert.isTrue(projTaskRecord != null);   
        }
        //@ Method Name: testServicePlanProjectTaskBatch
        @IsTest static void testServicePlanProjectTaskBatchWithRoleAsBusTeamHRSpecialist() 
        {
            pse__Project_Task__c projTask = [SELECT Id, Name, pse__Project__c 
                                             FROM 
                                             pse__Project_Task__c LIMIT 1];
            DELETE projTask;
            
            // Get Account
            Account accountRecord = [SELECT ID 
                                     FROM 
                                     Account 
                                     WHERE 
                                     NSP_Sales_Service_Account_Status__c = :NSP_ServiceConstants.Account_Status 
                                     LIMIT 1];
            
            //Creating Account Team record
            NSP_Account_Team__c accountTeamRecord = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c());
            accountTeamRecord.NSP_Account__c = accountRecord.Id;
            accountTeamRecord.NSP_User__c = UserInfo.getUserId();
            accountTeamRecord.NSP_Role__c = NSP_ServiceConstants.BUS_TEAM_HRSP_CL;
            INSERT accountTeamRecord;
            
            //Test Run
            Test.startTest();
            Database.executeBatch(new NSP_ServicePlanProjectTaskBatch()); //executes the batch class
            Test.stopTest();
            
            // Validating the Results
            Assert.areEqual(2, [SELECT count() 
                                FROM 
                                pse__Project_Task__c 
                                WHERE 
                                NSP_Category__c =: NSP_ServiceConstants.Client_Management]
                           );
            List<pse__Project_Task__c> projectTasks = [SELECT ID, OwnerId 
                                                       FROM pse__Project_Task__c 
                                                       LIMIT 2];
            
            Assert.areEqual(projectTasks[0].OwnerId, 	accountTeamRecord.NSP_User__c);
            Assert.areEqual(projectTasks[1].OwnerId, 	accountTeamRecord.NSP_User__c);
        }
        
        //@ Method Name: testServicePlanProjectTaskBatch
        @IsTest static void testServicePlanProjectTaskBatchWithRoleAsManagerHRServices() 
        {
            pse__Project_Task__c projTask = [SELECT Id, Name, pse__Project__c 
                                             FROM 
                                             pse__Project_Task__c LIMIT 1];
            DELETE projTask;
            
            // Get Account
            Account accountRecord = [SELECT ID 
                                     FROM 
                                     Account 
                                     WHERE 
                                     NSP_Sales_Service_Account_Status__c = :NSP_ServiceConstants.Account_Status 
                                     LIMIT 1];
            
            //Creating Account Team record
            NSP_Account_Team__c accountTeamRecord = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c());
            accountTeamRecord.NSP_Account__c = accountRecord.Id;
            accountTeamRecord.NSP_User__c = UserInfo.getUserId();
            accountTeamRecord.NSP_Role__c = NSP_ServiceConstants.MANAGER_HRSERVICES;
            INSERT accountTeamRecord;
            
            // Test Run
            Test.startTest();
            Database.executeBatch(new NSP_ServicePlanProjectTaskBatch()); //executes the batch class
            Test.stopTest();
            
            // Validating the Results
            Assert.areEqual(2, [SELECT count() 
                                FROM 
                                pse__Project_Task__c 
                                WHERE 
                                NSP_Category__c =: NSP_ServiceConstants.Client_Management]
                           );
            List<pse__Project_Task__c> projectTasks = [SELECT ID, OwnerId 
                                                       FROM pse__Project_Task__c 
                                                       LIMIT 2];
            
            Assert.areEqual(projectTasks[0].OwnerId, 	accountTeamRecord.NSP_User__c);
            Assert.areEqual(projectTasks[1].OwnerId, 	accountTeamRecord.NSP_User__c);
        }
        
        //@ Method Name: testServicePlanProjectTaskBatchNotRun
        @IsTest static void testServicePlanProjectTaskBatchNotRun() 
        {
            // Get Sub client and update the record
            NSP_Sub_Client__c subClient= [SELECT Id, NSP_Renewal_Date__c 
                                          FROM 
                                          NSP_Sub_Client__c 
                                          WHERE 
                                          NSP_Account_Status__c =:NSP_ServiceConstants.AIMS_STATUS 
                                          LIMIT 1];
            subClient.NSP_Renewal_Date__c = system.Today().addDays(1);
            UPDATE subClient;
            
            // Get Project Task and update the Record
            pse__Project_Task__c projTask = [SELECT Id, Name, pse__Project__c 
                                             FROM pse__Project_Task__c 
                                             LIMIT 1];
            
            projTask.pse__Start_Date_Time__c = system.Today().addDays(1);
            UPDATE projTask;
            
            // Test Run
            Test.startTest();
            Database.executeBatch(new NSP_ServicePlanProjectTaskBatch()); //executes the batch class
            Test.stopTest();
            
            // Validating the Results
            Assert.areEqual(0, [SELECT count() 
                                FROM 
                                pse__Project_Task__c 
                                WHERE 
                                NSP_Category__c =: NSP_ServiceConstants.Client_Management
                               ]
                           );
        }
    }