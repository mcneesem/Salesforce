/**
* @description  :  class for calling Automations from FSO Form.
* @date 07/28/2022
* Author : Nischay .J
* Name : NSP_FSOImplementationController
*/
public class NSP_FSOImplementationController {
    /***********************************************************************************************
    * MethodName: loadAutomationRecords
    * Description : This Method will load all the automations for the given IP record Id
    * Params:       String recordId
    * ********************************************************************************************/
    @AuraEnabled
    public static List<IPAutomationWrapper>  loadAutomationRecords(String recordId, String recordTypeId){
        Map<String,NSP_Implementation_Profile_Automation__c> mapAutomationNameIPRecord = new   Map<String,NSP_Implementation_Profile_Automation__c>();
        Map<String,List<IPAutomationList>> mapSectionNameListSectionTable = new  Map<String,List<IPAutomationList>>();
        List<IPAutomationWrapper> ipWrapperList = new List<IPAutomationWrapper>();
        Map<Id, Implementation_Profile__c>  impProfileMap = new Map<Id, Implementation_Profile__c>();
        Implementation_Profile__c impProfile = new Implementation_Profile__c ();
        Map<String, Set<Id>> ipRecordsByAutomationMap = new Map<String, Set<Id>> ();
        Map<String, Set<Id>> ipRecordsByAutomationTaskMap = new Map<String, Set<Id>> ();
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecordsList = new List<NSP_Implementation_Profile_Automation__c> ();
        try{
            String impRecordTypeName = Schema.getGlobalDescribe().get(NSP_ServiceConstants.implProfile).getDescribe().getRecordTypeInfosById().get(recordTypeId).getName();
            
            // Searching for all the automations in the metadata for the FSO IP  
            List<NSP_Implementation_Automations__mdt> automationTable = [SELECT Id, Sort_Order__c,NSP_Automation_Order__c,DeveloperName, MasterLabel, Label, NSP_Automation_Name__c, NSP_Type_of_Automation__c, 
                                                                         NSP_Section__c, NSP_Method_Name__c, NSP_Class_Name__c, NSP_IP_Record_Type__c,NSP_IP_Record_Type_IP__c 
                                                                         FROM NSP_Implementation_Automations__mdt WHERE NSP_IP_Record_Type__c =: impRecordTypeName AND NSP_Section__c!=null 
                                                                         Order By Sort_Order__c , NSP_Automation_Order__c NULLS  LAST  ];
            //Exclude Premier Performance automation if triggerSwitch.Premier_Performance_Automation__c = true
            //AZD-271433
            NSP_Trigger_Switch__c triggerSwitch =  NSP_Trigger_Switch__c.getInstance(UserInfo.getUserId());
            if(triggerSwitch != null && triggerSwitch.Premier_Performance_Automation__c) {
                if ( ( automationTable != null ) && !automationTable.isEmpty() ) {
                    for(Integer i = automationTable.size() - 1; i >=0; i--) {
                        if(automationTable[i].NSP_Automation_Name__c == NSP_ServiceConstants.PremierPerformance) {
                            automationTable.remove(i);
                        }
                    }
                }
            }

            if(recordId !=null){
                impProfileMap = NSP_ImpAutomationsController.getIpRecord(recordId);
                impProfile =impProfileMap.values()[0];
                NSP_Implementationprofile_ServiceHelper impService = new NSP_Implementationprofile_ServiceHelper(impProfileMap, null);
                ipRecordsByAutomationMap= impService.executeAutomation();
                
                if(impRecordTypeName == NSP_ServiceConstants.FSOAutomations){
                    NSP_Implprofile_ServiceHelperUpdate impTasks = new NSP_Implprofile_ServiceHelperUpdate(impProfileMap, null);
                    ipRecordsByAutomationTaskMap= impTasks.executeAutomation();
                }
                else {
                    NSP_MMImplProfile_ServHelpUpdate impTasks = new NSP_MMImplProfile_ServHelpUpdate(impProfileMap, null);
                    ipRecordsByAutomationTaskMap= impTasks.executeAutomation();
                }
                
                // searching for the existing automation for the given IP 
                ipAutomationRecordsList =[SELECT Id, OwnerId, Name, NSP_Last_Run__c, NSP_Method_Name__c, NSP_Class_Name__c, NSP_Implementation_Profile__c,NSP_Implementation_Profile__r.NSP_Form_Completed__c, NSP_Section__c,
                                          NSP_Record_Type__c FROM NSP_Implementation_Profile_Automation__c WHERE NSP_Implementation_Profile__c =:recordId AND  NSP_Record_Type__c =:impProfile.recordType.Name ];
                
                // creating a map of automation Name and Automation record
                for(NSP_Implementation_Profile_Automation__c ipAutomation:ipAutomationRecordsList ){
                    mapAutomationNameIPRecord.put(ipAutomation.Name,ipAutomation);
                }
            }
            mapSectionNameListSectionTable = getmapSectionNameListSectionTable(automationTable,impProfile, 
                                                                               mapAutomationNameIPRecord,ipRecordsByAutomationMap,ipRecordsByAutomationTaskMap);
            
            
            for(String IPAutomation: mapSectionNameListSectionTable.Keyset()){
                IPAutomationWrapper ipWrapper = new IPAutomationWrapper();
                ipWrapper.sectionName = IPAutomation;
                ipWrapper.automationTableList = mapSectionNameListSectionTable.get(IPAutomation);
                ipWrapperList.add(ipWrapper);
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        // returning wrapper to UI 
        return ipWrapperList;
    }
    
    /***********************************************************************************************
    * MethodName: mapSectionNameListSectionTable
    * Description : This method will set and filter all the automations  
    * ********************************************************************************************/
    private static Map<String,List<IPAutomationList>> getmapSectionNameListSectionTable(List<NSP_Implementation_Automations__mdt> automationTable,  Implementation_Profile__c impProfile,Map<String,NSP_Implementation_Profile_Automation__c> mapAutomationNameIPRecord,Map<String, Set<Id>>  ipRecordsByAutomationMap, Map<String, Set<Id>>  ipRecordsByAutomationTaskMap ){
        Map<String,List<IPAutomationList>> mapSectionNameListSectionTable = new  Map<String,List<IPAutomationList>>();
        
        // creating a Wrapper to load the table in UI 
        for(NSP_Implementation_Automations__mdt ipTable :automationTable){
            if(!mapSectionNameListSectionTable.containsKey(ipTable.NSP_Section__c)){
                mapSectionNameListSectionTable.put(ipTable.NSP_Section__c, new List<IPAutomationList>());
            }
            if(mapSectionNameListSectionTable.containsKey(ipTable.NSP_Section__c)){
                IPAutomationList ipAutomationWrapperList = new IPAutomationList();
                ipAutomationWrapperList.automationName = ipTable.NSP_Automation_Name__c;
                ipAutomationWrapperList.automationType = ipTable.NSP_Type_of_Automation__c; 
                ipAutomationWrapperList.automationClassName = ipTable.NSP_Class_Name__c;
                ipAutomationWrapperList.automationMethodName = ipTable.NSP_Method_Name__c;
                ipAutomationWrapperList.automationRecordType = ipTable.NSP_IP_Record_Type__c;
                ipAutomationWrapperList.automationSection = ipTable.NSP_Section__c;
                // if form completed is true make all the icons green
                if(impProfile.NSP_Form_Completed__c){
                    ipAutomationWrapperList.iconCss = NSP_ServiceConstants.EnableButton;
                }
                else{
                    ipAutomationWrapperList.iconCss = NSP_ServiceConstants.DisableButton;
                }
                // Disable the Button 
                ipAutomationWrapperList.rerunCss =NSP_ServiceConstants.DisableButton;
                ipAutomationWrapperList.isDisabled = true;   
                
                // set Automation Map
                ipAutomationWrapperList = fetchAllAutomations(ipAutomationWrapperList,ipTable,ipRecordsByAutomationMap,ipRecordsByAutomationTaskMap,mapAutomationNameIPRecord);
                
                // setting the Automation Icons for Case , Email , Project
                //Email Automation
                ipAutomationWrapperList = fetchEmailAutomations(ipAutomationWrapperList,ipTable,ipRecordsByAutomationMap,ipRecordsByAutomationTaskMap,mapAutomationNameIPRecord);
                // case Automations
                ipAutomationWrapperList = fetchCaseAutomations(ipAutomationWrapperList,ipTable,ipRecordsByAutomationMap,ipRecordsByAutomationTaskMap,mapAutomationNameIPRecord);
                // Project Automation
                ipAutomationWrapperList = fetchProjectAutomations(ipAutomationWrapperList,ipTable,ipRecordsByAutomationMap,ipRecordsByAutomationTaskMap,mapAutomationNameIPRecord);
                
                mapSectionNameListSectionTable.get(ipTable.NSP_Section__c).add(ipAutomationWrapperList);
            } 
        }
        return mapSectionNameListSectionTable;
        
    }
    /***********************************************************************************************
    * MethodName: fetchAllAutomations
    * Description : This Method will fetch All  the automations
    * ********************************************************************************************/
    private static IPAutomationList fetchAllAutomations(IPAutomationList ipAutomationWrapperList ,NSP_Implementation_Automations__mdt ipTable,Map<String, Set<Id>>  ipRecordsByAutomationMap,  Map<String, Set<Id>> ipRecordsByAutomationTaskMap,Map<String,NSP_Implementation_Profile_Automation__c> mapAutomationNameIPRecord ){
        if(mapAutomationNameIPRecord.containsKey(ipTable.NSP_Automation_Name__c) ){
            
            // adding last run date in the table by compairing it with the Existing automations 
            ipAutomationWrapperList.automationId = mapAutomationNameIPRecord.get(ipTable.NSP_Automation_Name__c).Id;
            if(mapAutomationNameIPRecord.get(ipTable.NSP_Automation_Name__c).NSP_Last_Run__c !=null){
                // change the format of Date Time 
                DateTime lastRunDT = mapAutomationNameIPRecord.get(ipTable.NSP_Automation_Name__c).NSP_Last_Run__c;
                Date lastRunDate = date.newinstance(lastRunDT.year(), lastRunDT.month(), lastRunDT.day());
                ipAutomationWrapperList.lastrun = String.valueOf(lastRunDate) +' '+  lastRunDT.format('hh:mm:ss a');
                // Disable the automations for existing cases and task  
                if(ipTable.NSP_Type_of_Automation__c!=NSP_ServiceConstants.EmailAutomation){
                    ipAutomationWrapperList.rerunCss =NSP_ServiceConstants.DisableButton;
                }else if(ipTable.NSP_Type_of_Automation__c==NSP_ServiceConstants.EmailAutomation && 
                         ipRecordsByAutomationMap.containsKey(ipTable.NSP_Method_Name__c)) {
                    ipAutomationWrapperList.isDisabled = false;
                    ipAutomationWrapperList.rerunCss =NSP_ServiceConstants.EnableButton;
                } 
            }
        }
        return ipAutomationWrapperList;
    }
    
    /***********************************************************************************************
    * MethodName: fetchEmailAutomations
    * Description : This Method will fetch Email related automations
    * ********************************************************************************************/
    private static IPAutomationList fetchEmailAutomations(IPAutomationList ipAutomationWrapperList ,NSP_Implementation_Automations__mdt ipTable,Map<String, Set<Id>>  ipRecordsByAutomationMap,   Map<String, Set<Id>> ipRecordsByAutomationTaskMap,Map<String,NSP_Implementation_Profile_Automation__c> mapAutomationNameIPRecord ){
        if(ipTable.NSP_Type_of_Automation__c==NSP_ServiceConstants.EmailAutomation){
            if(ipRecordsByAutomationMap.containsKey(ipTable.NSP_Method_Name__c) || ipRecordsByAutomationTaskMap.containsKey(ipTable.NSP_Method_Name__c)){
                ipAutomationWrapperList.iconsName =NSP_ServiceConstants.AutomationEmailIcon;
                if(!mapAutomationNameIPRecord.containsKey(ipTable.NSP_Automation_Name__c)){
                    ipAutomationWrapperList.isDisabled = true;
                    ipAutomationWrapperList.rerunCss =NSP_ServiceConstants.DisableButton;
                }
            }
            else{
                ipAutomationWrapperList.iconsName =NSP_ServiceConstants.EmailIcon;
            }
        }
        return ipAutomationWrapperList;
    }
    
    /***********************************************************************************************
    * MethodName: fetchCaseAutomations
    * Description : This Method will fetch Case related automations
    * ********************************************************************************************/
    private static IPAutomationList fetchCaseAutomations(IPAutomationList ipAutomationWrapperList ,NSP_Implementation_Automations__mdt ipTable,Map<String, Set<Id>>  ipRecordsByAutomationMap, Map<String, Set<Id>> ipRecordsByAutomationTaskMap,Map<String,NSP_Implementation_Profile_Automation__c> mapAutomationNameIPRecord ){
        if(ipTable.NSP_Type_of_Automation__c==NSP_ServiceConstants.CaseAutomation) {
            if(ipRecordsByAutomationMap.containsKey(ipTable.NSP_Method_Name__c) || ipRecordsByAutomationTaskMap.containsKey(ipTable.NSP_Method_Name__c)){
                ipAutomationWrapperList.iconsName =NSP_ServiceConstants.AutomationCaseIcon;
                if(!mapAutomationNameIPRecord.containsKey(ipTable.NSP_Automation_Name__c)){
                    ipAutomationWrapperList.isDisabled = true;
                    ipAutomationWrapperList.rerunCss =NSP_ServiceConstants.DisableButton;
                }
            }
            else{
                ipAutomationWrapperList.iconsName =NSP_ServiceConstants.CaseIcon;
            }
        }
        return ipAutomationWrapperList;
    }
    
    /***********************************************************************************************
    * MethodName: fetchProjectAutomations
    * Description : This Method will fetch project related automations
    * ********************************************************************************************/
    private static IPAutomationList fetchProjectAutomations(IPAutomationList ipAutomationWrapperList ,NSP_Implementation_Automations__mdt ipTable,Map<String, Set<Id>>  ipRecordsByAutomationMap,  Map<String, Set<Id>> ipRecordsByAutomationTaskMap, Map<String,NSP_Implementation_Profile_Automation__c> mapAutomationNameIPRecord ){
        if(ipTable.NSP_Type_of_Automation__c==NSP_ServiceConstants.ProjectAutomation) {
            if(ipRecordsByAutomationMap.containsKey(ipTable.NSP_Method_Name__c) || ipRecordsByAutomationTaskMap.containsKey(ipTable.NSP_Method_Name__c)){
                ipAutomationWrapperList.iconsName =NSP_ServiceConstants.AutomationProjectIcon;
                if(!mapAutomationNameIPRecord.containsKey(ipTable.NSP_Automation_Name__c)){
                    ipAutomationWrapperList.isDisabled = true;
                    ipAutomationWrapperList.rerunCss =NSP_ServiceConstants.DisableButton;
                }
                
            }
            else{
                ipAutomationWrapperList.iconsName =NSP_ServiceConstants.ProjectIcon;
            }
        }
        return ipAutomationWrapperList;             
    }
    /***********************************************************************************************
    * MethodName: runIpAutomations
    * Description : This Method will rerun the automations 
    * Params:       String recordId
    * ********************************************************************************************/
    @AuraEnabled
    public static Boolean runIpAutomations(String recordId,String automationType, String automationMethodName, String ipRecordType ){
        Boolean isUpdated;                            
        try{
            if(automationType==NSP_ServiceConstants.ProjectAutomation){
                if(ipRecordType == NSP_ServiceConstants.FSOAutomations){
                    NSP_Implprofile_ServiceHelperUpdate fSOProjectTaskAutomations = new NSP_Implprofile_ServiceHelperUpdate(recordId,automationMethodName);
                    fSOProjectTaskAutomations.executeAutomation(); 
                }else{
                    NSP_MMImplProfile_ServHelpUpdate mmProjectTaskAutomations = new NSP_MMImplProfile_ServHelpUpdate(recordId,automationMethodName);
                    mmProjectTaskAutomations.executeAutomation();   
                }   
                isUpdated =true;
            }
            else {
                NSP_Implementationprofile_ServiceHelper fSOCaseEmailAutomations = new NSP_Implementationprofile_ServiceHelper(recordId,automationMethodName);
                fSOCaseEmailAutomations.executeAutomation();
                isUpdated =true;
            }
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
        return isUpdated;
    }
    
    /***********************************************************************************************
    * Class: IPAutomationWrapper
    * Description : Wrapper Class 
    * ********************************************************************************************/
    public class IPAutomationWrapper {
        @AuraEnabled
        public String sectionName{get;set;} 
        @AuraEnabled
        public List<IPAutomationList> automationTableList{get;set;} 
    }
    /***********************************************************************************************
    * Class: IPAutomationList
    * Description : Wrapper Class 
    * ********************************************************************************************/
    public class IPAutomationList {
        @AuraEnabled
        public String automationName{get;set;}
        @AuraEnabled
        public String automationType{get;set;}
        @AuraEnabled
        public String lastrun{get;set;}
        @AuraEnabled
        public String iconsName{get;set;}
        @AuraEnabled
        public String iconCss{get;set;}
        @AuraEnabled
        public String rerunCss{get;set;}
        @AuraEnabled
        public String automationMethodName{get;set;}
        @AuraEnabled
        public String automationClassName{get;set;}
        @AuraEnabled
        public String automationId{get;set;}
        @AuraEnabled
        public String automationRecordType{get;set;}
        @AuraEnabled
        public String automationSection{get;set;}
        @AuraEnabled
        public Boolean isDisabled{get;set;}
        
    }
    
}