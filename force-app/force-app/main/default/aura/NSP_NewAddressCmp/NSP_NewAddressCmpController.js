({
    // Init method to call dependent picklist 
	doInit: function(component, event, helper) {
       helper.getDependentPicklist(component, event);
       helper.getRecordTypeId(component,event);
    },
    
    // Method to get selected country state value
    getStateValues : function(component, event,helper){
        helper.getStateValues(component, event);
    },
    
    // Method to save the address record
    saveRecord :  function(component, event,helper){
        helper.handleValidationAndSave(component, event);
	},
    
    // Method to navigate to List view
    gotoURL :  function(component, event,helper){
        $A.get("e.force:closeQuickAction").fire()
        component.set("v.toggleModal",false);
		//helper.gotoURL(component, event);
	}
})