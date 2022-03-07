({
    doInit : function(component, event, helper) {
        /* Added as part of DF-01318 */
if(sessionStorage.getItem('storeContactId') === null){
    sessionStorage.setItem('storeContactId', component.get("v.contactId"));
}
if(sessionStorage.getItem('storeContactId') !== null){
    component.set("v.contactId", sessionStorage.getItem('storeContactId'));
}
var fullUrl = window.location.href.toString();
if(fullUrl.includes("PartnerForm")){
    var encodedString = 'PartnerForm';
    var fullEncodedUrl = fullUrl.substr(0, fullUrl.lastIndexOf("PartnerForm"))+encodedString;
    window.history.pushState({}, document.title, fullEncodedUrl);
}
/* Added as part of DF-01318 */
        helper.getPicklistValues(component, event);
        helper.getStatePicklistValues(component, event);
 /* Added as part of DF-01282 */
         helper.getCaptcha(component,event);
    },
    
    handleClick : function(component, event, helper) {
        
        var allValid = [].concat(component.find('fieldId')).reduce(function (validSoFar, inputCmp) {
            inputCmp.showHelpMessageIfInvalid();
            return validSoFar && !inputCmp.get('v.validity').valueMissing;
        }, true);
        if (allValid) {

             helper.saveLead(component, event);
           
        }	
        
    },
    closeModel: function(component, event, helper) {
        // Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
    },
})