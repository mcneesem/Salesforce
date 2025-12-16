@isTest
private class OnCLMDocumentCreateTest {

    private static SpringCMIAuthenticator authenticator;
    private static SpringCMService svc;

    @isTest
    private static void testCLMDocumentInsert() {
        //Insert Test Account record
        Account account = New Account(Name = 'TestAccount', AccountNumber = '12345',NSP_AIMS_Client__c = 'ateammember1');
        insert account;

        //Create Opportunity
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = account.id;
        opportuniytObject.stagename = 'Qualification';
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.CurrencyIsoCode ='USD';
        opportuniytObject.NSP_PrimaryProduct__c = 'WO';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        //Inserting Opportunity Object
        insert opportuniytObject;

        // CLM_Document__c Document Record
        CLM_Document__c clm1 = New CLM_Document__c(Name = 'TestCLM1', CLM_Document_Id__c = 'f165bf8f-28bb-ea11-9c2e-d89d6716196d', Account__c = account.Id);
        CLM_Document__c clm2 = New CLM_Document__c(Name = 'TestCLM2', CLM_Document_Id__c = 'f165bf8f-28bb-ea11-9c2e-d89d6716196d', Opportunity__c = opportuniytObject.Id);

        // Start Test
        Test.startTest();
        insert clm1;
        insert clm2; 
        System.assertEquals('TestCLM1', clm1.Name);
        System.assertEquals('TestCLM2', clm2.Name);
        update clm1;
        delete clm1;
        Test.stopTest();
    }

}
//