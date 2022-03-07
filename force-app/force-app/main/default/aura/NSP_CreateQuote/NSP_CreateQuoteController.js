({
    // This method will be used to check user validation.
	doInit : function(component, event, helper) {
		helper.checkValidation(component, event, helper);
	},
    // This method will close the pop up.
    closePopUp : function(component, event, helper) {
    	$A.get("e.force:closeQuickAction").fire();
    },
  
})