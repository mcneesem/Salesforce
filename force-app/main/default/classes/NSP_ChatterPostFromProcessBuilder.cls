global class NSP_ChatterPostFromProcessBuilder {
    // test w/ NSP_ChatterPostFromProcessBuilderTest (100%)

    @InvocableMethod(label='Chatter Post')
    global static void sendReportDevelopmentPost( List<Case> caseList ) {
        String reportDevelopmentGroup = System.Label.NSP_ReportDevelopmentGroupName;
        Id reportDevelopmentGroupId = null;
        if ( String.isNotBlank( reportDevelopmentGroup ) ) {
            List<CollaborationGroup> reportDevelopmentGroups = [
                SELECT Id , Name
                FROM CollaborationGroup
                WHERE Name = :reportDevelopmentGroup
                LIMIT 1
            ];
            if ( ( reportDevelopmentGroups != null ) && !reportDevelopmentGroups.isEmpty() ) {
                reportDevelopmentGroupId = reportDevelopmentGroups[0].Id;
            }
        }
        if ( reportDevelopmentGroupId != null ) {
            postChatterFeed(
                caseList,reportDevelopmentGroupId ,
                System.Label.NSP_ReportDevelopmentChatterMessage
            );
        }
    }

    public static void postChatterFeed( List<Case> caseList , String reportDevelopmentGroupId , String chatMsg ) {
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        for ( Case each : caseList ) {
            ConnectApi.FeedItemInput input = getInputFeed( each.Id , reportDevelopmentGroupId , chatMsg );
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput( input );
            batchInputs.add( batchInput );
        }
        ConnectApi.ChatterFeeds.postFeedElementBatch( Network.getNetworkId() , batchInputs );
    }

    public static ConnectApi.FeedItemInput getInputFeed( Id parentRecordId , Id userGroupId , String chatMsg ) {
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        // add the mention
        mentionSegment.id = userGroupId;
        messageInput.messageSegments.add( mentionSegment );
        // add some text before the mention
        textSegment.text = ' ' + chatMsg;
        messageInput.messageSegments.add( textSegment );
        input.body = messageInput;
        input.feedElementType = ConnectApi.FeedElementType.FeedItem;
        input.subjectId = parentRecordId ;
        return input;
    }

}
//