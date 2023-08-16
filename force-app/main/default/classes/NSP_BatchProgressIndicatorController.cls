public class NSP_BatchProgressIndicatorController {
    // test w/ NSP_BatchProgressIndicatorControllerTest (88%)

    @AuraEnabled
    public static List<AsyncApexJob> getJobDetails(){
        try {
            List<String> applicableStatus = new List<String>{'Queued','Processing'};
            List<String> applicableClasses = new List<String>{'NSP_InvoiceBatch','NSP_DocuSignInvoiceDocumentBatch'};
            List<AsyncApexJob> asyncJobList = [SELECT Id, Status, JobItemsProcessed, TotalJobItems,
                                                NumberOfErrors, ApexClass.Name FROM AsyncApexJob WHERE Status IN :applicableStatus AND ApexClass.Name IN:applicableClasses LIMIT 2 ]; //where Status IN :applicableStatus AND ApexClass.Name IN:applicableClasses
            return asyncJobList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
   }

   @AuraEnabled
   public static string executeBatch(String className, Integer chunkSize, String recId){
        //if(recId!=null){
        try {
            Id batchJobId; 
            if(className == 'NSP_InvoiceBatch') {
            List<blng__Invoice__c> allinvs = [SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceStatus__c='Draft' AND blng__InvoiceRunCreatedBy__c =:recId ];
            List<id> invoicesList = new List<Id>();
            for (blng__Invoice__c inv : allinvs) {
                invoicesList.add(inv.Id) ; 
            }
            batchJobId = Database.executeBatch(new NSP_InvoiceBatch(invoicesList),chunkSize);
            }

            if(className == 'NSP_DocuSignInvoiceDocumentBatch') {
            List<blng__Invoice__c> allinvs = [SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceStatus__c = 'Posted' AND NSP_CLM_Document_Received__c = FALSE AND blng__InvoiceRunCreatedBy__c =:recId  LIMIT 1000 ];
            List<String> invsID = new List<String>();
            for (blng__Invoice__c inv : allinvs) {
                invsID.add(inv.Id) ; 
            }
            batchJobId = Database.executeBatch(new NSP_DocuSignInvoiceDocumentBatch(invsID),chunkSize);
            }


            //Type batchInstance = Type.forName(className);
            //Id batchJobId = Database.executeBatch((Database.Batchable<sObject>)batchInstance.newInstance(), chunkSize);
            return batchJobId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
   // }
   }

    @AuraEnabled
    public static Boolean getUserAccess(){
        try {
            Boolean result=false;
            String userId = UserInfo.getUserId();
            Set<String> financeRolesAllowed = new Set<String>(System.Label.NSP_Finance_Batch_Access.split(','));
            List<User> userDetails =[SELECT Id, Name, Email, Profile.Name, UserRole.Name FROM User where Id=:userId AND UserRole.Name IN:financeRolesAllowed ];
            List<GroupMember> memberList = [SELECT Id, UserOrGroupId, GroupId, Group.DeveloperName FROM GroupMember WHERE Group.DeveloperName = 'NSP_Invoice_Posting_Group' AND UserOrGroupId=:userId ]; 
            if(memberList.size()>0 || userDetails.size()>0){ result = true; }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
   }

}