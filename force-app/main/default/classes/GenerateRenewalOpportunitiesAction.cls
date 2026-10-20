public with sharing class GenerateRenewalOpportunitiesAction {
    // test w/ GenerateRenewalOpportunitiesActionTest(100%)

    @InvocableMethod(label='Generate Renewal Opportunities' description='Launch Renewals Batch and pass Month and Year values selected in Flow')
    public static List<Boolean> invoke( List<FlowInput> inputs ) {
        List<Boolean> results = new List<Boolean>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( FlowInput input : inputs ) {
                Boolean isValid = false;
                if ( GenerateRenewalOpportunitiesAction.isValidRequest( input ) ) {
                    Integer monthNumber = input.monthValue;
                    Integer yearNumber = input.yearValue;
                    Set<String> clientNumbers = GenerateRenewalOpportunitiesAction.getInputClientNumbers( input );
                    Id jobId = GenerateRenewalOpportunitiesJob.executeBatch( monthNumber, yearNumber, clientNumbers );
                    isValid = ( jobId != null );
                }
                results.add( isValid );
            }
        }
        return results;
    }

    public class FlowInput {
        @InvocableVariable(label='Month Value' required=true)
        public Integer monthValue;
        @InvocableVariable(label='Year Value' required=true)
        public Integer yearValue;
        @InvocableVariable(label='DEPRECATED - Client Number')
        public String clientNumber;
        @InvocableVariable(label='Client Numbers')
        public List<String> clientNumbers;
        @InvocableVariable(label='Run All Clients')
        public Boolean isRunAllClients;
    }

    //
    //
    //

    private static Boolean isValidRequest( FlowInput input ) {
        Boolean isValid = false;
        if ( ( input != null ) && ( input.monthValue != null ) && ( input.yearValue != null ) ) {
            if ( input.isRunAllClients == true ) {
                isValid = true;
            } else if ( input.clientNumbers != null && !input.clientNumbers.isEmpty() ){
               isValid = GenerateRenewalOpportunitiesAction.validateClientNumbers( input );
            }
        }
        return isValid;
    }

    private static Boolean validateClientNumbers( FlowInput input ) {
        Boolean isValid = false;
        Set<String> requestedClientNumbers = GenerateRenewalOpportunitiesAction.getInputClientNumbers( input );
        if ( !requestedClientNumbers.isEmpty() ) {
            Set<String> eligibleClientNumbers = GenerateRenewalOpportunitiesAction.getEligibleClientNumbers( input );
            isValid = eligibleClientNumbers.containsAll( requestedClientNumbers );
        }
        return isValid;
    }

    private static Set<String> getInputClientNumbers( FlowInput input ) {
        Set<String> clientNumbers = new Set<String>();
        if ( input != null && input.isRunAllClients != true && input.clientNumbers != null && !input.clientNumbers.isEmpty() ) {
            for ( String clientNumber : input.clientNumbers ) {
                if ( String.isNotBlank( clientNumber ) ) {
                    clientNumbers.add( clientNumber.trim() );
                }
            }
        }
        return clientNumbers;
    }

    private static Set<String> getEligibleClientNumbers( FlowInput input ) {
        Set<String> eligibleClientNumbers = new Set<String>();
        Set<String> clientNumbers = GenerateRenewalOpportunitiesAction.getInputClientNumbers( input );
        if ( input != null && input.monthValue != null && input.yearValue != null && clientNumbers != null && !clientNumbers.isEmpty() ) {
            Integer eligibleYear = input.yearValue - 1;
            Date eligibleStart = Date.newInstance( eligibleYear, input.monthValue, 1 );
            Date eligibleEnd = eligibleStart.addMonths( 1 ).addDays( -1 );
            String renewalCreated = input.monthValue + '/' + input.yearValue;
            List<NSP_Sub_Client__c> eligibleSubClients = [
                SELECT
                Id,
                NSP_Client__c
                FROM NSP_Sub_Client__c
                WHERE NSP_Client__c IN :clientNumbers
                AND NSP_Client__c != null
                AND NSP_Account_Status__c = 'Active'
                AND NSP_Renewal_Date__c >= :eligibleStart
                AND NSP_Renewal_Date__c <= :eligibleEnd
                AND Renewal_Created__c != :renewalCreated
                AND NSP_Renewal_Date__c != null
            ];
            if ( !eligibleSubClients.isEmpty() ) {
                for ( NSP_Sub_Client__c eligibleSubClient : eligibleSubClients ) {
                    eligibleClientNumbers.add( eligibleSubClient.NSP_Client__c );
                }
            }
        }
        return eligibleClientNumbers;
    }
}
//