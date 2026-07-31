public class OrderTriggerCreateInvoice {
    // test w/ OrderTriggerCreateInvoiceTest (83%)

    public static void createInvoice( List<Order> newList , Map<Id,Order> orderOldMap ) {
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> projCompletedIdSet = new Set<Id>();
        Set<Id> revisedOrderStartDateIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        List<OrderItem> orderItemListToUpdate = new List<OrderItem>();
        List<OrderItem> milestoneOpList = new List<OrderItem>();
        Set<Id> billToContactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> uniqueAcrIds = new Set<String>();
        Map<String,blng__PaymentMethod__c> paymentMethodMap = new Map<String,blng__PaymentMethod__c>();
        List<OrderItem> payMethodList = new List<OrderItem>();
        Set<Id> projGoLiveIdSet = new Set<Id>();
        Set<Id> projectLiveBeforeReviewIds = new Set<Id>();
        Set<Id> orderIdPT = new Set<Id>();
        Set<Id> orderIds = new Set<Id>();
        if(!NSP_CPQConstants.HAS_BLK_RAN){
            NSP_CPQConstants.HAS_BLK_RAN = true;
            for(Order newOrder : newList){
                Order oldOrder = ( ( orderOldMap != null ) ? orderOldMap.get( newOrder.Id ) : null );
                if(oldOrder.Status == NSP_CPQConstants.ORDER_DRAFT && newOrder.Status == NSP_CPQConstants.ORDER_REVIEWED) {
                    orderIdSet.add(newOrder.Id);
                    billToContactIds.add(newOrder.BillToContactId);
                    accountIds.add(newOrder.AccountId);
                    uniqueAcrIds.add(String.valueof(newOrder.BillToContactId)+String.valueOf(newOrder.AccountId));
                    accountIdSet.add(newOrder.AccountId);
                    if(oldOrder.NSP_Project_Go_Live_Date__c != null && oldOrder.NSP_Project_Go_Live_Approved__c == true){
                        projectLiveBeforeReviewIds.add(newOrder.Id);
                    }
                }
                if ( ( newOrder.NSP_Project_Go_Live_Date__c == null )
                    && !newOrder.NSP_Project_Go_Live_Approved__c
                    && ( newOrder.Revised_Amendment_Start_Date__c != null )
                    && ( oldOrder.Revised_Amendment_Start_Date__c != newOrder.Revised_Amendment_Start_Date__c )
                    )
                {
                    revisedOrderStartDateIdSet.add( newOrder.Id );
                }
                //When the Invoice Ready is checked on Project, Project Go Live checkbox will be set to true on Order and activates all the order products where Order Activation trigger is Project Go Live
                if(oldOrder.NSP_Project_Go_Live_Approved__c == false
                   && newOrder.NSP_Project_Go_Live_Date__c != null
                   && newOrder.NSP_Project_Go_Live_Approved__c == true
                   && newOrder.Status != NSP_CPQConstants.ORDER_DRAFT) {
                    projCompletedIdSet.add(newOrder.Id);
                }
                //Prepares the set when Go Live Date is Updated which in turn updates the Subscriptions where Start Date is Project Go Live
                if(oldOrder.NSP_Project_Go_Live_Date__c != newOrder.NSP_Project_Go_Live_Date__c && newOrder.NSP_Project_Go_Live_Date__c != null && newOrder.Type == NSP_CPQConstants.ORDER_TYPE_NEW) {
                    projGoLiveIdSet.add(newOrder.Id);
                }
                //This code is used to stamp order product type on order which is used to set Invoice Batch.
                if(newOrder.NSP_Order_Product_Type__c == null && newOrder.Status == NSP_CPQConstants.ORDER_DRAFT) {
                    orderIdPT.add(newOrder.Id);
                }
                if ( ( newOrder.NSP_Transaction_Type__c == NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                    && ( newOrder.Status == NSP_CPQConstants.ORDER_DRAFT )
                    && ( newOrder.NSP_TerminationDate__c != null )
                    && ( oldOrder.NSP_TerminationDate__c != newOrder.NSP_TerminationDate__c )
                    )
                {
                    orderIds.add(newOrder.Id);
                }
            }
            if ( ( accountIdSet != null ) && ( accountIdSet.size() > 0 ) ) {
                List<blng__PaymentMethod__c> paymentMList = [
                    SELECT Id , blng__Account__c , Payment_Method_Type__c
                    FROM blng__PaymentMethod__c
                    WHERE (
                        ( blng__Account__c IN :accountIdSet )
                        AND ( blng__Active__c = true )
                        AND ( NSP_Active_Custom__c = true )
                    )
                ];
                for ( blng__PaymentMethod__c pmObj : paymentMList ) {
                    if ( !paymentMethodMap.containskey( pmObj.blng__Account__c ) ) {
                        paymentMethodMap.put( pmObj.blng__Account__c , pmObj );
                    }
                }
            }
            if(orderIdPT != null && orderIdPT.size()>0){
                //Call to setOrderProductType future method which sets order product type on order used in setting invoice batch.
                NSP_OrderTriggerHelper.setOrderProductType( orderIdPT );
            }
            if(orderIds.size() > 0){
                NSP_OrderTriggerHelper.updateOrderStartDate( orderIds );
            }
            if(orderIdSet!=null && orderIdSet.size() > 0) {
                //calling method to check and stamp dunning email checkbox on contact acr record
                NSP_OrderTriggerHelper.stampDunningEmailonContact( billToContactIds , accountIds , uniqueAcrIds );
                //end of method call
                List<OrderItem> orderProductList = [
                    SELECT
                        Id ,
                        Order.Project_Status__c ,
                        SBQQ__Status__c,EndDate ,
                        SBQQ__SubscriptionTerm__c ,
                        Order.Type ,
                        Order.NSP_Transaction_Type__c ,
                        Order.NSP_Change_Order_Process_Quote__c ,
                        NSP_Preferred_Payment_Method__c ,
                        NSP_Order_Activation_Trigger__c ,
                        NSP_Order_Activation_Trigger_Amend__c ,
                        Order.AccountId ,
                        NSP_Payment_Method__c ,
                        ServiceDate ,
                        SBQQ__BillingFrequency__c ,
                        NSP_AnniversaryBlngApplicable__c ,
                        blng__BillingAccount__c
                    FROM OrderItem
                    WHERE ( OrderId IN :orderIdSet )
                ];
                for(OrderItem orderItemObj :orderProductList){
                    if(orderItemObj.SBQQ__Status__c != NSP_CPQConstants.ORDER_ACTIVATED){
                        //Checks if Order Product is eligible for Anniversay Billing and activates the order product and sets the bill through Date as Satrt Date + (Subscription Term - 1) when Order is reviewed
                        if ( ( orderItemObj.SBQQ__BillingFrequency__c == NSP_CPQConstants.BLNGFREQ_ANNUAL )
                            && ( orderItemObj.NSP_AnniversaryBlngApplicable__c == true )
                            && ( orderItemObj.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW )
                            )
                        {
                            orderItemObj.ServiceDate = System.today();
                            if(orderItemObj.NSP_Order_Activation_Trigger_Amend__c == NSP_CPQConstants.PROJGOLIVEDATE || orderItemObj.NSP_Order_Activation_Trigger__c == NSP_CPQConstants.PROJGOLIVEDATE){
                                orderItemObj.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                            }
                            if ( orderItemObj.SBQQ__SubscriptionTerm__c != null ) {
                                Integer subscriptionTerm = Integer.valueOf( orderItemObj.SBQQ__SubscriptionTerm__c );
                                orderItemObj.blng__BillThroughDateOverride__c = ( System.today().addMonths( subscriptionTerm ) - 1 );
                            } else if ( orderItemObj.EndDate != null ) {
                                orderItemObj.blng__BillThroughDateOverride__c = orderItemObj.EndDate;
                            }
                            orderItemListToUpdate.add(orderItemObj);
                        } else {
                            //Activates Order Product whose Order Activation trigger is Immediate
                            if(orderItemObj.NSP_Preferred_Payment_Method__c == null && orderItemObj.NSP_Order_Activation_Trigger__c == NSP_CPQConstants.IMMEDIATE && orderItemObj.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW && orderItemObj.Order.NSP_Change_Order_Process_Quote__c == FALSE){
                                orderItemObj.ServiceDate = System.today();
                                orderItemObj.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                                orderItemListToUpdate.add(orderItemObj);
                            }
                            if((orderItemObj.Order.Type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT || orderItemObj.Order.Type == NSP_CPQConstants.SUPPLEMENTAL) && (orderItemObj.order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION) && orderItemObj.NSP_Order_Activation_Trigger_Amend__c == NSP_CPQConstants.IMMEDIATE){
                                orderItemObj.ServiceDate = System.today();
                                orderItemObj.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                                orderItemListToUpdate.add(orderItemObj);
                            }
                            //Activates Order Product whose Order Activation trigger is Milestone based
                            if(orderItemObj.NSP_Order_Activation_Trigger__c == NSP_CPQConstants.MILESTONEBASED && orderItemObj.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW && orderItemObj.Order.NSP_Change_Order_Process_Quote__c == FALSE){
                                orderItemObj.ServiceDate = System.today();
                                orderItemObj.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                                milestoneOpList.add(orderItemObj);
                            }
                        }
                    }
                    if ( paymentMethodMap.containskey( orderItemObj.blng__BillingAccount__c )
                        && ( paymentMethodMap.get( orderItemObj.blng__BillingAccount__c ) != null )
                        && ( orderItemObj.NSP_Preferred_Payment_Method__c == paymentMethodMap.get( orderItemObj.blng__BillingAccount__c ).Payment_Method_Type__c )
                        )
                    {
                        orderItemObj.NSP_Payment_Method__c = paymentMethodMap.get( orderItemObj.blng__BillingAccount__c ).Id;
                        if ( ( orderItemObj.NSP_Order_Activation_Trigger__c == NSP_CPQConstants.IMMEDIATE )
                            && ( orderItemObj.Order.NSP_Change_Order_Process_Quote__c == FALSE )
                            )
                        {
                            orderItemObj.ServiceDate = System.today();
                            orderItemObj.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                        }
                        payMethodList.add( orderItemObj );
                    }
                }
                try{
                    if(orderItemListToUpdate.size()>0) {
                        database.update(orderItemListToUpdate);
                    }
                    if(milestoneOpList.size()>0) {
                        database.update(milestoneOpList);
                    }
                    if(payMethodList.size()>0) {
                        database.update(payMethodList);
                    }
                    //call asset method which creates project asset record
                    NSP_AssetUpdate.createAssetProject(orderIdSet);
                } catch ( Exception e ) {
                    NSP_ErrorLogHandler.logException(
                        OrderTriggerCreateInvoice.class.getName() ,
                        'createInvoice' ,
                        e
                    );
                }
            }
            if(projCompletedIdSet != null && projCompletedIdSet.size() > 0){
                OrderTriggerActivateOrderProduct.activateOrderProduct(newList,projCompletedIdSet);
            }
            if(projectLiveBeforeReviewIds !=null && projectLiveBeforeReviewIds.size()>0){
                OrderTriggerActivateOrderProduct.activateOrderProduct(newList,projectLiveBeforeReviewIds);
            }
            if ( ( revisedOrderStartDateIdSet != null ) && !revisedOrderStartDateIdSet.isEmpty() ){
                OrderTriggerActivateOrderProduct.activateOrderProduct( newList , revisedOrderStartDateIdSet );
            }
            if(projGoLiveIdSet != null && projGoLiveIdSet.size() > 0){
                NSP_OrderTriggerHelper.updateSubStartDate( projGoLiveIdSet );
            }
        }
    }

}
//