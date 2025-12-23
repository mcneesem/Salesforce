public with sharing class RulesOfEngagement_Scheduler implements ISelfSchedulable , Schedulable {
    // test w/ RulesOfEngagement_SchedulerTest (93%)

    public void execute( SchedulableContext context ) {
        runRulesOfEngagement();
    }

    public static void runRulesOfEngagement() {
        Id availableUserId = Rules_Of_Engagement__c.getInstance(UserInfo.getUserId()).Available_User_Id__c;
        List<Id> parentIds = new List<Id>();
        List<Id> accountIds = new List<Id>();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Account> accountsToUpdate = new List<Account>();
        Map<Id,User> permittedUserMap = CustomPermissionController.getPermittedUsersMap('Rules_Of_Engagement_Enabled');

        List<Opportunity> opps = [
            SELECT
                Id , Account.OwnerId ,
                (
                    SELECT WhatId
                    FROM Tasks
                    WHERE (
                        (
                            NSP_Task_Subtype__c = 'Nurture/Regen'
                            AND Status = 'Open'
                            AND CreatedDate = LAST_N_DAYS:90
                        )
                        OR (
                            Status = 'Completed'
                            AND Subject = 'Bid Sent to Pricing and Review'
                        )
                    )
                    LIMIT 1
                )
            FROM Opportunity
            WHERE (
                Discovery_Call_Completed_Date__c < LAST_N_MONTHS:6
                AND Most_Recent_Activity_Date__c < LAST_N_MONTHS:6
                AND OwnerId IN :permittedUserMap.keySet() // only Opps owned by users w/ ROE custom permission
                AND (
                    NSP_MidMarketNationalAccount__c = NULL
                    OR NSP_MidMarketNationalAccount__c = 'MidMarket'
                )
                AND Type = 'New Product'
                AND StageName != 'Closed Lost'
                AND StageName != 'Closed Won'
                AND StageName != 'Closing'
                AND Account.RecordType.DeveloperName  != 'NSP_Partner_Client'
            )
            LIMIT 3000
        ];

        for(Opportunity opp : opps) {

            if(opp.Tasks != null && opp.Tasks.size() > 0){
                continue;
            }

            opp.StageName = 'Closed Lost';
            opp.NSP_Lost_Reason__c = 'Abandoned';
            opp.NSP_Forecast__c = 'No';
            opp.NSP_ForecastPercent__c = null;
            opp.NSP_Forecast_Status__c = null;

            if (opp.Account.OwnerId != availableUserId) {
                accountIds.add(opp.accountId);
            }

            parentIds.add(opp.accountId);
            parentIds.add(opp.id);

        }

        for(Id accountId : accountIds) {
            accountsToUpdate.add(
                new Account(
                    Id=accountId,
                    OwnerId=availableUserId,
                    Account_Assignment_Method__c='ROE Available Assignment'
                )
            );
        }

        for ( AccountContactRelation accountRelation : [
                    SELECT
                        Contact.OwnerId ,
                        ContactId ,
                        Account.OwnerId ,
                        AccountId
                    FROM AccountContactRelation
                    WHERE (
                        NSP_Is_Primary__c = true
                        AND Roles EXCLUDES('COI')
                        AND AccountId IN:accountIds
                    )
                ]
            )
        {
            if(accountRelation.Contact.ownerId == accountRelation.Account.ownerId ) {
                contactsToUpdate.add(new Contact(Id=accountRelation.ContactId, OwnerId=availableUserId));
            }
        }

        try {
            if (opps != null && !opps.isEmpty()) {
                List<Database.SaveResult> results = Database.update( opps , true );
                NSP_ErrorLogHandler.logResults(
                    RulesOfEngagement_Scheduler.class.getName() ,
                    'runRulesOfEngagement:update:Opportunity' ,
                    results
                );
            }
            if (accountsToUpdate != null && !accountsToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update( accountsToUpdate , true );
                NSP_ErrorLogHandler.logResults(
                    RulesOfEngagement_Scheduler.class.getName() ,
                    'runRulesOfEngagement:update:Account' ,
                    results
                );
            }
            if (contactsToUpdate != null && !contactsToUpdate.isEmpty()) {
                List<Database.SaveResult> results = Database.update( contactsToUpdate , true );
                NSP_ErrorLogHandler.logResults(
                    RulesOfEngagement_Scheduler.class.getName() ,
                    'runRulesOfEngagement:update:Contact' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                RulesOfEngagement_Scheduler.class.getName() ,
                'runRulesOfEngagement' ,
                e
            );
        }

        if (parentIds != null && !parentIds.isEmpty()) {
            Database.executeBatch(new CancelCoreSalesEventsTasksBatch(parentIds), 200);
        }
    }

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'RulesOfEngagement_Scheduler ~ everyday at 3 AM' + suffix ,
            '0 0 3 * * ? *' ,
            new RulesOfEngagement_Scheduler()
        );
    }

}
//