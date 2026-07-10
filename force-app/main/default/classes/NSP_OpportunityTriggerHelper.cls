public with sharing class NSP_OpportunityTriggerHelper {
    // test w/ NSP_OpportunityTriggerHelperTest, NSP_AccountTriggerHelperTest, OpportunityCloseWonTest (78%)
    // test w/ NSP_OpportunityTriggerHelperTest, OpportunityCloseWonTest (76%)
    // test w/ NSP_OpportunityTriggerHelperTest (75%)
    // test w/ NSP_AccountTriggerHelperTest (42%)
    // test w/ NSP_UserAndOwnerFunctionsTest (40%)
    // test w/ OpportunityCloseWonTest (38%)

    public static List<String> analysisStageCriteraTypes = System.Label.NSP_AnalysisStageCriteria.split(',');
    public static List<String> proposeStageCriteraTypes = System.Label.NSP_ProposeStageCriteria.split(',');
    public static final List<String> contractProductTypes = System.Label.NSP_ApplicableProductTypesForContract.split(',');
    public static final List<String> workforceProductsList = System.Label.NSP_Primary_Workforce_Products.split(',');
    public static final String RETIREMENT_SERVICES_FOR_NON_WO_PRODUCTS = System.Label.Retirement_Services_For_Non_WO_Products;
    public static final String SELECT_PRIMARY_CONTACT = System.Label.NSP_Select_Primary_Contact;
    private static final string ASSET_RECORDTYPE = System.Label.NSP_Asset_Product;
    public static boolean valueAssignedFromUser = false;
    public static boolean createRewardsOnce = false;
    private static final string ClosedWonErrorMessage = System.Label.NSP_ClosedWonChecklistValidation;
    private static set<Id>  byPassValidationOnRole = null;
    private List<UserRole> notAllowedCloseWonRoles = null;
    private String userRole = UserInfo.getUserRoleId();
    public static Map<String, Integer> opptyStageOrder = retrieveFieldPicklistOrder(Opportunity.StageName);
    private static Boolean hasAdminPermission = CustomPermissionController.checkUserPermission('Bypass_Restrict_Opportunity_Backward_Stage', UserInfo.getUserId());
    private static Boolean Is_Enabled_WO_WS_Stage_Entry = OpportunityStageSettings__c.getInstance(UserInfo.getUserId()).Is_Enabled_WO_WS_Stage_Entry__c;

    private static final Id insuranceServiceAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'Insurance_Service' );
    private static final Id certifyAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'Certify' );
    private static final Id lockedOpportunityRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Opportunity' , 'Opportunity_Locked' );
    private static final String PAYROLL_ONLY ='Payroll Only';

    //
    // Iterates throught the list of new Opportunity and passes the required attributes to other methods.
    // @param newList List of New Opportunity.
    // @return void
    //
    public void beforeInsertDirector(List<Opportunity> newList){

        Set<String> accountIdSet =  new Set<String>();
        List<Opportunity> opportunityWoWxList =  new List<Opportunity>();
        List<Opportunity> childopportunityList =  new List<Opportunity>();
        Set<Id> parentOpportunityIdSet = new Set<Id>();

        // AZD-191924 AZD-232114
        List<Opportunity> calculateFrees =  new List<Opportunity>();

        //set to store opportunity owner Ids when opportunity owner is changed/or when opportunity is created
        Set<Id> ownerIdsSet = new Set<Id>();
        //118442- Opp list which is Closed on insert
        List<Opportunity> closedStageList =  new List<Opportunity>();
        List<Opportunity> closedOppList =  new List<Opportunity>();
        //Iterating over the opportunity new list
        for(Opportunity opportunityObject : newList){
            ownerIdsSet.add(opportunityObject.OwnerId);

            // AZD-191924 AZD-232114 AZD-232117
            // If primary product IS 'Workforce Optimization' then calculate fees
            if ( ( opportunityObject.NSP_PrimaryProduct__c != null )
                && String.isNotBlank( opportunityObject.Accountid )
                && NSP_ValidateOpportunityStage.validHRProducts.contains( opportunityObject.NSP_PrimaryProduct__c )
                && ( opportunityObject.NSP_lock_enrollment_fee__c == false )
                )
            {
                calculateFrees.add( opportunityObject );
            }
            // Checking if account id is not blank
            if ( String.isNotBlank( opportunityObject.Accountid ) ) {
                // Adding account to the set
                accountIdSet.add( opportunityObject.Accountid );
                // Checking if the product type on opty is WO/WX and its a parent opportunity
                // Added as part of DF-01869 handled primary product for WO/WS or WA/WX
                if ( String.isnotBlank( opportunityObject.NSP_PrimaryProduct__c )
                    && (
                        NSP_ValidateOpportunityStage.validHRProducts.contains( opportunityObject.NSP_PrimaryProduct__c )
                        || opportunityObject.NSP_PrimaryProduct__c.equals( NSP_SalesConstants.WA )
                        || opportunityObject.NSP_PrimaryProduct__c.equals( NSP_SalesConstants.WX )
                        )
                    && String.isBlank( opportunityObject.NSP_Parent_Opportunity__c )
                    )
                {
                    opportunityWoWxList.add( opportunityObject );
                }
            }

            if(String.isNotBlank(opportunityObject.NSP_Parent_Opportunity__c)){
                childopportunityList.add(opportunityObject);
                parentOpportunityIdSet.add(opportunityObject.NSP_Parent_Opportunity__c);
            }

            //If type is CAMS updating the stage to Analysis
            if (String.isNotBlank(opportunityObject.Type) && opportunityObject.Type.equals(NSP_SalesConstants.OPPORTUNITY_TYPE_CAMS)) {
                opportunityObject.StageName = NSP_SalesConstants.ANALYSIS_STAGE;
            }

            //118442- If type is Client Growth Credit and stage is Closed Won updating the recordtype to Locked
            if (String.isNotBlank(opportunityObject.Type) && opportunityObject.Type.equals(NSP_SalesConstants.CLIENT_GROWTH_CREDIT)
                && opportunityObject.StageName.equals(NSP_SalesConstants.CLOSED_WON_STAGE)){
                closedStageList.add(opportunityObject);
                changeOpportunityRecordType(closedStageList);
            }

            // checking for closeddate is lessthan today or Not
            if(opportunityObject.CloseDate != null && opportunityObject.CloseDate < date.today()){
            closedOppList.add(opportunityObject);
            }
            // ADO-498657
            NSP_OpportunityTriggerHelper.setServicesOpportunity( null , opportunityObject.OwnerId , opportunityObject );
        }

        NSP_OpportunityTriggerHelperFunctions oppHelperFuncObj = new NSP_OpportunityTriggerHelperFunctions();
        //Setting direct assignments to opportunity records
        oppHelperFuncObj.setDirectOpptyFieldsAssignments(newList);

        if(!opportunityWoWxList.isEmpty()){
            //Calling method to stamp WO/WX emails on oprty record
            oppHelperFuncObj.stampWoWxEmailOnOpprtunity(opportunityWoWxList);
        }

        //Opportunity Validation of Stages
        NSP_ValidateOpportunityStage.validateOpportunityStage(newList);

        //copy fields from parent opportuity to child opportunity
        if(! childopportunityList.isEmpty()){
            NSP_ChildOpportunitiesHelperFunctions.defaultFieldsOnChildOpportunity(childopportunityList,parentOpportunityIdSet);
        }

        NSP_OpportunityTriggerHelperFunctions.populateServiceEmail(newList,ownerIdsSet);
        setSalesOfficeDetails(newList,null); // added for STY-03154

         // AZD-191924 AZD-232114
         if(!calculateFrees.isEmpty()){
            calculateEnrollmentFees(calculateFrees);
        }

    }

    //
    // Iterates throught the map of new Opportunity and passes the required attributes to other methods.
    // @param newList List of New Opportunity.
    // @param opportunityNewMap Map of Opportunity id and Opportunity records.
    // @return void
    //
    public void afterInsertDirector( List<Opportunity> newList , Map<Id,Opportunity> opportunityNewMap ) {
        Set<String> accountIdSet = new Set<String>();
        //Opportunity list to capture opportunities created with HSA contribution data
        List<Opportunity> newTaskOpportunityList = new List<Opportunity>();
        Set<Id> opportunityAccountIds = new Set<Id>();
        for ( Id opportunityId : opportunityNewMap.keySet() ) {
            Opportunity newOpportunity = opportunityNewMap.get( opportunityId );
            accountIdSet.add( newOpportunity.AccountId );
            if ( String.isNotBlank( newOpportunity.NSP_Contribution_Level__c )
                && String.isNotBlank( newOpportunity.NSP_Frequency_of_Distribution__c )
                )
            {
                newTaskOpportunityList.add( newOpportunity );
            }
            // Added as a part of DF-01497
            if ( ( newOpportunity.NSP_Primary_Contact__c == null )
                || ( newOpportunity.NSP_Customer_Signer__c == null )
                )
            {
                opportunityAccountIds.add( newOpportunity.AccountId );
            }
        }
        // Moving to NSP_UpdateRelatedAccounts class as part of DF-01058
        NSP_UpdateRelatedAccounts.updateRelatedAccounts( accountIdSet );
        // Update Account status to 'Prospecting' once opportunity is added and there are no assets
        NSP_UpdateRelatedAccounts.updateAccountStatus( accountIdSet );
        //
        if ( !newTaskOpportunityList.isEmpty() ) {
            NSP_EventAndTaskHelperFunctions.createTaskRecordsForNCSQueue( newTaskOpportunityList , null );
        }
        // added as a part of DF-01497
        NSP_OpportunityTriggerHelper.getRelatedACR( opportunityAccountIds , opportunityNewMap.keySet() );
        // publish sync events for all new opportunies...
        this.publishNewRecords( newList );
    }

    //
    // Iterates throught the Opportunity map and identifies the records that needs to worked based on various criterias.
    // @param opportunityNewMap Map of New Opportunity.
    // @param opportunityOldMap Map of Old Opportunity.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,Opportunity> opportunityNewMap , Map<Id,Opportunity> opportunityOldMap ) {
        //Creating collection of account and opportunity
        Set<String> accountIdSet =  new Set<String>();
        Set<String> MODaccountIdSet =  new Set<String>();
        Set<Id> ownerIdSet = new Set<Id>();
        Set<Id> MODownerIdSet = new Set<Id>();
        List<Opportunity> opportunityWoWxList =  new List<Opportunity>();
        List<Opportunity> opportunityNewAccountList = new List<Opportunity>();
        //list to store opportunities where Opportunity owner is changed
        List<Opportunity> ownerChangedOpptyList = new List<Opportunity>();
        List<Opportunity> stageChangedOpportunityList = new List<Opportunity>();
        List<Opportunity> opportunitiesToClosingStageList = new List<Opportunity>();
        List<Opportunity> lockOpportunitiesList = new List<Opportunity>();
        List<Opportunity> optyList = new List<Opportunity>();
        ID quoteId = null;

        List<Opportunity> updatePriceBookList = new List<Opportunity>();
        List<String> primaryProductChanged = new List<String>();

        //docusign merge template
        Set<String> docuSignTemplateName = new Set<String>();
        List<Opportunity> opptyListToStampDocusignTemplateId = new List<Opportunity>();
        List<Opportunity> closedOppList =  new List<Opportunity>();

        // AZD-191924 AZD-232114
        List<Opportunity> calculateFrees =  new List<Opportunity>();

        //Iterating over the new opportunity map
        for(Id opportunityId : opportunityNewMap.keySet()){

            Opportunity newOpportunity =  opportunityNewMap.get(opportunityId);
            Opportunity oldOpportunity =  opportunityOldMap.get(opportunityId);

            //  AZD-258129
            if ( NSP_hotfix_Switch__c.getInstance( UserInfo.getUserId() ).Is_Edit_Closed_Won_Allowed__c
                && ( newOpportunity.Create_Box_com_Folder_s__c != oldOpportunity.Create_Box_com_Folder_s__c )
                && ( newOpportunity.StageName == 'Closed Won' )
                )
            {
                Map<String,Object> changedFields = newOpportunity.getPopulatedFieldsAsMap();
                // Only the field Create_Box_com_Folder_s__c should be updated
                for ( String fieldName : changedFields.keySet() ) {
                    if ( !fieldName.equals( 'Create_Box_com_Folder_s__c' )
                        && ( newOpportunity.get( fieldName ) != oldOpportunity.get( fieldName ) )
                        )
                    {
                        newOpportunity.addError( Label.NSP_CANNOT_CHANGE_CLOSEDWON );
                        break;
                    }
                }
                continue;
            }

            // AZD-191924 AZD-232114 AZD-232117
            //  If primary product IS 'Workforce Optimization' then calculate fees
            if ( ( newOpportunity.NSP_PrimaryProduct__c != null )
                && String.isNotBlank( newOpportunity.Accountid )
                && NSP_ValidateOpportunityStage.validHRProducts.contains( newOpportunity.NSP_PrimaryProduct__c )
                && !newOpportunity.NSP_lock_enrollment_fee__c
                )
            {
                calculateFrees.add( newOpportunity );
            }

            if(newOpportunity.OwnerId != oldOpportunity.OwnerId){
                ownerChangedOpptyList.add(newOpportunity);
                ownerIdSet.add(newOpportunity.OwnerId);
            }

            //Checking if the account id updated on the record
            if(opportunityNewMap.get(opportunityId).Accountid != opportunityOldMap.get(opportunityId).Accountid){
                accountIdSet.add(opportunityNewMap.get(opportunityId).Accountid);
                opportunityNewAccountList.add(opportunityNewMap.get(opportunityId));
            }

            //Checking if the primary quote id updated on the record
            if(opportunityNewMap.get(opportunityId).SBQQ__PrimaryQuote__c != null){
                if(opportunityNewMap.get(opportunityId).SBQQ__PrimaryQuote__c != opportunityOldMap.get(opportunityId).SBQQ__PrimaryQuote__c){
                    quoteId = opportunityNewMap.get(opportunityId).SBQQ__PrimaryQuote__c;
                    optyList.add(opportunityNewMap.get(opportunityId));
                }
            }

            if ( opportunityNewMap.get(opportunityId).StageName != opportunityOldMap.get(opportunityId).StageName ) {
                String newStageName = opportunityNewMap.get(opportunityId).StageName;
                String oldStageName = opportunityOldMap.get(opportunityId).StageName;
                if ( NSP_OpportunityTriggerHelper.Is_Enabled_WO_WS_Stage_Entry
                    && !NSP_OpportunityTriggerHelper.hasAdminPermission
                    && ( opptyStageOrder.get( newStageName ) < opptyStageOrder.get( oldStageName ) )
                    && ( opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c == opportunityOldMap.get(opportunityId).NSP_PrimaryProduct__c )
                    && ( ( opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c == NSP_SalesConstants.WO )
                         || ( opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c == NSP_SalesConstants.WS )
                        )
                    )
                {
                    opportunityNewMap.get(opportunityId).addError( Label.Opportunity_Backward_Stage );
                }
                stageChangedOpportunityList.add( opportunityNewMap.get(opportunityId) );
            }

            if(opportunityNewMap.get(opportunityId).NSP_Signed_Delivery_Order__c && opportunityNewMap.get(opportunityId).NSP_Signed_Delivery_Order__c != opportunityOldMap.get(opportunityId).NSP_Signed_Delivery_Order__c){
                opportunityNewMap.get(opportunityId).NSP_Signed_Delivery_Order_Date__c = system.today();
            }

            if ( opportunityNewMap.get(opportunityId).StageName.equals(NSP_SalesConstants.PROPOSAL_STAGE)
                && ( opportunityNewMap.get(opportunityId).NSP_Closing_Appointment__c != opportunityOldMap.get(opportunityId).NSP_Closing_Appointment__c
                   || opportunityNewMap.get(opportunityId).NSP_Order_Generated__c != opportunityOldMap.get(opportunityId).NSP_Order_Generated__c
                   || opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c != opportunityOldMap.get(opportunityId).NSP_PrimaryProduct__c
                   || opportunityNewMap.get(opportunityId).NSP_Signed_Delivery_Order__c != opportunityOldMap.get(opportunityId).NSP_Signed_Delivery_Order__c
                   )
                && !contractProductTypes.contains(opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c)
                )
            {
                opportunitiesToClosingStageList.add(opportunityNewMap.get(opportunityId));
            }

            if(opportunityNewMap.get(opportunityId).StageName != opportunityOldMap.get(opportunityId).StageName
               && (opportunityNewMap.get(opportunityId).StageName.equals(NSP_SalesConstants.CLOSED_WON)
                   ||opportunityNewMap.get(opportunityId).StageName.equals(NSP_SalesConstants.CLOSED_LOST)) ){
                       lockOpportunitiesList.add(opportunityNewMap.get(opportunityId));
            }

            //Checking if the product type is changed on the record and is WO/WX
            //and the opty record is a parent opportunity
            if ( String.isnotBlank(opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c)
                && (opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WO)
                    || opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c.equals(NSP_SalesConstants.WX)
                    )
                && (opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c != opportunityOldMap.get(opportunityId).NSP_PrimaryProduct__c)
                && String.isBlank(opportunityNewMap.get(opportunityId).NSP_Parent_Opportunity__c)
                )
            {
                opportunityWoWxList.add(opportunityNewMap.get(opportunityId));
            }

            if(String.isNotBlank(opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c) &&
               (opportunityNewMap.get(opportunityId).NSP_PrimaryProduct__c != opportunityOldMap.get(opportunityId).NSP_PrimaryProduct__c)) {
                   updatePriceBookList.add(opportunityNewMap.get(opportunityId));
               }

            //create list to populate docusign template id for merge on demand templates
            if ( !String.isBlank(newOpportunity.NSP_Merge_On_Demand_Template_Selection__c)
                && newOpportunity.NSP_Merge_On_Demand_Template_Selection__c != oldOpportunity.NSP_Merge_On_Demand_Template_Selection__c
                )
            {
                opptyListToStampDocusignTemplateId.add(newOpportunity);
                MODaccountIdSet.add(newOpportunity.Accountid);
                MODownerIdSet.add(newOpportunity.OwnerId);
            }

            // checking for closeddate is lessthan today or Not
            if ( newOpportunity.CloseDate != null
                && newOpportunity.CloseDate < date.today()
                && newOpportunity.NSP_Insperity_Signer__c == oldOpportunity.NSP_Insperity_Signer__c
                )
            {
                closedOppList.add(newOpportunity);
            }
            checkPrimaryProductChange( newOpportunity , oldOpportunity , primaryProductChanged );
            // ADO-498657
            NSP_OpportunityTriggerHelper.setServicesOpportunity( oldOpportunity.OwnerId , newOpportunity.OwnerId , newOpportunity );
        }

        NSP_OpportunityTriggerHelperFunctions oppHelperFuncObj = new NSP_OpportunityTriggerHelperFunctions();
        oppHelperFuncObj.setDirectOpptyFieldsAssignments(opportunityNewMap.values());

        // Account list is empty or not
        oppHelperFuncObj.getAccountOwnerEmail( opportunityNewAccountList , accountIdSet );
        NSP_UserAndOwnerFunctions uofobj = new NSP_UserAndOwnerFunctions();
        if(!optyList.isEmpty()){
            uofobj.getQuoteOwner(optyList,quoteId);
        }
        // opportunity list is empty or not
        oppHelperFuncObj.stampWoWxEmailOnOpprtunity(opportunityWoWxList);

        //Validate opportunity stage progression
        NSP_ValidateOpportunityStage.validateOpportunityStage(stageChangedOpportunityList);

        moveOpportunityToClosingStage(opportunitiesToClosingStageList);
        changeOpportunityRecordType(lockOpportunitiesList);
        NSP_ChildOpportunitiesHelperFunctions childOpptyHlprObj = new NSP_ChildOpportunitiesHelperFunctions();
        childOpptyHlprObj.updateChildOpportunityOnProductChange(primaryProductChanged);

        if(ownerChangedOpptyList.size()>0){
            NSP_OpportunityTriggerHelperFunctions.populateServiceEmail(ownerChangedOpptyList, ownerIdSet);
        }

        //call method to populate template id
        if(opptyListToStampDocusignTemplateId.size() > 0){
            uofobj.setDummyUsers(opptyListToStampDocusignTemplateId,MODaccountIdSet,MODownerIdSet);
        }

        setSalesOfficeDetails(opportunityNewMap.values(),opportunityOldMap); // added for STY-03154
        NSP_LeadTriggerHelper.transferDiscoveryCall( opportunityNewMap , opportunityOldMap ); // ADO-437605
        // AZD-191924 AZD-232114
        if(!calculateFrees.isEmpty()){
            calculateEnrollmentFees(calculateFrees);
        }
    }

    // Iterates throught the list of new leads and passes the required attributes to other methods.
    // @param opportunityNewMap Map of New Opportunity.
    // @param opportunityOldMap Map of Old Opportunity.
    // @return void
    public void afterUpdateDirector( Map<Id,Opportunity> opportunityNewMap , Map<Id,Opportunity> opportunityOldMap ) {
        List<String> closedOpportunityIdList = new List<String>();
        List<String> closedWonOpportunityIdList = new List<String>();
        List<String> reopenedOpportunityIdList = new List<String>();
        Set<String> accountIdSet = new Set<String>();
        Set<String> recordTypeSet = new Set<String>();
        Set<String> backoutOptySet = new Set<String>();
        List<Opportunity> closedWonOpptyList = new List<Opportunity>();
        List<Id> stageAutoOpportunityIds = new List<Id>();
        List<Opportunity> closedOpptyList = new List<Opportunity>();
        List<String> productCodeList = new List<String>{'Employment Screening','Expense Management','Insurance Services'};
        //opportunity list to store oppty records where Primary Quote is newly created
        //List<Opportunity> opportunitiesWithPrimaryQuote = new List<Opportunity>();// commeted as part of user story 128436

        //Opportunity list to capture opportunities created with HSA contribution data
        List<Opportunity> newTaskOpportunityList = new List<Opportunity>();

        //opportunities with Partner Accounts populated
        Map<Id,Opportunity> partnerAccountOpportunityMap = new Map<Id,Opportunity>();
        //Sending list to update enrollment fee payment
        enrollmentFeeCheck(opportunityNewMap,opportunityOldMap);

        //List of string to store opportunity id fro changed sales tax records
        List<String> salesTaxChanged = new List<String>();

        //Iterating over the opportunity new map
        for ( Id opportunityId : opportunityNewMap.keySet() ) {
            Opportunity newOpportunity = opportunityNewMap.get( opportunityId );
            Opportunity oldOpportunity = opportunityOldMap.get( opportunityId );
            accountIdSet.add( newOpportunity.AccountId );
            stageAutoOpportunityIds = optyStageAutomationCheck( newOpportunity , oldOpportunity , stageAutoOpportunityIds );
            partnerAccountOpportunityMap = optyPartnerCheck( newOpportunity , oldOpportunity , partnerAccountOpportunityMap );
            closedOpportunityIdList = optyClosedLostCheck( newOpportunity , closedOpportunityIdList );
            reopenedOpportunityIdList = optyReopenCheck( newOpportunity , oldOpportunity , reopenedOpportunityIdList );
            closedWonOpptyList = optyClosedWonCheck( newOpportunity , oldOpportunity , productCodeList, closedWonOpptyList );
            closedWonOpportunityIdList = optyClosedWonParentCheck( newOpportunity , oldOpportunity , closedWonOpportunityIdList );
            closedOpptyList = optyClosedWonProductCheck( newOpportunity , oldOpportunity , productCodeList , closedOpptyList );
            newTaskOpportunityList = optyNewTaskCheck( newOpportunity , oldOpportunity , newTaskOpportunityList );
            backoutOptySet = optyBackoutCheck( newOpportunity , oldOpportunity , backoutOptySet );
            salesTaxChanged = optyTaxCheck( newOpportunity , oldOpportunity , salesTaxChanged );
        }
        // publish sync events for critically modified opportunies...
        this.publishCriticalRecords( opportunityNewMap , opportunityOldMap );
        if ( !closedOpportunityIdList.isEmpty() ) {
            NSP_ChildOpportunitiesHelperFunctions childHlprObj = new NSP_ChildOpportunitiesHelperFunctions();
            childHlprObj.updatesOnChildOpportunity( closedOpportunityIdList );
        }
        //569718-to send notification to open child opportunities - upsell opportunities enhancement
        if ( !closedWonOpportunityIdList.isEmpty() ) {
            NSP_ChildOpportunitiesHelperFunctions childHlprObj = new NSP_ChildOpportunitiesHelperFunctions();
            childHlprObj.updatesOnOpenChildOpportunity( closedWonOpportunityIdList );
        }
        if ( !reopenedOpportunityIdList.isEmpty() ) {
            NSP_ChildOpportunitiesHelperFunctions.updateChildOpportunityOnReopen( reopenedOpportunityIdList );
        }
        // Moving to NSP_UpdateRelatedAccounts class as part of DF-01058
        NSP_UpdateRelatedAccounts.updateRelatedAccounts( accountIdSet );
        recordTypeSet = optyGetRecTypeList( closedOpptyList , recordTypeSet );
        optyCreateAssets( closedWonOpptyList , closedOpptyList , accountIdSet , recordTypeSet );
        if ( newTaskOpportunityList.size() > 0 ) {
            NSP_EventAndTaskHelperFunctions.createTaskRecordsForNCSQueue( newTaskOpportunityList , null );
        }
        setPartnerAccount( partnerAccountOpportunityMap );
        NSP_EnrollmentFeePaymentSharing.onOppClose( opportunityNewMap );
        if ( backoutOptySet.size() > 0 ) {
            NSP_AssetUpdate.assetBackoutUpdate( backoutOptySet , NSP_SalesConstants.BACKOUT_STATUS );
        }
        AutomateOpportunityStage.automateOpportunityStageAsync( stageAutoOpportunityIds );
    }

    private Set<String> optyBackoutCheck( Opportunity newOpportunity , Opportunity oldOpportunity , Set<String> backoutOptySet ) {
        //Update the asset status to backout when opportunity backout flag is checked
        if ( newOpportunity.NSP_Back_Out__c != oldOpportunity.NSP_Back_Out__c
            && newOpportunity.NSP_Back_Out__c == true
            )
        {
            backoutOptySet.add( newOpportunity.Id );
        }
        return backoutOptySet;
    }

    private List<String> optyTaxCheck( Opportunity newOpportunity , Opportunity oldOpportunity , List<String> salesTaxChanged ) {
        if ( newOpportunity.AVA_SFCLOUD__Sales_Tax__c != oldOpportunity.AVA_SFCLOUD__Sales_Tax__c ) {
            salesTaxChanged.add( newOpportunity.Id );
        }
        return salesTaxChanged;
    }

    private List<Id> optyStageAutomationCheck(
        Opportunity newOpportunity ,
        Opportunity oldOpportunity ,
        List<Id> stageAutoOpportunityIds
        )
    {
        // Any field update related to Stage Exit/Entry should trigger Stage progression automation attempt
        if ( NSP_OpportunityTriggerHelper.Is_Enabled_WO_WS_Stage_Entry
            && ( newOpportunity.NSP_Bid_Status__c != oldOpportunity.NSP_Bid_Status__c
                || newOpportunity.NSP_Number_of_Employees__c != oldOpportunity.NSP_Number_of_Employees__c
                || newOpportunity.NSP_PrimaryProduct__c != oldOpportunity.NSP_PrimaryProduct__c
                || newOpportunity.NSP_Forecast_Status__c != oldOpportunity.NSP_Forecast_Status__c
                || newOpportunity.Fee_Inclusive__c != oldOpportunity.Fee_Inclusive__c
                || newOpportunity.CloseDate != oldOpportunity.CloseDate
                || newOpportunity.NSP_CountAsSale__c != oldOpportunity.NSP_CountAsSale__c
                || newOpportunity.NSP_Booked_Date__c != oldOpportunity.NSP_Booked_Date__c
                || newOpportunity.NSP_TotalAnnualPayroll__c != oldOpportunity.NSP_TotalAnnualPayroll__c
                || newOpportunity.NSP_Bypass_Docusign_Signature__c != oldOpportunity.NSP_Bypass_Docusign_Signature__c
                || newOpportunity.NSP_Order_Generated__c != oldOpportunity.NSP_Order_Generated__c
                || newOpportunity.NSP_Client_For_Life__c != oldOpportunity.NSP_Client_For_Life__c
                || newOpportunity.StageName != oldOpportunity.StageName
                || newOpportunity.Type != oldOpportunity.Type
                )
            )
        {
            stageAutoOpportunityIds.add(newOpportunity.Id);
        }
        return stageAutoOpportunityIds;
    }

    private void optyCreateAssets(List<Opportunity> closedWonOpptyList, List<Opportunity> closedOpptyList, Set<String> accountIdSet, Set<String> recordTypeSet){
        // Adding Automation switch to disable Asset creation on Opportunity Close Won
        NSP_AutomationSetting__mdt isAssetCreationEnabled = NSP_AutomationSetting__mdt.getInstance('NSP_AssetCreationFromOppty');
        if(!isAssetCreationEnabled.NSP_Disable__c || Test.isrunningTest() ) {
            //STY-01519 - Asset creation from Opportunity line item
            if(closedWonOpptyList.size() > 0){
                createAssetForCloseWonOpportunity(closedWonOpptyList);
                // commented as a part of Defect-DF-01797
                //NSP_EmailServicesUtility.sendEmailsTOService(closedWonOpptyList, opportunityNewMap, workforceProductsList);
            }
            if(closedOpptyList!= null && closedOpptyList.size() > 0){
                createAsset(closedOpptyList,accountIdSet,recordTypeSet);
            }
        }
    }

    private List<Opportunity> optyNewTaskCheck(
        Opportunity newOpportunity ,
        Opportunity oldOpportunity ,
        List<Opportunity> newTaskOpportunityList
        )
    {
        if ( NSP_ValidateOpportunityStage.validHRProducts.contains( newOpportunity.NSP_PrimaryProduct__c )
            && String.isNotBlank( newOpportunity.NSP_Contribution_Level__c )
            && String.isNotBlank( newOpportunity.NSP_Frequency_of_Distribution__c )
            && (
                String.isBlank( oldOpportunity.NSP_Contribution_Level__c )
                || String.isBlank( oldOpportunity.NSP_Frequency_of_Distribution__c )
                )
            )
        {
            newTaskOpportunityList.add( newOpportunity );
        }
        return newTaskOpportunityList;
    }

    private Map<Id,Opportunity> optyPartnerCheck(
        Opportunity newOpportunity ,
        Opportunity oldOpportunity ,
        Map<Id,Opportunity> partnerAccountOpportunityMap
        )
    {
        if ( ( newOpportunity.NSP_Signed_Delivery_Order__c && newOpportunity.NSP_Signed_Delivery_Order__c != oldOpportunity.NSP_Signed_Delivery_Order__c )
            || ( newOpportunity.NSP_MOD_Document_Signed__c && newOpportunity.NSP_MOD_Document_Signed__c != oldOpportunity.NSP_MOD_Document_Signed__c )
            )
        {
            partnerAccountOpportunityMap.put( newOpportunity.AccountId , newOpportunity );
        }
        return partnerAccountOpportunityMap;
    }

    private List<String> optyClosedLostCheck( Opportunity newOpportunity , List<String> closedOpportunityIdList ) {
        // if the parent opty is closed lost then adding it to the list
        if ( ( String.isBlank( newOpportunity.NSP_Parent_Opportunity__c ) || ( newOpportunity.NSP_Parent_Opportunity__c == null ) )
            && newOpportunity.StageName.equals( NSP_SalesConstants.CLOSED_LOST )
            )
        {
            closedOpportunityIdList.add(newOpportunity.Id);
        }
        return closedOpportunityIdList;
    }

    private List<String> optyReopenCheck(
        Opportunity newOpportunity ,
        Opportunity oldOpportunity ,
        List<String> reopenedOpportunityIdList
        )
    {
        // if the parent opty is reopened then adding it to the list
        if ( ( String.isBlank( newOpportunity.NSP_Parent_Opportunity__c ) || ( newOpportunity.NSP_Parent_Opportunity__c == null ) )
            && ( newOpportunity.StageName != oldOpportunity.StageName )
            && ( newOpportunity.StageName != NSP_SalesConstants.CLOSED_LOST )
            && ( newOpportunity.StageName != NSP_SalesConstants.CLOSED_WON )
            )
        {
            reopenedOpportunityIdList.add(newOpportunity.Id);
        }
        return reopenedOpportunityIdList;
    }

    private List<Opportunity> optyClosedWonCheck(
        Opportunity newOpportunity ,
        Opportunity oldOpportunity ,
        List<String> productCodeList ,
        List<Opportunity> closedWonOpptyList
        )
    {
        if ( ( newOpportunity.StageName != oldOpportunity.StageName )
            && newOpportunity.StageName.equals( NSP_SalesConstants.CLOSED_WON )
            && !productCodeList.contains( newOpportunity.NSP_PrimaryProduct__c )
            && newOpportunity.NSP_TransactionType__c != NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION )
        {
            closedWonOpptyList.add( newOpportunity );
        }
        return closedWonOpptyList;
    }

    private List<String> optyClosedWonParentCheck(
        Opportunity newOpportunity ,
        Opportunity oldOpportunity ,
        List<String> closedWonOpportunityIdList
        )
    {
        if ( ( newOpportunity.StageName != oldOpportunity.StageName )
            && newOpportunity.StageName.equals( NSP_SalesConstants.CLOSED_WON )
            && ( String.isBlank( newOpportunity.NSP_Parent_Opportunity__c ) || ( newOpportunity.NSP_Parent_Opportunity__c == null ) )
            )
        {
            closedWonOpportunityIdList.add( newOpportunity.Id );
        }
        return closedWonOpportunityIdList;
    }

    private List<Opportunity> optyClosedWonProductCheck(
        Opportunity newOpportunity ,
        Opportunity oldOpportunity ,
        List<String> productCodeList ,
        List<Opportunity> closedOpptyList
        )
    {
        if ( ( newOpportunity.StageName != oldOpportunity.StageName )
            && newOpportunity.StageName.equals( NSP_SalesConstants.CLOSED_WON )
            && productCodeList.contains( newOpportunity.NSP_PrimaryProduct__c )
            && ( newOpportunity.NSP_PrimaryProduct__c != null && productCodeList.contains( newOpportunity.NSP_PrimaryProduct__c ) )
            )
        {
            closedOpptyList.add( newOpportunity );
        }
        return closedOpptyList;
    }

    private Set<String> optyGetRecTypeList( List<Opportunity> opportunityList , Set<String> recordTypeSet ) {
        String rectype = null;
        for ( Opportunity opportunityRecord : opportunityList ) {
            if ( opportunityRecord.NSP_PrimaryProduct__c == NSP_SalesConstants.PROD_INSURANCE ) {
                rectype = NSP_OpportunityTriggerHelper.insuranceServiceAssetRecordTypeId;
            } else if ( opportunityRecord.NSP_PrimaryProduct__c == NSP_SalesConstants.PROD_EXPENSEMANAGEMENT ) {
                rectype = NSP_OpportunityTriggerHelper.certifyAssetRecordTypeId;
            } else {
                rectype = NSP_OpportunityTriggerHelper.getAssetRecordTypeIdByName( opportunityRecord.NSP_PrimaryProduct__c );
            }
            recordTypeSet.add( rectype );
        }
        return recordTypeSet;
    }

    //
    // When Opportunity in Proposal Stage meets all criterias then update the stage to Closing
    // @param opportunityList list of New Opportunity.
    // @return void
    //
    public void moveOpportunityToClosingStage( List<Opportunity> opportunityList ) {
        for ( Opportunity opportunityRecord : opportunityList ) {
            if ( ( opportunityRecord.NSP_Closing_Appointment__c != null )
                && (
                    ( NSP_ValidateOpportunityStage.validHRProducts.contains( opportunityRecord.NSP_PrimaryProduct__c )
                        && opportunityRecord.NSP_Signed_CSA__c
                        )
                    || ( ( opportunityRecord.NSP_PrimaryProduct__c == NSP_SalesConstants.WX
                            || opportunityRecord.NSP_PrimaryProduct__c == NSP_SalesConstants.WA
                            )
                        && opportunityRecord.NSP_Signed_Delivery_Order__c
                        )
                    || ( !NSP_ValidateOpportunityStage.validHRProducts.contains( opportunityRecord.NSP_PrimaryProduct__c )
                        && opportunityRecord.NSP_PrimaryProduct__c != NSP_SalesConstants.WX
                        && opportunityRecord.NSP_PrimaryProduct__c != NSP_SalesConstants.WA
                        )
                    )
                )
            {
                opportunityRecord.StageName = NSP_SalesConstants.CLOSING_STAGE;
            }
        }
    }

    //
    // When Opportunity in closed won/lost change the record type to lock the page layout
    // @param opportunityList list of New Opportunity.
    // @return void
    //
    public void changeOpportunityRecordType( List<Opportunity> opportunityList ) {
        for ( Opportunity opportunityRecord : opportunityList ) {
            opportunityRecord.RecordTypeId = NSP_OpportunityTriggerHelper.lockedOpportunityRecordTypeId;
        }
    }

    //
    // prevent the users when existing Business opportunity with Interest in Retirement
    // services for accounts who does not own WO products is created.
    // @param opportunityList list of New Opportunity.
    // @return void
    //
    public void retirementServicesForNonWOProducts( List<Opportunity> opportunityList ) {
        Map<Id, List<Asset>> accountIdAssetListMap = new Map<Id, List<Asset>>();
        Set<Id> accountIdsSet = new Set<Id>();

        for(Opportunity opportunityRecord : opportunityList){
            accountIdsSet.add(opportunityRecord.AccountId);
        }

        List<Asset> assetWithWOProductsList = [SELECT Id, AccountId,Name, Product2.NSP_Product_Type__c FROM Asset WHERE AccountId IN :accountIdsSet AND Product2.NSP_Product_Type__c = 'WOSS Bundle'];

        //create a map of AccountId and List of Assets for each account
        for(Asset assetRecord : assetWithWOProductsList){
            if(accountIdAssetListMap.containsKey(assetRecord.AccountId)){
                accountIdAssetListMap.get(assetRecord.AccountId).add(assetRecord);
            } else {
                accountIdAssetListMap.put(assetRecord.AccountId, new List<Asset> {assetRecord});
            }
        }

        for(Opportunity opportunityRecord : opportunityList){
            if(accountIdAssetListMap.containsKey(opportunityRecord.AccountId)) {
                if( accountIdAssetListMap.get(opportunityRecord.AccountId).size() == 0){
                    opportunityRecord.addError(RETIREMENT_SERVICES_FOR_NON_WO_PRODUCTS);
                }
            }else{
                opportunityRecord.addError(RETIREMENT_SERVICES_FOR_NON_WO_PRODUCTS);
            }
        }
    }

    //
    // Setting Opportunity Type to Renewal for Renewal Oportunities
    // copy value from original opportunity to renewal /Amendment opportunity
    // Stage = Proposal : Number of Employees = Populated from original opportunity.
    // @param opportunityList list of New Opportunity.
    // @return void
    //
    public void setTypeforRenewalOpportunity( List<Opportunity> opportunityList ) {

        set<Id> contractIdSet = new set<Id> ();

        for(Opportunity op : opportunityList){

            if(op.SBQQ__AmendedContract__c != null){
                if(op.NSP_TransactionType__c == NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION){
                    op.Type = NSP_SalesConstants.TRANSACTION_TYPE_TERMINATION;
                    op.StageName = NSP_SalesConstants.PROPOSAL_STAGE;
                    contractIdSet.add(op.SBQQ__AmendedContract__c);
                }else{
                    op.Type = NSP_SalesConstants.OPPORTUNITY_TYPE_EXISTING_PRODUCT;
                    op.CloseDate = DATE.TODAY()+30;
                    contractIdSet.add(op.SBQQ__AmendedContract__c);
                }
            }

            if(op.SBQQ__RenewedContract__c != null) {
                op.Type = NSP_SalesConstants.OPPORTUNITY_TYPE_RENEWAL;
                contractIdSet.add(op.SBQQ__RenewedContract__c);
            }
        }

        if(contractIdSet.Size() > 0){
            Map<Id,Contract> comtractMap = new Map<Id,Contract>([SELECT Id,SBQQ__Opportunity__c,
                                                                 SBQQ__Opportunity__r.NSP_PrimaryProduct__c,NSP_PrimaryProduct__c,
                                                                 SBQQ__Opportunity__r.NSP_Client_For_Life__c,NSP_Client_For_Life__c,
                                                                 SBQQ__Opportunity__r.NSP_Partner__c, NSP_Partner__c
                                                                 FROM Contract WHERE Id IN : contractIdSet ]);
            if(comtractMap.Size() > 0){
                for(Opportunity newOpportunty : opportunityList){
                    Id contractIdstr = newOpportunty.SBQQ__RenewedContract__c != null ? newOpportunty.SBQQ__RenewedContract__c :newOpportunty.SBQQ__AmendedContract__c != null ? newOpportunty.SBQQ__AmendedContract__c : null;
                    if(contractIdstr != null && comtractMap.containskey(contractIdstr)){
                        Contract objContract = comtractMap.get(contractIdstr);
                        if(objContract.SBQQ__Opportunity__c !=null) {
                        newOpportunty.NSP_PrimaryProduct__c = objContract.SBQQ__Opportunity__r.NSP_PrimaryProduct__c;
                        newOpportunty.NSP_Client_For_Life__c = objContract.SBQQ__Opportunity__r.NSP_Client_For_Life__c;
                        newOpportunty.NSP_Partner__c = objContract.SBQQ__Opportunity__r.NSP_Partner__c;
                    }
                        else {
                        newOpportunty.NSP_PrimaryProduct__c = objContract.NSP_PrimaryProduct__c;
                        newOpportunty.NSP_Client_For_Life__c = objContract.NSP_Client_For_Life__c;
                        newOpportunty.NSP_Partner__c = objContract.NSP_Partner__c;
                        }
                    }
                }
            }
        }

    }

    //
    // Integration Sync Methods
    //

    // Opportunity-after-insert
    private void publishNewRecords( List<Opportunity> records ) {
        // publish sync events for all new opportunies...
        Set<Id> syncIds = new Set<Id>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( Opportunity record : records ) {
                syncIds.add( record.Id );
            }
        }
        this.publishIntegrationSyncEvents(
            syncIds ,
            NSP_OpportunityTriggerHelper.isEnabledIntegrationOpportunityEvent
        );
    }

    // Opportunity-after-update
    private void publishCriticalRecords( Map<Id,Opportunity> opportunityNewMap , Map<Id,Opportunity> opportunityOldMap ) {
        // publish sync events for critically modified opportunies...
        Set<Id> criticalRecordIds = this.identifyCriticalRecordIds( opportunityNewMap , opportunityOldMap );
        Set<Id> syncIdsAnalysis = new Set<Id>();
        Set<Id> syncIds = new Set<Id>();
        if ( !criticalRecordIds.isEmpty() ){
            for ( Id recordId : criticalRecordIds ) {
                if ( this.isNewStageAnalysis( recordId, opportunityNewMap , opportunityOldMap ) ) {
                    syncIdsAnalysis.add( recordId );
                } else {
                    syncIds.add( recordId );
                }
            }
        }
        Boolean isEnabledSyncAnalysis = (
            NSP_OpportunityTriggerHelper.isEnabledIntegrationOpportunityEvent
            || NSP_OpportunityTriggerHelper.isEnabledOpportunityStageChangeEvent
        );
        this.publishIntegrationSyncEvents(
            syncIdsAnalysis ,
            isEnabledSyncAnalysis
        );
        this.publishIntegrationSyncEvents(
            syncIds ,
            NSP_OpportunityTriggerHelper.isEnabledIntegrationOpportunityEvent
        );
    }

    // identify opportunities with critical field changes...
    private Set<Id> identifyCriticalRecordIds( Map<Id,Opportunity> opportunityNewMap , Map<Id,Opportunity> opportunityOldMap ) {
        Set<Id> criticalRecordIds = new Set<Id>();
        if ( ( opportunityNewMap != null ) && ( opportunityOldMap != null ) ) {
            NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
            criticalRecordIds.addAll(
                sObjectUpdateObj.fetchUpdFieldsLst(
                    'Opportunity' ,
                    (Map<Id,sObject>)opportunityNewMap ,
                    (Map<Id,sObject>)opportunityOldMap
                )
            );
        }
        return criticalRecordIds;
    }

    // identify opportunities with StageName changed to 'Analysis'...
    private Boolean isNewStageAnalysis( Id recordId , Map<Id,Opportunity> opportunityNewMap , Map<Id,Opportunity> opportunityOldMap ) {
        Boolean response = false;
        if ( ( opportunityNewMap != null ) && ( opportunityOldMap != null )) {
            Opportunity newOpportunity = opportunityNewMap.get( recordId );
            Opportunity oldOpportunity = opportunityOldMap.get( recordId );
            if ( ( newOpportunity != null ) && ( oldOpportunity != null ) ) {
                response = (
                    ( newOpportunity.StageName != oldOpportunity.StageName )
                    && 'Analysis'.equalsIgnoreCase( newOpportunity.StageName )
                );
            }
        }
        return response;
    }

    // Event-after-insert
    // OpportunityTeamMember-after-insert
    // OpportunityTeamMember-after-update
    public static void setReadyForIntegrationSync( Set<Id> syncIds ) {
        if ( ( syncIds != null ) && !syncIds.isEmpty() ) {
            NSP_OpportunityTriggerHelper helper = new NSP_OpportunityTriggerHelper();
            helper.publishIntegrationSyncEvents(
                syncIds ,
                NSP_OpportunityTriggerHelper.isEnabledIntegrationOpportunityEvent
            );
        }
    }

    // Account-after-update (NSP_OpportunityTriggerHelperFunctions)
    public static void publishIntegrationSyncEvents( List<Opportunity> records ) {
        if ( ( records != null ) && !records.isEmpty() ) {
            Map<Id,Opportunity> recordMap = new Map<Id,Opportunity>( records );
            NSP_OpportunityTriggerHelper helper = new NSP_OpportunityTriggerHelper();
            helper.publishIntegrationSyncEvents(
                recordMap.keySet() ,
                NSP_OpportunityTriggerHelper.isEnabledIntegrationOpportunityEvent
            );
        }
    }

    private void publishIntegrationSyncEvents( Set<Id> syncIds , Boolean isEnabled ) {
        if ( isEnabled
            && ( syncIds != null )
            && !syncIds.isEmpty()
            )
        {
            List<Integration_Opportunity_Event__e> eventList = new List<Integration_Opportunity_Event__e>();
            for ( Id syncId : syncIds ) {
                eventList.add(
                    new Integration_Opportunity_Event__e(
                        Id__c=syncId
                    )
                );
            }
            this.publishEventBus( eventList );
        }
    }

    // Iterates throught the event list publish the records in event bus.
    private void publishEventBus( List<sObject> eventList ) {
        try {
            if ( ( eventList != null ) && !eventList.isEmpty() ) {
                List<Database.SaveResult> results = EventBus.publish( eventList );
                NSP_ErrorLogHandler.logResults(
                    NSP_OpportunityTriggerHelper.class.getName() ,
                    'publishEventBus:publish' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_OpportunityTriggerHelper.handleException( e , 'publishEventBus' );
        }
    }

    //
    // Custom Settings
    //

    private static PlatformEventSettings__c platformEventSettings {
        private get {
            if ( platformEventSettings == null ) {
                platformEventSettings = PlatformEventSettings__c.getInstance( UserInfo.getUserId() );
            }
            return platformEventSettings;
        }
        private set;
    }

    private static Boolean isEnabledIntegrationOpportunityEvent {
        private get {
            if ( isEnabledIntegrationOpportunityEvent == null ) {
                Boolean local = false;
                if ( NSP_OpportunityTriggerHelper.platformEventSettings != null ) {
                    local = NSP_OpportunityTriggerHelper.platformEventSettings.IsEnabled_IntegrationOpportunityEvent__c;
                }
                isEnabledIntegrationOpportunityEvent = local;
            }
            return isEnabledIntegrationOpportunityEvent;
        }
        private set;
    }

    private static Boolean isEnabledOpportunityStageChangeEvent {
        private get {
            if ( isEnabledOpportunityStageChangeEvent == null ) {
                Boolean local = false;
                if ( NSP_OpportunityTriggerHelper.platformEventSettings != null ) {
                    local = NSP_OpportunityTriggerHelper.platformEventSettings.IsEnabled_OpportunityStageChangeEvent__c;
                }
                isEnabledOpportunityStageChangeEvent = local;
            }
            return isEnabledOpportunityStageChangeEvent;
        }
        private set;
    }

    public static Boolean isEnabledFutureCustomerSigner {
        public get {
            if ( isEnabledFutureCustomerSigner == null ) {
                Boolean local = false;
                if ( NSP_OpportunityTriggerHelper.platformEventSettings != null ) {
                    local = NSP_OpportunityTriggerHelper.platformEventSettings.IsEnabled_FutureCustomerSigner__c;
                }
                isEnabledFutureCustomerSigner = local;
            }
            return isEnabledFutureCustomerSigner;
        }
        private set;
    }

    //
    // Iterates tthrough closed won oportunity and looks for product where asset should be created
    // @param closedWonOpptyList of closed won Opportunity.
    // @return void
    //
    public void createAssetForCloseWonOpportunity( List<Opportunity> closedWonOpptyList ) {
        createHardwareAssets(closedWonOpptyList);
        Set<Id> productIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,String> recordTypeMap = new Map<Id,String>();
        Set<String> recordIdSet = new Set<String>();
        //store all ret record id in diff set
        List<String> retProducts = new List<String>{'RET WO', 'RET Choice'};
        Set<String> retRecordIdSet = new Set<String>();
        String optyType = null;
        List<OpportunityLineItem> opptyLineItemList = [SELECT Name,Opportunity.accountId,NSP_Product_Name__c,NSP_AccountId__c,
                                                       Product2Id,Quantity,UnitPrice,NSP_Opportunity_Booked_Date__c,NSP_Signed_Delivery_Order_Date__c,
                                                       NSP_ProductType__c,NSP_ProductBundle__c,NSP_EmployeesAtSignature__c,Opportunity.Type,//if its required on Asset then we create a formula for it
                                                       NSP_Original_Sold_EE_Count__c,NSP_Primary_Product__c,Product2.NSP_ServiceAssetCategory__c,NSP_AssetProductLine__c,NSP_AccountName__c,NSP_Pricing_Model__c,NSP_TransitionType__c FROM OpportunityLineItem WHERE
                                                       Product2.NSP_Convert_to_Asset__c = TRUE AND  Product2.NSP_ServiceAssetCategory__c != 'Hardware Asset' AND
                                                       OpportunityId IN: closedWonOpptyList];

        for(OpportunityLineItem oppItem : opptyLineItemList){
            productIds.add(oppItem.Product2Id);
            accountIds.add(oppItem.Opportunity.accountId);
            if(oppItem.Product2.NSP_ServiceAssetCategory__c != null){
                String rectype = Schema.SObjectType.ASSET.getRecordTypeInfosByName().get(oppItem.Product2.NSP_ServiceAssetCategory__c).getRecordTypeId();
                recordTypeMap.put(oppItem.Product2Id,rectype);
                if( !retProducts.contains(oppItem.Product2.NSP_ServiceAssetCategory__c)){
                    recordIdSet.add(rectype);
                }else{
                    retRecordIdSet.add(rectype);
                }
                optyType = oppItem.Opportunity.Type;
            }
        }
        List<Asset> upsertList=new List<Asset>();
        New NSP_SrcToTargetObjectDataMover(null,'OppAsset') ;//initialize the class
        List<Asset> assetfromCopier= NSP_SrcToTargetObjectDataMover.getSourceDatainTarget( opptyLineItemList);
        Map<Id, Asset> assetMap = new Map<Id, asset>();
        for(Asset assetItem: assetfromCopier){
            assetMap.put(assetItem.Product2Id,assetItem);
        }
        List<Asset> existingAssets = [
            SELECT
                Id ,
                Name ,
                AccountId ,
                Product2Id ,
                NSP_ProductBundle__c ,
                Product2.NSP_ServiceAssetCategory__c ,
                NSP_Product_Line__c
            FROM Asset
            WHERE (
                ( AccountId IN :accountIds )
                AND (
                    (
                        ( RecordTypeId IN :recordIdSet )
                        AND ( Status != :NSP_SalesConstants.TERMINATED_STATUS )
                        AND ( Status != :NSP_SalesConstants.BACKOUT_STATUS )
                    )
                    OR ( RecordTypeId IN :retRecordIdSet )
                )
            )
        ];
        Boolean isAssetFound = false;
        for ( Id draftAsset : assetMap.keySet() ) {
            for ( Asset existingAsset : existingAssets ) {
                if ( assetMap.get(draftAsset).AccountId == existingAsset.AccountId ) {
                    if ( retProducts.contains( existingAsset.Product2.NSP_ServiceAssetCategory__c ) ) {
                        //RET assit exists
                        isAssetFound = true;
                        break;
                    }
                    if ( ( existingAsset.NSP_ProductBundle__c == NSP_SalesConstants.WOSS )
                        && ( ( assetMap.get(draftAsset).NSP_ProductBundle__c == NSP_SalesConstants.WX ) || ( assetMap.get(draftAsset).NSP_ProductBundle__c == NSP_SalesConstants.WA ) )
                        && ( optyType == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY )
                        )
                    {
                        isAssetFound = false;
                    } else if ( ( existingAsset.NSP_ProductBundle__c != NSP_SalesConstants.WOSS )
                        && ( assetMap.get(draftAsset).NSP_ProductBundle__c == NSP_SalesConstants.WO_WS )
                        && ( optyType == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY )
                        )
                    {
                        isAssetFound = false;
                    } else if ( ( ( existingAsset.NSP_Product_Line__c == NSP_SalesConstants.PROD_WA ) || ( existingAsset.NSP_Product_Line__c == NSP_salesConstants.PROD_WX ) )
                        && ( assetMap.get(draftAsset).NSP_Product_Line__c == NSP_SalesConstants.PROD_WA )
                        && ( assetMap.get(draftAsset).NSP_ProductBundle__c == NSP_SalesConstants.WOSS )
                        && ( optyType == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY )
                        )
                    {
                        //Condition to allow woss asset creation
                        isAssetFound = false;
                    } else if ( ( optyType == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY )
                        && ( assetMap.get(draftAsset).NSP_Product_Line__c == NSP_salesConstants.PROD_WX )
                        && ( assetMap.get(draftAsset).NSP_ProductBundle__c == NSP_SalesConstants.WX )
                        && ( existingAsset.NSP_Product_Line__c == NSP_SalesConstants.PROD_WA )
                        && ( ( existingAsset.NSP_ProductBundle__c == NSP_SalesConstants.WA )
                            || ( existingAsset.NSP_ProductBundle__c == NSP_OpportunityTriggerHelper.PAYROLL_ONLY )
                            )
                        )
                    {
                        isAssetFound = false;
                    } else {
                        isAssetFound = true;
                        break;
                    }
                }
            }
            assetMap.get(draftAsset).RecordTypeId = recordTypeMap.get(assetMap.get(draftAsset).Product2Id);
            String prodLine = assetMap.get(draftAsset).NSP_Product_Line__c;
            if( prodLine== NSP_SalesConstants.PROD_RECRUITING || prodLine == NSP_SalesConstants.PROD_EMPSCREENING || prodLine == NSP_SalesConstants.PROD_INSURANCE){
                assetMap.get(draftAsset).Status = NSP_SalesConstants.ONDEMAND_STATUS;
            } else{
                assetMap.get(draftAsset).Status = NSP_SalesConstants.ONBOARDING;
            }
            if(prodLine== NSP_SalesConstants.PROD_WX || prodLine== NSP_SalesConstants.PROD_WA){
                assetMap.get(draftAsset).Name = assetMap.get(draftAsset).NSP_AccountName__c + ' '+ '-' + ' ' +assetMap.get(draftAsset).NSP_ProductBundle__c;
                populateHRContractChanges(
                    assetMap.get( draftAsset ) ,
                    new Map<Id,Opportunity>( closedWonOpptyList )
                );
            }
            if(prodLine ==  NSP_SalesConstants.RETIREMENT_SERVICE){
                assetMap.get(draftAsset).NSP_Client_is_Lead_Parent__c = true;
            }
            assetMap.get(draftAsset).NSP_Signature_Date__c = System.today();
            if(assetMap.get(draftAsset).NSP_TransitionType__c != null && assetMap.get(draftAsset).NSP_TransitionType__c == NSP_SalesConstants.PEOTOWX){
                if(prodLine == NSP_SalesConstants.PROD_WX){
                    assetMap.get(draftAsset).NSP_ProductBundle__c = NSP_SalesConstants.WOTOWX;
                } else if(prodLine== NSP_SalesConstants.PROD_WA){
                    assetMap.get(draftAsset).NSP_ProductBundle__c = NSP_SalesConstants.WOTOWA;
                }
            }
            if(!isAssetFound){
                upsertList.add(assetMap.get(draftAsset));
            }
            isAssetFound=FALSE;
        }
        try{
            if(upsertList != null && upsertList.size() > 0){
                List<Database.UpsertResult> upsertResults = Database.upsert( upsertList, false);
                NSP_ErrorLogHandler.logResults(
                    NSP_OpportunityTriggerHelper.class.getName() ,
                    'createAssetForCloseWonOpportunity:upsert' ,
                    upsertResults
                );
            }
            //Create Purchased Products
            PurchasedProductsCreateBatch.executeBatch( closedWonOpptyList );
        } catch ( Exception e ) {
            NSP_OpportunityTriggerHelper.handleException( e , 'createAssetForCloseWonOpportunity' );
        }
    }

    //populates HRContract changes on the Asset from Opp
    private static void populateHRContractChanges( Asset draftAsset , Map<Id,Opportunity> oppMap ) {
        if ( ( oppMap != null )
            && ( draftAsset != null )
            && ( draftAsset.Opportunity__c != null )
            && ( oppMap.containsKey(draftAsset.Opportunity__c) )
            && ( oppMap.get(draftAsset.Opportunity__c).HRCore_Contract_Changes__c != null )
            )
        {
            draftAsset.HRCore_Contract_Changes__c = oppMap.get( draftAsset.Opportunity__c ).HRCore_Contract_Changes__c;
        }
    }

    //
    // Description: accepts a list of Opportunities with Partner accounts and
    // sets the Partner Lifecycle field on Account to Onboarding
    // @param : List<Opportunity>, Set<Id> AccountIdSet
    //
    public static void setPartnerAccount( Map<Id,Opportunity> partnerAccountOpportunityMap ) {
        List<Opportunity> opportunityList = partnerAccountOpportunityMap.values();
        Set<Id> accountsIdSet = partnerAccountOpportunityMap.keySet();
        Map<Id,Account> accountMap = new Map<Id,Account>([
            SELECT Id , NSP_Partner_Lifecycle__c , NSP_Onboarding_Contract_Date__c
            FROM Account
            WHERE (
                ( Id IN :accountsIdSet )
                AND ( NSP_Partner_Lifecycle__c != 'Onboarding' )
            )
        ]);
        List<Account> accountList = new List<Account>();
        for ( Opportunity opportunityRecord : opportunityList ) {
            if ( accountMap.containsKey( opportunityRecord.AccountId ) ) {
                Account accountRecord = accountMap.get(opportunityRecord.AccountId );
                if ( ( accountRecord != null ) && ( accountRecord.NSP_Partner_Lifecycle__c != 'Onboarding' ) ) {
                    accountRecord.NSP_Partner_Lifecycle__c = 'Onboarding';
                    accountRecord.NSP_Onboarding_Contract_Date__c = System.today();
                    accountList.add( accountRecord );
                }
            }
        }
        if ( !accountList.isEmpty() ) {
            List<Database.SaveResult> results = Database.update( accountList , false );
            NSP_ErrorLogHandler.logResults(
                NSP_OpportunityTriggerHelper.class.getName() ,
                'setPartnerAccount' ,
                results
            );
        }
    }

    private static void getRelatedACR( Set<Id> accountIds , Set<Id> opportunityIds ) {
        Map<Id,AccountContactRelation> accountACRMap = new Map<Id,AccountContactRelation>();
        Set<Id> oppAccountIds = new Set<Id>();
        for ( AccountContactRelation accountContactRelation: [
                    SELECT
                        Id ,
                        ContactId ,
                        NSP_Is_Primary__c ,
                        AccountId
                    FROM AccountContactRelation
                    WHERE (
                        ( NSP_Is_Primary__c = true )
                        AND ( AccountId IN :accountIds )
                    )
                ]
            )
        {
            accountACRMap.put(
                accountContactRelation.AccountId ,
                accountContactRelation
            );
        }
        List<Opportunity> records = [
            SELECT Id , AccountId
            FROM Opportunity
            WHERE ( Id IN :opportunityIds )
        ];
        for ( Opportunity opp : records ) {
            if ( accountACRMap.containsKey( opp.AccountId )
                && ( accountACRMap.get( opp.AccountId ) != null )
                )
            {
                oppAccountIds.add( opp.AccountId );
            }
        }
        if ( !oppAccountIds.isEmpty() ) {
            NSP_OpportunityTriggerHelperFunctions.populatePrimaryContactCustomerSigner( oppAccountIds );
        }
    }

    //
    // Description: This method sets sales office details from user
    // @param: opportunityList, opportunityMap
    // @return: void
    // Modification History:
    // -------------------------------------------------------------------------------------
    //  Date | Description
    // -------------------------------------------------------------------------------------
    //  08/05/2022 created this new method added for STY-03154
    //
    public void setSalesOfficeDetails(List<Opportunity> newList,Map<Id, Opportunity> opportunityOldMap){
        set<Id> ownerIdSet = new set<Id>(); // owner id set
        set<string> officeSet = new set<string>(); // sales office set
        set<Id> recordToProcess = new set<Id>();  // record to be process set
        set<string> opportunityStageSet = new set<string>{'Prospecting','Discovery','Data Collection','Analysis','Proposal','Closing','Booking'};
        for(Opportunity newOpportunity: newList){
            Opportunity oldOpportunity = opportunityOldMap != null ? opportunityOldMap.get(newOpportunity.Id):null;
            if((Trigger.isInsert || newOpportunity.OwnerId != oldOpportunity.OwnerId)
               && newOpportunity.OwnerId != null && opportunityStageSet.contains(newOpportunity.StageName)){ // value assigned when owner is changed

                ownerIdSet.add(newOpportunity.OwnerId);
            }
            else if(Trigger.isUpdate && newOpportunity.NSP_Sales_Office__c != oldOpportunity.NSP_Sales_Office__c && String.isNotBlank(newOpportunity.NSP_Sales_Office__c) && !valueAssignedFromUser ){ // value assigned when sales office is changed.

                recordToProcess.add(newOpportunity.Id);
                officeSet.add(newOpportunity.NSP_Sales_Office__c);
            }
        }

        if(ownerIdSet.Size() > 0){
            // values assigned from users
            Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user WHERE Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
            for(Opportunity newOpportunity: newList){
                Opportunity oldOpportunity = opportunityOldMap != null ? opportunityOldMap.get(newOpportunity.Id):null;
                if((Trigger.isInsert || newOpportunity.OwnerId != oldOpportunity.OwnerId) && newOpportunity.OwnerId != null && userIdMap.containsKey(newOpportunity.OwnerId)){
                    user eachUser = userIdMap.get(newOpportunity.OwnerId);
                    newOpportunity.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                    newOpportunity.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newOpportunity.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                    valueAssignedFromUser = true;
                }
            }
        }
        // values assigned from sales office mapping
        if(officeSet.Size() > 0){
            map<String,NSP_Sales_Office_Mapping__c> salesOfficeToMappingMap =  new map<String,NSP_Sales_Office_Mapping__c>();
            for(NSP_Sales_Office_Mapping__c eachMapping : [SELECT Id,NSP_Sales_Office__c,NSP_Sales_Division__c,NSP_Sales_Region__c
                                                            FROM NSP_Sales_Office_Mapping__c
                                                            WHERE NSP_Sales_Office__c In : officeSet AND isActive__c = true]){
                salesOfficeToMappingMap.put(eachMapping.NSP_Sales_Office__c,eachMapping);
            }

            for(Opportunity newOpportunity: newList){
                if(Trigger.isUpdate && recordToProcess.contains(newOpportunity.Id) && salesOfficeToMappingMap.containsKey(newOpportunity.NSP_Sales_Office__c)){
                    NSP_Sales_Office_Mapping__c officeMapping = salesOfficeToMappingMap.get(newOpportunity.NSP_Sales_Office__c);
                    newOpportunity.NSP_Sales_Region__c = officeMapping.NSP_Sales_Region__c; // sales region
                    newOpportunity.NSP_Sales_Division__c = officeMapping.NSP_Sales_Division__c; // sales division
                }
            }
        }
    }

    //
    // Description: This method used to create rewards record for Contact role
    // @param: opportunityList, opportunityMap
    // @return: void
    //
    public void creteRewardForContactRole( Map<Id,Opportunity> opportunityNewMap , Map<Id,Opportunity> opportunityOldMap ) {
        set<String> primaryProductSet = new set<String>{'WX','WA','WO'};
        map<Id,String> opportunityIdToRewardTypeMap = new map<Id,String>();
        for(Opportunity newOpportunity: opportunityNewMap.Values()){
            Opportunity oldOpportunity = opportunityOldMap != null ? opportunityOldMap.get(newOpportunity.Id):null;
            if(newOpportunity.Type != 'Client Growth Credit'){ // added for DF-02233

                if(opportunityOldMap != null && newOpportunity.Discovery_Completed__c && !oldOpportunity.Discovery_Completed__c && String.isNotBlank(newOpportunity.NSP_PrimaryProduct__c) && primaryProductSet.contains(newOpportunity.NSP_PrimaryProduct__c)){
                    opportunityIdToRewardTypeMap.put(newOpportunity.Id,'Discovery');
                }
                else if(opportunityOldMap != null && newOpportunity.Nsp_1st_Pay_Invoice_Date_Reporting__c != null && oldOpportunity.Nsp_1st_Pay_Invoice_Date_Reporting__c == null && String.isNotBlank(newOpportunity.NSP_PrimaryProduct__c) && primaryProductSet.contains(newOpportunity.NSP_PrimaryProduct__c)){
                    opportunityIdToRewardTypeMap.put(newOpportunity.Id,'Sold');
                }
            }

        }

        if(opportunityIdToRewardTypeMap.Size() > 0){
            list<NSP_Reward__c> rewardsInsertList = new list<NSP_Reward__c>();
            map<id,Event> oppottunityToEventMap = new map<id,Event>();
            for ( Event eachEvent : [
                        SELECT Id , NSP_Completed_Date__c , WhatId
                        FROM Event
                        WHERE (
                            WhatId IN :opportunityIdToRewardTypeMap.KeySet()
                            AND NSP_Event_Subtype__c = 'Discovery Call'
                            AND NSP_Status__c = 'Completed'
                        )
                    ]
                )
            {
                oppottunityToEventMap.put(eachEvent.WhatId,eachEvent);
            }
            for ( OpportunityContactRole eachOCR : [
                        SELECT
                        Id , OpportunityId , Opportunity.NSP_Number_of_EEs__c , ContactId ,
                        Role , Opportunity.AccountId , NSP_Referralbenefitsanonprofitorg__c ,
                        NSP_Nonprofit_Organization_Name__c , NSP_Nonprofit_Organization_Tax_Id__c
                        FROM OpportunityContactRole
                        WHERE (
                            OpportunityId IN :opportunityIdToRewardTypeMap.keySet()
                            AND NSP_isReferral__c = true
                        )
                    ]
                )
            {
                string rewardType = opportunityIdToRewardTypeMap.get(eachOCR.opportunityId);
                opportunity currentOppty = opportunityNewMap.get(eachOCR.opportunityId);
                if(rewardType == 'Discovery'){
                    NSP_Reward__c newReward = createRewards(eachOCR, currentOppty);
                    if(String.isNotBlank(eachOCR.NSP_Referralbenefitsanonprofitorg__c)
                        && eachOCR.NSP_Referralbenefitsanonprofitorg__c == 'Match'
                        )
                    {
                        newReward.NSP_Reward_Amount__c = 200;
                        newReward.NSP_Nonprofit_Amount__c = 200;
                        newReward.NSP_Payment_Type_Reward__c = 'Check';
                        newReward.NSP_Payment_Type_Non_Profit__c = 'Check';
                    } else if(String.isNotBlank(eachOCR.NSP_Referralbenefitsanonprofitorg__c)
                        && eachOCR.NSP_Referralbenefitsanonprofitorg__c == 'Donation'
                        )
                    {
                        newReward.NSP_Reward_Amount__c = 0;
                        newReward.NSP_Nonprofit_Amount__c = 200;
                        newReward.NSP_Payment_Type_Reward__c = null;
                        newReward.NSP_Payment_Type_Non_Profit__c = 'Check';
                    } else{
                        newReward.NSP_Reward_Amount__c = 200;
                        newReward.NSP_Nonprofit_Amount__c = 0;
                        newReward.NSP_Payment_Type_Reward__c = 'Check';
                        newReward.NSP_Payment_Type_Non_Profit__c = null;

                    }
                    newReward.NSP_Reward_Type__c = 'Discovery';
                    newReward.NSP_Discovery_Call_Completed_Date__c = (
                        oppottunityToEventMap.containsKey(eachOCR.opportunityId)
                        ? oppottunityToEventMap.get(eachOCR.opportunityId).NSP_Completed_Date__c
                        : null
                    );
                    rewardsInsertList.add(newReward);
                } else if ( rewardType == 'Sold'
                    && (eachOCR.Role == 'Agency' || currentOppty.NSP_Number_of_Employees__c >= 5)
                    )
                {
                    NSP_Reward__c newReward = createRewards(eachOCR, currentOppty);
                    if( String.isNotBlank(eachOCR.NSP_Referralbenefitsanonprofitorg__c)
                        && eachOCR.NSP_Referralbenefitsanonprofitorg__c == 'Match'
                        )
                    {
                        newReward.NSP_Reward_Amount__c = 500;
                        newReward.NSP_Nonprofit_Amount__c = 500;
                        newReward.NSP_Payment_Type_Reward__c = 'Check';
                        newReward.NSP_Payment_Type_Non_Profit__c = 'Check';

                    } else if ( String.isNotBlank(eachOCR.NSP_Referralbenefitsanonprofitorg__c)
                        && eachOCR.NSP_Referralbenefitsanonprofitorg__c == 'Donation'
                        )
                    {
                        newReward.NSP_Reward_Amount__c = 0;
                        newReward.NSP_Nonprofit_Amount__c = 1000;
                        newReward.NSP_Payment_Type_Reward__c = null;
                        newReward.NSP_Payment_Type_Non_Profit__c = 'Check';
                    } else{
                        newReward.NSP_Reward_Amount__c = 1000;
                        newReward.NSP_Nonprofit_Amount__c = 0;
                        newReward.NSP_Payment_Type_Reward__c = 'Check';
                        newReward.NSP_Payment_Type_Non_Profit__c = null;

                    }
                    newReward.NSP_Reward_Type__c = 'Sold';
                    rewardsInsertList.add(newReward);
                }
            }
            if(rewardsInsertList.Size() > 0 && !createRewardsOnce ){
                createRewardsOnce  = true;
                Database.insert( rewardsInsertList , false );
            }
        }
    }

    public NSP_Reward__c createRewards(OpportunityContactRole objOCR, opportunity objOpportunity){
        NSP_Reward__c newReward = new NSP_Reward__c();
        newReward.NSP_Account__c = objOCR.Opportunity.AccountId;
        newReward.NSP_Benefits_Non_Profit__c = objOCR.NSP_Referralbenefitsanonprofitorg__c;
        newReward.NSP_Contact__c = objOCR.ContactId;
        newReward.Opportunity__c = objOpportunity.Id;
        newReward.NSP_Contact_Role__c = objOCR.Role;
        newReward.NSP_Non_ProfitName__c = objOCR.NSP_Nonprofit_Organization_Name__c;
        newReward.NSP_Non_Profit_TaxID__c = objOCR.NSP_Nonprofit_Organization_Tax_Id__c;
        newReward.NSP_Non_Profit_Address__c = objOpportunity.NSP_NonprofitNameAddress__c;
        return newReward;
    }

    //
    // Iterates tthrough closed won oportunity and looks for product where asset should be created
    // @param closedWonOpptyList of closed won Opportunity.
    // @return void
    //
    public void createAsset( List<Opportunity> closedWonOpptyList , Set<String> accountIdSet , Set<String> recordTypeSet ) {
        Set<Id> productIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,String> recordTypeMap = new Map<Id,String>();
        Set<String> recordIdSet = new Set<String>();
        String optyType = null;

        List<Asset> upsertList=new List<Asset>();
        New NSP_SrcToTargetObjectDataMover(null,'OpportunityAsset') ;//initialize the class
        List<Asset> assetfromCopier= NSP_SrcToTargetObjectDataMover.getSourceDatainTarget(closedWonOpptyList);
        Map<Id, Asset> assetMap = new Map<Id, asset>();
        for(Asset assetItem: assetfromCopier){
            assetMap.put(assetItem.AccountId,assetItem);
        }
        List<Asset> existingAssets = [SELECT Id,Name,AccountId,Product2Id,NSP_ProductBundle__c FROM Asset WHERE  AccountId IN :accountIdSet AND RecordTypeId IN :recordTypeSet AND  Status != :NSP_SalesConstants.TERMINATED_STATUS AND Status != :NSP_SalesConstants.BACKOUT_STATUS];
        Boolean isAssetFound=FALSE;
        for(Id draftAsset:assetMap.keySet()){
            for(Asset existingAsset: existingAssets ){
                if(assetMap.get(draftAsset).AccountId == existingAsset.AccountId){
                    isAssetFound=TRUE;
                    break;
                }
            }
            if(assetMap.get(draftAsset).NSP_Product_Line__c == NSP_SalesConstants.PROD_INSURANCE){
                assetMap.get(draftAsset).RecordTypeId = Schema.SObjectType.ASSET.getRecordTypeInfosByName().get(NSP_SalesConstants.ASSETRECTYPE_INSURANCE).getRecordTypeId();
            }
            else if(assetMap.get(draftAsset).NSP_Product_Line__c == NSP_SalesConstants.PROD_EXPENSEMANAGEMENT){
                String rectype = Schema.SObjectType.ASSET.getRecordTypeInfosByName().get(NSP_SalesConstants.ASSETRECTYPE_CERTIFY).getRecordTypeId();
                assetMap.get(draftAsset).RecordTypeId = rectype;
            } else {
                assetMap.get(draftAsset).RecordTypeId = Schema.SObjectType.ASSET.getRecordTypeInfosByName().get(assetMap.get(draftAsset).NSP_Product_Line__c).getRecordTypeId();
            }
            String prodLine = assetMap.get(draftAsset).NSP_Product_Line__c;
            if( prodLine== NSP_SalesConstants.PROD_RECRUITING || prodLine == NSP_SalesConstants.PROD_EMPSCREENING || prodLine == NSP_SalesConstants.PROD_INSURANCE){
                assetMap.get(draftAsset).Status = NSP_SalesConstants.ONDEMAND_STATUS;
            } else{
                assetMap.get(draftAsset).Status = NSP_SalesConstants.ONBOARDING;
            }
            if(prodLine== NSP_SalesConstants.PROD_WX || prodLine== NSP_SalesConstants.PROD_WA){
                assetMap.get(draftAsset).Name = assetMap.get(draftAsset).NSP_AccountName__c + ' '+ '-' + ' ' +assetMap.get(draftAsset).NSP_ProductBundle__c;
                populateHRContractChanges(
                    assetMap.get( draftAsset ) ,
                    new Map<Id,Opportunity>( closedWonOpptyList )
                );
            } else {
                assetMap.get(draftAsset).Name = assetMap.get(draftAsset).NSP_AccountName__c + ' '+ '-' + ' ' +prodLine;
            }
            assetMap.get(draftAsset).NSP_Signature_Date__c = System.today();
            if(!isAssetFound){
                upsertList.add(assetMap.get(draftAsset));
            }
            isAssetFound=FALSE;
        }
        try{
            if(upsertList != null && upsertList.size() > 0){
                upsert upsertList;
            }
        } catch ( Exception e ) {
            NSP_OpportunityTriggerHelper.handleException( e , 'createAsset' );
        }
    }

    //
    // MethodName: enrollmentFeeCheck
    // Description : This method will update enrollment fee payment
    // Params: Map<Id, Opportunity> opportunityNewMap,Map<Id, Opportunity> opportunityOldMap
    //
    public void enrollmentFeeCheck( Map<Id,Opportunity> opportunityNewMap , Map<Id,Opportunity> opportunityOldMap ) {
        set<Id> oppIdTrue = new set<Id>();
        set<Id> oppIdFalse = new set<Id>();
        list<NSP_Enrollment_Fee_Payment__c> enrollmentUpdateList = new list<NSP_Enrollment_Fee_Payment__c>();
        for(Opportunity newOpportunity: opportunityNewMap.Values()){
            Opportunity oldOpportunity = opportunityOldMap != null ? opportunityOldMap.get(newOpportunity.Id):null;
            //Modified for user story 192368
            if( ( newOpportunity.NSP_Number_of_Employees__c != oldOpportunity.NSP_Number_of_Employees__c && newOpportunity.NSP_Number_of_Employees__c >= 150 )
                || ( oldOpportunity.NSP_MidMarketNationalAccount__c == null && newOpportunity.NSP_MidMarketNationalAccount__c != null )
                )
            {
                oppIdTrue.add(newOpportunity.Id);
            } else if ( ( newOpportunity.NSP_Number_of_Employees__c != oldOpportunity.NSP_Number_of_Employees__c && newOpportunity.NSP_Number_of_Employees__c < 150 )
                || ( oldOpportunity.NSP_MidMarketNationalAccount__c != null && newOpportunity.NSP_MidMarketNationalAccount__c == null )
                )
            {
                oppIdFalse.add(newOpportunity.Id);
            }
        }
        if(oppIdTrue.Size() > 0){

               for(NSP_Enrollment_Fee_Payment__c eachEnrollment : [SELECT Id FROM NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__c in :oppIdTrue]){
                  NSP_Enrollment_Fee_Payment__c newEnrollment = new NSP_Enrollment_Fee_Payment__c();
                  newEnrollment.Id = eachEnrollment.Id;
                  newEnrollment.NSP_Is_MidMarket__c = True;
                  enrollmentUpdateList.add(newEnrollment);
                }
        }
        else if(oppIdFalse.Size() > 0){

               for(NSP_Enrollment_Fee_Payment__c eachEnrollment : [SELECT Id FROM NSP_Enrollment_Fee_Payment__c WHERE NSP_Opportunity__c in :oppIdFalse]){
                  NSP_Enrollment_Fee_Payment__c newEnrollment = new NSP_Enrollment_Fee_Payment__c();
                  newEnrollment.Id = eachEnrollment.Id;
                  newEnrollment.NSP_Is_MidMarket__c = False;
                  enrollmentUpdateList.add(newEnrollment);
            }
        }
        try{
            if(enrollmentUpdateList.Size() > 0){
                update enrollmentUpdateList;
            }
        } catch ( Exception e ) {
            NSP_OpportunityTriggerHelper.handleException( e , 'enrollmentFeeCheck' );
        }
    }


    //
    // Description: This Method will aggregate Sales Tax from Opty Products to Opportunity based on some conditions
    // Created By: CPQ Team
    // Created Date:12/05/2022
    //
    public void calculateSetUpAndDocupayTax( Map<Id,Opportunity> opportunityNewMap , Map<Id,Opportunity> opportunityOldMap ) {
        try {
            Set<Id> optyWithSalesTax = new Set<Id>(); // store all the Opty Ids where Sales Tax is Stamped
            for ( Opportunity opty:opportunityNewMap.values() ) {
                if ( ( opty.AVA_SFCLOUD__Sales_Tax__c != null )
                    && ( opty.AVA_SFCLOUD__Sales_Tax__c != opportunityOldMap.get(opty.Id).AVA_SFCLOUD__Sales_Tax__c )
                    && ( opty.Type == NSP_SalesConstants.NEW_BUSINESS_OPPORTUNITY )
                    && ( ( opty.NSP_PrimaryProduct__c == NSP_SalesConstants.WX )
                        || ( opty.NSP_PrimaryProduct__c == NSP_SalesConstants.WA )
                        || ( opty.NSP_PrimaryProduct__c == NSP_SalesConstants.CONTRACTOR_MANAGEMENT )
                        )
                    )
                {
                    optyWithSalesTax.add( opty.Id );
                }
            }
            Map<Id,Opportunity> optysToUpdate = new Map<Id,Opportunity>(); //Map, Key as Oppty Id and Value as Oppty
            if ( !optyWithSalesTax.isEmpty() ) {
                List<OpportunityLineItem> optyLines = [
                    SELECT Id,AVA_SFCLOUD__SalesTax_Line__c,ProductCode,Product2.NSP_Default_Invoice_Plan__c,Product2.SBQQ__BillingFrequency__c,OpportunityId
                    FROM OpportunityLineItem
                    WHERE ( OpportunityId IN :optyWithSalesTax )
                ];
                for ( OpportunityLineItem line:optyLines ) {
                    if ( ( line.ProductCode == NSP_CPQConstants.IWXSU )
                        || ( line.ProductCode == NSP_CPQConstants.IWASU )
                        || ( line.ProductCode == NSP_CPQConstants.CSUF )
                        )
                    {
                        if ( !optysToUpdate.containsKey( line.OpportunityId ) ) {
                            Opportunity opty = new Opportunity(
                                Id=line.OpportunityId ,
                                NSP_Enrollment_Fee_Tax__c=line.AVA_SFCLOUD__SalesTax_Line__c ,
                                NSP_Docupay_Upfront_fee_Tax__c=0
                            );
                            optysToUpdate.put( line.OpportunityId , opty );
                        } else {
                            Opportunity tempOpty = optysToUpdate.get( line.OpportunityId );
                            tempOpty.NSP_Enrollment_Fee_Tax__c = line.AVA_SFCLOUD__SalesTax_Line__c;
                            optysToUpdate.put( line.OpportunityId , tempOpty );
                        }
                    }
                    if ( ( line.Product2.SBQQ__BillingFrequency__c == NSP_CPQConstants.ANNUAL )
                        || ( ( line.Product2.SBQQ__BillingFrequency__c == NSP_CPQConstants.INVOICE_PLAN )
                            && ( line.Product2.NSP_Default_Invoice_Plan__c == NSP_CPQConstants.INVOICE_UP_FRONT_PLAN )
                            )
                        )
                    {
                        if ( !optysToUpdate.containsKey( line.OpportunityId ) ) {
                            Opportunity opty = new Opportunity(
                                Id=line.OpportunityId ,
                                NSP_Enrollment_Fee_Tax__c=0 ,
                                NSP_Docupay_Upfront_fee_Tax__c=line.AVA_SFCLOUD__SalesTax_Line__c
                            );
                            optysToUpdate.put( line.OpportunityId , opty );
                        } else {
                            Opportunity tempOpty = optysToUpdate.get( line.OpportunityId );
                            tempOpty.NSP_Docupay_Upfront_fee_Tax__c = ( line.AVA_SFCLOUD__SalesTax_Line__c + optysToUpdate.get( line.OpportunityId ).NSP_Docupay_Upfront_fee_Tax__c );
                            optysToUpdate.put( line.OpportunityId , tempOpty );
                        }
                    }
                }
            }
            if ( !optysToUpdate.isEmpty() ) {
                update optysToUpdate.values();
            }
        } catch ( Exception e ) {
            NSP_OpportunityTriggerHelper.handleException( e , 'calculateSetUpAndDocupayTax' );
        }
    }

    //
    // Method Name : createHardwareAssets
    // Description : Method to create hardware assets
    // @param List of closed won opportunities
    // @return void
    //
    private void createHardwareAssets( List<Opportunity> closedWonOpptyList ) {
        List<Asset> assetsToCreate= new List<Asset>();
        String rectype = Schema.SObjectType.ASSET.getRecordTypeInfosByName().get(NSP_CPQConstants.HARDWARE_ASSET).getRecordTypeId();
        List<OpportunityLineItem> opptyLineItemList=[SELECT Name,Opportunity.accountId,OpportunityId,SBQQ__QuoteLine__r.SBQQ__EndDate__c,Product2Id,Quantity,Product2.NSP_ServiceAssetCategory__c,NSP_AccountName__c,SBQQ__QuoteLine__r.SBQQ__Quote__r.NSP_Billing_Account__c,SBQQ__QuoteLine__r.NSP_Support_ProductCode__c,SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c,SBQQ__QuoteLine__r.NSP_ActionType__c,SBQQ__QuoteLine__r.NSP_Product_Type__c
                                                     FROM OpportunityLineItem
                                                     WHERE Product2.NSP_Convert_to_Asset__c = TRUE
                                                     AND OpportunityId IN: closedWonOpptyList AND Product2.NSP_ServiceAssetCategory__c=:NSP_CPQConstants.HARDWARE_ASSET];
        for(OpportunityLineItem oppItem : opptyLineItemList){
            if(oppItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.SBQQ__Type__c==NSP_CPQConstants.QUOTE_TYPE_NEW ||oppItem.SBQQ__QuoteLine__r.NSP_ActionType__c==NSP_CPQConstants.ACTION_NEW){
                for(Integer ints=0;ints<oppItem.Quantity;ints++){
                    Asset hardwareAsset= new Asset();
                    hardwareAsset.Name=oppItem.NSP_AccountName__c+' -'+NSP_CPQConstants.HARDWARE;
                    hardwareAsset.Product2Id=oppItem.Product2Id;
                    hardwareAsset.NSP_Support__c=true;
                    hardwareAsset.Status=NSP_CPQConstants.PURCHASED;
                    if(oppItem.SBQQ__QuoteLine__r.NSP_Product_Type__c==NSP_CPQConstants.TIME_AND_ATTENDANCE){
                        hardwareAsset.NSP_Contract_Length__c='365';
                    }
                    hardwareAsset.NSP_Billing_Account__c=oppItem.SBQQ__QuoteLine__r.SBQQ__Quote__r.NSP_Billing_Account__c;
                    hardwareAsset.NSP_Date_Purchased__c=system.today();
                    hardwareAsset.NSP_Licenses__c=1;
                    hardwareAsset.AccountId=oppItem.Opportunity.accountId;
                    hardwareAsset.Opportunity__c=oppItem.OpportunityId;
                    hardwareAsset.NSP_Support_ProductCode__c=oppItem.SBQQ__QuoteLine__r.NSP_Support_ProductCode__c;
                    hardwareAsset.RecordTypeId=rectype;
                    assetsToCreate.add(hardwareAsset);
                }
            }

        }
        if(assetsToCreate.size()>0){
            NSP_AssetTriggerHandler.TriggerDisabled=true;
            List<Database.SaveResult> results = Database.insert(assetsToCreate,false);
            NSP_AssetTriggerHandler.TriggerDisabled=false;
            NSP_ErrorLogHandler.logResults(
                NSP_OpportunityTriggerHelper.class.getName() ,
                'createHardwareAssets' ,
                results
            );
        }
    }

    // AZD-191924 232114
    public static void calculateEnrollmentFees(List<Opportunity> opps){

        for(Opportunity opp : opps){

            String oppSubType = opp.NSP_AddonType__c == null ? '' : opp.NSP_AddonType__c;

            if(oppSubType.equals('CAM') && opp.NSP_TotalAnnualPayroll__c !=null &&
            opp.NSP_Schedule_B_Enrollment_Fee__c != null && opp.NSP_1_6_OfScheduleB__c == false &&
            opp.NSP_WaivedInsperityFee__c == false && opp.NSP_InsperityFeePercent__c == null )  {

                //  Formula 1
                opp.NSP_Calculated_Enrollment_Fee__c = opp.NSP_Schedule_B_Enrollment_Fee__c;
                opp.NSP_EnrollmentFeeDiscount__c = opp.NSP_Calculated_Enrollment_Fee__c - opp.NSP_Schedule_B_Enrollment_Fee__c;
                opp.NSP_InsperityFee__c = opp.NSP_Schedule_B_Enrollment_Fee__c / 6;
                opp.NSP_Total_EF_Due_Reps__c = opp.NSP_Schedule_B_Enrollment_Fee__c - opp.NSP_InsperityFee__c;

            }
            else if(!oppSubType.equals('CAM') && opp.NSP_TotalAnnualPayroll__c !=null &&
                opp.NSP_Schedule_B_Enrollment_Fee__c != null && opp.NSP_1_6_OfScheduleB__c == false &&
                opp.NSP_WaivedInsperityFee__c == false && opp.NSP_InsperityFeePercent__c == null ) {

                    //  Formula 2
                    opp.NSP_Calculated_Enrollment_Fee__c =  ((opp.NSP_TotalAnnualPayroll__c / 12) * .06);
                    opp.NSP_EnrollmentFeeDiscount__c = opp.NSP_Calculated_Enrollment_Fee__c - opp.NSP_Schedule_B_Enrollment_Fee__c;
                    opp.NSP_InsperityFee__c = opp.NSP_Calculated_Enrollment_Fee__c / 6;
                    opp.NSP_Total_EF_Due_Reps__c = opp.NSP_Schedule_B_Enrollment_Fee__c - opp.NSP_InsperityFee__c;

            }
            else if(!oppSubType.equals('CAM') && opp.NSP_TotalAnnualPayroll__c !=null &&
                opp.NSP_Schedule_B_Enrollment_Fee__c != null && opp.NSP_1_6_OfScheduleB__c == true &&
                opp.NSP_WaivedInsperityFee__c == false && opp.NSP_InsperityFeePercent__c == null ) {

                //  Formula 3
                opp.NSP_Calculated_Enrollment_Fee__c =  ((opp.NSP_TotalAnnualPayroll__c / 12) * .06);
                opp.NSP_EnrollmentFeeDiscount__c = opp.NSP_Calculated_Enrollment_Fee__c - opp.NSP_Schedule_B_Enrollment_Fee__c;
                opp.NSP_InsperityFee__c = opp.NSP_Schedule_B_Enrollment_Fee__c / 6;
                opp.NSP_Total_EF_Due_Reps__c = opp.NSP_Schedule_B_Enrollment_Fee__c - opp.NSP_InsperityFee__c;

            }
            else if(!oppSubType.equals('CAM') && opp.NSP_TotalAnnualPayroll__c !=null
            &&  opp.NSP_Schedule_B_Enrollment_Fee__c != null  && opp.NSP_1_6_OfScheduleB__c == false &&
            opp.NSP_WaivedInsperityFee__c == true &&  opp.NSP_InsperityFeePercent__c !=null ) {

                //  Formula 4
                opp.NSP_Calculated_Enrollment_Fee__c = opp.NSP_Schedule_B_Enrollment_Fee__c;
                opp.NSP_EnrollmentFeeDiscount__c = opp.NSP_Calculated_Enrollment_Fee__c - opp.NSP_Schedule_B_Enrollment_Fee__c;
                opp.NSP_InsperityFee__c = (opp.NSP_InsperityFeePercent__c * opp.NSP_Schedule_B_Enrollment_Fee__c) / 100;
                opp.NSP_Total_EF_Due_Reps__c = opp.NSP_Schedule_B_Enrollment_Fee__c - opp.NSP_InsperityFee__c;
            }
        }
    }

    private static void checkPrimaryProductChange( Opportunity newOpportunity , Opportunity oldOpportunity , List<String> primaryProductChanged ) {
        if ( ( newOpportunity != null )
            && String.isNotBlank( newOpportunity.NSP_PrimaryProduct__c )
            && ( oldOpportunity != null )
            && String.isNotBlank( oldOpportunity.NSP_PrimaryProduct__c )
            && ( newOpportunity.NSP_PrimaryProduct__c != oldOpportunity.NSP_PrimaryProduct__c )
            && String.isBlank( newOpportunity.NSP_Parent_Opportunity__c )
            && (
                (
                    NSP_ValidateOpportunityStage.validHRProducts.contains( newOpportunity.NSP_PrimaryProduct__c )
                    && (
                        oldOpportunity.NSP_PrimaryProduct__c.equals( NSP_SalesConstants.WA )
                        || oldOpportunity.NSP_PrimaryProduct__c.equals( NSP_SalesConstants.WX )
                        )
                    )
                || (
                    (
                        newOpportunity.NSP_PrimaryProduct__c.equals( NSP_SalesConstants.WA )
                        || newOpportunity.NSP_PrimaryProduct__c.equals( NSP_SalesConstants.WX )
                        )
                    && NSP_ValidateOpportunityStage.validHRProducts.contains( oldOpportunity.NSP_PrimaryProduct__c )
                    )
                )
            )
        {
            primaryProductChanged.add( newOpportunity.Id );
        }
    }

    public static Map<String, Integer> retrieveFieldPicklistOrder(Schema.sObjectField field) {
        Map<String, Integer> fieldPicklistOrder = new Map<String, Integer>();
        if(field != null) {
            Integer i = 0;
            for(Schema.PicklistEntry sp : field.getDescribe().getPicklistValues()) {
                i++;
                fieldPicklistOrder.put(sp.getValue(), i);
            }
        }
        return fieldPicklistOrder;
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_OpportunityTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_OpportunityTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

    // PMCC ~ move getAssetRecordTypeIdByName( recordTypeLabel ) method to an Asset-related Apex Class...
    public static Id getAssetRecordTypeIdByName( String name ) {
        Id recordTypeId = null;
        if ( String.isNotBlank( name )
            && ( NSP_OpportunityTriggerHelper.assetRecordTypeNameMap != null )
            && NSP_OpportunityTriggerHelper.assetRecordTypeNameMap.containsKey( name )
            )
        {
            Schema.RecordTypeInfo info = NSP_OpportunityTriggerHelper.assetRecordTypeNameMap.get( name );
            if ( info != null ) {
                recordTypeId = info.getRecordTypeId();
            }
        }
        return recordTypeId;
    }

    // Map from RecordType.Name to RecordTypeInfo...
    private static Map<String,Schema.RecordTypeInfo> assetRecordTypeNameMap {
        private get {
            if ( assetRecordTypeNameMap == null ) {
                Map<String,Schema.RecordTypeInfo> local = new Map<String,Schema.RecordTypeInfo>();
                if ( NSP_OpportunityTriggerHelper.assetRecordTypeMap != null ) {
                    for ( Schema.RecordTypeInfo info : NSP_OpportunityTriggerHelper.assetRecordTypeMap.values() ) {
                        local.put( info.getName() , info );
                    }
                }
                assetRecordTypeNameMap = local;
            }
            return assetRecordTypeNameMap;
        }
        private set;
    }

    // Map from RecordType.DeveloperName to RecordTypeInfo...
    private static Map<String,Schema.RecordTypeInfo> assetRecordTypeMap {
        private get {
            if ( assetRecordTypeMap == null ) {
                assetRecordTypeMap = NSP_GenericRecordType.getRecordTypeMap( 'Asset' );
            }
            return assetRecordTypeMap;
        }
        private set;
    }

    //
    // Description : Set field "Is Service Opportunity" to true if Opportunity's owner has PS 'Services_Opportunity_Owner'
    // @param: Old Opportunity owner
    // @param: New Opportunity owner
    // @param: Opportunity
    // @return void
    //
    private static void setServicesOpportunity( Id oldOwner , Id newOwner , Opportunity record ) {
        if ( ( record != null ) && ( oldOwner != newOwner ) ) {
            record.Is_Services_Opportunity__c = CustomPermissionController.checkUserPermission(
                'Services_Opportunity_Owner' ,
                newOwner
            );
            if ( record.Is_Services_Opportunity__c ) {
                record.NSP_Sales_Office__c	= null;
            }
        }
    }

}
//