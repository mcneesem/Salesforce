public without sharing class OpportunityMaxOrientationDateAction {
    // test w/ OpportunityMaxOrientationDateActionTest (84%)

    @InvocableMethod(label='Opportunity Max Orientation Date' description='This method populates the max orientation date on the given Opportunity')
    public static void invoke( List<FlowInput> inputs ) {
        try {
            Map<Id,Date> opportunityMap = new Map<Id,Date>();
            if ( ( inputs != null ) && !inputs.isEmpty() ) {
                for ( FlowInput input : inputs ) {
                    if ( ( input != null ) && ( input.opportunitytId != null ) ) {
                        opportunityMap.put( input.opportunitytId , input.maxOrientationDate );
                    }
                }
            }
            if ( !opportunityMap.isEmpty() ) {
                OpportunityMaxOrientationDateAction.populateMaxOrientationDate( opportunityMap );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                OpportunityMaxOrientationDateAction.class.getName() ,
                'invoke' ,
                e
            );
        }
    }

    public class FlowInput {
        @InvocableVariable(label='Opprtunity Id' required=true)
        public String opportunitytId;
        @InvocableVariable(label='Max Orientation Date')
        public Date maxOrientationDate;
    }

    private static void populateMaxOrientationDate( Map<Id,Date> opportunityMaxOrientationDateMap ) {
        List<Opportunity> records = null;
        if ( opportunityMaxOrientationDateMap != null ) {
            records = [
                SELECT Id , Max_Orientation_Date__c
                FROM Opportunity
                WHERE ( Id IN :opportunityMaxOrientationDateMap.keySet() )
            ];
        }
        List<Opportunity> dmlRecords = new List<Opportunity>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( Opportunity record : records ) {
                if ( opportunityMaxOrientationDateMap.containsKey( record.Id ) ) {
                    Date max = opportunityMaxOrientationDateMap.get( record.Id );
                    if ( record.Max_Orientation_Date__c != max ) {
                        record.Max_Orientation_Date__c = max;
                        dmlRecords.add( record );
                    }
                }
            }
        }
        if ( !dmlRecords.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( dmlRecords , false );
            NSP_ErrorLogHandler.logResults(
                OpportunityMaxOrientationDateAction.class.getName() ,
                'populateMaxOrientationDate' ,
                results
            );
        }
    }

}
//