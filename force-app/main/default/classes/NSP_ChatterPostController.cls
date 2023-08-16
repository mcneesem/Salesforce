/**
Apex Class Name      :  NSP_ChatterPostController
Version              :  1.0 
Author               :  Anil                                                                          
Created Date         :  12/19/22 
Function             :  It is invoked the from the flow when Owner is changed, and Create a chatter post.
Story                :  As part of STY-01980                                                                    
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Anil                       12/19/22                 First Iteration
*/
public without sharing class NSP_ChatterPostController {

    /**
    * execute - When the Owner of the Record is changed this action is invoked.
    * Invocable - it will create chatter post records with necessary inputs
    * @param inputResponse -  List of Request wrapper objects.  
    * @return `void`                         
    */
    
    @invocableMethod(label='Post Chatter Feed to the Record if Owner is Changed')
    public static void postChatterFeed(List<InputResponse> inputResponse){
        try{
            List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();

            for(InputResponse input : inputResponse){
				List<String> userIds = input?.userIds;
                
                if(userIds != null){
                    
                    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                    ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
                    
                    messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                    
                    textSegmentInput.text =  input.subject.stripHtmlTags()+'\n';// Subject of the record
                    messageBodyInput.messageSegments.add(textSegmentInput);
                    
                    for(String userId : userIds){
                        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
                        mentionSegmentInput.id = userId;//User Id
                        messageBodyInput.messageSegments.add(mentionSegmentInput);
                    }
                    
                    feedItemInput.body = messageBodyInput;
                    feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
                    feedItemInput.subjectId = input.relatedId; //Id of the record
                    
                    ConnectApi.BatchInput batchInput = new ConnectApi.BatchInput(feedItemInput);
                    batchInputs.add(batchInput);
                }
                
            }

            if(!batchInputs.isEmpty()){
                ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
            }

        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_ChatterPostController', 'postChatterFeed', ex.getMessage());
        }

    }

    public class InputResponse{
        @InvocableVariable public String relatedId;
        @InvocableVariable public List<String> userIds;
        @InvocableVariable public String subject;
    }
}