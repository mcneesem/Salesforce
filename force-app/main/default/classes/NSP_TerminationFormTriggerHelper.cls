public with sharing class NSP_TerminationFormTriggerHelper {
    // test w/ NSP_TerminationFormTriggerHelperTest (83%)

    private static final string SUPERVISOR_DENIED = 'PR Supervisor Denied';
    private static final string TERM_TEAM_DENIED = 'Term Team Denied';
    private static final string TERM_TEAM_APPROVED = 'Term Team Approved';
    public static final String NSP_Credit_Specialist_Form = 'NSP_Credit_Specialist_Form';
    public static final String NSP_Client_Reinstatement = 'NSP_Client_Reinstatement';
    public static final String Termination_Form_Approved = 'Termination_Form_Approved';
    private static final Id payrollRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
            'NSP_Termination_Form__c' ,
            'NSP_Payroll_Specialist_Form'
        );
    private static final Id creditRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
            'NSP_Termination_Form__c' ,
            'NSP_Credit_Specialist_Form'
        );
    private static final Id reinstateRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
            'NSP_Termination_Form__c' ,
            'NSP_Client_Reinstatement'
        );

    // Description : This method will run before inserting Termination Form
    // Date        : 13/10/2021
    public void beforeTerminationFormInsert(List<NSP_Termination_Form__c> terminationFormList) {
        set<Id> setOfProjectTaskId = new set<Id>();
        set<Id> setOfClientOwnerId = new set<Id>();
        set<Id> setOfCreditSpecialistId = new set<Id>();
        updateAccountOnTerm(terminationFormList,null);
        List<NSP_Termination_Form__c> lTerminationForms = new List<NSP_Termination_Form__c>();
        List<NSP_Termination_Form__c> clientTerminationForms = new List<NSP_Termination_Form__c>();
        List<NSP_Termination_Form__c> creditTerminationForms = new List<NSP_Termination_Form__c>();
        for(NSP_Termination_Form__c terminationForm : terminationFormList){
            if(terminationForm.NSP_Project_Task__c != null){
                setOfProjectTaskId.add(terminationForm.NSP_Project_Task__c);
                lTerminationForms.add(terminationForm);
            }
            if(terminationForm.NSP_Client_Owner__c != null){
                setOfClientOwnerId.add(terminationForm.NSP_Client_Owner__c);
                clientTerminationForms.add(terminationForm);
            }
            if(terminationForm.Credit_Specialist__c !=null){
                setOfCreditSpecialistId.add(terminationForm.Credit_Specialist__c);
                creditTerminationForms.add(terminationForm);
            }
        }
        if(!setOfProjectTaskId.isEmpty()){
            updateUserLookups(setOfProjectTaskId, terminationFormList);
            populateSubClientandAssetValues(setOfProjectTaskId, lTerminationForms);
        }
        if(!setOfClientOwnerId.isEmpty()){
            populateClientOwnerEmailAndPhone(setOfClientOwnerId, clientTerminationForms);
        }
        if(!setOfCreditSpecialistId.isEmpty()){
            populateCreditspecialistphone(setOfCreditSpecialistId, creditTerminationForms);
        }
    }

    //
    // Populates the Sub Client Numbers from the Account and Number of Employees from WO Asset on Termination Form
    // @param sProjectTaskIds set of Project Task Ids
    // @param lTerminationForms List of New Termination Forms.
    // @return void
    //
    //
    public void populateSubClientandAssetValues( Set<Id> sProjectTaskIds , List<NSP_Termination_Form__c> lTerminationForms ) {
        Id woAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
            'Asset' ,
            'WO'
        );
        Map<Id,pse__Project_Task__c> mProjectTasks = new Map<Id,pse__Project_Task__c>(
            [
                SELECT Id , pse__Project__r.pse__Account__c
                FROM pse__Project_Task__c
                WHERE Id in :sProjectTaskIds
            ]
        );
        Set<Id> sAccountIds = new Set<Id>();
        try{
            for(pse__Project_Task__c oProjectTask : mProjectTasks.values()){
                if(oProjectTask.pse__Project__r?.pse__Account__c != null){
                    sAccountIds.add(oProjectTask.pse__Project__r.pse__Account__c);
                }
            }
            List<String> assetFields = new List<String>{'Id','AccountId','Status','NSP_Account_Status__c','NSP_Client_Segment_type__c'};
                //getting all the assets from record with filter from queryBuilder Class
                String query = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
                .addFilter('RecordTypeId', woAssetRecordTypeId)
                .addFilter('NSP_Account_Status__c', NSP_ServiceConstants.Terminated,NSP_QueryBuilder.Operator.NOT_EQUALS)
                .addFilter('AccountId', new List<Id>(sAccountIds), NSP_QueryBuilder.Operator.INCLUDES)
                .addLimit(1).build();
            List<Asset> assetsList = (List<Asset>)Database.query(query);
            // added for DF-03867
            String queryTerm = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
                .addFilter('RecordTypeId', woAssetRecordTypeId)
                .addFilter('NSP_Account_Status__c', NSP_ServiceConstants.TERMINATED)
                .addFilter('AccountId', new List<Id>(sAccountIds), NSP_QueryBuilder.Operator.INCLUDES)
                .orderBy('NSP_Termination_Date__c','Desc',False)
                .addLimit(1).build();
            List<Asset> terminatedAssetsList = (List<Asset>)Database.query(queryTerm);
            List<NSP_Sub_Client__c> lTerminatedSubClients = new List<NSP_Sub_Client__c>(
                [
                    SELECT
                        Id ,
                        NSP_Account__c ,
                        NSP_Sub_Client__c ,
                        Is_Primary_Contract__c ,
                        NSP_Renewal_Date__c ,
                        NSP_Original_Contract_Date__c ,
                        NSP_Account_Status_Date__c ,
                        NSP_Asset__r.NSP_Account_Status_Date__c
                    FROM NSP_Sub_Client__c
                    WHERE (
                        ( NSP_Account__c IN :sAccountIds )
                        AND ( NSP_Asset__c IN :terminatedAssetsList )
                    )
                    ORDER BY NSP_Account__c ASC , NSP_Sub_Client__c ASC
                ]
            );
            List<NSP_Sub_Client__c> lSubClients = new List<NSP_Sub_Client__c>(
                [
                    SELECT
                        Id ,
                        NSP_Account__c ,
                        NSP_Sub_Client__c ,
                        Is_Primary_Contract__c ,
                        NSP_Renewal_Date__c ,
                        NSP_Original_Contract_Date__c
                    FROM NSP_Sub_Client__c
                    WHERE (
                        ( NSP_Account__c IN :sAccountIds )
                        AND ( NSP_Asset__c IN :assetsList )
                        AND ( NSP_Account_Status__c != :NSP_ServiceConstants.TERMINATED )
                    )
                    ORDER BY NSP_Account__c ASC , NSP_Sub_Client__c ASC
                ]
            );
            Map<Id,String> mTermAccountToSubClientNumbers = new Map<Id,String>();
            for(NSP_Sub_Client__c oTempSClient : lTerminatedSubClients){
                if ( String.isNotBlank(oTempSClient.NSP_Sub_Client__c)
                    && ( oTempSClient.NSP_Account_Status_Date__c >= oTempSClient.NSP_Asset__r.NSP_Account_Status_Date__c )
                    )
                {
                    if(mTermAccountToSubClientNumbers.get(oTempSClient.NSP_Account__c) != null ){
                        String subClientNumbers = mTermAccountToSubClientNumbers.get(oTempSClient.NSP_Account__c) + ',' + oTempSClient.NSP_Sub_Client__c;
                        mTermAccountToSubClientNumbers.put(oTempSClient.NSP_Account__c,subClientNumbers);
                    }else{
                        mTermAccountToSubClientNumbers.put(oTempSClient.NSP_Account__c,oTempSClient.NSP_Sub_Client__c);
                    }
                }
            }
            Map<Id,String> mAccountToSubClientNumbers = new Map<Id,String>();
            Map<Id, String> mAccountToAssetAIMSClientNumber = new Map<Id, String> ();
            for(NSP_Sub_Client__c oTempSClient : lSubClients){
                if(String.isNotBlank(oTempSClient.NSP_Sub_Client__c)){
                    if(mAccountToSubClientNumbers.get(oTempSClient.NSP_Account__c) != null ){
                        String subClientNumbers = mAccountToSubClientNumbers.get(oTempSClient.NSP_Account__c) + ',' + oTempSClient.NSP_Sub_Client__c;
                        mAccountToSubClientNumbers.put(oTempSClient.NSP_Account__c,subClientNumbers);
                    }else{
                        mAccountToSubClientNumbers.put(oTempSClient.NSP_Account__c,oTempSClient.NSP_Sub_Client__c);
                    }
                }
            }
            List<Asset> lAssets = new List<Asset>(
                [
                    SELECT Id , AccountId , NSP_Client__c , NSP_Unique_Active_Employee__c
                    FROM Asset
                    WHERE (
                        RecordTypeId =: woAssetRecordTypeId
                        AND AccountId IN : sAccountIds
                    )
                ]
            );
            Map<Id,Decimal> mAccountToAssetEmployees = new Map<Id,Decimal>();
            for(Asset otempAsset : lAssets){
                Decimal uniqueActiveEmp = 0;
                if ( otempAsset.NSP_Unique_Active_Employee__c != null ) {
                    uniqueActiveEmp = otempAsset.NSP_Unique_Active_Employee__c;
                }
                mAccountToAssetEmployees.put(otempAsset.AccountId,uniqueActiveEmp);
                if(otempAsset.NSP_Client__c != null){
                    mAccountToAssetAIMSClientNumber.put(otempAsset.AccountId, otempAsset.NSP_Client__c);
                }
            }
            Map<Id,String> mClientSegmentAsset = new Map<Id,String>();
            for(Asset oClientAsset : assetsList){
                if(oClientAsset.NSP_Client_Segment_type__c != null){
                    mClientSegmentAsset.put(oClientAsset.AccountId, oClientAsset.NSP_Client_Segment_type__c);
                }
            }
            Map<ID,NSP_Sub_Client__c> nonTermSubClientsMap = new Map<ID,NSP_Sub_Client__c>();
            for(NSP_Sub_Client__c oClientRenewel : lSubClients){
                if ( String.isNotBlank( oClientRenewel.NSP_Sub_Client__c )
                    && oClientRenewel.Is_Primary_Contract__c
                    )
                {
                    nonTermSubClientsMap.put(oClientRenewel.NSP_Account__c, oClientRenewel);
                }
            }
            Map<Id,String> termClientSegmentAsset = new Map<Id,String>();
            for(Asset pClientAsset : terminatedAssetsList){
                if(pClientAsset.NSP_Client_Segment_type__c != null){
                    termClientSegmentAsset.put(pClientAsset.AccountId, pClientAsset.NSP_Client_Segment_type__c);
                }
            }
            Map<ID,NSP_Sub_Client__c> termSubClientsMap = new Map<ID,NSP_Sub_Client__c>();
            for(NSP_Sub_Client__c oClientRenewel : lTerminatedSubClients){
                if ( String.isNotBlank( oClientRenewel.NSP_Sub_Client__c )
                    && oClientRenewel.Is_Primary_Contract__c
                    )
                {
                    termSubClientsMap.put(oClientRenewel.NSP_Account__c, oClientRenewel);
                }
            }
            List<NSP_Termination_Form__c> nonTerminatedFormList = new List<NSP_Termination_Form__c>();
            List<NSP_Termination_Form__c> terminatedFormList = new List<NSP_Termination_Form__c>();
            for(NSP_Termination_Form__c oTerminationForm : lTerminationForms){
                if(oTerminationForm.NSP_Project_Task__c != null){
                    pse__Project_Task__c oProjectTask  = mProjectTasks.get(oTerminationForm.NSP_Project_Task__c);
                    Id accountId = oProjectTask?.pse__Project__r?.pse__Account__c;
                    if(accountId != null){
                        //check if Account has Active WO Asset
                        if(mAccountToSubClientNumbers.containsKey(accountId)){
                            nonterminatedFormList.add(oTerminationForm);
                        } else{
                            terminatedFormList.add(oTerminationForm);
                        }
                        if(mAccountToAssetAIMSClientNumber.containsKey(accountId)){
                            oTerminationForm.NSP_Client_Number__c = mAccountToAssetAIMSClientNumber.get(accountId);
                        }
                        if(mAccountToAssetEmployees.containsKey(accountId)){
                            oTerminationForm.NSP_Number_of_Active_Employees__c = mAccountToAssetEmployees.get(accountId);
                        }
                    }
                }
            }
            if(!nonTerminatedFormList.isEmpty()){
                updateTermFormFields(
                    nonTerminatedFormList ,
                    mProjectTasks ,
                    mAccountToSubClientNumbers ,
                    mClientSegmentAsset ,
                    nonTermSubClientsMap
                );
            }
            if(!terminatedFormList.isEmpty()){
                updateTermFormFields(
                    terminatedFormList ,
                    mProjectTasks ,
                    mTermAccountToSubClientNumbers ,
                    termClientSegmentAsset ,
                    termSubClientsMap
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_TerminationFormTriggerHelper.class.getName() ,
                'populateSubClientandAssetValues' ,
                e
            );
        }
    }

    private void updateTermFormFields(
        List<NSP_Termination_Form__c> termformList ,
        Map<Id,pse__Project_Task__c> projectTasks ,
        Map<Id,String> accountToSubClientNumbers ,
        Map<Id,String> clientSegmentAsset ,
        Map<ID,NSP_Sub_Client__c> accountSubClientsMap
        )
    {
        try{
            if ( ( termformList != null ) && !termformList.isEmpty() ) {
                for(NSP_Termination_Form__c oTerminationForm : termformList){
                    pse__Project_Task__c oProjectTask  = ProjectTasks.get(oTerminationForm.NSP_Project_Task__c);
                    Id accountId = oProjectTask?.pse__Project__r?.pse__Account__c;
                    if(accountId != null){
                        if ( accountToSubClientNumbers != null ) {
                            oTerminationForm.NSP_Client_Sub_Account_Numbers__c = SchemaController.safeText(
                                accountToSubClientNumbers.get( accountId ) ,
                                sObjectType.NSP_Termination_Form__c.Fields.NSP_Client_Sub_Account_Numbers__c
                            );
                        }
                        if (clientSegmentAsset != null && clientSegmentAsset.containsKey(accountId)){
                            oTerminationForm.NSP_Segment_Type__c = SchemaController.safeText(
                                clientSegmentAsset.get( accountId ) ,
                                sObjectType.NSP_Termination_Form__c.Fields.NSP_Segment_Type__c
                            );
                        }
                        if (accountSubClientsMap != null && accountSubClientsMap.containsKey(accountId)){
                            NSP_Sub_Client__c accountSubClient = accountSubClientsMap.get(accountId);
                            if ( accountSubClient != null ) {
                                oTerminationForm.NSP_Renewal_Date__c = accountSubClient.NSP_Renewal_Date__c;
                                oTerminationForm.NSP_CSA_Effective_Date__c = accountSubClient.NSP_Original_Contract_Date__c;
                            }
                        }
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_TerminationFormTriggerHelper.class.getName() ,
                'updateTermFormFields' ,
                e
            );
        }
    }

    //
    // Iterates throught the list of new Asset and passes the required attributes to other methods.
    // @param newList List of New Termination Forms.
    // @param newList Map of New Termination Forms.
    // @return void
    //
    public void afterInsertFilter(List<NSP_Termination_Form__c> lTerminationForms , Map<Id,NSP_Termination_Form__c> mTerminationForms){
        if (lTerminationForms != null && !lTerminationForms.isEmpty() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
            System.enqueueJob(
                new QueueableTermFormJunctionObjects(
                    lTerminationForms,
                    null,
                    NSP_ServiceConstants.INSERT_TRIGGER
                )
            );
        }
        Map<Id,Set<Id>> mTFToUsers = new Map<Id,Set<Id>>();
        for(NSP_Termination_Form__c oTerminationForm : lTerminationForms){
            mTFToUsers.put(oTerminationForm.Id,new Set<Id>());
            checkLookupChange(mTFToUsers,oTerminationForm.Id,oTerminationForm.OwnerId,oTerminationForm.NSP_Payroll_Specialist__c);
            checkLookupChange(mTFToUsers,oTerminationForm.Id,oTerminationForm.OwnerId,oTerminationForm.NSP_Supervisor__c);
            checkLookupChange(mTFToUsers,oTerminationForm.Id,oTerminationForm.OwnerId,oTerminationForm.NSP_Approver__c);
            if(mTFToUsers.get(oTerminationForm.Id).size() == 0){
                mTFToUsers.remove(oTerminationForm.Id);
            }
        }
        if(mTFToUsers.keySet().size() > 0){
            shareTerminationFormsWithUsers(mTFToUsers,'Edit');
        }
    }

    private void shareTerminationFormsWithUsers( Map<Id,Set<Id>> mRecordToUsers , String accessLevel ) {
        try {
            List<NSP_Termination_Form__Share> lTerminationFormShares = new List<NSP_Termination_Form__Share>();
            if ( mRecordToUsers != null ) {
                for ( Id iTForm : mRecordToUsers.keySet() ) {
                    if ( mRecordToUsers.containsKey( iTForm ) ) {
                        Set<Id> userSet = mRecordToUsers.get( iTForm );
                        if ( userSet != null ) {
                            for ( Id iUser : userSet ) {
                                lTerminationFormShares.add(
                                    new NSP_Termination_Form__Share(
                                        ParentId=iTForm ,
                                        UserOrGroupId=iUser ,
                                        AccessLevel = accessLevel
                                    )
                                );
                            }
                        }
                    }
                }
            }
            if ( !lTerminationFormShares.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( lTerminationFormShares , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_TerminationFormTriggerHelper.class.getName() ,
                    'shareTerminationFormsWithUsers:insert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_TerminationFormTriggerHelper.class.getName() ,
                'shareTerminationFormsWithUsers' ,
                e
            );
        }
    }

    public void beforeTerminationFormUpdate( Map<Id,NSP_Termination_Form__c> newMap , Map<Id,NSP_Termination_Form__c> oldMap ) {
        set<Id> setOfClientOwnerId = new set<Id>();
        set<Id> setOfCreditSpecialistId = new set<Id>();
        List<NSP_Termination_Form__c> clientTerminationForms = new List<NSP_Termination_Form__c>();
        List<NSP_Termination_Form__c> creditTerminationForms = new List<NSP_Termination_Form__c>();
        if(newMap != null){
            for(NSP_Termination_Form__c terminationForm : newMap.values()){
                if ( terminationForm.NSP_Client_Owner__c != null
                    && terminationForm.NSP_Client_Owner__c != oldMap.get(terminationForm.id).NSP_Client_Owner__c
                    )
                {
                    setOfClientOwnerId.add(terminationForm.NSP_Client_Owner__c);
                    clientTerminationForms.add(terminationForm);
                }
                if(String.isBlank(terminationForm.NSP_Client_Owner__c) && terminationForm.NSP_Client_Owner__c != oldMap.get(terminationForm.id).NSP_Client_Owner__c){
                    terminationForm.Client_Owner_Phone__c = '';
                    terminationForm.Client_Owner_Email__c = '';
                }
                if(terminationForm.Credit_Specialist__c != null && terminationForm.Credit_Specialist__c!= oldMap.get(terminationForm.id).Credit_Specialist__c){
                    setOfCreditSpecialistId.add(terminationForm.Credit_Specialist__c);
                    creditTerminationForms.add(terminationForm);
                }
                if(String.isBlank(terminationForm.NSP_Client_Owner__c) && terminationForm.NSP_Client_Owner__c != oldMap.get(terminationForm.id).NSP_Client_Owner__c){
                    terminationForm.Client_Owner_Phone__c = '';
                    terminationForm.Client_Owner_Email__c = '';
                }
            }
        }
        if(!setOfClientOwnerId.isEmpty()){
            populateClientOwnerEmailAndPhone(setOfClientOwnerId, clientTerminationForms);
        }
        if(!setOfCreditSpecialistId.isEmpty()){
            populateCreditspecialistphone(setOfCreditSpecialistId, creditTerminationForms);
        }
    }

    public void afterUpdateTerminationForm( List<NSP_Termination_Form__c> terminationFormList , Map<Id,NSP_Termination_Form__c> oldMap ) {
        Map<Id,Set<Id>> mTFToUsers = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mTFSharingToDelete = new Map<Id,Set<Id>>();
        List<NSP_Termination_Form__c> queueNewTerm = new List<NSP_Termination_Form__c>();
        Map<Id, NSP_Termination_Form__c> queueOldMap = new Map<Id, NSP_Termination_Form__c>();
        Set<Id> processedTerm = new Set<Id>();
        Set<Id> termFormSet = new Set<Id>();
        Set<ID> terminationFormBellNotificationSet = new Set<ID>();
        Set<Id> setOfProjectTaskId = new Set<Id>();
        for ( NSP_Termination_Form__c terminationForm : terminationFormList ) {
            if ( terminationForm.NSP_Project_Task__c != null
                && terminationForm.NSP_Status__c == NSP_ServiceConstants.TERMINATION_FORM_PR_APPROVED_STATUS
                && terminationForm.NSP_Status__c != oldMap.get( terminationForm.Id ).NSP_Status__c
                )
            {
                setOfProjectTaskId.add( terminationForm.NSP_Project_Task__c );
            }

            //RECORD SHARING LOGIC
            mTFToUsers.put(terminationForm.Id,new Set<Id>());
            mTFSharingToDelete.put(terminationForm.Id,new Set<Id>());
            NSP_Termination_Form__c oOldTermination = oldMap.get(terminationForm.Id);
            if ( ( oOldTermination != null )
                && ( terminationForm.NSP_Project_Task__c != null )
                && ( terminationForm.NSP_Project_Task__c != oOldTermination.NSP_Project_Task__c )
                && !processedTerm.contains(terminationForm.Id)
                )
            {
                queueOldMap.put(terminationForm.Id,oOldTermination);
                queueNewTerm.add(terminationForm);
                processedTerm.add(terminationForm.Id);
            }
            if(terminationForm.OwnerId != oOldTermination.OwnerId){
                checkLookupChange(mTFToUsers,terminationForm.Id,terminationForm.OwnerId,terminationForm.NSP_Payroll_Specialist__c);
                checkLookupChange(mTFToUsers,terminationForm.Id,terminationForm.OwnerId,terminationForm.NSP_Supervisor__c);
                checkLookupChange(mTFToUsers,terminationForm.Id,terminationForm.OwnerId,terminationForm.NSP_Approver__c);
            }else{
                if(terminationForm.NSP_Payroll_Specialist__c != oOldTermination.NSP_Payroll_Specialist__c){
                    checkLookupChange(mTFToUsers,terminationForm.Id,terminationForm.OwnerId,terminationForm.NSP_Payroll_Specialist__c);
                    checkLookupChange(mTFSharingToDelete,terminationForm.Id,terminationForm.OwnerId,oOldTermination.NSP_Payroll_Specialist__c);
                }
                if(terminationForm.NSP_Supervisor__c != oldMap.get(terminationForm.Id).NSP_Supervisor__c){
                    checkLookupChange(mTFToUsers,terminationForm.Id,terminationForm.OwnerId,terminationForm.NSP_Supervisor__c);
                    checkLookupChange(mTFSharingToDelete,terminationForm.Id,terminationForm.OwnerId,oOldTermination.NSP_Supervisor__c);
                }
                if(terminationForm.NSP_Approver__c != oldMap.get(terminationForm.Id).NSP_Approver__c){
                    checkLookupChange(mTFToUsers,terminationForm.Id,terminationForm.OwnerId,terminationForm.NSP_Approver__c);
                    checkLookupChange(mTFSharingToDelete,terminationForm.Id,terminationForm.OwnerId,oOldTermination.NSP_Approver__c);
                }
            }

            if(mTFSharingToDelete.get(terminationForm.Id).size() == 0){
                mTFSharingToDelete.remove(terminationForm.Id);
            }
            if(mTFToUsers.get(terminationForm.Id).size() == 0){
                mTFToUsers.remove(terminationForm.Id);
            }

            if ( ( terminationForm.NSP_Status__c != null )
                && ( terminationForm.NSP_Status__c != oldMap.get(terminationForm.Id).NSP_Status__c )
                && (
                    ( terminationForm.RecordTypeId == payrollRecordTypeId && terminationForm.NSP_Status__c == SUPERVISOR_DENIED )
                    || ( terminationForm.RecordTypeId == creditRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_DENIED )
                    || ( terminationForm.RecordTypeId == payrollRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_DENIED )
                    || ( terminationForm.RecordTypeId == creditRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_APPROVED )
                    || ( terminationForm.RecordTypeId == payrollRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_APPROVED )
                    || ( terminationForm.RecordTypeId == reinstateRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_DENIED )
                    || ( terminationForm.RecordTypeId == reinstateRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_APPROVED )
                    )
                )
            {
                terminationFormBellNotificationSet.add( terminationForm.Id );
            }
            if ( terminationForm.NSP_Status__c != null
                && terminationForm.NSP_Status__c != oldMap.get(terminationForm.Id).NSP_Status__c
                && terminationForm.RecordTypeId == payrollRecordTypeId
                && terminationForm.NSP_Status__c == TERM_TEAM_APPROVED
                )
            {
                termFormSet.add(terminationForm.Id);
            }
        }
        if (!queueNewTerm.isEmpty() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            System.enqueueJob(
                new QueueableTermFormJunctionObjects(
                    queueNewTerm,
                    queueOldMap,
                    NSP_ServiceConstants.UPDATE_TRIGGER
                )
            );
        }

        if(mTFSharingToDelete.keySet().size() > 0){
            deleteTerminationFormSharing(mTFSharingToDelete);
        }

        if(mTFToUsers.keySet().size() > 0){
            shareTerminationFormsWithUsers(mTFToUsers,'Edit');
        }

        if ( !setOfProjectTaskId.isEmpty() ) {
            NSP_TerminationFormTriggerHelper.updateProjectTaskStatus( setOfProjectTaskId );
        }

        if( NotificationDeliverabilityController.IsEnabledOutbound
          && terminationFormBellNotificationSet.size() > 0 ) {
            sendBellNotificationToSpecialist(terminationFormBellNotificationSet);
        }
        if( EmailDeliverabilityController.IsEnabledOutbound
          && termFormSet.size() > 0 ) {
            sendEmailNotificationToSupervisor(termFormSet);
        }
    }

    // Method to Send Bell Notifications when termination form is rejected/approved
    @future
    public static void sendBellNotificationToSpecialist( Set<Id> terminationFormSet ) {
        List<NSP_Termination_Form__c> terminationFormBellNotificationList = null;
        if(terminationFormSet != null && !terminationFormSet.isEmpty()) {
            terminationFormBellNotificationList = [
                SELECT
                    Id , Name , RecordTypeId , NSP_Status__c ,
                    CreatedById , CreatedBy.IsActive ,
                    OwnerId , Owner.IsActive ,
                    Credit_Specialist__c , Credit_Specialist__r.pse__Salesforce_User__c , Credit_Specialist__r.pse__Salesforce_User__r.IsActive ,
                    NSP_Supervisor__c , NSP_Supervisor__r.IsActive ,
                    NSP_Payroll_Specialist__c , NSP_Payroll_Specialist__r.IsActive , NSP_Approver__c, NSP_Approver__r.IsActive
                FROM NSP_Termination_Form__c
                WHERE ( Id IN :terminationFormSet )
            ];
        }
        Map<NSP_Termination_Form__c,Set<String>> termFormToSpecialistIdsMap = new Map<NSP_Termination_Form__c,Set<String>>();
        for ( NSP_Termination_Form__c term : terminationFormBellNotificationList ) {
            termFormToSpecialistIdsMap = getTermFormToSpecialistIdsMap(term);
        }
        if ( !termFormToSpecialistIdsMap.isEmpty() ) {
            sendCustomBellNotification(termFormToSpecialistIdsMap);
        }
    }

    private static void sendCustomBellNotification (Map<NSP_Termination_Form__c,Set<String>> termFormToSpecialistIdsMap){
        if ( NotificationDeliverabilityController.IsEnabledOutbound
          && !termFormToSpecialistIdsMap.keySet().isEmpty() ) {
            List<CustomNotificationType> bellNotificationTermForms = [
                SELECT Id , DeveloperName
                FROM CustomNotificationType
                WHERE DeveloperName='NSP_Bell_Notification_Termination_Form'
                LIMIT 1
            ];
            CustomNotificationType bellNotificationTermForm = null;
            if ( ( bellNotificationTermForms != null ) && !bellNotificationTermForms.isEmpty() ) {
                bellNotificationTermForm = bellNotificationTermForms[0];
            }
            if ( bellNotificationTermForm != null ) {
                for ( NSP_Termination_Form__c termForm : termFormToSpecialistIdsMap.keySet() ) {
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setNotificationTypeId( bellNotificationTermForm.id );
                    if ( ( termForm.NSP_Status__c == TERM_TEAM_DENIED ) || ( termForm.NSP_Status__c == SUPERVISOR_DENIED ) ) {
                        notification.setTitle( 'Approval Request for Termination Form is Rejected' );
                    } else if ( termForm.NSP_Status__c == TERM_TEAM_APPROVED ) {
                        notification.setTitle( 'Approval Request for Termination Form is Approved' );
                    }
                    notification.setBody( termForm.Name );
                    notification.setTargetId( termForm.Id);
                    // prevent System.HandledException ~ all recipients must be active Users to send bell notifications...
                    notification.send( termFormToSpecialistIdsMap.get( termForm ) );
                }
            }
        }
    }
    private static Map<NSP_Termination_Form__c, Set<String>> getTermFormToSpecialistIdsMap(NSP_Termination_Form__c term) {
        Map<NSP_Termination_Form__c, Set<String>> termFormToSpecialistIdsMap = new Map<NSP_Termination_Form__c, Set<String>>();
        Set<String> specialistIds = new Set<String>();

        if (term == null) {
            return termFormToSpecialistIdsMap;
        }

        Boolean isPayroll = term.RecordTypeId == payrollRecordTypeId;
        Boolean isCredit = term.RecordTypeId == creditRecordTypeId;
        Boolean isReinstate = term.RecordTypeId == reinstateRecordTypeId;
        Boolean isTermDenied = term.NSP_Status__c == TERM_TEAM_DENIED;
        Boolean isTermApproved = term.NSP_Status__c == TERM_TEAM_APPROVED;
        Boolean isSupervisorDenied = term.NSP_Status__c == SUPERVISOR_DENIED;

        if (isPayroll) {
            handlePayrollCases(specialistIds, term, isTermApproved, isTermDenied, isSupervisorDenied);
        } else if (isCredit) {
            handleCreditCases(specialistIds, term, isTermApproved, isTermDenied);
        } else if (isReinstate) {
            handleReinstateCases(specialistIds, term, isTermApproved, isTermDenied);
        }

        if (!specialistIds.isEmpty()) {
            termFormToSpecialistIdsMap.put(term, specialistIds);
        }
        return termFormToSpecialistIdsMap;
    }

    private static void handlePayrollCases(Set<String> specialistIds, NSP_Termination_Form__c term, Boolean isTermApproved, Boolean isTermDenied, Boolean isSupervisorDenied) {
        if (isSupervisorDenied) {
            addIfActive(specialistIds, term.NSP_Payroll_Specialist__r, term.NSP_Payroll_Specialist__c);
        } else if (isTermDenied) {
            addIfActive(specialistIds, term.NSP_Payroll_Specialist__r, term.NSP_Payroll_Specialist__c);
            addIfOwnerActive(specialistIds, term.OwnerId);
        } else if (isTermApproved) {
            addIfActive(specialistIds, term.NSP_Supervisor__r, term.NSP_Supervisor__c);
            addIfOwnerActive(specialistIds, term.OwnerId);
            addIfActive(specialistIds, term.NSP_Payroll_Specialist__r, term.NSP_Payroll_Specialist__c);
            addIfACtive(specialistIds, term.NSP_Approver__r, term.NSP_Approver__c);
        }
    }

    private static void handleCreditCases(Set<String> specialistIds, NSP_Termination_Form__c term, Boolean isTermApproved, Boolean isTermDenied) {
        if (isTermDenied) {
            addIfActive(specialistIds, term.Credit_Specialist__r != null ? term.Credit_Specialist__r.pse__Salesforce_User__r : null, term.Credit_Specialist__r != null ? term.Credit_Specialist__r.pse__Salesforce_User__c : null);
        } else if (isTermApproved) {
            addIfOwnerActive(specialistIds, term.OwnerId);
            addIfActive(specialistIds, term.CreatedBy, term.CreatedById);
        }
    }

    private static void handleReinstateCases(Set<String> specialistIds, NSP_Termination_Form__c term, Boolean isTermApproved, Boolean isTermDenied) {
        if (isTermDenied) {
            addIfOwnerActive(specialistIds, term.OwnerId);
        } else if (isTermApproved) {
            addIfOwnerActive(specialistIds, term.OwnerId);
            addIfActive(specialistIds, term.NSP_Supervisor__r, term.NSP_Supervisor__c);
            addIfActive(specialistIds, term.NSP_Payroll_Specialist__r, term.NSP_Payroll_Specialist__c);
            addIfACtive(specialistIds, term.NSP_Approver__r, term.NSP_Approver__c);
        }
    }

    private static void addIfActive(Set<String> specialistIds, User user, String userId) {
        if (user != null && userId != null && user.IsActive) {
            specialistIds.add(userId);
        }
    }

    private static void addIfOwnerActive(Set<String> specialistIds, String ownerId) {
        if (ownerId != null) {
            specialistIds.add(ownerId);
        }
    }

    // Method to Send Email Notification to Supervisor when termination form is rejected
    @future
    public static void sendEmailNotificationToSupervisor( Set<Id> termFormSet ) {
        Id payrollRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
            'NSP_Termination_Form__c' ,
            'NSP_Payroll_Specialist_Form'
        );
        Map<Id,Id> termFormToSupervisorId = new Map<Id,Id>();
        List<NSP_Termination_Form__c> iTermFrom = [
            SELECT Id , NSP_Status__c , RecordTypeId , NSP_Supervisor__c , NSP_Supervisor__r.IsActive , NSP_Supervisor__r.Email
            FROM NSP_Termination_Form__c
            WHERE ( Id IN :termFormSet )
        ];
        for ( NSP_Termination_Form__c termForm : iTermFrom ) {
            if ( ( termForm.NSP_Supervisor__c != null )
                && termForm.NSP_Supervisor__r.IsActive
                && String.isNotBlank( termForm.NSP_Supervisor__r.Email )
                && ( termForm.NSP_Status__c == TERM_TEAM_APPROVED )
                && ( termForm.RecordTypeId == payrollRecordTypeId )
                )
            {
                termFormToSupervisorId.put(
                    termForm.Id ,
                    termForm.NSP_Supervisor__c
                );
            }
        }
        if ( !termFormToSupervisorId.isEmpty() ) {
            NSP_EmailService.sendEmail(
                termFormToSupervisorId ,
                NSP_TerminationFormTriggerHelper.Termination_Form_Approved
            );
        }
    }

    public void checkLookupChange( Map<Id,Set<Id>> mTFToUsers , Id recordId , Id ownerId , Id iUser ) {
        if ( ( mTFToUsers != null )
            && ( iUser != null )
            && ( iUser != ownerId )
            )
        {
            mTFToUsers.get( recordId ).add( iUser );
        }
    }

    private void deleteTerminationFormSharing( Map<Id,Set<Id>> mDeleteSharingIds ) {
        try {
            if ( ( mDeleteSharingIds != null ) && !mDeleteSharingIds.isEmpty() ) {
                String query = 'SELECT Id FROM NSP_Termination_Form__Share WHERE';
                for ( Id iTForm : mDeleteSharingIds.keySet() ) {
                    query += ' ( ParentId = \'' + iTForm + '\' AND UserOrGroupId in (\'';
                    for ( Id userId : mDeleteSharingIds.get( iTForm ) ) {
                        query +=  userId + '\',\'';
                    }
                    query = query.removeEnd( ',\'' );
                    query += ')) OR';
                }
                query = query.removeEnd( ' OR' );
                List<NSP_Termination_Form__Share> lDeleteSharing = (List<NSP_Termination_Form__Share>)Database.query( query );
                if ( !lDeleteSharing.isEmpty() ) {
                    List<Database.DeleteResult> results = Database.delete( lDeleteSharing , false );
                    NSP_ErrorLogHandler.logResults(
                        NSP_TerminationFormTriggerHelper.class.getName() ,
                        'deleteTerminationFormSharing:delete' ,
                        results
                    );
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_TerminationFormTriggerHelper.class.getName() ,
                'deleteTerminationFormSharing' ,
                e
            );
        }
    }

    private static void updateProjectTaskStatus( Set<Id> setOfProjectTaskId ) {
        try {
            List<pse__Project_Task__c> listOfProjectTask = new List<pse__Project_Task__c>();
            for ( pse__Project_Task__c projectTask : [
                        SELECT pse__Project__c
                        FROM pse__Project_Task__c
                        WHERE ( Id IN :setOfProjectTaskId )
                    ]
                )
            {
                listOfProjectTask.add(
                    new pse__Project_Task__c(
                        Id=projectTask.Id ,
                        pse__Status__c=NSP_ServiceConstants.TASKCOMPLETE
                    )
                );
            }
            if ( !listOfProjectTask.isEmpty() ) {
                List<Database.SaveResult> results = Database.update( listOfProjectTask , false ); // throws DmlException ~ FIELD_CUSTOM_VALIDATION_EXCEPTION, Please approve all Termination Forms before marking this Project Task as complete
                NSP_ErrorLogHandler.logResults(
                    NSP_TerminationFormTriggerHelper.class.getName() ,
                    'updateProjectTaskStatus:update' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_TerminationFormTriggerHelper.class.getName() ,
                'updateProjectTaskStatus' ,
                e
            );
        }
    }
  //variable maps used by 'updateUserLookups' method
    private static Map<Id,Id> mapOfProjectTaskAndProject = new Map<Id,Id>();
    private static Map<Id,Id> mapOfProjectAndAccount = new Map<Id,Id>();
    private static Map<String,Id> primaryRolesMap = new Map<String,Id>();
    private static Map<String,Id> nonPrimaryRolesMap = new Map<String,Id>();
    private static final string renewalCoordinator = 'Renewal Coordinator';
    /* Description : This method will fetch value of User Lookups from Account Team
        Date       : 13/10/2021 */

    public static void updateUserLookups(set<Id> setOfProjectTaskId, List<NSP_Termination_Form__c> terminationFormList){
        Map<String,Id> mapOfAccountAndAccountTeam = new Map<String,Id>();
        String termObj = 'NSP_Termination_Form__c';

        //populate project-account and project_task-project maps
        mapProjectTasksToAccounts(setOfProjectTaskId);

        //proceed if map is populated
        if(mapOfProjectAndAccount != null){

            //process the account teams using mapped accounts
            processAccountTeams(new Set<Id>(mapOfProjectAndAccount.values()));

            Id payrollRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
                termObj ,
                NSP_ServiceConstants.NSP_Payroll_Specialist_Form
            );
            Id creditRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
                termObj ,
                NSP_Credit_Specialist_Form
            );
            Id reinstateRecordTypeId = NSP_GenericRecordType.getRecordTypeId(
                termObj ,
                NSP_Client_Reinstatement
            );

            if ( ( terminationFormList != null ) && !terminationFormList.isEmpty() ) {
                for ( NSP_Termination_Form__c termForm : terminationFormList ) {
                    if ( ( termForm.RecordTypeId == payrollRecordTypeId )
                        || ( termForm.RecordTypeId == creditRecordTypeId )
                        || ( termForm.RecordTypeId == reinstateRecordTypeId )
                       )
                    {
                        //Termination Form Payroll Specialist Record Type
                        mapOfAccountAndAccountTeam = primaryRolesMap;
                    } else {
                        mapOfAccountAndAccountTeam = nonPrimaryRolesMap;
                    }
                }
                //process the Temination form records before insert
                processTermForms(terminationFormList, mapOfAccountAndAccountTeam);
            }
        }
    }

    //method used for populating the project-account and project_task-project maps (called by method - updateUserLookups)
    public static void mapProjectTasksToAccounts( Set<Id> setOfProjectTaskId)
    {
        if(!setOfProjectTaskId.isEmpty()){
            for(pse__Project_Task__c projectTask : [SELECT pse__Project__c FROM pse__Project_Task__c WHERE ID IN : setOfProjectTaskId]){
                if(!mapOfProjectTaskAndProject.containsKey(projectTask.id)){
                    mapOfProjectTaskAndProject.put(projectTask.id, projectTask.pse__Project__c);
                }
            }
        }
        if(mapOfProjectTaskAndProject != null){
            for(pse__Proj__c project : [SELECT pse__Account__c FROM pse__Proj__c WHERE ID IN : mapOfProjectTaskAndProject.values()]){
                if(!mapOfProjectAndAccount.containsKey(project.id)){
                    mapOfProjectAndAccount.put(project.id, project.pse__Account__c);
                }
            }
        }
    }
    //method for processing Account teams using mapped accounts (called by method - updateUserLookups)
    public static void processAccountTeams(Set<Id> mapOfProjectAndAccount){
      List<String> roleList = new List<String>{
            NSP_ServiceConstants.PayrollSpecialist,
                NSP_ServiceConstants.BUS_TEAM_HRSP_CL,
                NSP_ServiceConstants.CLIENT_LIAISION,
                NSP_ServiceConstants.MID_MARKET_ACC_EX,
                NSP_ServiceConstants.PAYROLL_SUPERVISOR,
                NSP_ServiceConstants.MANAGER_HRSERVICES,
                NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR,
                NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT,
                renewalCoordinator
                };
        if(mapOfProjectAndAccount != null){
            for ( NSP_Account_Team__c accountTeamPayroll : [
                    SELECT NSP_Role__c , NSP_User__c , NSP_Primary__c , NSP_Last_Name__c, NSP_Account__c
                    FROM NSP_Account_Team__c
                    WHERE (
                        ( NSP_Account__c IN : mapOfProjectAndAccount)
                        AND ( NSP_User__c != null )
                        AND (NSP_Role__c =: roleList)
                    )
                    ORDER BY NSP_Role__c ASC , NSP_Primary__c ASC , NSP_Last_Name__c ASC
                    ]
                )
            {
                //populate each account team into map
               populateRoleMaps(accountTeamPayroll);
            }
        }
    }

    //method for populating Role Maps using Account Team (called by method - processAccountTeams)
    public static void populateRoleMaps(NSP_Account_Team__c accountTeamPayroll){
        if( accountTeamPayroll != null ){
            if ( !primaryRolesMap.containsKey( accountTeamPayroll.NSP_Account__c ) ) {
                primaryRolesMap.put(
                    accountTeamPayroll.NSP_Account__c + '-' + accountTeamPayroll.NSP_Role__c ,
                    accountTeamPayroll.NSP_User__c
                );
            }
            if (
                (!accountTeamPayroll.NSP_Primary__c )
                &&( !nonPrimaryRolesMap.containsKey( accountTeamPayroll.NSP_Account__c ) )
               )
            {
                nonPrimaryRolesMap.put(
                    accountTeamPayroll.NSP_Account__c + '-' + accountTeamPayroll.NSP_Role__c ,
                    accountTeamPayroll.NSP_User__c
                );
            }
        }
    }

    //method for processing the Term forms before insert (called by method - updateUserLookups)
    public static void processTermForms(List<NSP_Termination_Form__c> terminationFormList, Map<String,Id> mapOfAccountAndAccountTeam){
        for ( NSP_Termination_Form__c termForm : terminationFormList ) {
            if ( ( mapOfAccountAndAccountTeam != null )
                && ( mapOfProjectAndAccount != null )
                && ( mapOfProjectTaskAndProject != null )
               )
            {
                Id mappedProjectId = null;
                if( mapOfProjectTaskAndProject.containsKey(termForm.NSP_Project_Task__c) ){
                    mappedProjectId = mapOfProjectTaskAndProject.get( termForm.NSP_Project_Task__c );
                }

                if( mappedProjectId != null ){
                    Id mappedAccountId = mapOfProjectAndAccount.get( mappedProjectId );

                    if(mappedAccountId != null){
                        //populate fields on term form
                        populateTermFormFields(termForm, mapOfAccountAndAccountTeam, mappedAccountId);
                    }
                }
            }
        }
    }

    //method used to populate fields on term form (called by method - processTermForms)
    public static void populateTermFormFields(NSP_Termination_Form__c termForm, Map<String,Id> mapOfAccountAndAccountTeam, Id mappedAccountId){
        Map<String,String> termFormFieldMapping = new Map<String,String>{
            'NSP_Approver__c' => NSP_ServiceConstants.PAYROLL_SUPERVISOR ,
            'NSP_Supervisor__c' => NSP_ServiceConstants.PAYROLL_SUPERVISOR ,
            'NSP_Payroll_Specialist__c' => NSP_ServiceConstants.PAYROLL_SPECIALIST ,
            'NSP_Sales_Representative__c' => NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR ,
            'NSP_Client_Liaison__c' => NSP_ServiceConstants.CLIENT_LIAISION ,
            'NSP_Account_Executive__c' => NSP_ServiceConstants.MID_MARKET_ACC_EX ,
            'NSP_Manager_HR_Services__c' => NSP_ServiceConstants.MANAGER_HRSERVICES ,
            'NSP_Insperity_Blended_Role__c' => NSP_ServiceConstants.BUS_TEAM_HRSP_CL ,
            'BPA__c' => NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR ,
            'BPC__c' => NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT ,
            'Renewal_Coordinator__c' => renewalCoordinator
        };
        if(termForm != null){
            for(String fieldAPI :termFormFieldMapping.keyset()){
                String key = mappedAccountId + '-' + termFormFieldMapping.get(fieldAPI);
                if(mapOfAccountAndAccountTeam.containskey(key)){
                    termform.put(fieldAPI,mapOfAccountAndAccountTeam.get(key));
                }
             }
         }
    }

    public void updateClientTermDateOnProject( List<NSP_Termination_Form__c> lTerminationForms , Map<Id,NSP_Termination_Form__c> mTerminationForms ) {
        if ( ( mTerminationForms != null ) && !mTerminationForms.isEmpty() ) {
            Map<Id,Id> mapOfTerminationFormAndProjectId = new Map<Id,Id>();
            Map<Id,pse__Proj__c> mapOfProject = new Map<Id,pse__Proj__c>();
            for ( NSP_Termination_Form__c terminationForm : [
                    SELECT
                        NSP_Project_Task__r.pse__Project__c ,
                        NSP_Project_Task__r.pse__Project__r.NSP_Client_Term_Date__c ,
                        NSP_Client_Term_Date__c
                    FROM NSP_Termination_Form__c
                    WHERE ( Id IN :mTerminationForms.keySet() )
                    ]
                )
            {
                if ( !mapOfTerminationFormAndProjectId.containsKey( terminationForm.id ) ) {
                    mapOfTerminationFormAndProjectId.put(
                        terminationForm.Id ,
                        terminationForm.NSP_Project_Task__r.pse__Project__c
                    );
                }
                if ( ( terminationForm.NSP_Client_Term_Date__c != null )
                    && ( terminationForm.NSP_Project_Task__r.pse__Project__r.NSP_Client_Term_Date__c == null )
                    && !mapOfProject.containsKey(terminationForm.NSP_Project_Task__r.pse__Project__c)
                    )
                {
                    mapOfProject.put(
                        terminationForm.NSP_Project_Task__r.pse__Project__c ,
                        new pse__Proj__c(
                            Id=terminationForm.NSP_Project_Task__r.pse__Project__c ,
                            NSP_Client_Term_Date__c=terminationForm.NSP_Client_Term_Date__c
                        )
                    );
                }
            }
            if ( !mapOfProject.isEmpty() ) {
                update mapOfProject.values();
            }
        }
    }

    //
    // Iterates throught the list of new NSP_Termination_Form__c and passes the required attributes to other methods.
    // @param newList, oldMap List of NSP_Termination_Form__c.
    // @return void
    // description: logic to update account on NSP_Termination_Form__c
    // Date :7/13/2023
    //
    public void updateAccountOnTerm( List<NSP_Termination_Form__c> newList , Map<Id,NSP_Termination_Form__c> oldMap ) {
        try {
            Map<Id,Id> termAccountIdMap = new Map<Id,Id>();
            for ( NSP_Termination_Form__c newTerm : newList ) {
                if ( newTerm.NSP_Project_Task__c != null ) {
                    NSP_Termination_Form__c oldTerm = null;
                    if ( ( oldMap != null ) && oldMap.containsKey( newTerm.Id ) ) {
                        oldTerm = oldMap.get( newTerm.Id );
                    }
                    if ( ( oldTerm == null ) || ( newTerm.NSP_Project_Task__c != oldTerm.NSP_Project_Task__c ) ) {
                        termAccountIdMap.put(
                            newTerm.Id ,
                            newTerm.NSP_Project_Task__c
                        );
                    }
                }
            }
            Map<Id,Id> accountIdMap = new Map<Id,Id>();
            if ( !termAccountIdMap.isEmpty() ) {
                for ( pse__Project_Task__c eachProjectTasklist : [
                            SELECT Id , NSP_Account_Id__c
                            FROM pse__Project_Task__c
                            WHERE (
                                NSP_Account_Id__c != null
                                AND Id IN :termAccountIdMap.values()
                            )
                        ]
                    )
                {
                    accountIdMap.put(
                        eachProjectTasklist.Id ,
                        eachProjectTasklist.NSP_Account_Id__c
                    );
                }
            }
            for ( NSP_Termination_Form__c newTerm : newList ) {
                if ( termAccountIdMap.containsKey( newTerm.Id ) ) {
                    Id mappedId = termAccountIdMap.get( newTerm.Id );
                    if ( accountIdMap.containsKey( mappedId ) ) {
                        newTerm.NSP_Account__c = accountIdMap.get( mappedId );
                    }
                }
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_TerminationFormTriggerHelper.class.getName() ,
                'updateAccountOnTerm' ,
                e
            );
        }
    }

    /**
    * Populates email and phone from client Owner lookup when user selects client owner
    * @param setOfClientOwnerId set of Client Owner(Contact) Ids
    * @param clientTerminationForms termination form list.
    * @return void
    *
    */
    private void populateClientOwnerEmailAndPhone( Set<Id> setOfClientOwnerId , List<NSP_Termination_Form__c> clientTerminationForms ) {
        Map<Id,Contact> contactMap = new Map<Id,Contact>([
            SELECT Id , NSP_Work_email__c , NSP_Work_Phone__c
            FROM Contact
            WHERE Id IN: setOfClientOwnerId
        ]);
        for(NSP_Termination_Form__c termForm : clientTerminationForms){
            termForm.Client_Owner_Email__c = contactMap.get(termForm.NSP_Client_Owner__c).NSP_Work_email__c;
            termForm.Client_Owner_Phone__c = contactMap.get(termForm.NSP_Client_Owner__c).NSP_Work_Phone__c;
        }
    }

    /**
    * Populates phone from credit specialist lookup when user selects credit specialist
    * @param setOfCreditSpecialistId set of Credit specialist(Contact) Ids
    * @param creditTerminationForms termination form list.
    * @return void
    *
    */
    public void populateCreditspecialistphone(Set<Id> setOfCreditSpecialistId, List<NSP_Termination_Form__c> creditTerminationForms ){
        Map<Id,Contact> contactMap = new Map<Id,Contact>([SELECT Id,NSP_Work_Phone__c FROM Contact WHERE ID IN: setOfCreditSpecialistId]);
        if(creditTerminationForms != null && contactMap != null){
            for(NSP_Termination_Form__c termForm : creditTerminationForms){
                termForm.NSP_Credit_Specialist_Phone__c = contactMap.get(termForm.Credit_Specialist__c).NSP_Work_Phone__c;
            }
        }
    }

}
//