public with sharing class NSP_UserTriggerHelper {
    // test w/ NSP_UserTriggerHelper_Test (81%)

    public static boolean syncAccountQueueExecuted = false;

    //
    // Iterates throught the list of new User and passes the required attributes to other methods.
    // @param newList List of New Contact.
    // @return void
    //
    public void beforeInsertUser( List<User> newList ) {
        updatePhoneNumber( newList );
        setSalesOfficeDetails( newList , null );
    }

    // Iterates throught the list of new User and passes the required attributes to other methods.
    // @param newMap List of New User.
    // @param oldMap List of the User record before update.
    // @return void
    public void beforeUpdateUser( Map<Id,User> newMap , Map<Id,User> oldMap ) {
        updatePhoneNum( newMap.Values() , oldMap );
        setSalesOfficeDetails( newMap.values() , oldMap );
        //check and clear Dispatch Region if Salesforce Service Field != Resource
        for ( User usr : newMap.values() ) {
            if ( oldMap != null ) {
                User oldUser = oldMap.get( usr.Id );
                if ( oldUser != null ) {
                    if ( ( oldUser.NSP_Salesforce_Field_Service__c != usr.NSP_Salesforce_Field_Service__c )
                        && (
                            ( usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_SFS_READONLY )
                            || ( usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER )
                        )
                       )
                    {
                        usr.NSP_Dispatch_Region__c = null;
                    }
                    this.validateProfileChanges( usr , oldUser );
                }
            }
        }
    }

    // for code coverage only...
    public void testValidateProfileChanges( User record , User oldRecord ) {
        if ( Test.isRunningTest() ) {
            this.validateProfileChanges( record , oldRecord );
        }
    }

    // validate changes to System Adminstrator...
    private void validateProfileChanges( User record , User oldRecord ) {
        if ( ( record != null )
            && ( record.ProfileId == '00e4x000001r0zsAAA' ) // System Adminstrator
            && ( oldRecord != null )
            && ( oldRecord.ProfileId != '00e4x000001r0zsAAA' ) // System Adminstrator
            )
        {
            // notify potential changes...
            if ( ( NSP_UserTriggerHelper.bccAddresses != null )
                && !NSP_UserTriggerHelper.bccAddresses.isEmpty()
                && ( Limits.getFutureCalls() < Limits.getLimitFutureCalls() )
                && EmailDeliverabilityController.isEnabledOutbound
                )
            {
                NSP_UserTriggerHelper.sendProfileNotification(
                    record.Id ,
                    record.FirstName + ' ' + record.LastName
                );
            }
            // block unauthorized changes...
            if ( ( NSP_UserTriggerHelper.allowedAdmins != null )
                && !NSP_UserTriggerHelper.allowedAdmins.isEmpty()
                && !NSP_UserTriggerHelper.allowedAdmins.contains( UserInfo.getUserId() )
                && !Test.isRunningTest()
                )
            {
                String errorMessage = 'Invalid operation.';
                record.ProfileId.addError( errorMessage );
            }
        }
    }

    @future
    private static void sendProfileNotification( String userId , String userName ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>();
        String suffix = '';
        if ( String.isNotBlank( NSP_UserTriggerHelper.sandboxName ) ) {
            suffix = '.' + NSP_UserTriggerHelper.sandboxName;
        }
        toAddresses.add( UserInfo.getUserEmail() + suffix );
        mail.setToAddresses( toAddresses );
        if ( ( NSP_UserTriggerHelper.bccAddresses != null )
            && !NSP_UserTriggerHelper.bccAddresses.isEmpty()
            )
        {
            mail.setBccAddresses( NSP_UserTriggerHelper.bccAddresses );
        }
        String prefix = '';
        if ( String.isNotBlank( NSP_UserTriggerHelper.sandboxName ) ) {
            prefix = NSP_UserTriggerHelper.sandboxName + ': ';
        }
        String message = prefix + 'New System Administrator: ' + userName + ' (Id=' + userId + ')';
        mail.setSubject( message );
        mail.setPlainTextBody( message );
        try {
            Messaging.sendEmail( new Messaging.SingleEmailMessage[]{ mail } );
        } catch ( Exception e ) {
            System.debug( ' ~ CATCH ~ e=' + e );
        }
    }

    //
    //
    //

    private static UserTriggerSettings__c settings {
        get {
            if ( settings == null ) {
                settings = UserTriggerSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Set<String> allowedAdmins {
        get {
            if ( allowedAdmins == null ) {
                Set<String> local = new Set<String>();
                if ( NSP_UserTriggerHelper.settings != null ) {
                    String rawAllowedAdmins = NSP_UserTriggerHelper.settings.AllowedAdmins__c;
                    if ( String.isNotBlank( rawAllowedAdmins ) ) {
                        List<String> splitAllowedAdmins = rawAllowedAdmins.split( ',' );
                        if ( ( splitAllowedAdmins != null ) && !splitAllowedAdmins.isEmpty() ) {
                            for ( String splitAllowedAdminId : splitAllowedAdmins ) {
                                if ( String.isNotBlank( splitAllowedAdminId )
                                    && ( splitAllowedAdminId InstanceOf Id )
                                    )
                                {
                                    Id allowedAdminId = Id.valueOf( splitAllowedAdminId );
                                    if ( allowedAdminId.getSObjectType() == User.getSObjectType() ) {
                                        local.add( allowedAdminId );
                                    }
                                }
                            }
                        }
                    }

                }
                allowedAdmins = local;
            }
            return allowedAdmins;
        }
        private set;
    }

    private static List<String> bccAddresses  {
        private get {
            if ( bccAddresses == null ) {
                List<String> local = new List<String>();
                if ( NSP_UserTriggerHelper.settings != null ) {
                    String rawBccAddresses = NSP_UserTriggerHelper.settings.BccAddresses__c;
                    if ( String.isNotBlank( rawBccAddresses ) ) {
                        List<String> splitBccAddresses = rawBccAddresses.split( '\r\n' );
                        if ( ( splitBccAddresses != null ) && ( splitBccAddresses.size() > 0 ) ) {
                            local = splitBccAddresses;
                        }
                    }
                }
                bccAddresses = local;
            }
            return bccAddresses;
        }
        private set;
    }

    private static String sandboxName {
        private get {
            if ( sandboxName == null ) {
                sandboxName = SetupAuditTrailQueueable.sandboxName;
            }
            return sandboxName;
        }
        private set;
    }

    //
    //
    //

    //
    // Iterates throught the list of new User and passes the required attributes to other methods.
    // @param newMap List of New User.
    // @param oldMap List of the User record after insert.
    // @return void
    //
    //
    public void afterInsertUser( List<User> newList ) {
        List<string> serviceProfiles = System.Label.NSP_ServiceProfiles.split(',');
        Set<Id> serviceProfileUserIdSet = new Set<Id>();
        List<User> lstUserToAssignFSLPermissions = new List<User>();
        Map<Id, User> userIdUserMap  = new Map<Id, User>();
        Set<Id> portalUserIds = new Set<Id>();
        for ( User usr : newList ) {
            if(serviceProfiles.contains(usr.NSP_User_Profile_Name__c) && usr.IsActive){
                serviceProfileUserIdSet.add(usr.id);
            }

            if ( usr.IsActive
                && usr.IsPortalEnabled
                && ( usr.ContactId != null )
                )
            {
                portalUserIds.add( usr.Id );
            }

            if(String.isNotBlank(usr.NSP_Salesforce_Field_service__c)){
                lstUserToAssignFSLPermissions.add(usr);
            }

            if(usr.NSP_Financial_Force_User__c != null)
            {
                userIdUserMap.put(usr.Id, usr);
            }
        }

        if(!userIdUserMap.isEmpty()){
           assignPSAPermission(userIdUserMap);
        }

        // Adding Service user to Service Profile Group Members
        if(!serviceProfileUserIdSet.isEmpty()){
            addtoServiceProfilePublicGroup(serviceProfileUserIdSet);
        }
        PortalClientSharing.enqueueJob( portalUserIds );
        if ( !lstUserToAssignFSLPermissions.isEmpty() ) {
            //send it to queueable method to assign permissionset
            this.processUserPermissions( lstUserToAssignFSLPermissions , null );
        }
    }

    //
    // Iterates throught the list of new User and passes the required attributes to other methods.
    // @param newMap List of New User.
    // @param oldMap List of the User record before update.
    // @return void
    //
    public void afterUpdateUser( Map<Id,User> newMap , Map<Id,User> oldMap ) {
        List<User> lstUserToAssignFSLPermissions = new List<User>();
        List<string> serviceProfiles = System.Label.NSP_ServiceProfiles.split(',');
        Set<Id> serviceProfileUserIdSet = new Set<Id>();
        Set<Id> nonserviceProfileUserIdSet = new Set<Id>();
        Set<Id> psaUserIdSet  = new Set<Id>();
        Map<Id, User> userIdUserMap  = new Map<Id, User>();
        Set<Id> userToremovePsSet  = new Set<Id>();
        Set<Id> portalUserIds = new Set<Id>();

        for ( User usr : newMap.values() ) {

            if(String.isNotBlank(usr.NSP_User_Profile_Name__c) && usr.NSP_User_Profile_Name__c != oldMap.get(usr.Id).NSP_User_Profile_Name__c && usr.IsActive){
                if(serviceProfiles.contains(usr.NSP_User_Profile_Name__c) && !serviceProfiles.contains(oldMap.get(usr.Id).NSP_User_Profile_Name__c)){
                    serviceProfileUserIdSet.add(usr.id);
                }else if(!serviceProfiles.contains(usr.NSP_User_Profile_Name__c) && serviceProfiles.contains(oldMap.get(usr.Id).NSP_User_Profile_Name__c)){
                    nonserviceProfileUserIdSet.add(usr.id);
                }
            }

            if((usr.NSP_Salesforce_Field_service__c != oldMap.get(usr.Id).NSP_Salesforce_Field_service__c) ||
                                usr.NSP_Dispatch_Region__c != oldMap.get(usr.Id).NSP_Dispatch_Region__c){
                lstUserToAssignFSLPermissions.add(usr);
            }

            if(usr.NSP_Financial_Force_User__c != oldMap.get(usr.Id).NSP_Financial_Force_User__c ){
                //psaUserIdSet.add(usr.Id);
                if(oldMap.get(usr.Id).NSP_Financial_Force_User__c != null)
                {
                    userToremovePsSet.add(usr.Id);
                }
                if(usr.NSP_Financial_Force_User__c != null)
                {
                    userIdUserMap.put(usr.Id, usr);
                }
            }

            if ( usr.isActive
                && usr.IsPortalEnabled
                && ( usr.ContactId != null )
                )
            {
                portalUserIds.add( usr.Id );
            }
        }

        // Adding Service user to Service Profile Group Members
        if(!serviceProfileUserIdSet.isEmpty()){
            addtoServiceProfilePublicGroup(serviceProfileUserIdSet);
        }

        // Adding Service user to Service Profile Group Members
        if(!nonserviceProfileUserIdSet.isEmpty()){
            removeFromServiceProfilePublicGroup(nonserviceProfileUserIdSet);
        }

        if(!lstUserToAssignFSLPermissions.isEmpty()){
             processUserPermissions(lstUserToAssignFSLPermissions, oldMap);
        }

        if(!userToremovePsSet.isEmpty()){
            removePSAPermission(userToremovePsSet);
        }

        if(!userIdUserMap.isEmpty()){
           assignPSAPermission(userIdUserMap);
        }
        PortalClientSharing.enqueueJob( portalUserIds );
        this.syncToAccount( newMap.values() , oldMap );
    }

    //
    // @description: private method to process serviceResources records
    // @parameters: List of users
    // @return: void
    //
    public void processUserPermissions(List<User> lstUser, Map<Id, User> mapOldUser){
        Map<Id, ServiceResource> mapUserServiceResource = new Map<Id, ServiceResource>();
        List<ServiceResource> lstServiceResource = new List<ServiceResource>();
        List<ServiceTerritoryMember> lstTerritoryMember =  new List<ServiceTerritoryMember>();
        List<ServiceTerritoryMember> lstTerritoryMemberToDelete =  new List<ServiceTerritoryMember>();
        set<Id> setServiceResourceId = new set<Id>();
        Set<String> setDispatachRegion = new Set<String>();
        Map<String, Id> mapTerritory = new Map<String, Id>();
        Set<Id> setUserId = new set<Id>();
        Map<String, ServiceTerritoryMember> mapServiceResourceTerritoryMember = new Map<String, ServiceTerritoryMember>();

        for(User usr: lstUser){
            setUserId.add(usr.Id);
            //Populate the set of old dispatch region
            if(mapOldUser != null && mapOldUser.get(usr.Id) != null){
                User oldUser = mapOldUser.get(usr.Id);
                if(String.isNotBlank(oldUser.NSP_Dispatch_Region__c)){
                    setDispatachRegion.add(oldUser.NSP_Dispatch_Region__c);
                }
            }
            if(String.isNotBlank(usr.NSP_Dispatch_Region__c)){
                setDispatachRegion.add(usr.NSP_Dispatch_Region__c);
            }
        }

        //get ServiceResource records
        for(ServiceResource sr: [SELECT Id, Name, IsActive, RelatedRecordId FROM ServiceResource WHERE RelatedRecordId IN :setUserId]){
            mapUserServiceResource.put(sr.RelatedRecordId, sr);
            setServiceResourceId.add(sr.Id);
        }
        for(ServiceTerritoryMember terrMember: [SELECT Id, ServiceTerritory.Name, ServiceResourceId FROM  ServiceTerritoryMember WHERE ServiceResourceId IN :setServiceResourceId]){
            mapServiceResourceTerritoryMember.put(('' + terrMember.ServiceResourceId + terrMember.ServiceTerritory.Name), terrMember);
        }

        for(ServiceTerritory servTerritory : [SELECT Id, Name FROM ServiceTerritory WHERE Name IN :setDispatachRegion]){
            mapTerritory.put(servTerritory.Name, servTerritory.Id);
        }
        if(!setDispatachRegion.isEmpty()){
            createServiceResourceTerritoryMemberMap(setServiceResourceId, setDispatachRegion, mapTerritory);
        }

        for(User usr: lstUser){
            ServiceResource servRes = mapUserServiceResource.get(usr.Id);

            //When Salesforce Field Service is Dispatcher or Resource
            if(String.isNotBlank(usr.NSP_Salesforce_Field_Service__c) && usr.NSP_Salesforce_Field_Service__c != NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_SFS_READONLY){
                //Check if ServiceResource exists or not
                if(servRes == null){
                    servRes = new ServiceResource(RelatedRecordId = usr.Id, IsActive = true, Name = usr.FirstName + ' ' +  usr.LastName);
                    mapUserServiceResource.put(usr.Id, servRes);
                }else if(servRes != null && !servRes.IsActive){
                    servRes.IsActive = true;
                }
                servRes.ResourceType = usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER ? 'D' : 'T';
            }else if(String.isBlank(usr.NSP_Salesforce_Field_Service__c) ||usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_SFS_READONLY ){
                if(servRes != null && servRes.IsActive){
                    servRes.IsActive = false;
                }
            }
            if(servRes != null){
                lstServiceResource.add(servRes);
            }
        }

        if ( !lstServiceResource.isEmpty() ) {
            List<Database.UpsertResult> results =  Database.upsert( lstServiceResource , false );
            NSP_ErrorLogHandler.logResults(
                NSP_UserTriggerHelper.class.getName() ,
                'processUserPermissions:upsert' ,
                results
            );
        }

        for(User usr: lstUser){
            ServiceResource servRes = mapUserServiceResource.get(usr.Id);
            if(servRes != null){
                if(String.isNotBlank(usr.NSP_Salesforce_Field_Service__c) &&
                        (usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_RESOURCE ||
                        usr.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE)){
                    String territoryMemberKey = '' + servRes.Id + usr.NSP_Dispatch_Region__c;
                    if(mapServiceResourceTerritoryMember.get(territoryMemberKey) == null){
                        ServiceTerritoryMember territoryMember = createTerritoryMember(usr, servRes.Id, mapTerritory);
                        if(territoryMember != null){
                            lstTerritoryMember.add(territoryMember);
                        }
                    }
                }

                //Check for the dispatch region change
                if(mapOldUser != null && mapOldUser.get(usr.Id) != null){
                    User oldUser = mapOldUser.get(usr.Id);
                    if(((oldUser.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_RESOURCE ||
                                oldUser.NSP_Salesforce_Field_Service__c == NSP_ServiceConstants.SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE) &&
                                oldUser.NSP_Salesforce_Field_Service__c != usr.NSP_Salesforce_Field_Service__c) ||
                            (oldUser.NSP_Dispatch_Region__c != usr.NSP_Dispatch_Region__c && String.isNotBlank(oldUser.NSP_Dispatch_Region__c))){
                        String territoryMemberKey = '' + servRes.Id + oldUser.NSP_Dispatch_Region__c;
                        ServiceTerritoryMember servTerrMember = mapServiceResourceTerritoryMember.get(territoryMemberKey);
                        if(servTerrMember != null){
                            lstTerritoryMemberToDelete.add(servTerrMember);
                        }
                    }
                }

            }
        }

        if ( !lstTerritoryMemberToDelete.isEmpty() ) {
            Database.DeleteResult[] results = Database.delete( lstTerritoryMemberToDelete , false );
            NSP_ErrorLogHandler.logResults(
                NSP_UserTriggerHelper.class.getName() ,
                'processUserPermissions:delete' ,
                results
            );
        }

        if ( !lstTerritoryMember.isEmpty() ) {
            Database.SaveResult[] results =  Database.insert( lstTerritoryMember , false );
            NSP_ErrorLogHandler.logResults(
                NSP_UserTriggerHelper.class.getName() ,
                'processUserPermissions:insert' ,
                results
            );
        }

        System.enqueueJob(new NSP_AssignFSLUserPermissions(lstUser, Trigger.isUpdate));
    }

    //
    // @description: private method to create map of Service resource and its Territory Member record map
    // @parameters: serviceResource Id set, dispatch region string
    // @return: map<String, TerritoryMember> where key is combination of serviceResource Id and territory Name
    //
    private Map<String, ServiceTerritoryMember> createServiceResourceTerritoryMemberMap(Set<Id> setServiceResourceId, Set<String> setDispatachRegion, Map<String, Id> mapTerritory){
        Map<String, ServiceTerritoryMember> mapServiceResourceTerritoryMember = new Map<String, ServiceTerritoryMember>();

        for(ServiceTerritory servTerritory : [SELECT Id, Name, (SELECT Id, ServiceTerritory.Name, ServiceResourceId FROM ServiceResources
                                    WHERE ServiceResourceId IN :setServiceResourceId) FROM ServiceTerritory WHERE Name IN :setDispatachRegion]){
            mapTerritory.put(servTerritory.Name, servTerritory.Id);
            if(servTerritory.ServiceResources != null && !servTerritory.serviceResources.isEmpty()){
                for(ServiceTerritoryMember terrMember: servTerritory.ServiceResources){
                    mapServiceResourceTerritoryMember.put(('' + terrMember.ServiceResourceId + terrMember.ServiceTerritory.Name), terrMember);
                }
            }
        }
        return mapServiceResourceTerritoryMember;
    }

    //
    // @description: private method to create Service Territory Member record
    // @parameters: permission set name, user Id
    // @return: ServiceTerritoryMember
    //
    private ServiceTerritoryMember createTerritoryMember(User usr, Id serviceResourceId, Map<String, Id> mapTerritory){
        ServiceTerritoryMember territoryMember;
        //get the territory Id
        String territoryId = mapTerritory.get(usr.NSP_Dispatch_Region__c);
        if(String.isNotBlank(territoryId) && String.isNotBlank(serviceResourceId)){
            territoryMember = new ServiceTerritoryMember(TerritoryType = 'P', ServiceTerritoryId = territoryId,
                        EffectiveEndDate = null, EffectiveStartDate = System.now(), ServiceResourceId = serviceResourceId);
        }
        return territoryMember;
    }


    //
    // Method Name : updatePhoneNumber
    // Description : Method to format Phone number on insert
    // Author : Raksha       Date : 22/02/2022
    // @param currentRecordsList List of New User.
    // @return void
    //
    public void updatePhoneNumber(List < User > currentRecordsList) {
        for (User contact: currentRecordsList) {
            if(contact.Phone != null) {
            Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
            String initialNum = nonAlphanumeric.matcher(contact.Phone).replaceAll('').replace('ext', 'x');
            Pattern numFormat10Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})');
            Pattern numFormat10Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})(x\\d{3})?$');
            Pattern numFormat11Dig;
            Pattern numFormat11Ext;
            if (initialNum.startsWith('1')) {
                numFormat11Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})');
                numFormat11Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})(x\\d{3})?$');
                if (numFormat11Dig.matcher(initialNum).matches() || numFormat11Ext.matcher(initialNum).matches()) {
                    contact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(contact.Phone);
                } else if (numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                    contact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(contact.Phone);
                } else {
                    contact.NSP_Formatted_Phone_Num__c = contact.Phone;
                }
            } else if (numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                contact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(contact.Phone);
            } else {
                contact.NSP_Formatted_Phone_Num__c = contact.Phone;
            }
         }
        }
    }

    //
    // Method Name : updatePhoneNum
    // Description : Method to format Phone number on update
    // Author : Raksha       Date : 22/02/2022
    // @param currentRecordsList List of New User.
    // @return void
    //
    public void updatePhoneNum(List < User > newContactList, Map < Id, User > contactOldMap) {
        for (User newContact: newContactList) {
            User oldContact = contactOldMap != null ? contactOldMap.get(newContact.Id) : null;
            if (newContact.Phone != oldContact.Phone && newContact.Phone != null) {
                Pattern nonAlphanumeric = Pattern.compile('[^a-zA-Z0-9]');
                String initialNum = nonAlphanumeric.matcher(newContact.Phone).replaceAll('').replace('ext', 'x');
                Pattern numFormat10Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})');
                Pattern numFormat10Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{4})(x\\d{3})?$');
                Pattern numFormat11Dig;
                Pattern numFormat11Ext;
                if (initialNum.startsWith('1')) {
                    numFormat11Dig = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})');
                    numFormat11Ext = Pattern.compile('^\\(?(\\d{3})\\)?[-\\. ]?(\\d{3})[-\\. ]?(\\d{5})(x\\d{3})?$');
                    if (numFormat11Dig.matcher(initialNum).matches() || numFormat11Ext.matcher(initialNum).matches()) {
                        newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                    } else if (numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                        newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                    } else {
                        newContact.NSP_Formatted_Phone_Num__c = newContact.Phone;
                    }
                } else if (numFormat10Dig.matcher(initialNum).matches() || numFormat10Ext.matcher(initialNum).matches()) {
                    newContact.NSP_Formatted_Phone_Num__c = formatPhoneNumbers(newContact.Phone);
                } else {
                    newContact.NSP_Formatted_Phone_Num__c = newContact.Phone;
                }
            }
            if (newContact.Phone == null) {
                newContact.NSP_Formatted_Phone_Num__c = null;
            }
        }
    }

    //
    // Method Name : formatPhoneNumbers
    // Description : Method to format Phone number
    // Author : Raksha       Date : 22/02/2022
    // @param String input called from updatePhoneNum.
    // @return String
    //
    public String formatPhoneNumbers(String input) {
        String requiredOutput;
        input = input.replaceAll('\\(', '').replaceAll('\\)', '');
        input = input.replaceAll('-', '');
        String trimString = input.deleteWhitespace();
        List < String > parts = new List < String > ();
        if (trimString.contains('ext')) {
            parts = trimString.split('ext');
            requiredOutput = formatCommonPattern(parts.get(0).trim()) + ' x' + parts.get(1);
        } else if (trimString.contains('x')) {
            parts = trimString.split('x');
            requiredOutput = formatCommonPattern(parts.get(0).trim()) + ' x' + parts.get(1);
        } else {
            requiredOutput = formatCommonPattern(trimString);
        }
        return requiredOutput;
    }

    //
    // Method Name : formatCommonPattern
    // Description : Method to construct common pattern and format Phone number
    // Author : Raksha       Date : 22/02/2022
    // @param String input called from formatPhoneNumbers.
    // @return String
    //
    public String formatCommonPattern(String input) {
        if (input.length() == 10) {
            String number1 = input.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '($1) $2-$3');
            return number1;
        }
        String substring = input.length() > 10 ? input.substring(input.length() - 10) : input;
        String codeNumber = substring.replaceFirst('(\\d{3})(\\d{3})(\\d+)', '+1 ($1) $2-$3');
        return codeNumber;
    }

    //
    // Method Name : setSalesOfficeDetails
    // Description : Method to set the sales office details from sales office mapping
    // @param currentRecordsList List of New User.
    // @return void
    //
    public void setSalesOfficeDetails( List<User> newUserList , Map<Id,User> userOldMap ) {
        set<String> salesOfficeSet = new set<String>();

        for(User newUser : newUserList)
        {
            User oldUser = userOldMap != null ? userOldMap.get(newUser.Id):null;

            if( !system.isBatch() && String.isNotBlank(newUser.NSP_Sales_Office__c) && (Trigger.isInsert || (newUser.NSP_Sales_Office__c != oldUser.NSP_Sales_Office__c || newUser.NSP_SalesRegion__c != oldUser.NSP_SalesRegion__c || newUser.NSP_SalesDivision__c != oldUser.NSP_SalesDivision__c )))
            {

                salesOfficeSet.add(newUser.NSP_Sales_Office__c);
            }
        }

        if(salesOfficeSet.Size() > 0)
        {
            map<String,NSP_Sales_Office_Mapping__c> salesOfficeToMappingMap =  new map<String,NSP_Sales_Office_Mapping__c>();
            for(NSP_Sales_Office_Mapping__c eachMapping : [SELECT Id,NSP_Sales_Office__c,NSP_Sales_Division__c,NSP_Sales_Region__c
                                                            FROM NSP_Sales_Office_Mapping__c
                                                           WHERE NSP_Sales_Office__c In : salesOfficeSet AND isActive__c = true])
            {
                salesOfficeToMappingMap.put(eachMapping.NSP_Sales_Office__c,eachMapping);
            }



            for(User newUser : newUserList)
            {
                User oldUser = userOldMap != null ? userOldMap.get(newUser.Id):null;

                if(!system.isBatch() && String.isNotBlank(newUser.NSP_Sales_Office__c) && (Trigger.isInsert || (newUser.NSP_Sales_Office__c != oldUser.NSP_Sales_Office__c || newUser.NSP_SalesRegion__c != oldUser.NSP_SalesRegion__c || newUser.NSP_SalesDivision__c != oldUser.NSP_SalesDivision__c )))
                {
                    if(salesOfficeToMappingMap.containsKey(newUser.NSP_Sales_Office__c))
                        {
                            NSP_Sales_Office_Mapping__c officeMapping = salesOfficeToMappingMap.get(newUser.NSP_Sales_Office__c);
                            newUser.NSP_SalesDivision__c = officeMapping.NSP_Sales_Division__c;
                            newUser.NSP_SalesRegion__c = officeMapping.NSP_Sales_Region__c;
                        }
                    else{
                            newUser.NSP_SalesDivision__c = null;
                            newUser.NSP_SalesRegion__c = null;
                    }
                }
            }

        }
    }

    //
    // Method Name : syncToAccount
    // Description : Method to sync the sales office details from User to Account
    // @param currentRecordsList List of New User.
    // @return void
    //
    public void syncToAccount(List < User > newUserList, Map < Id, User > userOldMap)
    {
        set<Id> userIdSet = new set<Id>();

        for(User newUser : newUserList)
        {
            User oldUser = userOldMap != null ? userOldMap.get(newUser.Id):null;

            if(String.isNotBlank(newUser.NSP_Sales_Office__c)  && (Trigger.isInsert || (newUser.NSP_Sales_Office__c != oldUser.NSP_Sales_Office__c || newUser.NSP_SalesRegion__c != oldUser.NSP_SalesRegion__c || newUser.NSP_SalesDivision__c != oldUser.NSP_SalesDivision__c )))
            {
                userIdSet.add(newUser.Id);
            }
        }

        if(userIdSet.Size() > 0 && !syncAccountQueueExecuted)
        {
            syncAccountQueueExecuted = true;
            system.enqueueJob(new NSP_SyncAccountSalesOfficeQueueable(userIdSet));
        }
    }

    //
    // @MethodName: updateAccountTeamField
    // @Description: This method is used to update Asset Fields on after Insert
    // @param : Map<Id, User> newMap, Map<Id, User> oldMap
    // @createdDate : 12/01/2022
    // @Defect : STY-02108
    // @return void
    //
    public static void updateAssetServiceRegion( Map<Id, User> newMap, Map<Id, User> oldMap ) {

        Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );

        Set<Id> userIds = new Set<Id>();
        List<Asset> assetToBeUpdated = new List<Asset>();

        Map<Id, String> accountByRegion = new Map<Id, String>();

        // get user id
        for (User user : newMap.values()) {
            if(user.NSP_Service_Region__c != oldMap.get(user.Id).NSP_Service_Region__c ) {
                userIds.add(user.Id);
            }
        }

        // get all account ids to find asset
        for(NSP_Account_Team__c accTeam : [SELECT Id, NSP_User__c, NSP_User__r.NSP_Service_Region__c, NSP_Account__c From NSP_Account_Team__c WHERE
                                           NSP_Role__c ='Manager, HR Services' AND NSP_User__c=:userIds AND NSP_Account__c != null]){
            accountByRegion.put(accTeam.NSP_Account__c,  accTeam.NSP_User__r.NSP_Service_Region__c);
        }

        // get exist Asset records with record type wo related this user
        for(Asset asset : [SELECT Id, RecordTypeId, NSP_Service_Region__c, AccountId From Asset WHERE RecordTypeId =:woRecordTypeId  AND AccountId =:accountByRegion.keyset() AND NSP_Account_Status__c = 'Active']){
            if(accountByRegion.containsKey(asset.AccountId)) {
                asset.NSP_Service_Region__c = accountByRegion.get(asset.AccountId);
                assetToBeUpdated.add(asset);
            }
        }

        if(!assetToBeUpdated.isEmpty()) {
            update assetToBeUpdated;
        }
    }

    //
    // @MethodName: addtoServiceProfilePublicGroup
    // @Description: This method is used to add Service Profile members to Service Profile Group Members group
    // @param : Set<Id> serviceProfileUserIdSet
    // @createdDate : 1/24/2023
    // @Story : STY-03841
    // @return void
    //
    public static void addtoServiceProfilePublicGroup( Set<Id> serviceProfileUserIdSet ) {

        List<GroupMember> grpMemList = new List<GroupMember>();
        List<String> grpFields = new List<String>{'Id', 'Type','DeveloperName'};
        GroupMember newGrpMem = null;
        Id serviceProfileGroupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.SERVICE_PROFILE_GROUP_MEMBERS, grpFields).Id;

        for(Id usrId : serviceProfileUserIdSet){
            newGrpMem = new GroupMember();
            newGrpMem.GroupId = serviceProfileGroupId;
            newGrpMem.UserOrGroupId = usrId;
            grpMemList.add(newGrpMem);
        }

        try {
            if ( !grpMemList.isEmpty() ) {
                List<Database.SaveResult> results = Database.insert( grpMemList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_UserTriggerHelper.class.getName() ,
                    'addtoServiceProfilePublicGroup:insert' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_UserTriggerHelper.class.getName() ,
                'addtoServiceProfilePublicGroup' ,
                e
            );
        }
    }

    //
    // @MethodName: removeFromServiceProfilePublicGroup
    // @Description: This method is used to members from Service Profile Group Members group
    // @param : Set<Id> serviceProfileUserIdSet
    // @createdDate : 1/24/2023
    // @Story : STY-03841
    // @return void
    //
    public static void removeFromServiceProfilePublicGroup( Set<Id> nonserviceProfileUserIdSet ) {

        List<GroupMember> grpMemList = new List<GroupMember>();
        List<String> grpFields = new List<String>{'Id', 'Type','DeveloperName'};

        Id serviceProfileGroupId = NSP_sObjectSelector.selectGroupByTypeAndApiName(NSP_ServiceConstants.TYPE_REGULAR, NSP_ServiceConstants.SERVICE_PROFILE_GROUP_MEMBERS, grpFields).Id;

        for(GroupMember grpMem : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE UserOrGroupId IN: nonserviceProfileUserIdSet AND GroupId =: serviceProfileGroupId]){
            grpMemList.add(grpMem);
        }

        try {
            if ( !grpMemList.isEmpty() ) {
                List<Database.DeleteResult> results = Database.delete( grpMemList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_UserTriggerHelper.class.getName() ,
                    'removeFromServiceProfilePublicGroup:delete' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_UserTriggerHelper.class.getName() ,
                'removeFromServiceProfilePublicGroup' ,
                e
            );
        }
    }

    //
    // @MethodName: removePSAPermission
    // @Description: Assign PSA Adminstration Permission Set
    // @param : Set<Id>
    // @return void
    //
    public static void removePSAPermission( Set<Id> userToremovePsSet ) {
        List<PermissionSetAssignment> getPermList = new List<PermissionSetAssignment>();
        List<String> perSetNames = System.Label.NSP_FF_PerSet_Names.split(',');

        for(PermissionSetAssignment permSetAssignment : [SELECT Id, PermissionSetId, PermissionSet.Name, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId IN: userToremovePsSet AND PermissionSet.Name IN : perSetNames]){
                getPermList.add(permSetAssignment);
        }

        try {
            if ( !getPermList.isEmpty() ) {
                List<Database.DeleteResult> results = Database.delete( getPermList , false );
                NSP_ErrorLogHandler.logResults(
                    NSP_UserTriggerHelper.class.getName() ,
                    'removePSAPermission:delete' ,
                    results
                );
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_UserTriggerHelper.class.getName() ,
                'removePSAPermission' ,
                e
            );
        }
    }

    //
    // @MethodName: assignPSAPermission
    // @Description: Assign PSA Adminstration Permission Set
    // @param : Map<Id, User> newMap, Map<Id, User> oldMap
    // @return void
    //
    public static void assignPSAPermission( Map<Id,User> userIdUserMap ) {
        try {
            Set<Id> permSetIds = new Set<Id>();
            String queryPerm;

            List<String> perSetFields = new List<String>{ 'Id', 'Name' };
            List<String> perSetNames_FullAccess = System.Label.NSP_PerSet_Names_FullAccess.split(',');
            List<String> perSetNames_ReadOnly =  System.Label.NSP_PerSet_Names_Read_Only.split(',');
            for(User userFF : userIdUserMap.values()){
                if(userIdUserMap.get(userFF.id).NSP_Financial_Force_User__c == 'Full Access'){
                         queryPerm = new NSP_QueryBuilder('PermissionSet', perSetFields)
                        .addFilter('Name', perSetNames_FullAccess, NSP_QueryBuilder.Operator.INCLUDES)
                        .build();
                }else if (userIdUserMap.get(userFF.id).NSP_Financial_Force_User__c == 'Read Only'){
                         queryPerm = new NSP_QueryBuilder('PermissionSet', perSetFields)
                        .addFilter('Name', perSetNames_ReadOnly, NSP_QueryBuilder.Operator.INCLUDES)
                        .build();
                }
            }


            if(!userIdUserMap.isEmpty()){
                for(PermissionSet permSet : Database.query(queryPerm)){
                    permSetIds.add(permSet.Id);
                }
                assignUserPerm(userIdUserMap.keySet(), permSetIds);
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_UserTriggerHelper.class.getName() ,
                'assignPSAPermission' ,
                e
            );
        }
    }

    //
    // @MethodName: assignUserPerm
    // @Description: Assign PSA Adminstration Permission Set, PSAManageGanttAndProjectTasks
    // @param : Set<Id> userIdSet, Set<Id> permSetIds
    // @return void
    //
    @future
    public static void assignUserPerm(Set<Id> userIdSet, Set<Id> permSetIds){
        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        //for set of Users assigning set of Permissions
        for(Id usrId: userIdSet){
            for(Id permSetId : permSetIds){
                permissionSetList.add(
                    new PermissionSetAssignment(
                        PermissionSetId = permSetId,
                        AssigneeId = usrId
                    )
                );
            }
        }

        if(!permissionSetList.isEmpty()){
            Database.insert(permissionSetList, false);
        }
    }

}
//