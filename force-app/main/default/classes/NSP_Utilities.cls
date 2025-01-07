/**
Apex Class Name      :  NSP_Utilities
Version              :  1.0                                                                          
Created Date         :  6/1/2022  
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Jatin Ahuja                 6/9/2022            First Iteration
*/
public with sharing class NSP_Utilities{


    @AuraEnabled(cacheable = true)
    public static List<FieldSetField> getFieldSetFieldsByFieldSetName(String objectApiName, String fieldSetName){
        try{
            List<Schema.FieldSetMember> fieldSetMembers = ((SObject)Type.forName(objectApiName).newInstance()).getSObjectType().getDescribe().FieldSets.getMap().get(fieldSetName).getFields();
        //Equal to: 
        //List<Schema.FieldSetMember> fieldSetMembers = Schema.getGlobalDescribe().get(objectName).getDescribe().FieldSets.getMap().get(fieldSetName).getFields();
        List<FieldSetField> fields = new List<FieldSetField>();

        for (Schema.FieldSetMember fieldSetMember : fieldSetMembers){
            FieldSetField fieldSetField = new FieldSetField(fieldSetMember,fieldSetName);
            fields.add(fieldSetField);
        }

            return fields;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }


    @AuraEnabled
    public static Boolean isFieldAccessible(String fieldName){
        try{
            if(fieldName == 'Roles') {
                if (Schema.sObjectType.AccountContactRelation.fields.Roles.isAccessible()) {
                    return true;
                 }
            }
            if(fieldName == 'Relationship_Strength__c') {
                if (Schema.sObjectType.AccountContactRelation.fields.Relationship_Strength__c.isAccessible()) {
                    return true;
                 }
            }
            return false;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static Map<String, List<FieldSetField>> getAllFieldSetFieldsBySObjectName(String objectApiName){
        try{
            Map<String, List<FieldSetField>>  fieldSetFieldMap =  new  Map<String, List<FieldSetField>>();
            Map<String,Schema.FieldSet> fieldSetMap = ((SObject)Type.forName(objectApiName).newInstance()).getSObjectType().getDescribe().FieldSets.getMap();
            for( String eachKey : fieldSetMap.keySet()){
                List<FieldSetField> fieldsetList = new List<FieldSetField>();
            for (Schema.FieldSetMember fieldSetMember : fieldSetMap.get(eachKey).getFields()){
                FieldSetField fieldSetField = new FieldSetField(fieldSetMember,fieldSetMap.get(eachKey).getLabel());
                    fieldsetList.add(fieldSetField);
                }

                fieldSetFieldMap.put(eachKey,fieldsetList);
            }
            return fieldSetFieldMap;
        }catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static AuraHandledException getAuraException(Exception e){
        AuraHandledException ex = new AuraHandledException(e.getMessage());
        ex.setMessage(e.getMessage());

        return ex;
    }

    /**
     * This method returns a list of errors by processing given DB results
     */
    public static List<String> getDbErrorRecords(List<Database.SaveResult> saveResults){
        List<String> errors = new List<String>();
        for (Database.SaveResult sr : saveResults) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    errors.add(err.getStatusCode() + ' : ' + err.getMessage() + ' ::: ' + err.getFields());
                }
            }
        }

        return errors;
    }

    /**
     * This method returns a list of errors by processing given DB results
     */
    public static List<String> getDbErrorRecords(List<Database.DeleteResult> deleteResults){
        List<String> errors = new List<String>();
        for (Database.DeleteResult sr : deleteResults) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    errors.add(err.getStatusCode() + ' : ' + err.getMessage() + ' ::: ' + err.getFields());
                }
            }
        }

        return errors;
    }

    /**
     * This method returns a list of errors by processing given DB results
     */
    public static List<String> getDbErrorRecords(List<Database.UpsertResult> upsertResults){
        List<String> errors = new List<String>();
        for (Database.UpsertResult sr : upsertResults) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    errors.add(err.getStatusCode() + ' : ' + err.getMessage() + ' ::: ' + err.getFields());
                }
            }
        }

        return errors;
    }

    // wrapper class to set fields

    public class FieldSetField{
        @AuraEnabled
        public Boolean dbRequired;
        @AuraEnabled
        public String apiName;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Boolean required;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String fieldSetName;

        public FieldSetField(Schema.FieldSetMember fieldSetMember, String fieldSetName)
        {
            this.dbRequired = fieldSetMember.dbRequired;
            this.apiName = fieldSetMember.fieldPath;
            this.label = fieldSetMember.label;
            this.required = fieldSetMember.required;
            this.type = String.valueOf(fieldSetMember.getType());
            this.fieldSetName =fieldSetName;
        }
    }
}