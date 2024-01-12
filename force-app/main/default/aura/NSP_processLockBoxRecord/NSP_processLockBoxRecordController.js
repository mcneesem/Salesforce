({
    // This method will be used to check record validation.
	doInit : function(component, event, helper) {
        helper.checkValidRecord(component, event, helper);
	},
    // This method will close the pop up.
    closePopUp : function(component, event, helper) {
    	$A.get("e.force:closeQuickAction").fire();
    },
})