/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-08-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public abstract class NSP_TestDataFactory {
    
    
    public static void generateUniqTestData() {
        NSP_TestDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
        
    }
    
    public static SObject createSObject(SObject sObj) {
        
        String objectName = String.valueOf(sObj.getSObjectType());
        
        String defaultClassName = 'NSP_TestDataFactory.' + objectName.replaceAll('__(c|C)$|__', '') + 'Defaults';
        
        if (Type.forName(defaultClassName) != null) {
            sObj = createSObject(sObj, defaultClassName);
        }
        
        return sObj;
    }
    
    public static SObject createSObject(SObject sObj, Boolean doInsert) {
        
        SObject retObject = createSObject(sObj);
        
        if (doInsert) {
            insert retObject;
        }
        
        return retObject;
    }
    
    public static SObject createSObject(SObject sObj, String defaultClassName) {
        
        Type t = Type.forName(defaultClassName);
        
        if (t == null) {
            Throw new TestFactoryException('Invalid defaults class.');
        }
        
        FieldDefaults defaults = (FieldDefaults)t.newInstance();
        addFieldDefaults(sObj, defaults.getFieldDefaults());
        
        return sObj;
    }
    
    
    
    public static SObject createSObject(SObject sObj, String defaultClassName, Boolean doInsert) {
        
        SObject retObject = createSObject(sObj, defaultClassName);
        
        if (doInsert) {
            insert retObject;
        }
        
        return retObject;
    }
    
    private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
        
        Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();
        for (Schema.SObjectField field : defaults.keySet()) {
            if (!populatedFields.containsKey(String.valueOf(field))) {
                sObj.put(field, defaults.get(field));
            }
        }
    }
    
    public class TestFactoryException extends Exception {}
    
    
    public interface FieldDefaults {
        Map<Schema.SObjectField, Object> getFieldDefaults();
    }
    
    public class AccountDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Account.Name => 'Test New Acc - 01',
                    Account.BillingCity =>'New York',
                    Account.BillingPostalCode => '10021',
                    Account.BillingCountry => 'United States',
                    Account.BillingStreet => 'Broadway ' ,
                    Account.BillingState =>  'Texas' 
                    };
                        }
    }
    
    public class accountTeamDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            Account acc= getAccount;
            return new Map<Schema.SObjectField, Object> {                
                    NSP_Account_Team__c.NSP_Account__c => acc.Id,
                    NSP_Account_Team__c.NSP_User__c => userInfo.getUserId()
                    };
                        }
    }
    
    public class AccountGroupDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Account_Group__c.Name => 'Test New Acc Grp- 01',
                NSP_Account_Group__c.NSP_Tag__c =>'Test Account',
                NSP_Account_Group__c.NSP_Type__c => 'Account Health',
                NSP_Account_Group__c.NSP_Watchlist__c => true
            };
        }
    }

