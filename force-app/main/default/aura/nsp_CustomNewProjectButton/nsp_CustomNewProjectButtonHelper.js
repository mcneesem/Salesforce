({
    //Create standard record method
    showCreateRecordScreen : function (component, event, helper) {

        var recTypeId = component.get("v.pageReference").state.recordTypeId;
        var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": 'pse__Proj__c',
            "recordTypeId": recTypeId,
        });
        createRecordEvent.fire();
    },
    //Show error mehtod
    showError : function() {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Error',
            message:'You cannot create a new project. Please click Create Project from Template button.',
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    //Show error mehtod
    navigateBackToList : function(component,event) {
        var pageReference = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'pse__Proj__c',
                actionName: 'home'
            }
        };
        var navService = component.find("navService");
        navService.navigate(pageReference);
    },
})