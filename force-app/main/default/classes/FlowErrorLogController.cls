public with sharing class FlowErrorLogController {
    // test w/ FlowErrorLogControllerTest (100%)
    private static final String CLASS_NAME = ' ~ FlowErrorLogController';
    private static final String ERROR_OCCURED_DURING_FLOW = 'An error occurred with your ';
    private static final String ERROR_ELEMENT = 'Error element ';

    public static void insertFlowErrorLogs( List<InboundEmailLog__c> inboundEmailLogs ) {
        String METHOD_NAME = 'insertFlowErrorLogs';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        System.debug( DEBUG_PREFIX + ' ~ isEnabled=' + FlowErrorLogController.isEnabled );
        if ( FlowErrorLogController.isEnabled ) {
            List<FlowErrorLog__c> records = new List<FlowErrorLog__c>();
            if ( ( inboundEmailLogs != null ) && ( inboundEmailLogs.size() > 0 ) ) {
                System.debug( DEBUG_PREFIX + ' ~ inboundEmailLogs.size=' + inboundEmailLogs.size() );
                for ( InboundEmailLog__c inboundEmailLog : inboundEmailLogs ) {
                    // populate FlowErrorLog__c record...
                    FlowErrorLog__c record = FlowErrorLogController.populateFlowErrorLog( inboundEmailLog );
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

    private static InboundEmailLogSettings__c settings { // replace with FlowErrorLogSettings__c
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

    private static FlowErrorLog__c populateFlowErrorLog( InboundEmailLog__c emailLog ) {
        String METHOD_NAME = 'populateFlowErrorLog';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        FlowErrorLog__c errorLog = null;
        if ( ( emailLog != null )
            && String.isNotBlank( emailLog.Subject__c )
            && String.isNotBlank( emailLog.HtmlBody__c )
           )
        {
            // flow error detetion...
            if ( emailLog.Subject__c.contains( ERROR_OCCURED_DURING_FLOW )
                && emailLog.HtmlBody__c.contains( ERROR_ELEMENT )
               )
            {
                String flowErrorBody = emailLog.HtmlBody__c;
                if ( String.isNotBlank( flowErrorBody ) ) {
                    errorLog = new FlowErrorLog__c();
                    errorLog.InboundEmailLog__c = emailLog.Id;
                    errorLog.FlowErrorBody__c = SchemaController.safeText(
                        flowErrorBody ,
                        sObjectType.FlowErrorLog__c.Fields.FlowErrorBody__c
                    );
                    // flow error parsing...
                    errorLog = FlowErrorLogController.parseFlowErrorBody( errorLog );
                }
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ errorLog=' + errorLog );
        return errorLog;
    }

    private static FlowErrorLog__c parseFlowErrorBody( FlowErrorLog__c errorLog ) {
        String METHOD_NAME = 'parseFlowErrorBody';
        String DEBUG_PREFIX = CLASS_NAME + '.' + METHOD_NAME;
        if ( errorLog != null ) {
            List<String> flowErrorBodyLines = null;
            if ( String.isNotBlank( errorLog.FlowErrorBody__c ) ) {
                flowErrorBodyLines = errorLog.FlowErrorBody__c.split( '\n' );
            }
            //
            String apiName = null;
            Integer apiVersion = null;
            String duration = null;
            String errorElement = null;
            String errorMessage = null;
            String interviewGuid = null;
            String interviewLabel = null;
            String processType = null;
            String startTime = null;
            Integer versionNumber = null;
            Id orgId = null;
            Id userId = null;
            //
            if ( ( flowErrorBodyLines != null ) && ( flowErrorBodyLines.size() > 0 ) ) {
                System.debug( DEBUG_PREFIX + ' ~ flowErrorBodyLines.size=' + flowErrorBodyLines.size() );
                Integer lineIndex = 0;
                Integer errorMessageIndex = null;
                for ( String flowErrorBodyLine : flowErrorBodyLines ) {
                    flowErrorBodyLine = flowErrorBodyLine.stripHtmlTags().trim(); ////
                    System.debug( DEBUG_PREFIX + ' ~ flowErrorBodyLine=' + flowErrorBodyLine );
                    //
                    if ( ( apiName == null ) && flowErrorBodyLine.startsWith( 'Flow API Name: ' ) ) {
                        // Flow API Name: XXXXX_XXXXX_XXXXX
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Flow API Name: ' ) ) {
                            apiName = input.substringAfter( 'Flow API Name: ' );
                        }
                    }
                    if ( ( apiVersion == null ) && flowErrorBodyLine.startsWith( 'API Version for Running the Flow: ' ) ) {
                        // API Version for Running the Flow: ##
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'API Version for Running the Flow: ' ) ) {
                            String apiVersionValue = input.substringAfter( 'API Version for Running the Flow: ' );
                            if ( String.isNotBlank( apiVersionValue ) && apiVersionValue.isNumeric() ) {
                                apiVersion = Integer.valueOf( apiVersionValue );
                            }
                        }
                    }
                    if ( ( duration == null ) && flowErrorBodyLine.startsWith( 'Duration: ' ) ) {
                        // Duration: # seconds
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Duration: ' ) ) {
                            duration = input.substringAfter( 'Duration: ' );
                        }
                    }
                    if ( ( errorElement == null ) && flowErrorBodyLine.startsWith( 'Error element ' ) ) {
                        // Error element XXXXX_XXXXX_XXXXX (FlowXXXXX).
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Error element ' ) && input.contains( ').' ) ) {
                            errorElement = input.substringAfter( 'Error element ' ).substringBefore( '.' );
                            if ( errorMessageIndex == null ) {
                                errorMessageIndex = ( lineIndex + 1 );
                                System.debug( DEBUG_PREFIX + ' ~ errorMessageIndex=' + errorMessageIndex );
                            }
                        }
                    }
                    if ( ( interviewGuid == null ) && flowErrorBodyLine.startsWith( 'Interview GUID: ' ) ) {
                        // Interview GUID: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-XXXX
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Interview GUID: ' ) ) {
                            interviewGuid = input.substringAfter( 'Interview GUID: ' );
                        }
                    }
                    if ( ( interviewLabel == null ) && flowErrorBodyLine.startsWith( 'Interview Label: ' ) ) {
                        // Interview Label: XXXXX XXXXX XXXXX MM/DD/YYYY HH:MM XM
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Interview Label: ' ) ) {
                            interviewLabel = input.substringAfter( 'Interview Label: ' );
                        }
                    }
                    if ( ( orgId == null ) && flowErrorBodyLine.startsWith( 'Org: ' ) ) {
                        // Org: XXXXX (00DXXX000XXXXXX)
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Org: ' ) && input.contains( '(' ) && input.contains( ')' ) ) {
                            String orgIdValue = input.substringAfter( 'Org: ' ).substringAfter( '(' ).substringBefore( ')' );
                            if ( orgIdValue InstanceOf Id ) {
                                orgId = Id.valueOf( orgIdValue );
                            }
                        }
                    }
                    if ( ( processType == null ) && flowErrorBodyLine.startsWith( 'Type: ' ) ) {
                        // Type: Screen Flow
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Type: ' ) ) {
                            processType = input.substringAfter( 'Type: ' );
                        }
                    }
                    if ( ( startTime == null ) && flowErrorBodyLine.startsWith( 'Start time: ' ) ) {
                        // Start time: MM/DD/YYYY HH:MM XM
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Start time: ' ) ) {
                            startTime = input.substringAfter( 'Start time: ' );
                        }
                    }
                    if ( ( userId == null ) && flowErrorBodyLine.startsWith( 'Current User: ' ) ) {
                        // Current User: XXXXX XXXXX (005XXX000XXXXXX)
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Current User: ' ) && input.contains( '(' ) && input.contains( ')' ) ) {
                            String userIdValue = input.substringAfter( 'Current User: ' ).substringAfter( '(' ).substringBefore( ')' );
                            if ( userIdValue InstanceOf Id ) {
                                userId = Id.valueOf( userIdValue );
                            }
                        }
                    }
                    if ( ( versionNumber == null ) && flowErrorBodyLine.startsWith( 'Version: ' ) ) {
                        // Version: ##
                        String input = flowErrorBodyLine;
                        if ( String.isNotBlank( input ) && input.contains( 'Version: ' ) ) {
                            String versionNumberValue = input.substringAfter( 'Version: ' );
                            if ( String.isNotBlank( versionNumberValue ) && versionNumberValue.isNumeric() ) {
                                versionNumber = Integer.valueOf( versionNumberValue );
                            }
                        }
                    }
                    lineIndex++;
                }
                //
                System.debug( DEBUG_PREFIX + ' ~ errorMessageIndex=' + errorMessageIndex );
                //
                if ( ( errorMessageIndex != null ) && ( flowErrorBodyLines != null ) && ( flowErrorBodyLines.size() > errorMessageIndex ) ) {
                    String errorMessageLine = flowErrorBodyLines[errorMessageIndex];
                    if ( ( errorMessage == null ) && String.isNotBlank( errorMessageLine ) ) {
                        // The flow failed to access the value for XXXXX.XXXXX because it hasn't been set or assigned.
                        String input = errorMessageLine.stripHtmlTags().trim();
                        if ( String.isNotBlank( input ) ) {
                            errorMessage = input;
                        }
                        // You can look up ExceptionCode values in the <a>SOAP API Developer Guide</a>.
                        if ( String.isNotBlank( errorMessage ) && errorMessage.contains( 'You can look up ExceptionCode' ) ) {
                            errorMessage = errorMessage.substringBefore( 'You can look up ExceptionCode' );
                            if ( String.isNotBlank( errorMessage ) ) {
                                errorMessage = errorMessage.trim();
                            }
                            if ( String.isNotBlank( errorMessage ) && errorMessage.endsWith( '..' ) ) {
                                errorMessage = errorMessage.removeEnd( '.' );
                            }
                        }
                    }
                }
            }
            //
            errorLog.ApiName__c = SchemaController.safeText(
                apiName ,
                sObjectType.FlowErrorLog__c.Fields.ApiName__c
            );
            errorLog.ApiVersion__c = SchemaController.safeInteger(
                apiVersion ,
                sObjectType.FlowErrorLog__c.Fields.ApiVersion__c
            );
            errorLog.Duration__c = SchemaController.safeText(
                duration ,
                sObjectType.FlowErrorLog__c.Fields.Duration__c
            );
            errorLog.ErrorElement__c = SchemaController.safeText(
                errorElement ,
                sObjectType.FlowErrorLog__c.Fields.ErrorElement__c
            );
            errorLog.ErrorMessage__c = SchemaController.safeText(
                errorMessage ,
                sObjectType.FlowErrorLog__c.Fields.ErrorMessage__c
            );
            errorLog.InterviewGuid__c = SchemaController.safeText(
                interviewGuid ,
                sObjectType.FlowErrorLog__c.Fields.InterviewGuid__c
            );
            errorLog.InterviewLabel__c = SchemaController.safeText(
                interviewLabel ,
                sObjectType.FlowErrorLog__c.Fields.InterviewLabel__c
            );
            errorLog.OrganizationId__c = SchemaController.safeText(
                orgId ,
                sObjectType.FlowErrorLog__c.Fields.OrganizationId__c
            );
            errorLog.ProcessType__c = SchemaController.safeText(
                processType ,
                sObjectType.FlowErrorLog__c.Fields.ProcessType__c
            );
            errorLog.StartTime__c = SchemaController.safeText(
                startTime ,
                sObjectType.FlowErrorLog__c.Fields.StartTime__c
            );
            errorLog.UserId__c = SchemaController.safeText(
                userId ,
                sObjectType.FlowErrorLog__c.Fields.UserId__c
            );
            errorLog.VersionNumber__c = SchemaController.safeInteger(
                versionNumber ,
                sObjectType.FlowErrorLog__c.Fields.VersionNumber__c
            );
        }
        return errorLog;
    }

}
//