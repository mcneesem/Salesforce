public class SubClientAssetStateSyncAction {

    @InvocableMethod(label='Resync WO Asset States of Operations'
                     description='Resynchronizes the States of Operations for the specified WO Assets.'
                    )
    public static List<SubClientAssetStateSyncAction.FlowResult> resyncStatesOfOperations( List<SubClientAssetStateSyncAction.FlowInput> inputs ){
        List<SubClientAssetStateSyncAction.FlowResult> response = new List<SubClientAssetStateSyncAction.FlowResult>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( SubClientAssetStateSyncAction.FlowInput input : inputs ) {
                response.add( SubClientAssetStateSyncAction.processInput( input ) );
            }
        }
        return response;
    }

    private static SubClientAssetStateSyncAction.FlowResult processInput( SubClientAssetStateSyncAction.FlowInput input ) {
        SubClientAssetStateSyncAction.FlowResult result = new SubClientAssetStateSyncAction.FlowResult();
        result.success = false;
        if ( ( input != null ) && ( input.assetIds != null ) && !input.assetIds.isEmpty() ) {
            result.success = SubClientAssetStateSyncAction.processAssets( new Set<Id>( input.assetIds ) );
        }
        return result;
    }

    private static Boolean processAssets( Set<Id> assetIds ) {
        Boolean success = false;
        try {
            NSP_SubClientAssetStateSyncJob syncJob = new NSP_SubClientAssetStateSyncJob();
            syncJob.handleAssets( assetIds );
            success = true;
        } catch ( Exception exceptionRecord ) {
            NSP_ErrorLogHandler.logException(
                SubClientAssetStateSyncAction.class.getName(),
                'processAssets',
                exceptionRecord
            );
        }
        return success;
    }

    public class FlowInput {
        @InvocableVariable(required=true)
        public List<Id> assetIds;
    }

    public class FlowResult {
        @InvocableVariable
        public Boolean success;
    }

}