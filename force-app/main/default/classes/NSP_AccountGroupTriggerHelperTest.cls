/**
Apex Class Name      :  NSP_AccountGroupTriggerHelperTest
Version              :  1.0                                                                          
Created Date         :  12/24/2021   
Function             :  Represents test class for AccountGroupTrigger helper 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Anil                6/24/2022            First Iteration
*/

@isTest
public class NSP_AccountGroupTriggerHelperTest {
    /**
* Test data setup for Account Groups
* @param N/A. 
* @return void                          
*/
    private static String GROWTH_FORECAST = 'Growth Forecast';
    @testSetup
    static void testData() {
        Id autoCreatedRecordTypeId = Schema.SObjectType.NSP_Account_Group__c.getRecordTypeInfosByName().get('Automatically Created').getRecordTypeId();
            //creating account group
        List<NSP_Account_Group__c> lstAccGroups = new List<NSP_Account_Group__c>();
        for(Integer ints=0; ints<5; ints++){
            lstAccGroups.add(new NSP_Account_Group__c(Name = GROWTH_FORECAST,
                                                      RecordTypeId = autoCreatedRecordTypeId,
                                                      NSP_Account__c = 'Test Account',
                                                      NSP_Type__c = GROWTH_FORECAST,
                                                      NSP_Tag__c = 'Test Tag'));
        }
        insert lstAccGroups;
    }
    /* Before insert/Update for AccountGroupTrigger this will Create Account Groups and Updates the Group Names with Primary Account and Grouptype and Tag
*/
    @isTest
    static void updateAccountGroupNames() {
        
        test.startTest();
        //qurying account group
        List<NSP_Account_Group__c> lstAccGroups = [SELECT Id,Name,NSP_Account__c,NSP_Type__c,NSP_Tag__c FROM NSP_Account_Group__c WHERE Id != null LIMIT 5];
        
        for(NSP_Account_Group__c accgp: lstAccGroups){
            accgp.Name = GROWTH_FORECAST;
            accgp.NSP_Account__c = 'Test Account 1';
            accgp.NSP_Type__c = GROWTH_FORECAST;
            accgp.NSP_Tag__c = 'Test Tag 1';
        }
        update lstAccGroups;
        Integer countGroups = [SELECT COUNT() FROM NSP_Account_Group__c WHERE Id != Null];
        
        System.assertEquals(5, countGroups,true);
        
        delete lstAccGroups;
        undelete lstAccGroups;
        
        test.stopTest();
    }

    @isTest
    static void updateControlledGroupNames() {
     
        NSP_Account_Group__c controlledAccountGroup = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        controlledAccountGroup.NSP_Account_Group_External_ID__c = '001';
        controlledAccountGroup.NSP_Tag__c = 'Test Grp 2';
        controlledAccountGroup.NSP_Type__c = 'Controlled Group';
        controlledAccountGroup.RecordTypeId =  NSP_GenericRecordType.getRecordTypeId('NSP_Account_Group__c', 'Automatically_Created');
        
        Test.startTest();
        INSERT controlledAccountGroup;
        String query = new NSP_QueryBuilder('NSP_Account_Group__c', new List<String>{'Name'}).addFilter('NSP_Type__c', 'Controlled Group').addLimit(1).build();
        NSP_Account_Group__c accountGroup = (NSP_Account_Group__c) Database.query(query);
        System.assertEquals(accountGroup.Name, 'Controlled Group 001', true);
        Test.stopTest();

    }


    @isTest
    static void updateOtherGroupNames() {
     
        NSP_Account_Group__c controlledAccountGroup = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', false);
        controlledAccountGroup.NSP_Account_Group_External_ID__c = '001';
        controlledAccountGroup.NSP_Tag__c = 'Test Grp 2';
        controlledAccountGroup.NSP_Type__c = GROWTH_FORECAST;
        controlledAccountGroup.RecordTypeId =  NSP_GenericRecordType.getRecordTypeId('NSP_Account_Group__c', 'Automatically_Created');
        
        Test.startTest();
        INSERT controlledAccountGroup;
        String query = new NSP_QueryBuilder('NSP_Account_Group__c', new List<String>{'Name'}).addFilter('NSP_Type__c', GROWTH_FORECAST).addLimit(1).build();
        NSP_Account_Group__c accountGroup = (NSP_Account_Group__c) Database.query(query);
        //assert
        System.assertNotEquals(accountGroup.Name, 'Growth Forecast 001', true);
        Test.stopTest();

    }
}