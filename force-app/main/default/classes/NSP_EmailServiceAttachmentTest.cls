/**
Apex Class Name      :  NSP_EmailServiceAttachmentTest
Version              :  1.0                                                                          
Created Date         :  7/4/2022  
Function             :  Represents test class for NSP_EmailServiceAttachment 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------        
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------    
* Nischay                    8/5/2022           First Iteration
*/

@isTest(SeeAllData=false)
public class NSP_EmailServiceAttachmentTest {
    public final static String PEOProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Project_Task__c', NSP_ServiceConstants.PROJECT_TASK_PEO_RECORDTYPE);
    
    /**
* Does test data setup
* @param N/A. 
* @return void                          
*/
    
    @testSetup
    static void testData() {
        
        Account oAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        Contact oContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', false);
        oContact.AccountId = oAccount.Id;
        oContact.pse__Salesforce_User__c = UserInfo.getUserId();
        oContact.NSP_Work_email__c = 'abctestexamplyxyz@test.com.abc';
        insert oContact;
        
        Case oCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', true);
        //project creation
        pse__Proj__c oProject = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', false);
        oProject.pse__Start_Date__c = Date.Today();
        oPRoject.Case__c = oCase.Id;
        oProject.pse__End_Date__c = System.Today().addDays(100);
        oProject.pse__Account__c= oAccount.Id;
        oProject.TemplateName__c = label.Middle_Market_Implementation_Project;
        oProject.pse__Project_Type__c=NSP_ServiceConstants.ImplementationProjectType;
        oProject.NSP_Asset_Implementation_Project__c =True; 
        //inserting project
        insert oProject;

        //inserting project task
		pse__Project_Task__c projTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        projTask.pse__Status__c = NSP_ServiceConstants.PROJECT_TASK_IN_PROGRESS;
        projTask.RecordTypeId = PEOProjectTaskRecordTypeId;
        projTask.Name = NSP_ServiceConstants.FEIN;
        projTask.pse__Project__c = oProject.Id;
        insert projTask;
        //content creation
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        content.NSP_Signature_Date__c = System.today();
        //inserting content
        insert content;
        //contentLink creation
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=oProject.id;
        contentlink.contentdocumentid=[SELECT contentdocumentid from contentversion WHERE id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        //inserting contentLink
        insert contentlink;

        //contentLink creation
        ContentDocumentLink ctl=new ContentDocumentLink();
        ctl.LinkedEntityId=projTask.id;
        ctl.contentdocumentid=[select contentdocumentid from contentversion WHERE id =: content.id].contentdocumentid;
        ctl.ShareType = 'I';
        ctl.Visibility = 'AllUsers'; 
        //inserting contentLink
        insert ctl;
        
    }
    /**
* @Description: This test method is used to cover getProjectTaskAttachments method
* @Created date: 07/18/2022. 
* @return void             
*     */  
    
    @isTest
    public static void getProjectTaskAttachmentsTest(){
        Date getDate = Date.Today();
        pse__Proj__c getProj = [SELECT Id,
                                pse__Start_Date__c 
                                FROM pse__Proj__c 
                                WHERE pse__Start_Date__c =: getDate
                                LIMIT 1];
        Test.startTest();
        NSP_EmailServiceAttachment.getProjectTaskAttachments(getProj.Id);
        Test.stopTest();
        system.assertEquals(getDate, getProj.pse__Start_Date__c);
    }

     /**
* @Description: This test method is used to cover getProjectTaskAttachments method
* @Created date: 05/03/2023. 
* @return void             
*     */  
    
@isTest
public static void getTaskAttachmentsTest(){
    Set<Id> projTaskIds = new Set<Id>();
    pse__Project_Task__c getProjTask = [SELECT Id
                                FROM pse__Project_Task__c WHERE Name != null
                            LIMIT 1];
    projTaskIds.add(getProjTask.id);
    
    Test.startTest();
    NSP_EmailServiceAttachment.getProjectTaskAttachments(projTaskIds);
        System.assert(NSP_EmailServiceAttachment.getProjectTaskAttachments(projTaskIds).size() > 0);
    Test.stopTest();
}
}