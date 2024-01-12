/* **************************************************************************************************   
Component Name :  NSP_QuoteApprovalPreValidation class
Version              :  1.0                                                                          
Created Date         :  July 2021                                                             
Function             :  This class validates the quotes against multiple business rules checks before submitting for approval.
					 :  Includes all Notes field validations   	
Story                :  STY-00450                                                                           
Modification Log     :                                                                               
*	Utpal           July 2021          First Iteration
*
***************************************************************************************************
*/

public class NSP_QuoteApprovalPreValidation {
    // test w/ QuoteExtControllerTests (80%)

    //constructor
    private NSP_QuoteApprovalPreValidation(){}
    
    //Static strings for storing error messages from labels.
    Static final String IRSO_ONDEMAND='IRSOOnDemand';	
    Static final String ERR_MESSAGE=System.Label.NSP_QuoteApprovalPreValidationMessage;
    Static final String NO_PRODUCTS_ERR_MESSAGE=System.Label.NSP_No_Products_Added_Error;
    Static final String INVALID_NOTES_ERR_MSG = System.Label.NSP_Invalid_Notes_Error;
    Static final String REQ_DATE_ERR_MESSAGE=System.Label.NSP_RequestFirstCheckDate;
    Static final String DESC_SERVICES_ERR_MESSAGE=System.Label.NSP_Description_Of_Service;
    Static final String INVOICE_EMAIL_ERR_MESSAGE=System.Label.NSP_InvoiceToEmailonQuote;
    Static final String QUOTE_EXPIRATION_DATE_ERR_MESSAGE=System.Label.NSP_QuoteExpirationDate;
    Static final String QUOTE_OWNER_MISMATCH_ERR_MESSAGE=System.Label.NSP_Quote_Owner_Mismatch_Message;
	Static final String INVOICE_BILLING_ERR=System.Label.NSP_InvoiceEmailBilling;
    Static final String INVOICE_SHIPPING_ERR=System.Label.NSP_InvoiceEmailShipping;
	
	Static final String BILLING_ADDRESS_ERR=System.Label.NSP_QuoteBillingAddressValidationMessage;
	Static final String SHIPPING_ADDRESS_ERR=System.Label.NSP_QuoteShippingAddressValidationMessage;
	Static final String CUSTOMER_BILLING_ADDRESS_ERR=System.Label.NSP_QuoteCustomerBillingAddressValidationMessage;
	Static final String CUSTOMER_SHIPPING_ADDRESS_ERR=System.Label.NSP_QuoteCustomerShippingAddressValidationMessage;
    Static final String BENCHMARK_JOB_DATE_ERR=System.Label.NSP_Benchmark_Date_Validation;
    Static final String SERIAL_IDS_ERR=System.Label.NSP_SerialId_Validation;
    Static final String ET_SERIAL_IDS_ERR=System.Label.NSP_ET_Serial_Id_Validation;
    //Map to prepare kay value pair of notes field for each corresponsing product.
    Static final Map<String,String> productFieldMap=new Map<String,String>{
         'NSP_OnDemand_Notes__c' => 'IRSOOnDemand',
         'NSP_Personality_Assessment_Notes__c' => 'IRSOPALicense',
         'NSP_Skills_Based_Assessment_Notes__c' => 'IRSOSBALicense',
         'NSP_Sourcing_Notes__c' => 'IRSOSourcing',
          //  'ITC%' => 'NSP_Talent_Connect_Notes__c',
         'NSP_Employment_Screening_Notes__c' => 'IRSOEmpScreen',
         'NSP_Employment_Branding_Notes__c' => 'IRSOEmpBranding',
         'NSP_BehavioralBasedInterviewTrainingNote__c'=>'IRSOBehavioralTraining'
        };
            
/**
* Method for querying all quoteline assocaited to a quote ad scanning
* for Retirement services product and then validatethat the Notes are filled before 
* submitting for approval
* @param  Quote Id  
*/                                                                          
            
