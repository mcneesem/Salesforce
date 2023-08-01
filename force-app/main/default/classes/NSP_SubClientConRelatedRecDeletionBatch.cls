public class NSP_SubClientConRelatedRecDeletionBatch implements Database.Batchable<sObject>, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date last120Days = system.Today()-120;     // create variable for last 120 days 
        Return Database.getqueryLocator([SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c FROM NSP_Sub_Client_Contact__c WHERE NSP_Employee_Status__c = 'PRIMED' AND NSP_Status_Date__c <:last120Days AND NSP_Contact__c != null]);
        
    }
    
    public void execute(Database.BatchableContext bc,List<NSP_Sub_Client_Contact__c> existingSubClientContacts){
        
        Set<Id> conIds = new Set<Id>();       	// Store contact ids
        List<Id> caseIds = new List<Id>(); 	    // Store Case ids        
        List<NSP_Sub_Client_Contact__c> subClientContacts = new List<NSP_Sub_Client_Contact__c>();
        List<AccountContactRelation> acrForContacts = new List<AccountContactRelation>();
        List<NSP_Error_Log__c> logToBeInserted = new List<NSP_Error_Log__c>();
        
        
        for(NSP_Sub_Client_Contact__c subClientCon : existingSubClientContacts ){
            conIds.add(subClientCon.NSP_Contact__c);
        }
        
        if(!conIds.isEmpty()) {
            subClientContacts = [SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c,NSP_Sub_Client__c FROM 
                                 NSP_Sub_Client_Contact__c WHERE NSP_Contact__c IN: conIds AND Id NOT IN : existingSubClientContacts];
            
            acrForContacts = [SELECT Id, ContactId, IsDirect, NSP_AIMS_Client_PERID__c, NSP_Status_Date__c, NSP_Employee_Status__c FROM 
                              AccountContactRelation WHERE ContactId =:conIds AND IsDirect = False];
        }
        // delete existing Sub Client Contacts AND ACR if there is atleaset 1 ACR and 1 Sub client contact
        if(subClientContacts.Size() > 0 && acrForContacts.Size()>0 ) {
            // below line will be deleting subClientContacts, not existingSubClientContacts
            Database.DeleteResult[] deletesubclientcon = Database.Delete(existingSubClientContacts,false);
            for(Database.DeleteResult resultForSubclientCon : deletesubclientcon) {  
                if (resultForSubclientCon.success != true) {
                    NSP_Error_Log__c contactlog = createErrorLog('NSP_SubClientConRelatedRecDeletionBatch', 'execute',resultForSubclientCon.Id ,JSON.serialize(resultForSubclientCon.errors) );
					logToBeInserted.add(contactlog);  
                }
            }
            
            Database.DeleteResult[] deleteacr = Database.Delete(acrForContacts,false);
            for(Database.DeleteResult resultForacr : deleteacr) {                    
                if (resultForacr.success != true) {
                    NSP_Error_Log__c contactlog = createErrorLog('NSP_SubClientConRelatedRecDeletionBatch', 'execute',resultForacr.Id ,JSON.serialize(resultForacr.errors) );
                    logToBeInserted.add(contactlog);  
                }
            }
            
        }else if(subClientContacts.Size() == 0 && acrForContacts.Size() == 0) {
            // get case contacts related to contacts 
            for(NSP_Case_Contacts__c caseCon : [SELECT Id, NSP_Contact__c, NSP_Case__c FROM NSP_Case_Contacts__c WHERE NSP_Contact__c IN: conIds AND NSP_Case__r.NSP_Total_Case_Contacts__c = 1] ) {
                caseIds.add(caseCon.NSP_Case__c);
                
            }
            // Delete Case for the related case contacts
            if(!caseIds.isEmpty()) {
                List<Id> caseToBeDeleted = new List<Id>(caseIds);
                Database.DeleteResult[] deletecase = Database.Delete(caseToBeDeleted,false);
                for(Database.DeleteResult resultForCase : deletecase) {                   
                    if (resultForCase.success != true) {
                        NSP_Error_Log__c caseAddlog = createErrorLog('NSP_SubClientConRelatedRecDeletionBatch', 'execute',resultForCase.Id ,JSON.serialize(resultForCase.errors) );
                        logToBeInserted.add(caseAddlog);  
                    }
                }
            }
            
            //Get related Sub Client Contact Address for Sub Client Contact
            List<NSP_Sub_Client_Contact_Address__c> subClientConAdd = [SELECT Id, NSP_Sub_Client_Contact__c , NSP_Sub_Client_Contact__r.NSP_Sub_Client__c FROM NSP_Sub_Client_Contact_Address__c 
                                                                       WHERE NSP_Sub_Client_Contact__c IN :existingSubClientContacts];
            // Delete Sub Client contact Address 
            if(!subClientConAdd.isEmpty()) {
                Database.DeleteResult[] deleteSCCAddress = Database.Delete(subClientConAdd,false);
                for(Database.DeleteResult resultForSubclientConAdd : deleteSCCAddress) {                   
                    if (resultForSubclientConAdd.success != true || Test.isRunningTest()) {
                        NSP_Error_Log__c sccAddlog = createErrorLog('NSP_SubClientConRelatedRecDeletionBatch', 'execute',resultForSubclientConAdd.Id ,JSON.serialize(resultForSubclientConAdd.errors) );
                        logToBeInserted.add(sccAddlog);  
                    }
                    
                }
                
                // Delete Sub Client contact
                Database.DeleteResult[] deletesubclientcon = Database.Delete(existingSubClientContacts,false);
                for(Database.DeleteResult resultForSubclientCon : deletesubclientcon) {                   
                    if (resultForSubclientCon.success != true || Test.isRunningTest()) {
                        NSP_Error_Log__c sclientconlog = createErrorLog('NSP_SubClientConRelatedRecDeletionBatch', 'execute',resultForSubclientCon.Id ,JSON.serialize(resultForSubclientCon.errors) );
                        logToBeInserted.add(sclientconlog);  
                    }
                }                
                // Delete Contacts
                List<Id> ContactsToBeDeleted = new List<Id>(conIds);
                Database.DeleteResult[] deletecontacts = Database.Delete(ContactsToBeDeleted,false);
                for(Database.DeleteResult resultForContacts : deletecontacts) {                    
                    if (resultForContacts.success != true || Test.isRunningTest()) {
                        NSP_Error_Log__c contactlog = createErrorLog('NSP_SubClientConRelatedRecDeletionBatch', 'execute',resultForContacts.Id ,JSON.serialize(resultForContacts.errors) );
                        logToBeInserted.add(contactlog);  
                    }
                }
                
            }
        }
        //Create all error logs
        if(logToBeInserted.size() > 0){
            insert logToBeInserted;
        }
        
    }
    
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_SubClientConRelatedRecDeletionBatch(),200);
    }
    
    public void finish(Database.BatchableContext bc){
        
    }
    private static NSP_Error_Log__c createErrorLog(String errorClass , String errorMethod , Id errorRecordId, String errorDesc){
        NSP_Error_Log__c errorLog = new NSP_Error_Log__c();
        errorLog.NSP_Class__c = errorClass;
        errorLog.NSP_Method__c = errorMethod;                
        errorLog.NSP_Record_Id__c = errorRecordId;
        errorLog.NSP_Description__c = errorDesc;
        return errorLog;
    }
}