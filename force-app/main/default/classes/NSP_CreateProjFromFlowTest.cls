/**
 * @description       : NSP_CreateProjFromFlow
 * @author            : Manikantan
 * @group             :
 * @last modified on  : 01-11-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
@isTest
public class NSP_CreateProjFromFlowTest{
    @TestSetup
    static void testSetup(){
        NSP_OpportunityTriggerHandler.TriggerDisabled = true;
        NSP_QuoteTriggerHandler.TriggerDisabled = true;
        Account objaccount = NSP_TestHelper.createAccount(true);
        blng__BillingRule__c bRule = NSP_TestHelper.createBillingRule();
        blng__RevenueRecognitionRule__c rRule = NSP_TestHelper.createRevrecRule(NSP_CPQConstants.PROJ_REV_REC);
        blng__TaxRule__c tRule = NSP_TestHelper.createRevTaxRule();

        Product2 objproduct = NSP_TestHelper.createBillingProduct('Test Product', rRule, tRule, bRule, 'Monthly');
        objproduct.NSP_Project_Name_New_Sales__c = 'OPRT Implementation';
        Update objproduct;
        List<Product2>objproductlist = new List<Product2>{objproduct};
        
        //create pricebook Entry
        PricebookEntry pb = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        List<PricebookEntry> pblist = new List<PricebookEntry>{pb};
        
        //Create opp and quote
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', true);
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id, objOpprtunity.Id, true);
        NSP_TestHelper.createCPQQuotelines(objQuote,objproductlist,pblist, true);
        
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Type__c = 'New Product';
        objQuote.NSP_Budgetary_Quote__c = true;
        objQuote.ApprovalStatus__c = 'Approved';
        objQuote.SBQQ__Status__c = 'Approved';
        objQuote.SBQQ__Ordered__c = true;
        Update objQuote;
    }

    @IsTest
    static void testNSPCreateProjFromFlowwithoutProj(){
        
        List<String> recordsList = new List<String>();
        List<Order> orderList = [Select id, NSP_Project_Key__c, NSP_Project__c, NSP_Project_Name__c
                                 From Order WHERE NSP_Project__c = null
                                 WITH SECURITY_ENFORCED];
        for (Order recId : orderList){
            recordsList.add(recId.Id);
            recId.NSP_Project_Name__c = 'OPRT Implementation';
            recId.NSP_Project_Key__c = 'IOPRTSU';
            recId.NSP_Project__c = null;
            recId.NSP_ProjectOwner__c = UserInfo.getUserId();
            
        }
        Update orderList;
        Test.startTest();
        
        NSP_CreateProjFromFlow.createProject(recordsList);
        System.assert(recordsList != NULL);
        Test.stopTest();

    }

    @isTest
    static void testNSPCreateProjFromFlowwithProj(){
        Id recTypeId = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByName().get('TES+BPS').getRecordTypeId();
        NSP_ProjectTriggerHandler.TriggerDisabled = true;
        pse__Proj__c projRecord = new pse__Proj__c(Name = 'OPRT Implementation', pse__Project_ID_Chain__c = 'a2o3C000000aL9pQAE', pse__Project_Name_Chain__c = 'OPRT Implementation', pse__Revenue_Forecast_Processing_Status__c = 'Not Started', pse__Stage__c = 'Pursuit / Estimation', pse__Start_Date__c = System.today(), RecordTypeId = recTypeId);
        insert projRecord;
        NSP_ProjectTriggerHandler.TriggerDisabled = false;
        List<String> recordsList = new List<String>();

        List<Order> orderList = [Select id, NSP_Project_Key__c, NSP_Project__c, NSP_Project_Name__c
                                 From Order WHERE NSP_Project__c = null
                                 WITH SECURITY_ENFORCED];
        for (Order recId : orderList){
            recordsList.add(recId.Id);
            recId.NSP_Project_Name__c = 'OPRT Implementation';
            recId.NSP_Project_Key__c = 'IOPRTSU';
            recId.NSP_Project__c = projRecord.Id;

            
        }
        update orderList;
        Test.startTest();
        NSP_CreateProjFromFlow.createProject(recordsList);
        NSP_CreateProjFromFlow.checkCreateProject(recordsList);
        NSP_CreateProjFromFlow.validateUserRole();
        Test.stopTest();

        // Asserts
        List<pse__Proj__c> projList = [Select Id
                                       From pse__Proj__c
                                       WHERE Id = :orderList[0].NSP_Project__c];
        List<OrderItem> orderItemList = [Select Id, NSP_Project__c
                                         From OrderItem
                                         WHERE OrderId = :orderList[0].Id
                                         Limit 1];
        System.assertEquals(projList[0].Id, orderItemList[0].NSP_Project__c, '');
    }

}