
/**
* Represents Generic class to get record type for  all objects
*/



public class NSP_GenericRecordType {
    
    /***********************************************************************************************
    * MethodName: getRecordTypeId
    * Description :  This method returns record Type id based on object name and record Type label
    * Params:   String objectName, String recordTypeLabel   
    * Author: Bindushree R
    * ********************************************************************************************/
    public static Id getRecordTypeId(String objectStr, String recordTypeLabel){
        
        
        if(String.isNotBlank(objectStr) && String.isNotBlank(recordTypeLabel)){
            
            SObjectType objToken = Schema.getGlobalDescribe().get(objectStr);
			DescribeSObjectResult objDef = objToken.getDescribe();
			Map<String,Schema.RecordTypeInfo> rtMapByName = objDef.getRecordTypeInfosByDeveloperName();
			Schema.RecordTypeInfo rtByName =  rtMapByName.get(recordTypeLabel);
			Id recordTypeId = rtByName.getRecordTypeId();        
        
            return recordTypeId;
        }
        return null;
    }

    /**
     * It returns map of all record types of the given object.
     * Returned map will have record type developer name as key and record type info as value.
     */
    public static Map<String,Schema.RecordTypeInfo> getRecordTypeMap(String objectStr){
        if(String.isBlank(objectStr)){
            return new Map<String,Schema.RecordTypeInfo>();
        }

        SObjectType objToken = Schema.getGlobalDescribe().get(objectStr);
        if(objToken == null){
            return new Map<String,Schema.RecordTypeInfo>();
        }

        return objToken.getDescribe().getRecordTypeInfosByDeveloperName();
    }
}
			

