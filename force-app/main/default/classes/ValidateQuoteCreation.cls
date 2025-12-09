public with sharing class ValidateQuoteCreation {
    // test w/ ValidateQuoteCreationTest (93%)

    public void validateQuote(List<SBQQ__Quote__c> quotes){
        Set<Id> accountIds = this.getAccountIds(quotes);
        Map<Id, Map<String, Asset>> accountAssetMap = this.getAccountAssetMap(accountIds);

        for(SBQQ__Quote__c newQuote:quotes){
            if(this.isValidQuote(newQuote) && accountAssetMap != null && accountAssetMap.containsKey(newQuote.SBQQ__Account__c)){
                validateQuoteAgainstAssets(newQuote, accountAssetMap.get(newQuote.SBQQ__Account__c));
            }
        }
    }

    private void validateQuoteAgainstAssets(SBQQ__Quote__c newQuote, Map<String, Asset> recTypeAssetMap){
        if(newQuote != null){
            String assetRecordType = ValidateQuoteCreation.productRecordTypeMap.get(newQuote.NSP_Opportunity_Primary_Product__c);
            if(recTypeAssetMap != null && recTypeAssetMap.containsKey(assetRecordType)){
                Asset ast = recTypeAssetMap.get(assetRecordType);
                if(ast != null){
                    String key = newQuote.NSP_Opportunity_Primary_Product__c + '_' + newQuote.NSP_Opportunity_Primary_Bundle__c + '_' + ast.NSP_ProductBundle__c + '_' + ast.RecordType.DeveloperName;
                    if(ValidateQuoteCreation.quoteValidationMdtKeys != null &&
                        ValidateQuoteCreation.quoteValidationMdtKeys.contains(key) &&
                        !ValidateQuoteCreation.hasBypassQuoteCreationError
                    ){
                        newQuote.addError(System.Label.NSP_WX_WA_Quote_Validation_Message);
                    }
                }
            }
        }
    }

    private Boolean isValidQuote(SBQQ__Quote__c newQuote) {
        Boolean value = false;
        if(newQuote != null){
            value = String.isNotBlank( newQuote.SBQQ__Type__c ) &&
               		newQuote.SBQQ__Type__c.equals(NSP_CPQConstants.QUOTE_TYPE_NEW) &&
                    String.isNotBlank( newQuote.SBQQ__Account__c ) &&
                    String.isNotBlank( newQuote.NSP_Opportunity_Primary_Product__c ) &&
                    ValidateQuoteCreation.productRecordTypeMap != null &&
                    ValidateQuoteCreation.productRecordTypeMap.containsKey(newQuote.NSP_Opportunity_Primary_Product__c);
        }
        return value;
    }

    private static Boolean hasBypassQuoteCreationError {
        private get {
            if ( hasBypassQuoteCreationError == null ) {
               if (Test.isRunningTest()) {
                    hasBypassQuoteCreationError = true;
                } else {
                    hasBypassQuoteCreationError = CustomPermissionController.checkUserPermission(
                        'Bypass_Quote_Creation_Error',
                        UserInfo.getUserId()
                    );
                }
            }
            return hasBypassQuoteCreationError;
        }
        private set;
    }

    private static Map<String, Quote_Validation__mdt> validationRecords {
        private get {
            if (validationRecords == null) {
                validationRecords = new Map<String, Quote_Validation__mdt>();
                for (Quote_Validation__mdt record : Quote_Validation__mdt.getAll().values()) {
                    validationRecords.put(record.Id, record);
                }
            }
            return validationRecords;
        }
        private set;
    }

    private static Map<String, String> productRecordTypeMap {
        private get {
            if (productRecordTypeMap == null) {
                Map<String, String> local = new Map<String, String>();
                for (Quote_Validation__mdt validationRecord : ValidateQuoteCreation.validationRecords.values()) {
                    local.put(validationRecord.Opportunity_Primary_Product__c, validationRecord.Asset_Record_Type__c);
                }
                productRecordTypeMap = local;
            }
            return productRecordTypeMap;
        }
        private set;
    }

    private static List<String> quoteValidationMdtKeys {
        private get {
            if ( quoteValidationMdtKeys == null ) {
                List<String> local = new List<String>();
                for (Quote_Validation__mdt validationRecord : ValidateQuoteCreation.validationRecords.values()) {
                    string uniqueKey = validationRecord.Opportunity_Primary_Product__c+'_'
                                      +validationRecord.Opportunity_Primary_Bundle__c+'_'
                                      +validationRecord.Asset_Product_Bundle__c +'_'
                                      +validationRecord.Asset_Record_Type__c;
                    local.add(uniqueKey);
                }
                quoteValidationMdtKeys = local;
            }
            return quoteValidationMdtKeys;
        }
        private set;
    }

    private Set<Id> getAccountIds(List<SBQQ__Quote__c> quotes) {
        Set<Id> accountIds = new Set<Id>();
        if(quotes != null && !quotes.isEmpty()){
            for (SBQQ__Quote__c newQuote : quotes) {
                if (this.isValidQuote( newQuote )) {
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
}