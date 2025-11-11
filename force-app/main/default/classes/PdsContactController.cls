public with sharing class PdsContactController {
    // test w/ NSP_PayrollTriggerHelperTest (83%)
    /* AZD-502310 : Class used to get the count of PC and HR Contacts from SCC
     * Refer : LWC Component to Show/Hide the Flow Compoent on PDS Page Layout
     * Get the Count of PC Contact from SCC:
     * Derives Sub Client Id from NSP_Payroll__c via recordId.
     */
    @AuraEnabled(cacheable=true)
    public static Integer getSCCPCCount(Id recordId) {
        Integer pcCount = 0;
        String scId = PdsContactController.fetchSubClientId(recordId);
        if (!String.isBlank(scId)) {
            pcCount = [
                SELECT COUNT()
                FROM NSP_Sub_Client_Contact__c
                WHERE NSP_Sub_Client__c = :scId
                AND NSP_Payroll_Contact__c = true
            ];
        }
        return pcCount;
    }

    /**
     * Get the Count of HR Contact from SCC:
     * Derives Sub Client Id from NSP_Payroll__c via recordId.
     */
    @AuraEnabled(cacheable=true)
    public static Integer getSCCHRCount(Id recordId) {
        Integer hrCount = 0;
        String scId = PdsContactController.fetchSubClientId(recordId);
        if (!String.isBlank(scId)) {
            hrCount = [
                SELECT COUNT()
                FROM NSP_Sub_Client_Contact__c
                WHERE NSP_Sub_Client__c = :scId
                AND NSP_HR_Contact__c = true
            ];
        }
        return hrCount;
    }

    // Get the Sub Client Id from NSP_Payroll__c  , Added List to Avoid Query Exception  
    private static String fetchSubClientId(Id recordId) {
        String subClientId = null;
        if (recordId != null) {
            List<NSP_Payroll__c> pdsList = [
                SELECT NSP_Sub_Client_Name__c
                FROM NSP_Payroll__c
                WHERE Id = :recordId
                LIMIT 1
            ];

            if (!pdsList.isEmpty()) {
                subClientId = pdsList[0].NSP_Sub_Client_Name__c;
            }
        }
        return subClientId;
    }

}