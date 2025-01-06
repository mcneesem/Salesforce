public with sharing class OnboardingMeetingDetailHistory {
    // test w/ OnboardingMeetingDetailHistoryTest (96%)
    private static final String OLD_VALUE  = 'Old Value: ';
    private static final String NEW_VALUE  = 'New Value: ';
    private static final String CHANGED_FROM  = ' changed from ';
    
    @InvocableMethod(label='Get Onboarding Meeting Detail History' description='Read Onboarding Meeting Detail History and send the latest history detail back to the flow')    
    
    public static List<Response> getOMDHistory(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        // Get the metadata for the fields on the Onboarding_Meeting_Detail__c object
        Map<String, Schema.SObjectField> mfields = Schema.Onboarding_Meeting_Detail__c.SObjectType.getDescribe().fields.getMap();
        
        try {
            if (requests?.size() > 0) {
                for (Request req : requests) {
                    Response res = createResponseFromHistory(req.omdHistory, mfields);
                    responses.add(res);
                }
            }
        } catch (Exception e) {
            NSP_ErrorLogHandler.logException(OnboardingMeetingDetailHistory.class.getName(), 'getOMDHistory', e);
        }
        
        return responses;
    }
    
    // crreate Response Object based on History Records
    private static Response createResponseFromHistory(List<Onboarding_Meeting_Detail__History> omdHistory, Map<String, Schema.SObjectField> mfields) {
        Response res = new Response();
        res.meetingRescheduled = false;
        
        if (omdHistory?.size() > 0) {
            for (Onboarding_Meeting_Detail__History history : omdHistory) {
                Schema.DescribeFieldResult fieldResult = mfields.get(history.Field).getDescribe();
               res = processHistoryField(history, fieldResult, res);                              
            }
        }
        
        return res;
    }
    
    // process individual history fields    
    private static Response processHistoryField(Onboarding_Meeting_Detail__History history, Schema.DescribeFieldResult fieldResult, Response res) {
        if (history.Field == 'Onboarding_Meeting_Request__c') {
            res.meetingRescheduled = true;
        } else {
          appendResultFromHistory(history, fieldResult, res);
        }
        return res;
    }
    
    private static Response appendResultFromHistory(Onboarding_Meeting_Detail__History history, Schema.DescribeFieldResult fieldResult, Response res) {
        String parsedResult = parseStringFromListOfValues(history, fieldResult);
        res.result = res.result == null ? parsedResult : res.result + parsedResult;        
        return res;
    }
 
        
   private static string parseStringFromListOfValues(Onboarding_Meeting_Detail__History history, Schema.DescribeFieldResult fieldResult) {
        String returnValue = '';
        String fieldLabel = fieldResult.getLabel();
        String oldValue = String.valueOf(history?.OldValue);
        String newValue = String.valueOf(history?.NewValue);
            
           String fieldType = String.valueOf( fieldResult?.getType() );
           if ( fieldType == 'DOUBLE' ) {
               oldValue = formatDoubleValue(Integer.valueOf(history?.OldValue) );
               newValue = formatDoubleValue(Integer.valueOf(history?.NewValue) );
               
           } else if ( fieldType == 'DATE' ) {
               oldValue = formatDateValue( (Datetime)(history?.OldValue) );
               newValue = formatDateValue( (Datetime)(history?.NewValue) );
           }
           if ( fieldType == 'TEXTAREA' ) {
               returnValue = formatTextareaValue(fieldLabel);
           } else {
               returnValue = '<br/>' + fieldLabel + CHANGED_FROM + OLD_VALUE + oldValue + ' to ' + NEW_VALUE + newValue;
           }
           return returnValue;       
    } 

    // format Double
      private static String formatDoubleValue(Double value) {         
        return value != null ? String.valueOf(Integer.valueOf(value)) : String.valueOf(value);
        
    } 

   // format Date
    private static String formatDateValue(Datetime value) {
        return value != null ? value.format('MM-dd-yyyy'): String.valueOf(value);        
    } 
    
	// format TEXTAREA
    private static String formatTextareaValue(String fieldLabel) {
        return '<br/>' + fieldLabel + ' updated ';
    }
    
    //== Request Wrapper
    public class Request  
    {
        @InvocableVariable
        public List<Onboarding_Meeting_Detail__History> omdHistory;
    }
    
    //== Response Wrapper
    public class Response 
    {
        @InvocableVariable
        public String result;
        
        @InvocableVariable
        public boolean meetingRescheduled;       
    } 
}