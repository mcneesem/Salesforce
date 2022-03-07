({
      doInit : function(component, event, helper) {
          
          helper.createTaskRecord(component, event, helper);
       
    },
    closeQuickAction : function(component, event, helper) {
        var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
    }
})