({
    checkValidRecord : function (component, event, helper) {
        var action = component.get("c.checkValidRecordForProcess");
        action.setParams({ lockBoxId : component.get("v.recordId") });
        
         action.setCallback(this, function(response) {
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");

            if (state === "SUCCESS") {
               
                var response1= response.getReturnValue();
              /*  $A.get("e.force:closeQuickAction").fire();
                toastEvent.setParams({
                        title: "Success!",
                        type: "Success",
                        message : "Request processed successfully..!!",
                });
                component.set('v.spinner',false); 
                toastEvent.fire(); */
                if(response1) {
                    component.set('v.loaded',false); 
                helper.callprocessRecordLogic(component, event, helper);
                }
                else {
                     $A.get("e.force:closeQuickAction").fire();
                	toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": "This Lock Box Transaction is not valid for processing. Please review the details and check Ready To Convert checkbox."
                	});
               		 component.set('v.loaded',true); 
                	toastEvent.fire();
                }
            }
            else  {
                $A.get("e.force:closeQuickAction").fire();
                toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": "Please contact your administrator."
                });
                component.set('v.loaded',true); 
                toastEvent.fire();
            }
        
        });
        
        $A.enqueueAction(action);
        
    },

    callprocessRecordLogic : function(component, event, helper) {

        var action = component.get("c.callProcessLockBoxLogic");
        action.setParams({ lockBoxId : component.get("v.recordId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");

            if (state === "SUCCESS") {
                var response2= response.getReturnValue();
                component.set('v.loaded',true); 
                if(response2) {
                $A.get("e.force:closeQuickAction").fire();
                toastEvent.setParams({
                        title: "Success!",
                        type: "Success",
                        message : "Request processed successfully..!!",
                });
                component.set('v.loaded',true); 
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
                }
                else {
                    $A.get("e.force:closeQuickAction").fire();
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": "Error processing request. Please contact your administrator."
                });
                component.set('v.loaded',true); 
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
                }
            }
            else  {
                $A.get("e.force:closeQuickAction").fire();
                toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": "Please contact your administrator."
                });
                component.set('v.loaded',true); 
                toastEvent.fire();
            }
        
        });
        
        $A.enqueueAction(action);

    }


})