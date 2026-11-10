// intentionally `without sharing` to preserve default sharing at api version 55...
public without sharing class NSP_PDSRecordManagerController {
    // test w/ NSP_PDSRecordManagerController_Test (82%)

    public Id recordId { get; set; }

    public NSP_PDSRecordManagerController( ApexPages.StandardSetController sc ) {
        recordId  = ApexPages.currentPage().getParameters().get( 'id' );
    }

    @AuraEnabled
    public static String getPDSRecordsForSubClient( String recordId ) {
        try {
            List<NSP_Payroll__c> payrollDetails = [
                SELECT Id
                FROM NSP_Payroll__c
                WHERE ( NSP_Sub_Client_Name__c = :recordId )
            ];
            if ( ( payrollDetails != null ) && !payrollDetails.isEmpty() ) {
                return 'PDS Exists';
            }
            return NSP_PDSRecordManagerController.createNewPayrollRecord( recordId );
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
    }

    private static String createNewPayrollRecord( String recordId ) {
        String payrollId = null;
        try {
            List<NSP_Sub_Client__c> existingSubClients = [
                SELECT Id , NSP_Sub_Client__c
                FROM NSP_Sub_Client__c
                WHERE Id =:recordId
            ];
            NSP_Sub_Client__c existingSubClient = null;
            if( !existingSubClients.isEmpty() ){
                existingSubClient = existingSubClients[0];
            }
            if ( ( existingSubClient != null )
                && Schema.sObjectType.NSP_Payroll__c.isCreateable()
                )
            {
                NSP_Payroll__c newPayroll = new NSP_Payroll__c();
                newPayroll.NSP_Sub_Client_Name__c = recordId;
                newPayroll.NSP_Sub_Client__c = existingSubClient.NSP_Sub_Client__c;
                insert newPayroll; 
                payrollId = newPayroll.Id;
            }
        } catch ( Exception e ) {
            throw new AuraHandledException( e.getMessage() );
        }
        return payrollId;
    }

    @AuraEnabled
    public static String getUpdatedSubClient( String recordId ) {
        List<NSP_Payroll__c> records = [
            SELECT Id , LastModifiedBy.Profile.Name
            FROM NSP_Payroll__c
            WHERE ( NSP_Sub_Client_Name__c = :recordId )
        ];
        String response = null;
        if ( ( records != null ) && !records.isEmpty() ) {
            response = records[0].LastModifiedBy.Profile.Name;
        }
        return response;
    }

}
//
