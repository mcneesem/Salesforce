public with sharing class UserAvailabilityFlow {

    @InvocableMethod(label='Get Available Users')
    public static List<List<Id>> getUsers( List<UserAvailabilityFlow.UserAvailabilityInput> inputs ) {
        List<List<Id>> response = new List<List<Id>>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( UserAvailabilityFlow.UserAvailabilityInput i : inputs ) {
                List<Id> userIds = UserAvailabilityService.getAvailableUsersForWindow(
                    i.startDT,
                    i.endDT,
                    i.skill
                );
                if ( userIds == null ) {
                    userIds = new List<Id>();
                }
                response.add( userIds );
            }
        }
        return response;
    }

    public class UserAvailabilityInput {
        @InvocableVariable(required=true)
        public Datetime startDT;
        @InvocableVariable(required=true)
        public Datetime endDT;
        @InvocableVariable
        public String skill;
    }
}