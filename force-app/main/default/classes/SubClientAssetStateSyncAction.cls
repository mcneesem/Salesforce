public class SubClientAssetStateSyncAction {
    // test w/ SubClientAssetStateSyncActionTest (85%)

    @InvocableMethod( label='Resync WO Asset States of Operations'
                     description='Resynchronizes the States of Operations for the specified WO Assets.'
                    )
    public static List<Boolean> invoke( List<Id> inputs ) {
        List<Boolean> response = new List<Boolean>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( Id assetId : inputs ) {
                response.add( SubClientAssetStateSyncAction.processAssets( new Set<Id>{ assetId } ) );
            }
        }
        return response;
    }

    private static Boolean processAssets( Set<Id> assetIds ) {
        Boolean success = false;
        try {
            NSP_SubClientAssetStateSyncJob syncJob = new NSP_SubClientAssetStateSyncJob();
            success = syncJob.handleAssets( assetIds );
        } catch ( Exception exceptionRecord ) {
            NSP_ErrorLogHandler.logException( SubClientAssetStateSyncAction.class.getName(), 'processAssets', exceptionRecord );
        }
        return success;
    }
}