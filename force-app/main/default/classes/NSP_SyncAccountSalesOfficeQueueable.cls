public class NSP_SyncAccountSalesOfficeQueueable implements Queueable  {
    // test w/ NSP_AccountTriggerHelperTest (82%)
    
    private Set<Id> ownerIdSet = new Set<Id>();

    public NSP_SyncAccountSalesOfficeQueueable( Set<Id> local ) {
        if ( local != null ) {
            this.ownerIdSet = local;
        }
    }

    public void execute( QueueableContext context ) {
        if ( ( this.ownerIdSet != null ) && !this.ownerIdSet.isEmpty() ) {
            List<Account> records = new List<Account>();
            for ( Account record : [
                        SELECT
                            Id ,
                            NSP_Sales_Division__c ,
                            NSP_Sales_Office__c ,
                            NSP_SalesRegion__c ,
                            Owner.NSP_SalesDivision__c ,
                            Owner.NSP_Sales_Office__c ,
                            Owner.NSP_SalesRegion__c
                        FROM Account
                        WHERE ( ownerId IN :this.ownerIdSet )
                    ]
                )
            {
                // prevent DmlExceptions UNABLE_TO_LOCK_ROW
                // ~ limit DML operations to only the Accounts that require a modification...
                if ( ( record.NSP_Sales_Division__c != record.Owner.NSP_SalesDivision__c )
                    || ( record.NSP_Sales_Office__c != record.Owner.NSP_Sales_Office__c )
                    || ( record.NSP_SalesRegion__c != record.Owner.NSP_SalesRegion__c )
                    )
                {
                    record.NSP_Sales_Division__c = record.Owner.NSP_SalesDivision__c;
                    record.NSP_Sales_Office__c = record.Owner.NSP_Sales_Office__c;
                    record.NSP_SalesRegion__c = record.Owner.NSP_SalesRegion__c;
                    records.add( record );
                }
            }
            try {
                if ( !records.isEmpty() ) {
                    List<Database.SaveResult> results = Database.update( records , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_SyncAccountSalesOfficeQueueable.class.getName() ,
                        'execute:update' ,
                        results
                    );
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_SyncAccountSalesOfficeQueueable.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

}
//