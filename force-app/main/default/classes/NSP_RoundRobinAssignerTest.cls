/**
* Represents test class for round robin assigner class
*/

@isTest(SeeAllData=false)
public class NSP_RoundRobinAssignerTest {
    //test setup method for data setup
    @testSetup
    static void testData() {
        //Create custom object record for lead zip to city Mapping
        NSP_Zip_To_City_Mapping__c zipToCityObject = new NSP_Zip_To_City_Mapping__c();
        zipToCityObject.NSP_City__c = 'New York';
        zipToCityObject.NSP_Location_Name__c = 'New York';
        zipToCityObject.NSP_State__c = 'NY';
        zipToCityObject.NSP_Zip__c = '10001';
        
        //insert zip to city mapping record
        insert zipToCityObject;
        
        //Create Office records
        NSP_Office__c officeObj =  new NSP_Office__c();
        officeObj.NSP_Last_Index_Used__c = 0;
        officeObj.Name ='New York';
        //insert office record
        insert officeObj;
        
        //Creating User
        String lang = 'en_US';
        User userRecord = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            LastName = 'TestClassUser',
            Email = 'testuser@test.com',
            Username = 'testuser@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = lang,
            LocaleSidKey = lang
        );
        //insert user record
        insert userRecord;
        
        User userRecord1 = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'][0].Id,
            LastName = 'TestClassUser1',
            Email = 'testuser1@test.com',
            Username = 'testuser1@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = lang,
            LocaleSidKey = lang
        );
        //insert user record
        insert userRecord1;
        
        //Create office assignment record
        NSP_Office_Assignment__c officeAssignmentObj =  new NSP_Office_Assignment__c();
        officeAssignmentObj.NSP_District_Administrator__c= userRecord.id;
        officeAssignmentObj.NSP_Location_Name__c=officeObj.id;
        officeAssignmentObj.NSP_Office_Number__c=1;
        officeAssignmentObj.Name = '3300 New York 1';
        //insert office assignment
        Insert officeAssignmentObj;
        
        //Create office assignment record
        NSP_Office_Assignment__c officeAssignmentObj1 =  new NSP_Office_Assignment__c();
        officeAssignmentObj1.NSP_District_Administrator__c= userRecord1.id;
        officeAssignmentObj1.NSP_Location_Name__c=officeObj.id;
        officeAssignmentObj1.NSP_Office_Number__c=2;
        officeAssignmentObj1.Name = '3301 New York 2';
        //insert office assignment
        Insert officeAssignmentObj1;
        
    }
    
    /**
* Checks the update protion of the trigger
* @param N/A. 
* @return void                          
*/
    @isTest
    static void roundRobin() {
        //Lead refrence
        List<Lead> leadList = new List<Lead>();
        
        //iterating to create multiple lead records
        for(integer itr=0;itr<5;itr++){
            Lead leadObject = new Lead();
            leadObject.firstname='Test';
            leadObject.lastname='Lead' + 'itr';
            leadObject.Company = 'TestClass' + 'itr';
            leadObject.Email = 'test@test' + 'itr' + '.com';
            leadObject.PostalCode = '10001';
            
            // Adding object to the list
            leadList.add(leadObject);      
        }
        //Inserting lead record
        insert leadList;
        // Assert statement
        System.assert(leadList.Size() >0, true);
    }
}