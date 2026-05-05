//
// Represents the Implementation profile tirgger for update scenario.
// Refactored FSO IP - AZD-352367
//
public class NSP_Implprofile_ServiceHelperUpdate {
    // test w/ NSP_Implprofile_ServiceHelperUpdate_Test (80%)

    private  Boolean isRerun =false;
    private Boolean isSaveForm = false;
    private Map<Id, Implementation_Profile__c> newIPs = null;
    private Map<Id, Implementation_Profile__c> oldIPs = null;
    private Map<String, Set<Id>> ipRecordsByAutomation = new Map<String, Set<Id>>();
    private List<pse__Project_Task__c> projectTaskToInsertList = new List<pse__Project_Task__c>();
    private List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
    private List<sObject> recToInsert = new List<sObject>();
    private List<sObject> recToUpdate = new List<sObject>();
    private List<pse__Project_Task__c> updateProjTask = new List<pse__Project_Task__c>();
    private Map<String, Map<Id, sObject>> data = new Map<String, Map<Id, sObject>>();
    private Map<String, List<String>> ipAutomationdata = new Map<String, List<String>>();
    private Map<String, Map<String, NSP_Employee_Data__c>> employeeData = new Map<String, Map<String, NSP_Employee_Data__c>>();
    private List<String> automationsToExecute = new List<String>();
    private Set<Id> ipIds=new Set<Id>();
    private Map<String, Id> mapofGroupIds=new Map<String, Id>();
    Map<Id, List<String>> mapOfCompletedTasks=new Map<Id, List<String>>();
    private Map<String, pse__Milestone__c> mileStonesToInsert = new Map<String, pse__Milestone__c>();
    private Map<String, Implementation_Profile__c> impProfileToUpdate = new Map<String, Implementation_Profile__c>();
    private List<String> existingIpAutomations=new List<String>();
    private static final String EMPLOYEE_DATA_IDENTIFIER = 'NSP_Employee_Data__c';
    private static final String PROJECT_IDENTIFIER = 'pse__Proj__c';
    private static final String PROJECT_TASK_IDENTIFIER = 'pse__Project_Task__c';
    private static final String IMPL_PROFILE_IDENTIFIER = 'Implementation_Profile__c';
    private static final String IP_AUTOMATION_IDENTIFIER = 'NSP_Implementation_Profile_Automation__c';
    private static final String CT_SPONSORED_PLAN_FN = 'CSP_doc_s_not_received';
    private static final String GENERAL_LIABILITY_FN = 'generalLiability';
    private static final String EEO_FILING_FN = 'EEOFiling';
    private static final String CLIENT_HANDBOOK_FN = 'Client_policies' ;
    private static final String EDC_FN = 'EDC' ;
    private static final String PAYROLL_LOCATIONS_FN = 'Special_Payroll_Needs_Locations';
    private static final String PAYROLL_DEPARTMENTS_FN = 'Payroll_Needs_Departments';
    private static final String PAYROLL_JOBCOSTING_FN = 'Special_Payroll_Needs_Job_Costing';
    private static final String PAYROLL_REGISTER_FN= 'Payroll_Register';
    private static final String GARNISHMENT_FN= 'Garnishments';
    private static final String POST_DEDUCTION_FN= 'Post_tax_deductions';
    private static final String RETIRE_PLAN_FN='retirementPlan';
    private static final String POSTTAX_LOANS_FN= 'Post_tax_deductions_NY_WSEE';
    private static final String SPECIAL_RELABEL_FN= 'Special_Pay_Codes_Relabeling';
    private static final String REPORT_Integra_FN= 'Integra';
    private static final String REPORT_Custom401k_FN= 'Custom_401_k';
    private static final String REPORT_JOBCOSTING_FN= 'Job_Costing_Reports';
    private static final String INTEGRA_RESPONSE= 'Integra_Responses_Smartsheet' ;
    private static final String REPORT_OTHER_FN='Custom_Report';
    private static final String COBRA_FN= 'Missing_COBRA_Names';
    private static final String COBRA_FORM_COLLECTED_FN=  'Verify_COBRA_eligibility';
    private static final String COBRA_FORM_NOT_COLLECTED_FN= 'COBRA_Form_Followup';
    private static final String LOA_INFO_FN= 'Missing_LOA_forms';
    private static final String MISSING_LOA_FN=  'Missing_LOA_Info';
    private static final String INTERNAL_DISCOVERY_FN ='NSP_Internal_Discovery';
    private static final String ONSITE_DISCOVERY_FN ='NSP_Onsite_Discovery';
    private static final String CSP_DOCS_FSO = 'CSP_doc_s_not_received';
    private static final String CSP_HCFSA_FSO ='CSP_HCFSA_FSO';
    private static final String CSP_HSA_FSO ='CSP_HSA_FSO';
    private static final String CSP_DCFSA_FSO ='CSP_DCFSA_FSO';
    private static final String CSP_MEDICAL_FSO ='CSP_MEDICAL_FSO';
    private static final String CSP_DENTAL_FSO ='CSP_DENTAL_FSO';
    private static final String CSP_VISION_FSO ='CSP_VISION_FSO';
    private static final String enrollFee_FN ='Enter_Enrollment_Fee';
    private static final String enrollFee_Subtask_FN ='EnrollmentFeeSubtask';
    private static final String DATA_VERIFICATION ='AWW_EE_Data_Verification' ;
    private static final String FLSA_EXEMPTION_REVIEW ='FLSA_Exemption_Review_non_EG';
    private static  Integer Counter=0;
    private static Id ipFSORecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.FSOProfile).getRecordTypeId();
    private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
    private static Id milestonePEORecordtypeId = SObjectType.pse__Milestone__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PEOMILSTONE).getRecordTypeId();
    private static Id projectTaskPEORecordTypeId = Schema.SObjectType.pse__Project_Task__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE).getRecordTypeId();
    private static final List<String> MILESTONE_NAMES = new List<String>{
        NSP_ServiceConstants.MILESTONE,
        NSP_ServiceConstants.EMPLOYEEPRIMING,
        NSP_ServiceConstants.EMPLOYEEDEDUCTION,
        NSP_ServiceConstants.REPORITNTNEED,
        NSP_ServiceConstants.PAYSETUP,
        NSP_ServiceConstants.BENEFITS,
        NSP_ServiceConstants.AM
    };

    public NSP_Implprofile_ServiceHelperUpdate(Map<Id, Implementation_Profile__c> newIPs, Map<Id, Implementation_Profile__c> oldIPs){
        this.newIPs = newIPs;
        this.oldIPs = oldIPs;
        this.automationsToExecute.addAll(
            new List<String>{
                CT_SPONSORED_PLAN_FN , GENERAL_LIABILITY_FN ,
                EEO_FILING_FN , CLIENT_HANDBOOK_FN , EDC_FN ,
                PAYROLL_LOCATIONS_FN , PAYROLL_DEPARTMENTS_FN ,
                PAYROLL_JOBCOSTING_FN , PAYROLL_REGISTER_FN ,
                GARNISHMENT_FN , POST_DEDUCTION_FN ,
                RETIRE_PLAN_FN , POSTTAX_LOANS_FN , SPECIAL_RELABEL_FN ,
                REPORT_Integra_FN , REPORT_Custom401k_FN ,
                REPORT_JOBCOSTING_FN , INTEGRA_RESPONSE ,
                REPORT_OTHER_FN , COBRA_FN , LOA_INFO_FN ,
                MISSING_LOA_FN , COBRA_FORM_COLLECTED_FN ,
                COBRA_FORM_NOT_COLLECTED_FN ,
                INTERNAL_DISCOVERY_FN ,
                ONSITE_DISCOVERY_FN , CSP_DOCS_FSO,
                enrollFee_FN ,enrollFee_Subtask_FN, DATA_VERIFICATION,FLSA_EXEMPTION_REVIEW
            }
        );
    }
    public NSP_Implprofile_ServiceHelperUpdate(Id ipRecord, String automationName){
        this.newIPs =  NSP_ImpAutomationsController.getIpRecord(ipRecord);
        this.isRerun=true;
        this.automationsToExecute.add(automationName);
    }
    public NSP_Implprofile_ServiceHelperUpdate(Boolean isSave){
        this.isSaveForm = isSave;
    }

    public static Boolean isAutomationAllowed() {
        return (
            CustomPermissionController.checkUserPermission( 'Use_Implementation_Profile' , UserInfo.getUserId() )
            && Schema.SObjectType.Implementation_Profile__c.isAccessible()
            && Schema.SObjectType.Implementation_Profile__c.isUpdateable()
        );
    }

    public Map<String,Set<Id>>  executeAutomation() {
        Map<String,Set<Id>> ipRecordsByAutomationMap = new Map<String,Set<Id>>();
        if ( NSP_Implprofile_ServiceHelperUpdate.isAutomationAllowed() ) {
            try {
                this.start();
                this.execute();
                this.finish();
                ipRecordsByAutomationMap = this.ipRecordsByAutomation;
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_Implprofile_ServiceHelperUpdate.class.getName() ,
                    'executeAutomation' ,
                    e
                );
            }
        }
        return ipRecordsByAutomationMap;
    }

    private void start() {
        //get all Employee Data
        // Create a set of eligible records which we need to pull
        populateEligibleRecords();
        // Fetch Project Records from DB
        if(ipRecordsByAutomation.size()>0){
            // Fetch Project Records from DB
            getProjectDBRecords();
            getImplAutomationRecords();
            //get all project manager for IP
            getIPRecords();
            //get all group id for queue
            getGroupId();
        }
    }

    private void execute() {
        Id workCalendarId = [SELECT Id FROM pse__Work_Calendar__c LIMIT 1].Id;
        for(String automation: ipRecordsByAutomation.keySet()) {
            createProjectTasks(automation, workCalendarId);
        }
        if(!projectTaskToInsertList.isEmpty()){
            //check for existing Project Tasks to avoid duplications
            recToInsert.addAll(getNewTaskstoInsert(projectTaskToInsertList));
        }
        if(!ipAutomationRecords.isEmpty()){
            //check for existing Automation record and store the new Automation records
            recToInsert.addAll(getNewAutomationListToInsert(ipAutomationRecords));
        }
      }

    private void finish(){
        List<Database.UpsertResult> upsertResults = Database.upsert(mileStonesToInsert.values(), false);
        NSP_ErrorLogHandler.logResults(
            NSP_Implprofile_ServiceHelperUpdate.class.getName() ,
            'finish:upsertResults' ,
            upsertResults
        );
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
        database.insert(recToInsert,false);
        if(updateProjTask != null) {
            database.update(updateProjTask,false);
        }
        List<Database.UpsertResult> upsertImpResults = Database.upsert(impProfileToUpdate.values(), false);
        NSP_ErrorLogHandler.logResults(
            NSP_Implprofile_ServiceHelperUpdate.class.getName() ,
            'finish:upsertImpResults' ,
            upsertImpResults
        );
    }

    private void getProjectDBRecords(){
        Set<Id> projectIDs = new Set<Id>();
        for (Set<Id> ipRecords : ipRecordsByAutomation.values()) {
            ipIDs.addAll(ipRecords);
        }
        for (Id ipRec : ipIDs) {
            projectIDs.add(newIPs.get(ipRec).NSP_Project__c);
        }
        Map<Id, sObject> dbRec = new Map<Id, sObject>([SELECT Id, pse__End_Date__c,pse__Account__r.Name,
                                                       NSP_Account_Executive__c,
                                                       NSP_Account_Executive__r.NSP_Work_email__c,pse__Project_Manager__c,
                                                       pse__Project_Manager__r.pse__Salesforce_User__c, (SELECT Id, Name FROM pse__Milestones__r),
                                                       (SELECT Id,NSP_Role__c,NSP_Assignee__c, NSP_Assignee__r.NSP_Work_email__c FROM Project_Teams__r),
                                                       (SELECT Id, pse__Project__c,pse__Status__c, pse__Order__c,Task_Order__c, NSP_Sub_Category__c, NSP_Category__c,pse__Milestone__c, Name, NSP_Implementation_Profile_Account__c,NSP_Implementation_Account_Id__c FROM pse__Project_Tasks__r) FROM pse__Proj__c WHERE Id IN :projectIDs]);
        for(sObject projObj : dbRec.values()){
            pse__Proj__c proj=(pse__Proj__c)projObj;
            List<String> completedTask = new List<String>();
            for(pse__Project_Task__c pt:proj.pse__Project_Tasks__r ){
                if(pt.pse__Status__c==NSP_ServiceConstants.PROJECTSTATUSCOMPLETED){
                    completedTask.add(pt.Name);
                }
            }
            mapOfCompletedTasks.put(proj.Id, completedTask);
        }
        data.put(PROJECT_IDENTIFIER, dbRec);
    }

    private void getImplAutomationRecords(){
        Map<Id, sObject> dbRec = new Map<Id, sObject>([SELECT Id,Name,NSP_Implementation_Profile__c,NSP_Record_Type__c,NSP_Method_Name__c FROM NSP_Implementation_Profile_Automation__c WHERE NSP_Implementation_Profile__c = :ipIDs]);
        data.put(IP_AUTOMATION_IDENTIFIER, dbRec);
    }

    private void getProjectTasksDBRecords(){
        Set<Id> projectIDs = new Set<Id>();
        for (Set<Id> ipRecords : ipRecordsByAutomation.values()) {
            for (Id ipRec : ipRecords) {
                projectIDs.add(newIPs.get(ipRec).NSP_Project__c);
                ipIDs.add(ipRec);
            }
        }
        Map<Id, sObject> dbRec = new Map<Id, sObject>([SELECT Id, pse__Project__r.pse__End_Date__c, pse__Project__c, NSP_Sub_Category__c, NSP_Category__c,pse__Milestone__c, Name, NSP_Implementation_Profile_Account__c,NSP_Implementation_Account_Id__c
                                                        FROM pse__Project_Task__c  WHERE pse__Project__c IN :projectIDs]);
        data.put(PROJECT_TASK_IDENTIFIER, dbRec);
    }

    private void populateEligibleRecords(){
        for(Implementation_Profile__c ipRec : newIPs.values()){
            Implementation_Profile__c existingRec = oldIPs != null ? oldIPs.get(ipRec.Id) : null;
            ipIds.add(ipRec.Id);
            checkForClientSposoredPlan(ipRec, existingRec);
            checkForClientSposoredPlanSubTask(ipRec, existingRec);
            checkforReceivedCertificate(ipRec, existingRec);
            checkforEEO(ipRec, existingRec);
            checkforClientHandbook(ipRec, existingRec);
            checkforEDC(ipRec, existingRec);
            checkforPayrollLocations(ipRec, existingRec);
            checkforPayrollDepartments(ipRec, existingRec);
            checkforPayrollJobCosting(ipRec, existingRec);
            checkforPayrollRegister(ipRec, existingRec);
            checkforGarnishments(ipRec, existingRec);
            checkforPostDeduction(ipRec, existingRec);
            checkforRetPlan(ipRec, existingRec);
            checkforPostTaxLoans(ipRec, existingRec);
            checkforRelabel(ipRec, existingRec);
            checkforReportingJobCosting(ipRec, existingRec);
            checkforReportingIntegra(ipRec, existingRec);
            checkforReportingCustom(ipRec, existingRec);
            checkforReportingOther(ipRec, existingRec);
            checkforReportingIntegraResponse(ipRec, existingRec);
            checkforCOBRA(ipRec, existingRec);
            checkforLOAInfo(ipRec,existingRec);
            checkforLOAInfo(ipRec,existingRec);
            checkforCOBRAForm(ipRec,existingRec,COBRA_FORM_COLLECTED_FN,NSP_ServiceConstants.YES);
            checkforCOBRAForm(ipRec,existingRec,COBRA_FORM_NOT_COLLECTED_FN,NSP_ServiceConstants.NO);
            checkInternalDiscovery(ipRec, existingRec);
            checkOnsiteDiscovery(ipRec, existingRec);
            checkEnrollFee(ipRec, existingRec);
            checkDataVerification(ipRec, existingRec);
            checkFlsaExemptionReview(ipRec, existingRec);
        }
    }

    private  void checkEnrollFee(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if (automationsToExecute.contains(enrollFee_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.NSP_Is_there_an_Enrollment_fee__c == NSP_ServiceConstants.YES
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_Is_there_an_Enrollment_fee__c != existingRec.NSP_Is_there_an_Enrollment_fee__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, enrollFee_FN);
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, enrollFee_Subtask_FN);
        }
    }

    private void checkDataVerification(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(DATA_VERIFICATION)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Does_this_client_have_an_AWW__c == NSP_ServiceConstants.YES
            && newRec.First_Pay_Date__c != null
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Does_this_client_have_an_AWW__c != existingRec.Does_this_client_have_an_AWW__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, DATA_VERIFICATION);
        }
    }
    private void checkFlsaExemptionReview(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(FLSA_EXEMPTION_REVIEW)
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
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, FLSA_EXEMPTION_REVIEW);
        }
    }

    private void checkForClientSposoredPlan(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if(automationsToExecute.contains(CSP_DOCS_FSO)
           && newRec != null
           && newRec.RecordTypeId == ipFSORecordTypeId
           && newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c != null
           && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c == NSP_ServiceConstants.YES
              )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CSP_DOCS_FSO);
        }
    }

    private void checkForClientSposoredPlanSubTask(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if(automationsToExecute.contains(CT_SPONSORED_PLAN_FN)
           && newRec != null
           && newRec.RecordTypeId == ipFSORecordTypeId
           && newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c == NSP_ServiceConstants.YES
           && newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != null
           && (
                newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HCFSA)
                || newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HSA)
                || newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DCFSA)
                || newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.MEDICAL)
                || newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DENTAL)
                || newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.VISION)
               )
           && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != existingRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c)
            )
        {
           updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CT_SPONSORED_PLAN_FN);
        }
    }


    private void checkforReceivedCertificate(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(GENERAL_LIABILITY_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c == NSP_ServiceConstants.REQUESTED
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c != existingRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, GENERAL_LIABILITY_FN);
        }
    }

    private void checkforEEO(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(EEO_FILING_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Client_have_EEO_filing_under__c == NSP_ServiceConstants.YES
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Client_have_EEO_filing_under__c != existingRec.Client_have_EEO_filing_under__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EEO_FILING_FN);
        }
    }

    private void checkforClientHandbook(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(CLIENT_HANDBOOK_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && (newRec.Gave_copy_of_PTO_sick_leave_other_policy__c == NSP_ServiceConstants.NO
                || newRec.Gave_copy_of_PTO_sick_leave_other_policy__c == NSP_ServiceConstants.REQUESTED
               )
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Gave_copy_of_PTO_sick_leave_other_policy__c != existingRec.Gave_copy_of_PTO_sick_leave_other_policy__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CLIENT_HANDBOOK_FN);
        }
    }

    private void checkforEDC(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(EDC_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && (newRec.Employee_Data_Collection_EDC_collected__c == NSP_ServiceConstants.NO
                || newRec.Employee_Data_Collection_EDC_collected__c == NSP_ServiceConstants.NOTCOLLECTED
               )
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Employee_Data_Collection_EDC_collected__c != existingRec.Employee_Data_Collection_EDC_collected__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EDC_FN);
        }
    }

    private void checkforPayrollLocations(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(PAYROLL_LOCATIONS_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Select_all_payroll_needs_that_apply__c != null
            && newRec.Client_has_any_special_payroll_needs__c == NSP_ServiceConstants.YES
            && newRec.Select_all_payroll_needs_that_apply__c.contains(NSP_ServiceConstants.LOCATIONS)
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || existingRec.Select_all_payroll_needs_that_apply__c != null
                || newRec.Select_all_payroll_needs_that_apply__c != existingRec.Select_all_payroll_needs_that_apply__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_LOCATIONS_FN);
        }
    }

    private void checkforPayrollDepartments(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(PAYROLL_DEPARTMENTS_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Select_all_payroll_needs_that_apply__c != null
            && newRec.Client_has_any_special_payroll_needs__c == NSP_ServiceConstants.YES
            && newRec.Select_all_payroll_needs_that_apply__c.contains(NSP_ServiceConstants.DEPARTMENTS)
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_all_payroll_needs_that_apply__c != existingRec.Select_all_payroll_needs_that_apply__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_DEPARTMENTS_FN);
        }
    }

    private void checkforPayrollJobCosting(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(PAYROLL_JOBCOSTING_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Select_all_payroll_needs_that_apply__c != null
            && newRec.Client_has_any_special_payroll_needs__c == NSP_ServiceConstants.YES
            && newRec.Select_all_payroll_needs_that_apply__c.contains(NSP_ServiceConstants.JOBCOSTING)
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Select_all_payroll_needs_that_apply__c != existingRec.Select_all_payroll_needs_that_apply__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_JOBCOSTING_FN);
        }
    }

    private void checkforPayrollRegister(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(PAYROLL_REGISTER_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && (newRec.Recent_Payroll_Register_Collected__c == NSP_ServiceConstants.NO
                || newRec.Recent_Payroll_Register_Collected__c == NSP_ServiceConstants.NOTCOLLECTED
               )
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Recent_Payroll_Register_Collected__c != existingRec.Recent_Payroll_Register_Collected__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_REGISTER_FN);
        }
    }

    private void checkforGarnishments(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(GARNISHMENT_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Do_any_EEs_have_garnishments__c == NSP_ServiceConstants.YES
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Do_any_EEs_have_garnishments__c != existingRec.Do_any_EEs_have_garnishments__c
               )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, GARNISHMENT_FN);
        }
    }

    private void checkforPostDeduction(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(POST_DEDUCTION_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && (newRec.Client_has_any_post_tax_deductions__c == NSP_ServiceConstants.YES
                || (newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c == NSP_ServiceConstants.YES
                    && newRec.Sponsored_plan_contribution_type__c != null
                    && newRec.Sponsored_plan_contribution_type__c.contains(NSP_ServiceConstants.POSTTAX)
                )
            )
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Sponsored_plan_contribution_type__c != existingRec.Sponsored_plan_contribution_type__c
                || newRec.Client_has_any_post_tax_deductions__c != existingRec.Client_has_any_post_tax_deductions__c
                || newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c != existingRec.Spnsrd_pln_when_Insperity_hndles_payroll__c
            )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POST_DEDUCTION_FN);
        }
    }

    private void checkforRetPlan(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(RETIRE_PLAN_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && (newRec.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.CSP401K
                || newRec.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.SIMPLEIRA
                || newRec.Type_of_retirement_plan_client_has_today__c == NSP_ServiceConstants.CLIENTB
            )
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Type_of_retirement_plan_client_has_today__c != existingRec.Type_of_retirement_plan_client_has_today__c
            )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, RETIRE_PLAN_FN);
        }
    }

    private void checkforPostTaxLoans(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(POSTTAX_LOANS_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Employees_work_in_the_following_states__c != null
            && newRec.Employees_work_in_the_following_states__c.contains(NSP_ServiceConstants.NY)
            && (newRec.Client_has_any_post_tax_deductions__c == NSP_ServiceConstants.YES
                || (newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c == NSP_ServiceConstants.YES
                    && newRec.Sponsored_plan_contribution_type__c != null
                    && newRec.Sponsored_plan_contribution_type__c.contains(NSP_ServiceConstants.POSTTAX)
                )
            )
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Sponsored_plan_contribution_type__c != existingRec.Sponsored_plan_contribution_type__c
                || newRec.Client_has_any_post_tax_deductions__c != existingRec.Client_has_any_post_tax_deductions__c
                || newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c != existingRec.Spnsrd_pln_when_Insperity_hndles_payroll__c
                || newRec.Employees_work_in_the_following_states__c != existingRec.Employees_work_in_the_following_states__c
            )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POSTTAX_LOANS_FN);
        }
    }

    private void checkforRelabel(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(SPECIAL_RELABEL_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.NSP_Any_special_pay_codes_Needed__c == NSP_ServiceConstants.YES
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_Any_special_pay_codes_Needed__c != existingRec.NSP_Any_special_pay_codes_Needed__c
            )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SPECIAL_RELABEL_FN);
        }
    }

    private void checkforReportingJobCosting(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(REPORT_JOBCOSTING_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.NSP_Select_all_that_apply__c != null
            && newRec.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.COSTING)
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_Select_all_that_apply__c != existingRec.NSP_Select_all_that_apply__c
            )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, REPORT_JOBCOSTING_FN);
        }
    }

    private void checkforReportingIntegraResponse(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(INTEGRA_RESPONSE)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Is_there_a_need_for_Integra__c == NSP_ServiceConstants.YES
            && newRec.First_Pay_Date__c != null
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Is_there_a_need_for_Integra__c != existingRec.Is_there_a_need_for_Integra__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, INTEGRA_RESPONSE);
        } else if (automationsToExecute.contains(INTEGRA_RESPONSE)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Is_there_a_need_for_Integra__c == NSP_ServiceConstants.NO
            )
        {
            updateProjecttaskforIntegraResponse(existingRec);
        }
    }

    private void checkforReportingIntegra(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(REPORT_Integra_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.NSP_Select_all_that_apply__c != null
            && newRec.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.INTEGRA_ASSET)
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_Select_all_that_apply__c != existingRec.NSP_Select_all_that_apply__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, REPORT_Integra_FN);
        }
    }

    private void checkforReportingCustom(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(REPORT_Custom401k_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.NSP_Select_all_that_apply__c != null
            && newRec.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.REPORT401)
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_Select_all_that_apply__c != existingRec.NSP_Select_all_that_apply__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, REPORT_Custom401k_FN);
        }
    }

    private void checkforReportingOther(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(REPORT_OTHER_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.NSP_Select_all_that_apply__c != null
            && newRec.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.OTHREPORTS)
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.NSP_Select_all_that_apply__c != existingRec.NSP_Select_all_that_apply__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, REPORT_OTHER_FN);
        }
    }

    private void checkforCOBRA(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if (automationsToExecute.contains(COBRA_FN)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Have_name_s_of_COBRA_takeovr_employees__c != null
            && newRec.Have_name_s_of_COBRA_takeovr_employees__c == NSP_ServiceConstants.NO
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Have_name_s_of_COBRA_takeovr_employees__c != existingRec.Have_name_s_of_COBRA_takeovr_employees__c
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, COBRA_FN);
        }
    }

    private void checkforCOBRAForm(
        Implementation_Profile__c newRec,
        Implementation_Profile__c existingRec,
        String formType,
        String expectedValue
    ){
        if (automationsToExecute.contains(formType)
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.Have_name_s_of_COBRA_takeovr_employees__c == NSP_ServiceConstants.YES
            && (String.isNotBlank(newRec.NSP_COBRA_Takeover_Emp_Details__c))
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Have_name_s_of_COBRA_takeovr_employees__c != existingRec.Have_name_s_of_COBRA_takeovr_employees__c
                )
            )
        {
            List<String> employeeNames = newRec.NSP_COBRA_Takeover_Emp_Details__c.split(',');
            for (String employee : employeeNames) {
                String[] parts = employee.split('~');
                if (parts.size() > 1) {
                    String value = parts[1];
                    if (expectedValue == value) {
                        updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, formType);
                        break;
                    }
                }
            }
        }
    }

    private void checkforLOAInfo(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        if ( (automationsToExecute.contains(MISSING_LOA_FN) || automationsToExecute.contains(LOA_INFO_FN))
            && newRec != null
            && newRec.RecordTypeId == ipFSORecordTypeId
            && newRec.NSP_Project__c != null
            && (existingRec == null
                || newRec.NSP_Form_Completed__c
                || newRec.Do_you_have_the_LOA_information__c != existingRec.Do_you_have_the_LOA_information__c
                )
            )
        {
            // Check if LOA information is missing
            if (newRec.Do_you_have_the_LOA_information__c == NSP_ServiceConstants.NO) {
                updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, MISSING_LOA_FN);
            }
            // Check if LOA information is provided and employee details are not null
            if (newRec.Do_you_have_the_LOA_information__c == NSP_ServiceConstants.YES
                && String.isNotBlank(newRec.NSP_Employee_Details_On_LOA__c)
                )
            {
                List<String> employeeNames = newRec.NSP_Employee_Details_On_LOA__c.split(',');
                for (String empName : employeeNames) {
                    String[] parts = empName.trim().split('~');
                    if (parts.size() > 2 && parts[2] == NSP_ServiceConstants.NO) {
                        updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, LOA_INFO_FN);
                        break;
                    }
                }
            }
        }
    }

    private void updateEligibleRecordsMap(Map<String, Set<Id>> automationMap, Id recId, String fnName){
        Set<Id> relevantRecords = automationMap.get(fnName);
        if(relevantRecords == null){
            relevantRecords = new Set<Id>();
        }
        relevantRecords.add(recId);
        automationMap.put(fnName, relevantRecords);
    }

