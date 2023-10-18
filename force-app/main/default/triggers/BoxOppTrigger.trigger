trigger BoxOppTrigger on Opportunity ( after insert , after update ) {
    // test w/ BoxFileRequestFolderUtilityTests (100%)
    
    if ( BoxFileRequestFolderUtility.isEnabled ) {
        for ( Opportunity record : Trigger.new ) {
            Opportunity recordNew = Trigger.newMap.get( record.Id );
            if ( recordNew != null ) {
                if ( Trigger.isInsert ) {
                    // ~ insert and checkbox is checked...
                    if ( recordNew.Create_Box_com_Folder_s__c ) {
                        System.enqueueJob( new BoxFileRequestFolderUtility( record.Id ) );
                    }
                } else if ( Trigger.isUpdate ) {
                    // ~ update and checkbox is checked and checkbox was previously unchecked...
                    Opportunity recordOld = Trigger.oldMap.get( record.Id );
                    if ( recordNew.Create_Box_com_Folder_s__c
                        && ( recordOld != null )
                        && !recordOld.Create_Box_com_Folder_s__c
                       )
                    {
                        System.enqueueJob( new BoxFileRequestFolderUtility( record.Id ) );
                    } 
                }
            }
        }
    }
}
//