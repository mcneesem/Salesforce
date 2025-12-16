//
// @description  : Batch Class to create renewal opportunity and quote based on renewal term and product type
// @author Rakesh Das
// @date 08/04/2021
// Name : NSP_ContractRenewal_Batch
//
public class NSP_ContractRenewal_Batch implements Database.Batchable<SObject>, Database.Stateful {
    // test w/ NSP_ContractRenewal_Batch_Test (93%)

    public Integer recordsProcessed = 0; // stores number of records processed.
    public String query;
    public Map<String,NSP_Contract_Renewal_Configurations__mdt> productTypeToConfigMap = new Map<String,NSP_Contract_Renewal_Configurations__mdt>();
    public Map<String,String> userNameToIdMap = new Map<String,String>();
    public String contractId;

    // Code for QA testing only. Not added to GIT. Must be deleted in higher sandboxes
    public NSP_ContractRenewal_Batch( String contractIdinput ) {
        contractId = contractIdinput;
        List<String> ownerUsernames = new List<String>();
        Map<String, NSP_Contract_Renewal_Configurations__mdt> renewalConfigs = NSP_Contract_Renewal_Configurations__mdt.getAll();
        if(renewalConfigs.size()>0) {
            //looping through renewal configuration map to put in respective lists by date range
            for(NSP_Contract_Renewal_Configurations__mdt configrec : renewalConfigs.values()){
                productTypeToConfigMap.put(configrec.NSP_Linked_ProductType__c, configrec);
                ownerUsernames.add(configrec.NSP_Default_Opportunity_Owner__c);
            }
        }
        //querying user object to get renewal owner user ids
        if(ownerUsernames.size()>0){
            for(User usr : [Select Id, Username from User WHERE Username IN:ownerUsernames]) {
                userNameToIdMap.put(usr.Username,usr.Id);
            }
        }
        //query formation
        query='SELECT Id, SBQQ__RenewalForecast__c, SBQQ__RenewalQuoted__c, ContractTerm,NSP_Product_Type__c,SBQQ__ActiveContract__c FROM Contract WHERE SBQQ__RenewalForecast__c = FALSE AND SBQQ__RenewalQuoted__c = FALSE AND ContractTerm>=1 AND SBQQ__ActiveContract__c=1 AND';
        query+=' Id =:contractId';
    }

    // Code for QA testing only. Not added to GIT. Must be deleted in higher sandboxes

    //Constructor declaration
    public NSP_ContractRenewal_Batch() {
        //List to store products with renewal date ranges
        List<String> ProductsWith30DaysList = new List<String>();
        List<String> ProductsWith60DaysList = new List<String>();
        List<String> ownerUsernames = new List<String>();
        Map<String, NSP_Contract_Renewal_Configurations__mdt> renewalConfigs = NSP_Contract_Renewal_Configurations__mdt.getAll();
        if(renewalConfigs.size()>0) {
            //looping through renewal configuration map to put in respective lists by date range
            for(NSP_Contract_Renewal_Configurations__mdt configrec : renewalConfigs.values()){
                if(configrec.NSP_Days_Before_Expiry__c == 30){
                    ProductsWith30DaysList.add(configrec.NSP_Linked_ProductType__c);
                }
                if(configrec.NSP_Days_Before_Expiry__c == 60 ||configrec.DeveloperName == 'Sage' ) {     // This static string is intentional. It might be removed in future.
                    ProductsWith60DaysList.add(configrec.NSP_Linked_ProductType__c);
                }
                productTypeToConfigMap.put(configrec.NSP_Linked_ProductType__c, configrec);
                ownerUsernames.add(configrec.NSP_Default_Opportunity_Owner__c);
            }
        }
        //querying user object to get renewal owner user ids
        if(ownerUsernames.size()>0){
            for(User usr : [Select Id, Username from User WHERE Username IN:ownerUsernames]) {
                userNameToIdMap.put(usr.Username,usr.Id);
            }
        }
        //formulating string from list to use in query parameters
        String Days30ListasString = '(\'' + String.join(ProductsWith30DaysList, '\', \'') + '\')';
        String Days60ListasString = '(\'' + String.join(ProductsWith60DaysList, '\', \'') + '\')';
        //query formation
        query = 'SELECT Id , SBQQ__RenewalForecast__c , SBQQ__RenewalQuoted__c , ContractTerm , NSP_Product_Type__c , SBQQ__ActiveContract__c ';
        query += 'FROM Contract ';
        query += 'WHERE ';
        query += '( SBQQ__RenewalForecast__c = false ) ';
        query += 'AND ( SBQQ__RenewalQuoted__c = false ) ';
        query += 'AND ( ContractTerm > 1 ) ';
        query += 'AND ( SBQQ__ActiveContract__c = 1 ) ';
        query += 'AND ( EndDate >= TODAY ) ';
        query += 'AND ( ';
        query += '    ( NSP_Product_Type__c INCLUDES ' + Days30ListasString + ' AND EndDate <= NEXT_N_DAYS:30 ) ';
        query += '    OR ( NSP_Product_Type__c INCLUDES ' + Days60ListasString + ' AND EndDate <= NEXT_N_DAYS:62 ) ';
        query += ')';
    }

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator(query);
    }

    public void execute( Database.BatchableContext bc , List<Contract> scope ) {
        for(Contract contract:scope){
            NSP_Contract_Renewal_Configurations__mdt contractRenewConfig = productTypeToConfigMap.get(contract.NSP_Product_Type__c);
            if(contractRenewConfig!=null) {
                contract.SBQQ__RenewalForecast__c = TRUE;
                contract.SBQQ__RenewalQuoted__c = TRUE;
                contract.NSP_Customer_Signature_Required__c = contractRenewConfig.NSP_Renewal_Signature_Required__c;
                if(userNameToIdMap.containskey(contractRenewConfig.NSP_Default_Opportunity_Owner__c)){
                    contract.SBQQ__RenewalOwner__c = userNameToIdMap.get(contractRenewConfig.NSP_Default_Opportunity_Owner__c);
                }
                recordsProcessed = recordsProcessed + 1;
            }
        }
        //update scope;
        try {
            database.update(scope);
        } catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
    }

    public void finish( Database.BatchableContext bc ) {
        //THIS COMMENT IS INTENTIONAL. DO NOT DELETE.
        // This sends an email to Operations team DL. Will be used in Phase 2 when contracts are loaded into system.
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        if ( EmailDeliverabilityController.IsEnabledOutbound ) {
            AsyncApexJob apexJob = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob WHERE Id = :BC.getJobId()
            ];
            // OPTIONAL: Send an email to the Apex job's submitter notifying of job completion.
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {apexJob.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Contract Renewal Batch ' + apexJob.Status);
            mail.setPlainTextBody(
                'The batch Apex job processed ' + apexJob.TotalJobItems +
                ' batches with '+ apexJob.NumberOfErrors + ' failures.' +
                'Total Records :'+recordsProcessed
            );
            try {
                Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ mail } );
            } catch ( Exception e ) {
                System.debug( ' ~ CATCH ~ e=' + e );
            }
        }
    }

}
//