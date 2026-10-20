global with sharing class CLMFolderRequest {
    // test w/ SpringCMTests (??%)

    global CLMFolderRequest(String folderId,String folderPath,String eosObjType,String eosObjID,String folderType, SpringCMService svc, String apiURL) {
        pid = folderId;
        ppath = folderPath;
        eosOT = eosObjType;
        eosOID = eosObjID;
        folT = folderType;
        scmsvc = svc;
        aURL = apiURL;
    }

    global CLMFolderRequest(CLMFolder folder, SpringCMService svc) {
        this.pfolder = folder;
        this.pid = svc.getIDfromHref(folder.Href);
        scmsvc = svc;
    }

    private String pid;
    private String ppath;
    private String eosOT;
    private String eosOID;
    private String folT;
    private SpringCMService scmsvc;
    private CLMFolder pfolder;
    private String aURL;
    private Boolean pexpandParentFolder;
    private Boolean pexpandDocuments;
    private Boolean pexpandFolders;
    private Boolean pexpandPath;
    private Boolean pexpandEosParentInfo;
    private Boolean pexpandEosInfo;
    private Boolean pexpandShareLinks;
    private Boolean pexpandAttributeGroups;
    private Boolean pexpandSecurity;


    global Boolean getExpandParentFolder() {return pexpandParentFolder;}
    global void setExpandParentFolder(Boolean value) {if (pexpandParentFolder != value) { pfolder = null;} pexpandParentFolder = value; }

    global Boolean getExpandDocuments() {return pexpandDocuments;}
    global void setExpandDocuments(Boolean value) {if (pexpandDocuments != value) { pfolder = null;} pexpandDocuments = value; }

    global Boolean getExpandFolders() {return pexpandFolders;}
    global void setExpandFolders(Boolean value) {if (pexpandFolders != value) { pfolder = null;} pexpandFolders = value; }

    global Boolean getExpandPath() { return pexpandPath;}
    global void setExpandPath(Boolean value) {if (pexpandPath != value) { pfolder = null; } pexpandPath = value; }

    global Boolean getExpandEosParentInfo() { return pexpandEosParentInfo;}
    global void setExpandEosParentInfo(Boolean value) { if (pexpandEosParentInfo != value) { pfolder = null; } pexpandEosParentInfo = value; }

    global Boolean getExpandEosInfo() { return pexpandEosInfo;}
    global void setExpandEosInfo(Boolean value) { if (pexpandEosInfo != value) { pfolder = null; } pexpandEosInfo = value; }

    global Boolean getExpandShareLinks() {return pexpandShareLinks;}
    global void setExpandShareLinks(Boolean value) { if (pexpandShareLinks != value) { pfolder = null; } pexpandShareLinks = value; }

    global Boolean getExpandAttributeGroups() {return pexpandAttributeGroups;}
    global void setExpandAttributeGroups(Boolean value) { if (pexpandAttributeGroups != value) { pfolder = null; } pexpandAttributeGroups = value; }

    global Boolean getExpandSecurity() {return pexpandSecurity;}
    global void setExpandSecurity(Boolean value) { if (pexpandSecurity != value) { pfolder = null; } pexpandSecurity = value; }

    global CLMFolder getFolder() {
        if ( pfolder == null ) {
            this.result();
        }
        return pfolder;
    }

    private CLMFolder result() {
        if ( pfolder != null ) {
            return pfolder;
        }

        //Folder By Path
        if ( String.isNotBlank( ppath ) && this.containsV2() ) {
            String js = scmsvc.requestor.Get(
                aURL + '/folders/path?path=' + EncodingUtil.urlEncode(ppath,'UTF-8') + '&' + this.expandFolder() ,
                new Map<String,String>()
            );
            pfolder = (CLMFolder)JSON.deserialize(js, CLMFolder.class);
        }
        if ( String.isNotBlank( ppath ) && this.containsV201411() ) {
            String js = scmsvc.requestor.Get(
                aURL + '/folders?path=' + EncodingUtil.urlEncode(ppath,'UTF-8') + '&' + this.expandFolder() ,
                new Map<String,String>()
            );
            pfolder = (CLMFolder)JSON.deserialize(js, CLMFolder.class);
        }

        //SystemFolder
        if ( String.isNotBlank( folT ) && this.containsV2() ) {
            String js = scmsvc.requestor.Get(
                aURL + '/folders/type?SystemFolder=' + EncodingUtil.urlEncode(folT,'UTF-8') + '&' + this.expandFolder() ,
                new Map<String,String>()
            );
            pfolder = (CLMFolder)JSON.deserialize(js, CLMFolder.class);
        }
        if ( String.isNotBlank( folT ) && this.containsV201411() ) {
            String js = scmsvc.requestor.Get(
                aURL + '/folders?SystemFolder=' + EncodingUtil.urlEncode(folT,'UTF-8') + '&' + this.expandFolder() ,
                new Map<String,String>()
            );
            pfolder = (CLMFolder)JSON.deserialize(js, CLMFolder.class);
        }

        //Folder By EOS
        if ( this.isEos() && this.containsV2() ) {
            String js = scmsvc.requestor.Get(
                aURL + '/folders/eos?eosObjectType=' + EncodingUtil.urlEncode(eosOT,'UTF-8') + '&eosObjectId=' + EncodingUtil.urlEncode(eosOID,'UTF-8') + this.expandFolder() ,
                new Map<String,String>()
            );
            pfolder = (CLMFolder)JSON.deserialize(js, CLMFolder.class);
        }
        if ( this.isEos() && this.containsV201411() ) {
            String js = scmsvc.requestor.Get(
                aURL + '/folders?eosObjectType=' + EncodingUtil.urlEncode(eosOT,'UTF-8') + '&eosObjectId=' + EncodingUtil.urlEncode(eosOID,'UTF-8') + this.expandFolder() ,
                new Map<String,String>()
            );
            pfolder = (CLMFolder)JSON.deserialize(js, CLMFolder.class);
        }

        //Folder By ID
        if ( pid != null ) {
            String js = scmsvc.requestor.Get(
                aURL + '/folders/' + pid + '?' + this.expandFolder() ,
                new Map<String,String>()
            );
            pfolder = (CLMFolder)JSON.deserialize(js, CLMFolder.class);
        }

        return pfolder;
    }

    // sonar helper method...
    private Boolean containsV2() {
        return (
            this.aURL.contains( 'v2/' )
            || this.aURL.contains( 'V2/' )
        );
    }
    // sonar helper method...
    private Boolean containsV201411() {
        return (
            this.aURL.contains( '/v201411' )
            || this.aURL.contains( '/V201411' )
        );
    }
    // sonar helper method...
    private Boolean isEos() {
        return (
            String.isNotBlank( this.eosOT )
            && String.isNotBlank( this.eosOID )
        );
    }

    private String expandFolder() {
        List<String> expandString = new List<String>();
        if (pexpandParentFolder  == true) {
            expandString.add('ParentFolder');
        }
        if (pexpandDocuments  == true) {
            expandString.add('Documents');
        }
        if (pexpandFolders  == true) {
            expandString.add('Folders');
        }
        if (pexpandPath  == true) {
            expandString.add('Path');
        }
        if (pexpandEosParentInfo  == true) {
            expandString.add('EosParentInfo');
        }
        if (pexpandEosInfo  == true) {
            expandString.add('Eosinfo');
        }
        if (pexpandShareLinks  == true) {
            expandString.add('ShareLinks');
        }
        if (pexpandAttributeGroups  == true) {
            expandString.add('AttributeGroups');
        }
        if (pexpandSecurity  == true) {
            expandString.add('Security');
        }
        if (expandString.size() == 0) {
            return '';
        }
        return 'expand='+ String.join(expandString,',');
    }

}
//