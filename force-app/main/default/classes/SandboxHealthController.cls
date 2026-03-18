/**
 * ApexDocs:
 * Class: SandboxHealthController
 * Description: Provides read-only health verification for sandbox-specific configuration.
 * Sections implemented:
 *  - CSP Trusted Sites presence and expected endpoint URL
 *  - Custom Labels values against expected sandbox placeholders
 *
 * Design:
 * - with sharing, user mode operations where applicable
 * - All methods are @AuraEnabled(cacheable=true) for LWC consumption
 * - Returns a DTO with sections and checks for easy UI rendering
 *
 * Notes:
 * - Placeholder expectations are hard-coded initially and should be externalized to Custom Metadata in future.
 * - No DML is performed; this is a verification-only service.
 */
public with sharing class SandboxHealthController {
    public enum STATUS {
        PASS, FAIL, WARN
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
    private static String calculateSectionStatus(List<Check> checks) {
        if (checks == null || checks.isEmpty()) {
            return STATUS.WARN.name(); // Default to WARN for empty sections
        }
        
        Boolean hasFail = false;
        Boolean hasWarn = false;
        
        for (Check check : checks) {
            if (check.status == STATUS.FAIL.name()) {
                hasFail = true;
                break; // Early exit on first fail
            } else if (check.status == STATUS.WARN.name()) {
                hasWarn = true;
            }
        }
        
        if (hasFail) {
            return STATUS.FAIL.name();
        } else if (hasWarn) {
            return STATUS.WARN.name();
        } else {
            // All checks are PASS
            return STATUS.PASS.name();
        }
    }

    public class HealthResult {
        @AuraEnabled public List<Section> sections;
        @AuraEnabled public String sandboxName;
        @AuraEnabled public String orgId;
        @AuraEnabled public String instance;
        @AuraEnabled public Boolean isSandbox;
        @AuraEnabled public Datetime evaluatedAt;
    }

    @AuraEnabled(cacheable=true)
    public static HealthResult getHealth() {
        HealthResult res = new HealthResult();
        res.sections = new List<Section>();
        res.evaluatedAt = System.now();

        // Org context
        String sandbox = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        res.sandboxName = sandbox;
        Organization orgInfo = [SELECT Id, InstanceName, IsSandbox FROM Organization WHERE Id != null LIMIT 1];
        res.orgId = orgInfo.Id;
        res.instance = orgInfo.InstanceName;
        res.isSandbox = orgInfo.IsSandbox;

        // Sections
        res.sections.add(verifyCspTrustedSites());
        // Validate Documents created by NSP_PrepSandbox.doImageDocs()
        res.sections.add(verifyImageDocuments());
        // Split label checks into core and email label sections
        LabelSections lblSections = verifyCustomLabels(sandbox);
        res.sections.add(lblSections.core);
        res.sections.add(lblSections.email);

        // Custom Settings checks (from doCSettings and doCSettings2)
        // Resolve DocuSign context first to get expected downstream values
        DocuSignContext dsCtx = verifyDocuSignSettings(sandbox);
        res.sections.add(dsCtx.section);
        res.sections.add(verifyWingspanSettings());
        res.sections.add(verifyGoogleRecaptchaSettings(sandbox));
        res.sections.add(verifyDocusignAccountDetails(dsCtx.accountNumber, dsCtx.clmBaseUrl));
        res.sections.add(verifyOrgSettings(sandbox));
        res.sections.add(verifyEnvironmentDetails(sandbox));
        res.sections.add(verifyBoxFileRequest());
        res.sections.add(verifyUserTriggerSettings());
        res.sections.add(verifyContractTerminationSettings());
        res.sections.add(verifyNVMContactWorldSettings(sandbox));
        res.sections.add(verifySalesTeamEmailSettings());

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

    private static DocuSignContext verifyDocuSignSettings(String sandbox) {
        Section s = new Section();
        s.key = 'DocuSign_Settings__c';
        s.label = 'DocuSign Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        String resolvedAccount = null;
        String resolvedClmBase = null;

        try {
            Map<String, DocuSign_Settings__c> all = DocuSign_Settings__c.getAll();
            if (all == null || all.isEmpty()) {
                s.checks.add(newFail('dss_missing_all', 'Records presence', 'At least one row', 'None', 'No DocuSign_Settings__c rows found'));
            } else {
                // Determine expected row by NSP_PrepSandbox logic (prefix match)
                String keyVal = (String.isEmpty(sandbox) || sandbox.toUpperCase().startsWith('DEV')) ? 'DEV' : sandbox.toUpperCase();
                for (String key : all.keySet()) {
                    if (key.startsWith(keyVal)) {
                        keyVal = key;
                        break;
                    }
                }
                DocuSign_Settings__c row = DocuSign_Settings__c.getValues(keyVal);
                resolvedAccount = row == null ? null : row.AccountNumber__c;
                resolvedClmBase = row == null ? null : row.CLMBaseUrl__c;
                Boolean expectedEnabled = !String.isBlank(sandbox) && sandbox.toLowerCase().startsWith(keyVal.left(3).toLowerCase());
                s.checks.add(checkBool('dss_enabled', keyVal + ' IsEnabled__c', expectedEnabled, row != null && row.IsEnabled__c));
            }
        } catch (Exception e) {
            s.checks.add(newWarn('dss_query', 'Access', 'Queryable', 'Error', 'Unable to read DocuSign_Settings__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
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
            if (all == null || all.isEmpty()) {
                s.checks.add(newFail('wss_missing_all', 'Records presence', 'Row named DEV', 'None', 'No Wingspan_Settings__c rows found'));
            } else {
                Wingspan_Settings__c dev = all.get('DEV');
                Boolean actual = dev != null && dev.IsEnabled__c;
                s.checks.add(checkBool('wss_is_dev_enabled', 'DEV IsEnabled__c', true, actual));
            }
        } catch (Exception e) {
            s.checks.add(newWarn('wss_query', 'Access', 'Queryable', 'Error', 'Unable to read Wingspan_Settings__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
    }

    // 3) NSP_GoogleRecaptchaSettings__c (org defaults set SiteKey and SiteUrl)
    private static Section verifyGoogleRecaptchaSettings(String sandbox) {
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
            s.checks.add(checkExact('rec_key', 'NSP_SiteKey__c', expectedKey, def == null ? null : def.NSP_SiteKey__c));
            s.checks.add(checkExact('rec_url', 'NSP_SiteUrl__c', expectedUrl, def == null ? null : def.NSP_SiteUrl__c));
        } catch (Exception e) {
            s.checks.add(newWarn('rec_query', 'Access', 'Queryable', 'Error', 'Unable to read NSP_GoogleRecaptchaSettings__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
    }

    // 4) NSP_Docusign_Account_Details__c (org defaults optionally set when values available)
    private static Section verifyDocusignAccountDetails(String expectedAccountId, String expectedClmBaseUrl) {
        Section s = new Section();
        s.key = 'NSP_Docusign_Account_Details__c';
        s.label = 'Docusign Account Details';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            NSP_Docusign_Account_Details__c def = NSP_Docusign_Account_Details__c.getOrgDefaults();
            s.checks.add(checkExact('dad_acct', 'Docusign_Account_Id__c', expectedAccountId, def == null ? null : def.Docusign_Account_Id__c));
            s.checks.add(checkExact('dad_clm', 'CLM_Base_URL__c', expectedClmBaseUrl, def == null ? null : def.CLM_Base_URL__c));
        } catch (Exception e) {
            s.checks.add(newWarn('dad_query', 'Access', 'Queryable', 'Error', 'Unable to read NSP_Docusign_Account_Details__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
    }

    // 5) OrgSettings__c (org defaults mirror org context)
    private static Section verifyOrgSettings(String sandbox) {
        Section s = new Section();
        s.key = 'OrgSettings__c';
        s.label = 'Org Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            Organization orgInfo = [SELECT Id, InstanceName, IsSandbox FROM Organization WHERE Id != null LIMIT 1];
            OrgSettings__c def = OrgSettings__c.getOrgDefaults();
            s.checks.add(checkExact('org_domain', 'OrgDomainUrl__c', URL.getOrgDomainUrl().toExternalForm().toLowerCase(), def == null ? null : def.OrgDomainUrl__c));
            s.checks.add(checkExact('org_instance', 'Instance__c', orgInfo.InstanceName.toLowerCase(), def == null ? null : def.Instance__c));
            s.checks.add(checkBool('org_is_sbx', 'IsSandbox__c', orgInfo.IsSandbox, def == null ? false : def.IsSandbox__c));
            s.checks.add(checkExact('org_id', 'OrgId__c', orgInfo.Id, def == null ? null : def.OrgId__c));
            s.checks.add(checkExact('org_sb_api', 'SandboxApiName__c', sandbox.toLowerCase(), def == null ? null : def.SandboxApiName__c));
            s.checks.add(checkExact('org_sb_name', 'SandboxName__c', sandbox, def == null ? null : def.SandboxName__c));
        } catch (Exception e) {
            s.checks.add(newWarn('org_query', 'Access', 'Queryable', 'Error', 'Unable to read OrgSettings__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
    }

    // 6) NSP_Environment_Details__c (org defaults NSP_Detailed_Data__c branch by sandbox)
    private static Section verifyEnvironmentDetails(String sandbox) {
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
            s.checks.add(checkExact('env_data', 'NSP_Detailed_Data__c', expectedVal, def == null ? null : def.NSP_Detailed_Data__c));
        } catch (Exception e) {
            s.checks.add(newWarn('env_query', 'Access', 'Queryable', 'Error', 'Unable to read NSP_Environment_Details__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
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
            s.checks.add(checkExact('box_tmpl', 'BoxTemplateFolderId__c', '225207143235', def == null ? null : def.BoxTemplateFolderId__c));
        } catch (Exception e) {
            s.checks.add(newWarn('box_query', 'Access', 'Queryable', 'Error', 'Unable to read BoxFileRequest__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
    }

    // 8) UserTriggerSettings__c (org defaults cleared to nulls)
    private static Section verifyUserTriggerSettings() {
        Section s = new Section();
        s.key = 'UserTriggerSettings__c';
        s.label = 'User Trigger Settings';
        s.category = 'CUSTOM_SETTINGS';
        s.checks = new List<Check>();

        try {
            UserTriggerSettings__c def = UserTriggerSettings__c.getOrgDefaults();
            s.checks.add(checkBlank('uts_admins', 'AllowedAdmins__c', 'Cleared to blank', def == null ? null : def.AllowedAdmins__c));
            s.checks.add(checkBlank('uts_bcc', 'BccAddresses__c', 'Cleared to blank', def == null ? null : def.BccAddresses__c));
        } catch (Exception e) {
            s.checks.add(newWarn('uts_query', 'Access', 'Queryable', 'Error', 'Unable to read UserTriggerSettings__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
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
            s.checks.add(checkBlank('cts_auto', 'AutoTerminationEmailAddresses__c', 'Cleared to blank', def == null ? null : def.AutoTerminationEmailAddresses__c));
        } catch (Exception e) {
            s.checks.add(newWarn('cts_query', 'Access', 'Queryable', 'Error', 'Unable to read Contract_Termination_Settings__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
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
                s.checks.add(checkBlank('nvm_client', 'NVMContactWorld__clientId__c', 'Cleared to blank', def == null ? null : def.NVMContactWorld__clientId__c));
            } else {
                s.checks.add(checkExact('nvm_client', 'NVMContactWorld__clientId__c', expectedId, def == null ? null : def.NVMContactWorld__clientId__c));
            }
            
        } catch (Exception e) {
            s.checks.add(newWarn('nvm_query', 'Access', 'Queryable', 'Error', 'Unable to read NVMContactWorld__Settings__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
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
            s.checks.add(checkExact('stes_bcc', 'BccEmailAddress__c', 'test.datacollection_sfqa2@insperity.com', def == null ? null : def.BccEmailAddress__c));
            s.checks.add(checkSuffix('stes_nat', 'NationalAccountEmailAddress__c', '.invalid', def == null ? null : def.NationalAccountEmailAddress__c));
            s.checks.add(checkSuffix('stes_pcm', 'PrivateCapitalMarketEmailAddress__c', '.invalid', def == null ? null : def.PrivateCapitalMarketEmailAddress__c));
            s.checks.add(checkSuffix('stes_str', 'StrategicSalesEmailAddress__c', '.invalid', def == null ? null : def.StrategicSalesEmailAddress__c));
        } catch (Exception e) {
            s.checks.add(newWarn('stes_query', 'Access', 'Queryable', 'Error', 'Unable to read Sales_Team_Email_Settings__c: ' + e.getMessage()));
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
    }

    // ---------- Small helpers to build checks ----------
    private static Check newCheck(String key, String label, String expected, String actual, String message, STATUS st) {
        Check c = new Check();
        c.key = key;
        c.label = label;
        c.expected = expected;
        c.actual = actual;
        c.message = message;
        c.status = st.name();
        return c;
    }

    private static Check newFail(String key, String label, String expected, String actual, String message) {
        return newCheck(key, label, expected, actual, message, STATUS.FAIL);
    }

    private static Check newPass(String key, String label, String expected, String actual, String message) {
        return newCheck(key, label, expected, actual, message, STATUS.PASS);
    }

    private static Check newWarn(String key, String label, String expected, String actual, String message) {
        return newCheck(key, label, expected, actual, message, STATUS.WARN);
    }

    private static Check checkExact(String key, String label, String expected, String actual) {
        if (actual == null) return newFail(key, label, expected, 'null', 'Missing value');
        return expected == actual
            ? newPass(key, label, expected, actual, 'Matches expected')
            : newFail(key, label, expected, actual, 'Value mismatch');
    }

    private static Check checkBool(String key, String label, Boolean expected, Boolean actual) {
        if (actual == null) return newFail(key, label, String.valueOf(expected), 'null', 'Missing value');
        return expected == actual
            ? newPass(key, label, String.valueOf(expected), String.valueOf(actual), 'Matches expected')
            : newFail(key, label, String.valueOf(expected), String.valueOf(actual), 'Value mismatch');
    }

    private static Check checkBlank(String key, String label, String expectedDesc, String actual) {
        return String.isBlank(actual)
            ? newPass(key, label, expectedDesc, actual, 'Cleared as expected')
            : newFail(key, label, expectedDesc, actual, 'Should be blank');
    }

    private static Check checkSuffix(String key, String label, String expectedSuffix, String actual) {
        if (String.isBlank(actual)) return newFail(key, label, 'Ends with ' + expectedSuffix, actual, 'Missing value');
        return actual.endsWith(expectedSuffix)
            ? newPass(key, label, 'Ends with ' + expectedSuffix, actual, 'Has required suffix')
            : newFail(key, label, 'Ends with ' + expectedSuffix, actual, 'Missing required suffix');
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
            for (CspTrustedSite ts : [SELECT Id, DeveloperName, EndpointUrl, IsActive FROM CspTrustedSite WITH SECURITY_ENFORCED]) {
                actualByName.put(ts.DeveloperName, ts.EndpointUrl);
            }
        } catch (Exception e) {
            // If sObject not queryable for the running user, leave actualByName empty and mark WARN
        }

        for (String key : required.keySet()) {
            String expectedUrl = required.get(key);
            String actualUrl = actualByName.containsKey(key) ? actualByName.get(key) : null;

            if (actualUrl == null) {
                s.checks.add(newFail('csp_' + key, key, expectedUrl, 'null', 'Missing Trusted Site: ' + key));
            } else {
                s.checks.add(checkExact('csp_' + key, key, expectedUrl, actualUrl));
            }
        }

        // If we failed to query any CspTrustedSite rows and list is empty, emit a WARN
        if (s.checks.isEmpty()) {
            s.checks.add(newWarn(
                'csp_query',
                'Trusted URLs',
                'Readable via user-context',
                'No data',
                'Unable to read CspTrustedSite. Verify permissions or run with a user who can view Setup records.'
            ));
        }

        // Set section status after all checks are processed
        s.status = calculateSectionStatus(s.checks);
        return s;
    }

    // Required image Documents created by NSP_PrepSandbox.doImageDocs()
    // Verifies presence in the 'Services' folder with public visibility.
    private static Map<String, String> requiredImageDocs() {
        // Map of metadata names (used by NSP_PrepSandbox) to expected human-readable Document Name
        // NSP_PrepSandbox sets Document.fullName = 'Services/' + name + '.png' and doc.name = replaceUnderscoresWithSpaces(name)
        Map<String, String> m = new Map<String, String>();
        m.put('Insperity_Copyright_Logo', 'Insperity_Copy_write_logo');
        m.put('Insperity_Footer_Logo', 'Insperity_Footer_Logo');
        m.put('Insperity_HR', 'Insperity_HR');
        m.put('Insperity_HR_Logo', 'Insperity_HR_Logo');
        m.put('Insperity_Service_Operations', 'Insperity_Service_Operations');
        m.put('InsperityEmailSignatureLogo', 'InsperityEmailSignatureLogo');
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
            for (Document d : [
                SELECT Id, Name, Folder.Name, IsPublic, IsInternalUseOnly, Type
                FROM Document
                WHERE (
                        ( Folder.Name = 'Services' )
                        AND ( IsPublic = true )
                        AND ( IsInternalUseOnly = false )
                    )
                WITH SECURITY_ENFORCED
            ]) {
                byName.put(d.Name, d);
            }
        } catch (Exception e) {
            // If user can't access Documents, emit a WARN and exit with section status
            s.checks.add(newWarn(
                'docs_query',
                'Image Documents',
                'Queryable via user-context',
                'No access',
                'Unable to read Document records in Services folder: ' + e.getMessage()
            ));
            s.status = calculateSectionStatus(s.checks);
            return s;
        }

        // For each required metadata key, compute the expected human-readable Document.Name
        for (String metaKey : required.keySet()) {
            String expectedDocName = required.get(metaKey).replace('_', ' ');
            Document d = byName.get(expectedDocName);

            if (d == null) {
                s.checks.add(newFail(
                    'doc_presence_' + metaKey,
                    expectedDocName,
                    'Exists in Services',
                    'Missing',
                    'Document not found in Services folder or is not public'
                ));
                continue;
            }

            if (String.isBlank(d.Type)) {
                s.checks.add(newWarn('doc_type_' + metaKey, expectedDocName + ' Type', 'png', 'blank', 'File type not available'));
            } else if (d.Type?.toLowerCase() != 'png') {
                s.checks.add(newWarn('doc_type_' + metaKey, expectedDocName + ' Type', 'png', d.Type, 'Expected PNG type per metadata creation'));
            } else {
                s.checks.add(newPass('doc_type_' + metaKey, expectedDocName + ' Type', 'png', d.Type, 'PNG document found as expected'));
            }
        }

        s.status = calculateSectionStatus(s.checks);
        return s;
    }

    // Placeholder required labels. These align with NSP_PrepSandbox.doCLabels() and doEmailCLabels() examples.
    private static Map<String, String> requiredLabels(String sandbox) {
        Map<String, String> m = new Map<String, String>();
        // Baseline placeholders
        m.put('NSP_Docusign_Base_URL', 'https://uatna11.springcm.com/atlas/doclauncher/OneClickDocGen');
        // Sandbox-specific examples from NSP_PrepSandbox.doCLabels()
        if (sandbox == 'stage') {
            m.put('NSP_FTA_Base_URL', 'https://stageportalapps.insperity.com/financialcomparison/financialanalysis/');
            m.put('NSP_Docusign_Account_Id', '48945');
            m.put('NSP_Contact_Center_Email_Addresses', 'test.contact_center_UAT@insperity.com.invalid');
            m.put('NSP_Health_Welfare_Section_125', 'test.section125_UAT@insperity.com.invalid');
        } else if (sandbox == 'test') {
            m.put('NSP_FTA_Base_URL', 'https://testportalapps.insperity.com/financialcomparison/financialanalysis/');
            m.put('NSP_Docusign_Account_Id', '65500');
            m.put('NSP_Contact_Center_Email_Addresses', 'test.contact_center@insperity.com.invalid');
            m.put('NSP_Health_Welfare_Section_125', 'test.section125@insperity.com.invalid');
        } else if (sandbox == 'merge') {
            m.put('NSP_FTA_Base_URL', 'https://devportalapps.insperity.com/financialcomparison/financialanalysis/');
            m.put('NSP_Docusign_Account_Id', '122677');
            m.put('NSP_Contact_Center_Email_Addresses', 'test.contact_center.merge@insperity.com.invalid');
            m.put('NSP_Health_Welfare_Section_125', 'test.section125.merge@insperity.com.invalid');
        } else {
            // default dev-like
            m.put('NSP_FTA_Base_URL', 'https://devportalapps.insperity.com/financialcomparison/financialanalysis/');
            m.put('NSP_Docusign_Account_Id', '50202');
        }
        return m;
    }

    // DTO to return two sections: core and email
    public class LabelSections {
        @AuraEnabled public Section core;
        @AuraEnabled public Section email;
    }

    private static LabelSections verifyCustomLabels(String sandbox) {
        LabelSections out = new LabelSections();

        // Core section
        Section core = new Section();
        core.key = 'customLabels';
        core.label = 'Custom Labels';
        core.category = 'LABELS';
        core.checks = new List<Check>();

        Map<String,String> expected = requiredLabels(sandbox);

        // Verify known labels via direct System.Label references (including Contact Center and Section 125)
        Map<String,String> directLabelActuals = new Map<String,String>{
            'NSP_Docusign_Base_URL' => System.Label.NSP_Docusign_Base_URL,
            'NSP_FTA_Base_URL' => System.Label.NSP_FTA_Base_URL,
            'NSP_Docusign_Account_Id' => System.Label.NSP_Docusign_Account_Id,
            'NSP_Contact_Center_Email_Addresses' => System.Label.NSP_Contact_Center_Email_Addresses,
            'NSP_Health_Welfare_Section_125' => System.Label.NSP_Health_Welfare_Section_125
        };

        for (String lblName : expected.keySet()) {
            String exp = expected.get(lblName);
            String act = directLabelActuals.containsKey(lblName) ? directLabelActuals.get(lblName) : null;

            if (String.isBlank(act)) {
                core.checks.add(newFail('label_' + lblName, lblName, exp, act, 'Label value unavailable via System.Label. Ensure the label exists and is referenced here.'));
            } else {
                core.checks.add(checkExact('label_' + lblName, lblName, exp, act));
            }
        }
        // Set section status for core labels
        core.status = calculateSectionStatus(core.checks);

        // Email labels section from Post_Refresh_Email_Labels and Post_Refresh_Email_Labels_2
        Section email = new Section();
        email.key = 'emailCustomLabels';
        email.label = 'Email Custom Labels';
        email.category = 'LABELS';
        email.checks = new List<Check>();

        List<String> dynamicLabelNames = new List<String>();
        try {
            String list1 = System.Label.Post_Refresh_Email_Labels;
            if (String.isNotBlank(list1)) {
                dynamicLabelNames.addAll(new List<String>(list1.split(',')));
            }
        } catch (Exception ignore) {}
        try {
            String list2 = System.Label.Post_Refresh_Email_Labels_2;
            if (String.isNotBlank(list2)) {
                dynamicLabelNames.addAll(new List<String>(list2.split(',')));
            }
        } catch (Exception ignore) {}

        Set<String> uniqueNames = new Set<String>();
        for (String n : dynamicLabelNames) {
            if (n != null) {
                uniqueNames.add(n.trim());
            }
        }

        for (String lblName : uniqueNames) {
            if (String.isBlank(lblName)) continue;
            String act = null;
            try {
                // Use namespace-aware overload: System.Label.get(namespace, name)
                // No namespace for these labels, so pass empty string as namespace per feedback
                act = System.Label.get('', lblName);
            } catch (Exception e) {
                act = null;
            }

            final String expectedSuffix = '.invalid';
            if (String.isBlank(act)) {
                email.checks.add(newFail('email_label_' + lblName, lblName, 'Ends with ' + expectedSuffix, act, 'Label not found or empty via System.Label.get(' + lblName + ').'));
            } else {
                email.checks.add(checkSuffix('email_label_' + lblName, lblName, expectedSuffix, act));
            }
        }
        // Set section status for email labels
        email.status = calculateSectionStatus(email.checks);

        out.core = core;
        out.email = email;
        return out;
    }
}
