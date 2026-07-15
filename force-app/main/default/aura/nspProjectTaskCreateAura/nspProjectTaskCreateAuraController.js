({
    doInit: function(cmp, event, helper) {
        let pageRef = cmp.get("v.pageReference");
        let parentID = '';
        if(pageRef != null && pageRef != '') {
            let state = pageRef.state; // state holds any query params
            let base64Context = state.inContextOfRef;
            if(base64Context != undefined) {
                if(base64Context.startsWith("1\.")) {
                    base64Context = base64Context.substring(2);
                }
                let addressableContext = JSON.parse(window.atob(base64Context));
                parentID = addressableContext.attributes.recordId;
            }
            if(parentID !== '' && parentID !== undefined){
                if(parentID.substring(0, 3) === 'a35'){
                    cmp.set("v.projectTaskParentId", parentID);
                    helper.getProjectFromProjectTask(cmp, event, helper, cmp.get("v.projectTaskParentId"));
                }else if(parentID.substring(0, 3) === 'a2o'){
                   cmp.set("v.parentId", parentID); 
                }
            }
        }
        window.addEventListener("popstate", $A.getCallback(function() {
            var navEvt;
            if(parentID != null && parentID != '') {
                navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    recordId: parentID,
                    slideDevName: "detail",
                    isredirect: true
                });
            } else {
                navEvt = $A.get("e.force:navigateToList");
                navEvt.setParams({
                    "listViewId": 'Recent',
                    "listViewName": null,
                    "scope": "pse__Project_Task__c"
                });
            }
            navEvt.fire();
        }));
        window.addEventListener("popstate", () => {
            window.location.href = window.location.href;
            eval("$A.get('e.force:refreshView').fire();");
        });
    },
    onPageReferenceChanged: function(cmp) {
        $A.get('e.force:refreshView').fire();
    }
})