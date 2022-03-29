({
    // Init method to call dependent picklist 
    doInit: function(component, event, helper) {
        /*  As part of DF-01393, On the load of the page, getting the page reference and the recordId of particular object */
        component.set("v.isModalOpen", true);
        var pageRef = component.get("v.pageReference");
        var state = pageRef.state; 
        var base64Context = state.inContextOfRef;
        if (base64Context.startsWith("1\.")) {
            base64Context = base64Context.substring(2);
        }
        var addressableContext = JSON.parse(window.atob(base64Context));
        component.set("v.recordId", addressableContext.attributes.recordId);
        /*  DF-01393 Ends */
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
    // Method to navigate to related List view
    gotoURL :  function(component, event,helper){
        component.set("v.toggleModal",false);
        helper.gotoURL(component, event);
    }
})