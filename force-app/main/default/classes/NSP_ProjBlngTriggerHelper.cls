public with sharing class NSP_ProjBlngTriggerHelper {
    // test w/ NSP_ProjBlngTriggerHelperTest (81%)

    private static final String PROJECT_UPDATE_ORDER='PROJECT_UPDATE_ORDER';
    
    /**
* Constructor
*/
    public NSP_ProjBlngTriggerHelper() {
        
    }
    /**
* Iterates through list of projects to set go live and project completion date on Order.
* Author :      CPQ Team
* @param projectNewMap Map of New project. 
* @param projectOldMap Map of Old project.   
* @return void             
*                
*/
    public  void onProjectDateUpdates(List<pse__Proj__c> newList,Map<Id, pse__Proj__c> projectOldMap){ 
        List<Process_Billing_Event__e> billingEvents= new List<Process_Billing_Event__e>();
        for(pse__Proj__c newProj : newList){
            pse__Proj__c oldProj = projectOldMap != null ? projectOldMap.get(newProj.Id):null;
            Process_Billing_Event__e emptyEvent= new Process_Billing_Event__e();
            Process_Billing_Event__e orderEvent= new Process_Billing_Event__e();
            
            if(oldProj.Go_Live_Date__c != newProj.Go_Live_Date__c) {
                Process_Billing_Event__e event= new Process_Billing_Event__e();
                event.NSP_Action__c='PROJECT_UPDATE';
                event.NSP_Project_SF_Id__c=newProj.Id;
                event.NSP_Project_Go_Live_Date__c=newProj.Go_Live_Date__c;
                billingEvents.add(event);
                
                orderEvent.NSP_Action__c=PROJECT_UPDATE_ORDER;
                orderEvent.NSP_Project_SF_Id__c=newProj.Id;
                orderEvent.NSP_Project_Go_Live_Date__c=newProj.Go_Live_Date__c;
            }
            if((oldProj.Go_Live_Date__c != newProj.Go_Live_Date__c) && (oldProj.Invoice_Ready__c == false && newProj.Invoice_Ready__c == true)){
                if(orderEvent==emptyEvent){
                    orderEvent.NSP_Action__c=PROJECT_UPDATE_ORDER;
                    orderEvent.NSP_Project_SF_Id__c=newProj.Id;
                    orderEvent.NSP_Project_Go_Live_Date__c=newProj.Go_Live_Date__c;
                    orderEvent.NSP_Invoice_Ready__c=newProj.Invoice_Ready__c;
                }
                else{
                    orderEvent.NSP_Project_Go_Live_Date__c=newProj.Go_Live_Date__c;
                    orderEvent.NSP_Invoice_Ready__c=newProj.Invoice_Ready__c;
                }
            }
            if(oldProj.pse__Project_Status__c != newProj.pse__Project_Status__c && newProj.pse__Project_Status__c == 'Complete'){
                if(orderEvent==emptyEvent){
                    orderEvent.NSP_Action__c=PROJECT_UPDATE_ORDER;
                    orderEvent.NSP_Project_SF_Id__c=newProj.Id;
                    orderEvent.NSP_Project_Status__c=newProj.pse__Project_Status__c;
                }else{
                    orderEvent.NSP_Project_Status__c=newProj.pse__Project_Status__c;
                }
            }
            if(oldProj.Invoice_Ready__c == false && newProj.Invoice_Ready__c == true){
                if(orderEvent==emptyEvent){
                    orderEvent.NSP_Action__c=PROJECT_UPDATE_ORDER;
                    orderEvent.NSP_Project_SF_Id__c=newProj.Id;
                    orderEvent.NSP_Invoice_Ready__c=newProj.Invoice_Ready__c;
                    orderEvent.NSP_Project_Go_Live_Date__c=newProj.Go_Live_Date__c;
                }
                else{
                    orderEvent.NSP_Invoice_Ready__c=newProj.Invoice_Ready__c;
                    orderEvent.NSP_Project_Go_Live_Date__c=newProj.Go_Live_Date__c;
                }
            }
            if(orderEvent.NSP_Action__c!=null){
                billingEvents.add(orderEvent); //add the event to list
            }
        }
       
        if(billingEvents.size()>0){
            List<NSP_Error_Log__c> erlogs= new List<NSP_Error_Log__c>();
            // Call method to publish events
            List<Database.SaveResult> results = EventBus.publish(billingEvents);
            NSP_ErrorLogHandler.logResults(
                NSP_ProjBlngTriggerHelper.class.getName() ,
                'onProjectDateUpdates' ,
                results
            );
        }
    }
    /***********************************************************************************************
* MethodName:   updateOrderONProjectUpdates
* Description : This Method gets called becasue of Platform event and updates on Order
* Params:       Map<Id,Process_Billing_Event__e> projectEventmap
* Author :      CPQ Team
*Date:
*retun void
* ********************************************************************************************/ 
    public static void updateOrderONProjectUpdates(Map<String,Process_Billing_Event__e> projectEventmap){
        List<OrderItem> orderItems = [SELECT Id,OrderId,NSP_Project__c FROM OrderItem WHERE NSP_Project__c IN :projectEventmap.keySet()];
        Map<Id, Order> ordersToUpdateMap= new Map<Id,Order>();
        for(OrderItem oitem:orderItems){
            if(projectEventmap.containskey(oitem.NSP_Project__c)){
                if(!ordersToUpdateMap.containskey(oitem.OrderId)){
                    Order orderobj = new Order(Id=oitem.OrderId);
                    if(projectEventmap.get(oitem.NSP_Project__c)?.NSP_Invoice_Ready__c == true){
                        orderobj.NSP_Project_Go_Live_Approved__c=projectEventmap.get(oitem.NSP_Project__c)?.NSP_Invoice_Ready__c;
                        orderobj.NSP_Project_Go_Live_Date__c=projectEventmap.get(oitem.NSP_Project__c)?.NSP_Project_Go_Live_Date__c;
                    }
                    if(projectEventmap.get(oitem.NSP_Project__c)?.NSP_Project_Go_Live_Date__c != null){
                        orderobj.NSP_Project_Go_Live_Date__c=projectEventmap.get(oitem.NSP_Project__c)?.NSP_Project_Go_Live_Date__c;
                    }
                    if(projectEventmap.get(oitem.NSP_Project__c)?.NSP_Project_Status__c=='Complete'){
                        orderobj.NSP_Project_Complete_Date__c=System.today();
                    }
                    ordersToUpdateMap.put(oitem.OrderId,orderobj);
                }    
            } 
        }
        if(ordersToUpdateMap.values().size()>0){
            List<Database.SaveResult> results = Database.update(ordersToUpdateMap.values(),false);
            NSP_ErrorLogHandler.logResults(
                NSP_ProjBlngTriggerHelper.class.getName() ,
                'updateOrderONProjectUpdates' ,
                results
            );
        }
    }
    /***********************************************************************************************
* MethodName:   updateBackOutOnOrder
* Description : This Method updates the Back Out on Order
* Params:       Map<Id,pse__Proj__c> newProjectMap ,  Map<Id,pse__Proj__c> oldProjectMap
*return void
*Date:
* Author :      CPQ Team
* ********************************************************************************************/   
    public static void updateBackOutOnOrder(Map<Id,pse__Proj__c> newProjectMap , Map<Id,pse__Proj__c> oldProjectMap){
        Set<Id> lostProjectIds= new Set<Id>();
        List<Order> ordersToUpdate= new List<Order>();
        try{
            for(pse__Proj__c proj :newProjectMap.values()){
                pse__Proj__c oldProj=oldProjectMap.get(proj.Id);
                if(oldProj.pse__Project_Status__c!=proj.pse__Project_Status__c && proj.pse__Project_Status__c=='Close/Lost' && proj.Go_Live_Date__c<=System.today() && proj.Invoice_Ready__c==TRUE){
                    lostProjectIds.add(proj.Id);
                }
            }
            if(lostProjectIds.size()>0){
                for(Order orderObj :[SELECT Id,Status,NSP_Back_Out__c FROM Order WHERE NSP_Project__c IN :lostProjectIds AND Status!='Activated']){
                    Order obj= new Order(Id=orderObj.Id,NSP_Back_Out__c=TRUE);
                    ordersToUpdate.add(obj);
                }
                if(ordersToUpdate.size()>0){
                    update ordersToUpdate;
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_ProjBlngTriggerHelper.class.getName() ,
                'updateBackOutOnOrder' ,
                e
            );
        }
    } 

}
//