public class NSP_ImplementationProfileHandler implements NSP_ITriggerHandler {
    // test w/ NSP_ImplProfileTriggerHelperTest (92%)

    public static Boolean TriggerDisabled = false;

    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    public void beforeInsert( List<sObject> newList ) {
        NSP_IPServiceHelper_Insert implementationProfileServiceHelper = new NSP_IPServiceHelper_Insert();
        implementationProfileServiceHelper.updateAssetOnImpProfile(
            (List<Implementation_Profile__c>)newList
        );
    }

    public void afterInsert( List<sObject> newList , Map<Id, sObject> newMap ) {
        Map<Id,Implementation_Profile__c> newIPs = (Map<Id,Implementation_Profile__c>)newMap;
        //Handles IP automation for project task creation for both FSO and MM -STY-01959
        NSP_Implprofile_ServiceHelperUpdate implementationProfileServiceHelperUpdate = new NSP_Implprofile_ServiceHelperUpdate(
            newIPs ,
            null
        );
        implementationProfileServiceHelperUpdate.executeAutomation();
        //Handles IP automation for case creation for both FSO and MM - STY-02166 & STY-02194
        NSP_Implementationprofile_ServiceHelper ipCaseHandler = new NSP_Implementationprofile_ServiceHelper(
            newIPs ,
            null
        );
        ipCaseHandler.executeAutomation();
    }

    public void beforeUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
    }

    public void afterUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
        // added as a part of STY-03121
        NSP_ImplementaionProfileTriggerHelper.updateProjectTeamRoles(
            (Map<Id,Implementation_Profile__c>)newMap ,
            (Map<Id, Implementation_Profile__c>)oldMap
        );
        Map<Id,Implementation_Profile__c> newIPs = (Map<Id,Implementation_Profile__c>)newMap;
        Map<Id,Implementation_Profile__c> oldIPs = (Map<Id,Implementation_Profile__c>)oldMap;
        //Handles IP automation for project task creation for both FSO and MM -STY-01959
        NSP_Implprofile_ServiceHelperUpdate implementationProfileServiceHelperUpdate = new NSP_Implprofile_ServiceHelperUpdate(
            newIPs ,
            oldIPs
        );
        implementationProfileServiceHelperUpdate.executeAutomation();
        //Handles IP automation for case creation for both FSO and MM - STY-02166 & STY-02194
        NSP_Implementationprofile_ServiceHelper ipCaseHandler = new NSP_Implementationprofile_ServiceHelper(
            newIPs ,
            oldIPs
        );
        ipCaseHandler.executeAutomation();
        //Handles IP automation for project task creation for both  MM - STY-02194
        NSP_MMImplProfile_ServHelpUpdate mmServiceHelper = new NSP_MMImplProfile_ServHelpUpdate(
            newIPs ,
            oldIPs
        );
        mmServiceHelper.executeAutomation();
    }

    public void beforeDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
    }

    public void afterDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
    }

}
//