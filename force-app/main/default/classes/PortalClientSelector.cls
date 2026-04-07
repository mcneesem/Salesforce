public with sharing class PortalClientSelector {
    // test w/ PortalClientSelectorTest (87%)

    @AuraEnabled(cacheable=true)
    public static List<Portal_Client__c> getPortalClients() {
        return [
            SELECT Id
            FROM Portal_Client__c
        ];
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isCommunityContext() {
        Boolean response = ( Site.getSiteId() != null );
        Map<String,String> currentSession = null;
        if ( !Test.isRunningTest() ) {
            // Prevent UnexpectedException: Current session unavailable
            currentSession = Auth.SessionManagement.getCurrentSession();
        }
        if ( ( currentSession != null ) && currentSession.containsKey( 'SessionType' ) ) {
            // SessionType
            // ~ 'ChatterNetworks' is-a Community
            // ~ 'LivePreview' is-a Community Builder
            response = ( response || ( currentSession.get( 'SessionType' ) == 'ChatterNetworks' ) ); // Community
        }
        return response;
    }

    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getPortalLinks( String linkedEntityId ) {
        List<ContentDocumentLink> response = new List<ContentDocumentLink>();
        if ( String.isNotBlank( linkedEntityId ) ) {
            response = [
                SELECT Id
                FROM ContentDocumentLink
                WHERE ( LinkedEntityId = :linkedEntityId )
                ORDER BY ContentDocument.LastModifiedDate DESC
            ];
        }
        return response;
    }

}
//