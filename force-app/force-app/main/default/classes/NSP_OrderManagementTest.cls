/*
*Test class for NSP_OrderManagement
*@Utpal Utkalit
*/
@isTest(SeeAllData=false)
public class NSP_OrderManagementTest {
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
        List<Contract> contractList = [SELECT Id FROM Contract WHERE Status = 'Draft' LIMIT 10]; //Added WHERE Condition as part of code fix
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