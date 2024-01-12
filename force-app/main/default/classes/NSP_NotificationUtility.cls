/* **************************************************************************************************   
Component Name :  NSP_NotificationUtility class
Version              :  1.0                                                                          
Created Date         :  August 19, 2022                                                             
Function             :  This component is used as utility class for Event Notification functionality
					 :  Events published create notifications via flow  	
Story                :                                                                             
Modification Log     :                                                                               
*	Rakesh           August 19, 2022          First Iteration
*
***************************************************************************************************
*/

public class NSP_NotificationUtility {
    
    private NSP_NotificationUtility() {
     
  }
    
/**
* publishNotificationEvent - Method to pusblish cutsom event notification records.
* @param notificationEventList -  List of notificationEventWrapper objects.  
* @return void             
*                
*/
    public static void publishNotificationEvent (List<notificationEventWrapper> notificationEventList ) {
        try{
            // Looping over list to populate details of event.
            List<NSP_Custom_Notification_Event__e> notifEvents = new List<NSP_Custom_Notification_Event__e>();
            for(notificationEventWrapper nev : notificationEventList) {
                NSP_Custom_Notification_Event__e notifEvt = new NSP_Custom_Notification_Event__e();
                notifEvt.NSP_TypeIdOrApiName__c = nev.typeid;
                notifEvt.NSP_Title__c = nev.title;
                notifEvt.NSP_Notification_Body__c = nev.body;
                notifEvt.NSP_Target_Id__c = nev.targetid;
                notifEvt.NSP_Sender_Id__c = nev.senderid;
                List<String> deliveryList = new List<String>(nev.userIds);
                notifEvt.NSP_UserIdList__c = String.join(deliveryList, ',');
                //Adding event to list
                notifEvents.add(notifEvt);
            }
            // publish event list
            if(notifEvents.size()>0) {
                EventBus.publish(notifEvents);
            }
        }
        catch (Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_NotificationUtility','publishNotificationEvent',ex.getMessage());
        }
        
        
    }

/**
* execute - Method to convert comma separated values to list of string.
* Invocable - To be called from flow action
* @param requests -  List of Request wrapper objects.  
* @return List of Response objects             
*                
*/
    
    @invocableMethod(label='Convert Comma-separated-values to String Collection')
    public static List<Response> execute (List<Request> requests) {
        
        List<Response> responseList = new List<Response>();
        for (Request curRequest : requests) {
            
            Response response = new Response();
            response.stringCollection = curRequest.csvString?.split(',');
            responseList.add(response);
        }
        
        return responseList;
    }
    
    public class Request {
        @invocableVariable
        public String csvString;
    }
    
    public class Response {
        @invocableVariable
        public List<String> stringCollection;
        
    }
    
/**
* notificationEventWrapper - Inner Class used as a wrapper to gather event details.          
* Multiple Construtors           
*/  
    
    public class notificationEventWrapper {
        public String typeid;   	// Must be Developer Name of custom event type.
        public String title; 		// Title of the notification post.
        public String body; 		// Message body of the notification post.
        public String senderid;		// Id of the notification sender.(Optional)
        public String targetid; 	// Id of the target record
        public Set<String> userIds;	// Recipients Ids for the notofication
		
        //default constructor
        public notificationEventWrapper() {
            
        }        
        
        //parameterized constructor
        public notificationEventWrapper(String typeid, String title, String body, String senderid, String targetid, Set<String> userIds) {
            
            this.typeid = typeid;
            this.title = title;
            this.body = body;
            this.senderid = senderid;
            this.targetid = targetid;
            this.userIds = userIds;
            
        }
        
    }
    
}