({
    navigateToRec : function(component, event, helper){
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": component.get("v.leadRecordId")
            });
            navEvt.fire();
    },
    
    initInputVariables : function(component, event, helper){
        var leadRecordType = component.get("v.selectedRecordId") != null ? component.get("v.selectedRecordId") : '' ;
        var inputVariables = [
            {
                name : 'leadRecordTypeId',
                type : 'String',
                value : leadRecordType
            }
        ];
        
        return inputVariables;
    }
})