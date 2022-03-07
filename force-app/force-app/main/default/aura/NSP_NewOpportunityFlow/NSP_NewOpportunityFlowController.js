({
	init : function (component, event, helper) {
        
        // Find the component whose aura:id is "flowData"
        var flow = component.find("New_Opportunity_Flow");
        // In that component, start your flow. Reference the flow's API Name.
        flow.startFlow("Invoke_Primary_Opportunity_fields_on_click_of_New_button");
    },
    
    handleStatusChange : function(component, event, helper){
        if(event.getParam("status") === "FINISHED") {
         // Get the output variables and iterate over them
         var outputVariables = event.getParam("outputVariables");
         var outputVar;
         for(var i = 0; i < outputVariables.length; i++) {
            outputVar = outputVariables[i];
            // Pass the values to the component's attributes
            if(outputVar.name === "OpportunityRecordID") {
                component.set("v.OpportunityRecordID", outputVar.value);
                if(outputVar.value){
                    helper.navigateToRec(component, event, helper);
                }
            }
         }
      }
    },
    
    navigateToListView : function(component, event, helper){
        window.location.href = '/lightning/o/Opportunity/list?filterName=Recent';
    }
})