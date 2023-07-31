({
    doInit : function(component, event, helper) {
        let getProfileDetails = component.get("c.getIsUserSystemAdmin");
        getProfileDetails.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {                 
                component.set("v.isAllowedDelete",response.getReturnValue());
            }
        });
        $A.enqueueAction(getProfileDetails);
    },
    handleDeleteRecord: function(component, event, helper) {
        helper.showSpinner(component,'deleteSpinner');
        let projectRecId = component.get("v.recordId");
        let deepDeleteRecords = component.get("c.deepDeleteRecords");
        deepDeleteRecords.setParams({
            projectId : projectRecId
        });
        deepDeleteRecords.setCallback(this, function(response) {
            helper.hideSpinner(component,'deleteSpinner');
            let state = response.getState();
            // NOTE: If you want a specific behavior(an action or UI behavior) when this action is successful 
            // then handle that in a callback (generic logic when record is changed should be handled in recordUpdated event handler)
            if (state === "SUCCESS") {
                // record is deleted
                var navEvent = $A.get("e.force:navigateToList");
                navEvent.setParams({
                    "listViewId": "Recent",
                    "listViewName":"Recent",
                    "scope": "pse__Proj__c"
                });
                navEvent.fire();
                // Close the action panel
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
                
            }  else if (state === "ERROR") {
                var errorsmessagecorrect = deepDeleteRecords.getError();
                var errormsg = errorsmessagecorrect[0].message
                component.set("v.recordError",errormsg);
            }            
        });
        $A.enqueueAction(deepDeleteRecords);
    },
})