/**
* Represents the Implementation profile tirgger for update scenario.
*/ 
public class NSP_Implprofile_ServiceHelperUpdate {
    private  Boolean isRerun =false;
    private Boolean isSaveForm = false;
    private Map<Id, Implementation_Profile__c> newIPs = null; 
    private Map<Id, Implementation_Profile__c> oldIPs = null;
    private Map<String, Set<Id>> ipRecordsByAutomation = new Map<String, Set<Id>>();
    private List<sObject> recToInsert = new List<sObject>();
    private List<sObject> recToUpdate = new List<sObject>();
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
    private static final String CT_SPONSORED_PLAN_FN = 'ctfSponsoredPlan';
    private static final String GENERAL_LIABILITY_FN = 'generalLiability';
    private static final String EEO_FILING_FN = 'EEOFiling';
    private static final String CLIENT_HANDBOOK_FN = 'clientHandbook';
    private static final String EDC_FN = 'EDCCollected';
    private static final String PAYROLL_LOCATIONS_FN = 'payrollLocations';
    private static final String PAYROLL_DEPARTMENTS_FN = 'payrollDepartments';
    private static final String PAYROLL_JOBCOSTING_FN = 'payrollJobCosting';
    private static final String PAYROLL_REGISTER_FN='payrollRegister';
    private static final String GARNISHMENT_FN='garnishments';
    private static final String TAX_LEVIES_FN='taxLevies';
    private static final String POST_DEDUCTION_FN='postDeduction';
    private static final String RETIRE_PLAN_FN='retirementPlan';
    private static final String POSTTAX_LOANS_FN='posttaxLoans';
    private static final String SPECIAL_RELABEL_FN='specialRelabel';
    private static final String REPORT_Integra_FN='reportIntegra';
    private static final String REPORT_Custom401k_FN='reportCustom401k';
    private static final String REPORT_JOBCOSTING_FN='reportJobcosting';
    private static final String REPORT_OTHER_FN='reportOther';
    private static final String COBRA_FN='COBRA';
    private static final String COBRA_FORM_COLLECTED_FN='employeeFormCollected';
    private static final String LOA_INFO_FN='LOA_INFO_FN';
    private static final String MISSING_LOA_FN='MISSING_LOA';
    private static final String SUBTASK_GARNISH_FN='garnishSubtask';
    private static final String SUBTASK_LEVIES_FN='leviesSubtask';
    private static final String INTERNAL_DISCOVERY_FN ='NSP_Internal_Discovery';
    private static final String ONSITE_DISCOVERY_FN ='NSP_Onsite_Discovery';
    private static final String premierPerformance_FN ='premierPerformance';
    private static final String enrollFee_FN ='enrollFee';
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
                    this.automationsToExecute.addAll(new List<String>{ CT_SPONSORED_PLAN_FN,GENERAL_LIABILITY_FN,EEO_FILING_FN,CLIENT_HANDBOOK_FN,EDC_FN,
                        PAYROLL_LOCATIONS_FN,PAYROLL_DEPARTMENTS_FN,PAYROLL_JOBCOSTING_FN,PAYROLL_REGISTER_FN,GARNISHMENT_FN,
                        TAX_LEVIES_FN,POST_DEDUCTION_FN,RETIRE_PLAN_FN,POSTTAX_LOANS_FN,SPECIAL_RELABEL_FN,REPORT_Integra_FN,REPORT_Custom401k_FN,
                        REPORT_JOBCOSTING_FN,REPORT_OTHER_FN,COBRA_FN,LOA_INFO_FN,MISSING_LOA_FN,COBRA_FORM_COLLECTED_FN,SUBTASK_GARNISH_FN,
                        SUBTASK_LEVIES_FN,INTERNAL_DISCOVERY_FN,ONSITE_DISCOVERY_FN,premierPerformance_FN,enrollFee_FN});
                }
    
    public NSP_Implprofile_ServiceHelperUpdate(Id ipRecord, String automationName){
        this.newIPs =  NSP_ImpAutomationsController.getIpRecord(ipRecord);
        this.isRerun=true;
        this.automationsToExecute.add(automationName);
    }
    
        
    public NSP_Implprofile_ServiceHelperUpdate(Boolean isSave){
        this.isSaveForm = isSave;
    }
    public Map<String, Set<Id>>  executeAutomation() {
        Map<String, Set<Id>> ipRecordsByAutomationMap = new  Map<String, Set<Id>> ();
        try{
            start();
            execute();
            finish();
            ipRecordsByAutomationMap= ipRecordsByAutomation;
        }catch(Exception ex ){
            NSP_ErrorLogHandler.logSaveException('NSP_Implprofile_ServiceHelperUpdate', 'executeAutomation', ex.getMessage());
        }
        return ipRecordsByAutomationMap;
    }
    
    private void start() {
        //get all Employee Data
        // Create a set of eligible records which we need to pull
        populateEligibleRecords();
        // Fetch Project Records from DB 
        if(ipRecordsByAutomation.size()>0){

            getProjectDBRecords();
            getImplAutomationRecords();     
            //get all project manager for IP
            getIPRecords();
            //get all group id for queue 
            getGroupId();
        }
        
    }
    
    private void execute(){
        if(ipRecordsByAutomation.containsKey(CT_SPONSORED_PLAN_FN)){
            createProjecttaskforSponsporedplan();
        }
        if(ipRecordsByAutomation.containsKey(GENERAL_LIABILITY_FN)){
            createProjecttaskforReceivedCertificate();
        }
        if(ipRecordsByAutomation.containsKey(EEO_FILING_FN)){
            createProjecttaskforEEO();
        }
        if(ipRecordsByAutomation.containsKey(CLIENT_HANDBOOK_FN)){
            createProjecttaskforClient();
        }
        if(ipRecordsByAutomation.containsKey(EDC_FN)){
            createProjecttaskforEDC();
        }
        if(ipRecordsByAutomation.containsKey(PAYROLL_LOCATIONS_FN)){
            createProjecttaskforPayrollneeds();
        }
        if(ipRecordsByAutomation.containsKey(PAYROLL_DEPARTMENTS_FN)){
            createProjecttaskforPayrollJob();
        }
        if(ipRecordsByAutomation.containsKey(PAYROLL_JOBCOSTING_FN)){
            createProjecttaskforPayrollJobCosting();
        }
        if(ipRecordsByAutomation.containsKey(PAYROLL_REGISTER_FN)){
            createProjecttaskforPayrollRegister();
        }
        if(ipRecordsByAutomation.containsKey(GARNISHMENT_FN)){
            createProjecttaskforGarnishment();
        }
        if(ipRecordsByAutomation.containsKey(TAX_LEVIES_FN)){
            createProjecttaskforTaxlevis();
        }
        if(ipRecordsByAutomation.containsKey(POST_DEDUCTION_FN)){
            createProjecttaskforPostDeduction();
        }
        if(ipRecordsByAutomation.containsKey(RETIRE_PLAN_FN)){
            createProjecttaskforRetplan();
        }
        if(ipRecordsByAutomation.containsKey(POSTTAX_LOANS_FN)){
            createProjecttaskforPosttaxded();
        }
        if(ipRecordsByAutomation.containsKey(SPECIAL_RELABEL_FN)){
            createProjecttaskforRelable();
        }
        if(ipRecordsByAutomation.containsKey(REPORT_Integra_FN)){
            createProjecttaskforReportingIntegra();
        }
        if(ipRecordsByAutomation.containsKey(REPORT_Custom401k_FN)){
            createProjecttaskforReportingCustom();
        }
        if(ipRecordsByAutomation.containsKey(REPORT_JOBCOSTING_FN)){
            createProjecttaskforReportingJob();
        }
        if(ipRecordsByAutomation.containsKey(REPORT_OTHER_FN)){
            createProjecttaskforReportingOther();
        }
        if(ipRecordsByAutomation.containsKey(COBRA_FN)){
            createProjecttaskforCOBRA();
        }
        if(ipRecordsByAutomation.containsKey(LOA_INFO_FN)){
            createProjecttaskforLOAInfo();
        }
        if(ipRecordsByAutomation.containsKey(MISSING_LOA_FN)){
            createProjecttaskforLOAInfo();
        }
        if(ipRecordsByAutomation.containsKey(COBRA_FORM_COLLECTED_FN)){
            createProjecttaskforCOBRAFormCollected();
        }
        if(ipRecordsByAutomation.containsKey(SUBTASK_GARNISH_FN)){
           createSubtaskforGarnishments();
        }
        if(ipRecordsByAutomation.containsKey(SUBTASK_LEVIES_FN)){
            createSubtaskforLevies();
        }
        if(ipRecordsByAutomation.containsKey(enrollFee_FN)){
            createProjecttaskforEnrollFee();
             createSubtaskforEnrollment();
        }  
        if(ipRecordsByAutomation.containsKey(premierPerformance_FN)){
            createProjecttaskforPermierPerfomance();
        }
        if(ipRecordsByAutomation.containsKey(INTERNAL_DISCOVERY_FN)){
            emailNotifyInternalDiscovery();
        }
        if(ipRecordsByAutomation.containsKey(ONSITE_DISCOVERY_FN)){
            emailNotifyOnsiteDiscovery();
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
        database.insert(recToInsert,false);
        List<Database.UpsertResult> upsertImpResults = Database.upsert(impProfileToUpdate.values(), false);
        NSP_ErrorLogHandler.logUpsertResultsException('NSP_Implprofile_ServiceHelperUpdate', 'impProfileToUpdate:upsertResults', upsertResults);

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
                                                       (SELECT Id, pse__Project__c,pse__Status__c, pse__Order__c, NSP_Sub_Category__c, NSP_Category__c,pse__Milestone__c, Name, NSP_Implementation_Profile_Account__c,NSP_Implementation_Account_Id__c FROM pse__Project_Tasks__r) FROM pse__Proj__c WHERE Id IN :projectIDs]);
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
            
            // All the automation methods will check the eligibility of the current record.
            if(automationsToExecute.contains(CT_SPONSORED_PLAN_FN)){
                checkForClientSposoredPlans(ipRec, existingRec);
            }
            if(automationsToExecute.contains(GENERAL_LIABILITY_FN)){
                checkforReceivedCertificate(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EEO_FILING_FN)){
                checkforEEO(ipRec, existingRec);
            }
            if(automationsToExecute.contains(CLIENT_HANDBOOK_FN)){
                checkforClientHandbook(ipRec, existingRec);
            }
            if(automationsToExecute.contains(EDC_FN)){
                checkforEDC(ipRec, existingRec);
            }
            if(automationsToExecute.contains(PAYROLL_LOCATIONS_FN)){
                checkforPayrollLocations(ipRec, existingRec);
            }
            if(automationsToExecute.contains(PAYROLL_DEPARTMENTS_FN)){
                checkforPayrollDepartments(ipRec, existingRec);
            }
            if(automationsToExecute.contains(PAYROLL_JOBCOSTING_FN)){
                checkforPayrollJobCosting(ipRec, existingRec);
            }
            if(automationsToExecute.contains(PAYROLL_REGISTER_FN)){
                checkforPayrollRegister(ipRec, existingRec);
            }
            if(automationsToExecute.contains(GARNISHMENT_FN)){
                checkforGarnishments(ipRec, existingRec);
            }
            if(automationsToExecute.contains(TAX_LEVIES_FN)){
                checkforTaxLevies(ipRec, existingRec);
            }
            if(automationsToExecute.contains(POST_DEDUCTION_FN)){
                checkforPostDeduction(ipRec, existingRec);
            }
            if(automationsToExecute.contains(RETIRE_PLAN_FN)){
                checkforRetPlan(ipRec, existingRec);
            }
            if(automationsToExecute.contains(POSTTAX_LOANS_FN)){
                checkforPostTaxLoans(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SPECIAL_RELABEL_FN)){
                checkforRelabel(ipRec, existingRec);
            }
            if(automationsToExecute.contains(REPORT_JOBCOSTING_FN)){
                checkforReportingJobCosting(ipRec, existingRec);
            }
            if(automationsToExecute.contains(REPORT_Integra_FN)){
                checkforReportingIntegra(ipRec, existingRec);
            }
            if(automationsToExecute.contains(REPORT_Custom401k_FN)){
                checkforReportingCustom(ipRec, existingRec);
            }
            if(automationsToExecute.contains(REPORT_OTHER_FN)){
                checkforReportingOther(ipRec, existingRec);
            }
            if(automationsToExecute.contains(COBRA_FN)){
                checkforCOBRA(ipRec, existingRec);
            }
            if(automationsToExecute.contains(LOA_INFO_FN)){
                checkforLOAInfo(ipRec, existingRec);
            }
            if(automationsToExecute.contains(MISSING_LOA_FN)){
                checkforLOAInfo(ipRec, existingRec);
            }
            if(automationsToExecute.contains(COBRA_FORM_COLLECTED_FN)){
                checkforCOBRAFormCollected(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SUBTASK_GARNISH_FN)){
                checkforGarnishmentSubtask(ipRec, existingRec);
            }
            if(automationsToExecute.contains(SUBTASK_LEVIES_FN)){
                checkforTaxLeviesSubtask(ipRec, existingRec);
            }
            if(automationsToExecute.contains(INTERNAL_DISCOVERY_FN)){
                checkInternalDiscovery(ipRec, existingRec);
            }
            if(automationsToExecute.contains(ONSITE_DISCOVERY_FN)){
                checkOnsiteDiscovery(ipRec, existingRec);
            }
            if(automationsToExecute.contains(premierPerformance_FN)){
                checkPermierPerfomance(ipRec, existingRec);
            }
            if(automationsToExecute.contains(enrollFee_FN)){
                checkEnrollFee(ipRec, existingRec);
            }
        }
    }
    private  void checkEnrollFee(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Is_there_an_Enrollment_fee__c == null 
           || newRec.NSP_Is_there_an_Enrollment_fee__c != NSP_ServiceConstants.YES) {
               return;
           }
        
        
        if( newRec.RecordTypeId == ipFSORecordTypeId && newRec.NSP_Is_there_an_Enrollment_fee__c == NSP_ServiceConstants.YES){
            if(existingRec == null || newRec.NSP_Form_Completed__c ||  
               newRec.NSP_Is_there_an_Enrollment_fee__c != existingRec.NSP_Is_there_an_Enrollment_fee__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, enrollFee_FN);
               }
        }
    } 


    private  void checkPermierPerfomance(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.Client_Implementing_Premier_Performance__c == null 
           || newRec.Client_Implementing_Premier_Performance__c != NSP_ServiceConstants.YES) {
               return;
           }
        
        
        if( newRec.RecordTypeId == ipFSORecordTypeId && newRec.Client_Implementing_Premier_Performance__c == NSP_ServiceConstants.YES){
            if(existingRec == null || newRec.NSP_Form_Completed__c ||  
               newRec.Client_Implementing_Premier_Performance__c != existingRec.Client_Implementing_Premier_Performance__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, premierPerformance_FN);
               }
        }
    }   
    private void checkForClientSposoredPlans(Implementation_Profile__c newRec, Implementation_Profile__c existingRec) {
        
        
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c != NSP_ServiceConstants.YES
           || newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c == null) {
               return;
           }
        
        if( newRec.RecordTypeId == ipFSORecordTypeId && ((newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HCFSA) && newRec.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c == NSP_ServiceConstants.REQUESTED)
                                                                                                     ||(newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HSA) && newRec.NSP_HSA_Ongoing_CSP_cafeteria_document__c == NSP_ServiceConstants.REQUESTED)
                                                                                                     ||(newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DCFSA) && newRec.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c == NSP_ServiceConstants.REQUESTED)
                                                                                                     ||(newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.MEDICAL) && newRec.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c == NSP_ServiceConstants.REQUESTED)
                                                                                                     ||(newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DENTAL) && newRec.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c == NSP_ServiceConstants.REQUESTED)
                                                                                                     ||(newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.VISION) && newRec.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c == NSP_ServiceConstants.REQUESTED))){
                                                                                                         if(existingRec == null || newRec.NSP_Form_Completed__c || 
                                                                                                            newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c != existingRec.Spnsrd_pln_when_Insperity_hndles_payroll__c ||
                                                                                                            newRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c != existingRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c){
                                                                                                             updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CT_SPONSORED_PLAN_FN);
                                                                                                         }
                                                                                                     }
    }
    
    private  void checkforReceivedCertificate(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c != NSP_ServiceConstants.REQUESTED) {
               return;
           }
        
        
        if( newRec.RecordTypeId == ipFSORecordTypeId && newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c==NSP_ServiceConstants.REQUESTED){
            if(existingRec == null || newRec.NSP_Form_Completed__c ||  
               newRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c != existingRec.Gotten_Cvrg_Cert_Gen_Liability_Auto__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, GENERAL_LIABILITY_FN);
               }
        }
    } 
    
    private  void checkforEEO(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Client_have_EEO_filing_under__c != NSP_ServiceConstants.YES) {
               return;
           }
        
        
        if( newRec.RecordTypeId == ipFSORecordTypeId && newRec.Client_have_EEO_filing_under__c==NSP_ServiceConstants.YES ){
            
            if(existingRec == null || newRec.NSP_Form_Completed__c || 
               newRec.Client_have_EEO_filing_under__c != existingRec.Client_have_EEO_filing_under__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EEO_FILING_FN);
               }
        }
    }
    
    private  void checkforClientHandbook(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || (newRec.Gave_copy_of_PTO_sick_leave_other_policy__c != NSP_ServiceConstants.NO &&  
           newRec.Gave_copy_of_PTO_sick_leave_other_policy__c != NSP_ServiceConstants.REQUESTED)) {
               return;
           }
        
        
        if(  newRec.RecordTypeId == ipFSORecordTypeId && 
           (newRec.Gave_copy_of_PTO_sick_leave_other_policy__c==NSP_ServiceConstants.NO || newRec.Gave_copy_of_PTO_sick_leave_other_policy__c==NSP_ServiceConstants.REQUESTED)){
               if(existingRec == null || newRec.NSP_Form_Completed__c || 
                  newRec.Gave_copy_of_PTO_sick_leave_other_policy__c != existingRec.Gave_copy_of_PTO_sick_leave_other_policy__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, CLIENT_HANDBOOK_FN);
                  }
           }
    }
    
    
    private  void checkforEDC(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || (newRec.Employee_Data_Collection_EDC_collected__c != NSP_ServiceConstants.NO
               && newRec.Employee_Data_Collection_EDC_collected__c != NSP_ServiceConstants.NOTCOLLECTED)) {
                   return;
               }
        
        
        if( newRec.RecordTypeId == ipFSORecordTypeId && 
           (newRec.Employee_Data_Collection_EDC_collected__c==NSP_ServiceConstants.NO || newRec.Employee_Data_Collection_EDC_collected__c==NSP_ServiceConstants.NOTCOLLECTED)){
               if(existingRec == null  ||  newRec.NSP_Form_Completed__c ||
                  newRec.Employee_Data_Collection_EDC_collected__c != existingRec.Employee_Data_Collection_EDC_collected__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, EDC_FN);
                  }
           }
    }
    
    private  void checkforPayrollLocations(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Client_has_any_special_payroll_needs__c != NSP_ServiceConstants.YES
           || newRec.Select_all_payroll_needs_that_apply__c==null) {
               return;
           }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && 
           newRec.Client_has_any_special_payroll_needs__c==NSP_ServiceConstants.YES && newRec.Select_all_payroll_needs_that_apply__c.contains(NSP_ServiceConstants.LOCATIONS)){
               if(existingRec == null || newRec.NSP_Form_Completed__c ||  
                  newRec.Select_all_payroll_needs_that_apply__c != existingRec.Select_all_payroll_needs_that_apply__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_LOCATIONS_FN);
                  }
           }
    }
    
    private  void checkforPayrollDepartments(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Client_has_any_special_payroll_needs__c != NSP_ServiceConstants.YES
           || newRec.Select_all_payroll_needs_that_apply__c==null) {
               return;
           }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && 
           newRec.Client_has_any_special_payroll_needs__c==NSP_ServiceConstants.YES && newRec.Select_all_payroll_needs_that_apply__c.contains(NSP_ServiceConstants.DEPARTMENTS)){
               if(existingRec == null || newRec.NSP_Form_Completed__c ||  
                  newRec.Select_all_payroll_needs_that_apply__c != existingRec.Select_all_payroll_needs_that_apply__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_DEPARTMENTS_FN);
                  }
           }
    }
    
    private  void checkforPayrollJobCosting(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Client_has_any_special_payroll_needs__c != NSP_ServiceConstants.YES
           || newRec.Select_all_payroll_needs_that_apply__c==null) {
               return;
           }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && 
           newRec.Client_has_any_special_payroll_needs__c==NSP_ServiceConstants.YES && newRec.Select_all_payroll_needs_that_apply__c.contains(NSP_ServiceConstants.JOBCOSTING)){
               if(existingRec == null || newRec.NSP_Form_Completed__c ||  
                  newRec.Select_all_payroll_needs_that_apply__c != existingRec.Select_all_payroll_needs_that_apply__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_JOBCOSTING_FN);
                  }
           }
    }
    
    
    private  void checkforPayrollRegister(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if(newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || (newRec.Recent_Payroll_Register_Collected__c != NSP_ServiceConstants.NO && newRec.Recent_Payroll_Register_Collected__c != NSP_ServiceConstants.NOTCOLLECTED) ) {
               return;
           }
        
        
        if(    newRec.RecordTypeId == ipFSORecordTypeId && 
           newRec.Recent_Payroll_Register_Collected__c==NSP_ServiceConstants.NO ||newRec.Recent_Payroll_Register_Collected__c == NSP_ServiceConstants.NOTCOLLECTED){
               if(existingRec == null || newRec.NSP_Form_Completed__c ||  
                  newRec.Recent_Payroll_Register_Collected__c != existingRec.Recent_Payroll_Register_Collected__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, PAYROLL_REGISTER_FN);
                  }
           }
    }
    
    private  void checkforGarnishments(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Do_any_EEs_have_garnishments__c != NSP_ServiceConstants.YES  ) {
               return;
           }
        
        
        if(    newRec.RecordTypeId == ipFSORecordTypeId && newRec.Do_any_EEs_have_garnishments__c==NSP_ServiceConstants.YES ){
            if(existingRec == null  ||  newRec.NSP_Form_Completed__c ||
               newRec.Do_any_EEs_have_garnishments__c != existingRec.Do_any_EEs_have_garnishments__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, GARNISHMENT_FN);
               }
        }
    }

    private  void checkforGarnishmentSubtask(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Do_any_EEs_have_garnishments__c != NSP_ServiceConstants.YES || String.isBlank(newRec.NSP_Employee_Names_List_garnishments__c) ) {
               return;
           }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && newRec.Do_any_EEs_have_garnishments__c==NSP_ServiceConstants.YES
           && String.isNotBlank(newRec.NSP_Employee_Names_List_garnishments__c) ){
               if(existingRec == null || newRec.NSP_Form_Completed__c || 
                  newRec.Do_any_EEs_have_garnishments__c != existingRec.Do_any_EEs_have_garnishments__c
                  ||newRec.NSP_Employee_Names_List_garnishments__c != existingRec.NSP_Employee_Names_List_garnishments__c 
                  ||newRec.NSP_Documents_garnishments__c != existingRec.NSP_Documents_garnishments__c){

                    List<String> employeeNames = new List<String>();
                     employeeNames = newRec.NSP_Employee_Names_List_garnishments__c.split(',');
                    updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SUBTASK_GARNISH_FN);
                  }
           }
    }
    
    private  void checkforTaxLevies(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Do_any_EEs_have_tax_levies__c != NSP_ServiceConstants.YES  ) {
               return;
           }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && newRec.Do_any_EEs_have_tax_levies__c==NSP_ServiceConstants.YES ){
            if(existingRec == null || newRec.NSP_Form_Completed__c || 
               newRec.Do_any_EEs_have_tax_levies__c != existingRec.Do_any_EEs_have_tax_levies__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, TAX_LEVIES_FN);
               }
        }
    }
    
    private  void checkforTaxLeviesSubtask(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Do_any_EEs_have_tax_levies__c != NSP_ServiceConstants.YES || String.isBlank(newRec.NSP_List_Employee_Names_Levies__c)
            ) {
               return;
           }
        
        
        if(  newRec.RecordTypeId == ipFSORecordTypeId && newRec.Do_any_EEs_have_tax_levies__c==NSP_ServiceConstants.YES
           && String.isNotBlank(newRec.NSP_List_Employee_Names_Levies__c)){
               if(existingRec == null || newRec.NSP_Form_Completed__c ||
                  newRec.Do_any_EEs_have_tax_levies__c != existingRec.Do_any_EEs_have_tax_levies__c
                  ||newRec.NSP_List_Employee_Names_Levies__c != existingRec.NSP_List_Employee_Names_Levies__c 
                  ||newRec.NSP_Documents_Collected_Leviesd__c != existingRec.NSP_Documents_Collected_Leviesd__c){
                      
                      String [] employeeNames = newRec.NSP_List_Employee_Names_Levies__c.split(',');
                      
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SUBTASK_LEVIES_FN);
                  }
           }
    }
    
    private  void checkforPostDeduction(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if(newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
        || (newRec.Sponsored_plan_contribution_type__c == null && newRec.Client_has_any_post_tax_deductions__c != NSP_ServiceConstants.YES
        && newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c != NSP_ServiceConstants.YES )) {
            return;
        }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && (newRec.Client_has_any_post_tax_deductions__c==NSP_ServiceConstants.YES ||
        (newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c==NSP_ServiceConstants.YES && newRec.Sponsored_plan_contribution_type__c!=null
        &&  newRec.Sponsored_plan_contribution_type__c.contains(NSP_ServiceConstants.POSTTAX)  ) )){
            if(existingRec == null || newRec.NSP_Form_Completed__c ||
                  newRec.Sponsored_plan_contribution_type__c != existingRec.Sponsored_plan_contribution_type__c
                  ||newRec.Client_has_any_post_tax_deductions__c != existingRec.Client_has_any_post_tax_deductions__c
                  ||newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c != existingRec.Spnsrd_pln_when_Insperity_hndles_payroll__c  ){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POST_DEDUCTION_FN);
                  }
           }
    }
    
    private  void checkforRetPlan(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if(newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           ||newRec.Type_of_retirement_plan_client_has_today__c ==null ){
                  return;
              }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && (newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.CSP401K
           || newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.SIMPLEIRA
           || newRec.Type_of_retirement_plan_client_has_today__c==NSP_ServiceConstants.CLIENTB )){
               if(existingRec == null || newRec.NSP_Form_Completed__c ||
                  newRec.Type_of_retirement_plan_client_has_today__c != existingRec.Type_of_retirement_plan_client_has_today__c){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, RETIRE_PLAN_FN);
                  }
           }
    }
    
    private  void checkforPostTaxLoans(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.Employees_work_in_the_following_states__c==null){
               return;
           }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && (newRec.Employees_work_in_the_following_states__c!=null && newRec.Employees_work_in_the_following_states__c.contains(NSP_ServiceConstants.NY))
           &&  (newRec.Client_has_any_post_tax_deductions__c==NSP_ServiceConstants.YES || 
                (newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c==NSP_ServiceConstants.YES &&
                newRec.Sponsored_plan_contribution_type__c!=null && newRec.Sponsored_plan_contribution_type__c.contains(NSP_ServiceConstants.POSTTAX  ))) ){
               if(existingRec == null  || newRec.NSP_Form_Completed__c
                  || newRec.Sponsored_plan_contribution_type__c != existingRec.Sponsored_plan_contribution_type__c
                  ||newRec.Client_has_any_post_tax_deductions__c != existingRec.Client_has_any_post_tax_deductions__c
                  ||newRec.Spnsrd_pln_when_Insperity_hndles_payroll__c != existingRec.Spnsrd_pln_when_Insperity_hndles_payroll__c 
                  ||newRec.Employees_work_in_the_following_states__c != existingRec.Employees_work_in_the_following_states__c ){
                      updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, POSTTAX_LOANS_FN);
                  }
           }
    }
    
    private  void checkforRelabel(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if(newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.NSP_Any_special_pay_codes_Needed__c != NSP_ServiceConstants.YES  ) {
               return;
           }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && newRec.NSP_Any_special_pay_codes_Needed__c==NSP_ServiceConstants.YES ){
            if(existingRec == null  ||  newRec.NSP_Form_Completed__c ||
               newRec.NSP_Any_special_pay_codes_Needed__c != existingRec.NSP_Any_special_pay_codes_Needed__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, SPECIAL_RELABEL_FN);
               }
        }
    }
    
    private  void checkforReportingJobCosting(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.NSP_Select_all_that_apply__c ==null ) {
               return;
           }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && newRec.NSP_Select_all_that_apply__c!=null && newRec.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.COSTING)){
            if(existingRec == null || newRec.NSP_Form_Completed__c || 
               newRec.NSP_Select_all_that_apply__c != existingRec.NSP_Select_all_that_apply__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, REPORT_JOBCOSTING_FN);
               }
        }
    }
    
    private  void checkforReportingIntegra(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.NSP_Select_all_that_apply__c ==null ) {
               return;
           }
        
        
        if(  newRec.RecordTypeId == ipFSORecordTypeId && newRec.NSP_Select_all_that_apply__c!=null && newRec.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.INTEGRA_ASSET)){
            if(existingRec == null || newRec.NSP_Form_Completed__c ||
               newRec.NSP_Select_all_that_apply__c != existingRec.NSP_Select_all_that_apply__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, REPORT_Integra_FN);
               }
        }
    }
    
    private  void checkforReportingCustom(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.NSP_Select_all_that_apply__c ==null ) {
               return;
           }
        
        
        if(   newRec.RecordTypeId == ipFSORecordTypeId && newRec.NSP_Select_all_that_apply__c!=null && newRec.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.REPORT401)){
            if(existingRec == null || newRec.NSP_Form_Completed__c ||
               newRec.NSP_Select_all_that_apply__c != existingRec.NSP_Select_all_that_apply__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, REPORT_Custom401k_FN);
               }
        }
    }
    
    private  void checkforReportingOther(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null 
           || newRec.NSP_Select_all_that_apply__c ==null ) {
               return;
           }
        
        
        if(  newRec.RecordTypeId == ipFSORecordTypeId && newRec.NSP_Select_all_that_apply__c!=null && newRec.NSP_Select_all_that_apply__c.contains(NSP_ServiceConstants.OTHREPORTS)){
            if(existingRec == null || newRec.NSP_Form_Completed__c ||
               newRec.NSP_Select_all_that_apply__c != existingRec.NSP_Select_all_that_apply__c){
                   updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, REPORT_OTHER_FN);
               }
        }
    }
    
    private  void checkforCOBRA(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null
          ||newRec.Have_name_s_of_COBRA_takeovr_employees__c == null) {
            return;
        }
       
        if(   newRec.RecordTypeId == ipFSORecordTypeId && newRec.Have_name_s_of_COBRA_takeovr_employees__c == NSP_ServiceConstants.NO){
            if(existingRec == null  ||  newRec.NSP_Form_Completed__c || newRec.Have_name_s_of_COBRA_takeovr_employees__c != existingRec.Have_name_s_of_COBRA_takeovr_employees__c){
                updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, COBRA_FN);
            }
        }
    }
    
    private  void checkforCOBRAFormCollected(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null) {
            return;
        }

        if(   newRec.RecordTypeId == ipFSORecordTypeId &&  
           ((newRec.Have_name_s_of_COBRA_takeovr_employees__c == NSP_ServiceConstants.YES))){
                if(existingRec == null || newRec.NSP_Form_Completed__c || newRec.Have_name_s_of_COBRA_takeovr_employees__c != existingRec.Have_name_s_of_COBRA_takeovr_employees__c){
                    List<String> employeeNames = new List<String>();
                    if(newRec.NSP_COBRA_Takeover_Emp_Details__c!=null){
                    	 employeeNames = newRec.NSP_COBRA_Takeover_Emp_Details__c.split(',');
                    }
                    updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, COBRA_FORM_COLLECTED_FN);
                   }
            }
    }
    
    //STY-02163 
    /*Automation Section: Benefits
    Automation Name: Missing LOA Info
    Automation Icon: P
    */
    private  void checkforLOAInfo(Implementation_Profile__c newRec, Implementation_Profile__c existingRec){
        if( newRec.RecordTypeId != ipFSORecordTypeId || newRec.NSP_Project__c == null) {
            return;
        }
       
        if(newRec.RecordTypeId == ipFSORecordTypeId){ 
            if(newRec.Do_you_have_the_LOA_information__c == NSP_ServiceConstants.NO){
                 if(existingRec == null ||  newRec.NSP_Form_Completed__c || newRec.Do_you_have_the_LOA_information__c != existingRec.Do_you_have_the_LOA_information__c) {
                     updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, MISSING_LOA_FN);
                 }
             }
            if(newRec.Do_you_have_the_LOA_information__c == NSP_ServiceConstants.YES && newRec.NSP_Employee_Details_On_LOA__c!=null){
                if(existingRec == null  ||  newRec.NSP_Form_Completed__c || 
                    newRec.Do_you_have_the_LOA_information__c != existingRec.Do_you_have_the_LOA_information__c){
                        List<String> employeeNames = new List<String>();
                        if(newRec.NSP_Employee_Details_On_LOA__c!=null){
                            employeeNames = newRec.NSP_Employee_Details_On_LOA__c.split(',');
                        }
                        for(String emplyName : employeeNames){
                             employeeNames = emplyName?.trim().split('~');
                             if(employeeNames[2] == NSP_ServiceConstants.NO){
                             updateEligibleRecordsMap(ipRecordsByAutomation, newRec.Id, LOA_INFO_FN);
                             }
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
    
    /**
* Iterates throught the list of new Implementation profiles and passes the required attributes .
* @param newList List of New Implementation profiles.  
* @return void
* as part of STY-001959 -create project tasks for each condition    
*/
    
    public void createProjecttaskforSponsporedplan(){
        //if client be maintaining a client sponsored plan
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        
        for(Id ipRecId : ipRecordsByAutomation.get(CT_SPONSORED_PLAN_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.MILESTONE);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.MILESTONE;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.MILESTONE, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                if(ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HCFSA)){
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, NSP_ServiceConstants.CLIENTCATEGORY, milestoneKey);
                    eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.FSA;
                    eachProjecttask.Name=NSP_ServiceConstants.HEALTHCARE;
                    eachProjecttask.pse__Milestone__c=milestoneId;
                    eachProjecttask.pse__Order__c = 14;
                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                        eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                    }
                    
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                        eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                        eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                    }
                    projectTaskList.add(eachProjecttask);
                }
                
                if(ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.HSA)){
                    
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, NSP_ServiceConstants.CLIENTCATEGORY, milestoneKey);
                    eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.HSAA;
                    eachProjecttask.Name=NSP_ServiceConstants.HSA;
                    eachProjecttask.pse__Milestone__c=milestoneId;
                    eachProjecttask.pse__Order__c = 14;
                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                        eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                        eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                        eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                    }
                    
                    projectTaskList.add(eachProjecttask);
                    
                }
                
                if(ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DCFSA)){
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, NSP_ServiceConstants.CLIENTCATEGORY, milestoneKey);
                    eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.DCFS;
                    eachProjecttask.Name=NSP_ServiceConstants.DC;
                    eachProjecttask.pse__Milestone__c=milestoneId;
                    eachProjecttask.pse__Order__c = 14;
                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                        eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                        eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                        eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                    }
                    projectTaskList.add(eachProjecttask);
                    
                }
                
                if(ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.MEDICAL)){
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, NSP_ServiceConstants.CLIENTCATEGORY, milestoneKey);
                    eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MED;
                    eachProjecttask.Name=NSP_ServiceConstants.MEDCSP;
                    eachProjecttask.pse__Milestone__c=milestoneId;
                    eachProjecttask.pse__Order__c = 14;
                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                        eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                        eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                        eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                    }
                    projectTaskList.add(eachProjecttask);
                    
                }
                
                if(ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.DENTAL)){
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, NSP_ServiceConstants.CLIENTCATEGORY, milestoneKey);
                    eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.DENT;
                    eachProjecttask.Name=NSP_ServiceConstants.DCSP;
                    eachProjecttask.pse__Milestone__c=milestoneId;
                    eachProjecttask.pse__Order__c = 14;
                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                        eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                        eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                        eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                    }
                    projectTaskList.add(eachProjecttask);
                }
                
                if(ipRec.Pre_tax_Client_Sponsored_Plan_CSP_Type__c.contains(NSP_ServiceConstants.VISION)){
                    
                    pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, NSP_ServiceConstants.CLIENTCATEGORY, milestoneKey);
                    eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.VIS;
                    eachProjecttask.Name=NSP_ServiceConstants.VCSP;
                    eachProjecttask.pse__Milestone__c=milestoneId;
                    eachProjecttask.pse__Order__c = 14;
                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                        eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                        eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                    }
                    if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                        eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                    }
                    projectTaskList.add(eachProjecttask);
                }
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.CSPDOCSNOTRECEIVED,CT_SPONSORED_PLAN_FN,NSP_ServiceConstants.BENEFITS,NSP_ServiceConstants.FSOProfile));
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
    }
    
    public  void createProjecttaskforReceivedCertificate(){
        
        //if Received Certificate of Coverage for General Liability & Auto
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(GENERAL_LIABILITY_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.MILESTONE);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.MILESTONE;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.MILESTONE, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }

                
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, NSP_ServiceConstants.ONBOARDING, milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MILESTONE;
                eachProjecttask.Name=NSP_ServiceConstants.CERTIFICATE;
                eachProjecttask.pse__Order__c=17;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.GENERALlIABILITY,GENERAL_LIABILITY_FN,NSP_ServiceConstants.GENERAL,NSP_ServiceConstants.FSOProfile));
        
            }
        }

        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforEEO(){
        
        //3.	If Does the client have an EEO # they have been filing under? 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(EEO_FILING_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.MILESTONE);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.MILESTONE;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.MILESTONE, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }

                
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.CLIENTIMPL, milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MILESTONE;
                eachProjecttask.Name=NSP_ServiceConstants.EEO;
                eachProjecttask.pse__Order__c=18;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.EEO,EEO_FILING_FN,NSP_ServiceConstants.GENERAL,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    
    public  void createProjecttaskforClient(){
        
        //Has client provided a copy of their handbook, PTO, paid sick leave, or another accrual policy?  
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(CLIENT_HANDBOOK_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.MILESTONE);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.MILESTONE;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.MILESTONE, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
               
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.CLIENTIMPL,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MILESTONE;
                eachProjecttask.Name=NSP_ServiceConstants.PTOSICKLEAVE;
                eachProjecttask.pse__Order__c = 19 ;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Onboarding_Specialist_Coordinator__c!=null && ipwithValue.NSP_Onboarding_Specialist_Coordinator__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Onboarding_Specialist_Coordinator__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.CLIENTPOLICY,CLIENT_HANDBOOK_FN,NSP_ServiceConstants.GENERAL,NSP_ServiceConstants.FSOProfile));
       
            }
        }
        
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }

    
    public  void createProjecttaskforEDC(){
        
        //	Has the Employee Data Collection (EDC) been collected?  
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(EDC_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEPRIMING);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEPRIMING;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEPRIMING, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
               
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.CLIENTIMPL,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.Priming_SubCat;
                eachProjecttask.Name=NSP_ServiceConstants.PRIMINGDATA;
                eachProjecttask.pse__Order__c=29;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null ){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.EDC,EDC_FN,NSP_ServiceConstants.GENERAL,NSP_ServiceConstants.FSOProfile));
       
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforPayrollneeds(){
        
        //	 Does the client have any special payroll needs (i.e. job costing, IRR, departments)?
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(PAYROLL_LOCATIONS_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEPRIMING);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEPRIMING;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEPRIMING, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MILESTONE;
                eachProjecttask.Name=NSP_ServiceConstants.LOCATIONSETUP;
                eachProjecttask.pse__Order__c=30;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.PAYROLLLOCATIONS,PAYROLL_LOCATIONS_FN,NSP_ServiceConstants.GENERAL,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforPayrollJob(){
        
        //	 Does the client have any special payroll needs (i.e. job costing, IRR, departments)? = 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(PAYROLL_DEPARTMENTS_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEPRIMING);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEPRIMING;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEPRIMING, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj, NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MILESTONE;
                eachProjecttask.Name=NSP_ServiceConstants.DEPARTMENTSETUP;
                eachProjecttask.pse__Order__c=31;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.PAYROLLDEPARTMENTS,PAYROLL_DEPARTMENTS_FN,NSP_ServiceConstants.GENERAL,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforPayrollJobCosting(){
        
        //	 Does the client have any special payroll needs (i.e. job costing, IRR, departments)? = 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(PAYROLL_JOBCOSTING_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEPRIMING);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEPRIMING;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEPRIMING, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MILESTONE;
                eachProjecttask.Name=NSP_ServiceConstants.JOBSETUP;
                eachProjecttask.pse__Order__c=32;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.PAYROLLJOBCOSTING,PAYROLL_JOBCOSTING_FN,NSP_ServiceConstants.GENERAL,NSP_ServiceConstants.FSOProfile));
       
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    

    public  void createProjecttaskforPayrollRegister(){
        
        //	Has a recent payroll register been collected?  
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        for(Id ipRecId : ipRecordsByAutomation.get(PAYROLL_REGISTER_FN)){
            Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEPRIMING);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEPRIMING;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEPRIMING, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MILESTONE;
                eachProjecttask.Name=NSP_ServiceConstants.CPR;
                if(ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                eachProjecttask.pse__Order__c=33;
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.PAYROLLREGISTER,PAYROLL_REGISTER_FN,NSP_ServiceConstants.GENERAL,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforGarnishment(){
        
        //		If Do any EEs have garnishments? 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(GARNISHMENT_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEDEDUCTION);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEDEDUCTION;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEDEDUCTION, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.STATUTORY;
                eachProjecttask.Name=NSP_ServiceConstants.GARNISHMENT;
                eachProjecttask.pse__Order__c=44;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.GARNISHMENTS,GARNISHMENT_FN,NSP_ServiceConstants.PAYROLLSEC,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforTaxlevis(){
        
        //			If Do any EEs tax levies? 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(TAX_LEVIES_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEDEDUCTION);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEDEDUCTION;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEDEDUCTION, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.STATUTORY;
                eachProjecttask.Name=NSP_ServiceConstants.LEVIEIS;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                eachProjecttask.pse__Order__c=45;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.LEVIES,TAX_LEVIES_FN,NSP_ServiceConstants.PAYROLLSEC,NSP_ServiceConstants.FSOProfile));
       
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforPostDeduction(){
        
        //	If Does the client have any post-tax deductions 
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(POST_DEDUCTION_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEDEDUCTION);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEDEDUCTION;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEDEDUCTION, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.ELECTIVE;
                eachProjecttask.Name=NSP_ServiceConstants.AUTHFORM;
                eachProjecttask.pse__Order__c=46;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.POSTTAXDEDUCT,POST_DEDUCTION_FN,NSP_ServiceConstants.PAYROLLSEC,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforRetplan(){
        
        //	15.	If What kind of retirement plan does client have today? 	
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(RETIRE_PLAN_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEDEDUCTION);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEDEDUCTION;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEDEDUCTION, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.ORKDEDUCTION;
                eachProjecttask.Name=NSP_ServiceConstants.AUTHFORMORK;
                eachProjecttask.pse__Order__c=47;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.EMPLOYEEDEDUCT,RETIRE_PLAN_FN,NSP_ServiceConstants.RT,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforPosttaxded(){
        
        //If Does the client have any post-tax deductions  	
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(POSTTAX_LOANS_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.EMPLOYEEDEDUCTION);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.EMPLOYEEDEDUCTION;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.EMPLOYEEDEDUCTION, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.ELECTIVE;
                eachProjecttask.Name=NSP_ServiceConstants.NYDEDUCTION;
                eachProjecttask.pse__Order__c=48;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.NYWSEE,POSTTAX_LOANS_FN,NSP_ServiceConstants.PAYROLLSEC,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforRelable(){
        
        //			If Any special pay codes and/or relabeling needed?   	
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(SPECIAL_RELABEL_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.PAYSETUP);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.PAYSETUP;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.PAYSETUP, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MILESTONE;
                eachProjecttask.Name=NSP_ServiceConstants.CUSTOMPAYSETUP;
                eachProjecttask.pse__Order__c=52;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.RELABELING,SPECIAL_RELABEL_FN,NSP_ServiceConstants.PAYOUTSSEC,NSP_ServiceConstants.FSOProfile));
       
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforReportingJob(){
        
        //	If Reporting: Select all that apply  	
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(REPORT_JOBCOSTING_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.REPORITNTNEED);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.REPORITNTNEED;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.REPORITNTNEED, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.CATEGORY6,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.SPECIALREPORT;
                eachProjecttask.Name=NSP_ServiceConstants.JOBCOSTREPORT;
                eachProjecttask.pse__Order__c=56;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.JOBCOST,REPORT_JOBCOSTING_FN,NSP_ServiceConstants.REPORTINGSEC,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforReportingIntegra(){
        
        //	If Reporting: Select all that apply  	
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(REPORT_Integra_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.REPORITNTNEED);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.REPORITNTNEED;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.REPORITNTNEED, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.CATEGORY6,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.SPECIALREPORT;
                eachProjecttask.Name=NSP_ServiceConstants.FINANCEREPORT;
                eachProjecttask.pse__Order__c=57;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.INTEGRA,REPORT_Integra_FN,NSP_ServiceConstants.REPORTINGSEC,NSP_ServiceConstants.FSOProfile));
       
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforReportingCustom(){
        
        //	If Reporting: Select all that apply  	
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(REPORT_Custom401k_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.REPORITNTNEED);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.REPORITNTNEED;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.REPORITNTNEED, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PPMREQUEST,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.CUSTREPORTS;
                eachProjecttask.Name=NSP_ServiceConstants.REPORT401K;
                eachProjecttask.pse__Order__c=58;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.CUSTOM401K,REPORT_Custom401k_FN,NSP_ServiceConstants.REPORTINGSEC,NSP_ServiceConstants.FSOProfile));
       
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforReportingOther(){
        
        //	If Reporting: Select all that apply  	
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(REPORT_OTHER_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.REPORITNTNEED);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.REPORITNTNEED;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.REPORITNTNEED, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.CATEGORY6,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.SPECIALREPORT;
                eachProjecttask.Name=NSP_ServiceConstants.CUSTREPORTS;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                eachProjecttask.pse__Order__c=59;

                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.CUSTOMREPORT,REPORT_OTHER_FN,NSP_ServiceConstants.REPORTINGSEC,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforCOBRA(){
        
        //	If Reporting: Select all that apply  	
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(COBRA_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                

                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.BENEFITS);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.BENEFITS;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.BENEFITS, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                        eachMilestone.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                    }            
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                
                
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.COBRA,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.COBRASubcat;
                if(ipRec.Have_name_s_of_COBRA_takeovr_employees__c == NSP_ServiceConstants.NO){
                    eachProjecttask.Name = NSP_ServiceConstants.COBRA_MISSING_NAMES;
                }else{
                    eachProjecttask.Name = NSP_ServiceConstants.COBRATask;
                }
                    eachProjecttask.pse__Order__c=87;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.MISSINGCOBRA,COBRA_FN,NSP_ServiceConstants.BENEFITS,NSP_ServiceConstants.FSOProfile));
        
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    } 
    
    public  void createProjecttaskforCOBRAFormCollected(){
        
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        Map<Id,Id> mapProjectIdIPId = new Map<Id,Id>();
        Map<Id,pse__Proj__c> projectMap = new Map<Id,pse__Proj__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(COBRA_FORM_COLLECTED_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                projectMap.put(proj.Id, proj);
                mapProjectIdIPId.put(proj.Id, ipRec.Id);
            }
        } 

        for(Id ipRecId : ipRecordsByAutomation.get(COBRA_FORM_COLLECTED_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);

            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                
                Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.BENEFITS);
                String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.BENEFITS;

                if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                    pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.BENEFITS, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                    Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                    if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                        eachMilestone.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                    } 
                    mileStonesToInsert.put(milestoneKey, eachMilestone);
                }
                List<String> lstNamesEmployess = new List<String>();
                if(!String.isBlank(ipRec.NSP_COBRA_Takeover_Emp_Details__c)){
                    lstNamesEmployess= ipRec.NSP_COBRA_Takeover_Emp_Details__c.split(',');
                }

                if(lstNamesEmployess.size()>0){
                    for(String empName: lstNamesEmployess){
                        lstNamesEmployess = empName?.split('~');
                        pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.COBRA,milestoneKey);
                        eachProjecttask.NSP_Sub_Category__c = NSP_ServiceConstants.COBRASubcat;
                        if(lstNamesEmployess[1] == NSP_ServiceConstants.NO){
                            eachProjecttask.Name = NSP_ServiceConstants.COBRA_FORM_COLLECTED_NO.replace('<WSEE Name>',lstNamesEmployess[0]);
                            eachProjecttask.pse__Order__c=88;
                            ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.COBRAFOLLOWUP,COBRA_FORM_COLLECTED_FN,NSP_ServiceConstants.BENEFITS,NSP_ServiceConstants.FSOProfile));
                        }else{
                            eachProjecttask.Name = NSP_ServiceConstants.COBRA_FORM_COLLECTED_YES.replace('<WSEE Name>',lstNamesEmployess[0]);
                        	eachProjecttask.pse__Order__c=89;
                            ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.COBRAELIGIBITY,COBRA_FORM_COLLECTED_FN,NSP_ServiceConstants.BENEFITS,NSP_ServiceConstants.FSOProfile));
                        }
                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                        }
                        if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                            eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                        }
                        if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                            eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                        }
                        eachProjecttask.pse__Milestone__c=milestoneId;
                        
                        projectTaskList.add(eachProjecttask);               
                        
                    }
                }
            }
        }
        //check for existing Automation record and store the new Automation records
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
    
    public  void createProjecttaskforLOAInfo(){
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        Map<Id,Id> mapProjectIdIPId = new Map<Id,Id>();
        Map<Id,pse__Proj__c> projectMap = new Map<Id,pse__Proj__c>();
        
        if(ipRecordsByAutomation.get(LOA_INFO_FN)!=null){
            for(Id ipRecId : ipRecordsByAutomation.get(LOA_INFO_FN)){
                Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                    pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                    projectMap.put(proj.Id, proj);
                    mapProjectIdIPId.put(proj.Id, ipRec.Id);
                }
            }
        }
        if(ipRecordsByAutomation.get(LOA_INFO_FN)!=null){
            for(Id ipRecId : ipRecordsByAutomation.get(LOA_INFO_FN)){
                Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                    pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                    
                    if(ipRec.NSP_Employee_Details_On_LOA__c!=null && ipRec.Do_you_have_the_LOA_information__c == NSP_ServiceConstants.YES){
                        
                        Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.BENEFITS);
                        String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.BENEFITS;

                        if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                        pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.BENEFITS, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                            eachMilestone.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                        } 
                        mileStonesToInsert.put(milestoneKey, eachMilestone);
                        }
                        List<String> lstNamesEmployess = new List<String>();
                        if(!String.isBlank(ipRec.NSP_Employee_Details_On_LOA__c)){
                        lstNamesEmployess= ipRec.NSP_Employee_Details_On_LOA__c.split(',');
                        }
                        for(String emplyName : lstNamesEmployess){
                            lstNamesEmployess = emplyName?.trim().split('~');
                            if(lstNamesEmployess[2] == NSP_ServiceConstants.NO){
                                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.COBRA,milestoneKey);
                                eachProjecttask.NSP_Sub_Category__c = NSP_ServiceConstants.LOAPAPERWORK;
                                eachProjecttask.NSP_Category__c = NSP_ServiceConstants.SUBCATEGORY9;
                                eachProjecttask.Name = NSP_ServiceConstants.EMPLOYEE_LOA_INFO_YES.replace('<WSEE Name>',lstNamesEmployess[0]);
                                eachProjecttask.NSP_Detail__c=NSP_ServiceConstants.LOADETAILS;
                                eachProjecttask.pse__Order__c=91;
                                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                                if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                                }
                                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                                }
                                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                                }
                                eachProjecttask.pse__Milestone__c=milestoneId;
                                
                                projectTaskList.add(eachProjecttask);  
                                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.MISSINGLOAFORMS,LOA_INFO_FN,NSP_ServiceConstants.BENEFITS,NSP_ServiceConstants.FSOProfile)); 
                            }            
                        }
                    }
                }
            }
        }
        if(ipRecordsByAutomation.get(MISSING_LOA_FN)!=null){
            for(Id ipRecId : ipRecordsByAutomation.get(MISSING_LOA_FN)){
                    Implementation_Profile__c ipRec = newIPs.get(ipRecId);
                    if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                        pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                    if(ipRec.Do_you_have_the_LOA_information__c == NSP_ServiceConstants.NO){
                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                       
                        Id milestoneId = getMilestoneId(proj.pse__Milestones__r, NSP_ServiceConstants.BENEFITS);
                        String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.BENEFITS;
                                                            
                        if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                            pse__Milestone__c eachMilestone1 = new pse__Milestone__c(Name=NSP_ServiceConstants.BENEFITS, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                            mileStonesToInsert.put(milestoneKey, eachMilestone1);
                        }
                        pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  '',milestoneKey);
                        eachProjecttask.NSP_Sub_Category__c = NSP_ServiceConstants.LOAPAPERWORK;
                        eachProjecttask.NSP_Category__c = NSP_ServiceConstants.SUBCATEGORY9;
                        eachProjecttask.Name = NSP_ServiceConstants.EMPLOYEE_LOA_INFO;
                        eachProjecttask.NSP_Detail__c=NSP_ServiceConstants.LOADETAILS;
                        if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                            eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                        }
                        if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                            eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                        }
                        if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                            eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                        }
                        eachProjecttask.pse__Order__c=90;
                        eachProjecttask.pse__Milestone__c=milestoneId;
                        
                        projectTaskList.add(eachProjecttask);
                        ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.MISSINGLOAINFO,MISSING_LOA_FN,NSP_ServiceConstants.BENEFITS,NSP_ServiceConstants.FSOProfile));      
                    }
                }
            }
        }
            
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }
  
    public  void createSubtaskforGarnishments(){
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> taskList = new List<pse__Project_Task__c>  (); 
        Map<Id,Implementation_Profile__c> impProfMap = new  Map<Id,Implementation_Profile__c>();
        Map<Id,Id> mapProjectIdIPId = new Map<Id,Id>();
        Map<Id,pse__Proj__c> projectMap = new Map<Id,pse__Proj__c>();

        for(Id ipRecId : ipRecordsByAutomation.get(SUBTASK_GARNISH_FN)){
            Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
            pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
            projectMap.put(proj.Id,proj);
            mapProjectIdIPId.put(proj.Id,ipRec.Id);
            if( proj.pse__Project_Tasks__r.size()>0){
                 taskList.addAll(proj.pse__Project_Tasks__r);
                }
                if(ipwithValue.Id ==ipRec.Id){
                    impProfMap.put(proj.Id,ipwithValue);
                }
            }
        
            List<String> lstNamesEmployess = new List<String>();
            if(!String.isBlank(ipRec.NSP_Employee_Names_List_garnishments__c)){
                        lstNamesEmployess= ipRec.NSP_Employee_Names_List_garnishments__c.split(',');
            }
        if(lstNamesEmployess.size()>0){
                for(pse__Project_Task__c pt:taskList){
                    pse__Proj__c proj = projectMap.get(pt.pse__Project__c);
                    if(pt.Name==NSP_ServiceConstants.GARNISHMENT){
                        for(String empName: lstNamesEmployess){
                            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,null);
                             ipwithValue=impProfMap.get(pt.pse__Project__c);
                            if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                            }
                            if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                                eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                            }
                            if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                                eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                            }
                            eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.STATUTORY;
                            eachProjecttask.Name=empName+NSP_ServiceConstants.GARNISHDOC;
                            eachProjecttask.pse__Parent_Task__c=pt.Id;
                            eachProjecttask.pse__Hierarchy_Depth__c=1;
                            eachProjecttask.pse__Milestone__c=pt.pse__Milestone__c;
                            eachProjecttask.pse__Order__c = pt.pse__Order__c;
                            projectTaskList.add(eachProjecttask);  
                        }
                    }
                }
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
    }
    
    public  void createSubtaskforLevies(){
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> taskList = new List<pse__Project_Task__c>  (); 
        Map<Id,Implementation_Profile__c> impProfMap = new  Map<Id,Implementation_Profile__c>();
        Map<Id,Id> mapProjectIdIPId = new Map<Id,Id>();
        Map<Id,pse__Proj__c> projectMap = new Map<Id,pse__Proj__c>();
        for(Id ipRecId : ipRecordsByAutomation.get(SUBTASK_LEVIES_FN)){
            Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                projectMap.put(proj.Id,proj);
                mapProjectIdIPId.put(proj.Id,ipRec.Id);
                if( proj.pse__Project_Tasks__r.size()>0){
                    taskList.addAll(proj.pse__Project_Tasks__r);
                }
                    if(ipwithValue.Id ==ipRec.Id){
                        impProfMap.put(proj.Id,ipwithValue);
                    }
            }
        
            List<String> lstNamesEmployess = new List<String>();
            if(!String.isBlank(ipRec.NSP_List_Employee_Names_Levies__c)){
                        lstNamesEmployess= ipRec.NSP_List_Employee_Names_Levies__c.split(',');
            }
        if(lstNamesEmployess.size()>0){
                for(pse__Project_Task__c pt: taskList){
                    pse__Proj__c proj = projectMap.get(pt.pse__Project__c);
                    if(pt.Name==NSP_ServiceConstants.LEVIEIS){
                        for(String empName: lstNamesEmployess){
                            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,null);
                             ipwithValue=impProfMap.get(pt.pse__Project__c);
                            if(ipwithValue.NSP_Project_Manager__c!=null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null){
                                eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                            }
                            if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                                eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                            }
                            if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                                eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                            }
                            eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.STATUTORY;
                            eachProjecttask.Name=empName+NSP_ServiceConstants.LEVYDOC;
                            eachProjecttask.pse__Parent_Task__c=pt.Id;
                            eachProjecttask.pse__Hierarchy_Depth__c=1;
                            eachProjecttask.pse__Milestone__c=pt.pse__Milestone__c;
                            eachProjecttask.pse__Order__c=45;
                            projectTaskList.add(eachProjecttask);  
                        } 
                    }
                }
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
    }
    
    
    private pse__Project_Task__c createProjectTaskfromIP(pse__Proj__c project,  String category, String milestoneKey){
        
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
        
        
        return eachProjectTask;
    }
    
    private void getIPRecords(){
        
        for (Set<Id> ipRecords : ipRecordsByAutomation.values()) {
                ipIds.addAll(ipRecords);
        }
        Map<Id, sObject> dbRec = new Map<Id, sObject>([SELECT Id,NSP_Payroll_Specialist__c, NSP_Payroll_Specialist__r.pse__Salesforce_User__c,NSP_Transition_Specialist__c,NSP_OT_Representative__c,
                                                       NSP_Client_Liaison__c,NSP_HR_Specialist__c,NSP_HR_Specialist__r.NSP_Work_email__c,NSP_Client_Liaison__r.NSP_Work_email__c,NSP_OT_Representative__r.NSP_Work_email__c,
                                                       NSP_Transition_Specialist__r.NSP_Work_email__c,NSP_Payroll_Specialist__r.NSP_Work_email__c,NSP_Onboarding_Specialist_Coordinator__c,NSP_Onboarding_Specialist_Coordinator__r.pse__Salesforce_User__c,
                                                       NSP_Onboarding_Specialist_Coordinator__r.Email,NSP_Project_Manager__c,NSP_Project_Manager__r.Name, NSP_Project_Manager__r.NSP_Work_email__c, NSP_Project_Manager__r.NSP_Job_Title__c,
                                                       NSP_Project_Manager__r.pse__Salesforce_User__c, Account__c, Account__r.Name,NSP_Old_Benefits_Package__c,NSP_Old_Effective_Date_EPLI__c,NSP_Old_Insperity_Ben_effective_date__c
                                                       FROM Implementation_Profile__c WHERE Id IN:ipIds]);
        data.put(IMPL_PROFILE_IDENTIFIER, dbRec);
    }
    
    public List<pse__Project_Task__c> getnewTaskstoInsert(List<pse__Project_Task__c> projTaskList){
        
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
    
    public void getnewAutomationListtoInsert(List<NSP_Implementation_Profile_Automation__c> ipAutomationList,
                                             List<Sobject> newRecordList , List<Sobject> oldRecordsUpdate){
                                                 
                                                 Map<Id, sObject> dbRec=data.get(IP_AUTOMATION_IDENTIFIER);
                                                 List<String> existingIpAutomations=new List<String>();
                                                 for(Id ipaId:dbRec.keySet()){
                                                     NSP_Implementation_Profile_Automation__c ipa=(NSP_Implementation_Profile_Automation__c)dbRec.get(ipaId);
                                                     existingIpAutomations.add(ipa.NSP_Implementation_Profile__c+'_'+ipa.Name+'_'+ipa.NSP_Record_Type__c);
                                                     
                                                 }   
                                                 //List<NSP_Implementation_Profile_Automation__c> newipAutomationList=new List<NSP_Implementation_Profile_Automation__c>();
                                                 for(NSP_Implementation_Profile_Automation__c ipa: ipAutomationList){
                                                     if(existingIpAutomations.isEmpty()|| 
                                                        !existingIpAutomations.contains(ipa.NSP_Implementation_Profile__c+'_'+ipa.Name+'_'+ipa.NSP_Record_Type__c)) {
                                                            newRecordList.add(ipa);
                                                        }
                                                     else if(!existingIpAutomations.isEmpty()){
                                                         NSP_Implementation_Profile_Automation__c ipAutomation = new NSP_Implementation_Profile_Automation__c();
                                                         ipAutomation.NSP_Last_Run__c = System.now();
                                                         ipAutomation.Id= ipa.Id;
                                                         oldRecordsUpdate.add(ipAutomation);
                                                     }
                                                     
                                                 }   
                                                 
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
                newIPAautomation= createIPAutomation( ipRecId,  automationName,  fnName,  recordType, section);
                Insert newIPAautomation;
                IPAautomation=newIPAautomation;
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_Implprofile_ServiceHelperUpdate', 'automationRecordUpdate', ex.getMessage());  
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
    
    /***********************************************************************************************
    * MethodName: checkInternalDiscovery
    * Description : This Method check Insperity effective date for Payroll/Worker’s Comp/EPLI, Insperity benefits effective date or the Package is updated
    * Params:       Implementation_Profile__c newIp, Implementation_Profile__c existingRecp
    * Author :      Bindushree R
    * ********************************************************************************************/
    public void checkInternalDiscovery(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp){
        if( ipFSORecordTypeId== newIp.recordTypeId && newIp.NSP_Project__c!=null && existingRecp!=null 
           && ((newIp.Effective_Date_Payroll_Worker_comp_EPLI__c!=null && 
           newIp.Effective_Date_Payroll_Worker_comp_EPLI__c!=newIp.NSP_Old_Effective_Date_EPLI__c)
           || (newIp.Insperity_benefits_effective_date__c!=null && 
           newIp.Insperity_benefits_effective_date__c!=newIp.NSP_Old_Insperity_Ben_effective_date__c)
           ||(newIp.Benefits_Package__c!=null && 
           newIp.Benefits_Package__c!=newIp.NSP_Old_Benefits_Package__c))){
            updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, INTERNAL_DISCOVERY_FN);
        }
    }
    /***********************************************************************************************
    * MethodName: emailNotifyInternalDiscovery
    * Description : This Method trigger email for FSO IP
    * Author :      Bindushree R
    * ********************************************************************************************/
    public void emailNotifyInternalDiscovery(){
        for(Id ipRecId : ipRecordsByAutomation.get(INTERNAL_DISCOVERY_FN)){
            Boolean isSendEmail;
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
             Implementation_Profile__c existingRec =  oldIPs.get(ipRec.Id);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){ 
            NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(INTERNAL_DISCOVERY_FN);
            NSP_PEO_Implementations__mdt pf1 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ALLOSCOORDINATOR);
            NSP_PEO_Implementations__mdt pf2 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.HRSUPPORT);
            NSP_PEO_Implementations__mdt pf3 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.ORIENTCOORDINATOR);
            NSP_PEO_Implementations__mdt pf4 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.CLIENTACCOUNTMANAGEMENT);

            pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
              
            if( proj.pse__Project_Tasks__r.size()>0){   
                List<String> completedTasks = mapOfCompletedTasks.get(proj.Id);
                    if( completedTasks.contains(NSP_ServiceConstants.CLIENTTRANSITION)) {
                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                        List<String> listOfTOAddresses = new List<String>();
                        //get list of email address for to address
                        listOfTOAddresses.add(pf.NSP_Email_Address__c);
                        listOfTOAddresses.add(pf1.NSP_Email_Address__c);
                        listOfTOAddresses.add(pf2.NSP_Email_Address__c);
                        listOfTOAddresses.add(pf3.NSP_Email_Address__c);
                        listOfTOAddresses.add(pf4.NSP_Email_Address__c);
                        if(ipwithValue.NSP_Transition_Specialist__c!=null && ipwithValue.NSP_Transition_Specialist__r.NSP_Work_email__c!=null){
                           listOfTOAddresses.add(ipwithValue.NSP_Transition_Specialist__r.NSP_Work_email__c); 
                        }
                        if(ipwithValue.NSP_OT_Representative__c!=null && ipwithValue.NSP_OT_Representative__r.NSP_Work_email__c!=null){
                           listOfTOAddresses.add(ipwithValue.NSP_OT_Representative__r.NSP_Work_email__c); 
                        }
                        
                        if(ipwithValue.NSP_Client_Liaison__c!=null && ipwithValue.NSP_Client_Liaison__r.NSP_Work_email__c!=null){
                           listOfTOAddresses.add(ipwithValue.NSP_Client_Liaison__r.NSP_Work_email__c); 
                        }
                        if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c!=null){
                           listOfTOAddresses.add(ipwithValue.NSP_Payroll_Specialist__r.NSP_Work_email__c); 
                        }
                        if(ipwithValue.NSP_HR_Specialist__c!=null && ipwithValue.NSP_HR_Specialist__r.NSP_Work_email__c!=null){
                           listOfTOAddresses.add(ipwithValue.NSP_HR_Specialist__r.NSP_Work_email__c); 
                        }
                        
                        //prepare email template for subject and body
                        String subjectString = ipRec.NSP_AIMS_Client_Name__c+' ('+ipRec.NSP_AIMS_ClientNo__c+')'+': Key Information updated';
                        String mailBody ='The following information for  ' +ipRec.NSP_AIMS_Client_Name__c+' ('+ipRec.NSP_AIMS_ClientNo__c+')';
                        mailBody += 'has been updated since the Transition Meeting.'+'<br/><br/>';
                        if(ipRec.NSP_Old_Effective_Date_EPLI__c!=null && 
                        ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c!=ipRec.NSP_Old_Effective_Date_EPLI__c){
                            isSendEmail = true;
                            mailBody +='The Insperity effective date for Payroll/Worker’s Comp/EPLI has changed from '
                            + ipRec.NSP_Old_Effective_Date_EPLI__c.format() +' to '+ ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c.format()+'.';
                        }
                        mailBody += '<br/>';
                        if(ipRec.NSP_Old_Insperity_Ben_effective_date__c!=null && 
                        ipRec.Insperity_benefits_effective_date__c!=ipRec.NSP_Old_Insperity_Ben_effective_date__c){
                            isSendEmail = true;
                            mailBody +='The Insperity benefits effective date has changed from '
                            + (ipRec.NSP_Old_Insperity_Ben_effective_date__c).format()+' to '+ (ipRec.Insperity_benefits_effective_date__c).format()+'.';
                        }
                        mailBody += '<br/>';
                        if(ipRec.NSP_Old_Benefits_Package__c!=null && 
                        ipRec.Benefits_Package__c!=ipRec.NSP_Old_Benefits_Package__c){
                            isSendEmail = true;
                            mailBody +='The Medical Package has changed from  '
                            + ipRec.NSP_Old_Benefits_Package__c +' to '+ ipRec.Benefits_Package__c+'.';
                        }
                        mailBody += '<br/><br/>'+'Regards,'+'<br/>';
                        mailBody += ipwithValue.NSP_Project_Manager__r.Name+'<br/>';
                                            	// update IP record 
                        String ImpProfKey = proj.Id + '~' + ipRec.Name;
                        Implementation_Profile__c impProfile = new Implementation_Profile__c();
                        impProfile.Id = ipRec.Id;
                        impProfile.NSP_Old_Effective_Date_EPLI__c = ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c;
                        impProfile.NSP_Old_Insperity_Ben_effective_date__c = ipRec.Insperity_benefits_effective_date__c;
                        impProfile.NSP_Old_Benefits_Package__c = ipRec.Benefits_Package__c;
                        impProfileToUpdate.put(ImpProfKey,impProfile);
                        if(!listOfTOAddresses.isEmpty() && isSendEmail){
                       		 NSP_ProjectTaskTriggerEmailNotification.sendMail(subjectString,mailBody,listOfTOAddresses,null,null);
                        }

                       
                   }
              }
        
            }
                   
        }
           
    }
    
    /***********************************************************************************************
    * MethodName: checkOnsiteDiscovery
    * Description : This Method check Insperity effective date for Payroll/Worker’s Comp/EPLI, Insperity benefits effective date or the Package is updated for MM IP
    * Params:       Implementation_Profile__c newIp, Implementation_Profile__c existingRecp
    * Author :      Bindushree R
    * ********************************************************************************************/
    public void checkOnsiteDiscovery(Implementation_Profile__c newIp, Implementation_Profile__c existingRecp){
        if( ipMMRecordTypeId== newIp.recordTypeId && newIp.NSP_Project__c!=null && existingRecp!=null 
           && ((newIp.Effective_Date_Payroll_Worker_comp_EPLI__c!=null && 
           newIp.Effective_Date_Payroll_Worker_comp_EPLI__c!=newIp.NSP_Old_Effective_Date_EPLI__c)
           || (newIp.Insperity_benefits_effective_date__c!=null && 
           newIp.Insperity_benefits_effective_date__c!=newIp.NSP_Old_Insperity_Ben_effective_date__c)
           ||(newIp.Benefits_Package__c!=null && 
           newIp.Benefits_Package__c!=newIp.NSP_Old_Benefits_Package__c))){
            updateEligibleRecordsMap(ipRecordsByAutomation, newIp.Id, ONSITE_DISCOVERY_FN);
        }
    }
    
    /***********************************************************************************************
    * MethodName: emailNotifyOnsiteDiscovery
    * Description : This Method trigger email for MM IP
    * Author :      Bindushree R
    * ********************************************************************************************/


	public void emailNotifyOnsiteDiscovery(){
        for(Id ipRecId : ipRecordsByAutomation.get(ONSITE_DISCOVERY_FN)){
            Boolean isSendMail;
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            Implementation_Profile__c existingRec =  oldIPs.get(ipRec.Id);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm ){ 
            NSP_PEO_Implementations__mdt pf = NSP_PEO_Implementations__mdt.getInstance(ONSITE_DISCOVERY_FN);
            NSP_PEO_Implementations__mdt pf1 = NSP_PEO_Implementations__mdt.getInstance(NSP_ServiceConstants.CLIENTACCOUNTMANAGEMENT);

            pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
              
            if( proj.pse__Project_Tasks__r.size()>0){   
                List<String> completedTasks = mapOfCompletedTasks.get(proj.Id);
                    if(completedTasks.contains(NSP_ServiceConstants.ONSITEDISCOVERY)) {
                        //fetch all to address from project
                        Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);

                        List<String> listOfTOAddresses = new List<String>();
                        listOfTOAddresses.add(pf.NSP_Email_Address__c);
                        listOfTOAddresses.add(pf1.NSP_Email_Address__c);
                        if( proj.Project_Teams__r.size()>0){ 
                            for(NSP_Project_Team__c projTeam : proj.Project_Teams__r){ 
                                if(projTeam.NSP_Role__c == NSP_ServiceConstants.SrHrSpecialist && projTeam.NSP_Assignee__c!=null && projTeam.NSP_Assignee__r.NSP_Work_email__c!=null){
                                    listOfTOAddresses.add(projTeam.NSP_Assignee__r.NSP_Work_email__c); 
                                }
                                if(projTeam.NSP_Role__c == NSP_ServiceConstants.AccountExecutive && projTeam.NSP_Assignee__c!=null && projTeam.NSP_Assignee__r.NSP_Work_email__c!=null){
                                    listOfTOAddresses.add(projTeam.NSP_Assignee__r.NSP_Work_email__c); 
                                }
                                if(projTeam.NSP_Role__c == NSP_ServiceConstants.PAYROLL_SPECIALIST && projTeam.NSP_Assignee__c!=null && projTeam.NSP_Assignee__r.NSP_Work_email__c!=null){
                                    listOfTOAddresses.add(projTeam.NSP_Assignee__r.NSP_Work_email__c); 
                                }
                                if(projTeam.NSP_Role__c == NSP_ServiceConstants.PayrollProjectManager && projTeam.NSP_Assignee__c!=null && projTeam.NSP_Assignee__r.NSP_Work_email__c!=null){
                                    listOfTOAddresses.add(projTeam.NSP_Assignee__r.NSP_Work_email__c); 
                                }
                            }
                        }
                        
                        //Email template preparation for subject and body
                        String subjectString = proj.pse__Account__r.Name+' : Key Information updated';
                        String mailBody ='The following information for  ' +proj.pse__Account__r.Name;
                        mailBody += ' has been updated since the Discovery Meeting.'+'<br/><br/>';
                        if(ipRec.NSP_Old_Effective_Date_EPLI__c!=null && 
                        ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c!=ipRec.NSP_Old_Effective_Date_EPLI__c){
                            isSendMail =true;
                            mailBody +='The Insperity effective date for Payroll/Worker’s Comp/EPLI has changed from '
							+ ipRec.NSP_Old_Effective_Date_EPLI__c.format() +' to '+ ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c.format()+'. <br/>';
                        }
                        if(ipRec.NSP_Old_Insperity_Ben_effective_date__c!=null && 
                        ipRec.Insperity_benefits_effective_date__c!=ipRec.NSP_Old_Insperity_Ben_effective_date__c){
                            isSendMail =true;
                            mailBody +='The Insperity benefits effective date has changed from '
							+ ipRec.NSP_Old_Insperity_Ben_effective_date__c.format() +' to '+ ipRec.Insperity_benefits_effective_date__c.format() + '. <br/>';
                        }
                        if(ipRec.NSP_Old_Benefits_Package__c!=null && 
                        ipRec.Benefits_Package__c!=ipRec.NSP_Old_Benefits_Package__c){
                            isSendMail =true;
                            mailBody +='The Medical Package has changed from  '
                            + ipRec.NSP_Old_Benefits_Package__c +' to '+ ipRec.Benefits_Package__c;
                        }
                        mailBody += '<br/><br/>'+'Regards,'+'<br/>';
                        mailBody += ipwithValue.NSP_Project_Manager__r.Name+'<br/>';
                        mailBody += ipwithValue.NSP_Project_Manager__r.NSP_Job_Title__c+'<br/>';
                        mailBody += ipwithValue.NSP_Project_Manager__r.NSP_Work_email__c+'<br/>';
                        // update IP record 
                        String ImpProfKey = proj.Id + '~' + ipRec.Name;
                        Implementation_Profile__c impProfile = new Implementation_Profile__c();
                        impProfile.Id = ipRec.Id;
                        impProfile.NSP_Old_Effective_Date_EPLI__c = ipRec.Effective_Date_Payroll_Worker_comp_EPLI__c;
                        impProfile.NSP_Old_Insperity_Ben_effective_date__c = ipRec.Insperity_benefits_effective_date__c;
                        impProfile.NSP_Old_Benefits_Package__c = ipRec.Benefits_Package__c;
                        impProfileToUpdate.put(ImpProfKey,impProfile);
                        if(!listOfTOAddresses.isEmpty() && isSendMail){
                        	NSP_ProjectTaskTriggerEmailNotification.sendMail(subjectString,mailBody,listOfTOAddresses,null,null);
                        }
                   }
              }     
          }
      }
           
   }
    public  void createProjecttaskforPermierPerfomance(){
        
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(premierPerformance_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.MILESTONE, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                milestoneId = getMilestoneId(proj.pse__Milestones__r,NSP_ServiceConstants.MILESTONE); 

                        String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.MILESTONE;
                                                            
                        if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                            pse__Milestone__c eachMilestone1 = new pse__Milestone__c(Name=NSP_ServiceConstants.BENEFITS, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                            mileStonesToInsert.put(milestoneKey, eachMilestone1);
                        }
            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.CLIENTIMPL,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.MILESTONE;
                eachProjecttask.Name=NSP_ServiceConstants.PermierPerformanceTask;
                eachProjecttask.pse__Order__c=24;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Project_Manager__c != null && ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c!=null ){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Project_Manager__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.PremierPerformance,premierPerformance_FN,NSP_ServiceConstants.GENERAL,NSP_ServiceConstants.FSOProfile));
       
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
        
    }

   public  void createProjecttaskforEnrollFee(){
        
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecords = new List<NSP_Implementation_Profile_Automation__c>();
        
        for(Id ipRecId : ipRecordsByAutomation.get(enrollFee_FN)){
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                Id milestoneId;
                pse__Milestone__c eachMilestone = new pse__Milestone__c(Name=NSP_ServiceConstants.PayrollTraining_ML, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                milestoneId = getMilestoneId(proj.pse__Milestones__r,NSP_ServiceConstants.PayrollTraining_ML); 

                    String milestoneKey = proj.Id + '~' + NSP_ServiceConstants.PayrollTraining_ML;
                                                        
                    if(milestoneId == null && !mileStonesToInsert.containsKey(milestoneKey)){
                        pse__Milestone__c eachMilestone1 = new pse__Milestone__c(Name=NSP_ServiceConstants.PayrollTraining_ML, RecordTypeId=milestonePEORecordtypeId, pse__Project__c=proj.Id, pse__Target_Date__c=proj.pse__End_Date__c);
                        mileStonesToInsert.put(milestoneKey, eachMilestone1);
                    }
            
                pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,milestoneKey);
                eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.ClientTrainingCat;
                eachProjecttask.Name=NSP_ServiceConstants.ReviewenrollmentFeeTask;
                eachProjecttask.pse__Order__c=86;
                Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
                if(ipwithValue.NSP_Payroll_Specialist__c !=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null ){
                    eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                    eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                }
                if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                    eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                }
                eachProjecttask.pse__Milestone__c=milestoneId;
                
                projectTaskList.add(eachProjecttask);               
                
                ipAutomationRecords.add(NSP_Implprofile_ServiceHelperUpdate.createIPAutomation(ipRecId, NSP_ServiceConstants.ENROLLMENTFEE,enrollFee_FN,NSP_ServiceConstants.MISCELLANEOUS,NSP_ServiceConstants.FSOProfile));
       
            }
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
        //check for existing Automation record and store the new Automation records
        getnewAutomationListtoInsert(ipAutomationRecords,recToInsert,recToUpdate);
    }  
     public  void createSubtaskforEnrollment(){
        List<pse__Project_Task__c> projectTaskList = new List<pse__Project_Task__c>();
        List<pse__Project_Task__c> taskList = new List<pse__Project_Task__c>  (); 
        Map<Id,Implementation_Profile__c> impProfMap = new  Map<Id,Implementation_Profile__c>();
        Map<Id,Id> mapProjectIdIPId = new Map<Id,Id>();
        Map<Id,pse__Proj__c> projectMap = new Map<Id,pse__Proj__c>();
        for(Id ipRecId : ipRecordsByAutomation.get(enrollFee_FN)){
            Implementation_Profile__c ipwithValue=(Implementation_Profile__c) data.get(IMPL_PROFILE_IDENTIFIER).get(ipRecId);
            Implementation_Profile__c ipRec = newIPs.get(ipRecId);
            if((isRerun || ipRec.NSP_Form_Completed__c) && !isSaveForm){
                pse__Proj__c proj = (pse__Proj__c) data.get(PROJECT_IDENTIFIER).get(ipRec.NSP_Project__c);
                projectMap.put(proj.Id,proj);
                mapProjectIdIPId.put(proj.Id,ipRec.Id);
                if( proj.pse__Project_Tasks__r.size()>0){
                    taskList.addAll(proj.pse__Project_Tasks__r);
                }
                    if(ipwithValue.Id ==ipRec.Id){
                        impProfMap.put(proj.Id,ipwithValue);
                    }
            }
        
                for(pse__Project_Task__c pt: taskList){
                    pse__Proj__c proj = projectMap.get(pt.pse__Project__c);
                    if(pt.Name==NSP_ServiceConstants.FIRSTPAYROLL){
                            pse__Project_Task__c eachProjecttask = createProjectTaskfromIP(proj,  NSP_ServiceConstants.PAROLLIMP,null);
                             ipwithValue=impProfMap.get(pt.pse__Project__c);
                            if(ipwithValue.NSP_Payroll_Specialist__c!=null && ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c!=null){
                                eachProjecttask.OwnerId=ipwithValue.NSP_Payroll_Specialist__r.pse__Salesforce_User__c;
                            }
                            if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Name!=null){
                                eachProjecttask.NSP_Implementation_Profile_Account__c=ipwithValue.Account__r.Name;
                            }
                            if(ipwithValue.Account__c!=null && ipwithValue.Account__r.Id!=null){
                                eachProjecttask.NSP_Implementation_Account_Id__c=ipwithValue.Account__r.Id;
                            }
                            eachProjecttask.NSP_Sub_Category__c=NSP_ServiceConstants.WebPyPremierTraing;
                            eachProjecttask.Name=NSP_ServiceConstants.VerifyEnrollFeeTask;
                            eachProjecttask.pse__Parent_Task__c=pt.Id;
                            eachProjecttask.pse__Milestone__c=pt.pse__Milestone__c;
                            eachProjecttask.pse__Order__c=pt.pse__Order__c;
                            projectTaskList.add(eachProjecttask);  
                        
                    }
                }
            
        }
        //check for existing project task and store the new tasks
        recToInsert.addAll(getnewTaskstoInsert(projectTaskList));
    }
       
}