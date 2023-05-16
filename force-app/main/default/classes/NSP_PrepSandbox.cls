global class NSP_PrepSandbox implements SandboxPostCopy {

    public String runManualResult{get;set;}
    global void runApexClass(SandboxContext context){
        System.debug('Org ID: ' + context.organizationId());
        System.debug('Sandbox ID: ' + context.sandboxId());
        System.debug('Sandbox Name: ' + context.sandboxName());
        doQueues();
        doCSettings(context.sandboxName());
    }

    public static void runManualSteps(){
        String sandbox = OrgSettings__c.getOrgDefaults().SandboxName__c;
        System.debug('Manual Step Sandbox Name: ' + sandbox);
        doUserImport(sandbox);      
        doCMetadata(sandbox);
        doCLabels();
        doEmailCLabels();
        doEmailAlerts();
        setPostRefreshRunFlag();
    }

    public pagereference runManualStepsButton(){
        try{
            doCMetadata(OrgSettings__c.getOrgDefaults().SandboxName__c);
            doCLabels();
            doEmailCLabels();
            doEmailAlerts();
            setPostRefreshRunFlag();
        } catch(Exception e) {
            runManualResult = 'An exception occurred Updating Metadata: ' + e.getMessage();
        }
        return null;
    }

    public pagereference doUserImportPage(){
        try{
            doUserImport(OrgSettings__c.getOrgDefaults().SandboxName__c);
            runManualResult = 'Post-Refresh Steps complete!';
        } catch(Exception e) {
            runManualResult = 'An exception occurred Importing Users: ' + e.getMessage();
        }
        return null;
    }

    public static void doUserImport(String sandboxName){
        try{
            System.debug('Starting doUserImport');
            StaticResource userStaticResource = [SELECT Body FROM StaticResource WHERE Name = 'PreProd_Users' WITH SECURITY_ENFORCED];
            String userCsv = userStaticResource.Body.toString();
            /* columns: 0 - ID
            // 			1 - Username
            // 			2 - Email
            // 			3 - FirstName
            // 			4 - LastName
            // 			5 - Profile
            // 			6 - Role            
            */
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
            for(integer i=1; i < rows.size() ; i++){ // skip header row
                String[] column = rows[i].split(',');
                String aliasEnd = (column[4].length() < 5) ? column[4].trim(), : column[4].substring(0,5);
                if (column[1].indexOf(sandboxName) > -1 && column[1].indexOf('integration') < 0 && column[2].indexOf('noreply') < 0){
                    userList.add(new User(
                        IsActive = true,
                        Email = column[2].trim(),
                        FirstName = column[3].trim(),
                        LastName = column[4].trim(),
                        Username = column[1].trim(),
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
            System.debug('userList size: ' + userList.size());
            if(!Test.isRunningTest()){
                Database.upsert(userList, User.Username, true);
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doUserImport: ' + e.getMessage());
        }
    }

    public static void doCMetadata(String sandboxName){
        try{
            System.debug('starting doCMetadata');
            MetadataService.MetadataPort service = createService();
            List<MetadataService.Metadata> allMetadataList = new List<MetadataService.Metadata>();
            List<NSP_DocuSign_Signers__mdt> cMd = [Select Id, Label, DeveloperName, NSP_Signer_Username__c FROM NSP_DocuSign_Signers__mdt];
    
            for(NSP_DocuSign_Signers__mdt cMdRecord : cMd){
                string name = cMdRecord.DeveloperName;
                string fullName = 'NSP_DocuSign_Signers.' + name; //custom metadata full name
                string signer_Username = cMdRecord.NSP_Signer_Username__c;
                system.debug('CustomMetadata: ' + fullName);
                
                MetadataService.CustomMetadata cMdUpd = new MetadataService.CustomMetadata();
                    cMdUpd.fullName = fullName;
                    cMdUpd.label = name;
                MetadataService.CustomMetadataValue customField1 = new MetadataService.CustomMetadataValue();
                    customField1.field = 'NSP_Signer_Username__c'; //the custom field API Name to be updated
                    customField1.value = signer_Username + '.' + sandboxName;
                cMdUpd.values.add(customField1); //add the changes to list of changes to be deployed
                allMetadataList.add(cMdUpd);
            }
            if(allMetadataList.size() > 0 && !Test.isRunningTest()){
                List<MetadataService.SaveResult> results = service.updateMetadata(allMetadataList);
                for(MetadataService.SaveResult result: results){
                    system.debug('Update Custom Metadata Type result success = ' + result.success);
                }
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doCMetadata: ' + e.getMessage());
        }
    }
    
    public static void doCLabels(){
        try {
            System.debug('starting doCLabels');
            MetadataService.MetadataPort service = createService();
            List<MetadataService.Metadata> allMetadataList = new List<MetadataService.Metadata>();
            string cLabels = (!Test.isRunningTest()) ? 'NSP_FTA_Base_URL,NSP_Docusign_Account_Id,NSP_Docusign_Base_URL' : 'test';
            string[] cLNames = cLabels.split(',');
            for(integer i=0; i < cLNames.size() ; i++){
                MetadataService.CustomLabel cL = new MetadataService.CustomLabel();
                if(!Test.isRunningTest()){
                    cL = (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { cLNames[i] }).getRecords()[0];
                }else{
                    cL.fullName = 'test';
                    cL.value = 'test';
                }
                if(cL.value != null){
                    System.debug('Custom Label found : ' + cL.fullName + ' : ' + cL.value);
                    MetadataService.CustomLabel cLUpd = new MetadataService.CustomLabel();
                    cLUpd.fullName = cL.fullName;
                    switch on cL.fullName {
                        when 'NSP_FTA_Base_URL' {
                           cLUpd.value = 'https://stageportalapps.insperity.com/financialcomparison/financialanalysis/';
                        }
                        when 'NSP_Docusign_Account_Id' {
                           cLUpd.value = '65500';
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
                for(MetadataService.SaveResult result: results){
                    system.debug('Update Custom Label result success = ' + result.success);
                }
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doCLabels: ' + e.getMessage());
        }
    }
    
    public static void doEmailCLabels(){
        try {
            System.debug('starting doEmailCLabels');
            MetadataService.MetadataPort service = createService();        
            List<MetadataService.Metadata> allMetadataList = new List<MetadataService.Metadata>();
            MetadataService.CustomLabel cL = (!Test.isRunningTest()) ? (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { 'NSP_Post_Refresh_Email_Labels' }).getRecords()[0] : new MetadataService.CustomLabel();
            System.debug('NSP_Post_Refresh_Email_Labels : ' + cL.value);
            if(cL.value == null) cL.value = 'NSP_WX_Email_DL,NSP_WO_Email_DL,NSP_Opportunity_Closed_Won_AlertAdditionalEmails,NSP_New_Client_Sales_Email,NSP_Mid_Market_Sales_Email,NSP_Channel_Prgram_Email';
            string[] cLNames = cL.value.split(',');
            for(integer i=0; i < cLNames.size() ; i++){
                cL = (!Test.isRunningTest()) ? (MetadataService.CustomLabel) service.readMetadata('CustomLabel', new String[] { cLNames[i] }).getRecords()[0] : new MetadataService.CustomLabel();
                cL.value = (!Test.isRunningTest()) ? cL.value : 'test@insperity.com';
                if((cL.value != null && cL.value.indexOf('@') != -1 && cL.value.indexOf('.invalid') == -1)) {
                    System.debug('Custom Label email found : ' + cL.fullName + ' : ' + cL.value);
                    MetadataService.CustomLabel cLUpd = new MetadataService.CustomLabel();
                    cLUpd.fullName = cL.fullName;
                    cLUpd.value = invalidateEmailString(cL.value);
                    cLUpd.shortDescription = cL.shortDescription;
                    cLUpd.language = cL.language;
                    cLUpd.protected_x = cL.protected_x;
                    allMetadataList.add(cLUpd);
                }
            }
            if(allMetadataList.size() > 0 && !Test.isRunningTest()){
                List<MetadataService.SaveResult> results = service.updateMetadata(allMetadataList);
                for(MetadataService.SaveResult result: results){
                    system.debug('Update Email Custom Label result success = ' + result.success);
                }
            }
        } catch(Exception e) {
            System.debug('An exception occurred in doEmailCLabels: ' + e.getMessage());
        }
    }

    public static void doEmailAlerts(){
        System.debug('starting doEmailAlerts');
        string host = URL.getOrgDomainUrl().toExternalForm();
        string endPoint = host + '/services/data/v55.0/tooling/';
        string sessionId = UserInfo.getSessionId();
        MetadataService.MetadataPort service = createService();
        
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
            att.type = 'test';
            att.url = 'test';
            rec.FullName='test';
            rec.id='test';
        	rec.attributes = att;
            records.add(rec);
        }
        
        for(RecordAlert alert : records){
            // Get the Alert meta-data
            request = new HttpRequest();
            request.setEndpoint(host + alert.attributes.url);
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer '+ sessionId);
            MetadataService.WorkflowAlert wfa = new MetadataService.WorkflowAlert();
            
            if(!Test.isRunningTest()){
                response = new Http().send(request);
                WorkflowEmail wfe = (WorkflowEmail)JSON.deserialize(response.getBody(), WorkflowEmail.class);
                wfa = (MetadataService.WorkflowAlert) service.readMetadata('WorkflowAlert', new String[] { wfe.FullName }).getRecords()[0];
                string emails = invalidateEmailArray(wfa.ccEmails);
            }else{
                response = new HTTPResponse();
            }

            System.debug('Workflow Alert additional email found : ' + wfa.fullName + ' : ' + wfa.ccEmails);
            MetadataService.WorkflowAlert wfaUpd = new MetadataService.WorkflowAlert();
            wfaUpd.fullName = wfa.fullName;
            wfaUpd.ccEmails = (!Test.isRunningTest()) ? invalidateEmailArray(wfa.ccEmails).split(',') : new String[]{'test@insperity.com'};
            wfaUpd.description = wfa.description;
            wfaUpd.protected_x = wfa.protected_x;
            wfaUpd.senderType = wfa.senderType;
            wfaUpd.template = wfa.template;
            List<MetadataService.Metadata> allMetadataList = new List<MetadataService.Metadata>();
            allMetadataList.add(wfaUpd);

            if(allMetadataList.size() > 0 && !Test.isRunningTest()) {
                List<MetadataService.SaveResult> resultsUpd = service.updateMetadata(allMetadataList);
                for(MetadataService.SaveResult resultUpd: resultsUpd) {
                    system.debug('Update Workflow Alert additional emails result success = ' + resultUpd.success);
                }
            }
        }
    }
    
    public static void doCSettings(String sandboxName){
        try {
            System.debug('starting doCSettings');
            NSP_GoogleRecaptchaSettings__c cS1 = NSP_GoogleRecaptchaSettings__c.getOrgDefaults();
            cS1.NSP_SiteKey__c = '6Lc9ZIAeAAAAAHl4KudsEIeOVfmKRqyCo1Wq7gD5';
            cS1.NSP_SiteUrl__c = 'https://webforms.secure.force.com/';
            upsert cS1;
            System.debug('NSP_GoogleRecaptchaSettings.NSP_SiteKey : ' + cS1.NSP_SiteKey__c);
            System.debug('NSP_GoogleRecaptchaSettings.NSP_SiteUrl : ' + cS1.NSP_SiteUrl__c);
            
            NSP_Docusign_Account_Details__c cS2 = NSP_Docusign_Account_Details__c.getOrgDefaults();
            cS2.Docusign_Account_Id__c = '65500';
            upsert cS2;
            System.debug('NSP_Docusign_Account_Details.NSP_SiteKey : ' + cS2.Docusign_Account_Id__c);
            
            OrgSettings__c cS3 = OrgSettings__c.getOrgDefaults();
            cS3.OrgDomainUrl__c = URL.getOrgDomainUrl().toExternalForm().toLowerCase();
            cS3.Instance__c = [ SELECT InstanceName FROM Organization LIMIT 1 ].InstanceName.toLowerCase();
            cS3.IsSandbox__c =  [ SELECT IsSandbox FROM Organization LIMIT 1 ].IsSandbox;
            cS3.OrgId__c = [ SELECT Id FROM Organization LIMIT 1 ].Id;
            cS3.SandboxApiName__c = sandboxName.toLowerCase();
            cS3.SandboxName__c = sandboxName;
            upsert cS3;
            System.debug('OrgSettings__c.OrgDomainUrl__c : ' + cS3.OrgDomainUrl__c);
            System.debug('OrgSettings__c.Instance__c : ' + cS3.Instance__c);
            System.debug('OrgSettings__c.IsSandbox__c : ' + cS3.IsSandbox__c);
            System.debug('OrgSettings__c.OrgId__c : ' + cS3.OrgId__c);
            System.debug('OrgSettings__c.SandboxApiName__c : ' + cS3.SandboxApiName__c);
            System.debug('OrgSettings__c.SandboxName__c : ' + cS3.SandboxName__c);
        } catch(Exception e) {
            System.debug('An exception occurred in doCSettings: ' + e.getMessage());
        }
    }
    
    public static void doQueues(){
        try {
            System.debug('starting doQueues');
            List<Group> updateQueue = new List<Group>();
            for(Group queue:[SELECT id, email FROM Group WHERE type = 'Queue' AND email > ''])
            {
                //System.debug('Queue Email :' + queue.email);
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
    
    public static void setPostRefreshRunFlag(){
        try {
            System.debug('starting setPostRefreshRunFlag');
            OrgSettings__c cS = OrgSettings__c.getOrgDefaults();
            cS.PostRefreshRun__c = true;
            upsert cS;
            System.debug('OrgSettings__c.PostRefreshRun__c : ' + cS.PostRefreshRun__c);
        } catch(Exception e) {
            System.debug('An exception occurred in setPostRefreshRunFlag: ' + e.getMessage());
        }
    }
    
    public static MetadataService.MetadataPort createService(){
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        return service;
    }
    
    private static string invalidateEmailArray(List<String> origEmails){
        string newES = '';
        for(integer i=0; i<origEmails.size() ; i++) {
            newES = (origEmails[i].indexOf('.invalid') == -1) ? newES + ',' + origEmails[i] + '.invalid' : newES + ',' + origEmails[i];
        }
        return newES.substringAfter(',');
    }
    
    private static string invalidateEmailString(string origES){
        string[] origEmails = origES.split(',');
        string newES = '';
        for(integer i=0; i<origEmails.size() ; i++) {
            newES = (origEmails[i].indexOf('.invalid') == -1) ? newES + ',' + origEmails[i] + '.invalid' : newES + ',' + origEmails[i];
        }
        return newES.substringAfter(',');
    }

    private class AlertResult{
        public Integer totalSize;
        public Boolean done;
        public String queryLocator;    
        public RecordAlert[] records;
    }

    private class RecordAlert{
        public Attributes attributes{get;set;}
        public string id{get;set;}
        public string FullName{get;set;}
    }

    private class Attributes{
        public string type{get;set;}
        public string url{get;set;}
    }

    private class WorkflowEmail{
        public Attributes attributes;
        public string Id ;
        public string TemplateId;
        public String CcEmails;
        public String Description;
        public String DeveloperName;
        public string EntityDefinitionId;
        public MetadataService.WorkflowAlert Metadata;
        public String FullName;
    }
}