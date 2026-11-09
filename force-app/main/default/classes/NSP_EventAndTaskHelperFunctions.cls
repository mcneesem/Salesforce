// intentionally `without sharing` to preserve default sharing at api version 54...
public without sharing class NSP_EventAndTaskHelperFunctions {
    // test w/ NSP_EventAndTaskHelperFunctionsTest (87%)

    //
    // Description: This method accepts various parameters from which it
    // creates an instance of Task records and assigns field values based on parameters passed
    //
    public static Task instantiateTaskRecord(
        String taskSubject ,
        Id whatId ,
        Id ownerId ,
        String taskType ,
        String taskStatus ,
        String taskSubType ,
        Date taskDueDate
        )
    {
        Task taskRecord = new Task();
        taskRecord.Subject = taskSubject;
        taskRecord.WhatId = whatId;
        taskRecord.NSP_Task_type__c = taskType;
        taskRecord.Status = taskStatus;
        taskRecord.OwnerId = ownerId;
        taskRecord.NSP_Task_Subtype__c = taskSubType;
        taskRecord.ActivityDate = taskDueDate;
        return taskRecord;
    }

    //
    // Description: This method accepts various parameters from which it
    // creates an instance of Task records and assigns field values based on parameters passed
    //
    public static Task instantiateTaskPrimaryRecord(
        String taskSubject ,
        Id whatId ,
        Id ownerId ,
        String taskType ,
        String taskStatus ,
        String taskSubType ,
        Date taskDueDate
        )
    {
        Task taskRecord = new Task();
        taskRecord.Subject = taskSubject;
        taskRecord.WhatId = whatId;
        taskRecord.NSP_Task_type__c = taskType;
        taskRecord.Status = taskStatus;
        taskRecord.OwnerId = ownerId;
        taskRecord.NSP_Task_Subtype__c = taskSubType;
        taskRecord.ActivityDate = taskDueDate;
        taskRecord.NSP_Opportunity__c = whatId;
        return taskRecord;
    }

    //
    // Iterates through the opportunities where primary quote is created
    // and creates a Task to be assigned to Opportunity Owner
    //
    public static void createTaskForPrimaryQuote( List<Opportunity> opportunityList ) {
        try {
            List<Task> newTaskListPrimary = new List<Task>();
            Set<Id> oppIdSet = new Set<Id>();
            Set<Id> oppIdPrimarySet = new Set<Id>();
            List<Task> taskIdList = new List<Task>();
            for ( Opportunity oppList : opportunityList ) {
                if ( ( oppList.NSP_PrimaryProduct__c == 'WX' || oppList.NSP_PrimaryProduct__c == 'WA' )
                    && (oppList.NSP_Client_For_Life__c == 'WX' || oppList.NSP_Client_For_Life__c == 'WA')
                    )
                {
                    oppIdSet.add( oppList.Id );
                }
            }
            if ( !oppIdSet.isEmpty() ) {
                taskIdList = [
                    SELECT WhatId
                    FROM Task
                    WHERE (
                        Subject = 'Primary Quote Created'
                        AND NSP_Task_type__c = 'Core Sales'
                        AND NSP_Task_Subtype__c = 'WX Quote'
                        AND WhatId IN :oppIdSet
                    )
                ];
            }
            if ( !taskIdList.isEmpty() ) {
                for ( Task taskList : taskIdList ) {
                    oppIdPrimarySet.add( taskList.WhatId );
                }
            }
            for ( Opportunity opportunityRecord : opportunityList ) {
                if ( oppIdSet.contains( opportunityRecord.Id )
                    && !oppIdPrimarySet.contains( opportunityRecord.Id )
                    )
                {
                    Task taskRecord = NSP_EventAndTaskHelperFunctions.instantiateTaskPrimaryRecord(
                        'Primary Quote Created' ,
                        opportunityRecord.Id ,
                        opportunityRecord.OwnerId ,
                        NSP_SalesConstants.Task_Type ,
                        NSP_SalesConstants.COMPLETED ,
                        NSP_SalesConstants.Task_SubType ,
                        System.today()
                    );
                    newTaskListPrimary.add( taskRecord );
                } else if ( ( oppIdSet.contains( opportunityRecord.Id ) && oppIdPrimarySet.contains( opportunityRecord.Id ) )
                    || !oppIdSet.contains( opportunityRecord.Id )
                    )
                {
                    Task taskRecord = NSP_EventAndTaskHelperFunctions.instantiateTaskPrimaryRecord(
                        'Primary Quote Created' ,
                        opportunityRecord.Id ,
                        opportunityRecord.OwnerId ,
                        '' ,
                        NSP_SalesConstants.COMPLETED ,
                        '' ,
                        System.today()
                    );
                    newTaskListPrimary.add( taskRecord );
                }
            }
            if ( !newTaskListPrimary.isEmpty() ) {
                insert newTaskListPrimary;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EventAndTaskHelperFunctions.class.getName() ,
                'createTaskForPrimaryQuote' ,
                e
            );
        }
    }

    //
    // Description: Iterates through all Newly created Opportunities to check
    // if HSA Addendum fields are populated and create a task record assigned to NCS Group Queue
    //
    public static void createTaskRecordsForNCSQueue( List<Opportunity > newOpportunityList , Map<Id,Opportunity> opportunityOldMap ) {
        try {
            List<Task> newTaskList = new List<Task>();
            List<Group> ncsGroupQueues = [
                SELECT Id , DeveloperName , Name
                FROM Group
                WHERE (
                    ( Type = 'Queue' )
                    AND ( DeveloperName = :NSP_SalesConstants.NCS_SALES_GROUP )
                )
                LIMIT 1
            ];
            if ( !ncsGroupQueues.isEmpty() ) {
                Group ncsGroupQueue = ncsGroupQueues[0];
                for ( Opportunity opportunityObject: newOpportunityList ) {
                    Task taskRecord = NSP_EventAndTaskHelperFunctions.instantiateTaskRecord(
                        NSP_SalesConstants.NCS_SALES_TASK_SUBJECT ,
                        opportunityObject.Id ,
                        ncsGroupQueue.Id ,
                        NSP_SalesConstants.ADDENDUMREQUEST_TASKTYPE ,
                        NSP_SalesConstants.OPEN ,
                        '' ,
                        null
                    );
                    newTaskList.add( taskRecord );
                }
            }
            if ( !newTaskList.isEmpty() ) {
                insert newTaskList;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_EventAndTaskHelperFunctions.class.getName() ,
                'createTaskRecordsForNCSQueue' ,
                e
            );
        }
    }

}
//
