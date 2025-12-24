public class NSP_WXCSSTaskCreationBatch implements Schedulable, Database.Batchable<sObject> {
    // test w/ NSP_WXCSSTaskCreationBatchTest (93%)

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cssRenewDate = System.today().addDays(15);

        //List of engagement levels of account used in query
        List<String> engagementLevels = new List<String>{
            'Level 3',
            'Level 4'
        };

        //List of account fields used in query
        List<String> accountFields = new List<String>{
            'NSP_CSS_Renewal_Date__c',
            'NSP_Engagement_Level__c'
        };

        //Quey all the accounts with Engagement Level 3 OR 4 where CSS Renewal Date is 15 days in future
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('Account', accountFields)
            .setSecurityEnforce(false)
            .addFilter('NSP_Engagement_Level__c', engagementLevels, NSP_QueryBuilder.Operator.INCLUDES)
            ;
        String query = queryBuilder.build();
        query += ' AND NSP_CSS_Renewal_Date__c =: cssRenewDate';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> accountList){
        List<Task> taskList = new List<Task>();
        try{
            //for each account create tasks
            for(Account acc: accountList){
                Date cssDate = acc.NSP_CSS_Renewal_Date__c;
                Task task1 = createTask(acc, cssDate.addDays(5));
                Task task2 = createTask(acc, cssDate.addDays(90));
                Task task3 = createTask(acc, cssDate.addDays(180));
                Task task4 = createTask(acc, cssDate.addDays(270));
                taskList.add(task1);
                taskList.add(task2);
                taskList.add(task3);
                taskList.add(task4);
            }

            //check if task list is not empty
            if(!taskList.isEmpty()){
                List<Database.SaveResult> results = Database.insert(taskList,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_WXCSSTaskCreationBatch', 'ExecuteMethod', results );
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_WXCSSTaskCreationBatch', 'execute', ex.getMessage());
        }
    }

    private Task createTask(Account acc, Date cssDate){
        Id cssRep;
        //get account team for an account where role is customer success specialist
        List<String> accountTeamFields = new List<String>{
            'Id',
            'NSP_Role__c',
            'NSP_User__c',
            'NSP_Account__c',
            'NSP_Primary__c'
        };
        NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder('NSP_Account_Team__c', accountTeamFields)
            .setSecurityEnforce(false)
            .addFilter('NSP_Role__c', NSP_ServiceConstants.CUSTOMER_SPECIALIST)
            .addFilter('NSP_Account__c', acc.Id)
            ;
        String query = queryBuilder.build();
        List<NSP_Account_Team__c> accountTeam = (List<NSP_Account_Team__c>) Database.query(query);

        //if there is more than one css rep then use the one which is marked as primary
        if(accountTeam.size() > 1){
            for(NSP_Account_Team__c accTeam: accountTeam){
                if(accTeam.NSP_Primary__c == true){
                    cssRep = accTeam.NSP_User__c;
                }
            }
        }
        //assign cssRep to the user of the account team
        else if(!accountTeam.isEmpty()){
            cssRep = accountTeam[0].NSP_User__c;
        }

        //get bps task record type
        Id bpsTaskRT = NSP_GenericRecordType.getRecordTypeId('Task', 'BPS_task_RT');
        Task newTask = new Task();
        newTask.RecordTypeId = bpsTaskRT;
        newTask.Subject = NSP_ServiceConstants.QUARTERLY_MEETING;
        newTask.Description = NSP_ServiceConstants.FOLLOW_UP_QUARTERLY;
        newTask.OwnerId = cssRep;
        newTask.WhatId = acc.Id;
        newTask.NSP_Start_Date__c = cssDate;
        newTask.ActivityDate = cssDate.addDays(30);
        return newTask;
    }

    public void finish(Database.BatchableContext bc) {

    }

    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_WXCSSTaskCreationBatch(),200);
    }

    // runs everyday at 11pm central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_WXCSSTaskCreationBatch ~ On an Account when the current date is 15 days prior to the CSS Renewal date AND it has an Engagement Level = 3 or 4, then a set of tasks will be created ~ everyday at 11 PM' + suffix ,
            '0 0 23 ? * * *' ,
            new NSP_WXCSSTaskCreationBatch()
        );
    }

}
//