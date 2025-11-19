public with sharing class GeneratePriceIncreasesBatch implements Database.Batchable<sObject> , Database.Stateful {
    // test w/ GeneratePriceIncreasesBatchTest (87%)

    private Integer successCount = 0;
    private Integer failCount = 0;

    @AuraEnabled
    public static void executeBatch() {
        Database.executeBatch(
            new GeneratePriceIncreasesBatch() ,
            GeneratePriceIncreasesBatch.batchSize
        );
    }

    private GeneratePriceIncreasesBatch(){
    }

    //get purchased product records that are applicable for PI and dont have any existing PI record
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        //filter out records with pre-existing PI records for next year
        String filter = '%-' + this.getNextYear();
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    Total_Price__c ,
                    Retail_Price__c ,
                    Asset__c
                FROM Purchased_Product__c
                WHERE (
                    ( Product__r.Qualifies_For_Price_Increase__c = true )
                    AND (
                        Id NOT IN (
                            SELECT Purchased_Product__c
                            FROM Price_Increase__c
                            WHERE ( Unique_Id__c LIKE :filter )
                        )
                    ) 
                    AND ( Asset__r.Status = 'Active' )
                    AND ( Purchase_Status__c != 'Canceled' )
                )
            ]
        );
    }

    //create PI records
    public void execute( Database.BatchableContext bc , List<Purchased_Product__c> scope ) {
        if ( ( scope != null )
            && ( !scope.isEmpty() )
            && ( GeneratePriceIncreasesBatch.isEnabled )
            )
        {
            //insert list
            List<Price_Increase__c> piList = new List<Price_Increase__c>();
            //create PI records and add to list
            for ( Purchased_Product__c pp : scope ) {
                piList.add( this.buildPriceIncrease( pp ) );
            }
            //insert PI list
            if ( !piList.isEmpty() ) {
                try {
                    Database.SaveResult[] piSaveResult = Database.insert( piList , false );
                    NSP_ErrorLogHandler.logResults(
                        GeneratePriceIncreasesBatch.class.getName() ,
                        'execute:insert',
                        piSaveResult
                    );
                    this.updateResultCount( piSaveResult );
                } catch ( exception e ) {
                    NSP_ErrorLogHandler.logException(
                        GeneratePriceIncreasesBatch.class.getName() ,
                        'execute' ,
                        e
                    );
                }
            }
        }
    }

    //send processing finished email to user
    public void finish( Database.BatchableContext bc ) {
        if ( GeneratePriceIncreasesBatch.isEnabled ) {
            try {
                //email success batch job
                List<String> toUsers = new List<String>();
                toUsers.add( UserInfo.getUserEmail() );
                if ( ( GeneratePriceIncreasesBatch.monitorEmailAddresses != null )
                    && !GeneratePriceIncreasesBatch.monitorEmailAddresses.isEmpty()
                   )
                {
                    toUsers.addAll( GeneratePriceIncreasesBatch.monitorEmailAddresses );
                }
                GeneratePriceIncreasesBatch.sendEmail(
                    toUsers ,
                    'GeneratePriceIncreasesBatch Complete' ,
                    this.constructEmailBody()
                );
            } catch ( exception e ) {
                NSP_ErrorLogHandler.logException(
                    GeneratePriceIncreasesBatch.class.getName() ,
                    'finish',
                    e
                );
            }
        }
    }

    //kepe update of success and fails
    private void updateResultCount( List<Database.SaveResult> results ) {
        if ( ( results != null ) && !results.isEmpty() ) {
            for ( Database.SaveResult res : results ) {
                if ( !res.isSuccess() ) {
                    this.failCount += 1;
                } else {
                    this.successCount += 1;
                }
            }
        }
    }

    //create email message
    private String constructEmailBody() {
        String body = String.valueOf( this.successCount ) + ' ';
        if ( this.failCount != 0 ) {
            body += '(' + String.valueOf( this.failCount ) + '-errors) ';
        }
        body += 'Price Increase Records have been created for ' + this.getNextYear();
        return body;
    }

    //method for creating PI records
    private Price_Increase__c buildPriceIncrease( Purchased_Product__c pp ) {
        Price_Increase__c pi = new Price_Increase__c();
        if ( pp != null ) {
            if ( pp.Total_Price__c != null ) {
                pi.Current_PEPM__c = pp.Total_Price__c;
            }
            if ( pp.Retail_Price__c != null ) {
                pi.Current_Retail_Price__c = pp.Retail_Price__c;
            }
            if ( pp.Asset__c != null ) {
                pi.Asset__c = pp.Asset__c;
            }
            pi.Purchased_Product__c = pp.id;
            pi.Unique_Id__c = pp.Id + '-' + this.getNextYear();
        }
        return pi;
    }

    //method to fetch upcomming finanical year based on Today's Date
    private String getNextYear() {
        Date todaysDate = System.today();
        String outputYear = '';
        //first date of new financial year i.e. 1st April
        Date newYearsDay = Date.newInstance( todaysDate.year() , 4 , 1 );
        if ( todaysDate < newYearsDay ) {
            outputYear = String.valueOf( newYearsDay.year() );
        } else {
            outputYear = String.valueOf( newYearsDay.addYears( 1 ).year() );
        }
        return outputYear;
    }

    //method to send email via flow
    private static void sendEmail( String[] listOfToAddresses , String subject , String body ) {
        Map<String,Object> inputs = new Map<String,Object>();
        if ( !listOfToAddresses.isEmpty() ) {
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

    private static GeneratePriceIncreasesBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = GeneratePriceIncreasesBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( GeneratePriceIncreasesBatch.settings != null ) {
                    local = GeneratePriceIncreasesBatch.settings.IsEnabled__c;
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
                if ( ( GeneratePriceIncreasesBatch.settings != null )
                    && ( GeneratePriceIncreasesBatch.settings.BatchSize__c != null )
                   )
                {
                    local = GeneratePriceIncreasesBatch.settings.BatchSize__c.intValue();
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
                if ( GeneratePriceIncreasesBatch.settings != null ) {
                    String rawMonitorEmailAddresses = GeneratePriceIncreasesBatch.settings.MonitorEmailAddresses__c;
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