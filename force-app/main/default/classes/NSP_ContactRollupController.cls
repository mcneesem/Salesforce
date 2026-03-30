// Contact - Roll up visibility of all Contact roles at the Account Page from AccountContactRelation and SubClientContacts
// 5/19/2022
public without sharing class NSP_ContactRollupController {
    // test w/ NSP_ContactRollupController_Test (90%)

    //
    // @description: Contact - Roll up visibility of all Contact roles at the Account Page from AccountContactRelation and SubClientContacts
    // @param recordId of Account.
    // @return resultWrapper
    //
    @AuraEnabled(cacheable = true)
    public static List < ResultWrapper > getContactRollUpRecords(String recordId, Integer offSetCount, Boolean fullView, List < String > allFilters, String subClientFilter, String acrFilter) {
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
    // @return string

    public static Map < Id, ResultWrapper > getSubClientContacts(string recordId, Map < Id, ResultWrapper > resultsMap,
        Integer offSetCount, Integer offSetLimit, String subClientFilter) {
            Set<String> paidNonPaidValues = new Set<String>{'Paid WSEE', 'Active Non-Paid User'};

        List < String > strList = new List < String > {
            'NSP_On_Site_Supervisor__c',
            'NSP_Payroll_Contact__c',
            'NSP_Client_Leave_Administrator__c',
            'NSP_WC_Contact__c',
            'NSP_HR_Contact__c',
            'NSP_Benefits_Contact__c',
            'NSP_Background_Contact__c',
            'NSP_Unemployment_Contact__c = true'
        };

        string query = 'SELECT Id, Name, NSP_Sub_Client__c, NSP_Sub_Client__r.Name, NSP_Contact__r.Name, NSP_Sub_Client__r.NSP_Account__r.Name, ' +
            'NSP_Sub_Client__r.NSP_Account__c, NSP_Contact__r.firstName, NSP_Contact__r.lastName,NSP_Contact__r.NSP_Preferred_First_Name__c, ' +
            'NSP_Contact__c, NSP_On_Site_Supervisor__c, NSP_Payroll_Contact__c, NSP_Client_Leave_Administrator__c, NSP_WC_Contact__c, ' +
            'NSP_HR_Contact__c, NSP_Benefits_Contact__c, NSP_Background_Contact__c, NSP_Unemployment_Contact__c, NSP_Paid_Non_Paid__c, NSP_Employee_Status__c '+
            ' FROM NSP_Sub_Client_Contact__c ' +
            +'WHERE NSP_Sub_Client__r.NSP_Account__c =: recordId ' +
            ' AND  NSP_Paid_Non_Paid__c IN :paidNonPaidValues AND NSP_Employee_Status__c != \'Terminated \'' +
            ' AND NSP_Paid_Non_Paid__c != \'Inactive Non-Paid User\'';

        if (string.isNotblank(subClientFilter)) {
            query += ' AND (' + subClientFilter + ') ';
        }
        query += ' AND (' + String.join(strList, ' = true OR ') + ') ORDER BY NSP_Contact__r.Name ASC LIMIT :offSetLimit OFFSET :offSetCount'; // Removing Security Enforced as part of DF-03286
        return getSubClinetContactRecords(
            Database.query(query) ,
            resultsMap ,
            recordId
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
        String query = 'SELECT '
            + 'AccountId , Account.Name , '
            + 'ContactId , Contact.FirstName , Contact.LastName , Contact.Name , '
            + 'Client_Communication_Contact__c , NSP_Service_Roles__c , NSP_Support_Role__c , '
            + 'HRScale_Client_Roles__c , Contact.NSP_Preferred_First_Name__c , NSP_Job_Title__c , '
            + 'NSP_Employee_Status__c , NSP_Work_Phone__c , NSP_Work_email__c '
            + 'FROM AccountContactRelation '
            + 'WHERE ( AccountId = :recordId ) AND '
            ;
        if ( String.isBlank( acrFilter ) ) {
            query += '(NSP_Service_Roles__c != NULL OR NSP_Support_Role__c != NULL OR HRScale_Client_Roles__c != NULL OR Client_Communication_Contact__c = TRUE) ';
        } else {
            query += '(' + acrFilter + ')';
        }
        query += ' WITH SECURITY_ENFORCED ORDER BY Contact.Name ASC LIMIT :offSetLimit OFFSET :offSetCount';
        return NSP_ContactRollupController.getACRRecords(
            Database.query( query ) ,
            resultsMap
        );
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