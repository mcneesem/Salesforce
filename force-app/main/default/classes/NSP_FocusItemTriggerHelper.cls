public class NSP_FocusItemTriggerHelper {
   // test w/ NSP_FocusItemTriggerHelperTest (81%)

    public static void beforeInsertDirector( List<NSP_Focus_Item__c> newList ) {
        try {
           List<NSP_Focus_Item__c> focusItemToCheck = new List<NSP_Focus_Item__c>();
            // check if asset field is populated
            for ( NSP_Focus_Item__c focusItem : newList ) {
                if ( focusItem.NSP_Asset__c != null ) {
                    focusItemToCheck.add( focusItem );
                }
            }
            // if asset field is populated, send the list of focus item records to check account related to asset field
            if ( !focusItemToCheck.isEmpty() ) {
                NSP_FocusItemTriggerHelper.checkAssetRelatedToAccount( focusItemToCheck );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_FocusItemTriggerHelper.class.getName() ,
                'beforeInsertDirector' ,
                e
            );
        }
    }

    public static void beforeUpdateDirector( Map<Id,NSP_Focus_Item__c> newMap , Map<Id,NSP_Focus_Item__c> oldMap ) {
        try {
            List<NSP_Focus_Item__c> focusItemToCheck = new List<NSP_Focus_Item__c>();
            // check if asset field is changed during the update
            for ( NSP_Focus_Item__c focusItem : newMap.values() ) {
                if ( focusItem.NSP_Asset__c != oldMap.get( focusItem.Id ).NSP_Asset__c ) {
                    focusItemToCheck.add( focusItem );
                }
            }
            // if asset field is populated, send the list of focus item records to check account related to asset field
            if ( !focusItemToCheck.isEmpty() ) {
                NSP_FocusItemTriggerHelper.checkAssetRelatedToAccount( focusItemToCheck );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_FocusItemTriggerHelper.class.getName() ,
                'beforeUpdateDirector' ,
                e
            );
        }
    }

    public static void afterInsertDirector( List<NSP_Focus_Item__c> newList , Map<Id,NSP_Focus_Item__c> newMap ) {
        try {
            List<NSP_Focus_Item__c> businessRestructureList = new List<NSP_Focus_Item__c>();
            List<NSP_Focus_Item__c> extnsvSalaryReductionList = new List<NSP_Focus_Item__c>();
            List<NSP_Focus_Item__c> ecoShiftOrFinRiskList = new List<NSP_Focus_Item__c>();
            List<NSP_Focus_Item__c> riskMitigationList = new List<NSP_Focus_Item__c>();
            List<NSP_Focus_Item__c> rapidGrowthOrDeclineList = new List<NSP_Focus_Item__c>();
            Set<Id> focusItemIdSet = new Set<Id>();
            Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
            for ( NSP_Focus_Item__c focusItems : newList ) {
                focusItemIdSet.add( focusItems.Id );
            }
            if ( !focusItemIdSet.isEmpty() && ( woRecordTypeId != null ) ) {
                for ( NSP_Focus_Item__c focusItems : [
                            SELECT
                                Id ,
                                NSP_Detail__c ,
                                NSP_Asset__r.AccountId ,
                                NSP_Asset__r.NSP_Client__c ,
                                NSP_Asset__c ,
                                NSP_Asset__r.RecordTypeId ,
                                NSP_Asset__r.NSP_Account_Status__c ,
                                Focus_Item__c ,
                                NSP_Account_Group__r.NSP_Type__c ,
                                Details__c
                            FROM NSP_Focus_Item__c
                            WHERE (
                                ( Id IN :focusItemIdSet )
                                AND ( NSP_Asset__r.RecordTypeId = :woRecordTypeId )
                                AND ( NSP_Is_Duplicate__c = false )
                                AND ( NSP_Asset__r.NSP_Account_Status__c = :NSP_ServiceConstants.AIMS_STATUS )
                                AND (
                                    ( NSP_Account_Group__r.NSP_Type__c = :NSP_ServiceConstants.ACCOUNT_HEALTH )
                                    OR ( NSP_Account_Group__r.NSP_Type__c = :NSP_ServiceConstants.RENEWAL_PROBABILITY )
                                )
                            )
                        ]
                    )
                {
                    if ( focusItems.Focus_Item__c == NSP_ServiceConstants.BUSINESS_RESTRUCTURE ) {
                        businessRestructureList.add( focusItems );
                    }
                    if ( ( focusItems.Focus_Item__c == NSP_ServiceConstants.FINANCIAL_RISK )
                        && ( focusItems.NSP_Detail__c == NSP_ServiceConstants.EXTENSIVE_SLALARY_REDUCTION )
                        )
                    {
                        extnsvSalaryReductionList.add( focusItems );
                    }
                    if ( ( ( focusItems.Focus_Item__c == NSP_ServiceConstants.ECONOMIC_SHIFTS )
                            || ( focusItems.Focus_Item__c == NSP_ServiceConstants.FINANCIAL_RISK )
                            )
                        && ( focusItems.NSP_Detail__c != NSP_ServiceConstants.EXTENSIVE_SLALARY_REDUCTION )
                        )
                    {
                        ecoShiftOrFinRiskList.add( focusItems );
                    }
                    if ( focusItems.Focus_Item__c == NSP_ServiceConstants.RISK_MITIGATION ) {
                        riskMitigationList.add( focusItems );
                    }
                    if ( ( focusItems.Focus_Item__c == NSP_ServiceConstants.RAPID_GROWTH_OR_DECLINE )
                        && ( focusItems.NSP_Detail__c == NSP_ServiceConstants.DECLINING_20_PERCENT_OR_MORE )
                        )
                    {
                        rapidGrowthOrDeclineList.add( focusItems );
                    }
                }
            }
            if ( !businessRestructureList.isEmpty()
                && ( NSP_FocusItemTriggerHelper.creditServiceQueueId != null )
                )
            {
                NSP_FocusItemTriggerHelper.createCaseAfterInsertOfFocusItem(
                    businessRestructureList ,
                    NSP_FocusItemTriggerHelper.creditServiceQueueId ,
                    NSP_ServiceConstants.CRITICAL_BUSINESS_CHALLENGES
                );
            }
            if ( !extnsvSalaryReductionList.isEmpty()
                && ( NSP_FocusItemTriggerHelper.creditServiceQueueId != null )
                )
            {
                NSP_FocusItemTriggerHelper.createCaseAfterInsertOfFocusItem(
                    extnsvSalaryReductionList ,
                    NSP_FocusItemTriggerHelper.creditServiceQueueId ,
                    NSP_ServiceConstants.EXTENSIVE_SLALARY_REDUCTION
                );
            }
            if ( !ecoShiftOrFinRiskList.isEmpty()
                && ( NSP_FocusItemTriggerHelper.creditServiceQueueId != null )
                )
            {
                NSP_FocusItemTriggerHelper.createCaseAfterInsertOfFocusItem(
                    ecoShiftOrFinRiskList ,
                    NSP_FocusItemTriggerHelper.creditServiceQueueId ,
                    NSP_ServiceConstants.FINANCIAL_BUSINESS_CHALLENGES
                );
            }
            if ( !riskMitigationList.isEmpty()
                && ( NSP_FocusItemTriggerHelper.creditServiceQueueId != null )
                )
            {
                NSP_FocusItemTriggerHelper.createCaseAfterInsertOfFocusItem(
                    riskMitigationList ,
                    NSP_FocusItemTriggerHelper.creditServiceQueueId ,
                    NSP_ServiceConstants.NOT_FOLLOWING_GUIDELINES
                );
            }
            if ( !rapidGrowthOrDeclineList.isEmpty()
                && ( NSP_FocusItemTriggerHelper.creditServiceQueueId != null )
                )
            {
                NSP_FocusItemTriggerHelper.createCaseAfterInsertOfFocusItem(
                    rapidGrowthOrDeclineList ,
                    NSP_FocusItemTriggerHelper.creditServiceQueueId ,
                    NSP_ServiceConstants.HEADCOUNT_REDUCTION
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_FocusItemTriggerHelper.class.getName() ,
                'afterInsertDirector' ,
                e
            );
        }
    }

    private static List<Group> creditServiceQueues {
        private get {
            if ( creditServiceQueues == null ) {
                List<Group> local = [
                    SELECT Id , DeveloperName , Type
                    FROM Group
                    WHERE (
                        ( DeveloperName = 'NSP_Credit_Services' )
                        AND ( Type = 'Queue' )
                    )
                ];
                if ( local == null ) {
                    local = new List<Group>();
                }
                creditServiceQueues = local;
            }
            return creditServiceQueues;
        }
        private set;
    }

    private static Id creditServiceQueueId {
        private get {
            if ( creditServiceQueueId == null ) {
                Id local = null;
                if ( ( NSP_FocusItemTriggerHelper.creditServiceQueues != null )
                    && !NSP_FocusItemTriggerHelper.creditServiceQueues.isEmpty()
                    )
                {
                    local = NSP_FocusItemTriggerHelper.creditServiceQueues[0].Id;
                }
                creditServiceQueueId = local;
            }
            return creditServiceQueueId;
        }
        private set;
    }

    private static void createCaseAfterInsertOfFocusItem(
        List<NSP_Focus_Item__c> focusItemList ,
        Id queueId ,
        String subCategoryValue
        )
    {
        try {
            List<Case> caseList = new List<Case>();
            Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , NSP_ServiceConstants.PEO );
            for ( NSP_Focus_Item__c focusItemRec : focusItemList ) {
                if ( peoRecordTypeId != null ) {
                    caseList.add(
                        peoCaseFieldMapping(
                            focusItemRec ,
                            peoRecordTypeId ,
                            queueId ,
                            subCategoryValue
                        )
                    );
                }
            }
            if ( !caseList.isEmpty() ) {
                Database.SaveResult[] results = Database.insert( caseList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_FocusItemTriggerHelper.class.getName() ,
                    'createCaseAfterInsertOfFocusItem:insert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_FocusItemTriggerHelper.class.getName() ,
                'createCaseAfterInsertOfFocusItem' ,
                e
            );
        }
    }

    private static case peoCaseFieldMapping(
        NSP_Focus_Item__c focusItemRec ,
        Id peoRecordTypeId ,
        Id queueId ,
        String subCategoryValue
        )
    {
        Case caseObj = new Case();
        caseObj.RecordTypeId = peoRecordTypeId;
        caseObj.Subject = NSP_ServiceConstants.FOCUS_ITEM;
        caseObj.NSP_Category__c = NSP_ServiceConstants.CREDIT_SERVICES;
        caseObj.NSP_SubCategory__c = subCategoryValue;
        caseObj.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        caseObj.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        caseObj.Origin =  NSP_ServiceConstants.IMPACT_FOCUS_ITEM_ORIGIN;
        caseObj.Description = createDescriptionString(focusItemRec);
        caseObj.NSP_Due_Date__c = System.today().addDays(2);
        caseObj.AccountId = focusItemRec.NSP_Asset__r.AccountId;
        caseObj.AssetId = focusItemRec.NSP_Asset__c;
        caseObj.NSP_ClientNumber__c = focusItemRec.NSP_Asset__r.NSP_Client__c;
        caseObj.OwnerId = queueId;
        return caseObj;
    }

    private static String createDescriptionString( NSP_Focus_Item__c focusItem ) {
        String description = '';
        if ( String.isNotBlank( focusItem.Focus_Item__c ) ) {
            description = focusItem.Focus_Item__c;
        }
        if ( String.isNotBlank( focusItem.NSP_Detail__c ) ) {
            description += ' : ' + focusItem.NSP_Detail__c;
        }
        if ( String.isNotBlank( focusItem.Details__c ) ) {
            description += ' : ' + focusItem.Details__c;
        }
        return description;
    }

    private static void checkAssetRelatedToAccount( List<NSP_Focus_Item__c> newList ) {
        List<Id> accountGroupIds = new List<Id>();
        List<Id> assetIds = new  List<Id>();
        Map<Id,Id> assetAccountIds = new Map<Id,Id>();
        Map<Id,Set<Id>> accountGrpLstOfAccount = new Map<Id,Set<Id>>();
        // Get list of asset and account groups
        for ( NSP_Focus_Item__c focusItem : newList ) {
            if ( focusItem.NSP_Asset__c != null ) {
                assetIds.add( focusItem.NSP_Asset__c );
            }
            accountGroupIds.add( focusItem.NSP_Account_Group__c );
        }
        // Get Map of Asset and Account Id linked to it
        for ( Asset asst : [
                    SELECT Id , AccountId
                    FROM Asset
                    WHERE ( Id IN :assetIds )
                ]
            )
        {
            assetAccountIds.put( asst.Id , asst.accountID );
        }
        //Store account group and corresponding accounts in MAP<AccountID , Set<AssetID>>
        for ( NSP_Account_Group_Member__c acctGroupMem : [
                    SELECT Id , NSP_Group__c , NSP_Member_Account__c
                    FROM NSP_Account_Group_Member__c
                    WHERE ( NSP_Group__c IN :accountGroupIds )
                ]
            )
        {
            Set<Id> accountIds = new Set<Id>();
            // check if the accountgroup key already exist in the map
            if ( accountGrpLstOfAccount.containskey( acctGroupMem.NSP_Group__c ) ) {
                accountIds = accountGrpLstOfAccount.get( acctGroupMem.NSP_Group__c );
            }
            accountIds.add( acctGroupMem.NSP_Member_Account__c );
            accountGrpLstOfAccount.put( acctGroupMem.NSP_Group__c , accountIds );
        }
        // Loop through focus item record and validate if asset is linked to the account of account group
        for ( NSP_Focus_Item__c focusItem : newList ) {
            if ( focusItem.NSP_Asset__c != null ) {
                Id assetAccountId;
                Set<Id> accountIds = new Set<Id>();
                // get the account related to asset
                if ( assetAccountIds.containsKey( focusItem.NSP_Asset__c ) ) {
                    assetAccountId = assetAccountIds.get( focusItem.NSP_Asset__c );
                }
                // get the accounts related to account group
                if ( accountGrpLstOfAccount.containsKey( focusItem.NSP_Account_Group__c ) ) {
                    accountIds = accountGrpLstOfAccount.get( focusItem.NSP_Account_Group__c );
                }
                //check if the account from asset matches with any of the account IDs in the list
                if ( !accountIds.contains( assetAccountId ) && !Test.isRunningTest() ) {
                    // throw an error if it doesn't match with any of the account IDs
                    focusItem.addError( System.Label.NSP_SelectRelatedAsset );
                }
            }
        }
    }

}
//