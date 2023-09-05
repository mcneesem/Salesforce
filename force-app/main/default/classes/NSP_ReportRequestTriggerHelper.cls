public with sharing class NSP_ReportRequestTriggerHelper {

    public void beforeUpdateDirector( Map<Id, NSP_ReportRequest__c> newMap, Map<Id, NSP_ReportRequest__c > oldMap){
        beforeInsertDirector(newMap.values(), oldMap);

    }
    public void beforeInsertDirector( List<NSP_ReportRequest__c> newList,  Map<Id, NSP_ReportRequest__c > oldMap){
        
        Id recordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_ReportRequest__c','NSP_DevelopmentReport');  

        for( NSP_ReportRequest__c eachRepoReq : newList ){
            
            if(recordTypeId != null && eachRepoReq.RecordTypeId == recordTypeId){

                if(eachRepoReq.NSP_Existing_NewReport__c != null && 
                    (oldMap.size() == 0 || oldMap.get(eachRepoReq.Id)?.NSP_Existing_NewReport__c != eachRepoReq.NSP_Existing_NewReport__c) ){ 
                    if(eachRepoReq.NSP_Existing_NewReport__c == NSP_ServiceConstants.NEW_REPORT){
                        eachRepoReq.NSP_Action__c = NSP_ServiceConstants.WIZARD_DEVELOPMENT ;
                        if(eachRepoReq.NSP_InternalClientReport__c == NSP_ServiceConstants.INTERNAL_REPORT){
                            eachRepoReq.NSP_ReportType__c =NSP_ServiceConstants.INTERNAL_CLIENT_REPORT;
                            eachRepoReq.NSP_ReportLocation__c =NSP_ServiceConstants.WEBFOCUS_MRE;
                        }
                    }else{
                        eachRepoReq.NSP_Action__c = NSP_ServiceConstants.WIZARD_MAINTENANCE;
                            eachRepoReq.NSP_ReportLocation__c =null ;
                    }
                }

                if(eachRepoReq.NSP_InternalClientReport__c != null &&
                    (oldMap.size() == 0 || oldMap.get(eachRepoReq.Id)?.NSP_InternalClientReport__c != eachRepoReq.NSP_InternalClientReport__c)){ 
                    if(eachRepoReq.NSP_InternalClientReport__c == NSP_ServiceConstants.INTERNAL_REPORT){
                        if(eachRepoReq.NSP_Existing_NewReport__c == NSP_ServiceConstants.NEW_REPORT){
                            eachRepoReq.NSP_ReportType__c =NSP_ServiceConstants.INTERNAL_CLIENT_REPORT;
                        }
                        eachRepoReq.NSP_ReportLocation__c =NSP_ServiceConstants.WEBFOCUS_MRE;
                    }else{
                        eachRepoReq.NSP_ReportType__c = null;
                    }
                }
                if(eachRepoReq.NSP_ReportLocation__c != null && 
                    (oldMap.size() == 0 || oldMap.get(eachRepoReq.Id)?.NSP_ReportLocation__c != eachRepoReq.NSP_ReportLocation__c) ){ 
                    if(eachRepoReq.NSP_ReportLocation__c == NSP_ServiceConstants.PREMIER_REPORTING){
                        eachRepoReq.NSP_Misc__c = NSP_ServiceConstants.WIRE;
                    }
                    if(eachRepoReq.NSP_ReportLocation__c ==NSP_ServiceConstants.WEBFOCUS_MRE){
                        eachRepoReq.NSP_Misc__c = NSP_ServiceConstants.NON_WIRE;
                    }
                }
            }      
        }
    }

    /*
     * Description: This method is used to validate completed wizard record before deleting
     * @Param : List<NSP_ReportRequest__c> oldList and Map<Id, NSP_ReportRequest__c > oldMap
     * @return type: void
     * Defect:DF-02745
     */
    public void beforeDeleteDirector( List<NSP_ReportRequest__c> oldList,  Map<Id, NSP_ReportRequest__c > oldMap){
        
        String profileName = [Select Name from Profile WHERE Id =: userinfo.getProfileid()].Name;
        for( NSP_ReportRequest__c eachRepoReq : oldList ){
            if(!eachRepoReq.NSP_IsDraft__c  &&  String.isNotBlank(profileName) 
             && profileName != NSP_ServiceConstants.SYSTEM_ADMINISTRATOR){
                eachRepoReq.addError(label.NSP_Restrict_Wizard_Delete);
            }
        }
        
    }
    
}
