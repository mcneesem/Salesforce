/**
* Represents the Amendment checklist trigger helper which handles all the logic.
* Version - STY       - AUTHOR          - DESCRIPTION                                     - TAG
* V1.0    - STY-02109 - Abhishek Kumar - Amendment Checklist -populating fields from Asset - <STY-02109>
* V2.0    - STY-02110 - Ramya Ravi     - Amendment Chcklist - Form logic                   - <STY-02110>
*/
public class NSP_AmendmentChecklistTriggerHelper {
    
    /***********************************************************************************************
* MethodName: beforeInsertDirector
* Description : Iterates throught the list of new Amendment Checklist and passes the Asset Ids and Amendment Checklist to other methods.
* Params:       List < NSP_Amendment_Checklist__c > newList
* Author :      Abhishek Kumar
* ********************************************************************************************/  
    public void beforeInsertDirector(List < NSP_Amendment_Checklist__c > newList) {
        Set < Id > setOfAssetIds = new Set < Id > ();
        
        //iterate through new Amendment Checklist to get Asset Ids
        for (NSP_Amendment_Checklist__c eachAmendmentCheckList: newList){        
            setOfAssetIds.add(eachAmendmentCheckList.NSP_Asset__c);            
            //<STY-02110> starts
            if(eachAmendmentCheckList.NSP_By_Consultant__c != null && 
               eachAmendmentCheckList.NSP_By__c == null){            
                eachAmendmentCheckList.NSP_By__c = eachAmendmentCheckList.NSP_By_Consultant__c;
            }//<STY-02110> ends
        }
        
        //check if setOfAssetIds is not empty
        if(!setOfAssetIds.isEmpty()){
            updateSubplanNumberonAmendmentChecklist(newList, setOfAssetIds);
        }    
    }
    
    /***********************************************************************************************
* MethodName: beforeUpdateDirector
* Description : Iterates through the map of updated Amendment Checklist and passes the Asset Ids and Amendment Checklist to other methods.
* Params:       List < NSP_Amendment_Checklist__c > newList
* Author :      Abhishek Kumar
* ********************************************************************************************/  
    public void beforeUpdateDirector(Map<Id, NSP_Amendment_Checklist__c> newMap, Map<Id, NSP_Amendment_Checklist__c> oldMap){ 
        Set < Id > setOfAssetIds = new Set < Id > ();
        List < NSP_Amendment_Checklist__c > listOfAsstUpdatedAmendmentChecklist = new List < NSP_Amendment_Checklist__c >();
        List < NSP_Amendment_Checklist__c > listOfAsstRemovedAmendmentChecklist = new List < NSP_Amendment_Checklist__c >();
        
        //iterate through map of updated Amendment Checklist to get Asset Ids
        for( ID changedAmendmentCheckListId : newMap.KeySet() ){
            NSP_Amendment_Checklist__c oldAmendmentChecklistRec = oldMap.get( changedAmendmentCheckListId );
            NSP_Amendment_Checklist__c newAmendmentChecklistRec = newMap.get( changedAmendmentCheckListId );
            
            //check if Asset is changed on Amendment Checklist
            if( oldAmendmentChecklistRec.NSP_Asset__c != newAmendmentChecklistRec.NSP_Asset__c ){
                
                //check if Asset is not removed on Amendment Checklist
                if( newAmendmentChecklistRec.NSP_Asset__c != null){
                    setOfAssetIds.add( newAmendmentChecklistRec.NSP_Asset__c );
                    listOfAsstUpdatedAmendmentChecklist.add(newAmendmentChecklistRec);
                }
                else {
                    listOfAsstRemovedAmendmentChecklist.add(newAmendmentChecklistRec);
                }
            }           
        }
        
        //check if setOfAssetIds is not empty
        if( !setOfAssetIds.isEmpty() ){
            updateSubplanNumberonAmendmentChecklist(listOfAsstUpdatedAmendmentChecklist, setOfAssetIds);
        } 
        
        //check if listOfAsstRemovedAmendmentChecklist is not empty
        if( !listOfAsstRemovedAmendmentChecklist.isEmpty() ){
            removeSubplanNumberonAmendmentChecklist( listOfAsstRemovedAmendmentChecklist );
        }  
        
        //<STY-02110> starts 
        for (NSP_Amendment_Checklist__c eachAmendmentCheckList: newMap.values()){                      
            if(eachAmendmentCheckList.NSP_By_Consultant__c != oldMap.get(eachAmendmentCheckList.Id).NSP_By_Consultant__c && 
               oldMap.get(eachAmendmentCheckList.Id).NSP_By__c == oldMap.get(eachAmendmentCheckList.Id).NSP_By_Consultant__c){            
                eachAmendmentCheckList.NSP_By__c = eachAmendmentCheckList.NSP_By_Consultant__c;
            }
        }
        //<STY-02110> ends                
    }
    
