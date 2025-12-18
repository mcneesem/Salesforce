/* **************************************************************************************************   
Component Name :  NSP_dunningEmailNotificationsBatchTest class
Version              :  1.0                                                                          
Created Date         :  05/07/2021                                                            
Function             :  This is the test class for NSP_dunningEmailNotificationsBatch class which is used to send dunning emails.                                                                           
Modification Log     :                                                                               
*	Rakesh           September 2022          First Iteration
*
***************************************************************************************************
*/
@IsTest
private class NSP_dunningEmailNotificationsBatchTest {

    
    // test setup method
    @testSetup
    private static void setupTestData(){
        Email_Deliverability_Settings__c emailSetting = Email_Deliverability_Settings__c.getOrgDefaults();
        emailSetting.IsEnabledOutbound__c = true;
        upsert emailSetting;
        
        Order_Settings__c sett = new Order_Settings__c();
        sett.EffectiveDateStartOfMonth__c = true;
        insert sett;
        
        NSP_TestHelper.switchOffTriggers();
        Account objaccount = NSP_TestHelper.createAccount(true);
        //Contact objcontact = NSP_TestHelper.createContact(objaccount.id, true);
        Product2 objproduct = NSP_TestHelper.createProduct('Test Product',false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c ='YES';
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
        update objproduct;
        
        // Query account and product
        //Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        //Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];
     
        // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id,'New Product',true);
        PriceBookEntry objPbe     = NSP_TestHelper.createPriceBookEntry(objproduct.Id,200.0,true);
        //create quote
        SBQQ__Quote__c objQuote   = NSP_TestHelper.createCPQQuote(objaccount.Id,objOpprtunity.Id,true);
        // create quote lines
        NSP_TestHelper.createCPQQuotelines(objQuote,new List<Product2>{objproduct},new List<PriceBookEntry> {objPbe}, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;
		Test.startTest();
		List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE SBQQ__Quote__c=:objQuote.Id ];
        ords[0].blng__BillingDayOfMonth__c = '10';
        ords[0].Status = 'Reviewed';
        //ords[0].blng__BillNow__c = TRUE;
		update ords;
        
        ords[0].Status = 'Activated';
        update ords;
        Test.stopTest();
       
    }

        /**
     * Description : Test method to test emails for the dunning cases
     * Name : dunningCaseEmailsTest
     */
    private static testMethod void dunningCaseEmailsTest60Days(){
        
		Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated' LIMIT 1];
        ords[0].blng__BillNow__c = TRUE;
		update ords;
        
        
		List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c,blng__Balance__c FROM blng__Invoice__c WHERE Id!=null LIMIT 10];
        invc[0].blng__DueDate__c = Date.today() - 70;
        update invc;
        
        invc[0].blng__InvoiceStatus__c = NSP_CPQConstants.INVOICESTATUS;
        update invc;
        
        //NSP_DunningCaseCreationBatch cbatch = new NSP_DunningCaseCreationBatch();
		//ID batchprocessid = Database.executeBatch(cbatch);
		 Id DUNNING_CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(NSP_CPQConstants.DUNNING).getRecordTypeId();
     	NSP_CaseTriggerHandler.TriggerDisabled = TRUE;
        Case dunCase = new Case();
                dunCase.AccountId = objaccount.Id;
                //dunCase.ContactId = inv.blng__BillToContact__c;
                dunCase.Type = NSP_BillingConstants.DUNNING_ACCOUNT;
                dunCase.NSP_Dunning_Type__c = NSP_BillingConstants.OPEN_INVOICE;
                //dunCase.NSP_Dunning_Case_Invoice__c = inv.Id;
                dunCase.recordTypeId = DUNNING_CASE_RT_ID;
                dunCase.NSP_Dunning_Automation__c = NSP_BillingConstants.AUTOMATED;
                dunCase.Origin = NSP_BillingConstants.DUNNING;
                duncase.Subject = NSP_BillingConstants.DUNNING_CASE_SUBJECT;
        		duncase.NSP_Dunning_Emails_Sent__c= '45 Days;';
                //dunCase.OwnerId = queueId;
        insert dunCase;
        
        NSP_DunningEmailNotificationsBatch ebatch = new NSP_DunningEmailNotificationsBatch();
        ID ebatchprocessid = Database.executeBatch(ebatch);
        Test.stopTest();

        System.assertNotEquals(null, ebatchprocessid);
    }

