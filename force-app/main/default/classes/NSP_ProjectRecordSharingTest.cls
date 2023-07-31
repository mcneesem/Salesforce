/**
* @description  : Test Class for NSP_ProjectRecordSharing .
* @date 11/14/2022
* Name : NSP_ProjectRecordSharingTest
*/

@isTest
public class NSP_ProjectRecordSharingTest {
    
    /***********************************************************************************************
* MethodName: testData
* Description : Test Data Method
* ********************************************************************************************/
    
    @testsetup 
    static void testData() {
        
        Id PEORecordTypeId  = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PEOProject);
        
        //Insert Test Account record
        Account acc1 = (Account)NSP_TestDataFactory.createSObject(new Account(),'NSP_TestDataFactory.AccountDefaults');
        acc1.Name = 'acc1';
        insert acc1;
        
        //create contact
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.AccountId = acc1.Id;
        newContact.Email = 'test@pwc.com';
        newContact.NSP_Work_email__c = 'test@pwc.com';
        insert newContact;
        
        // inserting project
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.RecordTypeId = PEORecordTypeId;
        oProject.pse__Account__c = acc1.Id;
        insert oProject;
        
        pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
		region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        insert region;
        
    }
    
    /***********************************************************************************************
* MethodName: testProjectRecordSharing
* Description : unit test for Share Projects
* ********************************************************************************************/    
    @isTest
    static void testProjectRecordSharing() {
        
        //update AccountContactRelation
        List<String> setOfAcrFields =new List<String> {'NSP_Community_Access__c','ContactId','AccountId'};
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', setOfAcrFields)
            .addLimit(1).build();
        AccountContactRelation acr = Database.query(acrQuery);
        acr.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        update acr;
        

        List<String> setOfProjectFields = new List<String> {'ID','pse__Project_Type__c','NSP_Visible_to_Client__c','TemplateName__c'};
        String projectQuery = new NSP_QueryBuilder('pse__Proj__c',setOfProjectFields)
            .addFilter('TemplateName__c', label.Middle_Market_Implementation_Project)
            .addLimit(1).build();
        pse__Proj__c project = Database.query(projectQuery);
        project.NSP_Visible_to_Client__c = true;
        
        
        // Start Test
        Test.startTest();
        update project; 
        //stop test
        Test.stopTest();

        User portalUser = [SELECT Id ,
                           ContactId 
                           FROM User
                           WHERE 
                           Profile.Name=:NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS LIMIT 1];
        pse__proj__share prjShare = NSP_ProjectRecordSharing.createProjectSharing(portalUser.ID,project.ID);        
       
        System.assertEquals(prjShare.UserorGroupId, portalUser.Id );  
    }
    
    /***********************************************************************************************
* MethodName: testProjectRecordSharingException
* Description : negativce unit test for Share Projects
* 
* ********************************************************************************************/      
    @isTest
    static void testProjectRecordSharingException() {
        
        User portalUser = [SELECT Id ,
                           ContactId 
                           FROM User 
                           WHERE  Profile.Name=:NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS 
                           LIMIT 1];
        
        List<String> setOfProjectFields =new List<String> {'pse__Project_Type__c','NSP_Visible_to_Client__c','TemplateName__c'};
        String projectQuery = new NSP_QueryBuilder('pse__Proj__c',setOfProjectFields)
            .addFilter('TemplateName__c', label.Middle_Market_Implementation_Project)
            .addLimit(1).build();
        pse__Proj__c project = Database.query(projectQuery);
        project.NSP_Visible_to_Client__c=false;
        // Start Test
        Test.startTest();
        update project; 
        //stop test
        Test.stopTest();
        
        List<pse__proj__share> prjShare = [SELECT Id , 
                                           ParentId , UserorGroupId
                                           FROM pse__proj__share 
                                           WHERE UserorGroupId =:portalUser.Id  
                                           AND RowCause = :Schema.pse__Proj__Share.RowCause.InsperitySharing__c ];
        
        System.assertEquals(prjShare.size(), 0);  
    }

    /***********************************************************************************************
    * MethodName: testprojectRemoveSharing
    * Description : positive unit test for remove Project sharing
    * ********************************************************************************************/      
    @isTest
    static void testprojectRemoveSharing() {
    
        List<String> setOfAcrFields =new List<String> {'NSP_Community_Access__c','ContactId','AccountId'};
        String acrQuery = new NSP_QueryBuilder('AccountContactRelation', setOfAcrFields)
            .addLimit(1).build();
        AccountContactRelation acr = Database.query(acrQuery);
        User portalUser = [SELECT Id,ContactId FROM User 
                       WHERE  Profile.Name=:NSP_ServiceConstants.CUSTOMER_COMMUNITY_PLUS 
                       LIMIT 1];
    
        List<String> setOfProjectFields =new List<String> {'pse__Project_Type__c','NSP_Visible_to_Client__c','TemplateName__c'};
        String projectQuery = new NSP_QueryBuilder('pse__Proj__c',setOfProjectFields)
            .addFilter('TemplateName__c', label.Middle_Market_Implementation_Project)
            .addLimit(1).build();
        pse__Proj__c project = Database.query(projectQuery);
        Set<Id> projectIdSet = new Set<Id>();
        projectIdSet.add(project.Id);
        Test.startTest();
    
        NSP_ProjectRecordSharing.projectRemoveSharing(projectIdSet);
        List<pse__proj__share> prjShare = [SELECT Id , 
                                       ParentId , UserorGroupId
                                       FROM pse__proj__share 
                                       WHERE UserorGroupId =:portalUser.Id  
                                       AND ParentId =: project.Id
                                       AND RowCause = :Schema.pse__Proj__Share.RowCause.InsperitySharing__c ];
    
        System.assertEquals(prjShare.size(), 0);
        Test.stopTest();
    }
}