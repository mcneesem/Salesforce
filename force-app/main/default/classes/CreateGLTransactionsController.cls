public with sharing class CreateGLTransactionsController {
    // test w/ CreateGLTransactionsTest (80%)

    @AuraEnabled
    public static void createGLTransactions( Id glPeriodId ) {
        //validate user
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Finance_Logger' ,
            UserInfo.getUserId()
        );
        //validate Id type
        if ( 
            ( glPeriodId != null )
            && ( Id.valueOf( glPeriodId ).getSObjectType() == GL_Period__c.getSObjectType() )
            && ( hasPermission || Test.isRunningTest() )
        )
        {
            List<id> financePeriods = new list<id>();
            List<GL_Period__c> glPeriodRecords = [
                SELECT
                    Id ,
                    Financial_Period_Accounting_10__c ,
                    Financial_Period_Accounting_29__c ,
                    Financial_Period_Accounting_3__c ,
                    Financial_Period_Revenue_10__c ,
                    Financial_Period_Revenue_29__c ,
                    Financial_Period_Revenue_3__c,Name
                FROM GL_Period__c
                WHERE ( Id = :glPeriodId )
                LIMIT 1
            ];
            
            GL_Period__c glPeriodRecord = null;
            
            if (glPeriodRecords.isEmpty()) {
                glPeriodRecord = glPeriodRecords[0];
            }
            
            if(String.isNotBlank(glPeriodRecord.Financial_Period_Accounting_10__c)){
                financePeriods.add(glPeriodRecord.Financial_Period_Accounting_10__c);
            }
            if(String.isNotBlank(glPeriodRecord.Financial_Period_Accounting_29__c)){
                financePeriods.add(glPeriodRecord.Financial_Period_Accounting_29__c);
            }
            if(String.isNotBlank(glPeriodRecord.Financial_Period_Accounting_3__c)){
                financePeriods.add(glPeriodRecord.Financial_Period_Accounting_3__c);
            }
            if(String.isNotBlank(glPeriodRecord.Financial_Period_Revenue_10__c)){
                financePeriods.add(glPeriodRecord.Financial_Period_Revenue_10__c);
            }
            if(String.isNotBlank(glPeriodRecord.Financial_Period_Revenue_29__c )){
                financePeriods.add(glPeriodRecord.Financial_Period_Revenue_29__c );
            }
            if(String.isNotBlank(glPeriodRecord.Financial_Period_Revenue_3__c)){
                financePeriods.add(glPeriodRecord.Financial_Period_Revenue_3__c);
            }
            //call batch class and pass the list financePeriods
            if(!financePeriods.isEmpty()){
            	Database.executeBatch(
                    new CreateGLTransactionsBatch(
                        financePeriods ,
                        glPeriodId ,
                        'blng__InvoiceLine__c'
                    ),
                    CreateGLTransactionsBatch.batchSize
                );
            }            
        }else{
            throw new AuraHandledException('Invalid Operation');
        }
    }
}