({
    // Method to call dependent picklist 
    getDependentPicklist : function(component, event) {
        component.set("v.addressRecord.NSP_Related_Site__c",component.get("v.recordId"));
        /*var value = [{ 
            type: 'Account', 
            id: component.get("v.recordId"), 
            label: "navigate", 
        }]; 
        component.find("relatedAccount").get("v.body")[0].set("v.values", value); */
        var dependentPicklist = component.find("dependentPicklist");
        dependentPicklist.fetchDependentValues($A.getCallback(function(data) {
            
            component.set("v.countryStateMap",data);
        }));
    },
    
    // Method to get selected country state value
    getStateValues : function(component, event) {
        var globalStateAndCountryMap = component.get("v.countryStateMap");
        var country = component.get("v.addressRecord.NSP_Country__c");
        if(!$A.util.isUndefinedOrNull(country) && 
           !$A.util.isUndefinedOrNull(globalStateAndCountryMap) &&
           !$A.util.isUndefinedOrNull(globalStateAndCountryMap[country])){
            var opts = []; 
            var response=globalStateAndCountryMap[country];
            var opt={label: '---None---', value: ''};
            opts.push(opt);
            for(var i in response){
                if(typeof(response[i]) === 'string'){
                    var opt={label: response[i], value: response[i]};
                    opts.push(opt);
                }
            } 
            component.set("v.stateOptions", opts);
           
            
        }
        
    },
    
    // Method to save the address record
    saveRecords : function(component, event){
        var address = component.get("v.addressRecord");
        var add = {};
        add.sObjectType = 'NSP_Address__c';
        
        add.NSP_Related_Site__c = address.NSP_Related_Site__c;
        add.Name = address.Name;
        add.NSP_Street__c = address.NSP_Street__c;
        add.NSP_City__c = address.NSP_City__c;
        add.NSP_Country__c = address.NSP_Country__c;
        add.NSP_State__c = address.NSP_State__c;
        add.NSP_Postal_Code__c = address.NSP_Postal_Code__c;
        add.NSP_Address_Type__c = component.find("addressType").get("v.value");//address.SME_Address_Type__c;
        add.NSP_Legal_Name__c = address.NSP_Legal_Name__c;
        add.NSP_Payment_Terms__c = address.NSP_Payment_Terms__c;
        add.NSP_C_O_Name__c = address.NSP_C_O_Name__c;
        add.NSP_VAT_Registration_No__c = address.NSP_VAT_Registration_No__c;
        var action = component.get("c.saveAddress");
        action.setParams({ addressRecord : add});
        action.setCallback(this, function(response) {
            var state = response.getState();
            var success = "SUCCESS"
            var error = "ERROR"
            if (state === success) {
                    /* Added as part of DF-01313 */
                component.set("v.responseObject", response.getReturnValue());
                var getResponseObj =  component.get("v.responseObject");
                if(getResponseObj.responseType === 'Error'){
                    component.set("v.toogleErrorMessage", true);
                     var errorToast = $A.get("e.force:showToast");
                    errorToast.setParams({
                        "title": error,
                        "message":  getResponseObj.responseData[0],
                        "type" : error
                    });
                    errorToast.fire();
                    /* Added as part of DF-01313 */
                    }else{
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title": success,
                            "message":  "Address Saved",
                            "type" : success
                        });
                        resultsToast.fire();
                        var navEvt = $A.get("e.force:navigateToSObject");
                        navEvt.setParams({
                            "recordId": response.getReturnValue().responseData[0],
                        });
                        //navEvt.fire();
                        $A.get("e.force:closeQuickAction").fire();
                    }
                
            }
            else if (state === "INCOMPLETE") {
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": error,
                    "message": "Error Occured"
                });
                resultsToast.fire();
            }
                else if (state === error) {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            var resultsToast = $A.get("e.force:showToast");
                            resultsToast.setParams({
                                "title": error,
                                "message": errors[0].message
                            });
                            resultsToast.fire();
                        }
                    } else {
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title": error,
                            "message": "Error Occured"
                        });
                        resultsToast.fire();
                    }
                }
        });
        $A.enqueueAction(action);
        
    },
    
    // Method to navigate to List view
    gotoURL : function (component, event, helper) {
        
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.recordId")
        });
        navEvt.fire();
        
    },

    // Method to save the address record
    getRecordTypeId : function(component, event){
        
        var action = component.get("c.getDefaultRecordType");
        //action.setParams({ addressRecord : add});
        action.setCallback(this, function(response) {
            var state = response.getState();
            var success = "SUCCESS"
            var error = "ERROR"
            if (state === success) {
                    if(response.getReturnValue != null){
                        component.set("v.recordTypeId", response.getReturnValue);
                    }
            }
            else if (state === "INCOMPLETE") {
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": error,
                    "message": "Error Occured"
                });
                resultsToast.fire();
            }
                else if (state === error) {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            var resultsToast = $A.get("e.force:showToast");
                            resultsToast.setParams({
                                "title": error,
                                "message": errors[0].message
                            });
                            resultsToast.fire();
                        }
                    } else {
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title": error,
                            "message": "Error Occured"
                        });
                        resultsToast.fire();
                    }
                }
        });
        $A.enqueueAction(action);
        
    },

    handleValidationAndSave : function(component, event){
        
        var stateValid = component.find('states').get("v.value");
        var countryValid = component.find('country').get("v.value");
        var postalCodeValid = component.find('postalCode').get("v.value");
        var addressNameValid = component.find('addressName').get("v.value");
        var addressTypeValid = component.find('addressType').get("v.value");
        var errorFields = '';
        if(addressNameValid == null || addressNameValid == ''){
            errorFields += "Address Name,"
        }
        if(addressTypeValid == null || addressTypeValid == ''){
            errorFields += "Address Type,"
        }
        if(countryValid == null || countryValid == ''){
            errorFields += "Country,"
        }

        if(stateValid == null || stateValid == ''){
            errorFields += "State,"
        }

        if(postalCodeValid == null || postalCodeValid == ''){
            errorFields += "Postal Code,"
        }
       
        
        if(errorFields == ''){
            this.saveRecords(component, event);
        }else{
            var errorMessage = ('Please fill required data before submitting : '+errorFields).replace(/,\s*$/, "");
            component.find('errorMessage').setError(errorMessage);
        }
            
        
    },
   
   
})