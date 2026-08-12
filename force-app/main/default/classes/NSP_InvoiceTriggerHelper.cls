public class NSP_InvoiceTriggerHelper {
    // test w/ NSP_InvoiceTriggerHelperTest (75%)
    // test w/ NSP_InvoiceLineTriggerTest (46%)

    static final string DunningCase_RT = 'Dunning';
    static final Id DUNNING_CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DunningCase_RT).getRecordTypeId();

    // Iterates throught the lead map and identifies the records that needs to worked based on various criterias.
    public void beforeUpdateDirector( Map<Id,blng__Invoice__c> invoiceNewMap , Map<Id,blng__Invoice__c> invoiceOldMap ) {

        Set<String> invIdsForDocGenFieldsUpdate = new Set<String>();
        Map<String,blng__InvoiceLine__c> invIdToFirstLineMap = new Map<String,blng__InvoiceLine__c>();
        Set<String> budgetaryQuoteIds = new Set<String>();
        Map<String, Set<String>> quoteIdtoInvoiceIdMap = new  Map<String, Set<String>>();
        Map<String, String> invIdToQuoteIdMap = new Map<String, String>();
        Map<String, Boolean> quoteIdToEnrollmentFeeMap = new Map<String, Boolean>();
        Set<String> budgetraryProductCodes = new Set<String>(System.Label.NSP_ApplicableProductCodesForBudgetaryQuotes.split(','));

        for (blng__Invoice__c inv : invoiceNewMap.values() ){

            if(inv.blng__InvoiceStatus__c == 'Posted' && inv.blng__InvoiceStatus__c != invoiceOldMap.get(inv.Id).blng__InvoiceStatus__c)     {
                invIdsForDocGenFieldsUpdate.add(inv.id);
            }
        }
        for ( blng__InvoiceLine__c invLine : [SELECT Id, blng__Invoice__c, blng__LegalEntity__c, blng__LegalEntity__r.NSP_Company_Name__c,blng__OrderProduct__c, blng__OrderProduct__r.Order.AccountId, blng__OrderProduct__r.Order.PoNumber,
                                                blng__OrderProduct__r.SBQQ__Subscription__r.SBQQ__Contract__r.StartDate, blng__OrderProduct__r.SBQQ__Subscription__r.SBQQ__Contract__r.EndDate,
                                                blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,  blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.NSP_Budgetary_Quote__c, blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__c,
                                                blng__OrderProduct__r.Order.blng__BillingAccount__r.Name,blng__OrderProduct__r.Order.BillingCity,blng__OrderProduct__r.Order.BillingCountry,blng__OrderProduct__r.Order.BillingPostalCode,blng__OrderProduct__r.Order.BillingState,blng__OrderProduct__r.Order.BillingStreet,blng__OrderProduct__r.Order.BillToContactId,
                                                blng__OrderProduct__r.Order.NSP_Ship_To_Name__c,blng__OrderProduct__r.Order.NSP_Ship_To_Postal_Code__c,blng__OrderProduct__r.Order.NSP_Ship_To_State__c,blng__OrderProduct__r.Order.NSP_Ship_To_Street__c,blng__OrderProduct__r.Order.NSP_Ship_To_City__c,blng__OrderProduct__r.Order.NSP_Ship_To_Country__c
                                                FROM blng__InvoiceLine__c WHERE blng__Invoice__c IN : invIdsForDocGenFieldsUpdate ]) {

            if(!invIdToFirstLineMap.containsKey(invLine.blng__Invoice__c)) {
                invIdToFirstLineMap.put(invLine.blng__Invoice__c,invLine);
            }
            if(invLine.blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.NSP_Budgetary_Quote__c) {
                budgetaryQuoteIds.add(invLine.blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__c);
            }

        }

        if(budgetaryQuoteIds.size()>0) {
            for ( blng__InvoiceLine__c invLine : [SELECT Id, blng__Invoice__c, blng__LegalEntity__c, blng__LegalEntity__r.NSP_Company_Name__c,blng__OrderProduct__c, NSP_Product_Code__c,
                                                blng__OrderProduct__r.SBQQ__Subscription__r.SBQQ__Contract__r.StartDate, blng__OrderProduct__r.SBQQ__Subscription__r.SBQQ__Contract__r.EndDate,
                                                blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,  blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.NSP_Budgetary_Quote__c,
                                                blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__c FROM blng__InvoiceLine__c
                                                                                                        WHERE blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__c IN : budgetaryQuoteIds
                                                                                                        AND blng__Invoice__r.blng__InvoiceStatus__c != 'Cancelled' AND blng__Invoice__r.blng__InvoiceStatus__c != 'Rebilled'
                                                                                                        AND NSP_Product_Code__c IN : budgetraryProductCodes ]) {

                if(!invIdToQuoteIdMap.containsKey(invLine.blng__Invoice__c)) {
                    invIdToQuoteIdMap.put(invLine.blng__Invoice__c,invLine.blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__c);
                }
                if(quoteIdtoInvoiceIdMap.containskey(invLine.blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__c)) {
                    Set<String> quoteToinvIdSet = quoteIdtoInvoiceIdMap.get(invLine.blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__c);
                    quoteToinvIdSet.add(invLine.blng__Invoice__c);
                    quoteIdtoInvoiceIdMap.put(invLine.blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__c,quoteToinvIdSet);
                }
                else{
                    quoteIdtoInvoiceIdMap.put(invLine.blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__c,new Set<String>{invLine.blng__Invoice__c});
                }

            }

        }

        for (NSP_Enrollment_Fee_Payment__c enrollFee : [SELECT Id, Name, NSP_Opportunity__c, NSP_WX_WA_Enrollment_Fee_Received__c, NSP_Opportunity__r.SBQQ__PrimaryQuote__c FROM NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__r.SBQQ__PrimaryQuote__c IN : budgetaryQuoteIds AND NSP_WX_WA_Enrollment_Fee_Received__c!=null AND NSP_WX_WA_Enrollment_Fee_Received__c > 0]) {
            if(!quoteIdToEnrollmentFeeMap.containsKey(enrollFee.NSP_Opportunity__r.SBQQ__PrimaryQuote__c)) {
                quoteIdToEnrollmentFeeMap.put(enrollFee.NSP_Opportunity__r.SBQQ__PrimaryQuote__c,true);
            }
        }
        for (blng__Invoice__c inv : invoiceNewMap.values() ){

            if(invIdToFirstLineMap.containsKey(inv.Id)) {
                blng__InvoiceLine__c firstInvLine = invIdToFirstLineMap.get(inv.Id);
                if(firstInvLine.blng__OrderProduct__r.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c == 'Renewal') {
                    inv.Is_Renewal_Invoice__c = true;
                    inv.NSP_Renewal_Start_Date__c = firstInvLine.blng__OrderProduct__r.SBQQ__Subscription__r.SBQQ__Contract__r.StartDate;
                    inv.NSP_Renewal_End_Date__c = firstInvLine.blng__OrderProduct__r.SBQQ__Subscription__r.SBQQ__Contract__r.EndDate;
                }
                if(firstInvLine.blng__LegalEntity__c != null) {
                    inv.NSP_Legal_Entity_Internal__c = firstInvLine.blng__LegalEntity__r.NSP_Company_Name__c;
                }
                if(firstInvLine.blng__OrderProduct__r.Order.AccountId != null && inv.blng__Account__c != firstInvLine.blng__OrderProduct__r.Order.AccountId) {
                    inv.NSP_Primary_Account__c = firstInvLine.blng__OrderProduct__r.Order.AccountId;
                }
                if(firstInvLine.blng__OrderProduct__r.Order.PoNumber != null) {
                    inv.NSP_PO_Number__c = firstInvLine.blng__OrderProduct__r.Order.PoNumber;
                }

                inv.NSP_Bill_To_City__c = firstInvLine.blng__OrderProduct__r.Order.BillingCity;
                inv.NSP_Bill_To_Country__c = firstInvLine.blng__OrderProduct__r.Order.BillingCountry;
                inv.NSP_Bill_To_Name__c = firstInvLine.blng__OrderProduct__r.Order.blng__BillingAccount__r.Name;
                inv.NSP_Bill_To_Postal_Code__c = firstInvLine.blng__OrderProduct__r.Order.BillingPostalCode;
                inv.NSP_Bill_To_State__c = firstInvLine.blng__OrderProduct__r.Order.BillingState;
                inv.NSP_Bill_To_Street__c = firstInvLine.blng__OrderProduct__r.Order.BillingStreet;
                inv.NSP_Ship_To_City__c = firstInvLine.blng__OrderProduct__r.Order.NSP_Ship_To_City__c;
                inv.NSP_Ship_To_Country__c = firstInvLine.blng__OrderProduct__r.Order.NSP_Ship_To_Country__c;
                inv.NSP_Ship_To_Name__c = firstInvLine.blng__OrderProduct__r.Order.NSP_Ship_To_Name__c;
                inv.NSP_Ship_To_Postal_Code__c = firstInvLine.blng__OrderProduct__r.Order.NSP_Ship_To_Postal_Code__c;
                inv.NSP_Ship_To_State__c = firstInvLine.blng__OrderProduct__r.Order.NSP_Ship_To_State__c;
                inv.NSP_Ship_To_Street__c = firstInvLine.blng__OrderProduct__r.Order.NSP_Ship_To_Street__c;
                inv.blng__BillToContact__c = firstInvLine.blng__OrderProduct__r.Order.BillToContactId;

            }

            if(invIdToQuoteIdMap.containsKey(inv.Id)) {
                String currQuoteId = invIdToQuoteIdMap.get(inv.Id);
                if(quoteIdtoInvoiceIdMap.containsKey(currQuoteId) && quoteIdToEnrollmentFeeMap.containsKey(currQuoteId)) {
                    Set<String> budgetaryInvs = quoteIdtoInvoiceIdMap.get(invIdToQuoteIdMap.get(inv.Id));
                    if(budgetaryInvs.size()<=1) {
                        inv.NSP_Bdgt_Quote_First_Invoice__c = true;
                    }
                }
            }
        }


    }

    //
    // Iterates throught the lead map and identifies the records that needs to worked based on various criterias.
    // @param invoiceNewMap Map of New Invoices.
    // @param invoiceOldMap Map of Old Invoices.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,blng__Invoice__c> invoiceNewMap , Map<Id,blng__Invoice__c> invoiceOldMap ) {
        try {
            Date cutoffDate = ( Date.today() - 30 );
            Set<Id> accountIdsToCheck = new Set<Id>();
            Set<String> orderInvoiceIdSet = new Set<String>();
            Set<String> unpaidInvoiceIdSet = new Set<String>();
            for ( blng__Invoice__c inv : invoiceNewMap.values() ) {
                if ( ( inv.blng__Balance__c <= 0 )
                    && ( inv.blng__PaymentStatus__c == 'Paid' )
                    && ( inv.blng__DueDate__c < cutoffDate )
                    && ( inv.blng__PaymentStatus__c != invoiceOldMap.get( inv.Id ).blng__PaymentStatus__c )
                    )
                {
                    accountIdsToCheck.add( inv.blng__Account__c );
                }
                // added for STY-02870
                if ( ( inv.blng__PaymentStatus__c != invoiceOldMap.get( inv.Id ).blng__PaymentStatus__c )
                    && ( inv.blng__PaymentStatus__c == 'Paid' )
                    && ( inv.blng__ARStatus__c != 'Credited' )
                    )
                {
                    orderInvoiceIdSet.add( inv.Id );
                }
                if ( ( inv.blng__PaymentStatus__c != invoiceOldMap.get( inv.Id ).blng__PaymentStatus__c )
                    && ( invoiceOldMap.get( inv.Id ).blng__PaymentStatus__c == 'Paid' )
                    && ( inv.blng__PaymentStatus__c == 'Unpaid' )
                    && ( inv.blng__ARStatus__c != 'Credited' )
                    )
                {
                    unpaidInvoiceIdSet.add( inv.Id );
                }
            }
            if ( !accountIdsToCheck.isEmpty() ) {
                NSP_InvoiceTriggerHelper.checkAndCloseDunningCase( accountIdsToCheck );
            }
            NSP_InvoiceTriggerHelper.setDownPaymentDetailsOnProject( orderInvoiceIdSet );
            NSP_InvoiceTriggerHelper.unsetDownPaymentOnProject( unpaidInvoiceIdSet );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_InvoiceTriggerHelper.class.getName() ,
                'unsetDownPaymentOnProjectFuture' ,
                e
            );
        }
    }

    //@future
    public static void checkAndCloseDunningCase (Set<Id> accountIds ) {
        //System.debug('accountIds :'+accountIds);
        Date cutoffDate = Date.today() - 30;
        Map<String,Case> AccountWithDunningCase = new Map<String,Case>();
        Set<String> AccountIdsWithOpenInv = new Set<String>();
        List<Case> dunningCaseToClose = new List<Case>();
        for (Case cs : [SELECT Id, CaseNumber, Status, ClosedDate, AccountId, NSP_Dunning_Case_Invoice__c FROM Case WHERE AccountId IN: accountIds AND Status!='Closed' AND RecordTypeId=:DUNNING_CASE_RT_ID AND Origin='Dunning' AND NSP_Dunning_Type__c = 'Open Invoice' ]) {
            AccountWithDunningCase.put(cs.AccountId,cs);

        }

        for (blng__Invoice__c openInv : [SELECT Id, Name, blng__Account__c, blng__ARStatus__c, blng__DueDate__c, blng__BillToContact__c,blng__InvoiceDate__c, blng__Balance__c, NSP_Invoice_To_Email__c, blng__PaymentStatus__c, blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__DueDate__c <: cutoffDate AND blng__Balance__c > 0 AND blng__InvoiceStatus__c = 'Posted' AND blng__PaymentStatus__c!='Paid' AND blng__Account__c IN: accountIds LIMIT 1000]) {
            AccountIdsWithOpenInv.add(openInv.blng__Account__c);
        }

        if(AccountWithDunningCase.size()>0) {
            for(Case cs : AccountWithDunningCase.values()) {
                if(!AccountIdsWithOpenInv.contains(cs.AccountId)) {
                    cs.Status = 'Closed';
                    dunningCaseToClose.add(cs);
                }
            }
        }
        if(dunningCaseToClose.size()>0){
            update dunningCaseToClose;
        }
    }

    // Method Name : setDownPaymentDetailsOnProject
    // Description : Method to set Down Payment details on project added for STY-02870
    public static void setDownPaymentDetailsOnProject( Set<String> invoiceIdSet ) {
        if ( ( invoiceIdSet != null )
            && !invoiceIdSet.isEmpty()
            && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() ) // Prevent LimitExceptions
            && !System.isFuture()
            && !System.isBatch()
            )
        {
            NSP_InvoiceTriggerHelper.setDownPaymentDetailsOnProjectFuture( invoiceIdSet );
        }
    }

    @future
    public static void setDownPaymentDetailsOnProjectFuture( Set<String> invoiceIdSet ) {
        try {
            Map<Id,pse__Proj__c> projectUpdateMap = new Map<Id,pse__Proj__c>();
            if ( ( invoiceIdSet != null ) && !invoiceIdSet.isEmpty() ) {
                for ( blng__InvoiceLine__c eachInvline : [
                            SELECT
                                Id ,
                                blng__OrderProduct__r.Order.NSP_Down_Payment_Required__c ,
                                blng__OrderProduct__r.NSP_Project__c ,
                                blng__OrderProduct__r.NSP_Project__r.pse__Project_Status__c
                            FROM blng__InvoiceLine__c
                            WHERE (
                                ( blng__OrderProduct__r.NSP_Project__c != null )
                                AND ( blng__Invoice__c IN :invoiceIdSet )
                                AND ( blng__OrderProduct__r.Order.NSP_Down_Payment_Required__c = 'Yes' )
                            )
                        ]
                    )
                {
                    pse__Proj__c newProject = new pse__Proj__c(
                        Id=eachInvline.blng__OrderProduct__r.NSP_Project__c
                    );
                    if ( eachInvline.blng__OrderProduct__r.NSP_Project__r.pse__Project_Status__c != 'Complete' ) {
                        newProject.Project_Down_Payment_Received__c = true;
                        projectUpdateMap.put( newProject.Id , newProject );
                    }
                }
            }
            if ( !projectUpdateMap.isEmpty() ) {
                update projectUpdateMap.values();
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_InvoiceTriggerHelper.class.getName() ,
                'setDownPaymentDetailsOnProjectFuture' ,
                e
            );
        }
    }

    // Method Name : unsetDownPaymentOnProject
    // Description : When an invoice payment status changes from Paid to Unpaid, uncheck
    //               Project_Down_Payment_Received__c on the linked project if it is checked.
    // @param invoiceIdSet Invoice Id set (invoices that changed from Paid to Unpaid).
    // @return void
    public static void unsetDownPaymentOnProject( Set<String> invoiceIdSet ) {
        if ( ( invoiceIdSet != null )
            && !invoiceIdSet.isEmpty()
            && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() ) // Prevent LimitExceptions
            && !System.isFuture()
            && !System.isBatch()
            )
        {
            NSP_InvoiceTriggerHelper.unsetDownPaymentOnProjectFuture( invoiceIdSet );
        }
    }

    @future
    public static void unsetDownPaymentOnProjectFuture( Set<String> invoiceIdSet ) {
        try {
            Map<Id,pse__Proj__c> projectUpdateMap = new Map<Id,pse__Proj__c>();
            if ( ( invoiceIdSet != null ) && !invoiceIdSet.isEmpty() ) {
                for ( blng__InvoiceLine__c eachInvline : [
                            SELECT
                                Id ,
                                blng__OrderProduct__r.NSP_Project__c ,
                                blng__OrderProduct__r.NSP_Project__r.Project_Down_Payment_Received__c
                            FROM blng__InvoiceLine__c
                            WHERE (
                                ( blng__OrderProduct__r.NSP_Project__c != null )
                                AND ( blng__Invoice__c IN :invoiceIdSet )
                                AND ( blng__OrderProduct__r.NSP_Project__r.Project_Down_Payment_Received__c = true )
                            )
                        ]
                    )
                {
                    pse__Proj__c proj = new pse__Proj__c(
                        Id = eachInvline.blng__OrderProduct__r.NSP_Project__c
                    );
                    proj.Project_Down_Payment_Received__c = false;
                    projectUpdateMap.put( proj.Id , proj );
                }
            }
            if ( !projectUpdateMap.isEmpty() ) {
                update projectUpdateMap.values();
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_InvoiceTriggerHelper.class.getName() ,
                'unsetDownPaymentOnProjectFuture' ,
                e
            );
        }
    }

}