        public static String validateRetirementServiceQuote(Id QuoteId)  {
            SBQQ__Quote__c quoteRecord=[SELECT Id,Name,SBQQ__Account__c,SBQQ__Opportunity2__c,SBQQ__Primary__c,
                                        SBQQ__StartDate__c,SBQQ__EndDate__c,SBQQ__ExpirationDate__c,NSP_At_Hire_Payment__c,	
                                        NSP_UpFront_Payment__c,NSP_Retention_Payment__c ,NSP_Product_Type__c,
                                        NSP_OnDemand_Notes__c,NSP_Personality_Assessment_Notes__c,NSP_Skills_Based_Assessment_Notes__c,
                                        NSP_Sourcing_Notes__c,NSP_Talent_Connect_Notes__c,NSP_Employment_Screening_Notes__c,
                                        NSP_Employment_Branding_Notes__c,NSP_BehavioralBasedInterviewTrainingNote__c FROM SBQQ__Quote__c WHERE Id=:QuoteId ];
            //Query to collect field values from quote and quote lines
            
            List<SBQQ__QuoteLine__c> quoteLineList=[Select SBQQ__Discount__c,SBQQ__ProductCode__c,SBQQ__Quote__c,SBQQ__Quantity__c,NSP_Parent_Product_Code__c, NSP_Positions__c
                                                    FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:QuoteId];
            //variable declarations
            Map<String,Boolean> isProductPresentMap = new Map<String,Boolean>();
            Boolean isonDemandNotesRequired = false;
            Boolean isProductsMissing = false; //Modified as Part of code fix
            String errMsg = null;  
            //checking if products are added to the quote
            if(quoteLineList.size()>0) {
            List<SBQQ__QuoteLine__c> recrutingBaseProducts = new List<SBQQ__QuoteLine__c>();    
                for(SBQQ__QuoteLine__c qli : quoteLineList) {
                    if(qli.NSP_Parent_Product_Code__c == NSP_CPQConstants.RECRUITING_BUNDLE || qli.NSP_Parent_Product_Code__c == IRSO_ONDEMAND ){
                        recrutingBaseProducts.add(qli); // adding recruiting products to list.
                    }
                }
            if(recrutingBaseProducts.size()>0) {
              
                for(SBQQ__QuoteLine__c ql:recrutingBaseProducts){
                // Criteria to check if OnDemand is added with positions and discounts and on demand notes are not populated.
                if(isonDemandNotesRequired==false && ql.SBQQ__ProductCode__c.contains(IRSO_ONDEMAND) && (ql.NSP_Positions__c > 0 || ql.SBQQ__Discount__c >0 ) && quoteRecord.NSP_OnDemand_Notes__c == null) {
                    isonDemandNotesRequired = true;
                    errMsg = ERR_MESSAGE;
                    //break;
                }
                for( String productPattern : productFieldMap.values()) {
                    if(ql.SBQQ__ProductCode__c.contains(productPattern)) {
                        isProductPresentMap.put(productPattern,true);  // preparing a map of products that needs corresponsing notes fields to be populated
                    }
                }
                
            }
            
                //Criteria to check if notes are populated but product is missing
            if(!isProductsMissing && isProductPresentMap.size()>0) {
                for(String notesField : productFieldMap.keySet()){
                    String notes=(String)quoteRecord.get(notesField);
                    if(notes != null) {
                        if(!isProductPresentMap.containsKey(productFieldMap.get(notesField))){  //criteria identifying missing product
                            isProductsMissing = true; 
                            if(String.isEmpty(errMsg)) {
                            errMsg = INVALID_NOTES_ERR_MSG; 
                            }
                            else {
                            errMsg+='\n'+INVALID_NOTES_ERR_MSG;
                            }
                            break;
                        }
                    }    
                }
            } 
        }  
    }
    else {
        errMsg = NO_PRODUCTS_ERR_MESSAGE; // error message for no quote lines
    }

            return errMsg;
        }    
    
/**
* Method for querying quote records on when Quote status in New or Amendement  
* and if WX or WA or WOSS products are added to quote and check if Requested First check has valid value before 
* submitting for approval
* @param  Quote Id  
*/                                                                          
    
