({
    onPageReferenceChanged: function(cmp, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    
    showModal : function (component, event, helper) {
       
        var inputVariables = [];
        var modalBody;
        var modalFooter;
        var header = "New Account Group";
        var flowName = "New_Account_Group";
        $A.createComponents([
            ["c:NSP_Modal",{  inputVariables : inputVariables, flowName: flowName }] ],
                            function(content, status){
                                if (status === "SUCCESS") {
                                    modalBody = content[0];
                                    modalFooter = content[1];
                                    component.find('overlayLibModal').showCustomModal({
                                        header: header,
                                        body: modalBody,
                                        footer: modalFooter,
                                        showCloseButton: true,
                                        cssClass:'slds-modal_small slds-backdrop',
                                        closeCallback: function() {
                                            var a = component.get('c.nagivateToRecord');
                                            $A.enqueueAction(a);          
                                        }
                                    })
                                }
                            }
                           );
    },
    nagivateToRecord : function(component, event, helper) {
        //navigate to recordId related list
        if(component.get("v.recordId")){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": component.get("v.recordId"),
                "slideDevName": "related"
            });
            navEvt.fire();    
        }else{
            //navigate to Listview
            var navEvent = $A.get("e.force:navigateToList");
            navEvent.setParams({
                "listViewName": "All",
                "scope": "NSP_Account_Group__c"
            });
            navEvent.fire();
        }
    }
})