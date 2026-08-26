public class SubClientAssetStateSyncAction {
    // test w/ SubClientAssetStateSyncActionTest (100%)

    @InvocableMethod( label='Resync WO Asset States of Operations'
                     description='Resynchronizes the States of Operations for the specified WO Assets.'
                    )
    public static List<Boolean> invoke( List<Id> inputs ) {
        List<Boolean> response = new List<Boolean>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            NSP_SubClientAssetStateSyncJob syncJob = new NSP_SubClientAssetStateSyncJob();
            for ( Id assetId : inputs ) {
                response.add( syncJob.handleAssets( new Set<Id>{ assetId } ) );
            }
        }
        return response;
    }
}