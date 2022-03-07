//
// This code is provided as an example only, no warranty is expressed or implied. If you choose to use 
// any or all of this sample code, you agree to assume all risk and liability associated with that use.
//

trigger OnCLMDocumentCreateTrigger on CLM_Document__c (after insert) {

    CLM_Document__c clmDoc = [SELECT Id, CLM_Document_Id__c, Name, Account__c, Opportunity__c
                              FROM CLM_Document__c 
                              WHERE Id IN:Trigger.newMap.keySet()
                              LIMIT 1];
    
    if(!Test.isRunningTest()){ 
        if(clmDoc.Opportunity__c != null){
    		CLMDocumentTransfer.DownloadDocument(clmDoc.CLM_Document_Id__c, clmDoc.Opportunity__c);
    	}else if(clmDoc.Account__c != null){
        	CLMDocumentTransfer.DownloadDocument(clmDoc.CLM_Document_Id__c, clmDoc.Account__c); 
    	}
    }
}