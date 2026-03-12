/**
* @description       : System to run a batch jobs to identify situations that could affect Account Health/Renewal Probability.
* @author            : Anil
* @group             :
* @last modified on  : 02-13-2023
* @last modified by  : Anil
**/
public without sharing class NSP_AccountGroupFocusItemsBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject>  {
    // test w/ NSP_AccountGroupFocusItemsBatch_Test (87%)

    Map<String, Integer> accGrpWithFocusItem = new Map<String, Integer>();
    Map<String, NSP_Focus_Item__c> accGrpWithFocusItemActive = new Map<String, NSP_Focus_Item__c>();
    Map<String, Integer> accGrpWithFocusItemNSP = new Map<String, Integer>();
    Map<String, NSP_Focus_Item__c> accGrpWithFocusItemActiveNSP = new Map<String, NSP_Focus_Item__c>();
    Map<String, String> accIdWithAimsClient = new Map<String, String>();
    Map<String, String> noInsperityAccIdWithAimsClient = new Map<String, String>();
    Map<String, String> noNSPAccIdWithAimsClient = new Map<String, String>();
    List<NSP_Focus_Item__c> lstFocusItems = new List<NSP_Focus_Item__c>();
    Map<String, List<String>> grpIdWithAccId = new Map<String, List<String>>();
    Map<String,Map<String,Integer>> accGrpFoucsItemCount = new Map<String, Map<String,Integer>>();
    Set<Id> accountIds = new Set<Id>();
    List<String> focusItemStatus = new List<String>{ NSP_ServiceConstants.STATUS_ACTIVE, NSP_ServiceConstants.CLOSED_STATUS };

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
        if (Test.isRunningTest()) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_AccountGroupFocusItemsBatch ~ monthly at 11 PM' + suffix,
            '0 0 23 1 * ?',
            new NSP_AccountGroupFocusItemsBatch()
        );
    }

    //
    // Schedulable
    //
    public void execute(SchedulableContext sc) {
        this.call('run', null);
    }

    //
    // Callable
    //
    public Object call(String action, Map<String,Object> args) {
        Object response = null;
        if (action == 'run') {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //
    public Id run() {
        return Database.executeBatch(
            new NSP_AccountGroupFocusItemsBatch()
        );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator( [
            SELECT Id,
                Name,
                NSP_Type__c,
                NSP_Account__c,
                NSP_Tag__c,
                NSP_Group_Member_Count__c,
                ( SELECT Id,
                     NSP_Member_Account__c
                  FROM Account_Group_Members__r
                ),
                ( SELECT Id,
                     Focus_Item__c,
                     NSP_Status__c,
                     NSP_Detail__c
                  FROM Focus_Items__r
                     WHERE NSP_Status__c != 'Closed'
                )
               FROM NSP_Account_Group__c
               WHERE NSP_Group_Member_Count__c > 0
               AND NSP_Type__c IN ('Account Health','Renewal Probability')
        ] );
    }

    public void execute(Database.BatchableContext bc, List<NSP_Account_Group__c> lstAccGrps) {
        if ( lstAccGrps != null && !lstAccGrps.isEmpty() ){
            try{
                this.checkForAccountGroups(lstAccGrps);
                this.checkForAssets();
                this.checkForFocusItems(lstAccGrps);
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

    //finish method
    public void finish(Database.BatchableContext bc) {}

    /**
    * @description check for FocusItems that matches with Account Groups
    * @author Anil | 02-03-2023
    * @param lstAccGrps
    **/
    private void checkForFocusItems(List<NSP_Account_Group__c> lstAccGrps) {
        if ( lstAccGrps != null && !lstAccGrps.isempty() ){
             for(NSP_Account_Group__c accGrp : lstAccGrps){
                List<String> lstAIMS = checkForAIMS(
                    accGrp.Id,
                    this.grpIdWithAccId,
                    this.accIdWithAimsClient
                );
                List<String> noInsperityAIMSClient = checkForAIMS(
                    accGrp.Id,
                    this.grpIdWithAccId,
                    this.noInsperityAccIdWithAimsClient
                );
                List<String> noNSPAccIdWithAims = checkForAIMS(
                    accGrp.Id,
                    grpIdWithAccId,
                    noNSPAccIdWithAimsClient
                );
                this.checkEarlyTenureFocusItems( accGrp.Id, lstAIMS );
                this.checkNoInsperity401kFocusItems( accGrp.Id, noInsperityAIMSClient, noNSPAccIdWithAims );
            }
        }

    }

    private void checkEarlyTenureFocusItems( Id accGrpId, List<String> lstAIMS ) {
        if ( accGrpId != null ) {
            if(  lstAIMS != null && !lstAIMS.isEmpty() ){
                // 1) Create NEW focus item when none exists and AIMS list is present
                if ( this.accGrpWithFocusItem.containsKey( accGrpId )
                    && this.accGrpWithFocusItem.get( accGrpId ) == 0
                   )
                {
                    this.lstFocusItems.add(
                        this.prepareFocusItem(
                            lstAIMS,
                            accGrpId,
                            NSP_ServiceConstants.EARLY_TENURE,
                            NSP_ServiceConstants.EARLY_TENURE_CLIENT,
                            NSP_ServiceConstants.UNFAVORABLE,
                            NSP_ServiceConstants.FOCUS_COMMENTS
                        )
                    );

                // 2) Update existing ACTIVE focus item when AIMS list is present
                } else if ( this.accGrpWithFocusItemActive.containsKey( accGrpId )
                           && this.accGrpWithFocusItemActive.get( accGrpId ) != null
                          )
                {
                    NSP_Focus_Item__c focusItem = this.accGrpWithFocusItemActive.get( accGrpId );
                    focusItem.Details__c = NSP_ServiceConstants.FOCUS_COMMENTS + ' [' + String.join(lstAIMS, ',') + ']';
                    this.lstFocusItems.add( focusItem );

                // 3) Close existing ACTIVE focus item when AIMS list is empty
                }
            }else if ( this.accGrpWithFocusItemActive.containsKey(accGrpId)
                       && this.accGrpWithFocusItemActive.get(accGrpId) != null
                     )
            {

                NSP_Focus_Item__c focusItem = this.accGrpWithFocusItemActive.get(accGrpId);
                focusItem.NSP_Estimated_Impact__c = NSP_ServiceConstants.NEUTRAL;
                focusItem.Details__c = null;
                focusItem.NSP_Status__c = NSP_ServiceConstants.CLOSED_STATUS;
                focusItem.NSP_End_Date__c = System.Today();
                this.lstFocusItems.add(focusItem);
            }
        }
    }


    private void checkNoInsperity401kFocusItems(
        Id accGrpId,
        List<String> noInsperityAIMSClient,
        List<String> noNSPAccIdWithAims
    )
    {
        if ( accGrpId != null
            && noInsperityAIMSClient != null
            && !noInsperityAIMSClient.isEmpty()
           )
         {
             // 1) Create NEW focus item when none exists and AIMS list is present
             if ( this.accGrpWithFocusItemNSP.containsKey(accGrpId)
                 && this.accGrpWithFocusItemNSP.get(accGrpId) == 0
                )
             {
                 this.lstFocusItems.add(
                     this.prepareFocusItem(
                         noInsperityAIMSClient,
                         accGrpId,
                         NSP_ServiceConstants.NO_INSPERITY_401K,
                         '',
                         NSP_ServiceConstants.SOME_WHAT_UNFAVORABLE,
                         NSP_ServiceConstants.FOCUS_401_COMMENTS
                     )
                 );

                 // 2) Update existing ACTIVE focus item when AIMS list is present
             } else if ( this.accGrpWithFocusItemActiveNSP.containsKey(accGrpId)
                        && this.accGrpWithFocusItemActiveNSP.get(accGrpId) != null
                       )
             {
                 NSP_Focus_Item__c focusItem = this.accGrpWithFocusItemActiveNSP.get(accGrpId);
                 focusItem.Details__c = NSP_ServiceConstants.FOCUS_401_COMMENTS
                     + ' [' + String.join( noInsperityAIMSClient, ',')
                     + ']';
                 this.lstFocusItems.add(focusItem);


             }

         // 3) Close existing ACTIVE focus item based on your original condition
         } else if ( accGrpId != null
                    && this.accGrpWithFocusItemActiveNSP.containsKey(accGrpId)
                    && this.accGrpWithFocusItemActiveNSP.get(accGrpId) != null
                    && noNSPAccIdWithAims != null
                    && !noNSPAccIdWithAims.isEmpty()
                   )
         {
             NSP_Focus_Item__c focusItem = this.accGrpWithFocusItemActiveNSP.get(accGrpId);
             focusItem.NSP_Estimated_Impact__c = NSP_ServiceConstants.NEUTRAL;
             focusItem.Details__c = null;
             focusItem.NSP_Status__c = NSP_ServiceConstants.CLOSED_STATUS;
             focusItem.NSP_End_Date__c = System.Today();
             this.lstFocusItems.add(focusItem);
         }

    }

    /**
    * @description check whether asset is associate with account Group Member
    * @author Anil | 02-03-2023
    * @param accGrpId
    * @param grpIdWithAccId
    * @param accIdWithAimsClient
    * @return List<String>
    **/
    private List<String> checkForAIMS(Id accGrpId, Map<String, List<String>> grpIdWithAccId, Map<String, String> accIdWithAimsClient){
        List<String> lstAIMS = new List<String>();
        if ( grpIdWithAccId != null
            && !grpIdWithAccId.isEmpty()
            && accGrpId != null
            && accIdWithAimsClient != null
            && !accIdWithAimsClient.isEmpty()
           )
        {
           for ( String accId : grpIdWithAccId.get( accGrpId ) ) {
              if ( accIdWithAimsClient.containsKey( accId ) && accIdWithAimsClient.get( accId ) != null ) {
                lstAIMS.add( accIdWithAimsClient.get( accId ) );
              }
           }
        }

        return lstAIMS;
    }

    /**
    * @description check for valid assets
    * @author Anil | 02-03-2023
    **/
    private void checkForAssets() {
        if ( !accountIds.isEmpty() ){
            for(Asset asst : new Selector().getAssets(new List<Id>(accountIds))) {
                accIdWithAimsClient.put(asst.AccountId, asst.NSP_Client__c);
            }

            for(Asset asst : new Selector().getNoInsperityAssets(new List<Id>(accountIds))) {
                if((asst.NSP_Retirement_Service_Plan_Name__c != null && asst.NSP_Retirement_Service_Plan_Name__c?.contains(NSP_ServiceConstants.ORK)) || asst.NSP_Retirement_Service_Plan_Name__c == null) {
                    noInsperityAccIdWithAimsClient.put(asst.AccountId, asst.NSP_Client__c);
                }
                if((asst.NSP_Retirement_Service_Plan_Name__c != null && !asst.NSP_Retirement_Service_Plan_Name__c?.contains(NSP_ServiceConstants.ORK)) || asst.NSP_Retirement_Service_Plan_Name__c != null){
                    noNSPAccIdWithAimsClient.put(asst.AccountId, asst.NSP_Client__c);
                }
            }
        }
    }


    /**
    * @description check for Account Groups and Focus Items
    * @author Anil | 02-03-2023
    * @param lstAccGrps
    **/
    private void checkForAccountGroups(List<NSP_Account_Group__c> lstAccGrps) {
       if ( lstAccGrps != null && !lstAccGrps.isEmpty() ) {

            for( NSP_Account_Group__c accGrp : lstAccGrps ) {

                grpIdWithAccId.put(accGrp.Id, new List<String>());
                accGrpWithFocusItem.put(accGrp.Id, 0);
                accGrpWithFocusItemNSP.put(accGrp.Id, 0);

                this.collectMemberAccounts( accGrp.Id, accGrp.Account_Group_Members__r);
                if ( accGrp.Focus_Items__r != null && !accGrp.Focus_Items__r.isEmpty() ){
                    for( NSP_Focus_Item__c focusItem : accGrp.Focus_Items__r) {
                        this.processEarlyTenureFocusItem( accGrp.Id, focusItem );
                        this.processNoInsperity401KFocusItem( accGrp.Id, focusItem );
                    }
                }

            }
        }
    }

    private void collectMemberAccounts(Id accountGroupId, List<NSP_Account_Group_Member__c> records){
        if ( records != null && !records.isEmpty() && accountGroupId != null ){
            for( NSP_Account_Group_Member__c accGrpMbr : records ) {
                if ( accGrpMbr.NSP_Member_Account__c != null ){
                    if ( this.grpIdWithAccId != null
                        && !this.grpIdWithAccId.isEmpty()
                        && this.grpIdWithAccId.containsKey( accountGroupId )
                       )
                    {
                        this.grpIdWithAccId.get( accountGroupId ).add( accGrpMbr.NSP_Member_Account__c );
                    }
                    accountIds.add(accGrpMbr.NSP_Member_Account__c);
                }
            }
        }

    }

    private void processEarlyTenureFocusItem( Id accGrpId, NSP_Focus_Item__c focusItem ){
        if ( accGrpId != null
             && focusItem !=null
             && focusItem.Focus_Item__c == NSP_ServiceConstants.EARLY_TENURE
             && this.accGrpWithFocusItem != null
             && this.accGrpWithFocusItem.containsKey(accGrpId)
           )
        {
             if ( String.isNotBlank( focusItem.NSP_Status__c )
                 && !this.focusItemStatus.contains( focusItem.NSP_Status__c ) ){
                  this.accGrpWithFocusItem.remove(accGrpId);
             } else if ( focusItem.NSP_Status__c == NSP_ServiceConstants.STATUS_ACTIVE ) {
                  this.accGrpWithFocusItem.remove(accGrpId);
                  this.accGrpWithFocusItemActive.put(accGrpId, focusItem);
             }
         }
    }

    private void processNoInsperity401KFocusItem( Id accGrpId, NSP_Focus_Item__c focusItem ){
        if ( accGrpId != null
             && focusItem !=null
             && focusItem.Focus_Item__c == NSP_ServiceConstants.NO_INSPERITY_401K
             && this.accGrpWithFocusItemNSP != null
             && this.accGrpWithFocusItemNSP.containsKey(accGrpId)
           )
        {
            if ( String.isNotBlank( focusItem.NSP_Status__c )
                && !this.focusItemStatus.contains(focusItem.NSP_Status__c)){
                 this.accGrpWithFocusItemNSP.remove(accGrpId);
             } else if( focusItem.NSP_Status__c == NSP_ServiceConstants.STATUS_ACTIVE) {
                 this.accGrpWithFocusItemNSP.remove(accGrpId);
                 this.accGrpWithFocusItemActiveNSP.put(accGrpId, focusItem);
             }
         }
    }

    /**
    * @description upsert FocusItems
    * @author Anil | 02-03-2023
    **/
    private void insertFocusItems() {
        if ( this.lstFocusItems != null && !this.lstFocusItems.isEmpty() ) {
            List<Database.UpsertResult> upsertResults = Database.upsert( this.lstFocusItems, false );
            NSP_ErrorLogHandler.logResults(
                NSP_AccountGroupFocusItemsBatch.class.getName() ,
                'insertFocusItems' ,
                upsertResults
            );
        }
    }

    /**
    * @description Prepare FocusItem
    * @author Anil | 02-03-2023
    * @param lstAIMS
    * @param accGrpId
    * @param focusItem
    * @param detail
    * @param estimatedImpact
    * @param comments
    * @return NSP_Focus_Item__c
    **/
    private NSP_Focus_Item__c prepareFocusItem(List<String> lstAIMS, Id accGrpId, String focusItem, String detail, String estimatedImpact, String comments) {
        return new NSP_Focus_Item__c (
            Area_of_Focus__c = NSP_ServiceConstants.CUSTOMER_RELATIONSHIP,
            Focus_Item__c = focusItem,
            RecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Focus_Item__c', 'NSP_System_Generated_Focus_Item'),
            NSP_Detail__c = detail,
            NSP_Estimated_Impact__c = estimatedImpact,
            Details__c = comments+' ['+String.join(lstAIMS, ',')+']',
            NSP_Status__c = NSP_ServiceConstants.STATUS_ACTIVE,
            NSP_Start_Date__c = System.Today(),
            NSP_System_Generated__c = 'Y',
            NSP_Account_Group__c = accGrpId
        );
    }

    @TestVisible
    private without sharing Class Selector {

        /**
        * @description get Assets based on AccountIds last 24 Months
        * @author Anil | 02-03-2023
        * @param accIds
        * @return List<Asset>
        **/
        private List<Asset> getAssets( List<Id> accIds ) {
            List<Asset> assets = new List<Asset>();
            if ( accIds != null && !accIds.isEmpty() ) {
                assets = [
                    SELECT Id, NSP_AIMS_Original_First_Pay_Date__c,
                        NSP_Retirement_Service_Plan_Name__c,
                        AccountId,
                        NSP_Client__c
                    FROM Asset
                    WHERE RecordTypeId = :NSP_GenericRecordType.getRecordTypeId('Asset', NSP_ServiceConstants.WO_ASSET_RECORDTYPE)
                    AND NSP_AIMS_Original_First_Pay_Date__c >= LAST_N_DAYS:730
                    AND NSP_AIMS_Original_First_Pay_Date__c <= LAST_N_DAYS:730
                    AND AccountId IN :accIds
                    WITH SECURITY_ENFORCED
                ];
            }
            return assets;
        }

        /**
        * @description get Assets based on AccountIds and which contains ORK
        * @author Anil | 02-03-2023
        * @param accIds
        * @return List<Asset>
        **/
        private List<Asset> getNoInsperityAssets(List<Id> accIds) {
            List<Asset> assets = new List<Asset>();
            if ( accIds != null && !accIds.isEmpty() ) {
                assets = [
                    SELECT Id,
                    NSP_AIMS_Original_First_Pay_Date__c,
                    NSP_Retirement_Service_Plan_Name__c,
                    AccountId,
                    NSP_Client__c
                    FROM Asset
                    WHERE RecordTypeId = :NSP_GenericRecordType.getRecordTypeId(
                        'Asset',
                        NSP_ServiceConstants.WO_ASSET_RECORDTYPE
                    )
                    AND AccountId IN :accIds
                    WITH SECURITY_ENFORCED
                ];
            }
            return assets;
       }

   }
}