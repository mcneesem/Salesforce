// intentionally `without sharing` to preserve default sharing at api version 52...
public without sharing class NSP_OpportunityTriggerServiceHelper {
    // test w/ NSP_OpportunityTriggerServiceHelperTest, NSP_AutomaticProjectBatchTest (85%)
    // test w/ NSP_OpportunityTriggerServiceHelperTest (78%)
    // test w/ NSP_AutomaticProjectBatchTest (9%)

    //
    // Creating Constructor to call FF API's
    // Creating Mock records of FF Api's Using interfaces
    //
    private static final Id PERFORM_SMART_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.PERFORMANCE_ASSET );
    private static final Id TIME_ATTENDANCE_ASSET = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.ASSET_SOBJECT_TYPE,NSP_ServiceConstants.ASSET_TT_RECORDTYPE );
    public NSP_FF_APIs implInstance = new NSP_FF_APIImpl();
    public NSP_OpportunityTriggerServiceHelper(){
        if(Test.isRunningTest()){
            this.implInstance = new Nsp_FFApiMock();
        }
    }
    // This constructor is for test use only. Don't use this in actual implementation.
    public NSP_OpportunityTriggerServiceHelper(Set<Id> projectIdSet){
       this.implInstance = new Nsp_FFApiMock(projectIdSet);
    }

    //
    // Iterates throught the Opportunity map and identifies the records that needs to worked based on various criterias.
    // @param opportunityNewMap Map of New Opportunity.
    // @param opportunityOldMap Map of Old Opportunity.
    // @return void
    //
    public void beforeUpdateDirector(Map<Id, Opportunity> opportunityNewMap, Map<Id, Opportunity> opportunityOldMap){
    	List<Opportunity> docusignedOpportunityList = new List<Opportunity>();

        //Iterating over the new opportunity map
        for(Id opportunityId : opportunityNewMap.keySet()){
            //Added as part of STY-STY-01602
            if(opportunityNewMap.get(opportunityId).NSP_Signed_CSA__c != opportunityOldMap.get(opportunityId).NSP_Signed_CSA__c &&
                opportunityNewMap.get(opportunityId).NSP_Signed_CSA__c == true){
                docusignedOpportunityList.add(opportunityNewMap.get(opportunityId));
            }
        }

        //Added as part of STY-STY-01602
        if(!docusignedOpportunityList.isEmpty()){
            updateCSAsignedDateOnOpportunity(docusignedOpportunityList);
        }
    }

    //
    // Iterates throught the list of new leads and passes the required attributes to other methods.
    // @param opportunityNewMap Map of New Opportunity.
    // @param opportunityOldMap Map of Old Opportunity.
    // @return void
    //
    public void afterUpdateDirector(Map<Id, Opportunity> opportunityNewMap,Map<Id, Opportunity> opportunityOldMap){
        List<Opportunity> docusignedOpportunityList = new List<Opportunity>();
        Map<Id,Opportunity> timeAttAssetMap = new Map<Id,Opportunity>();
        Map<Id,Opportunity> perAssetMap = new Map<Id,Opportunity>();
        Map<Id,Id> oppIdAccIdMap = new Map<Id,Id>();
        Set<Id>accountIdSet = new Set<Id>();
        Set<Id>  performSmartSet = new Set<Id>();
        Set<Id>  timeAttendenceSet = new Set<Id>();

        if (opportunityNewMap != null){
            for(Opportunity opportunityRecord : opportunityNewMap.values()){
                Opportunity oldOpportunity = opportunityOldMap != null ? opportunityOldMap.get(opportunityRecord.id):null;
                if ( oldOpportunity != null
                    && opportunityRecord.stagename != oldOpportunity.stagename
                    && opportunityRecord.Stagename == NSP_SalesConstants.CLOSED_WON
                    )
                {
                    oppIdAccIdMap.put(opportunityRecord.Id,opportunityRecord.AccountId);
                }
            }
        }
        if (!oppIdAccIdMap.values().isEmpty()){
            List<Asset> existingAssetList = [
                SELECT Id, Accountid, RecordTypeId
                FROM Asset
                WHERE (
                    AccountId IN :oppIdAccIdMap.values()
                    AND Status IN (:NSP_ServiceConstants.ASSET_ONBOARDING_STATUS, :NSP_ServiceConstants.ASSET_ONDEMAND_STATUS, :NSP_ServiceConstants.ASSET_ACTIVE_STATUS)
                    AND RecordTypeId IN (:PERFORM_SMART_ASSET, :TIME_ATTENDANCE_ASSET)
                )
            ];
            if(existingAssetList.size()>0){
                for(Asset assetList : existingAssetList){
                    if ( assetList.AccountId != null ) {
                        if ( assetList.RecordTypeId == PERFORM_SMART_ASSET ) {
                            performSmartSet.add( assetList.AccountId );
                        } else if( assetList.RecordTypeId == TIME_ATTENDANCE_ASSET ) {
                            timeAttendenceSet.add( assetList.AccountId );
                        }
                    }
                }
            }
        }
        if (!oppIdAccIdMap.keyset().isEmpty()){
            for(Id opportunityId : oppIdAccIdMap.keyset()){
                Opportunity opp = opportunityNewMap != null ? opportunityNewMap.get(opportunityId):null;
                if ( opp != null ) {
                    Boolean isValidTimeEntryRecommendation = (
                        ( opp.NSP_Time_Entry_Recommendation__c == NSP_ServiceConstants.Premier_Time_Att )
                        || ( opp.NSP_Time_Entry_Recommendation__c == NSP_ServiceConstants.Premier_Timesheet )
                    );
                    Boolean isValidWoWsPrimaryProduct = (
                        ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WO )
                        || ( opp.NSP_PrimaryProduct__c == NSP_SalesConstants.WS )
                    );
                    if (!timeAttendenceSet.contains(opp.AccountId)) {
                        // added as a part of STY-03649
                        if ( isValidWoWsPrimaryProduct
                            && isValidTimeEntryRecommendation
                            )
                        {
                            timeAttAssetMap.put(opp.Id,opp);
                        }
                        if ( (opp.NSP_PrimaryProduct__c == NSP_ServiceConstants.TIME_ATTENDANCE)
                            && isValidTimeEntryRecommendation
                            )
                        {
                            timeAttAssetMap.put(opp.Id,opp);
                        }

                    }
                    if (!performSmartSet.contains(opp.AccountId)) {
                        if ( isValidWoWsPrimaryProduct
                            && opp.NSP_IPMRecommendation__c == NSP_SalesConstants.Yes
                            )
                        {
                            perAssetMap.put(opp.Id,opp);
                        }
                        if ( opp.NSP_PrimaryProduct__c == NSP_ServiceConstants.PERFORMANCE_MANAGEMENT
                            && opp.NSP_IPMRecommendation__c == NSP_SalesConstants.Yes
                            )
                        {
                            perAssetMap.put(opp.Id,opp);
                        }
                    }
                }
                //Added as part of STY-STY-01602
                if ( opportunityNewMap.get(opportunityId).NSP_Signed_CSA__c != opportunityOldMap.get(opportunityId).NSP_Signed_CSA__c
                    && opportunityNewMap.get(opportunityId).NSP_Signed_CSA__c == true
                    && opportunityNewMap.get(opportunityId).NSP_Signed_CSA_Date__c != null
                    )
                {
                    docusignedOpportunityList.add(opportunityNewMap.get(opportunityId));
                }
                // added as a part of STY-02129
                if ( opp.StageName != opportunityOldMap.get(opp.Id).StageName
                    && opp.StageName == NSP_SalesConstants.CLOSED_WON
                    && opp.AccountId!=null
                    )
                {
                    accountIdSet.add(opp.AccountId);
                }
            }
        }

        //Added as part of STY-STY-01602
        if(!docusignedOpportunityList.isEmpty()){
            updateCSAsignedDateOnAsset(docusignedOpportunityList);
        }

        // added as a part of STY-03649
        if((!timeAttAssetMap.isEmpty() || !perAssetMap.isEmpty())  ){
            createAssetwithProject(timeAttAssetMap,perAssetMap,oppIdAccIdMap);
        }

    }

    //
    // Create Project And Delete Budget
    // @param lProjRequests Response received from FinancialForce APIs).
    // @return void
    //
    public Set<Id> createProjectAndDeleteBudget( List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest> lProjRequests ) {
        Set<Id> newProjectId = new Set<Id>();
        if ( ( lProjRequests != null ) && !lProjRequests.isEmpty() ) {
            //Add incoming mappers plus Region field
            if(lProjRequests[0].Mappers != null) {
                lProjRequests[0].Mappers.addAll(new List<pse.SObjectCloneMapper>{
                    NSP_CreateProjFromFlow.getDefaultMappers()
                });
            }
            else {
                lProjRequests[0].Mappers = new List<pse.SObjectCloneMapper> { NSP_CreateProjFromFlow.getDefaultMappers()};
            }
            //Call the service and create project
            List<pse.CreateProjectFromTemplateService.CreateProjectResponse> projResponse = this.implInstance.createProjectFromTemplate(new List<pse.CreateProjectFromTemplateService.CreateProjectFromTemplateAndAccountRequest>{lProjRequests[0]});
            newProjectId = this.implInstance.getProjectIdSet(projResponse);
            // Deleting all Budgets Created with Projects
            if ( !newProjectId.isEmpty() ) {
                List<pse__Budget__c> lBudgets = [
                    SELECT Id
                    FROM pse__Budget__c
                    WHERE pse__Project__c IN :newProjectId
                ];
                delete lBudgets;
            }
        }
        return newProjectId;
    }

    //
    // MethodName: createAssetwithProject
    // Description : This Method will update Opportunity related account ProjectId on the Implementation Profile for the Closed Opportunities
    // Params:     Map<Id,String> timeAttAssetMap,Map<Id,String> perAssetMap , Map<Id,Id> oppAccMap
    //
    private static void createAssetwithProject(
        Map<Id,Opportunity> timeAttAssetMap ,
        Map<Id,Opportunity> perAssetMap ,
        Map<Id,Id> oppAccMap
        )
    {
        try {
            List<Asset> assetList = new List<Asset>();
            if(!timeAttAssetMap.isEmpty()){
                for(Id oppId:timeAttAssetMap.keyset() ){
                    Opportunity record = timeAttAssetMap.get(oppId);
                    if(record != null){
                        assetList.add(
                            createAssetObject(
                                record.Name ,
                                oppId ,
                                oppAccMap.get(oppId) ,
                                NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'Time_Attendance' ) ,
                                NSP_ServiceConstants.ASSET_ONBOARDING_STATUS ,
                                NSP_ServiceConstants.CASE_TIME_ATTENDENCE ,
                                NSP_ServiceConstants.WoWSAsset,
                                record.NSP_PrimaryProduct__c
                            )
                        );
                    }
                }
            }
            if(!perAssetMap.isEmpty()){
                for(Id oppId:perAssetMap.keyset() ){
                    Opportunity record = perAssetMap.get(oppId);
                    if(record != null){
                        String assetStatus = NSP_ServiceConstants.ASSET_ONDEMAND_STATUS;
                        if(record.NSP_PrimaryProduct__c == NSP_ServiceConstants.PERFORMANCE_MANAGEMENT){
                            assetStatus = NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
                        }
                        assetList.add(
                            createAssetObject(
                                record.Name ,
                                oppId ,
                                oppAccMap.get(oppId) ,
                                NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'Performance_Management' ) ,
                                assetStatus ,
                                NSP_ServiceConstants.PERFORMANCE ,
                                NSP_ServiceConstants.WoWSAsset,
                                record.NSP_PrimaryProduct__c
                            )
                        );
                    }
                }
            }
            if ( !assetList.isEmpty() ) {
                List<Database.UpsertResult> upsertResults = Database.upsert( assetList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_OpportunityTriggerServiceHelper.class.getName() ,
                    'createAssetwithProject' ,
                    upsertResults
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_OpportunityTriggerServiceHelper.class.getName() ,
                'createAssetwithProject' ,
                e
            );
        }
    }

    private static Asset createAssetObject(String assetName , Id oppId, Id accountId , Id assetRecordTypeId , String status , String productLine , String bundle, String primaryProduct){
        Asset ast = new Asset();
        ast.Name = assetName;
        ast.RecordTypeId = assetRecordTypeId;
        ast.Status = status;
        ast.NSP_Signature_Date__c = System.today();
        ast.NSP_Product_Line__c = productLine;
        ast.NSP_ProductBundle__c = bundle;
        ast.Opportunity__c = OppId;
        ast.AccountId = accountId;
        if(primaryProduct == NSP_SalesConstants.WO || primaryProduct == NSP_SalesConstants.WS){
            ast.Is_Perform_WO_WS_Asset__c = TRUE;
        }
        return ast;
    }

    //
    // @MethodName : updateCSAsignedDateOnOpportunity
    // @Description: This method will update CSA Signed Date on opportunity
    //               record when Signed CSA is checked.
    // @param      : List<Opportunity> opportunityList
    // @Story      : STY-01602
    // @return     : void
    //
    public void updateCSAsignedDateOnOpportunity(List<Opportunity> opportunityList){
        try{
            for(Opportunity oppoRec : opportunityList){
                oppoRec.NSP_Signed_CSA_Date__c = System.today();
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_OpportunityTriggerServiceHelper.class.getName() ,
                'updateCSAsignedDateOnOpportunity' ,
                e
            );
        }
    }

    //
    // @MethodName : updateCSAsignedDateOnAsset
    // @Description: This method will update the CSA Signed Date field
    //               on opportunity related Asset record.
    // @param      : List<Opportunity> opportunityList
    // @Story      : STY-01602
    // @return     : void
    //
    public void updateCSAsignedDateOnAsset(List<Opportunity> opportunityList){
        try{
            List<Asset> relatedAssetList = new List<Asset>();
            List<Asset> assetListToUpdate = new List<Asset>();
            Set<Id> opportunityIdSet = new Set<Id>();
            for(Opportunity oppoRec : opportunityList){
                opportunityIdSet.add(oppoRec.Id);
            }
            if(!opportunityIdSet.isEmpty()){
                List<String> assetFields = new List<String>{'Id','NSP_CSA_Signed_Date__c','Opportunity__c','Opportunity__r.NSP_Signed_CSA_Date__c'};
                String query = new NSP_QueryBuilder('Asset', assetFields)
                                    .addFilter('Opportunity__c', new List<Id>(opportunityIdSet), NSP_QueryBuilder.Operator.INCLUDES)
                                    .addFilter('Opportunity__r.NSP_Signed_CSA__c', true).build();
                relatedAssetList = (List<Asset>)Database.query(query);
            }

            if(!relatedAssetList.isEmpty()){
                for(Asset assetRec : relatedAssetList){
                    Asset assetObj = new Asset();
                    assetObj.Id = assetRec.Id;
                    assetObj.NSP_CSA_Signed_Date__c = assetRec.Opportunity__r.NSP_Signed_CSA_Date__c;
                    assetListToUpdate.add(assetObj);
                }
            }

            if ( !assetListToUpdate.isEmpty() ) {
                Database.SaveResult[] assetUpdateList = Database.update( assetListToUpdate , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_OpportunityTriggerServiceHelper.class.getName() ,
                    'updateCSAsignedDateOnAsset' ,
                    assetUpdateList
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_OpportunityTriggerServiceHelper.class.getName() ,
                'updateCSAsignedDateOnAsset' ,
                e
            );
        }
    }

}
//