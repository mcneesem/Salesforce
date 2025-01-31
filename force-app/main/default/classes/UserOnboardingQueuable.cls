public class UserOnboardingQueuable implements Queueable {
    // test w/ UserOnboardingQueuableTest (100%)
/**
 * Handles after insert for User Onboarding asynchronously
 *                
*/
    private List<User> newUserList;
    private Map<Id,User> newUserMap;
    private Map<Id,User> oldUserMap;
    private String triggerOperation;
    
    //Constructor
    public UserOnboardingQueuable(List<User> newList, Map<Id,User> newMap , Map<Id,User> oldMap , String triggerContext){
        this.newUserList = newList;
        this.newUserMap = newMap;
        this.oldUserMap = oldMap;
        this.triggerOperation = triggerContext;
    }
    
    public void execute(QueueableContext context) {
        UserOnboardingTriggerHelper userOnboardingTriggerHelper =new UserOnboardingTriggerHelper();
        if(triggerOperation == 'afterinsert') {
            userOnboardingTriggerHelper.afterInsertUser((List<User>) newUserList);
        }
        else if(triggerOperation == 'afterupdate') {
            userOnboardingTriggerHelper.afterUpdateUser((Map<Id,User>) newUserMap ,(Map<Id,User>) oldUserMap);
        }
    }
}