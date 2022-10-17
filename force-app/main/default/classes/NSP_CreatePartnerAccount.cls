/**
* Represents the class which is responsible to create partner account from the site.
*/
public without sharing class  NSP_CreatePartnerAccount {
    
    /**
* Creates partner account from the information that is provided on the site by the user
* @param accountObject String json holds the values in the account object.  
* @param contactId String holds the contact for which the account is to be created
* @return String     
* Modified By           | Date              | Description
* -------------------------------------------------------------------------------------
* Ruchi Roy         	10/13/2022           Modified for 128063
*                
*/
@AuraEnabled
public static String createAccount(String accountObject, String contactObject){ 
    //Response String
    String response;
      
        try{
            //Deserialising the account object
        Account accountRecord =(Account)JSON.deserialize(accountObject,Account.class);
        accountRecord.Type ='Partner';
            accountRecord.BillingCountry='United States';
            //Added for 128063
            accountRecord.WebForm__c=True;
            //set the account reocord type as Partner 
        accountRecord.Recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();
        //By passing the duplicate rules
        Database.DMLOptions dbDML = new Database.DMLOptions(); 
        dbDML.DuplicateRuleHeader.allowSave = true;
        dbDML.DuplicateRuleHeader.runAsCurrentUser = true;
        
      //Inseting the accounts
            Database.insert(accountRecord, dbDML);
            /* As part of STY-02211, creating contact along with Account Record */
              Contact nContact =(Contact)JSON.deserialize(contactObject,Contact.class);
              nContact.accountid = accountRecord.id;
               Database.insert(nContact, dbDML);
             /* As part of STY-02211, creating contact along with Account Record */
              //Setting response as success             
            response = NSP_SalesConstants.successResponse;
        }catch(Exception ex){
            response = ex.getMessage();
            NSP_CustomException.LogException(ex);
            throw new AuraHandledException(ex.getMessage());
        }
    return response;
}

/**
* Method to get picklist values of the picklist fields for an object
* @param objectAPIName String has the objects API name.  
* @param fieldAPIName String has the api name of the field
* @return List<String>             
*                
*/

@AuraEnabled
public static List<String> getPiklistValues(string objectAPIName, string fieldAPIName) {
    //List to hold the pick list values
    List<String> levelPicklistValues = new List<String>();
    try{        
        //Using schema class to fetch the field details
        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectAPIName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Schema.DescribeFieldResult objFieldInfo = objDescribe.fields.getMap().get(fieldAPIName).getDescribe();
        List<Schema.PicklistEntry> picklistvalues = objFieldInfo.getPicklistValues();
        //Iterating over the picklist values and adding it to the list
        for(Schema.PicklistEntry value: picklistvalues) {
            levelPicklistValues.add(value.getValue());
        }           
        
    }Catch(Exception ex){
        levelPicklistValues.add(ex.getMessage());
        throw new AuraHandledException(ex.getMessage());
       
    }
    return levelPicklistValues;
    
}

   /**
* Method to get picklist values of the picklist fields for an object
* @return picklistValueClass            
*                
*/   
@AuraEnabled
public static picklistValueClass returnAllPickListValues (){
    
    String coverageArea = 'NSP_Coverage_Area__c';
    String   businessVertical ='NSP_Business_Vertical__c';
    String   oneToTen = 'NSP_HowFamiliar_is_the_company_with_PEOs__c';
    String   insperityHistory='NSP_Insperitys_History_with_This_Partner__c';
    
    picklistValueClass picklistValueClassObject = new picklistValueClass();
    try{
        String objectName = NSP_SalesConstants.Account;
        picklistValueClassObject.coverageArea = getPiklistValues(objectName,coverageArea);
        picklistValueClassObject.businessVertical = getPiklistValues(objectName,businessVertical);
        picklistValueClassObject.oneToTen = getPiklistValues(objectName,oneToTen);
        picklistValueClassObject.insperityHistory = getPiklistValues(objectName,insperityHistory);
    }Catch(Exception Ex){
        throw new AuraHandledException(ex.getMessage());
    }
    return picklistValueClassObject;
}

 /**
* Method to get dependent picklist values
* @param objDetail sObject  defines the sobject on which the field is present.  
*  @return String  contrfieldApiName controlling field name           
*  @return String  depfieldApiName controldependent field name                
*/
@AuraEnabled 
public static Map<String, List<String>> getDependentMap(sObject objDetail, string contrfieldApiName,string depfieldApiName) {
    try{
        return NSP_CreateReferralLead.getDependentMap(objDetail, contrfieldApiName,depfieldApiName);
    }Catch(Exception Ex){
    throw new AuraHandledException(ex.getMessage());
    }
}

       /**
* Wrapper Class
*/

public  class picklistValueClass{
    @AuraEnabled public   List<String> coverageArea;
    @AuraEnabled public List<String> businessVertical;
    @AuraEnabled public List<String> oneToTen;
    @AuraEnabled public List<String> insperityHistory;      
}
}