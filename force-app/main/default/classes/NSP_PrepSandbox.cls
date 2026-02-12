global class NSP_PrepSandbox implements SandboxPostCopy {
    // test w/ NSP_PrepSandboxTest (86%)

    static final string STRING_INVALID = '.invalid';
    static final string DOCUSIGN_BASE_URL = 'https://uatna11.springcm.com/atlas/doclauncher/OneClickDocGen';

    public String runManualResult{get;set;}

    global void runApexClass(SandboxContext context){
        try{
            doQueues();
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'runApexClass:doQueues' );
        }
        try{
            doCSettings(context.sandboxName());
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'runApexClass:doCSettings' );
        }
    }

    public pagereference runManualStepsButton() {
        try{
            runManualSteps();
            runManualResult = 'Post-Refresh Steps complete!';
        } catch(Exception e) {
            runManualResult = 'An exception occurred Updating Metadata: ' + e.getMessage();
        }
        return null;
    }

    public pagereference doUserImportPage() {
        try{
            runUserImport();
            runManualResult = 'Import Users step complete!';
        } catch(Exception e) {
            runManualResult = 'An exception occurred Importing Users: ' + e.getMessage();
        }
        return null;
    }

    public pagereference runManualStepsButton2() {
        try{
            runManualSteps2();
            runManualResult = 'Post-Import Steps complete!';
        } catch(Exception e) {
            runManualResult = 'An exception occurred Updating Metadata: ' + e.getMessage();
        }
        return null;
    }

    public pagereference runE2CAddressesButton() {
        try{
            resetResult();
            runE2CAddresses();
            runManualResult = 'E2C Address updates complete!';
        } catch(Exception e) {
            runManualResult = 'An exception occurred Updating E2C Addresses: ' + e.getMessage();
        }
        return null;
    }

    public pagereference resetResult() {
        runManualResult = '';
        return null;
    }

    @AuraEnabled
    public static void runManualSteps() {
        String sandbox = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        doCMetadata(sandbox);
        doCLabels(sandbox);
        doEmailCLabels();
        doEmailAlerts();
        doImageDocs();
        doTrustedURLs();
        doCSettings(sandbox);
        setPostRefreshRunFlag(1);
    }

    @AuraEnabled
    public static void runUserImport() {
        doUserImport(System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName());
        setPostRefreshRunFlag(2);
    }

    @AuraEnabled
    public static void runManualSteps2() {
        doCMetadataSvc(System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName());
        setPostRefreshRunFlag(3);
    }

    @AuraEnabled
    public static void runE2CAddresses() {
        doE2CAddresses(System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName());
        setPostRefreshRunFlag(4);
    }

    @AuraEnabled
    public static Boolean isCurrentUserAllowedE2C() {
        String allowedUserEmail = 'paul.mccluskey@insperity.com';
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() AND Email = :allowedUserEmail LIMIT 1];
        return currentUser != null;
    }

    public static void doUserImport(String sandboxName) {
        try {
            StaticResource userStaticResource = [SELECT Body FROM StaticResource WHERE Name = 'PreProd_Users' WITH SECURITY_ENFORCED];
            String adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' WITH SECURITY_ENFORCED LIMIT 1].Id;
            String userCsv = userStaticResource.Body.toString();
            // columns:
            //  0 - Notes
            //  1 - Username
            //  2 - Email
            //  3 - FirstName
            //  4 - LastName
            //  5 - Profile
            //  6 - Role
            //  7 - Orgs
            Map<String, List<Profile>> profileNameMap = getProfileNameMap(userCsv);
            Map<String, List<UserRole>> userRoleNameMap = getUserRoleNameMap(userCsv);

            List<User> userList = new List<User>(); // list of User records to upsert
            String[] rows = userCsv.split('\n');
            for(integer i=1; i < rows.size() ; i++) { // skip header row
                String[] column = rows[i].split(',');
                String aliasEnd = (column[4].length() < 5) ? column[4].trim() : column[4].substring(0,5);
                String orgNames = (column[7].length() > 1) ? column[7] : 'none';
                if (column[1].indexOf('integration') < 0 && column[2].indexOf('noreply') < 0 && column[2].indexOf('insperity') > -1){
                    userList.add(new User(
                        IsActive = true,
                        Email = column[2].substringBefore(STRING_INVALID).trim(),
                        FirstName = column[3].trim(),
                        LastName = column[4].trim(),
                        Username = column[2].substringBefore(STRING_INVALID).trim() + '.' + sandboxName,
                        ProfileId = getImportUserProfileId(adminProfileId, sandboxName.toLowercase(), profileNameMap, column[1], column[5], orgNames.toLowercase()),
                        Alias = column[3].substring(0,1).toLowercase() + aliasEnd.toLowercase(),
                        UserRoleId = (userRoleNameMap.containsKey(column[6])) ? userRoleNameMap.get(column[6])[0].Id : null,
                        TimeZoneSidKey = 'America/Chicago',
                        LocaleSidKey = 'en_US',
                        EmailEncodingKey = 'ISO-8859-1',
                        LanguageLocaleKey = 'en_US'
                    ));
                }
            }
            if(!Test.isRunningTest() && userList != null) {
                Database.UpsertResult[] userResults = Database.upsert(userList, User.Username, false);
                NSP_ErrorLogHandler.logResults( NSP_PrepSandbox.class.getName() , 'doUserImport:upsert' , userResults );
                updateUserLogins(userResults);
            }
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doUserImport' );
        }
    }

    public static void doCMetadata(String sandboxName) {
        try{
            List<List<MetadataService.Metadata>> allMetadataList = new List<List<MetadataService.Metadata>>();
            allMetadataList.add(new List<MetadataService.Metadata>());
            List<NSP_DocuSign_Signers__mdt> cMdDocuSigners = [Select Id, Label, DeveloperName, NSP_Signer_Username__c FROM NSP_DocuSign_Signers__mdt WHERE Id!=null AND NSP_Signer_Username__c!=null];
            List<DocuSignRESTSettings__mdt> cMdDocuSignREST = [Select Id, Label, DeveloperName, Value__c FROM DocuSignRESTSettings__mdt WHERE Id!=null];
            List<NSP_PEO_Implementations__mdt> cMdPEOImps = [Select Id, Label, DeveloperName, NSP_Email_Address__c FROM NSP_PEO_Implementations__mdt WHERE Id!=null AND NSP_Email_Address__c!=null];
            List<NSP_Retirement_Services__mdt> cMdRetSvcs = [Select Id, Label, DeveloperName, NSP_Email_Address__c FROM NSP_Retirement_Services__mdt WHERE Id!=null AND NSP_Email_Address__c!=null];

            doDS_mdt( sandboxName , allMetadataList , cMdDocuSigners );
            doDSREST_mdt( sandboxName , allMetadataList , cMdDocuSignREST );
            doPEO_mdt( sandboxName , allMetadataList , cMdPEOImps );
            doRET_mdt( sandboxName , allMetadataList , cMdRetSvcs );

            runUpdateMetadata( allMetadataList );

        } catch( Exception e ) {
            NSP_PrepSandbox.handleException( e , 'doCMetadata' );
        }
    }

    public static MetadataService.CustomMetadata buildCustomMetadataRow( String fullName , String name , String field , String value ) {
        MetadataService.CustomMetadata cMdUpd = new MetadataService.CustomMetadata();
        cMdUpd.fullName = fullName;
        cMdUpd.label = name;
        MetadataService.CustomMetadataValue customField1 = new MetadataService.CustomMetadataValue();
        customField1.field = field; // the custom field API Name to be updated
        customField1.value = value;
        if (cMdUpd.values != null) { //add the changes to list of changes to be deployed
            cMdUpd.values.add(customField1);
        } else {
            cMdUpd.values = new MetadataService.CustomMetadataValue[] { customField1 };
        }
        return cMdUpd;
    }

    public static List<List<MetadataService.Metadata>> addCustomMetadataRow( List<List<MetadataService.Metadata>> allMetadataList , MetadataService.CustomMetadata cMdUpd ) {
        Integer batch = allMetadataList.size() - 1;
        if (allMetadataList[batch].size() >= 200) {
            batch++;
            allMetadataList.add(new List<MetadataService.Metadata>()); // create a new batch when one fills up
        }
        allMetadataList[batch].add(cMdUpd);
        return allMetadataList;
    }

    public static void doDS_mdt(String sandboxName, List<List<MetadataService.Metadata>> allMetadataList, List<NSP_DocuSign_Signers__mdt> cMdDocuSigners) {
        for (NSP_DocuSign_Signers__mdt cMdRecord : cMdDocuSigners) {
            String name = cMdRecord.DeveloperName;
            String fullName = 'NSP_DocuSign_Signers.' + name; //custom metadata full name
            String signer_Username = cMdRecord.NSP_Signer_Username__c;

            MetadataService.CustomMetadata cMdUpd = buildCustomMetadataRow( fullName , name , 'NSP_Signer_Username__c' , signer_Username + '.' + sandboxName );
            allMetadataList = addCustomMetadataRow(allMetadataList, cMdUpd);
        }
    }

    public static void doDSREST_mdt(String sandboxName, List<List<MetadataService.Metadata>> allMetadataList, List<DocuSignRESTSettings__mdt> cMdDocuSignREST) {
        // map of DocuSignRESTSettings__mdt names to default values for DEV
        Map<String, String> resourceMap = new Map<String, String>();

        // retrieve org-specific values from DocuSign_Settings__c
        Map<String, DocuSign_Settings__c> docusignSettingsMap = DocuSign_Settings__c.getAll();
        String keyVal = '';
        if ( String.isEmpty( sandboxName )
            || sandboxName.toUpperCase().startsWith( 'DEV' )
            )
        {
            keyVal = 'DEV';
        } else {
            keyVal = sandboxName.toUpperCase();
        }

        for (String key : docusignSettingsMap.keySet()) {
            if (key.startsWith(keyVal)) {
                keyVal = key;
                break;
            }
        }
        DocuSign_Settings__c docusignSettings = DocuSign_Settings__c.getValues(keyVal);
        resourceMap.put('CLMv2ApiEndpoint', 'https://api' + docusignSettings.CLMBaseUrl__c + '/v2/');
        resourceMap.put('DSAccountID', docusignSettings.AccountId__c);
        resourceMap.put('DSUserName', docusignSettings.UserId__c);
        resourceMap.put('NSP_Docusign_Callback_Username', docusignSettings.Docusign_Callback_Username__c);
        resourceMap.put('RequestAuthDomain', docusignSettings.BaseUrl__c);
        resourceMap.put('RequestAuthEndpoint', 'https://' + docusignSettings.BaseUrl__c + '/oauth/token');
        resourceMap.put('NSP_Invoice_Workflow_Name', 'Invoice AutoGen');
        resourceMap.put('RequestAuthBody', 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=');
        resourceMap.put('RequestAuthContentType','application/x-www-form-urlencoded');
        resourceMap.put('RequestIntegratorKey',docusignSettings.IntegrationKey__c);
        resourceMap.put('RequestScope','signature impersonation spring_read spring_write');
        resourceMap.put(
            'RequestPrivateKey' ,
            docusignSettings.PrivateKey1__c
                + docusignSettings.PrivateKey2__c
                + docusignSettings.PrivateKey3__c
                + docusignSettings.PrivateKey4__c
                + docusignSettings.PrivateKey5__c
                + docusignSettings.PrivateKey6__c
                + docusignSettings.PrivateKey7__c
        );



        for (DocuSignRESTSettings__mdt cMdRecord : cMdDocuSignREST) {
            String name = cMdRecord.DeveloperName;
            String fullName = 'DocuSignRESTSettings.' + name; //custom metadata full name

            MetadataService.CustomMetadata cMdUpd = buildCustomMetadataRow( fullName , name , 'Value__c' , resourceMap.get(name) );
            allMetadataList = addCustomMetadataRow(allMetadataList, cMdUpd);
        }
    }

    public static void doPEO_mdt(String sandboxName, List<List<MetadataService.Metadata>> allMetadataList, List<NSP_PEO_Implementations__mdt> cMdPEOImps) {
        for (NSP_PEO_Implementations__mdt cMdRecord : cMdPEOImps) {
            String name = cMdRecord.DeveloperName;
            String fullName = 'NSP_PEO_Implementations.' + name; //custom metadata full name
            String defaultValue = cMdRecord.NSP_Email_Address__c.substringBefore(STRING_INVALID).trim() + STRING_INVALID;
            String value = defaultValue;
            switch on sandboxName {
                when 'merge','test','stage','devserva','devservb','devservx' {
                    value = 'monica.adams@insperity.com';
                }
                when else {
                    value = defaultValue;
                }
            }

            MetadataService.CustomMetadata cMdUpd = buildCustomMetadataRow( fullName , name , 'NSP_Email_Address__c' , value );
            allMetadataList = addCustomMetadataRow(allMetadataList, cMdUpd);
        }
    }

    public static void doRET_mdt(String sandboxName, List<List<MetadataService.Metadata>> allMetadataList, List<NSP_Retirement_Services__mdt> cMdRetSvcs) {
        for (NSP_Retirement_Services__mdt cMdRecord : cMdRetSvcs) {
            string name = cMdRecord.DeveloperName;
            string fullName = 'NSP_Retirement_Services.' + name; //custom metadata full name
            String value = cMdRecord.NSP_Email_Address__c.substringBefore(STRING_INVALID).trim() + STRING_INVALID;

            MetadataService.CustomMetadata cMdUpd = buildCustomMetadataRow( fullName , name , 'NSP_Email_Address__c' , value );
            allMetadataList = addCustomMetadataRow(allMetadataList, cMdUpd);
        }
    }

    public static void doCMetadataSvc(String sandboxName) {
        try {
            List<List<MetadataService.Metadata>> allMetadataList = new List<List<MetadataService.Metadata>>();
            allMetadataList.add(new List<MetadataService.Metadata>());
            List<NSP_ProjectTemplateMapping__mdt> cMdTmpls = [Select Id, Label, DeveloperName, Key__c, Template_ID__c, Template_Name__c FROM NSP_ProjectTemplateMapping__mdt WHERE Id!=Null];
            List<Template_Key_and_Id_Mapping__mdt> cMdTmplKeys = [Select Id, Label, DeveloperName, Key__c, Template_ID__c, Template_Name__c FROM Template_Key_and_Id_Mapping__mdt WHERE Id!=Null];
            List<pse__Proj__c> oProjTmpls = [Select Id, TemplateName__c FROM pse__Proj__c WHERE pse__Is_Template__c = true];
            Map<String, Id> mTmplId = new map<String, Id>();
            for (pse__Proj__c oProjTmpl : oProjTmpls) {
                mTmplId.put(oProjTmpl.TemplateName__c, oProjTmpl.Id);
            }

            doTmpls_mdt( sandboxName , mTmplId , allMetadataList , cMdTmpls );
            doTmplKeys_mdt( sandboxName , mTmplId , allMetadataList , cMdTmplKeys );

            runUpdateMetadata( allMetadataList );

        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCMetadataSvc' );
        }
    }

    public static void doTmpls_mdt(String sandboxName, Map<String, Id> mTmplId, List<List<MetadataService.Metadata>> allMetadataList, List<NSP_ProjectTemplateMapping__mdt> cMdTmpls) {
        for (NSP_ProjectTemplateMapping__mdt cMdTmpl : cMdTmpls) {
            if (mTmplId.containsKey(cMdTmpl.Template_Name__c) || Test.isRunningTest()) {
                string name = cMdTmpl.DeveloperName;
                string fullName = 'NSP_ProjectTemplateMapping.' + name; //custom metadata full name

                MetadataService.CustomMetadata cMdUpd = buildCustomMetadataRow( fullName , name , 'Template_ID__c' , mTmplId.get(cMdTmpl.Template_Name__c) );
                allMetadataList = addCustomMetadataRow(allMetadataList, cMdUpd);
            }
        }
    }

    public static void doTmplKeys_mdt(String sandboxName, Map<String, Id> mTmplId, List<List<MetadataService.Metadata>> allMetadataList, List<Template_Key_and_Id_Mapping__mdt> cMdTmplKeys) {
        for (Template_Key_and_Id_Mapping__mdt cMdTmplKey : cMdTmplKeys) {
            if (mTmplId.containsKey(cMdTmplKey.Template_Name__c) || Test.isRunningTest()) {
                string name = cMdTmplKey.DeveloperName;
                string fullName = 'Template_Key_and_Id_Mapping.' + name; //custom metadata full name

                MetadataService.CustomMetadata cMdUpd = buildCustomMetadataRow( fullName , name , 'Template_ID__c' , mTmplId.get(cMdTmplKey.Template_Name__c) );
                allMetadataList = addCustomMetadataRow(allMetadataList, cMdUpd);
            }
        }
    }

    public static void doCLabels(String sandboxName) {
        try {
            MetadataService.MetadataPort service = createService();
            List<MetadataService.Metadata> allMetadataList = new List<MetadataService.Metadata>();
            MetadataService.CustomLabel cL = new MetadataService.CustomLabel();
            Map<String, String> refreshValMap = new Map<String, String>();
            switch on sandboxName {
                when 'stage' {
                    refreshValMap.put('NSP_FTA_Base_URL', 'https://stageportalapps.insperity.com/financialcomparison/financialanalysis/');
                    refreshValMap.put('NSP_Docusign_Account_Id', '48945');
                    refreshValMap.put('NSP_Docusign_Base_URL', DOCUSIGN_BASE_URL);
                    refreshValMap.put('NSP_Contact_Center_Email_Addresses', 'test.contact_center_UAT@insperity.com');
                    refreshValMap.put('NSP_Health_Welfare_Section_125', 'test.section125_UAT@insperity.com');
                }
                when 'test' {
                    refreshValMap.put('NSP_FTA_Base_URL', 'https://testportalapps.insperity.com/financialcomparison/financialanalysis/');
                    refreshValMap.put('NSP_Docusign_Account_Id', '65500');
                    refreshValMap.put('NSP_Docusign_Base_URL', DOCUSIGN_BASE_URL);
                    refreshValMap.put('NSP_Contact_Center_Email_Addresses', 'test.contact_center@insperity.com');
                    refreshValMap.put('NSP_Health_Welfare_Section_125', 'test.section125@insperity.com');
                }
                when 'merge' {
                    refreshValMap.put('NSP_FTA_Base_URL', 'https://devportalapps.insperity.com/financialcomparison/financialanalysis/');
                    refreshValMap.put('NSP_Docusign_Account_Id', '122677');
                    refreshValMap.put('NSP_Docusign_Base_URL', DOCUSIGN_BASE_URL);
                    refreshValMap.put('NSP_Contact_Center_Email_Addresses', 'test.contact_center.merge@insperity.com');
                    refreshValMap.put('NSP_Health_Welfare_Section_125', 'test.section125.merge@insperity.com');
                }
                when else {
                    refreshValMap.put('NSP_FTA_Base_URL', 'https://devportalapps.insperity.com/financialcomparison/financialanalysis/');
                    refreshValMap.put('NSP_Docusign_Account_Id', '50202');
                    refreshValMap.put('NSP_Docusign_Base_URL', DOCUSIGN_BASE_URL);
                }
            }
            for (String cLName : refreshValMap.keySet()) {
                setCLabelData(service, cL, allMetadataList, cLName, refreshValMap);
            }

            if(allMetadataList.size() > 0 && !Test.isRunningTest()){
                service.updateMetadata(allMetadataList);
            }
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCLabels' );
        }
    }

    private static void setCLabelData(MetadataService.MetadataPort service, MetadataService.CustomLabel cL, List<MetadataService.Metadata> allMetadataList, String cLName, Map<String, String> refreshValMap) {
        if(!Test.isRunningTest()){
            cL = (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { cLName }).getRecords()[0];
        }else{
            cL.fullName = cLName;
            cL.value = 'test';
        }
        if(cL.value != null){
            MetadataService.CustomLabel cLUpd = new MetadataService.CustomLabel();
            cLUpd.fullName = cL.fullName;
            cLUpd.value = refreshValMap.get(cLName);
            cLUpd.shortDescription = cL.shortDescription;
            cLUpd.language = cL.language;
            cLUpd.protected_x = cL.protected_x;
            allMetadataList.add(cLUpd);
        }
    }

    public static void doEmailCLabels() {
        try {
            Integer batch = 0;
            MetadataService.MetadataPort service = createService();
            List<List<MetadataService.Metadata>> allMetadataList = new List<List<MetadataService.Metadata>>();
            allMetadataList.add(new List<MetadataService.Metadata>());
            MetadataService.CustomLabel cL;
            String sandbox = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName().toLowerCase();
            String[] cLNames = getEmailCLabelNames();
            String[] preserveNames = new String[]{'NSP_Contact_Center_Email_Addresses' , 'NSP_Health_Welfare_Section_125'};

            for( integer i=0; i < cLNames.size() ; i++ ) {
                cL = new MetadataService.CustomLabel();
                if ( !Test.isRunningTest() ) {
                    cL = (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { cLNames[i] }).getRecords()[0];
                } else {
                    cL.value = 'test@insperity.com';
                }
                if( cL?.value.indexOf('@') != -1 && cL?.value.indexOf(STRING_INVALID) == -1
                        && ( sandbox.indexOf('dev') != -1 || !preserveNames.contains( cLNames[i] ) ) ) {
                    MetadataService.CustomLabel cLUpd = new MetadataService.CustomLabel();
                    cLUpd.fullName = cL.fullName;
                    cLUpd.value = invalidateEmailString(cL.value);
                    cLUpd.shortDescription = cL.shortDescription;
                    cLUpd.language = cL.language;
                    cLUpd.protected_x = cL.protected_x;

                    if (allMetadataList[batch].size() >= 10) {
                        batch++;
                        allMetadataList.add(new List<MetadataService.Metadata>()); // create a new batch when we fill one up
                    }
                    allMetadataList[batch].add(cLUpd);
                }
            }

            runUpdateMetadata( allMetadataList );

        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doEmailCLabels' );
        }
    }

    public static void runUpdateMetadata( List<List<MetadataService.Metadata>> allMetadataList ) {
        MetadataService.MetadataPort service = createService();
        if ( allMetadataList.size() > 0 && allMetadataList[0].size() > 0 && !Test.isRunningTest() ) {
            for (Integer i = 0; i < allMetadataList.size(); i ++) {
                service.updateMetadata(allMetadataList[i]);
            }
        }
    }

    public static List<String> getEmailCLabelNames() {
        List<String> cLNames = new List<String>();
        MetadataService.MetadataPort service = createService();
        MetadataService.CustomLabel cL = (!Test.isRunningTest()) ? (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { 'Post_Refresh_Email_Labels' }).getRecords()[0] : new MetadataService.CustomLabel();
        MetadataService.CustomLabel cL2 = (!Test.isRunningTest()) ? (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { 'Post_Refresh_Email_Labels_2' }).getRecords()[0] : new MetadataService.CustomLabel();
        if(cL.value == null) {
            cL.value = 'dummy';
        }
        cLNames = cL.value.split(',');
        String[] cLNames2 = (cL2.value == null) ? new String[]{} : cL2.value.split(',');
        if(cLNames2.size() > 0) {
            cLNames.addAll(cLNames2);
        }
        return cLNames;
    }

    public static void doEmailAlerts() {
        try {
            String host = URL.getOrgDomainUrl().toExternalForm();
            String endPoint = host + '/services/data/v55.0/tooling/';
            String sessionId = UserInfo.getSessionId();
            List<String[]> wfaNames = new List<String[]>();
            wfaNames.add(new String[]{});
            List<List<MetadataService.Metadata>> allMetadataList = new List<List<MetadataService.Metadata>>();

            //  Get the list of alerts Ids where CCemails is not empty
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endPoint + 'query/?q=SELECT+id+FROM+WorkflowAlert+WHERE+CCemails+>+\'\'');
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer '+ sessionId);
            HTTPResponse response = new HTTPResponse();
            AlertResult results = new AlertResult();
            RecordAlert[] records = new RecordAlert[]{};

            if( !Test.isRunningTest() ) {
                response = new Http().send(request);
                results = (AlertResult)JSON.deserialize(response.getBody(), AlertResult.class);
                records = results.records;
            } else {
                RecordAlert rec = new RecordAlert();
                Attributes att = new Attributes();
                WorkflowEmail wfe = new WorkflowEmail();
                MetadataService.WorkflowAlert wfa = new MetadataService.WorkflowAlert();
                att.type = 'test';
                att.url = 'test';
                rec.FullName='test';
                rec.id='test';
                rec.attributes = att;
                wfe.attributes = att;
                wfe.id='test';
                wfe.TemplateId='test';
                wfe.CcEmails='test';
                wfe.Description='test';
                wfe.DeveloperName='test';
                wfe.EntityDefinitionId='test';
                wfe.FullName='test';
                wfe.Metadata=wfa;
                records.add(rec);
            }

            getWFAlertData( request , records , wfaNames );
            setWFAlertData( wfaNames , allMetadataList );

            runUpdateMetadata( allMetadataList );

        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doEmailAlerts' );
        }
    }

    public static void getWFAlertData(HttpRequest request, RecordAlert[] records, List<String[]> wfaNames) {
        Integer batch = 0;
        HTTPResponse response = new HTTPResponse();
        String host = URL.getOrgDomainUrl().toExternalForm();
        String sessionId = UserInfo.getSessionId();
        for (RecordAlert alert : records) {
            // Get the Alert meta-data
            request = new HttpRequest();
            request.setEndpoint(host + alert.attributes.url);
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer '+ sessionId);

            if (wfaNames[batch].size() >= 10) {
                batch++;
                wfaNames.add(new String[]{}); // create a new batch when we fill one up
            }
            if (!Test.isRunningTest()) {
                response = new Http().send(request);
                WorkflowEmail wfe = (WorkflowEmail)JSON.deserialize(response.getBody(), WorkflowEmail.class);
                wfaNames[batch].add(wfe.FullName);
            } else {
                wfaNames[batch].add('test');
            }
        }
    }

    public static void setWFAlertData(List<String[]> wfaNames, List<List<MetadataService.Metadata>> allMetadataList) {
        if (wfaNames.size() > 0) {
            MetadataService.MetadataPort service = createService();
            for (Integer i = 0; i < wfaNames.size(); i++) {
                MetadataService.ReadResult readResult = new MetadataService.ReadResult();
                if (!Test.isRunningTest()) {
                    readResult.records = service.readMetadata('WorkflowAlert', wfaNames[i]).getRecords();
                } else {
                    readResult.records = new MetadataService.Metadata[]{new MetadataService.WorkflowAlert()};
                }
                allMetadataList.add(new List<MetadataService.Metadata>());
                for (MetadataService.Metadata wfaMeta : readResult.records) {
                    MetadataService.WorkflowAlert wfa = (MetadataService.WorkflowAlert) wfaMeta;
                    wfa.ccEmails = (!Test.isRunningTest()) ? invalidateEmailArray(wfa.ccEmails).split(',') : invalidateEmailArray(new String[]{'test@insperity.com'}).split(',');
                    allMetadataList[i].add(wfa);
                }
            }
        }
    }

    public static void doCSettings(String sandboxName) {
        String dSAccountId = '';
        String cLMBaseURL = '';
        try {
            Map<String, DocuSign_Settings__c> docusignSettingsMap = DocuSign_Settings__c.getAll();
            List<DocuSign_Settings__c> updDSSettings = new List<DocuSign_Settings__c>();
            for (String key : docusignSettingsMap.keySet()) {
                DocuSign_Settings__c docusignSettings = DocuSign_Settings__c.getValues(key);
                docusignSettings.IsEnabled__c = false;
                if (sandboxName.startsWith(key.toLowerCase().left(3))) {
                    docusignSettings.IsEnabled__c = true;
                    dSAccountId = docusignSettings.AccountNumber__c;
                    cLMBaseURL = docusignSettings.CLMBaseUrl__c;
                }
                updDSSettings.add(docusignSettings);
            }
            update updDSSettings;
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCSettings:DocuSign_Settings__c' );
        }

        try {
            NSP_GoogleRecaptchaSettings__c cS1 = NSP_GoogleRecaptchaSettings__c.getOrgDefaults();
            cS1.NSP_SiteKey__c = '6LegnBQiAAAAAM_at9VCdc-X143lsbrvrgZPlOta';
            cS1.NSP_SiteUrl__c = 'https://insperity--' + sandboxName + '.sandbox.my.salesforce-sites.com/';
            upsert cS1;
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCSettings:NSP_GoogleRecaptchaSettings__c' );
        }

        try {
            NSP_Docusign_Account_Details__c cS2 = NSP_Docusign_Account_Details__c.getOrgDefaults();
            if (dSAccountId != '' && cLMBaseURL != ''){
                cS2.Docusign_Account_Id__c = dSAccountId;
                cS2.CLM_Base_URL__c = cLMBaseURL;
                upsert cS2;
            }
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCSettings:NSP_Docusign_Account_Details__c' );
        }

        try {
            OrgSettings__c cS3 = NSP_PrepSandbox.settings;
            cS3.OrgDomainUrl__c = URL.getOrgDomainUrl().toExternalForm().toLowerCase();
            cS3.Instance__c = [ SELECT InstanceName FROM Organization WHERE Id!=null LIMIT 1 ].InstanceName.toLowerCase();
            cS3.IsSandbox__c =  [ SELECT IsSandbox FROM Organization WHERE Id!=null LIMIT 1 ].IsSandbox;
            cS3.OrgId__c = [ SELECT Id FROM Organization WHERE Id!=null LIMIT 1 ].Id;
            cS3.SandboxApiName__c = sandboxName.toLowerCase();
            cS3.SandboxName__c = sandboxName;
            upsert cS3;
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCSettings:OrgSettings__c' );
        }

        try {
            NSP_Environment_Details__c cS4 = NSP_Environment_Details__c.getOrgDefaults();
            switch on sandboxName {
                when 'stage' {
                    cS4.NSP_Detailed_Data__c = 'stage1';
                }
                when 'test' {
                    cS4.NSP_Detailed_Data__c = 'test1';
                }
                when 'merge' {
                    cS4.NSP_Detailed_Data__c = 'dev1';
                }
                when else {
                    cS4.NSP_Detailed_Data__c = 'dev1';
                }
            }
            upsert cS4;
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCSettings:NSP_Environment_Details__c' );
        }

        try {
            BoxFileRequest__c cS5 = BoxFileRequest__c.getOrgDefaults();
            cS5.BoxTemplateFolderId__c = '225207143235';
            upsert cS5;
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCSettings:BoxFileRequest__c' );
        }

        try {
            UserTriggerSettings__c cS6 = UserTriggerSettings__c.getOrgDefaults();
            cS6.AllowedAdmins__c = null;
            cS6.BccAddresses__c = null;
            upsert cS6;
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCSettings:UserTriggerSettings__c' );
        }

        try {
            Contract_Termination_Settings__c cS7 = Contract_Termination_Settings__c.getOrgDefaults();
            cS7.AutoTerminationEmailAddresses__c = null;
            upsert cS7;
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCSettings:Contract_Termination_Settings__c' );
        }

    }

    public static void doE2CAddresses(String sandboxName) {
        try {
            Map<String, Integer> orgMap = new Map<String, Integer>{'merge' => 1, 'test' => 2, 'stage' => 3};
            Map<String, String> teamAddrMap = new Map<String, String>();
            StaticResource e2CStaticResource = [SELECT Body FROM StaticResource WHERE Name = 'EmailToCaseAddresses' WITH SECURITY_ENFORCED];
            String e2Ccsv = e2CStaticResource.Body.toString();
            String[] rows = e2Ccsv.split('\n');

            for(integer i=1; i < rows.size() ; i++) { // skip header row
                String[] col = rows[i].split(',');
                if (orgMap.containsKey(sandboxName) && col[0].length() > 0 && col[orgMap.get(sandboxName)].length() > 0) {
                    teamAddrMap.put(col[0], col[orgMap.get(sandboxName)]);
                }
            }

            MetadataService.MetadataPort service = createService();
            MetadataService.CaseSettings cS = new MetadataService.CaseSettings();
            if (!Test.isRunningTest()) {
                cS = (MetadataService.CaseSettings) service.readMetadata('CaseSettings', new String[] {'Settings'}).getRecords()[0];
            } else {
                MetadataService.EmailToCaseRoutingAddress addr = new MetadataService.EmailToCaseRoutingAddress();
                MetadataService.EmailToCaseRoutingAddress[] addrs = new MetadataService.EmailToCaseRoutingAddress[] {};
                MetadataService.EmailToCaseSettings e2CS = new MetadataService.EmailToCaseSettings();
                addr.routingName = 'Integra';
                addr.emailAddress = 'test.integrasupport@insperity.com';
                addrs.add(addr);
                e2CS.routingAddresses = addrs;
                cS.emailToCase = e2CS;
            }

            for (integer i=0; i < cS.emailToCase.routingAddresses.size() ; i++) {
                String routingName = cS.emailToCase.routingAddresses[i].routingName;
                if (teamAddrMap.containsKey(routingName)) {
                    cS.emailToCase.routingAddresses[i].emailAddress = teamAddrMap.get(routingName);
                }
            }

            List<MetadataService.Metadata> allMetadataList = new List<MetadataService.Metadata>();
            allMetadataList.add(cS);

            if (teamAddrMap.size() > 0 && allMetadataList.size() > 0 && !Test.isRunningTest()) {
                service.updateMetadata(allMetadataList);
            }
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doE2CAddresses' );
        }
    }

    public static void doQueues() {
        try {
            List<Group> updateQueue = new List<Group>();
            for (Group queue:[SELECT id, email FROM Group WHERE type = 'Queue' AND email > '']) {
                if(queue.email.indexOf(STRING_INVALID) == -1){
                    queue.email = queue.email + STRING_INVALID;
                    updateQueue.add(queue);
                }
            }
            if(!updateQueue.isEmpty()){
                update updateQueue;
            }
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doQueues' );
        }
    }

    public static void doImageDocs() {
        MetadataService.MetadataPort service = createService();
        try {
            List<MetadataService.Metadata> metadataList = new List<MetadataService.Metadata>();
            // map of static resource names to document names
            Map<String, String> resourceMap = new Map<String, String>();
            resourceMap.put('Insperity_Copyright_Logo', 'Insperity_Copy_write_logo');
            resourceMap.put('Insperity_Footer_Logo', 'Insperity_Footer_Logo');
            resourceMap.put('Insperity_HR', 'Insperity_HR');
            resourceMap.put('Insperity_HR_Logo', 'Insperity_HR_Logo');
            resourceMap.put('Insperity_Service_Operations', 'Insperity_Service_Operations');
            resourceMap.put('InsperityEmailSignatureLogo', 'InsperityEmailSignatureLogo');

            List<StaticResource> srList = new List<StaticResource>([SELECT Id, Body, Name FROM StaticResource WHERE Name IN :resourceMap.keySet()]);

            for (StaticResource sr : srList) {
                MetadataService.Document doc = new MetadataService.Document();
                doc.fullName = 'Services/' + resourceMap.get(sr.Name) + '.png';
                doc.name = replaceUnderscoresWithSpaces(resourceMap.get(sr.Name));
                doc.content = EncodingUtil.base64Encode(sr.Body);
                doc.public_x = true;
                doc.internalUseOnly = false;
                metadataList.add(doc);
            }

            if ( metadataList.size() > 0 && !Test.isRunningTest() ) {
                service.createMetadata(metadataList);
            }
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doImageDocs' );
        }
    }

    public static String replaceUnderscoresWithSpaces(String input) {
        if ( input != null ) {
            return input.replace('_', ' ');
        }
        return null;
    }

    @AuraEnabled(cacheable=true)
    public static OrgSettings__c getOrgSettings() {
        return NSP_PrepSandbox.settings;
    }

    public static void setPostRefreshRunFlag(Integer iStep) {
        try {
            OrgSettings__c cS = NSP_PrepSandbox.settings;
            if (iStep == 1) cS.PostRefreshRun__c = true;
            if (iStep == 2) cS.PostRefreshRun2__c = true;
            if (iStep == 3) cS.PostRefreshRun3__c = true;
            if (iStep == 4) cS.PostRefreshRun4__c = true;
            upsert cS;
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'setPostRefreshRunFlag' );
        }
    }

    public static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = apiEnabledSessionId();
        return service;
    }

    private static String apiEnabledSessionId() {
        return UserInfo.getSessionId();
    }

    public static void doTrustedURLs() {
        try {
            Integer batch = 0;
            MetadataService.MetadataPort service = createService();
            List<List<MetadataService.Metadata>> allMetadataList = new List<List<MetadataService.Metadata>>();
            allMetadataList.add(new List<MetadataService.Metadata>());

            Map<String, String> mapSites = new Map<String, String>();
            mapSites.put('Tableau', 'https://testtableau.insperity.com');
            mapSites.put('Salesforce_SCRT', 'https://*.sandbox.my.salesforce-scrt.com');
            mapSites.put('Salesforce_Setup', 'https://*.sandbox.my.salesforce-setup.com');

            MetadataService.ReadResult readResult = new MetadataService.ReadResult();
            if (!Test.isRunningTest()) {
                readResult.records = service.readMetadata('CspTrustedSite', new List<String>(mapSites.keySet())).getRecords();
            } else {
                readResult.records = new MetadataService.Metadata[]{new MetadataService.CspTrustedSite()};
            }

            for (MetadataService.Metadata result : readResult.records) {
                MetadataService.CspTrustedSite site = (MetadataService.CspTrustedSite) result;

                if( site != null ) {
                    MetadataService.CspTrustedSite siteUpd = new MetadataService.CspTrustedSite();
                    siteUpd.fullName = site.fullName;
                    siteUpd.description = site.description;
                    siteUpd.isActive = site.isActive;
                    siteUpd.endpointUrl = mapSites.get(siteName);

                    if (allMetadataList[batch].size() >= 10) {
                        batch++;
                        allMetadataList.add(new List<MetadataService.Metadata>()); // create a new batch when we fill one up
                    }
                    allMetadataList[batch].add(siteUpd);
                }
            }

            runUpdateMetadata( allMetadataList );

        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'doCTrustedURLs' );
        }
    }

    private static string invalidateEmailArray(List<String> origEmails) {
        string newES = '';
        for(integer i=0; i<origEmails.size() ; i++) {
            newES = (origEmails[i].indexOf(STRING_INVALID) == -1) ? newES + ',' + origEmails[i] + STRING_INVALID : newES + ',' + origEmails[i];
        }
        return newES.substringAfter(',');
    }

    private static string invalidateEmailString(String origES) {
        string[] origEmails = origES.split(',');
        string newES = '';
        for(integer i=0; i<origEmails.size() ; i++) {
            newES = (origEmails[i].indexOf(STRING_INVALID) == -1) ? newES + ',' + origEmails[i] + STRING_INVALID : newES + ',' + origEmails[i];
        }
        return newES.substringAfter(',');
    }

    private static string getImportUserProfileId(String adminProfileId, String sandboxName, Map<String, List<Profile>> profileNameMap, String userName, String profName, String orgNames) {
        string profileId = '00e4x0000012F54'; // '00e4x0000012F54' is 'Minimum Access - Salesforce' Profile Id
        string[] allowedOrgs = orgNames.split(':');
        if( allowedOrgs.contains(sandboxName) && sandboxName.startsWith('dev') && userName.contains('CRM Team') ) {
            profileId = adminProfileId;
        } else if ( profileNameMap.containsKey(profName) ) {
            profileId = profileNameMap.get(profName)[0].Id;
        }
        return profileId;
    }

    private static Map<String, List<Profile>> getProfileNameMap(String userCsv) {
        Map<String, List<Profile>> profileNameMap = new map<String, List<Profile>>();
        for (String row : userCsv.split('\n')) { // build Profile Map
            String[] col = row.split(',');
            if(col[5].length() > 0 && !profileNameMap.containsKey(col[5])){
                Profile[] userProf = [SELECT Id FROM Profile WHERE Name = :col[5].trim() WITH SECURITY_ENFORCED LIMIT 1];
                if(!userProf.isEmpty()) profileNameMap.put(col[5], userProf);
            }
        }
        return profileNameMap;
    }

    private static Map<String, List<UserRole>> getUserRoleNameMap(String userCsv) {
        Map<String, List<UserRole>> userRoleNameMap = new map<String, List<UserRole>>();
        for (String row : userCsv.split('\n')) { // build Role ID Map
            String[] col = row.split(',');
            if(col[6].length() > 0 && !userRoleNameMap.containsKey(col[6])){
                UserRole[] userRole = [SELECT Id FROM UserRole WHERE Name = :col[6].trim() WITH SECURITY_ENFORCED LIMIT 1];
                if(!userRole.isEmpty()) userRoleNameMap.put(col[6], userRole);
            }
        }
        return userRoleNameMap;
    }

    @TestVisible
    private static void updateUserLogins(Database.UpsertResult[] userResults) {
        Set<Id> userIdSet = new Set<Id>();
        List<UserLogin> userLoginList = new List<UserLogin>(); // list of UserLogin records to update
        try {
            for (Database.UpsertResult userResult : userResults) {
                if (userResult.isSuccess()) {
                    userIdSet.add(userResult.getId());
                }
            }
            if ( !userIdSet.isEmpty() ) {
                for(UserLogin ulogin : [SELECT Id, IsFrozen, UserId From UserLogin Where UserId IN :userIdSet]) {
                    ulogin.IsFrozen = false;
                    userLoginList.add(ulogin);
                }
            }
            if ( userLoginList != null ) {
                Database.SaveResult[] userLoginResults = Database.update(userLoginList, false);
                NSP_ErrorLogHandler.logResults( NSP_PrepSandbox.class.getName() , 'updateUserLogins:update' , userLoginResults );
            }
        } catch(Exception e) {
            NSP_PrepSandbox.handleException( e , 'updateUserLogins' );
        }
    }

    private class AlertResult {
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;
        public RecordAlert[] records;
    }

    private class RecordAlert {
        public Attributes attributes{get;set;}
        public string id{get;set;}
        public string FullName{get;set;}
    }

    private class Attributes {
        public string type{get;set;}
        public string url{get;set;}
    }

    private class WorkflowEmail {
        public Attributes attributes{get;set;}
        public string Id{get;set;}
        public string TemplateId{get;set;}
        public String CcEmails{get;set;}
        public String Description{get;set;}
        public String DeveloperName{get;set;}
        public string EntityDefinitionId{get;set;}
        public MetadataService.WorkflowAlert Metadata{get;set;}
        public String FullName{get;set;}
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_PrepSandbox.class.getName() ,
            methodName ,
            e
        );
    }

    private static OrgSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = OrgSettings__c.getOrgDefaults();
            }
            return settings;
        }
        private set;
    }
}
