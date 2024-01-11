public with sharing class ApexExceptionLogController {
    // test w/ ApexExceptionLogControllerTest (98%)
    private static final String CLASS_NAME = ' ~ ApexExceptionLogController';
    private static final String APEX_SCRIPT_UNHANDLED = 'Apex script unhandled ';

    public static void insertApexExceptionLogs( List<InboundEmailLog__c> inboundEmailLogs ) {
        String METHOD_NAME = 'insertApexExceptionLogs';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ isEnabled=' + ApexExceptionLogController.isEnabled );
        if ( ApexExceptionLogController.isEnabled ) {
            List<ApexExceptionLog__c> records = new List<ApexExceptionLog__c>();
            if ( ( inboundEmailLogs != null ) && ( inboundEmailLogs.size() > 0 ) ) {
                System.debug( DEBUG_PREFIX + ' ~ inboundEmailLogs.size=' + inboundEmailLogs.size() );
                for ( InboundEmailLog__c inboundEmailLog : inboundEmailLogs ) {
                    // populate ApexExceptionLog__c record...
                    ApexExceptionLog__c record = ApexExceptionLogController.populateApexExceptionLog( inboundEmailLog );
                    // defer dml...
                    if ( record != null ) {
                        records.add( record );
                    }
                }
            }
            // deferred dml...
            if ( ( records != null ) && ( records.size() > 0 ) ) {
                System.debug( DEBUG_PREFIX + ' ~ records.size=' + records.size() );
                insert records;
            }
        }
    }

    //
    //
    //

    private static InboundEmailLogSettings__c settings { // replace with ApexExceptionLogSettings__c
        get {
            if ( settings == null ) {
                settings = InboundEmailLogSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( settings != null ) {
                    local = settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static ApexExceptionLog__c populateApexExceptionLog( InboundEmailLog__c emailLog ) {
        String METHOD_NAME = 'populateApexExceptionLog';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        ApexExceptionLog__c exceptionLog = null;
        if ( ( emailLog != null )
            && String.isNotBlank( emailLog.PlainTextBody__c )
           )
        {
            // apex exception detetion...
            if ( emailLog.PlainTextBody__c.contains( APEX_SCRIPT_UNHANDLED ) ) {
                String apexExceptionBody = emailLog.PlainTextBody__c.substring( emailLog.PlainTextBody__c.indexOf( APEX_SCRIPT_UNHANDLED ) );
                if ( String.isNotBlank( apexExceptionBody ) ) {
                    exceptionLog = new ApexExceptionLog__c();
                    exceptionLog.InboundEmailLog__c = emailLog.Id;
                    exceptionLog.ApexExceptionBody__c = SchemaController.safeText(
                        apexExceptionBody ,
                        sObjectType.ApexExceptionLog__c.Fields.ApexExceptionBody__c
                    );
                    // apex exception parsing...
                    exceptionLog = ApexExceptionLogController.parseApexExceptionBody( exceptionLog );
                }
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ exceptionLog=' + exceptionLog );
        return exceptionLog;
    }

    private static ApexExceptionLog__c parseApexExceptionBody( ApexExceptionLog__c exceptionLog ) {
        String METHOD_NAME = 'parseApexExceptionBody';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        if ( exceptionLog != null ) {
            List<String> apexExceptionBodyChunks = null;
            if ( String.isNotBlank( exceptionLog.ApexExceptionBody__c ) ) {
                String apexExceptionBodyRaw = exceptionLog.ApexExceptionBody__c;
                if ( apexExceptionBodyRaw.contains( 'Source organization: 00D4x000003x74T (null)\n' ) ) {
                    apexExceptionBodyRaw = apexExceptionBodyRaw.replace( 'Source organization: 00D4x000003x74T (null)\n' , '\n' );
                }
                apexExceptionBodyChunks = apexExceptionBodyRaw.split( '\n\n' );
            }
            //
            Boolean isTrigger = False;
            //
            String cause = null;
            String classMethod = null;
            String className = null;
            String message = null;
            String namespace = null;
            Id orgId = null;
            String pageName = null;
            String stackTraceString = null;
            String triggerName = null;
            String triggerOperation = null;
            String typeName = null;
            Id userId = null;
            //
            if ( ( apexExceptionBodyChunks != null ) && ( apexExceptionBodyChunks.size() > 0 ) ) {
                System.debug( DEBUG_PREFIX + ' ~ apexExceptionBodyChunks.size=' + apexExceptionBodyChunks.size() );
                //
                for ( String apexExceptionBodyChunk : apexExceptionBodyChunks ) {
                    apexExceptionBodyChunk = apexExceptionBodyChunk.trim();
                    System.debug( DEBUG_PREFIX + ' ~ apexExceptionBodyChunk=' + apexExceptionBodyChunk );
                    //
                    if ( apexExceptionBodyChunk.startsWith( 'Apex script unhandled ' ) ) {
                        String remainingLine = apexExceptionBodyChunk.substringAfter( 'Apex script unhandled ' );
                        if ( remainingLine.startsWith( 'trigger ' ) ) {
                            isTrigger = True;
                        }
                        SplitUserOrganizationResponse splitResponse = ApexExceptionLogController.splitUserOrganization( apexExceptionBodyChunk );
                        if ( splitResponse != null ) {
                            if ( splitResponse.userId != null ) {
                                userId = splitResponse.userId;
                            }
                            if ( splitResponse.organizationId != null ) {
                                orgId = splitResponse.organizationId;
                            }
                        }
                    } else if ( apexExceptionBodyChunk.startsWith( 'Visualforce Page: ' ) ) {
                        message = apexExceptionBodyChunk;
                        String extractedPageName = ApexExceptionLogController.extractPageName( apexExceptionBodyChunk );
                        if ( String.isNotBlank( extractedPageName ) ) {
                            pageName = extractedPageName;
                            if ( pageName.contains( '__' ) ) {
                                namespace = pageName.substringBefore( '__' );
                                pageName = pageName.substringAfter( '__' );
                            }
                        }
                    } else if ( apexExceptionBodyChunk.startsWith( 'caused by: ' ) ) {
                        cause = apexExceptionBodyChunk.substringAfter( 'caused by: ' );
                        if ( cause.contains( ':' ) ) {
                            typeName = cause.substringBefore( ':' );
                        }
                    }
                }
                System.debug( DEBUG_PREFIX + ' ~ isTrigger=' + isTrigger );
                if ( isTrigger ) {
                    if ( apexExceptionBodyChunks.size() > 1 ) {
                        message = apexExceptionBodyChunks[1];
                        if ( message.contains( ':' ) ) {
                            triggerName = message.substringBefore( ':' );
                            if ( triggerName.contains( '.' ) ) {
                                namespace = triggerName.substringBeforeLast( '.' );
                                triggerName = triggerName.substringAfterLast( '.' );
                            }
                            String remainingMessage = message.substringAfter( ':' );
                            if ( remainingMessage.contains( 'execution of ' ) ) {
                                triggerOperation = remainingMessage.substringAfter( 'execution of ' );
                            } else if ( remainingMessage.contains( ':' ) ) {
                                triggerName = remainingMessage.substringBefore( ':' );
                            }
                        }
                    }
                }
                if ( String.isBlank( triggerName ) && String.isBlank( pageName ) ) {
                    if ( apexExceptionBodyChunks.size() > 1 ) {
                        message = apexExceptionBodyChunks[1];
                    }
                }
                if ( apexExceptionBodyChunks.size() > 3 ) {
                    stackTraceString = apexExceptionBodyChunks[apexExceptionBodyChunks.size()-1];
                }
            }
            if ( String.isNotBlank( stackTraceString ) ) {
                String stackFirstLine = stackTraceString.substringBefore( ':' );
                if ( stackFirstLine.startsWith( 'Class.' ) ) {
                    className = stackFirstLine.substringAfter( 'Class.' );
                    if ( className.contains( '.' ) ) {
                        classMethod = className.subStringAfterLast( '.' );
                        className = className.subStringBeforeLast( '.' );
                    }
                    if ( className.contains( '.' ) ) {
                        namespace = className.subStringBeforeLast( '.' );
                        className = className.subStringAfterLast( '.' );
                    }
                }
            }
            //
            exceptionLog.Cause__c = SchemaController.safeText(
                cause ,
                sObjectType.ApexExceptionLog__c.Fields.Cause__c
            );
            exceptionLog.ClassMethod__c = SchemaController.safeText(
                classMethod ,
                sObjectType.ApexExceptionLog__c.Fields.ClassMethod__c
            );
            exceptionLog.ClassName__c = SchemaController.safeText(
                className ,
                sObjectType.ApexExceptionLog__c.Fields.ClassName__c
            );
            exceptionLog.Message__c = SchemaController.safeText(
                message ,
                sObjectType.ApexExceptionLog__c.Fields.Message__c
            );
            exceptionLog.NamespacePrefix__c = SchemaController.safeText(
                namespace ,
                sObjectType.ApexExceptionLog__c.Fields.NamespacePrefix__c
            );
            exceptionLog.OrganizationId__c = SchemaController.safeText(
                orgId ,
                sObjectType.ApexExceptionLog__c.Fields.OrganizationId__c
            );
            exceptionLog.PageName__c = SchemaController.safeText(
                pageName ,
                sObjectType.ApexExceptionLog__c.Fields.PageName__c
            );
            exceptionLog.StackTrace__c = SchemaController.safeText(
                stackTraceString ,
                sObjectType.ApexExceptionLog__c.Fields.StackTrace__c
            );
            exceptionLog.TriggerName__c = SchemaController.safeText(
                triggerName ,
                sObjectType.ApexExceptionLog__c.Fields.TriggerName__c
            );
            exceptionLog.TriggerOperation__c = SchemaController.safeText(
                triggerOperation ,
                sObjectType.ApexExceptionLog__c.Fields.TriggerOperation__c
            );
            exceptionLog.TypeName__c = SchemaController.safeText(
                typeName ,
                sObjectType.ApexExceptionLog__c.Fields.TypeName__c
            );
            exceptionLog.UserId__c = SchemaController.safeText(
                userId ,
                sObjectType.ApexExceptionLog__c.Fields.UserId__c
            );
        }
        return exceptionLog;
    }

    private static String extractPageName( String input ) {
        String METHOD_NAME = 'splitUserOrganization';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ input=' + input );
        String pageName = null;
        if ( input.startsWith( 'Visualforce Page: ' ) ) {
            pageName = input.substringAfter( 'Visualforce Page: ' );
            if ( pageName.contains( '/' ) ) {
                pageName = pageName.substringAfterLast( '/' );
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ pageName=' + pageName );
        return pageName;        
    }

    private static SplitUserOrganizationResponse splitUserOrganization( String input ) {
        String METHOD_NAME = 'splitUserOrganization';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ input=' + input );
        Id userId = null;
        Id organizationId = null;
        if ( String.isNotBlank( input ) && input.contains( 'user/organization: ' ) ) {
            String userIdOrganizationId = input.substringAfter( 'user/organization: ' ).trim();
            List<String> splitIds = userIdOrganizationId.split( '/' );
            if ( ( splitIds != null ) && ( splitIds.size() == 2 ) ) {
                if ( splitIds[0] InstanceOf Id ) {
                    userId = Id.valueOf( splitIds[0] );
                }
                if ( splitIds[1] InstanceOf Id ) {
                    organizationId = Id.valueOf( splitIds[1] );
                }
            }
        }
        SplitUserOrganizationResponse response = new SplitUserOrganizationResponse();
        response.input = input;
        response.userId = userId;
        response.organizationId = organizationId;
        System.debug( DEBUG_PREFIX + ' ~ response=' + response );
        return response;
    }

    private class SplitUserOrganizationResponse {
        private String input { get; set; }
        private Id userId { get; set; }
        private Id organizationId { get; set; }
    }

}
//