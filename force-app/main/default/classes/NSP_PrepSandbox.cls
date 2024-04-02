global class NSP_PrepSandbox implements SandboxPostCopy {
    // test w/ NSP_PrepSandboxTest (84%)

    public String runManualResult{get;set;}
    global void runApexClass(SandboxContext context){
        try{
            doQueues();
        } catch(Exception e) {
            System.debug('An exception occurred in runApexClass: ' + e.getMessage());
        }
        try{
            doCSettings(context.sandboxName());
        } catch(Exception e) {
            System.debug('An exception occurred in runApexClass: ' + e.getMessage());
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

    public static void runManualSteps() {
        String sandbox = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        doCMetadata(sandbox);
        doCLabels(sandbox);
        doEmailCLabels();
        doEmailAlerts();
        doCSettings(sandbox);
        setPostRefreshRunFlag(1);
    }

    public static void runUserImport() {
        doUserImport(System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName());
        setPostRefreshRunFlag(2);
    }

    public static void runManualSteps2() {
        doCMetadataSvc(System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName());
        setPostRefreshRunFlag(3);
    }

    public static void runE2CAddresses() {
        doE2CAddresses(System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName());
        setPostRefreshRunFlag(4);
    }

    public static void doUserImport(String sandboxName) {
        try{
            StaticResource userStaticResource = [SELECT Body FROM StaticResource WHERE Name = 'PreProd_Users' WITH SECURITY_ENFORCED];
            String userCsv = userStaticResource.Body.toString();
            // columns:
            //  0 - Notes
            //  1 - Username
            //  2 - Email
            //  3 - FirstName
            //  4 - LastName
            //  5 - Profile
            //  6 - Role
            Map<String, List<Profile>> profileNameMap = new map<String, List<Profile>>();
            Map<String, List<UserRole>> userRoleNameMap = new map<String, List<UserRole>>();
            for (String row : userCsv.split('\n')) { // build Profile and Role ID Maps
                String[] col = row.split(',');
                if(col[5].length() > 0 && !profileNameMap.containsKey(col[5])){
                    Profile[] userProf = [SELECT Id FROM Profile WHERE Name = :col[5].trim() WITH SECURITY_ENFORCED LIMIT 1];
                    if(!userProf.isEmpty()) profileNameMap.put(col[5], userProf);
                }
                if(col[6].length() > 0 && !userRoleNameMap.containsKey(col[6])){
                    UserRole[] userRole = [SELECT Id FROM UserRole WHERE Name = :col[6].trim() WITH SECURITY_ENFORCED LIMIT 1];
                    if(!userRole.isEmpty()) userRoleNameMap.put(col[6], userRole);
                }
            }
            
            List<User> userList = new List<User>(); // list of User records to upsert
            String[] rows = userCsv.split('\n');
            for(integer i=1; i < rows.size() ; i++) { // skip header row
                String[] column = rows[i].split(',');
                String aliasEnd = (column[4].length() < 5) ? column[4].trim() : column[4].substring(0,5);
                if ((column[1].indexOf(sandboxName) > -1 || column[1].indexOf('CRM Team') > -1) && column[1].indexOf('integration') < 0 && column[2].indexOf('noreply') < 0){
                    userList.add(new User(
                        IsActive = true,
                        Email = column[2].substringBefore('.invalid').trim(),
                        FirstName = column[3].trim(),
                        LastName = column[4].trim(),
                        Username = column[2].substringBefore('.invalid').trim() + '.' + sandboxName,
                        ProfileId = (profileNameMap.containsKey(column[5])) ? profileNameMap.get(column[5])[0].Id : '00e4x0000012F54',
                        FederationIdentifier = column[2].substringBefore('.invalid').trim(),
                        Alias = column[3].substring(0,1).toLowercase() + aliasEnd.toLowercase(),
                        UserRoleId = (userRoleNameMap.containsKey(column[6])) ? userRoleNameMap.get(column[6])[0].Id : null,
                        TimeZoneSidKey = 'America/Chicago',
                        LocaleSidKey = 'en_US',
                        EmailEncodingKey = 'ISO-8859-1',
                        LanguageLocaleKey = 'en_US'
                    ));
                }
            }
            if(!Test.isRunningTest()) {
                Database.UpsertResult[] userResults = Database.upsert(userList, User.FederationIdentifier, false);
                for (Database.UpsertResult userResult : userResults) {
                    if (!userResult.isSuccess()) {
                        for (Database.Error err : userResult.getErrors()) {
                            System.debug('An exception occurred in doUserImport: ' + err.getMessage());
                        }
                    }
                }
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doUserImport: ' + e.getMessage());
        }
    }

    public static void doCMetadata(String sandboxName) {
        try{
            Integer batch = 0;
            MetadataService.MetadataPort service = createService();
            List<List<MetadataService.Metadata>> allMetadataList = new List<List<MetadataService.Metadata>>();
            allMetadataList.add(new List<MetadataService.Metadata>());
            List<NSP_DocuSign_Signers__mdt> cMdDocuSigners = [Select Id, Label, DeveloperName, NSP_Signer_Username__c FROM NSP_DocuSign_Signers__mdt WHERE Id!=null AND NSP_Signer_Username__c!=null];
            List<NSP_PEO_Implementations__mdt> cMdPEOImps = [Select Id, Label, DeveloperName, NSP_Email_Address__c FROM NSP_PEO_Implementations__mdt WHERE Id!=null AND NSP_Email_Address__c!=null];

            for (NSP_DocuSign_Signers__mdt cMdRecord : cMdDocuSigners) {
                string name = cMdRecord.DeveloperName;
                string fullName = 'NSP_DocuSign_Signers.' + name; //custom metadata full name
                string signer_Username = cMdRecord.NSP_Signer_Username__c;
                
                MetadataService.CustomMetadata cMdUpd = new MetadataService.CustomMetadata();
                    cMdUpd.fullName = fullName;
                    cMdUpd.label = name;
                MetadataService.CustomMetadataValue customField1 = new MetadataService.CustomMetadataValue();
                    customField1.field = 'NSP_Signer_Username__c'; // the custom field API Name to be updated
                    customField1.value = signer_Username + '.' + sandboxName;
                cMdUpd.values.add(customField1); //add the changes to list of changes to be deployed

                if (allMetadataList[batch].size() >= 200) {
                    batch++;
                    allMetadataList.add(new List<MetadataService.Metadata>()); // create a new batch when we fill one up
                }
                allMetadataList[batch].add(cMdUpd);
            }

            for (NSP_PEO_Implementations__mdt cMdRecord : cMdPEOImps) {
                string name = cMdRecord.DeveloperName;
                string fullName = 'NSP_PEO_Implementations.' + name; //custom metadata full name
                MetadataService.CustomMetadata cMdUpd = new MetadataService.CustomMetadata();
                    cMdUpd.fullName = fullName;
                    cMdUpd.label = name;
                MetadataService.CustomMetadataValue customField1 = new MetadataService.CustomMetadataValue();
                    customField1.field = 'NSP_Email_Address__c'; // the custom field API Name to be updated
                    switch on sandboxName {
                         when 'merge','test','stage' {
                            customField1.value = 'monica.adams@insperity.com';
                         }
                         when else {
                            customField1.value = cMdRecord.NSP_Email_Address__c.substringBefore('.invalid').trim() + '.invalid';
                         }
                     }
                cMdUpd.values.add(customField1); //add the changes to list of changes to be deployed

                if (allMetadataList[batch].size() >= 200) {
                    batch++;
                    allMetadataList.add(new List<MetadataService.Metadata>()); // create a new batch when we fill one up
                }
                allMetadataList[batch].add(cMdUpd);
            }

            if (allMetadataList.size() > 0 && !Test.isRunningTest()) {
                for (Integer i = 0; i < allMetadataList.size(); i ++) {
                    List<MetadataService.SaveResult> results = service.updateMetadata(allMetadataList[i]);
                }
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doCMetadata: ' + e.getMessage());
        }
    }

    public static void doCMetadataSvc(String sandboxName) {
        try {
            Integer batch = 0;
            MetadataService.MetadataPort service = createService();
            List<List<MetadataService.Metadata>> allMetadataList = new List<List<MetadataService.Metadata>>();
            allMetadataList.add(new List<MetadataService.Metadata>());
            List<NSP_ProjectTemplateMapping__mdt> cMdTmpls = [Select Id, Label, DeveloperName, Key__c, Template_ID__c, Template_Name__c FROM NSP_ProjectTemplateMapping__mdt WHERE Id!=Null];
            List<Template_Key_and_Id_Mapping__mdt> cMdTmplKeys = [Select Id, Label, DeveloperName, Key__c, Template_ID__c, Template_Name__c FROM Template_Key_and_Id_Mapping__mdt WHERE Id!=Null];
            List<pse__Proj__c> oProjTmpls = [Select Id, TemplateName__c FROM pse__Proj__c WHERE pse__Is_Template__c = true];
            Map<String, Id> mTmplId = new map<String, Id>();
            for (pse__Proj__c oProjTmpl : oProjTmpls) {
                mTmplId.put(oProjTmpl.TemplateName__c, oProjTmpl.Id);
            }

            for (NSP_ProjectTemplateMapping__mdt cMdTmpl : cMdTmpls) {
                if (mTmplId.containsKey(cMdTmpl.Template_Name__c) || Test.isRunningTest()) {
                    string name = cMdTmpl.DeveloperName;
                    string fullName = 'NSP_ProjectTemplateMapping.' + name; //custom metadata full name
                    MetadataService.CustomMetadata cMdUpd = new MetadataService.CustomMetadata();
                        cMdUpd.fullName = fullName;
                        cMdUpd.label = name;
                    MetadataService.CustomMetadataValue customField1 = new MetadataService.CustomMetadataValue();
                        customField1.field = 'Template_ID__c'; //the custom field API Name to be updated
                        customField1.value = mTmplId.get(cMdTmpl.Template_Name__c);
                    cMdUpd.values.add(customField1); //add the changes to list of changes to be deployed

                    if (allMetadataList[batch].size() >= 200) {
                        batch++;
                        allMetadataList.add(new List<MetadataService.Metadata>()); // create a new batch when we fill one up
                    }
                    allMetadataList[batch].add(cMdUpd);
                }
            }

            for (Template_Key_and_Id_Mapping__mdt cMdTmplKey : cMdTmplKeys) {
                if (mTmplId.containsKey(cMdTmplKey.Template_Name__c) || Test.isRunningTest()) {
                    string name = cMdTmplKey.DeveloperName;
                    string fullName = 'Template_Key_and_Id_Mapping.' + name; //custom metadata full name
                    MetadataService.CustomMetadata cMdUpd = new MetadataService.CustomMetadata();
                        cMdUpd.fullName = fullName;
                        cMdUpd.label = name;
                    MetadataService.CustomMetadataValue customField2 = new MetadataService.CustomMetadataValue();
                        customField2.field = 'Template_ID__c'; //the custom field API Name to be updated
                        customField2.value = mTmplId.get(cMdTmplKey.Template_Name__c);
                    cMdUpd.values.add(customField2); //add the changes to list of changes to be deployed
                    if (allMetadataList[batch].size() >= 200) {
                        batch++;
                        allMetadataList.add(new List<MetadataService.Metadata>());
                    }
                    allMetadataList[batch].add(cMdUpd);
                }
            }

            if (allMetadataList.size() > 0 && !Test.isRunningTest()) {
                for (Integer i = 0; i < allMetadataList.size(); i ++) {
                    List<MetadataService.SaveResult> results = service.updateMetadata(allMetadataList[i]);
                }
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doCMetadataSvc: ' + e.getMessage());
        }
    }
    
    public static void doCLabels(String sandboxName) {
        try {
            MetadataService.MetadataPort service = createService();
            List<MetadataService.Metadata> allMetadataList = new List<MetadataService.Metadata>();
            string cLabels = 'NSP_FTA_Base_URL,NSP_Docusign_Account_Id,NSP_Docusign_Base_URL';
            string[] cLNames = cLabels.split(',');
            for(integer i=0; i < cLNames.size() ; i++){
                MetadataService.CustomLabel cL = new MetadataService.CustomLabel();
                if(!Test.isRunningTest()){
                    cL = (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { cLNames[i] }).getRecords()[0];
                }else{
                    cL.fullName = cLNames[i];
                    cL.value = 'test';
                }
                if(cL.value != null){
                    MetadataService.CustomLabel cLUpd = new MetadataService.CustomLabel();
                    cLUpd.fullName = cL.fullName;
                    switch on cL.fullName {
                        when 'NSP_FTA_Base_URL' {
                            switch on sandboxName {
                                 when 'stage' {
                                     cLUpd.value = 'https://stageportalapps.insperity.com/financialcomparison/financialanalysis/';
                                 }
                                 when 'test' {
                                     cLUpd.value = 'https://testportalapps.insperity.com/financialcomparison/financialanalysis/';
                                 }
                                 when 'merge' {
                                     cLUpd.value = 'https://devportalapps.insperity.com/financialcomparison/financialanalysis/';
                                 }
                                 when else {
                                     cLUpd.value = 'https://devportalapps.insperity.com/financialcomparison/financialanalysis/';
                                 }
                             }
                         }
                        when 'NSP_Docusign_Account_Id' {
                           cLUpd.value = '65500';
                           switch on sandboxName {
                            when 'merge' {
                                cLUpd.value = '65500';
                            }
                            when 'test','stage' {
                                cLUpd.value = '48945';
                            }
                            when else {
                                cLUpd.value = '50202';
                            }
                        }
                        }
                        when 'NSP_Docusign_Base_URL' {
                           cLUpd.value = 'https://uatna11.springcm.com/atlas/doclauncher/OneClickDocGen';
                        }
                    }
                    cLUpd.shortDescription = cL.shortDescription;
                    cLUpd.language = cL.language;
                    cLUpd.protected_x = cL.protected_x;
                    allMetadataList.add(cLUpd);
                }
            }
            if(allMetadataList.size() > 0 && !Test.isRunningTest()){
                List<MetadataService.SaveResult> results = service.updateMetadata(allMetadataList);
                // for(MetadataService.SaveResult result: results){
                //     system.debug('Update Custom Label result success = ' + result.success);
                // }
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doCLabels: ' + e.getMessage());
        }
    }
    
    public static void doEmailCLabels() {
        try {
            Integer batch = 0;
            MetadataService.MetadataPort service = createService();
            List<List<MetadataService.Metadata>> allMetadataList = new List<List<MetadataService.Metadata>>();
            allMetadataList.add(new List<MetadataService.Metadata>());
            MetadataService.CustomLabel cL = (!Test.isRunningTest()) ? (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { 'Post_Refresh_Email_Labels' }).getRecords()[0] : new MetadataService.CustomLabel();
            MetadataService.CustomLabel cL2 = (!Test.isRunningTest()) ? (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { 'Post_Refresh_Email_Labels_2' }).getRecords()[0] : new MetadataService.CustomLabel();
            if(cL.value == null) cL.value = 'dummy';
            string[] cLNames = cL.value.split(',');
            string[] cLNames2 = (cL2.value == null) ? new string[]{} : cL2.value.split(',');
            if(cLNames2.size() > 0) cLNames.addAll(cLNames2);

            for(integer i=0; i < cLNames.size() ; i++){
                cL = (!Test.isRunningTest()) ? (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { cLNames[i] }).getRecords()[0] : new MetadataService.CustomLabel();
                cL.value = (!Test.isRunningTest()) ? cL.value : 'test@insperity.com';
                if((cL.value != null && cL.value.indexOf('@') != -1 && cL.value.indexOf('.invalid') == -1)) {
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

            if (allMetadataList.size() > 0 && !Test.isRunningTest()) {
                for (Integer i = 0; i < allMetadataList.size(); i ++) {
                    List<MetadataService.SaveResult> results = service.updateMetadata(allMetadataList[i]);
                }
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doEmailCLabels: ' + e.getMessage());
        }
    }

    public static void doEmailAlerts() {
        try {
            Integer batch = 0;
            string host = URL.getOrgDomainUrl().toExternalForm();
            string endPoint = host + '/services/data/v55.0/tooling/';
            string sessionId = UserInfo.getSessionId();
            List<String[]> wfaNames = new List<String[]>();
            wfaNames.add(new String[]{});
            MetadataService.MetadataPort service = createService();
            List<List<MetadataService.Metadata>> allMetadataList = new List<List<MetadataService.Metadata>>();
            
            //  Get the list of alerts Ids where CCemails is not empty
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endPoint + 'query/?q=SELECT+id+FROM+WorkflowAlert+WHERE+CCemails+>+\'\'');
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer '+ sessionId);
            HTTPResponse response = new HTTPResponse();
            AlertResult results = new AlertResult();
            RecordAlert[] records = new RecordAlert[] {};
                
            if(!Test.isRunningTest()){
                response = new Http().send(request);
                results = (AlertResult)JSON.deserialize(response.getBody(), AlertResult.class);
                records = results.records;
            }else{
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

            if (wfaNames.size() > 0) {
                for (Integer i = 0; i < wfaNames.size(); i++) {
                    MetadataService.ReadResult readResult = new MetadataService.ReadResult();
                    if (!Test.isRunningTest()) readResult.records = service.readMetadata('WorkflowAlert', wfaNames[i]).getRecords();
                    allMetadataList.add(new List<MetadataService.Metadata>());
                    for (MetadataService.Metadata wfaMeta : readResult.records) {
                        MetadataService.WorkflowAlert wfa = (MetadataService.WorkflowAlert) wfaMeta;
                        wfa.ccEmails = (!Test.isRunningTest()) ? invalidateEmailArray(wfa.ccEmails).split(',') : invalidateEmailArray(new String[]{'test@insperity.com'}).split(',');
                        allMetadataList[i].add(wfa);
                    }
                }
            }

            if (allMetadataList.size() > 0) {
                for (Integer i = 0; i < allMetadataList.size(); i ++) {
                    if (!Test.isRunningTest()) List<MetadataService.SaveResult> updResults = service.updateMetadata(allMetadataList[i]);
                }
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doEmailAlerts: ' + e.getMessage());
        }
    }

    public static void doCSettings(String sandboxName) {
        try {
            NSP_GoogleRecaptchaSettings__c cS1 = NSP_GoogleRecaptchaSettings__c.getOrgDefaults();
            cS1.NSP_SiteKey__c = '6LegnBQiAAAAAM_at9VCdc-X143lsbrvrgZPlOta';
            cS1.NSP_SiteUrl__c = 'https://insperity--' + sandboxName + '.sandbox.my.salesforce-sites.com/';
            upsert cS1;
        } catch(Exception e) {
            System.debug('An exception occurred in doCSettings: ' + e.getMessage());
        }

        try {
            NSP_Docusign_Account_Details__c cS2 = NSP_Docusign_Account_Details__c.getOrgDefaults();
            switch on sandboxName {
                when 'merge' {
                    cS2.Docusign_Account_Id__c = '65500';
                }
                when 'test','stage' {
                    cS2.Docusign_Account_Id__c = '48945';
                }
                when else {
                    cS2.Docusign_Account_Id__c = '50202';
                }
            }
            upsert cS2;
        } catch(Exception e) {
            System.debug('An exception occurred in doCSettings: ' + e.getMessage());
        }

        try {
            OrgSettings__c cS3 = OrgSettings__c.getOrgDefaults();
            cS3.OrgDomainUrl__c = URL.getOrgDomainUrl().toExternalForm().toLowerCase();
            cS3.Instance__c = [ SELECT InstanceName FROM Organization WHERE Id!=null LIMIT 1 ].InstanceName.toLowerCase();
            cS3.IsSandbox__c =  [ SELECT IsSandbox FROM Organization WHERE Id!=null LIMIT 1 ].IsSandbox;
            cS3.OrgId__c = [ SELECT Id FROM Organization WHERE Id!=null LIMIT 1 ].Id;
            cS3.SandboxApiName__c = sandboxName.toLowerCase();
            cS3.SandboxName__c = sandboxName;
            upsert cS3;
        } catch(Exception e) {
            System.debug('An exception occurred in doCSettings: ' + e.getMessage());
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
            System.debug('An exception occurred in doCSettings: ' + e.getMessage());
        }
            
        try {
            BoxFileRequest__c cS5 = BoxFileRequest__c.getOrgDefaults();
            cS5.BoxTemplateFolderId__c = '225207143235';
            upsert cS5;
        } catch(Exception e) {
            System.debug('An exception occurred in doCSettings: ' + e.getMessage());
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
                List<MetadataService.SaveResult> resultsUpd = service.updateMetadata(allMetadataList);
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doE2CAddresses: ' + e.getMessage());
        }
    }
    
    public static void doQueues() {
        try {
            List<Group> updateQueue = new List<Group>();
            for (Group queue:[SELECT id, email FROM Group WHERE type = 'Queue' AND email > '']) {
                if(queue.email.indexOf('.invalid') == -1){
                    queue.email = queue.email + '.invalid';
                    updateQueue.add(queue);
                }
            }
            if(!updateQueue.isEmpty()){
                update updateQueue;
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doQueues: ' + e.getMessage());
        }
    }
    
    public static void setPostRefreshRunFlag(Integer iStep) {
        try {            
            OrgSettings__c cS = OrgSettings__c.getOrgDefaults();
            if (iStep == 1) cS.PostRefreshRun__c = true;
            if (iStep == 2) cS.PostRefreshRun2__c = true;
            if (iStep == 3) cS.PostRefreshRun3__c = true;
            if (iStep == 4) cS.PostRefreshRun4__c = true;
            upsert cS;
        } catch(Exception e) {
            System.debug('An exception occurred in setPostRefreshRunFlag: ' + e.getMessage());
        }
    }
    
    public static MetadataService.MetadataPort createService() {
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }
    
    private static string invalidateEmailArray(List<String> origEmails) {
        string newES = '';
        for(integer i=0; i<origEmails.size() ; i++) {
            newES = (origEmails[i].indexOf('.invalid') == -1) ? newES + ',' + origEmails[i] + '.invalid' : newES + ',' + origEmails[i];
        }
        return newES.substringAfter(',');
    }
    
    private static string invalidateEmailString(String origES) {
        string[] origEmails = origES.split(',');
        string newES = '';
        for(integer i=0; i<origEmails.size() ; i++) {
            newES = (origEmails[i].indexOf('.invalid') == -1) ? newES + ',' + origEmails[i] + '.invalid' : newES + ',' + origEmails[i];
        }
        return newES.substringAfter(',');
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
}