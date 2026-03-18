public class NSP_UpdateProjMilestone implements Queueable {
    // test w/ NSP_OrderTriggerHelperTest (86%)

    private Set<Id> orderIdSet = new Set<Id>();
    private String commenceTrigger = null;

    public NSP_UpdateProjMilestone( Set<Id> projCompletedIdSet ) {
        this.orderIdSet = projCompletedIdSet;
    }

    // update billing target date on billing transaction when project go live is approved.
    public void execute( QueueableContext context ) {
        List<blng__BillingTransaction__c> updateList = new List<blng__BillingTransaction__c>();
        List<blng__BillingTransaction__c> transactionList = [
            SELECT
                Id ,
                blng__Status__c ,
                blng__OverrideBillingTargetDate__c ,
                NSP_Project_Completion_Date__c ,
                NSP_Billing_Commencement_Trigger__c
            FROM blng__BillingTransaction__c
            WHERE NSP_Order_Id__c IN :orderIdSet
        ];
        for ( blng__BillingTransaction__c transacationObj : transactionList ) {
            if ( transacationObj.blng__Status__c == NSP_CPQConstants.BLNG_STATUS_PENDING ) {
                if ( transacationObj.NSP_Billing_Commencement_Trigger__c == NSP_CPQConstants.PROJ_GO_LIVE ) {
                    transacationObj.blng__OverrideBillingTargetDate__c = System.today();
                    updateList.add( transacationObj );
                }
                if ( transacationObj.NSP_Billing_Commencement_Trigger__c == NSP_CPQConstants.PROJ_COMPLETE ) {
                    transacationObj.blng__OverrideBillingTargetDate__c = transacationObj.NSP_Project_Completion_Date__c;
                    updateList.add( transacationObj );
                }
            }
        }
        if ( ( updateList != null ) && !updateList.isEmpty() ) {
            try {
                Database.update( updateList );
            } catch ( Exception e ) {
                NSP_UpdateProjMilestone.handleException( e , 'execute' );
            }
        }
    }

     // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_UpdateProjMilestone.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_UpdateProjMilestone.class.getName() ,
            methodName ,
            e
        );
    }

}
//