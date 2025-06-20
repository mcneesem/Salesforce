// Returns the Case Guidance value from Categroy Sub Category Mapping record based on the Case Record's Id, Category, Sub Category, Detail.
public with sharing class CaseGuidanceController {
    // test W/ CaseGuidanceControllerTest (100%)

    //== Get Custom Setting values
    @AuraEnabled(cacheable=true)
    public static Case_Guidance_Setting__c getCaseGuidanceSetting() {
        return Case_Guidance_Setting__c.getInstance( UserInfo.getUserId() );
    }

    //== Get Case Guidance based on Case Id
    @AuraEnabled(cacheable=true)
    public static String getCaseGuidance( Id caseId ) {
        String guidance = '';
        Case caseRecord = CaseGuidanceController.getCaseRecord( caseId );
        if ( ( caseRecord != null )
            && String.isNotBlank( caseRecord.NSP_Category__c )
            && String.isNotBlank( caseRecord.NSP_SubCategory__c )
            )
        {
            NSP_Category_Sub_Category_Mapping__c categorySubCategoryRecord = CaseGuidanceController.getCategorySubCategoryRecord( caseRecord );
            if ( categorySubCategoryRecord != null ) {
                guidance = categorySubCategoryRecord.Case_Guidance__c;
            }
        }
        return guidance;
    }

    //== Method to return the case record based on case record Id
    private static Case getCaseRecord( Id caseId ) {
        Case caseRecord = null;
        if ( caseId != null ) {
            List<Case> caseRecords = [
                SELECT Id , NSP_Category__c , NSP_SubCategory__c , NSP_Detail__c
                FROM Case
                WHERE ( Id = :caseId )
            ];
            if ( !caseRecords?.isEmpty() ) {
                caseRecord = caseRecords?.get( 0 );
            }
        }
        return caseRecord;
    }

    //== Method to return the Category Sub Categroy Mapping based on Case Record Values
    private static NSP_Category_Sub_Category_Mapping__c getCategorySubCategoryRecord( Case caseRecord ) {
        NSP_Category_Sub_Category_Mapping__c categorySubCategoryRecord = null;
        if ( caseRecord != null ) {
            List<NSP_Category_Sub_Category_Mapping__c> categorySubCategoryRecords = [
                SELECT Id , Case_Guidance__c
                FROM NSP_Category_Sub_Category_Mapping__c
                WHERE (
                    ( NSP_Category__c = :caseRecord.NSP_Category__c )
                    AND ( NSP_Subcategory__c = :caseRecord.NSP_SubCategory__c )
                    AND ( NSP_Detail__c = :caseRecord.NSP_Detail__c )
                )
                LIMIT 1
            ];
            if ( !categorySubCategoryRecords?.isEmpty() ) {
                categorySubCategoryRecord = categorySubCategoryRecords?.get( 0 );
            }
        }
        return categorySubCategoryRecord;
    }

}
//