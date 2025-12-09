public class CLMDocumentTriggerHandler extends NSP_TriggerAction implements NSP_ITriggerHandler  {
    // test w/ OnCLMDocumentCreateTest (100%)

    public static Boolean TriggerDisabled = false;

    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    public void beforeInsert( List<sObject> newList ) {
    }

    public void afterInsert( List<sObject> newList , Map<Id,sObject> newMap ) {
        CLMDocumentTriggerHelper helper = new CLMDocumentTriggerHelper();
        helper.afterInsertDocument( (Map<Id,CLM_Document__c>)newMap );
    }

    public void beforeUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
    }

    public void afterUpdate( Map<Id,sObject> newMap , Map<Id,sObject> oldMap ) {
    }

    public void beforeDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
    }

    public void afterDelete( List<sObject> oldList , Map<Id,sObject> oldMap ) {
    }

}
//