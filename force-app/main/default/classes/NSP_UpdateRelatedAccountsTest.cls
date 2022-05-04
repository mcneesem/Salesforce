/*
*@Description: This class is used to cover the NSP_UpdateRelatedAccounts Class.
@createdDate: 01/25/2022
@story/Defect : DF-01058
*/
@isTest(SeeAllData=false)
public class NSP_UpdateRelatedAccountsTest {     
    public static final string ACCOUNT_NAME = 'Test Account';
    public static final string PARTNER_CLIENT_RECORDTYPE = 'NSP_Partner_Client';
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    @testSetup
    static void testData() {
        Account accoutObject = new Account();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PARTNER_CLIENT_RECORDTYPE).getRecordTypeId();
        accoutObject.Name = ACCOUNT_NAME;
        accoutObject.recordTypeId=partnerRecordTypeId;
        //Inserting account object
        database.insert(accoutObject);
    }
    
        /**
* This Method is used to cover updateRelatedAccounts method
* @param N/A. 
* @return void                          
*/
@isTest
    static void updateRelatedAccountsTest() {
        set<String> accIdSet = new set<String>();
        Account acc = [SELECT Id,
                       		nsp_last_updated__c 
                       		FROM Account
                      		WHERE Name =: ACCOUNT_NAME];
        accIdSet.add(acc.Id);
        Test.startTest();
        NSP_UpdateRelatedAccounts.updateRelatedAccounts(accIdSet);
        Test.stopTest();
        Date assertDate = date.today();
        Account assertAcc = [SELECT Id,
                       		nsp_last_updated__c 
                       		FROM Account
                      		WHERE Name =: ACCOUNT_NAME];
        system.assertEquals(assertDate, assertAcc.nsp_last_updated__c);
    
    }
}