        /**
     * Description : Test method to test emails for the dunning cases
     * Name : dunningCaseEmailsTest
     */
    private static testMethod void dunningCaseEmailsTest90Days(){
        
		Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated' LIMIT 1];
        ords[0].blng__BillNow__c = TRUE;
		update ords;
        
        
		List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c,blng__Balance__c FROM blng__Invoice__c WHERE Id!=null LIMIT 10];
        invc[0].blng__DueDate__c = Date.today() - 100;
        update invc;
        
        invc[0].blng__InvoiceStatus__c = NSP_CPQConstants.INVOICESTATUS;
        update invc;
        
        //NSP_DunningCaseCreationBatch cbatch = new NSP_DunningCaseCreationBatch();
		//ID batchprocessid = Database.executeBatch(cbatch);
		 Id DUNNING_CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(NSP_CPQConstants.DUNNING).getRecordTypeId();
     	NSP_CaseTriggerHandler.TriggerDisabled = TRUE;
        Case dunCase = new Case();
                dunCase.AccountId = objaccount.Id;
                //dunCase.ContactId = inv.blng__BillToContact__c;
                dunCase.Type = NSP_BillingConstants.DUNNING_ACCOUNT;
                dunCase.NSP_Dunning_Type__c = NSP_BillingConstants.OPEN_INVOICE;
                //dunCase.NSP_Dunning_Case_Invoice__c = inv.Id;
                dunCase.recordTypeId = DUNNING_CASE_RT_ID;
                dunCase.NSP_Dunning_Automation__c = NSP_BillingConstants.AUTOMATED;
                dunCase.Origin = NSP_BillingConstants.DUNNING;
                duncase.Subject = NSP_BillingConstants.DUNNING_CASE_SUBJECT;
        		duncase.NSP_Dunning_Emails_Sent__c= '45 Days;60 Days;';
                //dunCase.OwnerId = queueId;
        insert dunCase;
        
        NSP_DunningEmailNotificationsBatch ebatch = new NSP_DunningEmailNotificationsBatch();
        ID ebatchprocessid = Database.executeBatch(ebatch);
        Test.stopTest();

