/* **************************************************************************************************
 Component Name :  NSP_LockBox_Controller class
 Version              :  1.0
 Created Date         :  August 16, 2022
 Function             :  This component is used as controller class for Lock Box functionality
 : called from lightning page passing required paramter
 Story                :
 Modification Log     :
 *    Rakesh           August 16, 2022          First Iteration
 *    Manikandan       Dec 1,22                  Update Payment Record GL_Entity field value Based LockBox Number
 ***************************************************************************************************
 */
public class NSP_LockBox_Controller{
    public NSP_LockBox_Controller(){
    }

    //Method to check valid lock box record for processing.
    @AuraEnabled
    public static Boolean checkValidRecordForProcess(String lockBoxId){
        Boolean isvalid = false;
        try{
            if (lockBoxId != null){

                List<NSP_Lock_Box__c> validLockBoxes = [SELECT Id, NSP_Account__c, NSP_Bank_Number__c, NSP_Category__c, NSP_Check_Number__c, NSP_Customer_Batch_Number__c, NSP_Deposit_Date__c, NSP_Invoice_Number__c, NSP_Check_Amount__c, NSP_LockBox_Number__c, NSP_Ready_to_Convert__c, NSP_Sequence_Number__c, NSP_Remitter_Name__c, NSP_Status__c, NSP_Transaction_Type__c
                                                        FROM NSP_Lock_Box__c
                                                        WHERE NSP_Ready_to_Convert__c = TRUE AND (NSP_Status__c = :NSP_BillingConstants.PENDING OR NSP_Status__c = :NSP_BillingConstants.PROCESS_FAILED) AND NSP_Payment__c = null AND NSP_Account__c != null AND Id = :lockBoxId
                                                        LIMIT 1];
                if (validLockBoxes.size() == 1){
                    isValid = true;
                }
            }
        } catch (Exception ex){
            throw new AuraHandledException(NSP_CPQConstants.EXCEP_VALID_RECORD_CHECK + ex.getMessage());
        }
        return isvalid;
    }

