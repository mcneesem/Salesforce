/**
* Represent Integration field on UI based on Record Id
* Created by : Virendra Kumar
* Created Date : 9/06/2022  
*/

public class NSP_IntegrationFieldsController {
    // test w/ NSP_IntegrationFieldsControllerTest (100%)
    
    /**
    * Get Integration fields based on recordId
    * @param Id recordId.  
    * @return List<String>             
    *                
    */
    @AuraEnabled
    public static List<String> getIntegrationFieldsBasedOnObject(Id recordId) {
        
         List<String> fields = new List<String>();
        //Get Object Name based on record Id
        String sObjName = recordId.getSObjectType().getDescribe().getName();       
		//Get the metadata fields based on object name
        for(NSP_Integration_Fields_Management__mdt fieldMetadata : NSP_Integration_Fields_Management__mdt.getall().values()) {
            if(fieldMetadata.NSP_Object_Name__c == sObjName) {
               fields.addAll(fieldMetadata.NSP_Field_Names__c.split(';'));
            }
        }
        return fields;
    }
    
     /**
    * Get sObject details based on recordId
    * @param Id recordId.  
    * @return sObject record          
    *                
    */
    @AuraEnabled
    public static sObject getContact(Id recordId) {
        //Get Object Name based on record Id
        sObject record = null;
        List<Contact> contacts = new List<Contact>();
        String sObjName = recordId.getSObjectType().getDescribe().getName();
        if(sObjName == 'Contact') {
            contacts = [SELECT NSP_Per_ID__c, CreatedBy.NSP_Profile_Name__c  FROM Contact WHERE Id =: recordId];
        }
        if( !contacts.isEmpty() ) {
            record = contacts[0];
        }
        return record;
    }
}