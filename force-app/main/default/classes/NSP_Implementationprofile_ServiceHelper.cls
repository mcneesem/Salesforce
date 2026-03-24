public class NSP_Implementationprofile_ServiceHelper {
    // test w/ NSP_FSOImplementationControllerTest, NSP_ImpprofileServiceHelper_Test, NSP_MMImplProfile_UpdateTest, NSP_Implprofile_ServiceHelperUpdate_Test (77%)
    // test w/ NSP_FSOImplementationControllerTest, NSP_ImpprofileServiceHelper_Test, NSP_MMImplProfile_UpdateTest (76%)
    // test w/ NSP_FSOImplementationControllerTest, NSP_ImpprofileServiceHelper_Test (75%)
    // test w/ NSP_FSOImplementationControllerTest (21%)

    private List<Case> caseToInsertList = new List<Case>();
    private List<Case> caseToInsertSubjectIpList = new List<Case>();
    private List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
    private String impRecordId;
    private String  impAutomationName;
    private String impMethodName;
    private String  impAutomationRecordType;
    private String  impAutomationSection;
    @testVisible
    private  Boolean isRerun =false;
    private Boolean isSaveForm = false;
    private Map<Id, Implementation_Profile__c> newIPs = null;
    private Map<Id, Implementation_Profile__c> oldIPs = null;
    private Map<String, Set<Id>> ipRecordsByAutomation = new Map<String, Set<Id>>();
    private List<sObject> recToInsert = new List<sObject>();
    private List<sObject> recToUpdate = new List<sObject>();
    private Map<String, Map<Id, sObject>> data = new Map<String, Map<Id, sObject>>();
    private List<String> automationsToExecute = new List<String>();
    private Map<String, Id> mapofGroupIds=new Map<String, Id>();
    private Set<Id> ipIds = new Set<Id>();
    private List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
    private Map<String, EmailTemplate> mapOfEmailTempaltes = new Map<String, EmailTemplate>();
    private List<String> listRegulatedStates = new List<String>();
    private Map<String, List<String>> ipAutomationdata = new Map<String, List<String>>();
    private Set<Id> setOfBPAIds = new Set<Id>();
    private static Id ipFSORecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();
    private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
    private static Id casePEORecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEO).getRecordTypeId();
    private static final String RELATED_ACCOUNTS = 'Related Accounts:';

    private static final String EMP_HOURS_FN = 'NSP_Emp_Hours_Reported';
    private static final String SEASONAL_EE_FN = 'NSP_SEASONAL_EE';
    private static final String LEAVE_ABSENCE_FN = 'NSP_Leave_Absence';
    private static final String CLIENT_PROFILE_FN = 'clientProfileInfo';
    private static final String WAITING_PERIOD_FN = 'clientWaitingPeriod';
    private static final String MEDICAL_NEED_FN = 'urgentMedicalNeeds';
    private static final String WORKERS_CERTIFICATE_FN = 'workersCompCertificate';
    private static final String SEASONAL_EEFSO_FN = 'seasonalEEsFSO';
    private static final String RRP_CASE_FN = 'RRPCase';
    private static final String OFFER_HSA_FN = 'clientOfferHSA';
    private static final String OFFER_OPTUM_FN = 'clientOfferOPTUM';
    private static final String MM_OPTUM_CASE = 'OptumBankcase';
    private static final String LEAVE_ABSENCEFSO_FN = 'leaveAbsenceFSO';
    private static final String REMOVE_EMPLOYEE_DIR_FN = 'NSP_Remove_Employee_Directory';
    private static final String STOCK_PURCHASE_PLAN_FN = 'NSP_Stock_Purchase_Plan';
    private static final String EPLI_NOTIFY_FN = 'NSP_EPLI_Notification';
    private static final String EXISTING_RET_PLAN_KEEP_FN = 'NSP_Existing_Retirement_Plan_Keep';
    private static final String EXISTING_RET_PLAN_MOVE_FN = 'NSP_Existing_Retirement_Plan_Move';
    private static final String EEO_INFO_FN = 'NSP_EEO_information';
    private static final String NEW_401_FN = 'NSP_New_401_k';
    private static final String SRP_NOTIFY_FN = 'NSP_SRP_Notification';
    private static final String WC_NOTIFICATION_FN = 'NSP_WC_Notification';
    private static final String EPLI_POLICY_FN = 'NSP_EPLI_POLICY';
    private static final String LOGO_COLLECTED_FN = 'NSP_Logo_Collected';
    private static final String FEIN_NOTIFY_FN = 'NSP_FEIN_Template';
    private static final String SUB_ACCOUNT_FN = 'NSP_SubaccountTemplate';
    private static final String EMPLOYEE_DIRECTORY_FN = 'NSP_EmployeeDirectory';
    private static final String SERVICE_CONTRACT_FN ='NSP_Contractact';
    private static final String EMPLOYEE_MINISTER_FN ='NSP_EmployeeMinister';
    private static final String SUBACCOUNT_NEED_FN ='NSP_SubaccountNeed';
    private static final String TIME_ENTRY_FN ='NSP_TimeEntry';
    private static final String SPECIAL_PAYROLLNEED_FN ='NSP_SpecialPayrollNeeds';
    private static final String STOCK_PURCHASEPLAN_FN ='NSP_StockPurchaseplan';
    private static final String STOCK_OPTION_FN ='NSP_StockOptions';
    private static final String IRR_FN ='NSP_IRR';
    private static final String CLIENT_SUMMARY_FN ='NSP_ClientSummary';
    private static final String PAYROLL_SPECIALIST_SUMMARY_FN ='NSP_PayrollSpecialistSummary';
    private static final String EE_COMMISSION_FN ='NSP_EE_Commission';
    private static final String NSP_Existing_Retirement_Plan_Move_FSO='NSP_Existing_Retirement_Plan_Move_FSO';
    private static final String CAFETERIAL_PLAN_FN ='NSP_Cafeterai_Plan_Questionnaire';
    private static final String FEDERAL_COMPLIANCE_POSTERS ='Federal_Compliance_Posters';
    private static final String FEDERAL_COMPLIANCE_POSTERS_MM ='Federal_Compliance_Posters_MM';
    private static final String TECH_PACKET_FN ='NSP_Teck_Packet';
    private static final String AdditionalBPSes_FSO ='NSP_Additional_BPSes';
    private static final String NSP_New_401_k_FSO='NSP_New_401_k_FSO';
    private static final String CLIENT_AWW_YES = 'clientAWWYes';
    private static final String CLIENT_AWW_NO = 'clientAWWNo';
    private static final String FLSA_REVIEW_EG ='FLSA_Review_EG';
    private static final String FLSA_REVIEW_YES_MM ='FLSA_Review_Yes_MM';
    private static final String FLSA_REVIEW_NO ='flsaReviewNo';
    private static final String FLSA_REVIEW_NO_MM ='FLSA_Review_No_MM';
    private static final String FLSA_EXEMPTION_REVIEW_EMAIL ='FLSA_Exemption_Review_non_EG_Email';

    private Map<Id, Id> mapOfProjectManagers = new Map<Id, Id>();
    private Map<Id, Id> mapOfPayrollSpecialist = new Map<Id, Id>();
    private static final String IP_IDENTIFIER = 'Implementation_Profile__c';
    private static final String IP_AUTOMATION_IDENTIFIER = 'NSP_Implementation_Profile_Automation__c';
    private static final String USER_IDENTIFIER = 'User';
    private static final String Licensed_Contractor_Yes_FSO = 'licensedContractorYesFSO';
    private static final String Licensed_Contractor_Yes_MM = 'licensedContractorYesMM';
    private static final String Licensed_Automation_Name_FSO = 'Licensed_Contractor_FSO';
    private static final String Licensed_Automation_Name_MM = 'Licensed_Contractor_MM';
    private static final String LicensedContractorEmail = 'Licensed_Contractor_Email';
    private static final String MMOPTUM='Optum Bank case';
    private static final List<String> EMAIL_TEMPLATES = new List<String>{
        NSP_ServiceConstants.EEO_INFORMATION ,
        NSP_ServiceConstants.EPLI_NOTIFICATION ,
        NSP_ServiceConstants.ER_PLAN_KEEP ,
        NSP_ServiceConstants.ER_PLAN_MOVE ,
        NSP_ServiceConstants.NEW_401 ,
        NSP_ServiceConstants.REMOVE_EMP_DIR ,
        NSP_ServiceConstants.PURCHASE_PLAN ,
        NSP_ServiceConstants.SRP_NOTIFY ,
        NSP_ServiceConstants.SRP_NOTIFY_401 ,
        NSP_ServiceConstants.SRP_RET_SALES ,
        WC_NOTIFICATION_FN,EPLI_POLICY_FN ,
        LOGO_COLLECTED_FN ,
        FEIN_NOTIFY_FN ,
        SUB_ACCOUNT_FN ,
        EMPLOYEE_DIRECTORY_FN ,
        SERVICE_CONTRACT_FN ,
        EMPLOYEE_MINISTER_FN ,
        SUBACCOUNT_NEED_FN ,
        TIME_ENTRY_FN ,
        SPECIAL_PAYROLLNEED_FN ,
        STOCK_PURCHASEPLAN_FN ,
        STOCK_OPTION_FN ,
        IRR_FN ,
        CLIENT_SUMMARY_FN ,
        PAYROLL_SPECIALIST_SUMMARY_FN ,
        EE_COMMISSION_FN ,
        CAFETERIAL_PLAN_FN ,
        TECH_PACKET_FN ,
        NSP_Existing_Retirement_Plan_Move_FSO ,
        AdditionalBPSes_FSO ,
        NSP_New_401_k_FSO
    };

   NSP_IP_Automation_Helper ipAutomationHelper = new NSP_IP_Automation_Helper();


   public NSP_Implementationprofile_ServiceHelper (Boolean isSave){
    this.isSaveForm = isSave;
   }


    public NSP_Implementationprofile_ServiceHelper(Map<Id, Implementation_Profile__c> newIPs, Map<Id, Implementation_Profile__c> oldIPs){
        this.newIPs = newIPs;
        this.oldIPs = oldIPs;
        this.automationsToExecute.addAll(new List<String>{
            CLIENT_PROFILE_FN ,
            WAITING_PERIOD_FN ,
            MEDICAL_NEED_FN ,
            WORKERS_CERTIFICATE_FN ,
            SEASONAL_EEFSO_FN ,
            RRP_CASE_FN ,
            OFFER_HSA_FN ,
            OFFER_OPTUM_FN ,
            MM_OPTUM_CASE ,
            LEAVE_ABSENCEFSO_FN ,
            EMP_HOURS_FN ,
            SEASONAL_EE_FN ,
            LEAVE_ABSENCE_FN ,
            WC_NOTIFICATION_FN ,
            EPLI_POLICY_FN ,
            LOGO_COLLECTED_FN ,
            FEIN_NOTIFY_FN ,
            SUB_ACCOUNT_FN ,
            EMPLOYEE_DIRECTORY_FN ,
            SERVICE_CONTRACT_FN ,
            EMPLOYEE_MINISTER_FN ,
            SUBACCOUNT_NEED_FN ,
            TIME_ENTRY_FN ,
            SPECIAL_PAYROLLNEED_FN ,
            STOCK_PURCHASEPLAN_FN ,
            STOCK_OPTION_FN ,
            IRR_FN ,
            CLIENT_SUMMARY_FN ,
            PAYROLL_SPECIALIST_SUMMARY_FN ,
            REMOVE_EMPLOYEE_DIR_FN ,
            STOCK_PURCHASE_PLAN_FN ,
            EPLI_NOTIFY_FN ,
            EXISTING_RET_PLAN_KEEP_FN ,
            EXISTING_RET_PLAN_MOVE_FN ,
            EEO_INFO_FN ,
            NEW_401_FN ,
            SRP_NOTIFY_FN ,
            EE_COMMISSION_FN ,
            CAFETERIAL_PLAN_FN ,
            FEDERAL_COMPLIANCE_POSTERS ,
            FEDERAL_COMPLIANCE_POSTERS_MM ,
            TECH_PACKET_FN ,
            AdditionalBPSes_FSO ,
            CLIENT_AWW_YES ,
            CLIENT_AWW_NO ,
            FLSA_REVIEW_EG ,
            FLSA_REVIEW_YES_MM ,
            Licensed_Contractor_Yes_FSO ,
            Licensed_Contractor_Yes_MM ,
            FLSA_REVIEW_NO ,
            FLSA_REVIEW_NO_MM ,
            FLSA_EXEMPTION_REVIEW_EMAIL
        });
    }

    public NSP_Implementationprofile_ServiceHelper(Id ipRecord, String automationName){
        this.newIPs = NSP_ImpAutomationsController.getIpRecord(ipRecord);
        this.isRerun=true;
                this.automationsToExecute.add(automationName);
    }

    public Map<String,Set<Id>> executeAutomation() {
        Map<String,Set<Id>> ipRecordsByAutomationMap = new Map<String,Set<Id>>();
        if ( NSP_Implprofile_ServiceHelperUpdate.isAutomationAllowed() ) {
        try {
                this.start();
                this.execute();
                this.finish();
                ipRecordsByAutomationMap = this.ipRecordsByAutomation;
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_Implementationprofile_ServiceHelper.class.getName() ,
                'executeAutomation' ,
                e
            );
            }
       }
       return ipRecordsByAutomationMap;
    }

    private void start() {
        // Create a set of eligible records which we need to pull
        populateEligibleRecords();
        //get all group id for queue
        if(ipRecordsByAutomation.size()>0){
            getGroupId();//execute
            //get all Email Templatef
            getEmailTemplates();

            //get all IP records
            getIPRecords();

            //fetch all existing automation records for eligible ips
            getAllIPAutomation();
            //fetch all existing cases for eligible ips
            ipAutomationHelper.getAllCases(ipIds);

        }




    }

    private void execute() {
        for ( String automation: ipRecordsByAutomation.keySet() ) {
            createCases( automation );
        }
        if ( !caseToInsertList.isEmpty() ) {
            //check for existing Cases to avoid duplications
            recToInsert.addAll( ipAutomationHelper.getnewCasestoInsert( caseToInsertList ) );
        }
        if(!caseToInsertSubjectIpList.isEmpty()){
            //check for existing Cases to avoid duplications
            recToInsert.addAll( ipAutomationHelper.getNewCasesToInsertSubjectIp( caseToInsertSubjectIpList ) );
        }
        if ( !ipAutomationRecords.isEmpty() ) {
            //check for existing Automation record and store the new Automation records
            recToInsert.addAll( getnewAutomationListtoInsert( ipAutomationRecords ) );
        }
        if(ipRecordsByAutomation.containsKey(CLIENT_PROFILE_FN)){
            createCaseClientProfileInfo();
        }
        if(ipRecordsByAutomation.containsKey(WAITING_PERIOD_FN)){
            createCaseClientWaitingPeriod();
        }
        if(ipRecordsByAutomation.containsKey(MEDICAL_NEED_FN)){
            createCaseMedicalNeed();
        }
        if(ipRecordsByAutomation.containsKey(WORKERS_CERTIFICATE_FN)){
            createCaseWorkersCompCertificate();
        }
        if(ipRecordsByAutomation.containsKey(SEASONAL_EEFSO_FN)){
            createCaseSeasonalEEFSO();
        }
        if(ipRecordsByAutomation.containsKey(RRP_CASE_FN)){
            createCaseRRP();
        }
        if(ipRecordsByAutomation.containsKey(OFFER_HSA_FN)){
            createCaseHSA();
        }
        if(ipRecordsByAutomation.containsKey(OFFER_OPTUM_FN)){
            createCaseOPTUM();
        }
        if(ipRecordsByAutomation.containsKey(MM_OPTUM_CASE)){
            createMMCaseOPTUM();
        }
        if(ipRecordsByAutomation.containsKey(LEAVE_ABSENCEFSO_FN)){
            createCaseLeaveAbsenceFSO();
        }
        if(ipRecordsByAutomation.containsKey(SEASONAL_EE_FN)){
            createCaseSeasonal();
        }
        if(ipRecordsByAutomation.containsKey(LEAVE_ABSENCE_FN)){
            createCaseLeaveAbsence();
        }
        if(ipRecordsByAutomation.containsKey(EMP_HOURS_FN)){
            createCaseEmpHours();
        }


        //STY-02193 IP MM Email Automations
        //Email Notificaton for Remove employee directory
        if(ipRecordsByAutomation.containsKey(REMOVE_EMPLOYEE_DIR_FN)){
            emailNotifyforRemoveEmployeeDirectory();
        }
        //Email Notificaton for Stock Purchase Plan
        if(ipRecordsByAutomation.containsKey(STOCK_PURCHASE_PLAN_FN)){
            emailNotifyforStockPurchasePlan();
        }
        //Email Notificaton for EPLI Notification
        if(ipRecordsByAutomation.containsKey(EPLI_NOTIFY_FN)){
            emailNotifyforEPLINotification();
        }
        //Email Notificaton for Existing Retirement Plan/Keep
        if(ipRecordsByAutomation.containsKey(EXISTING_RET_PLAN_KEEP_FN)){
            emailNotifyforExistingRetirementPlanKeep();
        }
        if(ipRecordsByAutomation.containsKey(EXISTING_RET_PLAN_MOVE_FN)){
            emailNotifyforExistingRetirementPlanMove();
        }
        if(ipRecordsByAutomation.containsKey(EEO_INFO_FN)){
            emailNotifyforEEOInfo();
            emailNotifyforEEOInfoFSO();
        }
        if(ipRecordsByAutomation.containsKey(NEW_401_FN)){
            emailNotifyforNew401k();
        }
        if(ipRecordsByAutomation.containsKey(SRP_NOTIFY_FN)){
            System.debug('enter email emailNotifyforSRPNotification');
            emailNotifyforSRPNotification();
        }
        if(ipRecordsByAutomation.containsKey(WC_NOTIFICATION_FN)){
            emailNotifyforWCNotification();
        }
        if(ipRecordsByAutomation.containsKey(EPLI_POLICY_FN)){
            emailNotifyforEPLIPolicy();
        }
        if(ipRecordsByAutomation.containsKey(LOGO_COLLECTED_FN)){
            emailNotifyforLogoCollected();
        }
        if(ipRecordsByAutomation.containsKey(FEIN_NOTIFY_FN)){
            emailNotifyforFEIN();
        }
        if(ipRecordsByAutomation.containsKey(SUB_ACCOUNT_FN)){
            emailNotifyforSubaccount();
        }
        if(ipRecordsByAutomation.containsKey(EMPLOYEE_DIRECTORY_FN)){
            emailNotifyforEmployeeDirectory();
        }
        if(ipRecordsByAutomation.containsKey(SERVICE_CONTRACT_FN)){
            emailNotifyforServiceContract();
        }
        if(ipRecordsByAutomation.containsKey(EMPLOYEE_MINISTER_FN)){
            emailNotifyforEmployeeMinister();
        }
        if(ipRecordsByAutomation.containsKey(SUBACCOUNT_NEED_FN)){
            emailNotifyforSubaccountNeed();
        }
        if(ipRecordsByAutomation.containsKey(TIME_ENTRY_FN)){
            emailNotifyforTimeEntry();
        }
        if(ipRecordsByAutomation.containsKey(SPECIAL_PAYROLLNEED_FN)){
            emailNotifyforSpecialPayrollNeeds();
        }
        if(ipRecordsByAutomation.containsKey(STOCK_PURCHASEPLAN_FN)){
            emailNotifyforStockPlan();
        }
        if(ipRecordsByAutomation.containsKey(STOCK_OPTION_FN)){
            emailNotifyforStockOption();
        }
        if(ipRecordsByAutomation.containsKey(IRR_FN)){
            emailNotifyWhenIRRChecked();
        }
        if(ipRecordsByAutomation.containsKey(CLIENT_SUMMARY_FN)){
            emailNotifyforClientSummary();
        }
        if(ipRecordsByAutomation.containsKey(PAYROLL_SPECIALIST_SUMMARY_FN)){
            emailNotifyforPayrollSpecialistSummary();
        }

        if(ipRecordsByAutomation.containsKey(EE_COMMISSION_FN)){
            emailNotifyForEECommission();
        }
        if(ipRecordsByAutomation.containsKey(CAFETERIAL_PLAN_FN)){
            emailNotifyForCafeteriaPlan();
        }
        if(ipRecordsByAutomation.containsKey(TECH_PACKET_FN)){
            emailNotifyForTechPacket();
        }
        if(ipRecordsByAutomation.containsKey(AdditionalBPSes_FSO)){
            emailNotifyforcheckforBpses();
        }
        if(ipRecordsByAutomation.containsKey(CLIENT_AWW_YES)){
            emailNotifyforclientAWWYes();
        }
        if(ipRecordsByAutomation.containsKey(CLIENT_AWW_NO)){
            emailNotifyforclientAWWNo();
        }
        if(ipRecordsByAutomation.containsKey(FLSA_REVIEW_NO)){
            emailNotifyforFlsaReviewNo();
        }

        if(ipRecordsByAutomation.containsKey(FLSA_REVIEW_NO_MM)){
            emailNotifyforFlsaReviewNoMM();
        }

        if(ipRecordsByAutomation.containsKey(FLSA_EXEMPTION_REVIEW_EMAIL)){
            emailNotifyforFlsaExemptionReview();
        }
        if (ipRecordsByAutomation.containsKey(LICENSED_CONTRACTOR_YES_FSO)) {
            emailNotifyForLicensedContractor(LICENSED_CONTRACTOR_YES_FSO, Licensed_Automation_Name_FSO);
        }
        if (ipRecordsByAutomation.containsKey(LICENSED_CONTRACTOR_YES_MM)) {
            emailNotifyForLicensedContractor(LICENSED_CONTRACTOR_YES_MM, Licensed_Automation_Name_MM);
        }
    }

    private void finish() {
        try {
            recToInsert.sort();
            List<Database.SaveResult> results = Database.insert( recToInsert , false );
            NSP_ErrorLogHandler.logResults(
                NSP_Implementationprofile_ServiceHelper.class.getName() ,
                'finish:insert' ,
                results
            );
            if ( ( Limits.getEmailInvocations() + 2 ) < Limits.getLimitEmailInvocations() // prevent LimitExceptions...
                &&  EmailDeliverabilityController.isEnabledOutbound
                )
            {
                Savepoint sp = Database.setSavepoint();
                Messaging.sendEmail( lstEmailMessages );
                Database.rollback( sp );
                List<Messaging.SingleEmailMessage> msgListToBeSend = new List<Messaging.SingleEmailMessage>();
                for ( Messaging.SingleEmailMessage email : lstEmailMessages ) {
                    Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
                    emailToSend.setToAddresses( email.getToAddresses() );
                    emailToSend.setPlainTextBody( email.getPlainTextBody() );
                    emailToSend.setHTMLBody( email.getHTMLBody() );
                    emailToSend.setSubject( email.getSubject() );
                    emailToSend.setCcAddresses( email.getCcAddresses() );
                    emailToSend.setFileAttachments( email.getFileAttachments() );
                    emailToSend.setOrgWideEmailAddressId( email.getOrgWideEmailAddressId() );
                    emailToSend.setSaveAsActivity( email.getSaveAsActivity() );
                    emailToSend.setWhatId( email.getWhatId() );
                    msgListToBeSend.add( emailToSend );
                }
                Messaging.sendEmail( msgListToBeSend );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_Implementationprofile_ServiceHelper.class.getName() ,
                'finish' ,
                e
            );
        }
    }

    private void populateEligibleRecords() {
        for ( Implementation_Profile__c ipRec : newIPs.values() ) {
            Implementation_Profile__c existingRec = ( ( oldIPs != null ) ? oldIPs.get( ipRec.Id ) : null );
            // All the automation methods will check the eligibility of the current record.
            checkForFederalCompliancePosters( ipRec , existingRec );
            checkForFederalCompliancePostersMM( ipRec , existingRec );
            checkForFlsaReviewEg( ipRec , existingRec );
            checkForFlsaReviewYes_MM( ipRec , existingRec );
            checkforFlsaReviewNo( ipRec, existingRec );
            checkforFlsaReviewNoMM( ipRec, existingRec );
            checkforFlsaExemptionReview( ipRec, existingRec );
            if(automationsToExecute.contains(CLIENT_PROFILE_FN)){
                checkForClientProfileInfo(ipRec, existingRec);
            }
            if(automationsToExecute.contains(WAITING_PERIOD_FN)){
                checkForWaitingPeriod(ipRec, existingRec);
            }
            if(automationsToExecute.contains(MEDICAL_NEED_FN)){
                checkForMedicalNeed(ipRec, existingRec);
            }
            if(automationsToExecute.contains(WORKERS_CERTIFICATE_FN)){
                checkForWorkerCompCertificate(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SEASONAL_EEFSO_FN)){
                checkForSeasonalEEFSO(ipRec, existingRec);
            }
            if(automationsToExecute.contains(RRP_CASE_FN)){
                checkForRRPCase(ipRec, existingRec);
            }
            if(automationsToExecute.contains(OFFER_HSA_FN)){
                checkForHSA(ipRec, existingRec);
            }

            if(automationsToExecute.contains(OFFER_OPTUM_FN)){
                checkForOptum(ipRec, existingRec);
            }
            if(automationsToExecute.contains(MM_OPTUM_CASE)){
                checkForMMOptum(ipRec, existingRec);
            }
            if(automationsToExecute.contains(LEAVE_ABSENCEFSO_FN)){
                checkForLeaveAbsenceFSO(ipRec, existingRec);
            }

            if(automationsToExecute.contains(EMP_HOURS_FN)){
                checkForEmployeeHours(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SEASONAL_EE_FN)){
                checkForSeasonalEE(ipRec, existingRec);
            }
            if(automationsToExecute.contains(LEAVE_ABSENCE_FN)){
                checkForLeaveAbsence(ipRec, existingRec);
            }


            //STY-02193 IP MM Email Automations
            if(automationsToExecute.contains(REMOVE_EMPLOYEE_DIR_FN)){
                checkforRemoveEmployeeDirectory(ipRec, existingRec);
            }
            if(automationsToExecute.contains(STOCK_PURCHASE_PLAN_FN)){
                checkforStockPurchasePlan(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EPLI_NOTIFY_FN)){
                checkEPLINotification(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EXISTING_RET_PLAN_KEEP_FN)){
                checkforExistingRetirementPlanKeep(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EXISTING_RET_PLAN_MOVE_FN)){
                checkforExistingRetirementMovetoNSP401(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EEO_INFO_FN)){
                checkforEEOInformation(ipRec, existingRec);
            }
            if(automationsToExecute.contains(NEW_401_FN)){
                checkforNew401k(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SRP_NOTIFY_FN)){
                checkSRPNotification(ipRec, existingRec);
            }
            if(automationsToExecute.contains(WC_NOTIFICATION_FN)){
                checkforWCNotification(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EPLI_POLICY_FN)){
                checkforEPLIPolicy(ipRec, existingRec);
            }
            if(automationsToExecute.contains(LOGO_COLLECTED_FN)){
                checkforLogoCollected(ipRec, existingRec);
            }
            if(automationsToExecute.contains(FEIN_NOTIFY_FN)){
                checkforFEIN(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SUB_ACCOUNT_FN)){
                checkforSubaccount(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EMPLOYEE_DIRECTORY_FN)){
                checkforEmployeeDirectory(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SERVICE_CONTRACT_FN)){
                checkforServiceContract(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EMPLOYEE_MINISTER_FN)){
                checkforEmployeeMinister(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SUBACCOUNT_NEED_FN)){
                checkforSubaccountNeed(ipRec, existingRec);
            }
            if(automationsToExecute.contains(TIME_ENTRY_FN)){
                checkforTimeEntry(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SPECIAL_PAYROLLNEED_FN)){
                checkforSpecialPayrollNeeds(ipRec, existingRec);
            }
            if(automationsToExecute.contains(STOCK_PURCHASEPLAN_FN)){
                checkforStockPlan(ipRec, existingRec);
            }
            if(automationsToExecute.contains(STOCK_OPTION_FN)){
                checkforStockOption(ipRec, existingRec);
            }
            if(automationsToExecute.contains(IRR_FN)){
                checkWhenIRRChecked(ipRec, existingRec);
            }
            if(automationsToExecute.contains(CLIENT_SUMMARY_FN)){
                checkforClientSummary(ipRec, existingRec);
            }
            if(automationsToExecute.contains(PAYROLL_SPECIALIST_SUMMARY_FN)){
                checkforPayrollSpecialistSummary(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EE_COMMISSION_FN)){
                checkForEECommission(ipRec, existingRec);
            }
            if(automationsToExecute.contains(CAFETERIAL_PLAN_FN)){
                checkForCafeterialPlan(ipRec, existingRec);
            }
            if(automationsToExecute.contains(TECH_PACKET_FN)){
                checkForTechPacket(ipRec, existingRec);
            }
            if(automationsToExecute.contains(AdditionalBPSes_FSO)){
                checkforBpses(ipRec, existingRec);
            }
            if(automationsToExecute.contains(CLIENT_AWW_YES)){
                checkforClientAWWYes(ipRec, existingRec);
            }
            if(automationsToExecute.contains(CLIENT_AWW_NO)){
                checkforClientAWWNo(ipRec, existingRec);
            }
            if (automationsToExecute.contains(LICENSED_CONTRACTOR_YES_FSO)) {
                checkForLicensedContractor(ipRec, LICENSED_CONTRACTOR_YES_FSO);
            }
            if (automationsToExecute.contains(LICENSED_CONTRACTOR_YES_MM)) {
                checkForLicensedContractor(ipRec, LICENSED_CONTRACTOR_YES_MM);
            }

        }
    }

    private  void getAllIPAutomation(){

        Map<Id, sObject> dbRec = new Map<Id, sObject>([SELECT Id,NSP_Implementation_Profile__c,NSP_Record_Type__c,NSP_Method_Name__c, Name FROM NSP_Implementation_Profile_Automation__c WHERE NSP_Implementation_Profile__c in:newIPs.keyset()]);

        data.put(IP_AUTOMATION_IDENTIFIER,dbRec);
        List<String> lstOfAutomations = new List<String>();
        for(NSP_Implementation_Profile_Automation__c auto: (List<NSP_Implementation_Profile_Automation__c>) dbRec.values()){
            lstOfAutomations.add(auto.NSP_Implementation_Profile__c+'_'+auto.NSP_Method_Name__c+'_'+auto.NSP_Record_Type__c);
        }

        ipAutomationdata.put(IP_AUTOMATION_IDENTIFIER, lstOfAutomations);
    }

    private List<NSP_Implementation_Profile_Automation__c> getnewAutomationListtoInsert(List<NSP_Implementation_Profile_Automation__c> ipAutomationList){

        Map<Id, sObject> dbRec=data.get(IP_AUTOMATION_IDENTIFIER);
        List<String> existingIpAutomations = new List<String>();
        for(Id ipaId:dbRec.keySet()){
            NSP_Implementation_Profile_Automation__c ipa=(NSP_Implementation_Profile_Automation__c)dbRec.get(ipaId);
            existingIpAutomations.add(ipa.NSP_Implementation_Profile__c+'_'+ipa.Name+'_'+ipa.NSP_Record_Type__c);
        }

        List<NSP_Implementation_Profile_Automation__c> newipAutomationList=new List<NSP_Implementation_Profile_Automation__c>();

        for(NSP_Implementation_Profile_Automation__c ipa: ipAutomationList){
            if(existingIpAutomations.isEmpty()||
               !existingIpAutomations.contains(ipa.NSP_Implementation_Profile__c+'_'+ipa.Name+'_'+ipa.NSP_Record_Type__c)) {
                   newipAutomationList.add(ipa);
               }

        }
        return newipAutomationList;
    }

    private void updateEligibleRecordsMap(
        Map<String,Set<Id>> automationMap ,
        Id recordId ,
        String fnName
        )
    {
        if ( ( automationMap != null ) && String.isNotBlank( fnName ) ) {
            Set<Id> relevantRecords = null;
            if ( automationMap.containsKey( fnName ) ) {
                relevantRecords = automationMap.get( fnName );
            }
            if ( relevantRecords == null ) {
            relevantRecords = new Set<Id>();
        }
            if ( recordId != null ) {
                relevantRecords.add( recordId );
            }
            automationMap.put( fnName , relevantRecords );
        }
    }

    private void checkForClientProfileInfo(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if( newRec.RecordTypeId != ipFSORecordTypeId
           || newRec.Client_Profile_Information__c == null) {
               return;
           }

        if(newRec.RecordTypeId == ipFSORecordTypeId && newRec.Client_Profile_Information__c!=null
        && newRec.Client_Profile_Information__c.CONTAINS(NSP_ServiceConstants.FORMERCLIENT)){

               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.Client_Profile_Information__c != existingRec.Client_Profile_Information__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CLIENT_PROFILE_FN);
                  }
           }
    }

    private void checkForWaitingPeriod(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if( newRec.RecordTypeId != ipFSORecordTypeId
           || newRec.Insperity_benefits_waiting_period__c == null || newRec.Client_s_previous_waiting_period__c==null
           || newRec.NSP_List_Employee_Names__c==null) {
               return;
           }
           if(newRec.Insperity_benefits_waiting_period__c!=null && newRec.Client_s_previous_waiting_period__c!=null ) {
            String [] inspPeriod = newRec.Insperity_benefits_waiting_period__c.split(' ');
            String [] clientPeriod = newRec.Client_s_previous_waiting_period__c.split(' ');

                if(  newRec.RecordTypeId == ipFSORecordTypeId &&
                newRec.NSP_List_Employee_Names__c !=null && Integer.ValueOf(inspPeriod[0])> Integer.ValueOf(clientPeriod[0])){

                    if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                        newRec.NSP_List_Employee_Names__c != existingRec.NSP_List_Employee_Names__c
                        ||newRec.Insperity_benefits_waiting_period__c != existingRec.Insperity_benefits_waiting_period__c
                        ||newRec.Client_s_previous_waiting_period__c != existingRec.Client_s_previous_waiting_period__c){
                            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, WAITING_PERIOD_FN);
                        }
                }
            }
    }

    private void checkForMedicalNeed(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if( newRec.RecordTypeId != ipFSORecordTypeId
           || newRec.Any_EEs_with_urgent_medical_needs__c != NSP_ServiceConstants.YES) {
               return;
           }

        if(  newRec.RecordTypeId == ipFSORecordTypeId &&
           newRec.Any_EEs_with_urgent_medical_needs__c == NSP_ServiceConstants.YES){

               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.Any_EEs_with_urgent_medical_needs__c != existingRec.Any_EEs_with_urgent_medical_needs__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, MEDICAL_NEED_FN);
                  }
           }
    }

    private void checkForWorkerCompCertificate(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if( newRec.RecordTypeId != ipFSORecordTypeId
           || newRec.NSP_Immediate_need_for_Workers_Comp_Cert__c != NSP_ServiceConstants.YES) {
               return;
           }

        if( newRec.RecordTypeId == ipFSORecordTypeId &&
           newRec.NSP_Immediate_need_for_Workers_Comp_Cert__c == NSP_ServiceConstants.YES){

               if(existingRec == null ||   newRec.NSP_Form_Completed__c ||
                  newRec.NSP_Immediate_need_for_Workers_Comp_Cert__c != existingRec.NSP_Immediate_need_for_Workers_Comp_Cert__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, WORKERS_CERTIFICATE_FN);
                  }
           }
    }

    private void checkForSeasonalEEFSO(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if(newRec.RecordTypeId != ipFSORecordTypeId
           || newRec.Client_have_will_have_any_Seasonal_EEs__c != NSP_ServiceConstants.YES) {
               return;
           }

        if(  newRec.RecordTypeId == ipFSORecordTypeId &&
           newRec.Client_have_will_have_any_Seasonal_EEs__c == NSP_ServiceConstants.YES){

               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.Client_have_will_have_any_Seasonal_EEs__c != existingRec.Client_have_will_have_any_Seasonal_EEs__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SEASONAL_EEFSO_FN);
                  }
           }
    }

    private void checkForRRPCase(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if( newRec.RecordTypeId != ipFSORecordTypeId
           || !newRec.NSP_Check_to_create_the_RRP_Case__c) {
               return;
           }

        if(   newRec.RecordTypeId == ipFSORecordTypeId &&
           newRec.NSP_Check_to_create_the_RRP_Case__c){

               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.NSP_Check_to_create_the_RRP_Case__c != existingRec.NSP_Check_to_create_the_RRP_Case__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, RRP_CASE_FN);
                  }
           }
    }

    private void checkForHSA(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if( newRec.RecordTypeId != ipFSORecordTypeId
           || newRec.Does_the_client_offer_a_HSA__c != NSP_ServiceConstants.YES
           ||newRec.Is_client_s_current_HSA_with_Optum_Bank__c != NSP_ServiceConstants.YES
           ||newRec.Does_client_have_their_code_group_ID__c != NSP_ServiceConstants.YES) {
               return;
           }

        if(  newRec.RecordTypeId == ipFSORecordTypeId &&
           newRec.Does_the_client_offer_a_HSA__c == NSP_ServiceConstants.YES &&
           newRec.Is_client_s_current_HSA_with_Optum_Bank__c == NSP_ServiceConstants.YES &&
           newRec.Does_client_have_their_code_group_ID__c == NSP_ServiceConstants.YES  ){

               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.Does_the_client_offer_a_HSA__c != existingRec.Does_the_client_offer_a_HSA__c
                  ||newRec.Is_client_s_current_HSA_with_Optum_Bank__c != existingRec.Is_client_s_current_HSA_with_Optum_Bank__c
                  || newRec.Does_client_have_their_code_group_ID__c != existingRec.Does_client_have_their_code_group_ID__c ){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, OFFER_HSA_FN);
                  }
           }
    }

    private void checkForOptum(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if( newRec.RecordTypeId != ipFSORecordTypeId
           || newRec.Does_the_client_offer_a_HSA__c != NSP_ServiceConstants.YES
           ||newRec.Is_client_s_current_HSA_with_Optum_Bank__c != NSP_ServiceConstants.YES
           ||newRec.Does_client_have_their_code_group_ID__c != NSP_ServiceConstants.NO) {
               return;
           }

        if( newRec.RecordTypeId == ipFSORecordTypeId &&
           newRec.Does_the_client_offer_a_HSA__c == NSP_ServiceConstants.YES &&
           newRec.Is_client_s_current_HSA_with_Optum_Bank__c == NSP_ServiceConstants.YES &&
           newRec.Does_client_have_their_code_group_ID__c == NSP_ServiceConstants.NO  ){

               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.Does_the_client_offer_a_HSA__c != existingRec.Does_the_client_offer_a_HSA__c
                  ||newRec.Is_client_s_current_HSA_with_Optum_Bank__c != existingRec.Is_client_s_current_HSA_with_Optum_Bank__c
                  || newRec.Does_client_have_their_code_group_ID__c != existingRec.Does_client_have_their_code_group_ID__c ){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, OFFER_OPTUM_FN);
                  }
           }
    }

    private void checkForLeaveAbsenceFSO(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if( newRec.RecordTypeId != ipFSORecordTypeId
           || newRec.Are_there_any_EEs_on_Leave_of_Absence__c != NSP_ServiceConstants.YES) {
               return;
           }

        if(   newRec.RecordTypeId == ipFSORecordTypeId &&
           newRec.Are_there_any_EEs_on_Leave_of_Absence__c == NSP_ServiceConstants.YES){

               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.Are_there_any_EEs_on_Leave_of_Absence__c != existingRec.Are_there_any_EEs_on_Leave_of_Absence__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, LEAVE_ABSENCEFSO_FN);
                  }
           }
    }

    private void checkForEmployeeHours(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if(newRec.RecordTypeId != ipMMRecordTypeId ||( newRec.How_are_empl_hrs_reported_to_Insperity__c != NSP_ServiceConstants.PAYROLL
                                                                                       && newRec.How_are_empl_hrs_reported_to_Insperity__c!= NSP_ServiceConstants.XML)) {
                                                                                           return;
                                                                                       }

        if(   newRec.RecordTypeId == ipMMRecordTypeId &&
           (newRec.How_are_empl_hrs_reported_to_Insperity__c == NSP_ServiceConstants.XML ||
            newRec.How_are_empl_hrs_reported_to_Insperity__c == NSP_ServiceConstants.PAYROLL)){

                if(existingRec == null || newRec.NSP_Form_Completed__c ||
                   newRec.How_are_empl_hrs_reported_to_Insperity__c != existingRec.How_are_empl_hrs_reported_to_Insperity__c){

                       updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EMP_HOURS_FN);
                   }
            }
    }

    private void checkForFederalCompliancePosters( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( ( automationsToExecute != null )
            && automationsToExecute.contains( FEDERAL_COMPLIANCE_POSTERS )
            && ( newRec != null )
            && ( newRec.RecordTypeId == ipFSORecordTypeId )
            && ( ( newRec.Federal_Labor_Law_poster__c == NSP_ServiceConstants.No )
                || ( newRec.Federal_Labor_Law_poster__c == NSP_SalesConstants.APPROVAL_STATUS_PENDING )
                )
            && ( ( existingRec == null )
                || ( newRec.NSP_Form_Completed__c )
                || ( newRec.Federal_Labor_Law_poster__c != existingRec.Federal_Labor_Law_poster__c )
                )
            )
        {
            updateEligibleRecordsMap( ipRecordsByAutomation , newRec.Id , FEDERAL_COMPLIANCE_POSTERS );
        }
    }

    private void checkForFederalCompliancePostersMM( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( ( automationsToExecute != null )
            && automationsToExecute.contains( FEDERAL_COMPLIANCE_POSTERS_MM )
            && ( newRec != null )
            && ( newRec.RecordTypeId == ipMMRecordTypeId )
            && ( ( newRec.Federal_Labor_Law_poster__c == NSP_ServiceConstants.No )
                || ( newRec.Federal_Labor_Law_poster__c == NSP_SalesConstants.APPROVAL_STATUS_PENDING )
                )
            && ( ( existingRec == null )
                || ( newRec.NSP_Form_Completed__c )
                || ( newRec.Federal_Labor_Law_poster__c != existingRec.Federal_Labor_Law_poster__c )
                )
            )
        {
            updateEligibleRecordsMap( ipRecordsByAutomation , newRec.Id , FEDERAL_COMPLIANCE_POSTERS_MM );
        }
    }

    private void checkForFlsaReviewEg( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( ( automationsToExecute != null )
            && automationsToExecute.contains( FLSA_REVIEW_EG )
            && ( newRec != null )
            && ( newRec.RecordTypeId == ipFSORecordTypeId )
            && ( newRec.Would_the_client_like_a_FLSA_Exemption__c == NSP_ServiceConstants.Yes )
            && ( newRec.Is_the_client_Emerging_Growth__c == NSP_ServiceConstants.Yes )
            && ( ( existingRec == null )
                || ( newRec.NSP_Form_Completed__c )
                || ( newRec.Would_the_client_like_a_FLSA_Exemption__c != existingRec.Would_the_client_like_a_FLSA_Exemption__c )
                || ( newRec.Is_the_client_Emerging_Growth__c != existingRec.Is_the_client_Emerging_Growth__c )
                )
            )
        {
            updateEligibleRecordsMap( ipRecordsByAutomation , newRec.Id , FLSA_REVIEW_EG );
        }
    }

    private void checkForFlsaReviewYes_MM( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( ( automationsToExecute != null )
            && automationsToExecute.contains( FLSA_REVIEW_YES_MM )
            && ( newRec != null )
            && ( newRec.RecordTypeId == ipMMRecordTypeId )
            && ( newRec.Would_the_client_like_a_FLSA_Exemption__c == NSP_ServiceConstants.Yes )
            && ( ( existingRec == null )
                || ( newRec.NSP_Form_Completed__c )
                || ( newRec.Would_the_client_like_a_FLSA_Exemption__c != existingRec.Would_the_client_like_a_FLSA_Exemption__c )
                )
            )
        {
            updateEligibleRecordsMap( ipRecordsByAutomation , newRec.Id , FLSA_REVIEW_YES_MM );
        }
    }

    private void checkForSeasonalEE(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if(newRec.RecordTypeId != ipMMRecordTypeId
           || newRec.Client_have_will_have_any_Seasonal_EEs__c != NSP_ServiceConstants.YES) {
               return;
           }

        if(   newRec.RecordTypeId == ipMMRecordTypeId &&
           newRec.Client_have_will_have_any_Seasonal_EEs__c == NSP_ServiceConstants.YES){

               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.Client_have_will_have_any_Seasonal_EEs__c != existingRec.Client_have_will_have_any_Seasonal_EEs__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SEASONAL_EE_FN);
                  }
           }
    }

    private void checkForLeaveAbsence(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if(  newRec.RecordTypeId != ipMMRecordTypeId
           || newRec.Are_there_any_EEs_on_Leave_of_Absence__c != NSP_ServiceConstants.YES) {
               return;
           }

        if(    newRec.RecordTypeId == ipMMRecordTypeId &&
           newRec.Are_there_any_EEs_on_Leave_of_Absence__c == NSP_ServiceConstants.YES){

               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.Are_there_any_EEs_on_Leave_of_Absence__c != existingRec.Are_there_any_EEs_on_Leave_of_Absence__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, LEAVE_ABSENCE_FN);
                  }
           }
    }

    private void checkForMMOptum(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {

        if (newRec != null &&
            newRec.NSP_Asset__c != null &&
            newRec.RecordTypeId == ipMMRecordTypeId &&
            newRec.Is_client_s_current_HSA_with_Optum_Bank__c == NSP_ServiceConstants.Yes &&
            (existingRec == null ||
            newRec.NSP_Form_Completed__c ||
            newRec.Is_client_s_current_HSA_with_Optum_Bank__c != existingRec.Is_client_s_current_HSA_with_Optum_Bank__c)) {
                updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, MM_OPTUM_CASE);
        }
    }

    public void createCaseClientProfileInfo(){
        //create case for client profile information
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(CLIENT_PROFILE_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ) ){
                Case eachCase = createCase(ipRec);
                eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY1;
                eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY1;
                eachCase.Subject =NSP_ServiceConstants.SUBJECT1;

                if(mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT)!=null){
                    eachCase.OwnerId=mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT);
                }

                caseList.add(eachCase);
                ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.FSACLIENT,CLIENT_PROFILE_FN,NSP_ServiceConstants.GENERAL));
            }

        }

        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseClientWaitingPeriod(){
        //create case for insperity waiting period
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(WAITING_PERIOD_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm )   && ipRec.NSP_List_Employee_Names__c!=null){
                for( String name:   ipRec.NSP_List_Employee_Names__c.split(',')){
                    Case eachCase = createCase(ipRec);
                    eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY2;
                    eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY2;
                    eachCase.Subject =name+' '+ NSP_ServiceConstants.SUBJECT2;

                    if(mapofGroupIds.get(NSP_ServiceConstants.NATIONAL_BENEFIT_TEAM)!=null){
                        eachCase.OwnerId=mapofGroupIds.get(NSP_ServiceConstants.NATIONAL_BENEFIT_TEAM);
                    }

                    caseList.add(eachCase);
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.WPA,WAITING_PERIOD_FN,NSP_ServiceConstants.BENEFITS));

                }
            }
        }

        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseMedicalNeed(){
        //create case for urgnet medical needs
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(MEDICAL_NEED_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm )   && ipRec.NSP_Urgent_Medical_Needs_Emp_Details__c!=null){
                for( String name:   ipRec.NSP_Urgent_Medical_Needs_Emp_Details__c.split(',')){
                    Case eachCase = createCase(ipRec);
                    eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY2;
                    eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY2;
                    eachCase.Subject =name+' '+ NSP_ServiceConstants.SUBJECT3;

                    if(mapofGroupIds.get(NSP_ServiceConstants.NATIONAL_BENEFIT_TEAM)!=null){
                        eachCase.OwnerId=mapofGroupIds.get(NSP_ServiceConstants.NATIONAL_BENEFIT_TEAM);
                    }

                    caseList.add(eachCase);
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.MEDNEEDS,MEDICAL_NEED_FN,NSP_ServiceConstants.BENEFITS));
                }
            }

        }

        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseWorkersCompCertificate(){
        //create case if workers comp certificate is yes
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(WORKERS_CERTIFICATE_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ) ){
                    Case eachCase = createCase(ipRec);
                    eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY4;
                    eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY4;
                    eachCase.Subject =NSP_ServiceConstants.SUBJECT4;
                    Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                        eachCase.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                    }

                    caseList.add(eachCase);
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.WCERTS,WORKERS_CERTIFICATE_FN,NSP_ServiceConstants.SERVICE_TEAM_SEC));
                }

        }

        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseSeasonalEEFSO(){
        //create case if seasonal EES is yes
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(SEASONAL_EEFSO_FN)){

                Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm )  ){
                    Case eachCase = createCase(ipRec);
                    eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY5;
                    eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY5;
                    eachCase.NSP_Detail__c =NSP_ServiceConstants.SEASONAL_EMP_DETAIL;
                    eachCase.Subject =NSP_ServiceConstants.SUBCATEGORY5;
                    eachCase.NSP_Instructions__c=NSP_ServiceConstants.SEASONALCOMMENT;

                    if(mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE)!=null){
                        eachCase.OwnerId=mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE);
                    }

                    caseList.add(eachCase);
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.SEASONEMP,SEASONAL_EEFSO_FN,NSP_ServiceConstants.PAYROLLSEC));
                }
        }

        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseRRP(){
        //create case if RRP case is yes
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(RRP_CASE_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ) ){
                Case eachCase = createCase(ipRec);
                eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY6;
                eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY6;
                eachCase.NSP_Due_Date__c=System.today().addDays(30);
                if(ipRec.NSP_AIMS_Client_Name__c!=null && ipRec.NSP_AIMS_ClientNo__c!=null){
                    eachCase.Subject=NSP_ServiceConstants.SUBJECT6+' '+ipRec.NSP_AIMS_Client_Name__c+' ('+ipRec.NSP_AIMS_ClientNo__c+')';
                }

                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachCase.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }

                caseList.add(eachCase);
                ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.SUBCATEGORY6,RRP_CASE_FN,NSP_ServiceConstants.MISCELLANEOUS));
            }
        }

        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseHSA(){
        //create case for HSA with optum bank
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(OFFER_HSA_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ) ){
                Case eachCase = createCase(ipRec);
                eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY7;
                eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY1;
                if(ipRec.Optum_Bank_HSA_Code__c!=null && ipRec.Optum_Bank_HSA_Group__c!=null){
                    eachCase.Subject=NSP_ServiceConstants.SUBJECT7+' '+ipRec.Optum_Bank_HSA_Code__c+'; Group ID: '+ipRec.Optum_Bank_HSA_Group__c;
                }

                if(mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT)!=null){
                    eachCase.OwnerId=mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT);
                }

                caseList.add(eachCase);
                ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.OPTOCOLLECTED,OFFER_HSA_FN,NSP_ServiceConstants.BENEFITS));
            }
        }

        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseOPTUM(){
        //create case for HSA with optum bank
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(OFFER_OPTUM_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm )  ){
                Case eachCase = createCase(ipRec);
                eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY7;
                eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY1;
                eachCase.Subject =NSP_ServiceConstants.SUBJECT8;

                if(mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT)!=null){
                    eachCase.OwnerId=mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT);
                }
               /* Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachCase.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                } */

                caseList.add(eachCase);
                ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.OPTOMISSING,OFFER_OPTUM_FN,NSP_ServiceConstants.BENEFITS));
            }
        }
        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseLeaveAbsenceFSO(){
        //create case for EEs on Leave of Absence
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();
        for(Id ipRecId : ipRecordsByAutomation.get(LEAVE_ABSENCEFSO_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm )     ){

                Case eachCase = createCase(ipRec);
                eachCase.NSP_Category__c = NSP_ServiceConstants.SUBCATEGORY9;
                eachCase.NSP_SubCategory__c = NSP_ServiceConstants.LOAPAPERWORK;
                eachCase.Subject =NSP_ServiceConstants.SUBJECT9;
                eachCase.NSP_Instructions__c = NSP_ServiceConstants.LOACOMMETNS;
                eachCase.NSP_Detail__c=NSP_ServiceConstants.LOADETAILS;

                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachCase.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }

                caseList.add(eachCase);
                ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.EESONLOA,LEAVE_ABSENCEFSO_FN,NSP_ServiceConstants.EMPLOYEESEC));

            }
        }

        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseSeasonal(){
        //create case if seasonal EES is yes
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(SEASONAL_EE_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ) ){
                Case eachCase = createCase(ipRec);
                eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY5;
                eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY5;
                eachCase.NSP_Detail__c =NSP_ServiceConstants.SEASONAL_EMP_DETAIL;
                eachCase.Subject =NSP_ServiceConstants.SUBCATEGORY5;
                eachCase.NSP_Instructions__c=NSP_ServiceConstants.SEASONALCOMMENT;

                if(mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE)!=null){
                    eachCase.OwnerId=mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE);
                }

                caseList.add(eachCase);
                ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.SEASONEMPHW,SEASONAL_EE_FN,NSP_ServiceConstants.EMPLOYEESEC));
            }
        }
        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    public void createCaseLeaveAbsence(){
        //If Are there any EEs on Leave of Absence?
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(LEAVE_ABSENCE_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if( ((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm )  ){
                Case eachCase = createCase(ipRec);
                eachCase.NSP_Category__c = NSP_ServiceConstants.SUBCATEGORY9;
                eachCase.NSP_SubCategory__c = NSP_ServiceConstants.LOAPAPERWORK;
                eachCase.Subject =NSP_ServiceConstants.SUBJECT9;
                eachCase.NSP_Instructions__c = NSP_ServiceConstants.LOACOMMETNS;
                eachCase.NSP_Detail__c=NSP_ServiceConstants.LOADETAILS;

                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachCase.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }

                caseList.add(eachCase);
                ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.EESONLOA,LEAVE_ABSENCE_FN,NSP_ServiceConstants.EMPLOYEESEC));

            }
        }


        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));


    }
    public void createCaseEmpHours(){
        //How will employee hours be reported to Insperity?
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();

        for(Id ipRecId : ipRecordsByAutomation.get(EMP_HOURS_FN)){

            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm )  ){
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                Case eachCase = createCase(ipRec);
                eachCase.NSP_Category__c = NSP_ServiceConstants.INFRASTRUCTURE;
                eachCase.NSP_SubCategory__c = NSP_ServiceConstants.PTO;
                eachCase.Subject =NSP_ServiceConstants.TIMEENTRY+' '+ipRec.How_are_empl_hrs_reported_to_Insperity__c;
                eachCase.NSP_Instructions__c=NSP_ServiceConstants.HRSREVIEW;
                eachCase.NSP_Due_Date__c=System.today().addDays(12);
                if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                    eachCase.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                }

                caseList.add(eachCase);
                ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, NSP_ServiceConstants.TIMEENTRYHOURS,EMP_HOURS_FN,NSP_ServiceConstants.PAYROLLSEC));
            }
        }

        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
    }

    private Case createCase(Implementation_Profile__c ip){

        Case eachCase = new Case();
        eachCase.RecordTypeId = casePEORecordTypeId;
        eachCase.Status = NSP_ServiceConstants.OPEN;
        eachCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        eachCase.Priority = NSP_ServiceConstants.MEDIUM;
        eachCase.Origin = NSP_ServiceConstants.FOLLOWUP;
        if(ip!=null){
            eachCase.NSP_Implementation_Profile__c=ip.Id;
        }

        if (ip.NSP_Asset__c != null) {
            Implementation_Profile__c ipWithAsset= (Implementation_Profile__c)data.get(IP_IDENTIFIER).get(ip.Id);
            eachCase.AssetId = ipWithAsset.NSP_Asset__c;
            eachCase.AccountId = ipWithAsset.NSP_Asset__r.AccountId;
        }
        else if(ip.NSP_Asset__c==null && ip.RecordTypeId == ipMMRecordTypeId && ip.Account__c!=null){
            eachCase.AccountId = ip.Account__c;

        }

        return eachCase;

    }

    private void createCases( String automation ) {
        Case_Automation__mdt caseMdt = null;
        if ( automation != null ) {
            caseMdt = Case_Automation__mdt.getInstance( automation );
        }
        if ( ipRecordsByAutomation.containsKey( automation )
            && ( ipRecordsByAutomation.get(automation) != null )
            )
        {
            for ( Id ipRecId : ipRecordsByAutomation.get( automation ) ) {
                if ( newIPs != null ) {
                    Implementation_Profile__c ipRec = newIPs.get( ipRecId );
                    if ( ( ipRec != null )
                        && ( isRerun || ipRec.NSP_Form_Completed__c )
                        && !isSaveForm
                        )
                    {
                        caseAutomations( automation , caseMdt , ipRecId );
                    }
                }
            }
        }
    }

    private void caseAutomations(
        String automation ,
        Case_Automation__mdt caseMdt ,
        Id ipRecId
        )
    {
        if ( ( data != null )
            && data.containsKey( IP_IDENTIFIER )
            && ( data.get( IP_IDENTIFIER ) != null )
            && data.get( IP_IDENTIFIER ).containsKey( ipRecId )
            && ( data.get( IP_IDENTIFIER ).get( ipRecId ) != null )
            )
        {
            Implementation_Profile__c ipwithValue=(Implementation_Profile__c)data.get( IP_IDENTIFIER ).get( ipRecId );
            //Add here Case automations for IP
            createPostersCase( automation , caseMdt , ipRecId , ipwithValue );
            createFlsaReviewEgCase( automation , caseMdt , ipRecId , ipwithValue );
        }
    }

    private Case createComplianceCase(
        Case_Automation__mdt caseMdt ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue
        )
    {
        Case eachCase = new Case();
        eachCase.NSP_Opened_Date__c = Date.today();
        if ( ipWithValue != null ) {
            eachCase.AssetId = ipWithValue.NSP_Asset__c;
            eachCase.NSP_ClientNumber__c = ipwithValue.NSP_AIMS_ClientNo__c;
            if ( ipWithValue.NSP_Asset__r != null ) {
                eachCase.AccountId = ipWithValue.NSP_Asset__r.AccountId;
                eachCase.NSP_Segment__c = ipWithValue.NSP_Asset__r.NSP_Client_Segment_type__c;
            }
        }
        eachCase.Status = NSP_ServiceConstants.OPEN;
        eachCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        eachCase.NSP_Rating__c = NSP_ServiceConstants.CASE_RATING;
        eachCase.NSP_Implementation_Profile__c = ipRecId;
        eachCase.Project__c = ipWithValue.NSP_Project__c;
        if ( caseMdt != null ) {
            eachCase.Subject = SchemaController.safeText(
                caseMdt.Subject__c ,
                sObjectType.Case.Fields.Subject
            );
            eachCase.Origin = SchemaController.safeText(
                caseMdt.Origin__c ,
                sObjectType.Case.Fields.Origin
            );
            eachCase.NSP_Instructions__c = SchemaController.safeText(
                caseMdt.Instructions__c ,
                sObjectType.Case.Fields.NSP_Instructions__c
            );
            eachCase.NSP_Category__c = SchemaController.safeText(
                caseMdt.Category__c ,
                sObjectType.Case.Fields.NSP_Category__c
            );
            eachCase.NSP_SubCategory__c = SchemaController.safeText(
                caseMdt.Sub_Category__c ,
                sObjectType.Case.Fields.NSP_SubCategory__c
            );
        }
        return eachCase;
    }

    private void createPostersCase(
        String automation ,
        Case_Automation__mdt caseMdt ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue
        )
    {
        if ( automation == FEDERAL_COMPLIANCE_POSTERS || automation == FEDERAL_COMPLIANCE_POSTERS_MM ) {
            Case eachCase = createComplianceCase( caseMdt , ipRecId , ipwithValue );
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance( automation );
            if ( ( automation == FEDERAL_COMPLIANCE_POSTERS )
                && ( ipwithValue.NSP_Orientation_Coordinator__c != null )
                && ( ipwithValue.NSP_Orientation_Coordinator__r.pse__Salesforce_User__c != null )
                )
            {
                eachCase.OwnerId = ipwithValue.NSP_Orientation_Coordinator__r.pse__Salesforce_User__c;
            } else if ( ( automation == FEDERAL_COMPLIANCE_POSTERS_MM )
                && ( ipwithValue.NSP_Transition_Specialist__c != null )
                && ( ipwithValue.NSP_Transition_Specialist__r.pse__Salesforce_User__c != null )
                )
            {
                eachCase.OwnerId = ipwithValue.NSP_Transition_Specialist__r.pse__Salesforce_User__c;
            }
            ipAutomationRecords.add(
                ipAutomationHelper.createIPAutomation(
                    ipwithValue ,
                    ipa.NSP_Automation_Name__c ,
                    ipa.NSP_Method_Name__c ,
                    ipa.NSP_Section__c
                )
            );
            if ( eachCase != null ) {
                caseToInsertList.add( eachCase );
            }
        }
    }

    private void createFlsaReviewEgCase(
        String automation ,
        Case_Automation__mdt caseMdt ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue
    )
    {
        if ( automation == FLSA_REVIEW_EG || automation == FLSA_REVIEW_YES_MM ) {
            Case eachCase = createComplianceCase( caseMdt , ipRecId , ipwithValue );
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance( automation );
            List<Group> flsaComplianceQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'FLSA_Compliance' LIMIT 1];
            Date today = Date.today();
            Date dueDate = today.addDays(90);
            String clients = relatedClients(ipWithValue, FALSE);
            String contacts = flsaReviewContacts(ipWithValue);
            String relatedAccounts = '';
            String bulletList = '';
            String flsReviewContacts = '';
            String lineBreak = '\n';
            if(String.isNotBlank(clients)) {
                relatedAccounts = RELATED_ACCOUNTS + lineBreak;
                bulletList = clients;
            }
            if ( String.isNotBlank( contacts ) ) {
                flsReviewContacts = 'FLSA Review Contact(s):'+lineBreak + contacts;
            }
            if(eachCase != null && ipa != null) {
                if(flsaComplianceQueue != null) {
                    eachCase.OwnerId = flsaComplianceQueue[0].Id;
                }
                eachCase.NSP_Due_Date__c = dueDate;
                eachCase.Description = flsReviewContacts
                    + lineBreak
                    + lineBreak
                    + relatedAccounts
                    + bulletList;
                ipAutomationRecords.add(
                    ipAutomationHelper.createIPAutomation(
                        ipwithValue ,
                        ipa.NSP_Automation_Name__c ,
                        ipa.NSP_Method_Name__c ,
                        ipa.NSP_Section__c
                    )
                );
                if ( eachCase != null ) {
                    caseToInsertSubjectIpList.add( eachCase );
                }
            }
        }
    }

    public void createMMCaseOPTUM(){
        //create case for HSA with optum bank
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<Case> caseList = new List<Case>();
        String subject = 'Prior HSA with Optum Bank - ';
        String instruction = 'Confirm current HSA platform and HSA transfer process for employees.\nSBOS: Once Employer Code/Group # or participant data provided in the Notes, reassign to H&W Products Queue.';
        for(Id ipRecId : ipRecordsByAutomation.get(MM_OPTUM_CASE)){
            if(ipRecId != null){
                Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                if (ipRec != null ){
                    if(((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm )  ){
                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                        Case eachCase = createCase(ipRec);
                        if(ipWithValue != null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                            eachCase.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                            eachCase.NSP_Category__c = NSP_ServiceConstants.CATEGORY7;
                            eachCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY1;
                            eachCase.Subject =subject+ipWithValue.Account__r.Name;
                            eachCase.NSP_Instructions__c = instruction;
                            eachCase.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
                            eachCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
                            eachCase.Priority = NSP_ServiceConstants.MEDIUM;
                            eachCase.Origin = NSP_ServiceConstants.CANCELLED_REASON;
                            eachCase.AssetId = ipwithValue.NSP_Asset__c;
                            eachCase.NSP_Segment__c = ipWithValue.Account__r.NSP_Service_Segment__c;
                        }

                        caseList.add(eachCase);
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, MMOPTUM,MM_OPTUM_CASE,NSP_ServiceConstants.BENEFITS));
                    }
                }
            }
        }
        //check for existing Case and store the new cases
        recToInsert.addAll(ipAutomationHelper.getnewCasestoInsert(caseList));
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));

    }

    //Email notification for IP Automation STY-02164


    /**
     Automathion Section: General
     Automation Name: Cafeteria Plan Changes
     Automation icon: envelope
    */

    private void checkForCafeterialPlan(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(   newIp.RecordTypeId == ipFSORecordTypeId  &&
        String.isNotBlank(newIp.NSP_BPA_BPC__c) && newIp.Chngs_for_cafeteria_plan_questionnaire__c==NSP_ServiceConstants.YES
                   && newIp.List_change_s__c!=null){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, CAFETERIAL_PLAN_FN);

         }
    }

    private  void emailNotifyForCafeteriaPlan(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(CAFETERIAL_PLAN_FN);
        List<String> listOfToAddress =new List<String>();
        UserWrapper userWrapper = new UserWrapper();
        for(Id ipRecId : ipRecordsByAutomation.get(CAFETERIAL_PLAN_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(String.isNotBlank(ipWithValue.NSP_BPA_BPC__c) && String.isNotBlank(ipWithValue.NSP_BPA_BPC_Ids__c)){
                    List<String> listOfBPAIds =ipWithValue.NSP_BPA_BPC_Ids__c.split(',');
                    userWrapper=getDAEmail(listOfBPAIds);
                    listOfToAddress.addAll(userWrapper.bpaEmialList);
                    listOfToAddress.addAll(userWrapper.daEmailList);
                }

                if(!isRerun && !listOfToAddress.isEmpty() && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+CAFETERIAL_PLAN_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null,mapOfEmailTempaltes.get(CAFETERIAL_PLAN_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun && !listOfToAddress.isEmpty()){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null,mapOfEmailTempaltes.get(CAFETERIAL_PLAN_FN).Id,isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
            }
    }

    /**
     Automathion Section: Payroll
     Automation Name: FLSA Approval for Commission Only
     Automation icon: envelope
    */

    private void checkForEECommission(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){
        if(newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.Client_have_any_Commission_only_EEs__c==NSP_ServiceConstants.YES
           && newIp.Has_FLSA_team_approved__c==NSP_ServiceConstants.NO){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, EE_COMMISSION_FN);

         }
    }

    private  void emailNotifyForEECommission(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(EE_COMMISSION_FN);
        List<String> listOfToAddress = new List<String>();
        UserWrapper userWrapper = new UserWrapper();

        for(Id ipRecId : ipRecordsByAutomation.get(EE_COMMISSION_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(String.isNotBlank(ipWithValue.NSP_BPA_BPC__c) && String.isNotBlank(ipWithValue.NSP_BPA_BPC_Ids__c)){
                    List<String> listOfBPAIds =ipWithValue.NSP_BPA_BPC_Ids__c.split(',');
                    userWrapper=getDAEmail(listOfBPAIds);
                    listOfToAddress.addAll(userWrapper.bpaEmialList);
                    listOfToAddress.addAll(userWrapper.daEmailList);
                }
                if(!isRerun && !listOfToAddress.isEmpty() && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EE_COMMISSION_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null,mapOfEmailTempaltes.get(EE_COMMISSION_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun && !listOfToAddress.isEmpty() ){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null,mapOfEmailTempaltes.get(EE_COMMISSION_FN).Id,isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
         NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
    }

    /**
     Automathion Section: Payroll
     Automation Name: AWW - Yes
     Automation icon: envelope
    */
    private void checkforClientAWWYes(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if ( newRec != null ) {
            if ( newRec.RecordTypeId == ipFSORecordTypeId
                && newRec.Does_this_client_have_an_AWW__c == NSP_ServiceConstants.YES
                && newRec.Is_client_CA_docs_submitted_for_approval__c != null
                )
            {
                checkforClientAWW(newRec, existingRec, CLIENT_AWW_YES);
            }
        }
    }

    private void emailNotifyforclientAWWYes() {
        if(ipRecordsByAutomation != null) {
            for(Id ipRecId : ipRecordsByAutomation.get(CLIENT_AWW_YES)) {
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(ipWithValue != null) {
                    String subject = ipWithValue.Account__r.Name + ' ('+ ipWithValue.NSP_AIMS_ClientNo__c+') has an AWW';
                    String body = ipWithValue.Account__r.Name + ' ('+ ipWithValue.NSP_AIMS_ClientNo__c+') has employees with an Alternative Work Week (AWW) schedule. Partner\n'+
                        'with client to obtain any required documentation. Additional information below.\n'+
                        '\nDoes this client have an Alternative Workweek or AWW? '+ ipWithValue.Does_this_client_have_an_AWW__c +
                        '\nIf client has employees in CA who work this schedule, has the client already submitted all required\n'+
                        'documentation to the state for approval? '+ipWithValue.Is_client_CA_docs_submitted_for_approval__c+'\n';
                    emailNotifyforclientAWW(ipWithValue, CLIENT_AWW_YES, subject, body, 'AWW_Yes');
                }
            }
        }
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
    }

    /**
     Automathion Section: Payroll
     Automation Name: AWW - No
     Automation icon: envelope
    */
    private void checkforClientAWWNo(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if ( newRec != null ) {
            if( newRec.RecordTypeId == ipFSORecordTypeId
                && newRec.Does_this_client_have_an_AWW__c == NSP_ServiceConstants.NO
                )
            {
                checkforClientAWW(newRec, existingRec, CLIENT_AWW_NO);
            }
        }
    }

    private void emailNotifyforclientAWWNo() {
        if(ipRecordsByAutomation != null) {
            for(Id ipRecId : ipRecordsByAutomation.get(CLIENT_AWW_NO)) {
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(ipWithValue != null) {
                    String subject = ipWithValue.Account__r.Name + ' ('+ ipWithValue.NSP_AIMS_ClientNo__c+') does not have an AWW';
                    String body = ipWithValue.Account__r.Name + ' ('+ ipWithValue.NSP_AIMS_ClientNo__c+') does not have an Alternative Work Week.';
                    emailNotifyforclientAWW(ipWithValue, CLIENT_AWW_NO, subject, body, 'AWW_No');
                }
            }
        }
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
    }

    private void checkforFlsaReviewNo( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( automationsToExecute != null
            && automationsToExecute.contains( FLSA_REVIEW_NO )
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Would_the_client_like_a_FLSA_Exemption__c == NSP_ServiceConstants.No
            && newRec.NSP_HR_Specialist__c != null
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Would_the_client_like_a_FLSA_Exemption__c != existingRec.Would_the_client_like_a_FLSA_Exemption__c
                )
            )
        {
            updateEligibleRecordsMap( ipRecordsByAutomation , newRec.Id , FLSA_REVIEW_NO );
        }
    }

    private void emailNotifyforFlsaReviewNo() {
        if ( this.ipRecordsByAutomation != null ) {
            for ( Id ipRecId : this.ipRecordsByAutomation.get( NSP_Implementationprofile_ServiceHelper.FLSA_REVIEW_NO ) ) {
                Implementation_Profile__c ipWithValue = (Implementation_Profile__c)this.data.get( NSP_Implementationprofile_ServiceHelper.IP_IDENTIFIER ).get( ipRecId );
                if ( ipWithValue != null ) {
                    String clients = this.relatedClients( ipWithValue , true );
                    String relatedAccounts = '';
                    String bulletList = '';
                    if ( String.isNotBlank( clients ) ) {
                        relatedAccounts = RELATED_ACCOUNTS;
                        bulletList = clients;
                    }
                    String subject = ipWithValue.Account__r.Name + ' (' + ipWithValue.NSP_AIMS_ClientNo__c + ') FLSA Exemption Classification Review Declined';
                    String body = ''
                        + ipWithValue.Account__r.Name
                        + ' (' + ipWithValue.NSP_AIMS_ClientNo__c + ') does not want to have an exemption classification '
                        + 'review during implementation.'
                        + '<p> No action is required on your part for FLSA Exemption Classification Review.</p>'
                        + '<p> Service Team HR Professional: You have been included on this message for information purposes only. '
                        + 'No action is required on your part. Please do not make FLSA Review a part of your initial client meetings or conversations. '
                        + 'FLSA Review is only to be initiated when a client asks for this service in the future.</p>'
                        + relatedAccounts
                        + bulletList
                        ;
                    this.emailFlsaReviewNo(
                        ipWithValue ,
                        NSP_Implementationprofile_ServiceHelper.FLSA_REVIEW_NO ,
                        subject ,
                        body ,
                        'FLSA_Review_No'
                    );
                }
            }
        }
        if ( ( impRecordId != null ) && ( impAutomationName != null ) ) {
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(
                impRecordId ,
                impAutomationName ,
                impMethodName ,
                impAutomationRecordType ,
                impAutomationSection
            );
        }
    }

    private void emailFlsaReviewNo(Implementation_Profile__c ipWithValue, String fnName, String subject, String body, String mdtName) {
        if( ipWithValue != null ) {
            List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
            List<String> emailAddress = new List<String>();
            NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(FLSA_REVIEW_NO);
            if ( String.isNotBlank( pf.NSP_Email_Address__c ) ) {
                emailAddress.add(pf.NSP_Email_Address__c);
            }
            if(ipWithValue.NSP_HR_Specialist__c != null && ipWithValue.NSP_HR_Specialist__r.NSP_Work_email__c != null) {
                emailAddress.add(ipWithValue.NSP_HR_Specialist__r.NSP_Work_email__c);
            }

            ipAutomationRecords = runEmailAutomation(ipWithValue,fnName,subject,body,mdtName,emailAddress);
            if(ipAutomationRecords != null) {
                recToInsert.addAll(ipAutomationRecords);
            }
        }
    }

    private void checkforFlsaReviewNoMM( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( automationsToExecute != null
            && automationsToExecute.contains( FLSA_REVIEW_NO_MM )
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Would_the_client_like_a_FLSA_Exemption__c == NSP_ServiceConstants.No
            && newRec.NSP_HR_Specialist__c != null
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Would_the_client_like_a_FLSA_Exemption__c != existingRec.Would_the_client_like_a_FLSA_Exemption__c
                )
            )
        {
            updateEligibleRecordsMap( ipRecordsByAutomation , newRec.Id , FLSA_REVIEW_NO_MM );
        }
    }

    private void emailNotifyforFlsaReviewNoMM() {
        if(ipRecordsByAutomation != null) {
            for(Id ipRecId : ipRecordsByAutomation.get(FLSA_REVIEW_NO_MM)) {
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(ipWithValue != null) {

                    String clients = relatedClients(ipWithValue, TRUE);
                    String relatedAccounts = '';
                    String bulletList = '';
                    if(String.isNotBlank(clients)) {
                        relatedAccounts = RELATED_ACCOUNTS;
                        bulletList = clients;
                    }

                    String subject = ipWithValue.Account__r.Name + ' ('+ ipWithValue.NSP_AIMS_ClientNo__c+') FLSA Exemption Classification Review declined';
                    String body = ipWithValue.Account__r.Name + ' ('+ ipWithValue.NSP_AIMS_ClientNo__c+') has declined a FLSA Exemption Classification Review. '
                        +'<p>HR Specialist: Please do not make FLSA Review a part of your initial client meetings or conversations. '
                        + 'FLSA Review is only to be initiated when a client asks for this service in the future. </p>'
                        + relatedAccounts
                        + bulletList;
                    emailFlsaReviewNoMM(ipWithValue, FLSA_REVIEW_NO_MM, subject, body, 'FLSA_Review_No_MM');
                }
            }
        }
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
    }

    private void emailFlsaReviewNoMM(Implementation_Profile__c ipWithValue, String fnName, String subject, String body, String mdtName) {
        if( ipWithValue != null ) {
            List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
            List<String> emailAddress = new List<String>();
            NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(FLSA_REVIEW_NO_MM);
            if ( String.isNotBlank( pf.NSP_Email_Address__c ) ) {
                emailAddress.add(pf.NSP_Email_Address__c);
            }
            if(ipWithValue.NSP_HR_Specialist__c != null && ipWithValue.NSP_HR_Specialist__r.NSP_Work_email__c != null) {
                emailAddress.add(ipWithValue.NSP_HR_Specialist__r.NSP_Work_email__c);
            }

            ipAutomationRecords = runEmailAutomation(ipWithValue,fnName,subject,body,mdtName,emailAddress);
            if(ipAutomationRecords != null) {
                recToInsert.addAll(ipAutomationRecords);
            }
        }
    }

    private void checkforFlsaExemptionReview( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if (automationsToExecute.contains(FLSA_EXEMPTION_REVIEW_EMAIL)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Would_the_client_like_a_FLSA_Exemption__c == NSP_ServiceConstants.YES
            && newRec.Is_the_client_Emerging_Growth__c == NSP_ServiceConstants.No
            && newRec.NSP_HR_Quality_Support_Team_Member__c != null
            && newRec.NSP_HR_Specialist__c != null
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Would_the_client_like_a_FLSA_Exemption__c != existingRec.Would_the_client_like_a_FLSA_Exemption__c
                || newRec.Is_the_client_Emerging_Growth__c != existingRec.Is_the_client_Emerging_Growth__c
                )
            )
        {
            updateEligibleRecordsMap( ipRecordsByAutomation , newRec.Id , FLSA_EXEMPTION_REVIEW_EMAIL );
        }
    }

    private void emailNotifyforFlsaExemptionReview() {
        if(ipRecordsByAutomation != null) {
            for(Id ipRecId : ipRecordsByAutomation.get( FLSA_EXEMPTION_REVIEW_EMAIL ) ) {
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(ipWithValue != null) {

                    String clients = relatedClients(ipWithValue, TRUE);
                    String relatedAccounts = '';
                    String bulletList = '';
                    if(String.isNotBlank(clients)) {
                        relatedAccounts = RELATED_ACCOUNTS;
                        bulletList = clients;
                    }

                    String subject = ipWithValue.Account__r.Name + ' ('+ ipWithValue.NSP_AIMS_ClientNo__c+') FLSA Exemption Classification Review Requested';
                    String body = ipWithValue.Account__r.Name + ' ('+ ipWithValue.NSP_AIMS_ClientNo__c+') would like to have an exemption classification review during implementation.'
                        +'<p> Payroll Quality Support: Please proceed with your review of client exemption classifications. </p>'
                        +'<p> Implementation: Once Payroll Quality Support has finished their review, please proceed with your client notification steps.</p>'
                        +'<p>Service Team HR Professional: You have been included on this message for information purposes only. No action is required on your part. '
                        +'Please do not make FLSA Review a part of your initial client meetings or conversations. FLSA Review is only to be initiated when a client '
                        +'asks for this service in the future.</p>'
                        + relatedAccounts
                        + bulletList;
                    emailFlsaExemptionReview(ipWithValue, FLSA_EXEMPTION_REVIEW_EMAIL, subject, body, 'FLSA_Exemption_Review_non_EG_Email');
                }
            }
        }
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
    }

    private void emailFlsaExemptionReview(Implementation_Profile__c ipWithValue, String fnName, String subject, String body, String mdtName) {
        if( ipWithValue != null ) {
            List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
            List<String> emailAddress = new List<String>();
            NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(FLSA_REVIEW_NO);
            if ( String.isNotBlank( pf.NSP_Email_Address__c ) ) {
                emailAddress.add(pf.NSP_Email_Address__c);
            }
            if( ipWithValue.NSP_HR_Specialist__c != null
               && ipWithValue.NSP_HR_Specialist__r.NSP_Work_email__c != null ) {
                   emailAddress.add(ipWithValue.NSP_HR_Specialist__r.NSP_Work_email__c);
               }
            if( ipWithValue.NSP_HR_Quality_Support_Team_Member__r.NSP_Work_email__c != null) {
                emailAddress.add(ipWithValue.NSP_HR_Quality_Support_Team_Member__r.NSP_Work_email__c);
            }
            ipAutomationRecords = runEmailAutomation(ipWithValue,fnName,subject,body,mdtName,emailAddress);
            if(ipAutomationRecords != null) {
                recToInsert.addAll(ipAutomationRecords);
            }
        }
    }

    private List<NSP_Implementation_Profile_Automation__c> runEmailAutomation(
        Implementation_Profile__c ipWithValue ,
        String fnName ,
        String subject ,
        String body ,
        String mdtName ,
        List<String> emailAddress
        )
    {
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        String recordType = '';
        if ( ipWithValue.RecordTypeId == ipFSORecordTypeId ) {
            recordType = NSP_ServiceConstants.FSOProfile;
        } else {
            recordType = NSP_ServiceConstants.MIDDLEMARKET;
        }
        if ( String.isNotBlank( fnName )
            && String.isNotBlank( subject )
            && String.isNotBlank( body )
            && String.isNotBlank( mdtName )
            && String.isNotBlank( recordType )
            )
        {
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(mdtName);
            if ( ( isRerun || ipWithValue.NSP_Form_Completed__c )
                && !isSaveForm
                && ( ipa != null )
                )
            {
                if ( !isRerun
                    && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipWithValue.Id+'_'+fnName+'_'+recordType )
                    )
                {
                    sendMailUsingFlowAction( emailAddress , subject , body );
                    ipAutomationRecords.add(
                        ipAutomationHelper.createIPAutomation(
                            ipWithValue ,
                            ipa.NSP_Automation_Name__c ,
                            ipa.NSP_Method_Name__c ,
                            ipa.NSP_Section__c
                        )
                    );
                } else if ( isRerun ) {
                    sendMailUsingFlowAction( emailAddress , subject , body );
                    impRecordId = ipWithValue.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    impAutomationRecordType = recordType;
                }
            }
        }
        return ipAutomationRecords;
    }

    //
    // Automathion Section: Service Team
    // Automation Name: LicensedContractorYes
    // Automation icon: envelope
    //
    private void checkForLicensedContractor( Implementation_Profile__c newIp , String contractorType ) {
        Id recordTypeId = (contractorType == LICENSED_CONTRACTOR_YES_FSO) ? ipFSORecordTypeId : ipMMRecordTypeId;
        if ( newIp != null
            && newIp.RecordTypeId == recordTypeId
            && newIp.Are_you_registered_with_the_CSLB__c == NSP_ServiceConstants.YES
            && String.isNotBlank(newIp.Contractor_s_License__c)
            && String.isNotBlank(newIp.NSP_Legal_Name__c)
            && newIp.Effective_Date_Payroll_Worker_comp_EPLI__c != null
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, contractorType);
        }
    }

    private void emailNotifyForLicensedContractor( String contractorType , String mdtName ) {
        if (ipRecordsByAutomation != null) {
            for (Id ipRecId : ipRecordsByAutomation.get(contractorType)) {
                Implementation_Profile__c ipWithValue = (Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if (ipWithValue != null) {
                    String aimsClient = '(' + ipWithValue.NSP_AIMS_ClientNo__c + ')';
                    String subject = ipWithValue.Account__r.Name + ' ' + aimsClient +' is a Licensed Contractor in California';
                    String effectiveDate = null;
                    if(ipWithValue.Effective_Date_Payroll_Worker_comp_EPLI__c != null){
                       effectiveDate = ipWithValue.Effective_Date_Payroll_Worker_comp_EPLI__c.format();
                    }
                    String body = 'Lockton Affinity,<br><br>'
                        + ipWithValue.Account__r.Name
                        + ' '
                        + aimsClient
                        + ' is a Licensed Contractor in California. Please update the CSLB website with the client\'s new Workers\' Comp coverage through Insperity.<br><br>'
                        + 'LEGAL NAME: ' + ipWithValue.NSP_Legal_Name__c + '\n'
                        + 'CONTRACTORS CSLB#: ' + ipWithValue.Contractor_s_License__c + '\n'
                        + 'EFFECTIVE DATE: ' + effectiveDate + '<br><br>'
                        + 'Regards' + ',\n'
                        + ipWithValue.NSP_Project_Manager__r.Name + '\n'
                        + ipWithValue.NSP_Project_Manager__r.NSP_Job_Title__c + '\n'
                        + ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c + '\n';
                    emailNotify(ipWithValue, contractorType, subject, body, mdtName);
                }
            }
        }
        if (impRecordId != null && impAutomationName != null) {
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(
                impRecordId ,
                impAutomationName ,
                impMethodName ,
                impAutomationRecordType ,
                impAutomationSection
            );
        }
    }

    private void emailNotify( Implementation_Profile__c ipWithValue , String contractorType , String subject , String body , String mdtName ) {
        if ( ipWithValue != null
            && String.isNotBlank(contractorType)
            && String.isNotBlank(subject)
            && String.isNotBlank(body)
            && String.isNotBlank(mdtName)
            )
        {
            List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
            List<String> emailAddress = new List<String>();
            NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(LicensedContractorEmail);
            if ( String.isNotBlank( pf.NSP_Email_Address__c ) ) {
                emailAddress.add(pf.NSP_Email_Address__c);
            }
            if ( ipWithValue.NSP_Project_Manager__r != null
                && ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c != null
                )
            {
                emailAddress.add(ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c);
            }
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(mdtName);
            if ((isRerun || ipWithValue.NSP_Form_Completed__c)
                && !isSaveForm
                && ipa != null
                )
            {
                String automationIdentifier = ipWithValue.Id
                    + '_' + contractorType + '_'
                    + (contractorType == LICENSED_CONTRACTOR_YES_FSO ? NSP_ServiceConstants.FSOProfile : NSP_ServiceConstants.MIDDLEMARKET);
                if (!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(automationIdentifier)) {
                    sendMailUsingFlowAction(emailAddress, subject, body);
                    ipAutomationRecords.add(
                        ipAutomationHelper.createIPAutomation(
                            ipWithValue ,
                            ipa.NSP_Automation_Name__c ,
                            ipa.NSP_Method_Name__c ,
                            ipa.NSP_Section__c
                        )
                    );
                } else if (isRerun) {
                    sendMailUsingFlowAction(emailAddress, subject, body);
                    impRecordId = ipWithValue.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    impAutomationRecordType = (contractorType == LICENSED_CONTRACTOR_YES_FSO ? NSP_ServiceConstants.FSOProfile : NSP_ServiceConstants.MIDDLEMARKET);
                }
            }
            recToInsert.addAll(ipAutomationRecords);
        }
    }

    /**
     Automathion Section: Orientation
     Automation Name: Tech Packet Needed
     Automation icon: envelope
    */

    private void checkForTechPacket(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if( newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.Is_there_a_need_for_a_tech_package__c==NSP_ServiceConstants.YES){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, TECH_PACKET_FN);

         }
    }

    private  void emailNotifyForTechPacket(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(TECH_PACKET_FN);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(TECH_PACKET_FN);
        String orientationEmail;
        for(Id ipRecId : ipRecordsByAutomation.get(TECH_PACKET_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            List<String> emailAddress = new List<String>();
           if(ipRec.NSP_OT_Representative__c != null && ipRec.NSP_OT_Representative__r.NSP_Work_email__c != null ){
                orientationEmail = ipRec.NSP_OT_Representative__r.NSP_Work_email__c;
                emailAddress.add(orientationEmail);
            }
            emailAddress.add(pf.NSP_Email_Address__c);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+TECH_PACKET_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,emailAddress,null,null,mapOfEmailTempaltes.get(TECH_PACKET_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,emailAddress,null,null,mapOfEmailTempaltes.get(TECH_PACKET_FN).Id,isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
            }
    }


    /**
      Automation Section: Payroll
      Automation Name: Workers’ Comp Notification
      Automation icon: envelope
      */
    private void checkforWCNotification(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){
        List<String> stateCodes=new List<String>{'NH','WY','ND','WA','NY','MA','VA','OH','RI'};
        if((newIp.RecordTypeId == ipFSORecordTypeId  || (newIp.RecordTypeId == ipMMRecordTypeId && newIp.NSP_Asset__c!=null ) ) &&
        newIp.Employees_work_in_the_following_states__c!=null && newIp.Client_does_business_in_MA_NY_or_VA__c!=null &&
        newIp.Effective_Date_Payroll_Worker_comp_EPLI__c!=null && findSharedValue(stateCodes,newIp.Employees_work_in_the_following_states__c)){

                   if(existingRec == null || newIp.NSP_Form_Completed__c || newIp.Client_does_business_in_MA_NY_or_VA__c != existingRec.Client_does_business_in_MA_NY_or_VA__c
                      ||newIp.Effective_Date_Payroll_Worker_comp_EPLI__c != existingRec.Effective_Date_Payroll_Worker_comp_EPLI__c
                      ||newIp.Employees_work_in_the_following_states__c != existingRec.Employees_work_in_the_following_states__c ){
                          updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, WC_NOTIFICATION_FN);
                      }
               }
    }

    private  void emailNotifyforWCNotification(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(WC_NOTIFICATION_FN);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(WC_NOTIFICATION_FN);
        for(Id ipRecId : ipRecordsByAutomation.get(WC_NOTIFICATION_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(ipRec.RecordTypeId==ipMMRecordTypeId){
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+WC_NOTIFICATION_FN+'_'+NSP_ServiceConstants.MIDDLEMARKET)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(WC_NOTIFICATION_FN).Id,isRerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(WC_NOTIFICATION_FN).Id,isRerun));
                        impRecordId = ipRec.Id;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
                if(ipRec.RecordTypeId==ipFSORecordTypeId){
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+WC_NOTIFICATION_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(WC_NOTIFICATION_FN).Id,isRerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(WC_NOTIFICATION_FN).Id,isRerun));
                        impRecordId = ipRecId;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
    }

    /**
     Automathion Section: Benefits
     Automation Name: EPLI Notification
     Automation icon: envelope
    */

    private void checkforEPLIPolicy(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){
        if( (newIp.RecordTypeId == ipFSORecordTypeId)
            && (newIp.Client_maintaining_existing_EPLI_policy__c==NSP_ServiceConstants.YES
            || newIp.Wnt_cpy_of_Insperity_EPLI_policy_cert__c==NSP_ServiceConstants.YES ) && newIp.Effective_Date_Payroll_Worker_comp_EPLI__c!=null ){
             if(existingRec == null || newIp.NSP_Form_Completed__c || newIp.Client_maintaining_existing_EPLI_policy__c != existingRec.Client_maintaining_existing_EPLI_policy__c
                  ||newIp.Wnt_cpy_of_Insperity_EPLI_policy_cert__c != existingRec.Wnt_cpy_of_Insperity_EPLI_policy_cert__c
                  ||newIp.Effective_Date_Payroll_Worker_comp_EPLI__c != existingRec.Effective_Date_Payroll_Worker_comp_EPLI__c ){
                    updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, EPLI_POLICY_FN);
                }
           }
    }

    private  void emailNotifyforEPLIPolicy(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(EPLI_POLICY_FN);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(EPLI_POLICY_FN);
        for(Id ipRecId : ipRecordsByAutomation.get(EPLI_POLICY_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EPLI_POLICY_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(EPLI_POLICY_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(EPLI_POLICY_FN).Id, isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }
        }
        if(impRecordId!=null && impAutomationName !=null){
              NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
        recToInsert.addAll(ipAutomationRecords);

    }

    /**
     Automation Section: General
     Automation Name: Cobranding Logo
     Automation icon: envelope
    */

    private void checkforLogoCollected(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(  newIp.RecordTypeId == ipFSORecordTypeId  &&
        newIp.NSP_Has_the_client_s_logo_been_collected__c==NSP_ServiceConstants.YES){

             updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, LOGO_COLLECTED_FN);

           }
    }

    private  void emailNotifyforLogoCollected(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(LOGO_COLLECTED_FN);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(LOGO_COLLECTED_FN);
        for(Id ipRecId : ipRecordsByAutomation.get(LOGO_COLLECTED_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+LOGO_COLLECTED_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(LOGO_COLLECTED_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(LOGO_COLLECTED_FN).Id,isRerun));
                impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }

                }
            }
        }
        recToInsert.addAll(ipAutomationRecords);

    if(impRecordId!=null && impAutomationName !=null){
        NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
    }

    /**
     Automation Section: General
     Automation Name: NCS Multi FEIN Notification
     Automation icon: envelope
    */

    private void checkforFEIN(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.All_EEs_paid_under_same_FEIN_currently__c==NSP_ServiceConstants.NO &&
           newIp.List_additional_FEIN_s__c !=Null){

               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, FEIN_NOTIFY_FN);

           }
    }

    private  void emailNotifyforFEIN(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(FEIN_NOTIFY_FN);
        NSP_PEO_Implementations__mdt pfcc1 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ORIENT_COORDINATOR);
        NSP_PEO_Implementations__mdt pfcc2 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ORIENT_REQUEST);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(FEIN_NOTIFY_FN);
        List<String> ccAddressList = new List<String>{pfcc1.NSP_Email_Address__c,pfcc2.NSP_Email_Address__c};
            for(Id ipRecId : ipRecordsByAutomation.get(FEIN_NOTIFY_FN)){

                    Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                    if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                        if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+FEIN_NOTIFY_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                            lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,ccAddressList,mapOfEmailTempaltes.get(FEIN_NOTIFY_FN).Id,isRerun));
                            ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                        }
                        else if(isRerun){
                            lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,ccAddressList,mapOfEmailTempaltes.get(FEIN_NOTIFY_FN).Id,isRerun));
                            impRecordId = ipRec.Id;
                            impAutomationName = ipa.NSP_Automation_Name__c;
                            impMethodName = ipa.NSP_Method_Name__c;
                            impAutomationSection = ipa.NSP_Section__c;
                            if(ipRec.RecordTypeId==ipFSORecordTypeId){
                                impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                            }
                            if(ipRec.RecordTypeId==ipMMRecordTypeId){
                                impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                            }
                        }
                    }

            }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: Payroll
     Automation Name: NCS Classing Notification
     Automation icon: envelope
    */

    private void checkforSubaccount(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.Is_there_a_need_for_a_subaccount__c==NSP_ServiceConstants.YES && newIp.classing_req_a_new_download_for_Subacc__c ==NSP_ServiceConstants.YES
           && newIp.Why_is_subaccount_needed__c!=null){

               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, SUB_ACCOUNT_FN);

           }
    }

    private  void emailNotifyforSubaccount(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(SUB_ACCOUNT_FN);
        NSP_PEO_Implementations__mdt pfcc1 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ORIENT_COORDINATOR);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SUB_ACCOUNT_FN);
        List<String> ccAddressList = new List<String>{pfcc1.NSP_Email_Address__c};
            for(Id ipRecId : ipRecordsByAutomation.get(SUB_ACCOUNT_FN)){
                Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                    Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                    if(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c!=null){
                        ccAddressList.add(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c);
                    }
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+SUB_ACCOUNT_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,ccAddressList,mapOfEmailTempaltes.get(SUB_ACCOUNT_FN).Id,isRerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,ccAddressList,mapOfEmailTempaltes.get(SUB_ACCOUNT_FN).Id,isRerun));

                        impRecordId = ipRec.Id;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        if(ipRec.RecordTypeId==ipFSORecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                        }
                        if(ipRec.RecordTypeId==ipMMRecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                        }
                    }
                }
            }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: General
     Automation Name: Remove employee directory
     Automation icon: envelope
    */

    private void checkforEmployeeDirectory(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if( newIp.RecordTypeId == ipFSORecordTypeId &&
           newIp.remove_employee_directory_from_premier__c==NSP_ServiceConstants.YES){

               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, EMPLOYEE_DIRECTORY_FN);

           }
    }

    private  void emailNotifyforEmployeeDirectory(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(EMPLOYEE_DIRECTORY_FN);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(EMPLOYEE_DIRECTORY_FN);

        for(Id ipRecId : ipRecordsByAutomation.get(EMPLOYEE_DIRECTORY_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EMPLOYEE_DIRECTORY_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(EMPLOYEE_DIRECTORY_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(EMPLOYEE_DIRECTORY_FN).Id,isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }
        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: Payroll
     Automation Name: Service Contract Act
     Automation icon: envelope
    */

    private void checkforServiceContract(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.Client_has_Service_Contract_Act_SCA_EEs__c==NSP_ServiceConstants.YES
           && newIp.Have_the_SCA_EEs_been_approved__c!=NULL && newIp.SCA_EEs_get_wages_in_lieu_of_benefits__c!=null){

               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, SERVICE_CONTRACT_FN);

           }
    }

    private  void emailNotifyforServiceContract(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(SERVICE_CONTRACT_FN);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SERVICE_CONTRACT_FN);
        List<String> listOfToAddress =new List<String>();
        listOfToAddress.add(pf.NSP_Email_Address__c);
        UserWrapper userWrapper = new UserWrapper();

        for(Id ipRecId : ipRecordsByAutomation.get(SERVICE_CONTRACT_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
            if(String.isNotBlank(ipWithValue.NSP_BPA_BPC__c) && String.isNotBlank(ipWithValue.NSP_BPA_BPC_Ids__c)){
                List<String> listOfBPAIds =ipWithValue.NSP_BPA_BPC_Ids__c.split(',');
                userWrapper=getDAEmail(listOfBPAIds);
                listOfToAddress.addAll(userWrapper.bpaEmialList);

            }
            if(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c!=null){

                listOfToAddress.add(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c);
            }
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+SERVICE_CONTRACT_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null,mapOfEmailTempaltes.get(SERVICE_CONTRACT_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null,mapOfEmailTempaltes.get(SERVICE_CONTRACT_FN).Id,isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: Payroll
     Automation Name: Ministers or Teachers
     Automation icon: envelope
    */

    private void checkforEmployeeMinister(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.Does_client_employ_ministers_or_teachers__c==NSP_ServiceConstants.YES
           && newIp.Check_all_tht_apply_ministers_teachers__c!=NULL ){

               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, EMPLOYEE_MINISTER_FN);

           }
    }

    private  void emailNotifyforEmployeeMinister(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(EMPLOYEE_MINISTER_FN);
        List<String> listOfToAddress =new List<String>();
        for(Id ipRecId : ipRecordsByAutomation.get(EMPLOYEE_MINISTER_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
            Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(ipWithValue.NSP_Onboarding_Specialist_Coordinator__c!=null && !String.isBlank(ipWithValue.NSP_Onboarding_Specialist_Coordinator__r.NSP_Work_email__c)){

                    listOfToAddress.add(ipWithValue.NSP_Onboarding_Specialist_Coordinator__r.NSP_Work_email__c);

                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EMPLOYEE_MINISTER_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null,mapOfEmailTempaltes.get(EMPLOYEE_MINISTER_FN).Id,isRerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null,mapOfEmailTempaltes.get(EMPLOYEE_MINISTER_FN).Id,isRerun));
                        impRecordId = ipRec.Id;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        if(ipRec.RecordTypeId==ipFSORecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                        }
                        if(ipRec.RecordTypeId==ipMMRecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                        }
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: Payroll
     Automation Name: Form 8973
     Automation icon: envelope
    */


    /**
     Automation Section: Payroll
     Automation Name: Impl Team Subaccount notification
     Automation icon: envelope
    */

    private void checkforSubaccountNeed(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(newIp.RecordTypeId == ipFSORecordTypeId &&
           newIp.Is_there_a_need_for_a_subaccount__c==NSP_ServiceConstants.YES
           && newIp.Why_is_subaccount_needed__c!=null && newIp.Insperity_pay_frequency__c!=null ){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, SUBACCOUNT_NEED_FN);

           }
    }

    private  void emailNotifyforSubaccountNeed(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SUBACCOUNT_NEED_FN);
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ORIENT_COORDINATOR);
        List<String> listOfToAddress = new List<String>{pf.NSP_Email_Address__c};
            for(Id ipRecId : ipRecordsByAutomation.get(SUBACCOUNT_NEED_FN)){
                Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                    Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                    if(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c!=null){

                        listOfToAddress.add(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c);
                    }
                    if(ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c!=null){
                        listOfToAddress.add(ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c);
                    }

                    if(!isRerun && !listOfToAddress.isEmpty() && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+SUBACCOUNT_NEED_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null, mapOfEmailTempaltes.get(SUBACCOUNT_NEED_FN).Id,isRerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun && !listOfToAddress.isEmpty()){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listOfToAddress,null,null, mapOfEmailTempaltes.get(SUBACCOUNT_NEED_FN).Id,isRerun));
                        impRecordId = ipRec.Id;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        if(ipRec.RecordTypeId==ipFSORecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                        }
                        if(ipRec.RecordTypeId==ipMMRecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                        }
                    }
                }

            }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: General
     Automation Name: XML Upload
     Automation icon: envelope
    */

    private void checkforTimeEntry(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.Time_Entry_Method__c==NSP_ServiceConstants.XML){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, TIME_ENTRY_FN);

           }
    }

    private  void emailNotifyforTimeEntry(){
        List<String> listoftoAddresses =new List<String>() ;
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(TIME_ENTRY_FN);

        for(Id ipRecId : ipRecordsByAutomation.get(TIME_ENTRY_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(String.isNotBlank(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c)){

                    listoftoAddresses.add(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c);
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+TIME_ENTRY_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,null,mapOfEmailTempaltes.get(TIME_ENTRY_FN).Id,isrerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun ){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,null,mapOfEmailTempaltes.get(TIME_ENTRY_FN).Id,isrerun));
                        impRecordId = ipRec.Id;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        if(ipRec.RecordTypeId==ipFSORecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                        }
                        if(ipRec.RecordTypeId==ipMMRecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                        }
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
    }

    /**
     Automation Section: General
     Automation Name: Special Payroll Needs Notification
     Automation icon: envelope
    */

    private void checkforSpecialPayrollNeeds(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.Client_has_any_special_payroll_needs__c==NSP_ServiceConstants.YES
           && newIp.Select_all_payroll_needs_that_apply__c!=null){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, SPECIAL_PAYROLLNEED_FN);

           }
    }

    private  void emailNotifyforSpecialPayrollNeeds(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SPECIAL_PAYROLLNEED_FN);
        List<String> listoftoAddresses =new List<String>() ;

        for(Id ipRecId : ipRecordsByAutomation.get(SPECIAL_PAYROLLNEED_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);

                if(String.isNotBlank(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c)){

                    listoftoAddresses.add(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c);

                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+SPECIAL_PAYROLLNEED_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,null,mapOfEmailTempaltes.get(SPECIAL_PAYROLLNEED_FN).Id,isRerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun ){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,null,mapOfEmailTempaltes.get(SPECIAL_PAYROLLNEED_FN).Id,isRerun));
                        impRecordId = ipRec.Id;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        if(ipRec.RecordTypeId==ipFSORecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                        }
                        if(ipRec.RecordTypeId==ipMMRecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                        }
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: Additional Pay Outs
     Automation Name: Stock Purchase Plan
     Automation icon: envelope
    */

    private void checkforStockPlan(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.Does_the_client_offer_a_Stock_Purchase__c==NSP_ServiceConstants.YES){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, STOCK_PURCHASEPLAN_FN);

           }
    }

    private  void emailNotifyforStockPlan(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(STOCK_PURCHASEPLAN_FN);
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(STOCK_PURCHASE_PLAN_FN);

        for(Id ipRecId : ipRecordsByAutomation.get(STOCK_PURCHASEPLAN_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+STOCK_PURCHASEPLAN_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(STOCK_PURCHASEPLAN_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun ){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(STOCK_PURCHASEPLAN_FN).Id,isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: Additional Pay Outs
     Automation Name: Stock Options
     Automation icon: envelope
    */

    private void checkforStockOption(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if(newIp.RecordTypeId == ipFSORecordTypeId  &&
           newIp.NSP_Does_the_client_offer_Stock_Options__c==NSP_ServiceConstants.YES
           && newIp.First_Pay_Date__c != null && (newIp.Num_of_Worksite_Employees_Full_Time__c != Null ||
                                                  newIp.Num_of_Worksite_Employees_Part_Time__c != Null || newIp.Num_of_Worksite_Employees_Seasonal__c != Null)){
                                                      updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, STOCK_OPTION_FN);

                                                  }
    }

    private  void emailNotifyforStockOption(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(STOCK_OPTION_FN);
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(STOCK_OPTION_FN);

        for(Id ipRecId : ipRecordsByAutomation.get(STOCK_OPTION_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+STOCK_OPTION_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(STOCK_OPTION_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun ){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,null,mapOfEmailTempaltes.get(STOCK_OPTION_FN).Id,isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: Reporting
     Automation Name:  IRR Reporting
     Automation icon: envelope
    */

    private void checkWhenIRRChecked(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){

        if( newIp.RecordTypeId == ipFSORecordTypeId &&
           newIp.NSP_Select_all_that_apply__c != null && newIp.NSP_Select_all_that_apply__c.CONTAINS('IRR')){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, IRR_FN);

           }
    }

    private  void emailNotifyWhenIRRChecked(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(IRR_FN);
        NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(IRR_FN);
        List<String> listOfCCAddress = new List<String>();
        UserWrapper userWrapper = new UserWrapper();

        for(Id ipRecId : ipRecordsByAutomation.get(IRR_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);

                if(String.isNotBlank(ipWithValue.NSP_BPA_BPC__c) && String.isNotBlank(ipWithValue.NSP_BPA_BPC_Ids__c)){
                    List<String> listOfBPAIds =ipWithValue.NSP_BPA_BPC_Ids__c.split(',');
                    userWrapper=getDAEmail(listOfBPAIds);
                    listOfCCAddress.addAll(userWrapper.bpaEmialList);

                }
                if(String.isNotBlank(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c)){
                    listOfCCAddress.add(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c);
                }

                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+IRR_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,listOfCCAddress,mapOfEmailTempaltes.get(IRR_FN).Id,isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun ){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pf.NSP_Email_Address__c},null,listOfCCAddress,mapOfEmailTempaltes.get(IRR_FN).Id,isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section: Client Summary
     Automation Name: Miscellaneous
     Automation icon: envelope
    */

    private void checkforClientSummary(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){
        if( newIp.RecordTypeId == ipFSORecordTypeId  &&  newIp.NSP_CheckToSendTheClient_Summary_email__c ){
            updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, CLIENT_SUMMARY_FN);
        }
    }

    private void emailNotifyforClientSummary(){

        List<String> listoftoAddresses ;
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(CLIENT_SUMMARY_FN);

        for(Id ipRecId : ipRecordsByAutomation.get(CLIENT_SUMMARY_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(String.isNotBlank(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c)){
                    listoftoAddresses = new List<String>();
                    listoftoAddresses.add(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c);


                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+CLIENT_SUMMARY_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,null,mapOfEmailTempaltes.get(CLIENT_SUMMARY_FN).Id, isRerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun ){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,null,mapOfEmailTempaltes.get(CLIENT_SUMMARY_FN).Id,isRerun));
                        impRecordId = ipRec.Id;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        if(ipRec.RecordTypeId==ipFSORecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                        }
                        if(ipRec.RecordTypeId==ipMMRecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                        }

                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }
    }

    /**
     Automation Section:Miscellaneous
     Automation Name: Payroll Specialist Summary
     Automation icon: envelope
    */

    private void checkforPayrollSpecialistSummary(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){
        List<Implementation_Pay_Period__c> ipArrearageList =  additionalArrearageFrequency(newIp.Id);
        if( newIp.RecordTypeId == ipFSORecordTypeId  && newIp.NSP_CheckToSendPayrollSpecialist_Summary__c &&
        ( !ipArrearageList.isEmpty()
           || (newIp.Has_expenses_allowances_through_payroll__c ==NSP_ServiceConstants.YES &&
               newIp.Client_runs_expenses_or_payroll__c != null &&
               (newIp.Client_runs_expenses_or_payroll__c.CONTAINS(NSP_ServiceConstants.ALLOWANCES) || newIp.Client_runs_expenses_or_payroll__c.CONTAINS(NSP_ServiceConstants.EXPENSES)))
           || (newIp.Will_the_owner_s_be_on_payroll__c == NSP_ServiceConstants.YES)
           || (newIp.NSP_Is_there_an_Enrollment_fee__c == NSP_ServiceConstants.YES)
           || (newIp.NSP_Any_special_pay_codes_Needed__c == NSP_ServiceConstants.YES)
           || (newIp.NSP_Select_all_that_apply__c !=null &&  (newIp.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.INTEGRA_ASSET) ||newIp.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.DEPARTMENTS)
                                                              || newIp.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.JOBCOST) || newIp.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.CLIENTMANAGEDATA)
                                                              || newIp.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.LOCATIONS) || newIp.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.REPORT401) || newIp.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.CERTIFIEDREPORT))))){

                                                                  updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, PAYROLL_SPECIALIST_SUMMARY_FN);

                                                              }
    }

    private void emailNotifyforPayrollSpecialistSummary(){
        List<String> listoftoAddresses;
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(PAYROLL_SPECIALIST_SUMMARY_FN);

        for(Id ipRecId : ipRecordsByAutomation.get(PAYROLL_SPECIALIST_SUMMARY_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(String.isNotBlank(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c)){
                    listoftoAddresses = new List<String>();
                    listoftoAddresses.add(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c);

                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+PAYROLL_SPECIALIST_SUMMARY_FN+'_'+NSP_ServiceConstants.FSOProfile)){

                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,null,mapOfEmailTempaltes.get(PAYROLL_SPECIALIST_SUMMARY_FN).Id, isRerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,null,mapOfEmailTempaltes.get(PAYROLL_SPECIALIST_SUMMARY_FN).Id, isRerun));
                        impRecordId = ipRec.Id;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        if(ipRec.RecordTypeId==ipFSORecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                        }
                        if(ipRec.RecordTypeId==ipMMRecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                        }
                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
       }

    }


    public  boolean findSharedValue(List<String> stringList, String pickListValue) {
        if(!String.isBlank(pickListValue)){
            for(String stringVal : pickListValue.split(';')) {
                if(stringList.contains(stringVal)){
                    return true;
                }
            }
        }
        return false;
    }

    private void getIPRecords(){

        for (Set<Id> ipRecords : ipRecordsByAutomation.values()) {
            ipIds.addAll(ipRecords);
        }

        Map<Id,sObject> dbRec = new Map<Id,sObject>([
            SELECT
                Id ,
                NSP_Asset__c ,
                Account__c ,
                Account__r.Name ,
                NSP_AIMS_ClientNo__c ,
                NSP_BPA_BPC__c ,
                NSP_BPA_BPC_Ids__c ,
                NSP_Asset__r.AccountId ,
                NSP_Asset__r.NSP_Client_Segment_type__c ,
                NSP_Form_Completed__c ,
                NSP_Payroll_Specialist__c ,
                NSP_Payroll_Specialist__r.pse__Salesforce_User__c ,
                NSP_Onboarding_Specialist_Coordinator__c ,
                NSP_Orientation_Rep__c ,
                NSP_Orientation_Coordinator__r.pse__Salesforce_User__c ,
                NSP_Transition_Specialist__r.pse__Salesforce_User__c ,
                NSP_Orientation_Rep__r.NSP_Work_Email__c ,
                NSP_Onboarding_Specialist_Coordinator__r.NSP_Work_email__c ,
                NSP_HR_Specialist__c ,
                NSP_HR_Specialist__r.NSP_Work_email__c ,
                NSP_HR_Specialist__r.pse__Salesforce_User__c ,
                NSP_Payroll_Specialist__r.NSP_Work_email__c ,
                NSP_Project_Manager__c ,
                NSP_Project_Manager__r.NSP_Work_email__c ,
                NSP_Project_Manager__r.Name ,
                NSP_Project_Manager__r.pse__Salesforce_User__c ,
                NSP_Project_Manager__r.NSP_Job_Title__c,
                NSP_HR_Quality_Support_Team_Member__c ,
                NSP_HR_Quality_Support_Team_Member__r.NSP_Work_email__c ,
                RecordTypeId ,
                Account__r.NSP_Service_Segment__c,
                NSP_Sr_Onboarding_Benefit_Rep__c,
                NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c,
                NSP_Project_Manager__r.pse__Salesforce_User__r.Email ,
                NSP_OT_Representative__c ,
                NSP_OT_Representative__r.NSP_Work_email__c ,
                Does_this_client_have_an_AWW__c ,
                Is_client_CA_docs_submitted_for_approval__c ,
                Are_you_registered_with_the_CSLB__c ,
                NSP_Legal_Name__c ,
                Contractor_s_License__c ,
                Effective_Date_Payroll_Worker_comp_EPLI__c ,
                NSP_Project__c,
                Who_should_the_FLSA_team_reach_out_to__c ,
                NSP_Related_Clients__c
            FROM Implementation_Profile__c
            WHERE ( Id IN :ipIds )
        ]);
        data.put(IP_IDENTIFIER, dbRec);



    }

    private void getGroupId(){

        for(Group groupRecord: [SELECT Id, Name,Type from Group where Type='Queue']){
            mapofGroupIds.put(groupRecord.Name,groupRecord.Id);
        }
    }

    private void getEmailTemplates(){
        for(EmailTemplate iEmailTemplate : [SELECT Id, BrandTemplateId, Subject, HTMLValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName IN: EMAIL_TEMPLATES]){
            mapOfEmailTempaltes.put(iEmailTemplate.DeveloperName,iEmailTemplate);
        }
    }

     private void getRegulatedAreaStates(){
        for(NSP_Regulated_Area__c state : [SELECT Id, NSP_State__c,  NSP_Regulation_Type__c  FROM NSP_Regulated_Area__c  WHERE NSP_State__c != null  AND NSP_Regulation_Type__c =: NSP_ServiceConstants.STATE_RET_PLAN]){
            listRegulatedStates.add(state.NSP_State__c);
        }
    }

    private UserWrapper  getDAEmail(List<String> listOfBPAIds) {
        UserWrapper userWrapper = new UserWrapper();
        List<String> daEmailList = new List<String>();
        List<String> bpaEmialList = new List<String>();
        for( User daUser : [SELECT Email, NSP_District_Administrator__c,NSP_District_Administrator__r.Email
                            FROM User WHERE Id in: listOfBPAIds ]){
                                if(String.isNotBlank(daUser.NSP_District_Administrator__r.Email)){
                                daEmailList.add(daUser.NSP_District_Administrator__r.Email);
                                }
                                if(String.isNotBlank(daUser.Email)){
                                bpaEmialList.add(daUser.Email);
                                }


        }
        userWrapper.daEmailList=daEmailList;
        userWrapper.bpaEmialList =bpaEmialList;
        return UserWrapper;


    }

    public class UserWrapper{
        @AuraEnabled
        public List<String> daEmailList{get;set;}
       @AuraEnabled
        public List<String>  bpaEmialList{get;set;}


    }

   //STY-02193 IP MM Email Automations
    /**
    Automation Section: Employees
    Automation Name: Remove employee directory
    Automation icon: envelope
    */
    public void checkforRemoveEmployeeDirectory(Implementation_Profile__c newIp, Implementation_Profile__c existingRec){
        if( ipMMRecordTypeId == newIp.recordTypeId && newIp.NSP_Asset__c!=null && newIp.remove_employee_directory_from_premier__c == NSP_ServiceConstants.YES ){
            updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, REMOVE_EMPLOYEE_DIR_FN);
        }
    }

    public  void emailNotifyforRemoveEmployeeDirectory(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.REMOVE_EMP_DIR);
        for(Id ipRecId : ipRecordsByAutomation.get(REMOVE_EMPLOYEE_DIR_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            //IPId, AutoName, mthodName, sec, recodtype
            //profile,method,recordtype
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+REMOVE_EMPLOYEE_DIR_FN+'_'+NSP_ServiceConstants.MIDDLEMARKET)){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.REMOVE_EMP_DIR),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                    ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.REMOVE_EMPLOYEE_DIR, REMOVE_EMPLOYEE_DIR_FN, NSP_ServiceConstants.EMPLOYEE_SEC, NSP_ServiceConstants.MIDDLEMARKET));
                }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.REMOVE_EMP_DIR),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                    impRecordId = ipRecId;
                    impAutomationName = NSP_ServiceConstants.REMOVE_EMPLOYEE_DIR;
                    impMethodName = REMOVE_EMPLOYEE_DIR_FN;
                    impAutomationRecordType = NSP_ServiceConstants.MIDDLEMARKET ;
                }
            }
        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,NSP_ServiceConstants.EMPLOYEE_SEC);
       }
    }

    /**
    Automation Section: Payroll
    Automation Name: Stock Purchase Plan
    Automation Icon: envelope
    */
    public void checkforStockPurchasePlan(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp){
        if( ipMMRecordTypeId == newIp.recordTypeId && newIp.NSP_Asset__c!=null && newIp.Does_the_client_offer_a_Stock_Purchase__c == NSP_ServiceConstants.YES ){
            updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, STOCK_PURCHASE_PLAN_FN);
        }
    }

    public  void emailNotifyforStockPurchasePlan(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.PURCHASE_PLAN);

        for(Id ipRecId : ipRecordsByAutomation.get(STOCK_PURCHASE_PLAN_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+STOCK_PURCHASE_PLAN_FN+'_'+NSP_ServiceConstants.MIDDLEMARKET)){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.PURCHASE_PLAN),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                    ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_STOCK_PURCHASE, STOCK_PURCHASE_PLAN_FN, NSP_ServiceConstants.PAYROLLSEC, NSP_ServiceConstants.MIDDLEMARKET));
                }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.PURCHASE_PLAN),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                    impRecordId = ipRecId;
                    impAutomationName = NSP_ServiceConstants.AUTOMATION_STOCK_PURCHASE;
                    impMethodName = STOCK_PURCHASE_PLAN_FN;
                    impAutomationRecordType = NSP_ServiceConstants.MIDDLEMARKET ;
                }
            }
        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,NSP_ServiceConstants.PAYROLLSEC);
       }
    }

    /**
    Automation Section: Benefits
    Automation Name: EPLI Notification
    Automation icon: envelope
    */
    public void checkEPLINotification(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp){
        if( ipMMRecordTypeId == newIp.recordTypeId && newIp.NSP_Asset__c!=null &&  newIp.Effective_Date_Payroll_Worker_comp_EPLI__c!=null &&
        (newIp.Wnt_cpy_of_Insperity_EPLI_policy_cert__c == NSP_ServiceConstants.YES || newIp.Client_maintaining_existing_EPLI_policy__c == NSP_ServiceConstants.YES)){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, EPLI_NOTIFY_FN);
           }
    }

    public  void emailNotifyforEPLINotification(){
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.EPLI_NOTIFICATION);
        for(Id ipRecId : ipRecordsByAutomation.get(EPLI_NOTIFY_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EPLI_NOTIFY_FN+'_'+NSP_ServiceConstants.MIDDLEMARKET)){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.EPLI_NOTIFICATION),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                    ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_EPLI_NOTIFY, EPLI_NOTIFY_FN, NSP_ServiceConstants.BENEFITS, NSP_ServiceConstants.MIDDLEMARKET));
                }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.EPLI_NOTIFICATION),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                    impRecordId = ipRecId;
                    impAutomationName = NSP_ServiceConstants.AUTOMATION_EPLI_NOTIFY;
                    impMethodName = EPLI_NOTIFY_FN;
                    impAutomationRecordType = NSP_ServiceConstants.MIDDLEMARKET ;
                }
            }
        }
        if(impRecordId!=null && impAutomationName !=null){
           NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,NSP_ServiceConstants.BENEFITS);
        }
        recToInsert.addAll(ipAutomationRecords);

    }

    /**
    Automation Section: Retirement Services
    Automation Name: Existing Retirement Plan/Keep
    Automation icon: envelope
    */
    public void checkforExistingRetirementPlanKeep(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp){
        if( ((ipMMRecordTypeId == newIp.recordTypeId && newIp.NSP_Asset__c!=null )|| ipFSORecordTypeId == newIp.recordTypeId)
           && newIp.Client_has_existing_retirement_plan__c == NSP_ServiceConstants.YES
           && (newIp.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.CSP401K
               || newIp.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.SIMPLEIRA
               || newIp.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.CLIENTB
               || newIp.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.UNIDENTIFIED_ORK )){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, EXISTING_RET_PLAN_KEEP_FN);
               }
    }

    public  void emailNotifyforExistingRetirementPlanKeep(){
        NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ER_PLAN_KEEP);
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<String> listOfCCAddress = new List<String>();
        for(Id ipRecId : ipRecordsByAutomation.get(EXISTING_RET_PLAN_KEEP_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                // added by Masthan
                listOfCCAddress = this.buildCCAddresses( ipRecId );
                if(ipRec.RecordTypeId==ipMMRecordTypeId){
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EXISTING_RET_PLAN_KEEP_FN+'_'+NSP_ServiceConstants.MIDDLEMARKET)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.ER_PLAN_KEEP).Id, isRerun));
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_EXIST_RET_PLAN_KEEP, EXISTING_RET_PLAN_KEEP_FN, NSP_ServiceConstants.RT, NSP_ServiceConstants.MIDDLEMARKET));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.ER_PLAN_KEEP).Id, isRerun));
                        impRecordId = ipRecId;
                        impAutomationName = NSP_ServiceConstants.AUTOMATION_EXIST_RET_PLAN_KEEP;
                        impMethodName = EXISTING_RET_PLAN_KEEP_FN;
                        impAutomationRecordType = NSP_ServiceConstants.MIDDLEMARKET ;
                    }
                }
                if(ipRec.RecordTypeId==ipFSORecordTypeId){
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EXISTING_RET_PLAN_KEEP_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.ER_PLAN_KEEP).Id, isRerun));
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_EXIST_RET_PLAN_KEEP, EXISTING_RET_PLAN_KEEP_FN, NSP_ServiceConstants.RT, NSP_ServiceConstants.FSOProfile));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.ER_PLAN_KEEP).Id, isRerun));
                        impRecordId = ipRecId;
                        impAutomationName = NSP_ServiceConstants.AUTOMATION_EXIST_RET_PLAN_KEEP;
                        impMethodName = EXISTING_RET_PLAN_KEEP_FN;
                        impAutomationRecordType = NSP_ServiceConstants.FSOProfile ;
                    }
                }
            }
        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,NSP_ServiceConstants.RT);
       }
    }

    /**
    Automation Section: Retirement Services
    Automation Name: Existing Retirement Plan/Move to NSP 401(k)
    Automation icon: envelope
    */
    public void checkforExistingRetirementMovetoNSP401(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp){
        if( ((ipMMRecordTypeId == newIp.recordTypeId && newIp.NSP_Asset__c!=null) || ipFSORecordTypeId == newIp.recordTypeId)
           && newIp.Client_has_existing_retirement_plan__c == NSP_ServiceConstants.YES
           && (newIp.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.PEOMULTIPLIER
               || newIp.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.CSP401KNSP)){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, EXISTING_RET_PLAN_MOVE_FN);
               }
    }

    public  void emailNotifyforExistingRetirementPlanMove(){
        NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ER_PLAN_MOVE);

        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<String> listOfCCAddress = new List<String>();
        for(Id ipRecId : ipRecordsByAutomation.get(EXISTING_RET_PLAN_MOVE_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                // added by Masthan
                listOfCCAddress = this.buildCCAddresses( ipRecId );
                if(ipRec.RecordTypeId==ipMMRecordTypeId){
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EXISTING_RET_PLAN_MOVE_FN+'_'+NSP_ServiceConstants.MIDDLEMARKET)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.ER_PLAN_MOVE).Id, isRerun));
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_EXIST_RET_PLAN_MOVE, EXISTING_RET_PLAN_MOVE_FN, NSP_ServiceConstants.RT, NSP_ServiceConstants.MIDDLEMARKET));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.ER_PLAN_MOVE).Id, isRerun));
                        impRecordId = ipRecId;
                        impAutomationName = NSP_ServiceConstants.AUTOMATION_EXIST_RET_PLAN_MOVE;
                        impMethodName = EXISTING_RET_PLAN_MOVE_FN;
                        impAutomationRecordType = NSP_ServiceConstants.MIDDLEMARKET ;
                    }
                }
                if(ipRec.RecordTypeId==ipFSORecordTypeId){
                   if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EXISTING_RET_PLAN_MOVE_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_Existing_Retirement_Plan_Move_FSO).Id ,isRerun));
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_EXIST_RET_PLAN_MOVE, EXISTING_RET_PLAN_MOVE_FN, NSP_ServiceConstants.RT, NSP_ServiceConstants.FSOProfile));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_Existing_Retirement_Plan_Move_FSO).Id ,isRerun));
                        impRecordId = ipRecId;
                        impAutomationName = NSP_ServiceConstants.AUTOMATION_EXIST_RET_PLAN_MOVE;
                        impMethodName = EXISTING_RET_PLAN_MOVE_FN;
                        impAutomationRecordType = NSP_ServiceConstants.FSOProfile ;
                    }
                }
            }
        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,NSP_ServiceConstants.RT);
       }
    }

    /**
    Automation Section: Retirement Services
    Automation Name: EEO Information
    Automation icon: envelope
    */
    public void checkforEEOInformation(Implementation_Profile__c newIp,  Implementation_Profile__c existingRecp){
        //If user selects all of this questions as NO, the email will still be delivered
            if(((ipMMRecordTypeId == newIp.recordTypeId && newIp.NSP_Asset__c!=null)
               || ipFSORecordTypeId == newIp.recordTypeId)
                    && newIp.Is_the_client_a_federal_contractor__c != null
                    //If user selects YES (Does the client have an EEO # they have been filing under?) below questions appear and cannot be null
                    && newIp.Client_have_EEO_filing_under__c != null
                        && ((String.IsNotBlank(newIp.Client_have_EEO_filing_under__c)
                        //If user select YES(Can client provide EEO filing address?), fields EEO__C and Filin_address__c appear and need to have a value
                            && newIp.Can_client_provide_EEO_filing_address__c == NSP_ServiceConstants.YES
                                && newIp.EEO__c != null
                                && newIp.Filing_address__c != null)
                        || (String.IsNotBlank(newIp.Client_have_EEO_filing_under__c)
                        //If user selects NO (Can client provide EEO filing address?), a text box appears and it needs to be populated with the EEO Name, phone, and contact email
                            && newIp.Can_client_provide_EEO_filing_address__c == NSP_ServiceConstants.NO
                                && newIp.EEO_name_phone_contact_email_for_info__c != null))
                    //If user selects NO (Does the client have an EEO # they have been filing under?) none related questions appear
                    || newIp.Client_have_EEO_filing_under__c == NSP_ServiceConstants.NO
                    && newIp.NSP_co_employ_100_of_client_workforce__c!=null
                    && newIp.Client_part_of_entity_w_o_NSP__c!=null){
               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, EEO_INFO_FN);
           }
        }


    public  void emailNotifyforEEOInfo(){
        NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.EEO_INFORMATION);

        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        for(Id ipRecId : ipRecordsByAutomation.get(EEO_INFO_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm && ipRec.RecordTypeId==ipMMRecordTypeId ){

                    if( !isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EEO_INFO_FN+'_'+NSP_ServiceConstants.MIDDLEMARKET)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.EEO_INFORMATION),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.EEO_INFO, EEO_INFO_FN, NSP_ServiceConstants.CLIENTINFO, NSP_ServiceConstants.MIDDLEMARKET));
                    }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.EEO_INFORMATION),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                    impRecordId = ipRecId;
                    impAutomationName = NSP_ServiceConstants.EEO_INFO;
                    impMethodName = EEO_INFO_FN;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                        }
                        if(ipRec.RecordTypeId==ipMMRecordTypeId){
                            impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                        }
                }
            }
        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,NSP_ServiceConstants.CLIENTINFO);
       }
    }

    public  void emailNotifyforEEOInfoFSO(){
        NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.EEO_INFORMATION);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(EEO_INFO_FN);

        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        for(Id ipRecId : ipRecordsByAutomation.get(EEO_INFO_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm && ipFSORecordTypeId == ipRec.recordTypeId ){
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+EEO_INFO_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.EEO_INFORMATION),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                }
                else if(isRerun){
                    lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.sendMail(mapOfEmailTempaltes.get(NSP_ServiceConstants.EEO_INFORMATION),ipRec, new List<String>{pI.NSP_Email_Address__c},isRerun));
                    impRecordId = ipRec.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    if(ipRec.RecordTypeId==ipFSORecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                    }
                    if(ipRec.RecordTypeId==ipMMRecordTypeId){
                        impAutomationRecordType=NSP_ServiceConstants.MIDDLEMARKET;
                    }
                }
            }
        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection);
       }
    }

    /**
    Automation Section: Retirement Services
    Automation Name: SRP Notification
    Automation icon: envelope
    */
    public void checkSRPNotification(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp){
        if(((ipMMRecordTypeId == newIp.recordTypeId && newIp.NSP_Asset__c!=null) || ipFSORecordTypeId== newIp.recordTypeId)
           && newIp.Client_has_existing_retirement_plan__c == NSP_ServiceConstants.NO
           && newIp.Client_want_to_begin_401k_w_NSP_setup__c == NSP_ServiceConstants.NO ){
            getRegulatedAreaStates();
            if(findSharedValue(listRegulatedStates,newIp.Employees_work_in_the_following_states__c)){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, SRP_NOTIFY_FN);
               }
           }
    }

    public void emailNotifyforSRPNotification(){
        NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.SRP_NOTIFY);
        NSP_PEO_Implementations__mdt pI1 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.SRP_NOTIFY_401);
        NSP_PEO_Implementations__mdt pI2 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.SRP_RET_SALES);

        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<String> listOfCCAddress = new List<String>();
        for(Id ipRecId : ipRecordsByAutomation.get(SRP_NOTIFY_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                // added by Masthan
                listOfCCAddress = this.buildCCAddresses( ipRecId );
                if(ipMMRecordTypeId == ipRec.recordTypeId){
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+SRP_NOTIFY_FN+'_'+NSP_ServiceConstants.MIDDLEMARKET)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.SRP_NOTIFY).Id, isRerun));
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI1.NSP_Email_Address__c,pI2.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.SRP_NOTIFY).Id, isRerun));
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_SRP_NOTIFY, SRP_NOTIFY_FN, NSP_ServiceConstants.RT, NSP_ServiceConstants.MIDDLEMARKET));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.SRP_NOTIFY).Id, isRerun));
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI1.NSP_Email_Address__c,pI2.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.SRP_NOTIFY).Id, isRerun));
                        impRecordId = ipRecId;
                        impAutomationName = NSP_ServiceConstants.AUTOMATION_SRP_NOTIFY;
                        impMethodName = SRP_NOTIFY_FN;
                        impAutomationRecordType = NSP_ServiceConstants.MIDDLEMARKET ;


                    }
                }
                if(ipFSORecordTypeId == ipRec.recordTypeId){
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+SRP_NOTIFY_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.SRP_NOTIFY).Id, isRerun));
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI1.NSP_Email_Address__c,pI2.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.SRP_NOTIFY).Id, isRerun));
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_SRP_NOTIFY, SRP_NOTIFY_FN, NSP_ServiceConstants.RT, NSP_ServiceConstants.FSOProfile));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.SRP_NOTIFY).Id, isRerun));
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI1.NSP_Email_Address__c,pI2.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.SRP_NOTIFY).Id, isRerun));
                        impRecordId = ipRecId;
                        impAutomationName = NSP_ServiceConstants.AUTOMATION_SRP_NOTIFY;
                        impMethodName = SRP_NOTIFY_FN;
                        impAutomationRecordType = NSP_ServiceConstants.FSOProfile ;
                    }
                }
            }
        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
             NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,NSP_ServiceConstants.RT);
        }
    }

    /**
    Automation Section: Retirement Services
    Automation Name: New 401(k)
    Automation icon: envelope
    */
    public void checkforNew401k(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp){
        if(((ipMMRecordTypeId == newIp.recordTypeId && newIp.NSP_Asset__c!=null) || ipFSORecordTypeId == newIp.recordTypeId)
           && newIp.Client_has_existing_retirement_plan__c == NSP_ServiceConstants.NO
           && newIp.Client_want_to_begin_401k_w_NSP_setup__c == NSP_ServiceConstants.YES){
                               updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, NEW_401_FN);
           }
    }

    public void emailNotifyforNew401k(){
        NSP_PEO_Implementations__mdt pI = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ER_PLAN_MOVE);
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        List<String> listOfCCAddress = new List<String>();
       for(Id ipRecId : ipRecordsByAutomation.get(NEW_401_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){
                // added by Masthan
                listOfCCAddress = this.buildCCAddresses( ipRecId );
                if(ipMMRecordTypeId == ipRec.recordTypeId){
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+NEW_401_FN+'_'+NSP_ServiceConstants.MIDDLEMARKET)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.NEW_401).Id ,isRerun));
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_NEW_401, NEW_401_FN, NSP_ServiceConstants.RT, NSP_ServiceConstants.MIDDLEMARKET));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_ServiceConstants.NEW_401).Id ,isRerun));
                        impRecordId = ipRecId;
                        impAutomationName = NSP_ServiceConstants.AUTOMATION_NEW_401;
                        impMethodName = NEW_401_FN;
                        impAutomationRecordType = NSP_ServiceConstants.MIDDLEMARKET ;
                    }
                }
                if(ipFSORecordTypeId == ipRec.recordTypeId){
                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+NEW_401_FN+'_'+NSP_ServiceConstants.FSOProfile)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_New_401_k_FSO).Id ,isRerun));
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.AUTOMATION_NEW_401, NEW_401_FN, NSP_ServiceConstants.RT, NSP_ServiceConstants.FSOProfile));
                    }
                    else if(isRerun){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,new List<String>{pI.NSP_Email_Address__c},null,listOfCCAddress, mapOfEmailTempaltes.get(NSP_New_401_k_FSO).Id ,isRerun));
                        impRecordId = ipRecId;
                        impAutomationName = NSP_ServiceConstants.AUTOMATION_NEW_401;
                        impMethodName = NEW_401_FN;
                        impAutomationRecordType = NSP_ServiceConstants.FSOProfile ;
                    }

                }
            }
        }
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,NSP_ServiceConstants.RT);
         }
        recToInsert.addAll(ipAutomationRecords);
    }

    // Automation Section: General
    // Automation Name: Additional BPSes
    // Automation icon: Email
    private void checkforBpses( Implementation_Profile__c newIp , Implementation_Profile__c existingRec ) {
        if ( ( newIp != null )
            && ( newIp.Select_BPSes__c != null )
            && ( newIp.RecordTypeId != null )
            && ( newIp.RecordTypeId == NSP_Implementationprofile_ServiceHelper.ipFSORecordTypeId )
            )
        {
            String[] selectedValues = newIp.Select_BPSes__c.split(';');
            Set<String> selectedSet = new Set<String>(selectedValues);
            Set<String> excludeValues = new Set <String>{NSP_ServiceConstants.INTEGRA, NSP_ServiceConstants.PremierPerformance};
            selectedSet.removeAll(excludeValues);
            if ( selectedSet.size() > 0 ) {
                if ( existingRec == null
                    || newIp.NSP_Form_Completed__c
                    || newIp.Implementing_biz_Performance_solutions__c != existingRec.Implementing_biz_Performance_solutions__c
                    )
                {
                    updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, AdditionalBPSes_FSO);
                }
            }
        }
    }

    private  void emailNotifyforcheckforBpses(){
        List<String> listoftoAddresses =new List<String>() ;
        List<String> listofccAddresses =new List<String>() ;
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(AdditionalBPSes_FSO);

        for(Id ipRecId : ipRecordsByAutomation.get(AdditionalBPSes_FSO)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            UserWrapper userWrapper = new UserWrapper();

            if(isRerun || ipRec.NSP_Form_Completed__c ){
                Implementation_Profile__c ipWithValue=(Implementation_Profile__c) data.get(IP_IDENTIFIER).get(ipRecId);
                if(String.isNotBlank(ipWithValue.NSP_BPA_BPC__c) && String.isNotBlank(ipWithValue.NSP_BPA_BPC_Ids__c)){
                    List<String> listOfBPAIds =ipWithValue.NSP_BPA_BPC_Ids__c.split(',');
                    userWrapper=getDAEmail(listOfBPAIds);
                    listoftoAddresses.addAll(userWrapper.bpaEmialList);
                    listoftoAddresses.addAll(userWrapper.daEmailList);
                    if(ipWithValue.NSP_Project_Manager__c != null && ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c !=null){
                      listofccAddresses.add(ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c) ;
                    }

                    if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipRec.Id+'_'+AdditionalBPSes_FSO+'_'+NSP_ServiceConstants.FSOProfile)){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,listofccAddresses,mapOfEmailTempaltes.get(AdditionalBPSes_FSO).Id,isrerun));
                        ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                    else if(isRerun ){
                        lstEmailMessages.add(NSP_IP_MM_EmailAutomationsController.getMailObject(ipRec,listoftoAddresses,null,listofccAddresses,mapOfEmailTempaltes.get(AdditionalBPSes_FSO).Id,isrerun));
                        impRecordId = ipRec.Id;
                        impAutomationName = ipa.NSP_Automation_Name__c;
                        impMethodName = ipa.NSP_Method_Name__c;
                        impAutomationSection = ipa.NSP_Section__c;
                        impAutomationRecordType=NSP_ServiceConstants.FSOProfile;

                    }
                }
            }

        }
        recToInsert.addAll(ipAutomationRecords);
        if(impRecordId!=null && impAutomationName !=null){
            NSP_Implprofile_ServiceHelperUpdate.automationRecordUpdate(impRecordId,impAutomationName,impMethodName,impAutomationRecordType,impAutomationSection );
        }
    }
    private static List<Implementation_Pay_Period__c> additionalIpPayPeriods(Id ipId){
        return [ SELECT Id, Frequency__c, Final_pay_period_prior_to_Insperity__c,
                                 Final_pay_date_prior_to_Insperity__c,Does_the_client_have_prior_wages__c
                                 FROM Implementation_Pay_Period__c
                                 WHERE NSP_Implementation_Profile__c =: ipId AND
                                    ( Does_the_client_have_prior_wages__c = :NSP_ServiceConstants.NO OR
                                  (Does_the_client_have_prior_wages__c = :NSP_ServiceConstants.YES
                                   AND Final_pay_period_prior_to_Insperity__c!=NULL
                                   AND Final_pay_date_prior_to_Insperity__c!=NULL))];
    }

    private static List<Implementation_Pay_Period__c> additionalArrearageFrequency (Id ipId){
        return [ SELECT Id, Frequency__c, Is_arrearage_7_days__c,
                                 Have_credit_services_approved__c
                                    FROM Implementation_Pay_Period__c
                                 WHERE NSP_Implementation_Profile__c =: ipId AND
                                 Is_arrearage_7_days__c = :NSP_ServiceConstants.YES AND
                                 Have_credit_services_approved__c = :NSP_ServiceConstants.NO ];
    }

    private void checkforClientAWW(Implementation_Profile__c newRec, Implementation_Profile__c existingRec, String fnName) {
        if ( existingRec == null
            || newRec.NSP_Form_Completed__c
            || newRec.Does_this_client_have_an_AWW__c != existingRec.Does_this_client_have_an_AWW__c
           )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, fnName);
        }
    }

    private void emailNotifyforclientAWW(Implementation_Profile__c ipWithValue, String fnName, String subject, String body, String mdtName) {
        if(ipWithValue != null && String.isNotBlank(fnName) && String.isNotBlank(subject) && String.isNotBlank(body) && String.isNotBlank(mdtName)) {
            List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
            List<String> emailAddress = new List<String>();
            if(ipWithValue.NSP_Payroll_Specialist__c != null && ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c != null &&
                ipWithValue.NSP_Project_Manager__c != null && ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c != null) {
                emailAddress.add(ipWithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c);
                emailAddress.add(ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c);
            }
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(mdtName);
            if((isRerun || ipWithValue.NSP_Form_Completed__c) && !isSaveForm && ipa != null) {
                if(!isRerun && !ipAutomationdata?.get(IP_AUTOMATION_IDENTIFIER).contains(ipWithValue.Id+'_'+fnName+'_'+NSP_ServiceConstants.FSOProfile)){
                    sendMailUsingFlowAction(emailAddress,subject,body);
                    ipAutomationRecords.add(ipAutomationHelper.createIPAutomation(ipWithValue, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                } else if(isRerun){
                    sendMailUsingFlowAction(emailAddress,subject,body);
                    impRecordId = ipWithValue.Id;
                    impAutomationName = ipa.NSP_Automation_Name__c;
                    impMethodName = ipa.NSP_Method_Name__c;
                    impAutomationSection = ipa.NSP_Section__c;
                    impAutomationRecordType=NSP_ServiceConstants.FSOProfile;
                }
            }
            recToInsert.addAll(ipAutomationRecords);
        }
    }

    private void sendMailUsingFlowAction( List<String> emailAddress , String subject , String body ) {
        Map<String,Object> inputs = new Map<String,Object>();
        inputs.put('toEmailAddresses', emailAddress);
        inputs.put('emailSubject', subject);
        inputs.put('emailBody', body);
        inputs.put('useLineBreaks', true);
        try {
            Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email(inputs);
            sendEmailFlow.start();
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_Implementationprofile_ServiceHelper.class.getName() ,
                'sendMailUsingFlowAction' ,
                e
            );
        }
    }

    //Retrieves Related Clients of the Implementation Profile
    private String relatedClients(Implementation_Profile__c ipwithValue, Boolean isEmail) {
        List<String> clientIds = new List<String>();
        clientIds = splitRelatedClient(ipwithValue);
        Map<Id, Account> clientsMap = new Map<Id, Account>();

        if(!clientIds.isEmpty()) {
            clientsMap = new Map<Id, Account>([SELECT Id, Name,NSP_AIMS_Client__c FROM Account WHERE Id IN: clientIds]);
        }

        String bulletList = '';
        for(String id: clientIds) {
            Account client = null;
            if(clientsMap.containsKey(Id) && clientsMap.get(Id) != null){
                client = clientsMap.get(Id);
            }
            if( client != null && isEmail ) {
                //Email formatting
                bulletList += '<li>'+ client.Name + '</li>';
            } else if (client != null && !isEmail){
                //Long Text Area field formatting
                bulletList += '• '+ client.Name + '\n';
            }
        }
        return  bulletList;
    }
    //Splits the Related Clients of the Implementation Profile
    private List<String> splitRelatedClient(Implementation_Profile__c ipwithValue){
        String relatedClients = '';
        List<String> clientIds = new List<String>();
        if(ipwithValue != null) {
            relatedClients = ipwithValue.NSP_Related_Clients__c;
        }
        if(String.isNotBlank(relatedClients)) {
            for(String ids: relatedClients.split(',')) {
                if(String.isNotBlank(ids)) {
                    clientIds.add(ids.trim());
                }
            }
        }
        return clientIds;
    }

    private String flsaReviewContacts(Implementation_Profile__c ipwithValue) {
        String contacts = '';
        if( ipwithValue != null ) {
            contacts = ipwithValue.Who_should_the_FLSA_team_reach_out_to__c;
        }

        String contactsFormatted = '';
        if(String.isNotBlank(contacts)) {
            if(contacts.contains(','))
            {
                //Handles either 'A,B,C,D' or 'A\nB\nC\nD'
                contactsFormatted = contacts.replaceAll(',', '\n');
            } else {
                contactsFormatted = contacts;
            }
        }
        return contactsFormatted;
    }


    private List<String> buildCCAddresses( String recordId ){
        List<String> listOfCCAddress = new List<String>();
        if ( String.isNotBlank( recordId )
            && data.ContainsKey( IP_IDENTIFIER )
            && data.get( IP_IDENTIFIER ) != null
           )
        {
            Map<Id, sObject> iPMap = data.get(IP_IDENTIFIER);
            if ( ipMap != null
                && ipMap.containsKey( recordId )
                && ipMap.get(recordId) != null
               )
            {
                Implementation_Profile__c ipWithValue = (Implementation_Profile__c) iPMap.get( recordId );
                if ( ipWithValue.NSP_Project_Manager__r != null
                    && ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c != null
                   )
                {
                   listOfCCAddress.add( ipWithValue.NSP_Project_Manager__r.NSP_Work_email__c );
                }
            }
        }
        return listOfCCAddress;
    }

}
//