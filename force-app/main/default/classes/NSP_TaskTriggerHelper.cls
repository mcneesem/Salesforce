public with sharing class NSP_TaskTriggerHelper {
    // test w/ NSP_TaskTriggerHelperTest, LeadLastActivityDateHelperTest, NSP_CreateReferralLeadTest (85%)
    // test w/ NSP_TaskTriggerHelperTest (84%)
    // test w/ LeadLastActivityDateHelperTest (35%)
    // test w/ NSP_CreateReferralLeadTest (34%)

    public static Id referralRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Task' , 'Referral_Task' );
    public static Id peoTaskRecordType = NSP_GenericRecordType.getRecordTypeId( 'Task' , 'PEO_Service_Task' );
    private static Boolean Is_Enabled_WO_WS_Stage_Entry = OpportunityStageSettings__c.getInstance(UserInfo.getUserId()).Is_Enabled_WO_WS_Stage_Entry__c;
    private static final String EXPENSE_MANAGEMENT = 'Expense_Management';
    private static final String EMPLOYMENT_SCREENING = 'NSP_Employment_Screening';
    //Queue DeveloperNames
    public static final String I9_ASSIST_EVERIFY = 'I_9_Assist_E_Verify';
    //Products of Interest Tasks
    public static final String PI_I9_ASSIST_EVERIFY = 'I-9 Assist & E-Verify';
    /**
    * Iterates throught the list of new tasks/ activity and passes the required attributes to other methods.
    * @param newList List of New Task
    * @return void
    *
    */
    public void beforeInsertDirector( List<Task> newList ) {
        List<Task> lstRefferalTask = new List<Task>();
        Set<Id> accountIds = new Set<Id>();
        List<User> userdetails = [SELECT id, NSP_Sales_Office__c from User WHERE id = : UserInfo.getUserId()];
        for(Task taskObj : newList){
            if(String.isBlank(taskObj.NSP_Sales_Office__c) && String.isBlank(taskObj.NSP_OneForce_External_ID__c)){
                taskObj.NSP_Sales_Office__c = userdetails[0].NSP_Sales_Office__c;
            }
            // Added as Part of STY-00624
            if(isReferralTask(taskObj, null) && pIMappingQueue.containsKey(taskObj.Upsell_Product_of_Interest__c)){
                lstRefferalTask.add(taskObj);
            }else if(isReferralTask(taskObj, null) && taskObj.Upsell_Product_of_Interest__c == NSP_ServiceConstants.PAYROLL_HR_MANAGEMENT_WA || taskObj.Upsell_Product_of_Interest__c == NSP_ServiceConstants.FULL_SERVICE_HR_WO){
                accountIds.add(taskObj.AccountId);
            }
            taskObj.NSP_Last_Assigned_Owner__c = taskObj.OwnerId; // Added as part of STY-01774

            //added as a part of STY-03227
            if(taskObj.recordTypeId == NSP_TaskTriggerHelper.peoTaskRecordType){
                updatePEOTaskSubject(taskObj);
            }
        }
        if(!accountIds.isEmpty() || !lstRefferalTask.isEmpty()){
            assignReferralTaskOwner(lstRefferalTask,accountIds);
        }
        updateActivitySales(newList,null);
        populateWhatAndWhoNames(newList);
    }

    public void afterInsertDirector( List<Task> newList , Map<Id,Task> taskNewMap ) {
        List<Task> updateActivityList = new List<Task>();
        List<Task> refTaskList = new List<Task>();

        for(Task taskObj : newList){
            updateActivityList.add(taskObj);
            //Geeting Referral Record for which NSP_Is_Referral_Task__c is TRUE (UPSELL button Functionality)
            if(taskObj.NSP_Is_Referral_Task__c){
                refTaskList.add(taskObj);
            }
        }

        if ( !updateActivityList.isEmpty() ) {
            this.updateActivityDate( updateActivityList , null );
        }
        // Removing the Permission set for those user when they create  a referral Record with Upsell Button
        if(!refTaskList.isEmpty()){
           removePermissionSet();
        }
        checkOpportunityStageCriteria(newList);
    }

    // Iterates throught the task/activity map and identifies the records that needs to worked based on various criterias.
    // @param taskNewMap of New tasks.
    // @param taskOldMap of Old taska.
    // @return void
    public void beforeUpdateDirector( Map<Id,Task> taskNewMap , Map<Id,Task> taskOldMap ) {
        List<User> userdetails = [SELECT id, NSP_Sales_Office__c from User WHERE id = : UserInfo.getUserId()];
        List<Task> lstRefferalTask = new List<Task>();
        Set<Id> accountIds = new Set<Id>();
        List<Task> orientationMeetingRequestTaskList = new List<Task>();
        Id orientationMeetingReqRecTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.Task,NSP_ServiceConstants.ORIENTATION_MEETING_REQUEST);
        for(Id taskId : taskNewMap.keySet()){
            if(String.isBlank(taskNewMap.get(taskId).NSP_Sales_Office__c) && String.isBlank(taskNewMap.get(taskId).NSP_OneForce_External_ID__c)){
                taskNewMap.get(taskId).NSP_Sales_Office__c = userdetails[0].NSP_Sales_Office__c;
            }
            // Added as Part of STY-00624
            Task oTask = taskNewMap.get(taskId);
            Task oldTask = taskOldMap.get(oTask.Id);
            oTask.NSP_Last_Assigned_Owner__c = oTask.OwnerId; //Added as part of STY-01774
            if(isReferralTask(oTask, oldTask) && pIMappingQueue.containsKey(oTask.Upsell_Product_of_Interest__c)){
                lstRefferalTask.add(oTask);
            }else if(isReferralTask(oTask, oldTask) &&  oTask.Upsell_Product_of_Interest__c == NSP_ServiceConstants.PAYROLL_HR_MANAGEMENT_WA || oTask.Upsell_Product_of_Interest__c == NSP_ServiceConstants.FULL_SERVICE_HR_WO){
                accountIds.add(oTask.AccountId);
            }

            //added as a part of STY-03227
            if(oTask.recordTypeId == NSP_TaskTriggerHelper.peoTaskRecordType){
                updatePEOTaskSubject(oTask);
            }

            //Added as part of DF-04782
            if(oTask.RecordTypeId == orientationMeetingReqRecTypeId){
                orientationMeetingRequestTaskList.add(oTask);
            }
        }
        this.handleAssignReferralTaskOwner( lstRefferalTask , accountIds );
        this.updateActivitySales( taskNewMap.values() , taskOldMap );
        this.tasksFieldsToUpdate( taskOldMap , taskNewMap.values() );
        this.handleShowMessageWhenTaskIsUpdated( orientationMeetingRequestTaskList );
    }

    //
    // Iterates throught the list of new Tasks and passes the required attributes to other methods.
    // @param taskNewMap Map of New Task.
    // @param taskOldMap Map of Old Task.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,Task> taskNewMap , Map<Id,Task> taskOldMap ) {
        this.updateActivityDate( taskNewMap.values() , taskOldMap );
        checkOpportunityStageCriteria( taskNewMap.values() );
    }

    //
    // Method Name : updateActivityDate
    // Description : Method to update last activity date on all related leads with same DUNS.
    // Date : 31/03/2021
    // @param newList List of New Task.
    // @param oldMap Map of Old Task.
    // @return void
    //
    private void updateActivityDate( List<Task> newList , Map<Id,Task> oldMap ) {
        try {
            Set<Id> whoIds = new Set<Id>();
            for ( Task record : newList ) {
                Task oldRecord = null;
                if ( oldMap != null ) {
                    oldRecord = oldMap.get( record.Id );
                }
                if ( ( ( oldRecord == null ) || ( record.Status != oldRecord.Status ) )
                    && ( record.Status == NSP_SalesConstants.COMPLETED )
                    && ( record.WhoId != null )
                    )
                {
                    whoIds.add( record.WhoId );
                }
            }
            LeadLastActivityDateHelper.updateLeadLastActivityDate( whoIds );
        } catch ( Exception e ) {
            NSP_TaskTriggerHelper.handleException( e , 'updateActivityDate' );
        }
    }

     /**
* Method Name : updateActivitySales
* Description : Method to update sales region, sales devison and sales office.
* Date : 08/09/2022
* @param newList List of New Task.
* @param OldTaskMap Map of Old Task.
* @return void
*/

