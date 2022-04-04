@isTest
public class RollUpEnrollmentFeePaymentTest {
    static testmethod void TestFeePaymentRollUp(){
        
        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        //inserting account object
        insert accoutObject;
        //Create Opportunity
        Opportunity opportuniytObject = new Opportunity();
        opportuniytObject.Name = 'Test Oppty';
        opportuniytObject.AccountId = accoutObject.id;
        opportuniytObject.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject.CloseDate = date.today();
        opportuniytObject.CurrencyIsoCode = 'USD';
        opportuniytObject.NSP_PrimaryProduct__c = 'WX';
        opportuniytObject.NSP_Number_of_Employees__c = 100;
        opportuniytObject.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_WO_Number_Of_Employees__c = 123;
        opportuniytObject.NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
        opportuniytObject.Type ='CAMS';
        //Inserting Opportunity Object
        insert opportuniytObject;
        Opportunity opportuniytObject2 = new Opportunity();
        opportuniytObject2.Name = 'Test Oppty Email';
        opportuniytObject2.AccountId = accoutObject.id;
        opportuniytObject2.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject2.CloseDate = date.today();
        opportuniytObject2.CurrencyIsoCode = 'USD';
        opportuniytObject2.NSP_PrimaryProduct__c = 'WO';
        opportuniytObject2.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
        opportuniytObject2.Type ='CAMS';
        opportuniytObject2.NSP_WS_Number_Of_Employees__c = 123;
        opportuniytObject2.NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
        //Inserting Opportunity Object
        insert opportuniytObject2;
        List<NSP_Enrollment_Fee_Payment__c> newFeePayment = new List<NSP_Enrollment_Fee_Payment__c>();
        NSP_Enrollment_Fee_Payment__c newOrd = new NSP_Enrollment_Fee_Payment__c(NSP_Opportunity__c = opportuniytObject.Id, NSP_Payment_Number__c ='1', NSP_Payment_Amount__c = 123.00);
        NSP_Enrollment_Fee_Payment__c newOrd1 = new NSP_Enrollment_Fee_Payment__c(NSP_Opportunity__c = opportuniytObject2.Id, NSP_Payment_Number__c ='2', NSP_Payment_Amount__c = 123.00);
        newFeePayment.add(newOrd);
        insert newFeePayment;

        delete newFeePayment;
    }      
    
}