    /***********************************************************************************************
* MethodName: updateSubplanNumberonAmendmentChecklist
* Description: Update the Sub Plan Number of Amendment Checklist    
* Params:       List<NSP_Amendment_Checklist__c> listOfAmendmentChecklist, Set<Id> setOfAssetId
* Author :      Abhishek Kumar
* ********************************************************************************************/
    public void updateSubplanNumberonAmendmentChecklist( List<NSP_Amendment_Checklist__c> listOfAmendmentChecklist, Set<Id> setOfAssetId ){
        Set<Id> setOfPlanSubPlanId = new Set<Id> ();
        Map < Id, Id > mapAssetToSubPlanNum = new Map < Id, Id > ();
        Map<Id, String> mapOfPlanSubPlanIdAndNumber = new Map<Id, String> ();
        List < NSP_Amendment_Checklist__c > listOfAsstRemovedAmendmentChecklist = new List < NSP_Amendment_Checklist__c >();
        
        try{
            //iterate through Client Sub Plan History having Asset Id in setOfAssetId
            for (NSP_Client_Sub_Plan_History__c eachClientSubPlanHis: [Select Name, NSP_Plan_Subplan_Relationship__c,NSP_Asset__c
                                                                       FROM NSP_Client_Sub_Plan_History__c
                                                                       WHERE NSP_Asset__c IN: setOfAssetId
                                                                      ]) {
                                                                          setOfPlanSubPlanId.add(eachClientSubPlanHis.NSP_Plan_Subplan_Relationship__c);
                                                                          mapAssetToSubPlanNum.put(eachClientSubPlanHis.NSP_Asset__c, eachClientSubPlanHis.NSP_Plan_Subplan_Relationship__c);
                                                                      }
            
            //iterate through Plan Sub Plan having Asset Id in setOfPlanSubPlanId
            for(NSP_Plan_SubPlan__c planSubplan : [SELECT Name FROM NSP_Plan_SubPlan__c
                                                   WHERE ID IN : setOfPlanSubPlanId]){
                                                       mapOfPlanSubPlanIdAndNumber.put(planSubplan.id, planSubplan.name);                                        
                                                   }
            
            //iterate through Amendment Checklist to update subplan number
            for (NSP_Amendment_Checklist__c eachAmendmentCheckList: listOfAmendmentChecklist) {
                
                //check if Plan sub plan is not linked with Asset having on Amendment Checklist
                if (mapAssetToSubPlanNum.get(eachAmendmentCheckList.NSP_Asset__c) != null) {
                    eachAmendmentCheckList.NSP_Subplan_Number__c = mapOfPlanSubPlanIdAndNumber.get(
                        mapAssetToSubPlanNum.get(eachAmendmentCheckList.NSP_Asset__c));
                }
                else{
                    listOfAsstRemovedAmendmentChecklist.add(eachAmendmentCheckList);
                }
            }
            
            //check if listOfAsstRemovedAmendmentChecklist is not empty
            if( !listOfAsstRemovedAmendmentChecklist.isEmpty() ){
                removeSubplanNumberonAmendmentChecklist( listOfAsstRemovedAmendmentChecklist );
            }
            
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_AmendmentChecklistTriggerHelper', 'updateSubplanNumberonAmendmentChecklist', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
* MethodName: removeSubplanNumberonAmendmentChecklist
* Description : Remove the Sub Plan Number from Amendment Checklist    
* Params:       List<NSP_Amendment_Checklist__c> listOfAmendmentChecklist, Set<Id> setOfAssetId
* Author :      Abhishek Kumar
* ********************************************************************************************/
    public void removeSubplanNumberonAmendmentChecklist( List<NSP_Amendment_Checklist__c> listOfAmendmentChecklist ){
        try{
            //iterate through list of Amendment Checklist to remove Sub plan number
            for (NSP_Amendment_Checklist__c eachAmendmentCheckList: listOfAmendmentChecklist) {
                eachAmendmentCheckList.NSP_Subplan_Number__c = null;
            } 
        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_AmendmentChecklistTriggerHelper', 'removeSubplanNumberonAmendmentChecklist', ex.getMessage());
        }
    }
}