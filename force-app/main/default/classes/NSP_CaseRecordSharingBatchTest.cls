/**
Apex Class Name      :  NSP_CaseRecordSharingBatchTest
Version              :  1.0  
Author               :  Teja Mani                                                                        
Created Date         :   October 18, 2022    
Function             :   Represents test class for NSP_CaseRecordSharingBatch
Story                :          STY-03293                                                            
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
*/
@isTest
public class NSP_CaseRecordSharingBatchTest {
    
 public static final String CASEDEFAULTS = 'NSP_TestDataFactory.CaseDefaults';
    public static final Id PEO_RECORDTYPEID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
    @testSetup
    static void testData() {
        
        NSP_Category_Sub_Category_Mapping__c newCat = (NSP_Category_Sub_Category_Mapping__c)NSP_TestExtendedDataFactory.createSObject(new NSP_Category_Sub_Category_Mapping__c(), 'NSP_TestDataFactory.CatSubCatMappingDefaults', false);
        newCat.NSP_UserTitle__c = 'Benefits Manager';
        newCat.NSP_Category__c = 'Ben Service - Claims';
        newCat.NSP_Subcategory__c = 'Commuter';
        newCat.NSP_Detail__c = 'Login';
        newCat.NSP_isActive__c=True;
        newCat.NSP_Asset_Record_Types__c='WO';
        newCat.NSP_RecordType__c='PEO';
        newCat.NSP_Public_Groups_To_Share__c = 'All Data Visibility'; 
        Database.insert(newCat);
    
        //Creating list which stores case records
            Case case1 = (Case)NSP_TestExtendedDataFactory.createSObject(new Case(), CASEDEFAULTS, false);
            case1.NSP_Category__c =  NSP_ServiceConstants.BEN_SERVICE_CLAIMS;
            case1.NSP_Subcategory__c = 'Commuter';
            case1.NSP_Confidential__c = true;
            case1.recordTypeId = PEO_RECORDTYPEID;
            case1.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        	case1.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
            //inserting case 
            Database.insert(case1);
    }
    /**
* @Description: This test method is used to cover insertion of sharing records
* @Created date: 08/23/2022. 
* @return void             
*     */
    @isTest
    public static void insertConfidentialCase(){ 
        //Creating list case records 
        List<String> caseFields = new List<String>{'Id','Subject','NSP_SubCategory__c','recordTypeId', 'NSP_Confidential__c', 'recordType.DeveloperName'};
            String caseQaquery = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('NSP_Category__c', NSP_ServiceConstants.BEN_SERVICE_CLAIMS ).addLimit(1).build();
        Case getCase = Database.query(caseQaquery);
        Test.startTest();
        NSP_CaseRecordSharingBatch obj = new NSP_CaseRecordSharingBatch(userInfo.getUserId(), false);
        DataBase.executeBatch(obj);
        Test.stopTest();
        system.assertEquals(getCase.NSP_Confidential__c, true);
    }
    
      /**
* @Description: This test method is used to cover insertion of sharing records for migrated case
* @Created date: 01/20/2023.
* @return void             
*     */
    @isTest
    public static void insertMigratedConfidentialCase(){ 
        //Creating list case records 
        List<String> caseFields = new List<String>{'Id','Subject','NSP_SubCategory__c','recordTypeId', 'NSP_Confidential__c', 'recordType.DeveloperName'};
            String caseQaquery = new NSP_QueryBuilder('Case', caseFields)
            .addFilter('NSP_Category__c', NSP_ServiceConstants.BEN_SERVICE_CLAIMS ).addLimit(1).build();
        Case getCase = Database.query(caseQaquery);
        Test.startTest();
        NSP_CaseRecordSharingBatch obj = new NSP_CaseRecordSharingBatch(userInfo.getUserId(), true);
        DataBase.executeBatch(obj);
        Test.stopTest();
        system.assertEquals(getCase.NSP_Confidential__c, true);
    }
}