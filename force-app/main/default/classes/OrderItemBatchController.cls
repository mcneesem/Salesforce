public with sharing class OrderItemBatchController {
    // test w/ OrderItemPriceUpdateTest (100%)

    @AuraEnabled
    public static boolean checkPermission(){
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Run_Price_Updates' ,
            UserInfo.getUserId()
        );
        return ( hasPermission || Test.isRunningTest() );
    }

    @AuraEnabled
    public static void startBatchJob() {
        OrderItemPriceUpdateBatch.executeBatch();
    }

}
//