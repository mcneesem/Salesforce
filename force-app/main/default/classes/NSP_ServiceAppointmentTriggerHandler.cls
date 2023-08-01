public class NSP_ServiceAppointmentTriggerHandler extends NSP_TriggerAction implements NSP_ITriggerHandler {

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
     * Handles before insert for ServiceAppointment.
     * @param newList List of New ServiceAppointment.
     * @return void
     *
     */
    public void beforeInsert(List < sObject > newList) {
    }

    /**
     * Handles after insert for ServiceAppointment.
     * @param newList List of New ServiceAppointment.
     * @param newMap Map of New ServiceAppointment.
     * @return void
     *
     */
    public void afterInsert(List < sObject > newList, Map < Id, sObject > newMap) {

    }

    /**
     * Handles before update for ServiceAppointment.
     * @param newMap Map of New ServiceAppointment.
     * @param oldMap Map of Old ServiceAppointment.
     * @return void
     *
     */

    public void beforeUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
        NSP_ServiceAppointmentTriggerHelper.beforeUpdateDirector((Map < Id, ServiceAppointment > ) newMap, (Map < Id, ServiceAppointment > ) oldMap);
    }

    /**
     * Handles after update for ServiceAppointment.
     * @param newMap Map of New ServiceAppointment.
     * @param oldMap Map of Old ServiceAppointment. 
     * @return void           
     *                
     */

    public void afterUpdate(Map < Id, sObject > newMap, Map < Id, sObject > oldMap) {
        // added as a part of STY-01091
		NSP_ServiceAppointmentTriggerHelper.sendEmailNotifications((Map < Id, ServiceAppointment > ) newMap, (Map < Id, ServiceAppointment > ) oldMap);

        NSP_ServiceAppointmentTriggerHelper.afterUpdateDirector((Map < Id, ServiceAppointment > ) newMap, (Map < Id, ServiceAppointment > ) oldMap);
    } 
    
    /**
    * Handles before delete for ServiceAppointment.
    * @param oldList List, oldMap of New ServiceAppointment.
    * @return void
    */
    public void beforeDelete(List < sObject > oldList, Map < Id, sObject > oldMap) {
    }
    
    public void afterDelete(List < sObject > oldList, Map < Id, sObject > oldMap) {}
}