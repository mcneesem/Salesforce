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
    checkPermission: function(component, event, helper){
        let action = component.get("c.hasTerminationPermission");
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.hasTerminationPermission", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    isLastDayOfMonth: function(date) {
        if (!(date instanceof Date) || isNaN(date)) {
            console.warn('Invalid date passed to isLastDayOfMonth:', date);
            return false;
        }
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const nextMonth = new Date(date.getFullYear(), date.getMonth() + 1, 1);
        const lastDayOfMonth = new Date(nextMonth - 1);
        const isLastDay = date.getDate() === lastDayOfMonth.getDate();
        return isLastDay;
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
    processContractTermination : function(component, event, helper) {
        let toastEvent = $A.get("e.force:showToast");
        let message = '';
        let urlEvent = $A.get("e.force:navigateToURL");
        let selectedContractId = component.get("v.selectedContractId");
        let terminationDate = component.get("v.terminationDate");
        let hasTerminationPermission = component.get("v.hasTerminationPermission");
        let terminationAction = component.get('c.runContractAutoTermination');
        if (hasTerminationPermission) {
            if (terminationDate) {
                let parts = terminationDate.split('-');
                let parsedDate = new Date(parts[0], parts[1] - 1, parts[2]);
                if (helper.isLastDayOfMonth(parsedDate)) {
                    terminationAction.setParams({
                        "contractId": selectedContractId,
                        "terminationDate": parsedDate
                    });

                    terminationAction.setCallback(this, function(resp) {

                        let stateOrder = resp.getState();
                        if (stateOrder === "SUCCESS") {
                            let status = resp.getReturnValue();
                            console.log('status = ' + status);
                            component.set('v.section', '');
                            component.set("v.showMessageModal", true);

                        }
                        if (stateOrder === "ERROR") {
                            component.find('notifLib').showNotice({
                                "variant": "error",
                                "header": "Some error occurred!",
                                "message": terminationAction.getError(),
                            });
                        }


                    });
                    $A.enqueueAction(terminationAction);
                } else {
                    message = 'Termination date must be at the end of the month.';
                    toastEvent.setParams({
                        "title": "ERROR",
                        "type": 'ERROR',
                        "message": message
                    });
                    toastEvent.fire();
                }
            } else {
                message = 'Please Enter value for Termination Date';
                toastEvent.setParams({
                    "title": "ERROR",
                    "type": 'ERROR',
                    "message": message
                });
                toastEvent.fire();
            }
        } else {
            urlEvent.setParams({
                "url": "/apex/sbqq__AmendContract?scontrolCaching=1&id=" + component.get("v.selectedRow")[0].Id
            });
            urlEvent.fire();
        }

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
                let state = response.getState();
                let toastEvent = $A.get("e.force:showToast");
                let message = '';
                let urlEvent = $A.get("e.force:navigateToURL");
                if (state === "SUCCESS") {
                    component.set('v.spinner',false);
                    if(component.get("v.optionSelected")==='Renewal' || component.get("v.optionSelected")==='Renewal-AddOn'){
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
                                    urlEvent.setParams({
                                        "url": "/apex/sbqq__AmendContract?scontrolCaching=1&id="+component.get("v.selectedRow")[0].Id
                                });
                                urlEvent.fire();
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
                            ){
                        urlEvent.setParams({
                            "url": "/apex/sbqq__AmendContract?scontrolCaching=1&id="+component.get("v.selectedRow")[0].Id
                        });
                        urlEvent.fire();
                    }
                    else if(component.get("v.optionSelected")==='Termination'){
                        helper.processContractTermination(component,event,helper);
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