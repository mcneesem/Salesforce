public with sharing class InsperityWOBillingAccountTransferBatch implements Database.Batchable<sObject> , Database.Stateful {
    // test w/ InsperityWOBlngAccTransferBatchTest (92%)

    public String previousMonthAccountName;
    public String currentAccountId;
    public List<Id> lstOrdProcessed = new List<Id>();
    public List<String> lstOrdFailed = new List<String>();
    public List<Id> lstOrditemProcessed = new List<Id>();
    public List<String> lstOrditemFailed = new List<String>();

    public InsperityWOBillingAccountTransferBatch( String localPreviousMonthAccountName , String localCurrentMonthAccountId ) {
        this.previousMonthAccountName = localPreviousMonthAccountName;
        this.currentAccountId = localCurrentMonthAccountId;
    }

    //Querying the data from order matching the criteria
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Set<String> billingAccountNames = new Set<String>();
        if ( String.isNotBlank( this.previousMonthAccountName ) ) {
            billingAccountNames.add( this.previousMonthAccountName );
        }
        if ( String.isNotBlank( Label.InsperityWOBillingAccountName ) ) {
            billingAccountNames.add( Label.InsperityWOBillingAccountName );
        }
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    blng__BillingAccount__c ,
                    (
                        SELECT Id , blng__BillingAccount__c , blng__InvoiceRunProcessingStatus__c , Has_Consumption_Schedule__c
                        FROM OrderItems
                    )
                FROM Order
                WHERE (
                    ( NSP_Billing_Account_Name__c IN :billingAccountNames )
                    AND ( ( NSP_TerminationDate__c >= TODAY ) OR ( NSP_TerminationDate__c = null ) )
                    AND ( NSP_Back_Out__c = false )
                    AND ( Prevent_Reassignment__c = false )
                )
            ]
        );
    }

    // Collecting the order id from the order product
    // Checking all order product for that order for match criteria
    public void execute( Database.BatchableContext bc , List<Order> orderLst ) {
        List<String> strLstInvRun = new List<String>();
        if ( String.isNotBlank( Label.Product_Invoice_Run_status ) ) {
            strLstInvRun = Label.Product_Invoice_Run_status.split( ',' );
        }
        try {
            List<OrderItem> oiLst = new List<OrderItem>();
            List<OrderItem> oiLstToUpdate = new List<OrderItem>();
            List<Order> ordListUpdate = new List<Order>();
            Map<Id,List<OrderItem>>  mapOrOi = new Map<Id,List<OrderItem>>();
            if ( !orderLst.isEmpty() ) {
                for ( Order ord : orderLst ) {
                    Boolean ordExcluded = true;
                    for ( OrderItem oi : ord.OrderItems ) {
                        ord.blng__BillingAccount__c = this.currentAccountId;
                        oi.blng__BillingAccount__c = this.currentAccountId;
                        if ( oi.Has_Consumption_Schedule__c
                            || strLstInvRun.contains( oi.blng__InvoiceRunProcessingStatus__c )
                            )
                        {
                            ordExcluded = false;
                        }
                        oiLst.add( oi );
                    }
                    if ( !ordExcluded ) {
                        mapOrOi.put( ord.Id , oiLst );
                        oiLstToUpdate.addall( oiLst );
                        ordListUpdate.add( ord );
                        oiLst.clear();
                    }
                }
            }
            if ( !mapOrOi.isempty() ) {
                Database.SaveResult[] srList = Database.update( ordListUpdate , false );
                for ( Database.SaveResult dsr : srList ) {
                    if ( dsr.isSuccess() ) {
                        oiLstToUpdate.addall( mapOrOi.get( dsr.Id ) );
                        this.lstOrdProcessed.add( dsr.Id );
                    } else {
                        this.lstOrdFailed.add( dsr.Id + ' ' + dsr.getErrors()[0].getMessage() );
                    }
                }
                if( !oiLstToUpdate.isempty() ) {
                    Database.SaveResult[] srList1 = Database.update( oiLstToUpdate , false );
                    for ( Database.SaveResult dsr : srList1 ) {
                        if ( dsr.isSuccess() ) {
                           this.lstOrditemProcessed.add( dsr.Id );
                        } else {
                            this.lstOrditemFailed.add( dsr.Id + ' ' + dsr.getErrors()[0].getMessage() );
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                InsperityWOBillingAccountTransferBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
        try {
            if ( EmailDeliverabilityController.isEnabledOutbound ) {
                // Send an email to the Apex job's submitter notifying of job completion.
                // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
                // Query the AsyncApexJob object to retrieve the current job's information.
                AsyncApexJob async = [
                    SELECT Id , Status , NumberOfErrors , JobItemsProcessed , TotalJobItems , CreatedBy.Email
                    FROM AsyncApexJob
                    WHERE ( Id = :bc.getJobId() )
                ];

                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[]{ async.CreatedBy.Email };
                mail.setToAddresses( toAddresses );
                mail.setSubject( 'Transfer Billing Account Batch: ' + async.Status );
                String body = ''
                    + 'The batch Apex job processed ' + async.TotalJobItems + ' batches with '+ async.NumberOfErrors + ' failures.<br/>'
                    + 'Total order Records processed: ' + this.lstOrdProcessed.size() + '<br/>'
                    + 'Order records processed: ' + JSON.serialize( this.lstOrdProcessed ) + '<br/>'
                    + 'Total Order records failed: ' + this.lstOrdFailed.size() + '<br/>'
                    + 'Order records failed: ' + JSON.serialize( this.lstOrdFailed ) + '<br/>'
                    + 'Total OrderItem records processed: ' + this.lstOrditemProcessed.size() + '<br/>'
                    + 'OrderItem records processed: ' + JSON.serialize( this.lstOrditemProcessed ) + '<br/>'
                    + 'Total OrderItem records failed: ' + this.lstOrditemFailed.size() + '<br/>'
                    + 'OrderItem records failed: ' + JSON.serialize( this.lstOrditemFailed ) + '<br/>'
                    ;
                mail.setHtmlBody( body );
                Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ mail } );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                InsperityWOBillingAccountTransferBatch.class.getName() ,
                'finish' ,
                e
            );
        }
    }

}
//