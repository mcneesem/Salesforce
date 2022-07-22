({
    createTaskRecord : function (component,event, helper) {
        
        
        var action = component.get("c.getAccountOwner");
        action.setParams({recordID : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {   
                var todayDate = new Date();
                todayDate.setDate(todayDate.getDate() + 1);
                var today = $A.localizationService.formatDate(todayDate, "YYYY-MM-DD");
                var taskDetail = response.getReturnValue();
                var createRecordEvent = $A.get("e.force:createRecord");
                createRecordEvent.setParams({
                    "entityApiName": "Task",
                    "recordTypeId": taskDetail.taskrecordtypeId,
                    "defaultFieldValues": {
                        'WhatId' : component.get("v.recordId"),
                        'OwnerId' : taskDetail.recordOwnerId,
                        'Subject' : $A.get("$Label.c.NSP_Potential_Referral_Opportunity"),
                        'ActivityDate' : today
                    }
                });
                createRecordEvent.fire();
                
                
            } else if (state =="ERROR") {
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
                dismissActionPanel.fire();
            }
            
        });
        $A.enqueueAction(action);
    }    
    
    
})