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
            accountRecord.WebForm__c = True;
       
            //set the account reocord type as Partner 
            accountRecord.Recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('NSP_Partner_Client').getRecordTypeId();

            Contact nContact =(Contact)JSON.deserialize(contactObject,Contact.class);

            //By passing the duplicate rules
            Database.DMLOptions dbDML = new Database.DMLOptions(); 
            dbDML.DuplicateRuleHeader.allowSave = true;
            dbDML.DuplicateRuleHeader.runAsCurrentUser = true;

            //  Seach if there is an existing Partner based on the required fields
            List<Account> findAccts = [SELECT id FROM Account WHERE Name = :accountRecord.Name AND 
            BillingStreet = :accountRecord.BillingStreet AND BillingCity = :accountRecord.BillingCity AND 
            BillingState = :accountRecord.BillingState AND BillingPostalCode = :accountRecord.BillingPostalCode ORDER BY id];

            if(findAccts.size() > 0){

                //  Get the first matching Account
                Account oldAcct = findAccts[0];

                oldAcct.Recordtypeid = accountRecord.Recordtypeid;
                oldAcct.Type = accountRecord.Type;
                oldAcct.BillingCountry = accountRecord.BillingCountry;

                if(!String.isBlank(accountRecord.NSP_Coverage_Area__c)){
                    oldAcct.NSP_Coverage_Area__c = accountRecord.NSP_Coverage_Area__c;
                }

                if(!String.isBlank(accountRecord.NSP_Business_Vertical__c)){
                    oldAcct.NSP_Business_Vertical__c = accountRecord.NSP_Business_Vertical__c;    
                }

                if(!String.isBlank(accountRecord.NSP_Other_Vertical__c)){
                    oldAcct.NSP_Other_Vertical__c = accountRecord.NSP_Other_Vertical__c;
                }

                if(!String.isBlank(accountRecord.NSP_Partners_Business_Demographics__c)){
                    oldAcct.NSP_Partners_Business_Demographics__c = accountRecord.NSP_Partners_Business_Demographics__c;
                }

                if(!String.isBlank(accountRecord.NSP_Partners_Business_Community_Network__c)){
                    oldAcct.NSP_Partners_Business_Community_Network__c = accountRecord.NSP_Partners_Business_Community_Network__c;
                }

                if(!String.isBlank(accountRecord.NSP_Expected_Annual_Business_Growth__c)){
                    oldAcct.NSP_Expected_Annual_Business_Growth__c = accountRecord.NSP_Expected_Annual_Business_Growth__c;
                }

                if(!String.isBlank(accountRecord.NSP_Partners_Chief_Decision_Maker__c)){
                    oldAcct.NSP_Partners_Chief_Decision_Maker__c = accountRecord.NSP_Partners_Chief_Decision_Maker__c;
                }

                if(!String.isBlank(accountRecord.NSP_Insperitys_History_with_This_Partner__c)){
                    oldAcct.NSP_Insperitys_History_with_This_Partner__c = accountRecord.NSP_Insperitys_History_with_This_Partner__c;
                }

                if(!String.isBlank(accountRecord.NSP_Other_History_With_Partner__c)){
                    oldAcct.NSP_Other_History_With_Partner__c = accountRecord.NSP_Other_History_With_Partner__c;   
                }

                if(!String.isBlank(accountRecord.NSP_How_Long_Have_You_Had_a_Relation__c)){
                    oldAcct.NSP_How_Long_Have_You_Had_a_Relation__c = accountRecord.NSP_How_Long_Have_You_Had_a_Relation__c;
                }

                if(!String.isBlank(accountRecord.NSP_HowFamiliar_is_the_company_with_PEOs__c)){
                    oldAcct.NSP_HowFamiliar_is_the_company_with_PEOs__c = accountRecord.NSP_HowFamiliar_is_the_company_with_PEOs__c;
                }

                if(!String.isBlank(accountRecord.NSP_How_FamiliarIsCompany_with_Insperity__c)){
                    oldAcct.NSP_How_FamiliarIsCompany_with_Insperity__c = accountRecord.NSP_How_FamiliarIsCompany_with_Insperity__c;
                }
            
                if(!String.isBlank(accountRecord.NSP_DescribeBusinessFitWith_This_Partner__c)){
                    oldAcct.NSP_DescribeBusinessFitWith_This_Partner__c = accountRecord.NSP_DescribeBusinessFitWith_This_Partner__c;
                }

                if(!String.isBlank(accountRecord.NSP_Why_isThisRelationGood_For_Insperity__c)){
                    oldAcct.NSP_Why_isThisRelationGood_For_Insperity__c = accountRecord.NSP_Why_isThisRelationGood_For_Insperity__c;
                }

                if(!String.isBlank(accountRecord.NSP_DescribeTheJVPHowitllBe_Piloted__c)){
                    oldAcct.NSP_DescribeTheJVPHowitllBe_Piloted__c = accountRecord.NSP_DescribeTheJVPHowitllBe_Piloted__c;
                }
            
                if(!String.isBlank(accountRecord.NSP_ObstaclesAnticipatedInMutualBenifits__c)){
                    oldAcct.NSP_ObstaclesAnticipatedInMutualBenifits__c = accountRecord.NSP_ObstaclesAnticipatedInMutualBenifits__c;
                }

                if(!String.isBlank(accountRecord.NSP_If_So_WhoandHow_Successful_are_They__c)){
                    oldAcct.NSP_If_So_WhoandHow_Successful_are_They__c = accountRecord.NSP_If_So_WhoandHow_Successful_are_They__c;
                }

                if(!String.isBlank(accountRecord.NSP_Do_They_Have_Any_Other_Partnerships__c)){
                    oldAcct.NSP_Do_They_Have_Any_Other_Partnerships__c = accountRecord.NSP_Do_They_Have_Any_Other_Partnerships__c;
                }
            
                if(!String.isBlank(accountRecord.NSP_Have_You_Worked_With_Them_Before_Now__c)){
                    oldAcct.NSP_Have_You_Worked_With_Them_Before_Now__c = accountRecord.NSP_Have_You_Worked_With_Them_Before_Now__c;
                }

                if(!String.isBlank(accountRecord.NSP_AnyActiveOpportunitiesInThe_Pipeline__c)){
                    oldAcct.NSP_AnyActiveOpportunitiesInThe_Pipeline__c = accountRecord.NSP_AnyActiveOpportunitiesInThe_Pipeline__c;
                }

                if(!String.isBlank(accountRecord.NSP_WhatDoesSuccessLookLike_inShortTerm__c)){
                    oldAcct.NSP_WhatDoesSuccessLookLike_inShortTerm__c = accountRecord.NSP_WhatDoesSuccessLookLike_inShortTerm__c;
                }
            
                if(!String.isBlank(accountRecord.NSP_Short_Term_KPIs_to_Measure_Success__c)){
                    oldAcct.NSP_Short_Term_KPIs_to_Measure_Success__c = accountRecord.NSP_Short_Term_KPIs_to_Measure_Success__c;
                }

                if(!String.isBlank(accountRecord.NSP_WhatSuccessLooksLike_in_Intermediate__c)){
                    oldAcct.NSP_WhatSuccessLooksLike_in_Intermediate__c = accountRecord.NSP_WhatSuccessLooksLike_in_Intermediate__c;
                }

                if(!String.isBlank(accountRecord.NSP_What_Intermediate_Term_KPIs_used__c)){
                    oldAcct.NSP_What_Intermediate_Term_KPIs_used__c = accountRecord.NSP_What_Intermediate_Term_KPIs_used__c;    
                }
            
                if(!String.isBlank(accountRecord.NSP_Why_isThisBetterFitFor_Affiliate_Pgm__c)){
                    oldAcct.NSP_Why_isThisBetterFitFor_Affiliate_Pgm__c = accountRecord.NSP_Why_isThisBetterFitFor_Affiliate_Pgm__c;    
                }

                Database.update(oldAcct, dbDML);

                //  Search if Contact already exists in this Account
                List<Contact> findContact = [SELECT id FROM Contact WHERE FirstName =: nContact.FirstName AND 
                LastName =: nContact.LastName AND Email =: nContact.Email AND accountid =: oldAcct.id];

                //  If Contact exists then update info
                if(findContact.size() > 0){

                    Contact oldContact = findContact[0];
                    
                    oldContact.Title = nContact.Title;
                    oldContact.Phone = nContact.Phone;

                    Database.update(oldContact, dbDML); 
                }
                else{

                    //  Create new Contact
                    nContact.accountid = oldAcct.id;
                    Database.insert(nContact, dbDML); 
                }

            }
            else{
            
                //Inseting the accounts
                Database.insert(accountRecord, dbDML);
                /* As part of STY-02211, creating contact along with Account Record */
              
                nContact.accountid = accountRecord.id;
                Database.insert(nContact, dbDML);
                /* As part of STY-02211, creating contact along with Account Record */
                //Setting response as success             
            }

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