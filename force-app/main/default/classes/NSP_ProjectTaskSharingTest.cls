@isTest
public class NSP_ProjectTaskSharingTest {
    
    /***********************************************************************************************
    * MethodName: testData
    * Description : Test Data Method
    * Author :      Nischay Jindal
    * ********************************************************************************************/
    public static final String PROJECTDEFAULTS = 'NSP_TestDataFactory.ProjectDefaults';
    public static final String MILESTONEDEFAULTS = 'NSP_TestDataFactory.MileStoneDefaults';
    
    @testsetup 
    static void testData() {
        List<User> users = new List<User>();
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole userRole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
        Id PEORecordTypeId  = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c',NSP_ServiceConstants.PEOProject);
        Id PEOProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Project_Task__c','PEO_Project_Task');
        
        User newUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', false);
        newUser.ProfileId = profileobj.Id;
        newUser.UserName =  'insperityadminuser@insperity.com.testUs';
        newUser.userroleid = userRole.Id;
        users.add(newUser);
        insert users;
        System.runAs (newUser) {
            //Insert Test Account record
            Account acc1 = NSP_TestHelper.createAccount(true);
            NSP_TestHelper.createContact(acc1.id, true); 
            AccountContactRelation acrObj  = [SELECT Id ,ContactId , AccountId , NSP_Community_Access__c FROM AccountContactRelation WHERE NSP_Community_Access__c =null LIMIT 1 ];
            acrObj.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
            update acrObj;
            // inserting project
            pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
            oProject.RecordTypeId = PEORecordTypeId;
            oProject.pse__Start_Date__c = system.today();
            oProject.pse__Account__c =acc1.Id;
            insert oProject;
            
            
            pse__Milestone__c oMilestone = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), MILESTONEDEFAULTS, false);
            oMilestone.pse__Project__c = oProject.id;
            oMilestone.pse__Target_Date__c = System.Today().addDays(10);
            insert oMilestone;
            
            pse__Project_Task__c oProjectTask1 = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
            oProjectTask1.pse__Project__c = oProject.Id;
            oProjectTask1.pse__Milestone__c = oMilestone.id;
            oProjectTask1.RecordTypeId = PEOProjectTaskRecordTypeId;
            insert oProjectTask1;
            
            pse__Region__c region = (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
			region.Name = NSP_ServiceConstants.UnitedStatesRegion;
        	insert region;
            
        }
    }
    
    /***********************************************************************************************
    * MethodName: shareProjectTaskTest
    * Description : unit test for Share Project Task 
    * ********************************************************************************************/    
    @isTest
    static void shareProjectTaskTest() {
        Test.startTest();
        User user=[Select Id , Name , Email  from User WHERE UserName =  'insperityadminuser@insperity.com.testUs' Limit 1];
        AccountContactRelation acrObj  = [SELECT Id ,ContactId , AccountId , NSP_Community_Access__c FROM AccountContactRelation WHERE NSP_Community_Access__c !=null LIMIT 1 ];
        pse__Project_Task__c prjTask = [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Project_Task__c WHERE 
                                        pse__Project__c != Null Limit 1 ];
        
        prjTask.NSP_Visible_to_Client__c = true; 
        
        
        // Start Test
        System.runAs (user) {
            update prjTask; 
        }
        /* User portalUser = [SELECT Id , ContactId FROM User WHERE ContactId =:acrObj.ContactId LIMIT 1 ];
        
        pse__Project_Task__Share prjShare = [SELECT Id , ParentId , UserorGroupId FROM pse__Project_Task__Share 
                                             WHERE ParentId =:prjTask.Id  AND 
                                             RowCause = :Schema.pse__Project_Task__Share.RowCause.InsperitySharing__c ];  
        
        System.assertEquals(prjShare.UserorGroupId, portalUser.Id ); 
        
        List<pse__Project_Task__share> oldProjShareList = NSP_ProjectTaskSharing.getProjectTaskShareList(new Set<Id>{prjTask.Id});
        DELETE oldProjShareList;
        
        List<pse__Project_Task__Share> prjShare1 = [SELECT Id , ParentId , UserorGroupId FROM pse__Project_Task__Share 
                                             WHERE ParentId =:prjTask.Id  AND 
                                             RowCause = :Schema.pse__Project_Task__Share.RowCause.InsperitySharing__c ];  
        
        System.assertEquals(0, prjShare1.Size()); */
        
        Test.stopTest();       
        
    }
    /***********************************************************************************************
    * MethodName: shareProjectTaskTestException
    * Description : unit test for Share Project Task 
    * ********************************************************************************************/    
    @isTest
    static void shareProjectTaskTestException() {
        Test.startTest();
        pse__Project_Task__c prjTask = [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Project_Task__c WHERE 
                                        pse__Project__c != Null Limit 1 ];
        
        
        
        List<pse__Project_Task__Share> prjShare = [SELECT Id , ParentId , UserorGroupId FROM pse__Project_Task__Share 
                                             WHERE ParentId =:prjTask.Id  AND 
                                             RowCause = :Schema.pse__Project_Task__Share.RowCause.InsperitySharing__c ];  
        
        System.assertEquals(0, prjShare.Size() );  
        Test.stopTest();       
        
    }
}