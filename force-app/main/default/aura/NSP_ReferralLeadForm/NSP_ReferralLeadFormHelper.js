({
    getPicklistValues : function(component, event) {
       var action = component.get("c.returnAllPickListValues");
       action.setCallback(this, function(response) {
           var state = response.getState();
           if (state == "SUCCESS") {
               var picklistvalues = response.getReturnValue();
               component.set("v.industry",picklistvalues.industry);
               component.set("v.potentialCustomer",picklistvalues.potentialCustomer);
               var piValues = [];
               for (var i = 0; i < picklistvalues.productofinterest.length; i++) {
                   piValues.push({
                       label: picklistvalues.productofinterest[i],
                       value: picklistvalues.productofinterest[i]
                   });
               }
               component.set("v.PIlist",piValues);
                              
           } else if (state =="ERROR") {
              this.showErrorModal(component, event,$A.get("$Label.c.NSP_ReferralLeadErrorMessage"));
           }
       });
       $A.enqueueAction(action);
   },
    getStatePicklistValues : function(component, event) {
       var action = component.get("c.getDependentMap");     
       action.setParams({ objDetail : component.get("v.LeadObj"),
                      contrfieldApiName : 'CountryCode',
                        depfieldApiName : 'StateCode'});
       action.setCallback(this, function(response) {
           var state = response.getState();
           if (state == "SUCCESS") {
               var picklistvalues = response.getReturnValue();
               component.set("v.state",picklistvalues['United States']);
           } else if (state =="ERROR") {
                this.showErrorModal(component, event,$A.get("$Label.c.NSP_ReferralLeadErrorMessage"));
           }
       });
       $A.enqueueAction(action);
   },
    saveLead : function(component, event) {
       var action = component.get("c.createReferralLead");
       var leadObject = component.get("v.LeadObj");
        action.setParams({
             leadObject : JSON.stringify(leadObject)
           });
         action.setCallback(this, function(response) {
           var state = response.getState();
           if (state == "SUCCESS") {
               if(response.getReturnValue() === "success"){
                   var base_url = window.location.origin
               window.location.href = base_url +$A.get("$Label.c.NSP_ThankYou_Page");
               }                         
           } else if (state =="ERROR") {
              this.showErrorModal(component, event,$A.get("$Label.c.NSP_ReferralLeadErrorMessage"));
           }
       });
       $A.enqueueAction(action);
   },
    showErrorModal : function(component, eventz,errormsg) {
        component.set("v.isModalOpen", true);
        component.set("v.cmpError",errormsg);
   },
   // Uncommenting as part of service request - 563746 
   getCaptcha: function(component, eventz,errormsg) {
    var vfURL = $A.get("{!$Setup.NSP_GoogleRecaptchaSettings__c.NSP_SiteUrl__c}") ;
    
    window.addEventListener('message', function(event){
        if(event.data === component.get("v.unlock")){
            component.set('v.isDisable', false); 
        }
        else if(event.data == "Lock"){
            component.set('v.isDisable', true); 
        } 

    }, false);
} 
})