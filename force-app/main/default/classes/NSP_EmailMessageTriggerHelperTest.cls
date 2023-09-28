/**
Apex Class Name      :  NSP_EmailMessageTriggerHelperTest for NSP_EmailMessageTriggerHelper
Version              :  1.0                                                                          
Created Date         :  6/1/2022   
Function             :  Test class for NSP_EmailMessageTriggerHelper 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Ramya                     6/9/2022            First Iteration
*/

    
@isTest
private class NSP_EmailMessageTriggerHelperTest {
    public static final String CONTACTCENTER = 'contactcenter@insperity.com.invalid';
    public static final String QUEUE = 'Queue';
    public static final String CONTACTCENTERQUEUE = 'NSP_ContactCenter';
    
    @testSetup
    static void setupTestData(){
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCase.NSP_Category__c = 'Adaption';
        newCase.NSP_SubCategory__c = 'Claim';
        insert newCase;
    }

    @isTest
    static void markResponseAfterCloseTrueForPEOTest() {   
        test.startTest();
        Id casePEORecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();

        Case caseRecord = [SELECT id, Status FROM  Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = casePEORecordTypeId;
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';              
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= 'test@xyz.com';
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        
        //inserting Email message
        insert eMsg;
        test.stopTest();

    }     

    @isTest  
    static void reOpenCaseForBPSTest() {  
        test.startTest();
        Id caseBPSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('BPS').getRecordTypeId();
   
        Case caseRecord = [SELECT id, Status FROM Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = caseBPSRecordTypeId;
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= 'test@xyz.com';
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        
        //inserting Email message
        insert eMsg;
        test.stopTest();

        Case updatedCase = [SELECT Status FROM Case WHERE ID = : caseRecord.id];
        System.assertEquals('ReOpened', updatedCase.Status);
        
    }
    
     /**
    * @Description: This test method is used to test restriction
    * 				of email to case from particular senders
    * @return	  : void             
    */
    @isTest
    private static void testrestrictEmailFromRestrictedSenders(){
        Test.startTest();
        try{
            EmailMessage eMessage = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), 'NSP_TestDataFactory.emailMessageDefaults', false);
            eMessage.FromAddress = 'viva-noreply@microsoft.com';
            INSERT eMessage;
        }catch(Exception ex){
        	system.assertEquals(ex.getMessage(), 'Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, EmailMessage cannot be created as sender is from restricted list.: []');   
        }
        Test.stopTest();
    }
    
