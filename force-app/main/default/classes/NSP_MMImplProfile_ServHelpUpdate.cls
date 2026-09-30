public class NSP_MMImplProfile_ServHelpUpdate {
    // test w/ NSP_MMImplProfile_UpdateTest (94%)

    private  Boolean isRerun =false;
    private Map<Id,Implementation_Profile__c> newIPs = null;
    private Map<Id,Implementation_Profile__c> oldIPs = null;
    private List<pse__Project_Task__c> projectTaskToInsertList = new List<pse__Project_Task__c>();
    private List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
    private Map<String,Set<Id>> ipRecordsByAutomation = new Map<String,Set<Id>>();
    private List<sObject> recToInsert = new List<sObject>();
    private List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
    private Map<String,Map<Id,sObject>> data = new Map<String,Map<Id,sObject>>();
    private Map<String,List<String>> ipAutomationdata = new Map<String,List<String>>();
    private Boolean isSaveForm = false;
    private List<String> automationsToExecute = new List<String>();
    private Set<Id> ipIds=new Set<Id>();
    private Map<String,Id> mapofGroupIds=new Map<String,Id>();
    private Map<String,EmailTemplate> mapOfEmailTempaltes = new Map<String,EmailTemplate>();
    Map<Id,String[]> mapofEmpNames = new Map<Id,String[]>();
    private List<String> existingIpAutomations=new List<String>();
    private List<String> listRegulatedStates = new List<String>();
    private Map<String, pse__Milestone__c> mileStonesToInsert = new Map<String, pse__Milestone__c>();

    private static String childProjectTask = null;
    private static final String PROJECT_IDENTIFIER = 'pse__Proj__c';
    private static final String PROJECT_TASK_IDENTIFIER = 'pse__Project_Task__c';
    private static final String IMPL_PROFILE_IDENTIFIER = 'Implementation_Profile__c';
    private static final String IP_AUTOMATION_IDENTIFIER = 'NSP_Implementation_Profile_Automation__c';

    private static final String PAYROLL_REGISTER_MM='NSP_Payroll_Register';
    private static final String FEIN_DOCUMENT_COLLECTED_MM = 'NSP_FEIN_documentation';
    private static final String GENERAL_LIABILITY_MM = 'NSP_Received_Certificate';
    private static final String EEO_FILING_MM = 'NSP_Union_EEs';
    private static final String SEASONAL_EE_MM = 'NSP_Seasonal_EEs';
    private static final String EEO_ON_LEAVE_MM = 'NSP_Leave_of_Absence';
    private static final String TIMESTAR_MM = 'NSP_TimeStar';
    private static final String TIMESTAR_TA_MM = 'NSP_TimeStar_T_A';
    private static final String TIMESTAR_TA_ADMIN_MM = 'NSP_TimeStar_T_A_Administrator';
    private static final String TIMESTAR_TA_SUP_MM = 'NSP_TimeStar_T_A_Supervisor';
    private static final String TIMESTAR_TA_SYSTEM_MM = 'NSP_TimeStar_TA_System_Live';
    private static final String TIMESTAR_TA_PAYROLL_EXPERT_MM = 'NSP_TimeStar_TA_Payroll_Expert';
    private static final String GARNISHMENT_MM = 'NSP_EE_garnishments';
    private static final String RETIRE_PLAN_MM='NSP_Retirement_Plan';
    private static final String HSA_MM='NSP_HSA';
    private static final String HSA_OPTUM_MM='HSA_Optum';
    private static final String HSA_OPTUM_NO_MM='NSP_HSA_No_Optum';
    private static final String COBRA_MM='NSP_COBRA';
    private static final String DEDUCIBLE_CARRYOVER_MM = 'NSP_Deductible_Carryover';
    private static final String EE_MEDICAL_MM = 'NSP_EE_Medical';
    private static final String WAITING_MM = 'NSP_EE_Waiting';
    private static final String POST_DEDUCTION_MM='NSP_Post_tax';
    private static final String RETIRE_PLANORK_MM='NSP_Retirement_Plan_ORK_401K';
    private static final String RETIRE_PLAN_401K_EMP_MM='NSP_Retirement_Plan_401k_Employee';
    private static final String RETIRE_PLAN_401K_DEF_UP_MM='NSP_Retirement_Plan_401k_uploaded';
    private static final String RETIRE_PLAN_401K_LOAN_MM='NSP_Retirement_Plan_401k_Emp_Upload';
    private static final String RETIRE_PLAN_401K_YTD_UP_MM='NSP_Retirement_Plan_401k_YTD_uploaded';
    private static final String NSP401K_MM = 'NSP_X401k_Meeting';
    private static final String NSP401K_PLAN_MM = 'NSP_X401k_Plan_Setup';
    private static final String NSP401K_EMP_TRAIN_MM = 'NSP_X401K_Employee_training';
    private static final String STANDARD_MM = 'NSP_Standard_Offer_Letter';
    private static final String BACKGROUND_MM = 'NSP_Background_Check';
    private static final String DRUG_SCREENING_MM = 'NSP_Drug_Screening';
    private static final String SCREENING_BPS_MM = 'NSP_Select_BPSes_Employment';
    private static final String PERFORMANCE_BPS_MM = 'NSP_Select_BPSes_Performance';
    private static final String ORGANIZATIONAL_BPS_MM = 'NSP_Select_BPSes_Organizational';
    private static final String INSURANCE_BPS_MM = 'NSP_Select_BPSes_Insurance';
    private static final String RECRUITING_BPS_MM = 'NSP_Select_BPSes_Recruiting';
    private static final String CERTIFY_BPS_MM= 'NSP_Select_BPSes_Certify';
    private static final String SPECIFIC_LEAVE_MM= 'NSP_Specific_Leave';
    private static final String PRE_TAX_MM= 'NSP_Pre_Tax';
    private static final String PRE_TAX_DEDUCT_MM= 'NSP_Pre_Tax_Deduction';
    private static final String POST_TAX_SPONSPOREDPLAN_MM= 'NSP_Post_Tax_SponsporedPlan';
    private static final String POST_TAX_EMPSETUP_MM= 'NSP_Post_Tax_EmpSetup';
    private static final String ALLOWNCE_EXPENSE_MM= 'NSP_Allowance_Expenses';
    private static final String DEPENDENT_CARE_MM= 'NSP_Dependent_Care';
    private static final String HEALTH_CARE_MM= 'NSP_Health_Care';
    private static final String SEVERANCEAGREEMENT_MM= 'NSP_SeverenceAgreement';
    private static final String JOBDESCRIPTION_MM= 'NSP_JobDescriptiom';
    private static final String HANDBOOK_DEVELOPMENT_MM= 'NSP_HandbookDevelopment';
    private static final String COBRA_GUIDELINES_MM= 'NSP_COBRAGuidelines';
    private static final String COBRA_TEAM_MM= 'NSP_COBRATeam';
    private static final String COBRA_PACKETS_MM= 'NSP_COBRAPackets';
    private static final String CSP_HSA_MM ='CSP_HSA';
    private static final String CSP_MEDICAL_MM ='CSP_Medical';
    private static final String CSP_DENTAL_MM ='CSP_Dental';
    private static final String CSP_VISION_MM ='CSP_Vision';
    private static final String DATA_VERIFICATION_MM ='DataVerificationMM';
    private static Id ipFSORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Implementation_Profile__c' , NSP_ServiceConstants.FSOProfile );
    private static Id ipMMRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Implementation_Profile__c' , NSP_ServiceConstants.MMProfile );
    private static Id milestonePEORecordtypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Milestone__c' , NSP_ServiceConstants.PEOMILSTONE );
    private static Id projectTaskPEORecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c' , NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE );

    public NSP_MMImplProfile_ServHelpUpdate( Map<Id,Implementation_Profile__c> newIPs , Map<Id,Implementation_Profile__c> oldIPs ) {
        this.newIPs = newIPs;
        this.oldIPs = oldIPs;
        this.automationsToExecute.addAll(
            new List<String>{
                PAYROLL_REGISTER_MM ,
                FEIN_DOCUMENT_COLLECTED_MM ,
                GENERAL_LIABILITY_MM ,
                EEO_FILING_MM ,
                SEASONAL_EE_MM ,
                EEO_ON_LEAVE_MM ,
                SPECIFIC_LEAVE_MM ,
                TIMESTAR_MM ,
                GARNISHMENT_MM ,
                PRE_TAX_MM ,
                PRE_TAX_DEDUCT_MM ,
                POST_TAX_SPONSPOREDPLAN_MM ,
                POST_TAX_EMPSETUP_MM ,
                ALLOWNCE_EXPENSE_MM ,
                RETIRE_PLAN_MM ,
                HSA_MM ,
                HSA_OPTUM_MM ,
                HSA_OPTUM_NO_MM ,
                COBRA_MM ,
                DEDUCIBLE_CARRYOVER_MM ,
                EE_MEDICAL_MM ,
                WAITING_MM ,
                DEPENDENT_CARE_MM ,
                HEALTH_CARE_MM ,
                POST_DEDUCTION_MM ,
                RETIRE_PLANORK_MM ,
                NSP401K_MM ,
                HANDBOOK_DEVELOPMENT_MM ,
                JOBDESCRIPTION_MM ,
                SEVERANCEAGREEMENT_MM ,
                STANDARD_MM ,
                BACKGROUND_MM ,
                DRUG_SCREENING_MM ,
                SCREENING_BPS_MM ,
                PERFORMANCE_BPS_MM ,
                ORGANIZATIONAL_BPS_MM ,
                INSURANCE_BPS_MM ,
                RECRUITING_BPS_MM ,
                CERTIFY_BPS_MM ,
                CSP_HSA_MM ,
                CSP_MEDICAL_MM ,
                CSP_DENTAL_MM ,
                CSP_VISION_MM ,
                DATA_VERIFICATION_MM
            }
        );
    }

    public NSP_MMImplProfile_ServHelpUpdate( Id ipRecord , String automationName ) {
        this.newIPs = NSP_ImpAutomationsController.getIpRecord( ipRecord );
        this.isRerun = true;
        this.automationsToExecute.add( automationName );
    }

    public NSP_MMImplProfile_ServHelpUpdate( Boolean isSave ) {
        this.isSaveForm = isSave;
    }

    public Map<String,Set<Id>> executeAutomation() {
        Map<String,Set<Id>> ipRecordsByAutomationMap = new Map<String,Set<Id>>();
        if ( NSP_Implprofile_ServiceHelperUpdate.isAutomationAllowed() ) {
            try {
                this.start();
                this.execute();
                ipRecordsByAutomationMap = this.ipRecordsByAutomation;
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_MMImplProfile_ServHelpUpdate.class.getName() ,
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
        if ( !ipRecordsByAutomation.isEmpty() ) {
            // Fetch Project Records from DB
            getProjectDBRecords();
            //get all project manager for IP
            getIPRecords();
            //get all implementation automation record
            getImplAutomationRecords();
            getGroupId();
        }
    }

    private void getGroupId(){
        for ( Group groupRecord : [
                    SELECT Id , Name , Type
                    FROM Group
                    WHERE ( Type = :NSP_ServiceConstants.GroupType )
                ]
            )
        {
            mapofGroupIds.put( groupRecord.Name , groupRecord.Id );
        }
    }

    private void populateEligibleRecords() {
        for ( Implementation_Profile__c ipRec : newIPs.values() ) {
            Implementation_Profile__c existingRec = oldIPs != null ? oldIPs.get(ipRec.Id) : null;
            ipIds.add(ipRec.Id);
            // All the automation methods will check the eligibility of the current record.
            checkforPayrollRegister(ipRec, existingRec);
            checkforFEINDocument(ipRec, existingRec);
            checkforReceivedCertificate(ipRec, existingRec);
            checkforSeasonalEE(ipRec, existingRec);
            checkforUnionEE(ipRec, existingRec);
            checkforEEOnLeave(ipRec, existingRec);
            checkForStateSpecificLeave(ipRec, existingRec);
            checkforPostTaxDeductions(ipRec, existingRec);
            checkforTimeStar(ipRec, existingRec);
            checkForDataVerificationMM(ipRec, existingRec);
            checkforGarnishments(ipRec, existingRec);
            checkForPreTax(ipRec, existingRec);
            checkForCspHsa(ipRec, existingRec);
            checkForPostTax(ipRec, existingRec);
            checkForExpenseAllowance(ipRec, existingRec);
            checkforRetPlan(ipRec, existingRec);
            checkforHSA(ipRec, existingRec);
            checkforHSAOptum(ipRec, existingRec);
            checkforNoHSAOptum(ipRec, existingRec);
            checkforCOBRA(ipRec, existingRec);
            checkforDeducibleCarryover(ipRec, existingRec);
            checkforEEMedical(ipRec, existingRec);
            checkforWaitingPeriod(ipRec, existingRec);
            checkForDependentCare(ipRec, existingRec);
            checkForHealthCare(ipRec, existingRec);
            checkForMedical(ipRec, existingRec);
            checkForDental(ipRec, existingRec);
            checkForVision(ipRec, existingRec);
            checkforRetPlan(ipRec, existingRec);
            checkfor401KPlan(ipRec, existingRec);
            checkForHandbookDevelopment(ipRec, existingRec);
            checkForJobDescription(ipRec, existingRec);
            checkForSeveranceAgreement(ipRec, existingRec);
            checkforStandardOffer(ipRec, existingRec);
            checkforBackground(ipRec, existingRec);
            checkforDrugScreening(ipRec, existingRec);
            checkforScreeningBPS(ipRec, existingRec);
            checkforPerformanceBPS(ipRec, existingRec);
            checkforOrganizationalBPS(ipRec, existingRec);
            checkforInsuranceBPS(ipRec, existingRec);
            checkforRecruitingBPS(ipRec, existingRec);
            checkForCertifyBPS(ipRec, existingRec);
        }
    }

    private void execute() {
        Id workCalendarId = [SELECT Id FROM pse__Work_Calendar__c LIMIT 1].Id;
        for(String automation: ipRecordsByAutomation.keySet()) {
            createProjectTasks(automation, workCalendarId);
        }

        if(!projectTaskToInsertList.isEmpty()){
            //check for existing Project Tasks to avoid duplications
            recToInsert.addAll(getNewTasksToInsert(projectTaskToInsertList));
        }
        if(!projectTaskToInsertList.isEmpty()){
            //check for existing Automation record and store the new Automation records
            recToInsert.addAll(getNewAutomationListToInsert(ipAutomationRecords));
        }
        finish();
        getProjectDBRecords();
    }

    private void finish() {
        List<Database.UpsertResult> upsertResults = Database.upsert( mileStonesToInsert.values() , false );
        NSP_ErrorLogHandler.logResults(
            NSP_MMImplProfile_ServHelpUpdate.class.getName() ,
            'finish:upsert' ,
            upsertResults
        );
        recToInsert.sort();
        for ( SObject rec : recToInsert ) {
            if ( rec.getSObjectType() == Schema.pse__Project_Task__c.getSObjectType() ) {
                pse__Project_Task__c projectTask = (pse__Project_Task__c)rec;
                if ( projectTask.pse__Milestone__c == null ) {
                    pse__Milestone__c milestoneRec = mileStonesToInsert.get( projectTask.pse__WBS_Element_Number__c );
                    projectTask.pse__Milestone__c = milestoneRec.Id;
                    projectTask.pse__WBS_Element_Number__c = null;
                }
            }
        }
        List<Database.SaveResult> insertProjectTaskResults = Database.insert( recToInsert , false );
        NSP_ErrorLogHandler.logResults(
            NSP_MMImplProfile_ServHelpUpdate.class.getName() ,
            'finish:insert' ,
            insertProjectTaskResults
        );
    }

    private void getIPRecords() {
        for (Set<Id> ipRecords : ipRecordsByAutomation.values()) {
            for (Id ipRec : ipRecords) {
                ipIds.add(ipRec);
            }
        }
        Map<Id,sObject> dbRec = new Map<Id,sObject>(
            [
                SELECT
                    Id ,
                    NSP_Payroll_Specialist__c ,
                    NSP_Payroll_Specialist__r.pse__Salesforce_User__c ,
                    NSP_Sr_Onboarding_Benefit_Rep__c ,
                    NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c ,
                    NSP_Sr_Benefit_Rep__c ,
                    NSP_Sr_Benefit_Rep__r.pse__Salesforce_User__c ,
                    NSP_Payroll_Project_Manager__c ,
                    NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c ,
                    NSP_HR_Specialist__c ,
                    NSP_HR_Specialist__r.pse__Salesforce_User__c ,
                    Select_the_applicable_LOA_types__c ,
                    NSP_Project_Manager__c ,
                    NSP_Project_Manager__r.pse__Salesforce_User__c ,
                    Account__r.Id, Account__c ,
                    Account__r.Name ,
                    NSP_Insperity_1st_pay_date__c
                FROM Implementation_Profile__c
                WHERE ( Id IN :ipIds )
            ]
        );
        data.put(IMPL_PROFILE_IDENTIFIER, dbRec);
    }

    private void getImplAutomationRecords() {
        Map<Id,sObject> dbRec = new Map<Id,sObject>(
            [
                SELECT
                    Id ,
                    Name ,
                    NSP_Implementation_Profile__c ,
                    NSP_Record_Type__c ,
                    NSP_Method_Name__c
                FROM NSP_Implementation_Profile_Automation__c
                WHERE ( NSP_Implementation_Profile__c = :ipIDs )
            ]
        );
        data.put(IP_AUTOMATION_IDENTIFIER, dbRec);
    }

    private void getProjectDBRecords(){
        Set<Id> projectIDs = new Set<Id>();
        for (Set<Id> ipRecords : ipRecordsByAutomation.values()) {
            for (Id ipRec : ipRecords) {
                projectIDs.add(newIPs.get(ipRec).NSP_Project__c);
                ipIDs.add(ipRec);
            }
        }
        Map<Id,sObject> dbRec = new Map<Id,sObject>(
            [
                SELECT
                    Id ,
                    pse__End_Date__c ,
                    (
                        SELECT
                            Id ,
                            Name
                        FROM pse__Milestones__r
                    ) ,
                    (
                        SELECT
                            Id ,
                            pse__Project__c ,
                            NSP_Sub_Category__c ,
                            NSP_Category__c ,
                            pse__Milestone__c ,
                            Name ,
                            NSP_Implementation_Profile_Account__c ,
                            NSP_Implementation_Account_Id__c
                        FROM pse__Project_Tasks__r
                    )
                FROM pse__Proj__c
                WHERE ( Id IN :projectIDs )
            ]
        );

        data.put(PROJECT_IDENTIFIER, dbRec);
    }

    private void updateEligibleRecordsMap(Map<String, Set<Id>> automationMap, Id recId, String fnName){
        Set<Id> relevantRecords = automationMap.get(fnName);
        if(relevantRecords == null){
            relevantRecords = new Set<Id>();
        }
        relevantRecords.add(recId);
        automationMap.put(fnName, relevantRecords);
    }

    private pse__Project_Task__c createProjectTaskfromIP( pse__Proj__c project , String category , Id ipRecId , String milestoneKey ) {
        Id projectTaskPEORecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
        pse__Project_Task__c eachProjectTask = new pse__Project_Task__c();
        if(project != null && String.isNotBlank(category) && ipRecId != null && String.isNotBlank(milestoneKey)){
            eachProjectTask.RecordTypeId=projectTaskPEORecordTypeId;
            eachProjectTask.NSP_Category__c=category;
            eachProjectTask.NSP_Visible_to_Client__c=TRUE;
            eachProjectTask.pse__Status__c=NSP_ServiceConstants.PROJECT_TASK_NOT_STARTED;
            eachProjectTask.pse__Start_Date_Time__c=System.now();
            if(project.Id!=null){
                if(eachProjectTask.pse__Milestone__c == null){
                    eachProjectTask.pse__WBS_Element_Number__c = milestoneKey;
                }
                eachProjectTask.pse__Project__c=project.Id;
                eachProjectTask.pse__End_Date_Time__c= DateTime.newInstance(project.pse__End_Date__c, Time.newInstance(12, 0, 0, 0));
            }
            Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
            if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
            }
            if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
            }
        }
        return eachProjectTask;
    }

    //Creates Project Task automations for MM IP
    private void createProjectTasks( String automation , Id workCalendarId ) {
        NSP_ProjectTask_Automation__mdt pta = null;
        if(automation != null){
            pta = NSP_ProjectTask_Automation__mdt.getInstance(automation);
        }
        if(ipRecordsByAutomation.containsKey(automation) && ipRecordsByAutomation.get(automation) != null) {
            for(Id ipRecId : ipRecordsByAutomation.get(automation)){
                if(newIPs != null) {
                    Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                    if(ipRec != null && (isRerun || ipRec.NSP_Form_Completed__c)){
                        pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                        createMilestoneForProjectTask(proj,pta);
                        projectTasks(automation, proj,pta, ipRecId,workCalendarId);
                    }
                }
            }
        }
    }

    //Creates the Milestones for each of the Project Tasks
    private String createMilestoneForProjectTask( pse__Proj__c proj , NSP_ProjectTask_Automation__mdt pta ) {
        String milestoneKey;
        if(proj != null && pta != null){
            Id milestoneId = getMilestoneId( proj.pse__Milestones__r , pta.NSP_Milestone__c );
            milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;
            if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                pse__Milestone__c eachMilestone = new pse__Milestone__c(
                    Name=pta.NSP_Milestone__c,
                    RecordTypeId=NSP_MMImplProfile_ServHelpUpdate.milestonePEORecordtypeId,
                    pse__Project__c=proj.Id,
                    pse__Target_Date__c=proj.pse__End_Date__c
                );
                mileStonesToInsert.put(milestoneKey, eachMilestone);
            }
        }
        return milestoneKey;
    }

    //All Project Task Automations
    private void projectTasks(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Id workCalendarId
        )
    {
        if ( ( data != null )
            && data.containsKey( IMPL_PROFILE_IDENTIFIER )
            && ( data.get( IMPL_PROFILE_IDENTIFIER ) != null )
            && data.get( IMPL_PROFILE_IDENTIFIER ).containsKey( ipRecId )
            && ( data.get( IMPL_PROFILE_IDENTIFIER ).get( ipRecId ) != null )
            )
        {
            Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
            createProjectTaskForReceivedCertificate(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForSpecificLeave(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForFEIN(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForUnionEE(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForSeasonalEE(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForEELeave(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForDataVerification(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForExpenseAllowance(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForGarnishment(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForTimeStar(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforPayrollRegister(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForPostTaxEmp(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForPostTaxClient(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForEEWaiting(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForDeducibleCarryover(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForEEMedical(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForHSA(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForHSAOptum(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForNoHSA(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForPreTax(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForPreTaxDeduct(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForDependentCare(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForHealthCare(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForPreTaxHealth(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForDental(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForMedical(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForVision(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForPostDeductions(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForCOBRA(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForRetirementPlan(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForRetirementPlans(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskFor401k(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForHRHandbook(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForHRJobDescription(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForHRSeverance(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForStandardOffer(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForBackgroundCheck(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForDrugScreening(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForEmploymentScreening(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForPerformanceManagement(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForOrganizationalPlanning(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForInsuranceServices(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForRecruitingServices(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForCertify(automation,proj,pta,ipRecId,ipwithValue,workCalendarId);
        }
    }

    //Common fields for Project Tasks coming from the NSP_ProjectTask_Automation metadata
    private void genericProjectTask(
        pse__Proj__c proj ,
        pse__Project_Task__c eachProjecttask ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id workCalendarId
        )
    {
        eachProjecttask = NSP_Implprofile_ServiceHelperUpdate.genericProjectTaskHelper(
            eachProjecttask ,
            pta ,
            this.getMilestoneId( proj.pse__Milestones__r , pta.NSP_Milestone__c ) ,
            workCalendarId
        );
    }

    //Create Project Tasks for Time and Attendance automation
    //Create Project Tasks for ORK 401(k) set up automation
    private void subTask(
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId ,
        String ownerId
        )
    {
        String milestoneKey = createMilestoneForProjectTask(proj, pta);
        pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
        genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
        if ( !String.isBlank( ownerId ) ) {
            eachProjecttask.OwnerId = ownerId;
        }
        if(eachProjecttask != null){
            projectTaskToInsertList.add(eachProjecttask);
        }
    }

    // PM Task
    private pse__Project_Task__c genericPMTask(
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        String milestoneKey = createMilestoneForProjectTask(proj, pta);
        pse__Project_Task__c eachProjecttask = null;
        if ( pta != null ) {
            eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
        }
        genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
        if ( ipwithValue != null
            && ipwithValue.NSP_Project_Manager__c!=null
            && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null
            )
        {
            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
        }
        return eachProjectTask;
    }

    private pse__Project_Task__c payrollProjectManagerOwner(
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        String milestoneKey = createMilestoneForProjectTask(proj, pta);
        pse__Project_Task__c eachProjecttask = null;
        if ( pta != null ) {
            eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
        }
        genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
        if ( ipwithValue != null
            && ipwithValue.NSP_Payroll_Project_Manager__c!=null
            && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null
            )
        {
            eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
        }
        return eachProjectTask;
    }

    private pse__Project_Task__c hrSpecialistOwner(
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        String milestoneKey = createMilestoneForProjectTask(proj, pta);
        pse__Project_Task__c eachProjecttask = null;
        if ( pta != null ) {
            eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
        }
        genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
        if ( ipwithValue != null
            && ipwithValue.NSP_HR_Specialist__c!=null
            && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null
            )
        {
            eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
        }
        return eachProjectTask;
    }

    //General Liability & Auto - automation
    private void createProjectTaskForReceivedCertificate(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == GENERAL_LIABILITY_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //State Specific Sick Leave - automation
    private void createProjectTaskForSpecificLeave(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==SPECIFIC_LEAVE_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Client Information - Section
    //FEIN Documentation - automation
    private void createProjectTaskForFEIN(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==FEIN_DOCUMENT_COLLECTED_MM){
            pse__Project_Task__c eachProjecttask = payrollProjectManagerOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if ( ( ipwithValue != null )
                && ( ipwithValue.NSP_Project_Manager__c != null )
                && ( ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c != null )
                )
            {
                eachProjecttask.OwnerId = ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Employees - Section
    //Union EEs - automation
    private void createProjectTaskForUnionEE(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==EEO_FILING_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Seasonal EEs – AIMS setup - automation
    private void createProjectTaskForSeasonalEE(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==SEASONAL_EE_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //EEs on LOA - automation
    private void createProjectTaskForEELeave(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==EEO_ON_LEAVE_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Payroll - Section
    //AWW/EE Data Verification - automation
    private void createProjectTaskForDataVerification(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==DATA_VERIFICATION_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            DateTime now = DateTime.now();
            Integer hour = now.hour();
            Integer minute = now.minute();
            Integer second = now.second();
            if(ipwithValue.NSP_Insperity_1st_pay_date__c != null){
                eachProjecttask.pse__Start_Date_Time__c = DateTime.now();
                DateTime endDate = DateTime.newInstance(
                    ipwithValue.NSP_Insperity_1st_pay_date__c.year() ,
                    ipwithValue.NSP_Insperity_1st_pay_date__c.month() ,
                    ipwithValue.NSP_Insperity_1st_pay_date__c.day() ,
                    hour ,
                    minute ,
                    second
                );
                eachProjecttask.pse__End_Date_Time__c = endDate.addDays(-7);
            }
            if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
            }
            ipAutomationRecords.add(createIPAutomation(ipRec,ipa.NSP_Automation_Name__c,ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Expenses/Allowances - automation
    private void createProjectTaskForExpenseAllowance(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==ALLOWNCE_EXPENSE_MM){
            pse__Project_Task__c eachProjecttask = payrollProjectManagerOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Garnishments - automation
    private void createProjectTaskForGarnishment(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==GARNISHMENT_MM){
            pse__Project_Task__c eachProjecttask = payrollProjectManagerOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Time and Attendance - automation
    private void createProjectTaskForTimeStar(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==TIMESTAR_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            String userId = '';
            if ( ( ipwithValue != null )
                && ( ipwithValue.NSP_Project_Manager__c != null )
                && ( ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c != null )
                )
            {
                userId = ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                eachProjecttask.OwnerId = userId;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            //Create Project Tasks for Time and Attendance automation
            NSP_ProjectTask_Automation__mdt pta1 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_MM);
            NSP_ProjectTask_Automation__mdt pta3 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_ADMIN_MM);
            NSP_ProjectTask_Automation__mdt pta4 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_SUP_MM);
            NSP_ProjectTask_Automation__mdt pta7 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_SYSTEM_MM);
            NSP_ProjectTask_Automation__mdt pta8 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_PAYROLL_EXPERT_MM);
            subTask(proj,pta3,ipRecId,ipwithValue,workCalendarId,userId);
            subTask(proj,pta4,ipRecId,ipwithValue,workCalendarId,userId);
            subTask(proj,pta7,ipRecId,ipwithValue,workCalendarId,userId);
            userId = '';
            if ( ( ipwithValue != null )
                && ( ipwithValue.NSP_Payroll_Project_Manager__c != null )
                && ( ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c != null )
                )
            {
                userId = ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
            }
            subTask(proj,pta1,ipRecId,ipwithValue,workCalendarId,userId);
            subTask(proj,pta8,ipRecId,ipwithValue,workCalendarId,userId);
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Payroll Register - automation
    private void createProjecttaskforPayrollRegister(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==PAYROLL_REGISTER_MM){
            pse__Project_Task__c eachProjecttask = payrollProjectManagerOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Post-tax EE Deductions - automation
    private void createProjectTaskForPostTaxEmp(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==POST_TAX_EMPSETUP_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Post-Tax Client Setup - automation
    private void createProjectTaskForPostTaxClient(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==POST_TAX_SPONSPOREDPLAN_MM){
            pse__Project_Task__c eachProjecttask = payrollProjectManagerOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Benefits - Section
    //Wait Period - automation
    private void createProjectTaskForEEWaiting(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==WAITING_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Deductible Carryover - automation
    private void createProjectTaskForDeducibleCarryover(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == DEDUCIBLE_CARRYOVER_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Urgent Medical Needs - automation
    private void createProjectTaskForEEMedical(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == EE_MEDICAL_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            if(String.isNotBlank(System.label.Care_Transition)){
                eachProjecttask.pse__Long_Description__c = System.label.Care_Transition;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Client offers HSA - automation
    private void createProjectTaskForHSA(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == HSA_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            eachProjecttask.Implementation_Profile__c = ipRecId;
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Optum Bank - automation
    private void createProjectTaskForHSAOptum(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==HSA_OPTUM_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                if(pt.Name==NSP_ServiceConstants.HSA){
                    eachProjecttask.pse__Parent_Task__c=pt.Id;
                    eachProjecttask.pse__Hierarchy_Depth__c=1;
                    if(String.isNotBlank(System.label.HSA_With_Optum_Bank)){
                        eachProjecttask.pse__Long_Description__c = System.label.HSA_With_Optum_Bank;
                    }
                    if(ipWithValue != null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                        eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                    }
                    ipAutomationRecords.add(
                            createIPAutomation(
                                ipRec,
                                ipa.NSP_Automation_Name__c,
                                ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                            )
                        );
                    projectTaskToInsertList.add(eachProjecttask);
                }
            }
        }
    }

    //HSA not Optum - automation
    private void createProjectTaskForNoHSA(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==HSA_OPTUM_NO_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                if(pt.Name==NSP_ServiceConstants.HSA){
                    eachProjecttask.pse__Parent_Task__c=pt.Id;
                    eachProjecttask.pse__Hierarchy_Depth__c=2;
                    if(String.isNotBlank(System.label.HSA_With_No_Optum_Bank)){
                        eachProjecttask.pse__Long_Description__c = System.label.HSA_With_No_Optum_Bank;
                    }
                    if(ipWithValue != null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                        eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                    }
                    ipAutomationRecords.add(
                            createIPAutomation(
                                ipRec,
                                ipa.NSP_Automation_Name__c,
                                ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                            )
                        );
                    projectTaskToInsertList.add(eachProjecttask);
                }
            }
        }
    }

    //CSP Client Setup - automation
    private void createProjectTaskForPreTax(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==PRE_TAX_MM){
            pse__Project_Task__c eachProjecttask = payrollProjectManagerOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //CSP EE Deductions - automation
    private void createProjectTaskForPreTaxDeduct(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==PRE_TAX_DEDUCT_MM){
            pse__Project_Task__c eachProjecttask = payrollProjectManagerOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //CSP - Dependent Care FSA - automation
    private void createProjectTaskForDependentCare(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==DEPENDENT_CARE_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            if(String.isNotBlank(System.label.Dependent_Care_FSA)){
                eachProjecttask.pse__Long_Description__c = System.label.Dependent_Care_FSA;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //CSP - Health Care FSA - automation
    private void createProjectTaskForHealthCare(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==HEALTH_CARE_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            if(String.isNotBlank(System.label.Health_Care_FSA)){
                eachProjecttask.pse__Long_Description__c = System.label.Health_Care_FSA;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //CSP - HSA - automation
    private void createProjectTaskForPreTaxHealth(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==CSP_HSA_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            if(String.isNotBlank(System.label.CSP_HSA)){
                eachProjecttask.pse__Long_Description__c = System.label.CSP_HSA;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //CSP - Dental - automation
    private void createProjectTaskForDental(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==CSP_DENTAL_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            if(String.isNotBlank(System.label.CSP_Dental)){
                eachProjecttask.pse__Long_Description__c = System.label.CSP_Dental;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //CSP - Medical - automation
    private void createProjectTaskForMedical(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==CSP_MEDICAL_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            if(String.isNotBlank(System.label.CSP_Medical)){
                eachProjecttask.pse__Long_Description__c = System.label.CSP_Medical;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //CSP - Vision - automation
    private void createProjectTaskForVision(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==CSP_VISION_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            if(String.isNotBlank(System.label.CSP_Vision)){
                eachProjecttask.pse__Long_Description__c = System.label.CSP_Vision;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Post-tax enrollments - automation
    private void createProjectTaskForPostDeductions(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==POST_DEDUCTION_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            if(String.isNotBlank(System.label.Post_Tax_IIS)){
                eachProjecttask.pse__Long_Description__c = System.label.Post_Tax_IIS;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //EEs on COBRA - automation
    private void createProjectTaskForCOBRA(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==COBRA_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
            }
            if(String.isNotBlank(System.label.COBRA_Parent)){
                eachProjecttask.pse__Long_Description__c = System.label.COBRA_Parent;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Employee Deductions – non NSP... - automation
    private void createProjectTaskForRetirementPlan(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==RETIRE_PLAN_MM){
            String milestoneKey = createMilestoneForProjectTask(proj, pta);
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
            if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //ORK 401(k) set up - automation
    private void createProjectTaskForRetirementPlans(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==RETIRE_PLANORK_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            String userId = '';
            if ( ipwithValue != null
                && ipwithValue.NSP_Project_Manager__c!=null
                && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null
                )
            {
                userId = ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                eachProjectTask.OwnerId = userId;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            //Create Project Tasks for ORK 401(k) set up automation
            NSP_ProjectTask_Automation__mdt pta5 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_401K_DEF_UP_MM);
            NSP_ProjectTask_Automation__mdt pta6 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_401K_LOAN_MM);
            NSP_ProjectTask_Automation__mdt pta8 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_401K_YTD_UP_MM);
            subTask(proj,pta8,ipRecId,ipwithValue,workCalendarId,userId);
            userId = '';
            if ( ( ipwithValue != null )
                && ( ipwithValue.NSP_Payroll_Project_Manager__c != null )
                && ( ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c != null )
                )
            {
                userId = ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
            }
            subTaskFor401k(proj,pta6,ipRecId,ipwithValue,workCalendarId,userId);
            subTaskFor401k(proj,pta5,ipRecId,ipwithValue,workCalendarId,userId);
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //401K Deferrals - file provided - Project Task
    //401K Employee Loans (including term dates) - file provided - Project Task
    //401K Employee Loans (including term dates) - file uploaded - Project Task
    //401K Deferrals - file uploaded - Project Task
    private void subTaskFor401k(
        pse__Proj__c proj,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId ,
        String ownerId
        )
    {
        String milestoneKey = createMilestoneForProjectTask(proj, pta);
        pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c, ipRecId,milestoneKey);
        genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
        if ( !String.isBlank( ownerId ) ) {
             eachProjecttask.OwnerId = ownerId;
        }
        if(eachProjecttask != null){
            projectTaskToInsertList.add(eachProjecttask);
        }
    }

    //NSP 401(k) set up - automation
    private void createProjectTaskFor401k(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==NSP401K_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            String userId = '';
            if ( ( ipwithValue != null )
                && ( ipwithValue.NSP_Project_Manager__c != null )
                && ( ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c != null )
                )
            {
                userId = ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                eachProjectTask.OwnerId = userId;
            }
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            //Create Project Tasks for ORK 401(k) set up automation
            NSP_ProjectTask_Automation__mdt pta4 =  NSP_ProjectTask_Automation__mdt.getInstance(NSP401K_PLAN_MM);
            NSP_ProjectTask_Automation__mdt pta6 =  NSP_ProjectTask_Automation__mdt.getInstance(NSP401K_EMP_TRAIN_MM);
            subTask(proj,pta4,ipRecId,ipwithValue,workCalendarId,userId);
            subTask(proj,pta6,ipRecId,ipwithValue,workCalendarId,userId);
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Section: Human Resources
    //Handbook needed - automation
    private void createProjectTaskForHRHandbook(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==HANDBOOK_DEVELOPMENT_MM){
            pse__Project_Task__c eachProjecttask = hrSpecialistOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Job Descriptions needed - automation
    private void createProjectTaskForHRJobDescription(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==JOBDESCRIPTION_MM){
            pse__Project_Task__c eachProjecttask = hrSpecialistOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Severance agreements needed - automation
    private void createProjectTaskForHRSeverance(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==SEVERANCEAGREEMENT_MM){
            pse__Project_Task__c eachProjecttask = hrSpecialistOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Offer letter needed - automation
    private void createProjectTaskForStandardOffer(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==STANDARD_MM){
            pse__Project_Task__c eachProjecttask = hrSpecialistOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Background Checks - automation
    private void createProjectTaskForBackgroundCheck(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==BACKGROUND_MM){
            pse__Project_Task__c eachProjecttask = hrSpecialistOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Drug screening - automation
    private void createProjectTaskForDrugScreening(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==DRUG_SCREENING_MM){
            pse__Project_Task__c eachProjecttask = hrSpecialistOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Section: Business Performance Solutions
    //Employment Screening - automation
    private void createProjectTaskForEmploymentScreening(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==SCREENING_BPS_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Performance Management - automation
    private void createProjectTaskForPerformanceManagement(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==PERFORMANCE_BPS_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Organizational Planning - automation
    private void createProjectTaskForOrganizationalPlanning(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==ORGANIZATIONAL_BPS_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Insurance Services - automation
    private void createProjectTaskForInsuranceServices(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==INSURANCE_BPS_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Recruiting Services - automation
    private void createProjectTaskForRecruitingServices(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==RECRUITING_BPS_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    //Certify - automation
    private void createProjectTaskForCertify(
        String automation ,
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation ==CERTIFY_BPS_MM){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            ipAutomationRecords.add(
                createIPAutomation(
                    ipRec,
                    ipa.NSP_Automation_Name__c,
                    ipa.NSP_Method_Name__c,ipa.NSP_Section__c
                )
            );
            if(eachProjecttask != null){
                projectTaskToInsertList.add(eachProjecttask);
            }
        }
    }

    private List<pse__Project_Task__c> getNewTasksToInsert(List<pse__Project_Task__c> projTaskList){
        List<pse__Project_Task__c> newProjectList=new List<pse__Project_Task__c>();
        List<String> existingProjecttasks=new List<String>();
        Map<Id,sObject> dbRec=data.get(PROJECT_IDENTIFIER);
        if( ( dbRec != null ) && !dbRec.isEmpty() ) {
            for (Id projId : dbRec.keySet() ) {
                if ( dbRec.get( projId ) != null ) {
                    pse__Proj__c project=(pse__Proj__c)dbRec.get(projId);
                    for ( pse__Project_Task__c projTask : project.pse__Project_Tasks__r ) {
                        existingProjecttasks.add(projTask.NSP_Implementation_Account_Id__c+'_'+projTask.Name+'_'+projTask.NSP_Category__c+'_'+projTask.NSP_Sub_Category__c);
                    }
                }
            }
        }
        for ( pse__Project_Task__c pt : projTaskList ) {
            if ( existingProjecttasks.isEmpty()
                || !existingProjecttasks.contains(pt.NSP_Implementation_Account_Id__c+'_'+pt.Name+'_'+pt.NSP_Category__c+'_'+pt.NSP_Sub_Category__c)
                )
            {
                newProjectList.add(pt);
            }
        }
        return newProjectList;
    }

    private List<NSP_Implementation_Profile_Automation__c> getNewAutomationListToInsert(List<NSP_Implementation_Profile_Automation__c> ipAutomationList){
        Map<Id, sObject> dbRec = data.get(IP_AUTOMATION_IDENTIFIER);
        List<String> existingIpAutomations=new List<String>();
        if ( ( dbRec != null ) && !dbRec.isEmpty() ) {
            for ( Id ipaId : dbRec.keySet() ) {
                if ( dbRec.get( ipaId ) != null ) {
                    NSP_Implementation_Profile_Automation__c ipa=(NSP_Implementation_Profile_Automation__c)dbRec.get(ipaId);
                    existingIpAutomations.add(ipa.NSP_Implementation_Profile__c+'_'+ipa.Name+'_'+ipa.NSP_Record_Type__c);
                }
            }
        }
        List<NSP_Implementation_Profile_Automation__c> newipAutomationList=new List<NSP_Implementation_Profile_Automation__c>();
        for ( NSP_Implementation_Profile_Automation__c ipa : ipAutomationList ) {
            if ( existingIpAutomations.isEmpty()
                || !existingIpAutomations.contains(ipa.NSP_Implementation_Profile__c+'_'+ipa.Name+'_'+ipa.NSP_Record_Type__c)
                )
            {
                newipAutomationList.add(ipa);
            }
        }
        return newipAutomationList;
    }

    public static NSP_Implementation_Profile_Automation__c createIPAutomation(Implementation_Profile__c ipRec, String automationName, String fnName, String section){
        NSP_Implementation_Profile_Automation__c ipAautomation = new NSP_Implementation_Profile_Automation__c();
        ipAautomation.Name = automationName;
        ipAautomation.NSP_Method_Name__c = fnName;
        ipAautomation.NSP_Section__c = section;
        ipAautomation.NSP_Class_Name__c=NSP_ServiceConstants.IP_PROJECTTASKMM_AUTOMATIONCLASS;
        ipAautomation.NSP_Last_Run__c = System.now();
        if ( ipRec != null ) {
            ipAautomation.NSP_Implementation_Profile__c = ipRec.Id;
            if ( ipRec.RecordTypeId==ipFSORecordTypeId ) {
                ipAautomation.NSP_Record_Type__c=NSP_ServiceConstants.FSOProfile;
            }
            if ( ipRec.RecordTypeId==ipMMRecordTypeId ) {
                ipAautomation.NSP_Record_Type__c=NSP_ServiceConstants.MIDDLEMARKET;
            }
        }
        return ipAautomation;
    }

    private Id getMilestoneId( List<pse__Milestone__c> listOfMilestones , String milestoneName ) {
        Id response = null;
        if ( ( listOfMilestones != null ) && !listOfMilestones.isEmpty() ) {
            for ( pse__Milestone__c milestone : listOfMilestones ) {
                if ( milestone.Name == milestoneName ) {
                    response = milestone.Id;
                    break;
                }
            }
        }
        return response;
    }

    private  void checkforPayrollRegister(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(PAYROLL_REGISTER_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && ( newRec.Recent_Payroll_Register_Collected__c==NSP_ServiceConstants.NO
                || newRec.Recent_Payroll_Register_Collected__c == NSP_ServiceConstants.NOTCOLLECTED
                )
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Recent_Payroll_Register_Collected__c != existingRec.Recent_Payroll_Register_Collected__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_REGISTER_MM);
        }
    }

    private void checkforFEINDocument(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(FEIN_DOCUMENT_COLLECTED_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && ( newRec.Has_FEIN_documentation_been_collected__c==NSP_ServiceConstants.NO
                || newRec.Has_FEIN_documentation_been_collected__c == NSP_ServiceConstants.NOTCOLLECTED
                )
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Has_FEIN_documentation_been_collected__c != existingRec.Has_FEIN_documentation_been_collected__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, FEIN_DOCUMENT_COLLECTED_MM);
        }
    }

    private void checkforReceivedCertificate(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(GENERAL_LIABILITY_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c==NSP_ServiceConstants.REQUESTED
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c != existingRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, GENERAL_LIABILITY_MM);
        }
    }

    private void checkforSeasonalEE(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(SEASONAL_EE_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Client_have_will_have_any_Seasonal_EEs__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Client_have_will_have_any_Seasonal_EEs__c != existingRec.Client_have_will_have_any_Seasonal_EEs__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SEASONAL_EE_MM);
        }
    }

    private  void checkforUnionEE(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(EEO_FILING_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Does_the_client_have_any_union_EEs__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Does_the_client_have_any_union_EEs__c != existingRec.Does_the_client_have_any_union_EEs__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EEO_FILING_MM);
        }
    }

    private void checkforEEOnLeave(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(EEO_ON_LEAVE_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Are_there_any_EEs_on_Leave_of_Absence__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Are_there_any_EEs_on_Leave_of_Absence__c != existingRec.Are_there_any_EEs_on_Leave_of_Absence__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EEO_ON_LEAVE_MM);
        }
    }

    private void checkforPostTaxDeductions(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(POST_DEDUCTION_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Client_has_any_post_tax_deductions__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Client_has_any_post_tax_deductions__c != existingRec.Client_has_any_post_tax_deductions__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POST_DEDUCTION_MM);
        }
     }

    private void checkforTimeStar(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(TIMESTAR_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Client_utilizing_Insperity_s_TimeStar__c ==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Client_utilizing_Insperity_s_TimeStar__c != existingRec.Client_utilizing_Insperity_s_TimeStar__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, TIMESTAR_MM);
        }
    }

    private  void checkforGarnishments(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(GARNISHMENT_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Do_any_EEs_have_garnishments__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Do_any_EEs_have_garnishments__c != existingRec.Do_any_EEs_have_garnishments__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, GARNISHMENT_MM);
        }
    }

    private  void checkforRetPlan(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( ( automationsToExecute.contains(RETIRE_PLAN_MM)  || automationsToExecute.contains(RETIRE_PLANORK_MM) )
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && ( newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.CSP401K
                || newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.SIMPLEIRA
                || newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.CLIENTB
                || newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.UNIDENTIFIED_ORK
                )
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Type_of_retirement_plan_client_has_today__c != existingRec.Type_of_retirement_plan_client_has_today__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, RETIRE_PLAN_MM);
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, RETIRE_PLANORK_MM);
        }
    }

    private void checkforHSA(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(HSA_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Does_the_client_offer_a_HSA__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Does_the_client_offer_a_HSA__c != existingRec.Does_the_client_offer_a_HSA__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HSA_MM);
        }
    }

    private void checkforHSAOptum(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(HSA_OPTUM_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Is_client_s_current_HSA_with_Optum_Bank__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Is_client_s_current_HSA_with_Optum_Bank__c != existingRec.Is_client_s_current_HSA_with_Optum_Bank__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HSA_OPTUM_MM);
            childProjectTask = HSA_OPTUM_MM;
        }
    }

    private void checkforNoHSAOptum(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(HSA_OPTUM_NO_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Is_client_s_current_HSA_with_Optum_Bank__c==NSP_ServiceConstants.No
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Is_client_s_current_HSA_with_Optum_Bank__c != existingRec.Is_client_s_current_HSA_with_Optum_Bank__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HSA_OPTUM_NO_MM);
            childProjectTask = HSA_OPTUM_NO_MM;
        }
    }

    //Return value to create child tasks of "Client offers HSA" Automation
    //in afterInsert Project Task trigger
    public static String hsaOptumChildren(){
        return childProjectTask;
    }

    private void checkforCOBRA(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(COBRA_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Participants_on_COBRA_eligibility_period__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Participants_on_COBRA_eligibility_period__c != existingRec.Participants_on_COBRA_eligibility_period__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, COBRA_MM);
        }
    }

    private void checkforDeducibleCarryover(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(DEDUCIBLE_CARRYOVER_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Reviewed_deductible_carryover_w_client__c
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Reviewed_deductible_carryover_w_client__c != existingRec.Reviewed_deductible_carryover_w_client__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, DEDUCIBLE_CARRYOVER_MM);
        }
    }

    private void checkforEEMedical(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(EE_MEDICAL_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Any_EEs_with_urgent_medical_needs__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Any_EEs_with_urgent_medical_needs__c != existingRec.Any_EEs_with_urgent_medical_needs__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EE_MEDICAL_MM);
        }
    }

    private void checkforWaitingPeriod(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(WAITING_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Insperity_benefits_waiting_period__c != null
            && newRec.Client_s_previous_waiting_period__c != null
            && newRec.Any_EEs_in_clients_waiting_period__c == NSP_ServiceConstants.Yes
            )
        {
            String[] inspPeriod = newRec.Insperity_benefits_waiting_period__c.split(' ');
            String[] clientPeriod = newRec.Client_s_previous_waiting_period__c.split(' ');
            if ( Integer.valueOf(inspPeriod[0]) > Integer.valueOf(clientPeriod[0])
                && ( existingRec == null
                    || newRec.NSP_Form_Completed__c
                    || newRec.Any_EEs_in_clients_waiting_period__c != existingRec.Any_EEs_in_clients_waiting_period__c
                    || newRec.Insperity_benefits_waiting_period__c != existingRec.Insperity_benefits_waiting_period__c
                    || newRec.Client_s_previous_waiting_period__c != existingRec.Client_s_previous_waiting_period__c
                    )
                )
            {
                updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, WAITING_MM);
            }
        }
    }

    private void checkfor401KPlan(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(NSP401K_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && ( newRec.Client_want_to_begin_401k_w_NSP_setup__c == NSP_ServiceConstants.Yes
                || ( newRec.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.PEOMULTIPLIER
                    || newRec.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.CSP401KNSP
                    )
                )
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Client_want_to_begin_401k_w_NSP_setup__c != existingRec.Client_want_to_begin_401k_w_NSP_setup__c
                || newRec.Type_of_retirement_plan_client_has_today__c != existingRec.Type_of_retirement_plan_client_has_today__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, NSP401K_MM);
        }
    }

    private void checkforStandardOffer(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(STANDARD_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Client_has_any_of_the_following__c != null
            && newRec.Client_has_any_of_the_following__c.contains(NSP_ServiceConstants.STANDARD_LETTER)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Client_has_any_of_the_following__c != existingRec.Client_has_any_of_the_following__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, STANDARD_MM);
        }
    }

    private void checkforBackground(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(BACKGROUND_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Does_client_perform_background_checks__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Does_client_perform_background_checks__c != existingRec.Does_client_perform_background_checks__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, BACKGROUND_MM);
        }
    }

    private void checkforDrugScreening(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(DRUG_SCREENING_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Client_does_pre_employment_drug_screen__c==NSP_ServiceConstants.YES
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Client_does_pre_employment_drug_screen__c != existingRec.Client_does_pre_employment_drug_screen__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, DRUG_SCREENING_MM);
        }
    }

    private void checkforScreeningBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(SCREENING_BPS_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Select_BPSes__c != null
            && newRec.Select_BPSes__c.contains(NSP_ServiceConstants.SCREENING)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_BPSes__c != existingRec.Select_BPSes__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SCREENING_BPS_MM);
        }
    }

    private void checkforPerformanceBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(PERFORMANCE_BPS_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Select_BPSes__c != null
            && newRec.Select_BPSes__c.contains(NSP_ServiceConstants.PERFORMANCE)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_BPSes__c != existingRec.Select_BPSes__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PERFORMANCE_BPS_MM);
        }
    }

    private void checkforInsuranceBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(INSURANCE_BPS_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Select_BPSes__c != null
            && newRec.Select_BPSes__c.contains(NSP_ServiceConstants.INSURANCE)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_BPSes__c != existingRec.Select_BPSes__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, INSURANCE_BPS_MM);
        }
    }

    private void checkforOrganizationalBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(ORGANIZATIONAL_BPS_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Select_BPSes__c != null
            && newRec.Select_BPSes__c.contains(NSP_ServiceConstants.ORGANIZATIONAL)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_BPSes__c != existingRec.Select_BPSes__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, ORGANIZATIONAL_BPS_MM);
        }
    }

    private void checkforRecruitingBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(RECRUITING_BPS_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Select_BPSes__c != null
            && newRec.Select_BPSes__c.contains(NSP_ServiceConstants.RECRUITING)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_BPSes__c != existingRec.Select_BPSes__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, RECRUITING_BPS_MM);
        }
    }

    private void checkForCertifyBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(CERTIFY_BPS_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Select_BPSes__c != null
            && newRec.Select_BPSes__c.contains(NSP_ServiceConstants.CERTIFY)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_BPSes__c != existingRec.Select_BPSes__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CERTIFY_BPS_MM);
        }
    }

    private void checkForStateSpecificLeave(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        List<String> stateCodes = new List <String>{'CA','IL','MD','MN','NH','NY','SC','DC','WA'};
        if ( automationsToExecute.contains(SPECIFIC_LEAVE_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && findSharedValue(stateCodes,newRec.Employees_work_in_the_following_states__c)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Employees_work_in_the_following_states__c != existingRec.Employees_work_in_the_following_states__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SPECIFIC_LEAVE_MM);
        }
    }

    private void checkForPreTax(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( ( automationsToExecute.contains(PRE_TAX_DEDUCT_MM) || automationsToExecute.contains(PRE_TAX_MM) )
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES
            && newRec.Sponsored_plan_contribution_type__c!=null
            && newRec.Sponsored_plan_contribution_type__c.contains(NSP_ServiceConstants.PRETAX)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Sponsored_plan_contribution_type__c != existingRec.Sponsored_plan_contribution_type__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PRE_TAX_DEDUCT_MM);
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PRE_TAX_MM);
        }
    }

    private void checkForCspHsa( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( automationsToExecute.contains(CSP_HSA_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.NSP_Client_Sponsored_Plan__c==NSP_ServiceConstants.YES
            && newRec.Sponsored_plan_contribution_type__c != null
            && newRec.Sponsored_plan_contribution_type__c.contains(NSP_ServiceConstants.PRETAX)
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != null
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HSA)
            && newRec.NSP_HSA_Ongoing_CSP_cafeteria_document__c == NSP_ServiceConstants.REQUESTED
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_HSA_Ongoing_CSP_cafeteria_document__c != existingRec.NSP_HSA_Ongoing_CSP_cafeteria_document__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CSP_HSA_MM);
        }
    }

    private void checkForPostTax(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( ( automationsToExecute.contains(POST_TAX_SPONSPOREDPLAN_MM) || automationsToExecute.contains(POST_TAX_EMPSETUP_MM) )
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && ( newRec.Client_has_any_post_tax_deductions__c==NSP_ServiceConstants.YES
                || ( newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES
                    && newRec.Sponsored_plan_contribution_type__c!=null
                    && newRec.Sponsored_plan_contribution_type__c.contains(NSP_ServiceConstants.POSTTAX)
                    )
                )
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Sponsored_plan_contribution_type__c != existingRec.Sponsored_plan_contribution_type__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POST_TAX_SPONSPOREDPLAN_MM);
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POST_TAX_EMPSETUP_MM);
        }
    }

    private void checkForExpenseAllowance(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(ALLOWNCE_EXPENSE_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Allowances__c!=null
            && newRec.Allowances__c.contains(NSP_ServiceConstants.PHONE)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Allowances__c != existingRec.Allowances__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, ALLOWNCE_EXPENSE_MM);
        }
    }

    private void checkForDependentCare(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(DEPENDENT_CARE_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c!=null
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DCFSA)
            && newRec.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c == NSP_ServiceConstants.REQUESTED
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != existingRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, DEPENDENT_CARE_MM);
        }
    }

    private void checkForHealthCare(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(HEALTH_CARE_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c!=null
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HCFSA)
            && newRec.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c == NSP_ServiceConstants.REQUESTED
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != existingRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HEALTH_CARE_MM);
        }
    }

    private void checkForMedical( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( automationsToExecute.contains(CSP_MEDICAL_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c!=null
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.MEDICAL)
            && newRec.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c == NSP_ServiceConstants.REQUESTED
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c != existingRec.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CSP_MEDICAL_MM);
        }
    }

    private void checkForDental( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( automationsToExecute.contains(CSP_DENTAL_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c!=null
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DENTAL)
            && newRec.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c == NSP_ServiceConstants.REQUESTED
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c != existingRec.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CSP_DENTAL_MM);
        }
    }

    private void checkForVision( Implementation_Profile__c newRec , Implementation_Profile__c existingRec ) {
        if ( automationsToExecute.contains(CSP_VISION_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c!=null
            && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.VISION)
            && newRec.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c == NSP_ServiceConstants.REQUESTED
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c != existingRec.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CSP_VISION_MM);
        }
    }

    private void checkForDataVerificationMM(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if ( automationsToExecute.contains(DATA_VERIFICATION_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Does_this_client_have_an_AWW__c == NSP_ServiceConstants.YES
            && newRec.NSP_Insperity_1st_pay_date__c != null
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Does_this_client_have_an_AWW__c != existingRec.Does_this_client_have_an_AWW__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, DATA_VERIFICATION_MM);
        }
    }

    private void checkForHandbookDevelopment(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(HANDBOOK_DEVELOPMENT_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Client_have_any_urgent_HR_needs__c == NSP_ServiceConstants.YES
            && newRec.Select_client_urgent_HR_needs__c!=null
            && newRec.Select_client_urgent_HR_needs__c.CONTAINS(NSP_ServiceConstants.HANDBOOK)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_client_urgent_HR_needs__c != existingRec.Select_client_urgent_HR_needs__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HANDBOOK_DEVELOPMENT_MM);
        }
    }

    private void checkForJobDescription(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(JOBDESCRIPTION_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Client_have_any_urgent_HR_needs__c == NSP_ServiceConstants.YES
            && newRec.Select_client_urgent_HR_needs__c!=null
            && newRec.Select_client_urgent_HR_needs__c.CONTAINS(NSP_ServiceConstants.JOBDESCRIPTION)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_client_urgent_HR_needs__c != existingRec.Select_client_urgent_HR_needs__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, JOBDESCRIPTION_MM);
        }
    }

    private void checkForSeveranceAgreement(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if ( automationsToExecute.contains(SEVERANCEAGREEMENT_MM)
            && newRec != null
            && newRec.RecordTypeId == ipMMRecordTypeId
            && newRec.Client_have_any_urgent_HR_needs__c == NSP_ServiceConstants.YES
            && newRec.Select_client_urgent_HR_needs__c!=null
            && newRec.Select_client_urgent_HR_needs__c.CONTAINS(NSP_ServiceConstants.SEVERANCEAGREEMENT)
            && ( existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_client_urgent_HR_needs__c != existingRec.Select_client_urgent_HR_needs__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SEVERANCEAGREEMENT_MM);
        }
    }

    public boolean findSharedValue(List<String> stringList, String pickListValue) {
        if(!String.isBlank(pickListValue)){
            // if multiple values are selected
            if(pickListValue.contains(';')){
                for(String picklistVals : pickListValue.split(';')) {
                    if(stringList.contains(picklistVals)){
                        return true;
                    }
                }
            }
            // if only one value is selected
            else if(stringList.contains(pickListValue)){
                return true;
            }
        }
        return false;
    }


}
//