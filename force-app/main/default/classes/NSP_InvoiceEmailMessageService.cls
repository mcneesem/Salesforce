/**
* @description  : Dunnvoice Email Service Class to customize invoice emails sent from Apex
* @author Rakesh Das
* @date 11/28/2022
* Name : NSP_InvoiceEmailMessageService
*/

public class NSP_InvoiceEmailMessageService {
    
    private NSP_InvoiceEmailMessageService(){}
    public static final String ACHTEMPLATEID = NSP_GenericEmailUtility.getTemplateIdFromDevName('NSP_SendEmailforACH');
    public static final String PAYMENTTEMPLATEID = NSP_GenericEmailUtility.getTemplateIdFromDevName('NSP_SendInvoiceLink');
    
/**
* Invocable Method that can be called from Flows
* @param  List of String - Invoice Id from flow
* @return void
* @Author Rakesh Das
* @Since November 2022
*/
    @InvocableMethod(label='Send Invoice Email' description='Sends invoice emails on posting')
    public static void sendInvoiceEmail(List<String> invoiceIds) {
        sendInvoiceEmails(invoiceIds);
    }
    
/**
* Single static method called via Flow / Batch to send invoice emails. Depends on generateInvoiceEmails for email generation.
* @param  List of String - Invoice Ids
* @return void
* @Author Rakesh Das
* @Since November 2022
*/    
    public static void sendInvoiceEmails(List<String> invoiceIds) {
        Integer ecount = 0; // count of emails sent
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        emails = generateInvoiceEmails(invoiceIds); // call to generate email from template
        if(emails.size()>0) {
            ecount = NSP_GenericEmailUtility.sendSingleEmailMessages(emails,false); //method to send emails.
        }
        //return ecount;
    }
    
/**
* Single static method to generate invoice emails.
* @param  List of List of String - Invoice Ids
* @return List of Email Messages - List of Messaging.SingleEmailMessage objects
* @Author Rakesh Das
* @Since November 2022
*/
    public static List<Messaging.SingleEmailMessage> generateInvoiceEmails(List<String> invoiceIds) {
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        OrgWideEmailAddress orgWidAddress = NSP_GenericEmailUtility.getOrgWideAddress( System.label.NSP_no_reply );
        List<blng__Invoice__c> invcToUpdate = new  List<blng__Invoice__c>();
        
        if(invoiceIds!=null) {
            List<blng__Invoice__c> invRecs = getInvoiceRecsById(invoiceIds);
            Map<String, String> invIdToFileMap = getInvoiceDocuments(invoiceIds);
            
            for (blng__Invoice__c inv : invRecs) {
                //invoice recod to update
                blng__Invoice__c invUpd = new blng__Invoice__c();
                invUpd.Id = inv.Id;
                invUpd.NSP_Send_Email__c = false;
                // boolean flag to check email criterias
                Boolean isEmailCheck = false;
                isEmailCheck =  evaluateInvoiceEmailCriterias(inv);
                
                if( isEmailCheck ) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail = generateInvoiceEmail(inv, orgWidAddress.Id);
                    //mail.setSaveAsActivity(true);
                    //Linking Invoice to update
                    
                    if (mail != null ){
                        if(invIdToFileMap.containsKey(inv.Id)){
                            mail.setEntityAttachments(new List<String> {invIdToFileMap.get(inv.Id)});
                        }
                        emails.add(mail);  
                        // Setting Invoice Email Sent checkbox to TRUE
                        invUpd.NSP_Invoice_Email_Sent__c = true;
                    }
                }
                //adding to invoice list for update.
                invcToUpdate.add(invUpd);
                
            }
            
            if(invcToUpdate.size() >0) {
                //update invcToUpdate;
                NSP_InvoiceTriggerHandler.TriggerDisabled = true;
                List<Database.SaveResult> res = Database.update(invcToUpdate,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_InvoiceEmailMessageService', 'generateInvoiceEmails', res);
            }
            
        }   
        return emails;
    }
    
/**
* Single static method to check criterias for sending invoice emails.
* @param  Invoice object
* @return Boolean
* @Author Rakesh Das 
* @Since November 2022
*/
    public static Boolean evaluateInvoiceEmailCriterias (blng__Invoice__c inv) {
        
        Boolean isinvEmailCheck = false;
        DocuSignRESTSettings__mdt callbackUserName = DocuSignRESTSettings__mdt.getInstance('NSP_Docusign_Callback_Username');
        if( 
            ( 
                //first block of conditions for scenarios where emails should not be sent to customer
                (inv.blng__BillToContact__c != null && inv.NSP_Bdgt_Quote_First_Invoice__c == false && inv.blng__InvoiceStatus__c == 'Posted' && inv.blng__Account__r.Name != 'Insperity WO Billing Account' && inv.NSP_NoOfInvoiceLines__c != inv.NSP_PartialPeriodApplLines__c ) 
                // OR condition to above logic to send email anytime the send email checkbox is checked by user.
                || (inv.NSP_Send_Email__c == true && inv.LastModifiedBy.Username != callbackUserName.Value__c)) 
            // Mandatory conditions below, irrespective of other logic, below criteria should match.
            && inv.NSP_CLM_Document_Received__c == true && inv.NSP_Physical_Mail_Opt_In__c == false && inv.blng__Balance__c > 0 
        ) {
            isinvEmailCheck = true;
        }
        
        
        return isinvEmailCheck;
    }
    
    
/**
* Single static method to generate emails.
* @param  Invoice object
* @return Single Email Messages - Messaging.SingleEmailMessage object
* @Author Rakesh Das
* @Since November 2022
*/
    
