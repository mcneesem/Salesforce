/* **************************************************************************************************   
Component Name :  NSP_SObjectHistoryTrackingHelper class
Version              :  1.0                                                                          
Created Date         :  March, 2022                                                           
Function             :  Imported from generic utility
					 : Used in custom history tracking  	
Story                :                                                                             
Modification Log     :                                                                               

*   Harsha Khiroya   March 16, 2022              First Iteration
***************************************************************************************************
*/
public class NSP_HistoryTrackingVisibilityHandler {
	
    public static List<SObject> getAccessibleFieldList(List<SObject> objRecords,Id recordId){
        List<SObject> accessibleFieldsData = new List<SObject>();  
        for(String fieldName : getAccessibleFields(recordId)){
                for(SObject objRecord:objRecords){
                        if(objRecord.getSObjectType() == NSP_SObjects_History_Tracking__b.sObjectType) { 
                            if(fieldName == ((NSP_SObjects_History_Tracking__b)objRecord).NSP_Field_Name__c){
                                accessibleFieldsData.add(objRecord);
                            }
                    }
                }
            }
        return accessibleFieldsData;
    }
    
    public static List<String> getAccessibleFields(Id recordId){
        String sObjectType = String.valueOf(recordId.getsobjecttype());
        SObjectType schemaType = Schema.getGlobalDescribe().get(sObjectType);
        Map<String, SObjectField> fieldMap = schemaType.getDescribe().fields.getMap();
    
        List<String> fieldsToShow = new List<String>();
        for (String field : fieldMap.keySet()){
            SObjectField sfield = fieldMap.get(field);
            if (sfield.getDescribe().isAccessible()){
                fieldsToShow.add(sfield.getDescribe().getLabel());
            }
        }
        return fieldsToShow;
    }
}