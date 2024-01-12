public with sharing class NSP_ProjectAssignmentTriggerHelper {
    public final static String ASSIGNMENTNOTIFICATIONTEMPLATE = 'NSP_Project_Resource_Assignment';
    public final String RETRECORDTYPE = 'RET_Deconversion_2020_Form';
    
    /**
    * Update Role on Assignment From Contact Resource Role
    * @param lProjectAssignments List of New Project Assignments
    * @param mProjectAssignments Map of New project Assignments.
    * @return void
    */
    public void beforeInsertAssignmentFilters(List<pse__Assignment__c> lProjectAssignments){
        Set<Id> sContactIds = new Set<Id>();
        List<pse__Assignment__c> lAssignments = new List<pse__Assignment__c>();
        for(pse__Assignment__c oProjectAssignment : lProjectAssignments){
            if(oProjectAssignment.pse__Resource__c != null){
                sContactIds.add(oProjectAssignment.pse__Resource__c);
                lAssignments.add(oProjectAssignment);
            }
        }
        if(sContactIds.size() > 0){
            updateAssignmentRole(sContactIds,lAssignments);
        }
    }

    public void beforeUpdateAssignmentFilters(Map<Id, pse__Assignment__c> mNewProjectAssignments,Map<Id, pse__Assignment__c> mOldProjectAssignments){
        Set<Id> sContactsIds = new Set<Id>();
        List<pse__Assignment__c> lAssignments = new List<pse__Assignment__c>();
        for(pse__Assignment__c oAssignment : mNewProjectAssignments.values()){
            if(oAssignment.pse__Resource__c != null && oAssignment.pse__Resource__c != mOldProjectAssignments.get(oAssignment.Id).pse__Resource__c ){
                sContactsIds.add(oAssignment.pse__Resource__c);
                lAssignments.add(oAssignment);
            }
        }
        if(sContactsIds.size() > 0){
            updateAssignmentRole(sContactsIds,lAssignments);
        }
    }

    public void updateAssignmentRole(Set<Id> sContactIds,List<pse__Assignment__c> lProjectAssignments){
        Map<Id,Contact> mContacts = new Map<Id,Contact>([SELECT Id,pse__Resource_Role__c FROM Contact WHERE ID in: sContactIds AND pse__Resource_Role__c != null]);
        if(mContacts.keySet().size() == 0){
            return;
        }
        for(pse__Assignment__c oProjectAssignment : lProjectAssignments){
            if(oProjectAssignment.pse__Resource__c != null){
                oProjectAssignment.pse__Role__c = mContacts.get(oProjectAssignment.pse__Resource__c)?.pse__Resource_Role__c;
            }
        }
    }
    /**
    * Send Notification to Resource Assigned to Project
    * @param lProjectAssignments List of New Project Assignments
    * @param mProjectAssignments Map of New project Assignments.
    * @return void
    */
    public void afterInsertAssignmentFilters(List<pse__Assignment__c> lProjectAssignments, Map<Id, pse__Assignment__c> mProjectAssignments){
        Set<Id> sContactIds = new Set<Id>();
        Map<Id,Id> mAssignmentToContact = new Map<Id,Id>();
        Map<Id,pse__Assignment__c> mProjectIdtoAssignments = new Map<Id,pse__Assignment__c>();
        for(pse__Assignment__c oProjectAssignment : lProjectAssignments){
            if(String.isNotBlank(oProjectAssignment.pse__Role__c)){
                mProjectIdtoAssignments.put(oProjectAssignment.pse__Project__c,oProjectAssignment);
            }
            if(oProjectAssignment.pse__Resource__c != null){
                sContactIds.add(oProjectAssignment.pse__Resource__c);
                mAssignmentToContact.put(oProjectAssignment.Id,oProjectAssignment.pse__Resource__c);
            }
        }
        if(!System.isFuture() && !System.isBatch()){
            emailNotifications(sContactIds,mAssignmentToContact);
        }
        if(mProjectIdtoAssignments.keySet().size() > 0){
           createProjectTaskAssignmentForRETProjects(mProjectIdtoAssignments);
        }
    }
    
    /**
    * Create PTA Record for RET Projects under Project Task Role is same
    * @param mProjectIdtoAssignments Map of Project Id to Project Assignments.
    * @return void
    */
    public Set<Id> createProjectTaskAssignmentForRETProjects(Map<Id,pse__Assignment__c> mProjectIdtoAssignments){
        Id iRETRecordTypeId = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get(RETRECORDTYPE)?.getRecordTypeId();
        Map<Id,pse__Proj__c> mRETProjects = new Map<Id,pse__Proj__c>([SELECT Id FROM pse__Proj__c WHERE Id in: mProjectIdtoAssignments.keySet() AND RecordtypeId =: iRETRecordTypeId]);
        mProjectIdtoAssignments.keySet().retainAll(mRETProjects.keySet());
        Map<Id,pse__Project_Task__c> mProjectTasks = new Map<Id,pse__Project_Task__c>([SELECT Id,Responsible_Party__c,pse__Project__c from pse__Project_Task__c WHERE pse__Project__c in: mProjectIdtoAssignments.keySet()]);
        Map<Id,Map<String,List<pse__Project_Task__c>>> mProjectIdToProjectTasks = new Map<Id,Map<String,List<pse__Project_Task__c>>>();
        for(pse__Project_Task__c oProjectTask : mProjectTasks.values()){
            if(String.isBlank(oProjectTask.Responsible_Party__c)){
                continue;
            }
            if(mProjectIdToProjectTasks.get(oProjectTask.pse__Project__c) != null){
                if(mProjectIdToProjectTasks.get(oProjectTask.pse__Project__c).get(oProjectTask.Responsible_Party__c) != null){
                    mProjectIdToProjectTasks.get(oProjectTask.pse__Project__c).get(oProjectTask.Responsible_Party__c).add(oProjectTask);
                }else{
                    mProjectIdToProjectTasks.get(oProjectTask.pse__Project__c).put(oProjectTask.Responsible_Party__c, new List<pse__Project_Task__c>{oProjectTask});
                }
            }else{
                mProjectIdToProjectTasks.put(oProjectTask.pse__Project__c, new Map<String,List<pse__Project_Task__c>>{ oProjectTask.Responsible_Party__c => new List<pse__Project_Task__c> {oProjectTask}});
            }
        }

        List<pse__Project_Task_Assignment__c> lProjectAssignments = new List<pse__Project_Task_Assignment__c>();
        for(pse__Assignment__c oAssignment: mProjectIdtoAssignments.values()){
            Map<String,List<pse__Project_Task__c>> mPartyToProjectTasks = mProjectIdToProjectTasks.get(oAssignment.pse__Project__c);
            if(oAssignment.pse__Role__c != null && null != mPartyToProjectTasks && !mPartyToProjectTasks.isEmpty() && mPartyToProjectTasks.get(oAssignment.pse__Role__c) != null){
                for(pse__Project_Task__c oProjectTask : mPartyToProjectTasks.get(oAssignment.pse__Role__c)){
                    lProjectAssignments.add(new pse__Project_Task_Assignment__c(pse__Resource_Role__c = oAssignment.pse__Role__c,pse__Project_Task__c = oProjectTask.Id,
                    pse__Resource__c = oAssignment.pse__Resource__c,NSP_Priority__c  = 1));
                }
            }
        }
        if(lProjectAssignments.size() > 0){
            insert lProjectAssignments;
        }
        return mProjectIdtoAssignments.keySet();
    }

    /**
    * Filter Project Assignment Records to then pass to individual functionality methods
    * @param lProjectAssignments List of New Project Assignments
    * @param mProjectAssignments Map of New project Assignments.
    * @return void
    */
    public void afterUpdateAssignmentfilters(Map<Id, pse__Assignment__c> mNewProjectAssignments,Map<Id, pse__Assignment__c> mOldProjectAssignments){
        Set<Id> sContactIds = new Set<Id>();
        Map<Id,Id> mAssignmentToContact = new Map<Id,Id>();
        for(pse__Assignment__c oProjectAssignment : mNewProjectAssignments.values()){
            // FILTER RESOURCE ASSIGNMENT CHANGED RESOURCE
            if(oProjectAssignment.pse__Resource__c != null && oProjectAssignment.pse__Resource__c != mOldProjectAssignments.get(oProjectAssignment.Id).pse__Resource__c){
                sContactIds.add(oProjectAssignment.pse__Resource__c);
                mAssignmentToContact.put(oProjectAssignment.Id,oProjectAssignment.pse__Resource__c);
            }
        }
        if(!System.isFuture() && !System.isBatch()){
            emailNotifications(sContactIds,mAssignmentToContact);
        }
    }
    
    @future
    public static void emailNotifications(Set<Id> sContactIds, Map<Id,Id> mAssignmentToContact){
        if(sContactIds.size() == 0){
            return;
        }
        Map<Id,Contact> mContacts = new Map<Id,Contact>([SELECT Id,pse__Salesforce_User__c FROM Contact WHERE ID in: sContactIds AND pse__Salesforce_User__c != null AND pse__Salesforce_User__c !=: UserInfo.getUserId()]);
        if(mContacts.keySet().size() == 0){
            return;
        }
        Map<Id,Id> mAssignmentToUserIds = new Map<Id,Id>();
        for(Id iProjectAssign : mAssignmentToContact.keySet()){
            Contact oContact = mContacts.get(mAssignmentToContact.get(iProjectAssign));
            if(oContact != null){
                mAssignmentToUserIds.put(iProjectAssign, oContact.pse__Salesforce_User__c);
            }
        }
        NSP_EmailService.sendEmail(mAssignmentToUserIds, ASSIGNMENTNOTIFICATIONTEMPLATE);
    }
}