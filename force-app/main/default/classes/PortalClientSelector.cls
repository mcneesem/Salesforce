public with sharing class PortalClientSelector {
    // test w/ PortalClientSelectorTest (100%)

    @AuraEnabled(cacheable=true)
    public static List<Portal_Client__c> getPortalClients() {
        return [
            SELECT Id
            FROM Portal_Client__c
        ];
    }
}
//