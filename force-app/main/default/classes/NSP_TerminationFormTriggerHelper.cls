/**
* Represents the termination form trigger helper which handles all the logic.
*/
public class NSP_TerminationFormTriggerHelper {
    // test w/ NSP_TerminationFormTriggerHelperTest (91%)

    private static final string SUPERVISOR_DENIED = 'PR Supervisor Denied';
    private static final string TERM_TEAM_DENIED = 'Term Team Denied';
    private static final string TERM_TEAM_APPROVED = 'Term Team Approved';
    public static final String NSP_Credit_Specialist_Form = 'NSP_Credit_Specialist_Form';
    public static final String Termination_Form_Approved = 'Termination_Form_Approved';

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

    /**
    * Populates the Sub Client Numbers from the Account and Number of Employees from WO Asset on Termination Form
    * @param sProjectTaskIds set of Project Task Ids
    * @param lTerminationForms List of New Termination Forms.
    * @return void             
    *                
    */
    public void populateSubClientandAssetValues(Set<Id> sProjectTaskIds, List<NSP_Termination_Form__c> lTerminationForms){
        Id woAssetRecordTypeId =  Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE)?.getRecordTypeId();
        String ClientRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.NSP_Client_Reinstatement).getRecordTypeId();
        Map<Id,pse__Project_Task__c> mProjectTasks = new Map<Id,pse__Project_Task__c>([SELECT Id,pse__Project__r.pse__Account__c FROM pse__Project_Task__c WHERE ID in : sProjectTaskIds]);
        Set<Id> sAccountIds = new Set<Id>();
        for(pse__Project_Task__c oProjectTask : mProjectTasks.values()){
            if(oProjectTask.pse__Project__r?.pse__Account__c != null){
                sAccountIds.add(oProjectTask.pse__Project__r.pse__Account__c);
            }
        }
        List<String> assetFields = new List<String>{'Id','AccountId','Status','NSP_Client_Segment_type__c'};
        //getting all the assets from record with filter from queryBuilder Class
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
            .addFilter('RecordTypeId', woAssetRecordTypeId)
            .addFilter('Status', NSP_ServiceConstants.ASSET_ACTIVE_STATUS)
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
        List<NSP_Sub_Client__c> lTerminatedSubClients = new List<NSP_Sub_Client__c>([SELECT Id,NSP_Account__c,NSP_Sub_Client__c 
                                                FROM NSP_Sub_Client__c 
                                                WHERE NSP_Account__c IN: sAccountIds
                                                AND NSP_Asset__c IN: terminatedAssetsList]);
        
        List<NSP_Sub_Client__c> lSubClients = new List<NSP_Sub_Client__c>([SELECT Id,NSP_Account__c,NSP_Sub_Client__c,NSP_Renewal_Date__c 
                                                FROM NSP_Sub_Client__c 
                                                WHERE NSP_Account__c IN: sAccountIds
                                                AND NSP_Asset__c IN: assetsList
                                                AND NSP_Account_Status__c != :NSP_ServiceConstants.TERMINATED]);
        
        Map<Id,String> mTermAccountToSubClientNumbers = new Map<Id,String>();
        for(NSP_Sub_Client__c oTempSClient : lTerminatedSubClients){
            if(String.isNotBlank(oTempSClient.NSP_Sub_Client__c)){
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
        
        List<Asset> lAssets = new List<Asset>([SELECT ID,AccountId,NSP_Client__c, NSP_Unique_Active_Employee__c FROM Asset WHERE RecordTypeId =: woAssetRecordTypeId AND AccountId IN : sAccountIds]);
        Map<Id,Decimal> mAccountToAssetEmployees = new Map<Id,Decimal>();
        for(Asset otempAsset : lAssets){
            Decimal uniqueActiveEmp = otempAsset.NSP_Unique_Active_Employee__c != null ? otempAsset.NSP_Unique_Active_Employee__c : 0;
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
        
        Map<Id,Date> mClientRenewelDate = new Map<Id,Date>();
        for(NSP_Sub_Client__c oClientRenewel : lSubClients){
            if(oClientRenewel.NSP_Sub_Client__c!=Null && oClientRenewel.NSP_Sub_Client__c.endsWith('00')
               && oClientRenewel.NSP_Renewal_Date__c!=Null ){
                mClientRenewelDate.put(oClientRenewel.NSP_Account__c, oClientRenewel.NSP_Renewal_Date__c);
            }
        }

        for(NSP_Termination_Form__c oTerminationForm : lTerminationForms){
            pse__Project_Task__c oProjectTask  = mProjectTasks.get(oTerminationForm.NSP_Project_Task__c);
            Id accountId = oProjectTask.pse__Project__r?.pse__Account__c;
            if(accountId != null){
                if(oTerminationForm.RecordTypeId != ClientRecordTypeId ){
                oTerminationForm.NSP_Client_Sub_Account_Numbers__c = mAccountToSubClientNumbers.get(accountId);
                oTerminationForm.NSP_Number_of_Active_Employees__c = mAccountToAssetEmployees.get(accountId);
                  
                 }
                Else{
                    If(mAccountToSubClientNumbers.get(accountId)==Null){
                      oTerminationForm.NSP_Client_Sub_Account_Numbers__c = mTermAccountToSubClientNumbers.get(accountId);
               		  oTerminationForm.NSP_Number_of_Active_Employees__c = mAccountToAssetEmployees.get(accountId);
                    }
                    Else{
                      oTerminationForm.NSP_Client_Sub_Account_Numbers__c = mAccountToSubClientNumbers.get(accountId);
               		  oTerminationForm.NSP_Number_of_Active_Employees__c = mAccountToAssetEmployees.get(accountId);
                    }  
                 }
                if(mAccountToAssetAIMSClientNumber != null){
                    oTerminationForm.NSP_Client_Number__c = mAccountToAssetAIMSClientNumber.get(accountId);
                }
                if(mClientSegmentAsset != null){
                    oTerminationForm.NSP_Segment_Type__c = mClientSegmentAsset.get(accountId); 
                }
                if(mClientRenewelDate != null){
                    oTerminationForm.NSP_Renewal_Date__c = mClientRenewelDate.get(accountId); 
                }
            }           
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

    public void shareTerminationFormsWithUsers(Map<Id,Set<Id>> mRecordToUsers, String accessLevel){
        List<NSP_Termination_Form__Share> lTerminationFormShares = new List<NSP_Termination_Form__Share>();
        for(Id iTForm: mRecordToUsers.keySet()){
            for(Id iUser : mRecordToUsers.get(iTForm)){
                lTerminationFormShares.add(new NSP_Termination_Form__Share(ParentId = iTForm,UserOrGroupId = iUser,AccessLevel = accessLevel));
            }
        }
        if(lTerminationFormShares.size() > 0){
            insert lTerminationFormShares;
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

    public void afterUpdateTerminationForm(List<NSP_Termination_Form__c> terminationFormList, map<Id, NSP_Termination_Form__c> oldMap){
        set<Id> setOfProjectTaskId = new set<Id>();
        Map<Id,Set<Id>> mTFToUsers = new Map<Id,Set<Id>>();
        Map<Id,Set<Id>> mTFSharingToDelete = new Map<Id,Set<Id>>();
        List<NSP_Termination_Form__c> queueNewTerm = new List<NSP_Termination_Form__c>();
       	Map<Id, NSP_Termination_Form__c> queueOldMap = new Map<Id, NSP_Termination_Form__c>();
        Set<Id> processedTerm = new Set<Id>();
        Set<Id> termFormSet = new Set<Id>();
        Set<ID> terminationFormBellNotificationSet = new Set<ID>();
        String PayrollRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.NSP_Payroll_Specialist_Form).getRecordTypeId();
        String CreditRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_Credit_Specialist_Form).getRecordTypeId();
        
        for(NSP_Termination_Form__c terminationForm : terminationFormList){
            if(terminationForm.NSP_Project_Task__c != null 
                && terminationForm.NSP_Status__c == NSP_ServiceConstants.TERMINATION_FORM_PR_APPROVED_STATUS 
                && terminationForm.NSP_Status__c != oldMap.get(terminationForm.id).NSP_Status__c){
                setOfProjectTaskId.add(terminationForm.NSP_Project_Task__c);
            }

            //RECORD SHARING LOGIC
            mTFToUsers.put(terminationForm.Id,new Set<Id>());
            mTFSharingToDelete.put(terminationForm.Id,new Set<Id>());
            NSP_Termination_Form__c oOldTermination = oldMap.get(terminationForm.Id);
			if(oOldTermination != null && terminationForm.NSP_Project_Task__c!= null && terminationForm.NSP_Project_Task__c != oOldTermination.NSP_Project_Task__c && !processedTerm.contains(terminationForm.Id) )
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
    
            if(terminationForm.NSP_Status__c != null && terminationForm.NSP_Status__c != oldMap.get(terminationForm.Id).NSP_Status__c 
               && ((terminationForm.RecordTypeId == PayrollRecordTypeId && terminationForm.NSP_Status__c == SUPERVISOR_DENIED)
                   || (terminationForm.RecordTypeId == CreditRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_DENIED) 
                   || (terminationForm.RecordTypeId == CreditRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_APPROVED) 
                   || (terminationForm.RecordTypeId == PayrollRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_APPROVED) )){
                       terminationFormBellNotificationSet.add(terminationForm.Id);
                   }
            if(terminationForm.NSP_Status__c != null && terminationForm.NSP_Status__c != oldMap.get(terminationForm.Id).NSP_Status__c 
               && terminationForm.RecordTypeId == PayrollRecordTypeId && terminationForm.NSP_Status__c == TERM_TEAM_APPROVED){
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

        if(!setOfProjectTaskId.isEmpty()){
            updateProjectTaskStatus(setOfProjectTaskId);
        }
        
        if(terminationFormBellNotificationSet.size() > 0){
            sendBellNotificationToSpecialist(terminationFormBellNotificationSet);
        }
        if(termFormSet.size() > 0){
            sendEmailNotificationToSupervisor(termFormSet);
        }
    }
    
    /**
    * Method to Send Bell Notifications when termination form is rejected/approved
    */
    @future
    public static void sendBellNotificationToSpecialist(Set<ID> terminationFormSet){
        String PayrollRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.NSP_Payroll_Specialist_Form).getRecordTypeId();
        String CreditRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_Credit_Specialist_Form).getRecordTypeId();
        Set<String> specialistIds = new Set<String>();
        Map<NSP_Termination_Form__c,Set<String>> termFormToSpecialistIdsMap = new Map<NSP_Termination_Form__c,Set<String>>();
        List<NSP_Termination_Form__c> terminationFormBellNotificationList = [
            SELECT ID, Name, NSP_Supervisor__c, NSP_Status__c, RecordTypeId, NSP_Payroll_Specialist__c, Credit_Specialist__c, OwnerId, CreatedById
            FROM NSP_Termination_Form__c 
            WHERE ID IN:terminationFormSet
        ];
        for(NSP_Termination_Form__c term : terminationFormBellNotificationList){
            if(term.RecordTypeId == PayrollRecordTypeId && term.NSP_Status__c == SUPERVISOR_DENIED && term.NSP_Payroll_Specialist__c != Null){
                specialistIds.add(term.NSP_Payroll_Specialist__c);
                termFormToSpecialistIdsMap.put(term, specialistIds);
            }else if(term.RecordTypeId == CreditRecordTypeId && term.NSP_Status__c == TERM_TEAM_DENIED && term.Credit_Specialist__c != Null){
                specialistIds.add(term.Credit_Specialist__c);
                termFormToSpecialistIdsMap.put(term, specialistIds);
            }else if(term.RecordTypeId == CreditRecordTypeId && term.NSP_Status__c == TERM_TEAM_APPROVED && term.OwnerId != Null){
                specialistIds.add(term.OwnerId);
                specialistIds.add(term.CreatedById);
                termFormToSpecialistIdsMap.put(term, specialistIds);
            }else if(term.RecordTypeId == PayrollRecordTypeId && term.NSP_Status__c == TERM_TEAM_APPROVED && term.NSP_Supervisor__c != Null){
                specialistIds.add(term.NSP_Supervisor__c);
                specialistIds.add(term.OwnerId);
                specialistIds.add(term.CreatedById);
                termFormToSpecialistIdsMap.put(term, specialistIds);
            }
        }
        
        if(termFormToSpecialistIdsMap.keySet().size()> 0 ){
            for(NSP_Termination_Form__c termForm : termFormToSpecialistIdsMap.keySet()){
                CustomNotificationType bellNotificationTermForm = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName='NSP_Bell_Notification_Termination_Form' LIMIT 1];  
        		Messaging.CustomNotification Notification = new Messaging.CustomNotification();
        		Notification.setNotificationTypeId(bellNotificationTermForm.id);
            	if(termForm.NSP_Status__c == TERM_TEAM_DENIED || termForm.NSP_Status__c == SUPERVISOR_DENIED){
                    Notification.setTitle('Approval Request for Termination Form is Rejected');
                }else if(termForm.NSP_Status__c == TERM_TEAM_APPROVED){
                	Notification.setTitle('Approval Request for Termination Form is Approved');
                }
        		Notification.setBody(termForm.Name); 
        		Notification.setTargetId(termForm.Id);
                Notification.send(termFormToSpecialistIdsMap.get(termForm));
            }
        }
    }
    
    /**
    * Method to Send Email Notification to Supervisor when termination form is rejected
    */
    @future
    public static void sendEmailNotificationToSupervisor(Set<Id> termFormSet){
        String PayrollRecordTypeId = Schema.SObjectType.NSP_Termination_Form__c.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.NSP_Payroll_Specialist_Form).getRecordTypeId();
        Map<Id,Id> termFormToSupervisorId = new Map<Id,Id>();
        List<NSP_Termination_Form__c> iTermFrom = new List<NSP_Termination_Form__c>();
        
        iTermFrom = [SELECT ID, NSP_Supervisor__c, NSP_Status__c, RecordTypeId FROM NSP_Termination_Form__c WHERE ID IN:termFormSet];
        
        for(NSP_Termination_Form__c termForm : iTermFrom){
            if(termForm.NSP_Supervisor__c != Null && termForm.NSP_Status__c == TERM_TEAM_APPROVED && termForm.RecordTypeId == PayrollRecordTypeId){
                termFormToSupervisorId.put(termForm.Id, termForm.NSP_Supervisor__c);
            }
        }
        
        if(termFormToSupervisorId.keySet().size() > 0 ){
            NSP_EmailService.sendEmail(termFormToSupervisorId, Termination_Form_Approved);
        }
    }

    public void checkLookupChange(Map<Id,Set<ID>> mTFToUsers,Id recordId,Id OwnerId, Id iUser){
        if(iUser != null && iUser != OwnerId){
            mTFToUsers.get(recordId).add(iUser);
        }
    }

    public void deleteTerminationFormSharing(Map<Id,Set<Id>> mDeleteSharingIds){
        String query = 'SELECT ID FROM NSP_Termination_Form__Share WHERE';
        for(Id iTForm : mDeleteSharingIds.keySet()){
            query += ' ( ParentID = \'' + iTForm + '\' AND UserorGroupId in (\'';
            for(Id userId : mDeleteSharingIds.get(iTForm)){
                query +=  userId + '\',\'';
            }
            query = query.removeEnd(',\'');
            query += ')) OR';
        }
        query = query.removeEnd(' OR');
        List<NSP_Termination_Form__Share> lDeleteSharing = (List<NSP_Termination_Form__Share>)Database.query(query);
        if(lDeleteSharing.size() > 0){
            delete lDeleteSharing;
        }
    }

    public static void updateProjectTaskStatus(set<Id> setOfProjectTaskId){
        list<pse__Project_Task__c> listOfProjectTask = new list<pse__Project_Task__c> ();

        for(pse__Project_Task__c projectTask : [SELECT pse__Project__c FROM pse__Project_Task__c WHERE ID IN : setOfProjectTaskId]){
            projectTask.pse__Status__c = NSP_ServiceConstants.TASKCOMPLETE;
            listOfProjectTask.add(projectTask);
        }

        if(!listOfProjectTask.isEmpty()){
            update listOfProjectTask;
        }
    }

    /* Description : This method will fetch value of User Lookups from Account Team
        Date       : 13/10/2021 */

    public static void updateUserLookups(set<Id> setOfProjectTaskId, List<NSP_Termination_Form__c> terminationFormList){
        map<Id, Id> mapOfProjectTaskAndProject = new map<Id, Id>();
        map<Id, Id> mapOfProjectAndAccount     = new map<Id, Id>();
        map<String, Id> mapOfAccountAndAccountTeam = new map<String, Id>();

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

        if(mapOfProjectAndAccount != null){
            for(NSP_Account_Team__c accountTeam : [SELECT NSP_Account__c, NSP_User__c, NSP_Role__c FROM NSP_Account_Team__c 
                                                    WHERE NSP_Account__c IN : mapOfProjectAndAccount.values() 
                                                    ]){
                if(!mapOfAccountAndAccountTeam.containsKey(accountTeam.NSP_Account__c)){
                    mapOfAccountAndAccountTeam.put(accountTeam.NSP_Account__c + '-' + accountTeam.NSP_Role__c, accountTeam.NSP_User__c);
                }
            }
        }

        for(NSP_Termination_Form__c termForm : terminationFormList){
            if(mapOfAccountAndAccountTeam != null && mapOfProjectAndAccount != null && mapOfProjectTaskAndProject != null){
                termForm.NSP_Approver__c                = mapOfAccountAndAccountTeam.get(
                                                                mapOfProjectAndAccount.get(
                                                                mapOfProjectTaskAndProject.get(termForm.NSP_Project_Task__c)) + '-' + NSP_ServiceConstants.PAYROLL_SUPERVISOR);
                    termForm.NSP_Supervisor__c              = mapOfAccountAndAccountTeam.get(
                                                                mapOfProjectAndAccount.get(
                                                                mapOfProjectTaskAndProject.get(termForm.NSP_Project_Task__c)) + '-' + NSP_ServiceConstants.PAYROLL_SUPERVISOR);
                    termForm.NSP_Payroll_Specialist__c      = mapOfAccountAndAccountTeam.get(
                                                                mapOfProjectAndAccount.get(
                                                                mapOfProjectTaskAndProject.get(termForm.NSP_Project_Task__c)) + '-' + NSP_ServiceConstants.PAYROLL_SPECIALIST);
                    termForm.NSP_Sales_Representative__c    = mapOfAccountAndAccountTeam.get(
                                                                mapOfProjectAndAccount.get(
                                                                mapOfProjectTaskAndProject.get(termForm.NSP_Project_Task__c)) + '-' + NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR);
                    termForm.NSP_Client_Liaison__c          = mapOfAccountAndAccountTeam.get(
                                                                mapOfProjectAndAccount.get(
                                                                mapOfProjectTaskAndProject.get(termForm.NSP_Project_Task__c)) + '-' + NSP_ServiceConstants.CLIENT_LIAISION);
                    termForm.NSP_Account_Executive__c       = mapOfAccountAndAccountTeam.get(
                                                                mapOfProjectAndAccount.get(
                                                                mapOfProjectTaskAndProject.get(termForm.NSP_Project_Task__c)) + '-' + NSP_ServiceConstants.MID_MARKET_ACC_EX);
                    termForm.NSP_Manager_HR_Services__c     = mapOfAccountAndAccountTeam.get(
                                                                mapOfProjectAndAccount.get(
                                                                mapOfProjectTaskAndProject.get(termForm.NSP_Project_Task__c)) + '-' + NSP_ServiceConstants.MANAGER_HRSERVICES);
                    termForm.NSP_Insperity_Blended_Role__c  = mapOfAccountAndAccountTeam.get(
                                                                mapOfProjectAndAccount.get(
                                                                mapOfProjectTaskAndProject.get(termForm.NSP_Project_Task__c)) + '-' + NSP_ServiceConstants.BUS_TEAM_HRSP_CL);
            }
        }
    }
    public void updateClientTermDateOnProject(List<NSP_Termination_Form__c> lTerminationForms , Map<Id,NSP_Termination_Form__c> mTerminationForms){
        List<pse__Proj__c> listOfProjects = new List<pse__Proj__c> ();
        Map<Id, Id> mapOfTerminationFormAndProjectId = new Map<Id, Id> ();
        Map<ID, pse__Proj__c> mapOfProject = new Map<ID, pse__Proj__c> ();
        
        for(NSP_Termination_Form__c terminationForm : [SELECT NSP_Project_Task__r.pse__Project__c,NSP_Project_Task__r.pse__Project__r.NSP_Client_Term_Date__c,NSP_Client_Term_Date__c FROM NSP_Termination_Form__c WHERE ID IN : mTerminationForms.keySet()]){
            if(!mapOfTerminationFormAndProjectId.containsKey(terminationForm.id)){
                mapOfTerminationFormAndProjectId.put(terminationForm.id, terminationForm.NSP_Project_Task__r.pse__Project__c);
            }
            
            if(terminationForm.NSP_Client_Term_Date__c != null && terminationForm.NSP_Project_Task__r.pse__Project__r.NSP_Client_Term_Date__c == null){
                if(!mapOfProject.containsKey(terminationForm.NSP_Project_Task__r.pse__Project__c)){
                    mapOfProject.put(terminationForm.NSP_Project_Task__r.pse__Project__c, new pse__Proj__c(ID = terminationForm.NSP_Project_Task__r.pse__Project__c, NSP_Client_Term_Date__c = terminationForm.NSP_Client_Term_Date__c));
                }
            }
            
        }
        if(mapOfProject.keySet().size()>0){
            update mapOfProject.values();
        }
     }
   
    
/* Iterates throught the list of new NSP_Termination_Form__c and passes the required attributes to other methods.
* @param newList, oldMap List of NSP_Termination_Form__c.  
* @return void   
* description: logic to update account on NSP_Termination_Form__c
* Date :7/13/2023
*/
    public void updateAccountOnTerm(List<NSP_Termination_Form__c> newList,Map<Id, NSP_Termination_Form__c> oldMap){
        List <NSP_Termination_Form__c> termListLookup = new List<NSP_Termination_Form__c> ();
		map<id,id> accountIdMap = new map<id,id>();
        map<id,id> termAccountIdMap = new map<id,id>();
		for(NSP_Termination_Form__c newTerm : newList){
			NSP_Termination_Form__c oldTerm = oldMap != null ? oldMap.get(newTerm.Id):null;
            if((newTerm.NSP_Project_Task__c != null && Trigger.isInsert) || (newTerm.NSP_Project_Task__c != oldTerm.NSP_Project_Task__c && newTerm.NSP_Project_Task__c != null)  ){
                termAccountIdMap.put(newTerm.Id,newTerm.NSP_Project_Task__c );
            }
		}
        if(termAccountIdMap.Size() > 0) {
           
            for(pse__Project_Task__c eachProjectTasklist : [SELECT Id, NSP_Account_Id__c FROM pse__Project_Task__c 
                                                            WHERE NSP_Account_Id__c != null AND ID IN :termAccountIdMap.values()]) {
                accountIdMap.put(eachProjectTasklist.Id,eachProjectTasklist.NSP_Account_Id__c);
                                                              
            }

        } 
        for(NSP_Termination_Form__c newTerm : newList){
            if(termAccountIdMap.keyset().contains(newTerm.id)){
                newTerm.NSP_Account__c = accountIdMap.get(termAccountIdMap.get(newTerm.id));
            }
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