public with sharing class PortalClientSelector {
    // test w/ PortalClientSelectorTest (86%)

    @AuraEnabled(cacheable=true)
    public static List<Portal_Client__c> getPortalClients() {
        return [
            SELECT Id
            FROM Portal_Client__c
            WHERE (
                Id IN (
                    SELECT Portal_Client__c
                    FROM Portal_Project__c
                    WHERE ( Status__c = 'Active' )
                )
            )
            ORDER BY CreatedDate ASC
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

    @AuraEnabled(cacheable=true)
    public static void logInfo( String className , String methodName , String info ) {
        try {
            if ( String.isNotBlank( className )
                && String.isNotBlank( methodName )
                && String.isNotBlank( info )
                && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() )
                )
            {
                PortalClientSelector.logInfoFuture(
                    className + '.' + methodName ,
                    info
                );
            }
        } catch ( Exception e ) {
            System.debug( ' ~ PortalClientSelector ~ e=' + e );
        }
    }

    @future
    private static void logInfoFuture( String methodName , String info ) {
        try {
            if ( String.isNotBlank( methodName )
                && String.isNotBlank( info )
                )
            {
                NSP_ErrorLogHandler.logInfo(
                    PortalClientSelector.class.getName() + '.logInfoFuture' ,
                    methodName ,
                    info
                );
            }
        } catch ( Exception e ) {
            PortalClientSelector.handleException( e , 'logInfoFuture' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            PortalClientSelector.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            PortalClientSelector.class.getName() ,
            methodName ,
            e
        );
    }

}
//