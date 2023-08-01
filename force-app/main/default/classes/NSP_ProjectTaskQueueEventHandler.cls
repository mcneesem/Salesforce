public with sharing class NSP_ProjectTaskQueueEventHandler {
    public static void afterInsertHandler(List<NSP_ProjectTaskQueueEvent__e> lstProjectTaskEvents){
        Set<Id> setProjTaskAutoResourceIds = new set<Id>();
        Set<Id> setProjTaskOwnerIds = new set<Id>();

        Set<Id> setProjTaskOwnerIdsCreatePTA = new set<Id>();
        Set<Id> setProjIdsCreatePTA = new set<Id>();
        Set<Id> setProjTaskIdsCreatePTA = new set<Id>();

        Set<Id> setProjTaskAssignmentsIds = new set<Id>();
        Set<Id> setProjTaskIdsUpdateResourceOnInsert = new set<Id>();
        
        Set<Id> setprojectTaskIdsOwnerChanged = new set<Id>();
        Set<Id> setprojectTaskIdsOffsetDate = new set<Id>();

        Id currentUserId;

        for(NSP_ProjectTaskQueueEvent__e projectTaskQueue: lstProjectTaskEvents){
            currentUserId = projectTaskQueue.NSP_UserId__c;

            switch on projectTaskQueue.NSP_MethodName__c {

                when 'updateProjectTaskOwnerForAutoResource' {	
                    Map<String, Object> mapParams = (Map<String, Object>) JSON.deserializeUntyped(projectTaskQueue.NSP_Input_Parameters__c);
                    List<Object> lstProjectTaskIds = (List<Object>) mapParams?.get('projectTaskIds');
                    Set<Id> projectTaskIds = new Set<Id>();
                    for(Object obj: lstProjectTaskIds){
                        projectTaskIds.add((Id) obj);
                    }

                    if(projectTaskIds != null){
                        setProjTaskAutoResourceIds.addAll(projectTaskIds);
                    }
                }

                when 'updateProjectTaskOwner' {	
                    Map<String, Object> mapParams = (Map<String, Object>) JSON.deserializeUntyped(projectTaskQueue.NSP_Input_Parameters__c);
                    List<Object> lstProjectTaskIds = (List<Object>) mapParams?.get('projectTaskIds');
                    Set<Id> projectTaskIds = new Set<Id>();
                    for(Object obj: lstProjectTaskIds){
                        projectTaskIds.add((Id) obj);
                    }

                    if(projectTaskIds != null){
                        setProjTaskOwnerIds.addAll(projectTaskIds);
                    }
                }

                when 'createPTAOnProject' {
                    Map<String, Object> mapParams = (Map<String, Object>) JSON.deserializeUntyped(projectTaskQueue.NSP_Input_Parameters__c);

                    List<Object> lstPTaskOwnerIdSet = (List<Object>) mapParams?.get('pTaskOwnerIdSet');
                    Set<Id> pTaskOwnerIdSet = new Set<Id>();
                    for(Object obj: lstpTaskOwnerIdSet){
                        pTaskOwnerIdSet.add((Id) obj);
                    }

                    List<Object> lstSetProjectId = (List<Object>) mapParams?.get('setProjectId');
                    Set<Id> setProjectId = new Set<Id>();
                    for(Object obj: lstSetProjectId){
                        setProjectId.add((Id) obj);
                    }

                    List<Object> lstSetProjectTaskId = (List<Object>) mapParams?.get('setProjectTaskId');
                    Set<Id> setProjectTaskId = new Set<Id>();
                    for(Object obj: lstSetProjectTaskId){
                        setProjectTaskId.add((Id) obj);
                    }

                    if(pTaskOwnerIdSet != null && setProjectId != null && setProjectTaskId != null){
                        setProjTaskOwnerIdsCreatePTA.addAll(pTaskOwnerIdSet);
                        setProjIdsCreatePTA.addAll(setProjectId);
                        setProjTaskIdsCreatePTA.addAll(setProjectTaskId);
                    }
                }

                when 'updateResourceOnInsert' {	
                    Map<String, Object> mapParams = (Map<String, Object>) JSON.deserializeUntyped(projectTaskQueue.NSP_Input_Parameters__c);

                    List<Object> lstProjectTaskId = (List<Object>) mapParams?.get('projectTaskId');
                    Set<Id> projectTaskId = new Set<Id>();
                    for(Object obj: lstProjectTaskId){
                        projectTaskId.add((Id) obj);
                    }

                    List<Object> lstPTAIdSet = (List<Object>) mapParams?.get('PTAIdSet');
                    Set<Id> ptaIdSet = new Set<Id>();
                    for(Object obj: lstPTAIdSet){
                        ptaIdSet.add((Id) obj);
                    }

                    if(projectTaskId != null && ptaIdSet != null){
                        setProjTaskAssignmentsIds.addAll(ptaIdSet);
                        setProjTaskIdsUpdateResourceOnInsert.addAll(projectTaskId);
                    }
                }

                when 'createPTAIfOwnerIsChanged' {	
                    Map<String, Object> mapParams = (Map<String, Object>) JSON.deserializeUntyped(projectTaskQueue.NSP_Input_Parameters__c);
                    List<Object> lstProjectTaskIdsChangedOwner = (List<Object>) mapParams?.get('projectTaskidsChangedOwner');
                    Set<Id> projectTaskIdsOwnerChanged = new Set<Id>();
                    for(Object obj: lstProjectTaskIdsChangedOwner){
                        projectTaskIdsOwnerChanged.add((Id) obj);
                    }

                    if(projectTaskIdsOwnerChanged != null){
                        setprojectTaskIdsOwnerChanged.addAll(projectTaskIdsOwnerChanged);
                    }
                }
                
                when 'setStartDateAndEndDateOnProjectTaskQTP' {	
                    Map<String, Object> mapParams = (Map<String, Object>) JSON.deserializeUntyped(projectTaskQueue.NSP_Input_Parameters__c);
                    List<Object> lstProjectTaskIdsoffsetDate = (List<Object>) mapParams?.get('projectTaskIdsOffsetDate');
                    Set<Id> projectTaskIdsOffsetDate = new Set<Id>();
                    for(Object obj: lstProjectTaskIdsoffsetDate){
                        projectTaskIdsOffsetDate.add((Id) obj);
                    }
                    
                    if(projectTaskIdsOffsetDate != null){
                        setprojectTaskIdsOffsetDate.addAll(projectTaskIdsOffsetDate);
                    }
                }
            }
        }

        if(setProjTaskAutoResourceIds != null && !setProjTaskAutoResourceIds.isEmpty()){
            NSP_ProjectTasksTriggerServiceHelper.updateProjectTaskOwnerForAutoResource(setProjTaskAutoResourceIds, currentUserId);
        }

        if(setProjTaskOwnerIds != null && !setProjTaskOwnerIds.isEmpty()){
            NSP_ProjectTasksTriggerServiceHelper.updateProjectTaskOwner(setProjTaskOwnerIds, currentUserId);
        }

        if(setProjTaskOwnerIdsCreatePTA != null && !setProjTaskOwnerIdsCreatePTA.isEmpty() &&
            setProjIdsCreatePTA != null && !setProjIdsCreatePTA.isEmpty() &&
            setProjTaskIdsCreatePTA != null && !setProjTaskIdsCreatePTA.isEmpty()){
                NSP_ProjectTasksTriggerServiceHelper.createPTAOnProject(setProjTaskOwnerIdsCreatePTA, setProjIdsCreatePTA, setProjTaskIdsCreatePTA);
        }

        if(setProjTaskIdsUpdateResourceOnInsert != null && !setProjTaskIdsUpdateResourceOnInsert.isEmpty() &&
            setProjTaskAssignmentsIds != null && !setProjTaskAssignmentsIds.isEmpty()){
                NSP_ProjectTaskAssignmentTriggerHelper.updateResourceOnInsert(setProjTaskIdsUpdateResourceOnInsert, setProjTaskAssignmentsIds, currentUserId);
        }

        if(setprojectTaskIdsOwnerChanged != null && !setprojectTaskIdsOwnerChanged.isEmpty()){
            NSP_ProjectTasksTriggerHelper.createPTAIfOwnerIsChanged(setprojectTaskIdsOwnerChanged);
        }
        
        if(setprojectTaskIdsOffsetDate != null && !setprojectTaskIdsOffsetDate.isEmpty()){
            NSP_ProjectTasksTriggerHelper.setStartDateAndEndDateOnProjectTaskQTP(setprojectTaskIdsOffsetDate);
        }
    }
}