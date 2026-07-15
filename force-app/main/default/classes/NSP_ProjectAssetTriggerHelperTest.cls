@isTest
private class NSP_ProjectAssetTriggerHelperTest {

    @isTest
    private static void testDeprecatedConstant() {
        Test.startTest();
        System.debug(NSP_ProjectAssetTriggerHelper.DEPRECATED);
        Test.stopTest();
        System.assertEquals('DEPRECATED',NSP_ProjectAssetTriggerHelper.DEPRECATED);
    }

    @isTest
    private static void beforeInsert() {
        new NSP_ProjectAssetTriggerHandler().beforeInsert(null);
        System.assert(new NSP_ProjectAssetTriggerHandler().beforeInsert(null) == null);
    }

    @isTest
    private static void afterInsert() {
        new NSP_ProjectAssetTriggerHandler().afterInsert(null, null);
        System.assert(new NSP_ProjectAssetTriggerHandler().afterInsert(null, null) == null);
    }

    @isTest
    private static void beforeUpdate() {
        new NSP_ProjectAssetTriggerHandler().beforeUpdate(null, null);
        System.assert(new NSP_ProjectAssetTriggerHandler().beforeUpdate(null, null) == null);
    }

    @isTest
    private static void afterUpdate() {
        new NSP_ProjectAssetTriggerHandler().afterUpdate(null, null);
        System.assert(new NSP_ProjectAssetTriggerHandler().afterUpdate(null, null) == null);
    }

    @isTest
    private static void beforeDelete() {
        new NSP_ProjectAssetTriggerHandler().beforeDelete(null, null);
        System.assert(new NSP_ProjectAssetTriggerHandler().beforeDelete(null, null) == null);
    }

    @isTest
    private static void afterDelete() {
        new NSP_ProjectAssetTriggerHandler().afterDelete(null, null);
        System.assert(new NSP_ProjectAssetTriggerHandler().afterDelete(null, null) == null);
    }

}
//