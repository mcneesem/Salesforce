({
    doInit : function(component, event, helper) {
        helper.getContractRecord(component, event, helper);
    },
    handleSelection : function(component, event, helper) {
        var changeValue = event.getParam("value");
        component.set("v.optionSelected",changeValue);
        (changeValue!=undefined)?component.set('v.isDisable',false):component.set('v.isDisable',true);
        if(changeValue && changeValue == 'Amendment/Supplemental'){
            component.set("v.displaystring","Products Upsells/Downgrade");
        }
        else if(changeValue && changeValue == 'Supplemental Only'){
            component.set("v.displaystring",'Additional Services/Training');
        } 
        else if(changeValue && changeValue == 'Termination'){
            component.set("v.displaystring",'Full termination of products');
        } 
         component.set("v.displayhelp",true);
    },
   handleContractSelect : function(component, event, helper) {
		if(component.get("v.selectedRow").length>0){
		//	component.set('v.spinner',true);
			component.set("v.selectedContractId",component.get("v.selectedRow")[0].Id);/////////////
            component.set('v.section','Option');
 
        } else{
          //display message to select an active contract
        }
       
    },
    
     handleTransactionTypeSelection : function(component, event, helper) {
        helper.handleTransactionTypeSelect(component, event, helper);
         
    },
    handleNext : function(component, event, helper) {
        if(component.get("v.optionSelected")=='Renewal'){
            var action=component.get('c.validateUserforRenewal');
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    var validUser = response.getReturnValue();
                    if(validUser){
                        component.set('v.section','MSAContract');
                    }
                    else{
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "type" : 'error',                           
                            "message":''
                        });
                        toastEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();                    
                    }
                }
            });
            $A.enqueueAction(action); 
        }
        else{
            component.set('v.section','MSAContract');
        }
    },
    handleCancel : function(component, event, helper) {
       $A.get("e.force:closeQuickAction").fire();
    },

})