@isTest
public class NSP_sObjectSearchControllerTest {

    /***********************************************************************************************
    * MethodName:  Setting up test data
    * Description : Setting Up data
    * ********************************************************************************************/
    @testSetup
    static void setupData(){
        List<Account> accounts = new List<Account>();
        for (Integer intgr = 0; intgr < 5; intgr++) {
            Account acc = (Account) NSP_TestDataFactory.createSObject(new Account());
            acc.Name = 'Test ' + intgr;
            accounts.add(acc);
        }

        insert accounts;
    }

    /***********************************************************************************************
    * MethodName:  searchRecordsByFiltersTest
    * Description : searchRecordsBy Filters Test
    * ********************************************************************************************/
    @isTest
    static void searchRecordsByFiltersTest() {
        // GIVEN
        String searchConfig = '{"searchTerm": "Test 1","preSelectedRecs": "[]" , "objectApiName": "Account", "searchCategory": "Name", "resultSize":10 }';

        // WHEN
        List<NSP_LookupOption> results = NSP_sObjectSearchController.searchRecordsByFilters(searchConfig);

        // THEN
        System.assertEquals(1, results.size());
        System.assertEquals('Test 1', results[0].label);
    }

}