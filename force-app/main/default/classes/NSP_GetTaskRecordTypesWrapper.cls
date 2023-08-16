/**
Apex Class Name      :  NSP_GetTaskRecordTypesWrapper
Version              :  1.0                                                                          
Created Date         :  1/2/2022  
Function             :  Represents wrapper class for NSP_GetTaskRecordTypesWrapper 
Story                :  STY-02168                                                               
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                Description                                    
* -------------------------------------------------------------------------------------------------  
* Srushti Bikkannavar        1/2/2022          First Iteration
*/


public with sharing class NSP_GetTaskRecordTypesWrapper {
    public class RecordType{
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean isdefault;

        public RecordType(String value, String label, Boolean isdefault){
            this.value = value;
            this.label = label;
            this.isdefault = isdefault;
        }
    }
    
    /***********************************************************************************************
    * MethodName: getRecordTypes
    * Description : Mehtod which will return list of task RecordTypeId, 
                    RecordType Name and DefaultRecordTypeMapping
    * Params: none
    * ********************************************************************************************/ 
    
    @AuraEnabled(cacheable=true)
    public static List<RecordType>  getRecordTypes (){
        List<RecordType> lstRecordType = new List<RecordType>();
        List<RecordTypeInfo> rtMapByName = Schema.SObjectType.Task.getRecordTypeInfos();
        for(RecordTypeInfo rt : rtMapByName){
            if(rt.getName() != 'master' && rt.isAvailable()){
                lstRecordType.add(new RecordType(
                    rt.getRecordTypeId(),
                    rt.getName(),
                    rt.isDefaultRecordTypeMapping()
            ));
        }
    }
        return lstRecordType;
    }
}