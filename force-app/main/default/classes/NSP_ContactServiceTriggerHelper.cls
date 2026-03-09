/* 
*    Class Name  : NSP_ContactServiceTriggerHelper
*    @Description: Represents the Contact trigger helper of Service Stream which handles all the logic.
*    @Date       : 05/11/2022
*/

public with sharing class NSP_ContactServiceTriggerHelper {
     // test w/ NSP_ContactServiceTriggerHelperTest (89%)
    /**
    * Iterates throught the list of new Contact and passes the required attributes to other methods.
    * @param newList List of New Contact.
    * @return void
    *                
    */
    
    public void beforeInsertDirector(List<Contact> newList) {
        try{
            For(Contact conObj : newList){
                // Populating Preferred First Name if Pref First Name is left blank
                if(conObj.NSP_Preferred_First_Name__c == null && conObj.FirstName != null){
                    conObj.NSP_Preferred_First_Name__c = conObj.FirstName;
                }
            }
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    
    /**
    * Iterates throught the list of new Contact and passes the required attributes to other methods.
    * @param oldMap List of New Contact.
    * @param newMap List of New Contact.
    * @return void
    *                
    */
    
    public void beforeUpdateDirector(Map<Id, Contact> newMap,Map<Id, Contact> oldMap) {
        try{
            Map<String,AccountContactRelation> acrMapWithAccConId ;
            if(newMap != null){
               acrMapWithAccConId = NSP_ContactServiceTriggerHelper.getACRData(newMap);
            }
            for(Contact conObj : newMap.values()){
                // Populating Preferred First Name if Pref First Name is left blank
                if(newMap.get(conObj.id).NSP_Preferred_First_Name__c != oldMap.get(conObj.id).NSP_Preferred_First_Name__c 
                   && conObj.NSP_Preferred_First_Name__c == null 
                   && conObj.FirstName != null){
                       conObj.NSP_Preferred_First_Name__c = conObj.FirstName;  
                   }
                   //Updating Pin Validated to false, when Service Request Channel changes from Phone to null - DF-03665
                if(conObj.NSP_Service_Request_Channel__c != oldMap.get(conObj.id).NSP_Service_Request_Channel__c 
                && conObj.NSP_Service_Request_Channel__c == null && oldMap.get(conObj.id).NSP_Service_Request_Channel__c == 'Phone'){
                    conObj.NSP_Pin_Validated__c = false;  
                }
                //Update primary details on contact based on account  
                if(oldMap != null && conObj.AccountId != null && conObj.AccountId != oldMap.get(conObj.Id).AccountId){
                    AccountContactRelation acrRecord = acrMapWithAccConId.get((String)conObj.AccountId + conObj.Id);
                    if(acrRecord != null){
                        conObj.NSP_Work_email__c = acrRecord.NSP_Work_Email__c;
                        conObj.NSP_Work_Phone__c = acrRecord.NSP_Work_Phone__c;
                        conObj.NSP_Employee_Status__c = acrRecord.NSP_Employee_Status__c;
                        conObj.NSP_Status_Date__c = acrRecord.NSP_Status_Date__c;
                        conObj.NSP_Job_Title__c = acrRecord.NSP_Job_Title__c;
                    }
                }
            }     
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
    /**
    * @MethodName: updateSSNField
    * @Description: This method is used to update Contact SSN Fields on before Insert or update
    * @param : List<Contact> newList, Map<Id, Contact> oldMap
    * @createdDate : 01/02/2023
    * @Defect : STY-02659
    * @return void                          
    */
    public void updateSSNField( List<Contact> newList , Map<Id,Contact> oldMap ) {
        if ( newList != null ) {
            for ( Contact con : newList ) {
                Contact oldCon = ( ( oldMap != null ) ? oldMap.get( con.Id ) : null );
                if ( ( oldCon == null )
                    || ( con.NSP_SSN_Unmasked__c != oldCon.NSP_SSN_Unmasked__c )
                    || ( con.NSP_SSN__c != oldCon.NSP_SSN__c )
                    )
                {
                    con.NSP_SSN_Masked__c = null; // reset masked field...
                    if ( String.isNotBlank( con.NSP_SSN__c ) || String.isNotBlank( con.NSP_SSN_Unmasked__c ) ) {
                        if ( String.isNotBlank( con.NSP_SSN_Unmasked__c ) ) {
                            con.NSP_SSN__c = con.NSP_SSN_Unmasked__c;
                        }
                        if ( String.isNotBlank( con.NSP_SSN__c ) ) {
                            // rebuild masked field...
                            con.NSP_SSN_Masked__c = '';
                            String ssn = con.NSP_SSN__c.replaceAll( '-' , '' );
                            for ( Integer index=0 ; index < ssn.length() ; index++ ) {
                                if ( index == 0 ) {
                                    con.NSP_SSN_Masked__c = 'X';
                                } else if ( ( index == 3 ) || ( index == 5 ) ) {
                                    con.NSP_SSN_Masked__c += '-X';
                                } else {
                                    con.NSP_SSN_Masked__c += 'X';
                                }
                            }
                            con.NSP_SSN_Unmasked__c = '';
                        }
                    }
                }
            }
        }
    }
    
    /**
    * @MethodName: updateDateofbirthfield
    * @Description: This method is used to update Contact Birthday, SSN, DOB Fields on before Insert or update
    * @param : List<Contact> newList, Map<Id, Contact> oldMap
    * @createdDate : 05/02/2023
    * @Defect : STY-02659
    * @return void                          
    */
    
    public void updateBirthday( List<Contact> newList , Map<Id,Contact> oldMap ) {
        if ( newList != null ) {
            for ( Contact con : newList ) {
                Contact oldCon = ( ( oldMap != null ) ? oldMap.get( con.Id ) : null );
                if ( ( oldCon == null )
                    || ( con.NSP_Date_Of_Birth_Unmasked__c != oldCon.NSP_Date_Of_Birth_Unmasked__c )
                    || ( con.NSP_Date_of_Birth__c != oldCon.NSP_Date_of_Birth__c )
                    )
                {
                    con.NSP_Birthday__c = null;
                    con.NSP_Date_Of_Birth_Masked__c = null;
                    con.NSP_Is_Masked__c = false;
                    con.NSP_Is_Unmasked__c = false;
                    if ( ( con.NSP_Date_of_Birth__c != null ) || ( con.NSP_Date_Of_Birth_Unmasked__c != null ) ) {
                        if ( con.NSP_Date_Of_Birth_Unmasked__c !=null ) {
                            con.NSP_Date_of_Birth__c = con.NSP_Date_Of_Birth_Unmasked__c;
                        }
                        con.NSP_Date_Of_Birth_Masked__c = 'XX/XX/XXXX';
                        con.NSP_Is_Masked__c = true;
                        con.NSP_Is_Unmasked__c = true;
                        con.NSP_Date_Of_Birth_Unmasked__c = null;
                        //Update Birthday field
                        updateBirthdayBasedOnDOB(con); 
                    }
                }
            }
        }
    }

    private static void updateBirthdayBasedOnDOB( Contact con ) {
        if ( ( con != null ) && ( con.NSP_Date_of_Birth__c != null ) ) {
            Date dt = con.NSP_Date_of_Birth__c;
            Integer day = dt.Day(); 
            Integer month = dt.Month();
            if ( month == 1 ) {
                con.NSP_Birthday__c = 'JAN ' + day;
            } else if ( month == 2 ) {
                con.NSP_Birthday__c = 'FEB ' + day;
            } else if ( month == 3 ) {
                con.NSP_Birthday__c = 'MAR ' + day;
            } else if ( month == 4 ) {
                con.NSP_Birthday__c = 'APR ' + day;
            } else if ( month == 5 ) {
                con.NSP_Birthday__c = 'MAY ' + day;
            } else if ( month == 6 ) {
                con.NSP_Birthday__c = 'JUN ' + day;
            } else if ( month == 7 ) {
                con.NSP_Birthday__c = 'JUL ' + day;
            } else if ( month == 8 ) {
                con.NSP_Birthday__c = 'AUG ' + day;
            } else if ( month == 9 ) {
                con.NSP_Birthday__c = 'SEP ' + day;
            } else if ( month == 10 ) {
                con.NSP_Birthday__c = 'OCT ' + day;
            } else if ( month == 11 ) {
                con.NSP_Birthday__c = 'NOV ' + day;
            } else if ( month == 12 ) {
                con.NSP_Birthday__c = 'DEC ' + day;
            }
        }
    }

    private static Map<String,AccountContactRelation> getACRData(Map<Id, Contact> newMap)  {
        Map<String,AccountContactRelation> acrMapWithAccConId = new Map<String,AccountContactRelation>();
        for(AccountContactRelation acr : [Select Id, AccountId, ContactId, NSP_Work_Email__c, NSP_Work_Phone__c, NSP_Employee_Status__c, NSP_Status_Date__c, NSP_Job_Title__c from AccountContactRelation where ContactId in :newMap.keySet()]){
            if(acr.AccountId != null && acr.ContactId != null){
                acrMapWithAccConId.put((String)acr.AccountId + acr.ContactId, acr);
            }
        }
        return acrMapWithAccConId;
    }

}