    public static List<String> validateRequestedFirstCheck(Id QuoteId) {
        List<String>  errorMessageList = new List<String>();
        Set<String> profilesToSkip = new Set<String>(System.label.NSP_CPQ_Profiles_Skip_Validation.split(','));
        Set<String> groupname = new Set<String>(System.label.NSP_ApprovalSubmitterGroups.split(','));
        List<String>  groupList = new List<String>();
		String invoiceToEmail = null;
        String descriptionOfService = null;
        String customerStakeHolder = null;
        String customerRole = null;
        String authorizedPurchaser = null;
        String primaryContact = null;
        String serialIds=null;
        //quering user groups
        for(groupMember  objmember : [Select id,UserOrGroupId,GroupId,Group.DeveloperName,Group.Name FROM groupMember 
        WHERE UserOrGroupId =: userinfo.getUserId() AND Group.DeveloperName IN : groupname  ]) {
             groupList.add(objmember.Group.Name);
         } 
        //current user profile info fetch
        Id userprofileId=userinfo.getProfileId();
        String userprofileName=[SELECT Id,Name FROM Profile WHERE Id=:userprofileId].Name;
        
        List<SBQQ__Quote__c> quoteRecord=[SELECT Id,Name,NSP_Requested_First_Check_Date__c,NSP_Has_WA_product__c,NSP_Has_WX_product__c,NSP_Has_WOSS_product__c,SBQQ__ExpirationDate__c,SBQQ__Type__c,NSP_Submitted_User_Role_L2__c,
                                          SBQQ__Account__r.Id,NSP_Invoice_To_Email__r.Id,NSP_Billing_Account__r.Id,NSP_DO_Signed_By_Billing_Account__c,
										  SBQQ__BillingStreet__c,SBQQ__BillingState__c,SBQQ__BillingCity__c,SBQQ__BillingPostalCode__c,SBQQ__BillingCountry__c,
										  SBQQ__ShippingStreet__c,SBQQ__ShippingState__c,SBQQ__ShippingCity__c,SBQQ__ShippingPostalCode__c,SBQQ__ShippingCountry__c,
										  NSP_Bill_To_Street__c,NSP_Bill_To_State__c,NSP_Bill_To_City__c,NSP_Bill_To_Postal_Code__c,NSP_Bill_To_Country__c,
                                          NSP_Ship_To_Street__c,NSP_Ship_To_State__c,NSP_Ship_To_City__c,NSP_Ship_To_Postal_Code__c,NSP_Ship_To_Country__c,
                                          NSP_Benchmark_Job_End_Date__c,NSP_Benchmark_Job_Start_Date__c,NSP_Implementation_Start_Date__c,NSP_Talent_Connect_Subscription_End_Date__c,NSP_Talent_Connect_Subscription_Date__c,
                                          NSP_RPO_End_Date__c,NSP_RPO_Start_Date__c,NSP_ProjRec_Start_Date__c,NSP_ProjRec_End_Date__c,NSP_Target_Date__c,NSP_Customer_Stakeholder__c,NSP_Authorized_Purchaser_1__c,
                                          NSP_Authorized_Purchaser_2__c,NSP_Customer_Role__c,SBQQ__PrimaryContact__c,NSP_TerminationDate__c,NSP_TransactionType__c FROM SBQQ__Quote__c WHERE Id=:QuoteId];

        
        for(SBQQ__Quote__c quoteRec: quoteRecord) {
            //sequential execution of validations conditions for that specific quote
            if(quoteRec.NSP_Invoice_To_Email__c == null && quoteRec.SBQQ__Type__c!=NSP_CPQConstants.QUOTE_TYPE_TERMINATION){
                errorMessageList.add(INVOICE_EMAIL_ERR_MESSAGE);
            }   
            if((quoteRec.SBQQ__ExpirationDate__c == null)  || (quoteRec.SBQQ__ExpirationDate__c <= system.today())) {
                errorMessageList.add(QUOTE_EXPIRATION_DATE_ERR_MESSAGE);
            }    
            /* check for quote owner mismatch */ 
            if(!profilesToSkip.contains(userprofileName)) {
            if(quoteRec.NSP_Submitted_User_Role_L2__c != null && ((groupList.isEmpty()) || (!groupList.contains(quoteRec.NSP_Submitted_User_Role_L2__c)))) {
                errorMessageList.add(QUOTE_OWNER_MISMATCH_ERR_MESSAGE);
            } 
            }
            //Validate Invoice To Email
            if(quoteRec.NSP_Invoice_To_Email__c != null){
                if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == true){
                    invoiceToEmail = validateContacts(quoteRec.NSP_Invoice_To_Email__c,quoteRec.NSP_Billing_Account__c,QuoteExtController.INVOICE_BILLING_ERR,true);
                }
                else if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == false){
                    invoiceToEmail = validateContacts(quoteRec.NSP_Invoice_To_Email__c,quoteRec.SBQQ__Account__c,QuoteExtController.INVOICE_SHIPPING_ERR,true);
                }
                if(invoiceToEmail != null){
                    errorMessageList.add(invoiceToEmail);
                }
            }
              //Validate Customer Stake Holder
            if(quoteRec.NSP_Customer_Stakeholder__c != null){
                if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == true){
                 customerStakeHolder =  validateContacts(quoteRec.NSP_Customer_Stakeholder__c,quoteRec.NSP_Billing_Account__c,QuoteExtController.CUST_STAKEHOLDER_BILLING_ERR,false);
                }
                else if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == false){
                    customerStakeHolder = validateContacts(quoteRec.NSP_Customer_Stakeholder__c,quoteRec.SBQQ__Account__c,QuoteExtController.CUST_STAKEHOLDER_SHIPPING_ERR,false);
                }
                if(customerStakeHolder != null){
                    errorMessageList.add(customerStakeHolder);
               }
            }
            //Validate Authorized Purchaser 1
            if(quoteRec.NSP_Authorized_Purchaser_1__c != null){
                if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == true){
                    authorizedPurchaser = validateContacts(quoteRec.NSP_Authorized_Purchaser_1__c,quoteRec.NSP_Billing_Account__c,QuoteExtController.AUTHORIZED_PURCHASE_BILL_ERR,false);
                }
                else if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == false){
                    authorizedPurchaser = validateContacts(quoteRec.NSP_Authorized_Purchaser_1__c,quoteRec.SBQQ__Account__c,QuoteExtController.AUTHORIZED_PURCHASE_SHIP_ERR,false);
                }
                if(authorizedPurchaser != null){
                    errorMessageList.add(authorizedPurchaser);
                }
            }
            //Validate Authorized Purchaser 2
            if(quoteRec.NSP_Authorized_Purchaser_2__c != null){
                authorizedPurchaser = null;
                if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == true){
                    authorizedPurchaser = validateContacts(quoteRec.NSP_Authorized_Purchaser_2__c,quoteRec.NSP_Billing_Account__c,QuoteExtController.AUTHORIZED_PURCHASE2_BILL_ERR,false);
                }
                else if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == false){
                    authorizedPurchaser = validateContacts(quoteRec.NSP_Authorized_Purchaser_2__c,quoteRec.SBQQ__Account__c,QuoteExtController.AUTHORIZED_PURCHASE2_SHIP_ERR,false);
                }
                if(authorizedPurchaser != null){
                    errorMessageList.add(authorizedPurchaser);
                }
            }
            //Validate Customer Role
            if(quoteRec.NSP_Customer_Role__c != null){
                if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == true){
                    customerRole = validateContacts(quoteRec.NSP_Customer_Role__c,quoteRec.NSP_Billing_Account__c,QuoteExtController.CUST_ROLE_BILLING_ERR,false);
                }
                else if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == false){
                    customerRole = validateContacts(quoteRec.NSP_Customer_Role__c,quoteRec.SBQQ__Account__c,QuoteExtController.CUST_ROLE_SHIPPING_ERR,false);
                }
                if(customerRole != null){
                    errorMessageList.add(customerRole);
                }
            }
            //Validate Primary Contact
            if(quoteRec.SBQQ__PrimaryContact__c != null){
                if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == true){
                    primaryContact = validateContacts(quoteRec.SBQQ__PrimaryContact__c,quoteRec.NSP_Billing_Account__c,QuoteExtController.PRIMARY_CONTACT_BILL_ERR,false);
                }
                else if(quoteRec.NSP_DO_Signed_By_Billing_Account__c == false){
                    primaryContact = validateContacts(quoteRec.SBQQ__PrimaryContact__c,quoteRec.SBQQ__Account__c,QuoteExtController.PRIMARY_CONTACT_SHIP_ERR,false);
                }
                if(primaryContact != null){
                    errorMessageList.add(primaryContact);
                }
            }
			
			/* check for billing address validation*/
			if(String.isBlank(quoteRec.SBQQ__BillingStreet__c) ||String.isBlank(quoteRec.SBQQ__BillingState__c) ||String.isBlank(quoteRec.SBQQ__BillingCity__c) ||String.isBlank(quoteRec.SBQQ__BillingPostalCode__c) || String.isBlank(quoteRec.SBQQ__BillingCountry__c) ){
				errorMessageList.add(BILLING_ADDRESS_ERR);
			}
			
			/* check for shipping address validation*/
			if(String.isBlank(quoteRec.SBQQ__ShippingStreet__c) ||String.isBlank(quoteRec.SBQQ__ShippingState__c) ||String.isBlank(quoteRec.SBQQ__ShippingCity__c) ||String.isBlank(quoteRec.SBQQ__ShippingPostalCode__c) || String.isBlank(quoteRec.SBQQ__ShippingCountry__c) ){
				errorMessageList.add(SHIPPING_ADDRESS_ERR);
			}
			
			/* check for Customer billing address validation*/
			if(String.isBlank(quoteRec.NSP_Bill_To_Street__c) ||String.isBlank(quoteRec.NSP_Bill_To_State__c) ||String.isBlank(quoteRec.NSP_Bill_To_City__c) ||String.isBlank(quoteRec.NSP_Bill_To_Postal_Code__c) || String.isBlank(quoteRec.NSP_Bill_To_Country__c) ){
				errorMessageList.add(CUSTOMER_BILLING_ADDRESS_ERR);
			}
			
			/* check for billing address validation*/
			if(String.isBlank(quoteRec.NSP_Ship_To_Street__c) ||String.isBlank(quoteRec.NSP_Ship_To_State__c) ||String.isBlank(quoteRec.NSP_Ship_To_City__c) ||String.isBlank(quoteRec.NSP_Ship_To_Postal_Code__c) || String.isBlank(quoteRec.NSP_Ship_To_Country__c) ){
				errorMessageList.add(CUSTOMER_SHIPPING_ADDRESS_ERR);
			}
			
            if(quoteRec.SBQQ__Type__c == NSP_CPQConstants.QUOTE_TYPE_NEW){
                /* Validate NSP_Benchmark_Job_End_Date__c > NSP_Benchmark_Job_Start_Date__c*/
                if(quoteRec.NSP_Benchmark_Job_End_Date__c != null &&  quoteRec.NSP_Benchmark_Job_Start_Date__c != null 
                && quoteRec.NSP_Benchmark_Job_End_Date__c < quoteRec.NSP_Benchmark_Job_Start_Date__c){
                    errorMessageList.add(BENCHMARK_JOB_DATE_ERR);
                }
                // validate NSP_Implementation_Start_Date__c
                if(quoteRec.NSP_Implementation_Start_Date__c != null && quoteRec.NSP_Implementation_Start_Date__c < system.today()){
                   errorMessageList.add(QuoteExtController.IMPLEMENTATION_DATE_ERR);
                }
                
                // validate talent connect subscription dates
                if(quoteRec.NSP_Talent_Connect_Subscription_End_Date__c != null && quoteRec.NSP_Talent_Connect_Subscription_Date__c != null && 
                (quoteRec.NSP_Talent_Connect_Subscription_Date__c < system.today() || quoteRec.NSP_Talent_Connect_Subscription_End_Date__c < quoteRec.NSP_Talent_Connect_Subscription_Date__c)){
                    errorMessageList.add(QuoteExtController.TALENT_CONNECT_SUB_DATE_ERR);      
                }
                // validate RPO dates
                if(quoteRec.NSP_RPO_End_Date__c != null && quoteRec.NSP_RPO_Start_Date__c != null && 
                (quoteRec.NSP_RPO_Start_Date__c < system.today() || quoteRec.NSP_RPO_End_Date__c < quoteRec.NSP_RPO_Start_Date__c)){
                    errorMessageList.add(QuoteExtController.RPO_DATE_ERR);      
                }
                // Project recruiting dates
                if(quoteRec.NSP_ProjRec_Start_Date__c != null && quoteRec.NSP_ProjRec_End_Date__c != null && 
                (quoteRec.NSP_ProjRec_Start_Date__c < system.today() || quoteRec.NSP_ProjRec_End_Date__c < quoteRec.NSP_ProjRec_Start_Date__c)){
                    errorMessageList.add(QuoteExtController.PROJECT_RECRUITING_DATE_ERR);      
                }
                // branding target dates
                if(quoteRec.NSP_Target_Date__c != null && quoteRec.NSP_Target_Date__c < system.today() ){
                    errorMessageList.add(QuoteExtController.BRANDING_TARGET_DATE_ERR);      
                }
            }
            //validate termination date
            if(quoteRec.NSP_TransactionType__c == NSP_CPQConstants.QUOTE_TYPE_TERMINATION && quoteRec.NSP_TerminationDate__c == null){
                errorMessageList.add(QuoteExtController.TERMINATION_DATE_ERROR);
            }
            
        }						   
        descriptionOfService = 	validateDescriptionOfServices(QuoteId);
        serialIds=validateSerialIds(QuoteId);
        if(descriptionOfService!= null)	{
            errorMessageList.add(DESC_SERVICES_ERR_MESSAGE);
        }
        if(serialIds!= null)	{
            errorMessageList.add(serialIds);
        }
        return errorMessageList;
        
    }
    
    /**
* Method for querying all quoteline assocaited to a quote to check 
* if Description of Service is populated for supplemental delivery orders 
* submitting for approval
* @param  Quote Id  
*/                                                                          
    
    public static String validateDescriptionOfServices(Id QuoteId) {
        List<SBQQ__QuoteLine__c> quoteLineList=[Select 	Id,NSP_Applicable_Transaction_Type__c,SBQQ__ProductCode__c,SBQQ__Quote__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.Type,SBQQ__PriorQuantity__c,SBQQ__Quote__r.NSP_Description_Of_Services__c
                                                FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:QuoteId AND (SBQQ__Quote__r.SBQQ__Type__c = :NSP_CPQConstants.SUPPLEMENTAL) AND (NSP_Applicable_Transaction_Type__c = :NSP_CPQConstants.APPLICABLE_TRANSACTION_TYPE)];
        
        for(SBQQ__QuoteLine__c quoteLineRec: quoteLineList)	 {
            if(quoteLineRec.SBQQ__Quote__r.NSP_Description_Of_Services__c == null) {
                return DESC_SERVICES_ERR_MESSAGE;
            }
        }						   
        return null;
        
    }
	
