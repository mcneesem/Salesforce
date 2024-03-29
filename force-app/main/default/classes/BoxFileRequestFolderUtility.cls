/**
* @File Name            :   BoxFileRequestFolderUtility.cls
* @Description          :   Creates a Box Folder for SF record, creates an internal subfolder.  A collaboration is created on the internal subfolder using the email address assoicated with the opportunity's OpportunityContactRole.  
* @Author               :   Colin Hancock
* @Group                :   Box Consulting
* @Last Modified By     :   Colin Hancock
* @Last Modified On     :   9/27/23
* @Last Update          :   Init
**/

public class BoxFileRequestFolderUtility implements Queueable, Database.AllowsCallouts {
    // test w/ BoxFileRequestFolderUtilityTests (100%)

    private String opportunityRecordId;

    public BoxFileRequestFolderUtility(id recordId) {
        System.debug( ' ~ BoxFileRequestFolderUtility ~ recordId=' + recordId );
        this.opportunityRecordId = recordId;
    }

    public void execute(QueueableContext context) {
        try {
            if ( BoxFileRequestFolderUtility.isEnabled ) {
                System.debug('BoxFileRequestUtility running: ' + opportunityRecordId);

                //create opportunity folder for opportunityRecordId
                box.Toolkit boxToolkit = new box.Toolkit();
                //define collaboration level
                box.Toolkit.CollaborationType collabType = box.Toolkit.CollaborationType.VIEWERUPLOADER;

                System.debug( ' ~ BoxFileRequestFolderUtility.boxTemplateFolderId=' + BoxFileRequestFolderUtility.boxTemplateFolderId );
                String opportunityFolderId = boxToolkit.createFolderForRecordIdFromTemplate(
                    opportunityRecordId,
                    BoxFileRequestFolderUtility.boxTemplateFolderId,
                    null,
                    true
                );
                System.debug('New opportunityFolderId: ' + opportunityFolderId);

                if (opportunityFolderId == null) {
                    System.debug('Error creating opportunity folder: ' + boxToolkit.mostRecentError);
                }

                //Create child folder for File Request
                System.debug( ' ~ BoxFileRequestFolderUtility.boxFileRequestFolderName=' + BoxFileRequestFolderUtility.boxFileRequestFolderName );
                String fileRequestFolderId = boxToolkit.createFolder(
                    BoxFileRequestFolderUtility.boxFileRequestFolderName,
                    opportunityFolderId,
                    null
                );
                System.debug('New fileRequestFolderId: ' + fileRequestFolderId);

                if (fileRequestFolderId == null) {
                    System.debug('Error creating file request link folder: ' + boxToolkit.mostRecentError);
                }

                //get OpportunityContactRole.IsPrimary associated with Opportunity
                List <OpportunityContactRole> opportunityContactRoles = [
                    SELECT ContactId, Contact.Email, Role, OpportunityId, IsPrimary
                    FROM OpportunityContactRole
                    WHERE (
                        ( OpportunityId = :opportunityRecordId )
                        AND ( ContactId != null )
                        AND ( IsPrimary = True )
                    )
                ];
                System.debug('Associated opportunityContactRoles: ' + opportunityContactRoles);

                System.debug( ' ~ BoxFileRequestFolderUtility.boxApiEndpoint=' + BoxFileRequestFolderUtility.boxApiEndpoint );
                for (OpportunityContactRole opportunityContactRole : opportunityContactRoles) {
                    System.debug('opportunityContactRole: ' + opportunityContactRole);
                    if (!String.isBlank(opportunityContactRole.Contact.Email)) {
                        //Collaborate OpportunityContactRole.IsPrimary email
                        String collaboratorEmail = opportunityContactRole.Contact.Email;
                        System.debug('Collaborator Email: ' + collaboratorEmail);
                        //Collaborate OpportunityContactRole.IsPrimary email manually
                        HttpRequest request = new HttpRequest();
                        request.setMethod('POST');
                        request.setEndpoint( BoxFileRequestFolderUtility.boxApiEndpoint );
                        request.setBody(
                            '{'
                            +'"item":{"type":"folder","id":' + '"' + fileRequestFolderId + '"' +'},'
                            +'"accessible_by":{"type":"user","login":'+ '"' + collaboratorEmail + '"' + '},'
                            +'"role":"viewer uploader"'
                            +'}'
                        );
                        System.debug('Request: ' + request);
                        HttpResponse response = boxToolkit.sendRequest(request);
                        System.debug('Response: ' + response);
                    }
                }
                boxToolKit.commitChanges();
            }
        } catch(Exception ex) {
            NSP_ErrorLogHandler.logSaveException('BoxFileRequestFolderUtility', 'execute', ex.getMessage()); 
        }
    }

    //
    // attributes controlled by Custom Settings...
    //

    public static BoxFileRequest__c settings {
        public get {
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
                    local = BoxFileRequestFolderUtility.settings.IsEnabled__c; // True
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    public static String boxTemplateFolderId {
        public get {
            if ( boxTemplateFolderId == null ) {
                String local = null;
                if ( BoxFileRequestFolderUtility.settings != null ) {
                    local = BoxFileRequestFolderUtility.settings.BoxTemplateFolderId__c; // '225207143235'
                }
                boxTemplateFolderId = local;
            }
            return boxTemplateFolderId;
        }
        private set;
    }

    public static String boxApiEndpoint {
        public get {
            if ( boxApiEndpoint == null ) {
                String local = null;
                if ( BoxFileRequestFolderUtility.settings != null ) {
                    local = BoxFileRequestFolderUtility.settings.BoxApiEndpoint__c; // 'https://api.box.com/2.0/collaborations/'
                }
                boxApiEndpoint = local;
            }
            return boxApiEndpoint;
        }
        private set;
    }

    public static String boxFileRequestFolderName {
        public get {
            if ( boxFileRequestFolderName == null ) {
                String local = null;
                if ( BoxFileRequestFolderUtility.settings != null ) {
                    local = BoxFileRequestFolderUtility.settings.BoxFileRequestFolderName__c; // 'Insperity File Request'
                }
                boxFileRequestFolderName = local;
            }
            return boxFileRequestFolderName;
        }
        private set;
    }

}
//