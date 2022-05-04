({
	fetchdependentValues : function(component, event) {
        if(component.isValid()){
        var action = component.get("c.getAuraDependentOptions");
        action.setParams({pObjName :component.get("v.sObject"),pControllingFieldName : component.get("v.controllingFieldName"),pDependentFieldName : component.get("v.dependentFieldName")});
        action.setCallback(this,function(response){
            var state = response.getState();
            if (state == 'SUCCESS') {
                if(response.getReturnValue() == null){
                    component.set("v.toogleErrorMessage", true);
                }else{
                var globalRes=response.getReturnValue();
                var params = event.getParam("arguments");
                params.callback(response.getReturnValue());
                } }
        });
        $A.enqueueAction(action);
    }
    }
})