    public static Messaging.SingleEmailMessage generateInvoiceEmail(blng__Invoice__c inv, String orgWideId) {
        
        List<String> toAddressList = New List<String>();
        String targetObjId;
        String templateId;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        if(inv.NSP_Payment_Method_Count__c > 0) {
            templateId=ACHTEMPLATEID;
        }
        else if (inv.NSP_Payment_Method_Count__c == 0){
            templateId=PAYMENTTEMPLATEID;
        }
        else {
            //do nothing
        }
        targetObjId = inv.blng__BillToContact__c;
        if(inv.NSP_Send_Email__c && inv.NSP_Bill_To_Email__c!=NULL) {
           toAddressList.addAll(inv.NSP_Bill_To_Email__c.split(',')); 
        }
        else {
        toAddressList.add(inv.blng__BillToContact__r.Email);
        }
        if(templateId!=null && targetObjId!=null) {
            
            mail = NSP_GenericEmailUtility.generateSingleMessageWithTemplate(templateId,inv.Id,targetObjId,orgWideId,toAddressList, null, null, null);
            mail.setSaveAsActivity(true);
            
        }
        
        return mail;
    }
    
    // Method to get invoice records
    public static List<blng__Invoice__c> getInvoiceRecsById (List<String> invoiceIds) {
        List<blng__Invoice__c> invRecs;
        try {
            invRecs = [SELECT Id, NSP_Payment_Method_Count__c, NSP_Invoice_Email_Sent__c, NSP_Send_Email__c, NSP_CLM_Document_Received__c, 
                       blng__InvoiceStatus__c, blng__BillToContact__c, blng__BillToContact__r.Email, LastModifiedById, LastModifiedBy.UserName, 
                       blng__Account__c, blng__Account__r.Name, NSP_Bdgt_Quote_First_Invoice__c, NSP_Bill_To_Email__c,
                       NSP_Physical_Mail_Opt_In__c, blng__Balance__c,NSP_NoOfInvoiceLines__c,NSP_PartialPeriodApplLines__c FROM blng__Invoice__c WHERE Id IN:invoiceIds AND blng__InvoiceStatus__c = 'Posted' AND NSP_CLM_Document_Received__c = TRUE AND NSP_Invoice_Email_Sent__c= FALSE ];
        }
        catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_InvoiceEmailMessageService','getInvoiceRecsById',ex.getMessage());
        }
        return invRecs;
    }
    
    // Method to get content document link records
    public static Map<String, String> getInvoiceDocuments (List<String> invoiceIds) {
        Map<String, String> invIdFileIdMap = new Map<String, String>();
        try {
            List<ContentDocumentLink> fileLinks = [Select Id, LinkedEntityId, ContentDocument.LatestPublishedVersion.Id, ContentDocument.LatestPublishedVersion.CreatedDate from ContentDocumentLink WHERE LinkedEntityId IN:invoiceIds AND ContentDocument.Title LIKE 'INV%' ORDER BY ContentDocument.LatestPublishedVersion.CreatedDate DESC ];
            for (ContentDocumentLink cdl : fileLinks) {
                if(!invIdFileIdMap.containsKey(cdl.LinkedEntityId)) {
                    invIdFileIdMap.put(cdl.LinkedEntityId, cdl.ContentDocument.LatestPublishedVersion.Id);
                }
            }
        }
        catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_InvoiceEmailMessageService','getInvoiceDocuments',ex.getMessage());
        }
        return invIdFileIdMap;
    }
}