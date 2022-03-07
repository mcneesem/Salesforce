({
    // This method will be used to check user validation.
    checkValidation : function(component, event, helper) {
        var action = component.get("c.validateQuoteCreationfromOpp");
        action.setParams({ opportunityId : component.get("v.recordId") });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            //confirm(state);
            if (state === "SUCCESS") {
                component.set('v.spinner',false); 
                var response= response.getReturnValue();
                if(!response.isSuccess){
                    $A.get("e.force:closeQuickAction").fire();
                    toastEvent.setParams({
                        "title": "Error!",
                        "type": "error",
                        "message": response.errorMessage
                    });
                    toastEvent.fire();
                } else {
                    helper.createQuoteRecord(response.quoteRecordValues);
                    /*
                    toastEvent.setParams({
                        title: "Success!",
                        type: "Success",
                        message : "Success",
                        messageTemplate: $A.get("$Label.c.NSP_QuoteCreated"),
                        messageTemplateData: ['Salesforce Lightning', {
                            url: '/'+response.quote.Id,
                            label: response.quote.Name,
                        }]
                    });
                    component.set('v.spinner',false); 
                    $A.get("e.force:closeQuickAction").fire();
                    toastEvent.fire();
                    */
                }
            }
        });
        $A.enqueueAction(action);
        
    },
    
    createQuoteRecord : function(quoteObjectFieldValues){
        var createAcountContactEvent = $A.get("e.force:createRecord");
        createAcountContactEvent.setParams({
            "entityApiName": 'SBQQ__Quote__c',
            "defaultFieldValues" : quoteObjectFieldValues,
            "recordTypeId" : quoteObjectFieldValues.RecordTypeId
        });
        createAcountContactEvent.fire();
    }
    
    })