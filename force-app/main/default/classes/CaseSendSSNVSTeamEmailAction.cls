// Invocable Apex to gather Sub Clients and their Contacts related to a Case's Account and send SSNVS Team notification emails.
public with sharing class CaseSendSSNVSTeamEmailAction {
    // test w/ CaseSendSSNVSTeamEmailActionTest (92%)

    // Error Messages
    private static final String ERR_NO_CONTACT = 'No Contact Found';

    // Domain constants to avoid magic strings
    private static final Set<String> ALLOWED_EMPLOYEE_STATUS = new Set<String>{
        'HIRED' ,
        'REHIRED'
    };

    private static final Set<String> ALLOWED_PAID_FLAGS = new Set<String>{
        'Paid WSEE' ,
        'Active Non-Paid User'
    };

    //
    // Entry point from Flow to retrieve related Sub Clients/Contacts and send notification emails.
    //
    // @param inputParams List of ActionInputParams from Flow. Only the first element is processed.
    // @return List<ActionOutputParams> Single-element list when emails are sent; empty when nothing qualifies.
    //
    // Invocable Config:
    // @label Get Sub Client and Sub Client Contacts
    // @category Case
    //
    @InvocableMethod(label='Get Sub Client and Sub Client Contacts' description='Get Sub Client and Sub Client Contacts' category='Case')
    public static List<ActionOutputParams> getSubClientAndSubClientContacts( List<ActionInputParams> inputParams ) {
        List<ActionOutputParams> results = new List<ActionOutputParams>();
        if ( ( inputParams != null ) && !inputParams.isEmpty() ) {
            for ( ActionInputParams inParams : inputParams ) {
                results.add( CaseSendSSNVSTeamEmailAction.processContactAndSubclients( inParams ) );
            }
        }
        return results;
    }

    // Wrapper class for Flow input variables.
    // Flow passes a collection; we currently read the first element.
    public class ActionInputParams {
        @InvocableVariable(required=true)
        public Case caseObj;
        @InvocableVariable(required=true)
        public String accountId;
        @InvocableVariable(required=true)
        public String emailBody;
        @InvocableVariable(required=true)
        public String emailSubject;
    }

    // Wrapper class for Flow output variables.
    // - subClientContactIdList: IDs of Sub Client Contact records that were emailed
    // - errorEntries: list of (recordId, errorMessage)
    public class ActionOutputParams {
        @InvocableVariable
        public List<NSP_Sub_Client_Contact__c> subClientContacts;
        @InvocableVariable
        public List<NSP_Error_Log__c> errorEntries;
    }

    //
    //
    //

    //
    // Process Contacts and sub client contacts based on inputs from the flow
    //
    // @param inParams ActionInputParams
    // @return ActionOutputParams
    //
    private static ActionOutputParams processContactAndSubclients( ActionInputParams inputRecord ) {
        ActionOutputParams result = new ActionOutputParams();
        // Guard input
        if ( ( inputRecord != null ) && ( inputRecord.caseObj != null ) ) {
            // Load case contact (only Active/HIRED/REHIRED)
            Contact caseContact = CaseSendSSNVSTeamEmailAction.getCaseContact( inputRecord.caseObj );
            Map<String,String> errorMap = new Map<String,String>();
            // Valid Contact Not Found related to Case
            if ( ( caseContact != null ) && ( inputRecord.caseObj.ContactId == caseContact.Id ) ) {
                result.subClientContacts = new List<NSP_Sub_Client_Contact__c>(
                    CaseSendSSNVSTeamEmailAction.processSubClientRecordsBasedOnContact(
                        inputRecord ,
                        caseContact ,
                        errorMap
                    )
                );
            } else {
                errorMap.put(
                    inputRecord.caseObj.Id ,
                    CaseSendSSNVSTeamEmailAction.ERR_NO_CONTACT
                );
            }
            if ( ( errorMap != null ) && !errorMap.isEmpty() ) {
                result.errorEntries = CaseSendSSNVSTeamEmailAction.buildErrors( errorMap );
            }
        }
        return result;
    }

    //
    // Process Sub Client Contacts based on Contact
    //
    // @param inParams ActionInputParams
    // @param caseContact Case Contact
    // @param errorMap Error Map
    // @return Set of Sub Client Contacts that were emailed successfully
    //
    private static Set<NSP_Sub_Client_Contact__c> processSubClientRecordsBasedOnContact(
        ActionInputParams inParams ,
        Contact caseContact ,
        Map<String,String> errorMap
        )
    {
        Set<NSP_Sub_Client_Contact__c> response = new Set<NSP_Sub_Client_Contact__c>();
        if ( ( inParams != null ) && ( caseContact != null ) ) {
            Map<Id,NSP_Sub_Client__c> subClientMap = CaseSendSSNVSTeamEmailAction.queryActiveSubClients(
                inParams.caseObj?.AccountId ,
                inParams.accountId
            );
            // Collect sub client contacts with atleast one sub client contact that is related to case contact
            List<NSP_Sub_Client_Contact__c> subClientContacts = new List<NSP_Sub_Client_Contact__c>();
            if ( ( subClientMap != null ) && !subClientMap.isEmpty() ) {
                subClientContacts = CaseSendSSNVSTeamEmailAction.collectSubClientContacts(
                    subClientMap?.values() ,
                    caseContact ,
                    errorMap
                );
            }
            // Evaluate eligibility and collect reasons
            List<NSP_Sub_Client_Contact__c> eligibleSubClientContacts = new List<NSP_Sub_Client_Contact__c>();
            if ( ( subClientContacts != null ) && !subClientContacts.isEmpty() ) {
                eligibleSubClientContacts = CaseSendSSNVSTeamEmailAction.evaluateEligibility(
                    subClientContacts ,
                    errorMap
                );
            }
            // Deliver emails to eligible
            if ( ( ( errorMap == null ) || errorMap.isEmpty() )
                && ( ( eligibleSubClientContacts != null ) && !eligibleSubClientContacts.isEmpty() )
                )
            {
                response = CaseSendSSNVSTeamEmailAction.deliverEmails(
                    caseContact ,
                    inParams ,
                    eligibleSubClientContacts
                );
            }
        }
        return response;
    }

    //
    // Build error entries from error map, respecting Blank Email filtering behavior
    //
    // @param errorMap Map of Contact Id -> Error Message
    // @return List of Error Log records
    //
    private static List<NSP_Error_Log__c> buildErrors( Map<String,String> errorMap ) {
        List<NSP_Error_Log__c> entries = new List<NSP_Error_Log__c>();
        if ( ( errorMap != null ) && !errorMap.isEmpty() ) {
            for ( String idStr : errorMap.keySet() ) {
                entries.add(
                    new NSP_Error_Log__c(
                        NSP_Record_Id__c=idStr ,
                        NSP_Description__c=errorMap.get( idStr )
                    )
                );
            }
        }
        return entries;
    }

    //
    // Formats email body and sends emails via Flow to each recipient.
    //
    // @param contactObj Case Contact used for header tokens
    // @param inParams ActionInputParams that can be used to build email body, subject, etc.
    // @param subClientContacts Contacts under Sub Client to notify
    // @return Set<String> IDs of Sub Client Contacts that were emailed successfully
    //
    private static Set<NSP_Sub_Client_Contact__c> deliverEmails(
        Contact caseContact ,
        ActionInputParams inParams ,
        List<NSP_Sub_Client_Contact__c> subClientContacts
        )
    {
        Set<NSP_Sub_Client_Contact__c> sentSubClientContacts = new Set<NSP_Sub_Client_Contact__c>();
        if ( ( caseContact != null )
            && ( inParams != null )
            && ( subClientContacts != null )
            && !subClientContacts.isEmpty()
            )
        {
            for ( NSP_Sub_Client_Contact__c subClientContact : subClientContacts ) {
                if ( subClientContact != null ) {
                    String formattedEmailBody = CaseSendSSNVSTeamEmailAction.getFormattedEmailBody(
                        inParams.emailBody ,
                        subClientContact ,
                        caseContact
                    );
                    Boolean emailSent = CaseSendSSNVSTeamEmailAction.callEmailAction(
                        inParams.emailSubject ,
                        formattedEmailBody ,
                        new List<String>{ subClientContact.NSP_Work_Email__c } ,
                        inParams.caseObj?.Id
                    );
                    if ( emailSent ) {
                        sentSubClientContacts.add( subClientContact );
                    }
                }
            }
        }
        return sentSubClientContacts;
    }

    //
    // Compose the email body using dynamic parameters and the static body provided by Flow.
    //
    // @param emailBody The base HTML/text to append after the header
    // @param subClientContact The Sub Client Contact to include sub client context
    // @param contactObj The Case Contact for Per ID/Workday ID and name
    // @return Fully formatted HTML string
    //
    private static String getFormattedEmailBody(
        String emailBody ,
        NSP_Sub_Client_Contact__c subClientContact ,
        Contact contactObj
        )
    {
        String formatted = '';
        if ( ( subClientContact != null )
            && ( contactObj != null )
            && String.isNotBlank( emailBody )
            )
        {
            formatted = '<html><body>';
            formatted += '<b><p>SSN Mismatch Client Notice</p></b><br />';
            formatted += '<b>SSN Mismatch / ' + subClientContact.NSP_AIMS_Sub_Client__c + ' / ';
            if ( String.isNotBlank( contactObj.NSP_Per_ID__c ) ) {
                formatted += contactObj.NSP_Per_ID__c + ' / ';
            } else if ( String.isNotBlank( contactObj.Workday_Employee_ID__c ) ) {
                formatted += contactObj.Workday_Employee_ID__c + ' / ';
            }
            formatted += contactObj.FirstName + ' ' + contactObj.LastName + '</b><br/>';
            formatted += emailBody;
            formatted += '</body></html>';
        }
        return formatted;
    }

    //
    // Invokes the Send_Email autolaunched Flow to deliver the email.
    //
    // @param emailSubject Subject line
    // @param emailBody HTML body
    // @param listOfToAddresses List of recipient email addresses
    // @param caseObj Case context (recordId for the Flow)
    // @return true if Flow started without exception; false otherwise
    //
    private static Boolean callEmailAction(
        String emailSubject ,
        String emailBody ,
        List<String> listOfToAddresses ,
        String caseRecordId
        )
    {
        Boolean success = false;
        try {
            Map<String,Object> inputs = CaseSendSSNVSTeamEmailAction.setAndGetEmailInputs(
                emailSubject ,
                emailBody ,
                listOfToAddresses ,
                caseRecordId
            );
            if ( ( inputs != null ) && !inputs.isEmpty() ) {
                Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email( inputs );
                sendEmailFlow.start();
                success = true;
            }
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                CaseSendSSNVSTeamEmailAction.class.getName() ,
                'callEmailAction' ,
                e
            );
        }
        return success;
    }

    private static Map<String,Object> setAndGetEmailInputs(
        String emailSubject ,
        String emailBody ,
        List<String> listOfToAddresses ,
        String caseRecordId
        )
    {
        Map<String,Object> inputs = new Map<String,Object>();
        inputs.put( 'recordId' , caseRecordId );
        inputs.put( 'toEmailAddresses' , listOfToAddresses );
        inputs.put( 'emailSubject' , emailSubject );
        inputs.put( 'emailBody' , emailBody );
        inputs.put( 'logEmail' , true );
        inputs.put( 'senderEmail' , 'ssnvs@insperity.com' );
        return inputs;
    }

    //
    // @param subClients List of Sub Clients (with child contacts pre-fetched)
    // @param caseContact The Case Contact to match on NSP_Contact__c
    // @param outputParams Output wrapper to carry any per-contact errors
    // @return List of qualifying Sub Client Contacts
    //
    private static List<NSP_Sub_Client_Contact__c> collectSubClientContacts(
        List<NSP_Sub_Client__c> subClients ,
        Contact caseContact ,
        Map<String,String> errorMap
        )
    {
        List<NSP_Sub_Client_Contact__c> returnSSCList = new List<NSP_Sub_Client_Contact__c>();
        if ( ( subClients != null )
            && !subclients.isEmpty()
            && ( caseContact != null )
            )
        {
            for ( NSP_Sub_Client__c sc : subClients ) {
                List<NSP_Sub_Client_Contact__c> sccs = sc.NSP_Sub_Client_Contacts__r;
                if ( ( sccs != null ) && !sccs.isEmpty() ) {
                    returnSSCList.addAll(
                        CaseSendSSNVSTeamEmailAction.getEligibleCaseContact(
                            sccs ,
                            caseContact
                        )
                    );
                }
            }
        }
        if ( ( returnSSCList == null ) || returnSSCList.isEmpty() ) {
            errorMap.put(
                caseContact.Id ,
                CaseSendSSNVSTeamEmailAction.ERR_NO_CONTACT
            );
        }
        return returnSSCList;
    }

    //
    // Get Eligible subclients when compared to contact
    //
    // @param subClientContacts List of Sub Client Contacts
    // @param caseContact The Case Contact to match on NSP_Contact__c
    //
    private static List<NSP_Sub_Client_Contact__c> getEligibleCaseContact(
        List<NSP_Sub_Client_Contact__c> subClientContacts ,
        Contact caseContact
        )
    {
        List<NSP_Sub_Client_Contact__c> returnList = new List<NSP_Sub_Client_Contact__c>();
        if ( ( subClientContacts != null )
            && !subClientContacts.isEmpty()
            && ( caseContact != null )
            )
        {
            for ( NSP_Sub_Client_Contact__c subClientContact : subClientContacts ) {
                Boolean statusAndRoleCheck = (
                    CaseSendSSNVSTeamEmailAction.contactStatusCheck( subClientContact )
                    && CaseSendSSNVSTeamEmailAction.contactPaidNonPaidCheck( subClientContact )
                );
                if ( ( subClientContact != null )
                    && ( subClientContact.NSP_Contact__c == caseContact.Id )
                    && statusAndRoleCheck)
                {
                    returnList.addAll( subClientContacts );
                }
            }
        }
        return returnList;
    }

    //
    // Evaluate eligibility of Sub Client Contact based on Employee Status
    //
    // @param subClientContact Sub Client Contact
    // @return Boolean
    //
    private static Boolean contactStatusCheck( NSP_Sub_Client_Contact__c subClientContact ) {
        return (
            ( subClientContact != null )
            && String.isNotBlank( subClientContact.NSP_Employee_Status__c )
            && CaseSendSSNVSTeamEmailAction.ALLOWED_EMPLOYEE_STATUS.contains( subClientContact.NSP_Employee_Status__c )
        );
    }

    //
    // Evaluate eligibility of Sub Client Contact based on Employee Paid/Non-Paid value
    //
    // @param subClientContact Sub Client Contact
    // @return Boolean
    //
    private static Boolean contactPaidNonPaidCheck( NSP_Sub_Client_Contact__c subClientContact ) {
        return (
            ( subClientContact != null )
            && String.isNotBlank( subClientContact.NSP_Paid_Non_Paid__c )
            && CaseSendSSNVSTeamEmailAction.ALLOWED_PAID_FLAGS.contains( subClientContact.NSP_Paid_Non_Paid__c )
        );
    }

    //
    // Apply business rules to filter eligible Sub Client Contacts and populate errors for ineligible ones.
    //
    // @param subClientContacts Candidate contacts
    // @param outputParams Output wrapper to hold error map per contact
    // @return Eligible contacts only
    //
    private static List<NSP_Sub_Client_Contact__c> evaluateEligibility(
        List<NSP_Sub_Client_Contact__c> subClientContacts ,
        Map<String,String> errorMap
        )
    {
        List<NSP_Sub_Client_Contact__c> eligibleSubClientContacts = new List<NSP_Sub_Client_Contact__c>();
        if ( ( subClientContacts != null ) && !subClientContacts.isEmpty() ) {
            for ( NSP_Sub_Client_Contact__c scc : subClientContacts ) {
                Boolean isEligibleSubClientContact = CaseSendSSNVSTeamEmailAction.getEligibleSubClientContact( scc , errorMap );
                if ( isEligibleSubClientContact == true ) {
                    eligibleSubClientContacts.add( scc );
                }
            }
        }
        if ( ( ( errorMap == null ) || errorMap.isEmpty() )
            && ( ( eligibleSubClientContacts == null ) || eligibleSubClientContacts.isEmpty() )
            )
        {
            errorMap?.put( null , 'Not Eligible' );
        }
        return eligibleSubClientContacts;
    }

    //
    // Evaluate eligibility of Sub Client Contact based on Employee Status and Paid/Non-Paid
    //
    // @param subClientContact Sub Client Contact
    // @return Boolean
    //
    private static Boolean getEligibleSubClientContact( NSP_Sub_Client_Contact__c subClientContact , Map<String,String> errorMap ) {
        Boolean validityCheck = false;
        if ( subClientContact != null ) {
            Boolean statusOk = CaseSendSSNVSTeamEmailAction.contactStatusCheck( subClientContact );
            String activeNonPaidRole = 'Active Non-Paid User';
            String paidWorkSiteRole = 'Paid WSEE';
            Boolean onSiteSupervisorOrPayrollContactCheck = (
                ( subClientContact.NSP_On_Site_Supervisor__c == true )
                || ( subClientContact.NSP_Payroll_Contact__c == true )
            );
            Boolean activeNonPaidCheck = (
                String.isBlank( subClientContact.NSP_Employee_Status__c )
                && activeNonPaidRole.equalsIgnoreCase( subClientContact.NSP_Paid_Non_Paid__c )
            );
            if ( onSiteSupervisorOrPayrollContactCheck
                && ( ( statusOk && paidWorkSiteRole.equalsIgnoreCase( subClientContact.NSP_Paid_Non_Paid__c ) )
                    || activeNonPaidCheck
                    )
                )
            {
                if ( String.isNotBlank( subClientContact.NSP_Work_Email__c ) ) {
                    validityCheck = true;
                } else {
                    errorMap?.put( subClientContact.Id , 'Blank Email' );
                }
            }
        }
        return validityCheck;
    }

    //
    // Query Active Sub Clients based on flow inputs
    //
    // @param Account Id and AccountId from Case
    // @return Map of Sub Client Id -> NSP_Sub_Client__c (with child NSP_Sub_Client_Contacts__r)
    //
    private static Map<Id,NSP_Sub_Client__c> queryActiveSubClients( String caseAccountId , String accountId ) {
        Map<Id,NSP_Sub_Client__c> subClientMap = new Map<Id,NSP_Sub_Client__c>();
        if ( String.isNotBlank( caseAccountId ) && String.isNotBlank( accountId ) ) {
            try {
                List<NSP_Sub_Client__c> rows = [
                    SELECT
                        Id ,
                        Name ,
                        NSP_Client__c ,
                        NSP_Sub_Client__c ,
                        Source__c ,
                        NSP_Account__c ,
                        NSP_Account_Status__c ,
                        (
                            SELECT
                                Id ,
                                Name ,
                                NSP_Work_Email__c ,
                                NSP_Paid_Non_Paid__c ,
                                NSP_On_Site_Supervisor__c ,
                                NSP_Payroll_Contact__c ,
                                NSP_AIMS_Sub_Client__c ,
                                NSP_Sub_Client__c ,
                                NSP_Employee_Status__c ,
                                NSP_Contact__c
                            FROM NSP_Sub_Client_Contacts__r
                        )
                    FROM NSP_Sub_Client__c
                    WHERE (
                        ( NSP_Account__c = :accountId )
                        AND ( NSP_Account__c = :caseAccountId )
                        AND ( NSP_Account_Status__c = 'Active' )
                    )
                    WITH USER_MODE
                ];
                if ( ( rows != null ) && !rows.isEmpty() ) {
                    subClientMap = new Map<Id,NSP_Sub_Client__c>( rows );
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    CaseSendSSNVSTeamEmailAction.class.getName(),
                    'queryActiveSubClients',
                    e
                );
            }
        }
        return subClientMap;
    }

    //
    // Query Case Contact based on flow inputs
    //
    // @param caseObj Case record
    // @return List<Contact> Single-element list when found; empty list otherwise
    //
    private static Contact getCaseContact( Case caseObj ) {
        Contact result = null;
        if ( ( caseObj != null ) && ( caseObj.ContactId != null ) ) {
            try {
                List<Contact> rows = [
                    SELECT
                        Id ,
                        NSP_Per_ID__c ,
                        Workday_Employee_ID__c ,
                        FirstName ,
                        LastName ,
                        NSP_Employee_Status__c
                    FROM Contact
                    WHERE (
                        ( Id = :caseObj.ContactId )
                        AND ( NSP_Employee_Status__c IN :CaseSendSSNVSTeamEmailAction.ALLOWED_EMPLOYEE_STATUS )
                    )
                    WITH USER_MODE
                ];
                if ( ( rows != null ) && !rows.isEmpty() ) {
                    result = rows[0];
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    CaseSendSSNVSTeamEmailAction.class.getName() ,
                    'getCaseContact' ,
                    e
                );
            }
        }
        return result;
    }

}
//