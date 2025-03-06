@isTest
private class NSP_CampaignTriggerHelperTest {

    private static final String emailencodingkey = 'UTF-8';
    private static final String languagekey = 'en_US'; 
    private static final String timezonesidkey = 'America/Los_Angeles';   

    @testSetup
    private static void testData() {
        
        List<NSP_Sales_Office_Mapping__c> offices = new List<NSP_Sales_Office_Mapping__c>();
        NSP_Sales_Office_Mapping__c officeMapping_1 = new NSP_Sales_Office_Mapping__c(
                                                            NSP_Sales_Office__c = '1403',
                                                            NSP_Sales_Division__c = 'Eastern',
                                                            NSP_Sales_Region__c = 'Eastern 3',
                                                            NSP_Start_Date__c = system.today()-1,
                                                            NSP_End_Date__c = system.today()+100);
        offices.add(officeMapping_1);
        
        NSP_Sales_Office_Mapping__c officeMapping_2 = new NSP_Sales_Office_Mapping__c(
                                                            NSP_Sales_Office__c = '4410',
                                                            NSP_Sales_Division__c = 'Central',
                                                            NSP_Sales_Region__c = 'Central 1',
                                                            NSP_Start_Date__c = system.today()-1,
                                                            NSP_End_Date__c = system.today()+100);
        offices.add(officeMapping_2);
        database.insert(offices);
       
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Profile profileMark = [SELECT Id FROM Profile WHERE Name='Marketing Channel'];
        UserRole LArole = [SELECT Id FROM UserRole WHERE Name='Loyalty Advisor'];
        UserRole DARole = [SELECT Id FROM UserRole WHERE Name = 'District Administrator'];
        List<User> users = new List<User>();
        //Creating User
      
        User LAuser = new User(alias = 'jBPA', email='jsmithyBPA@insperity.com', 
                                emailencodingkey=emailencodingkey, lastname='Smith', 
                                languagelocalekey=languagekey, 
                                localesidkey=languagekey, profileid = profileMark.Id, //userroleid = LArole.Id,
                                timezonesidkey=timezonesidkey, NSP_Sales_Office__c='302' , 
                                username='insperitytestadminuser@insperity.com.testBPA');
        users.add(LAuser);
        // Adding Sales Leader User
     
        
        User dAUser = new User(alias = 'jsmit', email='jsmithda@insperity.com', 
                               emailencodingkey=emailencodingkey, lastname='Smithda', 
                               languagelocalekey=languagekey, 
                               localesidkey=languagekey, profileid = profileobj.Id, //userroleid = DARole.Id,
                               timezonesidkey=timezonesidkey , NSP_Sales_Office__c='4410' , NSP_SalesDivision__c='Central' , NSP_SalesRegion__c='Central 1',
                               username='insperitytestadminuserda@insperity.com.testUsr');
        users.add(dAUser);

        database.insert(users);
        
    }

    @isTest
    private static void updateCampaignFieldOfficeTest() {
        User dAUser=[Select Id , Name , Email ,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from User WHERE Email = 'jsmithda@insperity.com' Limit 1];
        System.runAs (dAUser) {
            PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Campaign_Update_Sales_Office_Info_Owner_Assigned'];
            if (permSet != null) {
                insert new PermissionSetAssignment(AssigneeId = dAUser.id, PermissionSetId = permSet.Id);
            }
        
            //Campaign creation
            Test.startTest();
            Campaign campaignObject = new Campaign(
                RecordTypeId='0124x000000yRv1AAE' ,
                Name='HelloTest' ,
                OwnerId=UserInfo.getUserId() ,
            	NSP_Sales_Office__c = '1403'
            );
            insert campaignObject;
            Campaign camp = [Select Id , Name , NSP_Sales_Division__c , NSP_Sales_Office__c , NSP_Sales_Region__c from Campaign WHERE Name = 'HelloTest' Limit 1];
            Test.stopTest();
            System.assertEquals('HelloTest', camp.Name);
            System.assertEquals('4410', camp.NSP_Sales_Office__c);
            System.assertEquals('Central', camp.NSP_Sales_Division__c);
            System.assertEquals('Central 1', camp.NSP_Sales_Region__c);
        }
    }

    @isTest
    private static void updateCampaignFieldOfficeNegativeTest() {
        User dAUser=[Select Id , Name , Email ,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from User WHERE Email = 'jsmithda@insperity.com' Limit 1];
        System.runAs (dAUser) {
            //Campaign creation
            Test.startTest();
            Campaign campaignObject = new Campaign(
                RecordTypeId='0124x000000yRv1AAE' ,
                Name='HelloTestNeg' ,
                OwnerId=UserInfo.getUserId(),
            	NSP_Sales_Office__c = '1403'
            );
            insert campaignObject;
            Campaign camp = [Select Id , Name , NSP_Sales_Division__c , NSP_Sales_Office__c , NSP_Sales_Region__c from Campaign WHERE Name = 'HelloTestNeg' Limit 1];
            Test.stopTest();
            System.assertEquals('HelloTestNeg', camp.Name);
            System.assertEquals('1403', camp.NSP_Sales_Office__c);
            System.assertEquals(null, camp.NSP_Sales_Division__c);
            System.assertEquals(null, camp.NSP_Sales_Region__c);
        }
    }

    @isTest
    private static void updateCampaignFieldSalesOfficeTest() {        
        User LAUser=[Select Id , Name , Email ,NSP_Sales_Office__c from User WHERE Email = 'jsmithyBPA@insperity.com' Limit 1];
        System.runAs (LAUser) {
            PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Campaign_Update_Sales_Office_Info_Campaign_Assigned'];
            if (permSet != null) {
                insert new PermissionSetAssignment(AssigneeId = LAUser.id, PermissionSetId = permSet.Id);
            }
            
            //Campaign creation
            Test.startTest();
            Campaign campaignObject = new Campaign(
                RecordTypeId='0124x000000yRv1AAE' ,
                Name='HelloTest1' ,
                NSP_Sales_Office__c='1403'
            );
            insert campaignObject;
            Campaign camp = [Select Id , Name , NSP_Sales_Division__c , NSP_Sales_Office__c , NSP_Sales_Region__c from Campaign WHERE Name = 'HelloTest1' Limit 1];
            Test.stopTest();
            System.assertEquals('HelloTest1', camp.Name);
            System.assertEquals('1403', camp.NSP_Sales_Office__c);
            System.assertEquals('Eastern', camp.NSP_Sales_Division__c);
            System.assertEquals('Eastern 3', camp.NSP_Sales_Region__c);
        }
    }
}
//