/**
 * Author               : Prakash Jada
 * Created Date         : June 12, 2025
 * Description          : Returns the Case Guidance value from Categroy Sub Category Mapping record 
 *                      : based on the Case Record's Id, Category, Sub Category, Detail.
 * Last Modified Date   : 
 */

public with sharing class CaseGuidanceController {
    // Test W/ CaseGuidanceControllerTest (100%)

    @AuraEnabled(cacheable = true)
    //== Get Custom Setting values
    public static Case_Guidance_Setting__c getCaseGuidanceSetting()
    {
        Case_Guidance_Setting__c caseGuidanceSetting = Case_Guidance_Setting__c.getInstance(UserInfo.getUserId());
        return caseGuidanceSetting;
    }
    
    @AuraEnabled(cacheable = true)
    //== Get Case Guidance based on Case Id
    public static string getCaseGuidance(Id caseId)
    {
        
        string guidance = '';
        Case caseRecord = getCaseRecord(caseId);

        if(caseRecord?.NSP_Category__c != null && caseRecord?.NSP_SubCategory__c != null)
        {
            NSP_Category_Sub_Category_Mapping__c categorySubCategoryRecord = getCategorySubCategoryRecord(caseRecord);

            if(categorySubCategoryRecord != null)
            {
                guidance = categorySubCategoryRecord.Case_Guidance__c;
            }
        }
        
        return guidance;
    }

    /** ******************************* QUERIES ************************************* */
    //== Method to return the case record based on case record Id
    private static Case getCaseRecord(Id caseId)
    {
        Case caseRecord = new Case();
        if(caseId != null)
        {
            List<Case> caseRecords = [SELECT ID, NSP_Category__c, NSP_SubCategory__c, NSP_Detail__c 
            FROM 
            Case 
            WHERE 
            ID = : caseId
            ];

            caseRecord = caseRecords?.get(0);
        }

         return caseRecord;
    }

    //== Method to return the Category Sub Categroy Mapping based on Case Record Values
    private static NSP_Category_Sub_Category_Mapping__c getCategorySubCategoryRecord( Case caseRecord)
    {
        NSP_Category_Sub_Category_Mapping__c categorySubCategoryRecord = new NSP_Category_Sub_Category_Mapping__c();
        if(caseRecord != null)
        {            
            List<NSP_Category_Sub_Category_Mapping__c> categorySubCategoryRecords = [SELECT Id, Case_Guidance__c 
            FROM 
            NSP_Category_Sub_Category_Mapping__c 
            WHERE 
            NSP_Category__c = : caseRecord.NSP_Category__c 
            AND 
            NSP_Subcategory__c = : caseRecord.NSP_SubCategory__c 
            AND 
            NSP_Detail__c = : caseRecord.NSP_Detail__c 
            LIMIT 1
            ];
            
            categorySubCategoryRecord = categorySubCategoryRecords?.get(0);
        }

         return categorySubCategoryRecord;
    }
}