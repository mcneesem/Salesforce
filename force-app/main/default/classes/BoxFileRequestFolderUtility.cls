public with sharing class BoxFileRequestFolderUtility implements Queueable, Database.AllowsCallouts {
    // test w/ BoxFileRequestFolderUtilityTests, NSP_OpportunityTriggerHelperTest (XX%)
    // test w/ BoxFileRequestFolderUtilityTests (XX%)
    // test w/ NSP_OpportunityTriggerHelperTest (XX%)

    public static void enqueueJob( Id recordId ) {
        if ( BoxFileRequestFolderUtility.isEnabled
            && ( recordId != null )
            && !System.isQueueable() // prevent AsyncExceptions...
            && ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) // prevent LimitExceptions...
            )
        {
            System.enqueueJob( new BoxFileRequestFolderUtility( recordId ) );
        }
    }

    //
    //
    //

    private String opportunityRecordId;

    private BoxFileRequestFolderUtility( Id recordId ) {
        this.opportunityRecordId = recordId;
    }

    public void execute( QueueableContext context ) {
        try {
            if ( BoxFileRequestFolderUtility.isEnabled ) {
                //create opportunity folder for opportunityRecordId
                box.Toolkit boxToolkit = new box.Toolkit();
                //define collaboration level
                box.Toolkit.CollaborationType collabType = box.Toolkit.CollaborationType.VIEWERUPLOADER;
                String opportunityFolderId = boxToolkit.createFolderForRecordIdFromTemplate(
                    opportunityRecordId ,
                    BoxFileRequestFolderUtility.boxTemplateFolderId ,
                    null ,
                    true
                );
                //Create child folder for File Request
                String fileRequestFolderId = boxToolkit.createFolder(
                    BoxFileRequestFolderUtility.boxFileRequestFolderName ,
                    opportunityFolderId ,
                    null
                );
                //get OpportunityContactRole.IsPrimary associated with Opportunity
                List<OpportunityContactRole> opportunityContactRoles = [
                    SELECT
                        ContactId ,
                        Contact.Email ,
                        Role ,
                        OpportunityId ,
                        IsPrimary
                    FROM OpportunityContactRole
                    WHERE (
                        ( OpportunityId = :opportunityRecordId )
                        AND ( ContactId != null )
                        AND ( IsPrimary = True )
                    )
                ];
                for ( OpportunityContactRole opportunityContactRole : opportunityContactRoles ) {
                    if ( String.isNotBlank( opportunityContactRole.Contact.Email ) ) {
                        //Collaborate OpportunityContactRole.IsPrimary email
                        String collaboratorEmail = opportunityContactRole.Contact.Email;
                        //Collaborate OpportunityContactRole.IsPrimary email manually
                        HttpRequest request = new HttpRequest();
                        request.setMethod( 'POST' );
                        request.setEndpoint( BoxFileRequestFolderUtility.boxApiEndpoint );
                        request.setBody(
                            '{'
                            +'"item":{"type":"folder","id":' + '"' + fileRequestFolderId + '"' +'},'
                            +'"accessible_by":{"type":"user","login":'+ '"' + collaboratorEmail + '"' + '},'
                            +'"role":"viewer uploader"'
                            +'}'
                        );
                        HttpResponse response = boxToolkit.sendRequest( request );
                    }
                }
                boxToolKit.commitChanges();
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                BoxFileRequestFolderUtility.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    //
    // attributes controlled by Custom Settings...
    //

    private static BoxFileRequest__c settings {
        private get {
            if ( settings == null ) {
                settings = BoxFileRequest__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    public static Boolean isEnabled {
        public get {
            if ( isEnabled == null ) {
                Boolean local = False;
                if ( BoxFileRequestFolderUtility.settings != null ) {
                    local = BoxFileRequestFolderUtility.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static String boxTemplateFolderId {
        private get {
            if ( boxTemplateFolderId == null ) {
                String local = null;
                if ( BoxFileRequestFolderUtility.settings != null ) {
                    local = BoxFileRequestFolderUtility.settings.BoxTemplateFolderId__c;
                }
                boxTemplateFolderId = local;
            }
            return boxTemplateFolderId;
        }
        private set;
    }

    private static String boxApiEndpoint {
        private get {
            if ( boxApiEndpoint == null ) {
                String local = null;
                if ( BoxFileRequestFolderUtility.settings != null ) {
                    local = BoxFileRequestFolderUtility.settings.BoxApiEndpoint__c;
                }
                boxApiEndpoint = local;
            }
            return boxApiEndpoint;
        }
        private set;
    }

    private static String boxFileRequestFolderName {
        private get {
            if ( boxFileRequestFolderName == null ) {
                String local = null;
                if ( BoxFileRequestFolderUtility.settings != null ) {
                    local = BoxFileRequestFolderUtility.settings.BoxFileRequestFolderName__c;
                }
                boxFileRequestFolderName = local;
            }
            return boxFileRequestFolderName;
        }
        private set;
    }

}
//
