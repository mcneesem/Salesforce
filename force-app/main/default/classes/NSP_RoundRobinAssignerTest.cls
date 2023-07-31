/**
* Represents test class for round robin assigner class
*/

@isTest(SeeAllData=false)
public class NSP_RoundRobinAssignerTest {
     public static final String LEADCONVERTRECORD_EMAIL ='Allstate@Allstate.com';
    public static final String LEADSTATUS ='Nurturing';
 @testSetup
    static void testData() {
               //Create custom setting record for lead zip to city Mapping
        NSP_Zip_To_City_Mapping__c zipToCityCustomSetting = new NSP_Zip_To_City_Mapping__c();
        zipToCityCustomSetting.NSP_City__c = 'New York';
        zipToCityCustomSetting.NSP_Location_Name__c = 'New York';
        zipToCityCustomSetting.NSP_State__c = 'NY';
        zipToCityCustomSetting.NSP_Zip__c = '10001';
        
        //Creteing zip to city record
        insert zipToCityCustomSetting;
        
        //Create Office records
        NSP_Office__c officeObj =  new NSP_Office__c();
        officeObj.NSP_Last_Index_Used__c = 5;
        officeObj.Name ='New York';
        insert officeObj;
        
        NSP_Zip_To_City_Mapping__c zipToCityCustomSetting1 = new NSP_Zip_To_City_Mapping__c();
        
        zipToCityCustomSetting1.NSP_City__c = 'New York1';
        zipToCityCustomSetting1.NSP_Location_Name__c = 'New York1';
        zipToCityCustomSetting1.NSP_State__c = 'NY1';
        zipToCityCustomSetting1.NSP_Zip__c = '10002';
        
        //Creteing zip to city record
        insert zipToCityCustomSetting1;
        
        //Create Office records
        NSP_Office__c officeObj1 =  new NSP_Office__c();
        officeObj1.NSP_Last_Index_Used__c = 0;
        officeObj1.Name ='New York1';
        insert officeObj1;
        
        //Creating User
        User userRecord = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
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
        //Inserting users that can be used in the test class data setup
        insert userRecord;
        
        //Create office assignment record
        NSP_Office_Assignment__c officeAssignmentObj =  new NSP_Office_Assignment__c();
        officeAssignmentObj.NSP_District_Administrator__c= userRecord.id;
        officeAssignmentObj.NSP_Location_Name__c=officeObj.id;
        officeAssignmentObj.NSP_Office_Number__c=1;
        officeAssignmentObj.Name = '3300 New York 1';
        officeAssignmentObj.NSP_Sales_Office__c = '301';
        //Inserting office assignment object
        Insert officeAssignmentObj;
        
        NSP_Office_Assignment__c officeAssignmentObj1 =  new NSP_Office_Assignment__c();
        officeAssignmentObj1.NSP_District_Administrator__c= userRecord.id;
        officeAssignmentObj1.NSP_Location_Name__c=officeObj1.id;
        officeAssignmentObj1.NSP_Office_Number__c = 1;
        officeAssignmentObj1.Name = '3300 New York 12';
        officeAssignmentObj1.NSP_Sales_Office__c = '302';
        //Inserting office assignment object
        Insert officeAssignmentObj1;
        
        //Account creation
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        accoutObject.Name = 'Test Account';
        accoutObject.recordTypeId=partnerRecordTypeId;
        accoutObject.DNBoptimizer__DNB_D_U_N_S_Number__c = '876543987';
        //Inserting account object
        insert accoutObject;
        
        Account accoutObject1 = new Account();
        accoutObject1.Name = 'Test Account1';
        
        //Inserting account object
        insert accoutObject1;
        
        //Contact creation        
        Contact contactObject = new Contact();
        contactObject.lastname = 'TestContact';
        contactObject.email = 'test@test.com';
        contactObject.AccountId=accoutObject1.id;
        //Inserting contact object
        insert contactObject;  
        //List to store Lead objects
        List<Lead> leadList = new List<Lead>();
        List<Lead> newLeadList = new List<Lead>();
        //Lead Creation
        Lead leadObject5 = new Lead();
        leadObject5.firstname='TestLead113';
        leadObject5.lastname='Acc';
        leadObject5.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        leadObject5.NumberOfEmployees =160;
        leadObject5.Company = 'Allstate123';
        leadObject5.NSP_Referred_By_COI__c = contactObject.Id;
        leadObject5.Email = 'test333@test.com';
        leadObject5.DNBoptimizer__DNB_D_U_N_S_Number__c  = '';
        leadObject5.NSP_Lead_Routing__c = true;
		newLeadList.add(leadObject5);
        
        Lead leadObject6 = new Lead();
        leadObject6.firstname='RounRobinTest';
        leadObject6.lastname='Acc';
        leadObject6.NSP_Product_Interest__c='Payroll & Human Capital Management(Workforce Acceleration)';
        leadObject6.NumberOfEmployees =160;
        leadObject6.Company = 'Allstate123';
        leadObject6.NSP_Referred_By_COI__c = contactObject.Id;
        leadObject6.Email = 'test333@test.com';
        leadObject6.DNBoptimizer__DNB_D_U_N_S_Number__c  = '';
        leadObject6.NSP_Lead_Routing__c = true;
		newLeadList.add(leadObject6);
        //insert lead records
        insert newLeadList; 
    }
        /**
* @Description: This test method is used to cover NSP_RoundRobinAssigner method
* @Created date: 05/02/2022. 
* @return void             
*     */  
           @isTest
public static void dunsCheckBeforeUpdateTest2(){ 
        Lead getLead = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_Lead_Routing__c,NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                       WHERE firstName = 'TestLead113'];
    getLead.DNBoptimizer__DNB_D_U_N_S_Number__c = '';
    getLead.PostalCode = '10001';
     getLead.NumberOfEmployees = 100;
    Test.startTest();
    database.update(getLead);
    Test.stopTest();
    system.assertEquals(getLead.PostalCode, '10001');
}
    
            /**
* @Description: This test method is used to cover NSP_RoundRobinAssigner method
* @Created date: 05/02/2022. 
* @return void             
*     */ 
     @isTest
public static void dunsCheckBeforeUpdateTest(){ 
        Lead getLead = [SELECT Id, Company,NSP_DC_SetDate__c, NSP_Product_Interest__c,NumberOfEmployees,PostalCode, NSP_Lead_Routing__c,NSP_DC_SetTime__c,NSP_Assign_Lead__c FROM Lead 
                       WHERE firstName = 'RounRobinTest'];
    getLead.DNBoptimizer__DNB_D_U_N_S_Number__c = '';
    getLead.PostalCode = '10002';
     getLead.NumberOfEmployees = 100;
    Test.startTest();
    database.update(getLead);
    Test.stopTest();
    system.assertEquals(getLead.PostalCode, '10002');
}
}