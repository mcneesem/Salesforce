/*
 * Author: Jatin Ahuja 
* Represents test class for Report Request Trigger helper
* Test Class to cover Report Request Trigger Handler and Helper classes 
* Modified Date: 12 Sep 2021 
*/
@isTest
private class NSP_ReportRequestTriggerHelperTest{

    private static final String REPORT_REQUEST = 'NSP_ReportRequest__c';

    //setup
    @testSetup static void setup(){ 
        Id recordTypeID = NSP_GenericRecordType.getRecordTypeId(REPORT_REQUEST,'NSP_DevelopmentReport');
        NSP_ReportRequest__c reportrequest = (NSP_ReportRequest__c)NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), 'NSP_TestDataFactory.ReportRequestDefaults', false);
        reportrequest.RecordTypeId = recordTypeID;
        reportrequest.NSP_IsDraft__c=false;
        reportrequest.name='test';
        insert reportrequest;
    }

/**
* @Description: This test method is usePd to cover testCaseTriggerOperation
* @Created date: 1 june 2022 
* @return void             
* Author:Jatin Ahuja            
*/
@isTest
private static void testCaseTriggerOperation(){
    // create account details
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', false);
        newAccount.NSP_Premier_Pathway_Client__c ='12345ABCDEF';
    //insert account
        insert newAccount;

    //create contact details
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        newContact.Account = newAccount;
        newContact.NSP_Per_ID__c ='ABCDEF12345';
    // insert conact
       insert newContact;

    //create group
       Group newGroup;
       if([Select ID from Group WHERE DeveloperName ='NSP_ReportDevelopment']?.size() == 0 ){
           newGroup= (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', false); 
           newGroup.Type ='Queue';
           newGroup.name ='Report Development';
           newGroup.DeveloperName ='NSP_ReportDevelopment' ;
      //insert group
           insert newGroup; 
           
     //create queue and insert
           QueuesObject testQueue = new QueueSObject(QueueID = newGroup.id, SObjectType = 'Case');
           System.runAs(new User(Id = UserInfo.getUserId())){
           insert testQueue;}
       }

       Id recordTypeID = SObjectType.NSP_ReportRequest__c.getRecordTypeInfosByDeveloperName().get('NSP_DevelopmentReport').getRecordTypeId();

    //create report request
       NSP_ReportRequest__c newRepReqTrigger = new NSP_ReportRequest__c();
       newRepReqTrigger.RecordTypeId =recordTypeID;
       newRepReqTrigger.NSP_Existing_NewReport__c = 'New Report';
       newRepReqTrigger.NSP_InternalClientReport__c ='Internal Report';
       newRepReqTrigger.NSP_Action__c = NSP_ServiceConstants.WIZARD_DEVELOPMENT;
    // insert report request
       insert newRepReqTrigger;
    
       NSP_ReportRequest__c  insertData = [SELECT Id,NSP_Action__c,NSP_ReportType__c,NSP_ReportLocation__c,NSP_Misc__c, NSP_Existing_NewReport__c 
                                           FROM NSP_ReportRequest__c WHERE NSP_Action__c =: NSP_ServiceConstants.WIZARD_DEVELOPMENT LIMIT 1];
       System.assertEquals(insertData.NSP_Existing_NewReport__c, 'New Report');
       
    }
    
    /**
	* @Description: This test method is used to cover wizard deletion validation
	* @Created date: 02 /16/ 2023 
	* @return void             
	*/
    @isTest
	private static void testWizardDelete(){
        List<String> repReqFields = new List<String>{'Id','NSP_IsDraft__c'};
        String query = new NSP_QueryBuilder(REPORT_REQUEST, repReqFields)
                          .addLimit(1).build();
        List<NSP_ReportRequest__c> repReqRecord = Database.query(query);
        Test.startTest();
        delete repReqRecord[0];
        Test.stopTest();
        System.assertEquals(repReqRecord.size(),1);
        
	}
    
    /**
	* @Description: This test method is used to cover wizard deletion validation
	* @Created date: 02 /16/ 2023 
	* @return void             
	*/
    @isTest
	private static void testWizardDeleteNegative(){
        List<String> repReqFields = new List<String>{'Id','NSP_IsDraft__c'};
        String query = new NSP_QueryBuilder(REPORT_REQUEST, repReqFields)
                          .addLimit(1).build();
        List<NSP_ReportRequest__c> repReqRecord = Database.query(query);
        Test.startTest();
        repReqRecord[0].NSP_IsDraft__c=true;
        update repReqRecord;
        delete repReqRecord;
        Test.stopTest();
        String repquery = new NSP_QueryBuilder(REPORT_REQUEST, repReqFields)
                          .addLimit(1).build();
        List<NSP_ReportRequest__c> repReqList = Database.query(repquery);
        System.assertEquals(repReqList.size(),0);
        
	}

    @IsTest
    static void afterInsert() {
        new NSP_ReportRequestTriggerHandler().afterInsert(null, null);
        System.assert(new NSP_ReportRequestTriggerHandler().afterInsert(null, null) == null);
    }
    @IsTest
    static void afterUpdate() {
        new NSP_ReportRequestTriggerHandler().afterUpdate(null, null);
         System.assert(new NSP_ReportRequestTriggerHandler().afterUpdate(null, null) == null);
    }
    @IsTest
    static void afterDelete() {
        new NSP_ReportRequestTriggerHandler().afterDelete(null, null);
         System.assert(new NSP_ReportRequestTriggerHandler().afterDelete(null, null) == null);
    }


}