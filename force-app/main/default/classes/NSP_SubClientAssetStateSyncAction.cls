public without sharing class NSP_SubClientAssetStateSyncAction {
    // test w/ NSP_SubClientAssetStateSyncActionTest (79%)

    @InvocableMethod(label='Resync WO Asset States of Operations')
    public static List<NSP_SubClientAssetStateSyncAction.FlowResult> resyncStatesOfOperations( List<NSP_SubClientAssetStateSyncAction.FlowInput> inputs ){
        List<NSP_SubClientAssetStateSyncAction.FlowResult> response = new List<NSP_SubClientAssetStateSyncAction.FlowResult>();
        if ( ( inputs != null ) && !inputs.isEmpty() ) {
            for ( NSP_SubClientAssetStateSyncAction.FlowInput input : inputs ) {
                response.add( NSP_SubClientAssetStateSyncAction.processInput( input ) );
            }
        }
        return response;
    }

    private static NSP_SubClientAssetStateSyncAction.FlowResult processInput( NSP_SubClientAssetStateSyncAction.FlowInput input ) {
        NSP_SubClientAssetStateSyncAction.FlowResult result = new NSP_SubClientAssetStateSyncAction.FlowResult();
        result.success = false;
        if ( ( input != null ) && ( input.assetIds != null ) && !input.assetIds.isEmpty() ) {
            result.success = NSP_SubClientAssetStateSyncAction.processAssets( new Set<Id>( input.assetIds ) );
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
                NSP_SubClientAssetStateSyncAction.class.getName(),
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