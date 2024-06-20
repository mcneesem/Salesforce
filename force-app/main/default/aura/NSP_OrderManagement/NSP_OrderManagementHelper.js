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
                    //Vaibhav Jetli 7th june 2024 start    
                    }else if(component.get("v.optionSelected")=='Amendment/Supplemental'){
                        console.log('Amendment/Supplemental selected');
                        var validateOrder = component.get('c.checkAmendmentConditionsApex');
                        console.log('validate order found');

                        validateOrder.setParams({
                            "contractId" :selectedContractId
                        });
                        console.log('validate order params set');

                        validateOrder.setCallback(this,function(resp){

                            var stateOrder = resp.getState();
                            if(stateOrder === "SUCCESS"){
                                var status = resp.getReturnValue();
                                console.log('status = ' + status);
                                if(status == false){
                                    //show error
                                    var errorMessage = 'Amendment transaction is not allowed as there is an open order for the same product type. Please reach out to Finance for assistance';
                                    component.find('notifLib').showNotice({
                                        "variant": "error",
                                        "header": "Amendment not allowed!",
                                        "message": errorMessage,
                                        closeCallback: function() {
                                            alert('You closed the alert!');
                                        }
                                    });
                                    
                                }else{
                                    var urlEvent1 = $A.get("e.force:navigateToURL");
                                    urlEvent1.setParams({
                                        "url": "/apex/sbqq__AmendContract?scontrolCaching=1&id="+component.get("v.selectedRow")[0].Id
                                });
                                urlEvent1.fire();
                            }

                            }if(stateOrder === "ERROR"){
                                component.find('notifLib').showNotice({
                                    "variant": "error",
                                    "header": "Some error occurred!",
                                    "message": validateOrder.getError(),
                                });
                            }


                        });
                        $A.enqueueAction(validateOrder);
                    }
                    //Vaibhav Jetli 7th june 2024 End
                    else if(/*component.get("v.optionSelected")=='Amendment/Supplemental' 
                            || */component.get("v.optionSelected")==='Supplemental Only' 
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