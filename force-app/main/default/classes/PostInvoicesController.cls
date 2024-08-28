public with sharing class PostInvoicesController {
    // test w/ PostInvoicesControllerTest (84%)

    @AuraEnabled
    public static void PostInvoices( Id invoiceRunId ) {
        //validate user
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Manage_Posted_Invoices' ,
            UserInfo.getUserId()
        );
        //validate Id type and user access
        if ( hasPermission
            && ( invoiceRunId != null )
            && ( Id.valueOf( invoiceRunId ).getSObjectType() == blng__InvoiceRun__c.getSObjectType() )
            )
        {
            //handle the posted Invoices with unposted lines
            List<blng__Invoice__c> invoice2Update = new list<blng__Invoice__c>();
            List<blng__InvoiceLine__c> lines2Update = new List<blng__InvoiceLine__c>();
            //query all invoices and the related lines where: 
            //(invoice run matches), (status is posted) and the (invoice has atlease one unposted line from the current invoice run)
            for ( blng__Invoice__c invoice : [
                        SELECT
                            Id , blng__InvoiceStatus__c , blng__InvoicePostedDate__c ,
                            (
                                SELECT Id , blng__InvoiceLineStatus__c , blng__TaxStatus__c,blng__TotalAmount__c
                                FROM blng__InvoiceInvoiceLines__r
                                WHERE ( blng__InvoiceLineStatus__c != 'Posted' )
                            )
                        FROM blng__Invoice__c 
                        WHERE (
                            ( blng__InvoiceRunCreatedBy__c = :invoiceRunId )
                            AND (
                                ( blng__InvoiceStatus__c = 'Posted' )
                                OR ( blng__InvoiceStatus__c = 'Post In Progress' )
                            )
                            AND (
                                Id IN (
                                    SELECT blng__Invoice__c
                                    FROM blng__InvoiceLine__c
                                    WHERE (
                                        ( blng__InvoiceLineStatus__c != 'Posted' )
                                        AND ( blng__InvoiceRun__c = :invoiceRunId )
                                    )
                                )
                            )
                        )
                    ]
                )
            {
                invoice.blng__InvoiceStatus__c = 'Draft';
                invoice.blng__InvoicePostedDate__c = System.today();
                invoice2Update.add(invoice);
                //process lines
                if ( !invoice.blng__InvoiceInvoiceLines__r.isEmpty() ) {
                    for(List<blng__InvoiceLine__c> listOfUnpostedLines: invoice.blng__InvoiceInvoiceLines__r){
                        if ( !listOfUnpostedLines.isEmpty() ) {
                            for(blng__InvoiceLine__c invoiceLine: listOfUnpostedLines){
                                invoiceLine.blng__TaxStatus__c = 'Queued';
                                invoiceLine.blng__TotalAmount__c = 0;
                                lines2Update.add(invoiceLine);
                            }
                        }
                    }
                }
            }
            try{
                if ( ( lines2Update != null ) && !lines2Update.isEmpty() ){
                    update lines2Update;
                }
                if ( ( invoice2Update != null ) && !invoice2Update.isEmpty() ){
                    SBQQ.TriggerControl.disable();
                    try{
                        update invoice2Update;
                    }Catch(DmlException e){
                        //System.debug(e);
                        throw new AuraHandledException(e.getMessage());
                    }finally{
                        SBQQ.TriggerControl.enable();
                    }
                }
            }catch(DmlException e){
                //System.debug(e);
                throw new AuraHandledException(e.getMessage());
            }
        }else{
            throw new AuraHandledException('Invalid Operation');
        }
    }

}