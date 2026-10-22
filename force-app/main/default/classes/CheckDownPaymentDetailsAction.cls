public with sharing class CheckDownPaymentDetailsAction {
    // test w/ CheckDownPaymentDetailsActionTest (94%)

    @InvocableMethod(label='check DownPayment Detail' description='method to determine if down payment id required' category='Account')
    public static void checkDownPaymentDetails( List<Id> orderIds ) {
        Set<Id> orderItemToCheckSet = new Set<Id>();
        try
        {
            List<Order> orderProcessList = new List<Order>(
                [
                    SELECT
                        Id ,
                        NSP_Down_Payment_Required__c ,
                        NSP_Project__c ,
                        NSP_Project__r.Project_Complete_Date__c ,
                        OpportunityId ,
                    (
                        SELECT
                            Id ,
                            SBQQ__BillingFrequency__c ,
                            NSP_Project__c ,
                            NSP_Project__r.Project_Complete_Date__c ,
                            TotalPrice
                        FROM OrderItems
                        WHERE (
                            SBQQ__BillingFrequency__c IN (
                                'Monthly' ,
                                'Annual' ,
                                'Invoice Plan'
                            )
                        )
                    )
                    FROM Order
                    WHERE (
                        ( Id IN : orderIds )
                        AND ( NSP_Project_Complete_Date__c = NULL )
                    )
                ]
            );

            //order of evaluation as per business logic (change with caution)
            //
            //mark downpayment flags
            orderProcessList = CheckDownPaymentDetailsAction.evaluateDownPayment( orderProcessList );
            //get invoice plan order items
            orderItemToCheckSet = CheckDownPaymentDetailsAction.evaluateOrderForItemsToCheck( orderProcessList );
            //iterate through billing transactions to decide for valid OP based on billing amount
            Set<Id> orderItemApplicable = CheckDownPaymentDetailsAction.evaluateBillingTransaction( orderItemToCheckSet );
            orderProcessList = CheckDownPaymentDetailsAction.evaluateInvoicePlan(
                orderProcessList ,
                orderItemApplicable
            );
            //update projects and orders
            CheckDownPaymentDetailsAction.processUpdates( orderProcessList );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                CheckDownPaymentDetailsAction.class.getName() ,
                'checkDownPaymentDetails' ,
                e
            );
        }
    }

    //method to iterate through orders and decide down payment
    private static List<Order> evaluateDownPayment( List<Order> orderProcessList ) {
        List<Order> responseList = new List<Order>();
        if ( ( orderProcessList != null ) && ( !orderProcessList.isEmpty() ) ){
            for(Order eachOrder : orderProcessList){
                responseList.add( CheckDownPaymentDetailsAction.setDownPaymentRequired( eachOrder ) );
            }
        }
        return responseList;
    }

    //method to populate downpayment flags on order
    private static Order setDownPaymentRequired( Order eachOrder ) {
        if ( ( eachOrder != null )
            && ( eachOrder.OrderItems != null )
            && !eachOrder.OrderItems.isEmpty()
           )
        {
            for ( OrderItem eacholi : eachOrder.OrderItems ) {
                if ( String.isNotBlank( eacholi.SBQQ__BillingFrequency__c )
                    && ( eacholi.SBQQ__BillingFrequency__c == 'Annual' )
                    && ( eacholi.TotalPrice != null )
                    && ( eacholi.TotalPrice > 0 )
                   )
                {
                    eachOrder.NSP_Down_Payment_Required__c = 'Yes';
                } else if ( ( eacholi.SBQQ__BillingFrequency__c == 'Monthly' )
                           && ( eachOrder.NSP_Down_Payment_Required__c != 'Yes' )
                          )
                {
                    eachOrder.NSP_Down_Payment_Required__c = 'No';
                }
            }
        }
        return eachOrder;
    }

    private static Set<Id> evaluateOrderForItemsToCheck( List<Order> orderProcessList ){
        //maintain all order items set
        Set<Id> orderItemToCheckSet = new Set<Id>();
        if ( ( orderProcessList != null ) && ( !orderProcessList.isEmpty() ) ){
            for(Order eachOrder : orderProcessList){
                //for every order merge the set of Ids in original set
                orderItemToCheckSet.addAll( CheckDownPaymentDetailsAction.collectOrderItemsToCheck( eachOrder ) );
            }
        }
        return orderItemToCheckSet;
    }

    //method to return set of invoice plan order items for every order
    private static Set<Id> collectOrderItemsToCheck( Order eachOrder ) {
        //maintain set of order items
        Set<Id> orderItemIds = new Set<Id>();
        if ( ( eachOrder != null )
            && ( eachOrder.NSP_Down_Payment_Required__c != 'Yes' )
            && ( eachOrder.OrderItems != null )
            && ( !eachOrder.OrderItems.isEmpty() )
           )
        {
            for ( OrderItem eacholi : eachOrder.OrderItems ) {
                if ( eacholi.SBQQ__BillingFrequency__c == 'Invoice Plan' ) {
                    //add order item to set if it is invoice plan
                    orderItemIds.add( eacholi.Id );
                }
            }
        }
        return orderItemIds;
    }


    private static Set<Id> evaluateBillingTransaction ( Set<Id> orderItemToCheckSet ) {
        Set<Id> orderItemApplicable = new Set<Id>();
        if ( ( orderItemToCheckSet != null ) && ( !orderItemToCheckSet.isEmpty() ) ) {
            for ( blng__BillingTransaction__c eachTransaction : [
                SELECT
                    Id ,
                    blng__BillingSchedule__r.blng__OrderProduct__c ,
                    blng__InvoicePlanLine__c ,
                    blng__InvoicePlanLine__r.NSP_Billing_Commencement_Trigger__c ,
                    blng__BillingSchedule__r.blng__Amount__c
                FROM blng__BillingTransaction__c
                WHERE
                    ( blng__BillingSchedule__c != null )
                    AND ( blng__BillingSchedule__r.blng__OrderProduct__c IN : orderItemToCheckSet )
                    AND ( NSP_DownPayment_Required__c = TRUE )
            ]){
                if( ( eachTransaction.blng__BillingSchedule__c != null )
                   && ( eachTransaction.blng__BillingSchedule__r.blng__Amount__c != null )
                   && ( eachTransaction.blng__BillingSchedule__r.blng__Amount__c > 0 )
                  )
                {
                    orderItemApplicable.add( eachTransaction.blng__BillingSchedule__r.blng__OrderProduct__c );
                }
            }
        }
        return orderItemApplicable;
    }

    //method to perform updates on orders and projects
    private static void processUpdates( List<Order> orderProcessList ) {
        // update project
        Map<Id,pse__Proj__c> projectUpdateMap = CheckDownPaymentDetailsAction.evaluateProject( orderProcessList );
        if ( ( projectUpdateMap != null ) && !projectUpdateMap.isEmpty() ) {
            update projectUpdateMap.values();
        }
        // update order
        Map<Id,Order> orderUpdateMap = CheckDownPaymentDetailsAction.evaluateOrderUpdateMap( orderProcessList );
        if ( ( orderUpdateMap != null ) && !orderUpdateMap.isEmpty() ) {
            update orderUpdateMap.values();
        }
    }

    //method to process order downpayment flag
    private static List<Order> evaluateInvoicePlan( List<Order> orderProcessList , Set<Id> orderItemApplicable ) {
        if( ( orderProcessList != null ) && ( !orderProcessList.isEmpty() ) ) {
            for(Order eachOrder : orderProcessList) {
                eachOrder = CheckDownPaymentDetailsAction.evaluateOrderItems( eachOrder , orderItemApplicable );
            }
        }
        return orderProcessList;
    }

    //method to check orderItems for down payment applicable
    private static Order evaluateOrderItems( Order eachOrder , Set<Id> orderItemApplicable ) {
        if ( ( eachOrder != null )
            && ( eachOrder.NSP_Down_Payment_Required__c != 'Yes' )
            && ( eachOrder.OrderItems != null )
            && ( !eachOrder.OrderItems.isEmpty() )
           )
        {
            for ( OrderItem eacholi : eachOrder.OrderItems ) {
                // check if order item have billing transaction
                if ( ( eacholi.SBQQ__BillingFrequency__c == 'Invoice Plan' )
                    && ( orderItemApplicable != null )
                    && ( orderItemApplicable.contains( eacholi.Id ) )
                   )
                {
                    eachOrder.NSP_Down_Payment_Required__c = 'Yes';
                }
            }
        }
        return eachOrder;
    }

    //method to populate project fields
    private static Map<Id,pse__Proj__c> evaluateProject( List<Order> orderProcessList ) {
        Map<Id,pse__Proj__c> projectUpdateMap = new Map<Id,pse__Proj__c>();
        if( ( orderProcessList != null ) && ( !orderProcessList.isEmpty() ) ) {
            for(Order eachOrder : orderProcessList) {
                if ( eachOrder.NSP_Project__c != null ) {
                    pse__Proj__c newProject = new pse__Proj__c(
                        Id = eachOrder.NSP_Project__c
                    );
                    if ( String.isNotBlank( eachOrder.OpportunityId ) ){
                        newProject.pse__Opportunity__c = eachOrder.OpportunityId;
                    }
                    if ( eachOrder.NSP_Down_Payment_Required__c == 'No' ) {
                        newProject.Project_Down_Payment_Not_Required__c = true;
                    }
                    projectUpdateMap.put( newProject.Id , newProject );
                }
            }
        }
        return projectUpdateMap;
    }

    //method to update orderUpdateMap based on downpayment
    private static Map<Id,Order> evaluateOrderUpdateMap( List<Order> orderProcessList ) {
        Map<Id,Order> orderUpdateMap = new Map<Id,Order>();
        if ( ( orderProcessList != null ) && !orderProcessList.isEmpty() ) {
            for ( Order eachOrder : orderProcessList ) {
                if ( String.isNotBlank( eachOrder.NSP_Down_Payment_Required__c ) ) {
                    orderUpdateMap.put( eachOrder.Id , eachOrder );
                }
            }
        }
        return orderUpdateMap;
    }

}
//
