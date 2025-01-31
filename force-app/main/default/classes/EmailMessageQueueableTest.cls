@isTest private class EmailMessageQueueableTest {
    private static final Id BPS_RECORDTYPEID = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'BPS' );

    @testSetup private static void setupTestData() {
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', false);
        newCase.NSP_Category__c = 'Adaption';
        newCase.NSP_SubCategory__c = 'Claim';
        insert newCase;
    }

    @isTest private static void reOpenCaseForBPSAsyncTest() {
        test.startTest();
        Case_Settings__c settings = Case_Settings__c.getOrgDefaults();
        settings.BPS_Case_Tier_1_Categories__c = 'Integra';
        settings.BPS_Case_Tier_2_Categories__c = 'Test';
        settings.BPS_Case_Tier_1_Reopen_Days__c = 14;
        settings.BPS_Case_Tier_2_Reopen_Days__c = 30;
        upsert settings;
        EmailMessageTriggerSettings__c asyncSwitchSetting = EmailMessageTriggerSettings__c.getOrgDefaults();
        asyncSwitchSetting.IsAfterInsertQueueableEnabled__c = true;
        upsert asyncSwitchSetting;
        //Update case record
        Case caseRecord = [SELECT id, Status FROM Case WHERE Status = 'Open' LIMIT 1];
        caseRecord.NSP_Rating__c = 'Neutral';
        caseRecord.Status = 'Closed';
        caseRecord.RecordTypeId = BPS_RECORDTYPEID;
        caseRecord.NSP_Category__c = 'Integra';
        update caseRecord;
        //Email message creation
        EmailMessage eMsg = new EmailMessage ();
        eMsg.FromAddress = 'test@test.com';
        eMsg.Incoming = True;
        eMsg.ToAddress= 'test@xyz.com';
        eMsg.Subject = 'Test email Subject';
        eMsg.HtmlBody = 'Test email body';
        eMsg.ParentId = caseRecord.id;
        eMsg.TextBody = 'Test email Body';
        //inserting Email message
        insert eMsg;
        List<EmailMessage> lstOfEmailMessage = new List<EmailMessage>();
        lstOfEmailMessage.add(eMsg);
        Map<Id,EmailMessage> mapOfEmailMessage = new Map<Id,EmailMessage>();
        mapOfEmailMessage.put(eMsg.Id,eMsg);
        System.enqueueJob(new EmailMessageQueueable(lstOfEmailMessage , mapOfEmailMessage));
        test.stopTest();
        Case updatedCase = [SELECT Status FROM Case WHERE ID = : caseRecord.id];
        System.assertEquals('ReOpened', updatedCase.Status);
    }

}
//