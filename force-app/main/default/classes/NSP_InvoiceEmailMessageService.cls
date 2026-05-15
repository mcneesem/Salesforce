/**
* @description  : Dunnvoice Email Service Class to customize invoice emails sent from Apex
* @author Rakesh Das
* @date 11/28/2022
* Name : NSP_InvoiceEmailMessageService
*/

public class NSP_InvoiceEmailMessageService {
    // test w/ NSP_InvoiceEmailMessageServiceTest (84%)

    private NSP_InvoiceEmailMessageService(){

    }


    public static final String ACHTEMPLATEID = NSP_GenericEmailUtility.getTemplateIdFromDevName('NSP_SendEmailforACH');
    public static final String PAYMENTTEMPLATEID = NSP_GenericEmailUtility.getTemplateIdFromDevName('NSP_SendInvoiceLink');
    public static final String CREDITCARD_TEMPLATEID = NSP_GenericEmailUtility.getTemplateIdFromDevName('NSP_CC_All_Invoice_Template');
    public static final String ACH_WX_TEMPLATEID = NSP_GenericEmailUtility.getTemplateIdFromDevName('NSP_ACH_WX_Invoice_Template');
    public static final String ACH_RET_TEMPLATEID = NSP_GenericEmailUtility.getTemplateIdFromDevName('NSP_ACH_RET_Invoice_Template');
    public static final String CONTRACTOR_MANAGEMENT_TEMPLATEID = NSP_GenericEmailUtility.getTemplateIdFromDevName('Contractor_Management_Inv_Email_Template');
    public static final String CONTRACTOR_MANAGEMENT_PRODUCT_TYPE = 'Contractor Management';


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
            Map<Id,blng__InvoiceLine__c> invoiceToinvLineMap =new Map<Id,blng__InvoiceLine__c> ();

            for (blng__Invoice__c inv : invRecs) {
                if(invIdToFileMap.containsKey(inv.Id)){

                    if(inv.blng__InvoiceInvoiceLines__r.size()>0){
                        invoiceToinvLineMap.put(inv.Id,inv.blng__InvoiceInvoiceLines__r[0]);
                    }

                    //invoice recod to update
                    blng__Invoice__c invUpd = new blng__Invoice__c();
                    invUpd.Id = inv.Id;
                    invUpd.NSP_Send_Email__c = false;
                    invUpd.NSP_InvBatch_Processed_Internal__c= true;
                    // boolean flag to check email criterias
                    Boolean isEmailCheck = false;
                    isEmailCheck =  evaluateInvoiceEmailCriterias(inv);

                    if( isEmailCheck ) {
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail = generateInvoiceEmail(inv, invoiceToinvLineMap.get(inv.Id),orgWidAddress.Id);
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

        Boolean isInvEmailCheck = false;
        DocuSignRESTSettings__mdt callbackUserName = DocuSignRESTSettings__mdt.getInstance('NSP_Docusign_Callback_Username');
        if(
            (
                //first block of conditions for scenarios where emails should not be sent to customer
                (inv.blng__BillToContact__c != null && inv.NSP_Bdgt_Quote_First_Invoice__c == false && inv.blng__InvoiceStatus__c == 'Posted' && inv.blng__Account__r.Name != 'Insperity WO Billing Account' && inv.NSP_NoOfInvoiceLines__c != inv.NSP_PartialPeriodApplLines__c )
                // OR condition to above logic to send email anytime the send email checkbox is checked by user.
                || (inv.NSP_Send_Email__c == true && inv.LastModifiedBy.Username != callbackUserName.Value__c))
            // Mandatory conditions below, irrespective of other logic, below criteria should match.
            && inv.NSP_Physical_Mail_Opt_In__c == false && inv.blng__Balance__c > 0
        ) {
            isInvEmailCheck = true;
        }


        return isInvEmailCheck;
    }


/**
* Single static method to generate emails.
* @param  Invoice object
* @return Single Email Messages - Messaging.SingleEmailMessage object
* @Author Rakesh Das
* @Since November 2022
*/

    public static Messaging.SingleEmailMessage generateInvoiceEmail(blng__Invoice__c inv,blng__InvoiceLine__c invLine, String orgWideId) {

        List<String> toAddressList = New List<String>();
        String targetObjId;
        String templateId;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        /*
        if(inv.NSP_Payment_Method_Count__c > 0) {
            templateId=ACHTEMPLATEID;
        }
        else if (inv.NSP_Payment_Method_Count__c == 0){
            templateId=PAYMENTTEMPLATEID;
        }
        else {
            //do nothing
        }*/

        //DF-05491-Added on 04Aug
        Boolean isCreditCard = false;
    	Boolean isACH = false;
        if(invLine!=null && invLine.NSP_Payment_Method__c!=null){
            if(!isCreditCard && invLine.NSP_Payment_Method__r.blng__PaymentType__c == 'Credit Card'){
                isCreditCard = true;
            }
            if(!isACH && invLine.NSP_Payment_Method__r.blng__PaymentType__c == 'ACH'){
                isACH = true;
            }
        }
        //Payment Method Link and is ACH--
        if(isACH && inv.NSP_Legal_Entity_Internal__c == NSP_BillingConstants.WX_LEGAL_ENTITY_NAME){
            templateId = ACH_WX_TEMPLATEID;
            if(invLine.NSP_Order_Product_Type__c == CONTRACTOR_MANAGEMENT_PRODUCT_TYPE){
              templateId = CONTRACTOR_MANAGEMENT_TEMPLATEID;
            }
        }
        else if(isACH && inv.NSP_Legal_Entity_Internal__c == NSP_BillingConstants.RET_LEGAL_ENTITY_NAME){
            templateId = ACH_RET_TEMPLATEID;
        }
        else if (isACH){
            templateId = ACHTEMPLATEID;
        }
        //Payment Method Link and is Credit Card
        else if (isCreditCard){
            templateId = CREDITCARD_TEMPLATEID;
        }
        //No Payment Method Link
        else{
            templateId=PAYMENTTEMPLATEID;
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
            invRecs = [SELECT Id,NSP_Legal_Entity_Internal__c, NSP_Payment_Method_Count__c, NSP_Invoice_Email_Sent__c, NSP_Send_Email__c,
                       blng__InvoiceStatus__c, blng__BillToContact__c, blng__BillToContact__r.Email, LastModifiedById, LastModifiedBy.UserName,
                       blng__Account__c, blng__Account__r.Name, NSP_Bdgt_Quote_First_Invoice__c, NSP_Bill_To_Email__c,
                       NSP_Physical_Mail_Opt_In__c, blng__Balance__c,NSP_NoOfInvoiceLines__c,NSP_PartialPeriodApplLines__c,(SELECT name,id,NSP_Payment_Method__c,NSP_Payment_Method__r.blng__PaymentType__c,NSP_Order_Product_Type__c FROM blng__InvoiceInvoiceLines__r) FROM blng__Invoice__c WHERE Id IN:invoiceIds AND blng__InvoiceStatus__c = 'Posted' AND NSP_Invoice_Email_Sent__c= FALSE ];


        }
        catch(Exception ex){
            NSP_InvoiceEmailMessageService.handleException(ex ,'getInvoiceRecsById');
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
            NSP_InvoiceEmailMessageService.handleException(ex ,'getInvoiceDocuments');
        }
        return invIdFileIdMap;
    }

      // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_InvoiceEmailMessageService.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_InvoiceEmailMessageService.class.getName() ,
            methodName ,
            e
        );
    }
}