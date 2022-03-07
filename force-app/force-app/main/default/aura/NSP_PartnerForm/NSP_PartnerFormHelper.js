({
    saveLead : function(component, event) {
        var action = component.get("c.createAccount");
        var accountObject = component.get("v.AccountObj");
         action.setParams({ accountObject : JSON.stringify(accountObject),
                       contactId : component.get("v.contactId") });
          action.setCallback(this, function(response) {
            var state = response.getState();
     
            if (state == "SUCCESS") {
                
                if(response.getReturnValue() === "success"){
                    var base_url = window.location.origin
                window.location.href = base_url +$A.get("$Label.c.NSP_ThankYou_Page");
                }else if(response.getReturnValue() === "exists"){
                    this.showErrorModal(component, event, $A.get("$Label.c.NSP_Partner_Form_Duplicate_Account_Message"));
                }
                
                               
            } else if (state =="ERROR") {
               
                this.showErrorModal(component, event, $A.get("$Label.c.NSP_Partner_Form_Error_Message"));
            }
            
        });
        $A.enqueueAction(action);
    },
    getPicklistValues : function(component, event) {
        var action = component.get("c.returnAllPickListValues");
       action.setCallback(this, function(response) {
            var state = response.getState();

            if (state == "SUCCESS") {
                
                var picklistvalues = response.getReturnValue();
                
                if(picklistvalues.fieldAPIName === ''){
                    
                }
                component.set("v.insperityHistory",picklistvalues.insperityHistory);
                component.set("v.oneToTen",picklistvalues.oneToTen);
                component.set("v.coverageArea",picklistvalues.coverageArea);
                component.set("v.businessVertical",picklistvalues.businessVertical);
                
                component.set("v.AccountObj.NSP_Insperitys_History_with_This_Partner__c",picklistvalues.insperityHistory[0]);
                component.set("v.AccountObj.NSP_How_FamiliarIsCompany_with_Insperity__c",picklistvalues.oneToTen[0]);
                component.set("v.AccountObj.NSP_HowFamiliar_is_the_company_with_PEOs__c",picklistvalues.oneToTen[0]);
                component.set("v.AccountObj.NSP_Coverage_Area__c",picklistvalues.coverageArea[0]);
                component.set("v.AccountObj.NSP_Business_Vertical__c",picklistvalues.businessVertical[0]);
                
            } else if (state =="ERROR") {
               
               this.showErrorModal(component, event, $A.get("$Label.c.NSP_Partner_Form_Error_Message"));
            }
            
        });
        $A.enqueueAction(action);
    },
    
    showErrorModal : function(component, eventz,errormsg) {
         component.set("v.isModalOpen", true);
                component.set("v.cmpError",errormsg);
    },
    
    getStatePicklistValues : function(component, event) {
        var action = component.get("c.getDependentMap");     
        action.setParams({ objDetail : component.get("v.AccountObj"),
                       contrfieldApiName : 'BillingCountryCode',
                         depfieldApiName : 'BillingStateCode'});
        action.setCallback(this, function(response) {
            var state = response.getState();
             
            if (state == "SUCCESS") {
                 
                var picklistvalues = response.getReturnValue();
            
                component.set("v.state",picklistvalues['United States']);
               component.set("v.AccountObj.BillingState",picklistvalues['United States'][0]);
                
            } else if (state =="ERROR") {
             
               this.showErrorModal(component, event, $A.get("$Label.c.NSP_Partner_Form_Error_Message"));
            }
            
        });
        $A.enqueueAction(action);
    },
    getCaptcha: function(component, eventz,errormsg) {
        var vfURL = $A.get("{!$Setup.NSP_GoogleRecaptchaSettings__c.NSP_SiteUrl__c}") ;
        
        window.addEventListener('message', function(event){
            if(event.data === component.get("v.unlock") ){
                component.set('v.isDisable', false); 
            }
        }, false);
    }
})