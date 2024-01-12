/*
*Test class for NSP_AddressCtrl
*@Utpal Utkalit
*/


@isTest(SeeAllData=false)
public without sharing class NSP_AddressCtrlTest {
    
    //test setup data for NSP_AddressCtrlTest
    @testSetup
    public static void createTestData(){
        Account acnt=NSP_TestHelper.createAccount(true);
        NSP_Address__c addressRecord = NSP_TestHelper.createCustomAddress();
        addressRecord.NSP_Related_Site__c = acnt.Id;
        NSP_AddressCtrl.saveAddress(addressRecord);
        //insert addressRecord;
     }
    
    /*get Address details test mehthod
     *Method Name : getAddressTest
     *@param : null
    */
    @isTest
    public static void getAddressTest(){
        List<NSP_Address__c> addressRecord = [SELECT Id, Name,NSP_Country__c FROM NSP_Address__c WHERE Name=:'Test Temporary Address' Limit 1];
        NSP_Address__c address;
        NSP_Address__c addressRecordRetrieve;
        if(addressRecord.size() > 0){
            address=addressRecord[0];
            addressRecordRetrieve = NSP_AddressCtrl.getAddress(address.Id);
        }
        System.assertEquals(addressRecordRetrieve.NSP_Country__c, address.NSP_Country__c);
        address = new NSP_Address__c();
        NSP_AddressCtrl.saveAddress(address);
        
    }
    
    
}