public with sharing class NSP_ImplementationProfileController {

    private static final String IP_OBJ_NAME = 'Implementation_Profile__c';
    
    /**
    * Returns a List of Related Clients of the Implementation Profile
    * @param recordId Id of the Implementation Profile Record 
    * @return List<NSP_IP_Related_Client__c> List of Related Clients
    */
    @AuraEnabled(cacheable=true)
    public static List<NSP_IP_Related_Client__c> getRelatedClients(Id recordId){
        try {
            return [SELECT Id,NSP_Related_Client__c,NSP_Related_Client__r.Name, NSP_Implementation_Profile__c,NSP_Implementation_Profile__r.Name FROM NSP_IP_Related_Client__c WHERE NSP_Implementation_Profile__c =: recordId];
        } catch (Exception except) {
            throw new AuraHandledException(except.getMessage());
        }
    }

    /**
    * Returns a List of Accounts with Names
    * @param clientIds List of Account Ids
    * @return List<Account> List of Accounts
    */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountName(List<Id> clientIds){
        try {
            return [SELECT Id,Name FROM Account WHERE Id in:clientIds WITH SECURITY_ENFORCED];
        } catch (Exception except) {
            throw new AuraHandledException(except.getMessage());
        }
    }

    /**
    * Return a NSP_IProfileGeneralWrapper that contains Implementation Profile records with its related clients
    * @param sIProfileGeneralWrapper Serialized version of NSP_IProfileGeneralWrapper
    * @return NSP_IProfileGeneralWrapper Update IP record with clients
    */
    @AuraEnabled
    public static NSP_IProfileGeneralWrapper saveGeneralDetails(String sIProfileGeneralWrapper){
        try {
            NSP_IProfileGeneralWrapper oGeneralWrapper = (NSP_IProfileGeneralWrapper)JSON.deserialize(sIProfileGeneralWrapper, NSP_IProfileGeneralWrapper.class);
            upsert oGeneralWrapper.oIProfile;
            if(oGeneralWrapper.lRelatedClients.size() > 0){
                for(NSP_IP_Related_Client__c oIPRelatedClient : oGeneralWrapper.lRelatedClients){
                    if(oIPRelatedClient.NSP_Implementation_Profile__c == null){
                        oIPRelatedClient.NSP_Implementation_Profile__c = oGeneralWrapper.oIProfile.Id;
                    }
                }
                upsert oGeneralWrapper.lRelatedClients;
            }
            return oGeneralWrapper;
        } catch (Exception except) {
            throw new AuraHandledException(except.getMessage());
        }
    }

    /**
    * Return a NSP_AssingmentMeetingIPWrapper that contains Implementation Profile records with its employee Orientations records
    * @param sAssigmentMeetingWrapper Serialized version of NSP_AssingmentMeetingIPWrapper
    * @return NSP_AssingmentMeetingIPWrapper Update IP record with employee orientations
    */
    @AuraEnabled
    public static NSP_AssingmentMeetingIPWrapper saveAssignmentDetails(String sAssigmentMeetingWrapper){
        try {
            NSP_AssingmentMeetingIPWrapper oAssigmentMeetingWrapper = (NSP_AssingmentMeetingIPWrapper)JSON.deserialize(sAssigmentMeetingWrapper, NSP_AssingmentMeetingIPWrapper.class);
            upsert oAssigmentMeetingWrapper.oIProfile;
            for(Employee_Orientation__c oEmployee : oAssigmentMeetingWrapper.lEmployeeOrientations){
                if(oEmployee.NSP_Implementation_Profile__c == null){
                    oEmployee.NSP_Implementation_Profile__c = oAssigmentMeetingWrapper.oIProfile.Id;
                }
            }
            upsert oAssigmentMeetingWrapper.lEmployeeOrientations;
            return oAssigmentMeetingWrapper;
        } catch (Exception except) {
            throw new AuraHandledException(except.getMessage());
        }
    }

    /**
    * Returns a List of Employee Orientations related to the given Implementation Profile
    * @param recordId Id of the Implementation Profile Record
    * @return List<Employee_Orientation__c> List of Employee Orientations
    */
    @AuraEnabled(cacheable=true)
    public static List<Employee_Orientation__c> getEmployeeOrientations(Id recordId){
        try {
            return [SELECT Id,Date_and_Time__c,Meeting_Type__c,Orientation_Rep__c,NSP_Implementation_Profile__c FROM Employee_Orientation__c WHERE NSP_Implementation_Profile__c =: recordId WITH SECURITY_ENFORCED];
        } catch (Exception except) {
            throw new AuraHandledException(except.getMessage());
        }
    }

    /**
    * Returns a List of Implementation Pay Periods related to the given Implementation Profile
    * @param recordId Id of the Implementation Profile Record
    * @return List<Implementation_Pay_Period__c> List of Implementation Pay Periods
    */
    @AuraEnabled(cacheable=true)
    public static List<Implementation_Pay_Period__c> getPayPeriods(Id recordId){
        try {
            return [SELECT Id,Client_number__c, Frequency__c, Insperity_first_day_of_1st_pay_period__c,Insperity_last_day_of_1st_pay_period__c,Insperity_1st_pay_date__c,Insperity_first_day_of_2nd_pay_period__c,Insperity_last_day_of_2nd_pay_period__c,
            Insperity_2nd_pay_date__c, Is_arrearage_7_days__c,Have_credit_services_approved__c, Provide_credit_services_detaIls__c,Does_arrearage_comply_with_state_laws__c,Provide_arrearage_details__c,
            Does_the_client_have_prior_wages__c, Final_pay_period_prior_to_Insperity__c, Final_pay_date_prior_to_Insperity__c,NSP_Implementation_Profile__c FROM Implementation_Pay_Period__c WHERE NSP_Implementation_Profile__c =: recordId WITH SECURITY_ENFORCED];
        } catch (Exception except) {
            throw new AuraHandledException(except.getMessage());
        }
    }

    /**
    * Return a NSP_PayrollIPWrapper that contains Implementation Profile records with its employee Orientations records
    * @param sAssigmentMeetingWrapper Serialized version of NSP_AssingmentMeetingIPWrapper
    * @return NSP_AssingmentMeetingIPWrapper Update IP record with employee orientations
    */
    @AuraEnabled
    public static NSP_PayrollIPWrapper savePayrollDetails(String sPayrollWrapper){
        try {
            NSP_PayrollIPWrapper oPayrollIPWrapper = (NSP_PayrollIPWrapper)JSON.deserialize(sPayrollWrapper, NSP_PayrollIPWrapper.class);
            upsert oPayrollIPWrapper.oIProfile;
            if(oPayrollIPWrapper.lPayPeriods.size() > 0){
                for(Implementation_Pay_Period__c oPayPeriod : oPayrollIPWrapper.lPayPeriods){
                    if(oPayPeriod.NSP_Implementation_Profile__c == null){
                        oPayPeriod.NSP_Implementation_Profile__c = oPayrollIPWrapper.oIProfile.Id;
                    }
                }
                upsert oPayrollIPWrapper.lPayPeriods;
            }
            if(oPayrollIPWrapper.parentFieldNames != null){ 
            createNewEmployeeDataRecords(oPayrollIPWrapper.empRecords, oPayrollIPWrapper.oIProfile.Id, oPayrollIPWrapper.parentFieldNames);
            }
            return oPayrollIPWrapper;
        } catch (Exception except) {
            throw new AuraHandledException(except.getMessage());
        }
    }

    /**
    * Returns a List of account team members as comma separated String
    * @param recordId Id of the Account/ Project
    * @param isAccountId Boolean flag to check whether record Id is of account / asset
    * @return String Comma Separated values
    */
    @AuraEnabled
    public static AccountTeamWrapper getTeamMembers(String recordId, Boolean isAccountId){
        try {
            Id accountId = (Id) recordId;
            if(!isAccountId){
                accountId = [SELECT ID, pse__Account__c FROM pse__Proj__c WHERE Id = :recordId LIMIT 1].pse__Account__c;
            }
            AccountTeamWrapper accTeamWrapper = new AccountTeamWrapper();
            List<String> memberNames = new List<String>();
            List<String> memberIds = new List<String>();
            for (NSP_Account_Team__c member : [SELECT Name, NSP_User__c, NSP_User__r.Name FROM NSP_Account_Team__c 
                                              WHERE NSP_Account__c = :accountId
                                              AND NSP_User__c!=NULL
                                              AND (NSP_Role__c=:NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR OR
                                              NSP_Role__c=:NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT)]) {
                memberNames.add(member.NSP_User__r.Name);
                memberIds.add(member.NSP_User__c);
            }
            accTeamWrapper.memberNames = String.join(memberNames, ',');
            accTeamWrapper.memberIds = String.join(memberIds, ',');

            return accTeamWrapper;
        } catch (Exception except) {
            throw new AuraHandledException(except.getMessage());
        }
    }

    public static Map<String, List<String>> getEmpDetailsByQuestions(String ipRecordId){
        Map<String, List<String>> recMap = new Map<String, List<String>>();
        for(NSP_Employee_Data__c empRec : [SELECT Id, NSP_Parent_Field_API_Name__c FROM NSP_Employee_Data__c WHERE NSP_Implementation_Profile__c = :ipRecordId]){
            List<String> empRecords = recMap.get(empRec.NSP_Parent_Field_API_Name__c);
            if(empRecords == null){
                empRecords = new List<String>();
            }
            empRecords.add(empRec.Id);
            recMap.put(empRec.NSP_Parent_Field_API_Name__c, empRecords);
        }

        return recMap;
    }

    @AuraEnabled
    public static void saveEmployeeData(String records, String ipRecId, List<String> parentFieldNames){
        try{
			List<NSP_Employee_Data__c> newRecords = (List<NSP_Employee_Data__c>) JSON.deserialize(records, List<NSP_Employee_Data__c>.class);
            createNewEmployeeDataRecords(newRecords, ipRecId, parentFieldNames);
        } catch(Exception excep){
            throw new AuraHandledException(excep.getMessage());
        }
    }

    @AuraEnabled
    public static void saveAndDeleteRecords(String recordsConfig, String objectApiName){
        try {
            Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(recordsConfig);
            List<SObject> recordsToUpsert = getSobjectRecords((List<Object>) params.get('recordsToUpsert'), objectApiName);

            if(!recordsToUpsert.isEmpty()){
                upsert recordsToUpsert;
            }

            List<SObject> recordsToDelete = getSobjectRecords((List<Object>) params.get('recordsToDelete'), objectApiName);
            if(!recordsToDelete.isEmpty()){
                delete recordsToDelete;
            }
         } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }

    /**
      * This method retrieves the specific record from IP object with the provided Id and returns a sObject.
      * We have created this method just because UI API fails when field count is more than 650.
      * 
      * @param recordId - Id - unique identifier of the record to retrieve.
      * @return SObject - the sObject representation of the record returned.
      * @throws AuraHandledException - if any exception occurred while fetching the record.
    */
    @AuraEnabled
    public static SObject getRecordWithAllFields(Id recordId) {
        try {
          // Get the object's describe information
          SObjectType objectType = Schema.getGlobalDescribe().get(IP_OBJ_NAME);
          List<String> allFields = new List<String>(objectType.getDescribe().fields.getMap().keySet());

          return new NSP_sObjectSelector(IP_OBJ_NAME, allFields).setSecurityEnforce(false).selectById(recordId);
        }
        catch (Exception exc) {
            throw NSP_Utilities.getAuraException(exc);
        }
    }

    private static List<SObject> getSobjectRecords(List<Object> records, String sObjectName){
        List<SObject> sObjects = new List<SObject>();
        for(Object obj : records){
            SObject sObj = (SObject) JSON.deserialize(JSON.serialize(obj), Type.forName(sObjectName));
            sObjects.add(sObj);
        }
        
        return sObjects;
    }

    private static void createNewEmployeeDataRecords(List<NSP_Employee_Data__c> newRecords, String ipRecId, List<String> parentFieldNames){
        List<NSP_Employee_Data__c> existingRec = [SELECT Id FROM NSP_Employee_Data__c WHERE NSP_Implementation_Profile__c = :ipRecId AND NSP_Parent_Field_API_Name__c IN :parentFieldNames];
        if(!existingRec.isEmpty()){
            DELETE existingRec;
        }

        for (NSP_Employee_Data__c emp : newRecords) {
            emp.NSP_Implementation_Profile__c = ipRecId;
        }

        if(!newRecords.isEmpty()){
            INSERT newRecords;
        }
    }
    @AuraEnabled
    public static Implementation_Profile__c populateIPData(String accountId){
       return  NSP_ImplementationHelper.prepopulateIPData(accountId);
    }

    @AuraEnabled
    public static void copyIpRecordData(List<String> recordIds, String fieldValues, String sourceId, String recType, String userEmail){
        try{
	       NSP_ImplementationHelper.copyIpRecordData(recordIds, fieldValues, sourceId, recType, userEmail);
        } catch(Exception excep){
            throw new AuraHandledException(excep.getMessage());
        }
    }

    public class NSP_IProfileGeneralWrapper{
        @AuraEnabled
        public Implementation_Profile__c oIProfile;
        @AuraEnabled
        public List<NSP_IP_Related_Client__c> lRelatedClients;
        public NSP_IProfileGeneralWrapper(Implementation_Profile__c oIProfile,List<NSP_IP_Related_Client__c> lRelatedClients){
            this.oIProfile = oIProfile;
            this.lRelatedClients = lRelatedClients;
        }
    }
    public class NSP_AssingmentMeetingIPWrapper{
        @AuraEnabled
        public Implementation_Profile__c oIProfile;
        @AuraEnabled
        public List<Employee_Orientation__c> lEmployeeOrientations;
        public NSP_AssingmentMeetingIPWrapper(Implementation_Profile__c oIProfile,List<Employee_Orientation__c> lEmployeeOrientations){
            this.oIProfile = oIProfile;
            this.lEmployeeOrientations = lEmployeeOrientations;
        }
    }
    public class NSP_PayrollIPWrapper{
        @AuraEnabled
        public Implementation_Profile__c oIProfile;

        @AuraEnabled
        public List<Implementation_Pay_Period__c> lPayPeriods;

        @AuraEnabled
        public List<NSP_Employee_Data__c> empRecords;

        @AuraEnabled
        public List<String> parentFieldNames;

        public NSP_PayrollIPWrapper(Implementation_Profile__c oIProfile,List<Implementation_Pay_Period__c> lPayPeriods){
            this.oIProfile = oIProfile;
            this.lPayPeriods = lPayPeriods;
        }
    }
    public class AccountTeamWrapper{
        @AuraEnabled
        public String memberNames{get;set;}
       @AuraEnabled
        public String memberIds{get;set;}    
    }

    @AuraEnabled
    public static Map<String, List<String>> getIPRelatedRecords(String recordId){
        try {
            Map<String, List<String>> relatedRecordMap = new Map<String, List<String>>();
            String payPeriodQuery = new NSP_QueryBuilder('Implementation_Pay_Period__c')
                                                .addFilter('nsp_implementation_profile__c', recordId)
                                                .build();
            List<Sobject> relatedImplPayPeriodRecs = Database.query(payPeriodQuery);
            relatedRecordMap.put('Implementation_Pay_Period__c', getIdSetBySobjectRecords(relatedImplPayPeriodRecs));

            String empOrientationQuery = new NSP_QueryBuilder('Employee_Orientation__c')
                                                .addFilter('nsp_implementation_profile__c', recordId)
                                                .build();
            List<Sobject> relatedEmpOrientationRecs = Database.query(empOrientationQuery);
            relatedRecordMap.put('Employee_Orientation__c', getIdSetBySobjectRecords(relatedEmpOrientationRecs));

            String addClientContactQuery = new NSP_QueryBuilder('NSP_IP_Additional_Client_Contact__c')
                                                .addFilter('nsp_implementation_profile__c', recordId)
                                                .build();
            List<Sobject> relatedIPAddContactRecs = Database.query(addClientContactQuery);
            relatedRecordMap.put('NSP_IP_Additional_Client_Contact__c', getIdSetBySobjectRecords(relatedIPAddContactRecs));

            String relatedClientQuery = new NSP_QueryBuilder('NSP_IP_Related_Client__c')
                                                .addFilter('nsp_implementation_profile__c', recordId)
                                                .build();
            List<Sobject> relatedIPRelatedClientRecs = Database.query(relatedClientQuery);
            relatedRecordMap.put('NSP_IP_Related_Client__c', getIdSetBySobjectRecords(relatedIPRelatedClientRecs));

            relatedRecordMap.put('NSP_Implementation_Profile_Copy_Data__c', getCopyDataRecords(recordId));
            relatedRecordMap.putAll(getEmpDetailsByQuestions(recordId));

            return relatedRecordMap;
        } catch (Exception excep) {
            throw new AuraHandledException(excep.getMessage());
        }
    }

    private static List<String> getCopyDataRecords(String recordId){
        List<String> records = new List<String>();
        List<String> fields = new List<String>{ 'NSP_Target_Record__c', 'NSP_Target_Record__r.Name', 'NSP_Target_Record__r.Account__r.Name' };
        String copyDataQuery = new NSP_QueryBuilder('NSP_Implementation_Profile_Copy_Data__c', fields)
        .addFilter('NSP_Source_Record__c', recordId)
        .build();

        for (Sobject copyRecord : Database.query(copyDataQuery)) {
            SObject targetRecord = copyRecord.getSObject('NSP_Target_Record__r');
            SObject accountRec = targetRecord.getSObject('Account__r');

            String targetRecordName = String.valueOf(targetRecord.get('Name'));
            String accountName = accountRec == null ? '' : String.valueOf(accountRec.get('Name'));
            String targetRecordId = String.valueOf(copyRecord.get('NSP_Target_Record__c'));
            String targetRecordLabel = targetRecordName + ' | ' + accountName;

            records.add(targetRecordId + '~' + targetRecordLabel);
        }

        return records;
    }

    private static List<String> getIdSetBySobjectRecords(List<SObject> sObjects){
        return (List<String>) new List<Id>(new Map<Id, SObject>(sObjects).keySet());
    }
}