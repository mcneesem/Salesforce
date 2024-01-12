/**
* Represents test class for 
* Account trigger helper
* Author: Rahul Singh
* Created Date: 8/16/22
*/

@isTest(SeeAllData=false)
public class NSP_CampaignTriggerHelperTest {
    
    /***********************************************************************************************
Variables
********************************************************************************************/
    private static final String emailencodingkey = 'UTF-8';
    private static final String languagekey = 'en_US'; 
    private static final String timezonesidkey = 'America/Los_Angeles';   
    
    @testSetup
    static void testData() {
       
        Profile profileobj = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        Profile profileMark = [SELECT Id FROM Profile WHERE Name='Marketing Channel'];
        UserRole LArole = [SELECT Id FROM UserRole WHERE Name='Loyalty Advisor'];
        UserRole DARole = [SELECT Id FROM UserRole WHERE Name = 'District Administrator'];
        List<User> users = new List<User>();
        //Creating User
      
        User LAuser = new User(alias = 'jBPA', email='jsmithyBPA@insperity.com', 
                                emailencodingkey=emailencodingkey, lastname='Smith', 
                                languagelocalekey=languagekey, 
                                localesidkey=languagekey, profileid = profileMark.Id, userroleid = LArole.Id,
                                timezonesidkey=timezonesidkey, NSP_Sales_Office__c='302' , 
                                username='insperitytestadminuser@insperity.com.testBPA');
        users.add(LAuser);
        // Adding Sales Leader User
     
        
        User dAUser = new User(alias = 'jsmit', email='jsmithda@insperity.com', 
                               emailencodingkey=emailencodingkey, lastname='Smithda', 
                               languagelocalekey=languagekey, 
                               localesidkey=languagekey, profileid = profileobj.Id, userroleid = DARole.Id,
                               timezonesidkey=timezonesidkey,NSP_Sales_Office__c='4401' ,NSP_SalesDivision__c='Central',NSP_SalesRegion__c='Central 1',
                               username='insperitytestadminuserda@insperity.com.testUsr');
        users.add(dAUser);
        

        database.insert(users);
        
        
    }
    /***********************************************************************************************
* MethodName: setChannelPartnerAndLoyaltyAdvisor
* Description : This method is used to populate CPM and LA on Account on insertion based on BPA sales office group
* ********************************************************************************************/
    @isTest
    static void updateCampaignFieldOfficeTest() {
        User dAUser=[Select Id , Name , Email ,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from User WHERE Email = 'jsmithda@insperity.com' Limit 1];
        System.runAs (dAUser) {
            //Campaign creation
            Test.startTest();
            Campaign campaignObject = new Campaign(    
            Name = 'HelloTest',
            OwnerId = UserInfo.getUserId());
            insert campaignObject;
            Test.stopTest();
            System.assertEquals('HelloTest', campaignObject.Name);
        }
    }
    @isTest
    static void updateCampaignFieldSellsOfficeTest() {
        
        User LAUser=[Select Id , Name , Email ,NSP_Sales_Office__c from User WHERE Email = 'jsmithyBPA@insperity.com' Limit 1];
        System.runAs (LAUser) {
            //Campaign creation
            Test.startTest();
            NSP_Sales_Office_Mapping__c officeMapping = new NSP_Sales_Office_Mapping__c();
            officeMapping.NSP_Sales_Office__c = '1081';
            officeMapping.NSP_Sales_Division__c = 'Central';
            officeMapping.NSP_Sales_Region__c = 'Central 1';
            officeMapping.NSP_Start_Date__c = system.today()-1;
            officeMapping.NSP_End_Date__c = system.today()+100;
            insert officeMapping;

            Campaign campaignObject = new Campaign(    
            Name = 'HelloTest1',
            NSP_Sales_Office__c = '1081'
            );
            insert campaignObject;
            Test.stopTest();
            System.assertEquals('HelloTest1', campaignObject.Name);
        }
    }
}