({
    doInit : function(component, event, helper) {
        helper.getPicklistValues(component, event);
        helper.getStatePicklistValues(component, event);
    },
    
    handleClick : function(component, event, helper) {
        
        var allValid = [].concat(component.find('fieldId')).reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && !inputCmp.get('v.validity').valueMissing;
        }, true);
        if (allValid) {

             helper.saveLead(component, event);
           
        }	
        
    },
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
    },
})