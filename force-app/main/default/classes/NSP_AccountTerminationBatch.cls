/**
* @description  : Batch Class to update Account's status to terminated if all assets are terminated and their termination date is in previous month
* @author Harsha Khiroya
* @date 06/02/2022
* Name : NSP_AccountTerminationBatch
Last Updated on 06/02/2023
*/

global without sharing class NSP_AccountTerminationBatch implements Schedulable,Database.Batchable<SObject>, Database.Stateful {
    public Integer recordsProcessed = 0; // stores number of records processed.
    
 
     public Database.QueryLocator start(Database.BatchableContext bc){
       //returns QueryLocator to execute method.
         String query = 'SELECT id,Name,AccountId,Status,NSP_Termination_Date__c FROM Asset WHERE NSP_Termination_Date__c !=null AND NSP_Termination_Date__c = LAST_N_MONTHS:1 AND Status IN (\'Terminated\',\'Backout\')';
         return Database.getQueryLocator(query);
     }
 
    //Execute Method of Batch Class.
     public void execute(Database.BatchableContext bc, List<Asset> scope){
         Set<Id> accountIdSet = new Set<Id>();
         List<Account> accountsToUpdate = new List<Account>();
         for(Asset assetRec : scope){ 
             if(assetRec.AccountId!=null){
                 accountIdSet.add(assetRec.AccountId);
             }
         }
         List<Account> listofAccts=[SELECT Id , NSP_Sales_Service_Account_Status__c, (SELECT Id,Status,NSP_Termination_Date__c, NSP_Account_Status__c,AccountID  FROM Assets),
                                   (SELECT ID, StageName FROM Opportunities)
                                   FROM Account WHERE Id IN :accountIdSet];
        for (Account acc : listofAccts) {
            Boolean allAssetsTerminated = true;
            Boolean allOpportunitiesClosed = true;
            for (Asset asobj : acc.Assets) {
                if (asobj.NSP_Termination_Date__c == null || (asobj.Status != NSP_ServiceConstants.BACKOUT && asobj.Status != NSP_ServiceConstants.TERMINATED)) {
                    allAssetsTerminated = false;
                    break;
                }
            }
            for (Opportunity opp : acc.Opportunities) {
                if (opp.StageName != NSP_ServiceConstants.CLOSED_WON && opp.StageName != NSP_ServiceConstants.CLOSED_LOST) {
                    allOpportunitiesClosed = false;
                    break;
                }
            }
            if (allAssetsTerminated && allOpportunitiesClosed) {
                acc.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.TERMINATED;
                accountsToUpdate.add(acc);
            }
        }
         //update scope;
         try{
            if(!accountsToUpdate.isEmpty()){
                Database.SaveResult[] accountSaveResults = Database.update(accountsToUpdate,true);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AccountTerminationBatch', 'Execute Method', accountSaveResults);
            }
         }catch(Exception ex){
             NSP_CustomException.LogException(ex);
         }
     }
     public void finish(Database.BatchableContext bc){
       
     }
 
     global void execute(SchedulableContext scon) {
         Database.executeBatch(new NSP_AccountTerminationBatch(),100);
      }
 }