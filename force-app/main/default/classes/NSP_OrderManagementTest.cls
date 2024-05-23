/*
*Test class for NSP_OrderManagement
*@Utpal Utkalit
*/
@isTest(SeeAllData=false)
public class NSP_OrderManagementTest {
    
    public static final String goLiveDate = 'Project go-live date';
    public static final String TEST_PRODUCT = 'Test Product';
    
    public class myException extends Exception {}
    
    /*
    *Test setup Data
    *@Utpal Utkalit
    */
@testSetup
    public static void makeData(){
         Account acnt=NSP_TestHelper.createAccount(true);
         Opportunity opp=NSP_TestHelper.createOpenOpportunity(acnt.Id,'New Product',true);
         SBQQ__Quote__c quote = NSP_TestHelper.createCPQQuote(acnt.Id,opp.Id,true);
        
        Contract ctrct = new Contract(AccountId=acnt.id, 
                                   SBQQ__Opportunity__c=opp.id, 
                                   SBQQ__Quote__c=quote.id, Status='Draft', 
                                   StartDate=Date.today(), 
                                   ContractTerm=12, 
                                   SBQQ__PreserveBundleStructureUponRenewals__c=true);
                                   
        insert ctrct;
        
        blng__BillingRule__c bRule=NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule=NSP_TestHelper.createRevrecRule(NSP_CPQConstants.PROJ_REV_REC);
        blng__TaxRule__c tRule=NSP_TestHelper.createRevTaxRule();
        
        Product2 objproduct = NSP_TestHelper.createBillingProduct(TEST_PRODUCT,rRule,tRule,bRule,'Monthly');
         
         List<SBQQ__Subscription__c> subList = new List<SBQQ__Subscription__c>();
        //creates subscription
        SBQQ__Subscription__c subscription = new SBQQ__Subscription__c();
        subscription.SBQQ__Account__c = acnt.Id;
        subscription.SBQQ__Quantity__c = 10;
        subscription.SBQQ__Contract__c = ctrct.id;
        subscription.SBQQ__Product__c = objproduct.Id;
        subList.add(subscription);
        //creates subscription
        SBQQ__Subscription__c subscription1 = new SBQQ__Subscription__c();
        subscription1.SBQQ__Account__c = acnt.Id;
        subscription1.SBQQ__Quantity__c = 13;
        subscription1.SBQQ__Contract__c = ctrct.id;
        subscription1.SBQQ__Product__c = objproduct.Id;
        subList.add(subscription1);
        
        system.debug(subscription);
        system.debug(subscription1);
        
        insert subList;
        
        ctrct.Status = 'Activated';
        update ctrct;
        
    }
    
    /*
    *Test Method : testGetContractRecord
    *@Utpal Utkalit
    */
     @isTest
    private static void testGetContractRecord(){
        Test.startTest();
        List<Account> accList = [SELECT Id FROM Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 10]; //Added WHERE Condition as part of code fix
        List<Contract> contractList=NSP_OrderManagement.getContractRecord(accList[0].Id);
        System.assert(contractList.size() > 0);
        Test.stopTest();
    }
    
    /*
    *Test Method : testGetCurrentUserInfo
    *@Utpal Utkalit
    */
    @isTest
    private static void testGetCurrentUserInfo(){
        Test.startTest();
        User user=NSP_OrderManagement.getCurrentUserInfo();
        System.assert(user != null);
        Test.stopTest();
    }
    
    /*
    *Test Method : testUpdateContract
    *@Utpal Utkalit
    */
     @isTest
    private static void testUpdateContract(){
        Test.startTest();
        List<Contract> contractList = [SELECT Id FROM Contract WHERE Status = 'Activated' LIMIT 10]; //Added WHERE Condition as part of code fix
        Boolean isContractUpdated= NSP_OrderManagement.updateContract(contractList[0].Id,'Amendment/Supplemental');
        System.assert(isContractUpdated);
        Test.stopTest();
    }

    /*
    *Test Method : testUpdateContractException
    *@Utpal Utkalit
    */
     @isTest
    private static void testUpdateContractException(){
        //For Code coverage
        Boolean isContractUpdated = true;
        Test.startTest();
        try{
             isContractUpdated= NSP_OrderManagement.updateContract(null,'Amendment/Supplemental');
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
        System.assert(isContractUpdated);
        Test.stopTest();
    }
 
}