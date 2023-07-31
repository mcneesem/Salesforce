/**
* Represents the NSP_ContentVersionTriggerHelper handler.
* CreatedDate : 10/1/2022
*/
public class NSP_ContentVersionTriggerHelper {
      /**
    * Iterates throught the task/activity map and identifies the records that needs to worked based on various criterias.
    * @param taskNewMap of New tasks. 
    * @param taskOldMap of Old taska. 
    * @return void             
    *                
    */
    public void beforeInsertDirector(List<ContentVersion> newList){        
        for(ContentVersion conVer : newList){
            conVer.NSP_Last_Assigned_Owner__c = conVer.OwnerId; // Added as part of STY-01774
        } 
    }
    /**
* Iterates throught the Event map and identifies the records that needs to worked based on various criterias.
* @param eventNewMap Map of New Event. 
* @param eventOldMap Map of Old Event. 
* @return void             
*                
*/   
    public void beforeUpdateDirector(Map<Id, ContentVersion> conVerNewMap, Map<Id, ContentVersion> conVerOldMap){
        for(ContentVersion conVer : conVerNewMap.values()){
            conVer.NSP_Last_Assigned_Owner__c = conVer.OwnerId; // Added as part of STY-01774
        }
        
    }    
    
}