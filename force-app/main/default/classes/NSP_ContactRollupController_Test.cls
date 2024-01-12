/**
Apex Class Name      :  NSP_ContactRollupController_Test
Version              :  1.0                                                                          
Created Date         :  6/9/2022  
Function             :  Represents test class for NSP_ContactRollupController class
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Bindu                      7/4/2022            First Iteration
*/


@isTest(SeeAllData = false)
public class NSP_ContactRollupController_Test {

    /**
     * Does test data setup
     * @param N/A. 
     * @return void                          
     */

    @testSetup
    static void testData() {
        //List of Account creation
        List < Account > lstAccounts = new List < Account > ();
        //iterating new account list
        for (Integer index = 0; index < 5; index++) {
            Account newAccount = new Account();
            newAccount.Name = 'Test Acc - 00' + index;
            newAccount.BillingCity = 'New York' + index;
            newAccount.BillingPostalCode = '10021' + index;
            newAccount.BillingCountry = 'United States';
            newAccount.BillingStreet = 'Broadway ' + index;
            newAccount.BillingState = 'Texas';
            newAccount.NSP_AIMS_Client__c = 'tesitng' + index;
            lstAccounts.add(newAccount);
        }
        insert lstAccounts;
        //List of Contact Creation
        List < Contact > lstContacts = new List < Contact > ();
        //iterating new contact list
        for (Integer index = 0; index < 5; index++) {
            Contact newContact = new Contact();
            newContact.FirstName = 'Test index ';
            newContact.LastName = '-C000' + index;
            newContact.NSP_Per_ID__c = '-C000' + index;
            newContact.AccountId = lstAccounts.get(0).id;
            lstContacts.add(newContact);
        }
        insert lstContacts;
        //Asset creation
        Asset assetObj = new Asset();
        assetObj.accountId = lstAccounts.get(0).Id;
        assetObj.NSP_Client__c = 'asset2';
        assetObj.name = 'asset2';
        assetObj.NSP_Need_Rollup_Recalculation__c = true;
        insert assetObj;
        //Sub client records creation
        List < NSP_Sub_Client__c > subClientList = new List < NSP_Sub_Client__c > ();
        //iterating new subclient list
        for (integer index = 0;index < 5; index++) {
            NSP_Sub_Client__c subClientObj = new NSP_Sub_Client__c();
            subClientObj.NSP_Client__c = 'asset1' + String.valueOf(index);
            subClientObj.NSP_Paid_Employees_Last_Month__c = 1;
            subClientObj.NSP_Actual_Full_Time_EE_Count__c = 1;
            subClientObj.NSP_Actual_Part_Time_EE_Count__c = 3;
            subClientObj.NSP_Actual_Seasonal_Time_EE_Count__c = 2;
            subClientObj.NSP_Contractual_Full_time_EE_Count__c = 2;
            subClientObj.NSP_Contractual_Part_time_EE_Count__c = 3;
            subClientObj.NSP_Contractual_Seasonal_Time_EE_Count__c = 1;
            subClientObj.NSP_Account__c = lstAccounts[0].Id;
            subClientObj.NSP_Asset__c = assetObj.Id;
            subClientList.add(subClientObj);
        }

        insert subClientList;
    }
    
    @isTest
    private static void testRollupRecords() {
        //Account creation list
        List < Account > accountList = [SELECT Id, BillingState FROM Account WHERE BillingState = 'Texas' Limit 5];
        //List to store created contacts
        List < Contact > contactList = [SELECT Id, LastName FROM Contact WHERE LastName = '-C0001' Limit 5];
        //List of subclient creation
        List < NSP_Sub_Client__c > subClientList = [SELECT Id, NSP_Paid_Employees_Last_Month__c FROM NSP_Sub_Client__c WHERE NSP_Paid_Employees_Last_Month__c = 1 Limit 5];
        //AccountContactRelation records creation
        List < AccountContactRelation > lstACR = new List < AccountContactRelation > ();
        //iterating new AccountContactRelation list
        for (AccountContactRelation acr: [select Id, NSP_Support_Role__c, NSP_Service_Roles__c FROM AccountContactRelation WHERE NSP_Service_Roles__c = 'Key Decision Maker' LIMIT 5]) {
            acr.NSP_Support_Role__c = 'Time & Attendance Secondary Admin';
            acr.NSP_Service_Roles__c = 'Key Decision Maker';
            acr.NSP_Owner__c = true;
            lstACR.add(acr);
        }
        update lstACR;
        // subClientContactList records creation
        List < NSP_Sub_Client_Contact__c > subClientContactList = new List < NSP_Sub_Client_Contact__c > ();
        //iterating new subClientContactList
        for (integer index = 0; index < 5; index++) {
            subClientContactList.add(
                new NSP_Sub_Client_Contact__c(NSP_Contact__c = contactList[0].Id,
                    NSP_Sub_Client__c = subClientList[index].Id
                ));

        }
        insert subClientContactList;

        Test.startTest();
        System.assertEquals(5, subClientContactList.size(), 'true');
        NSP_ContactRollupController.getContactRollUpRecords(accountList[0].Id, 2, true, null, '', '');
        Test.stopTest();
    }
    
    @isTest
    private static void testRollupRecords2() {
        List < Account > accountList = [SELECT Id, BillingState from Account WHERE BillingState = 'Texas' Limit 5];
        List < Contact > contactList = [SELECT Id, FirstName from Contact WHERE LastName = '-C0001' Limit 5];
        List < NSP_Sub_Client__c > subClientList = [SELECT Id FROM NSP_Sub_Client__c WHERE NSP_Paid_Employees_Last_Month__c = 1 Limit 5];
       // subClientContactList records creation
       List < NSP_Sub_Client_Contact__c > subClientContactList = new List < NSP_Sub_Client_Contact__c > ();
       // iterating new subClientContactList
        for (integer index = 0; index < 5; index++) {
            subClientContactList.add(
                new NSP_Sub_Client_Contact__c(NSP_Contact__c = contactList[0].Id,
                    NSP_Sub_Client__c = subClientList.get(index).Id,
                    NSP_On_Site_Supervisor__c = true,
                    NSP_Payroll_Contact__c = true,
                    NSP_Client_Leave_Administrator__c = true,
                    NSP_WC_Contact__c = true,
                    NSP_HR_Contact__c = true,
                    NSP_Background_Contact__c = true,
                    NSP_Unemployment_Contact__c = true,
                    NSP_Benefits_Contact__c = true
                ));
        }
        insert subClientContactList;

        Test.startTest();
        System.assertEquals(5, subClientContactList.size(), 'true');
        NSP_ContactRollupController.getContactRollUpRecords(accountList[0].Id, 2, true, null, '', '');
        Test.stopTest();
    }
    //testing records by passing null values 
    @isTest
    private static void testRollupRecords3() {
        Test.startTest();
        try {
            NSP_ContactRollupController.getContactRollUpRecords(null, null, null, null, '', '');
        } catch (Exception ex) {
            System.assertEquals('Script-thrown exception', ex.getMessage(), 'true');
        }
        Test.stopTest();
    }
}