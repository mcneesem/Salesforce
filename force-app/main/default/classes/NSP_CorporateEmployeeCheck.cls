/**
Apex Class Name      :  NSP_CorporateEmployeeCheck
Version              :  1.0                                                                          
Created Date         :  01/8/2023  
Function             :  This class describes about to check NSP_CorporateEmployeeEE__c checkbox on case based on different combinations
Story                :  STY-03784                                                                  
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
public class NSP_CorporateEmployeeCheck {
    // test w/ NSP_CorporateEmployeeCheckTest,NSP_CaseTriggerHelperTest (80%)
    
    private static Map<Id,Account> accIdAccMap ;
    private static Map<Id, List<AccountContactRelation>> conIdListOfACRMap; 
    private static Map<Id, Id> conIdInspAccIdMap ;
    private static Map<Id, Id> conIdInspNotTerminatedAccIdMap;
    private static Map<Id, List<AccountContactRelation>> conIdNotTerminateACRdMap; 
    private static Map<Id, List<AccountContactRelation>> conIdTerminatedOrBlankACRMap;
    private static Map<Id, List<AccountContactRelation>> conIdACRListMap;
    private static Id insperityAccountId = System.Label.NSP_Insperity_Account;
    /***********************************************************************************************
* MethodName: stampCorporateEmployeeEECheckbox
* Description : This method maps the Corporate EE checkbox based on case Contact ACR's Combination
* Params:      Set<Id> acrAccIdSet, Set<Id> acrConIdSet, List<Case> newList
* Story: STY-03784
* ********************************************************************************************/
    public static void stampCorporateEmployeeEECheckbox(Set<Id> acrAccIdSet, Set<Id> acrConIdSet, List<Case> newList, Boolean isAcr){
        
        accIdAccMap =new Map<Id,Account>([SELECT Id, Name FROM Account WHERE Id IN: acrAccIdSet]);
        
        conIdListOfACRMap = new Map<Id, List<AccountContactRelation>>();
        conIdInspAccIdMap = new Map<Id, Id>();
        conIdInspNotTerminatedAccIdMap = new Map<Id, Id>();
        conIdNotTerminateACRdMap = new Map<Id, List<AccountContactRelation>>();
        conIdTerminatedOrBlankACRMap = new Map<Id, List<AccountContactRelation>>();
        conIdACRListMap = new Map<Id, List<AccountContactRelation>>();
        List<Case> cseToUpdateList = new List<Case>();
        
        for(AccountContactRelation acr : [SELECT Id, AccountId, ContactId, NSP_Employee_Status__c FROM AccountContactRelation WHERE ContactId IN: acrConIdSet]){
            getconIdACRListMap(acr); // Framing the map of Con and ACRs
            insperityAccountId = test.isRunningTest() ? acr.AccountId : System.Label.NSP_Insperity_Account;
            if(checkForInspAcc(accIdAccMap,conIdInspAccIdMap,null,acr,true)){
                conIdInspAccIdMap.put(acr.ContactId, acr.AccountId);
                if(acr.NSP_Employee_Status__c != NSP_ServiceConstants.TERMINATED_STATUS){
                    conIdInspNotTerminatedAccIdMap.put(acr.ContactId, acr.AccountId);
                }
            } 
            
            getconIdTerminatedACRMap(acr);  // framing the map of Contact and Terminated or Blank Employee Status ACRs
            getconIdNotTerminateACRdMap(acr); // framing the map of Contact and Not Terminated or Not Blank Employee Status ACRs 
            
        }        
        try{
            for(Case cse : newList){
                cse.NSP_CorporateEmployeeEE__c = oneAcrWithInsperityAccount(cse);
                cseToUpdateList.add(cse);
            }
            
            if(!cseToUpdateList.isEmpty() && isAcr){
                List<Database.SaveResult> results = Database.update(cseToUpdateList,false); 
                NSP_ErrorLogHandler.logSaveResultsException('NSP_CorporateEmployeeCheck', 'stampCorporateEmployeeEECheckbox', results );
            }
            
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        } 
    }
    
    /***********************************************************************************************
* MethodName: getconIdTerminatedACRMap
* Description : Map of ContactId and Terminated or null Employee status ACRs
* Params:      AccountContactRelation acr
* Story: STY-03784
* ********************************************************************************************/
    private static void getconIdACRListMap(AccountContactRelation acr){
        if(conIdACRListMap.containsKey(acr.ContactId)) {
            conIdACRListMap.get(acr.ContactId).add(acr);
        }else{
            conIdACRListMap.put(acr.ContactId, new list<AccountContactRelation>{acr}); 
        }
    }
    
    /***********************************************************************************************
* MethodName: getconIdTerminatedACRMap
* Description : Map of ContactId and Terminated or null Employee status ACRs
* Params:      AccountContactRelation acr
* Story: STY-03784
* ********************************************************************************************/
    private static void getconIdTerminatedACRMap(AccountContactRelation acr){
        if(acr.NSP_Employee_Status__c == NSP_ServiceConstants.TERMINATED_STATUS || acr.NSP_Employee_Status__c == null){
            if(conIdTerminatedOrBlankACRMap.containsKey(acr.ContactId)) {
                conIdTerminatedOrBlankACRMap.get(acr.ContactId).add(acr);
            }else{
                conIdTerminatedOrBlankACRMap.put(acr.ContactId, new list<AccountContactRelation>{acr}); 
            }
        }  
    }
    
    /***********************************************************************************************
* MethodName: getconIdNotTerminateACRdMap
* Description : Map of ContactId and not Terminated Employee status ACRs
* Params:      AccountContactRelation acr
* Story: STY-03784
* ********************************************************************************************/
    private static void getconIdNotTerminateACRdMap(AccountContactRelation acr){
        if(acr.NSP_Employee_Status__c != null && acr.NSP_Employee_Status__c != NSP_ServiceConstants.TERMINATED_STATUS){
            if(conIdNotTerminateACRdMap.containsKey(acr.ContactId)) {
                conIdNotTerminateACRdMap.get(acr.ContactId).add(acr);
            }else{
                conIdNotTerminateACRdMap.put(acr.ContactId, new list<AccountContactRelation>{acr}); 
            } 
        }
    }
    
    /***********************************************************************************************
    * MethodName: oneAcrWithInsperityAccount
    * Description : A case is created against a contact where the Contact has only one ACR AND that is with the Insperity Account
    * Params:      case cse
    * Story: STY-03784
    * ********************************************************************************************/
    private static Boolean oneAcrWithInsperityAccount(case cse){
        Boolean isCorpCase = false;
        if(!conIdACRListMap.isEmpty()
            && conIdACRListMap.get(cse.contactId).size() == 1
            && conIdInspAccIdMap.get(cse.ContactId) != null
            && checkForInspAcc(accIdAccMap,conIdInspAccIdMap,cse,null,false)
        ){
            isCorpCase = true;
        }else{
            isCorpCase = contactWasclientEmployee(cse);
        }
        return isCorpCase;
    }
    
    /***********************************************************************************************
* MethodName: contactWasclientEmployee
* Description : A case is created against a contact where the contact has more than one ACR AND 
the Employee Status does not = Terminated on the Insperity account AND 
the Employee status does = Terminated on the other ACRs OR the ACR has no Employee Status.
* Params:      case cse
* Story: STY-03784
* ********************************************************************************************/
    private static Boolean contactWasclientEmployee(case cse){
        Boolean isCorpCase = false;
        
        if(!conIdInspNotTerminatedAccIdMap.isEmpty() && 
           String.isNotBlank(conIdInspNotTerminatedAccIdMap.get(cse.ContactId)) &&
           !conIdNotTerminateACRdMap.get(cse.contactId).isEmpty() && !conIdTerminatedOrBlankACRMap.isEmpty() &&
           !conIdTerminatedOrBlankACRMap.get(cse.contactId).isEmpty()){
            isCorpCase = true;
           }else{
            isCorpCase = contactWasInsperityEmployee(cse);
           }
        
        return isCorpCase;
    }
    
    /***********************************************************************************************
* MethodName: contactWasInsperityEmployee
* Description : A case is created against a contact where the contact has more than one ACR AND 
where the Employee Status on the Insperity Account= Terminated and 
the Employee Status on one of the other ACRs does not = Terminated
* Params:      case cse
* Story: STY-03784
* ********************************************************************************************/
    private static Boolean contactWasInsperityEmployee(Case cse){
        Boolean isCorpCase = false;
        
        if(!conIdInspNotTerminatedAccIdMap.isEmpty() &&  // AC_03
           String.isBlank(conIdInspNotTerminatedAccIdMap.get(cse.ContactId)) &&
           !conIdNotTerminateACRdMap.get(cse.contactId).isEmpty()){
            isCorpCase = true;
           }else{
            isCorpCase = contactWorksForBothInsperityAndClient(cse);
           }
        
        return isCorpCase;     
    }
    
    /***********************************************************************************************
    * MethodName: contactWorksForBothInsperityAndClient
    * Description :  A case is created against a contact where the contact has more than one ACR AND 
    * the Employee Status does not = Terminated on the Insperity account AND 
    * the Employee status does not = Terminated on the other ACRs
    * Params:      case cse
    * Story: STY-03784
    * ********************************************************************************************/
    private static Boolean contactWorksForBothInsperityAndClient(Case cse){
        Boolean isCorpCase = false;
        if(!conIdInspNotTerminatedAccIdMap.isEmpty()
            && String.isNotBlank(conIdInspNotTerminatedAccIdMap.get(cse.ContactId))
            && !conIdNotTerminateACRdMap.get(cse.ContactId).isEmpty()
        ){
            if(String.isNotBlank(conIdInspAccIdMap.get(cse.ContactId)) 
                && checkForInspAcc(accIdAccMap,conIdInspAccIdMap,cse,null,false)
            ){
                isCorpCase = true;
            }
        }else{
            isCorpCase = contactDoNotWorksForBothInsperityAndClient(cse);
        }
        return isCorpCase;
    }
    
    /***********************************************************************************************
* MethodName: contactDoNotWorksForBothInsperityAndClient
* Description : A case is created against a contact where the contact has more than one ACR AND where all Employee Statuses = Terminated or Null
* Params:      case cse
* Story: STY-03784
* ********************************************************************************************/
    private static Boolean contactDoNotWorksForBothInsperityAndClient(Case cse){
        Boolean isCorpCase = false;
        
        if(!conIdTerminatedOrBlankACRMap.isEmpty() && !conIdTerminatedOrBlankACRMap.get(cse.ContactId).isEmpty() && conIdNotTerminateACRdMap.isEmpty()){
            isCorpCase = false; 
        }
        
        return isCorpCase;
    }

    /***********************************************************************************************
    * MethodName: CheckforInsperityAccount
    * Description : Method to check if the Account is insperity Account or Not
    * Params:  Map<Id,Account> accIdAccMap,Map<Id, Id> conIdInspAccIdMap,case cse,AccountContactRelation acr,isAcr
    * Story: Bug-237020
    * ********************************************************************************************/
    private static Boolean checkForInspAcc(Map<Id,Account> accIdAccMap,Map<Id, Id> conIdInspAccIdMap,case cse,AccountContactRelation acr,Boolean isAcr){
        Boolean con = false;
        if(isAcr){
            if(accIdAccMap.isEmpty()){
                con = acr.AccountId == insperityAccountId;
            }else{
                con = accIdAccMap.containsKey(acr.AccountId) && accIdAccMap.get(acr.AccountId).Id == insperityAccountId;
            }
        }else{
            if(accIdAccMap.isEmpty()){
                con = conIdInspAccIdMap.get(cse.ContactId) == insperityAccountId;
            }else{
                con = accIdAccMap.containsKey(cse.AccountId) && accIdAccMap.get(conIdInspAccIdMap.get(cse.ContactId)).Id == insperityAccountId;
            }
        }
        return con;
    }
}