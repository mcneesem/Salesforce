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
        
        updateActivitySales(newList,null);
    }   
    public void afterInsertDirector(List<Task> newList, Map<Id, Task> taskNewMap){ 
        updateActivityDate(newList,null); 
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
    updateActivitySales(taskNewMap.values(),taskOldMap);
   }   
/**
    * Iterates throught the list of new Events and passes the required attributes to other methods.
    * @param taskNewMap Map of New Task. 
    * @param taskOldMap Map of Old Task.   
    * @return void             
    *                
    */
        
    public void afterUpdateDirector(Map<Id, Task> taskNewMap, Map<Id, Task> taskOldMap){ 
        System.debug('==afterUpdateDirector=='); 
        updateActivityDate(taskNewMap.values(),taskOldMap);
    }
    /**
* Method Name : updateActivityDate 
* Description : Method to update last activity date on all related leads with same DUNS.
* Date : 31/03/2021
* @param newList List of New Event. 
* @param eventOldMap Map of Old Event.   
* @return void  
*/
public void updateActivityDate(List<Task> newList,Map<Id,Task> eventOldMap){
    Set < Id > leadIdSet = new Set < Id > ();
    List < Lead > leadResult = new List<Lead> ();
    List < Lead > leadWithDuns = new List<Lead> ();
    Map < String, Date > lastActivityDateMap = new Map < String, Date > ();
    List < Lead > leadToUpdate = new List<Lead> ();
    for(Task event : newList){
        Task oldEvent = eventOldMap != null ? eventOldMap.get(event.Id):null;
        if((Trigger.isInsert || event.Status != oldEvent.Status) && event.Status == NSP_SalesConstants.COMPLETED && event.WhoId!= null)
        leadIdSet.add(event.WhoId);
    }
    if(!leadIdSet.isEmpty()){
        leadResult = [SELECT Id, Salutation, FirstName, MiddleName, LastName, NSP_Parent_Lead__c, DNBoptimizer__DNB_D_U_N_S_Number__c,LastActivityDate FROM Lead WHERE Id IN: leadIdSet];
        if(!leadResult.isEmpty()) {
            for(Lead leadObj :leadResult){
                if(leadObj.LastActivityDate != null && leadObj.DNBoptimizer__DNB_D_U_N_S_Number__c !=null) {
                    lastActivityDateMap.put(leadObj.DNBoptimizer__DNB_D_U_N_S_Number__c,leadObj.LastActivityDate);
                }
            }
            if(!lastActivityDateMap.isEmpty()) {
                leadWithDuns = [SELECT Id, Salutation, FirstName, NSP_Last_Activity__c, LastName, NSP_Parent_Lead__c, DNBoptimizer__DNB_D_U_N_S_Number__c,LastActivityDate FROM Lead WHERE DNBoptimizer__DNB_D_U_N_S_Number__c IN: lastActivityDateMap.keySet()];
                Lead lastActive = [SELECT LastActivityDate FROM Lead WHERE DNBoptimizer__DNB_D_U_N_S_Number__c IN: lastActivityDateMap.keySet() AND LastActivityDate != null ORDER BY LastActivityDate DESC LIMIT 1];
                if(!leadWithDuns.isEmpty()){
                    for(Lead leadObject : leadWithDuns){
                         leadObject.NSP_Last_Activity__c = lastActive.LastActivityDate;
                         leadToUpdate.add(leadObject);
                       }
                }
            }
        }
    }
    try{
        if(!leadToUpdate.isEmpty()){
            update leadToUpdate;
        }
    }
    catch(Exception ex){
        NSP_ErrorLogHandler.logSaveException('NSP_EventTriggerHelper', 'updateActivityDate', ex.getMessage());
    }
}
    
     /**
* Method Name : updateActivitySales 
* Description : Method to update sales region, sales devison and sales office.
* Date : 08/09/2022
* @param newList List of New Task. 
* @param OldTaskMap Map of Old Task.   
* @return void  
*/

public void updateActivitySales(List<Task> newList,Map<Id,Task> OldTaskMap){
    
    set<Id> ownerIdSet = new set<Id>();
    for(Task newTask : newList)
    {
        Task oldTask = OldTaskMap != null ? OldTaskMap.get(newTask.Id):null;
        
        if(Trigger.isInsert || newTask.OwnerId != oldTask.OwnerId )
        {
            ownerIdSet.add(newTask.ownerId);    
        }
    }
    
    if(ownerIdSet.Size() > 0)
    {
        Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user where Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
        system.debug('userIdMap '+userIdMap);
        for(Task newTask : newList)
        {
            Task oldTask = OldTaskMap != null ? OldTaskMap.get(newTask.Id):null;
            
            if(Trigger.isInsert || newTask.OwnerId != oldTask.OwnerId )
            {
                if(userIdMap.containsKey(newTask.ownerId))
                {
                    user eachUser = userIdMap.get(newTask.OwnerId);
                    newTask.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                    newTask.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newTask.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                }                   
            }
        }    
    }
  }  
    
}