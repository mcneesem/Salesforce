public class NSP_TaskTriggerHelper {
    /**
     * Iterates throught the list of new tasks/ activity and passes the required attributes to other methods.
     * @param newList List of New Task
     * @return void
     *                
     */
    public void beforeInsertDirector(List<Task> newList){
        List<User> userdetails = [SELECT id, NSP_Sales_Office__c from User where id = : UserInfo.getUserId()];
        for(Task taskObj : newList){
            if(String.isBlank(taskObj.NSP_Sales_Office__c) && String.isBlank(taskObj.NSP_OneForce_External_ID__c)){
            	taskObj.NSP_Sales_Office__c = userdetails[0].NSP_Sales_Office__c;
            }
        }
        
            
    }	

        /**
* Iterates throught the task/activity map and identifies the records that needs to worked based on various criterias.
* @param taskNewMap of New tasks. 
* @param taskOldMap of Old taska. 
* @return void             
*                
*/
    
public void beforeUpdateDirector(Map<Id, Task> taskNewMap,Map<Id, Task> taskOldMap){
    List<User> userdetails = [SELECT id, NSP_Sales_Office__c from User where id = : UserInfo.getUserId()];
    for(Id taskId : taskNewMap.keySet()){
        if(String.isBlank(taskNewMap.get(taskId).NSP_Sales_Office__c) && String.isBlank(taskNewMap.get(taskId).NSP_OneForce_External_ID__c)){
            taskNewMap.get(taskId).NSP_Sales_Office__c = userdetails[0].NSP_Sales_Office__c;
        }
    }
     
    
}   
}