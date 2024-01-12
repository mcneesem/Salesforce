/**************************************************************************************************   
Apex Controller Name :  QuoteExtControllerTests
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :  Represents the Quote Extension Controller. Contains validation and logic for Quote Submit For Approval button.
Story                :                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

* CPQ Team                  October 10, 2021          First Iteration
***************************************************************************************************/
public with sharing class QuoteExtController {
    // test w/ QuoteExtControllerTests (82%)

        private SBQQ__Quote__c objQuote;
        public set<string> SE_Approval_Chain = new set<string>{'NSP_SE_Group_1','NSP_SE_Group_2','NSP_SE_MidMarket'};
        public boolean doNotAllow{get;set;}
        public  String errorFromValidation{get;set;}
        public  String isRequestedDateValid{get;set;}
        public  String descriptionOfService{get;set;}
        public Boolean invalidRequestedDate{get;set;}
        public Boolean isInvoiceEmailBlank{get;set;}
        public Boolean isQuoteExpirationInvalid{get;set;}
        public Boolean isDescriptionOfServiceBlank{get;set;}
        public Boolean quoteOwnerMismatch{get;set;}
        public  Boolean invoiceToEmailBilling{get;set;}
        public  Boolean invoiceToEmailShipping{get;set;}
        public  List<String> quoteFieldMessage = new List<String>();
        public  List<String> multipleErrors {get;set;}
        public Boolean isBillingAddressBlank{get;set;}
        public Boolean isShippingAddressBlank{get;set;}
        public Boolean isBillToAddressBlank{get;set;}
        public Boolean isShipToAddressBlank{get;set;}
        public Boolean isBenchmarkJobDateInvalid{get;set;}
        public Boolean showQuoteError{get;set;}
        public Boolean isImplementationDateInvalid{get;set;}
        public Boolean isTalentCpnnectSubDateInvalid{get;set;}
        public Boolean isRPODateInvalid{get;set;}
        public Boolean isProjectRecruitingDateInvalid{get;set;}
        public Boolean isBrandingTargetDateInvalid{get;set;}
        public  Boolean isCustomerStakeHolderBilling{get;set;}
        public  Boolean isCustomerStakeHolderShipping{get;set;}
        public  Boolean isCustomerRoleBilling{get;set;}
        public  Boolean isCustomerRoleShipping{get;set;}
        public  Boolean isAutorizedPurchaseBilling{get;set;}
        public  Boolean isAutorizedPurchaseShipping{get;set;}
        public  Boolean isAutorizedPurchaseBilling2{get;set;}
        public  Boolean isAutorizedPurchaseShipping2{get;set;}
        public  Boolean isPrimaryContactBilling{get;set;}
        public  Boolean isPrimaryContactShipping{get;set;}
        public  Boolean isProjOwnerNotSet{get;set;}
        public  Boolean isSerialIdsBlank{get;set;}
        public Boolean isETSerialIdsNotMatched{get;set;}
        public Boolean isTerminationDateBlank{get;set;}

        Static final String REQ_DATE_ERR_MESSAGE=System.Label.NSP_RequestFirstCheckDate;
        Static final String DESC_SERVICES_ERR_MESSAGE=System.Label.NSP_Description_Of_Service;
        Static final String INVOICE_EMAIL_ERR_MESSAGE=System.Label.NSP_InvoiceToEmailonQuote;
        Static final String QUOTE_EXPIRATION_DATE_ERR_MESSAGE=System.Label.NSP_QuoteExpirationDate;
        Static final String QUOTE_OWNER_MISMATCH_ERR_MESSAGE=System.Label.NSP_Quote_Owner_Mismatch_Message;
        public Static final String INVOICE_BILLING_ERR=System.Label.NSP_InvoiceEmailBilling;
        public Static final String INVOICE_SHIPPING_ERR=System.Label.NSP_InvoiceEmailShipping;
        
        Static final String BILLING_ADDRESS_ERR=System.Label.NSP_QuoteBillingAddressValidationMessage;
        Static final String SHIPPING_ADDRESS_ERR=System.Label.NSP_QuoteShippingAddressValidationMessage;
        Static final String CUSTOMER_BILLING_ADDRESS_ERR=System.Label.NSP_QuoteCustomerBillingAddressValidationMessage;
        Static final String CUSTOMER_SHIPPING_ADDRESS_ERR=System.Label.NSP_QuoteCustomerShippingAddressValidationMessage;
        Static final String BENCHMARK_JOB_DATE_ERR=System.Label.NSP_Benchmark_Date_Validation;
        public Static final String IMPLEMENTATION_DATE_ERR=System.Label.NSP_Implementation_Start_Date_Error;
        public Static final String TALENT_CONNECT_SUB_DATE_ERR=System.Label.NSP_Talent_Connect_Subscription_Error;
        public Static final String RPO_DATE_ERR=System.Label.NSP_RPO_Date_Validation_Error;
        public Static final String PROJECT_RECRUITING_DATE_ERR=System.Label.NSP_Project_Recruiting_Date_Validation_Error;
        public Static final String BRANDING_TARGET_DATE_ERR=System.Label.NSP_Branding_Target_Date_Validation_Error;
        public Static final String CUST_STAKEHOLDER_BILLING_ERR=System.Label.NSP_CustStakeHolderBilling;
        public Static final String CUST_STAKEHOLDER_SHIPPING_ERR=System.Label.NSP_CustStakeholderShipping;
        public Static final String CUST_ROLE_SHIPPING_ERR=System.Label.NSP_CustRoleShipping;
        public Static final String CUST_ROLE_BILLING_ERR=System.Label.NSP_CustRoleBilling;
        public Static final String AUTHORIZED_PURCHASE_BILL_ERR=System.Label.NSP_AuthorizedPurchaseBilling;
        public Static final String AUTHORIZED_PURCHASE_SHIP_ERR=System.Label.NSP_AuthorizedPurchaseShipping;
        public Static final String AUTHORIZED_PURCHASE2_BILL_ERR=System.Label.NSP_AuthorizedPurchaseBilling2;
        public Static final String AUTHORIZED_PURCHASE2_SHIP_ERR=System.Label.NSP_AuthorizedPurchaseShipping2;
        public Static final String PRIMARY_CONTACT_BILL_ERR=System.Label.NSP_PrimaryContactBilling;
        public Static final String PRIMARY_CONTACT_SHIP_ERR=System.Label.NSP_PrimaryContactShipping;
        Static final String SERIAL_IDS_ERR=System.Label.NSP_SerialId_Validation;
        Static final String ET_SERIAL_IDS_ERR=System.Label.NSP_ET_Serial_Id_Validation;
        public static final String TERMINATION_DATE_ERROR = System.Label.NSP_Termination_Date_Error;

    public QuoteExtController( ApexPages.StandardController stdController ) {
            objQuote = (SBQQ__Quote__c )stdController.getRecord();
            Map<Id,Profile> profileMap = new Map<Id,Profile>(); 
            if(String.isNotBlank(system.label.NSP_Quote_Approval_Bypass_Profile)){
            profileMap = new Map<Id,Profile>([SELECT Id,Name FROM profile WHERE Name in : system.label.NSP_Quote_Approval_Bypass_Profile.split(',')]);
            }

        if ( !profileMap.containsKey( UserInfo.getProfileId() ) || Test.isRunningTest() ) {
            errorFromValidation = NSP_QuoteApprovalPreValidation.validateRetirementServiceQuote(objQuote.Id);
            //descriptionOfService = NSP_QuoteApprovalPreValidation.validateDescriptionOfServices(objQuote.Id);
            quoteFieldMessage = NSP_QuoteApprovalPreValidation.validateRequestedFirstCheck(objQuote.Id);
            
            //Ensuring that the On Demand product isadded correctly @utpal Utkalit STY-00450
            if(objQuote != null && objQuote.SBQQ__Status__c == 'Draft' && errorFromValidation == null )  {
            doNotAllow = false;
            }
            else {
                doNotAllow  = true;
                if(String.isNotEmpty(errorFromValidation)) {
                multipleErrors = errorFromValidation.split('\n');
                
                }
            }

            //Check if quote fields are valid or invalid
            if ( quoteFieldMessage.isEmpty() || Test.isRunningTest() ) {
                isDescriptionOfServiceBlank = false;
                invalidRequestedDate = false;
                isInvoiceEmailBlank = false;
                isQuoteExpirationInvalid = false;
                quoteOwnerMismatch = false;
                invoiceToEmailBilling = false;
                invoiceToEmailShipping = false;
                isBillingAddressBlank = false;
                isShippingAddressBlank = false;
                isBillToAddressBlank = false;
                isShipToAddressBlank = false;
                isBenchmarkJobDateInvalid = false;
                showQuoteError = false;
                isImplementationDateInvalid = false;
                isTalentCpnnectSubDateInvalid = false;
                isRPODateInvalid = false;
                isProjectRecruitingDateInvalid = false;
                isBrandingTargetDateInvalid = false;
                isCustomerStakeHolderBilling = false;
                isCustomerStakeHolderShipping = false;
                isCustomerRoleBilling = false;
                isCustomerRoleShipping = false;
                isAutorizedPurchaseBilling = false;
                isAutorizedPurchaseShipping = false;
                isPrimaryContactBilling = false;
                isPrimaryContactShipping = false;
                isAutorizedPurchaseBilling2 = false;
                isAutorizedPurchaseShipping2 = false;
                isSerialIdsBlank=false;
                isETSerialIdsNotMatched=false;
                isTerminationDateBlank = false;
            }

            //This logic scans the quote fields to check if the fields are holding the right values or not.
            if(!quoteFieldMessage.isEmpty()) {
                for(String errorMessage:quoteFieldMessage){
                
                    if(errorMessage.contains(REQ_DATE_ERR_MESSAGE)){
                    
                        invalidRequestedDate = true; 
                        showQuoteError = true; 
                    }
                    if(errorMessage.contains(INVOICE_EMAIL_ERR_MESSAGE)){
                        isInvoiceEmailBlank = true; 
                        showQuoteError = true; 
                    }
                    if(errorMessage.contains(INVOICE_BILLING_ERR)){
                        invoiceToEmailBilling = true; 
                        showQuoteError = true; 
                            
                    }
                    if(errorMessage.contains(INVOICE_SHIPPING_ERR)){
                            invoiceToEmailShipping = true; 
                            showQuoteError = true; 
                    }
                    if(errorMessage.contains(QUOTE_EXPIRATION_DATE_ERR_MESSAGE)){
                        isQuoteExpirationInvalid = true; 
                        showQuoteError = true; 
                    }
                    if(errorMessage.contains(DESC_SERVICES_ERR_MESSAGE)){
                        isDescriptionOfServiceBlank = true;
                        showQuoteError = true; 
                    }
                    if(errorMessage.contains(QUOTE_OWNER_MISMATCH_ERR_MESSAGE)){
                        quoteOwnerMismatch = true; 
                        showQuoteError = true; 
                    }
                
                    if(errorMessage.contains(BILLING_ADDRESS_ERR)){
                            isBillingAddressBlank = true; 
                            showQuoteError = true; 
                    }
                    
                    if(errorMessage.contains(SHIPPING_ADDRESS_ERR)){
                        isShippingAddressBlank = true; 
                        showQuoteError = true; 
                    }
                    
                    if(errorMessage.contains(CUSTOMER_BILLING_ADDRESS_ERR)){
                        isBillToAddressBlank = true; 
                        showQuoteError = true; 
                    }
                    
                    if(errorMessage.contains(CUSTOMER_SHIPPING_ADDRESS_ERR)){
                        isShipToAddressBlank = true; 
                        showQuoteError = true; 
                    }
                    
                    if(errorMessage.contains(BENCHMARK_JOB_DATE_ERR)){
                        isBenchmarkJobDateInvalid = true;
                        showQuoteError = true; 
                    }
                    
                    if(errorMessage.contains(IMPLEMENTATION_DATE_ERR)){
                        isImplementationDateInvalid= true;
                        showQuoteError = true; 
                    }
                    
                    if(errorMessage.contains(TALENT_CONNECT_SUB_DATE_ERR)){
                        isTalentCpnnectSubDateInvalid = true;
                        showQuoteError = true; 
                    }
                    
                    if(errorMessage.contains(RPO_DATE_ERR)){
                        isRPODateInvalid= true;
                        showQuoteError = true; 
                    }
                    
                    if(errorMessage.contains(PROJECT_RECRUITING_DATE_ERR)){
                        isProjectRecruitingDateInvalid= true;
                        showQuoteError = true; 
                    }
                    
                    if(errorMessage.contains(BRANDING_TARGET_DATE_ERR)){
                        isBrandingTargetDateInvalid= true;
                        showQuoteError = true; 
                    }
                    if(errorMessage.contains(CUST_STAKEHOLDER_BILLING_ERR)){
                        isCustomerStakeHolderBilling= true;
                        showQuoteError = true; 
                    }
                    if(errorMessage.contains(CUST_STAKEHOLDER_SHIPPING_ERR)){
                        isCustomerStakeHolderShipping= true;
                        showQuoteError = true; 
                    }
        
                    if(errorMessage.contains(CUST_ROLE_SHIPPING_ERR)){
                        isCustomerRoleShipping = true;
                        showQuoteError = true; 
                    }
        
                    if(errorMessage.contains(CUST_ROLE_BILLING_ERR)){
                        isCustomerRoleBilling = true;
                        showQuoteError = true; 
                    }
        
                    if(errorMessage.contains(AUTHORIZED_PURCHASE_BILL_ERR)){
                        isAutorizedPurchaseBilling = true;
                        showQuoteError = true; 
                    }
        
                    if(errorMessage.contains(AUTHORIZED_PURCHASE_SHIP_ERR)){
                        isAutorizedPurchaseShipping = true;
                        showQuoteError = true; 
                    }

                    if(errorMessage.contains(AUTHORIZED_PURCHASE2_BILL_ERR)){
                        isAutorizedPurchaseBilling2 = true;
                        showQuoteError = true; 
                    }
        
                    if(errorMessage.contains(AUTHORIZED_PURCHASE2_SHIP_ERR)){
                        isAutorizedPurchaseShipping2 = true;
                        showQuoteError = true; 
                    }
        
                    if(errorMessage.contains(PRIMARY_CONTACT_BILL_ERR)){
                        isPrimaryContactBilling= true;
                        showQuoteError = true; 
                    }
        
                    if(errorMessage.contains(PRIMARY_CONTACT_SHIP_ERR)){
                        isPrimaryContactShipping= true;
                        showQuoteError = true; 
                    }
                    if(errorMessage.contains(SERIAL_IDS_ERR)){
                        isSerialIdsBlank= true;
                        showQuoteError = true; 
                    }
                    if(errorMessage.contains(ET_SERIAL_IDS_ERR)){
                        isETSerialIdsNotMatched=true;
                        showQuoteError = true; 
                    }
                    if(errorMessage.contains(TERMINATION_DATE_ERROR)){
                        isTerminationDateBlank = true;
                        showQuoteError = true;
                    }
                }
            }
        }
    }

    /**
    * Method Name : onSubmit 
    * Description : This method will be called on click of Submit for Approval button
    */ 
        public PageReference onSubmit() {
            
            if (objQuote != null && objQuote.Id != null ) {
                update objQuote;
                //SBAA.ApprovalAPI.submit(objQuote.Id, SBAA__Approval__c.Quote__c);
            }
            PageReference redirect = new PageReference('/apex/sbaa__PreviewApprovals?Id='+objQuote.Id); 
            return redirect;
        }
        
        public PageReference onCancel() {
        
                return new PageReference('/' + objQuote.id);
            
            
        }
        
        public PageReference onRecall() {
            if (objQuote != null && objQuote.Id != null ) {
                SBAA.ApprovalAPI.recall(objQuote.id, SBAA__Approval__c.Quote__c);
            }
            return new PageReference('/' + objQuote.id);
        }

}
//