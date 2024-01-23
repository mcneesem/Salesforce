trigger FlowErrorLogTrigger on FlowErrorLog__c ( before insert , before update ) {
    // test w/ FlowErrorLogControllerTest (100%)
    static final String DEBUG_PREFIX = ' ~ FlowErrorLogTrigger';
    TriggerContextHandler.debug( DEBUG_PREFIX );
    if ( Trigger.isBefore && ( Trigger.isInsert || Trigger.isUpdate ) ) {
        // collect all the unique UserIds...
        Set<Id> userIds = new Set<Id>();
        for ( FlowErrorLog__c record : Trigger.new ) {
            if ( String.isNotBlank( record.UserId__c )
                && ( record.UserId__c InstanceOf Id )
               )
            {
                userIds.add( record.UserId__c );
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ userIds=' + userIds );
        // build Map<UserId,User>...
        Map<Id,User> userMap = new Map<Id,User>(
            [
                SELECT Id , Name
                FROM User
                WHERE ( Id IN :userIds )
            ]
        );
        // second pass, update related Id values...
        // ~ populate UserId__c...
        for ( FlowErrorLog__c record : Trigger.new ) {
            if ( String.isNotBlank( record.UserId__c )
                && ( userMap != null )
                && userMap.containsKey( record.UserId__c )
                && ( userMap.get( record.UserId__c ) != null )
               )
            {
                record.User__c = userMap.get( record.UserId__c ).Id;
            }
        }
    }
}
//