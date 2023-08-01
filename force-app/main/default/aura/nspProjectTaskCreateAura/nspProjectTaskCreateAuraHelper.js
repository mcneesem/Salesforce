({
    getProjectFromProjectTask : function(cmp, event, helper, projectTaskId) {
        var action = cmp.get("c.getProjectIdFromProjectTask");     
        action.setParams({ projectTaskId : projectTaskId});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var getProjectId = response.getReturnValue();
                cmp.set("v.parentId", getProjectId);
            } else if (state =="ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title": error,
                            "message": errors[0].message
                        });
                        resultsToast.fire();
                    }
                } else {
                    var resultsToastError = $A.get("e.force:showToast");
                    resultsToastError.setParams({
                        "title": error,
                        "message": "Error Occured"
                    });
                    resultsToastError.fire();
                }
            }
        });
        $A.enqueueAction(action);
    }
})