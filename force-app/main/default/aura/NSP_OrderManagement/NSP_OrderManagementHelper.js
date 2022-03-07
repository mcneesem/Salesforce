({
    getContractRecord : function(component, event, helper) {        
        var action=component.get('c.getContractRecord');
        action.setParams({
            "recordId": component.get("v.recordId")
        });   
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var rows = response.getReturnValue();
                if(rows.length!=0){
                    component.set("v.accName", rows[0].Account.Name);
                }
               
              const options = [];
                 options.push({'label': 'Amendment/Supplemental', 'value': 'Amendment/Supplemental'});//Add-on
                 options.push({'label': 'Supplemental Only', 'value': 'Supplemental Only'});//Add-on
                 options.push({'label': 'Termination', 'value': 'Termination'});//Add-on
                component.set('v.options',options);   
                
            }
        });
        $A.enqueueAction(action); 
    },
    getCurrentUserInfo : function(component, event, helper) {
        var action=component.get('c.getCurrentUserInfo');
        action.setParams({});   
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                const options = [];
                 options.push({'label': 'Renewal', 'value': 'Renewal'});
                 options.push({'label': 'AddOn', 'value': 'AddOn'});
                 options.push({'label': 'Renewal-AddOn', 'value': 'Renewal-AddOn'});
                component.set('v.options',options);            
            }
        });
        $A.enqueueAction(action); 
    },
   
    
	  handleTransactionTypeSelect : function(component, event, helper) { 
          
        
        if(component.get("v.optionSelected")!='undefined'){
            //component.set('v.spinner',true);
            
           var selectedContractId = component.get("v.selectedContractId");  
           var transactionType=component.get("v.optionSelected");
           var action=component.get('c.updateContract');           
            action.setParams({
                "contractId":selectedContractId,
                "transactionType":transactionType,
            });   
            action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {                        
                    component.set('v.spinner',false);
                    if(component.get("v.optionSelected")==='Renewal' || component.get("v.optionSelected")==='Renewal-AddOn'){                
                        var toastEvent = $A.get("e.force:showToast");
                        var message = '';
                        toastEvent.setParams({
                            "title": "Success!",
                            "type" : 'success',                           
                            "message": message
                        });
                        toastEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }
                    else if(component.get("v.optionSelected")=='Amendment/Supplemental' 
                            || component.get("v.optionSelected")==='Supplemental Only' 
                            || component.get("v.optionSelected")==='Termination'){
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({ 
                            "url": "/apex/sbqq__AmendContract?scontrolCaching=1&id="+component.get("v.selectedRow")[0].Id
                        });
                        urlEvent.fire();
                    }
                }
                if (state === "ERROR") { 
                    component.set('v.spinner',false);
                    var toastEvent_error = $A.get("e.force:showToast");
                    toastEvent_error.setParams({
                        "title": "Error!",
                        "type" : 'error',                           
                        "message":'' 
                    });
                    toastEvent_error.fire();
                    $A.get("e.force:closeQuickAction").fire();
                }                    
            });
            $A.enqueueAction(action); 
        }
    },
	
	
	
	
    
    
    
    
})