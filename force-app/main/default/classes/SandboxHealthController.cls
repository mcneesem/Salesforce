public with sharing class SandboxHealthController {
    // test w/ SandboxHealthControllerTest (81%)

    static final string STRING_INVALID = '.invalid';
    static final string STRING_RECORDS = 'Records presence';
    static final string STRING_CLEARED = 'Cleared to blank';
    static final string STRING_ONE_REC = 'At least one record';
    static final string STRING_MISSING = 'Missing value';
    static final string STRING_ENDS_W = 'Ends with ';

    public enum STATUS {
        PASS , FAIL , WARN
    }

    public class Check {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String expected;
        @AuraEnabled public String actual;
        @AuraEnabled public String message;
        @AuraEnabled public String status; // STATUS name
    }

    public class Section {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public List<Check> checks;
        @AuraEnabled public String status;
        @AuraEnabled public String category; // e.g., CUSTOM_SETTINGS, LABELS, SECURITY, OTHER
    }

    // Store DS account and CLM base URL as locals in the DocuSign verification scope,
    // then pass those expected values into the Account Details verification method.
    // This avoids non-static state on a controller used by cacheable wire methods.

    /**
     * Calculates the overall status for a section based on individual check statuses
     * Logic: If ALL checks are PASS -> Section PASS, If ANY check is FAIL -> Section FAIL,
     * If NO checks are FAIL but some are WARN -> Section WARN, Else Section WARN (empty or all warn)
     */
    private static String calculateSectionStatus( List<Check> checks ) {
        Boolean hasFail = false;
        Boolean hasWarn = false;
        String secStat = STATUS.PASS.name();

        if ( ( checks == null ) || checks.isEmpty() ) {
            secStat = STATUS.WARN.name(); // Default to WARN for empty sections
        } else {
            for ( Check check : checks ) {
                if ( check.status == STATUS.FAIL.name() ) {
                    hasFail = true;
                    break; // Early exit on first fail
                } else if ( check.status == STATUS.WARN.name() ) {
                    hasWarn = true;
                }
            }

            if ( hasFail ) {
                secStat = STATUS.FAIL.name();
            } else if ( hasWarn ) {
                secStat = STATUS.WARN.name();
            }
        }

        return secStat;
    }

    public class HealthResult {
        @AuraEnabled public List<Section> sections;
        @AuraEnabled public String sandboxName;
        @AuraEnabled public String orgId;
        @AuraEnabled public String instance;
        @AuraEnabled public Boolean isPipeline;
        @AuraEnabled public Boolean isSandbox;
        @AuraEnabled public Datetime evaluatedAt;
    }

    @AuraEnabled( cacheable=true )
    public static HealthResult getHealth() {
        return SandboxHealthController.getHealth( false );
    }

    public static HealthResult getHealth( Boolean isMockSandbox ) {
        HealthResult res = new HealthResult();
        res.sections = new List<Section>();
        res.evaluatedAt = System.now();

        // Org context
        String sandbox = System.DomainParser.parse( URL.getOrgDomainUrl() ).getSandboxName();
        sandbox = ( String.isNotBlank( sandbox ) ? sandbox.toLowerCase() : '' );

        String[] pipelineOrgs = new String[] { 'merge' , 'test' , 'stage' };
        res.sandboxName = sandbox;
        Organization orgInfo = [SELECT Id, InstanceName, IsSandbox FROM Organization WHERE Id != null LIMIT 1];
        OrgSettings__c orgSettings = NSP_PrepSandbox.getOrgSettings();
        res.orgId = orgInfo.Id;
        res.instance = orgInfo.InstanceName;
        res.isPipeline = pipelineOrgs.contains( sandbox );
        res.isSandbox = ( ( isMockSandbox ) ? isMockSandbox : orgSettings.IsSandbox__c );

        if ( !res.isSandbox ) {
            res.sections.add( verifyExternalIdObjects() );
        } else {
            // Custom Labels
            res.sections.add( verifyAppCustomLabels( sandbox ) );
            res.sections.add( verifyEmailCustomLabels() );

            // Custom Metadata checks (from doCMetadata and doCMetadataSvc)
            res.sections.add( verifyDocuSignRESTMetadata( sandbox ) );
            res.sections.add( verifyDocuSignSignersMetadata( sandbox ) );
            res.sections.add( verifyPEOMetadata( sandbox ) );
            res.sections.add( verifyProjectTemplateMappingMetadata() );
            res.sections.add( verifyRetirementServicesMetadata() );
            res.sections.add( verifyTemplateKeyAndIdMappingMetadata() );

            // Custom Settings checks (from doCSettings and doCSettings2)
            res.sections.add( verifyBoxFileRequest() );
            // Resolve DocuSign context to get expected downstream values
            DocuSignContext dsCtx = verifyDocuSignSettings( sandbox );
            res.sections.add( verifyContractTerminationSettings() );
            res.sections.add( verifyDocusignAccountDetails( dsCtx.accountNumber , dsCtx.clmBaseUrl ) );
            res.sections.add( dsCtx.section );
            res.sections.add( verifyEnvironmentDetails( sandbox ) );
            res.sections.add( verifyGoogleRecaptchaSettings( sandbox ) );
            res.sections.add( verifyNVMContactWorldSettings( sandbox ) );
            res.sections.add( verifyOrgSettings( sandbox ) );
            res.sections.add( verifyProjectCreationSettings() );
            res.sections.add( verifySalesTeamEmailSettings() );
            if ( !res.isPipeline ) {
                res.sections.add( verifyUserTriggerSettings() );
            }
            res.sections.add( verifyWingspanSettings() );

            // Other checks
            res.sections.add( verifyImageDocuments() );
            res.sections.add( verifyQueuesEmailSuffix() );
            res.sections.add( verifyCspTrustedSites() );
        }

        return res;
    }

    // ========== Custom Settings Sections (verification only, user-mode) ==========

    // 1) DocuSign_Settings__c (hierarchy/custom settings, keyed by Name like DEV/TEST/STAGE,...)
    // Helper DTO to return both the built section and extracted values needed downstream
    public class DocuSignContext {
        public Section section;
        public String accountNumber;
        public String clmBaseUrl;
    }

    private static DocuSignContext verifyDocuSignSettings( String sandbox ) {
        Section s = new Section();
        s.key = 'DocuSign_Settings__c';
        s.label = 'DocuSign Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        String resolvedAccount = null;
        String resolvedClmBase = null;

        try {
            Map<String, DocuSign_Settings__c> all = DocuSign_Settings__c.getAll();
            if ( all == null || all.isEmpty() ) {
                s.checks.add( newFail( 'dss_missing_all' , STRING_RECORDS , 'At least one row' , 'None' , 'No DocuSign_Settings__c rows found' ) );
            } else {
                // Determine expected row by NSP_PrepSandbox logic (prefix match)
                String keyVal = ( String.isEmpty( sandbox ) || sandbox.toUpperCase().startsWith( 'DEV' ) ) ? 'DEV' : sandbox.toUpperCase();

                DocuSign_Settings__c row = DocuSign_Settings__c.getValues( keyVal );
                resolvedAccount = ( row == null ) ? null : row.AccountNumber__c;
                resolvedClmBase = ( row == null ) ? null : row.CLMBaseUrl__c;
                Boolean expectedEnabled = String.isNotBlank( sandbox ) && sandbox.startsWith( keyVal.left(3).toLowerCase() );
                s.checks.add( checkBool( 'dss_enabled' , keyVal + ' IsEnabled__c' , expectedEnabled , row != null && row.IsEnabled__c ) );
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'dss_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read DocuSign_Settings__c: ' + e.getMessage() ) );
        }

        s.status = SandboxHealthController.calculateSectionStatus( s.checks );
        DocuSignContext ctx = new DocuSignContext();
        ctx.section = s;
        ctx.accountNumber = resolvedAccount;
        ctx.clmBaseUrl = resolvedClmBase;
        return ctx;
    }

    // 2) Wingspan_Settings__c (only DEV IsEnabled__c true per NSP_PrepSandbox)
    private static Section verifyWingspanSettings() {
        Section s = new Section();
        s.key = 'Wingspan_Settings__c';
        s.label = 'Wingspan Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            Map<String, Wingspan_Settings__c> all = Wingspan_Settings__c.getAll();
            if ( all == null || all.isEmpty() ) {
                s.checks.add( newFail( 'wss_missing_all' , STRING_RECORDS , 'Row named DEV' , 'None' , 'No Wingspan_Settings__c rows found' ) );
            } else {
                Wingspan_Settings__c dev = all.get( 'DEV' );
                Boolean actual = ( dev != null ) && dev.IsEnabled__c;
                s.checks.add( checkBool( 'wss_is_dev_enabled' , 'DEV IsEnabled__c' , true , actual ) );
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'wss_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read Wingspan_Settings__c: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 3) NSP_GoogleRecaptchaSettings__c (org defaults set SiteKey and SiteUrl)
    private static Section verifyGoogleRecaptchaSettings( String sandbox ) {
        Section s = new Section();
        s.key = 'NSP_GoogleRecaptchaSettings__c';
        s.label = 'Google reCAPTCHA Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            NSP_GoogleRecaptchaSettings__c def = NSP_GoogleRecaptchaSettings__c.getOrgDefaults();
            String expectedKey = '6LegnBQiAAAAAM_at9VCdc-X143lsbrvrgZPlOta';
            String expectedUrlSuffix = '.sandbox.my.salesforce-sites.com/';
            String expectedUrl = 'https://insperity--' + sandbox + expectedUrlSuffix;
            s.checks.add( checkExact( 'rec_key' , 'NSP_SiteKey__c' , expectedKey , ( def == null ) ? null : def.NSP_SiteKey__c ) );
            s.checks.add( checkExact( 'rec_url' , 'NSP_SiteUrl__c' , expectedUrl , ( def == null ) ? null : def.NSP_SiteUrl__c ) );
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'rec_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read NSP_GoogleRecaptchaSettings__c: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 4) NSP_Docusign_Account_Details__c (org defaults optionally set when values available)
    private static Section verifyDocusignAccountDetails( String expectedAccountId , String expectedClmBaseUrl ) {
        Section s = new Section();
        s.key = 'NSP_Docusign_Account_Details__c';
        s.label = 'Docusign Account Details';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            NSP_Docusign_Account_Details__c def = NSP_Docusign_Account_Details__c.getOrgDefaults();
            s.checks.add( checkExact( 'dad_clm' , 'CLM_Base_URL__c' , expectedClmBaseUrl , ( def == null ) ? null : def.CLM_Base_URL__c ) );
            s.checks.add( checkExact( 'dad_acct' , 'Docusign_Account_Id__c' , expectedAccountId , ( def == null ) ? null : def.Docusign_Account_Id__c ) );
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'dad_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read NSP_Docusign_Account_Details__c: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 5) OrgSettings__c (org defaults mirror org context)
    private static Section verifyOrgSettings( String sandbox ) {
        Section s = new Section();
        s.key = 'OrgSettings__c';
        s.label = 'Org Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            OrgSettings__c orgset = OrgSettings__c.getOrgDefaults();
            Organization orgInfo = [SELECT Id, InstanceName, IsSandbox FROM Organization WHERE Id != null LIMIT 1];
            if ( ( orgset != null )
              && ( orgInfo != null ) ) {
                s.checks.add( checkExact( 'org_domain' , 'OrgDomainUrl__c' , URL.getOrgDomainUrl().toExternalForm().toLowerCase() , orgset.OrgDomainUrl__c));
                s.checks.add( checkExact( 'org_instance' , 'Instance__c' , orgInfo.InstanceName.toLowerCase() , orgset.Instance__c));
                s.checks.add( checkBool( 'org_is_sbx' , 'IsSandbox__c' , orgInfo.IsSandbox , orgset.IsSandbox__c));
                s.checks.add( checkExact( 'org_id' , 'OrgId__c' , orgInfo.Id , orgset.OrgId__c));
                s.checks.add( checkExact( 'org_sb_api' , 'SandboxApiName__c' , sandbox , orgset.SandboxApiName__c));
                s.checks.add( checkExact( 'org_sb_name' , 'SandboxName__c' , sandbox , orgset.SandboxName__c));
            } else {
                s.checks.add( newWarn('org_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read ' + ( ( orgset != null ) ? 'Organization' : 'OrgSettings__c' ) ) );
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn('org_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to verify OrgSettings__c: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 6) NSP_Environment_Details__c (org defaults NSP_Detailed_Data__c branch by sandbox)
    private static Section verifyEnvironmentDetails( String sandbox ) {
        Section s = new Section();
        s.key = 'NSP_Environment_Details__c';
        s.label = 'Environment Details';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            NSP_Environment_Details__c def = NSP_Environment_Details__c.getOrgDefaults();
            String expectedVal;
            switch on sandbox {
                when 'stage' { expectedVal = 'stage1'; }
                when 'test' { expectedVal = 'test1'; }
                when 'merge' { expectedVal = 'dev1'; }
                when else { expectedVal = 'dev1'; }
            }
            s.checks.add( checkExact( 'env_data' , 'NSP_Detailed_Data__c' , expectedVal , ( def == null ) ? null : def.NSP_Detailed_Data__c ) );
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'env_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read NSP_Environment_Details__c: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 7) BoxFileRequest__c (org defaults has BoxTemplateFolderId__c hardcoded)
    private static Section verifyBoxFileRequest() {
        Section s = new Section();
        s.key = 'BoxFileRequest__c';
        s.label = 'Box File Request';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            BoxFileRequest__c def = BoxFileRequest__c.getOrgDefaults();
            s.checks.add( checkExact( 'box_tmpl' , 'BoxTemplateFolderId__c' , '225207143235' , ( def == null ) ? null : def.BoxTemplateFolderId__c ) );
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'box_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read BoxFileRequest__c: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 8) UserTriggerSettings__c (org defaults cleared to nulls)
    @TestVisible
    private static Section verifyUserTriggerSettings() {
        Section s = new Section();
        s.key = 'UserTriggerSettings__c';
        s.label = 'User Trigger Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            UserTriggerSettings__c def = UserTriggerSettings__c.getOrgDefaults();
            s.checks.add( checkBlank('uts_admins', 'AllowedAdmins__c', STRING_CLEARED, ( def == null ) ? null : def.AllowedAdmins__c));
            s.checks.add( checkBlank('uts_bcc', 'BccAddresses__c', STRING_CLEARED, ( def == null ) ? null : def.BccAddresses__c));
        } catch ( Exception e ) {
            s.checks.add( newWarn('uts_query', 'Access', 'Queryable', 'Error', 'Unable to read UserTriggerSettings__c: ' + e.getMessage()));
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 9) Contract_Termination_Settings__c (org defaults clears AutoTerminationEmailAddresses__c)
    private static Section verifyContractTerminationSettings() {
        Section s = new Section();
        s.key = 'Contract_Termination_Settings__c';
        s.label = 'Contract Termination Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            Contract_Termination_Settings__c def = Contract_Termination_Settings__c.getOrgDefaults();
            s.checks.add( checkBlank('cts_auto', 'AutoTerminationEmailAddresses__c', STRING_CLEARED, ( def == null ) ? null : def.AutoTerminationEmailAddresses__c));
        } catch ( Exception e ) {
            s.checks.add( newWarn('cts_query', 'Access', 'Queryable', 'Error', 'Unable to read Contract_Termination_Settings__c: ' + e.getMessage()));
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 10) NVMContactWorld__Settings__c (org defaults sets clientId based on sandbox)
    private static Section verifyNVMContactWorldSettings(String sandbox) {
        Section s = new Section();
        s.key = 'NVMContactWorld__Settings__c';
        s.label = 'NVM ContactWorld Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            NVMContactWorld__Settings__c def = NVMContactWorld__Settings__c.getOrgDefaults();
            String expectedId;
            switch on sandbox {
                when 'merge' { expectedId = 'dz02lkbjl01'; }
                when 'test' { expectedId = 'mfb4hpckwhw'; }
                when else { expectedId = null; }
            }
            if ( expectedId == null ){
                s.checks.add( checkBlank('nvm_client', 'NVMContactWorld__clientId__c', STRING_CLEARED, ( def == null ) ? null : def.NVMContactWorld__clientId__c));
            } else {
                s.checks.add( checkExact('nvm_client', 'NVMContactWorld__clientId__c', expectedId, ( def == null ) ? null : def.NVMContactWorld__clientId__c));
            }

        } catch ( Exception e ) {
            s.checks.add( newWarn('nvm_query', 'Access', 'Queryable', 'Error', 'Unable to read NVMContactWorld__Settings__c: ' + e.getMessage()));
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 11) Sales_Team_Email_Settings__c (org defaults with specific values, many .invalid)
    private static Section verifySalesTeamEmailSettings() {
        Section s = new Section();
        s.key = 'Sales_Team_Email_Settings__c';
        s.label = 'Sales Team Email Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            Sales_Team_Email_Settings__c def = Sales_Team_Email_Settings__c.getOrgDefaults();
            s.checks.add( checkExact( 'stes_bcc' , 'BccEmailAddress__c' , 'test.datacollection_sfqa2@insperity.com' , ( def == null ) ? null : def.BccEmailAddress__c ) );
            s.checks.add( checkSuffix( 'stes_nat' , 'NationalAccountEmailAddress__c' , STRING_INVALID , ( def == null ) ? null : def.NationalAccountEmailAddress__c , true ) );
            s.checks.add( checkSuffix( 'stes_pcm' , 'PrivateCapitalMarketEmailAddress__c' , STRING_INVALID , ( def == null ) ? null : def.PrivateCapitalMarketEmailAddress__c , true ) );
            s.checks.add( checkSuffix( 'stes_str' , 'StrategicSalesEmailAddress__c' , STRING_INVALID , ( def == null ) ? null : def.StrategicSalesEmailAddress__c , true ) );
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'stes_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read Sales_Team_Email_Settings__c: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 12) ProjectCreationSettings__c (org defaults with specific DefaultRegionId__c)
    private static Section verifyProjectCreationSettings() {
        Section s = new Section();
        s.key = 'ProjectCreationSettings__c';
        s.label = 'Project Creation Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            ProjectCreationSettings__c pcs = ProjectCreationSettings__c.getOrgDefaults();
            List<pse__Region__c> reg = [SELECT Id FROM pse__Region__c WHERE Name = 'United States' LIMIT 1];
            if ( ( pcs != null )
              && ( reg != null ) ) {
                s.checks.add( checkExact( 'pcs_regid' , 'DefaultRegionId__c' , reg[0].id , pcs.DefaultRegionId__c ) );
            } else {
                s.checks.add( newWarn( 'pcs_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read ' + ( ( pcs != null ) ? 'pse__Region__c' : 'ProjectCreationSettings__c' ) ) );
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'pcs_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to verify ProjectCreationSettings__c' ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // ========== Custom Metadata Sections (verification only, user-mode) ==========

    // 1) NSP_DocuSign_Signers__mdt (from doCMetadata)
    private static Section verifyDocuSignSignersMetadata( String sandbox ) {
        Section s = new Section();
        s.key = 'NSP_DocuSign_Signers__mdt';
        s.label = 'DocuSign Signers Metadata';
        s.category = 'CUSTOM_METADATA';
        s.checks = new List<Check>();

        try {
            List<NSP_DocuSign_Signers__mdt> records = [SELECT Id, Label, DeveloperName, NSP_Signer_Username__c FROM NSP_DocuSign_Signers__mdt WHERE Id != null WITH SECURITY_ENFORCED];
            if ( records.isEmpty() ) {
                s.checks.add( newFail( 'ds_signers_missing' , STRING_RECORDS , STRING_ONE_REC , 'None' , 'No NSP_DocuSign_Signers__mdt records found' ) );
            } else {
                // Check that each record has a valid username with sandbox suffix
                for (NSP_DocuSign_Signers__mdt record : records) {
                    String key = 'ds_signer_' + record.DeveloperName;
                    String label = record.Label;
                    String actual = record.NSP_Signer_Username__c;
                    // Expected format: username.sandboxname (based on NSP_PrepSandbox.doDS_mdt)
                    String expectedSuffix = '.' + sandbox;
                    s.checks.add( checkSuffix( key , label , expectedSuffix , actual ) );
                }
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'ds_signers_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read NSP_DocuSign_Signers__mdt: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 2) DocuSignRESTSettings__mdt (from doCMetadata)

    // Required DocuSignRESTSettings__mdt per NSP_PrepSandbox.doDSREST_mdt()
    private static Map<String, String> requiredDocuSignRESTMetadata(String sandboxName) {
        Map<String, String> m = new Map<String, String>();

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
            if ( key.startsWith( keyVal ) ) {
                keyVal = key;
                break;
            }
        }
        DocuSign_Settings__c docusignSettings = DocuSign_Settings__c.getValues( keyVal );
        if ( docusignSettings != null ) {
            m.put( 'CLMv2ApiEndpoint' , 'https://api' + docusignSettings.CLMBaseUrl__c + '/v2/' );
            m.put( 'DSAccountID' , docusignSettings.AccountId__c );
            m.put( 'DSUserName' , docusignSettings.UserId__c );
            m.put( 'NSP_Docusign_Callback_Username' , docusignSettings.Docusign_Callback_Username__c );
            m.put( 'RequestAuthDomain' , docusignSettings.BaseUrl__c );
            m.put( 'RequestAuthEndpoint' , 'https://' + docusignSettings.BaseUrl__c + '/oauth/token' );
            m.put( 'NSP_Invoice_Workflow_Name' , 'Invoice AutoGen' );
            m.put( 'RequestAuthBody' , 'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' );
            m.put( 'RequestAuthContentType' , 'application/x-www-form-urlencoded' );
            m.put( 'RequestIntegratorKey' , docusignSettings.IntegrationKey__c );
            m.put( 'RequestScope' , 'signature impersonation spring_read spring_write' );
            m.put(
                'RequestPrivateKey' ,
                docusignSettings.PrivateKey1__c
                    + docusignSettings.PrivateKey2__c
                    + docusignSettings.PrivateKey3__c
                    + docusignSettings.PrivateKey4__c
                    + docusignSettings.PrivateKey5__c
                    + docusignSettings.PrivateKey6__c
                    + docusignSettings.PrivateKey7__c
            );
        }

        return m;
    }

    private static Section verifyDocuSignRESTMetadata(String sandboxName) {
        Section s = new Section();
        s.key = 'DocuSignRESTSettings__mdt';
        s.label = 'DocuSign REST Settings Metadata';
        s.category = 'CUSTOM_METADATA';
        s.checks = new List<Check>();

        Map<String,String> required = requiredDocuSignRESTMetadata( sandboxName );

        try {
            List<DocuSignRESTSettings__mdt> records = [SELECT Id, Label, DeveloperName, Value__c FROM DocuSignRESTSettings__mdt WHERE Id != null WITH SECURITY_ENFORCED];
            if ( records.isEmpty() ) {
                s.checks.add( newFail( 'ds_rest_missing' , STRING_RECORDS , STRING_ONE_REC , 'None' , 'No DocuSignRESTSettings__mdt records found' ) );
            } else if ( required.isEmpty() ) {
                s.checks.add( newFail( 'ds_settings_missing' , STRING_RECORDS , STRING_ONE_REC , 'None' , 'No DocuSign_Settings__c records found' ) );
            } else {
                // Check that each record has a value set (based on NSP_PrepSandbox.doDSREST_mdt)
                for ( DocuSignRESTSettings__mdt record : records ) {
                    String key = 'ds_rest_' + record.DeveloperName;
                    String label = record.Label;
                    String actual = record.Value__c;
                    // Should not be null or blank
                    if ( String.isBlank( actual ) ) {
                        s.checks.add( newFail( key , label , 'Not blank' , actual , 'Value should not be blank' ) );
                    } else {
                        s.checks.add( checkExact( key , label , required.get( label ) , actual ) );
                    }
                }
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'ds_rest_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read DocuSignRESTSettings__mdt: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 3) NSP_PEO_Implementations__mdt (from doCMetadata)
    private static Section verifyPEOMetadata(String sandboxName) {
        Section s = new Section();
        s.key = 'NSP_PEO_Implementations__mdt';
        s.label = 'PEO Implementations Metadata';
        s.category = 'CUSTOM_METADATA';
        s.checks = new List<Check>();

        try {
            List<NSP_PEO_Implementations__mdt> records = [SELECT Id, Label, DeveloperName, NSP_Email_Address__c FROM NSP_PEO_Implementations__mdt WHERE Id != null WITH SECURITY_ENFORCED];
            if ( records.isEmpty() ) {
                s.checks.add( newFail( 'peo_missing' , STRING_RECORDS , STRING_ONE_REC , 'None' , 'No NSP_PEO_Implementations__mdt records found' ) );
            } else {
                String expected = 'monica.adams@insperity.com';
                // Check that each record has a valid email address with sandbox suffix (based on NSP_PrepSandbox.doPEO_mdt)
                for (NSP_PEO_Implementations__mdt record : records) {
                    String key = 'peo_' + record.DeveloperName;
                    String label = record.Label;
                    String actual = record.NSP_Email_Address__c;
                    switch on sandboxName {
                        when 'merge','test','stage','devserva','devservb','devservx' {
                            s.checks.add( checkExact( key , label , expected , actual ) );
                        }
                        when else {
                            s.checks.add( checkSuffix( key , label , STRING_INVALID , actual , true ) );
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'peo_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read NSP_PEO_Implementations__mdt: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 4) NSP_Retirement_Services__mdt (from doCMetadata)
    private static Section verifyRetirementServicesMetadata() {
        Section s = new Section();
        s.key = 'NSP_Retirement_Services__mdt';
        s.label = 'Retirement Services Metadata';
        s.category = 'CUSTOM_METADATA';
        s.checks = new List<Check>();

        try {
            List<NSP_Retirement_Services__mdt> records = [SELECT Id, Label, DeveloperName, NSP_Email_Address__c FROM NSP_Retirement_Services__mdt WHERE Id != null WITH SECURITY_ENFORCED];
            if ( records.isEmpty() ) {
                s.checks.add( newFail( 'ret_missing' , STRING_RECORDS , STRING_ONE_REC , 'None' , 'No NSP_Retirement_Services__mdt records found' ) );
            } else {
                // Check that each record has a valid email address with sandbox suffix (based on NSP_PrepSandbox.doRET_mdt)
                for (NSP_Retirement_Services__mdt record : records) {
                    String key = 'ret_' + record.DeveloperName;
                    String label = record.Label;
                    String actual = record.NSP_Email_Address__c;
                    // Should be in the format email.invalid or have .[SANDBOX] suffix in dev sandboxes
                    s.checks.add( checkSuffix( key , label , STRING_INVALID , actual , true ) );
                }
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'ret_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read NSP_Retirement_Services__mdt: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 5) NSP_ProjectTemplateMapping__mdt (from doCMetadataSvc)
    private static Section verifyProjectTemplateMappingMetadata() {
        Section s = new Section();
        s.key = 'NSP_ProjectTemplateMapping__mdt';
        s.label = 'Project Template Mapping Metadata';
        s.category = 'CUSTOM_METADATA';
        s.checks = new List<Check>();

        try {
            List<NSP_ProjectTemplateMapping__mdt> records = [ SELECT Id , Label , DeveloperName , Key__c , Template_ID__c , Template_Name__c FROM NSP_ProjectTemplateMapping__mdt WHERE Id != null WITH SECURITY_ENFORCED ];

            if ( records.isEmpty() ) {
                s.checks.add( newFail( 'tmpl_missing' , STRING_RECORDS , STRING_ONE_REC , 'None' , 'No NSP_ProjectTemplateMapping__mdt records found' ) );
            } else if ( SandboxHealthController.mTmplId == null ) {
                s.checks.add( newWarn( 'proj_tmpl_missing' , STRING_RECORDS , STRING_ONE_REC , 'None' , 'No pse__Proj__c template records found' ) );
            } else {
                // Check that each record has a template ID set (based on NSP_PrepSandbox.doTmpls_mdt)
                for ( NSP_ProjectTemplateMapping__mdt record : records ) {
                    s.checks.add( templCheck( record.Template_Name__c.trim() , 'tmpl_' + record.DeveloperName , record.Label , record.Template_ID__c ) );
                }
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn('tmpl_query', 'Access', 'Queryable', 'Error', 'Unable to read NSP_ProjectTemplateMapping__mdt: ' + e.getMessage()));
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // 6) Template_Key_and_Id_Mapping__mdt (from doCMetadataSvc)
    private static Section verifyTemplateKeyAndIdMappingMetadata() {
        Section s = new Section();
        s.key = 'Template_Key_and_Id_Mapping__mdt';
        s.label = 'Template Key and ID Mapping Metadata';
        s.category = 'CUSTOM_METADATA';
        s.checks = new List<Check>();

        try {
            List<Template_Key_and_Id_Mapping__mdt> records = [ SELECT Id , Label , DeveloperName , Key__c , Template_ID__c , Template_Name__c FROM Template_Key_and_Id_Mapping__mdt WHERE Id != null WITH SECURITY_ENFORCED ];

            if ( records.isEmpty() ) {
                s.checks.add( newFail( 'tmplkey_missing' , STRING_RECORDS , STRING_ONE_REC , 'None' , 'No Template_Key_and_Id_Mapping__mdt records found' ) );
            } else if ( SandboxHealthController.mTmplId == null ) {
                s.checks.add( newWarn( 'proj_tmpl_missing' , STRING_RECORDS , STRING_ONE_REC , 'None' , 'No pse__Proj__c template records found' ) );
            } else {
                // Check that each record has a template ID set (based on NSP_PrepSandbox.doTmplKeys_mdt)
                for ( Template_Key_and_Id_Mapping__mdt record : records ) {
                    s.checks.add( templCheck( record.Template_Name__c.trim() , 'tmplkey_' + record.DeveloperName , record.Label , record.Template_ID__c ) );
                }
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn( 'tmplkey_query' , 'Access' , 'Queryable' , 'Error' , 'Unable to read Template_Key_and_Id_Mapping__mdt: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    private static Check templCheck( String tmplName , String key , String label , String actual ) {
        Check c = new Check();
        // Should not be null or blank (when mapping to actual templates)
        if ( String.isBlank( actual ) ) {
            c = newFail( key , label , 'Template ID' , actual , 'Template ID should not be blank' );
        } else {
            c = checkExact( key , label , SandboxHealthController.mTmplId.get( tmplName ) , actual );
        }
        return c;
    }

    // Queues email suffix verification (.invalid), mirrors NSP_PrepSandbox.doQueues() but read-only
    private static Section verifyQueuesEmailSuffix() {
        Section s = new Section();
        s.key = 'queuesEmailSuffix';
        s.label = 'Queue Emails';
        s.category = 'SECURITY';
        s.checks = new List<Check>();

        List<Group> queues = new List<Group>();
        try {
            queues = [
                SELECT Id, Name, Email
                FROM Group
                WHERE Type = 'Queue' AND Email > ''
                WITH SECURITY_ENFORCED
            ];

            if ( queues.isEmpty() ) {
                s.checks.add( newWarn(
                    'queues_none',
                    'Queues with Email',
                    'At least one queue with email',
                    'None found',
                    'No Queue groups with non-blank email were found'
                ));
            } else {
                for ( Group q : queues ) {
                    String key = 'queue_' + String.valueOf( q.Id );
                    String label = q.Name;
                    s.checks.add( checkSuffix( key , label , STRING_INVALID , q.Email , true ) );
                }
            }
        } catch ( Exception e ) {
            s.checks.add( newWarn(
                'queues_query',
                'Queues',
                'Readable via user-context',
                'No access',
                'Unable to read Queue Groups with email: ' + e.getMessage()
            ));
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // ---------- Small helpers to build checks ----------
    private static Check newCheck( String key , String label , String expected , String actual , String message , STATUS st ) {
        Check c = new Check();
        c.key = key;
        c.label = label;
        c.expected = expected;
        c.actual = actual;
        c.message = message;
        c.status = st.name();
        return c;
    }

    private static Check newFail( String key , String label , String expected , String actual , String message ) {
        return newCheck( key , label , expected , actual , message , STATUS.FAIL );
    }

    private static Check newPass( String key , String label , String expected , String actual , String message ) {
        return newCheck( key , label , expected , actual , message , STATUS.PASS );
    }

    private static Check newWarn( String key , String label , String expected , String actual , String message ) {
        return newCheck( key , label , expected , actual , message , STATUS.WARN );
    }

    private static Check checkExact( String key , String label , String expected , String actual ) {
        Check c = new Check();
        if ( actual == null ) {
            c = newFail( key , label , expected , 'null' , STRING_MISSING );
        } else {
            c = ( expected == actual )
                ? newPass( key , label , expected , actual , 'Matches expected' )
                : newFail( key , label , expected , actual , 'Value mismatch' );
        }

        return c;
    }

    private static Check checkBool( String key , String label , Boolean expected , Boolean actual ) {
        Check c = new Check();
        if ( actual == null ) {
            c = newFail( key , label , String.valueOf(expected) , 'null' , STRING_MISSING );
        } else {
            c = ( expected == actual )
                ? newPass(key, label, String.valueOf(expected), String.valueOf(actual), 'Matches expected')
                : newFail(key, label, String.valueOf(expected), String.valueOf(actual), 'Value mismatch');
        }

        return c;
    }

    private static Check checkBlank( String key , String label , String expectedDesc , String actual ) {
        return String.isBlank( actual )
            ? newPass(key, label, expectedDesc, actual, 'Cleared as expected')
            : newFail(key, label, expectedDesc, actual, 'Should be blank');
    }

    private static Check checkSuffix( String key , String label , String expectedSuffix , String actual , Boolean blankAllowed ) {
        Check c = new Check();
        if ( String.isBlank( actual ) ) {
            c = blankAllowed
                ? newPass( key , label , actual , actual , 'Blank value OK' )
                : newFail( key , label , STRING_ENDS_W + expectedSuffix , actual , STRING_MISSING );
        } else {
            c = actual.endsWith( expectedSuffix )
                ? newPass( key , label , STRING_ENDS_W + expectedSuffix , actual , 'Has required suffix' )
                : newFail( key , label , STRING_ENDS_W + expectedSuffix , actual , 'Missing required suffix' );
        }

        return c;
    }

    private static Check checkSuffix( String key , String label , String expectedSuffix , String actual ) {
        return checkSuffix( key , label , expectedSuffix , actual , false );
    }

    // Placeholder expectations for CSP Trusted Sites (keys must match CspTrustedSite fullName)
    // Matches NSP_PrepSandbox.doTrustedURLs() target names/URLs
    private static Map<String, String> requiredCspSites() {
        Map<String, String> m = new Map<String, String>();
        m.put('Tableau', 'https://testtableau.insperity.com');
        m.put('Salesforce_SCRT', 'https://*.sandbox.my.salesforce-scrt.com');
        m.put('Salesforce_Setup', 'https://*.sandbox.my.salesforce-setup.com');
        return m;
    }

    private static Section verifyCspTrustedSites() {
        Section s = new Section();
        s.key = 'cspTrustedSites';
        s.label = 'Trusted URLs';
        s.category = 'SECURITY';
        s.checks = new List<Check>();

        Map<String,String> required = requiredCspSites();

        // Read metadata via Metadata API (verification only). Fallback: Tooling not required; use MetadataService through NSP_PrepSandbox.createService if available.
        // We avoid direct dependency on NSP_PrepSandbox by performing a SOQL check to CspTrustedSite where possible for presence,
        // then compare endpoint via Metadata read for exact endpointUrl.
        // Note: The CspTrustedSite sObject is available for query in many orgs; WITH SECURITY_ENFORCED for user context.
        Map<String, String> actualByName = new Map<String,String>();
        try {
            // Try to read via sObject first for presence and active flag
            // DeveloperName available as Name in CspTrustedSite (fullName in metadata equals DeveloperName)
            for ( CspTrustedSite ts : [ SELECT Id , DeveloperName , EndpointUrl , IsActive FROM CspTrustedSite WITH SECURITY_ENFORCED ] ) {
                actualByName.put( ts.DeveloperName , ts.EndpointUrl );
            }
        } catch ( Exception e ) {
            // If sObject not queryable for the running user, leave actualByName empty and mark WARN
        }

        for ( String key : required.keySet() ) {
            String expectedUrl = required.get( key );
            String actualUrl = actualByName.containsKey( key ) ? actualByName.get( key ) : null;

            if (actualUrl == null) {
                s.checks.add( newFail('csp_' + key, key, expectedUrl, 'null', 'Missing Trusted Site: ' + key ) );
            } else {
                s.checks.add( checkExact( 'csp_' + key , key , expectedUrl , actualUrl ) );
            }
        }

        // If we failed to query any CspTrustedSite rows and list is empty, emit a WARN
        if ( s.checks.isEmpty() ) {
            s.checks.add( newWarn(
                'csp_query',
                'Trusted URLs',
                'Readable via user-context',
                'No data',
                'Unable to read CspTrustedSite. Verify permissions or run with a user who can view Setup records.'
            ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // Required image Documents created by NSP_PrepSandbox.doImageDocs()
    // Verifies presence in the 'Services' folder with public visibility.
    private static Map<String, String> requiredImageDocs() {
        // Map of metadata names (used by NSP_PrepSandbox) to expected human-readable Document Name
        // NSP_PrepSandbox sets Document.fullName = 'Services/' + name + '.png' and doc.name = replaceUnderscoresWithSpaces(name)
        Map<String, String> m = new Map<String, String>();
        m.put( 'Insperity_Copyright_Logo' , 'Insperity_Copy_write_logo' );
        m.put( 'Insperity_Footer_Logo' , 'Insperity_Footer_Logo' );
        m.put( 'Insperity_HR' , 'Insperity_HR' );
        m.put( 'Insperity_HR_Logo' , 'Insperity_HR_Logo' );
        m.put( 'Insperity_Service_Operations' , 'Insperity_Service_Operations' );
        m.put( 'InsperityEmailSignatureLogo' , 'InsperityEmailSignatureLogo' );
        return m;
    }

    private static Section verifyImageDocuments() {
        Section s = new Section();
        s.key = 'imageDocuments';
        s.label = 'Image Documents';
        s.category = 'OTHER';
        s.checks = new List<Check>();

        Map<String, String> required = requiredImageDocs();

        // Build a lookup of Documents in Services folder by Name
        Map<String, Document> byName = new Map<String, Document>();
        try {
            // Document is classic; enforce user-context security
            for ( Document d : [
                    SELECT Id , Name , Folder.Name , IsPublic , IsInternalUseOnly , Type
                    FROM Document
                    WHERE (
                            ( Folder.Name = 'Services' )
                        AND ( IsPublic = true )
                        AND ( IsInternalUseOnly = false )
                        )
                    WITH SECURITY_ENFORCED
                ] )
            {
                byName.put(d.Name, d);
            }
        } catch ( Exception e ) {
            // empty byName will emit WARN
        }

        if( byName == null || byName.isEmpty() ) {
            // If user can't access Documents, emit a WARN
            s.checks.add( newWarn(
                'docs_query' ,
                'Image Documents' ,
                'Queryable via user-context' ,
                'No access' ,
                'Unable to read Document records in Services folder'
            ) );
        } else {
            // For each required metadata key, compute the expected human-readable Document.Name
            for ( String metaKey : required.keySet() ) {
                String expectedDocName = required.get(metaKey).replace('_' , ' ');
                Document d = byName.get( expectedDocName );

                if ( d == null ) {
                    s.checks.add( newFail(
                        'doc_presence_' + metaKey ,
                        expectedDocName ,
                        'Exists in Services' ,
                        'Missing' ,
                        'Document not found in Services folder or is not public'
                    ));
                    continue;
                }

                if ( String.isBlank( d.Type ) ) {
                    s.checks.add( newWarn( 'doc_type_' + metaKey , expectedDocName , 'png' , 'blank' , 'Document found but type not available' ) );
                } else if ( d.Type?.toLowerCase() != 'png' ) {
                    s.checks.add( newWarn( 'doc_type_' + metaKey , expectedDocName , 'png' , d.Type , 'Document found but expected PNG type' ) );
                } else {
                    s.checks.add( newPass( 'doc_type_' + metaKey , expectedDocName , d.Name , 'Document found' , 'Document found as expected' ) );
                }
            }
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // ========== ExternalId objects verification (based on OrgSettings fields containing 'externalidobjects') ==========
    private static List<String> getExternalIdObjectNames( OrgSettings__c orgSettings ) {
        List<String> names = new List<String>();
        if ( orgSettings != null ) {
            Set<String> orgFields = Schema.SObjectType.OrgSettings__c.fields.getMap().keySet();
            for ( String f : orgFields ) {
                if ( ( f != null )
                  && ( f.toLowerCase().contains( 'externalidobjects' ) ) ) {
                    String val = (String) orgSettings.get( f );
                    names = parseExternalIdField( names , val );
                }
            }
        }
        return names;
    }

    private static List<String> parseExternalIdField( List<String> names , String val ) {
        if ( String.isNotBlank( val ) ) {
            for ( String entry : val.split( ',' ) ) {
                String obj = entry.trim();
                if ( String.isNotBlank( obj )
                    && !names.contains( obj ) ) {
                    names.add(obj);
                }
            }
        }
        return names;
    }

    private static void evaluateExternalIdForObject(Section target, String objName) {
        String key = 'extid_' + objName;
        String label = objName;
        try {
            String soql = 'SELECT count() FROM ' + objName + ' WHERE NSP_External_Id__c = null';
            Integer cnt = Database.countQuery( soql );
            if ( cnt == 0 ) {
                target.checks.add( newPass( key , label , 'No blank NSP_External_Id__c' , '0' , 'No records with blank ExternalId' ) );
            } else {
                String msgSub = ( cnt == 1 ) ? 'record' : 'records';
                target.checks.add( newFail( key , label , 'No blank NSP_External_Id__c' , String.valueOf(cnt) , cnt + ' ' + msgSub + ' with blank NSP_External_Id__c' ) );
            }
        } catch (Exception ex) {
            target.checks.add( newWarn( key , label , 'Validated' , 'unavailable' , 'Unable to validate ' + objName + ': ' + ex.getMessage() ) );
        }
    }

    @TestVisible
    private static Section verifyExternalIdObjects() {
        Boolean skipProcessing = false;
        Section s = new Section();
        s.key = 'externalIdObjects';
        s.label = 'ExternalId Objects';
        s.category = 'DATA_QUALITY';
        s.checks = new List<Check>();

        try {
            OrgSettings__c orgSettings = OrgSettings__c.getOrgDefaults();
            if ( orgSettings == null ) {
                s.checks.add( newWarn( 'extid_orgsettings_missing' , 'OrgSettings__c' , 'Configured' , 'none' , 'OrgSettings__c.getOrgDefaults() returned null' ) );
                skipProcessing = true;
            }

            // gather warnings about unreadable fields (only if we have orgSettings)
            List<String> objNames = new List<String>();
            if ( !skipProcessing ) {
                objNames = getExternalIdObjectNames( orgSettings );
                if ( objNames.isEmpty() ) {
                    s.checks.add( newWarn( 'extid_none_configured' , 'ExternalId object list' , 'At least one configured' , 'None' , 'No OrgSettings__c fields containing \"externalidobjects\" with values were found' ) );
                    skipProcessing = true;
                }
            }

            // If not skipped, evaluate each object
            if ( !skipProcessing ) {
                List<Check> perObjectChecks = new List<Check>();
                for ( String objName : objNames ) {
                    Section tmpSec = new Section();
                    tmpSec.checks = new List<Check>();
                    evaluateExternalIdForObject( tmpSec , objName );
                    if ( tmpSec.checks != null && !tmpSec.checks.isEmpty() ) {
                        perObjectChecks.addAll( tmpSec.checks );
                    }
                }
                if ( !perObjectChecks.isEmpty() ) {
                    s.checks.addAll( perObjectChecks );
                }
            }
        } catch (Exception e) {
            s.checks.add( newWarn( 'extid_unexpected' , 'ExternalId Objects' , 'Validated' , 'Error' , 'Unexpected error: ' + e.getMessage() ) );
        }

        return SandboxHealthController.finalizeSection( s );
    }

    // Placeholder required labels. These align with NSP_PrepSandbox.doCLabels() and doEmailCLabels() examples.
    @TestVisible
    private static Map<String, String> requiredLabels(String sandbox) {
        Map<String, String> m = new Map<String, String>();
        // Baseline placeholders
        try {
            List<Account> accountRecord = [SELECT id FROM Account WHERE NSP_AIMS_Client__c = '500' LIMIT 1];
            m.put( 'NSP_Insperity_Account' , ( accountRecord != null ) ? accountRecord[0].id : '500 Account not found' );
        } catch ( Exception e ) {
            m.put( 'NSP_Insperity_Account' , '500 Account not found' );
        }

        m.put( 'NSP_Docusign_Base_URL', 'https://uatna11.springcm.com/atlas/doclauncher/OneClickDocGen' );

        // Sandbox-specific values from NSP_PrepSandbox.doCLabels()
        if ( sandbox == 'stage' ) {
            m.put( 'NSP_FTA_Base_URL', 'https://stageportalapps.insperity.com/financialcomparison/financialanalysis/' );
            m.put( 'NSP_Docusign_Account_Id', '48945' );
            m.put( 'NSP_Contact_Center_Email_Addresses', 'test.contact_center_UAT@insperity.com.invalid' );
            m.put( 'NSP_Health_Welfare_Section_125', 'test.section125_UAT@insperity.com.invalid' );
        } else if ( sandbox == 'test' ) {
            m.put( 'NSP_FTA_Base_URL', 'https://testportalapps.insperity.com/financialcomparison/financialanalysis/' );
            m.put( 'NSP_Docusign_Account_Id', '65500' );
            m.put( 'NSP_Contact_Center_Email_Addresses', 'test.contact_center@insperity.com.invalid' );
            m.put( 'NSP_Health_Welfare_Section_125', 'test.section125@insperity.com.invalid' );
        } else if ( sandbox == 'merge' ) {
            m.put( 'NSP_FTA_Base_URL', 'https://devportalapps.insperity.com/financialcomparison/financialanalysis/' );
            m.put( 'NSP_Docusign_Account_Id', '122677');
            m.put( 'NSP_Contact_Center_Email_Addresses', 'test.contact_center.merge@insperity.com.invalid' );
            m.put( 'NSP_Health_Welfare_Section_125', 'test.section125.merge@insperity.com.invalid' );
        } else {
            // default dev orgs
            m.put( 'NSP_FTA_Base_URL', 'https://devportalapps.insperity.com/financialcomparison/financialanalysis/' );
            m.put( 'NSP_Docusign_Account_Id', '50202' );
        }
        return m;
    }

    private static Section verifyAppCustomLabels( String sandbox ) {
        Section core = new Section();
        core.key = 'customLabels';
        core.label = 'App Labels';
        core.category = 'LABELS';
        core.checks = new List<Check>();

        Map<String,String> expected = requiredLabels( sandbox );

        // Verify known labels via direct System.Label references (including Contact Center and Section 125)
        Map<String,String> directLabelActuals = new Map<String,String>{
            'NSP_Insperity_Account' => System.Label.NSP_Insperity_Account ,
            'NSP_Docusign_Base_URL' => System.Label.NSP_Docusign_Base_URL ,
            'NSP_FTA_Base_URL' => System.Label.NSP_FTA_Base_URL ,
            'NSP_Docusign_Account_Id' => System.Label.NSP_Docusign_Account_Id ,
            'NSP_Contact_Center_Email_Addresses' => System.Label.NSP_Contact_Center_Email_Addresses ,
            'NSP_Health_Welfare_Section_125' => System.Label.NSP_Health_Welfare_Section_125
        };

        for ( String lblName : expected.keySet() ) {
            String exp = expected.get( lblName );
            String act = directLabelActuals.containsKey( lblName ) ? directLabelActuals.get( lblName ) : null;

            if ( String.isBlank( act ) ) {
                core.checks.add( newFail( 'label_' + lblName , lblName , exp , act , 'Label value unavailable via System.Label. Ensure the label exists and is referenced here.' ) );
            } else {
                core.checks.add( checkExact( 'label_' + lblName , lblName , exp , act ) );
            }
        }

        return SandboxHealthController.finalizeSection( core );
    }

    private static Section verifyEmailCustomLabels() {
        Section email = new Section();
        email.key = 'emailCustomLabels';
        email.label = 'Email Labels';
        email.category = 'LABELS';
        email.checks = new List<Check>();

        List<String> dynamicLabelNames = new List<String>();
        String list1 = System.Label.Post_Refresh_Email_Labels;
        if (String.isNotBlank( list1 )) {
            dynamicLabelNames.addAll( new List<String>( list1.split(',') ) );
        }

        String list2 = System.Label.Post_Refresh_Email_Labels_2;
        if (String.isNotBlank( list2 )) {
            dynamicLabelNames.addAll( new List<String>( list2.split(',') ) );
        }

        Set<String> uniqueNames = new Set<String>();
        for (String n : dynamicLabelNames) {
            if ( n != null ) {
                uniqueNames.add( n.trim() );
            }
        }

        for ( String lblName : uniqueNames ) {
            if ( String.isBlank( lblName ) ) {
                continue;
            }
            String actual = null;
            try {
                // Use namespace-aware overload: System.Label.get(namespace, name)
                // No namespace for these labels, so pass empty string as namespace per feedback
                actual = System.Label.get( '' , lblName );
            } catch ( Exception e ) {
                actual = null;
            }

            email.checks.add( checkSuffix( 'email_label_' + lblName , lblName , STRING_INVALID , actual , true) );
        }

        return SandboxHealthController.finalizeSection( email );
    }

    private static Map<String, Id> mTmplId {
        // Get map of Project Template names and IDs (based on NSP_PrepSandbox.doTmpls_mdt)
        private get {
            if ( mTmplId == null ) {
                Map<String, Id> tmp = new Map<String, Id>();
                for (pse__Proj__c t : [ SELECT Id , TemplateName__c FROM pse__Proj__c WHERE pse__Is_Template__c = true ]) {
                    if ( t.TemplateName__c != null ) {
                        tmp.put( t.TemplateName__c.trim() , t.Id );
                    }
                }
                mTmplId = tmp;
            }
            return mTmplId;
        }
        private set;
    }

    // Finalize a section: sort checks by label (alphabetical, null-safe) and set status
    private static Section finalizeSection( Section s ) {
        if ( s != null ) {
            if ( s.checks != null && !s.checks.isEmpty() ) {
                // Group checks by label to ensure stable grouping for identical labels
                Map<String, List<Check>> byLabel = new Map<String, List<Check>>();
                for ( Check c : s.checks ) {
                    String lbl = ( c.label == null ) ? '' : c.label;
                    if ( !byLabel.containsKey( lbl ) ) {
                        byLabel.put( lbl , new List<Check>() );
                    }
                    byLabel.get( lbl ).add( c );
                }
                s.checks = sortSectionChecks( byLabel );
            }
            s.status = SandboxHealthController.calculateSectionStatus( s.checks );
        }
        return s;
    }

    private static List<Check> sortSectionChecks( Map<String, List<Check>> byLabel ) {
        // Separate checks by status
        Map<String, Map<String, List<Check>>> byStatusAndLabel = new Map<String, Map<String, List<Check>>>{
            STATUS.FAIL.name() => new Map<String, List<Check>>(),
            STATUS.WARN.name() => new Map<String, List<Check>>(),
            STATUS.PASS.name() => new Map<String, List<Check>>()
        };

        // Group checks by status, then by label
        for ( String lbl : byLabel.keySet() ) {
            for ( Check c : byLabel.get( lbl ) ) {
                String status = ( c.status == null ) ? STATUS.WARN.name() : c.status;
                if ( !byStatusAndLabel.get( status ).containsKey( lbl ) ) {
                    byStatusAndLabel.get( status ).put( lbl , new List<Check>() );
                }
                byStatusAndLabel.get( status ).get( lbl ).add( c );
            }
        }

        // Sort and build final list: FAIL, then WARN, then PASS (each alphabetically)
        List<Check> sorted = new List<Check>();
        for ( String status : new String[] { STATUS.FAIL.name() , STATUS.WARN.name() , STATUS.PASS.name() } ) {
            List<String> labels = new List<String>( byStatusAndLabel.get( status ).keySet() );
            labels.sort();
            for ( String lbl : labels ) {
                sorted.addAll( byStatusAndLabel.get( status ).get( lbl ) );
            }
        }

        return sorted;
    }
}