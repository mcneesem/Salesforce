public class NSP_BatchProgressIndicatorController {
    // test w/ NSP_BatchProgressIndicatorControllerTest (88%)

   @AuraEnabled
   public static string executeBatch(String className, Integer chunkSize, String recId){
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
                List<blng__Invoice__c> allinvs = [SELECT Id FROM blng__Invoice__c WHERE blng__InvoiceStatus__c = 'Posted' AND blng__InvoiceRunCreatedBy__c =:recId  LIMIT 10000 ];
                List<String> invsID = new List<String>();
                for (blng__Invoice__c inv : allinvs) {
                    invsID.add(inv.Id) ;
                }
                batchJobId = Database.executeBatch(new NSP_DocuSignInvoiceDocumentBatch(invsID),chunkSize);
            }
            return batchJobId;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
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

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getBatchOptions() {
        Boolean hasPermission = CustomPermissionController.checkUserPermission(
            'Use_Invoice_Post_Batch' ,
            UserInfo.getUserId()
        );
        // prepare a simple Map that can be converted to picklist options by the LWC...
        List<Map<String,String>> options = new List<Map<String,String>>();
        if ( hasPermission ) {
            options.add(
                new Map<String,String>{
                    'label' => 'Invoice Post Batch' ,
                    'value' => 'NSP_InvoiceBatch'
                }
            );
        }
        options.add(
            new Map<String,String>{
                'label' => 'DocuSign Document Generation Batch' ,
                'value' => 'NSP_DocuSignInvoiceDocumentBatch'
            }
        );
        return options;
    }

}