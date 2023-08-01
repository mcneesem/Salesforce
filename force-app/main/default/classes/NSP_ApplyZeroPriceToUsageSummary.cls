/**
* @description  : Queueable Class to apply zero unit price to Usage Summary records
* @author Rakesh Das
* @date 11/24/2022
* Name : NSP_ApplyZeroPriceToUsageSummary
*/

public class NSP_ApplyZeroPriceToUsageSummary implements Queueable {
    //varibales declaration
    private Set<String> orderLinesWithUsage;
    //constructor
    public NSP_ApplyZeroPriceToUsageSummary(Set<String> orderLinesWithUsage) {
        this.orderLinesWithUsage = orderLinesWithUsage;
    }
    
    //execute method implementation
    public void execute(QueueableContext context) {
        try{
            Map<String,Decimal> orderLineWithTotalPeriods = new Map<String,Decimal>();
            Map<String,OrderItem> orderLinesMap = new Map<String,OrderItem>();
            List<blng__UsageSummary__c> usageRecsToUpdate = new List<blng__UsageSummary__c>();
            
            for (OrderItem oi : [Select Id, OrderItemNumber, OrderId, NSP_Total_Free_Periods__c, NSP_Free_Periods_Available__c,ServiceDate,EndDate FROM OrderItem WHERE Id IN:orderLinesWithUsage]) { if(oi.NSP_Total_Free_Periods__c!=null) {
                orderLineWithTotalPeriods.put(oi.Id,oi.NSP_Total_Free_Periods__c);
            }
                                                                                                                                                                                                     orderLinesMap.put(oi.Id, oi);
                                                                                                                                                                                                    }
            
            Date currMonthFirstDate = System.Date.today().toStartOfMonth(); 
            Date freeMonthsMaxLimit = currMonthFirstDate.addMonths(4);
            List<blng__UsageSummary__c> usageSumRecs = [SELECT Id, blng__Status__c,blng__OrderProduct__c, blng__AppliedUnitPrice__c, blng__SummaryStartDate__c, blng__SummaryEndDate__c FROM blng__UsageSummary__c WHERE blng__OrderProduct__c IN:orderLinesWithUsage AND blng__Status__c='New' AND blng__SummaryStartDate__c < : freeMonthsMaxLimit];
            
            for(blng__UsageSummary__c usgSumRec : usageSumRecs) {
                if(orderLineWithTotalPeriods.containsKey(usgSumRec.blng__OrderProduct__c)) {
                    
                    Date oliStartDate = orderLinesMap.get(usgSumRec.blng__OrderProduct__c).ServiceDate;
                    //Date oliStartMonthDate = oliStartDate.toStartOfMonth();
                    
                    /*FreePeriodEndMonth is the 1st day of the month after free period ends.
                        Example - If free period ends on November. freePeriodEndMonth will be Dec-01 */
                    Date freePeriodEndMonth = oliStartDate.toStartOfMonth().addMonths(orderLineWithTotalPeriods.get(usgSumRec.blng__OrderProduct__c).intValue());
                    if(usgSumRec.blng__SummaryStartDate__c < freePeriodEndMonth && usgSumRec.blng__Status__c == 'New') {
                        usgSumRec.NSP_Billed_Free__c=true;
                        usageRecsToUpdate.add(usgSumRec);     
                    }
                }
            }
            
            if(usageRecsToUpdate.size()>0) {
                update usageRecsToUpdate;
            }
        } catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }
}