//Creates Project Task automations FSO IP
    private void createProjectTasks( String automation , Id workCalendarId ) {
        NSP_ProjectTask_Automation__mdt pta = null;
        if(automation != null){
            pta = NSP_ProjectTask_Automation__mdt.getInstance(automation);
        }
        if(ipRecordsByAutomation.containsKey(automation) && ipRecordsByAutomation.get(automation) != null) {
            for(Id ipRecId : ipRecordsByAutomation.get(automation)){
                if(newIPs != null) {
                    Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                    if(ipRec != null && ((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm)){
                        pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                        projectTasks(automation, proj,pta, ipRecId,workCalendarId);
                    }
                }
            }
        }
    }

    //Creates the Milestones for each of the Project Tasks
    private String createMilestoneForProjectTask(pse__Proj__c proj,NSP_ProjectTask_Automation__mdt pta) {
        String milestoneKey;
        if(proj != null && pta != null){
            Id milestoneId = getMilestoneId(proj.pse__Milestones__r,pta.NSP_Milestone__c);
            milestoneKey = proj.Id + '~' + pta.NSP_Milestone__c;
            if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                pse__Milestone__c eachMilestone = new pse__Milestone__c(
                    Name=pta.NSP_Milestone__c,
                    RecordTypeId=milestonePEORecordtypeId,
                    pse__Project__c=proj.Id,
                    pse__Target_Date__c=proj.pse__End_Date__c
                );
                mileStonesToInsert.put(milestoneKey, eachMilestone);
            }
        }
        return milestoneKey;
    }

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
            createProjecttaskforReceivedCertificate(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforEEO(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforClient(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforEDC(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforPayrollneeds(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforPayrollJob(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforPayrollJobCosting(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforPayrollRegister(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforGarnishment(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforPostDeduction(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforRetplan(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforPosttaxded(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforRelable(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforReportingIntegra(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforReportingCustom(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforReportingJob(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforIntegraResponse(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforReportingOther(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforCOBRA(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforLOAInfo(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforMissingLOA(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForCOBRAForm(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjecttaskforEnrollFee(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createSubtaskforEnrollment(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForDataVerification(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForFlsaExemptionReview(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            createSubtaskforClientSposoredPlan(automation,proj,ipRecId,ipwithValue,workCalendarId);
            createProjectTaskForClientSposoredPlan(automation,pta,proj,ipRecId,ipwithValue,workCalendarId);
            emailNotifyInternalDiscovery(automation,ipRecId);
            emailNotifyOnsiteDiscovery(automation,ipRecId);
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
        if(proj != null && eachProjecttask != null && pta != null){
            Id milestoneId = getMilestoneId( proj.pse__Milestones__r , pta.NSP_Milestone__c );
            eachProjecttask.NSP_Sub_Category__c = pta.NSP_Sub_Category__c;
            eachProjecttask.Name = pta.NSP_Task_Name__c;
            eachProjecttask.pse__Order__c = pta.Order__c;
            eachProjecttask.Task_Order__c = pta.Task_Order__c;
            eachProjecttask.NSP_Visible_to_Client__c = pta.Visible_to_Client__c;
            eachProjecttask.pse__Milestone__c = milestoneId;
            if ( workCalendarId != null ) {
                eachProjecttask.pse__Work_Calendar__c = workCalendarId;
            }
        }

    }

    private Id getProjectTaskId(pse__Proj__c proj, String projectTaskName){
        String projectTaskId = '';
        if ( ( proj != null ) && ( proj.pse__Project_Tasks__r != null ) && String.isNotBlank(projectTaskName)) {
            for ( pse__Project_Task__c projTask:proj.pse__Project_Tasks__r ) {
                if ( projTask.Name == projectTaskName ) {
                    projectTaskId = projTask.Id;
                    break;
                }
            }
        }
        return projectTaskId;
    }

   // Client Sposored Plan FSA - automation
    private  void createProjectTaskForClientSposoredPlan(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == CSP_DOCS_FSO){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null && ipwithValue != null){
                eachProjecttask.Implementation_Profile__c = ipwithValue.id;
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }


   //Health Care FSA - Task
    private void createTaskForHealthCareFSA(
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId,
        pse__Project_Task__c pt
        )
    {
        // CSP_HCFSA_FSO
        pse__Project_Task__c eachProjecttask = null;
        Implementation_Profile__c ipRec = newIPs.get(ipRecId);
        if(ipRec != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HCFSA)
            )
        {
            NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(CSP_HCFSA_FSO);
            eachProjecttask = this.createSubtaskCspDocsNotReceivedRecord(proj, pta, ipRecId, ipWithValue, workCalendarId, pt);
        }
        if(eachProjecttask != null){
            projectTaskToInsertList.add(eachProjecttask);
        }
    }

    //Health Saving Account - Task
    private void createTaskForHSA(
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId,
        pse__Project_Task__c pt
        )
    {
        // CSP_HSA_FSO
        pse__Project_Task__c eachProjecttask = null;
        Implementation_Profile__c ipRec = newIPs.get(ipRecId);
        if(ipRec != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HSA)
            )
        {
            NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(CSP_HSA_FSO);
            eachProjecttask = this.createSubtaskCspDocsNotReceivedRecord(proj, pta, ipRecId, ipWithValue, workCalendarId, pt);
        }
        if(eachProjecttask != null){
            projectTaskToInsertList.add(eachProjecttask);
        }
    }

    //Dependent Care FSA - Task
    private void createTaskForDependentCareFSA(
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId,
        pse__Project_Task__c pt
        )
    {
        // CSP_DCFSA_FSO
        pse__Project_Task__c eachProjecttask = null;
        Implementation_Profile__c ipRec = newIPs.get(ipRecId);
        if(ipRec != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DCFSA)
            )
        {
            NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(CSP_DCFSA_FSO);
            eachProjecttask = this.createSubtaskCspDocsNotReceivedRecord(proj, pta, ipRecId, ipWithValue, workCalendarId, pt);
        }
        if(eachProjecttask != null){
            projectTaskToInsertList.add(eachProjecttask);
        }
    }

    //CSP - Medical - automation
    private void createTaskForMedical(
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId,
        pse__Project_Task__c pt
        )
    {
      // CSP_MEDICAL_FSO
        pse__Project_Task__c eachProjecttask = null;
        Implementation_Profile__c ipRec = newIPs.get(ipRecId);
        if( ipRec != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.MEDICAL)
            )
        {
            NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(CSP_MEDICAL_FSO);
            eachProjecttask = this.createSubtaskCspDocsNotReceivedRecord(proj, pta, ipRecId, ipWithValue, workCalendarId, pt);
        }
        if(eachProjecttask != null){
            projectTaskToInsertList.add(eachProjecttask);
        }
    }

    //Dental CSP - Task
    private void createTaskForDental(
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId,
        pse__Project_Task__c pt
        )
    {
        // CSP_DENTAL_FSO
        pse__Project_Task__c eachProjecttask = null;
        Implementation_Profile__c ipRec = newIPs.get(ipRecId);
        if( ipRec != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DENTAL)
            )
        {
            NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(CSP_DENTAL_FSO);
            eachProjecttask = this.createSubtaskCspDocsNotReceivedRecord(proj, pta, ipRecId, ipWithValue, workCalendarId, pt);
        }
        if(eachProjecttask != null){
            projectTaskToInsertList.add(eachProjecttask);
        }
    }

    //CSP - Vision - automation
    private void createTaskForVision(
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId,
        pse__Project_Task__c pt
        )
    {
        // CSP_VISION_FSO
        pse__Project_Task__c eachProjecttask = null;
        Implementation_Profile__c ipRec = newIPs.get(ipRecId);
        if( ipRec != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != null
            && ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.VISION)
            )
        {
            NSP_ProjectTask_Automation__mdt pta =  NSP_ProjectTask_Automation__mdt.getInstance(CSP_VISION_FSO);
            eachProjecttask = this.createSubtaskCspDocsNotReceivedRecord(proj, pta, ipRecId, ipWithValue, workCalendarId, pt);
        }
        if(eachProjecttask != null){
            projectTaskToInsertList.add(eachProjecttask);
        }
    }

    // Onboarding Task -
    private pse__Project_Task__c genericOnboardingTask(
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        String milestoneKey = createMilestoneForProjectTask(proj, pta);
        pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c,ipRecId,milestoneKey);
        genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
        if(ipwithValue != null
            && ipwithValue.NSP_Onboarding_Specialist_Coordinator__c!=null
            && ipwithValue.NSP_Onboarding_Specialist_Coordinator__r.pse__Salesforce_User__c!=null
            )
        {
            eachProjecttask.OwnerId=ipwithValue.NSP_Onboarding_Specialist_Coordinator__r.pse__Salesforce_User__c;
        }
        return eachProjectTask;
    }

    // Payroll Task -
    private pse__Project_Task__c genericPayrollTask(
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        String milestoneKey = createMilestoneForProjectTask(proj, pta);
        pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c,ipRecId,milestoneKey);
        genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
        if(ipwithValue != null
            && ipwithValue.NSP_Payroll_Specialist__c!=null
            && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null
            )
        {
            eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
        }
        return eachProjectTask;
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
        pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c,ipRecId,milestoneKey);
        genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
        if(ipwithValue != null
            && ipwithValue.NSP_Project_Manager__c!=null
            && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null
            )
        {
            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
        }
        return eachProjectTask;
    }

    //HR Client Implementation Team Member owner
    private pse__Project_Task__c hrClientImplementationOwner(
        pse__Proj__c proj ,
        NSP_ProjectTask_Automation__mdt pta ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        String milestoneKey = createMilestoneForProjectTask(proj, pta);
        pse__Project_Task__c eachProjecttask = null;
        if(pta != null){
            eachProjecttask = createProjectTaskfromIP(proj,  pta.NSP_Category__c,ipRecId,milestoneKey);
        }
        genericProjectTask(proj,eachProjecttask, pta, workCalendarId);
        if(ipwithValue != null
            && ipwithValue.NSP_HR_Quality_Support_Team_Member__c!=null
            && ipwithValue.NSP_HR_Quality_Support_Team_Member__r.pse__Salesforce_User__c!=null
            )
        {
            eachProjecttask.OwnerId=ipwithValue.NSP_HR_Quality_Support_Team_Member__r.pse__Salesforce_User__c;
        }
        return eachProjectTask;
    }

    // GENERAL_LIABILITY_FN refactored
    private  void createProjecttaskforReceivedCertificate(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == GENERAL_LIABILITY_FN){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // EEO_FILING_FN refactored
    private  void createProjecttaskforEEO(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == EEO_FILING_FN){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

   //  CLIENT_HANDBOOK_FN refactored
    private void createProjecttaskforClient(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == CLIENT_HANDBOOK_FN){
            pse__Project_Task__c eachProjecttask = genericOnboardingTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // EDC_FN refactored
    private  void createProjecttaskforEDC(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == EDC_FN){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // PAYROLL_LOCATIONS_FN refactored
    private  void createProjecttaskforPayrollneeds(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == PAYROLL_LOCATIONS_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null ){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // PAYROLL_DEPARTMENTS_FN refactored
    private  void createProjecttaskforPayrollJob(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == PAYROLL_DEPARTMENTS_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // PAYROLL_JOBCOSTING_FN refactored
    private  void createProjecttaskforPayrollJobCosting(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == PAYROLL_JOBCOSTING_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null ){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }
    // PAYROLL_REGISTER_FN refactored
    private  void createProjecttaskforPayrollRegister(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == PAYROLL_REGISTER_FN){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // GARNISHMENT_FN refactored
    private  void createProjecttaskforGarnishment(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == GARNISHMENT_FN){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null && ipwithValue != null){
                eachProjecttask.Implementation_Profile__c = ipwithValue.id;
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // POST_DEDUCTION_FN refactored
    private  void createProjecttaskforPostDeduction(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == POST_DEDUCTION_FN){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // RETIRE_PLAN_FN refactored
    private  void createProjecttaskforRetplan(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == RETIRE_PLAN_FN){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // POSTTAX_LOANS_FN refactored
    private  void createProjecttaskforPosttaxded(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == POSTTAX_LOANS_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // SPECIAL_RELABEL_FN refactored
    private  void createProjecttaskforRelable(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == SPECIAL_RELABEL_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // REPORT_JOBCOSTING_FN refactored
    private  void createProjecttaskforReportingJob(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == REPORT_JOBCOSTING_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // INTEGRA_RESPONSE refactored
    private  void createProjecttaskforIntegraResponse(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == INTEGRA_RESPONSE){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            DateTime now = DateTime.now();
            Integer hour = now.hour();
            Integer minute = now.minute();
            Integer second = now.second();
            if(eachProjecttask != null && ipa != null && ipwithValue != null ){
                if(ipwithValue.First_Pay_Date__c != null){
                    eachProjecttask.pse__Start_Date_Time__c = DateTime.newInstance(
                        ipwithValue.First_Pay_Date__c.year() ,
                        ipwithValue.First_Pay_Date__c.month() ,
                        ipwithValue.First_Pay_Date__c.day() ,
                        hour ,
                        minute ,
                        second
                    );
                    eachProjecttask.Implementation_Profile__c = ipwithValue.Id;
                    eachProjecttask.pse__End_Date_Time__c = eachProjecttask.pse__Start_Date_Time__c.addDays(30);
                }
                eachProjecttask.pse__Long_Description__c = System.label.ProjectTaskLongDescription;
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // Method to update Project Task status field to Cancelled if the related IP record field
    // Is there a need for Integra is changed to No, as long as the Project Task status != Complete
    private void updateProjecttaskforIntegraResponse(Implementation_Profile__c existingRec){
        if(existingRec != null) {
            List<pse__Project_Task__c> projectTasks = [
                SELECT Id, pse__Status__c
                FROM pse__Project_Task__c
                WHERE Implementation_Profile__c =: existingRec.Id
            ];
            if(!projectTasks.isEmpty()) {
                for(pse__Project_Task__c projTask: projectTasks){
                    if(projTask.pse__Status__c != NSP_ServiceConstants.TASKCOMPLETE){
                        projTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_CANCELLED;
                    }
                    updateProjTask.add(projTask);
                }
            }
        }
    }

    // REPORT_Integra_FN refactored
    private  void createProjecttaskforReportingIntegra(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == REPORT_Integra_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // REPORT_Custom401k_FN refactored
    private  void createProjecttaskforReportingCustom(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == REPORT_Custom401k_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // REPORT_OTHER_FN refactored
    private  void createProjecttaskforReportingOther(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == REPORT_OTHER_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

        // COBRA_FN refactored
    private  void createProjecttaskforCOBRA(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == COBRA_FN){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if (eachProjecttask != null && ipa != null ) {
                if(ipRec.Have_name_s_of_COBRA_takeovr_employees__c == NSP_ServiceConstants.NO){
                    eachProjecttask.Name = NSP_ServiceConstants.COBRA_MISSING_NAMES;
                }else{
                    eachProjecttask.Name = NSP_ServiceConstants.COBRATask;
                }
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // COBRA_FORM_COLLECTED_FN , COBRA_FORM_NOT_COLLECTED_FN refactored
    private  void createProjectTaskForCOBRAForm(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == COBRA_FORM_COLLECTED_FN || automation == COBRA_FORM_NOT_COLLECTED_FN ){
            String yesOrNoConstant;
            String formCollectedTemplate;
            pse__Project_Task__c eachProjecttask = null;
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            yesOrNoConstant = (automation == COBRA_FORM_COLLECTED_FN) ? NSP_ServiceConstants.YES : NSP_ServiceConstants.NO;
            formCollectedTemplate = (automation == COBRA_FORM_COLLECTED_FN) ? NSP_ServiceConstants.COBRA_FORM_COLLECTED_YES : NSP_ServiceConstants.COBRA_FORM_COLLECTED_NO;
            List<String> lstNamesEmployees = new List<String>();
            if(ipa != null && ipRec != null && !String.isBlank(ipRec.NSP_COBRA_Takeover_Emp_Details__c)){
                lstNamesEmployees = ipRec.NSP_COBRA_Takeover_Emp_Details__c.split(',');
                if(lstNamesEmployees != null && lstNamesEmployees.size() > 0){
                    for(String empName : lstNamesEmployees){
                        List<String> empDetails = empName?.split('~');
                        if(empDetails.size() > 1 && empDetails[1] == yesOrNoConstant){
                            eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
                            if(eachProjecttask != null){
                                eachProjectTask.Name = formCollectedTemplate.replace('<WSEE Name>', empDetails[0]);
                                projectTaskToInsertList.add(eachProjecttask);
                            }
                        }
                    }
                }
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // LOA_INFO_FN
    private  void createProjecttaskforLOAInfo(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == LOA_INFO_FN ){
            pse__Project_Task__c eachProjecttask = null;
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            List<String> lstNamesEmployees = new List<String>();
            if(ipa != null && ipRec != null && !String.isBlank(ipRec.NSP_Employee_Details_On_LOA__c)) {
                lstNamesEmployees = ipRec.NSP_Employee_Details_On_LOA__c.split(',');
                for(String emplyName : lstNamesEmployees){
                    lstNamesEmployees = emplyName?.trim().split('~');
                    if(lstNamesEmployees[2] == NSP_ServiceConstants.NO){
                        eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
                        if(eachProjecttask != null){
                            eachProjecttask.Name = NSP_ServiceConstants.EMPLOYEE_LOA_INFO_YES.replace('<WSEE Name>',lstNamesEmployees[0]);
                            eachProjecttask.NSP_Detail__c=NSP_ServiceConstants.LOADETAILS;
                            projectTaskToInsertList.add(eachProjecttask);
                        }
                    }
                }
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // MISSING_LOA_FN
    private  void createProjecttaskforMissingLOA(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == MISSING_LOA_FN ){
            pse__Project_Task__c eachProjecttask = genericPMTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null) {
                eachProjecttask.NSP_Detail__c=NSP_ServiceConstants.LOADETAILS;
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // Client Sposored Plan Type FSA - atuomation
    private  void createSubtaskforClientSposoredPlan(
        String automation ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if ( proj != null && automation == CT_SPONSORED_PLAN_FN
            && ( proj.pse__Project_Tasks__r != null )
            && !proj.pse__Project_Tasks__r.isEmpty()
           )
        {
            for( pse__Project_Task__c pt : proj.pse__Project_Tasks__r) {
                if ( pt.Name == 'CSP Client Authorization/Cafeteria Plan documentation collected') {
                    this.createTaskForHealthCareFSA(proj,ipRecId,ipwithValue,workCalendarId,pt);
                    this.createTaskForHSA(proj,ipRecId,ipwithValue,workCalendarId,pt);
                    this.createTaskForDependentCareFSA(proj,ipRecId,ipwithValue,workCalendarId,pt);
                    this.createTaskForMedical(proj,ipRecId,ipwithValue,workCalendarId,pt);
                    this.createTaskForDental(proj,ipRecId,ipwithValue,workCalendarId,pt);
                    this.createTaskForVision(proj,ipRecId,ipwithValue,workCalendarId,pt);
                }
            }
        }
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

    private void getIPRecords(){
        for (Set<Id> ipRecords : ipRecordsByAutomation.values()) {
                ipIds.addAll(ipRecords);
        }
        Map<Id, sObject> dbRec = new Map<Id, sObject>(
            [
                SELECT
                    Id ,
                    NSP_Payroll_Specialist__c ,
                    First_Pay_Date__c ,
                    NSP_Payroll_Specialist__r.pse__Salesforce_User__c ,
                    NSP_Transition_Specialist__c ,
                    NSP_OT_Representative__c ,
                    NSP_Client_Liaison__c ,
                    NSP_HR_Specialist__c ,
                    NSP_HR_Specialist__r.NSP_Work_email__c ,
                    NSP_Client_Liaison__r.NSP_Work_email__c ,
                    NSP_OT_Representative__r.NSP_Work_email__c ,
                    NSP_Transition_Specialist__r.NSP_Work_email__c ,
                    NSP_Payroll_Specialist__r.NSP_Work_email__c ,
                    NSP_Onboarding_Specialist_Coordinator__c ,
                    NSP_Onboarding_Specialist_Coordinator__r.pse__Salesforce_User__c ,
                    NSP_Onboarding_Specialist_Coordinator__r.Email ,
                    NSP_Project_Manager__c ,
                    NSP_Project_Manager__r.Name ,
                    NSP_Project_Manager__r.NSP_Work_email__c ,
                    NSP_HR_Quality_Support_Team_Member__c ,
                    NSP_HR_Quality_Support_Team_Member__r.NSP_Work_email__c ,
                    NSP_HR_Quality_Support_Team_Member__r.pse__Salesforce_User__c ,
                    NSP_Project_Manager__r.NSP_Job_Title__c ,
                    NSP_Project_Manager__r.pse__Salesforce_User__c ,
                    Account__c ,
                    Account__r.Name ,
                    NSP_Old_Benefits_Package__c ,
                    Benefits_Package__c ,
                    NSP_Old_Effective_Date_EPLI__c ,
                    NSP_Old_Insperity_Ben_effective_date__c
                FROM Implementation_Profile__c
                WHERE ( Id IN :ipIds )
            ]
        );
        data.put(IMPL_PROFILE_IDENTIFIER, dbRec);
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

    public static NSP_Implementation_Profile_Automation__c createIPAutomation(Id ipRecId, String automationName, String fnName, String section, string recordType){
        NSP_Implementation_Profile_Automation__c ipAautomation = new NSP_Implementation_Profile_Automation__c();
        ipAautomation.NSP_Class_Name__c = NSP_ServiceConstants.IP_PROJECTTASK_AUTOMATIONCLASS;
        ipAautomation.Name = automationName;
        ipAautomation.NSP_Method_Name__c = fnName;
        ipAautomation.NSP_Section__c = section;
        ipAautomation.NSP_Implementation_Profile__c = ipRecId;
        ipAautomation.NSP_Record_Type__c = recordType;
        ipAautomation.NSP_Last_Run__c = System.now();
        return ipAautomation;
    }

    public static NSP_Implementation_Profile_Automation__c  automationRecordUpdate(Id ipRecId, String automationName, String fnName, string recordType ,String section ){
        NSP_Implementation_Profile_Automation__c IPAautomation = new  NSP_Implementation_Profile_Automation__c();
        try{
            NSP_Implementation_Profile_Automation__c newIPAautomation = new  NSP_Implementation_Profile_Automation__c();
            NSP_Implementation_Profile_Automation__c ipAautomationUpdate = new  NSP_Implementation_Profile_Automation__c();
            ipAautomationUpdate = [Select Id ,NSP_Record_Type__c,NSP_Last_Run__c FROM NSP_Implementation_Profile_Automation__c
                                   WHERE Name=: automationName AND  NSP_Method_Name__c=:fnName  AND NSP_Record_Type__c =: recordType
                                   AND NSP_Implementation_Profile__c =:ipRecId];
            if(ipAautomationUpdate!=null){
                ipAautomationUpdate.NSP_Last_Run__c = System.now();
                if( ipAautomationUpdate.NSP_Record_Type__c == null){
                    ipAautomationUpdate.NSP_Record_Type__c = recordType;
                }
                update ipAautomationUpdate;
                IPAautomation=ipAautomationUpdate;
            }
            else if(ipAautomationUpdate==null){
                newIPAautomation= createIPAutomation( ipRecId,  automationName,  fnName,section,recordType);
                Insert newIPAautomation;
                IPAautomation=newIPAautomation;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_Implprofile_ServiceHelperUpdate.class.getName() ,
                'automationRecordUpdate' ,
                e
            );
        }
        return IPAautomation;
    }

    private Id getMilestoneId(List<pse__Milestone__c> listOfMilestone, String milestoneName){
        if(!listOfMilestone.isEmpty()){
            for(pse__Milestone__c milestone:listOfMilestone){
                if(milestone.Name==milestoneName){
                    return milestone.Id;
                }
            }
        }
        return null;
    }

    private void getGroupId(){
        for(Group groupRecord: [SELECT Id, Name,Type FROM Group WHERE Type='Queue']){
            mapofGroupIds.put(groupRecord.Name,groupRecord.Id);
        }
    }

    private Id getParentTask( pse__Proj__c proj ) {
        String parentTaskId = null;
        pse__Proj__c local = null;
        if ( ( proj != null )
            && ( proj.Id != null )
            && data.containsKey(PROJECT_IDENTIFIER)
            && ( data.get(PROJECT_IDENTIFIER) != null )
            )
        {
            Map<Id,sObject> dbRec=data.get(PROJECT_IDENTIFIER);
            if ( dbRec.containsKey( proj.Id ) && ( dbRec.get( proj.Id ) != null ) ) {
                local = (pse__Proj__c)dbRec.get( proj.Id );
            }
        }
        if ( ( local != null ) && ( local.pse__Project_Tasks__r != null ) ) {
            for ( pse__Project_Task__c projTask:local.pse__Project_Tasks__r ) {
                if ( projTask.Name == 'Review and Address FLSA Compliance Issues with Client' ) {
                    parentTaskId = projTask.Id;
                    break;
                }
            }
        }
        return parentTaskId;
    }

    //
    // MethodName: checkInternalDiscovery
    // Description : This Method check Insperity effective date for Payroll/Worker’s Comp/EPLI, Insperity benefits effective date or the Package is updated
    // Params:       Implementation_Profile__c newIp, Implementation_Profile__c existingRecp
    // Author :      Bindushree R
    //
    private void checkInternalDiscovery(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp) {
        if (automationsToExecute.contains(INTERNAL_DISCOVERY_FN)
            && newIp != null
            && newIp.RecordTypeId == ipFSORecordTypeId
            && newIp.NSP_Project__c != null
            && (existingRecp == null
                || (newIp.Effective_Date_Payroll_Worker_comp_EPLI__c != null && newIp.Effective_Date_Payroll_Worker_comp_EPLI__c != newIp.NSP_Old_Effective_Date_EPLI__c)
                || (newIp.Insperity_benefits_effective_date__c != null && newIp.Insperity_benefits_effective_date__c != newIp.NSP_Old_Insperity_Ben_effective_date__c)
                || (newIp.Benefits_Package__c != null && newIp.Benefits_Package__c != newIp.NSP_Old_Benefits_Package__c)
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, INTERNAL_DISCOVERY_FN);
        }
    }

    private void emailNotifyInternalDiscovery(
        String automation ,
        Id ipRecId
    )
    {
        if(automation == INTERNAL_DISCOVERY_FN && newIPs != null){
            Implementation_Profile__c ipRec = newIPs.get( ipRecId );
            pse__Proj__c proj = (pse__Proj__c)data.get( PROJECT_IDENTIFIER ).get( ipRec.NSP_Project__c );
            if ( !proj.pse__Project_Tasks__r.isEmpty() ) {
                List<String> completedTasks = mapOfCompletedTasks.get( proj.Id );
                if ( completedTasks != null && completedTasks.contains( NSP_ServiceConstants.CLIENTTRANSITION ) ) {
                    Implementation_Profile__c ipwithValue=(Implementation_Profile__c)data.get( IMPL_PROFILE_IDENTIFIER ).get( ipRecId );
                    //get list of email address for to address
                    List<String> listOfTOAddresses = NSP_Implprofile_ServiceHelperUpdate.getToAddresses( ipwithValue );
                    //prepare email template for subject and body
                    Boolean isSendEmail = NSP_Implprofile_ServiceHelperUpdate.getIsSendEmail( ipRec );
                    String subjectString = ''
                        + ipRec.NSP_AIMS_Client_Name__c
                        + ' (' + ipRec.NSP_AIMS_ClientNo__c + ')'
                        + ': Key Information updated'
                        ;
                    String mailBody = NSP_Implprofile_ServiceHelperUpdate.prepareMailBody( ipRec , ipwithValue );
                    // update IP record
                    String impProfKey = proj.Id + '~' + ipRec.Name;
                    Implementation_Profile__c impProfile = new Implementation_Profile__c();
                    impProfile.Id = ipRec.Id;
                    impProfile.NSP_Old_Effective_Date_EPLI__c = ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c;
                    impProfile.NSP_Old_Insperity_Ben_effective_date__c = ipRec.Insperity_benefits_effective_date__c;
                    impProfile.NSP_Old_Benefits_Package__c = ipRec.Benefits_Package__c;
                    impProfileToUpdate.put( impProfKey , impProfile );
                    NSP_Implprofile_ServiceHelperUpdate.sendMail(
                        subjectString ,
                        mailBody ,
                        listOfTOAddresses ,
                        isSendEmail
                    );
                }
            }
        }
    }

    // MethodName: emailNotifyInternalDiscovery
    // Description : This Method trigger email for FSO IP
    // Author : Bindushree R
    private static Boolean getIsSendEmail( Implementation_Profile__c ipRec ) {
        Boolean isSendEmail = false;
        if ( ipRec!= null
            && (
                ( ( ipRec.NSP_Old_Effective_Date_EPLI__c != null ) && ( ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c != ipRec.NSP_Old_Effective_Date_EPLI__c ) )
                || ( ( ipRec.NSP_Old_Insperity_Ben_effective_date__c != null ) && ( ipRec.Insperity_benefits_effective_date__c != ipRec.NSP_Old_Insperity_Ben_effective_date__c ) )
                || ( ( ipRec.NSP_Old_Benefits_Package__c != null ) && ( ipRec.Benefits_Package__c != ipRec.NSP_Old_Benefits_Package__c ) )
                )
            )
        {
            isSendEmail = true;
        }
        return isSendEmail;
    }

    private static List<String> getToAddresses( Implementation_Profile__c ipwithValue ) {
        List<String> listOfTOAddresses = new List<String>();
        listOfTOAddresses.addAll( NSP_Implprofile_ServiceHelperUpdate.metadataInstanceEmails );
        if ( ipwithValue!= null ) {
            listOfTOAddresses = NSP_Implprofile_ServiceHelperUpdate.addWorkEmail(
                ipwithValue.NSP_Transition_Specialist__r ,
                listOfTOAddresses
            );
            listOfTOAddresses = NSP_Implprofile_ServiceHelperUpdate.addWorkEmail(
                ipwithValue.NSP_OT_Representative__r ,
                listOfTOAddresses
            );
            listOfTOAddresses = NSP_Implprofile_ServiceHelperUpdate.addWorkEmail(
                ipwithValue.NSP_Client_Liaison__r ,
                listOfTOAddresses
            );
            listOfTOAddresses = NSP_Implprofile_ServiceHelperUpdate.addWorkEmail(
                ipwithValue.NSP_Payroll_Specialist__r ,
                listOfTOAddresses
            );
            listOfTOAddresses = NSP_Implprofile_ServiceHelperUpdate.addWorkEmail(
                ipwithValue.NSP_HR_Specialist__r ,
                listOfTOAddresses
            );
            listOfTOAddresses = NSP_Implprofile_ServiceHelperUpdate.addWorkEmail(
                ipwithValue.NSP_HR_Quality_Support_Team_Member__r ,
                listOfTOAddresses
            );
            listOfTOAddresses = NSP_Implprofile_ServiceHelperUpdate.addWorkEmail(
                ipwithValue.NSP_Project_Manager__r ,
                listOfTOAddresses
            );
        }
        return listOfTOAddresses;
    }

    private static List<String> addWorkEmail( Contact reference , List<String> collection ) {
        if ( collection == null ) {
            collection = new List<String>();
        }
        if ( ( reference != null )
            && String.isNotBlank( reference.NSP_Work_email__c )
            )
        {
            collection.add( reference.NSP_Work_email__c );
        }
        return collection;
    }

    private static List<String> metadataInstanceEmails {
        private get {
            if ( metadataInstanceEmails == null ) {
                List<String> local = new List<String>();
                local = NSP_Implprofile_ServiceHelperUpdate.addMetadataInstanceEmail(
                    NSP_Implprofile_ServiceHelperUpdate.INTERNAL_DISCOVERY_FN ,
                    local
                );
                local = NSP_Implprofile_ServiceHelperUpdate.addMetadataInstanceEmail(
                    NSP_ServiceConstants.ALLOSCOORDINATOR ,
                    local
                );
                local = NSP_Implprofile_ServiceHelperUpdate.addMetadataInstanceEmail(
                    NSP_ServiceConstants.HRSUPPORT ,
                    local
                );
                local = NSP_Implprofile_ServiceHelperUpdate.addMetadataInstanceEmail(
                    NSP_ServiceConstants.ORIENTCOORDINATOR ,
                    local
                );
                local = NSP_Implprofile_ServiceHelperUpdate.addMetadataInstanceEmail(
                    NSP_ServiceConstants.CLIENTACCOUNTMANAGEMENT ,
                    local
                );
                metadataInstanceEmails = local;
            }
            return metadataInstanceEmails;
        }
        private set;
    }

    private static List<String> addMetadataInstanceEmail( String key , List<String> collection ) {
        if ( collection == null ) {
            collection = new List<String>();
        }
        String value = NSP_Implprofile_ServiceHelperUpdate.getMetadataInstanceEmail( key );
        if ( String.isNotBlank( value ) ) {
            collection.add( value );
        }
        return collection;
    }

    private static String getMetadataInstanceEmail( String key ) {
        String response = null;
        if ( String.isNotBlank( key ) ) {
            NSP_PEO_Implementations__mdt instance = NSP_PEO_Implementations__mdt.getInstance( key );
            if ( ( instance != null ) && String.isNotBlank( instance.NSP_Email_Address__c ) ) {
                response = instance.NSP_Email_Address__c;
            }
        }
        return response;
    }

    private static String prepareMailBody( Implementation_Profile__c ipRec , Implementation_Profile__c ipwithValue ) {
        String mailBody = '';
        if ( ( ipRec != null ) && ( ipWithValue != null ) ) {
            mailBody += 'The following information for '
                + ipRec.NSP_AIMS_Client_Name__c
                + ' ('
                + ipRec.NSP_AIMS_ClientNo__c
                + ')'
                ;
            mailBody += 'has been updated since the Transition Meeting.'+'<br/><br/>';
            if ( ipRec.NSP_Old_Effective_Date_EPLI__c != null
                && ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c != ipRec.NSP_Old_Effective_Date_EPLI__c
                )
            {
                mailBody += 'The Insperity effective date for Payroll/Worker’s Comp/EPLI has changed from '
                    + ipRec.NSP_Old_Effective_Date_EPLI__c.format()
                    + ' to '
                    + NSP_Implprofile_ServiceHelperUpdate.safeDateFormat( ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c )
                    + '.'
                    ;
            }
            mailBody += '<br/>';
            if ( ipRec.NSP_Old_Insperity_Ben_effective_date__c != null
                && ipRec.Insperity_benefits_effective_date__c != ipRec.NSP_Old_Insperity_Ben_effective_date__c
                )
            {
                mailBody += 'The Insperity benefits effective date has changed from '
                    + (ipRec.NSP_Old_Insperity_Ben_effective_date__c).format()
                    + ' to '
                    + NSP_Implprofile_ServiceHelperUpdate.safeDateFormat( ipRec.Insperity_benefits_effective_date__c )
                    + '.'
                    ;
            }
            mailBody += '<br/>';
            if ( ipRec.NSP_Old_Benefits_Package__c != null
                && ipRec.Benefits_Package__c != ipRec.NSP_Old_Benefits_Package__c
                )
            {
                mailBody += 'The Medical Package has changed from  '
                    + ipRec.NSP_Old_Benefits_Package__c
                    + ' to '
                    + NSP_Implprofile_ServiceHelperUpdate.safeStringFormat( ipRec.Benefits_Package__c )
                    + '.'
                    ;
            }
            mailBody += '<br/><br/>'+'Regards,'+'<br/>';
            mailBody += ipwithValue.NSP_Project_Manager__r.Name
                + '<br/>'
                ;
        }
        return mailBody;
    }

    private static String safeDateFormat( Date d ) {
        return ( ( d == null ) ? '' : d.format() );
    }

    private static String safeStringFormat( String s ) {
        return ( String.isBlank( s ) ? '' : s );
    }

    private static void sendMail(
        String subjectString ,
        String mailBody ,
        List<String> listOfTOAddresses ,
        Boolean isSendEmail
        )
    {
        if ( String.isNotBlank( subjectString )
            && ( listOfTOAddresses != null )
            && !listOfTOAddresses.isEmpty()
            && isSendEmail
            )
        {
            NSP_ProjectTaskTriggerEmailNotification.sendMail(
                subjectString ,
                mailBody ,
                listOfTOAddresses ,
                null ,
                null
            );
        }
    }

    //
    // MethodName: checkOnsiteDiscovery
    // Description : This Method check Insperity effective date for Payroll/Worker’s Comp/EPLI, Insperity benefits effective date or the Package is updated for MM IP
    // Params: Implementation_Profile__c newIp, Implementation_Profile__c existingRecp
    // Author : Bindushree R
    //
    private void checkOnsiteDiscovery(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp) {
        if ( automationsToExecute.contains( ONSITE_DISCOVERY_FN )
            && newIp != null
            && newIp.RecordTypeId == ipMMRecordTypeId
            && newIp.NSP_Project__c != null
            && ( ( existingRecp == null )
                || ( newIp.Effective_Date_Payroll_Worker_comp_EPLI__c != null
                    && newIp.Effective_Date_Payroll_Worker_comp_EPLI__c != newIp.NSP_Old_Effective_Date_EPLI__c
                    )
                || (newIp.Insperity_benefits_effective_date__c != null
                    && newIp.Insperity_benefits_effective_date__c != newIp.NSP_Old_Insperity_Ben_effective_date__c
                    )
                || ( newIp.Benefits_Package__c != null
                    && newIp.Benefits_Package__c != newIp.NSP_Old_Benefits_Package__c
                    )
                )
            )
        {
            updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, ONSITE_DISCOVERY_FN);
        }
    }

    //
    // MethodName: emailNotifyOnsiteDiscovery
    // Description : This Method trigger email for MM IP
    // Author : Bindushree R
    //
    private void emailNotifyOnsiteDiscovery(String automation, Id ipRecId) {
        if (automation == ONSITE_DISCOVERY_FN && newIPs != null ) {
            String subjectString = null;
            String mailBody = '' ;
            String projectTaskId = '';
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(ONSITE_DISCOVERY_FN);
            NSP_PEO_Implementations__mdt pf1 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.CLIENTACCOUNTMANAGEMENT);
            pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
            if ( (isRerun || ipRec.NSP_Form_Completed__c)
                && !isSaveForm
                && proj != null
                && proj.pse__Project_Tasks__r.size() > 0
                )
            {
                List<String> completedTasks = mapOfCompletedTasks.get(proj.Id);
                if (completedTasks != null
                    && completedTasks.contains(NSP_ServiceConstants.ONSITEDISCOVERY)
                    )
                {
                    projectTaskId = getProjectTaskId(proj, NSP_ServiceConstants.ONSITEDISCOVERY);
                    Implementation_Profile__c ipwithValue = (Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                    List<String> listOfTOAddresses = prepareEmailAddresses(pf, pf1, proj);
                    subjectString = proj.pse__Account__r.Name+' : Key Information updated';
                    mailBody = prepareEmailTemplate(ipRec, ipwithValue, proj,mailBody);
                    updateImplementationProfile(proj,ipRec);
                    if (listOfTOAddresses != null
                        && !listOfTOAddresses.isEmpty()
                        && String.isNotBlank( mailBody )
                        && String.isNotBlank( projectTaskId )
                        )
                    {
                        NSP_ProjectTasksTriggerHelper.sendEmail(listOfTOAddresses,subjectString,mailBody,projectTaskId);
                    }
                }
            }
        }
    }

    private List<String> prepareEmailAddresses(NSP_PEO_Implementations__mdt pf, NSP_PEO_Implementations__mdt pf1, pse__Proj__c proj) {
        List<String> listOfTOAddresses = new List<String>();
        if(pf != null ){
            listOfTOAddresses.add(pf.NSP_Email_Address__c);
        }
        if(pf1 != null ){
            listOfTOAddresses.add(pf1.NSP_Email_Address__c);
        }
        if (proj != null
            && proj.Project_Teams__r != null
            && proj.Project_Teams__r.size() > 0
            )
        {
            for (NSP_Project_Team__c projTeam : proj.Project_Teams__r) {
                if ( projTeam.NSP_Assignee__c != null
                    && String.isNotBlank( projTeam.NSP_Assignee__r.NSP_Work_email__c )
                    && ( projTeam.NSP_Role__c == NSP_ServiceConstants.SrHrSpecialist
                        || projTeam.NSP_Role__c == NSP_ServiceConstants.AccountExecutive
                        || projTeam.NSP_Role__c == NSP_ServiceConstants.PAYROLL_SPECIALIST
                        || projTeam.NSP_Role__c == NSP_ServiceConstants.PayrollProjectManager
                        )
                    )
                {
                    listOfTOAddresses.add(projTeam.NSP_Assignee__r.NSP_Work_email__c);
                }
            }
        }
        return listOfTOAddresses;
    }

    private String prepareEmailTemplate(Implementation_Profile__c ipRec, Implementation_Profile__c ipwithValue, pse__Proj__c proj, String mailBody) {
        String mailHeader = '';
        String mailFooter = '';
        if(proj != null
            && ipwithValue != null
            && proj.pse__Account__r != null
        )
        {
            mailHeader = 'The following information for  ' + proj.pse__Account__r.Name;
            mailHeader += ' has been updated since the Discovery Meeting.' + '<br/><br/>';
            mailBody = updateMailBodyForEPLI(ipRec, mailBody);
            mailBody = updateMailBodyForEffDate(ipRec, mailBody);
            mailBody = updateMailBodyForMedPkg(ipRec, mailBody);
            if(ipwithValue.NSP_Project_Manager__r != null){
                mailFooter = '<br/><br/>' + 'Regards,' + '<br/>';
                mailFooter += ipwithValue.NSP_Project_Manager__r.Name + '<br/>';
                mailFooter += ipwithValue.NSP_Project_Manager__r.NSP_Job_Title__c + '<br/>';
                mailFooter += ipwithValue.NSP_Project_Manager__r.NSP_Work_email__c + '<br/>';
            }
            if ( String.isNotBlank( mailBody ) ) {
                mailBody = mailHeader + mailBody + mailFooter ;
            }
        }
        return mailBody;
    }

    private String updateMailBodyForEPLI(Implementation_Profile__c ipRec,String mailBody) {
        mailBody = (mailBody == null) ? '' : mailBody;
        if ( ipRec != null
            && ipRec.NSP_Old_Effective_Date_EPLI__c != null
            && ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c != null
            && ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c != ipRec.NSP_Old_Effective_Date_EPLI__c
            )
        {
            mailBody +='The Insperity effective date for Payroll/Worker’s Comp/EPLI has changed from '
                + ipRec.NSP_Old_Effective_Date_EPLI__c.format() +' to '
                + ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c.format()+'. <br/>';
        }
        return mailBody;
    }

    private String updateMailBodyForEffDate(Implementation_Profile__c ipRec,String mailBody) {
        mailBody = (mailBody == null) ? '' : mailBody;
        if ( ipRec != null
            && ipRec.NSP_Old_Insperity_Ben_effective_date__c!=null
            && ipRec.Insperity_benefits_effective_date__c!=null
            && ipRec.Insperity_benefits_effective_date__c!=ipRec.NSP_Old_Insperity_Ben_effective_date__c
            )
        {
            mailBody +='The Insperity benefits effective date has changed from '
                + ipRec.NSP_Old_Insperity_Ben_effective_date__c.format() +' to '
                + ipRec.Insperity_benefits_effective_date__c.format() + '. <br/>';
        }
        return mailBody;
    }

    private String updateMailBodyForMedPkg(Implementation_Profile__c ipRec,String mailBody) {
        mailBody = (mailBody == null) ? '' : mailBody;
        if (ipRec != null
            && ipRec.NSP_Old_Benefits_Package__c != null
            && ipRec.Benefits_Package__c != null
            && ipRec.Benefits_Package__c != ipRec.NSP_Old_Benefits_Package__c
            )
        {
            mailBody +='The Medical Package has changed from  '
                + ipRec.NSP_Old_Benefits_Package__c +' to '+ ipRec.Benefits_Package__c;
        }
        return mailBody;
    }

    private void updateImplementationProfile(pse__Proj__c proj, Implementation_Profile__c ipRec) {
        if(proj != null && ipRec != null ){
            String implProfKey = proj.Id + '~' + ipRec.Name;
            Implementation_Profile__c impProfile = new Implementation_Profile__c();
            impProfile.Id = ipRec.Id;
            impProfile.NSP_Old_Effective_Date_EPLI__c = ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c;
            impProfile.NSP_Old_Insperity_Ben_effective_date__c = ipRec.Insperity_benefits_effective_date__c;
            impProfile.NSP_Old_Benefits_Package__c = ipRec.Benefits_Package__c;
            impProfileToUpdate.put(implProfKey,impProfile);
        }
    }

    // enrollFee_FN refactored
    private void createProjecttaskforEnrollFee(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == enrollFee_FN){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            if(eachProjecttask != null && ipa != null){
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    private void createProjectTaskForDataVerification(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == DATA_VERIFICATION){
            pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            DateTime now = DateTime.now();
            Integer hour = now.hour();
            Integer minute = now.minute();
            Integer second = now.second();
            if ( eachProjecttask != null
                && ipa != null
                && ipwithValue != null
                && ipwithValue.First_Pay_Date__c != null
                )
            {
                    eachProjecttask.pse__Start_Date_Time__c = DateTime.now();
                    DateTime endDate = DateTime.newInstance(
                    ipwithValue.First_Pay_Date__c.year() ,
                    ipwithValue.First_Pay_Date__c.month() ,
                    ipwithValue.First_Pay_Date__c.day() ,
                    hour ,
                    minute ,
                    second
                );
                eachProjecttask.pse__End_Date_Time__c = endDate.addDays(-7);
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }
    private void createProjectTaskForFlsaExemptionReview(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == FLSA_EXEMPTION_REVIEW){
            pse__Project_Task__c eachProjecttask = hrClientImplementationOwner(proj,pta,ipRecId,ipwithValue,workCalendarId);
            NSP_Implementation_Automations__mdt ipa = NSP_Implementation_Automations__mdt.getInstance(automation);
            DateTime now = DateTime.now();
            if ( eachProjecttask != null && ipa != null)
            {
                eachProjecttask.pse__Start_Date_Time__c = DateTime.now();
                eachProjecttask.pse__End_Date_Time__c = now.addDays(30);
                eachProjecttask.pse__Parent_Task__c = this.getParentTask(proj);
                projectTaskToInsertList.add(eachProjecttask);
                ipAutomationRecords.add(
                    createIPAutomation(
                        ipRecId,
                        ipa.NSP_Automation_Name__c,
                        ipa.NSP_Method_Name__c,
                        ipa.NSP_Section__c,NSP_ServiceConstants.FSOProfile
                    )
                );
            }
        }
    }

    // SUBTASK FOR - enrollFee_Subtask_FN
    private void createSubtaskforEnrollment(
        String automation ,
        NSP_ProjectTask_Automation__mdt pta ,
        pse__Proj__c proj ,
        Id ipRecId ,
        Implementation_Profile__c ipwithValue ,
        Id workCalendarId
        )
    {
        if(automation == enrollFee_Subtask_FN && proj != null ){
            for(pse__Project_Task__c pt: proj.pse__Project_Tasks__r){
                if(pt.Name==NSP_ServiceConstants.FIRSTPAYROLL){
                    pse__Project_Task__c eachProjecttask = genericPayrollTask(proj,pta,ipRecId,ipwithValue,workCalendarId);
                    if(eachProjecttask != null){
                        eachProjecttask.pse__Parent_Task__c=pt.Id;
                        projectTaskToInsertList.add(eachProjecttask);
                    }
                }
            }
        }
    }

    private pse__Project_Task__c createSubtaskCspDocsNotReceivedRecord(
        pse__Proj__c proj,
        NSP_ProjectTask_Automation__mdt pta,
        Id ipRecId,
        Implementation_Profile__c ipWithValue,
        Id workCalendarId,
        pse__Project_Task__c pt
        )
    {
        pse__Project_Task__c eachProjectTask = this.genericPMTask(
            proj,
            pta,
            ipRecId,
            ipWithValue,
            workCalendarId
        );
        if (eachProjectTask != null && pt != null && pt.Id != null ) {
            eachProjectTask.pse__Parent_Task__c = pt.Id;
            eachProjectTask.pse__Hierarchy_Depth__c = 1;
        }
        return eachProjectTask;
    }

}