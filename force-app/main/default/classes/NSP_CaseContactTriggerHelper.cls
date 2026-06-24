/**
* Represents the Case Contact Trigger Helper which handles all the logic.
* Version - STY           - DESCRIPTION                                      - TAG

* V1.0    - STY-02660     - Multiple Contacts on Case 	                     -<STY-03685>

*/
public class NSP_CaseContactTriggerHelper {
    // test w/ NSP_CaseContactTriggerHelperTest (82%)

    private static final string NSP_CASE_TRIGGERHELPER = 'NSP_CaseContactTriggerHelper';
    /***********************************************************************************************
* MethodName: beforeInsertDirector
* Description : Iterates throught the list of new Case Contacts Records and passes the Case Ids and Case Contacts to other methods.
* Params:       List <NSP_Case_Contacts__c> newList
* ********************************************************************************************/ 
    
    public void beforeInsertDirector(List<NSP_Case_Contacts__c> newList){
        Set<Id> caseIdSet = new Set<Id>();
        for(NSP_Case_Contacts__c cseCon : newList){
            if( String.isNotBlank(cseCon.NSP_Case__c) && 
               String.isNotBlank(cseCon.NSP_Contact__c) && 
               cseCon.NSP_IsPrimary__c == true){
                   caseIdSet.add(cseCon.NSP_Case__c);
               }
        }
        if(!caseIdSet.isEmpty()){
            checkCaseContactIsPrimary(caseIdSet, newList);
        } 
    }
    
       /***********************************************************************************************
* MethodName: afterInsertDirector
* Description : Iterates throught the list of new Case COntacts Records and passes the Case Ids and Case Contacts to other methods.
* Params:      Map < Id, NSP_Case_Contacts__c > cseConNewMap, Map < Id, NSP_Case_Contacts__c > cseConOldMap 
* ********************************************************************************************/
    
    public void afterInsertDirector(List<NSP_Case_Contacts__c> newList, Map < Id, NSP_Case_Contacts__c > cseConNewMap) {
        Map<Id, Id> caseConIdMap = new Map<Id,Id>();
        Set<Id> caseIdSet = new Set<Id>();
        List<Case> caseToUpdateList = new List<Case>();
        for(NSP_Case_Contacts__c cseCon : newList){
            if(cseCon.NSP_IsPrimary__c == true){                   
                   caseConIdMap.put(cseCon.NSP_Case__c, cseCon.NSP_Contact__c);
               }
            caseIdSet.add(cseCon.NSP_Case__c);
        }
        if(!caseConIdMap.isEmpty()){
            updateContactonCase(caseConIdMap);
        } 
        
        // Added as part of STY-3784
        if(!caseIdSet.isEmpty()){
            for(case cse: [SELECT Id, NSP_CorporateEmployeeEE__c, (SELECT Id From Case_Contact_Roles__r) FROM Case WHERE Id IN: caseIdSet AND NSP_CorporateEmployeeEE__c = true]){
                if(cse.Case_Contact_Roles__r.size() > 1){
                    caseToUpdateList.add(cse);
                }
            }
            if(!caseToUpdateList.isEmpty()){
                updateCorporateEmployeecheckBox(caseToUpdateList); 
            }
        }
    }
    
    /***********************************************************************************************
* MethodName: updateCorporateEmployeecheckBox
* Description : This method describes about unchecking of NSP_CorporateEmployeeEE__c on case, if the case has more than one Contacts
* Params:      List<Case> caseList
* Story: STY-3784
* ********************************************************************************************/
    public static void updateCorporateEmployeecheckBox(List<Case> caseList){
        Boolean isNewCorpEEEnable = Case_Settings__c.getInstance(UserInfo.getUserId() ).Enable_New_Corp_EE_Logic__c;
        if(!isNewCorpEEEnable){
            for(Case cse : caseList){
                cse.NSP_CorporateEmployeeEE__c = false;
            }
            try {
                List<Database.SaveResult> results = Database.update( caseList , false ); 
                NSP_ErrorLogHandler.logResults(
                    NSP_CaseContactTriggerHelper.class.getName() ,
                    'updateCorporateEmployeecheckBox' ,
                    results
                );
            } catch ( Exception e ) {
                NSP_CaseContactTriggerHelper.handleException(
                    e ,
                    'updateCorporateEmployeecheckBox'
                );
            }
        }
    }

