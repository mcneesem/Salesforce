public with sharing class ComponentPriceUpdateBatch implements Database.Batchable<sObject> , Database.Stateful {
    // test w/ ComponentPriceUpdateBatchTest (87%)

    private Integer successCount = 0;
    private Integer failCount = 0;
    private String pricingModel= null;
    private String seasonalPricing= null;
    private String productId=null;
    private List<NSP_Pricing_Table__c> pricingTables = null;

    public static void executeBatch(
        String pricingModelLocal ,
        String seasonalPricingLocal ,
        String productIdLocal ,
        List<NSP_Pricing_Table__c> lstPricingTableLocal
        )
    {
        if ( ComponentPriceUpdateBatch.isEnabled
            && String.isNotBlank( pricingModelLocal )
            && String.isNotBlank( seasonalPricingLocal )
            && String.isNotBlank( productIdLocal )
            && ( lstPricingTableLocal != null )
            && !lstPricingTableLocal.isEmpty() )
        {
            Database.executeBatch(
                new ComponentPriceUpdateBatch(
                    pricingModelLocal ,
                    seasonalPricingLocal ,
                    productIdLocal ,
                    lstPricingTableLocal
                ) ,
                ComponentPriceUpdateBatch.batchSize
            );
        }
    }

    private ComponentPriceUpdateBatch(
        String pricingModelLocal ,
        String seasonalPricingLocal ,
        String productIdLocal ,
        List<NSP_Pricing_Table__c> lstPricingTableLocal
        )
    {
        pricingModel = pricingModelLocal;
        seasonalPricing = seasonalPricingLocal;
        productId = productIdLocal;
        pricingTables = lstPricingTableLocal;
    }

    //get purchased product records that are applicable for PI and dont have any existing PI record
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    Component_Price__c ,
                    Quoted_Quantity__c
                FROM Purchased_Product__c
                WHERE (
                    ( Product__c = :productId )
                    AND ( Pricing_Model__c = :pricingModel )
                    AND ( Seasonal_Pricing__c = :seasonalPricing )
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<Purchased_Product__c> scope ) {
        try {
            if ( ComponentPriceUpdateBatch.isEnabled
                && ( scope != null )
                && !scope.isEmpty()
                )
            {
                List<Purchased_Product__c> ppList = new List<Purchased_Product__c>();
                for ( Purchased_Product__c pp : scope ) {
                    ppList = this.updateComponentPrice( pp , ppList );
                }
                //insert PP list
                if ( !ppList.isEmpty() ) {
                    Database.SaveResult[] ppSaveResult = Database.Update( ppList , false );
                    NSP_ErrorLogHandler.logResults(
                        ComponentPriceUpdateBatch.class.getName() ,
                        'execute',
                        ppSaveResult
                    );
                    updateCount(ppSaveResult);
                }
            }
        } catch( Exception e ) {
            NSP_ErrorLogHandler.logException(
                ComponentPriceUpdateBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    private List<Purchased_Product__c> updateComponentPrice( Purchased_Product__c pp , List<Purchased_Product__c> ppList ) {
        if ( ( this.pricingTables != null ) && !this.pricingTables.isEmpty() ) {
            for ( NSP_Pricing_Table__c prtable : this.pricingTables ) {
                if ( ( pp != null )
                    && this.isWithinPricingBounds(pp.Quoted_Quantity__c, prtable)
                    )
                {
                    pp.Component_Price__c = prtable.NSP_List_Price__c;
                    ppList.add( pp );
                    break; // Exit the loop once the price is set
                }
            }
        }
        return ppList;
    }

    private Boolean isWithinPricingBounds( Decimal quotedQuantity , NSP_Pricing_Table__c prtable ) {
        Boolean isWithinBounds = false;
        if ( ( quotedQuantity != null ) && ( prtable != null ) ) {
            isWithinBounds = (
                ( quotedQuantity <= prtable.NSP_Upper_Bound__c )
                && ( quotedQuantity >= prtable.NSP_Lower_Bound__c )
            );
        }
        return isWithinBounds;
    }

    //send processing finished email to user
    public void finish( Database.BatchableContext bc ) {
        try {
            if ( ComponentPriceUpdateBatch.isEnabled ) {
                //email success batch job
                List<String> toUsers = new List<String>();
                toUsers.add( UserInfo.getUserEmail() );
                if ( ( ComponentPriceUpdateBatch.monitorEmailAddresses != null )
                    && !ComponentPriceUpdateBatch.monitorEmailAddresses.isEmpty()
                    )
                {
                    toUsers.addAll( ComponentPriceUpdateBatch.monitorEmailAddresses );
                }
                ComponentPriceUpdateBatch.sendEmail(
                    toUsers ,
                    'ComponentPriceUpdateBatch Complete' ,
                    constructMailBody()
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                ComponentPriceUpdateBatch.class.getName() ,
                'finish',
                e
            );
        }
    }

    private void updateCount( List<Database.SaveResult> results ) {
        if ( ( results != null ) && !results.isEmpty() ) {
            for ( Database.SaveResult res : results ) {
                if ( res.isSuccess() ) {
                    this.successCount += 1;
                } else {
                    this.failCount += 1;
                }
            }
        }
    }

    private String constructMailBody() {
        String body = String.valueOf( this.successCount ) + '';
        if ( this.failCount > 0 ) {
            body += '(' + String.valueOf( this.failCount ) + '-errors) ';
        }
        body += ' Purchase product Records have been updated ';
        return body;
    }

    //method to send email via flow
    private static void sendEmail( List<String> listOfToAddresses , String subject , String body ) {
        Map<String,Object> inputs = new Map<String,Object>();
        if ( ( listOfToAddresses != null ) && !listOfToAddresses.isEmpty() ) {
            inputs.put( 'toEmailAddresses' , listOfToAddresses );
            inputs.put( 'emailSubject' , subject );
            inputs.put( 'emailBody' , body );
            Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email( inputs );
            sendEmailFlow.start();
        }
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a running job...
    // ~ leveraging same custom settings to control the batch as OrderItemPriceUpdatBatch
    //

    private static ComponentPriceUpdateBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = ComponentPriceUpdateBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( ComponentPriceUpdateBatch.settings != null ) {
                    local = ComponentPriceUpdateBatch.settings.IsEnabled__c;
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
                Integer local = 200;
                if ( ( ComponentPriceUpdateBatch.settings != null )
                    && ( ComponentPriceUpdateBatch.settings.BatchSize__c != null )
                    )
                {
                    local = ComponentPriceUpdateBatch.settings.BatchSize__c.intValue();
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

    private static List<String> monitorEmailAddresses  {
        private get {
            if ( monitorEmailAddresses == null ) {
                List<String> local = new List<String>();
                if ( ComponentPriceUpdateBatch.settings != null ) {
                    String rawMonitorEmailAddresses = ComponentPriceUpdateBatch.settings.MonitorEmailAddresses__c;
                    if ( String.isNotBlank( rawMonitorEmailAddresses ) ) {
                        List<String> splitMonitorEmailAddresses = rawMonitorEmailAddresses.split( '\r\n' );
                        if ( ( splitMonitorEmailAddresses != null ) && ( splitMonitorEmailAddresses.size() > 0 ) ) {
                            local = splitMonitorEmailAddresses;
                        }
                    }
                }
                monitorEmailAddresses = local;
            }
            return monitorEmailAddresses;
        }
        private set;
    }

}
//