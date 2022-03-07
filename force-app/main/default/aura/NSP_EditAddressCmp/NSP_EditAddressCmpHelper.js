({
    // Method to call dependent picklist     
    getDependentPicklist : function(component, event,helper) {
        var dependentPicklist = component.find("dependentPicklist");
        dependentPicklist.fetchDependentValues($A.getCallback(function(data) {
            component.set("v.countryStateMap",data);   
            
            helper.setStateValue(component, event); 
            
        }));
          
        var action = component.get("c.getAddress");
        action.setParams({
            "recId" : component.get("v.recordId")
        })
        action.setCallback(this,function(response){
            var result = response.getReturnValue();
            if(result !=null){
                component.find("country").set("v.value", result.NSP_Country__c);
            	component.find("addressType").set("v.value",result.NSP_Address_Type__c);
                component.find("state").set("v.value", result.NSP_State__c);
                component.set("v.addressRecord.recordTypeId", result.recordtypeId);
                helper.setStateValue(component, event); 
            }
        });
        $A.enqueueAction(action);
        
    },
    // Method to get selected country state value
    getStateValues : function(component, event) {
        var globalStateAndCountryMap = component.get("v.countryStateMap");
        var country = component.find("country").get("v.value");
        if(!$A.util.isUndefinedOrNull(country) && 
           !$A.util.isUndefinedOrNull(globalStateAndCountryMap) &&
           !$A.util.isUndefinedOrNull(globalStateAndCountryMap[country])){
            var opts = []; 
            var response=globalStateAndCountryMap[country];
            var opt={label: '---None---', value: ''};
            opts.push(opt);
            for(var i in response){
                if(typeof(response[i]) === 'string'){
                    var optres={label: response[i], value: response[i]}; //rename from opt to optres for code scan
                    opts.push(optres);
                }
            } 
            component.find("state").set("v.options", opts);
        }
    },
    
    // Method to update the address record
    updateRecord : function(component, event){
        var add = {};
        add.sObjectType = 'NSP_Address__c';
        add.NSP_Related_Site__c = component.find("relatedSite").get("v.value");
        add.NSP_Street__c = component.find("street").get("v.value");
        add.NSP_City__c = component.find("city").get("v.value");
        add.NSP_Country__c = component.find("country").get("v.value");
        add.NSP_State__c = component.find("state").get("v.value");
        add.NSP_Postal_Code__c = component.find("postalCode").get("v.value");
        if(component.find("addressType").get("v.value") !=''){         
 	       add.NSP_Address_Type__c = component.find("addressType").get("v.value");
        }
        
        add.NSP_Legal_Name__c = component.find("legalNumber").get("v.value");
        add.NSP_Payment_Terms__c = component.find("paymentTerms").get("v.value");
        add.NSP_C_O_Name__c = component.find("coName").get("v.value"); 
        add.NSP_VAT_Registration_No__c = component.find("vatRegNum").get("v.value");
        add.Id = component.get("v.recordId");
        var action = component.get("c.saveAddress");
        action.setParams({ addressRecord : add});
                action.setCallback(this, function(response) {
            var state = response.getState();
                    var success = "SUCCESS"
                    var error = "ERROR"
                    if (state === success) {
                        if(response.getReturnValue() == null){
                            component.set("v.toogleErrorMessage", true);
                        }else{
                            var resultsToast = $A.get("e.force:showToast");
                            resultsToast.setParams({
                                "title": success,
                                "message":  "Address Updated",
                                "type" : success
                            });
                            resultsToast.fire();
                            var navEvt = $A.get("e.force:navigateToSObject");
                            navEvt.setParams({
                                "recordId": response.getReturnValue().responseData[0],
                            });
                            //navEvt.fire();
                            window.location = "/"+response.getReturnValue().responseData[0];
                        }                
                    }
                    else if (state === "INCOMPLETE") {
                var resultsToastError = $A.get("e.force:showToast");
                resultsToastError.setParams({
                    "title": error,
                    "message": "Error Occured"
                });
                resultsToastError.fire();
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
    
    // Method to set the state value
    setStateValue : function(component, event){
        var globalStateAndCountryMap = component.get("v.countryStateMap");
        var country = component.find("country").get("v.value");
        var selectedState = component.find("stateHidden").get("v.value");
        if(!$A.util.isUndefinedOrNull(country) && 
           !$A.util.isUndefinedOrNull(globalStateAndCountryMap) &&
           !$A.util.isUndefinedOrNull(globalStateAndCountryMap[country])){
            var opts = []; 
            var response=globalStateAndCountryMap[country];
            var opt={label: '---None---', value: ''};
            opts.push(opt);
            for(var i in response){
                if(typeof(response[i]) === 'string'){
                    var isSelected = response[i] == selectedState ? true:false;
                    var opt={label: response[i], value: response[i],selected :isSelected };
                    opts.push(opt);
                }
            }
            var spinner = component.find("mySpinner");
        	$A.util.toggleClass(spinner, "slds-hide");
			component.find("state").set("v.options", opts);
    	}
    },
    
    //Method to navigate to detail page.
    navigateToDetail : function(component, event){
    	var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": component.get("v.recordId"),
        });
        navEvt.fire();
    }
})