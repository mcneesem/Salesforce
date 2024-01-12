Global class NSP_ChatterPostFromProcessBuilder {

    /**
         * posts chatter feed on the list of cases
         * @param List<Case> caseList
         * @return void
         * invocable method
         */
    @InvocableMethod(label='Chatter Post')
    global static void sendReportDevelopmentPost(List<Case> caseList){
    
        String reportDevelopmentGroup = System.Label.NSP_ReportDevelopmentGroupName;
        String chatMsg = System.Label.NSP_ReportDevelopmentChatterMessage;
        Id reportDevelopmentGroupId ;
         if(reportDevelopmentGroup !=null && String.isNotBlank(reportDevelopmentGroup)){
             reportDevelopmentGroupId = [SELECT Id, Name from CollaborationGroup WHERE Name = : reportDevelopmentGroup LIMIT 1 ].Id;
         }
     
         if(reportDevelopmentGroupId != null){
            postChatterFeed(caseList,reportDevelopmentGroupId,chatMsg);
     
         }
     }
    
     /**
         * posts chatter feed on the list of cases
         * @param List<Case> caseList,String reportDevelopmentGroupId,String chatMsg
         * @return void
         * 
         */
    public static void postChatterFeed(List<Case> caseList,String reportDevelopmentGroupId,String chatMsg) {
        List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
        for(Case each: caseList){
            ConnectApi.FeedItemInput input =  getInputFeed(each.id,reportDevelopmentGroupId,chatMsg);
            ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(input);
            batchInputs.add(batchInput);
        }
        ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
     }
    
    
        public static ConnectApi.FeedItemInput getInputFeed(id parentRecordId, Id userGroupId, String chatMsg){
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
    
            messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            // add the mention
           mentionSegment.id = userGroupId;
            messageInput.messageSegments.add(mentionSegment);
            
            // add some text before the mention
            textSegment.text = ' '+chatMsg;
            
            messageInput.messageSegments.add(textSegment);
            input.body = messageInput;
            input.feedElementType = ConnectApi.FeedElementType.FeedItem;
            input.subjectId = parentRecordId ;
            return input;
        }
    
    }