    /***********************************************************************************************
* MethodName: beforeUpdateDirector
* Description : Iterates throught the list of new Case COntacts Records and passes the Case Ids and Case Contacts to other methods.
* Params:      Map < Id, NSP_Case_Contacts__c > cseConNewMap, Map < Id, NSP_Case_Contacts__c > cseConOldMap 
* ********************************************************************************************/
    
    public void beforeUpdateDirector(Map < Id, NSP_Case_Contacts__c > cseConNewMap, Map < Id, NSP_Case_Contacts__c > cseConOldMap) {
        Set<Id> caseIdSet = new Set<Id>();
        for(NSP_Case_Contacts__c cseCon : cseConNewMap.values()){
            if(cseCon.NSP_IsPrimary__c == true &&
               cseConOldMap.get(cseCon.Id).NSP_IsPrimary__c == false){
                   caseIdSet.add(cseCon.NSP_Case__c);
               }
        }
        if(!caseIdSet.isEmpty()){
            checkCaseContactIsPrimary(caseIdSet, cseConNewMap.values());
        } 
    }
    
    /***********************************************************************************************
* MethodName: afterUpdateDirector
* Description : Iterates throught the list of new Case COntacts Records and passes the Case Ids and Case Contacts to other methods.
* Params:      Map < Id, NSP_Case_Contacts__c > cseConNewMap, Map < Id, NSP_Case_Contacts__c > cseConOldMap 
* ********************************************************************************************/
    
    public void afterUpdateDirector(Map < Id, NSP_Case_Contacts__c > cseConNewMap, Map < Id, NSP_Case_Contacts__c > cseConOldMap) {
        Map<Id, Id> caseConIdMap = new Map<Id,Id>();
        for(NSP_Case_Contacts__c cseCon : cseConNewMap.values()){
            if(cseCon.NSP_IsPrimary__c == true &&
               cseConOldMap.get(cseCon.Id).NSP_IsPrimary__c == false){                   
                   caseConIdMap.put(cseCon.NSP_Case__c, cseCon.NSP_Contact__c);
               }
        }
        if(!caseConIdMap.isEmpty()){
            updateContactonCase(caseConIdMap);
        } 
    }

    //
    // MethodName: updateContactonCase
    // Description : If Case Contact Primary Checkbox is updated to true, then that contact will be mapped on the respective Case.
    // Params: caseConIdMap
    //
    private void updateContactonCase( Map<Id,Id> caseConIdMap ) {
        if ( caseConIdMap != null ) {
            try{
                List<Case> caseToUpdateList = new List<Case>();
                for ( Case cse : [
                            SELECT Id , ContactId
                            FROM Case
                            WHERE (
                                ( Id IN :caseConIdMap.keySet() )
                                AND ( Status != 'Closed' )
                            )
                        ]
                    )
                {
                    if ( caseConIdMap.containsKey( cse.Id ) ) {
                        cse.ContactId = caseConIdMap.get( cse.Id );
                        caseToUpdateList.add( cse );
                    }
                }
                if ( !caseToUpdateList.isEmpty() ) {
                    List<Database.SaveResult> results = Database.update( caseToUpdateList , False );
                    NSP_ErrorLogHandler.logResults(
                        NSP_CaseContactTriggerHelper.class.getName() ,
                        'updateContactonCase' ,
                        results
                    );
                }
            } catch ( Exception e ) {
                NSP_CaseContactTriggerHelper.handleException(
                    e ,
                    'updateContactonCase'
                );
            }
        }
    }

    private static void handleException( Exception e , String methodName ) {
        if ( e != null ) {
            NSP_ErrorLogHandler.logException(
                NSP_CaseContactTriggerHelper.class.getName() ,
                methodName ,
                e
            );
        }
    }

    /***********************************************************************************************
* MethodName: checkCaseContactIsPrimary
* Description : Check the current IsPrimary checkbox on Case Contact Record if it matches the criteria mentioned in the story.
* Params:       Set<Id> caseIdSet, List<NSP_Case_Contacts__c> caseContactRecList
* ********************************************************************************************/
    
