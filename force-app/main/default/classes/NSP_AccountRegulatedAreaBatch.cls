public class NSP_AccountRegulatedAreaBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> {
    // test w/ NSP_AccountRegulatedAreaBatch_Test (83%)

    private static final String CASE_SUBJECT = 'Employees work in ';
    private static List<NSP_Account_Regulated_area__c> accRegulatedAreaList = new List<NSP_Account_Regulated_area__c>();
    private static Map<String, List<String>> accWithCaseSubjStates = new Map<String, List<String>>();
    private static Map<String, List<Address>> accIdWithStateAddress = new Map<String, List<Address>>();
    private static Map<String, List<Address>> accIdWithZipAddress = new Map<String, List<Address>>();
    private static Map<String, Set<String>> accWithAddressStates = new Map<String, Set<String>>();
    private static Map<String, Set<String>> accWithAddressZipCodes = new Map<String, Set<String>>();
    private static List<NSP_Address__c> lstAddressToUpdate = new List<NSP_Address__c>();
    private static Map<Id, Set<String>> accWithAccRegState = new Map<Id, Set<String>>();
    private static Map<Id, set<String>> accWithAccRegCity = new Map<Id, Set<String>>();
    private static Map<String, String> accIdRegIdWithCaseSubject = new Map<String, String>();
    private static Set<String> setAccRegArea = new Set<String>();
    private static Set<String> setCases = new Set<String>();
    private static Set<String> setAddressId = new Set<String>();
    private static Map<Id, Map<String,Id>> accountWithTeamMemberId = new Map<Id, Map<String,Id>>();
    private static List<Group> lstHRImplementationqueue = new List<Group>();
    private static Map<Id, String> accountWithRoleMap = new Map<Id, String>();
    private static List<Case> lstCases = new List<Case>();
    private static List<Case> lstCasesToUpdate = new List<Case>();
    private static Id recordTypePEOID = NSP_GenericRecordType.getRecordTypeId('Case', NSP_ServiceConstants.PEO);
    @TestVisible private static Set<Id> setAccountIds = new Set<Id>();
    @TestVisible NSP_AccountRegulatedAreaBatch.Selector selector = new NSP_AccountRegulatedAreaBatch.Selector();
    private static Map<String, String> accIdWithCase = new Map<String, String>();
    private static Map<ID, String> caseWithSubject = new Map<ID, String>();
    public Set<String> setRegulatedStates = new Set<String>();
    public Map<String, NSP_Regulated_Area__c> stateWithRegulatedArea = new Map<String, NSP_Regulated_Area__c>();
    public Map<String, NSP_Regulated_Area__c> zipCodesWithRegArea = new Map<String, NSP_Regulated_Area__c>();
    public Integer counter = 0;
    public String query;

    public NSP_AccountRegulatedAreaBatch(Map<String,Object> data){
        this.counter = (Integer) data.get('counter');
        this.setRegulatedStates =  (Set<String>) data.get('setRegulatedStates');
        this.stateWithRegulatedArea = (Map<String, NSP_Regulated_Area__c>) data.get('stateWithRegulatedArea');
        this.zipCodesWithRegArea = (Map<String, NSP_Regulated_Area__c>) data.get('zipCodesWithRegArea');
        String regulatedStatesString = String.format( '(\'\'{0}\'\')', new List<String> { String.join( new List<String>(setRegulatedStates) , '\',\'') });
        String zipCodesString = String.format( '(\'\'{0}\'\')', new List<String> { String.join( new List<String>(zipCodesWithRegArea.keySet()) , '\',\'') });

        //Added this if condition as part of STY - STY-04472
        if(counter == 0){
            query = 'SELECT Id, NSP_City__c, NSP_Postal_Code__c, NSP_Postal_Code_New__c, NSP_State__c, NSP_Address_Type__c, '
                + ' NSP_Asset__c, NSP_Contact__c, NSP_Contact__r.Name, NSP_Related_Site__c, NSP_Contact__r.AccountId '
                + ' FROM NSP_Address__c '
                + ' WHERE NSP_Contact__c  != NULL'
                + ' AND NSP_Label_Code__c like \'%PW1%\''
                + ' AND (NSP_Address_Type__c = \''+ NSP_ServiceConstants.WORK_SITE + '\' OR NSP_Address_Type__c =\''+ NSP_ServiceConstants.US_MAIL +'\')'
                + ' AND NSP_Regulated_Batch__c = FALSE '
                + ' AND (NSP_State__c != NULL OR NSP_Postal_Code_New__c != NULL) '
                + ' AND (NSP_State__c IN '+regulatedStatesString+' OR NSP_Postal_Code_New__c IN '+zipCodesString+')';
        } else if(counter == 1){
            query = 'SELECT Id, NSP_Address__c,  NSP_Address__r.NSP_Related_Site__c, NSP_City__c, NSP_State__c,'
                + ' NSP_Postal_Code__c,NSP_Postal_Code_New__c, NSP_Address_Type__c, NSP_Contact__c, NSP_Contact__r.AccountId, NSP_Sub_Client_Contact__c,'
                + ' NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c, NSP_Sub_Client_Contact__r.NSP_Employee_Status__c'
                + ' FROM NSP_Sub_Client_Contact_Address__c'
                + ' WHERE (NSP_Address_Type__c =\''+ NSP_ServiceConstants.WORK_SITE +'\' OR NSP_Address_Type__c =\''+ NSP_ServiceConstants.US_MAIL +'\')'
                + ' AND NSP_Contact__c != NULL'
                + ' AND (NSP_Sub_Client_Contact__r.NSP_Employee_Status__c !=\''+ NSP_ServiceConstants.PRIMED_STATUS +'\' OR NSP_Sub_Client_Contact__r.NSP_Employee_Status__c !=\''+ NSP_ServiceConstants.TERMINATED_STATUS +'\')'
                + ' AND NSP_Address__r.NSP_Regulated_Batch__c = FALSE'
                + ' AND (NSP_City__c != NULL OR NSP_State__c != NULL OR NSP_Postal_Code_New__c != NULL)'
                + ' AND (NSP_State__c IN '+regulatedStatesString+' OR NSP_Postal_Code_New__c IN '+zipCodesString+')';
        }
    }

    //
    // argument-free constructor is required to be "runnable"...
    //

    public NSP_AccountRegulatedAreaBatch() {
    }

    //
    // ISelfSchedulable
    //

    // runs everyday at 12am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_AccountRegulatedArea_Scheduler ~ When SCC is added to the account and the zip code or city is present in regulated area it will create case and account regulated area ~ everyday at 12 AM' + suffix ,
            '0 0 0 ? * * *' ,
            new NSP_AccountRegulatedAreaBatch()
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
        return Database.executeBatch( new NSP_RegulatedAreaBatch() , 2000 );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator( query );
    }

    public void execute( Database.BatchableContext bc , List<sObject> lstRecords ) {
        try {
            if(lstRecords instanceOf List<NSP_Address__c>){
                getContactAddress((List<NSP_Address__c>) lstRecords);
            } else if(lstRecords instanceOf List<NSP_Sub_Client_Contact_Address__c>){
                getSubClientContactAddress((List<NSP_Sub_Client_Contact_Address__c>) lstRecords);
            }
            getAccountRecords();
            getAccountTeams();
            prepareAccRegAreaAndCase();
            createRecords();

        } catch (Exception ex) {
            NSP_ErrorLogHandler.logSaveException('NSP_AccountRegulatedAreaBatch', 'execute', ex.getMessage());
        }
    }

    //
    //
    //

    // insert AccountRegulatedArea Records and Cases into the database
    private void createRecords() {
        Map<String, String> subjectWithCaseId = new Map<String, String>();
        Set<Id> setAccRegAreas = new Set<Id>();
        if (!accRegulatedAreaList.isEmpty()) {
            Database.insert(accRegulatedAreaList, false);
            for (NSP_Account_Regulated_area__c accRegArea : accRegulatedAreaList) {
                setAccRegAreas.add(accRegArea.Id);
            }
        }
        if (!lstCases.isEmpty()) {
            Database.insert(lstCases, false);
            for (Case cse : lstCases) {
                String subject = cse.Subject?.replace(CASE_SUBJECT, '');
                List<String> lstDescription = new List<String>();
                if (subject?.contains('/ ')) {
                    List<String> localCities = subject?.Split('/');
                    lstDescription.add(localCities[0]);
                    if (localCities[1] != null) {
                        lstDescription.addAll(localCities[1].split(', '));
                    }
                } else {
                    lstDescription.addAll(subject?.split(', '));
                }
                for (String str : lstDescription) {
                    subjectWithCaseId.put(cse.AccountId + '_' + str, cse.Id);
                }
            }
        }
        if (!lstCasesToUpdate.isEmpty()) {
            Database.update(lstCasesToUpdate, false);
            for (Case cse : lstCasesToUpdate) {
                String subject = cse.Subject?.replace(CASE_SUBJECT, '');
                List<String> lstDescription = new List<String>();
                if (subject?.contains('/ ')) {
                    List<String> localCities = subject?.Split('/');
                    lstDescription.add(localCities[0]);
                    if (localCities[1] != null) {
                        lstDescription.addAll(localCities[1].split(', '));
                    }
                } else {
                    lstDescription.addAll(subject?.split(', '));
                }
                for (String str : lstDescription) {
                    subjectWithCaseId.put(cse.AccountId + '_' + str, cse.Id);
                }
            }
        }
        connectAccRegAreaWithCase(subjectWithCaseId, setAccRegAreas);
        if (!lstAddressToUpdate.isEmpty()) {
            Database.update(lstAddressToUpdate, false);
        }
    }

    private void connectAccRegAreaWithCase(Map<String, String> subjectWithCaseId, Set<Id> setAccRegAreas){
        if (!setAccRegAreas.isEmpty()) {
            List<NSP_Account_Regulated_area__c> lstToUpdate = new List<NSP_Account_Regulated_area__c>();
            for (NSP_Account_Regulated_area__c accRegArea : selector.getAccountsRegulatedAreaRecords(setAccRegAreas)) {
                if (accRegArea.NSP_State__c != null &&
                    subjectWithCaseId.containsKey(accRegArea.NSP_Account__c + '_' + accRegArea.NSP_State__c)) {
                    accRegArea.NSP_Case__c = subjectWithCaseId?.get(accRegArea.NSP_Account__c + '_' + accRegArea.NSP_State__c);
                }
                if (accRegArea.NSP_City__c != null &&
                    subjectWithCaseId.containsKey(accRegArea.NSP_Account__c + '_' + accRegArea.NSP_City__c)) {
                    accRegArea.NSP_Case__c = subjectWithCaseId?.get(accRegArea.NSP_Account__c + '_' + accRegArea.NSP_City__c);
                }
                lstToUpdate.add(accRegArea);
            }
            if (!lstToUpdate.isEmpty()) {
                Database.update(lstToUpdate, false);
            }
        }
    }

    private void prepareAccRegAreaAndCase() {
        List<Address> lstAddress = new List<Address>();
        Map<String, Set<String>> accIdWithCaseSubjToCreate = new Map<String, Set<String>>();

        for(Id accountId : setAccountIds){
            if(accIdWithStateAddress.containsKey(accountId)){
                lstAddress.addAll(accIdWithStateAddress.get(accountId));
            }
            if(accIdWithZipAddress.containsKey(accountId)){
                lstAddress.addAll(accIdWithZipAddress.get(accountId));
            }
        }

        //if Address exists and not created any of the case with state and city then it will prepare case to create
        if (!lstAddress.isEmpty()) {
            for (Address oAddress : lstAddress) {

                Set<String> lstExistingStates = accWithAccRegState.containsKey(oAddress.accountId) ? accWithAccRegState.get(oAddress.accountId) : new Set<String>();
                Set<String> accIdHasAddressStates = accWithAddressStates.containsKey(oAddress.accountId) ? accWithAddressStates.get(oAddress.accountId) : new Set<String>();

                Set<String> lstExistingZipCodes = accWithAccRegCity.containsKey(oAddress.accountId) ? accWithAccRegCity.get(oAddress.accountId) : new Set<String>();
                Set<String> accIdHasAddressZipCodes = accWithAddressZipCodes.containsKey(oAddress.accountId) ? accWithAddressZipCodes.get(oAddress.accountId) : new Set<String>();

                List<String> lstExistingCaseStates = accWithCaseSubjStates.containsKey(oAddress.accountId) ? accWithCaseSubjStates.get(oAddress.accountId) : new List<String>();

                //check for the state/Zip that exists or not then create new Account Regulated Area
                if (
                    stateWithRegulatedArea.containsKey(oAddress.state) &&
                    stateWithRegulatedArea?.get(oAddress.state)?.NSP_State__c != null &&
                    accIdHasAddressStates.contains(oAddress.state) &&
                    stateWithRegulatedArea?.get(oAddress.state)?.NSP_City__c == null &&
                    stateWithRegulatedArea?.get(oAddress.state)?.NSP_Zip_Code__c == null &&
                    !lstExistingStates.contains(oAddress.state)
                ) {
                    newAccountRegulatedArea(oAddress);
                } else if (
                    zipCodesWithRegArea.containsKey(oAddress.zipCode) &&
                    !lstExistingZipCodes.contains(oAddress.zipCode) &&
                    accIdHasAddressZipCodes.contains(oAddress.zipCode) &&
                    zipCodesWithRegArea?.get(oAddress.zipCode)?.NSP_State__c == null &&
                    zipCodesWithRegArea?.get(oAddress.zipCode)?.NSP_City__c != null &&
                    zipCodesWithRegArea?.get(oAddress.zipCode)?.NSP_Zip_Code__c != null
                ) {
                    newAccountRegulatedArea(oAddress);
                }

                //check for the state/Zip that exists or not then create new Case
                if (
                    stateWithRegulatedArea.containsKey(oAddress.state) &&
                    !lstExistingCaseStates.contains(oAddress.state) &&
                    accIdHasAddressStates.contains(oAddress.state) &&
                    stateWithRegulatedArea?.get(oAddress.state)?.NSP_State__c != null &&
                    stateWithRegulatedArea?.get(oAddress.state)?.NSP_City__c == null &&
                    stateWithRegulatedArea?.get(oAddress.state)?.NSP_Zip_Code__c == null
                ) {
                    if (accIdWithCaseSubjToCreate.containsKey(oAddress.accountId)) {
                        accIdWithCaseSubjToCreate.get(oAddress.accountId).add(oAddress.state);
                    } else {
                        accIdWithCaseSubjToCreate.put(
                            oAddress.accountId,
                            new Set<String>{ oAddress.state }
                        );
                    }
                } else if (
                    zipCodesWithRegArea.containsKey(oAddress.zipCode) &&
                    accIdHasAddressZipCodes.contains(oAddress.zipCode) &&
                    !lstExistingZipCodes.contains(oAddress.zipCode) &&
                    zipCodesWithRegArea?.get(oAddress.zipCode)?.NSP_State__c == null &&
                    zipCodesWithRegArea?.get(oAddress.zipCode)?.NSP_City__c != null &&
                    zipCodesWithRegArea?.get(oAddress.zipCode)?.NSP_Zip_Code__c != null
                ) {
                    if (accIdWithCaseSubjToCreate.containsKey(oAddress.accountId)) {
                        accIdWithCaseSubjToCreate.get(oAddress.accountId).add(
                                zipCodesWithRegArea?.get(oAddress.zipCode)?.NSP_City__c
                            );
                    } else {
                        accIdWithCaseSubjToCreate.put(
                            oAddress.accountId,
                            new Set<String>{
                                zipCodesWithRegArea?.get(oAddress.zipCode)?.NSP_City__c
                            }
                            // + '/', oAddress.zipCode
                        );
                    }
                }
                if (!setAddressId.contains(oAddress.id)) {
                    setAddressId.add(oAddress.id);
                    lstAddressToUpdate.add(
                        new NSP_Address__c(
                            Id = oAddress.id,
                            NSP_Regulated_Batch__c = true
                        )
                    );
                }
            }
        }

        //preparing Case for Account to create
        if (!accIdWithCaseSubjToCreate.isEmpty()) {
            List<Case> insertedCase = selector.getExistingCase(accIdWithCaseSubjToCreate.keySet());
            for(Case existCase : insertedCase){
               accIdWithCase.put(existCase.AccountId,existCase.Id);
                caseWithSubject.put(existCase.Id,existCase.Subject);
            }
            for (String accountId : accIdWithCaseSubjToCreate.keySet()) {
                List<String> lstSubj = new List<String>();
                lstSubj.addAll(accIdWithCaseSubjToCreate.get(accountId));
                accIdRegIdWithCaseSubject.put(
                    accountId,
                    CASE_SUBJECT + String.join(lstSubj, ', ')
                );
                if(!accIdWithCase.containsKey(accountId)){
                    newCase(accountId, CASE_SUBJECT + String.join(lstSubj, ', '));
                }else{
                    updateCase(accIdWithCase.get(accountId),accountId,caseWithSubject.get(accIdWithCase.get(accountId))+', ' + String.join(lstSubj, ', '));
                }
            }
        }
    }

    // getAccountRecords based onthe Address relatedContact and check whether the account records has existingAccounts and then existing Cases
    @TestVisible
    private void getAccountRecords() {
        for (Account oAccount : selector.getAccounts()) {

            for (Case ocase : oAccount?.Cases) {
                if(ocase.Subject != NULL && ocase?.Subject?.startsWithIgnoreCase(CASE_SUBJECT)){
                    caseData(ocase, oAccount.Id);
                }
            }

            for (NSP_Account_Regulated_area__c accRegArea : oAccount?.Account_Regulated_areas__r) {
                List<String> setZipCodes = accRegArea.NSP_Regulated_Area__r
                    ?.NSP_Zip_Code__c?.deleteWhiteSpace()?.split(',');
                Set<String> zipCodes = new Set<String>();
                if (setZipCodes != null) {
                    zipCodes.addAll(setZipCodes);
                }
                if (accWithAccRegState.containsKey(oAccount.Id)) {
                    accWithAccRegState.get(oAccount.Id)
                        .add(accRegArea.NSP_State__c);
                    accWithAccRegCity.get(oAccount.Id).addAll(zipCodes);
                } else {
                    accWithAccRegState.put(
                        oAccount.Id,
                        new Set<String>{
                            accRegArea.NSP_State__c
                        }
                    );
                    accWithAccRegCity.put(oAccount.Id, zipCodes);
                }
            }
        }
    }

    // getAccountRecords based onthe Address relatedContact has existingAccounts and then existing Cases
    private void caseData(Case ocase, Id accountId) {
        String subject = ocase.Subject?.replace(CASE_SUBJECT, '');
        List<String> subj = new List<String>();
        subj.addAll(subject?.split(', '));
        if (accWithCaseSubjStates.containsKey(accountId)) {
            accWithCaseSubjStates.get(accountId).addAll(subj);
        } else {
            accWithCaseSubjStates.put(accountId, subj);
        }
    }

    // ********************************************************************************************
    // MethodName  : getFilteredContactWorkAddressRecords
    // Description : This method will filter address records based on sub clients contacts employee status
    // Params      : List < NSP_Address__c > List of Address records
    // Story       : STY-04472
    // createdDate : 8/3/2023
    // ********************************************************************************************
    private List<NSP_Address__c> getFilteredContactWorkAddressRecords(List<NSP_Address__c> lstRecords){
        Set<Id> setContactID = new Set<Id>();
        Set<Id> setSCCContactID = new Set<Id>();
        Map<Id, NSP_Sub_Client_Contact__c> contactIdSubClient = new Map<Id, NSP_Sub_Client_Contact__c>();
        List<NSP_Address__c> filteredRecords = new List<NSP_Address__c>();
        Integer addressSize = 0;
        for(NSP_Address__c address : lstRecords){
            setContactID.add(address.NSP_Contact__c);
        }
        for(NSP_Sub_Client_Contact__c subClientContact : [
            Select Id, NSP_Employee_Status__c, NSP_Contact__c, NSP_Contact__r.AccountId
            from NSP_Sub_Client_Contact__c
            where NSP_Employee_Status__c =: NSP_ServiceConstants.PRIMED_STATUS and NSP_Contact__c IN : setContactID
            ])
        {
            setSCCContactID.add(subClientContact.NSP_Contact__c);
        }
        while (addressSize < lstRecords.size()){
            NSP_Address__c addressRecord = lstRecords.get(addressSize);
            if(!setSCCContactID.contains(addressRecord.NSP_Contact__c)){
                lstRecords.remove(addressSize);
            } else {
                addressSize++;
            }
        }
        if(!lstRecords.isEmpty()){
            filteredRecords = getFilteredContactWorkAddressBasedOnAsset(lstRecords);
        }
        return filteredRecords;
    }

    // ********************************************************************************************
    // MethodName  : getFilteredContactWorkAddressBasedOnAsset
    // Description : This method will filter address records based on WO asset for that particular account on address records
    // Params      : List < NSP_Address__c > List of Address records
    // Story       : STY-04472
    // createdDate : 8/3/2023
	// ********************************************************************************************
    private List<NSP_Address__c> getFilteredContactWorkAddressBasedOnAsset(List<NSP_Address__c> lstAddress){
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setWoAssetAccountIds = new Set<Id>();
        for (NSP_Address__c oAddress : lstAddress) {
            setAccountIds.add(oAddress.NSP_Contact__r.AccountId);
        }
        for(Asset oAsset : [
            SELECT Id, AccountId FROM Asset
            WHERE AccountId IN: setAccountIds
            AND RecordType.DeveloperName =: NSP_ServiceConstants.WO_ASSET_RECORDTYPE
            AND NSP_AIMS_First_Pay_Date__c = NULL
            AND NSP_Account_Status__c= :NSP_ServiceConstants.ASSET_ACTIVE_STATUS
            ])
        {
            setWoAssetAccountIds.add(oAsset.AccountId);
        }
        Integer addressSize = 0;
        while (addressSize < lstAddress.size()){
            NSP_Address__c workAddress = lstAddress.get(addressSize);
            if(!setWoAssetAccountIds.contains(workAddress.NSP_Contact__r.AccountId)){
                lstAddress.remove(addressSize);
            } else {
                addressSize++;
            }
        }
        return lstAddress;
    }

    private List<NSP_Sub_Client_Contact_Address__c> getFilteredContactAddress(List<NSP_Sub_Client_Contact_Address__c> lstAddress){
        Set<Id> setAccountIds = new Set<Id>();
        Set<Id> setWoAssetAccountIds = new Set<Id>();
        for (NSP_Sub_Client_Contact_Address__c oAddress : lstAddress) {
            setAccountIds.add(oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c);
        }
        for(Asset oAsset : [SELECT Id, AccountId FROM Asset
                            WHERE AccountId IN: setAccountIds
                            AND RecordType.DeveloperName =: NSP_ServiceConstants.WO_ASSET_RECORDTYPE
                            AND NSP_AIMS_First_Pay_Date__c = NULL
                            AND NSP_Account_Status__c= :NSP_ServiceConstants.ASSET_ACTIVE_STATUS]){
            setWoAssetAccountIds.add(oAsset.AccountId);
        }

        Integer addressSize = 0;
        while (addressSize < lstAddress.size()){
            NSP_Sub_Client_Contact_Address__c ref = lstAddress.get(addressSize);
            if(!setWoAssetAccountIds.contains(ref.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c)){
                lstAddress.remove(addressSize);
            } else {
                addressSize++;
            }
        }

        return lstAddress;
    }

    // ********************************************************************************************
    // MethodName  : getContactAddress
    // Description : This method will create a map for accWithAddressStates and accWithAddressZipCodes
    // Params      : List < NSP_Address__c > List of Address records
    // Story       : STY-04472
    // createdDate : 8/3/2023
    // ********************************************************************************************
    private void getContactAddress(List<NSP_Address__c> lstAddress) {
        for (NSP_Address__c oAddress : getFilteredContactWorkAddressRecords(lstAddress)) {
            String state = oAddress.NSP_State__c;
            String postalCode = oAddress.NSP_Postal_Code_New__c;
            setAccountIds.add(oAddress.NSP_Contact__r.AccountId);
            if (stateWithRegulatedArea.containsKey(state)) {
                if (accIdWithStateAddress.containsKey(oAddress.NSP_Contact__r.AccountId)) {
                    accWithAddressStates.get(oAddress.NSP_Contact__r.AccountId).add(state);
                    accIdWithStateAddress.get(oAddress.NSP_Contact__r.AccountId)
                        .add(
                            new Address(
                                oAddress.Id,
                                oAddress.NSP_Contact__r.AccountId,
                                oAddress.NSP_Contact__c,
                                state,
                                oAddress.NSP_City__c,
                                postalCode
                            )
                        );
                } else {
                    accIdWithStateAddress.put(
                        oAddress.NSP_Contact__r.AccountId,
                        new List<Address>{
                            new Address(
                                oAddress.Id,
                                oAddress.NSP_Contact__r.AccountId,
                                oAddress.NSP_Contact__c,
                                state,
                                oAddress.NSP_City__c,
                                postalCode
                            )
                        }
                    );
                    accWithAddressStates.put(oAddress.NSP_Contact__r.AccountId,new Set<String>{ state });
                }
            }
            //Zip matches with the regulated Area
            if (zipCodesWithRegArea.containsKey(postalCode)) {
                if (accIdWithZipAddress.containsKey(oAddress.NSP_Contact__r.AccountId)) {
                    accIdWithZipAddress.get(oAddress.NSP_Contact__r.AccountId)
                        .add(
                            new Address(
                                oAddress.Id,
                                oAddress.NSP_Contact__r.AccountId,
                                oAddress.NSP_Contact__c,
                                state,
                                oAddress.NSP_City__c,
                                postalCode
                            )
                        );
                    accWithAddressZipCodes.get(oAddress.NSP_Contact__r.AccountId).add(postalCode);
                } else {
                    accIdWithZipAddress.put(
                        oAddress.NSP_Contact__r.AccountId,
                        new List<Address>{
                            new Address(
                                oAddress.Id,
                                oAddress.NSP_Contact__r.AccountId,
                                oAddress.NSP_Contact__c,
                                state,
                                oAddress.NSP_City__c,
                                postalCode
                            )
                        }
                    );
                    accWithAddressZipCodes.put(oAddress.NSP_Contact__r.AccountId,new Set<String>{ postalCode });
                }
            }
        }
    }

    private void getSubClientContactAddress(List<NSP_Sub_Client_Contact_Address__c> lstSubClientContactAddress){
        // SubClient ContactAddress object that has Regulated Area State or City/ZipCode matched
        for (NSP_Sub_Client_Contact_Address__c oAddress : getFilteredContactAddress(lstSubClientContactAddress)) {

            String state = oAddress.NSP_State__c;
            setAccountIds.add(oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c);

            //State matches with the regulated Area
            if (stateWithRegulatedArea.containsKey(state)) {
                if (accIdWithStateAddress.containsKey(oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c)) {
                    accWithAddressStates.get(oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c).add(state);
                    accIdWithStateAddress.get(oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c)
                        .add(
                            new Address(
                                oAddress.NSP_Address__c,
                                oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c,
                                oAddress.NSP_Contact__c,
                                state,
                                oAddress.NSP_City__c,
                                oAddress.NSP_Postal_Code_New__c
                            )
                        );
                } else {
                    accIdWithStateAddress.put(
                        oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c,
                        new List<Address>{
                            new Address(
                                oAddress.NSP_Address__c,
                                oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c,
                                oAddress.NSP_Contact__c,
                                state,
                                oAddress.NSP_City__c,
                                oAddress.NSP_Postal_Code_New__c
                            )
                        }
                    );
                    accWithAddressStates.put( oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c, new Set<String>{ state } );
                }
            }

            //Zip matches with the regulated Area
            if (zipCodesWithRegArea.containsKey(oAddress.NSP_Postal_Code_New__c)) {
                if (accIdWithZipAddress.containsKey(oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c)) {
                    accIdWithZipAddress.get(oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c)
                        .add(
                            new Address(
                                oAddress.NSP_Address__c,
                                oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c,
                                oAddress.NSP_Contact__c,
                                state,
                                oAddress.NSP_City__c,
                                oAddress.NSP_Postal_Code_New__c
                            )
                        );
                    accWithAddressZipCodes.get( oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c ).add(oAddress.NSP_Postal_Code_New__c);
                } else {
                    accIdWithZipAddress.put(
                        oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c,
                        new List<Address>{
                            new Address(
                                oAddress.NSP_Address__c,
                                oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c,
                                oAddress.NSP_Contact__c,
                                state,
                                oAddress.NSP_City__c,
                                oAddress.NSP_Postal_Code_New__c
                            )
                        }
                    );
                    accWithAddressZipCodes.put( oAddress.NSP_Sub_Client_Contact__r.NSP_Sub_Client__r.NSP_Account__c, new Set<String>{ oAddress.NSP_Postal_Code_New__c } );
                }
            }
        }
    }

    // newAccountRegulatedArea prepare new account Regulated area to Insert
    private void newAccountRegulatedArea(Address address) {
        NSP_Account_Regulated_area__c accRegulatedArea = new NSP_Account_Regulated_area__c();
        accRegulatedArea.NSP_Account__c = address.AccountId;
        if (stateWithRegulatedArea.containsKey(address.State)) {
            accRegulatedArea.NSP_Regulated_Area__c = stateWithRegulatedArea.get(address.State)?.Id;
        } else if (zipCodesWithRegArea?.containsKey(address.zipCode)) {
            accRegulatedArea.NSP_Regulated_Area__c = zipCodesWithRegArea.get(address.zipCode)?.Id;
        }
        String accRegId = accRegulatedArea.NSP_Account__c + '_' + accRegulatedArea.NSP_Regulated_Area__c;
        if (!setAccRegArea.contains(accRegId)) {
            setAccRegArea.add(accRegId);
            accRegulatedAreaList.add(accRegulatedArea);
        }
    }

    // newCase preare new case to Insert
    private void newCase(String accountId, String caseSubject) {
        Map<String,Id> roleMap = new Map<String,Id>();
        Case newCase = new Case();
        newCase.RecordTypeId = recordTypePEOID;
        newCase.AccountId = accountId;
        newCase.NSP_Category__c = NSP_ServiceConstants.INFRASTRUCTURE;
        newCase.NSP_SubCategory__c = NSP_ServiceConstants.SUBCATEGORY_PAID_SICK_LEAVE;
        newCase.Status = NSP_SalesConstants.OPEN;
        newCase.Regulated_Batch_Date__c=system.today();
        if(accountWithTeamMemberId?.get(accountId)!=null){
            roleMap.putAll(accountWithTeamMemberId?.get(accountId));
        }
        if ( newCase.OwnerId == null ) {
            if ( ( roleMap?.containsKey(NSP_SalesConstants.HRSpecialist) || roleMap?.containsKey(NSP_ServiceConstants.BUS_TEAM_HRSP_CL) ) && accountWithRoleMap.containsKey(accountId) ) {
                newCase.OwnerId = roleMap?.get(accountWithRoleMap.get(accountId));
            }else if ( roleMap?.containsKey(NSP_SalesConstants.HRSpecialist) ) {
                newCase.OwnerId = roleMap?.get(NSP_ServiceConstants.HRSpecialist);
            }else if ( roleMap?.containsKey(NSP_ServiceConstants.BUS_TEAM_HRSP_CL) ) {
                newCase.OwnerId = roleMap?.get(NSP_ServiceConstants.BUS_TEAM_HRSP_CL);
            }
        }
        newCase.OwnerId = newCase.OwnerId!=null ? newCase.OwnerId : lstHRImplementationqueue[0].Id;
        newCase.Subject = caseSubject?.replace('/,', '/');
        String caseString =
            newCase.RecordTypeId + '_' + newCase.AccountId + '_' + newCase.NSP_Category__c +
            '_' + newCase.Status + '_' + newCase.OwnerId +'_'+ newCase.Subject;
        if (!setCases.Contains(caseString)) {
            setCases.add(caseString);
            lstCases.add(newCase);
        }
    }

    private void updateCase(String caseId, String accId, String caseSubject) {
        Case updateCaseRecord = new Case();
        updateCaseRecord.id =caseId;
        updateCaseRecord.subject =caseSubject;
        updateCaseRecord.AccountId = accId;
        lstCasesToUpdate.add(updateCaseRecord);
    }

    // get Account Team Records based on the AccountId and Role
    private void getAccountTeams() {
        List<String> QUEUE_FIELDS = new List<String>{'Id','DeveloperNAME'};
        String queryQueue = new NSP_QueryBuilder('Group', QUEUE_FIELDS)
            .addFilter('Type', NSP_ServiceConstants.GroupType)
            .addFilter('DeveloperNAME', NSP_ServiceConstants.HR_CLIENT_IMPLEMENTATION_QUEUE)
            .addLimit(1).build();
        lstHRImplementationqueue = Database.query(queryQueue);
        for (NSP_Account_Team__c accTeamMember : selector.getAccountTeamRecords()) {
            if(accTeamMember.NSP_Account__r.NSP_Service_Segment__c == NSP_ServiceConstants.MIDDLEMARKET || accTeamMember.NSP_Account__r.NSP_Service_Segment__c == NSP_ServiceConstants.MMEAssetSegment){
                if ( !accountWithTeamMemberId.containsKey(accTeamMember.NSP_Account__c) ) {
                    accountWithTeamMemberId.put(accTeamMember.NSP_Account__c, new Map<String,Id>());
                }
                accountWithTeamMemberId.get(accTeamMember.NSP_Account__c).put(accTeamMember.NSP_Role__c, accTeamMember.NSP_User__c);
            }
            if ( accTeamMember.NSP_Primary__c && !accountWithRoleMap.containsKey(accTeamMember.NSP_Account__c) ) {
                if ( accTeamMember.NSP_Role__c == NSP_SalesConstants.HRSpecialist ) {
                    accountWithRoleMap.put(accTeamMember.NSP_Account__c, accTeamMember.NSP_Role__c);
                } else if ( accTeamMember.NSP_Role__c == NSP_ServiceConstants.BUS_TEAM_HRSP_CL ) {
                    accountWithRoleMap.put(accTeamMember.NSP_Account__c, accTeamMember.NSP_Role__c);
                }
            }
        }
    }

    @TestVisible
    private without sharing class Selector {

        // get Account Team Records based on the AccountId and Role
        public List<NSP_Account_Team__c> getAccountTeamRecords() {
            String accTeamQuery = new NSP_QueryBuilder(
                    'NSP_Account_Team__c',
                    new List<String> { 'Id', 'NSP_Role__c', 'NSP_Account__c', 'NSP_Account__r.NSP_Service_Segment__c', 'NSP_Email__c', 'NSP_User__c', 'NSP_Primary__c' }
                )
                .setSecurityEnforce(false)
                .build();
            accTeamQuery += ' WHERE NSP_Account__c IN :setAccountIds AND NSP_User__c != NULL '+
                ' ORDER BY NSP_Primary__c ASC';
            return Database.query(accTeamQuery);
        }

        // Accounts which has existing AccountRegulatedArea and Cases
        public  List<Account> getAccounts() {
            String strSubject = CASE_SUBJECT + '%';
            return [
                SELECT Id, Name, Type,  NSP_Account_Status__c, NSP_First_Pay_Date__c,
                    (SELECT Id, AccountId, Subject
                        FROM Cases
                        WHERE NSP_Category__c = :NSP_ServiceConstants.INFRASTRUCTURE AND Subject LIKE : strSubject),
                    (SELECT Id, NSP_Account__c, NSP_State__c, NSP_City__c, NSP_Regulated_Area__r.NSP_Zip_Code__c
                        FROM Account_Regulated_areas__r)
                FROM Account
                WHERE Id IN :setAccountIds
            ];
        }

        // AccountRegulatedArea based on Inserted AccountIds
        public  List<NSP_Account_Regulated_area__c> getAccountsRegulatedAreaRecords(Set<Id> setAccRegAreas ) {
            String query = new NSP_QueryBuilder(
                            'NSP_Account_Regulated_area__c',
                            new List<String> { 'Id', 'NSP_Account__c', 'NSP_City__c', 'NSP_State__c', 'NSP_Regulated_Area__r.NSP_Zip_Code__c' }
                        )
                        .addFilter('Id', new List<Id>(setAccRegAreas) , NSP_QueryBuilder.Operator.INCLUDES)
                        .build();
            return Database.Query(query);
        }
        public  List<Case> getExistingCase(Set<String> accid ) {
            return [ SELECT Subject, AccountId, Id, Regulated_Batch_Date__c FROM Case Where Regulated_Batch_Date__c = Today ];
        }

    }

    public void finish(Database.BatchableContext bc) {
        counter++;
        if(counter <= 1){
            Map<String,Object> data = new Map<String,Object>{
                'counter' => counter,
                'setRegulatedStates'=> setRegulatedStates,
                'stateWithRegulatedArea'=> stateWithRegulatedArea,
                'zipCodesWithRegArea'=> zipCodesWithRegArea
            };
            NSP_AccountRegulatedAreaBatch batchObject = new NSP_AccountRegulatedAreaBatch(data);
            Database.executeBatch(batchObject, 2000);
        }
    }

    class Address {
        String id;
        String accountId;
        String contactId;
        String state;
        String city;
        String zipCode;

        Address( String id, String accountId, String contactId, String state, String city, String zipCode ) {
            this.id = id;
            this.accountId = accountId;
            this.contactId = contactId;
            this.state = state;
            this.city = city;
            this.zipCode = zipCode;
        }
    }
}
//