public with sharing class SandboxManualStepsController {

    // Method to run post-refresh steps
    @AuraEnabled
    public static void runManualSteps() {
        NSP_PrepSandbox.runManualSteps();
    }

    // Method to import org users
    @AuraEnabled
    public static void runUserImport() {
        NSP_PrepSandbox.runUserImport();
    }

    // Method to run post-import steps
    @AuraEnabled
    public static void runManualSteps2() {
        NSP_PrepSandbox.runManualSteps2();
    }

    // Method to update E2C (Enhanced Email Content) addresses
    @AuraEnabled
    public static void runE2CAddresses() {
        NSP_PrepSandbox.runE2CAddresses();
    }

    @AuraEnabled(cacheable=true)
    public static OrgSettings__c getOrgSettings() {
        return OrgSettings__c.getOrgDefaults();
    }
}