public void updateActivitySales(List<Task> newList,Map<Id,Task> OldTaskMap){

    set<Id> ownerIdSet = new set<Id>();
    for(Task newTask : newList)
    {
        Task oldTask = OldTaskMap != null ? OldTaskMap.get(newTask.Id):null;

        if(Trigger.isInsert || newTask.OwnerId != oldTask.OwnerId )
        {
            ownerIdSet.add(newTask.ownerId);
        }
    }

    if(ownerIdSet.Size() > 0)
    {
        Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user WHERE Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
        for(Task newTask : newList)
        {
            Task oldTask = OldTaskMap != null ? OldTaskMap.get(newTask.Id):null;

            if(Trigger.isInsert || newTask.OwnerId != oldTask.OwnerId )
            {
                if(userIdMap.containsKey(newTask.ownerId))
                {
                    user eachUser = userIdMap.get(newTask.OwnerId);
                    newTask.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                    newTask.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newTask.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                }
            }
        }
    }
  }

    //
    // Iterates through task and sum up time spent on case.
    // @param newList list of task.
    // @return void
    //
    public void sumUpTaskTimeSpent( Map<Id,Task> taskNewMap , Map<Id,Task> taskOldMap ) {
        try {
            //Iterating over the opportunity new map
            Set<Id> caseIdSet = new Set<Id>();
            List<Case> caseListToUpdate = new List<Case>();
            for ( Task eachTask : taskNewMap.values() ) {
                // if the parent opty is closed lost then adding it to the list
                if ( ( eachTask.NSP_Minutes_spent_on_task__c != null )
                    && ( eachTask.WhatId != null )
                    && ( eachTask.WhatId.getSObjectType() == Case.getSObjectType() )
                    )
                {
                    caseIdSet.add( eachTask.WhatId );
                }
            }
            if(!caseIdSet.isEmpty()){
                for ( AggregateResult aggr : [
                            SELECT SUM(NSP_Minutes_spent_on_task__c)timespent , WhatId
                            FROM Task
                            WHERE ( WhatId IN :caseIdSet )
                            GROUP BY WhatId
                        ]
                    )
                {
                    Case caseObj = new Case();
                    caseObj.id = (Id)aggr.get( 'WhatId' );
                    caseObj.NSP_Actual_Minutes_Spent_To_Resolve_Case__c = (Decimal)aggr.get( 'timespent' );
                    caseListToUpdate.add( caseObj );
                }
                List<Database.SaveResult> results = Database.update( caseListToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_TaskTriggerHelper.class.getName() ,
                    'sumUpTaskTimeSpent' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_TaskTriggerHelper.handleException( e , 'sumUpTaskTimeSpent' );
        }
    }

    public void preventInsertOnClosedCase(List<Task> newList){
        Map<Id,List<Task>> caseTaskMap = new Map<Id,List<Task>> ();
            for(Task eachTask: NewList){
            if( eachTask.WhatId != null && 'Case'== eachTask.WhatId.getSObjectType().getDescribe().getName()){
                if(!caseTaskMap.containsKey(eachTask.WhatId)){
                    caseTaskMap.put(eachTask.WhatId, new List<Task>());
                }caseTaskMap.get(eachTask.WhatId).add(eachTask);
            }
        }

        for(Case eachCase :[SELECT Id, Status FROM Case WHERE Id IN :caseTaskMap.keySet() AND Status = 'Closed']){
            for( Task eachTask :caseTaskMap.get(eachCase.Id)){
                //Display error on When user Create a Task on Closed Cased.
                // Added if condition as part of DF-02541
                if(!eachTask.subject.StartsWith(NSP_ServiceConstants.TASK_SUBJECT_STARTS_WITH_EMAIL)){
                    eachTask.addError(System.Label.NSP_PreventTaskCreationOnClosedCase);
                }
            }
        }
    }

    // helper method to defeat sonar cognitive complexity...
    private void handleAssignReferralTaskOwner( List<Task> records , Set<Id> accountIds ) {
        if ( ( ( accountIds != null ) && !accountIds.isEmpty() )
            || ( ( records != null ) && !records.isEmpty() )
            )
        {
            assignReferralTaskOwner( records , accountIds );
        }
    }

    //
    // @MethodName: assignReferralTaskOwner
    // @Description: Assign Referral Task Owner based on Product of Interest Added as Part of STY-00624
    // @param : List<Task> lstRefferalTask
    // @param : Set<Id> accountIds
    // @return void
    //
    public void assignReferralTaskOwner(List<Task> lstRefferalTask, Set<Id> accountIds){

        Map<Id,Account> mapAccounts = new Map<Id,Account>();
        Map<String,String> mapQueueMapping = new Map<String,String>();

        if(!accountIds.isEmpty()){
            mapAccounts = new Map<Id,Account>([SELECT Id,OwnerId FROM Account WHERE Id IN: accountIds]);
        }else{
            mapQueueMapping = getQueueMapping();
        }

        for(Task oTask: lstRefferalTask){
            if(pIMappingQueue.containsKey(oTask.Upsell_Product_of_Interest__c)){
                oTask.OwnerId = mapQueueMapping?.get(pIMappingQueue?.get(oTask.Upsell_Product_of_Interest__c));
            }else if(mapAccounts.containsKey(oTask.AccountId)){
                oTask.OwnerId = mapAccounts.get(oTask.AccountId)?.OwnerId;
            }
        }
    }

    private void checkOpportunityStageCriteria( List<Task> newList ) {
        List<Id> updateOpportunityIds = new List<Id>();
        if ( NSP_TaskTriggerHelper.Is_Enabled_WO_WS_Stage_Entry ) {
            for ( Task task : newList ) {
                if ( ( task != null )
                    && ( task.WhatId != null )
                    && ( task.Subject != null )
                    && ( task.Status == NSP_SalesConstants.COMPLETED )
                    && ( task.WhatId.getSObjectType() == Opportunity.getSObjectType() )
                    && (
                        task.Subject.equalsIgnoreCase( System.Label.Business_Profile_Started )
                        || task.Subject.equalsIgnoreCase( System.Label.Bid_Generated_in_AIMS )
                        || task.Subject.equalsIgnoreCase( System.Label.Bid_Sent_to_Pricing_and_Review )
                        )
                    )
                {
                    updateOpportunityIds.add( task.WhatId );
                }
            }
            AutomateOpportunityStage.automateOpportunityStageAsync( updateOpportunityIds );
        }
    }

    //
    // @MethodName: isReferralTask
    // @Description: Checking if the Task is Referral Task to update Task Owner
    // @param : Task newTask
    // @param : Task oldTask
    // @return Boolean
    //
    private Boolean isReferralTask( Task newTask , Task oldTask ) {
        return (
            ( newTask.RecordTypeId == NSP_TaskTriggerHelper.referralRecordTypeId )
            && ( newTask.Upsell_Product_of_Interest__c != null )
            && (
                ( oldTask == null )
                || ( newTask.Upsell_Product_of_Interest__c != oldTask.Upsell_Product_of_Interest__c )
            )
        );
    }

    //
    // @MethodName: getQueueMapping
    // @Description: find the Queue Based on Product Of Interest on Task
    // @return Map<String,String>
    //
    private static Map<String,String> getQueueMapping() {
        Set<String> lstReferralQueues = new Set<String>{
            NSP_ServiceConstants.INTEGRA_QUEUE ,
            NSP_TaskTriggerHelper.EXPENSE_MANAGEMENT ,
            NSP_ServiceConstants.SERVICE_REFERRAL ,
            NSP_ServiceConstants.RECRUITING_SERVICES ,
            NSP_ServiceConstants.INSURANCE_SERVICES ,
            NSP_ServiceConstants.HR_CONSULTING ,
            NSP_ServiceConstants.RETIREMENT_SERVICES ,
            NSP_ServiceConstants.CONTINGENT_WORKFORCE ,
            NSP_ServiceConstants.CONTRACTOR_MANAGEMENT ,
            NSP_ServiceConstants.HRCORE_ONBOARDING_AMENDMENT ,
            NSP_TaskTriggerHelper.EMPLOYMENT_SCREENING ,
            NSP_TaskTriggerHelper.I9_ASSIST_EVERIFY
        };
        Map<String,String> mapQueueDeveloperNameQueueId = new Map<String,String>();
        for ( Group ogroup : [
                    SELECT Id , DeveloperName
                    FROM GROUP
                    WHERE (
                        ( DeveloperName IN :lstReferralQueues )
                        AND ( Type = 'Queue' )
                    )
                    WITH SECURITY_ENFORCED
                ]
            )
        {
            mapQueueDeveloperNameQueueId.put(ogroup.DeveloperName,ogroup.Id);
        }
        return mapQueueDeveloperNameQueueId;
    }

    //
    // @MethodName: pIMappingQueue
    // @Description: Mapping of Product of Interest on Task and and Queue Developer Name
    // @return Map<String,String>
    //
    private static Map<String,String> pIMappingQueue{
        get {
            return new Map<String,String>{
                NSP_ServiceConstants.INTEGRA => NSP_ServiceConstants.INTEGRA ,
                NSP_ServiceConstants.INSPERITY_INTEGRA => NSP_ServiceConstants.INTEGRA_QUEUE ,
                NSP_ServiceConstants.EXPENSE_MANAGEMENT => NSP_TaskTriggerHelper.EXPENSE_MANAGEMENT ,
                NSP_ServiceConstants.HR_CONSULTING_SERVICES => NSP_ServiceConstants.HR_CONSULTING ,
                NSP_ServiceConstants.PI_INSURANCE_SERVICES => NSP_ServiceConstants.INSURANCE_SERVICES ,
                NSP_ServiceConstants.PI_RECRUITING_SERVICES => NSP_ServiceConstants.RECRUITING_SERVICES ,
                NSP_ServiceConstants.PI_RETIREMENT_SERVICES => NSP_ServiceConstants.RETIREMENT_SERVICES ,
                NSP_ServiceConstants.APPLICANT_TRACKING => NSP_ServiceConstants.SERVICE_REFERRAL ,
                NSP_ServiceConstants.ORGANIZATIONAL_PLANNING => NSP_ServiceConstants.SERVICE_REFERRAL ,
                NSP_ServiceConstants.PERFORMANCE_MANAGEMENT => NSP_ServiceConstants.SERVICE_REFERRAL ,
                NSP_ServiceConstants.TIME_AND_ATTENDANCE => NSP_ServiceConstants.SERVICE_REFERRAL ,
                NSP_ServiceConstants.PI_CONTINGENT_WORKFORCE => NSP_ServiceConstants.CONTINGENT_WORKFORCE ,
                NSP_TaskTriggerHelper.PI_I9_ASSIST_EVERIFY => NSP_ServiceConstants.I9_ASSIST_EVERIFY ,
                NSP_ServiceConstants.PI_CONTRACTOR_MANAGEMENT => NSP_ServiceConstants.CONTRACTOR_MANAGEMENT ,
                NSP_ServiceConstants.PI_HRCORE_ONBOARDING_AMENDMENT => NSP_ServiceConstants.HRCORE_ONBOARDING_AMENDMENT ,
                NSP_ServiceConstants.EMPLOYMENT_SCREENING => NSP_TaskTriggerHelper.EMPLOYMENT_SCREENING,
                    'Insurance Services (Health & Wellness)' =>  NSP_ServiceConstants.INSURANCE_SERVICES ,
                    'Insurance Services (Property & Casualty)' =>  NSP_ServiceConstants.INSURANCE_SERVICES ,
                    'Insurance Services (Revolution)' => NSP_ServiceConstants.INSURANCE_SERVICES
            };
        }
    }

    //
    // @MethodName: updatePEOTaskSubject
    // @Params Task task
    //
    public static void updatePEOTaskSubject( Task record ) {
        if ( ( record != null ) && String.isNotBlank( record.Subject ) ) {
            record.NSP_What_needs_to_get_done__c = record.Subject;
        }
    }

    /**
    * Iterates throught the list of old Tasks and passes the required attributes to other methods.
    * @param taskList List of old Task.
    * @return void
    *
    */
    public static void beforeDeleteDirector(List<Task> taskList){
        try{
            Map<Id,User> userdetails = new Map<Id,User>([SELECT Id, Profile.Name FROM User WHERE Id = : UserInfo.getUserId()]);
            List<String> serviceUserProf = new List<String>(label.NSP_ServiceProfiles.split(','));
            for(Task task :taskList){
                if(serviceUserProf.contains(userdetails.get(UserInfo.getUserId()).Profile.Name) &&
                   UserInfo.getUserId() != task.createdById  ){
                       task.addError(label.NSP_CRMTaskError);
                   }
            }
        } catch ( Exception e ) {
            NSP_TaskTriggerHelper.handleException( e , 'beforeDeleteDirector' );
        }
    }

     /**
* @MethodName: removePermissionSet
* @Description: Remove Task-Referral Task Permission Set when cancel a referral record while creating through UPSELL Button
* DF-02737
* @return void
*/
    @future
    public static void removePermissionSet(){
        List<PermissionSetAssignment> permAsign = [SELECT Id, PermissionSetId, AssigneeId, IsActive
                                                    FROM PermissionSetAssignment WHERE PermissionSet.Name = 'NSP_Task_Referral_Task'
                                                    AND AssigneeId =: Userinfo.getUserId() AND IsActive = true];
        if(!permAsign.isempty()){
            delete permAsign;
        }
    }

    //
    // Method Name : populateWhatAndWhoNames
    // Description : Method to update NSP_What_Name__c and/or NSP_Who_Name__c on Task
    // Date : 13/02/2023
    // @param newTaskList List of new tasks
    // @return void
    //
    public void populateWhatAndWhoNames( List<Task> newTaskList ) {
        try {
            List<String> fieldApiNamesList = new List<String>{ 'WhatId', 'WhoId' };
            Map<String, Set<String>> targetRecordIdsByObjectApiNameMap = new Map<String, Set<String>>();

            //Code to populate What and Who records by their Object Type
            for(Task taskToBeUpdateRecord : newTaskList) {
                for(String fieldApiName : fieldApiNamesList) {
                    Id targetRecordId = (Id)taskToBeUpdateRecord.get(fieldApiName);
                    if(String.isNotBlank(targetRecordId)) {
                        String whatObjectName = String.valueOf(targetRecordId.getSObjectType());
                        if(!targetRecordIdsByObjectApiNameMap.containsKey(whatObjectName)) {
                            targetRecordIdsByObjectApiNameMap.put(whatObjectName, new Set<String>());
                        }
                        targetRecordIdsByObjectApiNameMap.get(whatObjectName).add(targetRecordId);
                    }
                }
            }

            //Code to fetch target object details (Id, Name) using dynamic SOQL query.
            Map<Id, String> targetRelatedObjectsMap = new Map<Id, String>();
            for(String objectApiName : targetRecordIdsByObjectApiNameMap.keySet()) {
                String targetFieldApiName = objectApiName.equalsIgnoreCase('Case') ? 'CaseNumber' : ( objectApiName.equalsIgnoreCase('ServiceAppointment') ? 'AppointmentNumber' : 'Name' ) ;
                Map<Id, String> relatedRecordDetailsMap = getRelatedRecordDetails(objectApiName, targetFieldApiName, targetRecordIdsByObjectApiNameMap.get(objectApiName));
                targetRelatedObjectsMap.putAll(relatedRecordDetailsMap);
            }

            for(Task taskToBeUpdateRecord : newTaskList) {
                taskToBeUpdateRecord.NSP_What_Name__c = String.isNotBlank(taskToBeUpdateRecord.WhatId) ? targetRelatedObjectsMap.get(taskToBeUpdateRecord.WhatId) : '';
                taskToBeUpdateRecord.NSP_Who_Name__c  = String.isNotBlank(taskToBeUpdateRecord.WhoId) ? targetRelatedObjectsMap.get(taskToBeUpdateRecord.WhoId) : '';
            }
        } catch ( Exception e ) {
            NSP_TaskTriggerHelper.handleException( e , 'populateWhatAndWhoNames' );
        }
    }

    /**
    * Method Name : tasksFieldsToUpdate
    * Description : Method to update NSP_What_Name__c and/or NSP_Who_Name__c on Task on update
    * Date : 17/02/2023
    * @param newList List of new tasks
    * @param oldTaskMap Map on old tasks
    * @return void
    */

    public void tasksFieldsToUpdate(Map<Id,Task> oldTaskMap, List<Task> newList) {
        try{

            List<Task> eligibleTasks = new List<Task>();
            for(Task newTaskRecord : newList) {
                Task oldTaskRecord = oldTaskMap?.get(newTaskRecord.Id);
                if(oldTaskRecord?.WhatId != newTaskRecord.WhatId || oldTaskRecord?.WhoId != newTaskRecord.WhoId) {
                    eligibleTasks.add(newTaskRecord);
                }
            }
            if(!eligibleTasks.isEmpty()) {
                populateWhatAndWhoNames(eligibleTasks);
            }

        } catch ( Exception e ) {
            NSP_TaskTriggerHelper.handleException( e , 'tasksFieldsToUpdate' );
        }
    }

    public Map<Id, String> getRelatedRecordDetails(String objectName, String fieldName, Set<String> recordIds) {
        Map<Id, String> relatedRecordDetailsMap = new Map<Id, String>();
        String query = 'SELECT Id, '+ fieldName + ' FROM ' + objectName + ' WHERE ID IN :recordIds';
        List<Schema.DescribeSObjectResult> describeSObjectResults = Schema.describeSObjects(new List<String>{objectName});
        for(sObject record: Database.query(query)) {
            relatedRecordDetailsMap.put(record.Id, describeSObjectResults[0].getLabel() + ' : ' + record.get(fieldName));
        }
        return relatedRecordDetailsMap;
    }

    // helper method to defeat sonar cognitive complexity...
    private void handleShowMessageWhenTaskIsUpdated( List<Task> records ) {
        // DF-04782
        if ( ( records != null )
            && !records.isEmpty()
            && Onboarding_Meeting_Detail_Settings__c.getInstance( UserInfo.getUserId() ).Restrict_Users_Edit_Orientation_Task__c
            )
        {
            showMessageWhenTaskIsUpdated( records );
        }
    }

    //
    // MethodName: showMessageWhenTaskIsUpdated
    // Description : This method will show error message when task is updated by non orientation meeting request queue users
    // Params:       List < Task > orientationMeetingRequestTaskList
    // Story:        DF-04782
    // createdDate : 7/21/2023
    //
    private static void showMessageWhenTaskIsUpdated( List<Task> orientationMeetingRequestTaskList ) {
        try {
            Set<Id> queueMemberIdSet = new Set<Id>();
            for ( GroupMember grpmember : [
                        SELECT UserOrGroupId
                        FROM GroupMember
                        WHERE Group.DeveloperName = :NSP_ServiceConstants.ONBOARDING_MEETING_REQUEST
                    ]
                )
            {
                queueMemberIdSet.add( grpmember.UserOrGroupId);
            }
            for ( Task newTask : orientationMeetingRequestTaskList ) {
                if ( !queueMemberIdSet.contains( UserInfo.getUserId() ) ) {
                    newTask.addError( System.Label.NSP_PreventOreintationMeetingTaskUpdate );
                }
            }
        } catch ( Exception e ) {
            NSP_TaskTriggerHelper.handleException( e , 'showMessageWhenTaskIsUpdated' );
        }
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_TaskTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_TaskTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//