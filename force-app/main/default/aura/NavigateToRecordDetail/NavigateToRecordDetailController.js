({
    invoke : function(component, event, helper) {
       window.location.href = '/lightning/r/Case/'+component.get("v.recordId")+'/view';
    }
})