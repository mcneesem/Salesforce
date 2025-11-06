public with sharing class PdsContactController {

    /**
     * Get the Count of PC Contact from SCC:
     * Derives Sub Client Id from NSP_Payroll__c via recordId.
     */
    @AuraEnabled(cacheable=true)
    public static Integer getSCCPCCount(Id recordId) {
        String scId = fetchSubClientId(recordId);
        if (String.isBlank(scId)) return 0;

        return [
            SELECT COUNT()
            FROM NSP_Sub_Client_Contact__c
            WHERE NSP_Sub_Client__c = :scId
              AND NSP_Payroll_Contact__c = true
        ];
    }

    /**
     * Get the Count of HR Contact from SCC:
     * Derives Sub Client Id from NSP_Payroll__c via recordId.
     */
    @AuraEnabled(cacheable=true)
    public static Integer getSCCHRCount(Id recordId) {
        String scId = fetchSubClientId(recordId);
        if (String.isBlank(scId)) return 0;

        return [
            SELECT COUNT()
            FROM NSP_Sub_Client_Contact__c
            WHERE NSP_Sub_Client__c = :scId
              AND NSP_HR_Contact__c = true
        ];
    }

    // Get the Sub Client Id from NSP_Payroll__c
    private static String fetchSubClientId(Id recordId) {
        if (recordId == null) return null;
        NSP_Payroll__c pdsRec = [
            SELECT NSP_Sub_Client_Name__c
            FROM NSP_Payroll__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        return pdsRec.NSP_Sub_Client_Name__c;
    }
}