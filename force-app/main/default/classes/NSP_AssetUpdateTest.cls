/* Description : Test class for NSP_AssetUpdate class
 Date        : 16/11/2022 */
 @isTest(SeeAllData = false)
 public class NSP_AssetUpdateTest{
     @testSetup
     public static void testData(){
         NSP_InvoiceTriggerHandler.TriggerDisabled = true;
         NSP_AssetTriggerHandler.TriggerDisabled = true;
         NSP_AccountTriggerHandler.TriggerDisabled = true;
         NSP_OrderItemTriggerHandler.TriggerDisabled = true;
         NSP_OrderTriggerHandler.TriggerDisabled = true;
         NSP_OpportunityTriggerHandler.TriggerDisabled = true;
         NSP_QuoteTriggerHandler.TriggerDisabled = true;
 
         Account objaccount = NSP_TestHelper.createAccount(true);
 
         Contact objcontact = NSP_TestHelper.createContact(objaccount.Id, true);
 
         Product2 objproduct = NSP_TestHelper.createProduct('Test Product', false);
         objproduct.SBQQ__ChargeType__c = 'Recurring';
         objproduct.SBQQ__BillingType__c = 'Arrears';
         objproduct.SBQQ__BillingFrequency__c = 'Monthly';
         objproduct.NSP_IsScholarshipPrice_Applicable__c = 'YES';
         objproduct.NSP_ServiceAssetCategory__c = 'Applicant Tracking';
         insert objproduct;
 
         blng__BillingRule__c brObj = new blng__BillingRule__c();
         brObj.blng__Active__c = true;
         brObj.Name = 'Test BR';
         brObj.blng__GenerateInvoices__c = 'Yes';
         brObj.blng__InitialBillingTrigger__c = 'Order Product Activation Date';
         brObj.blng__PartialPeriodTreatment__c = 'Combine';
         insert brObj;
 
         blng__RevenueRecognitionRule__c rrObj = new blng__RevenueRecognitionRule__c();
         rrObj.blng__Active__c = true;
         rrObj.blng__CreateRevenueSchedule__c = 'No';
         insert rrObj;
 
         blng__TaxRule__c taxRuleObj = new blng__TaxRule__c();
         taxRuleObj.blng__Active__c = true;
         taxRuleObj.blng__TaxableYesNo__c = 'No';
         insert taxRuleObj;
 
         objproduct.blng__BillingRule__c = brObj.Id;
         objproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
         objproduct.blng__TaxRule__c = taxRuleObj.Id;
         objproduct.NSP_Free_Periods_Applicable__c = true;
         update objproduct;
 
         Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', true);
 
         PriceBookEntry objPbe = NSP_TestHelper.createPriceBookEntry(objproduct.Id, 200.0, true);
 
         pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
         oProject.pse__Start_Date__c = System.Today();
         oProject.pse__Account__c = objaccount.Id;
         insert oProject;
 
         SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id, objOpprtunity.Id, false);
         objQuote.NSP_Project__c = oProject.Id;
         insert objQuote;
 
         List<SBQQ__QuoteLine__c> qlList = NSP_TestHelper.createCPQQuotelines(objQuote, new List<Product2>{ objproduct }, new List<PriceBookEntry>{ objPbe }, true);
         qlList[0].NSP_Free_Months__c = 1;
         qlList[0].NSP_ServiceAssetCategory__c = 'Applicant Tracking';
         update qlList;
 
         objQuote.SBQQ__Primary__c = true;
         objQuote.SBQQ__Ordered__c = true;
         objQuote.NSP_Free_Month__c = '1';
         update objQuote;
 
         Asset asst = new Asset();
         asst.Name = 'Test Asset';
         asst.ContactId = objcontact.Id;
         asst.AccountId = objaccount.Id;
         asst.Status = NSP_SalesConstants.ONBOARDING;
         asst.NSP_Process_Order_Change__c = false;
         asst.SBQQ__QuoteLine__c = qlList[0].Id;
         asst.NSP_Termination_Date__c = null;
         asst.Opportunity__c = objOpprtunity.Id;
         asst.RecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByName().get('WX_WA').getRecordTypeId();
         insert asst;
         List<Asset> asstList = [Select Id,RecordTypeId from Asset WHERE Id!=null];
         NSP_OrderTriggerHandler.TriggerDisabled = true;
         NSP_InvoiceTriggerHandler.TriggerDisabled = true;
         Test.startTest();
         NSP_UpdateAsset.updateAssets(asstList);
         List<Order> ords = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                             FROM Order WHERE Id!=null];
         ords[0].blng__BillingDayOfMonth__c = '1';
         ords[0].Status = 'Reviewed';
         update ords;
 
         ords[0].Status = 'Activated';
         update ords;
         test.stopTest();
     }
 
     @isTest
     static void assetBackoutUpdateTest(){
         Set<String> astIdSet = new Set<String>();

         List<pse__Proj__c> projectRec = [SELECT Id, pse__Account__c, pse__Start_Date__c
                                          FROM pse__Proj__c WHERE Id!=null];
         List<Order> orderList = [Select Id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                  From Order WHERE Id!=null];
         set<string> oppIds = new set<string>();
         Opportunity objOpprtunity = [SELECT Id
                                      FROM Opportunity WHERE Id!=null];
         oppIds.add(String.valueOf(objOpprtunity.Id));
 
         List<OrderItem> orderItemList = [SELECT Id, OrderItemNumber, NSP_Project__c, NSP_ServiceAssetCategory__c, SBQQ__Asset__r.RecordTypeId, SBQQ__Status__c, SBQQ__Asset__c, ServiceDate, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, OrderId, Order.Status, SBQQ__Activated__c
                                          FROM OrderItem WHERE Id!=null];
         List<Asset> asstList = [SELECT Id, Name, ContactId, SBQQ__OrderProduct__c, RecordTypeId, Status, NSP_ActivationDate__c, NSP_OrderProduct__c, SBQQ__QuoteLine__c, NSP_First_Pay_Date__c, AccountId, Opportunity__c
                                 FROM Asset WHERE Id!=null];
         asstList[0].NSP_OrderProduct__c = orderItemList[0].Id;
         update asstList;
 
         for (Asset asst : asstList){
             astIdSet.add(asst.Id);
         }
         Set<String> orderIdSetString = new Set<String>();
         orderIdSetString.add(String.valueOf(orderList[0].Id));
 
         Set<Id> orderIdSet = new Set<Id>();
         orderIdSet.add(orderList[0].Id);
 
         test.startTest();
         orderItemList[0].SBQQ__Status__c = NSP_SalesConstants.ACTIVATED_STATUS;
         orderItemList[0].NSP_ServiceAsset__c = asstList[0].Id;
         orderItemList[0].NSP_Project__c = projectRec[0].Id;
         update orderItemList;
         NSP_AssetUpdate.assetBackoutUpdate(orderIdSetString, NSP_SalesConstants.BACKOUT_STATUS);
         Map<Id, Date> opTermMap = new Map<Id, Date>();
         Date tday = System.today();
         opTermMap.put(orderItemList[0].Id, tday);
         NSP_AssetUpdate.assetTermination(opTermMap);
         NSP_AssetUpdate.createAssetProject(orderIdSet);
 
         Map<Id, Decimal> activeUserMap = new Map<Id, Decimal>();
         activeUserMap.put(asstList[0].Id, 1);
         NSP_AssetUpdate.setActiveUsers(activeUserMap);
         List<Asset> asstUpdatedList = [SELECT Id, Status
                                        FROM Asset WHERE Id!=null];
         System.assertEquals(NSP_SalesConstants.TERMINATED_STATUS, asstUpdatedList[0].Status, 'assetTermination method is updating the asset status');
         test.stopTest();
         
     }
 
     @isTest
     static void activateAssetMethod(){
         List<Account> objAccount = [SELECT Id, Name
                                     FROM Account WHERE Id!=null];
         List<Order> orderList = [Select Id, SBQQ__Quote__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
                                  From Order WHERE Id!=null];
         List<OrderItem> orderItemList = [SELECT Id, OrderItemNumber, NSP_ServiceAssetCategory__c, SBQQ__Asset__r.RecordTypeId, SBQQ__Status__c, SBQQ__Asset__c, ServiceDate, SBQQ__QuoteLine__c, SBQQ__QuoteLine__r.NSP_ActionType__c, SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c, OrderId, Order.Status, SBQQ__Activated__c
                                          FROM OrderItem WHERE Id!=null];
         List<Asset> asstList = [SELECT Id, Name, ContactId, SBQQ__OrderProduct__c, RecordTypeId, Status, NSP_ActivationDate__c, NSP_OrderProduct__c, SBQQ__QuoteLine__c, NSP_First_Pay_Date__c, AccountId, Opportunity__c
                                 FROM Asset WHERE Id!=null];
 
         Test.startTest();
         asstList[0].Status = NSP_SalesConstants.ONBOARDING;
         update asstList;
         Map<Id, OrderItem> opActiveMap = new Map<Id, OrderItem>();
         opActiveMap.put(asstList[0].RecordTypeId, orderItemList[0]);
         NSP_AssetUpdate.activateAsset(opActiveMap, String.valueOf(objAccount[0].Id));
 
         List<Asset> asstUpdatedList = [SELECT Id, Status
                                        FROM Asset WHERE Id!=null];
         Test.stopTest();
         System.assertEquals(NSP_SalesConstants.ACTIVE_STATUS, asstUpdatedList[0].Status, 'activateAsset  method is updating the asset status as active');
     }
     // @isTest
     // static void assetTestFail(){
     //     Set<String> orderIdSetString = new Set<String>();
     //     Map<Id, OrderItem> opActiveMapNull = new Map<Id, OrderItem>();
     //     Test.startTest();
     //     List<Order> orderList = [Select Id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c, NSP_First_usage_upload__c, Type, NSP_Project_Name__c, blng__InvoiceBatch__c, NSP_Billing_Address__c, NSP_Shipping_Address__c, NSP_Billing_Account__c
     //     From Order WHERE Id!=null];
     //     orderIdSetString.add(String.valueOf(orderList[0].Id));
     //     List<Asset> asstList = [SELECT Name, ContactId, SBQQ__OrderProduct__c, RecordTypeId, Status, NSP_ActivationDate__c FROM Asset WHERE Name!=null];
     //     List<Account> objAccount = [SELECT Id, Name
     //                                 FROM Account WHERE Id!=null];
     //     NSP_AssetUpdate.assetBackoutUpdate(orderIdSetString, NSP_SalesConstants.BACKOUT_STATUS);
     //     NSP_AssetUpdate.activateAsset(opActiveMapNull, String.valueOf(objAccount[0].Id));
     //     Test.stopTest();
     //     List<Asset> asstUpdatedList = [SELECT Id, Status
     //                                    FROM Asset WHERE Id!=null];
     //     System.assertNotEquals(NSP_SalesConstants.TERMINATED_STATUS, asstUpdatedList[0].Status, 'assetTermination method is updating the asset status');
     // }
 
 }