    /**
    * @Description: This test method is used to test 
    * 				EmailMessage creation
    * @return	  : void             
    */
    @isTest
    private static void testEmailMessageCreationWithoutRestrictedFromAddress(){
        test.startTest();
        List<String> caseFields = new List<String>{'Id','Status'};
        String query = new NSP_QueryBuilder('Case', caseFields)
                          .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS).build();
        Case caseRecord = Database.query(query);
        EmailMessage eMessage = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), 'NSP_TestDataFactory.emailMessageDefaults', false);
        eMessage.ParentId = caseRecord.Id;
        INSERT eMessage;
        System.assertEquals(1, [SELECT Count() FROM EmailMessage WHERE Id =: eMessage.Id]);   
        Test.stopTest();
    }
    
    /***********************************************************************************************
    * MethodName : testUpdateConfidentialCheckBoxForEmpScreening
    * Description : This method is used to test if case fields are updated when an email is sent to 
    * 				'test.customer.service@insperity.com' or 'test.lesdrugscreening.service@insperity.com
    * ********************************************************************************************/ 
    @isTest
    private static void testUpdateConfidentialCheckBoxForEmpScreening(){
        test.startTest();
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c'};
        String query = new NSP_QueryBuilder('Case', caseFields)
                          .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            			  .addLimit(1).build();
        Case caseRecord = Database.query(query);     
        EmailMessage eMessage = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), 'NSP_TestDataFactory.emailMessageDefaults', false);
        eMessage.ToAddress = System.Label.NSP_Customer_Service_Email;
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@test.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        System.assertEquals(false, caseRecord.NSP_Confidential__c);
        test.stopTest();
    }
    
    /***********************************************************************************************
    * MethodName : neagativTestUpdateConfidentialCheckBoxForEmpScreening
    * Description : This method is used to test if case fields are not updated when an email is not sent to 
    * 				'test.customer.service@insperity.com' or 'test.lesdrugscreening.service@insperity.com
    * ********************************************************************************************/ 
    @isTest
    private static void neagativTestUpdateConfidentialCheckBoxForEmpScreening(){
        test.startTest();
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c', 'Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);    
        EmailMessage eMessage = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), 'NSP_TestDataFactory.emailMessageDefaults', false);
        eMessage.ToAddress = 'test.test@test.com';
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@test.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        System.assertEquals(false, caseRecord.NSP_Confidential__c);
        test.stopTest();
    }
    
    /***********************************************************************************************
    * MethodName : sendEmailToHealthWelfareInternal
    * Description : This method is used to test if auto response mail is sent if sender is internal
    * ********************************************************************************************/ 
    @isTest
    private static void sendEmailToHealthWelfareInternal(){
        test.startTest();
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c', 'Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);    
        EmailTemplate template = new EmailTemplate ();
        template.developerName = 'Test_Email_Template_Unique';
        template.FolderId=userInfo.getUserId();
        template.TemplateType='Text';
        template.Name='TestEmailTempalte_Unique';
        insert template;
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
        EmailMessage eMessage = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), 'NSP_TestDataFactory.emailMessageDefaults', false);
        eMessage.ToAddress = System.Label.NSP_Health_Welfare_Section_125;
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@insperity.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        }
        system.assertEquals(caseRecord.Status, NSP_ServiceConstants.CASE_OPEN_STATUS);
        test.stopTest();
    }
    
    /***********************************************************************************************
    * MethodName : sendEmailToHealthWelfareExternal
    * Description : This method is used to test if auto response mail is sent if sender is external
    * ********************************************************************************************/ 
    @isTest
    private static void sendEmailToHealthWelfareExternal(){
        test.startTest();
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c', 'Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);    
        EmailMessage eMessage = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), 'NSP_TestDataFactory.emailMessageDefaults', false);
        eMessage.ToAddress = 'test.customer.service@insperity.com';
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@pwc.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        system.assertEquals(eMessage.Subject, 'test');
        test.stopTest();
    }
    
    /***********************************************************************************************
    * MethodName : negativesendEmailToHealthWelfareExternal
    * Description : This method is a negative test for sendEmailToHealthWelfareInternalExternal()
    * ********************************************************************************************/ 
    @isTest
    private static void negativesendEmailToHealthWelfareExternal(){
        test.startTest();
        List<String> caseFields = new List<String>{'Id', 'NSP_Confidential__c', 'NSP_Category__c', 'Status'};
            String query = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('Status', NSP_ServiceConstants.CASE_OPEN_STATUS)
            .addLimit(1).build();
        Case caseRecord = Database.query(query);    
        EmailMessage eMessage = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), 'NSP_TestDataFactory.emailMessageDefaults', false);
        eMessage.ToAddress = 'test.customer.service@test.com';
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.FromAddress = 'test@pwc.com';
        eMessage.ParentId = caseRecord.Id;
        Database.insert(eMessage);
        system.assertEquals(0, Limits.getEmailInvocations());
        test.stopTest();
    }

     /**
    * @Description: This test method is used to cover createCaseContact method
    * @Created date: 11/11/2022. 
    * @return void             
    *     
    */  
    @isTest  
    private static void updateEmailMessageFieldsTest(){
        test.startTest();
        Case nCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        nCase.NSP_Case_External_Id__c = '22778899';
        insert nCase;
        
        EmailMessage eMessage = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), 'NSP_TestDataFactory.emailMessageDefaults', false);
        eMessage.ToAddress = 'test@insperity.com';
        eMessage.FromName = 'cases.345678_SB4.22778899_3456789.netsuite';
        eMessage.Subject = 'test';
        eMessage.Incoming = true;
        eMessage.ParentId = nCase.Id;
        eMessage.FromAddress = 'test@pwc.com';
        Database.insert(eMessage);
        
        
        List<EmailMessage> eMessageList = [SELECT Id, FromName ,ParentId ,CreatedDate From EmailMessage WHERE FromName = 'cases.345678_SB4.22778899_3456789.netsuite'];
        system.assert(eMessageList.size() > 0);
        test.stopTest();
    }
    
    /***********************************************************************************************
    * MethodName : markResponseAfterCloseMoreThanFiveForPEOTest
    * Description : This method is used to test if Mark Response field and creation of Child case base on Case closed Date
    * ********************************************************************************************/ 
    @isTest
    static void markResponseAfterCloseMoreThanFiveForPEOTest() {
        test.startTest();
        Id casePEORecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
        ID contactCenterQueueId = ([SELECT ID FROM Group WHERE Type = :QUEUE AND DeveloperNAME = :CONTACTCENTERQUEUE]).ID;
        Map<Case,String> CaseToSubjectMap = new Map<Case,String>();
        Map<Case,EmailMessage> ParentCaseToEmailMessageMap = new Map<Case,EmailMessage>();
        List<Case> caseList = new List<Case>();

        Case caseRecord = [SELECT id, Status FROM  Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = casePEORecordTypeId;
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';
        caseRecord.NSP_Date_Closed__c = Date.Today().addDays(-10);
        update caseRecord;
        
        
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= CONTACTCENTER;
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        
        //inserting Email message
        insert eMsg;
        
        CaseToSubjectMap.put(caseRecord,'Created From TestClass');
        ParentCaseToEmailMessageMap.put(caseRecord,eMsg);
        caseList.add(caseRecord);
        
        NSP_EmailMessageTriggerHelper.createCaseFromEmail(CaseToSubjectMap,contactCenterQueueId);
        NSP_EmailMessageTriggerHelper.updateRelatedCaseOnEmailMessage(ParentCaseToEmailMessageMap,caseList);
        test.stopTest();        

    }
    
    /***********************************************************************************************
    * MethodName : markResponseAfterCloseLessThanFiveForPEOTest
    * Description : This method is used to test if Mark Response field and reopen case based on Case closed Date
    * ********************************************************************************************/ 
    @isTest
    static void markResponseAfterCloseLessThanFiveForPEOTest() {   
        test.startTest();
        Id casePEORecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();

        Case caseRecord = [SELECT id, Status FROM  Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = casePEORecordTypeId;
        caseRecord.NSP_Category__c = 'Adaption';
        caseRecord.NSP_SubCategory__c = 'Claim';
        caseRecord.NSP_Date_Closed__c = Date.Today();
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= CONTACTCENTER;
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        
        //inserting Email message
        insert eMsg;
        test.stopTest();

    }
}