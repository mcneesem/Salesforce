({
	init : function (component, event, helper) {
        var recordTypeId = component.get("v.pageReference").state.recordTypeId;
        component.set("v.selectedRecordId", recordTypeId);
        var inputVariables = helper.initInputVariables(component, event, helper);
        // Find the component whose aura:id is "flowData"
        var flow = component.find("New_Lead_Flow");
        // In that component, start your flow. Reference the flow's API Name.
        flow.startFlow("New_Lead_Flow",inputVariables);
    },
    
    handleStatusChange : function(component, event, helper){
        if(event.getParam("status") === "FINISHED") {
         // Get the output variables and iterate over them
         var outputVariables = event.getParam("outputVariables");
         var outputVar;
         for(var i = 0; i < outputVariables.length; i++) {
            outputVar = outputVariables[i];
            // Pass the values to the component's attributes
            if(outputVar.name === "leadRecordId") {
                component.set("v.leadRecordId", outputVar.value);
                if(outputVar.value){
                    helper.navigateToRec(component, event, helper);
                }
            }
         }
      }
    },
    
    navigateToListView : function(component, event, helper){
       // var device = $A.get("$Browser.formFactor");
        var homeEvent = $A.get("e.force:navigateToObjectHome");
        homeEvent.setParams({
            "scope": "Lead"
        });
        homeEvent.fire();
        //component.destroy();
    }
})