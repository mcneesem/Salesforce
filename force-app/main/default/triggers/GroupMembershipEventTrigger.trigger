trigger GroupMembershipEventTrigger on GroupMembershipEvent__e ( after insert ) {
    // test w/ GroupMembershipControllerTest (100%)
    static final String DEBUG_PREFIX = ' ~ GroupMembershipEventTrigger';
    TriggerContextHandler.debug( DEBUG_PREFIX );
    //
    // executing apex in this Platform Event Trigger will runAs the 'Automated Process' User
    //  ~ primary use-case is to allow modification of queue membership (GroupMember) without the "Manage Users" Permission...
    //  ~ use with extreme caution!!!
    //
    System.debug(
        DEBUG_PREFIX
        + ' ~ UserInfo.getName=' + UserInfo.getName()
        + ' ~ UserInfo.getUserId=' + UserInfo.getUserId()
        + ' ~ UserInfo.getUserName=' + UserInfo.getUserName()
        + ' ~ UserInfo.getUserType=' + UserInfo.getUserType()
    );
    // ~ GroupMembershipEventTrigger ~ UserInfo.getName=Automated Process ~ UserInfo.getUserId=005f4000003lkEAAAY ~ UserInfo.getUserName=autoproc@00df4000004lszxeai ~ UserInfo.getUserType=AutomatedProcess
    if ( Trigger.isAfter && Trigger.isInsert ) {
        // after-insert...
        for ( GroupMembershipEvent__e event : Trigger.new ) {
            GroupMembershipController.saveGroupMemberships( event );
        }
    }
}
//