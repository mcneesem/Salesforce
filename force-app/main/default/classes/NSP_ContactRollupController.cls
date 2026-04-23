// Contact - Roll up visibility of all Contact roles at the Account Page from AccountContactRelation and SubClientContacts
// 5/19/2022
public without sharing class NSP_ContactRollupController {
    // test w/ NSP_ContactRollupController_Test (98%)

    // Global Variables
    private static Set<String> paidNonPaidValues = new Set<String>{
        'Paid WSEE' ,
        'Active Non-Paid User'
    };

    private static final String includesStringValue = ' INCLUDES ';

    private static final List<Schema.SObjectField> subClientContactFieldsToCheck = new List<Schema.SObjectField>{
        NSP_Sub_Client_Contact__c.NSP_On_Site_Supervisor__c,
        NSP_Sub_Client_Contact__c.NSP_Payroll_Contact__c,
        NSP_Sub_Client_Contact__c.NSP_Client_Leave_Administrator__c,
        NSP_Sub_Client_Contact__c.NSP_WC_Contact__c,
        NSP_Sub_Client_Contact__c.NSP_HR_Contact__c,
        NSP_Sub_Client_Contact__c.NSP_Benefits_Contact__c,
        NSP_Sub_Client_Contact__c.NSP_Background_Contact__c,
        NSP_Sub_Client_Contact__c.NSP_Unemployment_Contact__c
    };

    // Properties
    private static Map<String, Schema.SObjectField> subClientContactFieldMap {
        private get {
            if (subClientContactFieldMap == null) {
                subClientContactFieldMap =  Schema.SObjectType.NSP_Sub_Client_Contact__c.fields.getMap();
            }

            return subClientContactFieldMap;
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
            resultsMap = NSP_ContactRollupController.getACR(recordId, resultsMap, offSetCount, offSetLimit, acrFilter);
            resultsMap = NSP_ContactRollupController.getSubClientContacts(recordId, resultsMap, offSetCount, offSetLimit, subClientFilter);
            if (allFilters != null && allFilters.size() > 0) {
                //fetch filtered result of ACR and Sub clients combined together based on all filters[] passed to regex expression
                String regex = '^';
                for (String filter: allFilters) {
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

    // @description: Retrieves and filters Sub Client Contact records for an account
    // @param recordId: Account Id
    // @param resultsMap: Map of existing contact results
    // @param offSetCount: Pagination offset (unused for sub-client contacts)
    // @param offSetLimit: Pagination limit (unused for sub-client contacts)
    // @param subClientFilter: Comma-separated list of field API names to filter by
    // @return: Updated results map with sub-client contact data
    public static Map<Id,ResultWrapper> getSubClientContacts(
        String recordId ,
        Map<Id,ResultWrapper> resultsMap ,
        Integer offSetCount ,
        Integer offSetLimit ,
        String subClientFilter
        )
    {
        // Retrieve all sub-client contacts for the account
        List<NSP_Sub_Client_Contact__c> queryResults = NSP_ContactRollupController.getQueryResultsOfSCC( recordId );
        // When there is sub client filter
        if ( ( queryResults != null )
            && !queryResults.isEmpty()
            && String.isNotBlank( subClientFilter )
            )
        {
            NSP_Sub_Client_Contact__c filterTemplate = NSP_ContactRollupController.buildFilterTemplate( subClientFilter );
            queryResults = NSP_ContactRollupController.applySubClientFilter(
                queryResults ,
                filterTemplate
            );
        }
        // Apply pagination to the results
        queryResults = (List<NSP_Sub_Client_Contact__c>)NSP_ContactRollupController.applyPagination(
            (List<SObject>)queryResults ,
            offSetCount ,
            offSetLimit
        );
        return NSP_ContactRollupController.getSubClientContactRecords(
            queryResults ,
            resultsMap ,
            recordId
        );
    }

    // @description : Fetch sub client contact records based on default filters
    // @params: recordId, offSetCount, offSetLimit, paidNonPaidValues
    // @return : List<NSP_Sub_Client_Contact__c>
    private static List<NSP_Sub_Client_Contact__c> getQueryResultsOfSCC( String recordId ) {
        return [
            SELECT
                Id ,
                Name ,
                NSP_Sub_Client__c ,
                NSP_Sub_Client__r.Name ,
                NSP_Contact__r.Name ,
                NSP_Sub_Client__r.NSP_Account__r.Name ,
                NSP_Sub_Client__r.NSP_Account__c ,
                NSP_Contact__r.FirstName ,
                NSP_Contact__r.LastName ,
                NSP_Contact__r.NSP_Preferred_First_Name__c ,
                NSP_Contact__c ,
                NSP_On_Site_Supervisor__c ,
                NSP_Payroll_Contact__c ,
                NSP_Client_Leave_Administrator__c ,
                NSP_WC_Contact__c ,
                NSP_HR_Contact__c ,
                NSP_Benefits_Contact__c ,
                NSP_Background_Contact__c ,
                NSP_Unemployment_Contact__c ,
                NSP_Paid_Non_Paid__c ,
                NSP_Employee_Status__c
            FROM NSP_Sub_Client_Contact__c
            WHERE (
                ( NSP_Sub_Client__r.NSP_Account__c = :recordId )
                AND ( NSP_Paid_Non_Paid__c IN :NSP_ContactRollupController.paidNonPaidValues )
                AND ( NSP_Employee_Status__c != 'Terminated' )
                AND ( NSP_Paid_Non_Paid__c != 'Inactive Non-Paid User' )
                AND (
                    ( NSP_On_Site_Supervisor__c = true )
                    OR ( NSP_Payroll_Contact__c = true )
                    OR ( NSP_Client_Leave_Administrator__c = true )
                    OR ( NSP_WC_Contact__c = true )
                    OR ( NSP_HR_Contact__c = true )
                    OR ( NSP_Benefits_Contact__c = true )
                    OR ( NSP_Background_Contact__c = true )
                    OR ( NSP_Unemployment_Contact__c = true )
                )
            )
            ORDER BY NSP_Contact__r.Name ASC
        ];
    }

    // @description: Builds a filter template object based on comma-separated field names
    // @param subClientFilter: Comma-separated list of field API names
    // @return: NSP_Sub_Client_Contact__c object with specified fields set to true
    private static NSP_Sub_Client_Contact__c buildFilterTemplate( String subClientFilter ) {
        NSP_Sub_Client_Contact__c filterTemplate = NSP_ContactRollupController.getSubClientContactObj();
        subClientFilter = ( String.isNotBlank( subClientFilter ) ? subClientFilter : '' );
        List<String> filterFields = subClientFilter.split( ',' );
        if ( !filterFields.isEmpty() ) {
            for ( String fieldName : filterFields ) {
                String trimmedField = fieldName.trim();
                if ( String.isNotBlank( trimmedField )
                    && subClientContactFieldMap.containsKey( trimmedField ) ) {
                    filterTemplate.put(
                        subClientContactFieldMap.get( trimmedField ) ,
                        true
                    );
                }
            }
        }
        return filterTemplate;
    }

    // @description: Creates a new NSP_Sub_Client_Contact__c object with all boolean fields set to false.
    //               Uses the static subClientContactFieldsToCheck list for consistent field management.
    // @return: NSP_Sub_Client_Contact__c with all boolean fields initialized to false
    private static NSP_Sub_Client_Contact__c getSubClientContactObj() {
        NSP_Sub_Client_Contact__c tempObj = new NSP_Sub_Client_Contact__c();
        // Initialize all fields from the static list to false
        for ( Schema.SObjectField field : NSP_ContactRollupController.subClientContactFieldsToCheck ) {
            tempObj.put( field , false );
        }
        return tempObj;
    }

    // @description: Filters a list of sub-client contacts based on the filter template
    // @param contacts: List of contacts to filter
    // @param filterTemplate: Template with filter criteria
    // @return: Filtered list of contacts
    private static List<NSP_Sub_Client_Contact__c> applySubClientFilter(
        List<NSP_Sub_Client_Contact__c> records ,
        NSP_Sub_Client_Contact__c filterTemplate
        )
    {
        List<NSP_Sub_Client_Contact__c> filteredResults = new List<NSP_Sub_Client_Contact__c>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( NSP_Sub_Client_Contact__c record : records ) {
                if ( NSP_ContactRollupController.parseSubClientContactRec( record , filterTemplate ) ) {
                    filteredResults.add( record );
                }
            }
        }
        return filteredResults;
    }

    // @description: Validates if a Sub Client Contact record matches filter criteria from template record.
    //               Uses static field list for optimal performance and maintainability.
    // @param scc: The NSP_Sub_Client_Contact__c record to validate
    // @param sccTemp: The template record containing filter criteria (fields set to true require matching)
    // @return: Boolean - true if all filter criteria are met, false otherwise
    private static Boolean parseSubClientContactRec(
        NSP_Sub_Client_Contact__c scc ,
        NSP_Sub_Client_Contact__c sccTemp
        )
    {
        Boolean returnFlag = true;
        if ( ( scc != null ) && ( sccTemp != null ) ) {
            // Iterate through static field list - no list recreation overhead
            for ( Schema.SObjectField field : NSP_ContactRollupController.subClientContactFieldsToCheck ) {
                // Early exit on first failed match for optimal performance
                if ( ( sccTemp.get( field ) == true ) && ( scc.get( field ) != true ) ) {
                    returnFlag = false;
                }
            }
        }
        return returnFlag;
    }

    private static Map<Id,ResultWrapper> getSubClientContactRecords( List<NSP_Sub_Client_Contact__c> lstSubClientContacts , Map<Id,ResultWrapper> resultsMap , String recordId ) {
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
    // @return String
    //
    private static Map<Id,ResultWrapper> getACR(
        String recordId ,
        Map<Id,ResultWrapper> resultsMap ,
        Integer offSetCount ,
        Integer offSetLimit ,
        String acrFilter
        )
    {
        List<AccountContactRelation> filteredResults = new List<AccountContactRelation>();
        List<AccountContactRelation> queryResults = NSP_ContactRollupController.getAccountContactRelationshipRecords(
            recordId
        );
        if ( String.isNotBlank( acrFilter )
            && ( queryResults != null )
            && !queryResults?.isEmpty()
            )
        {
            AccountContactRelation acrTempRec = new AccountContactRelation(
                NSP_Service_Roles__c=null ,
                NSP_Support_Role__c=null ,
                HRScale_Client_Roles__c=null ,
                Client_Communication_Contact__c=false
            );
            acrTempRec = NSP_ContactRollupController.parseAcrFilter(
                acrFilter ,
                acrTempRec
            );
            for ( AccountContactRelation acr : queryResults ) {
                if ( NSP_ContactRollupController.parseAccountContactRelationRec( acr , acrTempRec ) ) {
                    filteredResults.add( acr );
                }
            }
        }
        if ( ( filteredResults != null ) && !filteredResults?.isEmpty() ) {
            queryResults = filteredResults;
        }
        // Apply pagination to the results
        queryResults = (List<AccountContactRelation>)NSP_ContactRollupController.applyPagination(
            (List<SObject>)queryResults ,
            offSetCount ,
            offSetLimit
        );
        return NSP_ContactRollupController.getACRRecords(
            queryResults ,
            resultsMap
        );
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
    private static List<AccountContactRelation> getAccountContactRelationshipRecords( String recordId ) {
        List<AccountContactRelation> returnList = [
            SELECT
                AccountId ,
                Account.Name ,
                ContactId ,
                Contact.FirstName ,
                Contact.LastName ,
                Contact.Name ,
                Client_Communication_Contact__c ,
                NSP_Service_Roles__c ,
                NSP_Support_Role__c ,
                HRScale_Client_Roles__c ,
                Contact.NSP_Preferred_First_Name__c ,
                NSP_Job_Title__c ,
                NSP_Employee_Status__c ,
                NSP_Work_Phone__c ,
                NSP_Work_email__c
            FROM AccountContactRelation
            WHERE (
                ( AccountId = :recordId )
                AND ( NSP_Employee_Status__c != 'TERMINATED' )
                AND (
                    ( NSP_Service_Roles__c != null )
                    OR ( NSP_Support_Role__c != null )
                    OR ( HRScale_Client_Roles__c != null )
                    OR ( Client_Communication_Contact__c = true )
                )
            )
            WITH SECURITY_ENFORCED
            ORDER BY Contact.Name ASC
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
    private static AccountContactRelation parseAcrFilter(
        String acrFilter ,
        AccountContactRelation acrRec
        )
    {
        List<String> conditions = null;
        if ( String.isNotBlank( acrFilter ) ) {
            conditions = acrFilter.split( ' AND ' );
        }
        if ( ( conditions != null ) && !conditions?.isEmpty() ) {
            for( String condition : conditions ) {
                if ( condition.contains( includesStringValue ) ) {
                    acrRec = NSP_ContactRollupController.handleIncludesCondition(
                        condition ,
                        acrRec
                    );
                }
                if ( condition.contains( ' = ' ) ) {
                    acrRec = NSP_ContactRollupController.handleEqualityBooleanCondition(
                        condition ,
                        acrRec
                    );
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
    private static AccountContactRelation handleIncludesCondition(
        String condition ,
        AccountContactRelation acrRec
        )
    {
        if ( String.isNotBlank( condition )
            && condition.contains( includesStringValue )
            )
        {
            String key = condition.substringBefore( includesStringValue ).trim();
            String value = condition.substringBetween( '(' , ')' ).trim();
            if ( ( acrFieldMap != null )
                && !acrFieldMap?.isEmpty()
                && acrFieldMap.containsKey( key )
                )
            {
                acrRec.put(
                    acrFieldMap.get( key ) ,
                    value
                );
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
    private static AccountContactRelation handleEqualityBooleanCondition(
        String condition ,
        AccountContactRelation acrRec
        )
    {
        String key = condition.substringBefore( '=' ).trim();
        String value = condition.substringAfter( '=' ).trim();
        if ( ( acrFieldMap != null )
            && !acrFieldMap?.isEmpty()
            && acrFieldMap.containsKey( key )
            && String.isNotBlank( value )
            && ( value.equalsIgnoreCase( 'true' )
                || value.equalsIgnoreCase( 'false' )
                )
            )
        {
            acrRec.put(
                acrFieldMap.get( key ) ,
                Boolean.valueOf( value )
            );
        }
        return acrRec;
    }

    // @description: Validates if an AccountContactRelation record matches filter criteria from acrTempRec.
    //               Applies filters only when fields in acrTempRec are not null or false.
    // @param acr: The AccountContactRelation record to validate
    // @param acrTempRec: The filter criteria record
    // @return: Boolean - true if all filters pass, false otherwise
    private static Boolean parseAccountContactRelationRec(
        AccountContactRelation acr ,
        AccountContactRelation acrTempRec
        )
    {
        Boolean returnFlag = true;
        // Apply filter for NSP_Service_Roles__c if not null
        if ( String.isNotBlank( acrTempRec.NSP_Service_Roles__c )
            && ( String.isBlank( acr.NSP_Service_Roles__c )
                || !acrTempRec.NSP_Service_Roles__c.contains( acr.NSP_Service_Roles__c )
                )
            )
        {
            returnFlag = false;
        }
        // Apply filter for NSP_Support_Role__c if not null
        if ( String.isNotBlank( acrTempRec.NSP_Support_Role__c )
            && ( String.isBlank(acr.NSP_Support_Role__c)
                || !acrTempRec.NSP_Support_Role__c.contains( acr.NSP_Support_Role__c )
                )
            )
        {
            returnFlag = false;
        }
        // Apply filter for HRScale_Client_Roles__c if not null
        if ( String.isNotBlank( acrTempRec.HRScale_Client_Roles__c )
            && ( String.isBlank( acr.HRScale_Client_Roles__c )
                || !acrTempRec.HRScale_Client_Roles__c.contains( acr.HRScale_Client_Roles__c )
                )
            )
        {
            returnFlag = false;
        }
        // Apply filter for Client_Communication_Contact__c if true
        if ( ( acrTempRec.Client_Communication_Contact__c == true )
            && ( acr.Client_Communication_Contact__c != true )
            )
        {
            returnFlag = false;
        }
        return returnFlag;
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

    // @description: Apply pagination to any list of SObject records
    //               This generic method eliminates code duplication and provides consistent pagination
    //               behavior across different object types (AccountContactRelation, NSP_Sub_Client_Contact__c, etc.)
    // @param records: List of SObject records to paginate
    // @param offSetCount: Number of records to skip (starting index)
    // @param offSetLimit: Maximum number of records to return per page
    // @return: Paginated list of SObject records, or original list if pagination params are null/invalid
    private static List<SObject> applyPagination(
        List<SObject> records ,
        Integer offSetCount ,
        Integer offSetLimit
        )
    {
        List<SObject> paginatedResults = new List<SObject>();
        // Apply pagination only if valid params are provided
        // Handle case where offsetCount is less than or equal to records size
        if ( ( offSetCount != null )
            && ( offSetLimit != null )
            && ( records != null )
            && !records.isEmpty()
            && ( offSetCount <= records.size() )
            )
        {
            Integer endIndex = Math.min( ( offSetCount + offSetLimit ) , records.size() );
            // Extract paginated subset - no redundant bounds check needed (Math.min handles it)
            for ( Integer i=offSetCount ; i < endIndex ; i++ ) {
                paginatedResults.add( records[i] );
            }
        }
        return paginatedResults;
    }

    //
    // @description : all the roles will be concatenated to one String
    // @param  NSP_Sub_Client_Contact__c, String
    // @return String
    //
    public static String getUpdatedRoles( String allRoles , NSP_Sub_Client_Contact__c subClientCont ) {
        List<String> lstRoles = new List<String>();
        if ( allRoles != null ) {
            lstRoles.addAll( allRoles?.split( '; ' ) );
        }
        String sobjectApiName = 'NSP_Sub_Client_Contact__c';
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
        return String.join(lstRoles, '; ');
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