        System.assertNotEquals(null, ebatchprocessid);
    }

           /**
     * Description : Test method to test emails for the dunning cases
     * Name : dunningCaseEmailsTest
     */
    private static testMethod void dunningCaseEmailsTest120Days(){
        
		Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated' LIMIT 1];
        ords[0].blng__BillNow__c = TRUE;
		update ords;
		
        Contact con = new Contact();
        con.AccountId = objaccount.Id;
        con.Email = 'test@gmail.com';
        con.LastName ='Test Con';
        insert con;
        AccountContactRelation acr = [Select Id, NSP_Dunning_Emails__c, Contact.Email, Contact.Name, ContactId, AccountId from AccountContactRelation WHERE AccountId =: objaccount.Id LIMIT 1];
        acr.NSP_Dunning_Emails__c = TRUE;
        NSP_AccountContactRelationTriggerHandler.TriggerDisabled = TRUE;
        update acr;
                                      
		List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c,blng__Balance__c FROM blng__Invoice__c WHERE Name != null];
        invc[0].blng__DueDate__c = Date.today() - 130;
        update invc;
        
        invc[0].blng__InvoiceStatus__c = NSP_CPQConstants.INVOICESTATUS;
        update invc;
        
        //NSP_DunningCaseCreationBatch cbatch = new NSP_DunningCaseCreationBatch();
		//ID batchprocessid = Database.executeBatch(cbatch);
		 Id DUNNING_CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(NSP_CPQConstants.DUNNING).getRecordTypeId();
     NSP_CaseTriggerHandler.TriggerDisabled = TRUE;
        Case dunCase = new Case();
                dunCase.AccountId = objaccount.Id;
                //dunCase.ContactId = inv.blng__BillToContact__c;
                dunCase.Type = NSP_BillingConstants.DUNNING_ACCOUNT;
                dunCase.NSP_Dunning_Type__c = NSP_BillingConstants.OPEN_INVOICE;
                //dunCase.NSP_Dunning_Case_Invoice__c = inv.Id;
                dunCase.recordTypeId = DUNNING_CASE_RT_ID;
                dunCase.NSP_Dunning_Automation__c = NSP_BillingConstants.AUTOMATED;
                dunCase.Origin = NSP_BillingConstants.DUNNING;
                duncase.Subject = NSP_BillingConstants.DUNNING_CASE_SUBJECT;
        		duncase.NSP_Dunning_Emails_Sent__c= '45 Days;60 Days;90 Days';
                //dunCase.OwnerId = queueId;
        insert dunCase;
        
        NSP_DunningEmailNotificationsBatch ebatch = new NSP_DunningEmailNotificationsBatch();
        ID ebatchprocessid = Database.executeBatch(ebatch);
        Test.stopTest();

        System.assertNotEquals(null, ebatchprocessid);
    }

    private static testMethod void testdunningBatchScheduler() {  
        Test.startTest();  
        NSP_DunningEmailNotification_Scheduler dunEmailsBatch = new NSP_DunningEmailNotification_Scheduler();
        String sch = '0 0 2 * * ?';
        String jobId = System.schedule('Test Dunning Email Batch', sch, dunEmailsBatch);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(sch, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();     
   }  

              /**
     * Description : Test method to test emails for the dunning cases
     * Name : dunningCaseEmailsTest
     */
    private static testMethod void dunningCaseEmailsTest135Days(){
        
		Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        List<Order> ords =[SELECT Id, OrderNumber, blng__BillingDayOfMonth__c FROM Order WHERE Status = 'Activated' LIMIT 1];
        ords[0].blng__BillNow__c = TRUE;
		update ords;
        
        
		List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c,blng__Balance__c FROM blng__Invoice__c WHERE Id!=null LIMIT 10];
        invc[0].blng__DueDate__c = Date.today() - 130;
        update invc;
        
        invc[0].blng__InvoiceStatus__c = NSP_CPQConstants.INVOICESTATUS;
        update invc;
        
        //NSP_DunningCaseCreationBatch cbatch = new NSP_DunningCaseCreationBatch();
		//ID batchprocessid = Database.executeBatch(cbatch);
		 Id DUNNING_CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(NSP_CPQConstants.DUNNING).getRecordTypeId();
     	NSP_CaseTriggerHandler.TriggerDisabled = TRUE;
        Case dunCase = new Case();
                dunCase.AccountId = objaccount.Id;
                //dunCase.ContactId = inv.blng__BillToContact__c;
                dunCase.Type = NSP_BillingConstants.DUNNING_ACCOUNT;
                dunCase.NSP_Dunning_Type__c = NSP_BillingConstants.OPEN_INVOICE;
                //dunCase.NSP_Dunning_Case_Invoice__c = inv.Id;
                dunCase.recordTypeId = DUNNING_CASE_RT_ID;
                dunCase.NSP_Dunning_Automation__c = NSP_BillingConstants.AUTOMATED;
                dunCase.Origin = NSP_BillingConstants.DUNNING;
                duncase.Subject = NSP_BillingConstants.DUNNING_CASE_SUBJECT;
        		duncase.NSP_Dunning_Emails_Sent__c= '45 Days;60 Days;90 Days;120 Days';
                //dunCase.OwnerId = queueId;
        insert dunCase;
        
        NSP_DunningEmailNotificationsBatch ebatch = new NSP_DunningEmailNotificationsBatch();
        ID ebatchprocessid = Database.executeBatch(ebatch);
        Test.stopTest();

        System.assertNotEquals(null, ebatchprocessid);
    }

                /**
     * Description : Test method to test emails for the dunning cases
     * Name : dunningCaseEmailsTest
     */
    private static testMethod void testaccount30DayEmail(){
        Test.startTest();
        Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        Contact con = new Contact();
        con.AccountId = objaccount.Id;
        con.Email = 'test@gmail.com';
        con.LastName ='Test Con';
        insert con;
        AccountContactRelation acr = [Select Id, NSP_Dunning_Emails__c, Contact.Email, Contact.Name, ContactId, AccountId from AccountContactRelation WHERE AccountId =: objaccount.Id LIMIT 1];
        acr.NSP_Dunning_Emails__c = TRUE;
        NSP_AccountContactRelationTriggerHandler.TriggerDisabled = TRUE;
        update acr;
        
        NSP_DunningEmailsMessageService.dunningEmailParams accDParams = new NSP_DunningEmailsMessageService.dunningEmailParams('X30_Days_Past_Due_Reminder','Account',objaccount.Id);
        NSP_DunningEmailsMessageService.sendDunningEmail(new List<NSP_DunningEmailsMessageService.dunningEmailParams> {accDParams});
        System.assert(acr.NSP_Dunning_Emails__c == TRUE);
        Test.stopTest();

    }
}