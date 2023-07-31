({
    invoke : function(component, event, helper) {
        var navLink = component.find("navService");
        var pageRef = {
            type: 'standard__recordPage',
            attributes: {
                actionName: 'view',
                recordId : component.get("v.recordId")
            },
        };
        navLink.generateUrl(pageRef)
        .then($A.getCallback(function(url) {
            console.log('success: ' + url); 
            window.open(url,'_self');
        }), $A.getCallback(function(error) {
            console.log('error: ' + error);
        }));  
    }
})