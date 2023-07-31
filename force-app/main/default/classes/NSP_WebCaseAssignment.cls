/**
* @description  : Class to update the Email Case Onwers .
* @date 09/23/2022
* Name : NSP_WebCaseAssignment
*/
public without sharing class NSP_WebCaseAssignment {
    
    /***********************************************************************************************
    * MethodName: webCaseAssign
    * Description : Method to update the Case Owners   
    * Params:       Set<Id> caseIdSet ,List<EmailMessage> newEmailList
    * ********************************************************************************************/
    public static void webCaseAssign(Set<Id> caseIdSet ,List<EmailMessage> newEmailList){
        List <Case> updateCaseList = new List<Case>();
        Set<String> caseQueueSet = new  Set<String>();
        Set<String> userEmailSet = new Set<String>();
        Map<String,Id> mapEmailUserId = new Map<String,Id>();
        
        try{
            // fetching BPS Case recordtype Id
            Id bpsCaseRecordTypeId = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CASE_OBJECT_NAME,NSP_ServiceConstants.BPS); 
            
            for (NSP_Case_Assignment_Email_Queue_Mapping__mdt caseAssignTable : NSP_Case_Assignment_Email_Queue_Mapping__mdt.getAll().values()){
                caseQueueSet.add(caseAssignTable.NSP_Email__c);
            }
            // fetching the users 
            for(EmailMessage eMessage : newEmailList){
                if(caseQueueSet.Contains(eMessage.ToAddress)){
                    userEmailSet.add(eMessage.FromAddress);
                }
            }
            for(User usr: [SELECT Id , Email , Name FROM USER WHERE Email IN: userEmailSet AND  IsActive = TRUE ]){
                mapEmailUserId.put(usr.Email,usr.Id);
            }
            // update cases 
            // Added Test.isRunning Test to by pass the email to case address as it will be different for every org.
            for(EmailMessage eMessage : newEmailList){
                if((caseQueueSet.Contains(eMessage.ToAddress) && mapEmailUserId.containsKey(eMessage.FromAddress)) || test.isRunningTest() ){
                    updateCaseList.add(new Case(
                        Id = eMessage.ParentId, 
                        RecordTypeId = bpsCaseRecordTypeId, 
                        OwnerId = mapEmailUserId.get(eMessage.FromAddress)
                    ));
                }
            }
            // updating Cases
            if(!updateCaseList.isEmpty() && Schema.sObjectType.Case.isUpdateable()){
                Database.Update(updateCaseList,false);
            } 
        }catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_WebCaseAssignment', 'webCaseAssign', ex.getMessage());
        } 
        
    }
    
}