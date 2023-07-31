/**
 * @description  : Associate the client Sub plan his with asset
 * @date         : 10/03/2022
 */
public with sharing class NSP_RetAssetWithClntSubPlnController {
    /**
     * @description: get ClientSubplanhis related to asset 
     * @param recordId of Asset.  
     * @return boolean             
     */
    @AuraEnabled
    public static Boolean isClientSubPlanAssociatedWithAsset(Id assetId){
        try {
            //fetch client Sub plan history rec related to asset
            List<NSP_Client_Sub_Plan_History__c> clientSubPlanHisRec = [SELECT Id 
                    FROM NSP_Client_Sub_Plan_History__c
                    WHERE NSP_Asset__c =: assetId LIMIT 1] ;
                    
            return clientSubPlanHisRec.isEmpty();

        } catch (Exception except) { throw new AuraHandledException(except.getMessage()); }
    }

        /**
     * @description: get record type id of Client Subplan His 'Choice' by calling NSP_GenericRecordType.getRecordTypeId
     * @param sObjectName of client sub plan history.  
     * @param Record type Name of client sub plan history.  
     * @return RecordTypeId             
     */
    @AuraEnabled(cacheable = true)
    public static Id getRecordTypeIdByName( String sObjectName,String recTypeName ){
        try{
            return NSP_GenericRecordType.getRecordTypeId(sObjectName, recTypeName);
        }catch (Exception ex) { throw NSP_Utilities.getAuraException(ex); }
        
    }

}