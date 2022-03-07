({
    // This method will be used to check user validation.
	doInit : function(component, event, helper) {
		//helper.callContractReprocess(component, event, helper);
        //component.set('v.loaded', !component.get('v.loaded'));
        helper.checkValidContract(component, event, helper);
	},
    // This method will close the pop up.
    closePopUp : function(component, event, helper) {
    	$A.get("e.force:closeQuickAction").fire();
    },
  
})