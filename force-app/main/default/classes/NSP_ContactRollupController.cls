// Contact - Roll up visibility of all Contact roles at the Account Page from AccountContactRelation and SubClientContacts
// 5/19/2022
public without sharing class NSP_ContactRollupController {
    // test w/ NSP_ContactRollupController_Test (96%)

    private static Set<String> paidNonPaidValues = new Set<String>{
        'Paid WSEE' ,
        'Active Non-Paid User'
    };

    private static Map<String,Schema.SObjectField> fieldMap {
        private get {
            if ( fieldMap == null ) {
                fieldMap = Schema.SObjectType.NSP_Sub_Client_Contact__c.fields.getMap();
            }
            return fieldMap;
        }

        private set;
    }

    private static Map<String, Schema.SObjectField> acrFieldMap {
        private get {
            if( acrFieldMap == null ) {
                acrFieldMap = Schema.SObjectType.AccountContactRelation.fields.getMap();
            }

            return acrFieldMap;
        }

        private set;
    }

    private static final String includesStringValue = ' INCLUDES ';

    //
    // @description: Contact - Roll up visibility of all Contact roles at the Account Page from AccountContactRelation and SubClientContacts
    // @param recordId of Account.
    // @return resultWrapper
    //
    @AuraEnabled(cacheable=true)
    public static List<ResultWrapper> getContactRollUpRecords(
        String recordId ,
        Integer offSetCount ,
        Boolean fullView ,
        List<String> allFilters ,
        String subClientFilter ,
        String acrFilter
        )
    {
        try {
            Integer offSetLimit = fullView ? 50 : 10;
            Map < Id, ResultWrapper > resultsMap = new Map < Id, ResultWrapper > ();
            List < ResultWrapper > filteredResultSet = new List < ResultWrapper > ();
            resultsMap = getACR(recordId, resultsMap, offSetCount, offSetLimit, acrFilter);
            resultsMap = getSubClientContacts(recordId, resultsMap, offSetCount, offSetLimit, subClientFilter);
            if (allFilters != null && allFilters.size() > 0) {
                //fetch filtered result of ACR and Sub clients combined together based on all filters[] passed to regex expression
                String regex = '^';
                for (string filter: allFilters) {
                    regex = regex + '(?=.*\\b' + filter + '\\b)';
                }
                regex = regex + '.*$';

                for (ResultWrapper result: resultsMap.values()) {
                    if (Pattern.matches(regex, result.allRoles)) {
                        filteredResultSet.add(result);
                    }
                }
            } else {
                for (ResultWrapper result: resultsMap.values()) {
                    filteredResultSet.add(result);
                }
            }
            return filteredResultSet;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //
    // @description : get account based record AccountContactRelation records
    // @param  recordId of Account,
    // @param  Map<Id,ResultWrapper> contact and allACR's and SubClientContacts
    // @return String
    public static Map<Id,ResultWrapper> getSubClientContacts(
        String recordId ,
        Map<Id,ResultWrapper> resultsMap ,
        Integer offSetCount ,
        Integer offSetLimit ,
        String subClientFilter
        )
    {
        List<NSP_Sub_Client_Contact__c> subClientsBasedOnQueryResults = new List<NSP_Sub_Client_Contact__c>();
        // Based on Subclient contact fields filter
        if ( String.isNotBlank( subClientFilter ) ) {
            subClientsBasedOnQueryResults = NSP_ContactRollupController.getSubClientContactsBasedOnFilter(
                recordId ,
                offSetCount ,
                offSetLimit ,
                subClientFilter
            );
        } else {
            subClientsBasedOnQueryResults = NSP_ContactRollupController.getSubClientContactsBasedOnNoFilter(
                recordId ,
                offSetCount ,
                offSetLimit
            );
        }
        return NSP_ContactRollupController.getSubClientContactRecords(
            subClientsBasedOnQueryResults ,
            resultsMap ,
            recordId
        );
    }

    // @description : Fetch sub client contact records based on default filters
    // @params: recordId, offSetCount, offSetLimit, paidNonPaidValues
    // @return : List<NSP_Sub_Client_Contact__c>
    private static List<NSP_Sub_Client_Contact__c> getSubClientContactsBasedOnNoFilter(string recordId,
                                                                                       Integer offSetCount,
                                                                                       Integer offSetLimit) {
        List<NSP_Sub_Client_Contact__c> returnList = [
            SELECT
            Id, Name, NSP_Sub_Client__c,
            NSP_Sub_Client__r.Name, NSP_Contact__r.Name,
            NSP_Sub_Client__r.NSP_Account__r.Name, NSP_Sub_Client__r.NSP_Account__c,
            NSP_Contact__r.firstName, NSP_Contact__r.lastName,
            NSP_Contact__r.NSP_Preferred_First_Name__c, NSP_Contact__c,
            NSP_On_Site_Supervisor__c, NSP_Payroll_Contact__c,
            NSP_Client_Leave_Administrator__c, NSP_WC_Contact__c,
            NSP_HR_Contact__c, NSP_Benefits_Contact__c,
            NSP_Background_Contact__c, NSP_Unemployment_Contact__c,
            NSP_Paid_Non_Paid__c, NSP_Employee_Status__c
            FROM
            NSP_Sub_Client_Contact__c
            WHERE
            NSP_Sub_Client__r.NSP_Account__c =: recordId
            AND
            NSP_Paid_Non_Paid__c IN :NSP_ContactRollupController.paidNonPaidValues
            AND
            NSP_Employee_Status__c != 'Terminated'
            AND
            NSP_Paid_Non_Paid__c != 'Inactive Non-Paid User'
            AND (
                NSP_On_Site_Supervisor__c = true
                OR
                NSP_Payroll_Contact__c = true
                OR
                NSP_Client_Leave_Administrator__c = true
                OR
                NSP_WC_Contact__c = true
                OR
                NSP_HR_Contact__c = true
                OR
                NSP_Benefits_Contact__c = true
                OR
                NSP_Background_Contact__c = true
                OR
                NSP_Unemployment_Contact__c = true
            )
            ORDER BY
            NSP_Contact__r.Name ASC
            LIMIT :offSetLimit
            OFFSET :offSetCount


        ];

        return returnList;
    }

    // @description : Filter the sub client contacts based on sub client contact filters from UI
    // @params: recordId,  offSetCount, offSetLimit, subClientFilter
    // @return : List<NSP_Sub_Client_Contact__c>
    private static List<NSP_Sub_Client_Contact__c> getSubClientContactsBasedOnFilter(
        String recordId ,
        Integer offSetCount ,
        Integer offSetLimit ,
        String subClientFilter
        )
    {
        List<NSP_Sub_Client_Contact__c> returnList = new List<NSP_Sub_Client_Contact__c>();
        List<String> subClientFilterList = new List<String>();
        if ( String.isNotBlank(subClientFilter) ) {
            subClientFilterList = new List<String>( subClientFilter.split( ',' ) );
        }
        if ( ( subClientFilterList != null ) && !subClientFilterList.isEmpty() ) {
            NSP_Sub_Client_Contact__c tempSubClientContact = NSP_ContactRollupController.getSubClientContactObj();
            for ( String subClientFilterField : subClientFilterList ) {
                if ( NSP_ContactRollupController.getFlagFieldValue( subClientFilterField ) ) {
                    tempSubClientContact.put(
                        NSP_ContactRollupController.fieldMap.get( subClientFilterField ) ,
                        true
                    );
                }
            }
            returnList = NSP_ContactRollupController.getSubClientContactsBasedOnObjectFilter(
                recordId ,
                offSetCount ,
                offSetLimit ,
                tempSubClientContact
            );
        }
        return returnList;
    }

    //@description : Query results based on sub client contact field values
    //@params : recordId, offSetCount, offSetLimit, NSP_Sub_Client_Contact__c, paidNonPaidValues
    //@return : List<NSP_Sub_Client_Contact__c>
    private static List<NSP_Sub_Client_Contact__c> getSubClientContactsBasedOnObjectFilter(string recordId,
                                                                                           Integer offSetCount,
                                                                                           Integer offSetLimit,
                                                                                           NSP_Sub_Client_Contact__c subClientContact) {
        List<NSP_Sub_Client_Contact__c> returnList = [
            SELECT
            Id, Name, NSP_Sub_Client__c,
            NSP_Sub_Client__r.Name, NSP_Contact__r.Name,
            NSP_Sub_Client__r.NSP_Account__r.Name, NSP_Sub_Client__r.NSP_Account__c,
            NSP_Contact__r.firstName, NSP_Contact__r.lastName,
            NSP_Contact__r.NSP_Preferred_First_Name__c, NSP_Contact__c,
            NSP_On_Site_Supervisor__c, NSP_Payroll_Contact__c,
            NSP_Client_Leave_Administrator__c, NSP_WC_Contact__c,
            NSP_HR_Contact__c, NSP_Benefits_Contact__c,
            NSP_Background_Contact__c, NSP_Unemployment_Contact__c,
            NSP_Paid_Non_Paid__c, NSP_Employee_Status__c
            FROM
            NSP_Sub_Client_Contact__c
            WHERE
            NSP_Sub_Client__r.NSP_Account__c =: recordId
            AND
            NSP_Paid_Non_Paid__c IN :NSP_ContactRollupController.paidNonPaidValues
            AND
            NSP_Employee_Status__c != 'Terminated'
            AND
            NSP_Paid_Non_Paid__c != 'Inactive Non-Paid User'
            AND
            NSP_On_Site_Supervisor__c = :subClientContact.NSP_On_Site_Supervisor__c
            AND
            NSP_Payroll_Contact__c = :subClientContact.NSP_Payroll_Contact__c
            AND
            NSP_Client_Leave_Administrator__c = :subClientContact.NSP_Client_Leave_Administrator__c
            AND
            NSP_WC_Contact__c = :subClientContact.NSP_WC_Contact__c
            AND
            NSP_HR_Contact__c = :subClientContact.NSP_HR_Contact__c
            AND
            NSP_Benefits_Contact__c = :subClientContact.NSP_Benefits_Contact__c
            AND
            NSP_Background_Contact__c = :subClientContact.NSP_Background_Contact__c
            AND
            NSP_Unemployment_Contact__c = :subClientContact.NSP_Unemployment_Contact__c
            ORDER BY
            NSP_Contact__r.Name ASC
            LIMIT :offSetLimit
            OFFSET :offSetCount
        ];

        return returnList;
    }

    // @description : Setting the default field values for NSP_Sub_Client_Contact__c
    // @params : NONE
    // @return : NSP_Sub_Client_Contact__c
    private static NSP_Sub_Client_Contact__c getSubClientContactObj() {
        return new NSP_Sub_Client_Contact__c(
            NSP_On_Site_Supervisor__c = false,
            NSP_Payroll_Contact__c = false,
            NSP_Client_Leave_Administrator__c = false,
            NSP_WC_Contact__c = false,
            NSP_HR_Contact__c  = false,
            NSP_Benefits_Contact__c = false,
            NSP_Background_Contact__c = false,
            NSP_Unemployment_Contact__c = false
        );
    }

    // @description: based on field string match the field api name from schema object map
    // @params : string fild API name, fieldMap
    // @return : Boolean flag
    private static Boolean getFlagFieldValue( String fieldName ) {
        return (
            String.isNotBlank( fieldName )
            && NSP_ContactRollupController.fieldMap?.containsKey( fieldName )
        );
    }


    private static Map<Id,ResultWrapper> getSubClinetContactRecords( List<NSP_Sub_Client_Contact__c> lstSubClientContacts , Map<Id,ResultWrapper> resultsMap , String recordId ) {
        Set<Id> contactIdSet = new Set<Id>();
        for ( NSP_Sub_Client_Contact__c subClientCont : lstSubClientContacts ) {
            if ( !resultsMap.containsKey( subClientCont.NSP_Contact__c )
                && ( subClientCont.NSP_Sub_Client__c != null )
                && ( subClientCont.NSP_Sub_Client__r != null )
                && ( recordId == subClientCont.NSP_Sub_Client__r.NSP_Account__c )
                )
            {
                contactIdSet.add( subClientCont.NSP_Contact__c );
            }
        }
        Map<Id,AccountContactRelation> acrMap = new Map<Id,AccountContactRelation>();
        if ( !contactIdSet.isEmpty() ) {
            List<AccountContactRelation> acrList = [
                SELECT
                    AccountId , Account.Name ,
                    ContactId , Contact.FirstName , Contact.LastName , Contact.Name ,
                    Client_Communication_Contact__c , NSP_Service_Roles__c , NSP_Support_Role__c ,
                    Contact.NSP_Preferred_First_Name__c , NSP_Job_Title__c ,
                    NSP_Employee_Status__c , NSP_Work_Phone__c, NSP_Work_email__c
                FROM AccountContactRelation
                WHERE (
                    ( AccountId = :recordId )
                    AND ( ContactId = :contactIdSet )
                )
            ];
            for ( AccountContactRelation acr : acrList ) {
                acrMap.put( acr.contactId , acr);
            }
        }
        for ( NSP_Sub_Client_Contact__c subClientCont : lstSubClientContacts ) {
            NSP_Sub_Client__c sc = new NSP_Sub_Client__c(
                Id=subClientCont.NSP_Sub_Client__c ,
                Name=subClientCont.NSP_Sub_Client__r.Name
            );
            if ( resultsMap.containsKey( subClientCont.NSP_Contact__c ) ) {
                ResultWrapper wrap = resultsMap.get( subClientCont.NSP_Contact__c );
                if ( wrap != null ) {
                    wrap.allRoles = getUpdatedRoles( wrap.allRoles , subClientCont );
                    if ( wrap.subClients == null ) {
                        wrap.subClients = new List<NSP_Sub_Client__c>();
                    }
                    if ( !wrap.subClients.contains( sc ) ) {
                        wrap.subClients.add( sc );
                    }
                    resultsMap.put( subClientCont.NSP_Contact__c , wrap );
                }
            } else {
                if ( acrMap.containsKey( subClientCont.NSP_Contact__c ) ) {
                    AccountContactRelation subClientContAcr = acrMap.get( subClientCont.NSP_Contact__c );
                    if ( subClientContAcr != null ) {
                        resultsMap.put(
                            subClientCont.NSP_Contact__c ,
                            new ResultWrapper(
                                new Account(
                                    Id=subClientCont.NSP_Sub_Client__r.NSP_Account__c ,
                                    Name=subClientCont.NSP_Sub_Client__r.NSP_Account__r.Name
                                ) ,
                                new Contact(
                                    Id=subClientCont.NSP_Contact__c ,
                                    FirstName = subClientCont.NSP_Contact__r.FirstName ,
                                    NSP_Preferred_First_Name__c=subClientCont.NSP_Contact__r.NSP_Preferred_First_Name__c
                                ) ,
                                subClientCont.NSP_Contact__r.Name ,
                                new List<NSP_Sub_Client__c>{ sc } ,
                                getUpdatedRoles( null , subClientCont ) ,
                                subClientContAcr.NSP_Job_Title__c ,
                                subClientContAcr.NSP_Employee_Status__c ,
                                subClientContAcr.NSP_Work_Phone__c ,
                                subClientContAcr.NSP_Work_email__c
                            )
                        );
                    }
                }
            }
        }
        return resultsMap;
    }

    //
    // @description : get account based record AccountContactRelation records
    // @param  recordId of Account,
    // @param  Map<Id,ResultWrapper> contact and allACR's and SubClientContacts
    // @return string
    //
    private static Map<Id,ResultWrapper> getACR(
        String recordId ,
        Map<Id,ResultWrapper> resultsMap ,
        Integer offSetCount ,
        Integer offSetLimit ,
        String acrFilter
        )
    {
        List<AccountContactRelation> queryResults = new List<AccountContactRelation>();

        if(String.isNotBlank(acrFilter)) {
            AccountContactRelation acrTempRec = new AccountContactRelation(
                NSP_Service_Roles__c = NULL,
                NSP_Support_Role__c = NULL,
                HRScale_Client_Roles__c = NULL,
                Client_Communication_Contact__c = false
            );

            acrTempRec = NSP_ContactRollupController.parseAcrFilter(acrFilter, acrTempRec);
            queryResults = NSP_ContactRollupController.getAccountContactRelationshipRecordsWithFilters(
            recordId,
            offSetCount,
            offSetLimit,
            acrTempRec
             );
        }
        else {
            queryResults = NSP_ContactRollupController.getAccountContactRelationshipRecords(
            recordId,
            offSetCount,
            offSetLimit
            );
        }

        return NSP_ContactRollupController.getACRRecords(
            queryResults,
            resultsMap
        );
    }

     // @description Retrieves AccountContactRelation records with applied filter criteria.
     //              This method queries ACR records based on the provided filter values in acrTempRec,
     //              including service roles, support roles, HRScale roles, and client communication contact flag.
     //              Results are filtered to exclude terminated employees and are ordered by contact name.
     // @param recordId The Account Id to filter AccountContactRelation records
     // @param offSetCount The number of records to skip for pagination
     // @param offSetLimit The maximum number of records to return
     // @param acrTempRec An AccountContactRelation object containing filter criteria for the query
     //                   (NSP_Service_Roles__c, NSP_Support_Role__c, HRScale_Client_Roles__c, Client_Communication_Contact__c)
     // @return List<AccountContactRelation> A list of filtered AccountContactRelation records
    private static List<AccountContactRelation> getAccountContactRelationshipRecordsWithFilters(
         String recordId ,
        Integer offSetCount ,
        Integer offSetLimit ,
        AccountContactRelation acrTempRec)
        {
            List<AccountContactRelation> returnList = [
                            SELECT
            AccountId , Account.Name ,
            ContactId , Contact.FirstName ,
            Contact.LastName , Contact.Name ,
            Client_Communication_Contact__c ,
            NSP_Service_Roles__c , NSP_Support_Role__c ,
            HRScale_Client_Roles__c , Contact.NSP_Preferred_First_Name__c ,
            NSP_Job_Title__c , NSP_Employee_Status__c ,
            NSP_Work_Phone__c , NSP_Work_email__c
            FROM
            AccountContactRelation
            WHERE
            ( AccountId = :recordId )
            AND
            NSP_Employee_Status__c != 'TERMINATED'
            AND
            NSP_Service_Roles__c INCLUDES (:acrTempRec.NSP_Service_Roles__c)
            AND
            NSP_Support_Role__c INCLUDES (:acrTempRec.NSP_Support_Role__c)
            AND
            HRScale_Client_Roles__c INCLUDES (:acrTempRec.HRScale_Client_Roles__c)
            AND
            Client_Communication_Contact__c = :acrTempRec.Client_Communication_Contact__c
            WITH SECURITY_ENFORCED
            ORDER BY Contact.Name ASC
            LIMIT :offSetLimit
            OFFSET :offSetCount
            ];

            return returnList;
        }

     // @description Parses a filter string and applies the conditions to an AccountContactRelation record.
     //              The filter string contains multiple conditions separated by ' AND ', where each condition
     //              can be either an INCLUDES operation (for multi-select picklists) or an equality operation
     //              (for boolean fields). This method delegates to handleIncludesCondition and
     //              handleEqualityBooleanCondition for processing specific condition types.
     // @param acrFilter A string containing filter conditions in the format:
     //                  "FieldName INCLUDES (value)" or "FieldName = value" separated by ' AND '
     //                  Example: "NSP_Service_Roles__c INCLUDES (Service Manager) AND Client_Communication_Contact__c = true"
     // @param acrRec The AccountContactRelation record to populate with parsed filter values
     // @return AccountContactRelation The updated AccountContactRelation record with applied filter values
    private static AccountContactRelation parseAcrFilter(String acrFilter,
    AccountContactRelation acrRec)
    {

        List<String> conditions = null;
        if(String.isNotBlank(acrFilter)) {
            conditions = acrFilter.split(' AND ');
        }

        if(conditions != null && !conditions?.isEmpty()) {
            for(String condition : conditions) {
                if(condition.contains(includesStringValue)) {
                    acrRec = NSP_ContactRollupController.handleIncludesCondition(condition, acrRec);
                }

                if(condition.contains(' = ')) {
                    acrRec = NSP_ContactRollupController.handleEqualityBooleanCondition(condition, acrRec);
                }
            }
        }

        return acrRec;
    }

     // @description Handles INCLUDES conditions for multi-select picklist fields in filter parsing.
     //              Extracts the field name and value from a condition string formatted as "FieldName INCLUDES (value)",
     //              validates the field exists in the AccountContactRelation schema, and sets the value on the record.
     //              This is used for filtering multi-select picklists like NSP_Service_Roles__c, NSP_Support_Role__c,
     //              and HRScale_Client_Roles__c.
     // @param condition A string in the format "FieldName INCLUDES (value)"
     //                  Example: "NSP_Service_Roles__c INCLUDES (Service Manager)"
     // @param acrRec The AccountContactRelation record to update with the parsed field value
     // @return AccountContactRelation The updated AccountContactRelation record with the INCLUDES field value set
    private static AccountContactRelation handleIncludesCondition(String condition,
    AccountContactRelation acrRec)
    {
        if(String.isNotBlank(condition) && condition.contains(includesStringValue)) {
            string key = condition.substringBefore(includesStringValue).trim();
            string value = condition.substringBetween('(' , ')').trim();
            if(acrFieldMap!= null && !acrFieldMap?.isEmpty() && acrFieldMap.containsKey(key)) {
                acrRec.put(acrFieldMap.get(key), value);
            }
        }

        return acrRec;
    }

     // @description Handles equality conditions for boolean fields in filter parsing.
     //              Extracts the field name and boolean value from a condition string formatted as "FieldName = value",
     //              validates the field exists in the AccountContactRelation schema and the value is a valid boolean
     //              (true/false), then sets the boolean value on the record. This is primarily used for filtering
     //              the Client_Communication_Contact__c checkbox field.
     // @param condition A string in the format "FieldName = value" where value is 'true' or 'false'
     //                  Example: "Client_Communication_Contact__c = true"
     // @param acrRec The AccountContactRelation record to update with the parsed boolean field value
     // @return AccountContactRelation The updated AccountContactRelation record with the equality field value set
    private static AccountContactRelation handleEqualityBooleanCondition(String condition,
    AccountContactRelation acrRec)
    {

        String key = condition.substringBefore('=').trim();
        String value = condition.substringAfter('=').trim();
        if (acrFieldMap!= null && !acrFieldMap?.isEmpty() && acrFieldMap.containsKey(key) &&
        String.isNotBlank(value) &&
        (
            value.equalsIgnoreCase('true') ||
            value.equalsIgnoreCase('false')
            )
        ) {
            acrRec.put(acrFieldMap.get(key), Boolean.valueOf(value));
        }

        return acrRec;
    }

     // @description Retrieves AccountContactRelation records without any additional filter criteria.
     //              This method returns all ACR records for a given account where at least one role field
     //              (NSP_Service_Roles__c, NSP_Support_Role__c, HRScale_Client_Roles__c) is populated or
     //              the Client_Communication_Contact__c flag is true. Terminated employees are excluded.
     //              This is the default query method when no ACR filter is provided by the user.
     // @param recordId The Account Id to filter AccountContactRelation records
     // @param offSetCount The number of records to skip for pagination
     // @param offSetLimit The maximum number of records to return
     // @return List<AccountContactRelation> A list of AccountContactRelation records meeting the default criteria
    private static List<AccountContactRelation> getAccountContactRelationshipRecords(String recordId ,
    Integer offSetCount ,
    Integer offSetLimit)
    {
        List<AccountContactRelation> returnList = [
            SELECT
            AccountId , Account.Name ,
            ContactId , Contact.FirstName ,
            Contact.LastName , Contact.Name ,
            Client_Communication_Contact__c ,
            NSP_Service_Roles__c , NSP_Support_Role__c ,
            HRScale_Client_Roles__c , Contact.NSP_Preferred_First_Name__c ,
            NSP_Job_Title__c , NSP_Employee_Status__c ,
            NSP_Work_Phone__c , NSP_Work_email__c
            FROM
            AccountContactRelation
            WHERE
            ( AccountId = :recordId )
            AND
            NSP_Employee_Status__c != 'TERMINATED'
            AND
            (
                NSP_Service_Roles__c != NULL OR
                NSP_Support_Role__c != NULL OR
                HRScale_Client_Roles__c != NULL OR
                Client_Communication_Contact__c = TRUE
            )
            WITH SECURITY_ENFORCED
            ORDER BY Contact.Name ASC
            LIMIT :offSetLimit
            OFFSET :offSetCount
        ];

        return returnList;
    }


    private static Map<Id,ResultWrapper> getACRRecords( List<AccountContactRelation> lstACRRecords , Map<Id,ResultWrapper> resultsMap ) {
        for ( AccountContactRelation accConRelation : lstACRRecords ) {
            if ( !resultsMap.containsKey( accConRelation.ContactId ) ) {
                List<String> lstRoles = new List<String>();
                if ( String.isNotBlank( accConRelation.HRScale_Client_Roles__c ) ) {
                    lstRoles.add( accConRelation.HRScale_Client_Roles__c?.replace( ';' , '; ' ) );
                }
                if ( String.isNotBlank( accConRelation.NSP_Service_Roles__c ) ) {
                    lstRoles.add( accConRelation.NSP_Service_Roles__c?.replace( ';' , '; ' ) );
                }
                if ( String.isNotBlank( accConRelation.NSP_Support_Role__c ) ) {
                    lstRoles.add( accConRelation.NSP_Support_Role__c?.replace( ';' , '; ' ) );
                }
                if ( accConRelation.Client_Communication_Contact__c ) {
                    lstRoles.add( NSP_ContactRollupController.getfieldLabel( 'Client_Communication_Contact__c' , 'AccountContactRelation' ) );
                }
                resultsMap.put(
                    accConRelation.ContactId ,
                    new ResultWrapper(
                        new Account(
                            Id=accConRelation.AccountId ,
                            Name=accConRelation.Account.Name
                        ) ,
                        new Contact(
                            Id=accConRelation.ContactId ,
                            FirstName=accConRelation.Contact.FirstName ,
                            LastName=accConRelation.Contact.LastName ,
                            NSP_Preferred_First_Name__c=accConRelation.Contact.NSP_Preferred_First_Name__c
                        ) ,
                        accConRelation.Contact.Name ,
                        null ,
                        String.join( lstRoles , '; ' ) ,
                        accConRelation.NSP_Job_Title__c ,
                        accConRelation.NSP_Employee_Status__c ,
                        accConRelation.NSP_Work_Phone__c ,
                        accConRelation.NSP_Work_email__c
                    )
                );
            }
        }
        return resultsMap;
    }

    //
    // @description : all the roles will be concatenated to one string
    // @param  NSP_Sub_Client_Contact__c, string
    // @return string
    //
    public static string getUpdatedRoles(String allRoles, NSP_Sub_Client_Contact__c subClientCont) {
        List < string > lstRoles = new List < string > ();
        if (allRoles != null) {
            lstRoles.addAll(allRoles?.split('; '));
        }

        string sobjectApiName = 'NSP_Sub_Client_Contact__c';

        if (subClientCont.NSP_On_Site_Supervisor__c && !lstRoles.Contains(getfieldLabel('NSP_On_Site_Supervisor__c', sobjectApiName))) {
            lstRoles.add(getfieldLabel('NSP_On_Site_Supervisor__c', sobjectApiName));
        }
        if (subClientCont.NSP_Payroll_Contact__c && !lstRoles.Contains(getfieldLabel('NSP_Payroll_Contact__c', sobjectApiName))) {
            lstRoles.add(getfieldLabel('NSP_Payroll_Contact__c', sobjectApiName));
        }
        if (subClientCont.NSP_Client_Leave_Administrator__c && !lstRoles.Contains(getfieldLabel('NSP_Client_Leave_Administrator__c', sobjectApiName))) {
            lstRoles.add(getfieldLabel('NSP_Client_Leave_Administrator__c', sobjectApiName));
        }
        if (subClientCont.NSP_WC_Contact__c && !lstRoles.Contains(getfieldLabel('NSP_WC_Contact__c', sobjectApiName))) {
            lstRoles.add(getfieldLabel('NSP_WC_Contact__c', sobjectApiName));
        }
        if (subClientCont.NSP_HR_Contact__c && !lstRoles.Contains(getfieldLabel('NSP_HR_Contact__c', sobjectApiName))) {
            lstRoles.add(getfieldLabel('NSP_HR_Contact__c', sobjectApiName));
        }
        if (subClientCont.NSP_Benefits_Contact__c && !lstRoles.Contains(getfieldLabel('NSP_Benefits_Contact__c', sobjectApiName))) {
            lstRoles.add(getfieldLabel('NSP_Benefits_Contact__c', sobjectApiName));
        }
        if (subClientCont.NSP_Background_Contact__c && !lstRoles.Contains(getfieldLabel('NSP_Background_Contact__c', sobjectApiName))) {
            lstRoles.add(getfieldLabel('NSP_Background_Contact__c', sobjectApiName));
        }
        if (subClientCont.NSP_Unemployment_Contact__c && !lstRoles.Contains(getfieldLabel('NSP_Unemployment_Contact__c', sobjectApiName))) {
            lstRoles.add(getfieldLabel('NSP_Unemployment_Contact__c', sobjectApiName));
        }
        return string.join(lstRoles, '; ');
    }

    //
    // @description : get fieldLabel from ApiName
    // @param apiName of NSP_Sub_Client_Contact__c.
    // @return fieldLabel
    //
    private static String getfieldLabel( String fieldApiName , String obj ) {
        Map<String,Schema.SObjectField> sObjFields = sObjDetails.get( obj );
        return sObjFields.get( fieldApiName ).getDescribe().getLabel();
    }

    public class ResultWrapper {
        @AuraEnabled public Account account { get; set; }
        @AuraEnabled public Contact contact { get; set; }
        @AuraEnabled public String contactName { get; set; }
        @AuraEnabled public List<NSP_Sub_Client__c> subClients { get; set; }
        @AuraEnabled public String allRoles { get; set; }
        @AuraEnabled public String jobTitle{ get; set; }
        @AuraEnabled public String employeeStatus{ get; set; }
        @AuraEnabled public String workPhone{ get; set; }
        @AuraEnabled public String workEmail{ get; set; }

        public ResultWrapper(
            Account account ,
            Contact contact ,
            String contactName ,
            List<NSP_Sub_Client__c> subClients ,
            String allRoles ,
            String jobTitle ,
            String employeeStatus ,
            String workPhone ,
            String workEmail
            )
        {
            this.account = account;
            this.contact = contact;
            this.contactName = contactName;
            this.subClients = subClients;
            this.allRoles = allRoles;
            this.jobTitle = jobTitle;
            this.employeeStatus = employeeStatus;
            this.workPhone = workPhone;
            this.workEmail = workEmail;
        }
    }

    private static Map<String, Map<String,Schema.SObjectField>> sObjDetails {
        private get {
            if ( sObjDetails == null ) {
                sObjDetails = new Map<String,Map<String,Schema.SObjectField>>();
                String[] types = new String[]{
                    'AccountContactRelation' ,
                    'NSP_Sub_Client_Contact__c'
                };
                for ( Schema.DescribeSobjectResult sObj : Schema.describeSObjects( types ) ) {
                    sObjDetails.put(
                        sObj.getName() ,
                        Schema.getGlobalDescribe().get( sObj.getName() ).getDescribe().fields.getMap()
                    );
                }
            }
            return sObjDetails;
        }
        private set;
    }

}
//