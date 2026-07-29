public with sharing class NSP_MergeProjectController {
    // test w/ NSP_MergeProjectControllerTest (88%)

    //
    // This method is used to merge two projects records.
    // It deletes child project record & its associated Project Tasks, Milestones, Assignments.
    // It creates project asset, project account unique records on parent project record.
    // It is an invocable method which is being called by Merge Projects Screen Flow.
    // It do all the Db operations in async mode.
    //
    @InvocableMethod(label='Merge Project' description='Merge two projects' category='Project')
    public static void mergeProject( List<List<String>> flowParams ) {
        try {
            List<String> projectIds = flowParams[0];
            // Do Database operations asynchronously
            NSP_MergeProjectController.mergeProjectRecords( projectIds[0] , projectIds[1] );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_MergeProjectController.class.getName() ,
                'mergeProject' ,
                e
            );
        }
    }

    // Delete and update related records asynchronously.
    @future
    private static void mergeProjectRecords( String parentProjectId , String childProjectId ) {
        try {
            List<SObject> itemsToUpsert = new List<SObject>();
            List<pse__Proj__c> childProjectToUpdate = new List<pse__Proj__c>();

            // Fetch all the required records for parent & child project records
            List<pse__Proj__c> childProjs = [
                SELECT
                    Id ,
                    Name ,
                    NSP_Queued_for_Delete__c ,
                    ( SELECT Id FROM pse__Milestones__r ) ,
                    ( SELECT Id FROM pse__Project_Tasks__r ) ,
                    ( SELECT Id FROM Order_Products__r ) ,
                    ( SELECT Id FROM Orders__r ) ,
                    ( SELECT Id FROM pse__Assignments__r )
                FROM pse__Proj__c
                WHERE ( Id = :childProjectId )
                LIMIT 1
            ];
            pse__Proj__c childProj = childProjs[0];
            List<pse__Proj__c> parentProjs = [
                SELECT
                    Id ,
                    Name ,
                    ( SELECT Id , Asset__c FROM Project_Assets__r ) ,
                    ( SELECT Id , Account__c FROM Project_Accounts__r )
                FROM pse__Proj__c
                WHERE ( Id = :parentProjectId )
                LIMIT 1
            ];
            pse__Proj__c parentProj = parentProjs[0];

            // Prepare a list of records which needs to be inserted/updated
            itemsToUpsert.addAll(
                NSP_MergeProjectController.getUpdatedOrder(
                    parentProjectId ,
                    childProj.Orders__r
                )
            );
            itemsToUpsert.addAll(
                NSP_MergeProjectController.getUpdatedOrderItems(
                    parentProjectId ,
                    childProj.Order_Products__r
                )
            );
            itemsToUpsert.addAll(
                NSP_MergeProjectController.getProjectAccounts(
                    parentProjectId ,
                    childProjectId ,
                    NSP_MergeProjectController.getAccountIdList( parentProj.Project_Accounts__r )
                )
            );
            itemsToUpsert.addAll(
                NSP_MergeProjectController.getProjectAssets(
                    parentProjectId ,
                    childProjectId ,
                    NSP_MergeProjectController.getAssetIdList( parentProj.Project_Assets__r )
                )
            );

            // update child project "Queued for Delete" - start
            childProj.NSP_Queued_for_Delete__c = true;
            childProjectToUpdate.add( childProj );
            itemsToUpsert.addAll( childProjectToUpdate );
            // update child project "Queued for Delete" - end

            // Commit all the records to database
            NSP_MergeProjectController.doDbOperations( itemsToUpsert );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_MergeProjectController.class.getName() ,
                'mergeProjectRecords' ,
                e
            );
        }
   }

    // Do all the database operations and creates error log object for the failed records
    private static void doDbOperations( List<SObject> itemsToUpsert ) {
        if ( !itemsToUpsert.isEmpty() ) {
            List<Database.UpsertResult> upsertResults = Database.upsert( itemsToUpsert , false );
            NSP_ErrorLogHandler.logResults(
                NSP_MergeProjectController.class.getName() ,
                'doDbOperations' ,
                upsertResults
            );
        }
    }

    // Get a list of account ids from the list of project account records
    private static List<Id> getAccountIdList( List<Project_Account__c> projAccounts ) {
        List<Id> accIds = new List<Id>();
        for ( Project_Account__c projAcc : projAccounts ) {
            accIds.add( projAcc.Account__c );
        }
        return accIds;
    }

    // Get a list of asset ids from the list of project asset records
    private static List<Id> getAssetIdList( List<Project_Asset__c> projAssets ) {
        List<Id> assetIds = new List<Id>();
        for ( Project_Asset__c projAsset : projAssets ) {
            assetIds.add( projAsset.Asset__c );
        }
        return assetIds;
    }

    // Update parent project id in order of child projectm
    private static List<Order> getUpdatedOrder( String parentProjectId , List<Order> orders ) {
        List<Order> updatedOrder = new List<Order>();
        for ( Order orderObj : orders ) {
            orderObj.NSP_Project__c = parentProjectId;
            updatedOrder.add( orderObj );
        }
        return updatedOrder;
    }

    // Update parent project id in order items of child project
    private static List<OrderItem> getUpdatedOrderItems( String parentProjectId , List<OrderItem> oItems ) {
        List<OrderItem> updatedOrderItems = new List<OrderItem>();
        for ( OrderItem oItem : oItems ) {
            oItem.NSP_Project__c = parentProjectId;
            updatedOrderItems.add( oItem );
        }
        return updatedOrderItems;
    }

    // Get a list of project accounts which needs to be added on parent project record
    private static List<Project_Account__c> getProjectAccounts(
        String parentProjectId ,
        String childProjectId ,
        List<String> parentProjAccs
        )
    {
        List<Project_Account__c> projAccounts = new List<Project_Account__c>();
        for ( Project_Account__c projAcc : [
                    SELECT Id , Account__c
                    FROM Project_Account__c
                    WHERE (
                        ( Project__c = :childProjectId )
                        AND ( Account__c NOT IN :parentProjAccs )
                    )
                ]
            )
        {
            projAccounts.add(
                new Project_Account__c(
                    Project__c=parentProjectId ,
                    Account__c=projAcc.Account__c
                )
            );
        }
        return projAccounts;
    }

    // Get a list of project assets which needs to be added on parent project record
    private static List<Project_Asset__c> getProjectAssets(
        String parentProjectId ,
        String childProjectId ,
        List<String> parentProjAssets
        )
    {
        List<Project_Asset__c> projAssets = new List<Project_Asset__c>();
        for ( Project_Asset__c projAsset : [
                    SELECT Id , Asset__c
                    FROM Project_Asset__c
                    WHERE (
                        ( Project__c = :childProjectId )
                        AND ( Asset__c NOT IN :parentProjAssets )
                    )
                ]
            )
        {
            projAssets.add(
                new Project_Asset__c(
                    Project__c=parentProjectId ,
                    Asset__c=projAsset.Asset__c
                )
            );
        }
        return projAssets;
    }

    // Prepare set of ids by list of records
    private static Set<Id> getIdSetByRecordList( List<SObject> records ) {
        return new Map<Id,SObject>( records ).keyset();
    }

}
//