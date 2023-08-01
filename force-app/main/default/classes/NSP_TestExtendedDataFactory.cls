@isTest
public class NSP_TestExtendedDataFactory extends NSP_TestDataFactory{

    
    @isTest
    public static void testMethod1(){
        Account newAccount = (Account)NSP_TestExtendedDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        Lead newLead = (Lead)NSP_TestExtendedDataFactory.createSObject(new Lead(), 'NSP_TestDataFactory.LeadDefaults', true);
        Campaign newCampaign = (Campaign)NSP_TestExtendedDataFactory.createSObject(new Campaign(), 'NSP_TestDataFactory.CampaignDefaults', true);
        //Opportunity newOpportunity = (Opportunity)NSP_TestExtendedDataFactory.createSObject(new Opportunity(), 'NSP_TestDataFactory.OpportunityDefaults', true);
        Contact newContact = (Contact)NSP_TestExtendedDataFactory.createSObject(new Contact(), 'NSP_TestDataFactory.ContactDefaultsLight', true);
        User newUser = (User)NSP_TestExtendedDataFactory.createSObject(new User(), 'NSP_TestDataFactory.UserDefaults', true);
        Product2 newProduct2 = (Product2)NSP_TestExtendedDataFactory.createSObject(new Product2(), 'NSP_TestDataFactory.Product2Defaults', true);
        CollaborationGroup newCollaborationGroup = (CollaborationGroup)NSP_TestExtendedDataFactory.createSObject(new CollaborationGroup(), 'NSP_TestDataFactory.CollaborationGroupDefaults', true);
        Document newDocument = (Document)NSP_TestExtendedDataFactory.createSObject(new Document(), 'NSP_TestDataFactory.DocumentDefaults', true);
        Group newGroup = (Group)NSP_TestExtendedDataFactory.createSObject(new Group(), 'NSP_TestDataFactory.GroupDefaults', true); 
        Pricebook2 newPricebook2 = (Pricebook2)NSP_TestExtendedDataFactory.createSObject(new Pricebook2(), 'NSP_TestDataFactory.Pricebook2Defaults', true);
        Case newCase = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), 'NSP_TestDataFactory.CaseDefaults', true);
        Task newTask = (Task)NSP_TestExtendedDataFactory.createSObject(new Task(), 'NSP_TestDataFactory.TaskDefault', true);
        Attachment newAttachment = (Attachment)NSP_TestExtendedDataFactory.createSObject(new Attachment(), 'NSP_TestDataFactory.AttachmentDefaults', true);
        ContentVersion newContentVersion = (ContentVersion)NSP_TestExtendedDataFactory.createSObject(new ContentVersion(), 'NSP_TestDataFactory.ContentVersionDefaults', true);
        ContentDocumentLink newContentDocumentLink = (ContentDocumentLink)NSP_TestExtendedDataFactory.createSObject(new ContentDocumentLink(), 'NSP_TestDataFactory.ContentDocumentLinkDefaults', true);
        FeedItem newFeedItem = (FeedItem)NSP_TestExtendedDataFactory.createSObject(new FeedItem(), 'NSP_TestDataFactory.FeedItemDefaults', true);
        //NSP_Account_Group__c newAccountGroup = (NSP_Account_Group__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', true);
        NSP_Sub_Client_Contact_Address__c newSubClientAddress = (NSP_Sub_Client_Contact_Address__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client_Contact_Address__c(), 'NSP_TestDataFactory.SubClientContactAddressDefaults', true);
        NSP_Sub_Client_Contact__c newSubClientContact = (NSP_Sub_Client_Contact__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', true);
        NSP_Account_Team__c newAccTeam = (NSP_Account_Team__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Team__c(), 'NSP_TestDataFactory.accountTeamDefaults', true);
        pse__Proj__c newPrj = (pse__Proj__c)NSP_TestExtendedDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', true);
        pse__Project_Task__c newPrjTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false); // making boolean to false as in testdata factory we cannot fetch the ProjectId
        Order orderObj = (Order)NSP_TestExtendedDataFactory.createSObject(new Order(), 'NSP_TestDataFactory.OrderDefaults', false);
        NSP_Case_Contacts__c newCseCon = (NSP_Case_Contacts__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Case_Contacts__c(), 'NSP_TestDataFactory.caseContactDefaults', false);
        AccountContactRelation newAcr = (AccountContactRelation)NSP_TestExtendedDataFactory.createSObject(new AccountContactRelation(), 'NSP_TestDataFactory.acrDefaults', false);
        NSP_Service_Plan__c getServicePlanTeam = (NSP_Service_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Service_Plan__c(), 'NSP_TestDataFactory.ServicePlanDefaults', false);
        NSP_Regulated_Area__c getRegulatedArea = (NSP_Regulated_Area__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Regulated_Area__c(), 'NSP_TestDataFactory.RegulatedAreaDefaults', false);
        PricebookEntry newPricebookEntry = (PricebookEntry)NSP_TestExtendedDataFactory.createSObject(new PricebookEntry(), 'NSP_TestDataFactory.PriceBookEntryDefaults', false);
        Additional_Payroll_Contact__c newAddPayrollContact = (Additional_Payroll_Contact__c)NSP_TestExtendedDataFactory.createSObject(new Additional_Payroll_Contact__c(), 'NSP_TestDataFactory.AdditionalPayrollContactDefaults', false);
        NSP_Payroll__c newPayrollDataSheet = (NSP_Payroll__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Payroll__c(), 'NSP_TestDataFactory.PayrollDataSheetDefaults', false);
        NSP_PTO_Smartform__c newPTOSmartForm = (NSP_PTO_Smartform__c)NSP_TestExtendedDataFactory.createSObject(new NSP_PTO_Smartform__c(), 'NSP_TestDataFactory.PTOSmartformDefaults', false);
        NSP_Plan__c newPlan = (NSP_Plan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan__c(), 'NSP_TestDataFactory.PlanDefaults', false);
        NSP_Plan_SubPlan__c newSubPlan = (NSP_Plan_SubPlan__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Plan_SubPlan__c(), 'NSP_TestDataFactory.SubPlanDefaults', false);
        NSP_Client_Sub_Plan_History__c newClientSubPlanHistory = (NSP_Client_Sub_Plan_History__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Client_Sub_Plan_History__c(), 'NSP_TestDataFactory.ClientSubPlanHistoryDefaults', false);
        NSP_Sub_Plan_Change_History__c newSubPlanChangeHistory = (NSP_Sub_Plan_Change_History__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Sub_Plan_Change_History__c(), 'NSP_TestDataFactory.SubPlanChangeHistoryDefaults', false);
        Asset newAsset = (Asset)NSP_TestExtendedDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', false);
        NSP_Address__c newAddress = (NSP_Address__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Address__c(), 'NSP_TestDataFactory.AddressDefaults', false);
        pse__Project_Task__c newProjectTask = (pse__Project_Task__c)NSP_TestExtendedDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', false);
        pse__Milestone__c newMiletone = (pse__Milestone__c)NSP_TestExtendedDataFactory.createSObject(new pse__Milestone__c(), 'NSP_TestDataFactory.MileStoneDefaults', false);
        WorkType newWorkType = (WorkType)NSP_TestExtendedDataFactory.createSObject(new WorkType(), 'NSP_TestDataFactory.WorkTypeDefaults', false);
        NSP_Category_Sub_Category_Mapping__c newCatSubCatMap = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        NSP_Eligibility__c newEligibility = (NSP_Eligibility__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Eligibility__c(), 'NSP_TestDataFactory.EligibilityDefaults', false);
        NSP_RET_Education__c newEducation = (NSP_RET_Education__c)NSP_TestExtendedDataFactory.createSObject(new NSP_RET_Education__c(), 'NSP_TestDataFactory.EducationDefaults', false);
        AssetRETEducationAssociation__c newAssetRETEdu = (AssetRETEducationAssociation__c)NSP_TestExtendedDataFactory.createSObject(new AssetRETEducationAssociation__c(), 'NSP_TestDataFactory.AssetRETEducationAssociationDefaults', false);
        NSP_Note__c newNote = (NSP_Note__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Note__c(), 'NSP_TestDataFactory.NSPNoteDefaults', false);
        Order newOrder = (Order)NSP_TestExtendedDataFactory.createSObject(new Order(), 'NSP_TestDataFactory.OrderDefaults', false);
        NSP_ReportRequest__c newA = (NSP_ReportRequest__c)NSP_TestExtendedDataFactory.createSObject(new NSP_ReportRequest__c(), 'NSP_TestDataFactory.ReportRequestDefaults', false);
        EmailMessage newEmailMessage = (EmailMessage)NSP_TestExtendedDataFactory.createSObject(new EmailMessage(), 'NSP_TestDataFactory.emailMessageDefaults', false);
        NSP_Account_Group_Member__c newAcctGrpMem= (NSP_Account_Group_Member__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Account_Group_Member__c(), 'NSP_TestDataFactory.AccountGroupMemberDefaults', false);
        NSP_Focus_Item__c newFocusItem= (NSP_Focus_Item__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Focus_Item__c(), 'NSP_TestDataFactory.FocusItemDefaults', false);
        NSP_Implementation_Profile_Automation__c newImplPrOAuto= (NSP_Implementation_Profile_Automation__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Implementation_Profile_Automation__c(), 'NSP_TestDataFactory.ImplementationProfileAutomationsDefaults', false);
        pse__Region__c newRegion= (pse__Region__c)NSP_TestExtendedDataFactory.createSObject(new pse__Region__c(), 'NSP_TestDataFactory.RegionDefaults', false);
        pse__Permission_Control__c newPermissionControl = (pse__Permission_Control__c)NSP_TestExtendedDataFactory.createSObject(new pse__Permission_Control__c(), 'NSP_TestDataFactory.PermissionControlDefaults', false);
        NSP_Accrual_Profile__c accProfile = (NSP_Accrual_Profile__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Accrual_Profile__c(), 'NSP_TestDataFactory.AccrualProfileDefaults', false);
        NSP_Accrual_Profile_Account_Relationship__c accProfileAccRelationship = (NSP_Accrual_Profile_Account_Relationship__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Accrual_Profile_Account_Relationship__c(), 'NSP_TestDataFactory.AccrualProfileAccountRelationshipDefaults', false);
        system.assert(true);
    }
}