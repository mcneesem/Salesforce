/**
Apex Class Name      :  NSP_IpCopyActionEmailBodyContTest for NSP_IpCopyActionEmailBodyCont
Version              :  1.0                                                                          
Created Date         :  5/19/2023   
Function             :  Test class for NSP_IpCopyActionEmailBodyCont 
Story                :                                                                      
Modification Log     :                                                                              
*/

@isTest
private class NSP_IpCopyActionEmailBodyContTest {

    /******************************************************************
    * Method Name : testPopulateActionDetails
    * Description : test method for populateActionDetails, to check it's functionality
    */
    static testMethod void testPopulateActionDetails() {
        NSP_IpCopyActionEmailBodyCont controller = new NSP_IpCopyActionEmailBodyCont();

        Map<String, String> params = new Map<String, String>();
        params.put('recType', 'Test Record Type');
        params.put('success', '["a", "b", "c"]');
        params.put('fail', '["d", "e", "f"]');
        params.put('source', 'Test Account');

        Test.startTest();
        controller.populateActionDetails(params);
        Test.stopTest();

        System.assertEquals('Test Record Type', controller.getRecordTypeLabel());
        System.assertEquals('The copy action from Test Account to the following client(s) was ', controller.getSectionTitle());
    }



    /******************************************************************
    * Method Name : testPopulateRecordsByStatus
    * Description : test method for populateRecordsByStatus, where it is checking the IP records
    */
    static testMethod void testPopulateRecordsByStatus() {
        NSP_IpCopyActionEmailBodyCont controller = new NSP_IpCopyActionEmailBodyCont();

        Map<String, String> params = new Map<String, String>();
        params.put('recType', 'Test Record Type');
        params.put('success', '["a", "b", "c"]');
        params.put('fail', '["d", "e", "f"]');
        params.put('source', 'Test Account');

        List<String> allIpRecords = new List<String>{'a', 'b', 'c', 'd', 'e', 'f'};

        List<Implementation_Profile__c> ipRec = [SELECT Id, Account__r.Name FROM Implementation_Profile__c WHERE ID IN :allIpRecords];
        insert ipRec;

        Test.startTest();
        controller.populateActionDetails(params);
        Test.stopTest();

        List<Implementation_Profile__c> successRecords = controller.getSuccessfulIpRecords();
        List<Implementation_Profile__c> failRecords = controller.getFailIpRecords();

        System.assertEquals(0, successRecords.size());
        System.assertEquals(0, failRecords.size());

    }



    /******************************************************************
    * Method Name : testGetInsperityLogoLink
    * Description : test method for getInsperityLogoLink method
    */
    static testMethod void testGetInsperityLogoLink() {
        NSP_IpCopyActionEmailBodyCont controller = new NSP_IpCopyActionEmailBodyCont();


        Test.startTest();
        String link = controller.getInsperityLogoLink();
        Test.stopTest();
        System.assertEquals(link!='',true);
    }
}
