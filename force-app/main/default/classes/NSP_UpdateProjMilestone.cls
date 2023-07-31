/**************************************************************************************************************************
* @Description  :  Queueable Class to update override Billing target date on Billing transaction
* Author : CPQ Team
* Name : NSP_UpdateProjMilestone
**************************************************************************************************************************/
public class NSP_UpdateProjMilestone implements Queueable {
    private Set<Id> orderIdSet = new Set<Id>();
    private String commenceTrigger = null;
    public NSP_UpdateProjMilestone(Set<Id> projCompletedIdSet) {
        this.orderIdSet = projCompletedIdSet;
    }
        /**
* Method Name : updateProjGoLiveDate 
* Description : Method to update billing target date on billing transaction when project go live is approved.
* Author : CPQ Team       Date : 09/22/2022
* @param projCompletedIdSet Set of New Order. 
* @return void  
*/
    public void execute(QueueableContext context) {
        List<blng__BillingTransaction__c> updateList = new List<blng__BillingTransaction__c>();
        List<blng__BillingTransaction__c> transactionList=[SELECT Id,blng__Status__c,blng__OverrideBillingTargetDate__c,NSP_Project_Completion_Date__c,NSP_Billing_Commencement_Trigger__c FROM blng__BillingTransaction__c WHERE NSP_Order_Id__c IN :orderIdSet];
        for(blng__BillingTransaction__c transacationObj : transactionList){
            if(transacationObj.blng__Status__c == NSP_CPQConstants.BLNG_STATUS_PENDING){
                if(transacationObj.NSP_Billing_Commencement_Trigger__c == NSP_CPQConstants.PROJ_GO_LIVE){
                    transacationObj.blng__OverrideBillingTargetDate__c = System.today();
                    updateList.add(transacationObj);
                }
                if(transacationObj.NSP_Billing_Commencement_Trigger__c == NSP_CPQConstants.PROJ_COMPLETE){
                    transacationObj.blng__OverrideBillingTargetDate__c = transacationObj.NSP_Project_Completion_Date__c;
                    updateList.add(transacationObj);
                }
            }
         }
         if(updateList != null && updateList.size() > 0){
            try{
                database.update(updateList); 
            }
            catch(Exception ex){
                NSP_CustomException.LogException(ex);
            } 
        }
    }

}