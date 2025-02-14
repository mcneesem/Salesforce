/**
* @description  :  class for calling Automations from FSO Form.
* @date 07/28/2022
* Author : Nischay .J
* Name : NSP_FSOImplementationController
*/
public with sharing class NSP_FSOImplementationController {
    // test w/ NSP_FSOImplementationControllerTest (??%)

    /***********************************************************************************************
    * MethodName: loadAutomationRecords
    * Description : This Method will load all the automations for the given IP record Id
    * Params:       String recordId
    * ********************************************************************************************/
    @AuraEnabled
    public static List<IPAutomationWrapper> loadAutomationRecords(String recordId, String recordTypeId) {
        List<IPAutomationWrapper> ipWrapperList = new List<IPAutomationWrapper>();
        try {
            // Fetch the implementation record type name
            String impRecordTypeName = getImplementationRecordTypeName(recordTypeId);
    
            // Get automation metadata table for the specific record type
            List<NSP_Implementation_Automations__mdt> automationTable = getAutomationTable(impRecordTypeName);
    
            // Filter out certain automation types based on trigger settings
            filterAutomations(automationTable);

            // Load implementation profile and automation records
            Map<Id,Implementation_Profile__c> impProfileMap = loadImplementationProfile( recordId );
            Implementation_Profile__c impProfile = new Implementation_Profile__c();
            if ( ( impProfileMap != null ) && !impProfileMap.values().isEmpty() ) {
                impProfile = impProfileMap.values()[0];
            }

            // Get task automation records
            Map<String, Set<Id>> ipRecordsByAutomationMap = executeAutomationTasks(impProfile, impRecordTypeName);
    
            // Fetch existing automation records for the given profile
            Map<String, NSP_Implementation_Profile_Automation__c> mapAutomationNameIPRecord = getExistingAutomationRecords(recordId, impProfile);
    
            // Create map of automation sections and associated automation list
            Map<String, List<IPAutomationList>> mapSectionNameListSectionTable = getSectionAutomationTable(automationTable, impProfile, mapAutomationNameIPRecord, ipRecordsByAutomationMap);
    
            // Prepare the response wrapper for the UI
            ipWrapperList = prepareIPAutomationWrappers(mapSectionNameListSectionTable);
    
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return ipWrapperList;
    }

    private static String getImplementationRecordTypeName( String recordTypeId ) {
        Map<String,Schema.RecordTypeInfo> recordTypeMap = NSP_GenericRecordType.getRecordTypeMap( 'Implementation_Profile__c' );
        String recordTypeName = null;
        if ( recordTypeMap != null ) {
            for ( Schema.RecordTypeInfo info : recordTypeMap.values() ) {
                if ( info.getRecordTypeId() == recordTypeId ) {
                    recordTypeName = info.getName();
                }
            }
        }
        return recordTypeName;
    }

    private static List<NSP_Implementation_Automations__mdt> getAutomationTable( String impRecordTypeName ) {
        List<NSP_Implementation_Automations__mdt> automationList = new List<NSP_Implementation_Automations__mdt> (); 
        if ( impRecordTypeName!= null ) {
            automationList = [
                SELECT
                    Id ,
                    Sort_Order__c ,
                    NSP_Automation_Order__c ,
                    DeveloperName ,
                    MasterLabel ,
                    Label ,
                    NSP_Automation_Name__c ,
                    NSP_Type_of_Automation__c ,
                    NSP_Section__c ,
                    NSP_Method_Name__c ,
                    NSP_Class_Name__c ,
                    NSP_IP_Record_Type__c ,
                    NSP_IP_Record_Type_IP__c
                FROM NSP_Implementation_Automations__mdt
                WHERE (
                    NSP_IP_Record_Type__c = :impRecordTypeName
                    AND NSP_Section__c != null
                )
                ORDER BY Sort_Order__c , NSP_Automation_Order__c NULLS LAST
            ];
        }
        return automationList;
    }

    private static void filterAutomations( List<NSP_Implementation_Automations__mdt> automationTable ) {
        NSP_Trigger_Switch__c triggerSwitch = NSP_Trigger_Switch__c.getInstance( UserInfo.getUserId() );
        Implementation_Profile_Settings__c ipSettings = Implementation_Profile_Settings__c.getInstance( UserInfo.getUserId() );
        if ( ( automationTable != null )
            && !automationTable.isEmpty()
            && ( triggerSwitch != null )
            && ( ipSettings != null )
            )
        {
            for (Integer i = automationTable.size() - 1; i >= 0; i--) {
                if (shouldRemovePremierPerformanceAutomation(automationTable[i], triggerSwitch)) {
                    automationTable.remove(i);
                } else if (shouldRemoveLeviesAutomation(automationTable[i], ipSettings)) {
                    automationTable.remove(i);
                }
            }
        }
    }

    private static Boolean shouldRemovePremierPerformanceAutomation( NSP_Implementation_Automations__mdt automation , NSP_Trigger_Switch__c triggerSwitch ) {
        Boolean premierPerformance = false;
        if ( ( automation != null )
            && ( automation.NSP_Automation_Name__c == NSP_ServiceConstants.PremierPerformance )
            && triggerSwitch.Premier_Performance_Automation__c
            )
        {
            premierPerformance = true;
        }
        return premierPerformance;
    }

    private static Boolean shouldRemoveLeviesAutomation( NSP_Implementation_Automations__mdt automation , Implementation_Profile_Settings__c ipSettings ) {
        Boolean removeLevies = false;
        if ( ( automation != null )
            && ( automation.NSP_Automation_Name__c == NSP_ServiceConstants.LEVIES )
            && ( automation.NSP_IP_Record_Type__c == NSP_ServiceConstants.MIDDLEMARKET )
            && !ipSettings.Is_Enabled_Levies__c
            )
        {
            removeLevies = true;
        }
        return removeLevies;
    }

    private static Map<Id,Implementation_Profile__c> loadImplementationProfile( String recordId ) {
        Map<Id,Implementation_Profile__c> ipMap = new Map<Id,Implementation_Profile__c>();
        if ( recordId != null ) {
            ipMap = NSP_ImpAutomationsController.getIpRecord( recordId );
        }
        return ipMap;
    }

    private static Map<String,Set<Id>> executeAutomationTasks( Implementation_Profile__c impProfile , String impRecordTypeName ) {
        Map<String,Set<Id>> ipRecordsByAutomationMap = new Map<String,Set<Id>>();
        if ( impProfile != null ) {
            if ( String.isNotBlank( impRecordTypeName ) && ( impRecordTypeName == NSP_ServiceConstants.FSOAutomations ) ) {
                NSP_Implprofile_ServiceHelperUpdate impTasks = new NSP_Implprofile_ServiceHelperUpdate(new Map<Id, Implementation_Profile__c>{ impProfile.Id => impProfile }, null);
                ipRecordsByAutomationMap = impTasks.executeAutomation();
            } else {
                NSP_MMImplProfile_ServHelpUpdate impTasks = new NSP_MMImplProfile_ServHelpUpdate(new Map<Id, Implementation_Profile__c>{ impProfile.Id => impProfile }, null);
                ipRecordsByAutomationMap = impTasks.executeAutomation();
            }
        }
        return ipRecordsByAutomationMap;
    }

    private static Map<String, NSP_Implementation_Profile_Automation__c> getExistingAutomationRecords(String recordId, Implementation_Profile__c impProfile) {
        List<NSP_Implementation_Profile_Automation__c> ipAutomationRecordsList = new List<NSP_Implementation_Profile_Automation__c>();
        if ( String.isNotBlank(recordId) && ( impProfile != null ) && ( impProfile.RecordType != null ) ) {
            ipAutomationRecordsList = [
                SELECT
                    Id ,
                    OwnerId ,
                    Name ,
                    NSP_Last_Run__c ,
                    NSP_Method_Name__c ,
                    NSP_Class_Name__c ,
                    NSP_Implementation_Profile__c ,
                    NSP_Implementation_Profile__r.NSP_Form_Completed__c ,
                    NSP_Section__c ,
                    NSP_Record_Type__c
                FROM NSP_Implementation_Profile_Automation__c
                WHERE (
                    NSP_Implementation_Profile__c = :recordId
                    AND NSP_Record_Type__c = :impProfile.recordType.Name
                )
            ];
        }
        Map<String, NSP_Implementation_Profile_Automation__c> mapAutomationNameIPRecord = new Map<String, NSP_Implementation_Profile_Automation__c>();
        if(ipAutomationRecordsList != null){
            for (NSP_Implementation_Profile_Automation__c ipAutomation : ipAutomationRecordsList) {
                mapAutomationNameIPRecord.put(ipAutomation.Name, ipAutomation);
            }
        }
        return mapAutomationNameIPRecord;
    }

    private static Map<String,List<IPAutomationList>> getSectionAutomationTable(
        List<NSP_Implementation_Automations__mdt> automationTable ,
        Implementation_Profile__c impProfile ,
        Map<String,NSP_Implementation_Profile_Automation__c> mapAutomationNameIPRecord ,
        Map<String,Set<Id>> ipRecordsByAutomationMap
        )
    {
        return getmapSectionNameListSectionTable(
            automationTable ,
            impProfile ,
            mapAutomationNameIPRecord ,
            ipRecordsByAutomationMap ,
            new Map<String,Set<Id>>()
        );
    }

    private static List<IPAutomationWrapper> prepareIPAutomationWrappers( Map<String,List<IPAutomationList>> mapSectionNameListSectionTable ) {
        List<IPAutomationWrapper> ipWrapperList = new List<IPAutomationWrapper>();
        if(mapSectionNameListSectionTable!= null && !mapSectionNameListSectionTable.isEmpty()) {
            for (String sectionName : mapSectionNameListSectionTable.keySet()) {
                IPAutomationWrapper ipWrapper = new IPAutomationWrapper();
                ipWrapper.sectionName = sectionName;
                ipWrapper.automationTableList = mapSectionNameListSectionTable.get(sectionName);
                ipWrapperList.add(ipWrapper);
            }
        }
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