({
    doInit : function(component, event, helper) {

      let pageRef =  component.get("v.pageReference");
      let parentID ='' ;
        if(pageRef != null && pageRef != ''){
            let state = pageRef.state; // state holds any query params
            let base64Context = state.inContextOfRef;
            // For some reason, the string starts with "1.", if somebody knows why, this solution could be better generalized.
            if (base64Context.startsWith("1\.")) {
                base64Context = base64Context.substring(2);
            }
            let addressableContext = JSON.parse(window.atob(base64Context));
            parentID = addressableContext.attributes.recordId;
        }
        component.set("v.parentId", parentID);

        window.addEventListener("popstate", $A.getCallback(function () {
            var navEvt;

            if(parentID !=null && parentID != '' ){
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
                    "scope": "Case"
                });
            }
                navEvt.fire();
            }));

            window.addEventListener("popstate", ()=>{
                // location.reload(true);
                window.location.href = window.location.href ;
                eval("$A.get('e.force:refreshView').fire();");
            });
    },

    onPageReferenceChanged: function(cmp, event, helper) {
        $A.get('e.force:refreshView').fire();
    },
    // Added as part of DF-03869 to close the case create tab once the case is created
    handleCloseConsoleTab: function (cmp, event) {
        var workspaceAPI = cmp.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({ tabId: focusedTabId });
        });
    },

})

