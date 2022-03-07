public class NSP_EventAndTaskHelperFunctions {

    /*
     * Description: This method accepts various parameters from which it 
     * creates an instance of Task records and assigns field values based on parameters passed
     * @params: String taskSubject, Id whatId, Id ownerId, string taskType, string taskStatus, string taskSubType
     * @return: Task
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * Tejas          10-05-2021          created this new method
     * 
     * 
     */
    public static Task instantiateTaskRecord(String taskSubject, Id whatId, Id ownerId, string taskType, string taskStatus, string taskSubType, Date taskDueDate) {
        Task taskRecord = new Task();

        taskRecord.Subject = taskSubject;
        taskRecord.WhatId = whatId;
        taskRecord.Type = taskType;
        taskRecord.Status = taskStatus;
        taskRecord.OwnerId = ownerId;
        taskRecord.NSP_Task_Subtype__c = taskSubType;
        taskRecord.ActivityDate = taskDueDate;

        return taskRecord;

    }




    /**
     * Iterates through the opportunities where primary quote is created
     * and creates a Task to be assigned to Opportunity Owner
     * @param opportunityList of Opportunities where PrimaryQuote is created
     * @return void             
     * 
     */
    public static void createTaskForPrimaryQuote(List < Opportunity > opportunityList) {
        List < Task > newTaskList = new List < Task > ();
        for (Opportunity opportunityRecord: opportunityList) {
            Task taskRecord = instantiateTaskRecord('Primary Quote Created', opportunityRecord.Id, opportunityRecord.OwnerId,
                NSP_SalesConstants.ADDENDUMREQUEST_TASKTYPE,
                NSP_SalesConstants.OPEN, '', opportunityRecord.CloseDate);

            newTaskList.add(taskRecord);
        }

        try {
            if (newTaskList.size() > 0) {
                insert newTaskList;
            }
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_OpportunityTriggerHelper', 'createTaskForPrimaryQuote', ex.getMessage());
        }
    }

    /*
     * Description: Iterates through all Newly created Opportunities to check 
     * if HSA Addendum fields are populated and create a task record assigned to NCS Group Queue
     * @return: void
     * Modification History:
     * -------------------------------------------------------------------------------------
     * author           | Date              | Description
     * -------------------------------------------------------------------------------------
     * Tejas          10-05-2021          created this new method
     * 
     * 
     */

    public static void createTaskRecordsForNCSQueue(List < Opportunity > newOpportunityList, Map < Id, Opportunity > opportunityOldMap) {
        List < Task > newTaskList = new List < Task > ();
        Group NCS_Group_Queue = [SELECT Id, DeveloperName, name FROM Group
            WHERE Type = 'Queue'
            AND DeveloperName =: NSP_SalesConstants.NCS_SALES_GROUP LIMIT 1
        ];



        for (Opportunity opportunityObject: newOpportunityList) {
            Task taskRecord = instantiateTaskRecord(NSP_SalesConstants.NCS_SALES_TASK_SUBJECT, opportunityObject.Id, NCS_Group_Queue.Id,
                NSP_SalesConstants.ADDENDUMREQUEST_TASKTYPE,
                NSP_SalesConstants.OPEN, '', null);

            newTaskList.add(taskRecord);
        }

        if (!newTaskList.isEmpty()) {
            try {
                insert newTaskList;
            } catch (Exception ex) {
                NSP_ErrorLogHandler.logSaveException('NSP_OpportunityTriggerHelper', 'createTaskRecordsForNCSQueue', ex.getMessage());
            }
        }
    }

}