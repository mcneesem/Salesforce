// intentionally `without sharing` to preserve default sharing at api version 55...
public without sharing class NSP_IntegrationFieldsController {
    // test w/ NSP_IntegrationFieldsControllerTest (100%)

    // Get Integration fields based on recordId
    @AuraEnabled
    public static List<String> getIntegrationFieldsBasedOnObject( Id recordId ) {
        String sObjName = null;
        if ( recordId != null ) {
            sObjName = recordId.getSObjectType().getDescribe().getName();
        }
        List<String> fields = new List<String>();
        if ( String.isNotBlank( sObjName ) ) {
            for ( NSP_Integration_Fields_Management__mdt fieldMetadata : NSP_Integration_Fields_Management__mdt.getall().values() ) {
                if ( fieldMetadata.NSP_Object_Name__c == sObjName ) {
                    fields.addAll(
                        fieldMetadata.NSP_Field_Names__c.split( ';' )
                    );
                }
            }
        }
        return fields;
    }
    
    // Get sObject details based on recordId
    @AuraEnabled
    public static sObject getContact( Id recordId ) {
        List<Contact> records = new List<Contact>();
        if ( ( recordId != null )
            && recordId.getSObjectType() == Contact.getSObjectType()
            )
        {
            records = [
                SELECT NSP_Per_ID__c , CreatedBy.NSP_Profile_Name__c
                FROM Contact
                WHERE ( Id = :recordId )
            ];
        }
        sObject record = null;
        if ( !records.isEmpty() ) {
            record = records[0];
        }
        return record;
    }

}
//
