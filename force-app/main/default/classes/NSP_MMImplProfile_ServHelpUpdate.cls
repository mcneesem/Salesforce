public class NSP_MMImplProfile_ServHelpUpdate {

    private  Boolean isRerun =false;
    private Map<Id, Implementation_Profile__c> newIPs = null; 
    private Map<Id, Implementation_Profile__c> oldIPs = null;
    private Map<String, Set<Id>> ipRecordsByAutomation = new Map<String, Set<Id>>();
    private List<sObject> recToInsert = new List<sObject>();
    private List<sObject> childRecToInsert = new List<sObject>();
    private List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
    private Map<String, Map<Id, sObject>> data = new Map<String, Map<Id, sObject>>();
    private Map<String, List<String>> ipAutomationdata = new Map<String, List<String>>();
    private Boolean isSaveForm = false;
 
    private List<String> automationsToExecute = new List<String>();
    private Set<Id> ipIds=new Set<Id>();
    private Map<String, Id> mapofGroupIds=new Map<String, Id>();
    private Map<String, EmailTemplate> mapOfEmailTempaltes = new Map<String, EmailTemplate>();
    Map<Id, String []> mapofEmpNames = new Map<Id, String []>();
    
    private List<String> existingIpAutomations=new List<String>();
    private List<String> listRegulatedStates = new List<String>();
    private Map<String, pse__Milestone__c> mileStonesToInsert = new Map<String, pse__Milestone__c>();
     
     private static final String PROJECT_IDENTIFIER = 'pse__Proj__c';
     private static final String PROJECT_TASK_IDENTIFIER = 'pse__Project_Task__c';
     private static final String IMPL_PROFILE_IDENTIFIER = 'Implementation_Profile__c';
     private static final String IP_AUTOMATION_IDENTIFIER = 'NSP_Implementation_Profile_Automation__c';
 
     private static final String PAYROLL_REGISTER_MM='NSP_Payroll_Register';
     private static final String SECTION_QUESTIONNAIRE_MM = 'NSP_Section_125_Questionaire';
     private static final String FEIN_DOCUMENT_COLLECTED_MM = 'NSP_FEIN_documentation';
     private static final String GENERAL_LIABILITY_MM = 'NSP_Received_Certificate';
     private static final String PTO_MM='NSP_Tracking_PTO';
     private static final String EEO_FILING_MM = 'NSP_Union_EEs';
     private static final String SEASONAL_EE_MM = 'NSP_Seasonal_EEs';
     private static final String EEO_ON_LEAVE_MM = 'NSP_Leave_of_Absence';
     private static final String LOA_TYPES_MM = 'NSP_LOA_Types';
     private static final String LOA_GREATER_THAN_MM = 'NSP_LOA_Type_Greater';
     private static final String SALARY_CONT_MM = 'NSP_LOA_Salary_Continuation';
     private static final String POST_TAX_MM = 'NSP_Post_tax_deductions';
     private static final String TIMESTAR_MM = 'NSP_TimeStar';
     private static final String TIMESTAR_TA_MM = 'NSP_TimeStar_T_A';
     private static final String TIMESTAR_TA_SYS_MM = 'NSP_TimeStar_T_A_System';
     private static final String TIMESTAR_TA_ADMIN_MM = 'NSP_TimeStar_T_A_Administrator';
     private static final String TIMESTAR_TA_SUP_MM = 'NSP_TimeStar_T_A_Supervisor';
     private static final String TIMESTAR_TA_EMP_MM = 'NSP_TimeStar_Employee_Plan';
     private static final String TIMESTAR_TA_CONFIG_MM = 'NSP_Timestar_T_A_Configuration';
     private static final String TIMESTAR_TA_EMP_SUB1_MM  = 'NSP_Timestar_Emp_Plan_Sub1';
     private static final String TIMESTAR_TA_EMP_SUB2_MM  = 'NSP_Timestar_Emp_Plan_Sub2';
     private static final String TIMESTAR_TA_EMP_SUB3_MM  = 'NSP_Timestar_Emp_Plan_Sub3';
     private static final String TIMESTAR_TA_EMP_SUB4_MM  = 'NSP_Timestar_Emp_Plan_Sub4';
     private static final String TIMESTAR_TA_PARALLEL = 'NSP_TimeStar_TA_Parallel';
     private static final String TIMESTAR_TA_SYSTEM_MM = 'NSP_TimeStar_TA_System_Live';
     private static final String TIMESTAR_TA_PAYROLL_EXPERT_MM = 'NSP_TimeStar_TA_Payroll_Expert';
     private static final String GARNISHMENT_MM = 'NSP_EE_garnishments';
     private static final String TAX_LEVIES_MM = 'NSP_Tax_levies';
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
     private static final String RETIRE_PLAN_ORK_CLIENT_MM='NSP_Retirement_Plan_ORK_Client';
     private static final String RETIRE_PLAN_ORK_401K_MM='NSP_Retirement_Plan_ORK_Payroll';
     private static final String RETIRE_PLAN_401K_DEF_MM='NSP_Retirement_Plan_401k_Deferrals';
     private static final String RETIRE_PLAN_401K_EMP_MM='NSP_Retirement_Plan_401k_Employee';
     private static final String RETIRE_PLAN_401K_DEF_UP_MM='NSP_Retirement_Plan_401k_uploaded';
     private static final String RETIRE_PLAN_401K_LOAN_MM='NSP_Retirement_Plan_401k_Emp_Upload';
     private static final String RETIRE_PLAN_401K_YTD_MM='NSP_Retirement_Plan_401k_YTD';
     private static final String RETIRE_PLAN_401K_YTD_UP_MM='NSP_Retirement_Plan_401k_YTD_uploaded';
     private static final String NSP401K_MM = 'NSP_X401k_Meeting';
     private static final String NSP401K_CLIENT_MM = 'NSP_X401k_Client_Plan';
     private static final String NSP401K_ELECTION_MM = 'NSP_X401k_Election_Agreement';
     private static final String NSP401K_CLIENT_MATCH_MM = 'NSP_X401k_Client_Match';
     private static final String NSP401K_PLAN_MM = 'NSP_X401k_Plan_Setup';
     private static final String NSP401K_COLLECT_MM = 'NSP_X401k_Collect_YTD';
     private static final String NSP401K_EMP_TRAIN_MM = 'NSP_X401K_Employee_training';
     private static final String SUBSTANCE_ABUSE_MM = 'NSP_Substance_Abuse';
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
     private static final String OTHER_PRETAX_TYPE_MM= 'NSP_Other_Pretax';
     private static final String SEVERANCEAGREEMENT_MM= 'NSP_SeverenceAgreement';
     private static final String JOBDESCRIPTION_MM= 'NSP_JobDescriptiom';
     private static final String HANDBOOK_DEVELOPMENT_MM= 'NSP_HandbookDevelopment';
     private static final String COBRA_GUIDELINES_MM= 'NSP_COBRAGuidelines';
     private static final String COBRA_TEAM_MM= 'NSP_COBRATeam';
     private static final String COBRA_PACKETS_MM= 'NSP_COBRAPackets';
     
 
     private static Id ipFSORecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();
     private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
     private static Id milestonePEORecordtypeId = SObjectType.pse__Milestone__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOMILSTONE).getRecordTypeId();
     private static Id projectTaskPEORecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
     
     public NSP_MMImplProfile_ServHelpUpdate(Map<Id, Implementation_Profile__c> newIPs, Map<Id, Implementation_Profile__c> oldIPs){
         this.newIPs = newIPs;
         this.oldIPs = oldIPs;
         this.automationsToExecute.addAll(new List<String>{PAYROLL_REGISTER_MM,SECTION_QUESTIONNAIRE_MM,FEIN_DOCUMENT_COLLECTED_MM,GENERAL_LIABILITY_MM,
             PTO_MM,EEO_FILING_MM,SEASONAL_EE_MM,EEO_ON_LEAVE_MM,LOA_TYPES_MM,LOA_GREATER_THAN_MM,SALARY_CONT_MM,SPECIFIC_LEAVE_MM,POST_TAX_MM,TIMESTAR_MM,TIMESTAR_TA_EMP_MM,
             GARNISHMENT_MM,TAX_LEVIES_MM,PRE_TAX_MM,PRE_TAX_DEDUCT_MM,POST_TAX_SPONSPOREDPLAN_MM,POST_TAX_EMPSETUP_MM,ALLOWNCE_EXPENSE_MM,RETIRE_PLAN_MM,HSA_MM,HSA_OPTUM_MM,
             HSA_OPTUM_NO_MM,COBRA_MM,DEDUCIBLE_CARRYOVER_MM,EE_MEDICAL_MM,WAITING_MM,DEPENDENT_CARE_MM,HEALTH_CARE_MM,OTHER_PRETAX_TYPE_MM,POST_DEDUCTION_MM,RETIRE_PLANORK_MM,
             NSP401K_MM,HANDBOOK_DEVELOPMENT_MM,JOBDESCRIPTION_MM,SEVERANCEAGREEMENT_MM,SUBSTANCE_ABUSE_MM,STANDARD_MM,BACKGROUND_MM,DRUG_SCREENING_MM,
             SCREENING_BPS_MM,PERFORMANCE_BPS_MM,ORGANIZATIONAL_BPS_MM,INSURANCE_BPS_MM,RECRUITING_BPS_MM,CERTIFY_BPS_MM});
     }
  
     public NSP_MMImplProfile_ServHelpUpdate(Id ipRecord, String automationName){
        this.newIPs =  NSP_ImpAutomationsController.getIpRecord(ipRecord);
        this.isRerun=true;
        this.automationsToExecute.add(automationName);
    }
     public NSP_MMImplProfile_ServHelpUpdate(Boolean isSave){
        this.isSaveForm = isSave;
    }
     public  Map<String, Set<Id>> executeAutomation() {
        Map<String, Set<Id>> ipRecordsByAutomationMap = new  Map<String, Set<Id>> ();
         try{
            start();
            execute();
            ipRecordsByAutomationMap= ipRecordsByAutomation;
        }catch(Exception ex ){
            NSP_ErrorLogHandler.logSaveException('NSP_MMImplProfile_ServHelpUpdate', 'executeAutomation', ex.getMessage());
        }
        return ipRecordsByAutomationMap;
     }
 
 
     private void start() {
         // Create a set of eligible records which we need to pull
         populateEligibleRecords();
         if(ipRecordsByAutomation.size()>0){
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
        for(Group groupRecord: [SELECT Id, Name,Type FROM Group WHERE Type=:NSP_ServiceConstants.GroupType]){
            mapofGroupIds.put(groupRecord.Name,groupRecord.Id);
        }
    }
 
     private void populateEligibleRecords(){
         for(Implementation_Profile__c ipRec : newIPs.values()){
             Implementation_Profile__c existingRec = oldIPs != null ? oldIPs.get(ipRec.Id) : null;
             
             ipIds.add(ipRec.Id);
             
             // All the automation methods will check the eligibility of the current record.
             if(automationsToExecute.contains(PAYROLL_REGISTER_MM)){
                 checkforPayrollRegister(ipRec, existingRec);
             }
             if(automationsToExecute.contains(SECTION_QUESTIONNAIRE_MM)){
                 checkforSectionQuestionnaire(ipRec, existingRec);
             }
             if(automationsToExecute.contains(FEIN_DOCUMENT_COLLECTED_MM)){
                 checkforFEINDocument(ipRec, existingRec);
             }
             if(automationsToExecute.contains(GENERAL_LIABILITY_MM)){
                checkforReceivedCertificate(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SEASONAL_EE_MM)){
                checkforSeasonalEE(ipRec, existingRec);
            }
            if(automationsToExecute.contains(PTO_MM)){
                checkforPTO(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EEO_FILING_MM)){
                checkforUnionEE(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EEO_ON_LEAVE_MM)){
                checkforEEOnLeave(ipRec, existingRec);
            }
            if(automationsToExecute.contains(LOA_TYPES_MM)){
                checkforLOATypes(ipRec, existingRec);
            }
            if(automationsToExecute.contains(LOA_GREATER_THAN_MM)){
                checkforLOAGreaterThan(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SALARY_CONT_MM)){
                checkforLOASalaryContinuation(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SPECIFIC_LEAVE_MM)){
                checkForStateSpecificLeave(ipRec, existingRec);
            }
            if(automationsToExecute.contains(POST_TAX_MM)){
                checkforPostTaxDeductions(ipRec, existingRec);
            }
            if(automationsToExecute.contains(TIMESTAR_MM)){
                 checkforTimeStar(ipRec, existingRec);
             }
             if(automationsToExecute.contains(TIMESTAR_TA_EMP_MM)){
                 checkforTimeStar(ipRec, existingRec);
             }
             if(automationsToExecute.contains(GARNISHMENT_MM)){
                checkforGarnishments(ipRec, existingRec);
            }
            if(automationsToExecute.contains(TAX_LEVIES_MM)){
                checkforTaxLevies(ipRec, existingRec);
            }
            if(automationsToExecute.contains(PRE_TAX_MM)){
                checkForPreTax(ipRec, existingRec);
            }
            if(automationsToExecute.contains(PRE_TAX_DEDUCT_MM)){
                checkForPreTax(ipRec, existingRec);
            }
            if(automationsToExecute.contains(POST_TAX_SPONSPOREDPLAN_MM)){
                checkForPostTax(ipRec, existingRec);
            }
            if(automationsToExecute.contains(POST_TAX_EMPSETUP_MM)){
                checkForPostTax(ipRec, existingRec);
            }
            if(automationsToExecute.contains(ALLOWNCE_EXPENSE_MM)){
                checkForExpenseAllowance(ipRec, existingRec);
            }
            if(automationsToExecute.contains(RETIRE_PLAN_MM)){
                checkforRetPlan(ipRec, existingRec);
            }
            if(automationsToExecute.contains(HSA_MM)){
                checkforHSA(ipRec, existingRec);
            }
            if(automationsToExecute.contains(HSA_OPTUM_MM)){
                checkforHSAOptum(ipRec, existingRec);
            }
            if(automationsToExecute.contains(HSA_OPTUM_NO_MM)){
                checkforNoHSAOptum(ipRec, existingRec);
            }
            if(automationsToExecute.contains(COBRA_MM)){
                checkforCOBRA(ipRec, existingRec);
            }
            if(automationsToExecute.contains(DEDUCIBLE_CARRYOVER_MM)){
                checkforDeducibleCarryover(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EE_MEDICAL_MM)){
                checkforEEMedical(ipRec, existingRec);
            }
            if(automationsToExecute.contains(WAITING_MM)){
                checkforWaitingPeriod(ipRec, existingRec);
            }
            if(automationsToExecute.contains(DEPENDENT_CARE_MM)){
                checkForDependentCare(ipRec, existingRec);
            }
            if(automationsToExecute.contains(HEALTH_CARE_MM)){
                checkForHealthCare(ipRec, existingRec);
            }
            if(automationsToExecute.contains(OTHER_PRETAX_TYPE_MM)){
                checkForOtherPreTaxType(ipRec, existingRec);
            }
            if(automationsToExecute.contains(POST_DEDUCTION_MM)){
                checkforPostTaxDeductions(ipRec, existingRec);
            }
            if(automationsToExecute.contains(RETIRE_PLANORK_MM)){
                checkforRetPlan(ipRec, existingRec);
            }
            if(automationsToExecute.contains(NSP401K_MM)){
                checkfor401KPlan(ipRec, existingRec);
            }
            if(automationsToExecute.contains(HANDBOOK_DEVELOPMENT_MM)){
                checkForHandbookDevelopment(ipRec, existingRec);
            }
            if(automationsToExecute.contains(JOBDESCRIPTION_MM)){
                checkForJobDescription(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SEVERANCEAGREEMENT_MM)){
                checkForSeveranceAgreement(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SUBSTANCE_ABUSE_MM)){
                checkforSubstanceAbuse(ipRec, existingRec);
            }
            if(automationsToExecute.contains(STANDARD_MM)){
                checkforStandardOffer(ipRec, existingRec);
            }
            if(automationsToExecute.contains(BACKGROUND_MM)){
                checkforBackground(ipRec, existingRec);
            }
            if(automationsToExecute.contains(DRUG_SCREENING_MM)){
                checkforDrugScreening(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SCREENING_BPS_MM)){
                checkforScreeningBPS(ipRec, existingRec);
            }
            if(automationsToExecute.contains(PERFORMANCE_BPS_MM)){
                checkforPerformanceBPS(ipRec, existingRec);
            }
            if(automationsToExecute.contains(ORGANIZATIONAL_BPS_MM)){
                checkforOrganizationalBPS(ipRec, existingRec);
            }
            if(automationsToExecute.contains(INSURANCE_BPS_MM)){
                checkforInsuranceBPS(ipRec, existingRec);
            }
            if(automationsToExecute.contains(RECRUITING_BPS_MM)){
                checkforRecruitingBPS(ipRec, existingRec);
            }
            if(automationsToExecute.contains(CERTIFY_BPS_MM)){
                checkForCertifyBPS(ipRec, existingRec);
            }

         }
     }
 
     private void execute(){
         if(ipRecordsByAutomation.containsKey(PAYROLL_REGISTER_MM)){
            createProjecttaskforPayrollRegister();
         }
         if(ipRecordsByAutomation.containsKey(SECTION_QUESTIONNAIRE_MM)){
            createProjectTaskForSectionQuestionnaire();
         }
         if(ipRecordsByAutomation.containsKey(FEIN_DOCUMENT_COLLECTED_MM)){
            createProjectTaskForFEIN();
         }
         if(ipRecordsByAutomation.containsKey(GENERAL_LIABILITY_MM)){
            createProjecttaskforReceivedCertificate();
         }
         if(ipRecordsByAutomation.containsKey(SEASONAL_EE_MM)){
            createProjectTaskforSeasonalEE();
         }
         if(ipRecordsByAutomation.containsKey(PTO_MM)){
            createProjecttaskforPTO();
         }
         if(ipRecordsByAutomation.containsKey(EEO_FILING_MM)){
            createProjectTaskForUnionEE();
         }
         if(ipRecordsByAutomation.containsKey(EEO_ON_LEAVE_MM)){
            createProjectTaskForEELeave();
         }
         if(ipRecordsByAutomation.containsKey(SPECIFIC_LEAVE_MM)){
            createProjectTaskForSpecificLeave();
         }
         if(ipRecordsByAutomation.containsKey(POST_TAX_MM)){
            createProjectTaskForPostTax();
         }
         if(ipRecordsByAutomation.containsKey(POST_DEDUCTION_MM)){
            createProjectTaskForPostDeductions();
         }
         if(ipRecordsByAutomation.containsKey(TIMESTAR_MM)){
            createProjectTaskForTimeStar();
         }

         if(ipRecordsByAutomation.containsKey(GARNISHMENT_MM)){
            createProjectTaskForEEGarnishment();
         }
         if(ipRecordsByAutomation.containsKey(TAX_LEVIES_MM)){
            createProjectTaskForTaxLevies();
         }
         if(ipRecordsByAutomation.containsKey(PRE_TAX_MM)){
            createProjectTaskForPreTax();
         }
         if(ipRecordsByAutomation.containsKey(PRE_TAX_DEDUCT_MM)){
            createProjectTaskForPreTaxDeduct();
         }
         if(ipRecordsByAutomation.containsKey(POST_TAX_SPONSPOREDPLAN_MM)){
            createProjectTaskForPostTaxClient();
         }
         if(ipRecordsByAutomation.containsKey(POST_TAX_EMPSETUP_MM)){
            createProjectTaskForPostTaxEmp();
         }
         if(ipRecordsByAutomation.containsKey(ALLOWNCE_EXPENSE_MM)){
            createProjectTaskForExpenseAllowance();
         }
         if(ipRecordsByAutomation.containsKey(RETIRE_PLAN_MM)){
            createProjectTaskForRetirementPlan();
         }
         if(ipRecordsByAutomation.containsKey(HSA_MM)){
            createProjectTaskForHSA();
         }

         if(ipRecordsByAutomation.containsKey(DEDUCIBLE_CARRYOVER_MM)){
            createProjectTaskForDeducibleCarryover();
         }
         if(ipRecordsByAutomation.containsKey(EE_MEDICAL_MM)){
            createProjectTaskForEEMedical();
         }
         if(ipRecordsByAutomation.containsKey(WAITING_MM)){
            createProjectTaskForEEWaiting();
         }
         if(ipRecordsByAutomation.containsKey(DEPENDENT_CARE_MM)){
            createProjectTaskForDependentCare();
         }
         if(ipRecordsByAutomation.containsKey(HEALTH_CARE_MM)){
            createProjectTaskForHealthCare();
         }
         if(ipRecordsByAutomation.containsKey(OTHER_PRETAX_TYPE_MM)){
            createProjectTaskForOtherPretax();
         }
         if(ipRecordsByAutomation.containsKey(RETIRE_PLANORK_MM)){
            createProjectTaskForRetirementPlans();
         }
         if(ipRecordsByAutomation.containsKey(NSP401K_MM)){
            createProjectTaskFor401K();
         }
         if(ipRecordsByAutomation.containsKey(HANDBOOK_DEVELOPMENT_MM)){
            createProjectTaskForHRHandbook();
         }
         if(ipRecordsByAutomation.containsKey(JOBDESCRIPTION_MM)){
            createProjectTaskForHRJobDescription();
         }
         if(ipRecordsByAutomation.containsKey(SEVERANCEAGREEMENT_MM)){
            createProjectTaskForHRSeverance();
         }
         if(ipRecordsByAutomation.containsKey(SUBSTANCE_ABUSE_MM)){
            createProjectTaskForSubstanceAbuse();
         }
         if(ipRecordsByAutomation.containsKey(STANDARD_MM)){
            createProjectTaskForStandardOffer();
         }
         if(ipRecordsByAutomation.containsKey(BACKGROUND_MM)){
            createProjectTaskForBackgroundCheck();
         }
         if(ipRecordsByAutomation.containsKey(DRUG_SCREENING_MM)){
            createProjectTaskForDrugScreening();
         }
         if(ipRecordsByAutomation.containsKey(SCREENING_BPS_MM)){
            createProjectTaskForEmploymentScreening();
         }
         if(ipRecordsByAutomation.containsKey(PERFORMANCE_BPS_MM)){
            createProjectTaskForPerformanceManagement();
         }
         if(ipRecordsByAutomation.containsKey(ORGANIZATIONAL_BPS_MM)){
            createProjectTaskForOrganizationalPlanning();
         }
         if(ipRecordsByAutomation.containsKey(INSURANCE_BPS_MM)){
            createProjectTaskForInsuranceServices();
         }
         if(ipRecordsByAutomation.containsKey(RECRUITING_BPS_MM)){
            createProjectTaskForRecruitingServices();
         }
         if(ipRecordsByAutomation.containsKey(CERTIFY_BPS_MM)){
            createProjectTaskForCertify();
         }
        finish();
        getProjectDBRecords();
        if(ipRecordsByAutomation.containsKey(LOA_GREATER_THAN_MM)){
            createProjectTaskForLOAGreater();
         }
         if(ipRecordsByAutomation.containsKey(LOA_TYPES_MM)){
            createProjectTaskForLOATypes();
         }
         if(ipRecordsByAutomation.containsKey(SALARY_CONT_MM)){
            createProjectTaskForLOASalary();
         }
         if(ipRecordsByAutomation.containsKey(TIMESTAR_TA_EMP_MM)){
            createSubTaskForTimeStar();
         }
         if(ipRecordsByAutomation.containsKey(HSA_OPTUM_MM)){
            createProjectTaskForHSAOptum();
         }

         if(ipRecordsByAutomation.containsKey(HSA_OPTUM_NO_MM)){
            createProjectTaskForNoHSA();
         }
         if(ipRecordsByAutomation.containsKey(COBRA_MM)){
            createProjectTaskForCOBRA();
            createSubTaskForCobra();
         }
         
         if(!childRecToInsert.isEmpty() && !System.isFuture() && !System.isBatch()){
             String childRecordsList = Json.serialize(childRecToInsert);
             insertChildRecords(childRecordsList);
         }
        
    }
 
     private void finish(){
        List<Database.UpsertResult> upsertResults = Database.upsert(mileStonesToInsert.values(), false);
        NSP_ErrorLogHandler.logUpsertResultsException('NSP_Implprofile_ServiceHelperUpdate', 'milestoneRecords:upsertResults', upsertResults);
         recToInsert.sort();
         for (SObject rec : recToInsert) {
            if(rec.getSObjectType() == Schema.pse__Project_Task__c.getSObjectType()){
                pse__Project_Task__c projectTask = (pse__Project_Task__c) rec;
                if(projectTask.pse__Milestone__c == null){
                    pse__Milestone__c milestoneRec = mileStonesToInsert.get(projectTask.pse__WBS_Element_Number__c);
                    projectTask.pse__Milestone__c = milestoneRec.Id;
                    projectTask.pse__WBS_Element_Number__c = null;
                }
            }
        }

         List<Database.SaveResult> insertProjectTaskResults = Database.Insert(recToInsert, false);
         NSP_ErrorLogHandler.logSaveResultsException('NSP_Implprofile_ServiceHelperUpdate', 'ProjectTask:insertProjectTaskResults', insertProjectTaskResults); 
     }
 
     private void getIPRecords(){
         
         for (Set<Id> ipRecords : ipRecordsByAutomation.values()) {
             for (Id ipRec : ipRecords) {
                 ipIds.add(ipRec);
             }
         }
         Map<Id, sObject> dbRec = new Map<Id, sObject>([SELECT Id,NSP_Payroll_Specialist__c, NSP_Payroll_Specialist__r.pse__Salesforce_User__c,NSP_Sr_Onboarding_Benefit_Rep__c,NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c, NSP_Sr_Benefit_Rep__c,
                                                        NSP_Sr_Benefit_Rep__r.pse__Salesforce_User__c, NSP_Payroll_Project_Manager__c, NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c,NSP_HR_Specialist__c,NSP_HR_Specialist__r.pse__Salesforce_User__c,Select_the_applicable_LOA_types__c,
                                                        NSP_Project_Manager__c,NSP_Project_Manager__r.pse__Salesforce_User__c,Account__r.Id, Account__c, Account__r.Name from Implementation_Profile__c WHERE Id in:ipIds]);
         data.put(IMPL_PROFILE_IDENTIFIER, dbRec);
         
     }
 
     private void getImplAutomationRecords(){
         Map<Id, sObject> dbRec = new Map<Id, sObject>([SELECT Id,Name,NSP_Implementation_Profile__c,NSP_Record_Type__c,NSP_Method_Name__c FROM NSP_Implementation_Profile_Automation__c WHERE NSP_Implementation_Profile__c = :ipIDs]);
         
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
         
         Map<Id, sObject> dbRec = new Map<Id, sObject>([SELECT Id, pse__End_Date__c, (SELECT Id, Name FROM pse__Milestones__r),
                                                        (SELECT Id, pse__Project__c, NSP_Sub_Category__c, NSP_Category__c,pse__Milestone__c, Name, NSP_Implementation_Profile_Account__c,NSP_Implementation_Account_Id__c FROM pse__Project_Tasks__r) FROM pse__Proj__c WHERE Id IN :projectIDs]);
         
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

    
     
     private pse__Project_Task__c createProjectTaskfromIP(pse__Proj__c project,  String category, Id ipRecId,String milestoneKey){
         
         Id projectTaskPEORecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
         
         pse__Project_Task__c eachProjectTask = new pse__Project_Task__c();
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
         
         return eachProjectTask;
     }
     
            
     private List<pse__Project_Task__c> getnewTaskstoInsert(List<pse__Project_Task__c> projTaskList){
       
       List<pse__Project_Task__c> newProjectList=new List<pse__Project_Task__c>();
       List<String> existingProjecttasks=new List<String>();
         
       Map<Id, sObject> dbRec=data.get(PROJECT_IDENTIFIER);
       
       for(Id projId:dbRec.keySet()){
           
           pse__Proj__c project=(pse__Proj__c)dbRec.get(projId);
           
           for(pse__Project_Task__c projTask:project.pse__Project_Tasks__r){          
              existingProjecttasks.add(projTask.NSP_Implementation_Account_Id__c+'_'+projTask.Name+'_'+
              projTask.NSP_Category__c+'_'+projTask.NSP_Sub_Category__c);            
             }
       }
         
 
       for(pse__Project_Task__c pt: projTaskList){        
          
          if(existingProjecttasks.isEmpty() || !existingProjecttasks.contains(pt.NSP_Implementation_Account_Id__c+'_'+pt.Name+'_'+
          pt.NSP_Category__c+'_'+pt.NSP_Sub_Category__c)){
             newProjectList.add(pt);
          }
          
       }
 
       return newProjectList;
    } 
    
    private List<NSP_Implementation_Profile_Automation__c> getnewAutomationListtoInsert(List<NSP_Implementation_Profile_Automation__c> ipAutomationList){
       
        Map<Id, sObject> dbRec=data.get(IP_AUTOMATION_IDENTIFIER);
        List<String> existingIpAutomations=new List<String>();
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
     
    public static NSP_Implementation_Profile_Automation__c createIPAutomation(Implementation_Profile__c ipRec, String automationName, String fnName, String section){
 
     NSP_Implementation_Profile_Automation__c ipAautomation = new NSP_Implementation_Profile_Automation__c();
       ipAautomation.Name = automationName;
       ipAautomation.NSP_Method_Name__c = fnName;
       ipAautomation.NSP_Section__c = section;
       ipAautomation.NSP_Implementation_Profile__c = ipRec.Id;
       ipAautomation.NSP_Class_Name__c=NSP_ServiceConstants.IP_PROJECTTASKMM_AUTOMATIONCLASS;
       ipAautomation.NSP_Last_Run__c = System.now();
       if(ipRec.RecordTypeId==ipFSORecordTypeId){
           ipAautomation.NSP_Record_Type__c=NSP_ServiceConstants.FSOProfile;
       }
       if(ipRec.RecordTypeId==ipMMRecordTypeId){
           ipAautomation.NSP_Record_Type__c=NSP_ServiceConstants.MIDDLEMARKET;
       }
        
       return ipAautomation;
    }
     
     
     private Id getMilestoneId(List<pse__Milestone__c> listOfMilestone, String milestoneName, pse__Proj__c proj){
         if(listOfMilestone !=null && !listOfMilestone.isEmpty() ){
             
             for(pse__Milestone__c milestone:listOfMilestone){
                 if(milestone.Name==milestoneName){
                     return milestone.Id;
                 }
                     
             }             
         }
         return null;
         
     }
     
     public  void createProjecttaskforPayrollRegister(){
         
         //	Has a recent payroll register been collected?  
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(PAYROLL_REGISTER_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(PAYROLL_REGISTER_MM);
 
 
         for(Id ipRecId : ipRecordsByAutomation.get(PAYROLL_REGISTER_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Payroll_Project_Manager__c!=null && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
                                                        eachProjecttask.pse__Order__c=9;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        projectTaskList.add(eachProjecttask);               
                                            
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
         
       }
     
     public void createProjectTaskForSectionQuestionnaire(){
         //If Received Section 125 Questionnaire? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(SECTION_QUESTIONNAIRE_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SECTION_QUESTIONNAIRE_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(SECTION_QUESTIONNAIRE_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Order__c=11;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
                ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));  
         
            }
        }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
         
         
     }
     
     public void createProjectTaskForFEIN(){
         //Has FEIN documentation been collected?
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(FEIN_DOCUMENT_COLLECTED_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(FEIN_DOCUMENT_COLLECTED_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(FEIN_DOCUMENT_COLLECTED_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                        
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Order__c=28;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));  
         
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));   
     }
     
     public  void createProjecttaskforReceivedCertificate(){
         
         //if Received Certificate of Coverage for General Liability & Auto
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(GENERAL_LIABILITY_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(GENERAL_LIABILITY_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(GENERAL_LIABILITY_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Order__c=31;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);  
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
              
         
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));   
       
     }
     
     public void createProjectTaskforSeasonalEE(){
         //Does client have/will have any: Seasonal EEs? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(SEASONAL_EE_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SEASONAL_EE_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(SEASONAL_EE_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Order__c=36;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));             
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));   
     }
     
         public  void createProjecttaskforPTO(){
         //	If Reporting: Select all that apply  	
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(PTO_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(PTO_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(PTO_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Order__c=37;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));  
         
       }
     
     public void createProjectTaskForUnionEE(){
         //Does the client have any union EEs? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(EEO_FILING_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(EEO_FILING_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(EEO_FILING_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Order__c=38;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);  
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));             
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));  
     }
     
     public void createProjectTaskForEELeave(){
         //Are there any EEs on Leave of Absence? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(EEO_ON_LEAVE_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(EEO_ON_LEAVE_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(EEO_ON_LEAVE_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Order__c=55;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
                ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
          
            }
        }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));  
     }
     
     public void createProjectTaskForLOATypes(){
         //Select the applicable LOA types
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(LOA_TYPES_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(LOA_TYPES_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(LOA_TYPES_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
    
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }  
    
                for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                    if(pt.Name==NSP_ServiceConstants.EMP_ON_LOA){
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c+' ';
                                                        if(ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.MILITARY_LEAVE) && 
                                                            ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.WORKER) &&
                                                            ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.FMLA_STATUS) ){
                                                            eachProjecttask.Name+=NSP_ServiceConstants.MILITARY_LEAVE+';'+NSP_ServiceConstants.WORKER+';'+NSP_ServiceConstants.FMLA_STATUS;
                                                        }else if(ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.MILITARY_LEAVE) && 
                                                            ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.FMLA_STATUS) ){
                                                            eachProjecttask.Name+=NSP_ServiceConstants.MILITARY_LEAVE+';'+NSP_ServiceConstants.FMLA_STATUS;
                                                        }else if(ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.MILITARY_LEAVE) && 
                                                            ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.WORKER)  ){
                                                            eachProjecttask.Name+=NSP_ServiceConstants.MILITARY_LEAVE+';'+NSP_ServiceConstants.WORKER;
                                                        }else if(ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.WORKER) &&
															     ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.FMLA_STATUS)														){
                                                            eachProjecttask.Name+=NSP_ServiceConstants.WORKER+';'+NSP_ServiceConstants.FMLA_STATUS;
                                                        }else if(ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.WORKER)){
                                                            eachProjecttask.Name+=NSP_ServiceConstants.WORKER;
                                                        }
                                                        else if(ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.MILITARY_LEAVE)){
                                                            eachProjecttask.Name+=NSP_ServiceConstants.MILITARY_LEAVE;
                                                        }
                                                        else if(ipwithValue.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.FMLA_STATUS)){
                                                            eachProjecttask.Name+=NSP_ServiceConstants.FMLA_STATUS;
                                                        }
                                                        eachProjecttask.pse__Hierarchy_Depth__c=1;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
                                                        eachProjecttask.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask.pse__Order__c=56;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
                    }
                }
            }
         }
                //check for existing project task and store the new tasks
                childRecToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                childRecToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));   
     }
     
     public void createProjectTaskForLOAGreater(){
         //Select the applicable LOA types
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(LOA_GREATER_THAN_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(LOA_GREATER_THAN_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(LOA_GREATER_THAN_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
    
                for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                    if(pt.Name==NSP_ServiceConstants.EMP_ON_LOA){
                                            
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
                                                        eachProjecttask.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask.pse__Hierarchy_Depth__c=2;
                                                        eachProjecttask.pse__Order__c = 57;
                                                        eachProjecttask.NSP_Visible_to_Client__c = FALSE;
                                                        projectTaskList.add(eachProjecttask);  
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));             
                                            
                    }
                }
         
            }
        }
                //check for existing project task and store the new tasks
                childRecToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                childRecToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));   
     }
     
     public void createProjectTaskForLOASalary(){
         //Select the applicable LOA types
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(SALARY_CONT_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SALARY_CONT_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(SALARY_CONT_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj); 
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }                              
                for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                    if(pt.Name==NSP_ServiceConstants.EMP_ON_LOA){
                                                                    
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Hierarchy_Depth__c=3;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
                                                        eachProjecttask.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask.pse__Order__c = 58;
                                                        eachProjecttask.NSP_Visible_to_Client__c = FALSE;
                                                        projectTaskList.add(eachProjecttask);  
                        ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));             
                                            
                    }
                }
        
            }
        }
                //check for existing project task and store the new tasks
                childRecToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                childRecToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));   
     }
 
     public void createProjectTaskForSpecificLeave(){
         //Select the applicable LOA types
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(SPECIFIC_LEAVE_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SPECIFIC_LEAVE_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(SPECIFIC_LEAVE_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj); 
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }                              
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=59;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
                                                        
                                                        projectTaskList.add(eachProjecttask);  
                        ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));             
                                            
                    
                
         
            }
        }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));   
     }
     
     public void createProjectTaskForPostTax(){
         //Does the client have any post-tax deductions (i.e. auto, loans, uniforms, supplemental insurance)? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(POST_TAX_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(POST_TAX_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(POST_TAX_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c,ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=60;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
               
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords)); 
     }
     
     public void createProjectTaskForTimeStar(){
         //Will client be utilizing Insperity’s TimeStar? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_MM);
         NSP_ProjectTask_Automation__mdt pta1 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_MM);
         NSP_ProjectTask_Automation__mdt pta2 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_SYS_MM);
         NSP_ProjectTask_Automation__mdt pta3 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_ADMIN_MM);
         NSP_ProjectTask_Automation__mdt pta4 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_SUP_MM);
         NSP_ProjectTask_Automation__mdt pta5 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_EMP_MM);
         NSP_ProjectTask_Automation__mdt pta6 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_PARALLEL);
         NSP_ProjectTask_Automation__mdt pta7 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_SYSTEM_MM);
         NSP_ProjectTask_Automation__mdt pta8 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_PAYROLL_EXPERT_MM);
         NSP_ProjectTask_Automation__mdt pta9 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_CONFIG_MM);
 
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(TIMESTAR_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(TIMESTAR_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
    
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }                         
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Order__c=70;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
    
                pse__Project_Task__c eachProjecttask1 = createProjectTaskfromIP(proj, pta1.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask1.NSP_Sub_Category__c=pta1.NSP_Sub_Category__c;
                                                        eachProjecttask1.Name=pta1.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Payroll_Project_Manager__c!=null && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask1.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask1.pse__Order__c=71;
                                                        eachProjecttask1.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask1);               
                                            
                pse__Project_Task__c eachProjecttask2 = createProjectTaskfromIP(proj, pta2.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask2.NSP_Sub_Category__c=pta2.NSP_Sub_Category__c;
                                                        eachProjecttask2.Name=pta2.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask2.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask2.pse__Order__c=72;
                                                        eachProjecttask2.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask2);               
                                            
            
                pse__Project_Task__c eachProjecttask3 = createProjectTaskfromIP(proj, pta3.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask3.NSP_Sub_Category__c=pta3.NSP_Sub_Category__c;
                                                        eachProjecttask3.Name=pta3.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask3.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask3.pse__Order__c=73;
                                                        eachProjecttask3.pse__Milestone__c=milestoneId;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
    
                                                        projectTaskList.add(eachProjecttask3);               
                                            
                pse__Project_Task__c eachProjecttask4 = createProjectTaskfromIP(proj, pta4.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask4.NSP_Sub_Category__c=pta4.NSP_Sub_Category__c;
                                                        eachProjecttask4.Name=pta4.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask4.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask4.pse__Order__c=74;
                                                        eachProjecttask4.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask4);               
                                            
                pse__Project_Task__c eachProjecttask5 = createProjectTaskfromIP(proj, pta5.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask5.NSP_Sub_Category__c=pta5.NSP_Sub_Category__c;
                                                        eachProjecttask5.Name=pta5.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask5.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask5.pse__Order__c=75;
                                                        eachProjecttask5.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask5);               
                                            
                pse__Project_Task__c eachProjecttask6 = createProjectTaskfromIP(proj, pta6.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask6.NSP_Sub_Category__c=pta6.NSP_Sub_Category__c;
                                                        eachProjecttask6.Name=pta6.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Payroll_Project_Manager__c!=null && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask6.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask6.pse__Order__c=80;
                                                        eachProjecttask6.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask6);               
                                                    
                pse__Project_Task__c eachProjecttask7 = createProjectTaskfromIP(proj, pta7.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask7.NSP_Sub_Category__c=pta7.NSP_Sub_Category__c;
                                                        eachProjecttask7.Name=pta7.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask7.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask7.pse__Order__c=81;
                                                        eachProjecttask7.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask7);               
                                            
            
            pse__Project_Task__c eachProjecttask8 = createProjectTaskfromIP(proj, pta8.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask8.NSP_Sub_Category__c=pta8.NSP_Sub_Category__c;
                                                        eachProjecttask8.Name=pta8.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Payroll_Project_Manager__c!=null && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask8.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask8.pse__Order__c=82;
                                                        eachProjecttask8.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask8);   
                                                        
            pse__Project_Task__c eachProjecttask9 = createProjectTaskfromIP(proj, pta9.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask9.NSP_Sub_Category__c=pta9.NSP_Sub_Category__c;
                                                        eachProjecttask9.Name=pta9.NSP_Task_Name__c;
                                                        eachProjecttask9.pse__Order__c=83;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                        eachProjecttask9.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask9.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask9);  
                                            
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     public void createSubTaskForTimeStar(){
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_EMP_MM);
         NSP_ProjectTask_Automation__mdt pta1 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_EMP_SUB1_MM);
         NSP_ProjectTask_Automation__mdt pta2 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_EMP_SUB2_MM);
         NSP_ProjectTask_Automation__mdt pta3 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_EMP_SUB3_MM);
         NSP_ProjectTask_Automation__mdt pta4 =  NSP_ProjectTask_Automation__mdt.getInstance(TIMESTAR_TA_EMP_SUB4_MM);
       
         for(Id ipRecId : ipRecordsByAutomation.get(TIMESTAR_TA_EMP_MM)){
             Implementation_Profile__c ipRec = newIPs.get(ipRecId);
             if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
    
                
                    for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                        if(pt.Name==pta.NSP_Task_Name__c){
                           
                                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta1.NSP_Category__c, ipRecId,null);
                                                        eachProjecttask.NSP_Sub_Category__c=pta1.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta1.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Hierarchy_Depth__c=1;
                                                        eachProjecttask.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask.pse__Milestone__c=pt.pse__Milestone__c;
                                                        eachProjecttask.pse__Order__c = 76;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        projectTaskList.add(eachProjecttask);
                                
                                pse__Project_Task__c eachProjecttask1 = createProjectTaskfromIP(proj, pta2.NSP_Category__c, ipRecId,null);
                                                        eachProjecttask1.NSP_Sub_Category__c=pta2.NSP_Sub_Category__c;
                                                        eachProjecttask1.Name=pta2.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask1.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask1.pse__Hierarchy_Depth__c=2;
                                                        eachProjecttask1.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask1.pse__Milestone__c=pt.pse__Milestone__c;
                                                        eachProjecttask1.pse__Order__c = 77;
                                                        eachProjectTask1.NSP_Visible_to_Client__c=FALSE;
                                                        projectTaskList.add(eachProjecttask1); 
    
                                pse__Project_Task__c eachProjecttask2 = createProjectTaskfromIP(proj, pta3.NSP_Category__c, ipRecId,null);
                                                        eachProjecttask2.NSP_Sub_Category__c=pta3.NSP_Sub_Category__c;
                                                        eachProjecttask2.Name=pta3.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask2.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask2.pse__Hierarchy_Depth__c=3;
                                                        eachProjecttask2.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask2.pse__Milestone__c=pt.pse__Milestone__c;
                                                        eachProjecttask2.pse__Order__c = 78;
                                                        eachProjectTask2.NSP_Visible_to_Client__c=FALSE;
                                                        projectTaskList.add(eachProjecttask2); 
    
                                pse__Project_Task__c eachProjecttask3 = createProjectTaskfromIP(proj, pta4.NSP_Category__c, ipRecId,null);
                                                        eachProjecttask3.NSP_Sub_Category__c=pta4.NSP_Sub_Category__c;
                                                        eachProjecttask3.Name=pta4.NSP_Task_Name__c;
                                                    
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask3.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask3.pse__Hierarchy_Depth__c=4;
                                                        eachProjecttask3.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask3.pse__Milestone__c=pt.pse__Milestone__c;
                                                        eachProjecttask3.pse__Order__c = 79;
                                                        projectTaskList.add(eachProjecttask3);  
                            }
                        }
                 
             
                    }
                }
         
         childRecToInsert.addAll(getnewTaskstoInsert(projectTaskList));
     }
                     
         
     public void createProjectTaskForEEGarnishment(){
         //Do any EEs have garnishments? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(GARNISHMENT_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(GARNISHMENT_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(GARNISHMENT_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=84;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Payroll_Project_Manager__c!=null && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c)); 
         
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     public void createProjectTaskForTaxLevies(){
         //Do any EEs have tax levies?
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(TAX_LEVIES_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(TAX_LEVIES_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(TAX_LEVIES_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=85;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Payroll_Project_Manager__c!=null && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords)); 
     }
     
     public void createProjectTaskForPreTax(){
         //Pre-Tax is checked
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(PRE_TAX_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(PRE_TAX_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(PRE_TAX_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=86;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Payroll_Project_Manager__c!=null && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                        eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords)); 
     }
 
     public void createProjectTaskForPreTaxDeduct(){
         //Pre-Tax is checked
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(PRE_TAX_DEDUCT_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(PRE_TAX_DEDUCT_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(PRE_TAX_DEDUCT_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=87;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords)); 
     }
 
     public void createProjectTaskForPostTaxClient(){
         //Post-tax is checked Client Level
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(POST_TAX_SPONSPOREDPLAN_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(POST_TAX_SPONSPOREDPLAN_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(POST_TAX_SPONSPOREDPLAN_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=88;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Payroll_Project_Manager__c!=null && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                        eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords)); 
     }
 
     public void createProjectTaskForPostTaxEmp(){
         //Post-tax is checked Client Level
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(POST_TAX_EMPSETUP_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(POST_TAX_EMPSETUP_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(POST_TAX_EMPSETUP_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=89;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                                                        eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                    
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords)); 
     }
 
     public void createProjectTaskForExpenseAllowance(){
         //Post-tax is checked Client Level
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(ALLOWNCE_EXPENSE_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(ALLOWNCE_EXPENSE_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(ALLOWNCE_EXPENSE_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=NSP_ServiceConstants.SETUP+ipRec.Allowances__c+ ' '+ pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=90;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Payroll_Project_Manager__c!=null && ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                        eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Project_Manager__r.pse__Salesforce_User__c;
                                                        } 
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords)); 
     }
 
     public void createProjectTaskForRetirementPlan(){
         //What kind of retirement plan does client have today?
        
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(RETIRE_PLAN_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(RETIRE_PLAN_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=91;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                                                        eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
         
     }
     
     public void createProjectTaskForHSA(){
         //Does the client offer a HSA?
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(HSA_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(HSA_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(HSA_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=133;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                    
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
          
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     public void createProjectTaskForHSAOptum(){
         //Is client's current HSA with Optum Bank?
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(HSA_OPTUM_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(HSA_OPTUM_MM);
 
         
         for(Id ipRecId : ipRecordsByAutomation.get(HSA_OPTUM_MM)){
          
                    Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                    if(isRerun || ipRec.NSP_Form_Completed__c){
                        pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                        Id milestoneId;
                        for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                            if(pt.Name==NSP_ServiceConstants.HSA){
                                                    
                                    milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                                    String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                                    if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                                        pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                                        mileStonesToInsert.put(milestoneKey, eachMilestone);
                                    }
                                                                
                                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                                            eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                                            eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                                            if(mapofGroupIds.containsKey(NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT)!=null){
                                                                                eachProjecttask.OwnerId=mapofGroupIds.get(NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT);
                                                                            }
                                                                            eachProjecttask.pse__Hierarchy_Depth__c=1;
                                                                            eachProjecttask.pse__Milestone__c=milestoneId;
                                                                            eachProjecttask.pse__Parent_Task__c=pt.Id;
                                                                            eachProjecttask.pse__Order__c = 134;
                                                                            eachProjecttask.NSP_Visible_to_Client__c = FALSE;
                                                                            projectTaskList.add(eachProjecttask); 
                            }
                        }  
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));            
                                          
         
                }
            }
                //check for existing project task and store the new tasks
                childRecToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                childRecToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords)); 
     }
     
     public void createProjectTaskForNoHSA(){
         //Is client's current HSA with Optum Bank? = No
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(HSA_OPTUM_NO_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(HSA_OPTUM_NO_MM);
 
 
         for(Id ipRecId : ipRecordsByAutomation.get(HSA_OPTUM_NO_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj); 
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }                        
                for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                    if(pt.Name==NSP_ServiceConstants.HEALTH_SAVING){
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Hierarchy_Depth__c=2;
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
                                                        eachProjecttask.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask.pse__Order__c = 135;
                                                        eachProjecttask.NSP_Visible_to_Client__c = FALSE;
    
                                                        projectTaskList.add(eachProjecttask);  
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                    }
                }
         
            }
        }
                //check for existing project task and store the new tasks
                childRecToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                childRecToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));   
         
     }
     
     
     public void createProjectTaskForCOBRA(){
         //Are there any participants on COBRA or in the eligibility period? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(COBRA_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(COBRA_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj); 
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }                         
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=136;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                
            }                              
        }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }

     public void createSubTaskForCobra(){
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_MM);
        NSP_ProjectTask_Automation__mdt pta1 =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_GUIDELINES_MM);
        NSP_ProjectTask_Automation__mdt pta2 =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_TEAM_MM);
        NSP_ProjectTask_Automation__mdt pta3 =  NSP_ProjectTask_Automation__mdt.getInstance(COBRA_PACKETS_MM);
      
        for(Id ipRecId : ipRecordsByAutomation.get(COBRA_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                    pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                    Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);

                    
                        for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                            if(pt.Name==pta.NSP_Task_Name__c){
                            
                                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta1.NSP_Category__c, ipRecId,null);
                                                        eachProjecttask.NSP_Sub_Category__c=pta1.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta1.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Hierarchy_Depth__c =1;
                                                        eachProjecttask.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask.pse__Milestone__c=pt.pse__Milestone__c;
                                                        eachProjecttask.pse__Order__c=137;
                                                        projectTaskList.add(eachProjecttask);
                                    
                                    pse__Project_Task__c eachProjecttask1 = createProjectTaskfromIP(proj, pta2.NSP_Category__c, ipRecId,null);
                                                        eachProjecttask1.NSP_Sub_Category__c=pta2.NSP_Sub_Category__c;
                                                        eachProjecttask1.Name=pta2.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask1.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask1.pse__Hierarchy_Depth__c =2;
                                                        eachProjecttask1.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask1.pse__Milestone__c=pt.pse__Milestone__c;
                                                        eachProjecttask1.pse__Order__c=138;
                                                        projectTaskList.add(eachProjecttask1); 

                                    pse__Project_Task__c eachProjecttask2 = createProjectTaskfromIP(proj, pta3.NSP_Category__c, ipRecId,null);
                                                        eachProjecttask2.NSP_Sub_Category__c=pta3.NSP_Sub_Category__c;
                                                        eachProjecttask2.Name=pta3.NSP_Task_Name__c;
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                                eachProjecttask2.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask2.pse__Hierarchy_Depth__c =3;
                                                        eachProjecttask2.pse__Parent_Task__c=pt.Id;
                                                        eachProjecttask2.pse__Milestone__c=pt.pse__Milestone__c;
                                                        eachProjecttask2.pse__Order__c=139;
                                                        projectTaskList.add(eachProjecttask2); 

                                
                                }
                            }
                        
                }
        }
        
        childRecToInsert.addAll(getnewTaskstoInsert(projectTaskList));
    }
     
     public void createProjectTaskForDeducibleCarryover(){
         //Check when you have reviewed the deductible carryover process with the client
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(DEDUCIBLE_CARRYOVER_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(DEDUCIBLE_CARRYOVER_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(DEDUCIBLE_CARRYOVER_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=140;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);  
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
            }  
                                          
          }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
         
     }
     
     public void createProjectTaskForEEMedical(){
         //Are there any EEs with urgent medical needs? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(EE_MEDICAL_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(EE_MEDICAL_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(EE_MEDICAL_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=141;

                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
         
                }
            }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
         
     }
     
     public void createProjectTaskForEEWaiting(){
         //Are there any EEs in clients waiting period?
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(WAITING_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(WAITING_MM);
 
         
         for(Id ipRecId : ipRecordsByAutomation.get(WAITING_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=142;
                                                        eachProjectTask.NSP_Visible_to_Client__c=False;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
               
           
            }
        }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }

     public void createProjectTaskForDependentCare(){
        //Dependent Care Flexible Spending Account is checked 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
       
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(DEPENDENT_CARE_MM);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(DEPENDENT_CARE_MM);

        
        for(Id ipRecId : ipRecordsByAutomation.get(DEPENDENT_CARE_MM)){
           Implementation_Profile__c ipRec = newIPs.get(ipRecId);
           if(isRerun || ipRec.NSP_Form_Completed__c){
            pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
            Id milestoneId;
                                            
            milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
            String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                    eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                    eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                    eachProjecttask.pse__Order__c=146;
                                                    Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                    if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                        eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                    }
                                                    
                                                    eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                    projectTaskList.add(eachProjecttask); 
                ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
              
                                         
         
            }
        }
               //check for existing project task and store the new tasks
               recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
               //check for existing Automation record and store the new Automation records
               recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
    }

    public void createProjectTaskForHealthCare(){
        //and Health Care Flexible Spend Account is checked 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
       
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(HEALTH_CARE_MM);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(HEALTH_CARE_MM);

        
        for(Id ipRecId : ipRecordsByAutomation.get(HEALTH_CARE_MM)){
           Implementation_Profile__c ipRec = newIPs.get(ipRecId);
           if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                                
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                                
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=147;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
        
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
             }
         
                
         }
               //check for existing project task and store the new tasks
               recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
               //check for existing Automation record and store the new Automation records
               recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
    }

    public void createProjectTaskForOtherPretax(){
        //and Health Care Flexible Spend Account is checked 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
       
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(OTHER_PRETAX_TYPE_MM);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(OTHER_PRETAX_TYPE_MM);

        
        for(Id ipRecId : ipRecordsByAutomation.get(OTHER_PRETAX_TYPE_MM)){
           Implementation_Profile__c ipRec = newIPs.get(ipRecId);
           if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                                
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                                
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=148;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
        
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
           }  
                                         
         }
               //check for existing project task and store the new tasks
               recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
               //check for existing Automation record and store the new Automation records
               recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
    }
     
    public void createProjectTaskForPostDeductions(){
         //Does the client have any post-tax deductions 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(POST_DEDUCTION_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(POST_DEDUCTION_MM);
 
 
         for(Id ipRecId : ipRecordsByAutomation.get(POST_DEDUCTION_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=149;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__c!=null && ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Sr_Onboarding_Benefit_Rep__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
                ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
          
            }
        }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }

     public void createProjectTaskForHRHandbook(){
        //and Health Care Flexible Spend Account is checked 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
       
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(HANDBOOK_DEVELOPMENT_MM);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(HANDBOOK_DEVELOPMENT_MM);
        
        for(Id ipRecId : ipRecordsByAutomation.get(HANDBOOK_DEVELOPMENT_MM)){
           Implementation_Profile__c ipRec = newIPs.get(ipRecId);
           if(isRerun || ipRec.NSP_Form_Completed__c){
            pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
            Id milestoneId;
                                            
            milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
            String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                    eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                    eachProjecttask.Name=pta.NSP_Task_Name__c;
               										eachProjecttask.pse__Order__c=166;
                                                    Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                    if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                        eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                    }
                                                    
                                                    eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                    projectTaskList.add(eachProjecttask);
                                                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                         
         
                                                }
                                            }
               //check for existing project task and store the new tasks
               recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
               //check for existing Automation record and store the new Automation records
               recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
    }

    public void createProjectTaskForHRJobDescription(){
        //Job Descriptions selected
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
       
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(JOBDESCRIPTION_MM);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(JOBDESCRIPTION_MM);
        
        for(Id ipRecId : ipRecordsByAutomation.get(JOBDESCRIPTION_MM)){
           Implementation_Profile__c ipRec = newIPs.get(ipRecId);
           if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                                
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                                
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
               											eachProjecttask.pse__Order__c=167;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
        
                                                        projectTaskList.add(eachProjecttask);
                                                        ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));                              
                                         
             }
        }
               //check for existing project task and store the new tasks
               recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
               //check for existing Automation record and store the new Automation records
               recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
    }

    public void createProjectTaskForHRSeverance(){
        //Employment/Severance Agreements selected
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
       
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(SEVERANCEAGREEMENT_MM);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SEVERANCEAGREEMENT_MM);

        
        for(Id ipRecId : ipRecordsByAutomation.get(SEVERANCEAGREEMENT_MM)){
           Implementation_Profile__c ipRec = newIPs.get(ipRecId);
           if(isRerun || ipRec.NSP_Form_Completed__c){
            pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
            Id milestoneId;
                                            
            milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
            String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                    eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                    eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                    eachProjecttask.pse__Order__c=168;
                                                    Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                    if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                        eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                    }
                                                    
                                                    eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                    projectTaskList.add(eachProjecttask); 
                                                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c)); 
            }              
                                         
         }
               //check for existing project task and store the new tasks
               recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
               //check for existing Automation record and store the new Automation records
               recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
    }
     
     public void createProjectTaskForRetirementPlans(){
         //What kind of retirement plan does client have today? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLANORK_MM);
         NSP_ProjectTask_Automation__mdt pta1 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_ORK_CLIENT_MM);
         NSP_ProjectTask_Automation__mdt pta2 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_ORK_401K_MM);
         NSP_ProjectTask_Automation__mdt pta3 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_401K_DEF_MM);
         NSP_ProjectTask_Automation__mdt pta4 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_401K_EMP_MM);
         NSP_ProjectTask_Automation__mdt pta5 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_401K_DEF_UP_MM);
         NSP_ProjectTask_Automation__mdt pta6 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_401K_LOAN_MM);
         NSP_ProjectTask_Automation__mdt pta7 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_401K_YTD_MM);
         NSP_ProjectTask_Automation__mdt pta8 =  NSP_ProjectTask_Automation__mdt.getInstance(RETIRE_PLAN_401K_YTD_UP_MM);
 
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(RETIRE_PLANORK_MM);
 
 
         
         
         for(Id ipRecId : ipRecordsByAutomation.get(RETIRE_PLANORK_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
    
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=150;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjectTask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
                
                pse__Project_Task__c eachProjecttask1 = createProjectTaskfromIP(proj, pta1.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask1.NSP_Sub_Category__c=pta1.NSP_Sub_Category__c;
                                                        eachProjecttask1.Name=pta1.NSP_Task_Name__c;
                                                        eachProjecttask1.pse__Order__c=151;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask1.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask1.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask1);               
                                            
            
                pse__Project_Task__c eachProjecttask2 = createProjectTaskfromIP(proj, pta2.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask2.NSP_Sub_Category__c=pta2.NSP_Sub_Category__c;
                                                        eachProjecttask2.Name=pta2.NSP_Task_Name__c;
                                                        eachProjecttask2.pse__Order__c=152;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask2.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask2.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask2);               
                                                    
                pse__Project_Task__c eachProjecttask3 = createProjectTaskfromIP(proj, pta3.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask3.NSP_Sub_Category__c=pta3.NSP_Sub_Category__c;
                                                        eachProjecttask3.Name=pta3.NSP_Task_Name__c;
                                                        eachProjecttask3.pse__Order__c=153;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask3.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask3.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask3);               
                                                    
                pse__Project_Task__c eachProjecttask4 = createProjectTaskfromIP(proj, pta4.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask4.NSP_Sub_Category__c=pta4.NSP_Sub_Category__c;
                                                        eachProjecttask4.Name=pta4.NSP_Task_Name__c;
                										eachProjecttask4.pse__Order__c=154;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask4.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask4.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask4);               
                                                    
                pse__Project_Task__c eachProjecttask5 = createProjectTaskfromIP(proj, pta5.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask5.NSP_Sub_Category__c=pta5.NSP_Sub_Category__c;
                                                        eachProjecttask5.Name=pta5.NSP_Task_Name__c;
                                                        eachProjecttask5.pse__Order__c=155;
                                                        eachProjectTask5.NSP_Visible_to_Client__c=FALSE;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask5.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask5.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask5);               
                                                    
                pse__Project_Task__c eachProjecttask6 = createProjectTaskfromIP(proj, pta6.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask6.NSP_Sub_Category__c=pta6.NSP_Sub_Category__c;
                                                        eachProjecttask6.Name=pta6.NSP_Task_Name__c;
                                                        eachProjecttask6.pse__Order__c=156;
                                                        eachProjectTask6.NSP_Visible_to_Client__c=FALSE;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask6.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask6.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask6);               
                                                    
            pse__Project_Task__c eachProjecttask7 = createProjectTaskfromIP(proj, pta7.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask7.NSP_Sub_Category__c=pta7.NSP_Sub_Category__c;
                                                        eachProjecttask7.Name=pta7.NSP_Task_Name__c;
                                                        eachProjecttask7.pse__Order__c=157;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask7.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask7.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask7);               
                                                    
            pse__Project_Task__c eachProjecttask8 = createProjectTaskfromIP(proj, pta8.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask8.NSP_Sub_Category__c=pta8.NSP_Sub_Category__c;
                                                        eachProjecttask8.Name=pta8.NSP_Task_Name__c;
                                                        eachProjecttask8.pse__Order__c=158;
                                                        eachProjectTask8.NSP_Visible_to_Client__c=FALSE;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask8.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask8.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask8);               
                                            
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
     
                }
            }
                 //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     public void createProjectTaskFor401K(){
         //If Would client like to begin set-up of 401K plan with NSP? = Yes OR
         //What kind of retirement plan does client have today? = PEO Multiple Employer Plan (MEP) or CSP 401k 
         
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(NSP401K_MM);
         NSP_ProjectTask_Automation__mdt pta1 =  NSP_ProjectTask_Automation__mdt.getInstance(NSP401K_CLIENT_MM);
         NSP_ProjectTask_Automation__mdt pta2 =  NSP_ProjectTask_Automation__mdt.getInstance(NSP401K_ELECTION_MM);
         NSP_ProjectTask_Automation__mdt pta3 =  NSP_ProjectTask_Automation__mdt.getInstance(NSP401K_CLIENT_MATCH_MM);
         NSP_ProjectTask_Automation__mdt pta4 =  NSP_ProjectTask_Automation__mdt.getInstance(NSP401K_PLAN_MM);
         NSP_ProjectTask_Automation__mdt pta5 =  NSP_ProjectTask_Automation__mdt.getInstance(NSP401K_COLLECT_MM);
         NSP_ProjectTask_Automation__mdt pta6 =  NSP_ProjectTask_Automation__mdt.getInstance(NSP401K_EMP_TRAIN_MM);
 
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(NSP401K_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(NSP401K_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                    
                milestoneId=getMilestoneId(proj?.pse__Milestones__r,pta?.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                                                        eachProjecttask.pse__Order__c=159;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                                        
                pse__Project_Task__c eachProjecttask1 = createProjectTaskfromIP(proj, pta1.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask1.NSP_Sub_Category__c=pta1.NSP_Sub_Category__c;
                                                        eachProjecttask1.Name=pta1.NSP_Task_Name__c;
                                                        eachProjecttask1.pse__Order__c=160;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask1.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask1.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask1);                                 
            
            
                pse__Project_Task__c eachProjecttask2 = createProjectTaskfromIP(proj, pta2.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask2.NSP_Sub_Category__c=pta2.NSP_Sub_Category__c;
                                                        eachProjecttask2.Name=pta2.NSP_Task_Name__c;
                                                        eachProjecttask2.pse__Order__c=161;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask2.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask2.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask2);               
                                                    
                pse__Project_Task__c eachProjecttask3 = createProjectTaskfromIP(proj, pta3.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask3.NSP_Sub_Category__c=pta3.NSP_Sub_Category__c;
                                                        eachProjecttask3.Name=pta3.NSP_Task_Name__c;
                                                        eachProjecttask3.pse__Order__c=162;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask3.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask3.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask3);               
                                                    
                pse__Project_Task__c eachProjecttask4 = createProjectTaskfromIP(proj, pta4.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask4.NSP_Sub_Category__c=pta4.NSP_Sub_Category__c;
                                                        eachProjecttask4.Name=pta4.NSP_Task_Name__c;
                										eachProjecttask4.pse__Order__c=163;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask4.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask4.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask4);               
                                                    
                pse__Project_Task__c eachProjecttask5 = createProjectTaskfromIP(proj, pta5.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask5.NSP_Sub_Category__c=pta5.NSP_Sub_Category__c;
                                                        eachProjecttask5.Name=pta5.NSP_Task_Name__c;
                										eachProjecttask5.pse__Order__c=164;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask5.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask5.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask5);               
                                                    
                pse__Project_Task__c eachProjecttask6 = createProjectTaskfromIP(proj, pta6.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask6.NSP_Sub_Category__c=pta6.NSP_Sub_Category__c;
                                                        eachProjecttask6.Name=pta6.NSP_Task_Name__c;
                                                        eachProjecttask6.pse__Order__c=165;
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask6.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask6.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask6); 
    
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
               
             
                }
            }		
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     public void createProjectTaskForSubstanceAbuse(){
         //Does the client have any of the following
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(SUBSTANCE_ABUSE_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SUBSTANCE_ABUSE_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(SUBSTANCE_ABUSE_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                										eachProjecttask.pse__Order__c=169;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);
                ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                                              
          
            }
        }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     public void createProjectTaskForStandardOffer(){
         //Does the client have any of the following = Standard Offer Letter
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(STANDARD_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(STANDARD_MM);
 
 
         for(Id ipRecId : ipRecordsByAutomation.get(STANDARD_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                										eachProjecttask.pse__Order__c=170;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);  
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));             
                                          
         
             }
        }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     public void createProjectTaskForBackgroundCheck(){
         //Does the client perform background checks? = Yes
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(BACKGROUND_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(BACKGROUND_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(BACKGROUND_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                										eachProjecttask.pse__Order__c=171;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);               
                                            
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));   
            }
                
        }    //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));   
     }
     
     public void createProjectTaskForDrugScreening(){
         //If Does the client perform pre-employment drug screening? 
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(DRUG_SCREENING_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(DRUG_SCREENING_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(DRUG_SCREENING_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);  
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }                        
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                										eachProjecttask.pse__Order__c=172;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_HR_Specialist__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                    ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));              
                                          
          
            }
        }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords)); 
     }
     
     public void createProjectTaskForEmploymentScreening(){
         //Select BPSes = Employment Screening
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(SCREENING_BPS_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(SCREENING_BPS_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(SCREENING_BPS_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);  
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }                         
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                										eachProjecttask.pse__Order__c=184;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                                                        ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
               
                                                    }                              
          }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }

     public void createProjectTaskForCertify(){
        //Select BPSes = Employment Screening
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(CERTIFY_BPS_MM);
        NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(CERTIFY_BPS_MM);
        for(Id ipRecId : ipRecordsByAutomation.get(CERTIFY_BPS_MM)){
           Implementation_Profile__c ipRec = newIPs.get(ipRecId);
           if(isRerun || ipRec.NSP_Form_Completed__c){
            pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
            Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj); 
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }                          
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                    eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                    eachProjecttask.Name=pta.NSP_Task_Name__c;
               										eachProjecttask.pse__Order__c=185;
                                                    eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                    Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                    }
                                                    eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                    projectTaskList.add(eachProjecttask); 
                									ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
               
                                                }             
                                         
         }
               //check for existing project task and store the new tasks
               recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
               //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
    }
     
     
     public void createProjectTaskForPerformanceManagement(){
         //Select BPSes = Performance Management
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(PERFORMANCE_BPS_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(PERFORMANCE_BPS_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(PERFORMANCE_BPS_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                										eachProjecttask.pse__Order__c=186;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);
                                                        ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                                                    }
                                          
          }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     public void createProjectTaskForOrganizationalPlanning(){
         //Select BPSes = Organizational Planning
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(ORGANIZATIONAL_BPS_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(ORGANIZATIONAL_BPS_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(ORGANIZATIONAL_BPS_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                										eachProjecttask.pse__Order__c=187;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);
                                                        ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                                                    }  
          }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     public void createProjectTaskForInsuranceServices(){
         //Select BPSes = Insurance Services
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(INSURANCE_BPS_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(INSURANCE_BPS_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(INSURANCE_BPS_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                										eachProjecttask.pse__Order__c=188;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask); 
                                                        ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                                                    }
         }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
 
     public void createProjectTaskForRecruitingServices(){
         //Select BPSes = Recruiting Services
         List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
         List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
         
         NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(RECRUITING_BPS_MM);
         NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(RECRUITING_BPS_MM);
 
         for(Id ipRecId : ipRecordsByAutomation.get(RECRUITING_BPS_MM)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if(isRerun || ipRec.NSP_Form_Completed__c){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                                            
                milestoneId=getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c, proj);
                String milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=pta.NSP_Milestone__c, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                                            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, pta.NSP_Category__c, ipRecId,milestoneKey);
                                                        eachProjecttask.NSP_Sub_Category__c=pta.NSP_Sub_Category__c;
                                                        eachProjecttask.Name=pta.NSP_Task_Name__c;
                										eachProjecttask.pse__Order__c = 189;
                                                        eachProjectTask.NSP_Visible_to_Client__c=FALSE;
                                                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                                        }
                                                        eachProjecttask.pse__Milestone__c=milestoneId;
    
                                                        projectTaskList.add(eachProjecttask);
                                                        ipAutomationRecords.add(createIPAutomation(ipRec, ipa.NSP_Automation_Name__c, ipa.NSP_Method_Name__c,ipa.NSP_Section__c));
                                                    }
                                          
          }
                //check for existing project task and store the new tasks
                recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
                //check for existing Automation record and store the new Automation records
                recToInsert.addAll(getnewAutomationListtoInsert(ipAutomationRecords));
     }
     
     
     private  void checkforPayrollRegister(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || (newRec.Recent_Payroll_Register_Collected__c != NSP_ServiceConstants.NO && newRec.Recent_Payroll_Register_Collected__c != NSP_ServiceConstants.NOTCOLLECTED) ) {
            return;
         }
 
   
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
           (newRec.Recent_Payroll_Register_Collected__c==NSP_ServiceConstants.NO ||newRec.Recent_Payroll_Register_Collected__c == NSP_ServiceConstants.NOTCOLLECTED)){
             if(existingRec == null || newRec.NSP_Form_Completed__c ||
                newRec.Recent_Payroll_Register_Collected__c != existingRec.Recent_Payroll_Register_Collected__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_REGISTER_MM);
             }
         }
     }
     
     private void checkforSectionQuestionnaire(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if(newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || (newRec.Received_Section_125_Questionnaire__c != NSP_ServiceConstants.NO && newRec.Received_Section_125_Questionnaire__c != NSP_ServiceConstants.NOTCOLLECTED) ) {
            return;
         }
         
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
         (newRec.Received_Section_125_Questionnaire__c==NSP_ServiceConstants.NO ||newRec.Received_Section_125_Questionnaire__c == NSP_ServiceConstants.NOTCOLLECTED)){
             if(existingRec == null || newRec.NSP_Form_Completed__c ||
                newRec.Received_Section_125_Questionnaire__c != existingRec.Received_Section_125_Questionnaire__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SECTION_QUESTIONNAIRE_MM);
             }
         }
     }
     
     private void checkforFEINDocument(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || (newRec.Has_FEIN_documentation_been_collected__c!= NSP_ServiceConstants.NO && newRec.Has_FEIN_documentation_been_collected__c != NSP_ServiceConstants.NOTCOLLECTED) ) {
            return;
         }
         
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
          (newRec.Has_FEIN_documentation_been_collected__c==NSP_ServiceConstants.NO ||newRec.Has_FEIN_documentation_been_collected__c == NSP_ServiceConstants.NOTCOLLECTED)){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Has_FEIN_documentation_been_collected__c != existingRec.Has_FEIN_documentation_been_collected__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, FEIN_DOCUMENT_COLLECTED_MM);
             }
         }
     }
     
     private  void checkforReceivedCertificate(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c != NSP_ServiceConstants.REQUESTED) {
            return;
         }
 
   
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
         newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c==NSP_ServiceConstants.REQUESTED){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c != existingRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, GENERAL_LIABILITY_MM);
             }
         }
     }
     
     private  void checkforPTO(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if(newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Client_interested_in_NSP_tracking_PTO__c!= NSP_ServiceConstants.YES
            || newRec.PTO_Types__c!=NSP_ServiceConstants.AIMS) {
            return;
         }
 
   
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
         newRec.Client_interested_in_NSP_tracking_PTO__c== NSP_ServiceConstants.YES && newRec.PTO_Types__c==NSP_ServiceConstants.AIMS){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Client_interested_in_NSP_tracking_PTO__c != existingRec.Client_interested_in_NSP_tracking_PTO__c
                ||newRec.PTO_Types__c != existingRec.PTO_Types__c
                ||newRec.Client_utilizing_Insperity_s_TimeStar__c != existingRec.Client_utilizing_Insperity_s_TimeStar__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PTO_MM);
             }
         }
     }
     
     private void checkforSeasonalEE(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if(newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Client_have_will_have_any_Seasonal_EEs__c != NSP_ServiceConstants.YES) {
            return;
         }
 
   
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
         newRec.Client_have_will_have_any_Seasonal_EEs__c==NSP_ServiceConstants.YES){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Client_have_will_have_any_Seasonal_EEs__c != existingRec.Client_have_will_have_any_Seasonal_EEs__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SEASONAL_EE_MM);
             }
         }
     }
     
     private  void checkforUnionEE(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Does_the_client_have_any_union_EEs__c != NSP_ServiceConstants.YES) {
            return;
         }
 
   
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
         newRec.Does_the_client_have_any_union_EEs__c==NSP_ServiceConstants.YES){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Does_the_client_have_any_union_EEs__c != existingRec.Does_the_client_have_any_union_EEs__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EEO_FILING_MM);
             }
         }
     }
     
     private  void checkforEEOnLeave(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Are_there_any_EEs_on_Leave_of_Absence__c != NSP_ServiceConstants.YES) {
            return;
         }
 
   
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
           newRec.Are_there_any_EEs_on_Leave_of_Absence__c==NSP_ServiceConstants.YES){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Are_there_any_EEs_on_Leave_of_Absence__c != existingRec.Are_there_any_EEs_on_Leave_of_Absence__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EEO_ON_LEAVE_MM);
             }
         }
     }
     
     private void checkforLOATypes(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null ||
         newRec.Select_the_applicable_LOA_types__c==null ||
           (!newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.MILITARY_LEAVE) 
           && !newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.WORKER)
           && !newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.FMLA_STATUS) )) {
           return;
        } 
        if( newRec.RecordTypeId == ipMMRecordTypeId && 
          (newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.MILITARY_LEAVE)  
          || newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.FMLA_STATUS)  
           || newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.WORKER))){
               if(existingRec == null ||  newRec.NSP_Form_Completed__c ||
                  newRec.Select_the_applicable_LOA_types__c != existingRec.Select_the_applicable_LOA_types__c
                  || newRec.Select_the_applicable_LOA_types__c != existingRec.Select_the_applicable_LOA_types__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, LOA_TYPES_MM);
                  }
           }
    }
     
    private void checkforLOAGreaterThan(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null
           ||  newRec.Select_the_applicable_LOA_types__c ==null || 
           !newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.GREATER_THAN)){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId && 
          newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.GREATER_THAN)){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
             newRec.Select_the_applicable_LOA_types__c != existingRec.Select_the_applicable_LOA_types__c){
                updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, LOA_GREATER_THAN_MM);
            }
        }
    }
     
     private void checkforLOASalaryContinuation(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null || newRec.Select_the_applicable_LOA_types__c==null
           || !newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.SALARY) 
           ){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId && 
        newRec.Select_the_applicable_LOA_types__c.contains(NSP_ServiceConstants.SALARY)){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
             newRec.Select_the_applicable_LOA_types__c != existingRec.Select_the_applicable_LOA_types__c){
                updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SALARY_CONT_MM);
            }
        }
    }
     
     private void checkforPostTaxDeductions(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if(newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null
            || newRec.Client_has_any_post_tax_deductions__c != NSP_ServiceConstants.Yes){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
            newRec.Client_has_any_post_tax_deductions__c == NSP_ServiceConstants.Yes){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
              newRec.Client_has_any_post_tax_deductions__c != existingRec.Client_has_any_post_tax_deductions__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POST_TAX_MM);
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POST_DEDUCTION_MM);
             }
         }
     }
     
     private void checkforTimeStar(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if(newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null
            || newRec.Client_utilizing_Insperity_s_TimeStar__c != NSP_ServiceConstants.Yes){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
           newRec.Client_utilizing_Insperity_s_TimeStar__c == NSP_ServiceConstants.Yes){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
             newRec.Client_utilizing_Insperity_s_TimeStar__c != existingRec.Client_utilizing_Insperity_s_TimeStar__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, TIMESTAR_MM);
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, TIMESTAR_TA_EMP_MM);
             }
         }
     }
     
     private  void checkforGarnishments(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Do_any_EEs_have_garnishments__c != NSP_ServiceConstants.YES  ) {
            return;
         }
 
   
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
            newRec.Do_any_EEs_have_garnishments__c==NSP_ServiceConstants.YES ){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Do_any_EEs_have_garnishments__c != existingRec.Do_any_EEs_have_garnishments__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, GARNISHMENT_MM);
             }
         }
     }
     
     private  void checkforTaxLevies(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Do_any_EEs_have_tax_levies__c != NSP_ServiceConstants.YES  ) {
            return;
         }
 
   
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
            newRec.Do_any_EEs_have_tax_levies__c==NSP_ServiceConstants.YES ){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Do_any_EEs_have_tax_levies__c != existingRec.Do_any_EEs_have_tax_levies__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, TAX_LEVIES_MM);
             }
         }
     }
     private  void checkforRetPlan(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            ||( newRec.Type_of_retirement_plan_client_has_today__c != NSP_ServiceConstants.CSP401K
            && newRec.Type_of_retirement_plan_client_has_today__c != NSP_ServiceConstants.SIMPLEIRA
            && newRec.Type_of_retirement_plan_client_has_today__c != NSP_ServiceConstants.CLIENTB
            && newRec.Type_of_retirement_plan_client_has_today__c != NSP_ServiceConstants.UNIDENTIFIED_ORK ) ){
            return;
         }
 
   
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
           (newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.CSP401K
            || newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.SIMPLEIRA
            || newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.CLIENTB
            || newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.UNIDENTIFIED_ORK )){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Type_of_retirement_plan_client_has_today__c != existingRec.Type_of_retirement_plan_client_has_today__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, RETIRE_PLAN_MM);
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, RETIRE_PLANORK_MM);
             }
         }
     }
     private void checkforHSA(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Does_the_client_offer_a_HSA__c != NSP_ServiceConstants.Yes){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
           newRec.Does_the_client_offer_a_HSA__c == NSP_ServiceConstants.Yes){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Does_the_client_offer_a_HSA__c != existingRec.Does_the_client_offer_a_HSA__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HSA_MM);
             }
         }   
     }
     private void checkforHSAOptum(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Is_client_s_current_HSA_with_Optum_Bank__c	 != NSP_ServiceConstants.Yes){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
           newRec.Is_client_s_current_HSA_with_Optum_Bank__c == NSP_ServiceConstants.Yes){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Is_client_s_current_HSA_with_Optum_Bank__c != existingRec.Is_client_s_current_HSA_with_Optum_Bank__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HSA_OPTUM_MM);
             }
         }   
     }
     private void checkforNoHSAOptum(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Is_client_s_current_HSA_with_Optum_Bank__c	 != NSP_ServiceConstants.No){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
           newRec.Is_client_s_current_HSA_with_Optum_Bank__c == NSP_ServiceConstants.No){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Is_client_s_current_HSA_with_Optum_Bank__c != existingRec.Is_client_s_current_HSA_with_Optum_Bank__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HSA_OPTUM_NO_MM);
             }
         }   
     }
     private void checkforCOBRA(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Participants_on_COBRA_eligibility_period__c	 != NSP_ServiceConstants.Yes){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
           newRec.Participants_on_COBRA_eligibility_period__c == NSP_ServiceConstants.Yes){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Participants_on_COBRA_eligibility_period__c != existingRec.Participants_on_COBRA_eligibility_period__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, COBRA_MM);
             }
         }   
     }
     private void checkforDeducibleCarryover(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || !newRec.Reviewed_deductible_carryover_w_client__c){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
            newRec.Reviewed_deductible_carryover_w_client__c){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Reviewed_deductible_carryover_w_client__c != existingRec.Reviewed_deductible_carryover_w_client__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, DEDUCIBLE_CARRYOVER_MM);
             }
         }   
     }
     private void checkforEEMedical(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Any_EEs_with_urgent_medical_needs__c	 != NSP_ServiceConstants.Yes){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
            newRec.Any_EEs_with_urgent_medical_needs__c == NSP_ServiceConstants.Yes){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Any_EEs_with_urgent_medical_needs__c != existingRec.Any_EEs_with_urgent_medical_needs__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EE_MEDICAL_MM);
             }
         }   
     }
     private void checkforWaitingPeriod(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        
        if(newRec.Insperity_benefits_waiting_period__c!=null && newRec.Client_s_previous_waiting_period__c!=null ) {
            String [] inspPeriod = newRec.Insperity_benefits_waiting_period__c.split(' ');
            String [] clientPeriod = newRec.Client_s_previous_waiting_period__c.split(' ');
 
                if( newRec.RecordTypeId == ipMMRecordTypeId &&
                newRec.Any_EEs_in_clients_waiting_period__c == NSP_ServiceConstants.Yes &&
                    Integer.ValueOf(inspPeriod[0])> Integer.ValueOf(clientPeriod[0])){
        
                    if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                        newRec.Any_EEs_in_clients_waiting_period__c != existingRec.Any_EEs_in_clients_waiting_period__c
                        || newRec.Insperity_benefits_waiting_period__c != existingRec.Insperity_benefits_waiting_period__c
                        || newRec.Client_s_previous_waiting_period__c != existingRec.Client_s_previous_waiting_period__c){
                        updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, WAITING_MM);
                    }
                }
        }   
     }
 
 
     private void checkfor401KPlan(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
            (newRec.Client_want_to_begin_401k_w_NSP_setup__c == NSP_ServiceConstants.Yes
            ||(newRec.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.PEOMULTIPLIER
            || newRec.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.CSP401KNSP))){
 
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Client_want_to_begin_401k_w_NSP_setup__c != existingRec.Client_want_to_begin_401k_w_NSP_setup__c
                || newRec.Type_of_retirement_plan_client_has_today__c != existingRec.Type_of_retirement_plan_client_has_today__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, NSP401K_MM);
             }
         }   
     }
     
     private void checkforSubstanceAbuse(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null ||newRec.Client_has_any_of_the_following__c ==null 
           || !newRec.Client_has_any_of_the_following__c.contains( NSP_ServiceConstants.SUBSTANCE) ){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId &&
           newRec.Client_has_any_of_the_following__c.contains( NSP_ServiceConstants.SUBSTANCE)){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
               newRec.Client_has_any_of_the_following__c != existingRec.Client_has_any_of_the_following__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SUBSTANCE_ABUSE_MM);
            }
        }   
    }
    private void checkforStandardOffer(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Client_has_any_of_the_following__c==null || !newRec.Client_has_any_of_the_following__c.contains(NSP_ServiceConstants.STANDARD_LETTER) ){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId && 
          newRec.Client_has_any_of_the_following__c.contains(NSP_ServiceConstants.STANDARD_LETTER)){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
               newRec.Client_has_any_of_the_following__c != existingRec.Client_has_any_of_the_following__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, STANDARD_MM);
            }
        }   
    }
     private void checkforBackground(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Does_client_perform_background_checks__c != NSP_ServiceConstants.Yes){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
            newRec.Does_client_perform_background_checks__c == NSP_ServiceConstants.Yes){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Does_client_perform_background_checks__c != existingRec.Does_client_perform_background_checks__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, BACKGROUND_MM);
             }
         }   
     }
     private void checkforDrugScreening(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         if(newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
            || newRec.Client_does_pre_employment_drug_screen__c != NSP_ServiceConstants.Yes){
                return;
            }
         if( newRec.RecordTypeId == ipMMRecordTypeId && 
            newRec.Client_does_pre_employment_drug_screen__c == NSP_ServiceConstants.Yes){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Client_does_pre_employment_drug_screen__c != existingRec.Client_does_pre_employment_drug_screen__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, DRUG_SCREENING_MM);
             }
         }   
     }
     private void checkforScreeningBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Select_BPSes__c==null){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId && 
          newRec.Select_BPSes__c.contains(NSP_ServiceConstants.SCREENING)){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
               newRec.Select_BPSes__c != existingRec.Select_BPSes__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SCREENING_BPS_MM);
            }
        }   
    }
    private void checkforPerformanceBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Select_BPSes__c==null){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId && 
           newRec.Select_BPSes__c.contains(NSP_ServiceConstants.PERFORMANCE) ){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
               newRec.Select_BPSes__c != existingRec.Select_BPSes__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PERFORMANCE_BPS_MM);
            }
        }   
    }
    private void checkforInsuranceBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Select_BPSes__c==null){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId && 
           newRec.Select_BPSes__c.contains(NSP_ServiceConstants.INSURANCE)){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
               newRec.Select_BPSes__c != existingRec.Select_BPSes__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, INSURANCE_BPS_MM);
            }
        }   
    }
    private void checkforOrganizationalBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Select_BPSes__c==null ){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId &&
           newRec.Select_BPSes__c.contains(NSP_ServiceConstants.ORGANIZATIONAL)){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
               newRec.Select_BPSes__c != existingRec.Select_BPSes__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, ORGANIZATIONAL_BPS_MM);
            }
        }   
    }
    private void checkforRecruitingBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Select_BPSes__c==null){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId &&
           newRec.Select_BPSes__c.contains(NSP_ServiceConstants.RECRUITING)){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
               newRec.Select_BPSes__c != existingRec.Select_BPSes__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, RECRUITING_BPS_MM);
            }
        }   
    }

    private void checkForCertifyBPS(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipMMRecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Select_BPSes__c==null ){
               return;
           }
        if( newRec.RecordTypeId == ipMMRecordTypeId &&
           newRec.Select_BPSes__c.contains(NSP_ServiceConstants.CERTIFY)){
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
               newRec.Select_BPSes__c != existingRec.Select_BPSes__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CERTIFY_BPS_MM);
            }
        }   
    }

 
     private void checkForStateSpecificLeave(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         LIst<String> stateCodes = new List <String>{'CA','IL','MD','MN','NH','NY','SC','DC','WA'};
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
         findSharedValue(stateCodes,newRec.Employees_work_in_the_following_states__c)){
 
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Employees_work_in_the_following_states__c != existingRec.Employees_work_in_the_following_states__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SPECIFIC_LEAVE_MM);
             }
         }   
     }
 
     private void checkForPreTax(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
        if( newRec.RecordTypeId == ipMMRecordTypeId &&
        newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES && newRec.Sponsored_plan_contribution_type__c!=null 
        && newRec.Sponsored_plan_contribution_type__c.contains(NSP_ServiceConstants.PRETAX)){
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Sponsored_plan_contribution_type__c != existingRec.Sponsored_plan_contribution_type__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PRE_TAX_MM);
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PRE_TAX_DEDUCT_MM);
             }
         }   
     }
 
         private void checkForPostTax(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
            (newRec.Client_has_any_post_tax_deductions__c==NSP_ServiceConstants.YES ||
            (newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES && newRec.Sponsored_plan_contribution_type__c!=null 
            && newRec.Sponsored_plan_contribution_type__c.contains(NSP_ServiceConstants.POSTTAX)))){
 
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Sponsored_plan_contribution_type__c != existingRec.Sponsored_plan_contribution_type__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POST_TAX_SPONSPOREDPLAN_MM);
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POST_TAX_EMPSETUP_MM);
             }
         }   
     }
 
     private void checkForExpenseAllowance(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
        if( newRec.RecordTypeId == ipMMRecordTypeId && newRec.Allowances__c!=null &&
          (newRec.Allowances__c.contains(NSP_ServiceConstants.CAR) ||
          newRec.Allowances__c.contains(NSP_ServiceConstants.PHONE) ||
          newRec.Allowances__c.contains(NSP_ServiceConstants.PER_DIEM) ||
          newRec.Allowances__c.contains(NSP_ServiceConstants.HOUSE)) ){
            
            if(existingRec == null || newRec.NSP_Form_Completed__c  ||
               newRec.Allowances__c != existingRec.Allowances__c){
                 updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, ALLOWNCE_EXPENSE_MM);
            }
        }   
    }
 
     private void checkForDependentCare(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
            newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c!=null && 
            (newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DCFSA) 
            && newRec.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c == NSP_ServiceConstants.REQUESTED)){
 
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != existingRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, DEPENDENT_CARE_MM);
             }
         }   
     }
 
     private void checkForHealthCare(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
            newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c!=null && 
            (newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HCFSA) 
            && newRec.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c == NSP_ServiceConstants.REQUESTED)){
 
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != existingRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HEALTH_CARE_MM);
             }
         }   
     }
 
     private void checkForOtherPreTaxType(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
            newRec.NSP_Client_Sponsored_Plan__c == NSP_ServiceConstants.YES && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c!=null && 
            ((newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.MEDICAL) && newRec.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c == NSP_ServiceConstants.REQUESTED)
            ||(newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DENTAL) && newRec.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c == NSP_ServiceConstants.REQUESTED)
            ||(newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.VISION) && newRec.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c == NSP_ServiceConstants.REQUESTED))){
      
 
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != existingRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, OTHER_PRETAX_TYPE_MM);
             }
         }   
     }
 
     private void checkForHandbookDevelopment(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
            newRec.Client_have_any_urgent_HR_needs__c == NSP_ServiceConstants.YES && newRec.Select_client_urgent_HR_needs__c!=null 
            && newRec.Select_client_urgent_HR_needs__c.CONTAINS(NSP_ServiceConstants.HANDBOOK)){
      
 
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Select_client_urgent_HR_needs__c != existingRec.Select_client_urgent_HR_needs__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, HANDBOOK_DEVELOPMENT_MM);
             }
         }   
     }
 
     private void checkForJobDescription(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
            newRec.Client_have_any_urgent_HR_needs__c == NSP_ServiceConstants.YES && newRec.Select_client_urgent_HR_needs__c!=null 
            && newRec.Select_client_urgent_HR_needs__c.CONTAINS(NSP_ServiceConstants.JOBDESCRIPTION)){
      
 
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Select_client_urgent_HR_needs__c != existingRec.Select_client_urgent_HR_needs__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, JOBDESCRIPTION_MM);
             }
         }   
     }
 
     private void checkForSeveranceAgreement(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
         
         if( newRec.RecordTypeId == ipMMRecordTypeId &&
            newRec.Client_have_any_urgent_HR_needs__c == NSP_ServiceConstants.YES && newRec.Select_client_urgent_HR_needs__c!=null
            && newRec.Select_client_urgent_HR_needs__c.CONTAINS(NSP_ServiceConstants.SEVERANCEAGREEMENT)){
      
 
             if(existingRec == null || newRec.NSP_Form_Completed__c  ||
                newRec.Select_client_urgent_HR_needs__c != existingRec.Select_client_urgent_HR_needs__c){
                  updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SEVERANCEAGREEMENT_MM);
             }
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
    @future 
    private static void insertChildRecords(String childRecordsList){
        List<Sobject> insertChildRecordsList = (List<Sobject>) JSON.deserialize(childRecordsList, List<Sobject>.class);
        if(!insertChildRecordsList.isEmpty()){
            List<Database.SaveResult> insertChildResults = Database.Insert(insertChildRecordsList, false);
            NSP_ErrorLogHandler.logSaveResultsException('NSP_Implprofile_ServiceHelperUpdate', 'ProjectTask:insertProjectChildTaskResults', insertChildResults);
        }
    }
 }