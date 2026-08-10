public without sharing class NSP_AccountGroupFocusItemsBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> {
    // test w/ NSP_AccountGroupFocusItemsBatch_Test (80%)

    private Map<String,Integer> accGrpWithFocusItem = new Map<String,Integer>();
    private Map<String,NSP_Focus_Item__c> accGrpWithFocusItemActive = new Map<String,NSP_Focus_Item__c>();
    private Map<String,Integer> accGrpWithFocusItemNSP = new Map<String,Integer>();
    private Map<String,NSP_Focus_Item__c> accGrpWithFocusItemActiveNSP = new Map<String,NSP_Focus_Item__c>();
    private Map<String,String> accIdWithAimsClient = new Map<String,String>();
    private Map<String,String> noInsperityAccIdWithAimsClient = new Map<String,String>();
    private Map<String,String> noNSPAccIdWithAimsClient = new Map<String,String>();
    private List<NSP_Focus_Item__c> lstFocusItems = new List<NSP_Focus_Item__c>();
    private Map<String,List<String>> grpIdWithAccId = new Map<String,List<String>>();
    private Set<Id> accountIds = new Set<Id>();
    private List<String> focusItemStatus = new List<String>{
        NSP_ServiceConstants.STATUS_ACTIVE ,
        NSP_ServiceConstants.CLOSED_STATUS
    };

    //
    // Argument-free constructor is required to be "runnable"
    //

    public NSP_AccountGroupFocusItemsBatch() {
    }

    //
    // ISelfSchedulable
    //

    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_AccountGroupFocusItemsBatch ~ monthly at 11 PM' + suffix ,
            '0 0 23 1 * ?' ,
            new NSP_AccountGroupFocusItemsBatch()
        );
    }

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        return Database.executeBatch( new NSP_AccountGroupFocusItemsBatch() , 200 );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            [
                SELECT
                    Id ,
                    Name ,
                    NSP_Type__c ,
                    NSP_Account__c ,
                    NSP_Tag__c ,
                    NSP_Group_Member_Count__c ,
                    (
                        SELECT
                            Id ,
                            NSP_Member_Account__c
                        FROM Account_Group_Members__r
                    ) ,
                    (
                        SELECT
                            Id ,
                            Focus_Item__c ,
                            NSP_Status__c ,
                            NSP_Detail__c
                        FROM Focus_Items__r
                        WHERE ( NSP_Status__c != 'Closed' )
                    )
                FROM NSP_Account_Group__c
                WHERE (
                    ( NSP_Group_Member_Count__c > 0 )
                    AND (
                        NSP_Type__c IN (
                            'Account Health' ,
                            'Renewal Probability'
                        )
                    )
                )
            ]
        );
    }

    public void execute( Database.BatchableContext bc , List<NSP_Account_Group__c> scope ) {
        if ( ( scope != null ) && !scope.isEmpty() ) {
            try {
                this.checkForAccountGroups( scope );
                this.checkForAssets();
                this.checkForFocusItems( scope );
                this.insertFocusItems();
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_AccountGroupFocusItemsBatch.class.getName() ,
                   'execute' ,
                   e
                );
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

    //
    //
    //

    // check for FocusItems that matches with Account Groups
    private void checkForFocusItems( List<NSP_Account_Group__c> lstAccGrps ) {
        if ( ( lstAccGrps != null ) && !lstAccGrps.isEmpty() ){
             for ( NSP_Account_Group__c accGrp : lstAccGrps ) {
                List<String> lstAIMS = this.checkForAIMS(
                    accGrp.Id ,
                    this.grpIdWithAccId ,
                    this.accIdWithAimsClient
                );
                List<String> noInsperityAIMSClient = this.checkForAIMS(
                    accGrp.Id ,
                    this.grpIdWithAccId ,
                    this.noInsperityAccIdWithAimsClient
                );
                List<String> noNSPAccIdWithAims = this.checkForAIMS(
                    accGrp.Id ,
                    this.grpIdWithAccId ,
                    this.noNSPAccIdWithAimsClient
                );
                this.checkEarlyTenureFocusItems( accGrp.Id, lstAIMS );
                this.checkNoInsperity401kFocusItems(
                    accGrp.Id ,
                    noInsperityAIMSClient ,
                    noNSPAccIdWithAims
                );
            }
        }
    }

    private void checkEarlyTenureFocusItems( Id accGrpId , List<String> lstAIMS ) {
        if ( accGrpId != null ) {
            if( ( lstAIMS != null ) && !lstAIMS.isEmpty() ) {
                if ( this.accGrpWithFocusItem.containsKey( accGrpId )
                    && ( this.accGrpWithFocusItem.get( accGrpId ) == 0 )
                    )
                {
                    // 1) Create NEW focus item when none exists and AIMS list is present
                    this.lstFocusItems.add(
                        this.prepareFocusItem(
                            lstAIMS ,
                            accGrpId ,
                            NSP_ServiceConstants.EARLY_TENURE ,
                            NSP_ServiceConstants.EARLY_TENURE_CLIENT ,
                            NSP_ServiceConstants.UNFAVORABLE ,
                            NSP_ServiceConstants.FOCUS_COMMENTS
                        )
                    );
                } else if ( this.accGrpWithFocusItemActive.containsKey( accGrpId )
                    && ( this.accGrpWithFocusItemActive.get( accGrpId ) != null )
                    )
                {
                    // 2) Update existing ACTIVE focus item when AIMS list is present
                    NSP_Focus_Item__c focusItem = this.accGrpWithFocusItemActive.get( accGrpId );
                    focusItem.Details__c = NSP_ServiceConstants.FOCUS_COMMENTS + ' [' + String.join( lstAIMS , ',' ) + ']';
                    this.lstFocusItems.add( focusItem );
                }
            } else if ( this.accGrpWithFocusItemActive.containsKey(accGrpId)
                && ( this.accGrpWithFocusItemActive.get(accGrpId) != null )
                )
            {
                // 3) Close existing ACTIVE focus item when AIMS list is empty
                NSP_Focus_Item__c focusItem = this.accGrpWithFocusItemActive.get(accGrpId);
                focusItem.NSP_Estimated_Impact__c = NSP_ServiceConstants.NEUTRAL;
                focusItem.Details__c = null;
                focusItem.NSP_Status__c = NSP_ServiceConstants.CLOSED_STATUS;
                focusItem.NSP_End_Date__c = System.today();
                this.lstFocusItems.add( focusItem );
            }
        }
    }

    private void checkNoInsperity401kFocusItems(
        Id accGrpId ,
        List<String> noInsperityAIMSClient ,
        List<String> noNSPAccIdWithAims
        )
    {
        if ( ( accGrpId != null )
            && ( noInsperityAIMSClient != null )
            && !noInsperityAIMSClient.isEmpty()
            )
        {
             // 1) Create NEW focus item when none exists and AIMS list is present
            if ( this.accGrpWithFocusItemNSP.containsKey( accGrpId )
                && ( this.accGrpWithFocusItemNSP.get( accGrpId ) == 0 )
                )
            {
                this.lstFocusItems.add(
                    this.prepareFocusItem(
                        noInsperityAIMSClient ,
                        accGrpId ,
                        NSP_ServiceConstants.NO_INSPERITY_401K ,
                        '' ,
                        NSP_ServiceConstants.SOME_WHAT_UNFAVORABLE ,
                        NSP_ServiceConstants.FOCUS_401_COMMENTS
                    )
                );
            } else if ( this.accGrpWithFocusItemActiveNSP.containsKey( accGrpId )
                && ( this.accGrpWithFocusItemActiveNSP.get( accGrpId ) != null )
                )
            {
                // 2) Update existing ACTIVE focus item when AIMS list is present
                NSP_Focus_Item__c focusItem = this.accGrpWithFocusItemActiveNSP.get( accGrpId );
                focusItem.Details__c = ''
                    + NSP_ServiceConstants.FOCUS_401_COMMENTS
                    + ' ['
                    + String.join( noInsperityAIMSClient , ',' )
                    + ']';
                this.lstFocusItems.add( focusItem );
            }
        } else if ( ( accGrpId != null )
            && this.accGrpWithFocusItemActiveNSP.containsKey( accGrpId )
            && ( this.accGrpWithFocusItemActiveNSP.get( accGrpId ) != null )
            && ( noNSPAccIdWithAims != null )
            && !noNSPAccIdWithAims.isEmpty()
            )
        {
            // 3) Close existing ACTIVE focus item based on your original condition
            NSP_Focus_Item__c focusItem = this.accGrpWithFocusItemActiveNSP.get( accGrpId );
            focusItem.NSP_Estimated_Impact__c = NSP_ServiceConstants.NEUTRAL;
            focusItem.Details__c = null;
            focusItem.NSP_Status__c = NSP_ServiceConstants.CLOSED_STATUS;
            focusItem.NSP_End_Date__c = System.today();
            this.lstFocusItems.add( focusItem );
        }
    }

    // check whether asset is associate with account Group Member
    private List<String> checkForAIMS(
        Id accGrpId ,
        Map<String,List<String>> grpIdWithAccId ,
        Map<String,String> accIdWithAimsClient
        )
    {
        List<String> lstAIMS = new List<String>();
        if ( ( grpIdWithAccId != null )
            && !grpIdWithAccId.isEmpty()
            && ( accGrpId != null )
            && ( accIdWithAimsClient != null )
            && !accIdWithAimsClient.isEmpty()
            )
        {
            for ( String accId : grpIdWithAccId.get( accGrpId ) ) {
                if ( accIdWithAimsClient.containsKey( accId )
                    && ( accIdWithAimsClient.get( accId ) != null )
                    )
                {
                    lstAIMS.add( accIdWithAimsClient.get( accId ) );
                }
            }
        }
        return lstAIMS;
    }

    // check for valid assets
    private void checkForAssets() {
        if ( !accountIds.isEmpty() ) {
            for ( Asset asst : new Selector().getAssets( new List<Id>( accountIds ) ) ) {
                this.accIdWithAimsClient.put(
                    asst.AccountId ,
                    asst.NSP_Client__c
                );
            }
            for ( Asset asst : new Selector().getNoInsperityAssets( new List<Id>( accountIds ) ) ) {
                if ( this.isEligibleForNoInsperity401kFocusItem( asst ) ) {
                    this.noInsperityAccIdWithAimsClient.put(
                        asst.AccountId ,
                        asst.NSP_Client__c
                    );
                }
                if ( asst.Status != 'Active' && asst.Status != 'Onboarding' ) {
                    this.noNSPAccIdWithAimsClient.put(
                        asst.AccountId ,
                        asst.NSP_Client__c
                    );
                }
            }
        }
    }

    private Boolean isEligibleForNoInsperity401kFocusItem(Asset asst){
        Boolean local = False;
        if ( asst != null
            && (
                ( asst.NSP_Retirement_Service_Plan_Name__c != null 
                 && asst.NSP_Retirement_Service_Plan_Name__c?.contains( NSP_ServiceConstants.ORK )
                )
                || ( asst.NSP_Retirement_Service_Plan_Name__c == null )
           )
            && ( asst.Status == 'Active'
                || asst.Status == 'Onboarding'
               )
           )
        {
            local = True;       
        }
        return local;    
    }

    // check for Account Groups and Focus Items
    private void checkForAccountGroups( List<NSP_Account_Group__c> lstAccGrps ) {
       if ( ( lstAccGrps != null ) && !lstAccGrps.isEmpty() ) {
            for ( NSP_Account_Group__c accGrp : lstAccGrps ) {
                this.grpIdWithAccId.put( accGrp.Id , new List<String>() );
                this.accGrpWithFocusItem.put( accGrp.Id , 0 );
                this.accGrpWithFocusItemNSP.put( accGrp.Id , 0 );
                this.collectMemberAccounts( accGrp.Id , accGrp.Account_Group_Members__r );
                if ( ( accGrp.Focus_Items__r != null ) && !accGrp.Focus_Items__r.isEmpty() ) {
                    for ( NSP_Focus_Item__c focusItem : accGrp.Focus_Items__r ) {
                        this.processEarlyTenureFocusItem( accGrp.Id , focusItem );
                        this.processNoInsperity401KFocusItem( accGrp.Id , focusItem );
                    }
                }
            }
        }
    }

    private void collectMemberAccounts( Id accountGroupId , List<NSP_Account_Group_Member__c> records ) {
        if ( ( records != null )
            && !records.isEmpty()
            && ( accountGroupId != null )
            )
        {
            for( NSP_Account_Group_Member__c accGrpMbr : records ) {
                if ( accGrpMbr.NSP_Member_Account__c != null ){
                    if ( ( this.grpIdWithAccId != null )
                        && !this.grpIdWithAccId.isEmpty()
                        && this.grpIdWithAccId.containsKey( accountGroupId )
                        )
                    {
                        this.grpIdWithAccId.get( accountGroupId ).add( accGrpMbr.NSP_Member_Account__c );
                    }
                    accountIds.add( accGrpMbr.NSP_Member_Account__c );
                }
            }
        }
    }

    private void processEarlyTenureFocusItem( Id accGrpId, NSP_Focus_Item__c focusItem ){
        if ( ( accGrpId != null )
            && ( focusItem != null )
            && ( focusItem.Focus_Item__c == NSP_ServiceConstants.EARLY_TENURE )
            && ( this.accGrpWithFocusItem != null )
            && this.accGrpWithFocusItem.containsKey(accGrpId)
            )
        {
            if ( String.isNotBlank( focusItem.NSP_Status__c )
                && !this.focusItemStatus.contains( focusItem.NSP_Status__c )
                )
            {
                this.accGrpWithFocusItem.remove( accGrpId );
            } else if ( focusItem.NSP_Status__c == NSP_ServiceConstants.STATUS_ACTIVE ) {
                this.accGrpWithFocusItem.remove( accGrpId );
                this.accGrpWithFocusItemActive.put( accGrpId , focusItem );
            }
        }
    }

    private void processNoInsperity401KFocusItem( Id accGrpId , NSP_Focus_Item__c focusItem ) {
        if ( ( accGrpId != null )
            && ( focusItem != null )
            && ( focusItem.Focus_Item__c == NSP_ServiceConstants.NO_INSPERITY_401K )
            && ( this.accGrpWithFocusItemNSP != null )
            && this.accGrpWithFocusItemNSP.containsKey( accGrpId )
            )
        {
            if ( String.isNotBlank( focusItem.NSP_Status__c )
                && !this.focusItemStatus.contains( focusItem.NSP_Status__c )
                )
            {
                this.accGrpWithFocusItemNSP.remove( accGrpId );
            } else if ( focusItem.NSP_Status__c == NSP_ServiceConstants.STATUS_ACTIVE ) {
                this.accGrpWithFocusItemNSP.remove( accGrpId );
                this.accGrpWithFocusItemActiveNSP.put( accGrpId , focusItem );
            }
        }
    }

    // upsert FocusItems
    private void insertFocusItems() {
        if ( ( this.lstFocusItems != null )
            && !this.lstFocusItems.isEmpty()
            )
        {
            List<Database.UpsertResult> upsertResults = Database.upsert( this.lstFocusItems , false );
            NSP_ErrorLogHandler.logResults(
                NSP_AccountGroupFocusItemsBatch.class.getName() ,
                'insertFocusItems' ,
                upsertResults
            );
        }
    }


    // Prepare FocusItem
    private NSP_Focus_Item__c prepareFocusItem(
        List<String> lstAIMS ,
        Id accGrpId ,
        String focusItem ,
        String detail ,
        String estimatedImpact ,
        String comments
        )
    {
        return new NSP_Focus_Item__c (
            Area_of_Focus__c=NSP_ServiceConstants.CUSTOMER_RELATIONSHIP ,
            Focus_Item__c=focusItem ,
            RecordTypeId=NSP_GenericRecordType.getRecordTypeId( 'NSP_Focus_Item__c' , 'NSP_System_Generated_Focus_Item' ) ,
            NSP_Detail__c=detail ,
            NSP_Estimated_Impact__c=estimatedImpact ,
            Details__c=comments + ' [' + String.join( lstAIMS , ',' ) + ']' ,
            NSP_Status__c=NSP_ServiceConstants.STATUS_ACTIVE ,
            NSP_Start_Date__c=System.today() ,
            NSP_System_Generated__c='Y' ,
            NSP_Account_Group__c=accGrpId
        );
    }

    @TestVisible
    private without sharing Class Selector {

        // get Assets based on AccountIds last 24 Months
        private List<Asset> getAssets( List<Id> accIds ) {
            List<Asset> assets = new List<Asset>();
            if ( ( accIds != null ) && !accIds.isEmpty() ) {
                assets = [
                    SELECT
                        Id ,
                        NSP_AIMS_Original_First_Pay_Date__c ,
                        NSP_Retirement_Service_Plan_Name__c ,
                        AccountId ,
                        NSP_Client__c
                    FROM Asset
                    WHERE (
                        ( RecordTypeId = :NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.WO_ASSET_RECORDTYPE ) )
                        AND ( NSP_AIMS_Original_First_Pay_Date__c >= LAST_N_DAYS:730 )
                        AND ( NSP_AIMS_Original_First_Pay_Date__c <= LAST_N_DAYS:730 )
                        AND ( AccountId IN :accIds )
                    )
                    WITH SECURITY_ENFORCED
                ];
            }
            return assets;
        }

        // get Assets based on AccountIds and which contains ORK
        private List<Asset> getNoInsperityAssets( List<Id> accIds ) {
            List<Asset> assets = new List<Asset>();
            if ( ( accIds != null ) && !accIds.isEmpty() ) {
                assets = [
                    SELECT
                        Id ,
                        NSP_AIMS_Original_First_Pay_Date__c ,
                        NSP_Retirement_Service_Plan_Name__c ,
                        AccountId ,
                        NSP_Client__c,
                        Status
                    FROM Asset
                    WHERE (
                        ( RecordTypeId = :NSP_GenericRecordType.getRecordTypeId( 'Asset' , NSP_ServiceConstants.WO_ASSET_RECORDTYPE ) )
                        AND ( AccountId IN :accIds )
                    )
                    WITH SECURITY_ENFORCED
                ];
            }
            return assets;
       }

    }

}
//