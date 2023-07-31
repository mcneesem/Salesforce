public class NSP_PayrollTriggerHandler implements NSP_ITriggerHandler {
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
    * Handles before insert for Payroll Data Sheet
    * @param newList List of New Payroll Data Sheet. 
    * @return void             
    *                
    */
    public void beforeInsert(List<sObject> newList) {
    	NSP_PayrollTriggerHelper helperObj = new NSP_PayrollTriggerHelper();
        helperObj.fieldUpdatesAfterInsertUpdate((List<NSP_Payroll__c>) newList, null, null);  	   
        helperObj.checkForGovernmentContractor((List<NSP_Payroll__c>) newList);  // Added as part of STY-03277  
        helperObj.updatePDSContactRelatedFields((List<NSP_Payroll__c>) newList, null);
        NSP_PayrollTriggerHelper.updatePDSRelatedContactFields((List<NSP_Payroll__c>) newList);
        // Developed as part of DF-DF-03251
        NSP_PayrollTriggerHelper.validatePDSInsert((List<NSP_Payroll__c>) newList);
    }
    /**
    * Handles after insert for Payroll Data Sheet
    * @param newList List of New Payroll Data Sheet.
    * @param newMap Map of New Payroll Data Sheet. 
    * @return void             
    *                
    */
    public void afterInsert(List<sObject> newList, Map<Id, sObject> oldMap) {  
        NSP_PayrollTriggerHelper.createPayrollDataSheetEventRecord(newList);
    }            

    /**
    * Handles before update for Payroll Data Sheet
    * @param newMap Map of New Payroll Data Sheet.
    * @param oldMap Map of Old Payroll Data Sheet. 
    * @return void             
    *                
    */
    public void beforeUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) {
    	NSP_PayrollTriggerHelper helperObj = new NSP_PayrollTriggerHelper();
        helperObj.fieldUpdatesAfterInsertUpdate(null, (Map<Id, NSP_Payroll__c>) newMap, (Map<Id, NSP_Payroll__c>) oldMap);
        helperObj.updatePDSContactRelatedFields((List<NSP_Payroll__c>) newMap.values(), (Map<Id, NSP_Payroll__c>) oldMap);
    }    
    /**
    * Handles after update for Payroll Data Sheet
    * @param newMap Map of New Payroll Data Sheet.
    * @param oldMap Map of Old prPayroll Data Sheetoject. 
    * @return void             
    *                
    */
    public void afterUpdate(Map<Id, sObject> newMap,Map<Id, sObject> oldMap) { 
            
    } 
    /**
    * Handles before delete for Payroll Data Sheet
    * @param oldList Map of old Payroll Data Sheet.
    * @param oldMap Map of Old Payroll Data Sheet. 
    * @return void             
    *                
    */
    public void beforeDelete(List<sObject> oldList , Map<Id, sObject> oldMap) {
        
    }

    /**
    * Handles after delete for Payroll Data Sheet
    * @param oldList List of old Payroll Data Sheet
    * @param oldMap Map of Old Payroll Data Sheet
    * @return void             
    *                
    */
    
    public void afterDelete(List<sObject> oldList,Map<Id, sObject> oldMap) {
    }
}