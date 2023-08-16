({
    onPageReferenceChanged: function(cmp, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    
    showModal : function (component, event, helper) {
        let pageRef =  component.get("v.pageReference");
        let parentID ='' ;
        if(pageRef != null && pageRef != ''){
            let state = pageRef.state; // state holds any query params
           const relatedId = state.c__relatedId;
           if(relatedId){
            parentID = relatedId;
           }
           else{
            let base64Context = state.inContextOfRef;
            /*
             	*Get page parameters encoded recordId
                *recordId is converted from base64 to text.
            */
            if (base64Context.startsWith("1\.")) {
                base64Context = base64Context.substring(2);
            } 
            let addressableContext = JSON.parse(window.atob(base64Context));
                parentID = addressableContext.attributes.recordId;
           }
        }
        component.set("v.recordId",parentID);
        var inputVariables = [
            { name : "recordId", type : "String", value: parentID }
        ];
        var modalBody;
        var modalFooter;
        var flowName =  'New_Account_Group_Member';
        var header =  'New Account Group Member';
        //Create dynamic Modal and passing parameters
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
                                        cssClass:'slds-modal_medium slds-backdrop',
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
        //navigate to record
        if(component.get("v.recordId")){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": component.get("v.recordId"),
                "slideDevName": "related"
            });
            navEvt.fire();    
        }else{
            //navigate to relatedList
            var navEvent = $A.get("e.force:navigateToList");
            navEvent.setParams({
                "listViewName": "All",
                "scope": "Account"
            });
            navEvent.fire();
        }
    }
})