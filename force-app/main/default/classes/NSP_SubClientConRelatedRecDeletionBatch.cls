public class NSP_SubClientConRelatedRecDeletionBatch implements Schedulable , Database.Batchable<sObject> {
    // test w/ NSP_SCC_RelatedRecDeletionBatch_Test (100%)

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
        Date pastDay = Date.today() - 121;
        return Database.getqueryLocator(
            [
                SELECT
                    Id ,
                    NSP_Status_Date__c ,
                    NSP_Employee_Status__c ,
                    NSP_Contact__c
                FROM NSP_Sub_Client_Contact__c 
                WHERE (
                    ( NSP_Employee_Status__c = 'PRIMED' )
                    AND ( NSP_Contact__c != null )
                    AND NSP_Status_Date__c <= :pastDay
                )
            ]
        );
        
    }

    public void execute( Database.BatchableContext bc , List<NSP_Sub_Client_Contact__c> existingSubClientContacts ) {
        try {
            Map<Id,NSP_Sub_Client_Contact__c> subClientContactMap = new Map<Id,NSP_Sub_Client_Contact__c>();
            for ( NSP_Sub_Client_Contact__c subClientContact : existingSubClientContacts ) {
                subClientContactMap.put(
                    subClientContact.NSP_Contact__c ,
                    subClientContact
                );
            }

            // Filter the contact records if there is any associated case contact
            Map<Id,NSP_Sub_Client_Contact__c> filteredSubClientContactMapFromCaseContacts = getFilteredSubClientContacts( subClientContactMap );

            // Filter the contact record based on files, notes
            Map<Id,NSP_Sub_Client_Contact__c> filteredSubClientContacts = getFilteredSubclientContact( filteredSubClientContactMapFromCaseContacts );
            List<Database.DeleteResult> subClientDeleteList = Database.delete( filteredSubClientContacts.values() , false );
            NSP_ErrorLogHandler.logResults(
                NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                'execute:delete:NSP_Sub_Client_Contact__c' ,
                subClientDeleteList
            );
            
            // Get Sub client contact address records based on contact Ids and add them to delete list
            List<NSP_Address__c> addressToDelete = getSubClientContactAddress( filteredSubClientContacts.keySet() );
            List<Database.DeleteResult> addressRecordsToDelete = Database.delete( addressToDelete , false );
            NSP_ErrorLogHandler.logResults(
                NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                'execute:delete:NSP_Address__c' ,
                addressRecordsToDelete
            );
            
            // Get Contact records for deletion
            List<Contact> deleteContactList = new List<Contact>();
            for ( Id contactId : filteredSubClientContactMapFromCaseContacts.keySet() ) {
                deleteContactList.add( new Contact( Id = contactId ) );
            }
            List<Database.DeleteResult> contactDeleteList = Database.delete( deleteContactList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                'execute:delete:Contact List' ,
                contactDeleteList
            );

            // Get Account contact relationship records based on contact ID and add them to delete list
            List<AccountContactRelation> deleteACRList = getAcccountContactRelationshipRecords( filteredSubClientContacts.keySet() );
            List<Database.DeleteResult> acrRcordsToDelete = Database.delete( deleteACRList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                'execute:delete:AccountContactRelation' ,
                acrRcordsToDelete
            );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_SubClientConRelatedRecDeletionBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    //
    // Helper Methods
    //

    //== Get Sub Client Contact Address related to contact Ids
    private static List<NSP_Address__c> getSubClientContactAddress( Set<Id> contactIds ) {
        List<NSP_Address__c> subClientContactAddressList = [
            SELECT Id , NSP_Contact__c , NSP_Label_Code__c
            FROM NSP_Address__c
            WHERE (
                NSP_Contact__c =:contactIds 
                AND NSP_Label_Code__c LIKE 'P%'
            )
        ];
        
        return subClientContactAddressList;
    }

    //== Get Account contact relationship records based on contact ID
    private static List<AccountContactRelation> getAcccountContactRelationshipRecords( Set<Id> contactIds ) {
        List<AccountContactRelation> acrList = [
            SELECT Id , ContactId , IsDirect , NSP_AIMS_Client_PERID__c , NSP_Status_Date__c , NSP_Employee_Status__c
            FROM AccountContactRelation
            WHERE (
                ContactId =:contactIds
            )
        ];

        return acrList;
    }

    // Filter the contact record based on files, notes
    private static Map<Id,NSP_Sub_Client_Contact__c> getFilteredSubclientContact( Map<Id,NSP_Sub_Client_Contact__c> filteredSubClientContactMapFromCaseContacts ) {
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id , ContentDocumentId , LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :filteredSubClientContactMapFromCaseContacts.keySet()
        ];

        if ( !contentDocumentLinks?.isEmpty() ) {
            for ( ContentDocumentLink cdLink : contentDocumentLinks ) {
                if ( filteredSubClientContactMapFromCaseContacts.containsKey( cdLink.LinkedEntityId )
                    && cdLink.LinkedEntityId != null
                    )
                {
                    filteredSubClientContactMapFromCaseContacts.remove( cdLink.LinkedEntityId );
                }
            }
        }
        return filteredSubClientContactMapFromCaseContacts;
    }

    //== Exclude the contact if there is a case contact
    private static Map<Id,NSP_Sub_Client_Contact__c> getFilteredSubClientContacts( Map<Id,NSP_Sub_Client_Contact__c> subClientContactMap ) {
        List<NSP_Case_Contacts__c> caseContacts = [
            SELECT Id , NSP_Contact__c , NSP_Case__c
            FROM NSP_Case_Contacts__c
            WHERE NSP_Contact__c IN: subClientContactMap.keySet()
        ];
        if ( !caseContacts?.isEmpty() ) {
            for ( NSP_Case_Contacts__c caseContact : caseContacts ) {
                if ( subClientContactMap.containsKey( caseContact.NSP_Contact__c )
                    && caseContact.NSP_Case__c != null
                    )
                {
                    subClientContactMap.remove( caseContact.NSP_Contact__c );
                }
            }
        }
        return subClientContactMap;
    }

}
//