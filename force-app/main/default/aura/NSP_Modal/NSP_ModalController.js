({
    init : function(component, event, helper) {
        // In that component, start your flow. Reference the flow's API Name.
        var flow = component.find("flowData");
        flow.startFlow(component.get("v.flowName"), component.get("v.inputVariables"));
    }
})