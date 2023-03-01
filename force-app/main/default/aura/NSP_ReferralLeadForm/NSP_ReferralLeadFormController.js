({
    doInit : function(component, event, helper) {
     /* Added as part of DF-01282 */
       // Uncommenting as part of service request - 563746
       helper.getCaptcha(component,event); // Commenting as part of DF-01852
       helper.getPicklistValues(component, event);
       helper.getStatePicklistValues(component, event);
       component.set("v.LeadObj.NSP_Referralbenefitsanonprofitorg__c","Does not apply");
   },
   handlePIChange: function (component, event, helper) {
       //Get the Selected values   
       var selectedValues = event.getParam("value");
       //Update the Selected Values  
       component.set("v.selectedPIList", selectedValues);  
       component.set("v.LeadObj.NSP_Product_Interest__c", selectedValues.join(';'))
   }, 
   handleSubmit : function(component, event, helper) {
       var allValid = [].concat(component.find('fieldId')).reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && !inputCmp.get('v.validity').valueMissing;
       }, true);

       /* Added as part of DF-01739  - Potential customer*/
       var isNotPcValid = false;
       var select = component.find('pCOptions');
       if (!select.checkValidity()) {
           select.showHelpMessageIfInvalid();
           isNotPcValid = true;
       }  else  {
           isNotPcValid = false;
       }

       /* Validate the Zip Code - this field is not required
           Aura doesn't validate the pattern only displays an error message 
       */ 
       var isZipCodeValid = true;
       var zipCode = component.find('postalcode').get('v.value');
       if(zipCode != undefined){
            //  If zip code is not empty
            if(zipCode.trim().length > 0){
                // zip code must contain 5 digits
                let e = new RegExp("^\\d{5}$");
                isZipCodeValid = e.test(zipCode);
           }
       }

       /* Added as part of DF-01739 Ends*/
       if (allValid && !isNotPcValid && isZipCodeValid) {
           helper.saveLead(component, event);
           window.dispatchEvent(new Event("submit"));
       }
       else{
           // US-199954
           window.dispatchEvent(new Event("error"));
       }	  
   },
    closeModel: function(component, event, helper) {
       // Set isModalOpen attribute to false  
       component.set("v.isModalOpen", false);
   },
   handleNonProfitChange: function (component, event, helper) {
       if(component.find('nonprofitSelect').get('v.value') === "Donation" || component.find('nonprofitSelect').get('v.value') === "Match"){
             component.set("v.isNonProfit", true);
       }else{
           
           component.set("v.isNonProfit", false);
       }
   }
})