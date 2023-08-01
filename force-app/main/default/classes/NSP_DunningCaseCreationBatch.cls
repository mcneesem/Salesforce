/**
* @description  : Batch Class to create dunning cases for pending invoices
* @author Rakesh Das
* @date 09/05/2022
* Name : NSP_DunningCaseCreationBatch
*/

public class NSP_DunningCaseCreationBatch implements Database.Batchable<sObject>, Database.Stateful {

    static final string DunningCase_RT = 'Dunning';
    static final Id DUNNING_CASE_RT_ID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(DunningCase_RT).getRecordTypeId();
      

    public Integer recordsProcessed = 0; // stores number of records processed.
    public Integer casesCreated = 0;
    public String query;
    public String queueId;

    public NSP_DunningCaseCreationBatch(){

        List<Group> orderProcessingQueue = [SELECT Id,DeveloperName,name FROM Group WHERE Type = 'Queue' AND DeveloperName = 'NSP_Order_Processing_Queue' LIMIT 1];
		queueId = orderProcessingQueue[0].Id;

        query = 'SELECT Id, Name, blng__Account__c, blng__ARStatus__c, blng__DueDate__c, blng__BillToContact__c,blng__InvoiceDate__c, blng__Balance__c, NSP_Invoice_To_Email__c, blng__PaymentStatus__c, blng__InvoiceStatus__c FROM blng__Invoice__c WHERE blng__DueDate__c <= N_DAYS_AGO:45';
        query+= ' AND blng__Balance__c > 0 AND blng__InvoiceStatus__c = \'Posted\' AND blng__PaymentStatus__c!=\'Paid\'';
    }

    
	public Database.QueryLocator start(Database.BatchableContext bc){
		
     
        //returns QueryLocator to execute method.
        return Database.getQueryLocator(query);
      }

      public void execute(Database.BatchableContext bc, List<blng__Invoice__c> scope){

        Set<Id> AccountIds = new Set<Id>();
        Map <String, Case> accountIdToCaseMap = new Map<String,Case>();
        List<Case> casesToInsert = new List<Case>();
        for (blng__Invoice__c inv : scope) {

            AccountIds.add(inv.blng__Account__c);

        }

        List<Case> openDunningCases = [SELECT Id, CaseNumber, Status, ClosedDate, AccountId, NSP_Dunning_Case_Invoice__c FROM Case WHERE AccountId IN: AccountIds AND Status!='Closed' AND Type=:NSP_BillingConstants.DUNNING_ACCOUNT AND NSP_Dunning_Type__c=:NSP_BillingConstants.OPEN_INVOICE AND RecordTypeId=:DUNNING_CASE_RT_ID];
        for(Case cs : openDunningCases){
            accountIdToCaseMap.put(cs.AccountId, cs);
        }

        for (blng__Invoice__c inv : scope) {

            if(accountIdToCaseMap.containsKey(inv.blng__Account__c)) {
               /* if(inv.NSP_Linked_Dunning_Case__c==null) {
                    inv.NSP_Linked_Dunning_Case__c = accountIdToCaseMap.get(inv.blng__Account__c).id;
                    invsToUpdate.add(inv);
                } */

            }
            else {

                Case dunCase = new Case();
                dunCase.AccountId = inv.blng__Account__c;
                dunCase.ContactId = inv.blng__BillToContact__c;
                dunCase.Type = NSP_BillingConstants.DUNNING_ACCOUNT;
                dunCase.NSP_Dunning_Type__c = NSP_BillingConstants.OPEN_INVOICE;
                //dunCase.NSP_Dunning_Case_Invoice__c = inv.Id;
                dunCase.recordTypeId = DUNNING_CASE_RT_ID;
                dunCase.NSP_Dunning_Automation__c = NSP_BillingConstants.AUTOMATED;
                dunCase.Origin = NSP_BillingConstants.DUNNING;
                duncase.Subject = NSP_BillingConstants.DUNNING_CASE_SUBJECT;
                dunCase.OwnerId = queueId;
                casesToInsert.add(dunCase);
                accountIdToCaseMap.put(inv.blng__Account__c,dunCase);
            }
        }

        if (casesToInsert.size()>0) {
            insert casesToInsert;
            casesCreated += casesToInsert.size();

            /* for (Case cs : casesToInsert) {
                if(cs.NSP_Dunning_Case_Invoice__c!=null) {
                    blng__Invoice__c pinv = new blng__Invoice__c();
                    pinv.Id = cs.NSP_Dunning_Case_Invoice__c;
                    pinv.NSP_Linked_Dunning_Case__c = cs.Id;
                    invsToUpdate.add(pinv);
                }
            } */
        }
        /* if (invsToUpdate.size()>0) {
            update invsToUpdate;
        } */

      }

      public void finish(Database.BatchableContext bc){        
      }

}