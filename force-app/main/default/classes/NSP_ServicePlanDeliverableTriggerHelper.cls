public class NSP_ServicePlanDeliverableTriggerHelper {
    /**
    * Iterates throught the list of new Service Plan Deliverables and passes the required attributes to other methods.
    * @param deliverables List of New Service Plan Deliverables.
    * @return void
    */
    public void beforeInsertDirector(List<NSP_Service_Plan_Deliverable__c> deliverables){
        try{
            List<String> deliverableNames = getPicklistValues(NSP_Deliverable__c.NSP_Deliverable__c);
            for(NSP_Service_Plan_Deliverable__c deliverable : deliverables){
                // Show error if this deliverable name is not added in the delivberable picklist.
                if(!deliverableNames.contains(deliverable.Name)){
                    deliverable.addError('Please add "'+ deliverable.Name +'" to Deliverable picklist, and Additional Detail picklist items if required, in the Deliverable Object.');
                }
            }
        } catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_ServicePlanDeliverableTriggerHelper','beforeInsertDirector',ex.getMessage());
        }
    }
    
    /**
    * Iterates throught the list of new Service Plan Deliverables and passes the required attributes to other methods.
    * @param newMap Map of New Service Plan Deliverables.
    * @param oldMap Map of Old Service Plan Deliverables.
    * @return void
    */
    public void beforeUpdateDirector(Map<Id, NSP_Service_Plan_Deliverable__c> newMap, Map<Id, NSP_Service_Plan_Deliverable__c> oldMap){
        try{
            List<String> deliverableNames = getPicklistValues(NSP_Deliverable__c.NSP_Deliverable__c);
            for(NSP_Service_Plan_Deliverable__c deliverable : newMap.values()){
                if(!deliverableNames.contains(deliverable.Name)){
					// Show error if this deliverable name is not updated in the delivberable picklist.
                    deliverable.addError('Please update "' + deliverable.Name +'" in the Deliverable picklist in Deliverable object first.');
                }
            }
        } catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_ServicePlanDeliverableTriggerHelper','beforeUpdateDirector', ex.getMessage());
        }
    }

    /**
    * Iterates throught the list of deleted Service Plan Deliverables and passes the required attributes to other methods.
    * @param deliverables List of deleted Service Plan Deliverables.
    * @return void
    */
    public void beforeDeleteDirector(List<NSP_Service_Plan_Deliverable__c> deliverables){
        try{
            List<String> deliverableNames = getPicklistValues(NSP_Deliverable__c.NSP_Deliverable__c);
            for(NSP_Service_Plan_Deliverable__c deliverable : deliverables){
                if(deliverableNames.contains(deliverable.Name)){
					// Show error if this deliverable name is not deleted from the delivberable picklist.
                    deliverable.addError(deliverable.Name + ' record can\'t be deleted. Please remove "'+ deliverable.Name +'" from Deliverable picklist in Deliverable object.');
                }
            }
        } catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_ServicePlanDeliverableTriggerHelper','beforeDeleteDirector', ex.getMessage());
        }
    }

    // Return picklist values of the given field.
    private static List<String> getPicklistValues(Schema.sObjectField field){
		List<String> pickListValuesList = new List<String>();
        // Fetch picklist values by field
		for( Schema.PicklistEntry pickListVal : field.getDescribe().getPicklistValues()){
			pickListValuesList.add(pickListVal.getLabel());
		}

		return pickListValuesList;
    }
}