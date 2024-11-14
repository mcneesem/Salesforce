public class NSP_ContentVersionTriggerHelper {
    // test w/ CLMDocumentTransferTest (100%)

    //
    // Iterates throught the ContentVersion lies and identifies the records that needs to worked based on various criterias.
    // @param newList of new ContentVersions.
    // @return void
    //
    public void beforeInsertDirector( List<ContentVersion> newList ) {
        if ( ( newList != null ) && !newList.isEmpty() ) {
            for ( ContentVersion conVer : newList ) {
                conVer.NSP_Last_Assigned_Owner__c = conVer.OwnerId; // Added as part of STY-01774
            }
        }
    }

    //
    // Iterates throught the ContentVersion maps and identifies the records that needs to worked based on various criterias.
    // @param conVerNewMap Map of new ContentVersions.
    // @param conVerOldMap Map of old ContentVersions.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,ContentVersion> conVerNewMap , Map<Id,ContentVersion> conVerOldMapDEPRECATED ) {
        if ( ( conVerNewMap != null ) && !conVerNewMap.isEmpty() ) {
            for ( ContentVersion conVer : conVerNewMap.values() ) {
                conVer.NSP_Last_Assigned_Owner__c = conVer.OwnerId; // Added as part of STY-01774
            }
        }
    }

}
//