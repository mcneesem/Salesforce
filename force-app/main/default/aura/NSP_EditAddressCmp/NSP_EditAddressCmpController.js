({
    // Method to get the dependent picklist
    doInit: function(component, event, helper) {
        helper.getDependentPicklist(component, event,helper);
    },
    
    // Method to get selected country state value
    getStateValues : function(component, event,helper){
        helper.getStateValues(component, event);
    },
    
    // Method to save the records
    saveRecord : function(component, event,helper){
    	helper.updateRecord(component, event);
    },
    
    // Method to set the state value
    setStateValue : function(component, event,helper){

        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    	helper.getDependentPicklist(component, event, helper);
    },
    
    // Method to navigate to detail page.
    navigateToDetail : function(component, event,helper){
    	helper.navigateToDetail(component, event);
    }
})