/**
 * Represents the NSP_CampaignTriggerHandler.
 * Created By: Rahul Singh
 * Date:8/10/2022
 */
public class NSP_CampaignTriggerHandler implements NSP_ITriggerHandler {
 //Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;
    public static Boolean runOnce = true;
 /**
   * Represents whether the trigger is disabled or not
   * @param N/A.  
   * @return Boolean             
   *                
   */     
    
    public Boolean isDisabled(){
        return TriggerDisabled;
    }
    
 
        /**
   * Handles before insert for Campaign.
   * @param newList List of New Campaign. 
   * @return void             
   *                
   */
    public void beforeInsert(List<sObject> newList) {
        if(NSP_CampaignTriggerHandler.runOnce){
            NSP_CampaignTriggerHelper  campaignTriggerHelperObject =  new NSP_CampaignTriggerHelper();  
            campaignTriggerHelperObject.beforeInsertDirector((List<Campaign>)newList);
        }
    }
    
       /**
   * Handles after insert for Campaign
   * @param newList List of New Campaign.
   * @param newMap Map of New Campaign. 
   * @return void             
   *                
   */
  public void afterInsert(List<sObject> newList , Map<Id, sObject> newMap) {
   
}
    
  /**
   * Handles before update for Campaign
   * @param newMap Map of New Campaign.
   * @param oldMap Map of Old Campaign. 
   * @return void             
   *                
   */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
       
    }
    

   /**
   * Handles after update for Campaign
   * @param newMap Map of New Campaign.
   * @param oldMap Map of Old Campaign. 
   * @return void             
   *                
   */
  public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
  
}
/**
     * Handles before delete.
     * @param oldList List, OldMap Map.
     * @return void
     * Added beforeDelete method as this is referred in in NSP_ITriggerHandler
    **/
    public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }

    /**
   * Handles before delete for Campaign
   * @param oldList Map of old Campaign.
   * @param oldMap Map of old Campaign. 
   * @return void             
   *                
   */
   public void afterDelete(List<sobject> oldList, Map<Id, sObject> oldMap){
        
    }

}