@isTest
private class NSP_portalUserSharingTest {

    private static final String PROJECTDEFAULTS = 'NSP_TestDataFactory.ProjectDefaults';
    private static final String MILESTONEDEFAULTS = 'NSP_TestDataFactory.MileStoneDefaults';

    @testsetup
    private static void testData() {
        List<User> users = new List<User>();
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        UserRole userRole = [SELECT Id FROM UserRole WHERE Name='Business Performance Advisor'];
        Id PEORecordTypeId  = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOProject).getRecordTypeId();
        Id PEOProjectTaskRecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get('PEO_Project_Task').getRecordTypeId();

        User user = new User(alias = 'jsmi', email='jsmith@insperity.com',
                             emailencodingkey='UTF-8', lastname='Smih',
                             languagelocalekey= 'en_US',
                             localesidkey= 'en_US', profileid = profileobj.Id, userroleid = userRole.Id,
                             timezonesidkey= 'America/Los_Angeles' ,
                             username='insperityadminuser@insperity.com.testUs');
        users.add(user);
        insert users;
        System.runAs (user) {
            //Insert Test Account record
            Account acc1 = NSP_TestHelper.createAccount(true);
            NSP_TestHelper.createContact(acc1.id, true);
            // inserting project
            pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
            oProject.pse__Project_Type__c = NSP_ServiceConstants.ImplementationProjectType;
            oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
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

    @isTest
    private static void testCodeCoverage() {
        List<pse__Proj__c> projects = [
            SELECT Id , NSP_Visible_to_Client__c
            FROM pse__Proj__c
        ];
        for ( pse__Proj__c project : projects ) {
            project.NSP_Visible_to_Client__c = true;
        }
        //
        List<AccountContactRelation> relations = [
            SELECT Id , ContactId , AccountId , NSP_Community_Access__c
            FROM AccountContactRelation
        ];
        List<User> portalUsers = new List<User>();
        for ( AccountContactRelation relation : relations ) {
            relation.NSP_Community_Access__c = 'PEO Projects';
            portalUsers.add(
                new User(
                    UserName=UserInfo.getUsername() + '.portal' ,
                    FirstName='sharedFirstName' ,
                    LastName='sharedLastName' ,
                    Alias='alias' ,
                    CommunityNickname='communityNickname' ,
                    Email=UserInfo.getUserEmail() + '.portal' ,
                    ContactId=relation.ContactId ,
                    ProfileId='00e4x0000013MV2AAM' , // Customer Community Plus User
                    EmailEncodingKey='UTF-8' ,
                    TimeZoneSidKey='America/Los_Angeles' ,
                    LocaleSidKey='en_US' ,
                    LanguageLocaleKey='en_US'
                )
            );
        }
        //
        List<User> runners = [ SELECT Id FROM User WHERE ( Email = 'jsmith@insperity.com' ) LIMIT 1 ];
        User runner = runners[0];
        System.runAs ( runner ) {
            update relations;
            update projects;
        }
        System.runAs ( runner ) {
            insert portalUsers;
        }
        //
        Map<Id,Id> mapContactIdUserId = new Map<Id,Id>();
        for ( User portalUser : portalUsers ) {
            mapContactIdUserId.put( portalUser.ContactId , portalUser.Id );
        }
        //
        Test.startTest();
        NSP_portalUserSharing.enqueueJob( mapContactIdUserId );
        Test.stopTest();
        //
        NSP_portalUserSharing.createMilestoneShare( null , null );
        NSP_portalUserSharing.createProjectTaskShare( null , null );
    }

    @isTest
    private static void shareProjectsTest() {
        Test.startTest();
        User user=[Select Id , Name , Email  from User WHERE Email = 'jsmith@insperity.com' Limit 1];

        pse__Proj__c project = [Select Id ,pse__Account__c,pse__Project_Type__c,NSP_Visible_to_Client__c,TemplateName__c, RecordTypeId From pse__Proj__c
                                WHERE TemplateName__c =: label.Middle_Market_Implementation_Project ];

        pse__Milestone__c milestone = [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Milestone__c WHERE
                                           pse__Project__c =:project.Id  ];

        pse__Project_Task__c projectTask = [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Project_Task__c WHERE
                                                 pse__Project__c =:project.Id ];

        project.NSP_Visible_to_Client__c = true;
        milestone.NSP_Visible_to_Client__c = true;
        projectTask.NSP_Visible_to_Client__c = true;

        AccountContactRelation acrObj  = [SELECT Id ,ContactId , AccountId , NSP_Community_Access__c FROM
                                          AccountContactRelation WHERE NSP_Community_Access__c =null LIMIT 1 ];
        acrObj.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        // Start Test
        System.runAs (user) {

            update project;
            update milestone;
            update projectTask;
            update acrObj;
        }
        Test.stopTest();
    }

    @isTest
    private static void shareProjectsTestException() {
       Test.startTest();
       User user=[Select Id , Name , Email  from User WHERE Email = 'jsmith@insperity.com' Limit 1];

        pse__Proj__c project = [Select Id ,pse__Project_Type__c,NSP_Visible_to_Client__c,TemplateName__c, RecordTypeId From pse__Proj__c
                                WHERE TemplateName__c =: label.Middle_Market_Implementation_Project ];
        pse__Milestone__c milestone = [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Milestone__c WHERE
                                           pse__Project__c =:project.Id  ];
        pse__Project_Task__c projectTask = [SELECT Id , pse__Project__c , pse__Project__r.pse__Account__c, NSP_Visible_to_Client__c FROM pse__Project_Task__c WHERE
                                                 pse__Project__c =:project.Id ];

        AccountContactRelation acrObj  = [SELECT Id ,ContactId , AccountId , NSP_Community_Access__c FROM
                                          AccountContactRelation WHERE NSP_Community_Access__c =null LIMIT 1 ];
        acrObj.NSP_Community_Access__c = NSP_ServiceConstants.peoCommunityAccess;
        // Start Test
        System.runAs (user) {

            update acrObj;
        }
        Test.stopTest();
        List<pse__proj__share> prjShare = [SELECT Id , ParentId , UserorGroupId FROM pse__proj__share
                                             WHERE ParentId =:project.Id  AND RowCause = :Schema.pse__Proj__Share.RowCause.InsperitySharing__c ];

        List<pse__Project_Task__share> prjTskShare = [SELECT Id , ParentId , UserorGroupId FROM pse__Project_Task__share
                                                      WHERE ParentId =:projectTask.Id  AND RowCause = :Schema.pse__Project_Task__share.RowCause.InsperitySharing__c ];

        List<pse__Milestone__share> mileShare = [SELECT Id , ParentId , UserorGroupId FROM pse__Milestone__share
                                                  WHERE ParentId =:milestone.Id  AND  RowCause = :Schema.pse__Milestone__share.RowCause.InsperitySharing__c ];
        System.assertEquals(prjShare.size(), 0);
        System.assertEquals(prjTskShare.size(), 0);
        System.assertEquals(mileShare.size(), 0);
    }

}
//