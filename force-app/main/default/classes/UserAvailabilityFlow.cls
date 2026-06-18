public with sharing class UserAvailabilityFlow {
    // test w/ UserAvailabilityFlowTest (100%)

    // DEPRECATED

    @InvocableMethod(label='Get Available Users')
    public static List<List<User>> getUsers( List<UserAvailabilityFlow.UserAvailabilityInput> inputs ) {
        List<List<User>> response = new List<List<User>>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( UserAvailabilityFlow.UserAvailabilityInput i : inputs ) {
                List<Id> userIds = i.userIds;
                List<User> sortedUsers = new List<User>();
                if ( ( userIds != null ) && !userIds.isEmpty() && ( i.selectedDate != null ) ) {
                    sortedUsers = UserAvailabilityService.sortUsersByDailyLoad(
                        userIds ,
                        i.selectedDate
                    );
                }
                response.add( sortedUsers );
            }
        }
        return response;
    }

    public class UserAvailabilityInput {
        @InvocableVariable(required=false)
        public List<Id> userIds;
        @InvocableVariable(required=false)
        public Date selectedDate;
    }
}