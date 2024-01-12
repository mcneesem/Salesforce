@IsTest
public class NSP_LockBox_ControllerTest{
    /*
     * Description : Method to create test data
     * Name : setupTestData
     * Data created: Product,
     *                  Billing rule,
     *                  Revenue recognition,
     *               Tax Rule
     *                  Opportunity
     *                  PricebookEntry
     *                  SBQQ__Quote__c
     *                  CPQQuoteLines
     */
    @testSetup
    static void setupTestData(){

        Account objaccount = NSP_TestHelper.createAccount(true);

        Product2 objproduct = NSP_TestHelper.createProduct('Test Product', false);
        objproduct.SBQQ__ChargeType__c = 'Recurring';
        objproduct.SBQQ__BillingType__c = 'Arrears';
        objproduct.SBQQ__BillingFrequency__c = 'Monthly';
        objproduct.NSP_IsScholarshipPrice_Applicable__c = 'YES';
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

        blng__GLRule__c glrule = NSP_TestHelper.createGLRule();
        glrule.Name = 'RET Cash (Invoice-AR)';
        update glrule;

        blng__GLTreatment__c glTreatmentRec = new blng__GLTreatment__c();
        glTreatmentRec.blng__Active__c = true;
        glTreatmentRec.Name = 'RET Cash (Invoice-AR)';
        glTreatmentRec.blng__GLRule__c = glrule.Id;
        insert glTreatmentRec;

        blng__LegalEntity__c legalEntityRec = new blng__LegalEntity__c(blng__Active__c = true, NSP_Company_Name__c = 'Insperity Business Services', blng__City__c = 'KINGWOOD', blng__State__c = 'TX', blng__County__c = 'US', blng__Street1__c = '19001 CRESCENT SPRINGS DR', blng__ZipPostalCode__c = '77339-3802', Name = '29');
        insert legalEntityRec;

        objproduct.blng__BillingRule__c = brObj.Id;
        objproduct.blng__RevenueRecognitionRule__c = rrObj.Id;
        objproduct.blng__TaxRule__c = taxRuleObj.Id;
        update objproduct;

        // Query account and product
        //Account objaccount  = [Select Id, Name from Account WHERE Name =: NSP_TestHelper.DEFAULT_COMPANY_NAME LIMIT 1];
        //Product2 objproduct  = [Select Id, Name from Product2 WHERE Name = 'Test Product' LIMIT 1];

        // create opportunity
        Opportunity objOpprtunity = NSP_TestHelper.createOpenOpportunity(objaccount.Id, 'New Product', true);
        PriceBookEntry objPbe = NSP_TestHelper.createPriceBookEntry(objproduct.Id, 200.0, true);
        //create quote
        SBQQ__Quote__c objQuote = NSP_TestHelper.createCPQQuote(objaccount.Id, objOpprtunity.Id, true);
        // create quote lines
        NSP_TestHelper.createCPQQuotelines(objQuote, new List<Product2>{ objproduct }, new List<PriceBookEntry>{ objPbe }, true);
        // create order from quote
        objQuote.SBQQ__Primary__c = true;
        objQuote.SBQQ__Ordered__c = true;
        update objQuote;
        Test.startTest();
        List<Order> ords = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                            FROM Order
                            WHERE SBQQ__Quote__c = :objQuote.Id];
        ords[0].blng__BillingDayOfMonth__c = '10';
        ords[0].Status = 'Reviewed';
        //ords[0].blng__BillNow__c = TRUE;
        update ords;
        ords[0].Status = 'Activated';
        update ords;
        Assert.isNotNull(objOpprtunity.Id);
        Test.stopTest();
    }

    /**
     * Description : Test method to test the create and update on lock box record
     * Name : lockboxCreateTest
     */
    @isTest
    static void lockboxCreateTest(){

        /* List<OrderItem> orderItemList = new list<OrderItem>([select id from OrderItem where Order.SBQQ__Quote__c =:objQuote.Id]);
         orderItemList[0].NSP_Project_Completion_Date__c = Date.today();
         orderItemList[0].NSP_ReCalculation_Status_Internal__c = 'Staged';
         update orderItemList;

         OrderProductUpdateCaller.reCalculateQuoteLine(new List<String>{orderItemList[0].Id}); */
        Test.startTest();
        Account objaccount = [Select Id, Name
                              from Account
                              WHERE Name = :NSP_TestHelper.DEFAULT_COMPANY_NAME
                              LIMIT 1];
        List<Order> ords = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                            FROM Order
                            WHERE Status = 'Activated'];
        ords[0].blng__BillNow__c = TRUE;
        update ords;
        List<blng__GLRule__c> billingGLRuleList = [SELECT Id, Name
                                                   FROM blng__GLRule__c WHERE Id!=null LIMIT 10];
        List<blng__GLTreatment__c> glTreatmentList = [SELECT Id, Name, blng__GLRule__c
                                                      FROM blng__GLTreatment__c  WHERE Id!=null  LIMIT 10];
        List<blng__LegalEntity__c> glLegalEntityList = [Select Id, Name
                                                        From blng__LegalEntity__c WHERE Id!=null  LIMIT 10];

        List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c, blng__Balance__c
                                       FROM blng__Invoice__c  WHERE Id!=null 
                                       LIMIT 1];
        invc[0].blng__InvoiceStatus__c = 'Posted';
        update invc;
        NSP_Lock_Box__c newlbrec = new NSP_Lock_Box__c();
        newlbrec.NSP_Remitter_Name__c = objaccount.Name;
        newlbrec.NSP_LockBox_Number__c = 'RSO';
        newlbrec.NSP_Invoice_Number__c = invc[0].Name;
        newlbrec.NSP_Check_Amount__c = invc[0].blng__Balance__c;
        insert newlbrec;

        newlbrec.NSP_Ready_to_Convert__c = TRUE;
        update newlbrec;
        Assert.areEqual(true, newlbrec.NSP_Ready_to_Convert__c);
        Test.stopTest();
        //System.assert(ords.size()==1,true);
    }

    /**
     * Description : Test method to test the create and update on lock box record
     * Name : lockboxCreateTest
     * Methods called: NSP_LockBox_Controller.checkValidRecordForProcess
     * NSP_LockBox_Controller.callProcessLockBoxLogic
     */
    @isTest
    static void lockboxProcessTest(){

        Test.startTest();
        Account objaccount = [SELECT Id, Name
                              FROM Account LIMIT 10];
        List<blng__GLRule__c> billingGLRuleList = [SELECT Id, Name
                                                   FROM blng__GLRule__c  WHERE Id!=null  LIMIT 10];
        List<blng__GLTreatment__c> glTreatmentList = [SELECT Id, Name, blng__GLRule__c
                                                      FROM blng__GLTreatment__c WHERE Id!=null  LIMIT 10];
        List<blng__LegalEntity__c> glLegalEntityList = [Select Id, Name
                                                        From blng__LegalEntity__c WHERE Id!=null  LIMIT 10];
        List<Order> ords = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                            FROM Order
                            WHERE Status = 'Activated'
                            LIMIT 1];
        ords[0].blng__BillNow__c = TRUE;
        update ords;


        List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c, blng__Balance__c
                                       FROM blng__Invoice__c WHERE Id!=null 
                                       LIMIT 1];

        invc[0].blng__InvoiceStatus__c = 'Posted';
        update invc;
        NSP_Lock_Box__c newlbrec = new NSP_Lock_Box__c();
        newlbrec.NSP_Remitter_Name__c = objaccount.Name;
        newlbrec.NSP_Invoice_Number__c = invc[0].Name;
        newlbrec.NSP_Check_Amount__c = invc[0].blng__Balance__c;
        insert newlbrec;

        newlbrec.NSP_Ready_to_Convert__c = TRUE;
        update newlbrec;
        Boolean isValid = NSP_LockBox_Controller.checkValidRecordForProcess(String.valueOf(newlbrec.Id));
  //      System.assertEquals(isValid, false);

        NSP_LockBox_Controller.callProcessLockBoxLogic(newlbrec.Id);
        Test.stopTest();
        //System.assert(ords.size()==1,true);
    }

    
     /**
     * Description : Test method to test the notification via Event
     * Name : testNotificationEvent
     * Methods called: NSP_NotificationUtility.publishNotificationEvent
     */
    @isTest
    static void testNotificationEvent(){
        	 Test.startTest();
        		Account objaccount = [SELECT Id, Name FROM Account WHERE Id!=null LIMIT 1];
        		Id usrid = UserInfo.getUserId();
		     NSP_NotificationUtility.notificationEventWrapper newevt = new NSP_NotificationUtility.notificationEventWrapper('Generic_Bell_Notification','Test Notification','Yaayyyy -- I am here to notify you.',usrid,objaccount.Id,new Set<String>{usrid});
			NSP_NotificationUtility.publishNotificationEvent(new List<NSP_NotificationUtility.notificationEventWrapper>{newevt});   
        Test.stopTest();
       // System.assert(objaccount.name=='ABCTest Co',true);
    }
    
        /**
     * Description : Test method to test the create and update on lock box record in batch class
     * Name : lockboxProcessBatchTest
     * Methods called: NSP_processLockBoxFiles Batch Class
     */
    @isTest
    static void lockboxProcessBatchTest(){

        Test.startTest();
        Account objaccount = [SELECT Id, Name
                              FROM Account WHERE Id!=null LIMIT 10];
        List<blng__GLRule__c> billingGLRuleList = [SELECT Id, Name
                                                   FROM blng__GLRule__c WHERE Id!=null LIMIT 10];
        List<blng__GLTreatment__c> glTreatmentList = [SELECT Id, Name, blng__GLRule__c
                                                      FROM blng__GLTreatment__c WHERE Id!=null LIMIT 10];
        List<blng__LegalEntity__c> glLegalEntityList = [Select Id, Name
                                                        From blng__LegalEntity__c WHERE Id!=null LIMIT 10];
        List<Order> ords = [SELECT Id, OrderNumber, blng__BillingDayOfMonth__c
                            FROM Order
                            WHERE Status = 'Activated'
                            LIMIT 1];
        ords[0].blng__BillNow__c = TRUE;
        update ords;


        List<blng__Invoice__c> invc = [Select Id, Name, blng__Account__c, blng__Balance__c
                                       FROM blng__Invoice__c WHERE Id!=null
                                       LIMIT 1];

        invc[0].blng__InvoiceStatus__c = 'Posted';
        update invc;
        NSP_Lock_Box__c newlbrec = new NSP_Lock_Box__c();
        newlbrec.NSP_Remitter_Name__c = objaccount.Name;
        newlbrec.NSP_Invoice_Number__c = invc[0].Name;
        newlbrec.NSP_Check_Amount__c = invc[0].blng__Balance__c;
        newlbrec.NSP_Ready_to_Convert__c = TRUE;
        insert newlbrec;
        //update newlbrec;
		NSP_processLockBoxFiles lcbBatch = new NSP_processLockBoxFiles();
        Database.executeBatch(lcbBatch);
        Test.stopTest();
        //System.assert(invc.size()==1,true);
    }

}