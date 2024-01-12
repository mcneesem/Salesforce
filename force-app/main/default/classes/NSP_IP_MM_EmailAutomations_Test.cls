@isTest
private class NSP_IP_MM_EmailAutomations_Test {
    private static Id ipMMRecordTypeId = SObjectType.Implementation_Profile__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.MMProfile).getRecordTypeId();
    /**
    * Test data for NSP_IP_MM_EmailAutomationsController
    * @param N/A. 
    * @return void                          
    */

    @testSetup
    static void makeData(){
        //Insert Email Template

        List<NSP_Regulated_Area__c> lstRegulatedAssets = new List<NSP_Regulated_Area__c>();
        NSP_Regulated_Area__c regulatedAsset = new NSP_Regulated_Area__c(NSP_Regulation_Type__c = 'State Retirement Plan', NSP_State__c = 'NH');
        lstRegulatedAssets.add(regulatedAsset);
        
        NSP_Regulated_Area__c regulatedAsset1 = new NSP_Regulated_Area__c(NSP_Regulation_Type__c = 'State Retirement Plan', NSP_State__c = 'NH');
        lstRegulatedAssets.add(regulatedAsset1);
        
        NSP_Regulated_Area__c regulatedAsset2 = new NSP_Regulated_Area__c(NSP_Regulation_Type__c = 'State Retirement Plan', NSP_State__c = 'VA');
        lstRegulatedAssets.add(regulatedAsset2);
        insert lstRegulatedAssets;

        Implementation_Profile__c  ip = new Implementation_Profile__c();
        ip.RecordTypeId = ipMMRecordTypeId;
        ip.Client_has_existing_retirement_plan__c = NSP_ServiceConstants.YES;
        ip.Type_of_retirement_plan_client_has_today__c = NSP_ServiceConstants.CSP401K;
        insert ip;
    }

    //method to test email automations

    @isTest static void testMethodForEmailAutomations(){
        Test.startTest();
        // GIVEN
        //insert email template
        EmailTemplate emailTemplate = new EmailTemplate();
        emailTemplate.isActive = true;
        emailTemplate.Name = 'Test Email Template';
        emailTemplate.DeveloperName = 'Test_Email_Template';
        emailTemplate.TemplateType = 'text';
        emailTemplate.FolderId = UserInfo.getUserId();
        emailTemplate.Subject = 'Test Subject';
        insert emailTemplate;

        Implementation_Profile__c ip = [SELECT Id, Client_has_existing_retirement_plan__c FROM Implementation_Profile__c 
                                        WHERE Client_has_existing_retirement_plan__c =:NSP_ServiceConstants.YES LIMIT 1];

        // WHEN
        NSP_IP_MM_EmailAutomationsController.sendMail(emailTemplate,ip, new List<String>{'test@address.com'}, false);
        NSP_IP_MM_EmailAutomationsController.sendMail(emailTemplate,ip, new List<String>{'test@address.com'}, true);
        List<String> lstRegulatedAssets = NSP_IP_MM_EmailAutomationsController.getRegulatedAreaStates();
        NSP_IP_MM_EmailAutomationsController.getMailObject(ip, new List<String>{'test@address.com'}, null, new List<String>{'test@address.com'}, emailTemplate.Id, false);
        NSP_IP_MM_EmailAutomationsController.getMailObject(ip, new List<String>{'test@address.com'}, null, new List<String>{'test@address.com'}, emailTemplate.Id, true);
        // THEN
        System.assertEquals(lstRegulatedAssets.size(), 3, '3 Regulated States Found');

        Test.stopTest();
    }
}
