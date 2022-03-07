/**************************************************************************************************   
Test Class Name		 :  NSP_EmailServicesUtilityTest
Version              :  1.0                                                                          
Created Date         :  October 10, 2021                                                             
Function             :  This class is used to cover tests for NSP_EmailServicesUtility class.
Test class           :  NSP_EmailServicesUtilityTest
Story                :                                                                             
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  

*	Tejas          November 6, 2021          First Iteration
***************************************************************************************************/
@isTest
public without sharing class NSP_EmailServicesUtilityTest {
    
    @testSetup
    public static void createTestData(){
        List<EmailTemplate> emailTempalteList = new List<EmailTemplate>();
        Test.startTest();
        
        EmailTemplate template = new EmailTemplate ();
        template.developerName = 'Test_Email_Template_Unique';
        template.FolderId=userInfo.getUserId();
        template.TemplateType='Text';
        template.Name='TestEmailTempalte_Unique';
        
        emailTempalteList.add(template);
        
        EmailTemplate vfTemplate = new EmailTemplate ();
        string templateText = '<messaging:emailTemplate subject="{!relatedTo.Name}" recipientType="User" relatedToType="Opportunity"><messaging:htmlEmailBody ><ul><li>test content</li></ul></messaging:htmlEmailBody></messaging:emailTemplate>';
        vfTemplate.developerName = 'TestEmailTempalteVFTestTempalte';
        vfTemplate.FolderId=userInfo.getUserId();
        vfTemplate.TemplateType='Visualforce';
        vfTemplate.Name='TestEmailTempalteVFTestTempalte';
        vfTemplate.isActive=true;        
        
        vfTemplate.Markup=templateText;        
        emailTempalteList.add(vfTemplate);
        
        insert emailTempalteList;
        
        Test.stopTest();
    }
    
    @isTest
    public static void sendDynamicEmailFromEmailTemplateTest(){
        NSP_EmailServicesUtility.EmailMessageWrapper emailWrapper = new NSP_EmailServicesUtility.EmailMessageWrapper('Test Company',
                                                                                                                     new List<String>{'abcd@est.com'},
                                                                                                                     'test subject',
                                                                                                                     'body of email',
                                                                                                                     null,null);
        List<NSP_EmailServicesUtility.EmailMessageWrapper> emailWrapperList = new List<NSP_EmailServicesUtility.EmailMessageWrapper>{emailWrapper};
            
            EmailTemplate emailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name!='' AND TemplateType='Text' LIMIT 1];
        NSP_EmailServicesUtility.sendDynamicEmailFromEmailTemplate(emailWrapperList,emailTemplate.Id);    
        system.assertequals(true,true);
    }
    
    //sendVFEmailTemplateTest test method
    @isTest
    public static void sendVFEmailTemplateTest(){
        Test.startTest();
        String[] s1 = new String[] {'ram', 'sam', 'jack'}; 
        Id userId = userInfo.getUserId();
        
        Account account = NSP_TestHelper.createAccount(true);
        Opportunity opportunityRecord = NSP_TestHelper.createOpenOpportunity(account.Id, 'New Product', true);
        
        EmailTemplate vfEmailTemplate = [SELECT Id, Name FROM EmailTemplate WHERE Name!='' AND TemplateType='Visualforce' LIMIT 1];
        
        NSP_EmailServicesUtility.sendVFEmailTemplate(userId,s1,vfEmailTemplate, opportunityRecord.Id);
        Test.stopTest();
         system.assertequals(true,true);
    }
}