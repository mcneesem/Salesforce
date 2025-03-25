public with sharing class JobRunnerController {
    // test w/ JobRunnerControllerTest (%96)
    @AuraEnabled
    public static Id executeBatch(String batchClassName) {
        String jsonConfig = JSON.serialize(new Map<String, Object>{
            'batchName' => batchClassName
        });

        BatchableServiceHandler.ResponseWrapper response = BatchableServiceHandler.processBatchRequest(jsonConfig);

        if (response.statusCode != 200) {
            throw new AuraHandledException(response.responseBody);
        }

        Type batchType = Type.forName(batchClassName);
        if (batchType == null) {
            throw new AuraHandledException('Invalid batch class name: ' + batchClassName);
        }
        Database.Batchable<SObject> batchInstance = (Database.Batchable<SObject>) batchType.newInstance();
        return Database.executeBatch(batchInstance);
    }

    @AuraEnabled(cacheable=true)
    public static List<AsyncApexJob> getBatchJobStatuses(String batchClassName) {
        DateTime sevenDaysAgo = DateTime.now().addDays(-7);
        Id currentUserId = UserInfo.getUserId();

        return [
            SELECT Id, CreatedDate, JobType, Status, ExtendedStatus, TotalJobItems, 
                   NumberOfErrors, CreatedBy.Name, CompletedDate, ApexClass.Name, MethodName, JobItemsProcessed
            FROM AsyncApexJob
            WHERE ApexClass.Name = :batchClassName
            AND CreatedById = :currentUserId
            AND CreatedDate >= :sevenDaysAgo
            ORDER BY CreatedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRecentBatchClasses() {
        DateTime thirtyDaysAgo = DateTime.now().addDays(-30);
        Id currentUserId = UserInfo.getUserId();

        AggregateResult[] results = [
            SELECT ApexClass.Name
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND CreatedDate >= :thirtyDaysAgo
            AND ApexClass.Name != null
            AND CreatedById = :currentUserId
            GROUP BY ApexClass.Name
            ORDER BY ApexClass.Name
        ];

        List<Map<String, String>> options = new List<Map<String, String>>();
        for (AggregateResult ar : results) {
            String className = (String)ar.get('Name');
            options.add(new Map<String, String>{
                'label' => className,
                'value' => className
            });
        }
        return options;
    }
}