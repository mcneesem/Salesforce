global with sharing class CLMDocumentRequest {
    // test w/ SpringCMTests (78%)

    global CLMDocumentRequest( String documentId , String documentPath , SpringCMService svc , String apiURL ) {
        this.pid = documentId;
        this.ppath = documentPath;
        this.scmsvc = svc;
        this.aURL = apiURL;
    }

    global CLMDocumentRequest( CLMDocument document , SpringCMService svc ) {
        this.pdocument = document;
        this.pid = svc.getIDfromHref( document.Href );
        this.scmsvc = svc;
    }

    private String pid;
    private String ppath;
    private SpringCMService scmsvc;
    private String pdc;
    private String pav;
    private String aURL;
    private CLMDocument pdocument;
    private Boolean pexpandParentFolder;
    private Boolean pexpandDocuments;
    private Boolean pexpandFolders;
    private Boolean pexpandPath;
    private Boolean pexpandEosParentInfo;
    private Boolean pexpandEosInfo;
    private Boolean pexpandShareLinks;
    private Boolean pexpandAttributeGroups;
    private Boolean pexpandSecurity;
    private Boolean pexpandVersions;
    private Boolean pexpandLock;
    private Boolean pexpandDocumentProcessTrackingActivities;
    private Boolean pexpandHistoryItems;

    global Boolean getExpandParentFolder() {
        return this.pexpandParentFolder;
    }

    global void setExpandParentFolder( Boolean value ) {
        if ( this.pexpandParentFolder != value ) {
            this.pdocument = null;
        }
        this.pexpandParentFolder = value;
    }

    global Boolean getExpandPath() {
        return this.pexpandPath;
    }

    global void setExpandPath( Boolean value ) {
        if ( this.pexpandPath != value ) {
            this.pdocument = null;
        }
        this.pexpandPath = value;
    }

    global Boolean getExpandEosParentInfo() { return pexpandEosParentInfo;}
    global void setExpandEosParentInfo(Boolean value) { if (pexpandEosParentInfo != value) { this.pdocument = null; } pexpandEosParentInfo = value; }

    global Boolean getExpandShareLinks() {return pexpandShareLinks;}
    global void setExpandShareLinks(Boolean value) { if (pexpandShareLinks != value) { this.pdocument = null; } pexpandShareLinks = value; }

    global Boolean getExpandAttributeGroups() {return pexpandAttributeGroups;}
    global void setExpandAttributeGroups(Boolean value) { if (pexpandAttributeGroups != value) { this.pdocument = null; } pexpandAttributeGroups = value; }

    global Boolean getExpandHistoryItems() {return pexpandHistoryItems;}
    global void setExpandHistoryItems(Boolean value){ if (pexpandHistoryItems != value) { this.pdocument = null; } pexpandHistoryItems = value; }

    global Boolean getExpandVersions() {return pexpandVersions;}
    global void setExpandVersions(Boolean value){ if (pexpandVersions != value) { this.pdocument = null; } pexpandVersions = value; }

    global Boolean getExpandLock() {return pexpandLock;}
    global void setExpandLock(Boolean value){ if (pexpandLock != value) { this.pdocument = null; } pexpandLock = value; }

    global Boolean getExpandDocumentProcessTrackingActivities() {return pexpandDocumentProcessTrackingActivities;}
    global void setExpandDocumentProcessTrackingActivities(Boolean value){ if (pexpandDocumentProcessTrackingActivities != value) { pdocument = null; } pexpandDocumentProcessTrackingActivities = value; }

    global CLMDocument getDocument() {
        if ( this.pdocument == null ) {
            this.result();
        }
        return this.pdocument;
    }

    private CLMDocument result() {
        try {
            if ( this.pdocument == null ) {
                if ( !String.isEmpty( this.ppath ) ) {
                    String js = this.scmsvc.requestor.Get(
                        this.aURL + '/documents?path=' + EncodingUtil.urlEncode( this.ppath , 'UTF-8' ) + '&' + this.expandDocument() ,
                        new Map<String,String>()
                    );
                    if ( String.isNotBlank( js ) ) {
                        this.pdocument= (CLMDocument)JSON.deserialize( js , CLMDocument.class );
                    }
                }
                if ( this.pid != null ) {
                    String jsi =  this.scmsvc.requestor.Get(
                        this.aURL + '/documents/' + this.pid + '?' + this.expandDocument() ,
                        new Map<String,String>()
                    );
                    if ( String.isNotBlank( jsi ) ) {
                        this.pdocument = (CLMDocument)JSON.deserialize( jsi , CLMDocument.class );
                    }
                }
            }
        } catch ( Exception e ) {
            System.debug( ' ~ CATCH ~ e=' + e );
        }
        return this.pdocument;
    }

    global Blob downloadDocument( String acceptType ) {
        return this.scmsvc.requestor.GetBlob(
            this.result().DownloadDocumentHref ,
            new Map<String,String>{ 'Accept' => acceptType } ,
            0
        );
    }

    private String expandDocument() {
        List<String> expandString = new List<String>();
        if ( this.pexpandParentFolder == true ) {
            expandString.add( 'ParentFolder' );
        }
        if ( this.pexpandHistoryItems == true ) {
            expandString.add( 'HistoryItems' );
        }
        if ( this.pexpandLock == true ) {
            expandString.add( 'Lock' );
        }
        if ( this.pexpandPath == true ) {
            expandString.add( 'Path' );
        }
        if ( this.pexpandEosParentInfo == true ) {
            expandString.add( 'EosParentInfo' );
        }
        if ( this.pexpandDocumentProcessTrackingActivities == true ) {
            expandString.add( 'DocumentProcessTrackingActivities' );
        }
        if ( this.pexpandShareLinks == true ) {
            expandString.add( 'ShareLinks' );
        }
        if ( this.pexpandAttributeGroups == true ) {
            expandString.add( 'AttributeGroups' );
        }
        if ( this.pexpandVersions == true ) {
            expandString.add( 'Versions' );
        }
        String response = '';
        if ( expandString.size() > 0 ) {
            response = 'expand=' + String.join( expandString , ',' );
        }
        return response;
    }

}
//