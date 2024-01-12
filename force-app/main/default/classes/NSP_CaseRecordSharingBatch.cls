/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  October 18, 2022                                                             
Function             :  Represents the NSP_CaseRecordSharingBatch which handles all the logic that is related case sharing based on category/SubCategory Mapping public group field.
Test class           :  NSP_CaseRecordSharingBatchTest
Story                : STY-03293                                                                      
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  
***************************************************************************************************/
public class NSP_CaseRecordSharingBatch implements Database.Batchable < sObject > {
    
    public static Map<string, Id> grpNameGrpIdMap;
    public static Map<string, List<String>> catSubCatGroupNamesMap;
    public static Map<string, List<String>> catSubCatDetailGroupNamesMap;
    public static final Id PEO_RECORDTYPEID = SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PEO').getRecordTypeId();
    public static final string NSP_CASERECORDSHARINGBATCH = 'NSP_CaseRecordSharingBatch';
    public String createdByUserId;
    public Boolean isMigratedCase;
    
    public NSP_CaseRecordSharingBatch(string createdByUserId, Boolean isMigratedCase ){
        this.createdByUserId = createdByUserId;
        this.isMigratedCase = isMigratedCase; 
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc) {     

        if(this.isMigratedCase){
           return getMigrateCaseQueryLocator();
        }
        return getCaseQueryLocator();
    }

    private Database.QueryLocator getMigrateCaseQueryLocator(){

        String query = 'SELECT Id, NSP_Confidential__c, NSP_Category__c, NSP_SubCategory__c,'; 
        query += 'NSP_Detail__c FROM Case WHERE NSP_Confidential__c = true AND';
        query += ' NSP_Category__c != null AND (NSP_Case_External_Id__c != null OR NSP_NetSuite_External_ID__c != null ';
        query += 'OR NSP_OneVoice_External_ID__c != null) AND';
        query += ' CreatedDate = Today AND CreatedById =: createdByUserId';

        return Database.getQueryLocator(query);

    }

    private Database.QueryLocator getCaseQueryLocator(){

        String query = 'SELECT Id, NSP_Confidential__c, NSP_Category__c, NSP_SubCategory__c,'; 
        query += 'NSP_Detail__c FROM Case WHERE NSP_Confidential__c = true AND';
        query += ' NSP_Category__c != null AND NSP_SubCategory__c != null AND recordTypeId =: PEO_RECORDTYPEID AND';
        query += ' CreatedDate = Today AND CreatedById =: createdByUserId';

        return Database.getQueryLocator(query);

    }
      /**
* @MethodName: execute
* @Description: This method describes about Sharing of case to public group based on category/SubCategory Mapping.
* @param : List<Case> caseList
* @createdDate : 10/18/2022
* @Story : STY-03293
* @return void                          
*/
    public void execute(Database.BatchableContext bc, List < Case > caseList) {
        Set<String> categorySet = new Set<String>();
        Set<String> subCategorySet = new Set<String>();
        for(Case cse : caseList){
            categorySet.add(cse.NSP_Category__c);
            subCategorySet.add(cse.NSP_SubCategory__c); 
        }
        if(this.isMigratedCase){
            NSP_CaseRecordSharing.shareMigratedCase(caseList, categorySet, subCategorySet);
        }
        else{
            NSP_CaseRecordSharing.shareCaseOnUpdate(caseList, false, categorySet, subCategorySet);
        }
    }
    
        /**
* @MethodName: finish
* @Description: This method describes about the finish method when the execution of batch completes.
* @param : 
* @createdDate : 10/18/2022
* @Story : STY-03293
* @return void                          
*/
    public void finish(Database.BatchableContext bc) {
        
    }
    
}