public class UserOnboardingQueuable implements Queueable {
/**
 * Handles after insert for User Onboarding asynchronously
 *                
*/
    // test w/ UserOnboardingQueuableTest (100%)
    private List<User> newUserList;
    private Map<Id,User> newUserMap;
    private Map<Id,User> oldUserMap;
    private String triggerOperation;
    
    //Constructor
    public UserOnboardingQueuable(List<User> newList, Map<Id,User> newMap , Map<Id,User> oldMap , String TriggerContext){
        this.newUserList = newList;
        this.newUserMap = newMap;
        this.oldUserMap = oldMap;
        this.triggerOperation = TriggerContext;
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
    
    // ************************ Write Error Log ************************
    @future
    public static void createErrorLog(String className, String methName, String descText){
        NSP_Error_Log__c log = new NSP_Error_Log__c();
        log.NSP_Class__c = className;
        log.NSP_Method__c = methName;
        log.NSP_Description__c = descText;
        Insert log;
    }
}