/*    public class AccountGroupDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Account_Group__c.Name => 'Test New Acc Grp- 01',
                NSP_Account_Group__c.NSP_Tag__c =>'Test Account',
                NSP_Account_Group__c.NSP_Type__c => 'Account Health',
                NSP_Account_Group__c.NSP_Watchlist__c => true
            };
        }
    } */

    public class LeadDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Lead.FirstName => 'John',
                    Lead.LastName => 'Doe',
                    Lead.Status => 'Inquiry',
                    Lead.Email => 'lead@silverlinecrm.test',
                    Lead.Company => 'Test',
                    Lead.PostalCode => '7080943',
                    Lead.Email => 'Mocktest@test.com'
                    };
                        }
    }
    
    public class CampaignDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Campaign.Name => 'Test Campaign'
                    };
                        }
    }
    
    public class OpportunityDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            Account acc= getAccount;
            return new Map<Schema.SObjectField, Object> {
                Opportunity.Name => 'Test Opportunity',
                    Opportunity.StageName => 'Closed Won',
                    Opportunity.CloseDate => Date.today(),
                    Opportunity.AccountId => acc.id,
                    Opportunity.stagename => 'Qualification',
                    Opportunity.CloseDate => date.today(),
                    Opportunity.NSP_Product_type__c => 'WO',
                    Opportunity.Type => 'CAMS',
                    Opportunity.NSP_Upsell_Product_add_ons__c => 'Retirement Services'
                    };
                        }
    }
    
    public class OpportunityLineItemDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            Opportunity opp= getOpportunity;
            PricebookEntry pbEntry = getPriceBookEntry;
            return new Map<Schema.SObjectField, Object> {
                OpportunityLineItem.PriceBookEntryId => pbEntry.id,
                    OpportunityLineItem.OpportunityId => opp.id,
                    OpportunityLineItem.Quantity => 2,
                    OpportunityLineItem.TotalPrice => 2*pbEntry.UnitPrice
                    };
                        }
    }
    
    public class PriceBookEntryDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            Product2 prod= getProduct;
            Id pricebookId = Test.getStandardPricebookId();
            return new Map<Schema.SObjectField, Object> {
                PricebookEntry.Pricebook2Id => pricebookId,
                    PricebookEntry.Product2Id => prod.Id,
                    PricebookEntry.UnitPrice => 100.00,
                    PricebookEntry.IsActive => true
                    };
                        }
    }
    
    public class ContactDefaultsLight implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Contact.FirstName => 'ResourceFN',
                    Contact.LastName => 'ResourceLN',
                    Contact.pse__Is_Resource__c => true,
                    Contact.pse__Is_Resource_Active__c => true
                    };
                        }
    }
    public class AdditionalPayrollContactDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Additional_Payroll_Contact__c.Contact_Type__c => 'Test'
                    
                    };
                        }
    }
    public class PayrollDataSheetDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Payroll__c.NSP_Additional_information__c => 'Test'
                    };
                        }
    }
    public class PTOSmartformDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_PTO_Smartform__c.Name => 'Test PTO Smartform '
                    };
                        }
    }
    
    
    public class UserDefaults implements FieldDefaults {
        
        Profile prof = [SELECT id from profile where name = 'System Administrator'];
         
        String orgId = UserInfo.getOrganizationId();
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                User.Username => 'uniqueName' + '@test' + orgId + '.org',
                    User.LastName =>'Bla',
                    User.Alias =>'sas',
                    User.TimeZoneSidKey => 'America/New_York',
                    User.LocaleSidKey => 'en_GB',
                    User.EmailEncodingKey => 'UTF-8',
                    User.ProfileId => (prof != null ? prof.id : null),
                    User.LanguageLocaleKey => 'en_US',
                    User.Email => 'testUser72732@insperity.com'
                    };
                        }
    }
    
    
    public class CollaborationGroupDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                CollaborationGroup.Name=>'Test Wins',
                    CollaborationGroup.CollaborationType=>'Private'
                    };
                        }
    }
    
    public class DocumentDefaults implements FieldDefaults {
        
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Document.Body => Blob.valueOf('Sample Text'),
                    Document.ContentType => 'application/pdf',
                    Document.DeveloperName => 'SampleTest_Document',
                    Document.IsPublic => true,
                    Document.Name => 'SampleTest_Document',
                    Document.FolderId => UserInfo.getUserId()
                    };
                        }
    }
    
    public class GroupDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Group.Name => 'Contact Center'
                    };
                        }
    }
    
    
    public class Pricebook2Defaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Pricebook2.Name => 'Sample Test Pricebook',
                    Pricebook2.isActive => true
                    };
                        }
    }
    
    public class CaseDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Case.Origin => 'Web',
                    Case.Status =>'Open',
                    Case.Reason => 'Administration Request',
                    Case.Subject => 'Test Subject',
                    Case.NSP_Case_Sub_Status__c => 'In Progress'
                    };
                        }
    }

    public class ServicePlanDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            return new Map<Schema.SObjectField, Object> {
                NSP_Service_Plan__c.Name => 'Test Service Plan'
                    };
                        }
    }
    
    public class TaskDefault implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Task.Subject=>'Donni',
                    Task.Status=>'Completed',
                    Task.Priority=>'Normal',
                    Task.OwnerId => UserInfo.getUserId()
                    };
                        }
    }
    
    
    public class AttachmentDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            Account acc = getAccount;
            
            return new Map<Schema.SObjectField, Object> {
                Attachment.name => String.valueOf('test.txt'),
                    Attachment.ContentType => 'contentType',
                    Attachment.Body => Blob.valueOf('Unit Test Attachment Body'),
                    Attachment.ParentId => acc.Id
                    };
                        }
    }
    
    public class ContentVersionDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                ContentVersion.title=>'ABC Test',
                    ContentVersion.PathOnClient =>'abc_test',
                    ContentVersion.VersionData =>Blob.valueOf('Test Content'),
                    ContentVersion.NSP_Signature_Date__c => System.today()
                    };
                        }
    }
    
    public class ContentDocumentLinkDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            ContentVersion contV = getContentVersion;
            
            Account acc = getAccount;
            
            return new Map<Schema.SObjectField, Object> {
                ContentDocumentLink.ShareType => 'V',
                    ContentDocumentLink.Visibility => 'InternalUsers',
                    ContentDocumentLink.ContentDocumentId => contV.ContentDocumentId,
                    ContentDocumentLink.LinkedEntityId => acc.id
                    };
                        }
    }
    
    public class FeedItemDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            Account acc = getAccount;
            
            return new Map<Schema.SObjectField, Object> {
                FeedItem.type => 'ContentPost',
                    FeedItem.Body => 'Hello',
                    FeedItem.ParentId => acc.Id
                    };
                        }
    }
    
    public class Product2Defaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Product2.Name => 'Sample Test Product Entry',
                    Product2.Description => 'Sample Test Product Entry',
                    Product2.isActive => true
                    };
                        }
    }
    
    public static Product2 getProduct {
        get {
            if ( getProduct == null ) {
                List<Product2> lstProd = [SELECT id, Name FROM Product2 LIMIT 1];
                if(lstProd.size() > 0){
                    getProduct = lstProd[0];
                }else{
                    getProduct = (Product2) NSP_TestDataFactory.createSObject(new Product2(), 'NSP_TestDataFactory.Product2Defaults', true);
                }
            }
            return getProduct;
        } private set;
    }
    
    public static PriceBookEntry getPriceBookEntry {
        get {
            if ( getPriceBookEntry == null ) {
                List<PriceBookEntry> lstPbEntry = [SELECT id, Name FROM PriceBookEntry LIMIT 1];
                if(lstPbEntry.size() > 0){
                    getPriceBookEntry = lstPbEntry[0];
                }else{
                    getPriceBookEntry = (PriceBookEntry) NSP_TestDataFactory.createSObject(new PriceBookEntry(), 'NSP_TestDataFactory.PriceBookENtryDefaults', true);
                }
            }
            return getPriceBookEntry;
        } private set;
    }
    
    public static Opportunity getOpportunity {
        get {
            if ( getOpportunity == null ) {
                List<Opportunity> lstOpps = [SELECT id, Name FROM Opportunity LIMIT 1];
                if(lstOpps.size() > 0){
                    getOpportunity = lstOpps[0];
                }else{
                    getOpportunity = (Opportunity) NSP_TestDataFactory.createSObject(new Opportunity(), 'NSP_TestDataFactory.OpportunityDefaults', true);
                }
            }
            return getOpportunity;
        } private set;
    }
    
    public static Account getAccount {
        get {
            if ( getAccount == null ) {
                List<Account> lstAccs = [SELECT id, Name FROM Account LIMIT 1];
                if(lstAccs.size() > 0){
                    getAccount = lstAccs[0];
                }else{
                    getAccount = (Account) NSP_TestDataFactory.createSObject(new Account(), 'NSP_TestDataFactory.AccountDefaults', true);
                }
            }
            return getAccount;
        } private set;
    }

    public static NSP_Account_Group__c getAccountGroup {
        get {
            if ( getAccountGroup == null ) {
                List<NSP_Account_Group__c> lstAccsGrps = [SELECT id, Name FROM NSP_Account_Group__c LIMIT 1];
                if(lstAccsGrps.size() > 0){
                    getAccountGroup = lstAccsGrps[0];
                }else{
                    getAccountGroup = (NSP_Account_Group__c) NSP_TestDataFactory.createSObject(new NSP_Account_Group__c(), 'NSP_TestDataFactory.AccountGroupDefaults', true);
                }
            }
            return getAccountGroup;
        } private set;
    }
    
    public static Asset getAsset {
        get {
            if ( getAsset == null ) {
                List<Asset> lAssets = [SELECT Id, Name FROM Asset LIMIT 1];
                if(lAssets.size() > 0){
                    getAsset = lAssets[0];
                }else{
                    getAsset = (Asset) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetDefaults', true);
                }
            }
            return getAsset;
        } private set;
    }
    
    public static NSP_Client_Sub_Plan_History__c getClientSubPlanHistory{
        get {
        if ( getClientSubPlanHistory == null ) {
            List<NSP_Client_Sub_Plan_History__c> lClientSubPlan = [SELECT 
                                Id, NSP_Plan_Subplan_Relationship__c, NSP_Asset__c, NSP_Current_Subplan__c  
                                FROM NSP_Client_Sub_Plan_History__c LIMIT 1];
            if(lClientSubPlan.size() > 0){
                getClientSubPlanHistory = lClientSubPlan[0];
            }else{
                getClientSubPlanHistory= (NSP_Client_Sub_Plan_History__c) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.ClientSubPlanHistoryDefaults', true);
            }
        }
        return getClientSubPlanHistory;
        } private set;
    }

    public static AssetRETEducationAssociation__c getAssetRETEducationAssociation{
        get {
        if ( getAssetRETEducationAssociation == null ) {
            List<AssetRETEducationAssociation__c> lAssetRETEducationAssociation = [SELECT 
                                Id, NSP_Education_Client__c, NSP_Status__c,
                                NSP_Subplan__c 
                                FROM AssetRETEducationAssociation__c LIMIT 1];
            if(lAssetRETEducationAssociation.size() > 0){
                getAssetRETEducationAssociation = lAssetRETEducationAssociation[0];
            }else{
                getAssetRETEducationAssociation = (AssetRETEducationAssociation__c) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.AssetRETEducationAssociationDefaults', true);
            }
        }
        return getAssetRETEducationAssociation;
        } private set;
    }

    public static NSP_Plan_SubPlan__c getSubPlan{
        get {
        if ( getSubPlan == null ) {
            List<NSP_Plan_SubPlan__c> lSubPlan = [SELECT 
                                Id, NSP_Subplan_Lead_Parent__c  
                                FROM NSP_Plan_SubPlan__c LIMIT 1];
            if(lSubPlan.size() > 0){
                getSubPlan = lSubPlan[0];
            }else{
                getSubPlan= (NSP_Plan_SubPlan__c) NSP_TestDataFactory.createSObject(new Asset(), 'NSP_TestDataFactory.SubPlanDefaults', true);
            }
        }
        return getSubPlan;
        } private set;
    }


    public static pse__Proj__c getProject {
        get {
            if ( getProject == null ) {
                List<pse__Proj__c> lstProject = [SELECT id, Name, pse__Project_Type__c FROM pse__Proj__c LIMIT 1 FOR UPDATE];
                if(lstProject.size() > 0){
                    getProject = lstProject[0];
                }else{
                    getProject = (pse__Proj__c) NSP_TestDataFactory.createSObject(new pse__Proj__c(), 'NSP_TestDataFactory.ProjectDefaults', true);
                }
            }
            return getProject;
        } private set;
    }
    
    public static WorkType getWorkType {
        get {
            if ( getWorkType == null ) {
                List<WorkType> listWorkTypes = [SELECT Id, ShouldAutoCreateSvcAppt FROM WorkType LIMIT 1 FOR UPDATE];
                if(listWorkTypes.size() > 0){
                    getWorkType = listWorkTypes[0];
                }else{
                    getWorkType = (WorkType) NSP_TestDataFactory.createSObject(new WorkType(), 'NSP_TestDataFactory.WorkTypeDefaults', true);
                }
            }
            return getWorkType;
        } private set;
    }
    
    public static pse__Project_Task__c getProjectTask {
        get {
            if ( getProjectTask == null ) {
                List<pse__Project_Task__c> lstProjTask = [SELECT id, Name FROM pse__Project_Task__c LIMIT 1 FOR UPDATE];
                if(lstProjTask.size() > 0){
                    getProjectTask = lstProjTask[0];
                }else{
                    getProjectTask = (pse__Project_Task__c) NSP_TestDataFactory.createSObject(new pse__Project_Task__c(), 'NSP_TestDataFactory.ProjectTaskDefaults', true);
                }
            }
            return getProjectTask;
        } private set;
    }
    
    public static ContentVersion getContentVersion {
        get {
            if ( getContentVersion == null ) {
                List<ContentVersion> lstContentVersion = [SELECT id,ContentDocumentId FROM ContentVersion LIMIT 1];
                if(lstContentVersion.size() > 0){
                    getContentVersion = lstContentVersion[0];
                }else{
                    getContentVersion = (ContentVersion) NSP_TestDataFactory.createSObject(new ContentVersion(), 'NSP_TestDataFactory.ContentVersionDefaults', true);
                }
            }
            return getContentVersion;
        } private set;
    }
    
    public class RegulatedAreaDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Regulated_Area__c.NSP_City__c => 'test city',
                    NSP_Regulated_Area__c.NSP_Start_Date__c => System.today(),
                    NSP_Regulated_Area__c.NSP_State__c => 'test state',
                    NSP_Regulated_Area__c.NSP_Zip_Code__c =>'1234567'
                    };
                        }
    }
    
    public class AccountTeamMemberDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            Account acc = getAccount;
            
            return new Map<Schema.SObjectField, Object> {
                NSP_Account_Team__c.NSP_User__c => UserInfo.getUserId(),
                    NSP_Account_Team__c.NSP_Role__c => 'Client Liaison',
                    NSP_Account_Team__c.NSP_Account__c => acc.Id
                    };
                        }
    }
    
    public class ProjectDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            Account acc = getAccount;
            
            return new Map<Schema.SObjectField, Object> {
                pse__Proj__c.Name => 'Test 1',
                    pse__Proj__c.pse__Is_Active__c => true,
                    pse__Proj__c.pse__Account__c => acc.Id
                    };
                        }
    }
    
    public class PlanDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            return new Map<Schema.SObjectField, Object> {
                NSP_Plan__c.NSP_Email__c => 'test@gmail.com'
                    }; 
                        }
    }
    
    
    public class SubPlanDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            return new Map<Schema.SObjectField, Object> {
                NSP_Plan_SubPlan__c.NSP_Subplan_ID__c => '123456789',
                    NSP_Plan_SubPlan__c.NSP_Status__c => NSP_ServiceConstants.STATUS_ACTIVE,
                    NSP_Plan_SubPlan__c.NSP_Plan_Effective_Date__c => System.today() - 1
                    };
                        }
    }

    public class SubPlanChangeHistoryDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            return new Map<Schema.SObjectField, Object> {
                NSP_Sub_Plan_Change_History__c.NSP_Auto_Deferral__c => 10,
                    NSP_Sub_Plan_Change_History__c.NSP_Plan_Effective_Date__c => System.today(),
                    NSP_Sub_Plan_Change_History__c.NSP_Status__c => 'Active',
                    NSP_Sub_Plan_Change_History__c.NSP_Plan_Type__c => '401k'
                    };
                        }
    }
    
    public class AssetDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            Account acc = getAccount;
            
            return new Map<Schema.SObjectField, Object> {
                Asset.Name => 'Asset1',
                    Asset.AccountId => acc.Id
                    };
                        }
    }
    
    public class SubClientDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            Account acc = getAccount;
            Asset oAsset = getAsset;
            return new Map<Schema.SObjectField, Object> {
                NSP_Sub_Client__c.Name => 'SubCliennt1',
                    NSP_Sub_Client__c.NSP_Account__c => acc.Id,
                    NSP_Sub_Client__c.NSP_Asset__c => oAsset.Id,
                    NSP_Sub_Client__c.NSP_Sub_Client__c => String.valueOf(Integer.valueOf((100000 * ( 1 -  1 * Math.random()))))
                    };
                        }
    }

    public static NSP_Sub_Client_Contact__c getSubClientContact {
        get {
            if ( getSubClientContact == null ) {
                List<NSP_Sub_Client_Contact__c> lstSubClientContact = [SELECT Id, Name FROM NSP_Sub_Client_Contact__c LIMIT 1 FOR UPDATE];
                if(lstSubClientContact.size() > 0){
                    getSubClientContact = lstSubClientContact[0];
                }else{
                    getSubClientContact = (NSP_Sub_Client_Contact__c) NSP_TestDataFactory.createSObject(new NSP_Sub_Client_Contact__c(), 'NSP_TestDataFactory.SubClientContactDefaults', true);
                }
            }
            return getSubClientContact;
        } private set;
    }

    public static NSP_Accrual_Profile__c getAccrualProfile {
        get {
            if ( getAccrualProfile == null ) {
                List<NSP_Accrual_Profile__c> listAccrualProfiles = [SELECT Id, NSP_Accrual_Profile_Plan_Name__c FROM NSP_Accrual_Profile__c WHERE Id!=null LIMIT 1 FOR UPDATE];
                if(listAccrualProfiles.size() > 0){
                    getAccrualProfile = listAccrualProfiles[0];
                }else{
                    getAccrualProfile = (NSP_Accrual_Profile__c) NSP_TestDataFactory.createSObject(new NSP_Accrual_Profile__c(), 'NSP_TestDataFactory.AccrualProfileDefaults', true);
                }
            }
            return getAccrualProfile;
        } private set;
    }

    public class SubClientContactDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Sub_Client_Contact__c.NSP_Employee_Status__c => 'PRIMED' ,
                NSP_Sub_Client_Contact__c.NSP_Background_Contact__c => True
            };
        }
    }
    public class AddressDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Address__c.NSP_Label_Code__c => 'Testing123',
                NSP_Address__c.NSP_Address_Type__c =>'Worksite',
                NSP_Address__c.Name => 'Test',
                NSP_Address__c.NSP_Label_Code__c => 'Testing123',
                NSP_Address__c.NSP_Address_Type__c => 'Worksite',
                NSP_Address__c.Name => 'Test',
                NSP_Address__c.NSP_Country__c => 'United States',
                NSP_Address__c.NSP_City__c => 'Chicago',
                NSP_Address__c.NSP_Postal_Code__c => '40065',
                NSP_Address__c.NSP_Street__c => 'Test',
                NSP_Address__c.NSP_State__c => 'NY',
                NSP_Address__c.NSP_Source__c => 'AIMS'
            };
        }
    }


    public class SubClientContactAddressDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Sub_Client_Contact_Address__c.NSP_Label_Code__c => 'Testing123',
                NSP_Sub_Client_Contact_Address__c.NSP_Source__c => 'AIMS'
            };
        }
    }
    
    public class ProjectTaskDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            return new Map<Schema.SObjectField, Object> {
                pse__Project_Task__c.Name => 'pTask1',
                    pse__Project_Task__c.pse__Long_Description__c => 'Testing WO & SA GERNERICS',
                    pse__Project_Task__c.pse__Start_Date_Time__c => DateTime.newInstance(2022,7,14,12,0,0),
                    pse__Project_Task__c.pse__End_Date_Time__c => DateTime.newInstance(2022,10,12,12,0,0),
                    pse__Project_Task__c.OwnerId => UserInfo.getUserId(),
                    pse__Project_Task__c.pse__Status__c => 'Not Started',
                    pse__Project_Task__c.NSP_Category__c => 'Client Implementation',
                    pse__Project_Task__c.NSP_Sub_Category__c => 'Configuration Call'
                    };
                        }
    }
    
    public class MileStoneDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                pse__Milestone__c.pse__Milestone__c.Name => 'PMilestone1',
                    pse__Milestone__c.pse__Milestone_Amount__c => 2000,
                    pse__Milestone__c.pse__Target_Date__c => System.today()
                    };
                        }
    }
    
    public class TerminationFormDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            pse__Project_Task__c pTask = getProjectTask;
            return new Map<Schema.SObjectField, Object> {
                NSP_Termination_Form__c.Name => 'TF1',
                    NSP_Termination_Form__c.NSP_Project_Task__c => pTask.Id
                    };
                        }
    }
    public class ProjectTaskAssignmentDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            pse__Project_Task__c pTask = getProjectTask;
            
            return new Map<Schema.SObjectField, Object> {
                pse__Project_Task_Assignment__c.pse__Project_Task__c => pTask.id
                    };
                        }
    }
    
    public class WorkTypeDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            return new Map<Schema.SObjectField, Object> {
                WorkType.Name => 'Generic',
                    WorkType.DurationType => NSP_ServiceConstants.durationType,
                    WorkType.ShouldAutoCreateSvcAppt => True,
                    WorkType.EstimatedDuration => 3
                    };
                        }
    }
    
    public class CatSubCatMappingDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            
            return new Map<Schema.SObjectField, Object> {
                NSP_Category_Sub_Category_Mapping__c.NSP_Category__c => 'Test Cat 1',
                    NSP_Category_Sub_Category_Mapping__c.NSP_Subcategory__c => 'Test Sub Cat 1',
                    NSP_Category_Sub_Category_Mapping__c.NSP_Detail__c => 'Test Detail 1',
                    NSP_Category_Sub_Category_Mapping__c.NSP_RecordType__c => 'BPS'
                    };
                        }
    }

    public class EligibilityDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Eligibility__c.NSP_Age__c => 5,
                NSP_Eligibility__c.NSP_Contribution_Description__c => 'Contribution Description'
            };
        }
    }

    public class EducationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_RET_Education__c.Name => 'Test Ret Edu'
            };
        }
    }

    public class AssetRETEducationAssociationDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                AssetRETEducationAssociation__c.NSP_Name__c => 'Test Ret Edu'
            };
        }
    }
    
    public class NSPNoteDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Note__c.Note_Type__c => 'Note'    
            };
        }
    }
    
    public class OrderDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Order.EffectiveDate => System.today(),
                Order.Status => 'Draft'    
            };
        }
    }
    
    
    public class ReportRequestDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
            	NSP_ReportRequest__c.NSP_Existing_NewReport__c => 'New Report',
        		NSP_ReportRequest__c.NSP_ReportName__c => 'Test Report',
        		NSP_ReportRequest__c.NSP_ReportType__c => 'Benefits',
        		NSP_ReportRequest__c.NSP_ReportLocation__c => 'Premier Reporting (WIRE)',
        		NSP_ReportRequest__c.NSP_AreThereAdditionalClients_subAccount__c => 'Yes',
        		NSP_ReportRequest__c.NSP_HowIsReportUsed__c => 'Test Use',
        		NSP_ReportRequest__c.NSP_NeedcolumnHeading__c => 'Test Heading',
        		NSP_ReportRequest__c.NSP_columsToBeTotaled__c => 'Test Column',
        		NSP_ReportRequest__c.NSP_HowToSort__c => 'Test Sorted',
        		NSP_ReportRequest__c.NSP_IsReportSeparatedbytheFirstSort__c => 'Yes on same page',
        		NSP_ReportRequest__c.NSP_OutputFormatToProduced__c => 'PDF'
            };
        }
    }

    public class fLSAMappingDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_BPA_Mapping__c.NSP_FLSA_Specialist__c => UserInfo.getUserId()
            };
        }
    }
    
    public class emailMessageDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                EmailMessage.Incoming => true,
                EmailMessage.ToAddress => 'test@xyz.com',
                EmailMessage.FromAddress => 'test@abc.com',    
                EmailMessage.Subject => 'Test email Subject',
                EmailMessage.HtmlBody => 'Test email body'
            };
        }
    }
    
    public class caseContactDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
        }
    }
    
    public class acrDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
                }
    }
    
    public class AccountGroupMemberDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
        }
    }
    
    public class FocusItemDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
                }
    }
    
     public class ImplementationProfileDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
                }
    }
    
    public class ImplementationProfileAutomationsDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
        }
    }
    
    public class ClientSubPlanHistoryDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {

            return new Map<Schema.SObjectField, Object> {
                NSP_Client_Sub_Plan_History__c.NSP_Start_Date__c => System.today()
                    };
        }
    }

    public class RegionDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
        }
    }

    public class PermissionControlDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
        }
    }

    public class AssignmentDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
                }
    }
    
    public class ScheduleDefaults implements FieldDefaults {
        
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {};
                }
    }

    public class EventDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                Event.newEvent.ActivityDateTime => system.today()
            };
        }
    }
    public class AccrualProfileDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            return new Map<Schema.SObjectField, Object> {
                NSP_Accrual_Profile__c.NSP_Accrual_Profile_Plan_Name__c => 'Test Accrual Profile' 
            };
        }
    }
    
    public class AccrualProfileAccountRelationshipDefaults implements FieldDefaults {
        public Map<Schema.SObjectField, Object> getFieldDefaults() {
            NSP_Accrual_Profile__c accProfile = getAccrualProfile;
            Account acc = getAccount;
            return new Map<Schema.SObjectField, Object> {
                NSP_Accrual_Profile_Account_Relationship__c.NSP_Accrual_Profile__c => accProfile.Id, 
                NSP_Accrual_Profile_Account_Relationship__c.NSP_Account__c => acc.Id  
            };
        }
    }
}