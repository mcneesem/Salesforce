public with sharing class UserAvailabilityFlow {

    @InvocableMethod(label='Get Available Users')
    public static List<List<Id>> getUsers(List<UserAvailabilityInput> inputs) {
        UserAvailabilityInput i = null;
        if(inputs != null && !inputs.isEmpty()) {
            i = inputs[0];
        }

        List<Id> userIds = UserAvailabilityService.getAvailableUsersForWindow(
            i.startDT,
            i.endDT,
            i.skill
        );
        return new List<List<Id>>{userIds};
    }
}