 /**
* Method to call the process logic function with single lock box Id parameter.
* @param lockBoxId String
* @return success boolean
*                
*/
    @AuraEnabled
    public static Boolean callProcessLockBoxLogic(String lockBoxId){
        Boolean isSuccess = false;
        try{
            if (lockBoxId != null){
                List<lockboxWrapper> res = processLockBoxRecords(new List<String>{ lockBoxId });
                if (res.size() > 0) {
                    isSuccess = res[0].success;
                }
            }
        } catch (Exception ex){
            throw new AuraHandledException(NSP_CPQConstants.EXCEP_PROC_LOCKBOX + ex.getMessage());
        }
        return isSuccess;
    }

/**
* Method to process lock box records.
* @param lockBoxId List of String
* @return List of lockboxWrapper 
*                
*/
    public static List<lockboxWrapper> processLockBoxRecords(List<String> lockBoxIds){
        Map<String, String> lockBoxNumerGLRuleMap = new Map<String, String>();
        Map<String, String> lockBoxNumerGLLegalEntityMap = new Map<String, String>();
        Map<String, String> lockBoxNumerGLTreatmentMap = new Map<String, String>();

        Map<String, Id> glRuleMap = new Map<String, Id>();
        Map<String, Id> gLRulewithglTreatmentMap = new Map<String, Id>();
        Map<String, Id> glLegalEntityMap = new Map<String, Id>();
        
        List<NSP_Lockbox_Rules_Mapping__mdt> lockboxRulesMappingList = [Select NSP_Lock_box_Number__c, NSP_GL_Rule__c, NSP_GL_Legal_Entity__c, NSP_GL_Treatment__c
                                                                        From NSP_Lockbox_Rules_Mapping__mdt
                                                                        WHERE NSP_Lock_box_Number__c != null];
        for (NSP_Lockbox_Rules_Mapping__mdt lockBoxRulesMapping : lockboxRulesMappingList){
            lockBoxNumerGLRuleMap.put(lockBoxRulesMapping.NSP_Lock_box_Number__c, lockBoxRulesMapping.NSP_GL_Rule__c);
            lockBoxNumerGLLegalEntityMap.put(lockBoxRulesMapping.NSP_Lock_box_Number__c, lockBoxRulesMapping.NSP_GL_Legal_Entity__c);
            lockBoxNumerGLTreatmentMap.put(lockBoxRulesMapping.NSP_Lock_box_Number__c, lockBoxRulesMapping.NSP_GL_Treatment__c);
        }
        List<blng__GLRule__c> billingGLRuleList = [Select Id, Name
                                                   From blng__GLRule__c
                                                   WHERE Name IN:lockBoxNumerGLRuleMap.values()];
        for (blng__GLRule__c glRule : billingGLRuleList){
            glRuleMap.put(glRule.Name, glRule.Id);
        }
        List<blng__GLTreatment__c> glTreatmentList = [SELECT Id, Name, blng__GLRule__c
                                                      From blng__GLTreatment__c
                                                      WHERE Name IN:lockBoxNumerGLTreatmentMap.values()];
        for (blng__GLTreatment__c gltreatment : glTreatmentList){
            gLRulewithglTreatmentMap.put(gltreatment.Name, gltreatment.Id);
        }
        
        List<blng__LegalEntity__c> glLegalEntityList = [Select Id, Name
                                                        From blng__LegalEntity__c
                                                        WHERE Name IN:lockBoxNumerGLLegalEntityMap.values()];
        for (blng__LegalEntity__c glLegalEntity : glLegalEntityList){
            glLegalEntityMap.put(glLegalEntity.Name, glLegalEntity.Id);
        }
        List<NSP_Lock_Box__c> validLockBoxes = [SELECT Id, NSP_Account__c, NSP_Bank_Number__c, NSP_Category__c, NSP_Check_Number__c, NSP_Customer_Batch_Number__c, NSP_Deposit_Date__c, NSP_Invoice_Number__c, NSP_Check_Amount__c, NSP_Invoice__c, NSP_Invoice__r.blng__Balance__c, NSP_Invoice__r.blng__InvoiceStatus__c, NSP_LockBox_Number__c, NSP_Ready_to_Convert__c, NSP_Sequence_Number__c, NSP_Remitter_Name__c, NSP_Status__c, NSP_Transaction_Type__c, NSP_Invoice__r.blng__Account__c, NSP_Allocation_Amount__c
                                                FROM NSP_Lock_Box__c
                                                WHERE NSP_Ready_to_Convert__c = TRUE AND (NSP_Status__c = :NSP_BillingConstants.PENDING OR NSP_Status__c = :NSP_BillingConstants.PROCESS_FAILED) AND NSP_Payment__c = null AND NSP_Account__c != null AND Id IN:lockBoxIds];
        List<blng__Payment__c> paymentRecsToInsert = new List<blng__Payment__c>();
        List<blng__PaymentAllocationInvoice__c> allocationsToInsert = new List<blng__PaymentAllocationInvoice__c>();
        Map<String, Id> lockBoxIdToPaymentIdMap = new Map<String, Id>();
        Set<String> completedRecords = new Set<String>();
        List<NSP_Lock_Box__c> lockBoxesToUpdate = new List<NSP_Lock_Box__c>();
        List<lockboxWrapper> results = new List<lockboxWrapper>();
        String errorMsg;

        if (validLockBoxes.size() > 0){
            try{
                for (NSP_Lock_Box__c lb : validLockBoxes){
                    
                    if (lb.NSP_Account__c != null){
                        blng__Payment__c currPayment = new blng__Payment__c();
                        currPayment.blng__Account__c = lb.NSP_Account__c;  // Required field for Payment record
                        currPayment.blng__PaymentType__c = lb.NSP_Transaction_Type__c;
                        currPayment.blng__Amount__c = lb.NSP_Allocation_Amount__c;
                        currPayment.NSP_Created_From_Lock_Box__c = lb.Id;

                        if (lockBoxNumerGLRuleMap.containsKey(lb.NSP_LockBox_Number__c) || lockBoxNumerGLLegalEntityMap.containsKey(lb.NSP_LockBox_Number__c)){
                            currPayment.blng__LegalEntity__c = glLegalEntityMap.get(lockBoxNumerGLLegalEntityMap.get(lb.NSP_LockBox_Number__c));
                            currPayment.blng__GLRule__c = glRuleMap.get(lockBoxNumerGLRuleMap.get(lb.NSP_LockBox_Number__c));
                            currPayment.blng__GLTreatment__c = gLRulewithglTreatmentMap.get(lockBoxNumerGLRuleMap.get(lb.NSP_LockBox_Number__c));
                        }

                        /*
			*Case 1 : When there is a matching invoice on lock box record
			*/
                        if (lb.NSP_Invoice__c != null){
                            currPayment.blng__Invoice__c = lb.NSP_Invoice__c;
                            //currPayment.blng__Account__c = lb.NSP_Account__c;
                            if (lb.NSP_Invoice__r.blng__InvoiceStatus__c == NSP_BillingConstants.POSTED){
                                currPayment.blng__Status__c = NSP_BillingConstants.POSTED;
                                if (lb.NSP_Allocation_Amount__c != null){
                                    blng__PaymentAllocationInvoice__c invalloc = new blng__PaymentAllocationInvoice__c();
                                    invalloc.blng__Amount__c = lb.NSP_Allocation_Amount__c;
                                    invalloc.blng__Invoice__c = lb.NSP_Invoice__c;
                                    invalloc.blng__Type__c = NSP_BillingConstants.ALLOCATION;
                                    invalloc.blng__Payment__c = lb.Id; //placeholder to replace payment id later.
                                    allocationsToInsert.add(invalloc);
                                }
                            }
                        }
                        
                        paymentRecsToInsert.add(currPayment);
                    }
                    /*
                     else {
                     // Case 2 : When there is not matching invoice, but matching Account is opresent on lock box record
                     if(lb.NSP_Account__c!=null){
                     currPayment.blng__Account__c = lb.NSP_Account__c;
                     }
                     else {
                     // DO NOTHING - Defaulting Account is user action.
                     //Case 3 : Defaulting Payment to Generic Account
                     //currPayment.blng__Account__c = '0013C00000ixvkwQAA';
                     //lb.NSP_Account__c = '0013C00000ixvkwQAA';
                     }
                     } */

                    //lb.NSP_Status__c = 'Success';

                }
		/*
		* Creating blng__Payment__c Records
		*/
		
                if (paymentRecsToInsert.size() > 0) {
                    insert paymentRecsToInsert;
                }
                for (blng__Payment__c prec : paymentRecsToInsert){
                    lockBoxIdToPaymentIdMap.put(prec.NSP_Created_From_Lock_Box__c, prec.Id);
                    completedRecords.add(prec.NSP_Created_From_Lock_Box__c);

                }
                /*
		* Creating Allocations Records
		*/
                if (allocationsToInsert.size() > 0){
                    for (blng__PaymentAllocationInvoice__c allocrec : allocationsToInsert){
                        if (lockBoxIdToPaymentIdMap.containsKey(allocrec.blng__Payment__c)){
                            String lbid = allocrec.blng__Payment__c;
                            allocrec.blng__Payment__c = lockBoxIdToPaymentIdMap.get(lbid);
                        }
                    }

                    insert allocationsToInsert;
                }

                /*   for (NSP_Lock_Box__c lb : validLockBoxes ) {
                 if(completedRecords.contains(lb.id)){
                 lb.NSP_Status__c = 'Success';
                 lb.NSP_Payment__c = lockBoxIdToPaymentIdMap.get(lb.id);
                 lockBoxesToUpdate.add(lb);
                 }
                 }
                 if(lockBoxesToUpdate.size()>0) update lockBoxesToUpdate;
                 */

                //return response;
            } catch (Exception ex){
                NSP_ErrorLogHandler.logSaveException('NSP_LockBox_Controller', 'processLockBoxRecords', ex.getMessage());
                errorMsg = ex.getMessage();

            } finally{

                for (String lbid : lockBoxIds){
                    if (completedRecords.contains(lbid)){
                        NSP_Lock_Box__c lb = new NSP_Lock_Box__c();
                        lb.Id = lbid;
                        lb.NSP_Status__c = NSP_BillingConstants.SUCCESS;
                        lb.NSP_Payment__c = lockBoxIdToPaymentIdMap.get(lbid);
                        lockBoxesToUpdate.add(lb);
                        lockboxWrapper lbw = new lockboxWrapper(lbid, true);
                        results.add(lbw);
                    } else{
                        NSP_Lock_Box__c lb = new NSP_Lock_Box__c();
                        lb.Id = lbid;
                        lb.NSP_Status__c = NSP_BillingConstants.PROCESS_FAILED;
                        lb.NSP_Error_Message__c = errorMsg;
                        lockBoxesToUpdate.add(lb);
                        lockboxWrapper lbw = new lockboxWrapper(lbid, false);
                        results.add(lbw);
                    }
                }
                if (lockBoxesToUpdate.size() > 0) {
                    update lockBoxesToUpdate;
                }
            }

        }
        return results;
    }

    public class lockboxWrapper{
        @AuraEnabled
        public String lockboxId;
        @AuraEnabled
        public Boolean success;
        public lockboxWrapper(String lbId, Boolean opresult){
            this.lockboxId = lbId;
            this.success = opresult;
        }

    }

}