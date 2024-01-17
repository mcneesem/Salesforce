/**
* Represents the EmailMessage trigger helper which handles all the logic.
*/
public with sharing class NSP_EmailMessageTriggerHelper {
    // test w/ NSP_EmailMessageTriggerHelperTest (92%)

    public static boolean isFirst = false;
    public static final String CLASS_NAME = 'NSP_EmailMessageTriggerHelper';
    public static List<String> ContactCenterEmailAddresses = System.Label.NSP_Contact_Center_Email_Addresses.split(',');
    public static final String QUEUE = 'Queue';
    public static final String CONTACTCENTER = 'NSP_ContactCenter';
    public static final String REOPENED = 'ReOpened';
    public static final String CLOSED = 'Closed';
    public static final String UNASSIGNED = 'Unassigned';
    public static final String SATURDAY = 'Saturday';
    public static final String SUNDAY = 'Sunday';
    public static final String OPEN = 'Open';
    
    
    
        
    /* Description: This method will be called after insert of EmailMessage
	Date       : 17/11/2021 */
    public void afterInsertionEmailMessage(List<EmailMessage> newList, Map<Id, EmailMessage> newMap){
        Set<Id> setOfCaseId = new Set<Id> ();
        Set<Id> employmentScreeningcaseIdSet = new Set<Id>();
        List<Case> caseToUpdate = new List<Case> ();
        Map<Id, EmailMessage> healthWelfareInternalExternalCaseIdFromAddMap = new Map<Id, EmailMessage>();
        for(EmailMessage eMessage : newList){
            if ( ( eMessage.ParentId != null ) && incomingEmailCheck( eMessage ) ) {
                setOfCaseId.add( eMessage.ParentId );
            }
            //Added as a part of STY-04132 
            if(!setOfCaseId.isEmpty()){
              for(Id caseID:setOfCaseId){
                 Case caseRecord = new Case();
                 caseRecord.ID =caseID;
                 caseRecord.NSP_Case_Created_From_Email_To_Case__c  = true;
                 caseToUpdate.add(caseRecord);
              }
            }
                        
            //As a part of STY-03671        
            if(eMessage.ToAddress == System.Label.NSP_Customer_Service_Email ||
               eMessage.ToAddress == System.Label.NSP_Les_Drug_Screening_Email){
                   employmentScreeningcaseIdSet.add(eMessage.ParentId);
               }
            
            //As a part of STY-03531
            if(eMessage.ToAddress == System.Label.NSP_Health_Welfare_Section_125){
                healthWelfareInternalExternalCaseIdFromAddMap.put(eMessage.ParentId, eMessage);
            }
               
        }
        
        if(!setOfCaseId.isEmpty()){
            NSP_WebCaseAssignment.webCaseAssign(setOfCaseId, newList);
            reOpenOrMarkResponseAfterCloseTrue(setOfCaseId, newList);
        }
        
        //As a part of STY-03671
        if(!employmentScreeningcaseIdSet.isEmpty()){
            updateConfidentialCheckBoxForEmpScreening(employmentScreeningcaseIdSet);
        }
        
        //As a part of STY-03531
        if(!healthWelfareInternalExternalCaseIdFromAddMap.isEmpty()){
            sendEmailToHealthWelfareInternalExternal(healthWelfareInternalExternalCaseIdFromAddMap);
        }
        
            //Added as a part of STY-04132 
            if(!caseToUpdate.isEmpty()){
               List<Database.SaveResult> results1 =  Database.update( caseToUpdate , false );
                NSP_ErrorLogHandler.logSaveResultsException('NSP_EmailMessageTriggerHelper', 'afterInsertionEmailMessage', results1 );
            }
        
    }
    
    /***********************************************************************************************
    * MethodName	: beforeInsertionEmailMessage
    * Description	: This method will be called before insert of EmailMessage
    * Story 		: STY-03643
    * Params		: List<EmailMessage> listOfEmailMessage
    * ********************************************************************************************/
    public void beforeInsertionEmailMessage(List<EmailMessage> newList){
        restrictEmailFromRestrictedSenders(newList); 
    }
    
    /***********************************************************************************************
    * Description: This method will reOpen an existing case if days between closing of case (BPS)
    and EmailMessage date is less than 90 days,else, it will mark
    Response After Close to True
    * Date       : 17/11/2021 
    * Modified Date : 20/09/2021
    * Update- This Method will also will reOpen an existing case if days between closing of case (PEO)
    and EmailMessage date is within 5 days,else, it will create a new Case
    ***********************************************************************************************/
    public static void reOpenOrMarkResponseAfterCloseTrue(Set<Id> caseIds, List<EmailMessage> listOfEmailMessage){
        List<Case> listOfCase = new List<Case> ();
        Map<Id, Case> mapOfCaseIdAndCase = new Map<Id, Case> ();
        
        Id caseBPSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BPS').getRecordTypeId();
        Id casePEORecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
        
        ID contactCenterQueueId = ([SELECT ID FROM Group WHERE Type = :QUEUE AND DeveloperNAME = :CONTACTCENTER]).ID;
        List<Case> listOfCaseReopen = new List<Case> ();
        List<Case> insertedCaseList = new List<Case>();
        Map<Case,String> CaseToSubjectMap = new Map<Case,String>();
        Map<Case,EmailMessage> ParentCaseToEmailMessageMap = new Map<Case,EmailMessage>();
        
        for(Case caseRec : [SELECT Status, NSP_Response_After_Close__c, NSP_Case_Reopened_EmaiToCase__c, NSP_Case_Sub_Status__c, ClosedDate, NSP_Date_Closed__c, RecordTypeId, Origin, Priority, NSP_SubCategory__c, NSP_Category__c, ContactId, AccountId, AssetId, Subject 
                            FROM Case WHERE ID IN : caseIds]){
            if(!mapOfCaseIdAndCase.containsKey(caseRec.id)){
                mapOfCaseIdAndCase.put(caseRec.id, caseRec);
            }
        }
        
        for(EmailMessage eMessage : listOfEmailMessage){
            Integer daysBetween;
            Integer businessDaysBetween;
            List<String> ToAddressList = new List<String>(); 
            
            if(mapOfCaseIdAndCase.get(eMessage.ParentId).NSP_Date_Closed__c != null){
                Case getCase = mapOfCaseIdAndCase.get(eMessage.ParentId);
                Date caseClosedDate = mapOfCaseIdAndCase.get(eMessage.ParentId).NSP_Date_Closed__c;
                Datetime emailMessageDate = Datetime.newInstance(eMessage.MessageDate.year(), eMessage.MessageDate.month(), eMessage.MessageDate.day());
                
                daysBetween = caseClosedDate.daysBetween(Date.valueOf(emailMessageDate));
                
                if(mapOfCaseIdAndCase.get(eMessage.ParentId).RecordTypeId == caseBPSRecordTypeId && daysBetween <= 90){
                    getCase.Status = 'ReOpened';
                    getCase.NSP_Case_Reopened_EmaiToCase__c = true;
                    listOfCase.add(getCase);
                } else if(
                    	(mapOfCaseIdAndCase.get(eMessage.ParentId).RecordTypeId == casePEORecordTypeId) ||
                    	(mapOfCaseIdAndCase.get(eMessage.ParentId).RecordTypeId == caseBPSRecordTypeId && daysBetween > 90)){
                              getCase.NSP_Response_After_Close__c = true;
                              listOfCase.add(getCase);
                          }
            }
            ToAddressList = eMessage.ToAddress.split(';');
            if(mapOfCaseIdAndCase.get(eMessage.ParentId).ClosedDate != null && mapOfCaseIdAndCase.get(eMessage.ParentId).Status == 'Closed' && 
              mapOfCaseIdAndCase.get(eMessage.ParentId).RecordTypeId == casePEORecordTypeId && isContactCenterCase(ContactCenterEmailAddresses,ToAddressList)){
                Case getCase = mapOfCaseIdAndCase.get(eMessage.ParentId);
                Datetime caseClosedDate = mapOfCaseIdAndCase.get(eMessage.ParentId).ClosedDate;
                Datetime emailMessageDate = Datetime.newInstance(eMessage.MessageDate.year(), eMessage.MessageDate.month(), eMessage.MessageDate.day());
                
                businessDaysBetween = getNoOfBusinessDaysBetweenDates(caseClosedDate,emailMessageDate);
                if(businessDaysBetween <= 5){
                    getCase.Status = REOPENED;
                    getCase.NSP_Case_Sub_Status__c = UNASSIGNED;
                    getCase.OwnerId = contactCenterQueueId;
                    getCase.NSP_Response_After_Close__c = False;
                    listOfCaseReopen.add(getCase);
                }
                else if (businessDaysBetween > 5){
                    CaseToSubjectMap.put(getCase,eMessage.Subject);  
                    ParentCaseToEmailMessageMap.put(getCase,eMessage);
                }
            }
        }
        if(!listOfCaseReopen.isEmpty()){
            Database.update(listOfCaseReopen);
        }
        if(CaseToSubjectMap.size() > 0){
            insertedCaseList = createCaseFromEmail(CaseToSubjectMap,contactCenterQueueId);
        }
        
        if(!insertedCaseList.isEmpty()){
            updateRelatedCaseOnEmailMessage(ParentCaseToEmailMessageMap,insertedCaseList);
        }
        if(!listOfCase.isEmpty()){
            Database.update(listOfCase);
        }
    }
    
    /***********************************************************************************************
    * MethodName    : isContactCenterCase
    * Description   : Check if ToAddress has Contact Center Email
    * Story         : STY-04647
    * Params        : List<String> ContactCenterEmailAddresses, List<String> ToAddress
    * ********************************************************************************************/
    public static Boolean isContactCenterCase(List<String> ContactCenterEmailAddresses, List<String> ToAddress){
        Boolean isPresent;
        Integer count = 0;
        for(String str : ToAddress){
            if(ContactCenterEmailAddresses.contains(str)){
                count ++;
            }
        }
        if(count == 0){
            isPresent = False;
        }else {
            isPresent = True;
        }
        return isPresent;
    }
    
    /***********************************************************************************************
    * MethodName    : getNoOfBusinessDaysBetweenDates
    * Description   : Get number of business days between two dates
    * Story         : STY-04647
    * Params        : Date startDate, DateTime endDate
    * ********************************************************************************************/
    public static Integer getNoOfBusinessDaysBetweenDates(DateTime startDate, DateTime endDate){
        Integer workingDays = 0;  
         System.debug(' ** startDate' + startDate);
		 System.debug(' ** endDate' + endDate);
        for(Integer i=0; i <= Date.valueOf(startDate).daysBetween(Date.valueOf(endDate)); i++)  
        {  
            Date dt = Date.valueOf(startDate) + i;  
            DateTime currDate = DateTime.newInstance(dt.year(), dt.month(), dt.day());  
            String todayDay = currDate.format('EEEE');  
            if(todayDay != SATURDAY && todayDay != SUNDAY)  
                {  
                    System.debug('--todayDay '+todayDay);
                    workingDays = workingDays + 1;  
                }     
               
        }  
          system.debug('** workingDays' + workingDays);    
        return workingDays;
    }
    /***********************************************************************************************
    * MethodName    : createCaseFromEmail
    * Description   : method to Create case based on Parent Case
    * Story         : STY-04647
    * Params        : Map<Case,String> CaseToSubjectMap, ID contactCenterQueueId
    * ********************************************************************************************/
    public static List<Case> createCaseFromEmail(Map<Case,String> CaseToSubjectMap, ID contactCenterQueueId){
        List<Case> caseToInsert = new List<Case>();
        try{
            for(Case getCase : CaseToSubjectMap.keySet()){
                Case newCase = new Case();
                newCase.ParentId = getCase.Id;
                newCase.RecordTypeId = getCase.RecordTypeId;
                newCase.Status = OPEN;
                newCase.NSP_Case_Sub_Status__c = UNASSIGNED;
                newCase.OwnerId = contactCenterQueueId;
                newCase.AccountId = getCase.AccountId;
                newCase.AssetId = getCase.AssetId;
                newCase.ContactId = getCase.ContactId;
                newCase.NSP_Category__c = getCase.NSP_Category__c;
                newCase.NSP_SubCategory__c = getCase.NSP_SubCategory__c;
                newCase.Priority = getCase.Priority;
                newCase.Origin = getCase.Origin;
                newCase.Subject = CaseToSubjectMap.get(getCase);
                caseToInsert.add(newCase);
            }
            insert caseToInsert; 
       }catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException( CLASS_NAME, 'createCaseFromEmail', exc.getMessage());
        }
        return caseToInsert;
    }
    
    /***********************************************************************************************
    * MethodName    : updateRelatedCaseOnEmailMessage
    * Description   : method to clone Email Message and delete duplicate Email message
    * Story         : STY-04647
    * Params        : Map<Case,EmailMessage> ParentCaseToEmailMessageMap,List<Case> insertedCaseList
    * ********************************************************************************************/
    public static void updateRelatedCaseOnEmailMessage(Map<Case,EmailMessage> ParentCaseToEmailMessageMap,List<Case> insertedCaseList){
            //List to keep clone Email Messages
            List<EmailMessage> emailMessageClonedList = new List<EmailMessage>();
            //List to delete the cloned Email Message
            List<Id> emailMessageTobeDeleted = new List<Id>();
        try{
            
            for(EmailMessage emailMessage : ParentCaseToEmailMessageMap.Values()) {
                if(emailMessage.ParentId != Null){
                        emailMessageTobeDeleted.add(emailMessage.Id);
                        //Clonning the Email Message
                        EmailMessage emailMessageCloned = emailMessage.clone(false, true, false, false);
                        emailMessageClonedList.add(emailMessageCloned);
                }
            }
                
                //insert updated cases
                if(!emailMessageClonedList.isEmpty()) {
                    updateParentIdOnClonedEmailMessage(emailMessageClonedList,insertedCaseList);
                }
        
                //After process, delete all the Email Message Records which are cloned.
               if(!emailMessageTobeDeleted.isEmpty()) {
                    List<EmailMessage> emailMessageTobeD = [Select Id From EmailMessage WHERE Id =:emailMessageTobeDeleted];
                    delete emailMessageTobeD;
                }
        }catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException( CLASS_NAME, 'updateRelatedCaseOnEmailMessage', exc.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName    : updateParentIdOnClonedEmailMessage
    * Description   : Method to insert updated Email Message record.
    * Story         : STY-04647
    * Params        : List<EmailMessage> emailMessageClonedList, List<Case> insertedCaseList
    * ********************************************************************************************/       
    private static void updateParentIdOnClonedEmailMessage(List<EmailMessage> emailMessageClonedList, List<Case> insertedCaseList) {
        List<EmailMessage> emailMessageToBeInserted = New List<EmailMessage>();
        Map<Id,Id> parentCaseIdToCaseIdMap = new Map<Id,Id>();
        try{
        for(Case c : insertedCaseList){
            parentCaseIdToCaseIdMap.put(c.ParentId,c.Id);
        }
        for(EmailMessage eMessage : emailMessageClonedList) {
            if(parentCaseIdToCaseIdMap.get(eMessage.ParentId) != Null) {
                    //Update Parent Id
                    eMessage.ParentId = parentCaseIdToCaseIdMap.get(eMessage.ParentId);
                    emailMessageToBeInserted.add(eMessage);
                }
            }            
        //Insert Updated Email Messages
        if(!emailMessageToBeInserted.isEmpty()) {
            insert emailMessageToBeInserted; 
        }
        }catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException( CLASS_NAME, 'updateParentIdOnClonedEmailMessage', exc.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName    : restrictEmailFromRestrictedSenders
    * Description   : Restrict Email to Case from restricted senders
    * Story         : STY-03643
    * Params        : List<EmailMessage> listOfEmailMessage
    * ********************************************************************************************/
    public static void restrictEmailFromRestrictedSenders(List<EmailMessage> listOfEmailMessage){
        
        try{
            
            for(EmailMessage eMessage : listOfEmailMessage){
                if(restrictedEmailCheck(eMessage)){
                    eMessage.addError(NSP_ServiceConstants.RESTRICTED_EMAIL_ERROR_MESSAGE);   
                }
            }
            
        }catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException( CLASS_NAME, 'restrictEmailFromRestrictedSenders', exc.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName	: restrictedEmailCheck
    * Description	: Restrict Email check
    * Story 		: STY-03643
    * Params		: EmailMessage eMessage
    * ********************************************************************************************/
    public static Boolean restrictedEmailCheck(EmailMessage eMessage){
        List<String> restrictedEmailAddresses = System.Label.NSP_Restricted_Email_Addresses.split(',');
        return eMessage.incoming 
            && (restrictedEmailAddresses.contains(eMessage.FromAddress)
                || eMessage.FromAddress.startsWith(NSP_ServiceConstants.POSTMASTER_EMAIL_ADDRESS));
    }

    // ********************************************************************************************
    // MethodName	: incomingEmailCheck
    // Description	: Incoming Email check for subject check
    // Story 		: STY-03643
    // Params		: EmailMessage eMessage
    // ********************************************************************************************
    private static Boolean incomingEmailCheck( EmailMessage eMessage ) {
        return (
            ( eMessage != null ) // prevent NullPointerException...
            && eMessage.Incoming
            && ( eMessage.ParentId != null ) // prevent NullPointerException when EmailMessage is not related to a Case...
            && ( eMessage.ParentId.getSObjectType() == Case.getSObjectType() )
            && String.isNotBlank( eMessage.Subject ) // prevent NullPointerException when Subject is missing a value...
            && !eMessage.Subject.containsIgnoreCase( 'OOO' )
            && !eMessage.Subject.containsIgnoreCase( 'Out of Office' )
            && !eMessage.Subject.containsIgnoreCase( 'Auto-Response' )
            && !eMessage.Subject.containsIgnoreCase( 'Auto Response' )
            && !eMessage.Subject.containsIgnoreCase( 'Auto-Reply' )
            && !eMessage.Subject.containsIgnoreCase( 'Auto Reply' )
            && !eMessage.Subject.containsIgnoreCase( 'Automatic Response' )
            && !eMessage.Subject.containsIgnoreCase( 'Automatic-Response' )
            && !eMessage.Subject.containsIgnoreCase( 'Automatic Reply' )
            && !eMessage.Subject.containsIgnoreCase( 'Automatic-Reply' )
        );
    }

    /***********************************************************************************************
    * MethodName : updateConfidentialCheckBoxForEmpScreening
    * Story : STY-03671
    * Description : This method will update the case fields if an email is sent to 
    * 				'test.customer.service@insperity.com' or 'test.lesdrugscreening.service@insperity.com
    * Params : Set<Id> caseIdSet
    * ********************************************************************************************/ 
    public static void updateConfidentialCheckBoxForEmpScreening(Set<Id> caseIdSet){
        List<Case> caseListToUpdate = new List<Case>();
        try{
            for(Case caseRec: [SELECT Id, NSP_Confidential__c, NSP_Category__c 
                               FROM Case
                               WHERE Id IN: caseIdSet]){
                                   caseRec.NSP_Confidential__c = True;
                                   caseRec.NSP_Category__c = 'Employment Screening';
                                   caseListToUpdate.add(caseRec);
                               }
            if(!caseListToUpdate.isEmpty()){
                List<Database.SaveResult> results = Database.update(caseListToUpdate,false);
                NSP_ErrorLogHandler.logSaveResultsException( CLASS_NAME, 'updateConfidentialCheckBoxForEmpScreening', results);
            }
        }catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException( CLASS_NAME, 'updateConfidentialCheckBoxForEmpScreening', exc.getMessage());
        }
        
    }
    
    /***********************************************************************************************
    * MethodName 	: sendEmailToHealthWelfareInternalExternal
    * Story 	 	: STY-03531
    * Description   : This method will send auto-response mail based on internal/external sender email
    * Params 		: Map<Id, EmailMessage> healthWelfareInternalExternalCaseIdFromAddMap
    * ********************************************************************************************/     
    public static void sendEmailToHealthWelfareInternalExternal(Map<Id, EmailMessage> healthWelfareInternalExternalCaseIdFromAddMap){
        try{
            //get all the cases created from email-to-case if anybody sends email to Health & Welfare email ID
            //send auto response email with internal email template if the from address has an '@insperity.com' domain
            for(Case caseRec : [SELECT Id, NSP_Case_Created_From_Email_To_Case__c FROM Case WHERE Id IN: healthWelfareInternalExternalCaseIdFromAddMap.keySet()]){
                
                //DF-03783 - email should be triggered only when case is created
				if(caseRec.NSP_Case_Created_From_Email_To_Case__c)
					 continue;
				
                if(healthWelfareInternalExternalCaseIdFromAddMap.get(caseRec.Id).FromAddress.contains(NSP_ServiceConstants.INTERNAL_EMAIL_ADD) &&
                  healthWelfareInternalExternalCaseIdFromAddMap.get(caseRec.Id).ToAddress.equals(System.Label.NSP_Health_Welfare_Section_125)){
                    sendEmailToInternalExternal('NSP_Health_Welfare_Internal_Email_Template', healthWelfareInternalExternalCaseIdFromAddMap.get(caseRec.Id).FromAddress, caseRec.Id);
                }
                
                else {
                    if(healthWelfareInternalExternalCaseIdFromAddMap.get(caseRec.Id).ToAddress.equals(System.Label.NSP_Health_Welfare_Section_125)){
                    sendEmailToInternalExternal('NSP_Health_Welfare_External_Email_Template', healthWelfareInternalExternalCaseIdFromAddMap.get(caseRec.Id).FromAddress, caseRec.Id);
                    }
                 }
            }
        }catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException('NSP_EmailMessageTriggerHelper', 'sendEmailToHealthWelfareInternalExternal', exc.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName 	: sendEmailToInternalExternal
    * Story 	 	: STY-03531
    * Description   : Helper method for sendEmailToHealthWelfareInternalExternal
    * Params 		: String emailTemplateName, String ToAddress, Id caseRecId
    * ********************************************************************************************/ 
    private static void sendEmailToInternalExternal(String emailTemplateName, String ToAddress, Id caseRecId){
        try{
            List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>(); 
            List<String> sendToList = new List<String>();
            sendToList.add(ToAddress);
            List<String> emailTempFields = new List<String>{'ID'};
                EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, emailTemplateName);   
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null, caseRecId);
            email.setTemplateId(emailTemplate.Id); 
            email.setToAddresses(sendToList);
            OrgWideEmailAddress orgWidAddress = NSP_GenericEmailUtility.getOrgWideAddress( System.label.NSP_no_reply );
            if ( orgWidAddress != null ) {
                email.setOrgWideEmailAddressId( orgWidAddress.Id );
            }
            email.setWhatId(caseRecId); 
            email.setSaveAsActivity(false);
            lstEmailMessages.add(email);
            if(!lstEmailMessages.isEmpty()){
                NSP_GenericEmailUtility.sendSingleEmailMessages(lstEmailMessages,false);
            }  
        }catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException( CLASS_NAME, 'sendEmailToInternalExternal', exc.getMessage());
        }
    }

     /***********************************************************************************************
    * MethodName 	: UpdateEmailMessageFields
    * Story 	 	: STY-03853
    * Description   : This method will update EmailMessage ParentId Based on Case External Id
    * Params 		: List<EmailMessage> newList
    * ********************************************************************************************/
   
    public static void updateEmailMessageFields(List<EmailMessage> newList) {
        if(!isFirst) {
            isFirst = true;
            //List to store case Ids
            List<String> caseExternalId = new List<String>();
            //List to keep clone Email Messages
            List<EmailMessage> emailMessageClonedList = new List<EmailMessage>();
            //List to delete the cloned Email Message
            List<Id> emailMessageTobeDeleted = new List<Id>();
            //To Keep external id with its related case Id
            Map<String, String> caseExtrnlIdsByCaseIds = new Map<String, String>();
            
            for(EmailMessage emailMessage : newList) {
                //To Filter netsuote cases only
                if(emailMessage.FromName != null && emailMessage.FromName.Contains('netsuite')){
                    //Get the case external Id from FromName
                    string[] caseExtDetails = emailMessage.FromName.split('\\.');
                    string[] caseExtIds = caseExtDetails[2].split('_');
                    //Case number should be there
                    if(!caseExtIds.isEmpty()) {
                        //Store the external case Id
                        caseExternalId.add(caseExtIds[0]);
                        emailMessageTobeDeleted.add(emailMessage.Id);
                        //Clonning the Email Message
                        EmailMessage emailMessageCloned = emailMessage.clone(false, true, false, false);
                        emailMessageClonedList.add(emailMessageCloned);
                    }
                }
            }

            if(!caseExternalId.isEmpty()) {
                //Get cases for External Case
                for(Case cases : [SELECT Id, ParentId, NSP_Case_External_Id__c FROM Case WHERE NSP_Case_External_Id__c =: caseExternalId]) {
                    caseExtrnlIdsByCaseIds.put(cases.NSP_Case_External_Id__c, cases.Id);
                }

                
                //insert updated cases
                if(!emailMessageClonedList.isEmpty() && !caseExtrnlIdsByCaseIds.isEmpty()) {
                    updateParentIdOnEmailMessage(emailMessageClonedList, caseExtrnlIdsByCaseIds);
                }

                //Finally after process, delete all the Email Message Records which are cloned.
               if(!emailMessageTobeDeleted.isEmpty()) {
                    List<EmailMessage> emailMessageTobeD = [Select Id From EmailMessage WHERE Id =:emailMessageTobeDeleted];
                    delete emailMessageTobeD;
                }
            }
            
        }
    }
    
    //Method to insert updated Email Message record.
    private static void updateParentIdOnEmailMessage(List<EmailMessage> emailMessageClonedList, Map<String, String> caseExtrnlIdsByCaseIds) {
        List<EmailMessage> emailMessageToBeInserted = New List<EmailMessage>();

        for(EmailMessage eMessage : emailMessageClonedList) {
            string[] caseExtDetails = eMessage.FromName.split('\\.');
            string[] caseExtIds = caseExtDetails[2].split('_');

            //Case number should be there
            if(!caseExtIds.isEmpty()) {
                if(caseExtrnlIdsByCaseIds.containskey(caseExtIds[0])){
                    //Update Parent Id
                    eMessage.ParentId = caseExtrnlIdsByCaseIds.get(caseExtIds[0]);
                    emailMessageToBeInserted.add(eMessage);
                }
            }            
        }
        //Insert Updated Email Messages
        if(!emailMessageToBeInserted.isEmpty()) {
            insert emailMessageToBeInserted; 
        }
    }
}