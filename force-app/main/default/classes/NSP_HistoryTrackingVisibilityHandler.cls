public with sharing class NSP_HistoryTrackingVisibilityHandler {
    // test w/ NSP_SingleRelatedListControllerTest (100%)

    //
    // DEPRECATED
    //

    public static List<sObject> getAccessibleFieldList(List<sObject> objRecords,Id recordId){
        return NSP_SObjectHistoryTrackingHelper.getAccessibleFieldList( objRecords , recordId );
    }

    public static List<String> getAccessibleFields( Id recordId ) {
        return NSP_SObjectHistoryTrackingHelper.getAccessibleFields( recordId );
    }

}
//