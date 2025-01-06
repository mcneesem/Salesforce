public with sharing class OnboardingMeetingDetailHistory {
    // test w/ OnboardingMeetingDetailHistoryTest (84%)
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
                    Response res = createResponseFromHistory(req.OMDHistory, mfields);
                    responses.add(res);
                }
            }
        } catch (Exception e) {
            NSP_ErrorLogHandler.logException(OnboardingMeetingDetailHistory.class.getName(), 'getOMDHistory', e);
        }
        
        return responses;
    }
    
    // crreate Response Object based on History Records
    private static Response createResponseFromHistory(List<Onboarding_Meeting_Detail__History> OMDHistory, Map<String, Schema.SObjectField> mfields) {
        Response res = new Response();
        res.meetingRescheduled = false;
        
        if (OMDHistory?.size() > 0) {
            for (Onboarding_Meeting_Detail__History history : OMDHistory) {
                Schema.DescribeFieldResult fieldResult = mfields.get(history.Field).getDescribe();
                processHistoryField(history, fieldResult, res);                
            }
        }
        
        return res;
    }
    
    // process individual history fields    
    private static void processHistoryField(Onboarding_Meeting_Detail__History history, Schema.DescribeFieldResult fieldResult, Response res) {
        if (history.Field == 'Onboarding_Meeting_Request__c') {
            res.meetingRescheduled = true;
        } else {
            appendResultFromHistory(history, fieldResult, res);
        }
    }
    
    private static void appendResultFromHistory(Onboarding_Meeting_Detail__History history, Schema.DescribeFieldResult fieldResult, Response res) {
        String parsedResult = parseStringFromListOfValues(history, fieldResult);
        res.result = res.result == null ? parsedResult : res.result + parsedResult;
    }
    
    
   private static string parseStringFromListOfValues(Onboarding_Meeting_Detail__History history, Schema.DescribeFieldResult fieldResult) {
        String returnValue = '';
        String fieldLabel = fieldResult.getLabel();
        String oldValue = String.valueOf(history?.OldValue);
        String newValue = String.valueOf(history?.NewValue);
        
        // default message
        String changeMessage = '<br/>' + fieldLabel + CHANGED_FROM + OLD_VALUE + oldValue + ' to ' + NEW_VALUE + newValue;
        
        // format the output based in fieldtype
        String fieldType = String.valueOf(fieldResult?.getType());
        if (fieldType == 'DOUBLE') {
            returnValue = formatDoubleValue(changeMessage, history);
        } else if (fieldType == 'DATE') {
            returnValue = formatDateValue(changeMessage, history);
        } else if (fieldType == 'TEXTAREA') {
            returnValue = formatTextareaValue(fieldLabel);
        } else {
            returnValue = changeMessage;  // Default case for other types
        }
        
        return returnValue;
    }
    
    // format Double
    private static String formatDoubleValue(String baseMessage, Onboarding_Meeting_Detail__History history) {
        return baseMessage.replace(String.valueOf(history?.OldValue), String.valueOf(Integer.valueOf(history?.OldValue)))
            .replace(String.valueOf(history?.NewValue), String.valueOf(Integer.valueOf(history?.NewValue)));
    }
    
    // format Date
    private static String formatDateValue(String baseMessage, Onboarding_Meeting_Detail__History history) {
        String oldDate = ((Datetime)(history?.OldValue))?.format('MM-dd-yyyy');
        String newDate = ((Datetime)(history?.NewValue))?.format('MM-dd-yyyy');
        return baseMessage.replace(String.valueOf(history?.OldValue), oldDate)
            .replace(String.valueOf(history?.NewValue), newDate);
    }
    
    // format TEXTAREA
    private static String formatTextareaValue(String fieldLabel) {
        return '<br/>' + fieldLabel + ' updated ';
    }
    
    //== Request Wrapper
    public class Request  
    {
        @InvocableVariable
        public List<Onboarding_Meeting_Detail__History> OMDHistory;
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