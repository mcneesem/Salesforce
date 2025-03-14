public class NSP_SubClientConRelatedRecDeletionBatch implements Database.Batchable<sObject>, Schedulable {
    // test w/ NSP_SCC_RelatedRecDeletionBatch_Test (94%)
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date last120Days = system.Today()-120;     // create variable for last 120 days 
        Return Database.getqueryLocator(
            [
                SELECT Id, NSP_Status_Date__c, NSP_Employee_Status__c, NSP_Contact__c 
                FROM 
                NSP_Sub_Client_Contact__c 
                WHERE 
                NSP_Employee_Status__c = 'PRIMED' 
                AND 
                NSP_Status_Date__c <:last120Days 
                AND 
                NSP_Contact__c != null
            ]
        );
        
    }
    
    public void execute(Database.BatchableContext bc,List<NSP_Sub_Client_Contact__c> existingSubClientContacts){
        
        Set<Id> conIds = new Set<Id>();       	// Store contact ids       
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
            NSP_ErrorLogHandler.logResults(NSP_SubClientConRelatedRecDeletionBatch.class.getName(), 'execute', deletesubclientcon);
            
            Database.DeleteResult[] deleteacr = Database.Delete(acrForContacts,false);
            NSP_ErrorLogHandler.logResults(NSP_SubClientConRelatedRecDeletionBatch.class.getName(), 'execute', deleteacr);
            
        }else if(subClientContacts.Size() == 0 && acrForContacts.Size() == 0) {
            
            //Get related Sub Client Contact Address for Sub Client Contact
            List<NSP_Sub_Client_Contact_Address__c> subClientConAdd = [SELECT Id, NSP_Sub_Client_Contact__c , NSP_Sub_Client_Contact__r.NSP_Sub_Client__c FROM NSP_Sub_Client_Contact_Address__c 
                                                                       WHERE NSP_Sub_Client_Contact__c IN :existingSubClientContacts];
            // Delete Sub Client contact Address 
            if(!subClientConAdd.isEmpty()) {
                Database.DeleteResult[] deleteSCCAddress = Database.Delete(subClientConAdd,false);
                NSP_ErrorLogHandler.logResults(NSP_SubClientConRelatedRecDeletionBatch.class.getName(), 'execute', deleteSCCAddress); 
                
                // Delete Sub Client contact
                Database.DeleteResult[] deletesubclientcon = Database.Delete(existingSubClientContacts,false);
                NSP_ErrorLogHandler.logResults(NSP_SubClientConRelatedRecDeletionBatch.class.getName(), 'execute', deletesubclientcon); 

                // Delete Contacts
                List<Id> ContactsToBeDeleted = new List<Id>(conIds);
                Database.DeleteResult[] deletecontacts = Database.Delete(ContactsToBeDeleted,false);
                NSP_ErrorLogHandler.logResults(NSP_SubClientConRelatedRecDeletionBatch.class.getName(), 'execute', deletecontacts); 
            }
        }       
    }
    
    //== SCHEDULER METHOD
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_SubClientConRelatedRecDeletionBatch(),200);
    }
    
    //== FINISH METHOD
    public void finish(Database.BatchableContext bc){
        
    }
}