public class ContractTerminationHandler {
    // test w/ ContractTerminationHandlerTest (88%)

    @InvocableMethod(label='runContractTerminationHandler' description='Method to trigger call for contract termination')
    public static void runContractTerminationHandler( List<ContractTerminationRequest> requests ) {
        try {
            Map<Id,Date> contractToTerminationDates = new Map<Id,Date>();
            if ( ( requests != null ) && !requests.isEmpty() ) {
                for ( ContractTerminationRequest request : requests ) {
                    contractToTerminationDates.put( request.ContractId , request.TerminationDate );
                }
            }
            if ( !contractToTerminationDates.isEmpty()
                && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() )
                )
            {
                System.enqueueJob( new ContractTerminationQueue( contractToTerminationDates ) );
            }
        } catch ( Exception e ) {
            ContractTerminationHandler.handleException( e , 'runContractTerminationHandler' );
        }
    }

    public class ContractTerminationRequest {
        @InvocableVariable(label='Contract ID' required=true)
        public Id contractId;
        @InvocableVariable(label='Termination Date' required=true)
        public Date terminationDate;
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            ContractTerminationHandler.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            ContractTerminationHandler.class.getName() ,
            methodName ,
            e
        );
    }

}
//