/**
* Method for querying all quoteline assocaited to a quote to check 
* billing account address,shipping account address
* submitting for approval
* @param  ContactId Id ,AccountId Id,errMessage String
*/                                                                          
    
public static String validateContacts(Id cId,Id accountId,String errMessage,Boolean isValidateEmail){
    Set<String> contactSet = new Set<String>(); 
    List<Contact> contactList=[SELECT Id, Name FROM Contact WHERE Id IN (SELECT contactId FROM AccountContactRelation WHERE AccountId = :accountId)];
        
        for(Contact contactObj :contactList){ 
            contactSet.add(contactObj.Id); 
        } 
        if(!contactSet.contains(cId)) {
            return errMessage;
        }
        if(isValidateEmail == true) {
          Contact contactObj=[SELECT Email FROM Contact WHERE Id =:cId];
            if(contactObj.Email == null){ 
                return INVOICE_EMAIL_ERR_MESSAGE;
            }
       }
        return null;
    
}  
public static string validateSerialIds(Id QuoteId){
    List<SBQQ__QuoteLine__c> quoteLineList=[SELECT Id,NSP_SerialId_Validation__c,NSP_ET_Checked_Serial_Ids__c,NSP_Serial_Ids__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c=:QuoteId];
    for(SBQQ__QuoteLine__c quoteLineRec: quoteLineList)	 {
        if(quoteLineRec.NSP_SerialId_Validation__c == true) {
            return SERIAL_IDS_ERR;
        }
        if(quoteLineRec.NSP_Serial_Ids__c!=null && quoteLineRec.NSP_ET_Checked_Serial_Ids__c!=null){
            Map<String,String> serialIdsMap= new Map<String,String>();
            Map<String,String> etserialIdsMap= new Map<String,String>();
            for(String serialId:quoteLineRec.NSP_Serial_Ids__c.split(',')){
                serialIdsMap.put(serialId,serialId);
            }
            for(String etserialId:quoteLineRec.NSP_ET_Checked_Serial_Ids__c.split(',')){
                etserialIdsMap.put(etserialId,etserialId);
            }
            //iterate over Serial Ids and check it has all the Early Termination Checked Serial Ids, If not throw validation error
            for(String etSerialId:etserialIdsMap.KeySet()){
                if(!serialIdsMap.containsKey(etSerialId)){
                    return ET_SERIAL_IDS_ERR;
                }
            }
        }
    }						           
    return null;
}
    
}