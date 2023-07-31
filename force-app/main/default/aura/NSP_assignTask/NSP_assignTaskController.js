({
    doInit : function(component, event, helper) {
		var action = component.get("c.projectTaskAssignment");
        action.setParams({ projectId : component.get("v.recordId") });
        $A.enqueueAction(action);
        $A.get("e.force:closeQuickAction").fire();  
    }
})