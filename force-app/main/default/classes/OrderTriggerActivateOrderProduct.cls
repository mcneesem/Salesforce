public with sharing class OrderTriggerActivateOrderProduct {
    // test w/ OrderTriggerActivateOrderProductTest (??%)

    private static final String CLOSE_LOST = 'Close/Lost';

    public static void activateOrderProduct( List<Order> newList , Set<Id> projCompletedIdSet ) {
        Set<String> actionTypeValues = new Set<String>( System.Label.OrderItemRecalcTypes.split( ';' ) );
        List<OrderItem> orderItemToUpdate = new List<OrderItem>();
        List<OrderItem> orderProductList = [
            SELECT
                Id ,
                Order.Project_Status__c ,
                SBQQ__Status__c ,
                Order.NSP_Transaction_Type__c ,
                Order.Type ,
                Order.NSP_Project_Go_Live_Date__c ,
                NSP_Order_Activation_Trigger__c ,
                Product2.NSP_Partial_Period_Free_Treatment__c ,
                SBQQ__BillingFrequency__c ,
                Order.EffectiveDate ,
                OrderId ,
                NSP_OrderProductStartDate__c ,
                SBQQ__SubscriptionType__c ,
                NSP_AnniversaryBlngApplicable__c ,
                NSP_Order_Activation_Trigger_Amend__c ,
                NSP_QL_ActionType__c ,
                SBQQ__QuoteLine__r.NSP_ActionType__c ,
                NSP_ReCalculation_Status_Internal__c ,
                SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c ,
                NSP_Project_Completion_Date__c ,
                Order.NSP_Usage_Products_Count__c ,
                ServiceDate ,
                SBQQ__RequiredBy__c ,
                EndDate ,
                Order.Revised_Amendment_Start_Date__c ,
                blng__HoldBilling__c
            FROM OrderItem
            WHERE (
                ( OrderId IN :projCompletedIdSet )
                AND ( SBQQ__Status__c = 'Draft' )
            )
        ];
        for ( OrderItem oi : orderProductList ) {
            if ( ( oi.Order.Project_Status__c != OrderTriggerActivateOrderProduct.CLOSE_LOST )
                && ( ( ( oi.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW ) && ( oi.NSP_Order_Activation_Trigger__c == NSP_CPQConstants.PROJGOLIVEDATE ) )
                    || ( ( oi.NSP_Order_Activation_Trigger_Amend__c == NSP_CPQConstants.PROJGOLIVEDATE )
                        && ( oi.Order.Type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                        && ( oi.Order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                        )
                    )
                )
            {
                if ( ( oi.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW )
                    && ( oi.Product2.NSP_Partial_Period_Free_Treatment__c == false )
                    && ( oi.SBQQ__BillingFrequency__c == NSP_CPQConstants.BLNGFREQ_MONTHLY )
                    )
                {
                    if ( !oi.ServiceDate.isSameDay( System.today().toStartOfMonth() ) ) {
                        oi.ServiceDate = System.today().toStartOfMonth();
                        oi.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                        orderItemToUpdate.add( oi );
                    } else {
                        oi.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                        orderItemToUpdate.add( oi );
                    }
                } else if ( ( oi.Order.Type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                    && ( oi.Order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                    && ( oi.SBQQ__SubscriptionType__c == NSP_CPQConstants.SUBS_EVERGREEN )
                    && ( oi.NSP_OrderProductStartDate__c == '1st of the month' )
                    )
                {
                    oi.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                    orderItemToUpdate.add( oi );
                } else if ( ( oi.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == NSP_CPQConstants.SUBS_EVERGREEN )
                    || ( ( oi.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == NSP_CPQConstants.SUBS_RENEWABLE )
                        && ( oi.Order.Type == NSP_CPQConstants.QUOTE_TYPE_NEW )
                        )
                    || ( ( oi.SBQQ__RequiredBy__c == null )
                        && ( oi.Order.Type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                        && ( oi.SBQQ__SubscriptionType__c == null )
                        && ( oi.Order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                        )
                    )
                {
                    if ( oi.ServiceDate < System.today() ) {
                        oi.ServiceDate = System.today();
                    }
                    oi.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                    orderItemToUpdate.add( oi );
                }
            }
            if ( actionTypeValues.contains( oi.SBQQ__QuoteLine__r.NSP_ActionType__c )
                && ( oi.blng__HoldBilling__c == 'Yes' && oi.SBQQ__QuoteLine__r.NSP_ActionType__c == null )
                && ( ( oi.Order.NSP_Usage_Products_Count__c == null )
                    || ( oi.Order.NSP_Usage_Products_Count__c == 0 )
                    )
                && ( oi.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == NSP_CPQConstants.SUBS_RENEWABLE )
                && ( oi.NSP_ReCalculation_Status_Internal__c != 'Processing' )
                && ( oi.NSP_ReCalculation_Status_Internal__c != 'Staged' )
                && ( oi.Order.Type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                && ( oi.NSP_Order_Activation_Trigger_Amend__c == NSP_CPQConstants.PROJGOLIVEDATE )
                && ( oi.Order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                )
            {
                if ( oi.Order.NSP_Project_Go_Live_Date__c != null ) {
                    oi.NSP_Override_Start_Date__c = System.today();
                } else {
                    oi.NSP_Override_Start_Date__c = oi.Order.Revised_Amendment_Start_Date__c;
                }
                if ( ( oi.NSP_AnniversaryBlngApplicable__c == true )
                    && ( oi.EndDate != null )
                    )
                {
                    oi.blng__BillThroughDateOverride__c = oi.EndDate;
                }
                orderItemToUpdate.add( oi );
            } else if ( ( oi.Order.Project_Status__c != OrderTriggerActivateOrderProduct.CLOSE_LOST )
                && ( oi.Order.Type == NSP_CPQConstants.QUOTE_TYPE_AMENDMENT )
                && ( oi.NSP_Order_Activation_Trigger_Amend__c == NSP_CPQConstants.PROJGOLIVEDATE )
                && ( oi.SBQQ__QuoteLine__r.SBQQ__SubscriptionType__c == NSP_CPQConstants.SUBS_RENEWABLE )
                && ( oi.Order.NSP_Transaction_Type__c != NSP_CPQConstants.QUOTE_TYPE_TERMINATION )
                )
            {
                oi.ServiceDate = System.today();
                oi.SBQQ__Status__c = NSP_CPQConstants.ORDER_ACTIVATED;
                if ( ( oi.NSP_AnniversaryBlngApplicable__c == true )
                    && ( oi.EndDate != null )
                    )
                {
                    oi.blng__BillThroughDateOverride__c = oi.EndDate;
                }
                orderItemToUpdate.add( oi );
            }
        }
        try {
            if ( ( orderItemToUpdate != null ) && !orderItemToUpdate.isEmpty() ) {
                Database.update( orderItemToUpdate );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_OrderTriggerHelper.class.getName() ,
                'activateOrderProduct' ,
                e
            );
        }
        NSP_UpdateProjMilestone updateJob = new NSP_UpdateProjMilestone( projCompletedIdSet );
        // enqueue the job for processing , updates Override Next Billing Date on Billing transaction
        System.enqueueJob( updateJob );
    }

}
//