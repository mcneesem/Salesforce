public with sharing class GenerateRenewalOpportunitiesAction {
    // test w/ GenerateRenewalOpportunitiesActionTest(100%)

    @InvocableMethod(label='Generate Renewal Opportunities' description='Launch Renewals Batch and pass Month and Year values selected in Flow')
    public static List<Boolean> invoke( List<MonthYearData> inputs ) {
        List<Boolean> results = new List<Boolean>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( MonthYearData input : inputs ) {
                Boolean isValid = false;
                if ( GenerateRenewalOpportunitiesAction.isValidRequest( input ) ) {
                    Integer monthNumber = input.monthValue ;
                    Integer yearNumber = input.yearValue;
                    Set<String> clientNumbers = GenerateRenewalOpportunitiesAction.getClientNumbers( input );
                    Id jobId = GenerateRenewalOpportunitiesJob.executeBatch( monthNumber, yearNumber, clientNumbers );
                    isValid = ( jobId != null );
                }
                results.add( isValid );
            }
        }
        return results;
    }

    private static Boolean isValidRequest( MonthYearData input ) {
        Boolean isValid = false;
        if ( ( input != null ) && ( input.monthValue != null ) && ( input.yearValue != null ) ) {
            if ( input.isRunAllClients == true ) {
                isValid = true;
            } else if ( String.isNotBlank( input.clientNumber ) ) {
                String clientNumber = input.clientNumber.trim();
                Integer monthNumber = input.monthValue ;
                isValid = GenerateRenewalOpportunitiesAction.isEligibleClient( clientNumber, monthNumber, input.yearValue );
            }
        }
        return isValid;
    }

    private static Set<String> getClientNumbers( MonthYearData input ) {
        Set<String> clientNumbers = new Set<String>();
        if ( input != null && input.isRunAllClients != true && String.isNotBlank( input.clientNumber ) ) {
            clientNumbers.add( input.clientNumber.trim() );
        }
        return clientNumbers;
    }

    private static Boolean isEligibleClient( String clientNumber, Integer monthNumber, Integer yearNumber ) {
        List<NSP_Sub_Client__c> eligibleClients = new List<NSP_Sub_Client__c>();
        if ( String.isNotBlank( clientNumber ) && ( monthNumber != null ) && ( yearNumber != null ) ) {
            Integer eligibleYear = yearNumber - 1;
            Date eligibleStart = Date.newInstance( eligibleYear, monthNumber, 1 );
            Date eligibleEnd = eligibleStart.addMonths( 1 ).addDays( -1 );
            String renewalCreated = monthNumber + '/' + yearNumber;
            eligibleClients = [
                SELECT Id
                FROM NSP_Sub_Client__c
                WHERE NSP_Client__c = :clientNumber
                AND NSP_Account_Status__c = 'Active'
                AND NSP_Renewal_Date__c >= :eligibleStart
                AND NSP_Renewal_Date__c <= :eligibleEnd
                AND Renewal_Created__c != :renewalCreated
                AND NSP_Renewal_Date__c != null
                LIMIT 1
            ];
        }
        return !eligibleClients.isEmpty();
    }

    public class MonthYearData {
        @InvocableVariable(label='Month Value' required=true)
        public Integer monthValue;
        @InvocableVariable(label='Year Value' required=true)
        public Integer yearValue;
        @InvocableVariable(label='Client Number')
        public String clientNumber;
        @InvocableVariable(label='Run All Clients')
        public Boolean isRunAllClients;
    }
}
//