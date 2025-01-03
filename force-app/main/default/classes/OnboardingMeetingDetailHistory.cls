public class OnboardingMeetingDetailHistory {
    // test w/ OnboardingMeetingDetailHistoryTest (95%)
    @InvocableMethod(label='Get Onboarding Meeting Detail History' description='Read Onboarding Meeting Detail History and send the latest history detail back to the flow')    
    
    public static List<Response> getOMDHistory(List<Request> requests) {
        // Local variables
        List<Response> responses 				= new List<Response>();                  
        Map<String,Schema.SObjectField> mfields = Schema.Onboarding_Meeting_Detail__c.SObjectType.getDescribe().fields.getMap(); 
        
        try{          
            if(requests?.size() > 0) 
            {
                for(Request req : requests){
                    Response res = new Response(); 
                    res.meetingRescheduled = false;
                    
                    if ( req.OMDHistory?.size() > 0 ) 
                    {
                        for (Onboarding_Meeting_Detail__History history : req.OMDHistory) 
                        {                        
                            // Format the data as a string
                            Schema.DescribeFieldResult fieldResult = mfields.get(history.Field).getDescribe();
                            
                            if(history.Field == 'Onboarding_Meeting_Request__c')
                            {
                                res.meetingRescheduled = true;
                            }
                            else 
                            {  
                                if(res.result == null)
                                {
                                    res.result = parseStringFromListOfValues(history, fieldResult);
                                }
                                else
                                {
                                    res.result += parseStringFromListOfValues(history, fieldResult);
                                }
                                
                            }
                        }
                        
                        responses.add(res);
                    } // end if      
                } // end for
            } // end if requests
        }
        catch(Exception e)
        {
            NSP_ErrorLogHandler.logException(OnboardingMeetingDetailHistory.class.getName() ,'getOMDHistory' , e);
        } 
        
        return responses;  
    }
    
    public static  string parseStringFromListOfValues(Onboarding_Meeting_Detail__History history, Schema.DescribeFieldResult fieldResult)
    {
        String returnValue;

        switch on String.valueOf(fieldResult?.getType()) 
        {
            when 'DOUBLE' 
            {
                returnValue = ('<br/>' + fieldResult.getLabel() + ' changed from ' + 'Old Value: ' + 
                               String.valueOf(Integer.valueOf(history?.OldValue)) + 
                               ' to ' + 'New Value: ' +  
                               String.valueOf(Integer.valueOf(history?.NewValue)));
            }
            when 'DATE'
            {
                returnValue = ('<br/>' + fieldResult.getLabel() + ' changed from ' + 'Old Value: ' + 
                               (((Datetime) (history?.OldValue))?.format('MM-dd-yyyy')) + 
                               ' to ' + 'New Value: ' + 
                               (((Datetime) (history?.NewValue))?.format('MM-dd-yyyy'))) ;
            }
            when 'TEXTAREA' 
            {
                returnValue =  '<br/>' + fieldResult.getLabel() + ' updated ';                                     	
            }
            when else 
            {        
                returnValue = ('<br/>' + fieldResult.getLabel() + ' changed from ' + 'Old Value: ' + 
                               String.valueOf(history?.OldValue) + ' to ' + 'New Value: ' + 
                               String.valueOf(history?.NewValue)) ;
                
            } // when else
        } 
        
        return returnValue;
    }
    
    //=== Request Wrapper
    public class Request  
    {
        @InvocableVariable
        public List<Onboarding_Meeting_Detail__History> OMDHistory;
    }
    
    //=== Response Wrapper
    public class Response 
    {
        @InvocableVariable
        public String result;
        
        @InvocableVariable
        public boolean meetingRescheduled;       
    } 
}