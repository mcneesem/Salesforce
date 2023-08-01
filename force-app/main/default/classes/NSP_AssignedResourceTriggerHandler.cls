public class NSP_AssignedResourceTriggerHandler extends NSP_TriggerAction implements NSP_ITriggerHandler {
    //Use this variable to disable this trigger from transaction.
    public static Boolean TriggerDisabled = false;
    
    /**
     * Represents whether the trigger is disabled or not.
     * @param N/A.
     * @return Boolean
     *
     */

    public Boolean isDisabled() {
        return TriggerDisabled;
    }

    /**
     * Handles before insert for AssignedResource.
     * @param newList List of New AssignedResource.
     * @return void
     *
     */
    public void beforeInsert(List < sObject > newList) {
    }

    /**
     * Handles after insert for AssignedResource.
     * @param newList List of New AssignedResource.
     * @param newMap Map of New AssignedResource.
     * @return void
     *
     */
    public void afterInsert(List < sObject > newList, Map < Id, sObject > newMap) {

    }

    /**
     * Handles before update for AssignedResource.
     * @param newMap Map of New AssignedResource.
     * @param oldMap Map of Old AssignedResource.
     * @return void
     *
     */
    
    public void beforeUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
        
    }
    
    /**
     * Handles after update for AssignedResource.
     * @param newMap Map of New AssignedResource.
     * @param oldMap Map of Old AssignedResource. 
     * @return void           
     *                
     */
    
    public void afterUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
        NSP_AssignedResourceTriggerHelper.afterUpdateDirector((Map < Id, AssignedResource > ) newMap, (Map < Id, AssignedResource > ) oldMap);
    } 
    
    /**
    * Handles before delete for AssignedResource.
    * @param oldList List, oldMap of New AssignedResource.
    * @return void
    */
    public void beforeDelete(List < sObject > oldList, Map < Id, sObject > oldMap) {}
    
    public void afterDelete(List < sObject > oldList, Map < Id, sObject > oldMap) {}
}