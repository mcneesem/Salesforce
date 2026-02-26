public class NSP_ProjectTasksTriggerHandler implements NSP_ITriggerHandler {
    // test w/ NSP_ProjectTasksTriggerHelperTest (100%)

    //Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;
    public static Boolean runOnce = true;

    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    public void beforeInsert( List<sObject> newList ) {
        NSP_ProjectTasksTriggerHelper projectTaskTriggerHelperObject =  new NSP_ProjectTasksTriggerHelper();
        projectTaskTriggerHelperObject.updateProjecttaskFields((List<pse__Project_Task__c>)newList);
        //Handling STY-02129 part also
        projectTaskTriggerHelperObject.setStartDateAndEndDateOnProjectTask((List<pse__Project_Task__c>)newList);
        projectTaskTriggerHelperObject.updateTemplateNameOnProjectTaskAndTemplatesUsedOnProject((List<pse__Project_Task__c>)newList);
        NSP_ProjectTasksTriggerServiceHelper oProjectTaskServiceHelper = new NSP_ProjectTasksTriggerServiceHelper();
        oProjectTaskServiceHelper.updateRecordType((List<pse__Project_Task__c>)newList);

        // added as a part of STY-03071
        NSP_ProjectTasksTriggerHelper.assignQueueTasks((List<pse__Project_Task__c>)newList);
        // added as a part of STY-01671
        NSP_ProjectTasksTriggerHelper.updateEmailsTransitionToService((List<pse__Project_Task__c>) newList, null);
        new NSP_ProjectTasksTriggerServiceHelper().beforeInsertDirector((List<pse__Project_Task__c>)newList);
    }

    public void afterInsert( List<sObject> newList , Map<Id,sObject> newMap ) {
        NSP_ProjectTasksTriggerHelper  projectTaskTriggerHelperObject =  new NSP_ProjectTasksTriggerHelper();
        projectTaskTriggerHelperObject.afterInsertFilter((List<pse__Project_Task__c>) newList, (Map<Id, pse__Project_Task__c>) newMap);

        projectTaskTriggerHelperObject.updateTemplateUsedFieldOnProject((List<pse__Project_Task__c>) newList);
        projectTaskTriggerHelperObject.updateMilestoneAndProjectPercentCompleteOnInsert((List<pse__Project_Task__c>) newList);
        NSP_ProjectTasksTriggerServiceHelper oProjectTaskServiceHelper = new NSP_ProjectTasksTriggerServiceHelper();
        oProjectTaskServiceHelper.afterInsertFilter((List<pse__Project_Task__c>) newList, (Map<Id, pse__Project_Task__c>) newMap);
        //calling an event and updating project task start/end date of overriden by pse manage package
        projectTaskTriggerHelperObject.platformEventToSetStartDateAndTimePT((Map<Id, pse__Project_Task__c>) newMap);
    }

    public void beforeUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
        NSP_ProjectTasksTriggerHelper projectTaskTriggerHelperObject =  new NSP_ProjectTasksTriggerHelper();
        projectTaskTriggerHelperObject.updateStartedorCompleted((List<pse__Project_Task__c>)newMap.values(),(Map<Id,pse__Project_Task__c>)oldMap);
        projectTaskTriggerHelperObject.showErrorIfPercentageCompleteChangeToNot100(newMap.values(), (Map<Id, pse__Project_Task__c>) oldMap);
        projectTaskTriggerHelperObject.showErrorIfPreceedingTaskNotCompleted(newMap.values(), (Map<Id, pse__Project_Task__c>) oldMap);
        projectTaskTriggerHelperObject.sendEmailToAccountTeamMembersIfTaskIsLetterReceived(newMap.values(), (Map<Id, pse__Project_Task__c>) oldMap);
        // added as a part of STY-00711
        NSP_ProjectTasksTriggerHelper.updateEmailsTransitionToService((List<pse__Project_Task__c>) newMap.values(),(Map<Id, pse__Project_Task__c>) oldMap);
        //As a part of STY-02182
        NSP_ProjectTasksTriggerHelper.checkStatusComplete((Map<Id, pse__Project_Task__c>) newMap, (Map<Id, pse__Project_Task__c>) oldMap);

        projectTaskTriggerHelperObject.beforeUpdateDirector((List<pse__Project_Task__c>) newMap.values(), (Map<Id, pse__Project_Task__c>) oldMap);
    }

    public void afterUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
        //STY-01959 && STY-02192
        NSP_ProjtaskTriggerServiceHelperUpdate.updateSubtaskStatus((Map<Id,pse__Project_Task__c>)newMap, (Map<Id,pse__Project_Task__c>)oldMap);
        NSP_ProjtaskTriggerServiceHelperUpdate.afterUpdateProjectTask((List<pse__Project_Task__c>)newMap.values(), (Map<Id,pse__Project_Task__c>)oldMap);

        NSP_ProjectTasksTriggerHelper oProjectTaskHelper =  new NSP_ProjectTasksTriggerHelper();
        oProjectTaskHelper.afterUpdateTaskfilters((Map<Id,pse__Project_Task__c>)newMap,(Map<Id,pse__Project_Task__c>)oldMap);
        oProjectTaskHelper.updateMilestoneAndProjectPercentCompleteOnUpdate((List<pse__Project_Task__c>)newMap.values(), (Map<Id,pse__Project_Task__c>)oldMap);
        oProjectTaskHelper.calculateNumberOfCompletedAndCancelledProjectTask((List<pse__Project_Task__c>)newMap.values(), (Map<Id,pse__Project_Task__c>)oldMap);
        oProjectTaskHelper.cancelParentProjectIfProjectTaskIsCompletedonReinstatementRequestedTask((List<pse__Project_Task__c>)newMap.values(), (Map<Id,pse__Project_Task__c>)oldMap);
        NSP_ProjectTasksTriggerServiceHelper oProjectTaskServiceHelper = new NSP_ProjectTasksTriggerServiceHelper();
        oProjectTaskServiceHelper.afterUpdateProjectTask((List<pse__Project_Task__c>)newMap.values(), (Map<Id,pse__Project_Task__c>)oldMap);
        //As a part of STY-02182

        NSP_ProjectTasksTriggerServiceHelper.emailAlertProjectTaskCompleted((Map<Id,pse__Project_Task__c>)newMap, (Map<Id,pse__Project_Task__c>)oldMap);
    }

    public void afterDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
        // Added as part of DF-2180
        NSP_ProjectTasksTriggerHelper oProjectTaskHelper =  new NSP_ProjectTasksTriggerHelper();
        oProjectTaskHelper.afterDeleteProjectTask((List<pse__Project_Task__c>)oldList);
    }

    public void beforeDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
        NSP_ProjectTasksTriggerHelper oProjectTaskHelper =  new NSP_ProjectTasksTriggerHelper();
        // Added as part of STY-04554
        oProjectTaskHelper.handleBeforeDeleteOfProjTemp((List<pse__Project_Task__c>)oldList);
    }

}
//