({
	onInit : function(component, event, helper) {
        helper.setGuidanceMessages(component, component.get("v.opportunityRecord"));            
    },
    
    onRecordChange : function(component, event, helper){
        helper.setGuidanceMessages(component, component.get("v.opportunityRecord"));            
    }
})