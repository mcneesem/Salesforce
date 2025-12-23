public class NSP_ProcessOrderChangeBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<sObject> {
    // test w/ NSP_ProcessOrderChangeBatchTest (93%)

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_ProcessOrderChangeBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs M-F at 9pm central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_ProcessOrderChangeBatch ~ process asset and create opportunity and quote ~ M-F at 9 PM' + suffix ,
            '0 0 21 ? * MON-FRI *' ,
            new NSP_ProcessOrderChangeBatch()
        );
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        Id response = null;
        if ( NSP_ProcessOrderChangeBatch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_ProcessOrderChangeBatch() ,
                NSP_ProcessOrderChangeBatch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

    public database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    AccountId ,
                    NSP_RET_lead_parent__c ,
                    NSP_RET_lead_parent__r.AccountId ,
                    NSP_OrderProduct__r.Order.SBQQ__Quote__c ,
                    NSP_OrderProduct__r.Order.SBQQ__Quote__r.RecordTypeId ,
                    NSP_OrderProduct__r.Order.SBQQ__Quote__r.NSP_Product_Type__c ,
                    NSP_OrderProduct__r.Order.SBQQ__Quote__r.NSP_Price_Book__c ,
                    NSP_ReAssigned_Order_Quote_Id__c ,
                    NSP_OrderProduct__r.Order.OpportunityId ,
                    NSP_Change_Order_Process_Contract_Status__c ,
                    NSP_OrderProduct__r.Order.NSP_Billing_Account__c
                FROM Asset
                WHERE (
                    ( NSP_Process_Order_Change__c = true )
                    AND (
                        ( NSP_Change_Order_Process_Contract_Status__c = null )
                        OR ( NSP_Change_Order_Process_Contract_Status__c = '' )
                    )
                    AND ( NSP_RET_lead_parent__c != null )
                    AND (
                        (
                            ( NSP_OrderProduct__c != null )
                            AND ( NSP_OrderProduct__r.Order.SBQQ__Quote__c != null )
                        )
                        OR ( NSP_ReAssigned_Order_Quote_Id__c != null )
                    )
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<Asset> scope ) {
        if ( NSP_ProcessOrderChangeBatch.isEnabled ) {
            try {
                Map<Id,Opportunity> assetIdToOpportunityMap = new Map<Id,Opportunity>();
                Set<Id> opportunityIdSet = new Set<Id>();
                for ( Asset eachAsset : scope ) {
                    opportunityIdSet.add( eachAsset.NSP_OrderProduct__r.Order.OpportunityId );
                }
                for ( Asset eachAsset : scope ) {
                    eachAsset.NSP_Change_Order_Process_Contract_Status__c ='Change Order Created' ;
                    String quoteIdStr = ( ( eachAsset.NSP_ReAssigned_Order_Quote_Id__c != null ) ? eachAsset.NSP_ReAssigned_Order_Quote_Id__c : eachAsset.NSP_OrderProduct__r.Order.SBQQ__Quote__c );
                    QuoteReader reader = new QuoteReader();
                    QuoteModel model = reader.read( quoteIdStr );
                    SBQQ__Quote__c objNewQuote = model.record;
                    objNewQuote.SBQQ__Account__c = eachAsset.NSP_RET_lead_parent__r.AccountID;
                    objNewQuote.SBQQ__Opportunity2__c = null;
                    objNewQuote.SBQQ__Primary__c = true;
                    objNewQuote.SBQQ__Ordered__c = false;
                    objNewQuote.NSP_Change_Order_Process_Quote__c = true;
                    objNewQuote.RecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'SBQQ__Quote__c' , 'NSP_Retirement_Services' );
                    objNewQuote.NSP_Product_Type__c = eachAsset.NSP_OrderProduct__r.Order.SBQQ__Quote__r.NSP_Product_Type__c;
                    objNewQuote.NSP_Price_Book__c = eachAsset.NSP_OrderProduct__r.Order.SBQQ__Quote__r.NSP_Price_Book__c;
                    objNewQuote.NSP_Original_Order_Bill_To_Account__c = eachAsset.NSP_OrderProduct__r.Order.NSP_Billing_Account__c;
                    objNewQuote.id  = null;
                    objNewQuote.SBQQ__StartDate__c = System.today().toStartOfMonth();
                    objNewQuote.NSP_Change_Order_Process_Source_Asset__c = eachAsset.Id;
                    objNewQuote.NSP_Lead_Parent_Asset_Id__c = eachAsset.NSP_RET_lead_parent__c;
                    objNewQuote.NSP_Billing_Account__c = eachAsset.NSP_OrderProduct__r.Order.NSP_Billing_Account__c;
                    model = this.modelHelper( model );
                    String quoteJSON = SBQQ.ServiceRouter.save( 'SBQQ.QuoteAPI.QuoteSaver' , JSON.serialize( model ) );
                    JSON.deserialize( quoteJSON , QuoteModel.class );
                }
                List<Database.SaveResult> opptyResults = Database.update( assetIdToOpportunityMap.values() , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProcessOrderChangeBatch.class.getName() ,
                    'execute:Opportunity' ,
                    opptyResults
                );
                List<Database.SaveResult> assetResults = Database.update( scope , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_ProcessOrderChangeBatch.class.getName() ,
                    'execute:Asset' ,
                    assetResults
                );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_ProcessOrderChangeBatch.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

    private QuoteModel modelHelper( QuoteModel model ) {
        if ( ( model != null )
            && ( model.lineItems != null )
            && !model.lineItems.isEmpty()
            )
        {
            for ( QuoteLineModel item : model.lineItems ) {
                if ( item.record != null ) {
                    item.record.Id = null;
                }
            }
        }
        return model;
    }


    public void finish( Database.BatchableContext bc ) {
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static ProcessOrderChangeBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = ProcessOrderChangeBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( NSP_ProcessOrderChangeBatch.settings != null ) {
                    local = NSP_ProcessOrderChangeBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 10;
                if ( ( NSP_ProcessOrderChangeBatch.settings != null )
                    && ( NSP_ProcessOrderChangeBatch.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_ProcessOrderChangeBatch.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // batch size must be less than or equal to 2000...
                if ( local > 2000 ) {
                    local = 2000;
                }
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }

}
//