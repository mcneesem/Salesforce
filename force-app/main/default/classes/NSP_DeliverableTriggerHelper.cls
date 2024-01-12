/* Represents the Deliverable trigger helper which handles all the logic.
* 
* Modification History:
* -------------------------------------------------------------------------------------
* author           | Date              | Description
* -------------------------------------------------------------------------------------
* Jatin Ahuja       6/9/2022             Iterates through Deliverables
* Harsha Khiroya    28/02/2022           Added code for Additional Text & moved common code to other method
* 
*/
public class NSP_DeliverableTriggerHelper {
    /**
    * Iterates throught the list of new Deliverables and passes the required attributes to other methods.
    * @param deliverables List of New Deliverables.  
    * @return void
    */
    public void beforeInsertDirector(List<NSP_Deliverable__c> deliverables){
        updateDeliverables(deliverables);
        for(NSP_Deliverable__c deliverable: deliverables){
            if(deliverable.NSP_Additional_Detail__c != null){
                updateAdditionalDetails(deliverables);
            } 
        }  
    }

    /**
    * Iterates throught the list of new Deliverables and passes the required attributes to other methods.
    * @param newMAp List of New Deliverables.  
    * @param oldMap List of Old Deliverables.
    * @return void      
    *
    */
    public void beforeUpdateDirector(Map<Id, NSP_Deliverable__c> newMap, Map<Id, NSP_Deliverable__c> oldMap){
        List<String> deliverableNames = new List<String>();
        List<NSP_Deliverable__c> updatedDeliverables = new List<NSP_Deliverable__c>();
		List<NSP_Deliverable__c> updateForAdditionalDetails = new List<NSP_Deliverable__c>();
        
        for(NSP_Deliverable__c deliverable : newMap.values()){
            if(deliverable.NSP_Deliverable__c != oldMap.get(deliverable.Id).NSP_Deliverable__c){
	            updatedDeliverables.add(deliverable);
            }
            if(deliverable.NSP_Additional_Detail__c != null && deliverable.NSP_Additional_Detail__c != oldMap.get(deliverable.Id).NSP_Additional_Detail__c){
                updateForAdditionalDetails.add(deliverable);
            }
        }
		updateDeliverables(updatedDeliverables);
        updateAdditionalDetails(updateForAdditionalDetails);
    }
    
    /**
    * Iterates throught the list of new Deliverables and passes the required attributes to other methods.
    * @param deliverables
    * @return void 
    * added common code in separate method     
    * Last modified by : Harsha Khiroya 28/02/2023
    */
    public void updateDeliverables(List<NSP_Deliverable__c> deliverables){
        List<String> deliverableNames = new List<String>();
        for(NSP_Deliverable__c deliverable : deliverables){
            deliverableNames.add(deliverable.NSP_Deliverable__c);
        }

        Map<String, NSP_Service_Plan_Deliverable__c> deliverablePlanMap = new Map<String, NSP_Service_Plan_Deliverable__c>();
        List<NSP_Service_Plan_Deliverable__c> servicePlanDeliverables = [SELECT Name, NSP_Associated_Business_Goal__c, NSP_Business_Opportunity__c, NSP_Category__c, NSP_Sub_Category__c, NSP_Deliverable_Type__c FROM NSP_Service_Plan_Deliverable__c WHERE NAME IN :deliverableNames];
        for(NSP_Service_Plan_Deliverable__c deliverablePlan : servicePlanDeliverables){
            deliverablePlanMap.put(deliverablePlan.Name, deliverablePlan);
        }

        for(NSP_Deliverable__c deliverable : deliverables){
			NSP_Service_Plan_Deliverable__c deliverablePlan = deliverablePlanMap.get(deliverable.NSP_Deliverable__c);
            if(deliverablePlan!= null){
	            deliverable.NSP_Associated_Business_Goal__c = deliverablePlan.NSP_Associated_Business_Goal__c;
	            deliverable.NSP_Business_Opportunity__c = deliverablePlan.NSP_Business_Opportunity__c;
	            deliverable.NSP_Category__c = deliverablePlan.NSP_Category__c;
	            deliverable.NSP_Sub_Category__c = deliverablePlan.NSP_Sub_Category__c;
	            deliverable.NSP_Deliverable_Type__c = deliverablePlan.NSP_Deliverable_Type__c;
            }
        }
    }
    
    public void updateAdditionalDetails(List<NSP_Deliverable__c> deliverables){
    	for(NSP_Deliverable__c deliverable : deliverables){
        	deliverable.NSP_Additional_Details_Text__c = deliverable.NSP_Additional_Detail__c.replaceAll(';', ',\n');
        }
        
    }
}