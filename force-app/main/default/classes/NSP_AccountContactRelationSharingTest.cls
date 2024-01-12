/**
* @description  : Test Class for NSP_AccountContactRelationSharing .
* @date 11/14/2022
* Name : NSP_AccountContactRelationSharingTest
*/

@isTest
public class NSP_AccountContactRelationSharingTest {
    
    /***********************************************************************************************
* MethodName: testData
* Description : Test Data Method
* ********************************************************************************************/
    
    @testsetup 
    static void testData() {
        
        Id PEORecordTypeId  = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PEOProject);
        String pEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();

        //Insert Test Account record
        List<Account> accList = new List<Account> ();
        Account acc1 = (Account)NSP_TestDataFactory.createSObject(new Account(),'NSP_TestDataFactory.AccountDefaults');
        acc1.Name = 'acc1';
        accList.add(acc1);
        
        Account acc2 = (Account)NSP_TestDataFactory.createSObject(new Account(),'NSP_TestDataFactory.AccountDefaults');
        acc2.Name = 'acc2';
        accList.add(acc2);
        
        if(!accList.isEmpty()){
            database.insert(accList);
        }
        
        //create contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.AccountId = accList[0].Id;
        newContact.NSP_Work_email__c = 'test@pwc.com';
        insert newContact;
        
        
        // inserting project
        List<pse__Proj__c> projList = new List<pse__Proj__c> ();
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = PEORecordTypeId;
        oProject.pse__Account__c = acc1.Id;
        oProject.NSP_Visible_to_Client__c = true;
        projList.add(oProject);
        
        pse__Proj__c oProject1 = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject1.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject1.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject1.RecordTypeId = PEORecordTypeId;
        oProject1.pse__Account__c = acc2.Id;
        oProject1.NSP_Visible_to_Client__c = true;
        projList.add(oProject1);
        
        if(!projList.isEmpty()){
            database.insert(projList);
        }

        pse__Milestone__c milestone = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), 'NSP_TestDataFactory.MileStoneDefaults', false);
        milestone.pse__Project__c = oProject.id;
        insert milestone;
        
        pse__Project_Task__c oProjectTask2 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        oProjectTask2.Name = 'pTask2';
        oProjectTask2.pse__Project__c = oProject.Id;
        oProjectTask2.NSP_of_Days_Offset__c = 10;
        oProjectTask2.pse__Milestone__c = milestone.id;
        oProjectTask2.NSP_Template_Generated__c = true;
        oProjectTask2.RecordTypeId = pEOProjectTaskRecordTypeId;
        oProjectTask2.NSP_Visible_to_Client__c = true;
        oProjectTask2.NSP_Account_Id__c = acc1.Id;
        oProjectTask2.pse__Start_Date_Time__c = system.today().addDays(2);
        oProjectTask2.pse__End_Date_Time__c = system.today().addDays(62);
        
        insert oProjectTask2;

        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
		region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;
        
        
    }
    
    
    
    /***********************************************************************************************
	* MethodName: testProjectRecordSharing
	* Description : unit test for Share Projects when acr is created , deleted and updated
	* ********************************************************************************************/    
    @isTest
    static void testProjectRecordSharing() {
        //test on update
        List<String> setOfAcrFields =new List<String> {'NSP_Community_Access__c','ContactId','AccountId'};
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', setOfAcrFields)
            .addLimit(1).build();
        AccountContactRelation acr = Database.query(acrQuery);
        acr.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        //test on insert
        List<String> setOfAccFields =new List<String> {'Id','Name'};
        String accQuery = new NSP_QueryBuilder('Account', setOfAccFields)
            			  .addFilter('Name', 'acc2')
            			  .addLimit(1).build();
        Account acc = Database.query(accQuery);
        List<String> setOfConFields =new List<String> {'Id', 'NSP_Work_email__c', 'AccountId'};
        String conQuery = new NSP_QueryBuilder('Contact', setOfConFields)
            			  .addFilter('NSP_Work_email__c', 'test@pwc.com')
            			  .addLimit(1).build();
        Contact con = Database.query(conQuery);
        List<String> setOfProjFields =new List<String> {'Id', 'pse__Account__c'};
        String projQuery = new NSP_QueryBuilder('pse__Proj__c', setOfProjFields)
            			  .addFilter('pse__Account__c', acc.id)
            			  .addLimit(1).build();
        pse__Proj__c proj = Database.query(projQuery);
        AccountContactRelation acr1 = (AccountContactRelation)NSP_TestExtendedDataFactory.createSObject(new AccountContactRelation(), 'NSP_TestDataFactory.acrDefaults', false);
        acr1.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        acr1.ContactId=con.Id;
        acr1.AccountId=acc.Id;
        
        Test.startTest();
        update acr; 
        insert acr1;
        System.assertEquals(acr.NSP_Community_Access__c, NSP_ServiceConstants.peoCommunityAccess);
        Test.stopTest();
    }
    
     /***********************************************************************************************
	* MethodName: testProjectRecordSharingException
	* Description : remoce of project sharing when acr is updated to remove community access
	* ********************************************************************************************/      
    @isTest
    static void testProjectRecordRemoveExceptionOnUpdate() {
        
        List<String> setOfAcrFields =new List<String> {'NSP_Community_Access__c','ContactId','AccountId'};
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', setOfAcrFields)
            .addLimit(1).build();
        AccountContactRelation acr = Database.query(acrQuery);
        acr.NSP_Community_Access__c = null;
        User portalUser = [SELECT Id,ContactId FROM User 
                           WHERE  Profile.Name=:NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS 
                           LIMIT 1];
        
        Test.startTest();
        update acr; 
        Test.stopTest();
        
        List<pse__proj__share> prjShare = [SELECT Id , 
                                           ParentId , UserorGroupId
                                           FROM pse__proj__share 
                                           WHERE UserorGroupId =:portalUser.Id  
                                           AND RowCause = :Schema.pse__Proj__Share.RowCause.InsperitySharing__c ];
        
        System.assertEquals(prjShare.size(), 0);  
    }
}