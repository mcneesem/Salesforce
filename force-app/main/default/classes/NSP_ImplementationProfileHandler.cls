/**
 * Represents the Asset trigger handler.
 */

public class NSP_ImplementationProfileHandler implements NSP_ITriggerHandler{
	
    //Use this variable to disable this trigger from transaction.
    public static Boolean TriggerDisabled = false;

    /**
     * Represents whether the trigger is disabled or not.
     * @param N/A.
     * @return Boolean
     *
     */

    public Boolean isDisabled(){
        return TriggerDisabled;
    }
    
    public void beforeInsert(List<sObject> newList) {
        NSP_IPServiceHelper_Insert  implementationProfileServiceHelper =  new NSP_IPServiceHelper_Insert();
        implementationProfileServiceHelper.updateAssetOnImpProfile((List<Implementation_Profile__c>)newList);
        
    }
    /**
    * Handles after insert for Implementation Profile
    * @param newList List of New Implementation Profile.
    * @param newMap Map of New Implementation Profile. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        Map<Id,Implementation_Profile__c> newIPs = (Map<Id,Implementation_Profile__c>)newMap;
        //Handles IP automation for project task creation for both FSO and MM -STY-01959
        NSP_Implprofile_ServiceHelperUpdate implementationProfileServiceHelperUpdate= new NSP_Implprofile_ServiceHelperUpdate(newIPs,null);
        implementationProfileServiceHelperUpdate.executeAutomation();
        //Handles IP automation for case creation for both FSO and MM - STY-02166 & STY-02194
        NSP_Implementationprofile_ServiceHelper ipCaseHandler= new NSP_Implementationprofile_ServiceHelper(newIPs,null);
        ipCaseHandler.executeAutomation();
    }
    
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    }
    
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        //   added as a part of STY-03121 by Nischay Jindal 
        NSP_ImplementaionProfileTriggerHelper.updateProjectTeamRoles((Map<Id,Implementation_Profile__c>)newMap, (Map<Id, Implementation_Profile__c>) oldMap);
        
        Map<Id,Implementation_Profile__c> newIPs = (Map<Id,Implementation_Profile__c>)newMap;
        Map<Id,Implementation_Profile__c> oldIPs = (Map<Id, Implementation_Profile__c>) oldMap;
        //Handles IP automation for project task creation for both FSO and MM -STY-01959
        NSP_Implprofile_ServiceHelperUpdate implementationProfileServiceHelperUpdate= new NSP_Implprofile_ServiceHelperUpdate(newIPs, oldIPs);
        implementationProfileServiceHelperUpdate.executeAutomation();
        //Handles IP automation for case creation for both FSO and MM - STY-02166 & STY-02194
        NSP_Implementationprofile_ServiceHelper ipCaseHandler= new NSP_Implementationprofile_ServiceHelper(newIPs, oldIPs);
        ipCaseHandler.executeAutomation();
        //Handles IP automation for project task creation for both  MM - STY-02194
        NSP_MMImplProfile_ServHelpUpdate mmServiceHelper= new NSP_MMImplProfile_ServHelpUpdate(newIPs, oldIPs);
        mmServiceHelper.executeAutomation();
        
        //added as a part of STY-03103 tracking History
        if(newMap.size() > 0){
            NSP_SObjectHistoryTrackingHelper objectFieldHistoryHelper = new NSP_SObjectHistoryTrackingHelper((Map<Id, sObject>)newMap, (Map<Id, sObject>)oldMap);
            If( Limits.getQueueableJobs() != Limits.getLimitQueueableJobs()) {
                System.enqueueJob(objectFieldHistoryHelper);  
            }
        }
    
           
    }
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
     
    }
    
}