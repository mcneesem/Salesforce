({
    
    checkValidContract : function (component, event, helper) {
        var action = component.get("c.checkValidContractForReProcess");
        action.setParams({ contractId : component.get("v.recordId") });
        
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
                    component.set('v.spinner',true); 
                helper.callContractReprocess(component, event, helper);
                }
                else {
                     $A.get("e.force:closeQuickAction").fire();
                	toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": "This Contract is not valid for reprocessing."
                	});
               		 component.set('v.spinner',false); 
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
                component.set('v.spinner',false); 
                toastEvent.fire();
            }
        
        });
        
        $A.enqueueAction(action);
        
    },
    
    callContractReprocess : function(component, event, helper) {

        var action = component.get("c.callReProcessContract");
        action.setParams({ contractId : component.get("v.recordId") });

        action.setCallback(this, function(response) {
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");

            if (state === "SUCCESS") {
                component.set('v.spinner',false); 
                $A.get("e.force:closeQuickAction").fire();
                toastEvent.setParams({
                        title: "Success!",
                        type: "Success",
                        message : "Request processed successfully..!!",
                });
                component.set('v.spinner',false); 
                toastEvent.fire();
            }
            else  {
                $A.get("e.force:closeQuickAction").fire();
                toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": "Please contact your administrator."
                });
                component.set('v.spinner',false); 
                toastEvent.fire();
            }
        
        });
        
        $A.enqueueAction(action);

    }
})