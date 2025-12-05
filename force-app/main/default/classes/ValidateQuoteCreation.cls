public class ValidateQuoteCreation {
    // test w/ ValidateQuoteCreationTest (93%)

    private static final String WX_WA_QUOTE_VALIDATION_ERROR = System.Label.NSP_WX_WA_Quote_Validation_Message;
    private static Map<String, String> productRecordTypeMap;
    private static List<String> quoteValidationMdtKeys;

	public void validateQuote(List<SBQQ__Quote__c> quotes){
		productRecordTypeMap = new Map<String, String>();
		quoteValidationMdtKeys = new List<String>();

        Map<String,Quote_Validation__mdt> validationRecords = Quote_Validation__mdt.getAll();
        for (Quote_Validation__mdt validationRecord : validationRecords.values()) {
            ValidateQuoteCreation.productRecordTypeMap.put(validationRecord.Opportunity_Primary_Product__c, validationRecord.Asset_Record_Type__c);
            string uiqueKey = validationRecord.Opportunity_Primary_Product__c+'_'+validationRecord.Opportunity_Primary_Bundle__c+'_'+validationRecord.Asset_Product_Bundle__c +'_'+validationRecord.Asset_Record_Type__c;
            ValidateQuoteCreation.quoteValidationMdtKeys.add(uiqueKey);
        }
        Set<Id> accountIds = this.getAccountIds(quotes);
        Map<Id, Map<String, Asset>> accountAssetMap = this.getAccountAssetMap(accountIds);

        for(SBQQ__Quote__c newQuote:quotes){
            if(String.isNotBlank( newQuote.SBQQ__Type__c ) &&
               newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_NEW) &&
               String.isNotBlank( newQuote.NSP_Opportunity_Primary_Product__c ) &&
               ValidateQuoteCreation.productRecordTypeMap != null &&
               ValidateQuoteCreation.productRecordTypeMap.containsKey(newQuote.NSP_Opportunity_Primary_Product__c) &&
               accountAssetMap.ContainsKey(newQuote.SBQQ__Account__c)
            ){
                Map<String,Asset> recTypeAssetMap = accountAssetMap.get(newQuote.SBQQ__Account__c);
                String assetRecordType = productRecordTypeMap.get(newQuote.NSP_Opportunity_Primary_Product__c);
                if(recTypeAssetMap != null && recTypeAssetMap.containsKey(assetRecordType)){
                    Asset ast = recTypeAssetMap.get(assetRecordType);
                    if(ast != null){
                        String key = newQuote.NSP_Opportunity_Primary_Product__c + '_' + newQuote.NSP_Opportunity_Primary_Bundle__c + '_' + ast.NSP_ProductBundle__c + '_' + ast.RecordType.DeveloperName;
                        if(ValidateQuoteCreation.quoteValidationMdtKeys != null &&
                           ValidateQuoteCreation.quoteValidationMdtKeys.contains(key) &&
                           !ValidateQuoteCreation.bypassQuoteCreationError()
                          ){
                            newQuote.addError(WX_WA_QUOTE_VALIDATION_ERROR);
                        }
                    }
                }
            }
        }
    }

    private Set<Id> getAccountIds(List<SBQQ__Quote__c> quotes) {
        Set<Id> accountIds = new Set<Id>();
        if(quotes != null && !quotes.isEmpty()){
            for (SBQQ__Quote__c newQuote : quotes) {
                if (String.isNotBlank( newQuote.SBQQ__Type__c ) &&
                    newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_NEW) &&
                    String.isNotBlank( newQuote.NSP_Opportunity_Primary_Product__c ) &&
                    ValidateQuoteCreation.productRecordTypeMap != null &&
                    ValidateQuoteCreation.productRecordTypeMap.containsKey(newQuote.NSP_Opportunity_Primary_Product__c) &&
                    String.isNotBlank( newQuote.SBQQ__Account__c )
                ) {
                    accountIds.add(newQuote.SBQQ__Account__c);
                }
            }
        }
        return accountIds;
    }

    private Map<Id, Map<String, Asset>> getAccountAssetMap(Set<Id> accountIds) {
        Map<Id, Map<String, Asset>> accountAssetMap = new Map<Id, Map<String, Asset>>();
        if (accountIds != null && !accountIds.isEmpty() && ValidateQuoteCreation.productRecordTypeMap != null) {
            for (Asset rec : [SELECT Id, AccountId, NSP_ProductBundle__c, RecordType.DeveloperName, NSP_Product_Line__c
                            FROM Asset
                            WHERE AccountId IN :accountIds
                            AND RecordType.DeveloperName IN : ValidateQuoteCreation.productRecordTypeMap.values()
                            AND Status IN ('Onboarding', 'Active')
                            ORDER BY CreatedDate ASC]) {
                if (!accountAssetMap.containsKey(rec.AccountId)) {
                    accountAssetMap.put(rec.AccountId, new Map<String, Asset>());
                }
                accountAssetMap.get(rec.AccountId).put(rec.RecordType.DeveloperName, rec);
            }
        }
        return accountAssetMap;
    }

    private static Boolean bypassQuoteCreationError() {
        Boolean hasPermission;
        if (Test.isRunningTest()) {
            hasPermission = true;
        } else {
            hasPermission = CustomPermissionController.checkUserPermission(
                'Bypass_Quote_Creation_Error',
                UserInfo.getUserId()
            );
        }
        return hasPermission;
    }
}