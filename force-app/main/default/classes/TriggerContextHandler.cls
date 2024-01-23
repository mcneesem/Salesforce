public with sharing class TriggerContextHandler {
    // test w/ TriggerContextHandlerTest (100%)
    private static final String CLASS_NAME = ' ~ TriggerContextHandler';

    public static void debug( String prefix ) {
        System.debug(
            prefix
            + ' ~ Trigger.operationType=' + Trigger.operationType
            + ' ~ Trigger.size=' + Trigger.size
            + ' ~ Trigger.isBefore=' + Trigger.isBefore
            + ' ~ Trigger.isAfter=' + Trigger.isAfter
            + ' ~ Trigger.isInsert=' + Trigger.isInsert
            + ' ~ Trigger.isUpdate=' + Trigger.isUpdate
            + ' ~ Trigger.isDelete=' + Trigger.isDelete
            + ' ~ Trigger.isUndelete=' + Trigger.isUndelete
        );
    }
}
//