    public void checkCaseContactIsPrimary(Set<Id> caseIdSet, List<NSP_Case_Contacts__c> caseContactRecList){
        //Map of Case and Case Contact Recs which has current Is Primary checked
        Map<Id, NSP_Case_Contacts__c> primaryCheckedCaseContactMap = new Map<Id, NSP_Case_Contacts__c>();
        List<NSP_Case_Contacts__c> checkedcaseContactRecList = new List<NSP_Case_Contacts__c>();
        
        try{
            //Iterate through the list of Case Contact Records whose current IsPrimary checkbox is true and has an Case in caseIdSet
            for(NSP_Case_Contacts__c checkedCaseContact : [SELECT Id, 
                                                           Name, 
                                                           NSP_IsPrimary__c, 
                                                           NSP_Contact__c,
                                                           NSP_Case__c 
                                                           FROM NSP_Case_Contacts__c
                                                           WHERE NSP_Case__c IN: caseIdSet
                                                           AND NSP_IsPrimary__c = true]){
                                                               primaryCheckedCaseContactMap.put(checkedCaseContact.NSP_Case__c, checkedCaseContact);
                                                           }
            //Mark the current IsPrimary checkbox to true for most recently created Case Contact record
            if(!primaryCheckedCaseContactMap.isEmpty()){
                for(NSP_Case_Contacts__c caseContactRec : caseContactRecList){
                    if(!primaryCheckedCaseContactMap.isEmpty()){
                        if(String.isNotBlank(caseContactRec.NSP_Case__c) && 
                           String.isNotBlank(caseContactRec.NSP_Contact__c) && 
                           caseContactRec.NSP_IsPrimary__c == true){
                               primaryCheckedCaseContactMap.get(caseContactRec.NSP_Case__c).NSP_IsPrimary__c = false;
                               caseContactRec.NSP_IsPrimary__c = true;
                               checkedcaseContactRecList.add(primaryCheckedCaseContactMap.get(caseContactRec.NSP_Case__c));
                           }  
                    }
                    else{
                        caseContactRec.NSP_IsPrimary__c = true;
                    }
                }
            }
            if(!checkedcaseContactRecList.isEmpty()){
                Database.update(checkedcaseContactRecList);
            }
        } catch ( Exception e ) {
            NSP_CaseContactTriggerHelper.handleException(
                e ,
                'checkCaseContactIsPrimary'
            );
        }
    }

    /***********************************************************************************************
    * MethodName   : beforeDeleteDirector
    * Description  : Iterates throught the list of Case Contacts Records and displays error if it is primary WSEE on wizard
    * Params       : List <NSP_Case_Contacts__c> newList
    * Created Date : 24/08/2023 created as part of story STY-04602
    * ********************************************************************************************/ 
    public void beforeDeleteDirector(List<NSP_Case_Contacts__c> caseContactList) {
        Map<Id, Id> caseContactIdMap = new Map<Id, Id>();
        Set<Id> caseContactIdSet = new Set<Id>();
            for(NSP_Case_Contacts__c caseContact : caseContactList){
                if(caseContact.NSP_Case__c != null && caseContact.NSP_Contact__c != null){
                    caseContactIdSet.add(caseContact.NSP_Case__c);
                }   
            }
        for(NSP_ReportRequest__c repReq : [Select Id,NSP_Case__c, NSP_WSEE__c from NSP_ReportRequest__c WHERE NSP_Case__c IN : caseContactIdSet]){
            caseContactIdMap.put(repReq.NSP_Case__c, repReq.NSP_WSEE__c);
        }
        
        for(NSP_Case_Contacts__c caseCon : caseContactList){
            if(caseContactIdMap.containsKey(caseCon.NSP_Case__c) && caseCon.NSP_Contact__c == caseContactIdMap.get(caseCon.NSP_Case__c) && caseCon.NSP_IsPrimary__c){
                //After custom label is deployed to UAT, we have to update the error message with custom label
                caseCon.addError('Separating WSEE cannot be deleted from the Case');
            }
        }
    }
}