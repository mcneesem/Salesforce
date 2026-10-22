public with sharing class NSP_ContactTriggerHelper {
    // test w/ NSP_ContactTriggerHelperTest (91%)

    public static final String INSPERITYROLE = 'Insperity';
    public static final String CUSTOMERROLE = 'Customer';
    public static final String COMMUNITYLICENSE = 'Customer Community';
    public static final Id RESOURCE_REC_TYPE_ID = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CONTACT_OBJECT, 'Resource');
    public static final Id NEW_CON_REC_TYPE_ID = NSP_GenericRecordType.getRecordTypeId(NSP_ServiceConstants.CONTACT_OBJECT,'New_Contact_Record_Type');
    public static final List<String> ALLOWED_PROFILES = new List<String>{'BPS Service','Contact Center','PEO Service','Retirement Services'};
    public static final String WORK_CALENDAR_US40 ='US 40';

    //
    // Iterates throught the list of new Contact and passes the required attributes to other methods.
    // @param newList List of New Contact.
    // @param newMap List of New Contact.
    // @return void
    //
    //
    public void beforeInsertDirector( List<Contact> newList ) {
        //STY-02849/DF-05013 - Default Resource Fields on manually created contacts - start
        //Modified as part of SOQL fix 228901
        String loggedInUserProfileName = NSP_ContactTriggerHelper.loggedInUserProfileName;
        Id regionId, workCalenderId = null;
        //Modified as part of SOQL fix 228901
        if( loggedInUserProfileName != null && ALLOWED_PROFILES.contains(loggedInUserProfileName) ){
            regionId = getRegionId();
            workCalenderId = getWorkCalendarId();
        }
        //STY-02849/DF-05013 - Default Resource Fields on manually created contacts - end

        for(Contact conObj : newList){
            if(conObj.recordTypeId == NEW_CON_REC_TYPE_ID){
                conObj.recordTypeId = RESOURCE_REC_TYPE_ID; // Added as  part of STY-02840
            }
            conObj.NSP_isContactInsertion__c = true;

            //STY-02849/DF-05013 - Default Resource Fields on manually created contacts - start
            //modified as part of SOQL fix 228901
            if( loggedInUserProfileName != null && ALLOWED_PROFILES.contains(loggedInUserProfileName) ){
                conObj.pse__Is_Resource_Active__c = true;
                conObj.pse__Is_Resource__c = true;
                conObj.pse__Region__c = regionId;
                conObj.pse__Work_Calendar__c = workCalenderId;
            }
        }

        try {
            Set<Id> sUserIds = new Set<Id>();
            List<Contact> lContacts = new List<Contact>();
            for(Contact conObj : newList ){
                // UPDATE RESOURCE ROLE
                if(conObj.pse__Salesforce_User__c != null){
                    sUserIds.add(conObj.pse__Salesforce_User__c);
                    lContacts.add(conObj);
                }
            }
            updateClientRefTaskDate(newList,null);
            updateSSNLast4(newList,null);
            if(sUserIds.size() > 0){
                updateContactRoles(sUserIds,lContacts);
            }
        } catch ( Exception e ) {
            NSP_ContactTriggerHelper.handleException( e , 'beforeInsertDirector' );
        }

        //Format Phone number
        //modified as part of SOQL fix 228901
        if (!CustomPermissionController.checkUserPermission( 'Integration_User_Data_Migration', UserInfo.getUserId() )){
            updatePhoneNum(newList,null);
            setSalesOfficeDetails(newList,null);
        }
    }

    //
    // Iterates throught the list of new Contact and passes the required attributes to other methods.
    // @param newList List of New Contact.
    // @param newMap List of New Contact.
    // @return void
    //
    public void afterInsertDirector( List<Contact> newList , Map<Id,Contact > newMap ) {
        //Modified as part of SOQL fix 228901
        if (!CustomPermissionController.checkUserPermission( 'Integration_User_Data_Migration', UserInfo.getUserId() )){
            Set<Id> contactIdSet = new Set<Id>();
            List<Contact> clientRefernceContactList = new List<Contact>();
            for ( Contact conObj : newList ) {
                if ( conObj.NSP_Client_Reference__c ) {
                    clientRefernceContactList.add( conObj );
                }
                contactIdSet.add( conObj.Id );
            }
            if ( !contactIdSet.isEmpty()
                && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() ) // prevent LimitExceptions...
                )
            {
                NSP_ContactTriggerHelper.updateWorkPhoneEmailOnACR( contactIdSet );
            }
            if ( !clientRefernceContactList.isEmpty() ) {
                this.createTaskforClientReference( clientRefernceContactList );
            }
        }
        if (newList != null && !newList.isEmpty() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
            System.enqueueJob(
                new QueueableTermFormJunctionObjects(
                    newList,
                    null,
                    NSP_ServiceConstants.INSERT_TRIGGER
                )
            );
        }
    }

    //
    // Iterates throught the list of new Contact and passes the required attributes to other methods.
    // @param newList List of New Contact.
    // @param newMap List of New Contact.
    // @return void
    //
    public void beforeUpdateDirector( Map<Id,Contact> newMap , Map<Id,Contact> oldMap ) {
        try {
            Set<Id> sUserIds = new Set<Id>();
            List<Contact> lContacts = new List<Contact>();
            for ( Contact conObj : newMap.values() ) {
                // update role filter...
                if ( conObj.pse__Salesforce_User__c != null
                    && conObj.pse__Salesforce_User__c != oldMap.get( conObj.Id ).pse__Salesforce_User__c
                    )
                {
                    sUserIds.add( conObj.pse__Salesforce_User__c );
                    lContacts.add( conObj );
                }
            }

            updateClientRefTaskDate( newMap.values() , oldMap );
            updateSSNLast4( newMap.values() , oldMap );

            if ( !sUserIds.isEmpty() ) {
                updateContactRoles( sUserIds , lContacts );
            }
            if (!CustomPermissionController.checkUserPermission( 'Integration_User_Data_Migration', UserInfo.getUserId() )){
                // format phone number...
                updatePhoneNum( newMap.Values() , oldMap );
                // prepare account for integration sync...
                Set<Id> accountIdSetToUpdateResyncFlag = new Set<Id>();
                NSP_SObjectUpdateTriggerHelper sObjectUpdateObj = new NSP_SObjectUpdateTriggerHelper();
                accountIdSetToUpdateResyncFlag = sObjectUpdateObj.fetchUpdFieldsLst(
                    NSP_IntegrationConstants.SOBJECT_CONTACT ,
                    newMap ,
                    oldMap
                );
                IntegrationSyncController.setReadyForIntegrationSync(
                    accountIdSetToUpdateResyncFlag ,
                    Contact.getSObjectType()
                );
                // handle office details...
                setSalesOfficeDetails( newMap.values() , oldMap );
            }
        } catch ( Exception e ) {
            NSP_ContactTriggerHelper.handleException( e , 'beforeUpdateDirector' );
        }
    }

    //
    // Iterates through the list of new Contact and passes the required attributes to other methods.
    // @param newList List of New Contact.
    // @param newMap List of New Contact.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,Contact> newMap , Map<Id,Contact> oldMap ) {
        try {
            //Modified as part of SOQL fix 228901
            if (!CustomPermissionController.checkUserPermission( 'Integration_User_Data_Migration', UserInfo.getUserId() )){
                List<Contact> clientRefernceContactList = new List<Contact>();
                Set<Id> contactIdSet = new Set<Id>();
                NSP_ContactTriggerHelper.populateContacts(newMap, oldMap, clientRefernceContactList, contactIdSet);
                if ( !contactIdSet.isEmpty()
                    && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() ) // prevent LimitExceptions...
                    )
                {
                    NSP_ContactTriggerHelper.updateWorkPhoneEmailOnACR( contactIdSet );
                }
                if ( !clientRefernceContactList.isEmpty() ) {
                    this.createTaskforClientReference( clientRefernceContactList );
                }
            }
            NSP_ContactTriggerHelper.queueNewContacts(newMap, oldMap);
        } catch ( Exception e ) {
            NSP_ContactTriggerHelper.handleException( e , 'afterUpdateDirector' );
        }
   }

   // helper method to defeat sonar cognitive complexity
    private static void queueNewContacts(Map<Id,Contact> newMap, Map<Id,Contact> oldMap){
        if(newMap != null){
            List<Contact> queueNewContact = new List<Contact>();
            Map<Id,Contact> queueOldMap = new Map<Id,Contact>();
            Set<Id> processedContact = new Set<Id>();
            for(Contact conObj : newMap.values()){
                Contact oldContact = ( ( oldMap != null ) ? oldMap.get(conObj.Id) : null );
                if(oldContact != null && conObj.AccountId !=null && conObj.AccountId != oldContact.AccountId && !processedContact.contains(conObj.Id))
                {
                    queueOldMap.put(conObj.Id,oldContact);
                    queueNewContact.add(conObj);
                    processedContact.add(conObj.Id);
                }
            }
            if (!queueNewContact.isEmpty() && Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() ) {
                System.enqueueJob(
                    new QueueableTermFormJunctionObjects(
                        queueNewContact,
                        queueOldMap,
                        NSP_ServiceConstants.UPDATE_TRIGGER
                    )
                );
           }
        }
    }

    // helper method to defeat sonar cognitive complexity
    private static void populateContacts(Map<Id,Contact> newMap , Map<Id,Contact> oldMap,
        List<Contact> clientRefernceContactList, Set<Id> contactIdSet){
        for ( Contact conObj : newMap.values() ) {
            Contact oldContact = ( ( oldMap != null ) ? oldMap.get( conObj.Id ) : null );
            if ( oldContact != null ) {
                if ( ( conObj.NSP_Client_Reference__c != oldContact.NSP_Client_Reference__c )
                    && conObj.NSP_Client_Reference__c
                    )
                {
                    clientRefernceContactList.add( conObj );
                }
                if ( ( oldContact.NSP_Work_Phone__c != conObj.NSP_Work_Phone__c )
                    || ( oldContact.NSP_Work_email__c != conObj.NSP_Work_email__c )
                    || ( oldContact.NSP_Employee_Status__c != conObj.NSP_Employee_Status__c )
                    || ( oldContact.NSP_Status_Date__c != conObj.NSP_Status_Date__c )
                    || ( oldContact.NSP_Job_Title__c != conObj.NSP_Job_Title__c )
                    )
                {
                    contactIdSet.add( conObj.Id );
                }
            }
        }
    }

    //
    // Iterates throught the list of new Contact and passes the required attributes to other methods.
    // @param newList List of New Contact.
    // @param newMap List of New Contact.
    // @return void
    //
    public void createTaskforClientReference( List<Contact> clientReferenceContactList ) {
        List<Task> taskList = new List<Task>();
        for(Contact conObj : clientReferenceContactList){
            Task taskObj = new Task();
            taskObj.Type = NSP_SalesConstants.CLIENT_REFERENCE_TASKTYPE;
            taskObj.Status = NSP_SalesConstants.COMPLETED;
            taskObj.whoId = conObj.Id;
            taskObj.Subject = System.Label.NSP_Client_Reference_Task_Subject;
            taskList.add(taskObj);
        }
        insert taskList;
    }

    //
    // Method Name : updatePhoneNum
    // Description : Method to format Phone number on update
    // @param newContactList,contactOldMap.
    // @return void
    //
    public void updatePhoneNum( List<Contact> newContactList , Map<Id,Contact> contactOldMap ) {
        for(Contact newContact : newContactList ) {
            Contact oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id) : null;
            if((Trigger.isInsert || (oldContact != null && newContact.Phone != oldContact.Phone)) && newContact.Phone != null ) {
                Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
                String initialNum = nonAlphanumeric.matcher(newContact.Phone).replaceAll('').replace(NSP_ServiceConstants.EXT,'x');
                Pattern numFormat10Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})');
                Pattern numFormat10Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})(x\\d{3})?$');
                Pattern numFormat11Dig;
                Pattern numFormat11Ext;
                if(initialNum.startsWith('1')) {
                    numFormat11Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})');
                    numFormat11Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})(x\\d{3})?$');
                    if(numFormat11Dig.matcher(initialNum).matches() || numFormat11Ext.matcher(initialNum).matches()) {
                        newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                    }
                }
                if(numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                    newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                }
                else {
                    newContact.NSP_Formatted_Phone_Num__c = newContact.Phone;
                }
            }
            if(newContact.Phone == null){
                newContact.NSP_Formatted_Phone_Num__c = null;
            }
        }
    }

    //
    // Method Name : formatPhoneNumbers
    // Description : Method to format Phone number
    // @param String input called from updatePhoneNum.
    // @return String
    //
    public String formatPhoneNumbers( String input ) {
        String requiredOutput;
        input = input.replaceAll('\\(', '').replaceAll('\\)', '');
        input = input.replaceAll('-', '');
        String trimString = input.deleteWhitespace();
        List<String> parts = new List<String>();
        if(trimString.contains(NSP_ServiceConstants.EXT)) {
            parts = trimString.split(NSP_ServiceConstants.EXT);
            requiredOutput = formatCommonPattern(parts.get(0).trim())+ ' x'+parts.get(1);
        } else  if(trimString.contains('x')) {
            parts = trimString.split('x');
            requiredOutput = formatCommonPattern(parts.get(0).trim())+ ' x'+parts.get(1);
        } else {
            requiredOutput = formatCommonPattern(trimString);
        }
        return requiredOutput;
    }

    //
    // Method Name : formatCommonPattern
    // Description : Method to construct common pattern and format Phone number
    // @param String input called from formatPhoneNumbers.
    // @return String
    //
    public String formatCommonPattern( String input ) {
        if(input.length() == 10){
            String number1 = input.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '($1) $2-$3');
            return number1;
        }
        String substring = input.length() > 10 ? input.substring(input.length() - 10) : input;
        String codeNumber = substring.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '+1 ($1) $2-$3');
        return codeNumber;
    }

    //
    // Description: This method sets sales office details from user
    // @param: contactList
    // @return: void
    //
    public void setSalesOfficeDetails( List<Contact> newList , Map<Id, Contact> contactOldMap ) {
        set<Id> ownerIdSet = new set<Id>();
        for(Contact newContact: newList) {
            Contact oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id) : null;
            if((Trigger.isInsert || (oldContact != null && newContact.OwnerId != oldContact.OwnerId)) && newContact.OwnerId != null) {
                ownerIdSet.add(newContact.OwnerId);
            }
        }

        if(ownerIdSet.Size() > 0){
            Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user WHERE Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
            for(Contact newContact: newList) {
                Contact oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id):null;
                if((Trigger.isInsert || newContact.OwnerId != oldContact.OwnerId) && newContact.OwnerId != null && userIdMap.containsKey(newContact.OwnerId)){
                    user eachUser = userIdMap.get(newContact.OwnerId);
                    newContact.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                    newContact.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newContact.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                }
            }
        }
    }

    public void updateClientRefTaskDate(List<Contact> newList,Map<Id, Contact> contactOldMap){
        for(Contact newContact: newList){
            Contact oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id) : null;
            if( newContact.NSP_Client_Reference__c && (Trigger.isInsert || newContact.NSP_Client_Reference__c != oldContact.NSP_Client_Reference__c) ) {
                newContact.NSP_Client_Reference_Task_Date__c = System.today();
            }
        }
    }

    public void updateSSNLast4(List<Contact> newList,Map<Id, Contact> contactOldMap){
        for(Contact newContact: newList){
            Contact oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id) : null;
            if( (Trigger.isInsert || newContact.NSP_SSN__c != oldContact.NSP_SSN__c) ) {
                newContact.NSP_Last_4Digit_Of_SSN__c = null; // reset the last 4 digits...
                if ( String.isNotBlank( newContact.NSP_SSN__c ) && ( newContact.NSP_SSN__c.length() > 4 ) ) {
                    newContact.NSP_Last_4Digit_Of_SSN__c = newContact.NSP_SSN__c.right( 4 ); // rebuild the last 4 digits...
                }
            }
        }
    }

    // updateContactRoles function definition
    public void updateContactRoles(Set<Id> sUserIds, List<Contact> lContacts){
        Map<Id,User> mUsers = new Map<Id,User>([SELECT Id,Profile.UserLicense.Name FROM User WHERE Id in : sUserIds]);
        for(Contact oContact : lContacts){
            if(mUsers.get(oContact.pse__Salesforce_User__c).Profile.UserLicense.Name == COMMUNITYLICENSE){
                oContact.pse__Resource_Role__c = CUSTOMERROLE;
            }
                else{
                oContact.pse__Resource_Role__c = INSPERITYROLE;
            }
        }
    }

    //
    // @Description: This method describes to update the ACR when ever Contact's Email and Work Phone.
    // @param : Map<Id, Contact> conIdcontactMap
    // @createdDate : 12/13/2022
    // @Story : STY-02840
    // @return void
    //
    @future
    private static void updateWorkPhoneEmailOnACR( Set<Id> contactIdSet ) {
        try {
            Map<Id,Contact> conIdcontactMap = new Map<Id,Contact>();
            for ( Contact con : [
                        SELECT
                            Id ,
                            NSP_isContactInsertion__c ,
                            NSP_Work_email__c ,
                            NSP_Work_Phone__c ,
                            NSP_Employee_Status__c ,
                            NSP_Status_Date__c ,
                            NSP_Job_Title__c
                        FROM Contact
                        WHERE ( Id IN :contactIdSet )
                    ]
                )
            {
                conIdcontactMap.put( con.Id , con );
            }
            List<AccountContactRelation> acrList = new List<AccountContactRelation>();
            List<Contact> conUpdateList = new List<Contact>();
            Id integrationProfileId = '00e4x0000012vOHAAY'; // Profile: Integration User
            Set<Id> seenPrimaryAccountIds = new Set<Id>();
            for ( AccountContactRelation acr : [
                        SELECT
                            Id ,
                            AccountId ,
                            ContactId ,
                            Contact.NSP_isContactInsertion__c ,
                            NSP_Work_Email__c ,
                            NSP_Work_Phone__c ,
                            NSP_Is_Primary__c ,
                            IsDirect ,
                            CreatedById ,
                            CreatedBy.ProfileId
                        FROM AccountContactRelation
                        WHERE (
                            ( ContactId IN :contactIdSet )
                            AND ( isDirect = true )
                            AND ( CreatedBy.ProfileId != :integrationProfileId )
                            AND ( LastModifiedBy.ProfileId != :integrationProfileId )
                        )
                    ]
                )
            {
                if ( conIdcontactMap.containsKey( acr.ContactId )
                    && ( !acr.NSP_Is_Primary__c || seenPrimaryAccountIds.add( acr.AccountId ) )
                    )
                {
                    Contact cont = conIdcontactMap.get( acr.ContactId );
                    cont.NSP_isContactInsertion__c = false;
                    conUpdateList.add( cont );
                    acr.NSP_Work_Email__c = cont.NSP_Work_email__c;
                    acr.NSP_Work_Phone__c = cont.NSP_Work_Phone__c;
                    acr.NSP_Employee_Status__c = cont.NSP_Employee_Status__c;
                    acr.NSP_Status_Date__c = cont.NSP_Status_Date__c;
                    acr.NSP_Job_Title__c = cont.NSP_Job_Title__c;
                    acrList.add( acr );
                }
            }
            if ( !acrList.isEmpty() ) {
                update acrList ; // Don't change to Database.update
            }
            if ( !conIdcontactMap.isEmpty() ) {
                update conUpdateList; // Don't change to Database.update
            }
        } catch ( Exception e ) {
            NSP_ContactTriggerHelper.handleException( e , 'updateWorkPhoneEmailOnACR' );
        }
    }

    //
    // Method Name : getLoggedInUserProfileName
    // Date : 11/08/2023
    // @param
    // @return String profileName
    //
    private static String loggedInUserProfileName {
        public get {
            if( loggedInUserProfileName == null ){
                List<User> autouser = [ SELECT Profile.Name, Alias FROM User WHERE ( Id = :UserInfo.getUserId() ) ];
                if ( !autoUser.isEmpty()){
                    if( autoUser[0].Alias == 'autoproc' )  {
                        loggedInUserProfileName = 'AutoProc';
                    } else{
                        loggedInUserProfileName = autoUser[0].Profile.Name;
                    }
                }
            }
            return loggedInUserProfileName;
        }
        private set;
    }

    //
    // Method Name : getRegionId
    // Description : STY-02849/DF-05013 Method to United State region id
    // @param
    // @return Id
    //
    public Id getRegionId() {
        List<String> regionFields = new List<String>{'Id','Name'};
        String queryRegion = new NSP_QueryBuilder('pse__Region__c', regionFields)
            .addFilter('Name', NSP_ServiceConstants.UnitedStatesRegion).setSecurityEnforce(false).build();
        List<pse__Region__c> regionRecords = Database.query(queryRegion);
        if(regionRecords.size() > 0) {
            return regionRecords[0].id;
        }
        return null;
    }

    //
    // Method Name : getWorkCalendarId
    // Description : STY-02849/DF-05013 Method to work Calender US40 record id
    // @param
    // @return Id
    //
    public Id getWorkCalendarId() {
        List<String> wcFields = new List<String>{'Id','Name'};
        String queryWC = new NSP_QueryBuilder('pse__Work_Calendar__c', wcFields)
            .addFilter('Name', WORK_CALENDAR_US40).setSecurityEnforce(false).build();
        List<pse__Work_Calendar__c> wcRecords = Database.query(queryWC);
        if(wcRecords.size() > 0) {
            return wcRecords[0].id;
        }
        return null;
    }

    // for test code coverage only...
    public static void testHandleException( Exception e , String methodName ) {
        if ( Test.isRunningTest() ) {
            NSP_ContactTriggerHelper.handleException( e , methodName );
        }
    }

    private static void handleException( Exception e , String methodName ) {
        NSP_ErrorLogHandler.logException(
            NSP_ContactTriggerHelper.class.getName() ,
            methodName ,
            e
        );
    }

}
//