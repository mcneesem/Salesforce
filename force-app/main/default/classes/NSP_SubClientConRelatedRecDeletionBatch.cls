public class NSP_SubClientConRelatedRecDeletionBatch implements Schedulable , Database.Batchable<sObject> {
    // test w/ NSP_SCC_RelatedRecDeletionBatch_Test (94%)

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        Database.executeBatch( new NSP_SubClientConRelatedRecDeletionBatch() , 200 );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Date last120Days = ( System.Today() - 120 );     // create variable for last 120 days 
        Return Database.getqueryLocator(
            [
                SELECT
                    Id ,
                    NSP_Status_Date__c ,
                    NSP_Employee_Status__c ,
                    NSP_Contact__c
                FROM NSP_Sub_Client_Contact__c 
                WHERE (
                    ( NSP_Employee_Status__c = 'PRIMED' )
                    AND ( NSP_Status_Date__c < :last120Days )
                    AND ( NSP_Contact__c != null )
                )
            ]
        );
        
    }

    public void execute( Database.BatchableContext bc , List<NSP_Sub_Client_Contact__c> existingSubClientContacts ) {
        Set<Id> conIds = new Set<Id>(); // Store contact ids
        List<NSP_Sub_Client_Contact__c> subClientContacts = new List<NSP_Sub_Client_Contact__c>();
        List<AccountContactRelation> acrForContacts = new List<AccountContactRelation>();
        for ( NSP_Sub_Client_Contact__c subClientCon : existingSubClientContacts ) {
            conIds.add( subClientCon.NSP_Contact__c );
        }
        if ( !conIds.isEmpty() ) {
            subClientContacts = [
                SELECT
                    Id ,
                    NSP_Status_Date__c ,
                    NSP_Employee_Status__c ,
                    NSP_Contact__c,NSP_Sub_Client__c
                FROM NSP_Sub_Client_Contact__c
                WHERE (
                    ( NSP_Contact__c IN :conIds )
                    AND ( Id NOT IN :existingSubClientContacts )
                )
            ];
            
            acrForContacts = [
                SELECT
                    Id ,
                    ContactId ,
                    IsDirect ,
                    NSP_AIMS_Client_PERID__c ,
                    NSP_Status_Date__c ,
                    NSP_Employee_Status__c
                FROM AccountContactRelation
                WHERE ContactId =:conIds AND IsDirect = False
            ];
        }
        // delete existing Sub Client Contacts AND ACR if there is atleaset 1 ACR and 1 Sub client contact
        if ( ( subClientContacts.size() > 0 ) && ( acrForContacts.size() > 0 ) ) {
            // below line will be deleting subClientContacts, not existingSubClientContacts
            List<Database.DeleteResult> deletesubclientcon = Database.delete( existingSubClientContacts , false );
            NSP_ErrorLogHandler.logResults(
                NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                'execute:NSP_Sub_Client_Contact__c' ,
                deletesubclientcon
            );
            List<Database.DeleteResult> deleteacr = Database.delete( acrForContacts , false );
            NSP_ErrorLogHandler.logResults(
                NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                'execute:AccountContactRelation' ,
                deleteacr
            );
        } else if ( ( subClientContacts.size() == 0 ) && ( acrForContacts.size() == 0 ) ) {
            //Get related Sub Client Contact Address for Sub Client Contact
            List<NSP_Sub_Client_Contact_Address__c> subClientConAdd = [
                SELECT
                    Id ,
                    NSP_Sub_Client_Contact__c ,
                    NSP_Sub_Client_Contact__r.NSP_Sub_Client__c
                FROM NSP_Sub_Client_Contact_Address__c 
                WHERE ( NSP_Sub_Client_Contact__c IN :existingSubClientContacts )
            ];
            // Delete Sub Client contact Address 
            if ( !subClientConAdd.isEmpty() ) {
                List<Database.DeleteResult> deleteSCCAddress = Database.delete( subClientConAdd , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                    'execute:NSP_Sub_Client_Contact_Address__c' ,
                    deleteSCCAddress
                );
                // Delete Sub Client contact
                List<Database.DeleteResult> deletesubclientcon = Database.delete( existingSubClientContacts , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                    'execute:NSP_Sub_Client_Contact__c' ,
                    deletesubclientcon
                );
                // Delete Contacts
                List<Id> ContactsToBeDeleted = new List<Id>( conIds );
                List<Database.DeleteResult> deletecontacts = Database.delete( ContactsToBeDeleted , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                    'execute:Id' ,
                    deletecontacts
                );
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

}
//