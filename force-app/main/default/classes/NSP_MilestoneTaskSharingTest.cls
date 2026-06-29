@isTest
public class NSP_MilestoneTaskSharingTest {
    
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
        //inserting users
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
            oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
            oProject.RecordTypeId = PEORecordTypeId;
            oProject.pse__Start_Date__c = system.today();
            oProject.pse__Account__c =acc1.Id;
            insert oProject;
                    
            //inserting Milestone
            pse__Milestone__c oMilestone = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), MILESTONEDEFAULTS, false);
            oMilestone.pse__Project__c = oProject.id;
            oMilestone.pse__Target_Date__c = System.Today().addDays(10);
            insert oMilestone;
            
            pse__Region__c reg = new pse__Region__c();
            reg.name = NSP_ServiceConstants.UnitedStatesRegion;
            insert reg;
            
        }
    }

    /***********************************************************************************************
    * MethodName: shareMilestoneTest
    * Description : unit test for Share Milestone
    * ********************************************************************************************/    
    @isTest
    static void shareMilestoneTest() {

        User user=[Select Id , Name , Email  from User WHERE UserName =  'insperityadminuser@insperity.com.testUs' Limit 1];
        AccountContactRelation acrObj  = [SELECT Id ,ContactId , AccountId , NSP_Community_Access__c FROM AccountContactRelation WHERE NSP_Community_Access__c !=null LIMIT 1 ];
        pse__Milestone__c milestone = [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Milestone__c WHERE 
                                           pse__Project__c != Null Limit 1 ];
        milestone.NSP_Visible_to_Client__c = true; 
        
       
        // Start Test
        System.runAs (user) {
        Test.startTest();
            update milestone; 
        // Stop test
        Test.stopTest();
             
        }
       
        /* User portalUser = [SELECT Id , ContactId FROM User WHERE ContactId =:acrObj.ContactId LIMIT 1 ];
        
        pse__Milestone__share mileShare = [SELECT Id , ParentId , UserorGroupId FROM pse__Milestone__share 
                                     		WHERE ParentId =:milestone.Id  AND 
                                           RowCause = :Schema.pse__Milestone__share.RowCause.InsperitySharing__c ];  
          
        System.assertEquals(mileShare.UserorGroupId, portalUser.Id );  */
    }
    /***********************************************************************************************
    * MethodName: shareMilestoneTestException
    * Description : unit test for Share Milestone
    * ********************************************************************************************/    
    @isTest
    static void shareMilestoneTestException() {

        pse__Milestone__c milestone = [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Milestone__c WHERE 
                                           pse__Project__c != Null Limit 1 ];
        
        List<pse__Milestone__share> mileShare = [SELECT Id , ParentId , UserorGroupId FROM pse__Milestone__share 
                                     		WHERE ParentId =:milestone.Id  AND 
                                           RowCause = :Schema.pse__Milestone__share.RowCause.InsperitySharing__c ];  
          
        System.assertEquals(0,mileshare.Size() );  
    }
}