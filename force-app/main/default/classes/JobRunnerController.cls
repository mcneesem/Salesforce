public with sharing class JobRunnerController {
    // test w/ JobRunnerControllerTest (%96)
    @AuraEnabled
    public static void executeBatch(String batchClassName) {
        if (String.isBlank(batchClassName)) {
            throw new AuraHandledException('Batch class name cannot be empty');
        }

        String jsonConfig = JSON.serialize(new Map<String, Object>{
            'batchName' => batchClassName
        });

        BatchableServiceHandler.ResponseWrapper response = BatchableServiceHandler.processBatchRequest(jsonConfig);

        if (response.statusCode != 200) {
            throw new AuraHandledException(response.responseBody);
        }
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

        AggregateResult[] results = [
            SELECT Id , Name
            FROM ApexClass
            WHERE (
                ( NamespacePrefix = null )
                AND ( Name LIKE '%Batch%' )
                AND ( NOT Name LIKE '%Test%' )
                AND ( IsValid = true ) 
            )
            ORDER BY Name ASC
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