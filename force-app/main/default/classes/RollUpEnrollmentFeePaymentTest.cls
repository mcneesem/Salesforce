@isTest
private class RollUpEnrollmentFeePaymentTest{
  @testSetup
  static void setupTestData(){
    test.startTest();
    //insert account record
    Account account_Obj = new Account(Name = 'Test Account');
    Insert account_Obj;
    //insert opportunity record
    Opportunity opportunity_Obj = new Opportunity(Name = 'Test Oppty',AccountId = account_Obj.id,stagename = NSP_SalesConstants.ANALYSIS_STAGE,CloseDate = date.today(),CurrencyIsoCode = 'USD',NSP_PrimaryProduct__c = 'WX',NSP_Number_of_Employees__c = 100,NSP_WS_Number_Of_Employees__c = 123,NSP_WO_Number_Of_Employees__c = 123,NSP_TransactionType__c = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION,Type ='CAMS');
    Insert opportunity_Obj;
    //insert enrollment fee payment  
      NSP_Enrollment_Fee_Payment__c nsp_enrollment_fee_payment_Obj = new NSP_Enrollment_Fee_Payment__c(NSP_Opportunity__c = opportunity_Obj.id, NSP_Payment_Amount__c = 100.00, NSP_Payment_Number__c = '1', NSP_Payment_Status__c = 'Paid');
      NSP_Enrollment_Fee_Payment__c nsp_enrollment_fee_payment_Obj1 = new NSP_Enrollment_Fee_Payment__c(NSP_Opportunity__c = opportunity_Obj.id, NSP_Payment_Amount__c = 100.00, NSP_Payment_Number__c = '3', NSP_Payment_Status__c = 'Paid');  
      Insert nsp_enrollment_fee_payment_Obj; 
    //update enrollment fee payment
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Number__c='2';
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Amount__c = 100.00;
      Update nsp_enrollment_fee_payment_Obj;
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Number__c='3';
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Amount__c = 100.00;
      Update nsp_enrollment_fee_payment_Obj;
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Number__c='4';
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Amount__c = 100.00;
      Update nsp_enrollment_fee_payment_Obj;
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Number__c='5';
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Amount__c = 100.00;
      Update nsp_enrollment_fee_payment_Obj;
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Number__c='6';
      nsp_enrollment_fee_payment_Obj.NSP_Payment_Amount__c = 100.00;
      Update nsp_enrollment_fee_payment_Obj;
      
    test.stopTest();
  }
  static testMethod void test_sumofEnrollmentFee_UseCase1(){
    List<Opportunity> opportunity_Obj  =  [SELECT Id,NSP_Enrollment_Fee_Payment_1__c,NSP_Enrollment_Fee_Payment_2__c,NSP_Enrollment_Fee_Payment_3__c,NSP_Enrollment_Fee_Payment_4__c,NSP_Enrollment_Fee_Payment_5__c,NSP_Enrollment_Fee_Payment_6__c from Opportunity Limit 1];
    System.assertEquals(true,opportunity_Obj.size()>0);
    List<NSP_Enrollment_Fee_Payment__c> nsp_enrollment_fee_payment_Obj  =  [SELECT NSP_Opportunity__c,NSP_Payment_Amount__c,NSP_Payment_Method__c,NSP_Payment_Number__c,NSP_Payment_Status__c from NSP_Enrollment_Fee_Payment__c Limit 1];
    System.assertEquals(true,nsp_enrollment_fee_payment_Obj.size()>0);
    Delete nsp_enrollment_fee_payment_Obj;
    RollUpEnrollmentFeePayment obj01 = new RollUpEnrollmentFeePayment();
    RollUpEnrollmentFeePayment.sumofEnrollmentFee(nsp_enrollment_fee_payment_Obj);
  }
}