// calculates OrderItem free period
public class NSP_OrderItemFreePeriodCalculator {
    // test w/ NSP_OrderItemFreePeriodCalculatorTest (95%)

    private NSP_OrderItemFreePeriodCalculator () {
    }

    @InvocableMethod(label='Update Free Period' description='Evaluates and update available free period on an Order Line')
    public static void updateFreePeriodFlow( List<String> invoiceIdSet ) {
        NSP_OrderItemFreePeriodCalculator.evaluateFreePeriodInvoiceLine( invoiceIdSet );
    }

    // evaluate free periods on order item
    private static void evaluateFreePeriodInvoiceLine( List<String> invoiceIdSet ) {
        Set<String> invoicelinesId = new Set<String>();
        for ( blng__InvoiceLine__c invLine : [
                    SELECT
                        Id ,
                        blng__BillingFrequency__c ,
                        blng__ChargeType__c
                    FROM blng__InvoiceLine__c
                    WHERE (
                        ( blng__Invoice__c IN :invoiceIdSet )
                        AND ( blng__BillingFrequency__c = 'Monthly' )
                        AND ( blng__ChargeType__c = 'Recurring' )
                    )
                ]
            )
        {
            invoicelinesId.add( invLine.Id );
        }
        if ( !invoicelinesId.isEmpty() ) {
            NSP_OrderItemFreePeriodCalculator.evaluateFreePeriodOrderLine( invoicelinesId );
        }
    }

    // evaluate free periods on order item
    public static void evaluateFreePeriodOrderLine( Set<String> invoiceLineIdSet ) {
        List<OrderItem> orderLinesToUpdate = new List<OrderItem>();
        Set<String> orderItemIds = new Set<String>();
        Map<String,Integer> orderProductWithInvcMap = new Map<String,Integer>();
        for ( blng__InvoiceLine__c invLine : [
                    SELECT
                        Id ,
                        blng__BillingFrequency__c ,
                        blng__ChargeType__c ,
                        blng__OrderProduct__c ,
                        blng__OrderProduct__r.NSP_Total_Free_Periods__c ,
                        blng__OrderProduct__r.NSP_Free_Periods_Available__c
                    FROM blng__InvoiceLine__c
                    WHERE (
                        ( Id IN :invoiceLineIdSet )
                        AND ( blng__OrderProduct__r.NSP_Free_Periods_Available__c >= 0 )
                    )
                ]
            )
        {
            orderItemIds.add( invLine.blng__OrderProduct__c );
        }
        AggregateResult[] groupedResults = [
            SELECT blng__OrderProduct__c, COUNT(Id)InvoiceLinesCount
            FROM blng__InvoiceLine__c
            WHERE (
                ( blng__OrderProduct__c IN :orderItemIds )
                AND ( blng__InvoiceLineStatus__c = 'Posted' )
            )
            GROUP BY blng__OrderProduct__c
        ];
        for ( AggregateResult ar : groupedResults ) {
            orderProductWithInvcMap.put(
                (String)ar.get( 'blng__OrderProduct__c' ) ,
                (Integer)ar.get( 'InvoiceLinesCount' )
            );
        }
        for ( OrderItem oi : [
                    SELECT
                        Id ,
                        OrderItemNumber ,
                        OrderId ,
                        NSP_Total_Free_Periods__c ,
                        NSP_Free_Periods_Available__c
                    FROM OrderItem
                    WHERE ( Id IN :orderItemIds )
                ]
            )
        {
            if ( orderProductWithInvcMap.containsKey( oi.Id ) ) {
                if( oi.NSP_Total_Free_Periods__c >= orderProductWithInvcMap.get( oi.Id ) ) {
                    oi.NSP_Free_Periods_Available__c = ( oi.NSP_Total_Free_Periods__c - orderProductWithInvcMap.get( oi.Id ) );
                } else {
                    oi.NSP_Free_Periods_Available__c = 0;
                }
                if ( oi.NSP_Free_Periods_Available__c == 0 ) {
                    oi.NSP_Partial_Period_Applicable__c = false;
                }
                orderLinesToUpdate.add( oi );
            }
        }
        if ( !orderLinesToUpdate.isEmpty() ) {
            update orderLinesToUpdate;
        }
    }

    // zero out free periods on usage summary records
    public static void applyZeroUnitPriceToUsageRecords( Set<String> orderLinesWithUsage ) {
        NSP_ApplyZeroPriceToUsageSummary queableObj = new NSP_ApplyZeroPriceToUsageSummary( orderLinesWithUsage );
        if ( Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
            System.enqueueJob( queableObj );
        }
    }

}
//