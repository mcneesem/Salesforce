({
	onInit : function(component, event, helper) {
		var action = component.get("c.getGuidanceForSuccessMessages");
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var guidanceForSuccessMdtRecords = response.getReturnValue();                
                component.set("v.guidanceForSuccessMdtRecords", guidanceForSuccessMdtRecords);
                if(component.get("v.guidanceForSuccessMdtRecords")!=null){
                    helper.setGuidanceMessages(component, component.get("v.opportunityRecord"));            
                }
            }
            
        });
        
        $A.enqueueAction(action);
    },
    
    onRecordChange : function(component, event, helper){
        if(component.get("v.guidanceForSuccessMdtRecords")!=null){
            helper.setGuidanceMessages(component, component.get("v.opportunityRecord"));            
        }
    }
})