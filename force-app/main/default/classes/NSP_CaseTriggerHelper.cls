public class NSP_CaseTriggerHelper {
    // test w/ NSP_CaseTriggerHelperTest (78%)

    public static string ESCALATION_QUEUE = 'NSP_Escalations';
    public static string QUEUE_TYPE       = 'Queue';
    public static string CATEGORY_VALUE   = 'CSS';
    public static string CSS_ROLE         = 'Customer Success Specialist';
    public static string RET_NSPHardship_QUEUE = 'RET - NSPHardship';
    public final String BPSRECORDTYPE = 'BPS';
    public final String TASKPRIORITY = 'Medium';
    public final String TASKSTATUS = 'Completed';
    public final String TASKSUBJECT = 'Time Entry';
    private static final String STARTSWITHUSER = '005';
    private static final String STARTSWITHGROUP = '00G';
    List<Case> closedCaseLst ;
    Map<Id, Group> queueMap ;
    Map<String,Case> findAccountMap;
    Map<String,Case> findContactMap ;
    List<Case> updateCaseOwnerList;
    List<Case> lAssetCases;
    Set<Id> sAssetIds;
    Map<String,String> caseAccountIdStatus;
    Map<String, String> salesOfficePicklistValues;
    public static List<String> timeAttendanceSupportRoles = System.Label.NSP_Time_and_Attendance_Support_Roles.split(',');
    public static List<String> orgPlusSupportRoles = System.Label.NSP_OrgPlus_Support_Roles.split(',');
    public static List<String> performSmartSupportRoles = System.Label.NSP_PerformSmart_Support_Roles.split(',');
    public static List<String> tesSupportRoles = System.Label.NSP_TES_Support_Role.split(',');
    private static Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
    private static Id itaCqaRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'NSP_ITA_CQA' );
    private static Id dolAuditsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'NSP_DOLAudits' );
    private static Id wageClaimsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'NSP_WageClaims' );
    private static final String CASE_SUB_STATUS_IN_PROGRESS = 'In Progress';
    public static final String CASE_REASON_COMPLETE = 'Complete';


    /**
* Iterates throught the list of new leads and passes the required attributes to other methods.
* @param newList List of New leads.
* @return void
*/
    public void beforeInsertDirector(List<Case> newList){

        findAccountMap = new Map<String,Case>();
        findContactMap = new Map<String,Case>();
        queueMap =  new Map<Id, Group> ([SELECT Id,DeveloperName, Name FROM Group WHERE Id != null]);
        updateCaseOwnerList  = new List<Case>();
        lAssetCases = new List<Case>();
        sAssetIds = new Set<Id>();
        caseAccountIdStatus = new Map<String,String>();
        salesOfficePicklistValues = retreiveSalesOfficePicklistValues();

        List<Case> supportRoleCases = new List<Case>();
        Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'BPS' );
        Set<Id> acrAccIdSet = new Set<Id>();
        Set<Id> acrConIdSet = new Set<Id>();
        List<Case> itaCaseList = new List<Case>();

        Set<Id> assetpopulationAccIdSet = new Set<Id>();
        Set<String> assetpopulationCategoryIdSet = new Set<String>();
        Set<String> assetpopulationSubCategoryIdSet = new Set<String>();

        List<case> confidentialEligilbleList = new List<Case>();
        Set<String> categorySet = new Set<String>();
        Set<String> subCategorySet = new Set<String>();

        for(Case eachCase : newList){
            eachCase =  recordFirstQueueName(eachCase);
            assetValidation(eachCase);
            autoPopulateAccountContact(eachCase);
            eachCase = updateEmailSentinfo(eachCase);
            eachCase = recordOwnerAssingedDateTime(eachCase,null);
            //updateCaseOwnerFromAccountTeam(eachCase); /* commenting as part of DF-05464 as business don't want this logic to be implemented*/
            eachCase.NSP_SalesOffice__c = eachCase.NSP_SalesOffice__c != null && salesOfficePicklistValues.containsKey(eachCase.NSP_SalesOffice__c) ? salesOfficePicklistValues.get(eachCase.NSP_SalesOffice__c) : null;

            if(eachCase.RecordTypeId == bpsRecordTypeId && !String.isBlank(eachCase.AccountId) && !String.isBlank(eachCase.ContactId)){
                supportRoleCases.add(eachCase);
            }
            isBPSSupportAccountGroup(eachCase);
            // if the case sub category is Wage claim, recordtype will be wage claims and if the case sub category is DOL Audit, recordtype will be DOL Audits
            eachCase.recordTypeId = eachCase.NSP_SubCategory__c ==  NSP_ServiceConstants.CASE_SUB_CATEGORY_WAGE_CLAIMS ?  wageClaimsRecordTypeId :
            eachCase.NSP_SubCategory__c ==  NSP_ServiceConstants.CASE_SUB_CATEGORY_DOL_AUDITS ? dolAuditsRecordTypeId : eachCase.recordTypeId;
            Case_Import_Tool_Settings__c caseSettings =  Case_Import_Tool_Settings__c.getInstance( UserInfo.getUserId() );
            if ( ( caseSettings != null ) && !caseSettings.Bypass_Opened_Date__c ) {
                eachCase.NSP_Opened_Date__c = System.today(); //DF-02760
            }
            eachCase.NSP_Opened_Date__c = System.today(); //DF-02760

            eachCase.NSP_Case_Sub_Status__c = (eachcase.recordTypeId == NSP_CaseTriggerHelper.peoRecordTypeId && eachCase.Status == NSP_ServiceConstants.CLOSED_STATUS) ? NSP_ServiceConstants.RESOLVED : eachCase.NSP_Case_Sub_Status__c;

            if(isCorpEE(eachCase, null)){
                acrAccIdSet.add(eachCase.accountId);
                acrConIdSet.add(eachCase.contactId);
            }
            if(eachCase.recordTypeId == itaCqaRecordTypeId
               && eachCase.NSP_CQA_Resulting_Severity__c != null){
                   itaCaseList.add(eachCase);
               }
            //Added as part of DF-04518
            eachCase.NSP_Case_In_Progress_Hours__c =0;
            if(eachCase.NSP_Case_Sub_Status__c == CASE_SUB_STATUS_IN_PROGRESS){
                eachCase.NSP_Case_In_Progress_Modified_Date__c = DateTime.now();
            }

            // Added as part of DF-04796
            if(String.isNotBlank(eachCase.AccountId) && String.isNotBlank(eachcase.NSP_Category__c)){
                assetpopulationAccIdSet.add(eachCase.AccountId);
                assetpopulationCategoryIdSet.add(eachcase.NSP_Category__c);
                assetpopulationSubCategoryIdSet.add(eachcase.NSP_SubCategory__c);
            }

            // Added as part of usrsty-247918
            if ( ( eachcase.RecordTypeId == NSP_CaseTriggerHelper.peoRecordTypeId )
                && ( eachcase.NSP_Assigned_Queue__c == RET_NSPHardship_QUEUE )
                && String.isBlank( eachcase.NSP_Category__c)
                && String.isBlank( eachcase.NSP_SubCategory__c )
                )
            {
                    eachcase.NSp_Category__c = 'Retirement Svc-Processing';
                    eachcase.NSP_SubCategory__c = 'Hardship';
                }
            if ( ( eachcase.RecordTypeId == NSP_CaseTriggerHelper.peoRecordTypeId )
                && ( eachcase.NSP_Assigned_Queue__c == 'Payroll COE' )
                && String.isBlank( eachcase.NSP_Category__c )
                && String.isBlank( eachcase.NSP_SubCategory__c )
                )
            {
                eachcase.NSp_Category__c = 'PR COE Escalation';
                eachcase.NSP_SubCategory__c = 'Nexus';
            }
            if(String.isNotBlank(eachcase.NSP_Category__c) && String.isNotBlank(eachcase.NSP_SubCategory__c)){
                categorySet.add(eachCase.NSP_Category__c);
                subCategorySet.add(eachCase.NSP_SubCategory__c);
                confidentialEligilbleList.add(eachCase);
            }
            if(String.isNotBlank(eachcase.NSP_Topic__c) ){
                eachcase.Origin = 'Inbox Email';
            }
            if(eachCase.RecordTypeId==bpsRecordTypeId && eachCase.NSP_Level_2__c && eachCase.NSP_Level_2_Assigned_Date__c==NULL){
                eachCase.NSP_Level_2_Assigned_Date__c = System.now();
                eachCase.NSP_First_Level2_Assigned_Duration__c = 0;
            }
        }

        if(findContactMap.size()>0){
            findWebContact(findContactMap);
        }

        if(findAccountMap.size()>0){
            findWebAccount(findAccountMap);
        }
        if(!updateCaseOwnerList.isEmpty()){
            updateOwnerToCssRep(updateCaseOwnerList);
        }
        if(!supportRoleCases.isEmpty()){
            updateContactSupportRole(supportRoleCases);
        }
        if(!caseAccountIdStatus.isEmpty()){
            updateSupportAccountGroup(newList,caseAccountIdStatus);
        }

        //STY-03784
        if(!acrConIdSet.isEmpty()){
            NSP_CorporateEmployeeCheck.stampCorporateEmployeeEECheckbox(acrAccIdSet, acrConIdSet, newList, false);
        }
        //STY-01785 mapping of NSP_CQA_Severity__c based on NSP_CQA_Resulting_Severity__c
        if(!itaCaseList.isEmpty()){
            updateCqaSeverity(itaCaseList);
        }

         if(!confidentialEligilbleList.isEmpty()){
            checkTheEligibiltyOfConfidentiality(categorySet, subCategorySet, confidentialEligilbleList);
        }

        if(!assetpopulationCategoryIdSet.isEmpty() && !assetpopulationAccIdSet.isEmpty()){
            autoPopulateAsset(newList, assetpopulationCategoryIdSet, assetpopulationSubCategoryIdSet, assetpopulationAccIdSet, true);
        }

    }

    // record the first queue name in a piclist value
    public Case recordFirstQueueName(Case eachCase){
        if( eachCase.OwnerId !=null &&  String.valueOf(eachCase.OwnerId).startsWith(STARTSWITHGROUP)){
            eachCase.NSP_Assigned_Queue__c= queueMap.get(eachCase.OwnerId).Name;
            eachCase.NSP_Original_Assigned_Queue_Date__c = System.now();
        }
        return eachCase;
    }

    //Asset filter validation based on selected account
    public void assetValidation(Case eachCase){
        if(eachCase.AssetId != null && eachCase.Asset.AccountId != eachCase.AccountId){
            lAssetCases.add(eachCase);
            sAssetIds.add(eachCase.AssetId);
        }
    }

    // auto-populate Account and Contact based on PerId and ClientId field
    public void autoPopulateAccountContact(Case eachCase){
        if(eachCase.Origin=='Web' ){
            // when case is created from web wtih Per Id , auto populate the Contact
            if( eachCase.NSP_WebToCase_PerID__c != null){
                findContactMap.put( eachCase.NSP_WebToCase_PerID__c,eachCase);
            }
            // when case is created from Web with ClientId , auto populate the Account
            if(eachCase.NSP_WebToCase_ClientID__c != null){
                findAccountMap.put(eachCase.NSP_WebToCase_ClientID__c,eachCase);
            }
        }
    }

    // when the NSP_Consumer_Privacy_Inquiry__c set to true , enable the chekbox NSP_CCPA_email_Sent__c
    public Case updateEmailSentinfo(Case eachCase){
        if(eachCase.NSP_Consumer_Privacy_Inquiry__c == True && eachCase.NSP_CCPA_email_Sent__c == False){
            eachCase.NSP_CCPA_email_Sent__c= True;
        }
        return eachCase;
    }


    // when a new case is created with Owner and code will assign date / time.
    public case recordOwnerAssingedDateTime(Case eachCase , Map<Id, Case> caseOldMap){
        //DF-05853 - Update the "Owner Assign Date" whenever there is change in Owner
        if( eachCase.OwnerId != null && ( caseOldMap == null || caseOldMap.get(eachCase.Id).OwnerId != eachCase.OwnerId )){
            eachCase.NSP_Owner_Assign_Date__c = System.now();
        }
        return eachCase;
    }

    // update the case Owener from Account Team member Whose role is CSS.
    public void updateCaseOwnerFromAccountTeam(Case eachCase){
        if(eachCase.NSP_Category__c == CATEGORY_VALUE){
            updateCaseOwnerList.add(eachCase) ;
        }
    }

    /* Description : This will update the owner of Case to escalations queue
when L2 is set to true
Date        : 30/09/2021
*/

    public void updateCaseOwnerWhenL2IsTrue( list<Case> listOfCases ){
        Group escalationQueue = [SELECT Id
                                 FROM Group
                                 WHERE Type = : QUEUE_TYPE AND DeveloperName = : ESCALATION_QUEUE];

        for(Case updatedCase : listOfCases){
            updatedCase.OwnerId = escalationQueue.id;
        }
    }

    public void updateOwnerToCssRep( list<Case> listOfCases ){
        set<Id> setOfAccountId                       = new set<Id>();
        map<Id, Id> mapOfAccountIdAndAccountTeamUser = new map<Id, Id>();

        for(Case caseRec : listOfCases){
            setOfAccountId.add(caseRec.AccountId);
        }

        if(!setOfAccountId.isEmpty()){
            for(NSP_Account_Team__c accountTeam : [SELECT NSP_Role__c, NSP_User__c, NSP_Account__c
                                                   FROM NSP_Account_Team__c
                                                   WHERE NSP_Account__c IN : setOfAccountId
                                                   AND NSP_Role__c = :CSS_ROLE LIMIT 1]){
                                                       if(!mapOfAccountIdAndAccountTeamUser.containsKey(accountTeam.NSP_Account__c)){
                                                           mapOfAccountIdAndAccountTeamUser.put(accountTeam.NSP_Account__c, accountTeam.NSP_User__c);
                                                       }
                                                   }
        }

        for(Case updateOwnerVar : listOfCases){
            if(mapOfAccountIdAndAccountTeamUser.containsKey(updateOwnerVar.AccountId)){
                updateOwnerVar.OwnerId = mapOfAccountIdAndAccountTeamUser.get(updateOwnerVar.AccountId);
            }
        }
    }

    public List<case> findWebAccount( Map<String,Case> newCaseMap ){
        List<Case> updatedCase = new List<Case>();
        Map<String,Id> clientIdAccountIdMap = new Map<String,Id>();
        for( Account  eachAccount :[SELECT NSP_Premier_Pathway_Client__c  FROM Account WHERE NSP_Premier_Pathway_Client__c IN : newCaseMap.keySet() ]){
            clientIdAccountIdMap.put( eachAccount.NSP_Premier_Pathway_Client__c,eachAccount.Id );
        }
        if(clientIdAccountIdMap.size()>0){
            for(String eachKey : newCaseMap.keySet()){
                if(clientIdAccountIdMap.get(eachKey)!= null){
                    Case tempCase=  newCaseMap.get(eachKey);
                    tempCase.AccountId = clientIdAccountIdMap.get(eachKey);
                    updatedCase.add(tempCase);
                }
            }
        }
        return updatedCase ;
    }

    public List<case> findWebContact( Map<String,Case> newCaseMap){
        List<Case> updatedCase = new List<Case>();
        Map<String,Id> perIdContactIdMap = new Map<String,Id>();
        for(Contact eachContact: [ SELECT NSP_Per_ID__c,Id FROM Contact WHERE NSP_Per_ID__c IN : newCaseMap.keySet() ]){
            perIdContactIdMap.put( eachContact.NSP_Per_ID__c,eachContact.Id );
        }

        if(perIdContactIdMap.size()>0){
            for(String eachKey : newCaseMap.keySet()){
                if(perIdContactIdMap.get(eachKey)!= null){
                    Case tempCase = newCaseMap.get(eachKey);
                    tempCase.ContactId = perIdContactIdMap.get(eachKey);
                    updatedCase.add(tempCase);
                }
            }
        }
        return updatedCase ;
    }

    //Collect the Account team member
    public Id getAccountTeamMember(Id accId) {
        List<NSP_Account_Team__c> accountTeamList = [SELECT NSP_User__c
                                                    FROM NSP_Account_Team__c
                                                    WHERE NSP_Role__c = :NSP_SalesConstants.PayrollSpecialist
                                                    AND NSP_Account__c = :accId AND NSP_User__c!=null Limit 1];

        return !accountTeamList.isEmpty() ? accountTeamList[0].NSP_User__c : null;
    }

    /**
* Iterates throught the case  map and identifies the records that needs to worked based on various criterias.
* @param caseNewMap Map of New Case.
* @param caseOldMap Map of Old Case.
* @return void
*
*/
    public void beforeUpdateDirector(Map<Id, Case> caseNewMap, Map<Id, Case> caseOldMap){
        BusinessHours defaultBusinessHours = [SELECT ID FROM BusinessHours WHERE IsDefault=true];
        queueMap =  new Map<Id, Group> ([SELECT Id,DeveloperName, Name FROM Group WHERE Id != null]);
        closedCaseLst = new List<Case>();
        List<Case> escalationCaseList = new List<Case>();
        List<Case> lTypeChagnedCases = new List<Case>();
        List<Case> supportRoleCases = new List<Case>();
        List<Case> closedCases = new List<Case> ();
        List<Case> closedCaseForFirstTimeList = new List<Case>();
        caseAccountIdStatus = new Map<String,String>();
        List<Case> privateCaseList = new List<Case>();
        List<Case> nonInsperityEmplCaseList = new List<Case>();
        Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'BPS' );
        List<case> itaCaseList = new List<case>();
        salesOfficePicklistValues = retreiveSalesOfficePicklistValues();
        Set<Id> assetpopulationAccIdSet = new Set<Id>();
        Set<String> assetpopulationCategoryIdSet = new Set<String>();
        Set<String> assetpopulationSubCategoryIdSet = new Set<String>();

        List<case> confidentailEligilbleList = new List<Case>();
        Set<String> categorySet = new Set<String>();
        Set<String> subCategorySet = new Set<String>();
        List<Case> inProgressCaseList = new List<Case>();
        Set<Id> acrConIdSet = new Set<Id>();
        Set<Id> acrAccIdSet = new Set<Id>();
        for(Case eachCase : caseNewMap.values()) {

            eachCase = updateFLSACaseDetails(eachCase,caseOldMap);
            eachCase = enableEmailNotificationCaseCreation(eachCase,caseOldMap );
            eachCase = updateEmailSentinfo(eachCase);
            eachCase = autoResolvePEOCaseOnClosure(eachCase,caseOldMap);
            // when a case is update with Owner and code will assign date / time.
            eachCase = recordOwnerAssingedDateTime(eachCase,caseOldMap);
            // enable Juck checkbox will change the case status to Cancelled
            eachCase = markJunkCase(eachCase);

            if(isCorpEE(eachCase, caseOldMap.get(eachCase.Id))){
                acrConIdSet.add(eachCase.contactId);
                acrAccIdSet.add(eachCase.AccountId);
            }

            if(eachCase.NSP_SalesOffice__c != null && eachCase.NSP_SalesOffice__c != caseOldMap.get(eachCase.Id).NSP_SalesOffice__c) {
                eachCase.NSP_SalesOffice__c = salesOfficePicklistValues.containsKey(eachCase.NSP_SalesOffice__c) ? salesOfficePicklistValues.get(eachCase.NSP_SalesOffice__c) : eachCase.NSP_SalesOffice__c;
            }

            if(eachCase.NSP_L2__c && eachCase.NSP_L2__c != caseOldMap.get(eachCase.Id).NSP_L2__c){
                escalationCaseList.add(eachCase);
            }

            if(eachCase.Status == NSP_ServiceConstants.CASE_CLOSED_STATUS &&
               eachCase.Status != caseOldMap.get(eachCase.Id).Status &&
               eachCase.NSP_Date_Closed__c == null){
                   closedCases.add(eachCase);
               }

            if(!String.isBlank(eachCase.Type) && eachCase.Type != caseOldMap.get(eachCase.Id).Type){
                lTypeChagnedCases.add(eachCase);
            }

            if(caseOldMap.get(eachCase.Id).NSP_Private__c != eachCase.NSP_Private__c ){
                privateCaseList.add(eachcase);
            }

            if(caseOldMap.get(eachCase.Id).NSP_Category__c != eachCase.NSP_Category__c &&
               caseOldMap.get(eachCase.Id).NSP_Category__c == NSP_ServiceConstants.HW_SECTION_125){
                   eachCase.NSP_Private__c = false;
               }
            isBPSSupportAccountGroup(eachCase);

            //As a part of STY-02183
            if(eachCase.Status !=null &&
               caseOldMap.get(eachCase.Id).Status != NSP_ServiceConstants.CASE_CLOSED_STATUS &&
               eachCase.Status == NSP_ServiceConstants.CASE_CLOSED_STATUS && !caseOldMap.get(eachCase.Id).NSP_Is_Case_Closed__c){
                   closedCaseForFirstTimeList.add(eachCase);
               }

            //Added as part of STY-03638
            if(caseOldMap.get(eachCase.Id).Type != eachCase.Type
               && caseOldMap.get(eachCase.Id).RecordTypeId == bpsRecordTypeId
               && eachCase.Type == NSP_ServiceConstants.NON_INSPERITY_EMPLOYEE){
                   nonInsperityEmplCaseList.add(eachcase);
               }
            if(eachCase.recordTypeId == itaCqaRecordTypeId
               && eachCase.NSP_CQA_Resulting_Severity__c != null
               && eachCase.NSP_CQA_Resulting_Severity__c != caseOldMap.get(eachCase.Id).NSP_CQA_Resulting_Severity__c){
                   itaCaseList.add(eachCase);
               }
            if(eachCase.NSP_Category__c !=  caseOldMap.get(eachCase.Id).NSP_Category__c ||
               eachCase.NSP_SubCategory__c != caseOldMap.get(eachCase.Id).NSP_SubCategory__c ||
               (String.isNotBlank(eachCase.AccountId) &&
                eachCase.AccountId != caseOldMap.get(eachCase.Id).AccountId)){
                    assetpopulationAccIdSet.add(eachCase.AccountId);
                    assetpopulationCategoryIdSet.add(eachcase.NSP_Category__c);
                    assetpopulationSubCategoryIdSet.add(eachcase.NSP_SubCategory__c);
                }

            //As a part of DF-03961
            if(eachCase.NSP_Category__c !=  caseOldMap.get(eachCase.Id).NSP_Category__c ||
               eachCase.NSP_SubCategory__c != caseOldMap.get(eachCase.Id).NSP_SubCategory__c ||
               (String.isNotBlank(eachCase.ContactId) &&
                eachCase.ContactId != caseOldMap.get(eachCase.Id).ContactId) &&
               eachCase.RecordTypeId == bpsRecordTypeId){
                   supportRoleCases.add(eachCase);
               }
            //Added as part of DF-04518-->Start
            if(caseOldMap.get(eachCase.Id).NSP_Case_Sub_Status__c != CASE_SUB_STATUS_IN_PROGRESS && eachCase.NSP_Case_Sub_Status__c == CASE_SUB_STATUS_IN_PROGRESS){
                eachCase.NSP_Case_In_Progress_Modified_Date__c = DateTime.now();
            }
            if(caseOldMap.get(eachCase.Id).NSP_Case_Sub_Status__c == CASE_SUB_STATUS_IN_PROGRESS && eachCase.NSP_Case_Sub_Status__c != CASE_SUB_STATUS_IN_PROGRESS){
                inProgressCaseList.add(eachCase);
            }
            //Added as part of DF-04518-->End
            // Added as part of STY-04166 to check the Case is Confidential eligible or not
            if(eachCase.NSP_Category__c  != caseOldMap.get(eachCase.Id).NSP_Category__c ||
               eachCase.NSP_SubCategory__c  != caseOldMap.get(eachCase.Id).NSP_SubCategory__c ||
               eachCase.NSP_Detail__c  != caseOldMap.get(eachCase.Id).NSP_Detail__c ){
                   categorySet.add(eachCase.NSP_Category__c);
                   subCategorySet.add(eachCase.NSP_SubCategory__c);
                   confidentailEligilbleList.add(eachCase);
            }
            Id oldOwnerId = caseOldMap.get(eachCase.Id).OwnerId;
            Id newOwnerId = eachCase.OwnerId;
            //ADO-338835
            eachCase = NSP_CaseTriggerHelper.level2AssignedDate( eachCase , bpsRecordTypeId );
            eachCase = NSP_CaseTriggerHelper.firstLevel2Owner(
                eachCase ,
                bpsRecordTypeId ,
                oldOwnerId ,
                newOwnerId
            );
            if ( ( eachCase.RecordTypeId == bpsRecordTypeId ) && eachCase.NSP_Level_2__c ) {
                if ( ( newOwnerId != oldOwnerId )
                    && ( oldOwnerId.getSObjectType() != Schema.User.SObjectType )
                    && ( newOwnerId.getSObjectType() == Schema.User.SObjectType )
                    && ( eachCase.NSP_Level_2_Assigned_Date__c != null )
                    )
                {
                    eachCase.NSP_First_Level2_Assigned_Duration__c = calculateTimeDifferenceInMin(
                        defaultBusinessHours.Id ,
                        eachCase.NSP_Level_2_Assigned_Date__c ,
                        eachCase.First_Level_2_Owner_Assigned_Date__c
                    );
                }
                if ( ( caseOldMap.get(eachCase.Id).NSP_First_Level2_Reply_Date__c == null )
                    && ( eachCase.NSP_First_Level2_Reply_Date__c != null )
                    && ( eachCase.NSP_Level_2_Assigned_Date__c != null )
                    )
                {
                    eachCase.NSP_First_Level2_Reply_Duration__c = calculateTimeDifferenceInMin(
                        defaultBusinessHours.Id ,
                        eachCase.First_Level_2_Owner_Assigned_Date__c,
                        eachCase.NSP_First_Level2_Reply_Date__c
                    );
                }
            }
        }
        //Bug-237020 Logic to check or uncheck Corporate EE flag on Case update.
        if(!acrConIdSet.isEmpty() && !acrAccIdSet.isEmpty()){
            NSP_CorporateEmployeeCheck.stampCorporateEmployeeEECheckbox(acrAccIdSet, acrConIdSet, caseNewMap.values(), false);
        }

        if(escalationCaseList.size()>0){
            updateCaseOwnerWhenL2IsTrue(escalationCaseList);
        }

        if(closedCaseLst.size()>0){
            validateIncompletTask(closedCaseLst);
        }

        if(lTypeChagnedCases.size() > 0){
            new NSP_CaseService().fillCasesBasedOnType(lTypeChagnedCases);
        }
        if(!supportRoleCases.isEmpty()){
            updateContactSupportRole(supportRoleCases);
        }
        if(!caseAccountIdStatus.isEmpty()){
            updateSupportAccountGroup(caseNewMap.values(),caseAccountIdStatus);
        }
        //update NSP_Date_Closed__c on Case
        if(!closedCases.isEmpty()){
            updateDateClosed(closedCases);
        }

        if(!privateCaseList.isEmpty()){
            checkAccessToUpdatePrivateField(privateCaseList);
        }

        //As a part of STY-02183
        if(!closedCaseForFirstTimeList.isEmpty()){
            caseCloseForFirstTime(closedCaseForFirstTimeList);
        }

        //Added as a part of STY-03638
        if(!nonInsperityEmplCaseList.isEmpty()){
            bpsCaseUpdateForNonInsperityEmployeeType(nonInsperityEmplCaseList);
        }
        //STY-01785 mapping of NSP_CQA_Severity__c based on NSP_CQA_Resulting_Severity__c
        if(!itaCaseList.isEmpty()){
            updateCqaSeverity(itaCaseList);
        }

        if(!assetpopulationCategoryIdSet.isEmpty() && !assetpopulationAccIdSet.isEmpty()){
            autoPopulateAsset(caseNewMap.values(), assetpopulationCategoryIdSet, assetpopulationSubCategoryIdSet, assetpopulationAccIdSet, false);
        }
        if(!confidentailEligilbleList.isEmpty()){
            checkTheEligibiltyOfConfidentiality(categorySet, subCategorySet, confidentailEligilbleList);
        }
        if(!inProgressCaseList.isEmpty()){
            updateInProgressTime(caseOldMap,inProgressCaseList);
        }
    }

    //Level 2 Date and First Level2 Assigned Duration logic
    private static Case level2AssignedDate( Case eachCase , Id recordTypeId ) {
        if ( ( eachCase != null )
            && ( eachCase.RecordTypeId == recordTypeId )
            && eachCase.NSP_Level_2__c
            && ( eachCase.NSP_Level_2_Assigned_Date__c == null )
            )
        {
            eachCase.NSP_Level_2_Assigned_Date__c = System.now();
            eachCase.NSP_First_Level2_Assigned_Duration__c = 0;
        }
        return eachCase;
    }

    //First Level2 Owner Assigned Date logic
    private static Case firstLevel2Owner( Case eachCase , Id recordTypeId , Id oldUserId , Id newUserId ) {
        if ( ( eachCase != null )
            && ( eachCase.RecordTypeId == recordTypeId )
            && eachCase.NSP_Level_2__c
            && ( oldUserId != null )
            && ( oldUserId.getSObjectType() != Schema.User.SObjectType )
            && ( newUserId != null )
            && ( newUserId.getSObjectType() == Schema.User.SObjectType )
            )
        {
            eachCase.First_Level_2_Owner_Assigned_Date__c = System.now();
        }
        return eachCase;
    }

    /**
* @MethodName: isCorpEE
* @Description:  This method determines wheather a contact qualifies for Corporate EE or not
* @param : Case eachCase
* @createdDate : 10/25/2023
* @Story : Bug 237020
* @return Boolean
*/
    private Boolean isCorpEE( Case eachCase , Case oldCase ) {
        return (
            String.isNotBlank( eachCase.contactId )
            && ( eachCase.recordTypeId == NSP_CaseTriggerHelper.peoRecordTypeId )
        );
    }

    /**
* @MethodName: checkAccessToUpdatePrivateField
* @Description:  This method describes about of NSP_Private__c checkbox based on the user access and Category.
* @param : List<Case> caseList
* @createdDate : 11/230/2022
* @Story : STY-02804
* @return void
*/
    public void checkAccessToUpdatePrivateField(List<Case> caseList){
        Boolean isHavingAccess = NSP_CustomCaseCreationPageController.isMemberOfPrivateSection125Visibility();
        for(Case cse : caseList){
            if(!isHavingAccess || cse.NSP_Category__c !=NSP_ServiceConstants.HW_SECTION_125){
                cse.addError(System.Label.NSP_PrivateCheckBoxAccessError);
            }
        }
    }

    /**
* Update NSP_Date_Closed__c on Case when Case is marked as closed for first time
* Update NSP_Date_Closed__c on Case when Case is marked as closed for first time
* @param closedCaseList List of closed Cases
* @return void
*/
    public void updateDateClosed(list<Case> closedCaseList){
        for(Case closedCases : closedCaseList){
            closedCases.NSP_Date_Closed__c = Date.today();
        }
    }

    //Update required details on FLSA Case
    public Case updateFLSACaseDetails(Case eachCase, Map<Id, Case> caseOldMap){
        if(eachCase.NSP_FLSA_Case__c == True && caseOldMap.get(eachCase.Id).NSP_SubCategory__c == null && eachCase.AccountId != null){
            if(eachCase.NSP_SubCategory__c == NSP_SalesConstants.FLSASubCategory1){
                Id teamMemberId = getAccountTeamMember(eachCase.AccountId);
                if(teamMemberId!=null){
                    eachCase.OwnerId = teamMemberId;
                }
                eachCase.NSP_Case_Sub_Status__c = NSP_ServiceConstants.CASE_ASSIGNED;
                eachCase.Reason = NSP_ServiceConstants.CASE_REFERRED_TO_PAYROLL;
                eachCase.NSP_Due_Date__c = eachCase.NSP_Opened_Date__c != null ? eachCase.NSP_Opened_Date__c.addDays(90):eachCase.NSP_Due_Date__c;
            }else if(eachCase.NSP_SubCategory__c == NSP_SalesConstants.FLSASubCategory2){
                eachCase.NSP_Case_Sub_Status__c = NSP_SalesConstants.Resolved;
                eachCase.Status = NSP_SalesConstants.Closed;
                eachCase.OwnerId = userInfo.getUserId();
                //STY-04507 - When update the sub category of the case from null to FLSA Quick Check Service then Resolution is Complete
                eachCase.Reason = CASE_REASON_COMPLETE;
            }
        }
        return eachCase;
    }

    //auto update the sub status as resolved on PEO case closeure
    public Case autoResolvePEOCaseOnClosure(Case eachCase, Map<Id, Case> caseOldMap){
        // Upon Closing the case trigger will Chane the Sub Status to Resoloved for PEO record type
        if( eachCase.Status == 'Closed' && caseOldMap.get(eachCase.Id).Status != eachCase.Status ){
            Id recordTypePeoId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
            if ( ( recordTypePeoId != null ) && ( eachCase.RecordTypeId == recordTypePeoId ) ) {
                eachCase.NSP_Case_Sub_Status__c = 'Resolved';
            }
            closedCaseLst.add(eachCase);
        }
        return eachCase;
    }

    // enable Juck checkbox will change the case status of case to Cancelled
    public Case markJunkCase(Case eachCase){
        if(eachCase.NSP_IsJunkMail__c == true && ( eachCase.Status != 'Cancelled' || eachCase.NSP_Case_Sub_Status__c !='Junk Mail')){
            eachCase.Status = 'Cancelled' ;
            eachCase.NSP_Case_Sub_Status__c ='Junk Mail' ;
        }
        return eachCase;
    }

    public void validateIncompletTask(List<Case> caseList){
        Map<Id,Boolean> isBlockCaseId = new Map<Id,Boolean>();
        for(Task eachTask : [SELECT Id, WhatId,Subject,Status,IsClosed,TaskSubtype,NSP_Minutes_spent_on_task__c
                             FROM Task
                             WHERE (IsClosed = false) AND
                             WhatId IN: caseList]){
                                 isBlockCaseId.put(eachTask.WhatId,true);
                             }

        if(isBlockCaseId.size() >0){
            for(Case eachClosedCase : caseList ){
                if(isBlockCaseId.get(eachClosedCase.id)!= null && isBlockCaseId.get(eachClosedCase.id) == true){
                    eachClosedCase.addError(System.label.NSP_PreventCloseTheCaseWithOpenTask);
                }
            }
        }
    }

    public Case enableEmailNotificationCaseCreation(Case eachCase,Map<Id, Case> caseOldMap ){

        if( eachCase.OwnerId !=null && String.valueOf(eachCase.OwnerId).startsWith(STARTSWITHGROUP) && caseOldMap.get(eachCase.Id).OwnerId != eachCase.OwnerId
           && String.isBlank(eachCase.NSP_Assigned_Queue__c)){
               eachCase.NSP_Assigned_Queue__c = queueMap.get(eachCase.OwnerId).Name;
               eachCase.NSP_Original_Assigned_Queue_Date__c = System.now();
           }

        if( eachCase.OwnerId !=null && String.valueOf(eachCase.OwnerId).startsWith(STARTSWITHUSER) && caseOldMap.get(eachCase.Id).OwnerId!= null && caseOldMap.get(eachCase.Id).OwnerId != eachCase.OwnerId
           && String.valueOf(caseOldMap.get(eachCase.Id).OwnerId).startsWith(STARTSWITHGROUP) && String.isNotBlank(eachCase.NSP_Assigned_Queue__c) && eachCase.NSP_IsCaseCreatedNotificationEmailSent__c == false){
               eachCase.NSP_IsCaseCreatedNotificationEmailSent__c = true;
           }
        return eachCase;
    }

    /**
* After Insert Case Fitlers for other functions
* @param lCases List of New Cases
* @param mCases Map of New Cases.
* @return void
*/
    public void afterInsertCaseFilters(List<Case> lCases, Map<Id, Case> mCases){


        Id healthAndProductsGrpId = [SELECT Id, Name,Type FROM Group WHERE Type='Queue' AND Name =: NSP_ServiceConstants.HEALTH_WELFARE_PRODUCT].Id;
        Set<Id> iPIdSet = new Set<Id>();
        Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'BPS' );
        /* Added as part of STY-02137 */
        List<Case> casesToShare = new List<Case>();
        Set<String> categorySet = new Set<String>();
        Set<String> subCategorySet = new Set<String>();
        /* Added as part of STY-02137 */
        Set<Id> caseIdSet = new Set<Id>();
        List<Case> lBPSCases = new List<Case>();
        //Added as part of STY-02204
        List<Case> migratedCaseList = new List<Case>();
        Set<String> migratedCategorySet = new Set<String>();
        Set<String> migratedSubCategorySet = new Set<String>();
        List<case> privateCaseList = new List<Case>();
        //Report Dev Cases Lists
        List<Case> reqNotCompleteCaseList = new List<Case>();
        List<Case> referToExistingCaseList = new List<Case>();
        List<Case> awaitingVerificationCaseList = new List<Case>();
        List<Case> migrationCompleteCaseList = new List<Case>();
        Set<Id> itaParentCaseIdSet = new Set<Id>();
        List<String> openReOpenedStatus = new List<string>{NSP_ServiceConstants.CASE_OPEN_STATUS, NSP_ServiceConstants.REOPENED};
        Set<Id> NiceCXcaseIdset = new Set<Id>();

            for(Case oCase : lCases){
                if(oCase.RecordTypeId == bpsRecordTypeId && !String.isBlank(oCase.Type)){
                    lBPSCases.add(oCase);
                }
                //Added as part of STY-02204
                if(oCase.NSP_Confidential__c && String.isNotBlank(oCase.NSP_Category__c) &&
                   (String.isNotBlank(oCase.NSP_Case_External_Id__c ) ||  String.isNotBlank(oCase.NSP_NetSuite_External_ID__c) || String.isNotBlank(oCase.NSP_OneVoice_External_ID__c))){
                       migratedCaseList.add(oCase);
                       migratedCategorySet.add(oCase.NSP_Category__c);
                       migratedSubCategorySet.add(oCase.NSP_SubCategory__c);
                   }

                /* Added as part of STY-03293. If confidential Checkbox is true and Category/Sub Categpry is not blank share the records based on public group*/
                /* As part of STY-04427 opening up sharing access for BPS record type */
                if ( oCase.NSP_Confidential__c == true
                    && String.isNotBlank(oCase.NSP_Category__c)
                    && oCase.NSP_Private__c == false
                    && String.isNotBlank(oCase.NSP_SubCategory__c)
                    && ( oCase.recordTypeId == NSP_CaseTriggerHelper.peoRecordTypeId || oCase.recordTypeId == bpsRecordTypeId )
                    )
                {
                       casesToShare.add(oCase);
                       categorySet.add(oCase.NSP_Category__c);
                       subCategorySet.add(oCase.NSP_SubCategory__c);
                   }
                /* Added as part of STY-03293 */

                /*STY-02804 If private check box is checked then the case will be shared with Private Section 125 Visibility public group */
                if(oCase.NSP_Private__c &&
                   String.isNotBlank(oCase.NSP_Category__c) &&
                   oCase.NSP_Category__c == NSP_ServiceConstants.HW_SECTION_125){
                       privateCaseList.add(oCase);
                   }
                /*STY-02804  ends*/

                // Added as part of STY-03256
                if ( ( oCase.recordTypeId == NSP_CaseTriggerHelper.peoRecordTypeId )
                    && ( oCase.OwnerId == healthAndProductsGrpId )
                    && String.isNotBlank( oCase.Subject )
                    && oCase.Subject.startsWith( NSP_ServiceConstants.SUBJECT7 )
                    && String.isNotBlank( oCase.NSP_Implementation_Profile__c )
                    )
                {
                    iPIdSet.add( oCase.NSP_Implementation_Profile__c );
                }
                /*Added as part of STY-03256 */
                if(String.isNotBlank(oCase.ContactId)){
                    caseIdSet.add(oCase.Id);
                }
                /*Added as part of STY-00762*/
                if(oCase.NSP_Category__c == NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS
                   && oCase.NSP_SubCategory__c == NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT
                   && oCase.NSP_Detail__c == NSP_ServiceConstants.CASE_DETAIL_REQUEST_NOT_COMPLETE){
                       reqNotCompleteCaseList.add(oCase);
                   }
                if(oCase.NSP_Category__c == NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS
                   && oCase.NSP_SubCategory__c == NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT
                   && oCase.NSP_Detail__c == NSP_ServiceConstants.CASE_DETAIL_REFERRED_TO_EXISTING){
                       referToExistingCaseList.add(oCase);
                   }
                if(oCase.NSP_Category__c == NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS
                   && oCase.NSP_SubCategory__c == NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT
                   && oCase.NSP_Case_Sub_Status__c == NSP_ServiceConstants.CASE_SUB_STATUS_AWAITING_VERIFICATION){
                       awaitingVerificationCaseList.add(oCase);
                   }
                if(oCase.NSP_Category__c == NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS
                   && oCase.NSP_SubCategory__c == NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT
                   && oCase.NSP_Case_Sub_Status__c == NSP_ServiceConstants.CASE_SUB_STATUS_WIRE_MIGRATION_COMPLETE){
                       migrationCompleteCaseList.add(oCase);
                   }
                if(oCase.recordTypeId == itaCqaRecordTypeId
                   && String.isNotBlank(oCase.ParentId)
                   && openReOpenedStatus.contains(oCase.Status)
                   && oCase.NSP_CQA_Severity__c != null){
                       itaParentCaseIdSet.add(oCase.ParentId);
                   }
                /*NiceCX - if case is niceCX Case and Origin phone- update service request channel as phone*/
                if(oCase.NSP_NiceCx_Case__c  == true && oCase.Origin != null && oCase.Origin == NSP_ServiceConstants.PHONE_CHANNEL){
                    NiceCXcaseIdset.add(oCase.Id);
                }
            }
        createTimeEntryTask(lBPSCases);

        if(!casesToShare.isEmpty()){
            NSP_CaseRecordSharing.shareCaseOnUpdate(casesToShare, false, categorySet, subCategorySet);
        }

        if(!iPIdSet.isEmpty()){
            cancelPreviouslyCreatedCase(iPIdSet);
        }

        if(!caseIdSet.isEmpty()){
            createCaseContact(caseIdSet);
        }
        if(!migratedCaseList.isEmpty()){
            NSP_CaseRecordSharing.shareMigratedCase(migratedCaseList, migratedCategorySet, migratedSubCategorySet );
        }

        if(!privateCaseList.isEmpty()){
            NSP_CaseRecordSharing.sharePrivateCases(privateCaseList);
        }
        /*Added as part of STY-00762*/
        if(!reqNotCompleteCaseList.isEmpty()){
            NSP_CaseTriggerEmailNotification.sendRequestNotCompleteMail(reqNotCompleteCaseList);
        }
        if(!referToExistingCaseList.isEmpty()){
            NSP_CaseTriggerEmailNotification.sendReferredToExistingEmail(referToExistingCaseList);
        }
        if(!awaitingVerificationCaseList.isEmpty()){
            NSP_CaseTriggerEmailNotification.sendAwaitingVerificationEmail(awaitingVerificationCaseList);
        }
        if(!migrationCompleteCaseList.isEmpty()){
            NSP_CaseTriggerEmailNotification.sendMigrationCompleteEmail(migrationCompleteCaseList);
        }
        // STY-01785. update parent NSP_CQA_Severity__c with the highest level of the child NSP_CQA_Severity__c
        if(!itaParentCaseIdSet.isEmpty()){
            updateParentItaCqaCase(itaParentCaseIdSet);
        }

        if(!NiceCXcaseIdset.isEmpty()){
            UpdateServiceRequestChannel(NiceCXcaseIdset);
        }
        createCaseHistory(new Map<Id, Case>(), mCases);

    }

    /**
* @MethodName: createCaseContact
* @Description: This method describes When the case is getting created from Email, Case Contact with Primary checkbox Needs to be created.
* @param : Set<Id> caseIds
* @createdDate : 11/11/2022
* @Story : STY-03685
* @return void
*/
    public static void createCaseContact (Set<Id> caseIds){
        List<NSP_Case_Contacts__c> cseConList = new List<NSP_Case_Contacts__c>();
        NSP_Case_Contacts__c nCseCon;
        for(Case cse : [SELECT Id,
                        ContactId
                        FROM Case
                        WHERE Id IN:caseIds]){
                            nCseCon = new NSP_Case_Contacts__c();
                            nCseCon.NSP_Case__c = cse.Id;
                            nCseCon.NSP_Contact__c = cse.ContactId;
                            nCseCon.NSP_IsPrimary__c = true;
                            cseConList.add(nCseCon);
                        }
        if(!cseConList.isEmpty()){
            try{
                Database.insert(cseConList);
            } catch ( Exception e ) {
                NSP_CaseTriggerHelper.handleException(
                    e ,
                    'createCaseContact'
                );
            }
        }
    }

    private void createTimeEntryTask(List<Case> lCases){

        Set<String> sTypes = new Set<String>();

        for(Case oCase : lCases){
            sTypes.add(oCase.Type);
        }

        List<NSP_Case_Configuration__mdt> lCaseConfigurations = new List<NSP_Case_Configuration__mdt>([SELECT Label,NSP_Time_Entry__c FROM NSP_Case_Configuration__mdt WHERE Label in : sTypes]);
        Map<String,NSP_Case_Configuration__mdt> mNameToConfig  = new Map<String,NSP_Case_Configuration__mdt>();
        for(NSP_Case_Configuration__mdt oCaseConfig : lCaseConfigurations){
            mNameToConfig.put(oCaseConfig.Label,oCaseConfig);
        }

        List<Task> lTasks = new List<Task>();
        for(Case oCase : lCases){
            NSP_Case_Configuration__mdt oCaseConfig = mNameToConfig.get(oCase.Type);
            if(oCaseConfig != null && oCaseConfig.NSP_Time_Entry__c != null){
                lTasks.add(new Task(Subject = TASKSUBJECT, Status = TASKSTATUS,ActivityDate= System.today(),Priority = TASKPRIORITY, OwnerId = oCase.OwnerId ,WhatId = oCase.Id, NSP_Minutes_spent_on_task__c = oCaseConfig.NSP_Time_Entry__c));
            }
        }
        insert lTasks;
    }
    /**
* Iterates throught the case  map and identifies the records that needs to worked based on various criterias.
* @param caseNewMap Map of New Case.
* @param caseOldMap Map of Old Case.
* @return void
*
*/
    public void afterUpdateDirector(Map<Id, Case> caseNewMap,Map<Id, Case> caseOldMap){
        Set<Id> parentCaseIds = new Set<Id>();
        List<Case> casesToShare = new List<Case>();
        List<Case> casesToRemoveSharing = new List<Case>();
        Set<String> categorySet = new Set<String>();
        Set<String> subCategorySet = new Set<String>();
        Set < Id > ownerChnagedCases = new Set<Id>();
        Set<Id> reassignrecTypeIds = getReassignRecordTypeIds();
        List<Case> bankAuditCaseList = new List<Case>();
        List<Case> nonInsperityEmplCaseList = new List<Case>();
        //Report Dev Cases Lists
        List<Case> reqNotCompleteCaseList = new List<Case>();
        List<Case> referToExistingCaseList = new List<Case>();
        List<Case> awaitingVerificationCaseList = new List<Case>();
        List<Case> migrationCompleteCaseList = new List<Case>();
        //Added as part of STY-02204
        List<Case> migratedCaseList = new List<Case>();
        Set<String> migratedCategorySet = new Set<String>();
        Set<String> migratedSubCategorySet = new Set<String>();

        List<Case> privateCaseList = new List<Case>();
        List<Case> privateCaseRemoveShareList = new List<Case>();
        //Added as part of STY-03638
        Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'BPS' );
        Set<Id> itaParentCaseIdSet = new Set<Id>();
        List<String> openReOpenedStatus = new List<string>{NSP_ServiceConstants.CASE_OPEN_STATUS, NSP_ServiceConstants.REOPENED};
            Set<Id> itqCqaPrjctIdSet = new Set<Id>();
        Set<Id> itaChildClosedParentCseIdSet = new Set<Id>();
        Set<Id> reOpenParentItaCqaIdSet = new Set<Id>();
        Set<Id> NiceCXcaseIdset = new Set<Id>();

        for(Case eachCase: caseNewMap.values()){
            if(eachCase.NSP_Case_Issue__c != null && eachCase.Status != null){
                if(eachCase.Status == 'Closed' && caseOldMap.get(eachCase.Id).Status != eachCase.Status){
                    parentCaseIds.add(eachCase.Id);
                }
            }
            //Added as part of STY-02204
            if(eachCase.NSP_Confidential__c && !caseOldMap.get(eachCase.Id).NSP_Confidential__c
               && String.isNotBlank(eachCase.NSP_Category__c) && (String.isNotBlank(eachCase.NSP_Case_External_Id__c)
                                                                  ||  String.isNotBlank(eachCase.NSP_NetSuite_External_ID__c) || String.isNotBlank(eachCase.NSP_OneVoice_External_ID__c))){
                                                                      migratedCaseList.add(eachCase);
                                                                      migratedCategorySet.add(eachCase.NSP_Category__c);
                                                                      migratedSubCategorySet.add(eachCase.NSP_SubCategory__c);
                                                                  }
            /* Case Sharing Criterias. Stories covered STY-03293, STY-03941, STY-02804
* **When case recordtype is PEO and Private check box is false
* 1. If Confidential checkbox is changed and Confidential checkbox is true and Category is not blank OR
* 2. If Confidential check box is true and Category is changed OR
* 3. If Private checkbox is changed and Confidential checkbox is true and Private checkbox is false and Corp EE is false OR
* 4. If Corp EE is chanaged and false but Confidential checkbox is true OR
* ELSE IF Confidential is changed and it is false OR
* 1. Corp EE is changed and is true and Confidential is also true
* when ever owner is changing, recalculating the sharing rules as part of DF-03733
* As part of STY-04427 opening up sharing access for BPS record type
* */
            if ( ( eachCase.recordTypeId == NSP_CaseTriggerHelper.peoRecordTypeId || eachCase.recordTypeId == bpsRecordTypeId )
                && eachcase.NSP_Private__c == false
                )
            {

                if((caseOldMap.get(eachCase.Id).NSP_Confidential__c != eachCase.NSP_Confidential__c &&
                    eachCase.NSP_Confidential__c == true &&
                    String.isNotBlank(eachCase.NSP_Category__c) ||
                    (eachCase.NSP_Confidential__c == true &&
                     String.isNotBlank(eachCase.NSP_Category__c) &&
                     caseOldMap.get(eachCase.Id).NSP_Category__c != eachCase.NSP_Category__c) ||
                    (caseOldMap.get(eachCase.Id).NSP_Private__c != eachCase.NSP_Private__c && eachCase.NSP_Private__c == false && eachCase.NSP_Confidential__c == true) ||
                    (caseOldMap.get(eachCase.Id).ownerId != eachCase.ownerId &&  eachCase.NSP_Confidential__c == true))){
                        casesToShare.add(eachCase);
                        categorySet.add(eachCase.NSP_Category__c);
                        subCategorySet.add(eachCase.NSP_SubCategory__c);
                    }else if((caseOldMap.get(eachCase.Id).NSP_Confidential__c != eachCase.NSP_Confidential__c &&
                              eachCase.NSP_Confidential__c == false)){
                                  casesToRemoveSharing.add(eachCase);
                                  categorySet.add(eachCase.NSP_Category__c);
                                  subCategorySet.add(eachCase.NSP_SubCategory__c);
                              }
            }

            /*STY-02804 Private checkBox Sharing */
            if((caseOldMap.get(eachCase.Id).NSP_Private__c != eachCase.NSP_Private__c &&
                eachCase.NSP_Private__c == true ) || (caseOldMap.get(eachCase.Id).ownerId != eachCase.ownerId &&  eachCase.NSP_Private__c == true)){
                    privateCaseList.add(eachCase);
                }else if(caseOldMap.get(eachCase.Id).NSP_Private__c != eachCase.NSP_Private__c &&
                         eachCase.NSP_Private__c == false ){
                             privateCaseRemoveShareList.add(eachCase);
                         }
            /*STY-02804 Private checkBox Sharing */


            /* Added as part of STY-01774  To check whether case owner is changing from user to user*/
            if(caseOldMap.get(eachCase.Id).OwnerId != eachCase.OwnerId
               && string.valueOf(caseOldMap.get(eachCase.Id).OwnerId).startsWith(STARTSWITHUSER)
               && string.valueOf(eachCase.OwnerId).startsWith(STARTSWITHUSER)
               && reassignrecTypeIds.contains(eachCase.RecordTypeId)){
                   ownerChnagedCases.add(eachCase.Id);
               }

            /*Added as part of STY-00762*/
            if(caseOldMap.get(eachCase.Id).NSP_Detail__c != eachCase.NSP_Detail__c
               && eachCase.NSP_Category__c == NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS
               && eachCase.NSP_SubCategory__c == NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT
               && eachCase.NSP_Detail__c == NSP_ServiceConstants.CASE_DETAIL_REQUEST_NOT_COMPLETE){
                   reqNotCompleteCaseList.add(eachCase);
               }
            if(caseOldMap.get(eachCase.Id).NSP_Detail__c != eachCase.NSP_Detail__c
               && eachCase.NSP_Category__c == NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS
               && eachCase.NSP_SubCategory__c == NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT
               && eachCase.NSP_Detail__c == NSP_ServiceConstants.CASE_DETAIL_REFERRED_TO_EXISTING){
                   referToExistingCaseList.add(eachCase);
               }
            if(caseOldMap.get(eachCase.Id).NSP_Case_Sub_Status__c != eachCase.NSP_Case_Sub_Status__c
               && eachCase.NSP_Category__c == NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS
               && eachCase.NSP_SubCategory__c == NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT
               && eachCase.NSP_Case_Sub_Status__c == NSP_ServiceConstants.CASE_SUB_STATUS_AWAITING_VERIFICATION){
                   awaitingVerificationCaseList.add(eachCase);
               }
            if(caseOldMap.get(eachCase.Id).NSP_Case_Sub_Status__c != eachCase.NSP_Case_Sub_Status__c
               && eachCase.NSP_Category__c == NSP_ServiceConstants.CASE_CATEGORY_SERVICE_OPERATIONS
               && eachCase.NSP_SubCategory__c == NSP_ServiceConstants.CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT
               && eachCase.NSP_Case_Sub_Status__c == NSP_ServiceConstants.CASE_SUB_STATUS_WIRE_MIGRATION_COMPLETE){
                   migrationCompleteCaseList.add(eachCase);
               }

            //As a part of STY-02183
            if ( ( eachCase.Status == NSP_ServiceConstants.CASE_CLOSED_STATUS )
                && eachCase.NSP_Is_Case_Closed__c
                && !caseOldMap.get( eachCase.Id ).NSP_Is_Case_Closed__c
                && String.isNotBlank( eachCase.Subject )
                && eachCase.Subject.contains( NSP_ServiceConstants.BANK_AUDIT_CASE_SUBJECT )
                )
            {
                bankAuditCaseList.add( eachCase );
            }

            //Added as part of STY-03638
            if(caseOldMap.get(eachCase.Id).Type != eachCase.Type
               && caseOldMap.get(eachCase.Id).RecordTypeId == bpsRecordTypeId
               && eachCase.Type == NSP_ServiceConstants.NON_INSPERITY_EMPLOYEE){
                   nonInsperityEmplCaseList.add(eachcase);
               }
            /* Added conditions as part of STY-01785 for ITA CQA recordType  starts*/
            if(eachCase.recordTypeId == itaCqaRecordTypeId){

                if(String.isNotBlank(eachCase.ParentId)
                   && openReOpenedStatus.contains(eachCase.Status)
                   && caseOldMap.get(eachCase.Id).NSP_CQA_Severity__c != eachCase.NSP_CQA_Severity__c
                   && eachCase.NSP_CQA_Severity__c != null){
                       itaParentCaseIdSet.add(eachCase.ParentId);
                   }

                if(String.isBlank(eachCase.ParentId)
                   && caseOldMap.get(eachCase.Id).Status != eachCase.Status
                   && eachCase.Status == NSP_ServiceConstants.CASE_CLOSED_STATUS
                   && String.isNotBlank(eachCase.Project__c)){
                       itqCqaPrjctIdSet.add(eachCase.Project__c);
                   }

                if(String.isNotBlank(eachCase.ParentId)
                   && caseOldMap.get(eachCase.Id).Status != eachCase.Status
                   && eachCase.Status == NSP_ServiceConstants.CASE_CLOSED_STATUS){
                       itaChildClosedParentCseIdSet.add(eachCase.ParentId);
                   }

                if(String.isNotBlank(eachCase.ParentId)
                   && caseOldMap.get(eachCase.Id).Status != eachCase.Status
                   && caseOldMap.get(eachCase.Id).Status == NSP_ServiceConstants.CASE_CLOSED_STATUS
                   && eachCase.Status == NSP_ServiceConstants.REOPENED){
                       reOpenParentItaCqaIdSet.add(eachCase.ParentId);
                   }
            }
            /*NiceCX - if case is niceCX Case and Origin phone- update service request channel as phone*/
            if(eachCase.NSP_NiceCx_Case__c  == true && eachCase.Origin != null && eachCase.Origin == NSP_ServiceConstants.PHONE_CHANNEL){
                NiceCXcaseIdset.add(eachCase.Id);
            }
            /* Added conditions as part of STY-01785 for ITA CQA recordType  Ends*/
        }

        if(!ownerChnagedCases.isEmpty()){
            reassignActivitiesOwner(ownerChnagedCases);
        }
        /* Added as part of STY-01774 */

        if(parentCaseIds.size()>0){
            List<Case> updateChildCase = new List<Case>();
            for(Case eachCase: [SELECT Id, Status FROM Case WHERE ParentId IN : parentCaseIds AND IsClosed = false AND status != 'Closed']){
                eachCase.Status = 'Closed';
                updateChildCase.add(eachCase);
            }
            update updateChildCase;
        }

        if(!privateCaseRemoveShareList.isEmpty()){
            NSP_CaseRecordSharing.removeSharingOnCaseUpdate(privateCaseRemoveShareList);
        }

        if(!casesToShare.isEmpty()){
            NSP_CaseRecordSharing.shareCaseOnUpdate(casesToShare, true, categorySet, subCategorySet);
        }

        if(!casesToRemoveSharing.isEmpty()){
            NSP_CaseRecordSharing.removeSharingOnCaseUpdate(casesToRemoveSharing);
        }
        //Added as part of STY-02204
        if(!migratedCaseList.isEmpty()){
            NSP_CaseRecordSharing.shareMigratedCase(migratedCaseList, migratedCategorySet, migratedSubCategorySet );
        }

        if(!privateCaseList.isEmpty()){
            NSP_CaseRecordSharing.removeSharingOnCaseUpdate(privateCaseList);
            NSP_CaseRecordSharing.sharePrivateCases(privateCaseList);
        }

        //As a part of STY-02183
        if(!bankAuditCaseList.isEmpty()){
            bankAuditCaseCompletionEmail(bankAuditCaseList);
        }

        /*Added as part of STY-00762*/
        if(!reqNotCompleteCaseList.isEmpty()){
            NSP_CaseTriggerEmailNotification.sendRequestNotCompleteMail(reqNotCompleteCaseList);
        }
        if(!referToExistingCaseList.isEmpty()){
            NSP_CaseTriggerEmailNotification.sendReferredToExistingEmail(referToExistingCaseList);
        }
        if(!awaitingVerificationCaseList.isEmpty()){
            NSP_CaseTriggerEmailNotification.sendAwaitingVerificationEmail(awaitingVerificationCaseList);
        }
        if(!migrationCompleteCaseList.isEmpty()){
            NSP_CaseTriggerEmailNotification.sendMigrationCompleteEmail(migrationCompleteCaseList);
        }
        //Added as a part of STY-03638
        if(!nonInsperityEmplCaseList.isEmpty()){
            sendMailtoPrimaryCaseContact(nonInsperityEmplCaseList);
        }
        // STY-01785. update parent NSP_CQA_Severity__c with the highest level of the child NSP_CQA_Severity__c
        if(!itaParentCaseIdSet.isEmpty()){
            updateParentItaCqaCase(itaParentCaseIdSet);
        }
        //STY-01785. Sending an email to Project Implementor if Master ITA CQA case is closed
        if(!itqCqaPrjctIdSet.isEmpty()){
            sendEmailToProjectImplementor(itqCqaPrjctIdSet);
        }
        //STY-01785. update parent ITA CQA Case Status when the all the child case status is closed
        if ( !itaChildClosedParentCseIdSet.isEmpty()
            && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() )
            )
        {
            NSP_CaseTriggerHelper.updatePrentItaCqaCaseStatus( itaChildClosedParentCseIdSet );
        }
        //STY-01785. update parent ITA CQA Case Status when any one of the child case is re-opened
        if(!reOpenParentItaCqaIdSet.isEmpty()){
            reOpenParentItaCqaCase(reOpenParentItaCqaIdSet);
        }
        if(!NiceCXcaseIdset.isEmpty()){
            UpdateServiceRequestChannel(NiceCXcaseIdset);
        }
        createCaseHistory(caseOldMap, caseNewMap);

    }

    // @description Resolves and assigns Asset to Cases based on category/subcategory mapping.
    // @param caseList Cases to process.
    // @param categorySet Case categories to match.
    // @param subCategorySet Case subcategories to match.
    // @param accIdSet Account Ids from the cases.
    // @param isInsert True when running in before-insert context.
    public void autoPopulateAsset(
        List<Case> caseList ,
        Set<String> categorySet ,
        Set<String> subCategorySet ,
        Set<Id> accIdSet ,
        Boolean isInsert
        )
    {
        try {
            Map<String,String> catSubCatMap = this.buildCategoryAssetRecordTypeMap(
                categorySet ,
                subCategorySet
            );
            Set<String> assetRecTypeSet = new Set<String>( catSubCatMap.values() );
            Map<String, Asset> activeAssetMap = new Map<String, Asset>();
            Map<String, Asset> terminatedAssetMap = new Map<String, Asset>();
            Set<Id> assetRecTypeIdSet = this.getAssetRecordTypeIds(assetRecTypeSet);
            this.buildAssetLookupMaps(
                accIdSet ,
                assetRecTypeIdSet ,
                activeAssetMap ,
                terminatedAssetMap
            );
            for ( Case cse : caseList ) {
                Asset assetRec = this.resolveAssetId(
                    cse ,
                    catSubCatMap ,
                    activeAssetMap ,
                    terminatedAssetMap
                );

                if(assetRec != null) {
                    cse.AssetId = assetRec.Id;
                    cse.NSP_ClientNumber__c = assetRec.NSP_Client__c;
                    cse.NSP_Segment__c = assetRec.NSP_Client_Segment_type__c;
                }
            }
            if ( isInsert ) {
                this.clearFlsaSubCategoryIfApplicable( caseList );
            }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException( e , 'autoPopulateAsset' );
        }
    }

    private Set<Id> getAssetRecordTypeIds( Set<String> assetRecTypeSet ) {
        Set<Id> assetRecTypeIdSet = new Set<Id>();
        if ( !assetRecTypeSet?.isEmpty() ) {
            for ( String assetRecTypeName : assetRecTypeSet ) {
                assetRecTypeIdSet.add(
                    NSP_GenericRecordType.getRecordTypeIdByLabel(
                        'Asset' ,
                        assetRecTypeName
                    )
                );
            }
        }
        return assetRecTypeIdSet;
    }

    // @description Builds map from "category;subcategory" key to asset record type name.
    // @param categorySet Categories to filter.
    // @param subCategorySet Subcategories to filter.
    // @return Map keyed by "category;subcategory" to asset record type name.
    private Map<String,String> buildCategoryAssetRecordTypeMap(
        Set<String> categorySet ,
        Set<String> subCategorySet
        )
    {
        Map<String,String> catSubCatMap = new Map<String,String>();
        if ( ( categorySet != null ) && ( subCategorySet != null ) ) {
            for ( NSP_Category_Sub_Category_Mapping__c mapping : [
                        SELECT
                            Id ,
                            NSP_Category__c ,
                            NSP_Subcategory__c ,
                            NSP_Asset_Record_Types__c
                        FROM NSP_Category_Sub_Category_Mapping__c
                        WHERE (
                            ( NSP_Category__c IN :categorySet )
                            AND ( NSP_Subcategory__c IN :subCategorySet )
                        )
                    ]
                )
            {
                catSubCatMap.put(
                    mapping.NSP_Category__c + ';' + mapping.NSP_Subcategory__c ,
                    mapping.NSP_Asset_Record_Types__c
                );
            }
        }
        return catSubCatMap;
    }

    // @description Populates active and terminated asset lookup maps from a single query.
    //              ORDER BY NSP_Termination_Date__c DESC NULLS LAST places terminated records
    //              first, so the first terminated record per key is the most recently terminated.
    // @param accIdSet Account Ids to query.
    // @param assetRecTypeSet Asset record type names to include.
    // @param activeAssetMap Populated with active assets keyed by "recordTypeName-accountId".
    // @param terminatedAssetMap Populated with most recently terminated assets keyed by "recordTypeName-accountId".
    private void buildAssetLookupMaps(
        Set<Id> accIdSet ,
        Set<Id> assetRecTypeIdSet ,
        Map<String, Asset> activeAssetMap ,
        Map<String, Asset> terminatedAssetMap
        )
    {
        if ( !accIdSet?.isEmpty() && !assetRecTypeIdSet?.isEmpty() ) {
            List<String> excludedAccountStatuses = new List<String>{
                NSP_ServiceConstants.TERMINATED ,
                NSP_ServiceConstants.BACKOUT
            };
            for ( Asset assetRecord : [
                        SELECT
                            Id ,
                            AccountId ,
                            RecordType.Name ,
                            NSP_Account_Status__c ,
                            NSP_Termination_Date__c,
                            NSP_Client_Segment_type__c,
                            NSP_Client__c
                        FROM Asset
                        WHERE (
                            ( AccountId IN :accIdSet )
                            AND ( RecordTypeId IN :assetRecTypeIdSet )
                            AND (
                                (
                                    Status IN (
                                        'Active' ,
                                        'Onboarding' ,
                                        'On Demand'
                                    )
                                    AND ( NSP_Account_Status__c NOT IN :excludedAccountStatuses )
                                )
                                OR ( NSP_Account_Status__c = :NSP_ServiceConstants.TERMINATED )
                            )
                        )
                        ORDER BY NSP_Termination_Date__c DESC NULLS LAST , LastModifiedDate DESC
                    ]
                )
            {
                String key = this.buildAssetKey( assetRecord.RecordType.Name , assetRecord.AccountId );
                if ( assetRecord.NSP_Account_Status__c == NSP_ServiceConstants.TERMINATED ) {
                    if ( ( terminatedAssetMap != null )
                        && !terminatedAssetMap.containsKey( key )
                        )
                    {
                        terminatedAssetMap.put( key , assetRecord );
                    }
                } else if ( activeAssetMap != null ) {
                    activeAssetMap.put( key , assetRecord );
                }
            }
        }
    }

    // @description Resolves the Asset Id for a Case using active then terminated fallback.
    // @param cse Case to evaluate.
    // @param catSubCatMap Category/subcategory to asset record type map.
    // @param activeAssetMap Active asset lookup map.
    // @param terminatedAssetMap Terminated asset fallback lookup map.
    // @return Asset Id, or null if no match found.
    private Asset resolveAssetId(
        Case cse ,
        Map<String,String> catSubCatMap ,
        Map<String, Asset> activeAssetMap ,
        Map<String, Asset> terminatedAssetMap
        )
    {
        String assetRecType = catSubCatMap?.get( cse.NSP_Category__c + ';' + cse.NSP_SubCategory__c );
        Asset assetRec = null;
        if ( String.isNotBlank( assetRecType ) ) {
            String key = this.buildAssetKey( assetRecType , cse.AccountId );

            if ( activeAssetMap?.containsKey( key ) ) {
                assetRec = activeAssetMap.get( key );
            } else if ( terminatedAssetMap?.containsKey( key ) ) {
                assetRec = terminatedAssetMap.get( key );
            }
        }

        return assetRec;
    }

    // @description Clears NSP_SubCategory__c for FLSA cases on insert.
    // @param caseList Cases to evaluate.
    private List<Case> clearFlsaSubCategoryIfApplicable( List<Case> caseList ) {
        List<Case> returnCaseList = new List<Case>();
        if ( ( caseList != null ) && !caseList.isEmpty() ) {
             for ( Case cse : caseList ) {
                if ( ( cse.NSP_Category__c == NSP_ServiceConstants.FLSA_CATEGORY )
                    && ( cse.NSP_SubCategory__c == NSP_ServiceConstants.SUBCATEGORY_NOT_ON_UI )
                    )
                {
                    cse.NSP_SubCategory__c = '';
                    returnCaseList.add( cse );
                }
            }
        }
        return returnCaseList;
    }

    // @description Builds the asset lookup key from record type name and account Id.
    // @param recordTypeName Asset record type name.
    // @param accountId Account Id.
    // @return Concatenated key string.
    private String buildAssetKey( String recordTypeName , Id accountId ) {
        return recordTypeName + '-' + accountId;
    }

    // update contact support role from ACR
    // parameter : list of cases
    public static void updateContactSupportRole( List<Case> supportCases ) {
        try {
            if ( ( supportCases != null ) && !supportCases.isEmpty() ) {
                for ( Case sCase : supportCases ) {
                    Boolean isSupportRoleFound = false;
                    for ( AccountContactRelation ACR : [
                                SELECT Id , NSP_Support_Role__c
                                FROM AccountContactRelation
                                WHERE (
                                    AccountId = :sCase.AccountId
                                    AND ContactId = :sCase.ContactId
                                )
                            ]
                        )
                    {
                        if ( String.isNotBlank( ACR.NSP_Support_Role__c ) ) {
                            String [] ACRSupportRoleValues = ACR.NSP_Support_Role__c.split(';');
                            for ( String supportRole : ACRSupportRoleValues ) {
                                if ( !isSupportRoleFound
                                    && (
                                        ( ( sCase.NSP_Category__c == 'Time and Attendance' ) || ( sCase.NSP_Category__c == 'Time & Attendance') )
                                        && NSP_CaseTriggerHelper.timeAttendanceSupportRoles.contains( supportRole )
                                    )
                                    || ( ( sCase.NSP_Category__c == 'Time Clocks' ) && NSP_CaseTriggerHelper.timeAttendanceSupportRoles.contains( supportRole ) )
                                    || ( ( sCase.NSP_Category__c == 'OrgPlus Software' ) && NSP_CaseTriggerHelper.orgPlusSupportRoles.contains( supportRole ) )
                                    || ( ( sCase.NSP_Category__c == 'PerformSmart Software' ) && NSP_CaseTriggerHelper.performSmartSupportRoles.contains( supportRole ) )
                                    || ( ( sCase.NSP_Category__c == 'WX/WA' ) && NSP_CaseTriggerHelper.tesSupportRoles.contains( supportRole ) )
                                    )
                                {
                                    sCase.Contact_Support_Role__c = supportRole;
                                    isSupportRoleFound = true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'updateContactSupportRole'
            );
        }
    }

    /**
* Iterate for each case and verify the the condition for BPS Support AccountGroup.
* @param Case newCase.
* @return Case
*
*/
    public Case isBPSSupportAccountGroup(Case eachCase){
        Id bpsRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'BPS' );
        if(eachCase.RecordTypeId == bpsRecordTypeId && !String.isBlank(eachCase.AccountId)){
            if(eachCase.NSP_Category__c == NSP_ServiceConstants.CASE_TIME_ATTENDENCE){
                caseAccountIdStatus.put(eachCase.AccountId, NSP_ServiceConstants.TIME_ATTENDANCE_ASSET);
            }
            else if(eachCase.NSP_Category__c == NSP_ServiceConstants.CASE_ORGPLUS_SOFTWARE){
                caseAccountIdStatus.put(eachCase.AccountId, NSP_ServiceConstants.ORGANIZATIONAL_PLANNING_ASSET);
            }
            else if(eachCase.NSP_Category__c == NSP_ServiceConstants.CASE_PERFORM_SOFTWARE){
                caseAccountIdStatus.put(eachCase.AccountId, NSP_ServiceConstants.PERFORMANCE_MANAGEMENT_ASSET);
            }
            else if(eachCase.NSP_Category__c == NSP_ServiceConstants.CASE_WX_WA){
                caseAccountIdStatus.put(eachCase.AccountId, NSP_ServiceConstants.WX_WA_RECORD_TYPE);
            }
        }
        return eachCase;
    }

    /**
* Iterate for each case and update update Case SupportAccountGroup.
* @param List<Case> newList.
* @param Map<String,String> caseAccountIdStatus.
* @return Case
*
*/
    private void updateSupportAccountGroup(List<Case> newList, Map<String,String> caseAccountIdStatus){
        Map<String,String> mapAccountIdSupportGroupId = new  Map<String,String>();
        for(Asset asst : [SELECT Id,AccountId, NSP_Support_Account_Group__c FROM Asset
                          WHERE AccountId IN: caseAccountIdStatus.keyset() AND Status !=:NSP_ServiceConstants.TERMINATED
                          AND RecordType.Name IN: caseAccountIdStatus.values()]){
                              mapAccountIdSupportGroupId.put(asst.AccountId,asst.NSP_Support_Account_Group__c);
                          }
        for(case eachCase: newList){
            if(mapAccountIdSupportGroupId.containskey(eachCase.AccountId)){
                eachCase.NSP_Support_Account_Group__c = mapAccountIdSupportGroupId.get(eachCase.AccountId);
            }
        }
    }

    public void updateCreatedByDivision(List<Case> insertedCaseList){
        Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Case' , 'PEO' );
        List<Id> UserIds = New List<Id>();
        for(Case cse: insertedCaseList){
            if ( cse.RecordTypeId == peoRecordTypeId ) {
                UserIds.add(cse.OwnerId);
            }
        }

        List<User> Usr = [Select id ,Division from User WHERE id =: UserIds];
        Map<id , String> UsrMap = New Map<id , String>();
        for(user ur : Usr){
            UsrMap.put(ur.id , ur.Division);
        }

        for(Case cse: insertedCaseList){
            if(UsrMap.containsKey(cse.OwnerId)){
                cse.NSP_Created_by_Division__c = UsrMap.get(cse.OwnerId);
            }
        }
    }
    /**
* @MethodName: cancelPreviouslyCreatedCase
* @Description: When Does client have their code / group ID? = Yes and previously it was No on NSP_Implementation_Profile__c, then the previously
created case will be updated to cancelled.
* @param : Set<Id> ipSet
* @createdDate : 9/5/2022
* @Defect : STY-03256
* @return void
*/
    public void cancelPreviouslyCreatedCase(Set<Id> ipSet){
        List<Case> updateCaseList = new List<case>();
        for(Case cse : [SELECT Id, Status,
                        NSP_Implementation_Profile__c,
                        Subject
                        FROM Case
                        WHERE Status !=: NSP_ServiceConstants.STATUSCANCELLED
                        AND NSP_Implementation_Profile__c IN: ipSet
                        AND Subject =: NSP_ServiceConstants.SUBJECT8]){
                            cse.Status = NSP_ServiceConstants.STATUSCANCELLED ;
                            updateCaseList.add(cse);
                        }
        if(!updateCaseList.isEmpty()){
            Database.update(updateCaseList);
        }
    }

    /**
* @MethodName: reassignActivitiesOwner
* @Description: This method describes about when the case owner changed, then task owners should not get reassigned.
* @param : List<Case> ownerChangedList
* @createdDate : 9/30/2022
* @Defect : STY-01774
* @return void
*/
    public void reassignActivitiesOwner(Set<Id> ownerChangedList){
        List<sObject> restoreOwnerList = new List<sObject>();
        Set<Id> conDocIdSet = new Set<Id>();
        for(Task tsk : [SELECT Id,
                        WhatId,
                        OwnerId,
                        NSP_Last_Assigned_Owner__c
                        FROM Task
                        WHERE WhatId IN: ownerChangedList
                        AND NSP_Last_Assigned_Owner__c != null
                        AND IsClosed != TRUE ]) {
                            if( tsk.OwnerId  != tsk.NSP_Last_Assigned_Owner__c){
                                tsk.OwnerId =tsk.NSP_Last_Assigned_Owner__c;
                                restoreOwnerList.add(tsk);
                            }
                        }
        for(Event evt : [SELECT Id,
                         WhatId,
                         OwnerId,
                         NSP_Last_Assigned_Owner__c
                         FROM Event
                         WHERE WhatId IN: ownerChangedList
                         AND NSP_Last_Assigned_Owner__c != null]) {
                             if (evt.OwnerId != evt.NSP_Last_Assigned_Owner__c) {
                                 evt.OwnerId = evt.NSP_Last_Assigned_Owner__c;
                                 restoreOwnerList.add(evt);
                             }
                         }
        for(ContentDocumentLink cLink :[SELECT ContentDocumentId ,LinkedEntityId
                                        FROM ContentDocumentLink
                                        WHERE LinkedEntityId IN: ownerChangedList LIMIT 1]){
                                            conDocIdSet.add(cLink.ContentDocumentId);
                                        }
        if(!conDocIdSet.isEmpty()){
            for(ContentVersion conVer : [SELECT Id,OwnerId,
                                         NSP_Last_Assigned_Owner__c,
                                         ContentDocumentId
                                         FROM ContentVersion
                                         WHERE ContentDocumentId IN :conDocIdSet
                                         AND NSP_Last_Assigned_Owner__c != null]){
                                             if (conVer.OwnerId != conVer.NSP_Last_Assigned_Owner__c) {
                                                 conVer.OwnerId = conVer.NSP_Last_Assigned_Owner__c;
                                                 restoreOwnerList.add(conVer);
                                             }

                                         }
        }
        try{
            if (!restoreOwnerList.isEmpty()) {
                database.update(restoreOwnerList);
            }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'reassignActivitiesOwner'
            );
        }
    }

    /**
* @MethodName: getReassignRecordTypeIds
* @Description: This method is used to get Reassign recordtype Ids
* @param :
* @createdDate : 9/30/2022
* @Defect : STY-01774
* @return void
*/
    public Set<Id> getReassignRecordTypeIds(){
        Set<Id> reassignRecTypeIds = new Set<Id>();
        try{
            List < String > reassignRecTypes = Label.NSP_Reassign_Record_Types.split(',');
            for(RecordType cRecTypes : [SELECT Id,
                                        Name
                                        FROM RecordType
                                        WHERE sObjectType='Case'
                                        AND Name IN: reassignRecTypes]){
                                            reassignRecTypeIds.add(cRecTypes.Id);
                                        }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'getReassignRecordTypeIds'
            );
        }
        return reassignRecTypeIds;
    }

    private static void sendSingleEmailMessages( List<Messaging.SingleEmailMessage> messages ) {
        if ( EmailDeliverabilityController.isEnabledOutbound
            && ( messages != null )
            && !messages.isEmpty()
            )
        {
            try {
                Messaging.sendEmail( messages );
            } catch ( Exception e ) {
                NSP_CaseTriggerHelper.handleException(
                    e ,
                    'sendSingleEmailMessages'
                );
            }
        }
    }

    private static void handleException( Exception e , String methodName ) {
        if ( e != null ) {
            NSP_ErrorLogHandler.logException(
                NSP_CaseTriggerHelper.class.getName() ,
                methodName ,
                e
            );
        }
    }

    /***********************************************************************************************
* MethodName  : caseCloseForFirstTime
* Description : This Method updated the NSP_Is_Case_Closed__c checkbox on Case
* Params:     : List<Case> caseList
* ********************************************************************************************/

    public static void caseCloseForFirstTime(List<Case> caseList){
        try{
            for(Case caseRec: caseList){
                caseRec.NSP_Is_Case_Closed__c = true;
            }
        } catch ( Exception e ){
            NSP_CaseTriggerHelper.handleException(
                e ,
                'caseCloseForFirstTime'
            );
        }
    }

    /***********************************************************************************************
* MethodName  : bankAuditCaseCompletionEmail
* Description : This Method sends an email when the bank audit case is closed for the first time
* Params      : List<Case> caseList
* Story       : STY-02183
* ********************************************************************************************/

    public void bankAuditCaseCompletionEmail(List<Case> caseList){
        List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
        List<String> emailTempFields = new List<String>{
            'ID',
                'BrandTemplateId',
                'Subject',
                'HTMLValue',
                'Body',
                'DeveloperName'
                };
                    EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_iSolved_HCM_Case_Completion_Email');
        List<String> sendToList = new List<String>{System.Label.NSP_iSolved_HCM_Case_Completion_Email};
            for(Case caseRec: [SELECT Id, Project__c, Project__r.name FROM CASE WHERE Id IN: caseList]){
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null , caseRec.Id);
                String subject = email.getSubject() + ' ' + caseRec.Project__r.name;
                email.setSubject(subject);
                email.setTemplateId(emailTemplate.Id);
                email.setToAddresses(sendToList);
                email.setWhatId(caseRec.Id);
                email.setSaveAsActivity(false);
                lstEmailMessages.add(email);
            }
        if ( !lstEmailMessages.isEmpty() && !Test.isRunningTest() ) {
            NSP_CaseTriggerHelper.sendSingleEmailMessages( lstEmailMessages );
        }
    }

    /***********************************************************************
* @MethodName: bpsCaseUpdateForNonInsperityEmployeeType
* @Description: This method will update the BPS type case
*               field values for Type field value
*               selected as NON Insperity Employee
* @param : List<Case> caseList
* @createdDate : 06/01/2023
* @Story : STY-03638
* @return: void
**************************************************************************/
    public void bpsCaseUpdateForNonInsperityEmployeeType(List<Case> caseList){
        try{
            for(Case caseRec : caseList){
                bpsCaseUpdateFieldMapping(caseRec);
            }
        } catch( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'bpsCaseUpdateForNonInsperityEmployeeType'
            );
        }
    }

    /***********************************************************************
* @MethodName: bpsCaseUpdateFieldMapping
* @Description: This method will map the BPS type case field values
* @param : Case caseRec
* @createdDate : 06/01/2023
* @Story : STY-03638
* @return: void
**************************************************************************/
    public void bpsCaseUpdateFieldMapping(Case caseRec){
        caseRec.Subject = NSP_ServiceConstants.NON_INSPERITY_EMPLOYEE;
        caseRec.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        caseRec.NSP_Case_Sub_Status__c = NSP_ServiceConstants.CASE_SUB_STATUS_WAITING_ON_CUSTOMER;
        caseRec.Priority = NSP_ServiceConstants.CASE_PRIORITY_HIGH;
        caseRec.Origin = NSP_ServiceConstants.CASE_ORIGIN_EMAIL;
        caseRec.NSP_Category__c = NSP_ServiceConstants.CASE_CATEGORY_TIME_AND_ATTENDANCE;
        caseRec.NSP_SubCategory__c = NSP_ServiceConstants.CASE_SUBCATEGORY_TIMESTAR_WO;
    }

    /***********************************************************************
* @MethodName: sendMailtoPrimaryCaseContact
* @Description: This method will send email to primary Case Contact
* @param : List<NSP_Case_Contacts__c caseContactList
* @createdDate : 06/01/2023
* @Story : STY-03638
* @return: void
**************************************************************************/
    public void sendMailtoPrimaryCaseContact(List<Case> caseList){
        String subject;
        Set<Id> caseIdset = new Set<Id>();
        List<String> toAddressList = new List<String>();
        List<NSP_Case_Contacts__c> caseContactList = new List<NSP_Case_Contacts__c>();
        List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        for(Case caseRec : caseList){
            caseIdset.add(caseRec.Id);
        }
        if(!caseIdset.isEmpty()){
            List<String> caseContactFields = new List<String>{'Id','Contact_Name__c','NSP_Work_Email__c','NSP_Contact_Email__c','NSP_IsPrimary__c','NSP_Contact__c','NSP_Case__r.CaseNumber','NSP_Case__r.Subject'};
                String queryCase = new NSP_QueryBuilder('NSP_Case_Contacts__c', caseContactFields)
                .addFilter('NSP_Case__c', new List<Id>(caseIdSet), NSP_QueryBuilder.Operator.INCLUDES)
                .addFilter('NSP_IsPrimary__c', true).build();
            caseContactList = (List<NSP_Case_Contacts__c>)Database.query(queryCase);
        }

        if(!caseContactList.isEmpty()){
            for(NSP_Case_Contacts__c caseConRec : caseContactList){
                toAddressList.add(caseConRec.NSP_Contact_Email__c);
            }
        }
        //get Email Template
        List<String> emailTempFields = new List<String>{'ID'};
            EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_Case_Contact_Email_Notification');
        if(emailTemplate != null && !toAddressList.isEmpty() && !caseContactList.isEmpty()){
            for(NSP_Case_Contacts__c caseConRec: caseContactList){
                email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null , caseConRec.NSP_Contact__c);
                subject = caseConRec.NSP_Case__r.CaseNumber +' '+ email.getSubject();
                email.setSubject(subject);
                email.setTemplateId(emailTemplate.Id);
                email.setToAddresses(toAddressList);
                email.setWhatId(caseConRec.Id);
                email.setSaveAsActivity(false);
                emailMessageList.add(email);
            }
        }

        if(!emailMessageList.isEmpty()){
            //Send mail
            NSP_GenericEmailUtility.sendSingleEmailMessages(emailMessageList,false);
        }
    }

    /**********************************************************************************************
* MethodName: updateCqaSeverity
* Description : This method describes about the mapping of NSP_CQA_Severity__c
* Params:       Set<Id> itaChildCaseIdSet
* Story:        STY-01785
* ********************************************************************************************/
    private static void updateCqaSeverity(List<Case> itaCqaCaseList){
        // getting map of NSP_CQA_Resulting_Severity__c and NSP_CQA_Severity__c
        Map<string, string> resultingSeverityAndSeverityMap = getMapOfResultingSeverityAndSeverity();
        for(Case cse : itaCqaCaseList){
            cse.NSP_CQA_Severity__c = resultingSeverityAndSeverityMap.get(cse.NSP_CQA_Resulting_Severity__c);
        }
    }
    /**********************************************************************************************
* MethodName: getMapOfResultingSeverityAndSeverity
* Description : This method describes about the framing of map of NSP_CQA_Resulting_Severity__c and NSP_CQA_Severity__c
* Params:       Set<Id> itaChildCaseIdSet
* Story:        STY-01785
* ********************************************************************************************/
    private static Map<string, string> getMapOfResultingSeverityAndSeverity(){
        Map<string, string> resultingSeverityAndSeverityMap = new Map<String, String>();
        List<NSP_ITA_CQA_Case_Severity__mdt> assTempMap = NSP_ITA_CQA_Case_Severity__mdt.getAll().values();
        for(NSP_ITA_CQA_Case_Severity__mdt iTaCqa : assTempMap){
            resultingSeverityAndSeverityMap.put(iTaCqa.NSP_CQA_Resulting_Severity__c, iTaCqa.NSP_CQA_Severity__c);
        }
        return resultingSeverityAndSeverityMap;
    }
    /**********************************************************************************************
* MethodName: sendEmailToProjectImplementor
* Description : This method describes about the Sending an email to Project Implementor if Master ITA CQA case is closed
* Params:       Set<Id> itaChildCaseIdSet
* Story:        STY-01785
* ********************************************************************************************/
    private static void sendEmailToProjectImplementor(Set<Id> projectIdSet){
        List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> toAddressList = new List<String>();
        List<String> emailTempFields = new List<String>{'ID'};
            EmailTemplate emailTemplate = NSP_sObjectSelector.selectByDeveloperName(emailTempFields, 'NSP_ITA_CQA_Master_Case_Closed_Alert');
        try{
            for(pse__Proj__c prj : [SELECT Id, Project_Implementer__c, Project_Implementer__r.Email FROM pse__Proj__c WHERE Id IN: projectIdSet
                                    AND Project_Implementer__r.Email != null]){
                                        toAddressList.add(prj.Project_Implementer__r.Email);
                                        if(emailTemplate != null && !toAddressList.isEmpty()){
                                            email= Messaging.renderStoredEmailTemplate(emailTemplate.Id, null , prj.Id);
                                            email.setTargetObjectId(userInfo.getUserId());
                                            email.setTemplateId(emailTemplate.Id);
                                            email.setToAddresses(toAddressList);
                                            email.setWhatId(prj.Id);
                                            email.setSaveAsActivity(false);
                                            emailMessageList.add(email);
                                        }
                                    }
            if(!emailMessageList.isEmpty()){
                //Send mail
                NSP_GenericEmailUtility.sendSingleEmailMessages(emailMessageList,false);
            }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'sendEmailToProjectImplementor'
            );
        }
    }

    /**********************************************************************************************
* MethodName: updateParentItaCqaCase
* Description : This method describes about the updation of parent NSP_CQA_Severity__c with the highest level of the child NSP_CQA_Severity__c
* Params:       Set<Id> itaChildCaseIdSet
* Story:        STY-01785
* ********************************************************************************************/
    @future
    private static void updateParentItaCqaCase(Set<Id> itaParentCaseIdSet){
        List<String> openReOpenedStatus = new List<string>{NSP_ServiceConstants.CASE_OPEN_STATUS, NSP_ServiceConstants.REOPENED};
            Map<Id, List<string>> parentIdListOfCqaSeverityMap = new Map<Id, List<string>>();
        List<Case> pCaseList = new List<case>();
        try{
            // framing map of parent CaseId and list of child cases NSP_CQA_Severity__c
            for(Case cse : [SELECT Id, NSP_CQA_Resulting_Severity__c, NSP_CQA_Severity__c, ParentId, Parent.Status, Parent.NSP_CQA_Resulting_Severity__c,
                            Parent.NSP_CQA_Severity__c, Parent.recordTypeId FROM Case WHERE ParentId IN: itaParentCaseIdSet
                            AND Parent.Status IN: openReOpenedStatus
                            AND Status IN: openReOpenedStatus
                            AND Parent.recordTypeId =: itaCqaRecordTypeId]){
                                if(parentIdListOfCqaSeverityMap.containsKey(cse.ParentId)) {
                                    parentIdListOfCqaSeverityMap.get(cse.ParentId).add(cse.NSP_CQA_Severity__c);
                                }else{
                                    parentIdListOfCqaSeverityMap.put(cse.ParentId, new list<String>{cse.NSP_CQA_Severity__c});
                                }
                            }
            // mapping child cases highest NSP_CQA_Severity__c to parent case
            if(!parentIdListOfCqaSeverityMap.isEmpty()){
                for(Case pCse : [SELECT Id, NSP_CQA_Severity__c FROM Case WHERE Id IN: parentIdListOfCqaSeverityMap.keySet()]){
                    pCse.NSP_CQA_Severity__c = parentIdListOfCqaSeverityMap.get(pCse.Id).contains(NSP_ServiceConstants.L1_PAYROLL_CRITICAL)
                        ? NSP_ServiceConstants.L1_PAYROLL_CRITICAL
                        : parentIdListOfCqaSeverityMap.get(pCse.Id).contains(NSP_ServiceConstants.L2_CRUCIAL)
                            ? NSP_ServiceConstants.L2_CRUCIAL
                            : parentIdListOfCqaSeverityMap.get(pCse.Id).contains(NSP_ServiceConstants.L3_LOW)
                                ? NSP_ServiceConstants.L3_LOW
                                : parentIdListOfCqaSeverityMap.get(pCse.Id).contains(NSP_ServiceConstants.L4_NONE)
                                    ? NSP_ServiceConstants.L4_NONE : pCse.NSP_CQA_Severity__c;
                    pCaseList.add(pCse);
                }
                if(!pCaseList.isEmpty()){
                    //updating Parent Case
                    List<Database.SaveResult> results = Database.update(pCaseList, false);
                    NSP_ErrorLogHandler.logResults(
                        NSP_CaseTriggerHelper.class.getName() ,
                        'updateParentItaCqaCase' ,
                        results
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'updateParentItaCqaCase'
            );
        }
    }

    //
    // MethodName: updatePrentItaCqaCaseStatus
    // Description : This method describes about the updation of parent ITA CQA Case Status when the all the child case status is closed
    // Params: Set<Id> itaChildCaseIdSet
    // Story: STY-01785
    //
    @future
    private static void updatePrentItaCqaCaseStatus( Set<Id> updatePrentItaCqaCaseStatus ) {
        try {
            Map<Id,List<String>> parentIdChildStatusMap = new Map<Id,List<String>>();
            for ( Case cse : [
                        SELECT Id , Status , ParentId
                        FROM Case
                        WHERE ( ParentId IN :updatePrentItaCqaCaseStatus )
                    ]
                )
            {
                if ( !parentIdChildStatusMap.containsKey( cse.ParentId ) ) {
                    parentIdChildStatusMap.put( cse.ParentId , new List<String>() );
                }
                parentIdChildStatusMap.get( cse.ParentId ).add( cse.Status );
            }
            List<Case> cseListToUpdate = new List<Case>();
            if ( !parentIdChildStatusMap.isEmpty() ) {
                for ( Case cse : [
                            SELECT Id , Status
                            FROM Case
                            WHERE ( Id IN :parentIdChildStatusMap.keySet() )
                        ]
                    )
                {
                    List<String> parentIdChildStatuses = parentIdChildStatusMap.get( cse.Id );
                    if ( ( parentIdChildStatuses != null )
                        && !parentIdChildStatuses.contains( NSP_ServiceConstants.CASE_OPEN_STATUS )
                        && !parentIdChildStatuses.contains( NSP_ServiceConstants.REOPENED )
                        && !parentIdChildStatuses.contains( NSP_ServiceConstants.CASE_STATUS_NOT_STARTED )
                        )
                    {
                        cse.Status = NSP_ServiceConstants.CASE_CLOSED_STATUS;
                        cseListToUpdate.add( cse );
                    }
                }
                if ( !cseListToUpdate.isEmpty() ) {
                    List<Database.SaveResult> results = Database.update( cseListToUpdate , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_CaseTriggerHelper.class.getName() ,
                        'updatePrentItaCqaCaseStatus' ,
                        results
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'updatePrentItaCqaCaseStatus'
            );
        }
    }

    /**********************************************************************************************
MethodName: reOpenParentItaCqaCase
Description : This method describes about the updation of parent ITA CQA Case Status when any one of the child case is re-opened
Params:       Set<Id> itaChildCaseIdSet
Story:        STY-01785
********************************************************************************************/
    @future
    private static void reOpenParentItaCqaCase(Set<Id> reOpenParentItaCqaIdSet){

        List<Case> pCseListToUpdate = new List<Case>();
        try{
            for(Case cse : [SELECT Id, Status FROM Case WHERE Status !=: NSP_ServiceConstants.REOPENED AND Id IN: reOpenParentItaCqaIdSet]){
                cse.Status = NSP_ServiceConstants.REOPENED;
                pCseListToUpdate.add(cse);
            }
            if(!pCseListToUpdate.isEmpty()){
                List<Database.SaveResult> results = Database.update(pCseListToUpdate, false);
                NSP_ErrorLogHandler.logResults(
                    NSP_CaseTriggerHelper.class.getName() ,
                    'reOpenParentItaCqaCase' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'reOpenParentItaCqaCase'
            );
        }
    }

    public void createCaseHistory( Map<Id,Case> oldMap , Map<Id,Case> newMap ) {
        try {
            if(oldMap.isEmpty()) {
                List<NSP_Case_History__c> newCaseHistoryToBeCreatedList = new List<NSP_Case_History__c>();
                Set<Id> caseIdsSet = new Set<Id>();
                for(Id caseId : newMap.keySet()) {
                    caseIdsSet.add(caseId);
                }
                Map<Id,Case> caseMap ;
                if(caseIdsSet.size()>0){
                    caseMap = new Map<ID, Case>([SELECT Id, TYPEOF Owner WHEN User Then nsp_service_region__c,name,Manager.Name,Title WHEN Group THEN Name, DeveloperName END  FROM Case WHERE Id IN :caseIdsSet ]);
                }
                for(Case newCase : newMap.values()) {
                    NSP_Case_History__c caseHistory = new NSP_Case_History__c();
                    caseHistory.NSP_Case__c = newCase.Id;
                    String ownerName = null;
                    Case caseRec = null;
                    if ( ( caseMap != null )
                        && caseMap.containsKey( newCase.Id )
                        && ( caseMap.get( newCase.Id ) != null )
                        )
                    {
                        caseRec = caseMap.get(newCase.Id);
                    }
                    if ( caseRec != null ) {
                        if ( newCase.OwnerId.getSObjectType() == Group.getSObjectType() ) {
                            Group grp = caseRec.Owner;
                            ownerName = grp.Name;
                            String queueName = grp.DeveloperName;
                            if ( queueName == NSP_ReportingConstants.Time_H_W_B_P_C_Queue ) {
                                caseHistory.Time_H_W_B_P_C_Queue__c = 0;
                            } else if ( queueName == NSP_ReportingConstants.Time_H_W_Communications_Queue ) {
                                caseHistory.Time_H_W_Communications_Queue_Spent__c = 0;
                            } else if ( queueName == NSP_ReportingConstants.Time_Health_Welfare_Products_Queue ) {
                                caseHistory.Time_Health_Welfare_Products_Queue__c = 0;
                            } else {
                                caseHistory.NSP_Time_in_Queue__c = 0;
                            }
                        } else {
                            User userRec = caseRec.Owner;
                            ownerName = userRec.name;
                            caseHistory.NSP_Case_Current_Owners_Manager_Text__c = userRec.Manager != null && userRec.Manager.Name != null? userRec.Manager.name:'';
                            caseHistory.NSP_Case_Current_Service_Region_Text__c = userRec.nsp_service_region__c != null ? userRec.nsp_service_region__c :'';
                            caseHistory.NSP_Case_Current_Job_Title__c = userRec.Title != null ? userRec.Title :'';
                        }
                    }
                    caseHistory.NSP_Case_Current_Owner_Text__c = ownerName;
                    caseHistory.NSP_Case_Previous_Owner_Text__c = ownerName;
                    //caseHistory.NSP_Case_Current_Owner_Text__c = newCase.Status;
                    caseHistory.NSP_Case_Current_status__c = newCase.Status;
                    caseHistory.NSP_Case_Previous_Status__c = newCase.Status;
                    caseHistory.NSP_Case_Age__c = 0;
                    caseHistory.NSP_Time_Individual_Spent__c = 0;
                    caseHistory.NSP_Status_Duration__c = 0;
                    caseHistory.NSP_Start_Date__c=newCase.createdDate;
                    caseHistory.NSP_1st_Queue2User_Evaluated__c = false;
                    caseHistory.NSP_Case_Current_Detail__c = newCase.NSP_Detail__c;
                    caseHistory.NSP_Case_Current_Category__c = newCase.NSP_Category__c;
                    caseHistory.NSP_Case_Current_Sub_Category__c = newCase.NSP_SubCategory__c;
                    newCaseHistoryToBeCreatedList.add(caseHistory);
                }
                insert newCaseHistoryToBeCreatedList;
            } else {
                Set<Id> caseIds = new Set<Id>();
                for(Case newCaseRecord : newMap.values()) {
                    if(newCaseRecord.OwnerId != oldMap.get(newCaseRecord.Id).OwnerId || newCaseRecord.Status != oldMap.get(newCaseRecord.Id).Status) {
                        caseIds.add(newCaseRecord.Id);
                    }
                }
                if(!caseIds.isEmpty()) {
                    BusinessHours defaultBusinessHours = [SELECT ID FROM BusinessHours WHERE IsDefault=true];
                    List<Case> newCaseList = [
                        SELECT
                        Id, OwnerId, CreatedDate, Status, LastModifiedDate, NSP_Detail__c,NSP_Category__c,NSP_SubCategory__c,
                        NSP_JobTitle__c, TYPEOF Owner WHEN User Then nsp_service_region__c,name,
                        Manager.Name,Title WHEN Group THEN Name,DeveloperName END,
                        (SELECT Id, NSP_Case__c, CreatedDate,NSP_Case_Current_Owner_Text__c,
                        NSP_Case_Previous_Owner_Text__c, NSP_Case_Current_Owner__c,
                        NSP_Case_Current_status__c,
                        NSP_Time_Individual_Spent__c,NSP_Time_in_Queue__c,Time_H_W_B_P_C_Queue__c,
                        Time_H_W_Communications_Queue_Spent__c,
                        Time_Health_Welfare_Products_Queue__c,
                        NSP_Status_Duration__c,
                        NSP_Case_Previous_Owner__c, NSP_Case_Previous_Status__c,
                        NSP_Case_Current_Owners_Manager_Text__c,NSP_Case_Current_Service_Region_Text__c,NSP_Case_Current_Job_Title__c,
                        NSP_Case_Current_Sub_Category__c,NSP_1st_Queue2User_Evaluated__c,NSP_Case_1st_assigned_from_Queue_to_User__c FROM Case_Histories__r Order By CreatedDate Desc limit 1)
                        FROM Case
                        WHERE ( Id IN :caseIds )
                    ];
                    List<NSP_Case_History__c> newCaseHistoryToBeCreatedList = new List<NSP_Case_History__c>();
                    Datetime currentDateTime = Datetime.now();
                    NSP_Case_History__c historyRecord;
                    Decimal timeToAdd;
                    Boolean isQueue=false, isUser=false, isStatus=false;
                    for(Case newCaseRecord : newCaseList) {
                        Case oldCaseRecord = oldMap.get(newCaseRecord.Id);
                        if(!newCaseRecord.Case_Histories__r.isEmpty()) {
                            historyRecord = newCaseRecord.Case_Histories__r[0];
                            NSP_Case_History__c newCaseHistory = historyRecord.clone(false, false, false, false);
                            newCaseHistory.NSP_Case_Current_Detail__c = newCaseRecord.NSP_Detail__c;
                            newCaseHistory.NSP_Case_Current_Category__c = newCaseRecord.NSP_Category__c;
                            newCaseHistory.NSP_Case_Current_Sub_Category__c = newCaseRecord.NSP_SubCategory__c;
                            newCaseHistory.NSP_Start_Date__c = currentDateTime;
                            //Calculate time from case created till last modified.
                            newCaseHistory.NSP_Case_Age__c = calculateTimeDifference(defaultBusinessHours.Id, newCaseRecord.CreatedDate, newCaseRecord.LastModifiedDate);
                            timeToAdd = calculateTimeDifference(defaultBusinessHours.Id, historyRecord.CreatedDate, newCaseRecord.LastModifiedDate);
                            String newOwner;
                            if(newCaseRecord.OwnerId != oldCaseRecord.OwnerId && String.valueOf(newCaseRecord.OwnerId).startsWith(STARTSWITHGROUP)){
                                Group grp = newCaseRecord.owner;
                                newOwner = grp.Name;
                                newCaseHistory.NSP_Case_Current_Owners_Manager_Text__c ='';
                                newCaseHistory.NSP_Case_Current_Service_Region_Text__c = null;
                                newCaseHistory.NSP_Case_Current_Job_Title__c = '';
                            } else if(newCaseRecord.OwnerId != oldCaseRecord.OwnerId && String.valueOf(newCaseRecord.OwnerId).startsWith(STARTSWITHUSER)){
                                User newUser = newCaseRecord.owner;
                                newOwner = newUser.Name;
                                newCaseHistory.NSP_Case_Current_Service_Region_Text__c = newUser.nsp_service_region__c;
                                newCaseHistory.NSP_Case_Current_Owners_Manager_Text__c = newUser.Manager != null && newUser.Manager.Name != null? newUser.Manager.name:'';
                                newCaseHistory.NSP_Case_Current_Job_Title__c = newUser.Title != null ? newUser.Title:'';
                            }
                            if(newCaseRecord.OwnerId != oldCaseRecord.OwnerId && String.valueOf(oldCaseRecord.OwnerId).startsWith(STARTSWITHGROUP)) {
                                if(String.valueOf(newCaseRecord.OwnerId).startsWith(STARTSWITHGROUP)){
                                String grpOwner;
                                Group grp = newCaseRecord.owner;
                                grpOwner = grp.DeveloperName;
                                if(grpOwner == NSP_ReportingConstants.Time_H_W_B_P_C_Queue){
                                    newCaseHistory.Time_H_W_B_P_C_Queue__c=0;
                                } else if(grpOwner == NSP_ReportingConstants.Time_H_W_Communications_Queue){
                                    newCaseHistory.Time_H_W_Communications_Queue_Spent__c=0;
                                } else if(grpOwner == NSP_ReportingConstants.Time_Health_Welfare_Products_Queue){
                                    newCaseHistory.Time_Health_Welfare_Products_Queue__c=0;
                                } else{
                                    newCaseHistory.NSP_Time_in_Queue__c = 0;
                                }
                                }
                                newCaseHistory.NSP_Time_Individual_Spent__c = 0;
                                newCaseHistory.NSP_Case_Previous_Owner_Text__c = newCaseHistory.NSP_Case_Current_Owner_Text__c;
                                newCaseHistory.NSP_Case_Current_Owner_Text__c = newOwner;
                                isQueue = true;
                                if(!newCaseHistory.NSP_1st_Queue2User_Evaluated__c && String.valueOf(newCaseRecord.OwnerId).startsWith(STARTSWITHUSER)){
                                    newCaseHistory.NSP_1st_Queue2User_Evaluated__c = true;
                                    newCaseHistory.NSP_Case_1st_assigned_from_Queue_to_User__c = currentDateTime;
                                }
                            } else if(newCaseRecord.OwnerId != oldCaseRecord.OwnerId) {
                                if(String.valueOf(newCaseRecord.OwnerId).startsWith('00G')){
                                    String grpOwner;
                                    Group grp = newCaseRecord.owner;
                                    grpOwner = grp.DeveloperName;
                                    if(grpOwner == NSP_ReportingConstants.Time_H_W_B_P_C_Queue){
                                        newCaseHistory.Time_H_W_B_P_C_Queue__c=0;
                                    } else if(grpOwner == NSP_ReportingConstants.Time_H_W_Communications_Queue){
                                        newCaseHistory.Time_H_W_Communications_Queue_Spent__c=0;
                                    } else if(grpOwner == NSP_ReportingConstants.Time_Health_Welfare_Products_Queue){
                                        newCaseHistory.Time_Health_Welfare_Products_Queue__c=0;
                                    } else{
                                        newCaseHistory.NSP_Time_in_Queue__c = 0;
                                    }
                                }
                                newCaseHistory.NSP_Time_Individual_Spent__c = 0;
                                newCaseHistory.NSP_Case_Previous_Owner_Text__c = newCaseHistory.NSP_Case_Current_Owner_Text__c;
                                newCaseHistory.NSP_Case_Current_Owner_Text__c = newOwner;
                                isUser = true;
                            }
                            if(newCaseRecord.OwnerId == oldCaseRecord.OwnerId && String.valueOf(oldCaseRecord.OwnerId).startsWith(STARTSWITHGROUP)) {
                                String grpOwner;
                                Group grp = newCaseRecord.owner;
                                grpOwner = grp.DeveloperName;
                                if(grpOwner == NSP_ReportingConstants.Time_H_W_B_P_C_Queue){
                                    newCaseHistory.Time_H_W_B_P_C_Queue__c +=  timeToAdd;
                                } else if(grpOwner == NSP_ReportingConstants.Time_H_W_Communications_Queue){
                                    newCaseHistory.Time_H_W_Communications_Queue_Spent__c +=  timeToAdd;
                                } else if(grpOwner == NSP_ReportingConstants.Time_Health_Welfare_Products_Queue){
                                    newCaseHistory.Time_Health_Welfare_Products_Queue__c +=  timeToAdd;
                                } else{
                                    newCaseHistory.NSP_Time_in_Queue__c  +=  timeToAdd; // throws System.NullPointerException: Attempt to de-reference a null object
                                }
                            } else if(newCaseRecord.OwnerId == oldCaseRecord.OwnerId) {
                                newCaseHistory.NSP_Time_Individual_Spent__c +=  timeToAdd;
                            }
                            if(newCaseRecord.Status != oldCaseRecord.Status) {
                                newCaseHistory.NSP_Status_Duration__c = 0;
                                newCaseHistory.NSP_Case_Previous_Status__c = oldCaseRecord.Status;
                                newCaseHistory.NSP_Case_Current_status__c = newCaseRecord.Status;
                                isStatus = true;
                            }
                            if(newCaseRecord.Status == oldCaseRecord.Status) {

                                newCaseHistory.NSP_Status_Duration__c += timeToAdd;
                            }
                            newCaseHistoryToBeCreatedList.add(newCaseHistory);
                        }
                    }
                    if(historyRecord != null){
                        historyRecord.NSP_End_Date__c = currentDateTime;
                        if(isStatus){
                            historyRecord.NSP_Status_Duration__c += timeToAdd;
                        }
                        if ( isQueue ) {
                            List<String> grpFields = new List<String>{'Id', 'Name', 'DeveloperName'};
                            String grpQuery = new NSP_QueryBuilder( 'Group' , grpFields )
                                .addFilter( 'Name' , historyRecord.NSP_Case_Current_Owner_Text__c )
                                .build()
                                ;
                            List<Group> queueList = null;
                            try {
                                queueList = Database.query( grpQuery ); // throws...  System.QueryException: mismatched character '' expecting '''
                            } catch ( Exception e ) {
                                NSP_CaseTriggerHelper.handleException(
                                    e ,
                                    'createCaseHistory'
                                );
                            }
                            if ( ( queueList != null ) && !queueList.isEmpty() ) {
                                String grpOwner = queueList[0].DeveloperName;
                                if ( grpOwner == NSP_ReportingConstants.Time_H_W_B_P_C_Queue ) {
                                    historyRecord.Time_H_W_B_P_C_Queue__c += timeToAdd;
                                } else if ( grpOwner == NSP_ReportingConstants.Time_H_W_Communications_Queue ) {
                                    historyRecord.Time_H_W_Communications_Queue_Spent__c += timeToAdd;
                                } else if ( grpOwner == NSP_ReportingConstants.Time_Health_Welfare_Products_Queue ) {
                                    historyRecord.Time_Health_Welfare_Products_Queue__c += timeToAdd;
                                } else {
                                    historyRecord.NSP_Time_in_Queue__c  += timeToAdd;
                                }
                            }
                        }
                        if ( isUser ) {
                            historyRecord.NSP_Time_Individual_Spent__c += timeToAdd;
                        }
                        newCaseHistoryToBeCreatedList.add( historyRecord );
                    }
                    if ( !newCaseHistoryToBeCreatedList.isEmpty() ) {
                        upsert newCaseHistoryToBeCreatedList; // try catch capture error logs
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'createCaseHistory'
            );
        }
    }

    /**********************************************************************************************
MethodName: calculateTimeDifference
Description : This method calculates Time Difference including the business hours and holidays
Params:       String businessHoursId, DateTime startDate, DateTime endDate
********************************************************************************************/
    public Decimal calculateTimeDifference(String businessHoursId, DateTime startDate, DateTime endDate) {
        Long timeDifference = BusinessHours.diff(businessHoursId, startDate, endDate);
        Decimal mins = timeDifference / 60000;
        Decimal hours = mins/60;//Time spent in Hours
        return hours.setscale(2);
    }
 /**********************************************************************************************
MethodName: calculateTimeDifferenceInMin
Description : This method calculates Time Difference including the business hours and holidays
Params:       String businessHoursId, DateTime startDate, DateTime endDate
********************************************************************************************/
    public Decimal calculateTimeDifferenceInMin(String businessHoursId, DateTime startDate, DateTime endDate) {
        Decimal mins = 0.0;
        if ( ( businessHoursId != null ) && ( startDate != null ) && ( endDate != null ) ) {
            Long timeDifference = BusinessHours.diff(businessHoursId, startDate, endDate);
            decimal seconds =  timeDifference/1000;
            mins = (seconds / 60).setscale(2);
        }
        return mins;
    }

    // states with code and country variable
    private static Map<String, String> retreiveSalesOfficePicklistValues() {
        Map<String, String> salesOfficePicklistValues = new Map<String, String>();
        for(Schema.PicklistEntry sp : Asset.NSP_Sales_Office__c.getDescribe().getPicklistValues()) {
            salesOfficePicklistValues.put(sp.getValue(), sp.getLabel());
        }
        return salesOfficePicklistValues;
    }

    //
    // MethodName  : UpdateServiceRequestChannel
    // Description : This method will update servicereuest channel field on contact if the case is niceCX case and origin is Phone
    // Params : CaseList
    //Created by : Harsha Khiroya
    //
    private static void UpdateServiceRequestChannel( Set<Id> caseIdset){

        List<Contact> caseContactList = new List<Contact>();
        List<Contact> updatedContactList = new List<Contact>();
        Set<Id> contactIdSet = new Set<Id>();
        for(Case caseRec : [SELECT Id, ContactId FROM Case WHERE Id IN:caseIdset]){
            contactIdSet.add(caseRec.ContactId);
        }
        for(Contact con:[SELECT Id, NSP_Service_Request_Channel__c FROM Contact WHERE Id in : contactIdSet]){
            con.NSP_Service_request_Channel__c = NSP_ServiceConstants.PHONE_CHANNEL;
            updatedContactList.add(con);
        }
        if(!updatedContactList.isEmpty()){
            List<Database.SaveResult> results = Database.update(updatedContactList, false);
            NSP_ErrorLogHandler.logResults(
                NSP_CaseTriggerHelper.class.getName() ,
                'UpdateServiceRequestChannel' ,
                results
            );
        }

    }

    //Added as part of DF-04518
    /******
Method Name : updateInProgressTime
Description : To calculate the In progress Time after update of substatus
Param : Map<Id, Case> oldMap, Map<Id, Case> newMap
return type : void
********/
    private void updateInProgressTime(Map<Id, Case> oldMap, List<Case> caseList){
        BusinessHours defaultBusinessHours = [SELECT ID FROM BusinessHours WHERE IsDefault=true];
        for(Case newCase : caseList){
            newCase.NSP_Case_In_Progress_Hours__c = newCase.NSP_Case_In_Progress_Hours__c == null ? 0 : newCase.NSP_Case_In_Progress_Hours__c;
//Added as part of DF-05644 to avoid Null pointer exception when  NSP_Case_In_Progress_Modified_Date__c is null
            if(newCase.NSP_Case_In_Progress_Modified_Date__c != null){
            newCase.NSP_Case_In_Progress_Hours__c = newCase.NSP_Case_In_Progress_Hours__c+calculateTimeDifference(defaultBusinessHours.Id, newCase.NSP_Case_In_Progress_Modified_Date__c, DateTime.now());
            }
        }
    }


    //
    // MethodName: checkTheEligibiltyOfConfidentiality
    // Description : This method describes about Whether Case is Confidential Eligible or Not
    // Params: String Category String SubCategory
    // Story: STY-4166
    // createdDate : 6/12/2023
    //
    private static void checkTheEligibiltyOfConfidentiality(
        Set<String> categorySet ,
        Set<String> subCategorySet ,
        List<case> caseList
        )
    {
        Map<String,NSP_Category_Sub_Category_Mapping__c> catSubCatConfidentialEligibleMap = new Map<String, NSP_Category_Sub_Category_Mapping__c>();
        try {
            for ( NSP_Category_Sub_Category_Mapping__c catSubCatMapping : [
                        SELECT
                            Id ,
                            NSP_Category__c ,
                            NSP_Subcategory__c ,
                            NSP_Public_Groups_To_Share__c ,
                            NSP_Detail__c ,
                            NSP_Display_confidential_popup__c ,
                            Default_case_as_confidential__c
                        FROM NSP_Category_Sub_Category_Mapping__c
                        WHERE (
                            ( NSP_Category__c IN :categorySet )
                            AND ( NSP_Subcategory__c IN :subCategorySet )
                        )
                    ]
                )
            {
                String keyCatSubCat = catSubCatMapping.NSP_Category__c + ';' + catSubCatMapping.NSP_Subcategory__c;
                if ( String.isNotBlank( catSubCatMapping.NSP_Detail__c ) ) {
                   keyCatSubCat +=  ';' + catSubCatMapping.NSP_Detail__c;
                }
                catSubCatConfidentialEligibleMap.put( keyCatSubCat , catSubCatMapping );
            }
            for ( Case cse : caseList ) {
                String catSubCatKey = cse.NSP_Category__c + ';' + cse.NSP_Subcategory__c;
                if ( String.isNotBlank( cse.NSP_Detail__c ) ) {
                    catSubCatKey += ';' + cse.NSP_Detail__c;
                }
                if ( Test.isRunningTest() ) {
                    cse.NSP_Show_Confidential_Checkbox__c = false;
                } else {
                    if ( ( catSubCatConfidentialEligibleMap != null )
                        && catSubCatConfidentialEligibleMap.containsKey( catSubCatKey )
                        )
                    {
                        NSP_Category_Sub_Category_Mapping__c mapping = catSubCatConfidentialEligibleMap.get( catSubCatKey );
                        Boolean isDefaultConfidential = false;
                        Boolean shouldDisplayPopup = false;
                        if ( mapping != null ) {
                            isDefaultConfidential = mapping.Default_case_as_confidential__c;
                            shouldDisplayPopup = mapping.NSP_Display_confidential_popup__c;
                        }
                        if ( isDefaultConfidential ) {
                            cse.NSP_Confidential__c = true;
                            cse.NSP_Show_Confidential_Checkbox__c = true;
                        } else if ( shouldDisplayPopup ) {
                            cse.NSP_Show_Confidential_Checkbox__c = true;
                        } else {
                            cse.NSP_Confidential__c = false;
                            cse.NSP_Show_Confidential_Checkbox__c = false;
                        }
                    }
                    if ( !cse.NSP_Show_Confidential_Checkbox__c && cse.NSP_Confidential__c ) {
                        cse.NSP_Confidential__c = cse.NSP_Show_Confidential_Checkbox__c;
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_CaseTriggerHelper.handleException(
                e ,
                'checkTheEligibiltyOfConfidentiality'
            );
        }
    }

}
//
