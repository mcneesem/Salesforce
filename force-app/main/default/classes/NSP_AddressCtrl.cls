/**************************************************************************************************   
Apex Controller Name :  NSP_AddressCtrl
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :  This class is used as controller  class for NSP_NewAddress.
Test class           :  NSP_AddressCtrlTest
Story                :                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

*   Tejas           October 10, 2021          First Iteration
*   ManiTeja        February 18 2022          modified saveAddress method to remove null
                                              while catching exception and passing to aura component as part of DF-01313
***************************************************************************************************/
public without sharing class NSP_AddressCtrl{
    // test w/ NSP_AddressCtrlTest (83%)
    public static final string SUCCESS = 'Success';
    public static final string ERROR = 'Error';    
    
    /**********************************************************************************************
* Method Name:getAddress
* Purpose: This method will get address record
***********************************************************************************************/
    
    @AuraEnabled
    public static NSP_Address__c getAddress(String recId){
        
            NSP_Address__c address = null;
            try{
            List<NSP_Address__c> addresses = [SELECT NSP_Address_Type__c,NSP_Country__c, NSP_State__c FROM NSP_Address__c WHERE Id =:recId];
            if (!addresses.isEmpty()) {
            address = addresses[0];
             }
             }catch(Exception ex){
                throw new AuraHandledException(ex.getMessage());
            }
            return address;
        }
      
    /**********************************************************************************************
* Method Name:saveAddress
* Purpose: This method will save address record
***********************************************************************************************/
    
    @AuraEnabled
    public static ResponseWrapper saveAddress(NSP_Address__c addressRecord){
        ResponseWrapper responseWrap = new ResponseWrapper (); 
        try{
            if (null != addressRecord) {
                upsert addressRecord; 
                responseWrap.responseType = SUCCESS;
                responseWrap.responseData.add(addressRecord.id);
                responseWrap.responseData.add(addressRecord.Name);
            }
        }
        catch(DMLException dmlExc) {
            //responseWrap.responseType = ERROR;
            //responseWrap.responseData.add(dmlExc.getDmlMessage(0));
            throw new AuraHandledException(dmlExc.getDmlMessage(0));
         }
        return responseWrap;
    }

     
        

    
    // Wrapper class for response
    public class ResponseWrapper {
        @AuraEnabled
        public String responseType{get;set;}
        @AuraEnabled
        public List<String> responseData{get;set;}
        
        public ResponseWrapper() {
            responseData = new List<String>();
        }
    }
    
    
}