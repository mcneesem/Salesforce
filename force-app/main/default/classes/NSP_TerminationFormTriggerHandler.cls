/**
* Represents the Termination Form trigger handler.
*/
public class NSP_TerminationFormTriggerHandler implements NSP_ITriggerHandler {
    // test w/ NSP_TerminationFormTriggerHelperTest (90%)
	//Use this variable to disable this trigger from transaction
    public static Boolean TriggerDisabled = false;
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
    * Handles before insert for Termination Form
    * @param newList List of New Termination Form. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
        NSP_TerminationFormTriggerHelper terminationFormTriggerHelperObject =new NSP_TerminationFormTriggerHelper();
        terminationFormTriggerHelperObject.beforeTerminationFormInsert((List<NSP_Termination_Form__c>)newList);
    }
    
    /**
    * Handles after insert for Termination Form
    * @param newList List of New Termination Form.
    * @param newMap Map of New Termination Form. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> newMap) {
        NSP_TerminationFormTriggerHelper oTerminationFormTriggerHelper =new NSP_TerminationFormTriggerHelper();
        oTerminationFormTriggerHelper.afterInsertFilter((List<NSP_Termination_Form__c>)newList,(Map<Id,NSP_Termination_Form__c>)newMap);
        oTerminationFormTriggerHelper.updateClientTermDateOnProject((List<NSP_Termination_Form__c>)newList,(Map<Id,NSP_Termination_Form__c>)newMap);
    }
    
    /**
    * Handles before update for Termination Form
    * @param newMap Map of New Termination Form.
    * @param oldMap Map of Old Termination Form. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
        NSP_TerminationFormTriggerHelper oTerminationFormTriggerHelper =new NSP_TerminationFormTriggerHelper();
        oTerminationFormTriggerHelper.updateAccountOnTerm(newMap.values(),(Map<Id,NSP_Termination_Form__c>)oldMap);
        oTerminationFormTriggerHelper.beforeTerminationFormUpdate((Map<Id,NSP_Termination_Form__c>)newMap, (Map<Id,NSP_Termination_Form__c>)oldMap);
    }
    
    
    /**
    * Handles after update for Termination Form
    * @param newMap Map of New Termination Form.
    * @param oldMap Map of Old Termination Form. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {  
        NSP_TerminationFormTriggerHelper terminationFormTriggerHelperObject =  new NSP_TerminationFormTriggerHelper(); 
        terminationFormTriggerHelperObject.afterUpdateTerminationForm(newMap.values(), (Map<Id, NSP_Termination_Form__c>) oldMap);
        // added as part of STY-03529
        NSP_TerminationFormServiceHelper terminationServiceHelper = new NSP_TerminationFormServiceHelper();
        terminationServiceHelper.updateAssetTerminationForm((Map<Id, NSP_Termination_Form__c>) newMap,(Map<Id, NSP_Termination_Form__c>) oldMap);
    }

    /**
    * Handles after delete for Termination Form.
    * @param oldList List of old Termination Form.
    * @param oldMap Map of Old Termination Form.
    * @return void             
    *                
    */
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
        
    }

    /**
* Handles before delete for Termination Form.
* @param oldList List of old Termination Form.
* @param oldMap Map of Old Termination Form.
* @return void             
*                
*/
    
public void beforeDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    
}
}