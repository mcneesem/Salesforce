public with sharing class TransferBillingAccount {
    // test w/ TransferBillingAccountTest (??%)

    @InvocableMethod(label='Transfer Billing Account' description='Executes the batch job to transfer the Billing Account.')
    public static void transfer( List<FlowInputs> requests ) {
        if ( ( requests != null ) && !requests.isEmpty() ) {
            Database.executeBatch(
                new InsperityWOBillingAccountTransferBatch(
                    requests[0].PreviousMonthAccountName ,
                    requests[0].CurrentMonthAccountId
                ) ,
                TransferBillingAccount.batchSize
            );
        }
    }

    public class FlowInputs {
        @InvocableVariable(label='Previous Month Account Name' required=false) 
        public String PreviousMonthAccountName;
        @InvocableVariable(label='Current Month Account Id' required=true)
        public String CurrentMonthAccountId;
    }

    private static TransferBillingAccountSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = TransferBillingAccountSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( TransferBillingAccount.settings != null )
                    && ( TransferBillingAccount.settings.BatchSize__c != null )
                    )
                {
                    local = TransferBillingAccount.settings.BatchSize__c.intValue();
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