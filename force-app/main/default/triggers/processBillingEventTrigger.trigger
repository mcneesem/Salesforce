/* Trigger for process Billing Event
* Relies on NSP_Action__c to determine the type of event to be processed.
* Created Date : 03/20/2023
* Author : Rakesh Das
* Event Triggers is an auto subscribe mechanism for platform events. It runs in context of Deployment Manager user
* Please refer to processBillingEventTriggerConfig metadata for details on running user and batch size.
*/

trigger processBillingEventTrigger on Process_Billing_Event__e (after insert) {

    //Variable Declarations
    List<String> closedOpptyIds = new List<String>();
    List<String> activatedOrderIds = new List<String>();
    Map<String,Date> projectGoLiveDateMap = new Map<String,Date>();
    Map<String,Process_Billing_Event__e> projectEventmap= new Map<String,Process_Billing_Event__e>();
    List<String> orderIds = new List<String>();
    Set<Id> orderProductIds = new Set<Id>();
    //looping through event lists.
    for (Process_Billing_Event__e evt : Trigger.New) {
        //collecting opportunity ids from events for Order Creation.
        if(evt.NSP_Action__c == 'CREATE_ORDER' && evt.NSP_Opportunity_SF_Id__c != null) {
            closedOpptyIds.add(evt.NSP_Opportunity_SF_Id__c);
        }
        if(evt.NSP_Action__c == 'CREATE_CONTRACT' && evt.NSP_Order_SF_Id__c != null) {
            activatedOrderIds.add(evt.NSP_Order_SF_Id__c);
        }
        if(evt.NSP_Action__c == 'PROJECT_UPDATE' && evt.NSP_Project_SF_Id__c!=null && evt.NSP_Project_Go_Live_Date__c!=null){
            projectGoLiveDateMap.put(evt.NSP_Project_SF_Id__c,evt.NSP_Project_Go_Live_Date__c);
        }
        if(evt.NSP_Action__c == 'PROJECT_UPDATE_ORDER' && evt.NSP_Project_SF_Id__c!=null){
            projectEventmap.put(evt.NSP_Project_SF_Id__c,evt);
        }
        if(evt.NSP_Action__c == 'CREATE_PROJECT' && evt.NSP_CreateProject__c == true && evt.NSP_Order_SF_Id__c != null){
            orderIds.add(evt.NSP_Order_SF_Id__c);
        }
        if ( ( evt.NSP_Action__c == 'CHANGE_PAYMENT_METHOD' ) && ( String.isNotBlank( evt.Order_Product_Id__c ) ) ) {
            //gather Order product Ids
            orderProductIds.add( evt.Order_Product_Id__c );
        }
    }

    if(closedOpptyIds.size()>0) {
        //Calling helper function to create orders.
        NSP_GenerateOrderFromOpportunity.orderQuoteOnOpptyCloseWon(closedOpptyIds);
    }
    if(activatedOrderIds.size()>0) {
        //Calling helper function to create orders.
        NSP_GenerateOrderFromOpportunity.createContractOnOrderActivation(activatedOrderIds);
    }
    if(!projectGoLiveDateMap.isEmpty()){
        //calling helper function to stamp Go Live dates on Invoice Lines and Credit Note lines
        NSP_RevRecService.updateGoLiveDatesOnInvLineAndCredLines(projectGoLiveDateMap);
    }
    if(!projectEventmap.isEmpty()){
        NSP_ProjBlngTriggerHelper.updateOrderONProjectUpdates(projectEventmap);
    }
    if(orderIds.size()>0) {
        //Calling helper function to create project.
        NSP_CreateProjFromFlow.createProject(orderIds);
    }
    if ( !orderProductIds.isEmpty() ) {
        //call method
        NSP_OrderItemTriggerHelper.processPaymentChange( orderProductIds );
    }
}