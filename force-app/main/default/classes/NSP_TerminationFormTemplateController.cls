/**
* @description  : Apex Class to process the termination form for the email template.
* @author Shruti Patil
* @date : 10/18/2021
* Name : NSP_TerminationFormTemplateController
*Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Rahul Singh                 03/23/23               DF-03218
*/

public with sharing class NSP_TerminationFormTemplateController {
    // test w/ NSP_TerminationFormTempController_Test (98%)

    public List<WrapTermination> wrapTerminationList { get; set; }
    public List<WrapTermination> wrapReinstatementList { get; set; }

    public NSP_TerminationFormTemplateController() {
        wrapTerminationList = initializeWrapTerminationList( getTermFormList() );
        wrapReinstatementList = initializeWrapReinstatementList( getReinstatementList() );
    }

    private List<WrapTermination> initializeWrapTerminationList( List<NSP_Termination_Form__c> terminationFormList ) {
        return initializeWrapList(
            terminationFormList ,
            wrapTerminationList
        );
    }

    private List<WrapTermination> initializeWrapReinstatementList( List<NSP_Termination_Form__c> terminationFormList ) {
        return initializeWrapList(
            terminationFormList ,
            wrapReinstatementList
        );
    }

    private List<WrapTermination> initializeWrapList( List<NSP_Termination_Form__c> terminationFormList , List<WrapTermination> wrapList ) {
        if ( ( wrapList == null )
            && ( terminationFormList != null )
            && !terminationFormList.isEmpty()
            )
        {
            wrapList = new List<WrapTermination>();
            Map<Id,NSP_Termination_Form__c> accountWithTerminationMap = getMapAccountsToTerminations( terminationFormList );
            Map<Id,List<NSP_Account_Team__c>> accountWithAccountTeammemberMap = getAccountWithAccountTeammemberMap( accountWithTerminationMap );
            if ( !accountWithTerminationMap.isEmpty()
                && !accountWithAccountTeammemberMap.isEmpty()
                )
            {
                for ( NSP_Termination_Form__c termination : terminationFormList ) {
                    Id accountId = termination.NSP_Project_Task__r?.pse__Project__r?.pse__Account__c;
                    Map<String,String> roleMap = getRoleMap(
                        accountWithAccountTeammemberMap ,
                        accountId
                    );
                    wrapList.add( new WrapTermination( termination , roleMap ) );
                }
            }
        }
        return wrapList;
    }

    private Map<Id,NSP_Termination_Form__c> getMapAccountsToTerminations( List<NSP_Termination_Form__c> terminationFormList ) {
        Map<Id,NSP_Termination_Form__c> accountWithTerminationMap = new Map<Id,NSP_Termination_Form__c>();
        for ( NSP_Termination_Form__c termination : terminationFormList ) {
            Id accountId = termination.NSP_Project_Task__r?.pse__Project__r?.pse__Account__c;
            if ( accountId != null ) {
                accountWithTerminationMap.put( accountId , termination );
            }
        }
        return accountWithTerminationMap;
    }

    private Map<Id,List<NSP_Account_Team__c>> getAccountWithAccountTeammemberMap( Map<Id,NSP_Termination_Form__c> accountWithTerminationMap ) {
        Map<Id,List<NSP_Account_Team__c>> accountWithAccountTeammemberMap = new Map<Id,List<NSP_Account_Team__c>>(); 
        if ( !accountWithTerminationMap.isEmpty() ) {
            for ( NSP_Account_Team__c AccTeamMember : [
                        SELECT
                            Id ,
                            NSP_Role__c ,
                            NSP_Account__c ,
                            NSP_Email__c ,
                            NSP_First_Name__c ,
                            NSP_Last_Name__c ,
                            NSP_Primary__c ,
                            NSP_PER_ID__c
                        FROM NSP_Account_Team__c
                        WHERE (
                            ( NSP_Account__c IN :accountWithTerminationMap.keySet() )
                            AND ( NSP_Role__c != null )
                            AND ( NSP_PER_ID__c != '0' )
                        )
                    ]
                )
            {
                if ( !accountWithAccountTeammemberMap.containsKey( AccTeamMember.NSP_Account__c ) ) {
                    accountWithAccountTeammemberMap.put(
                        AccTeamMember.NSP_Account__c ,
                        new List<NSP_Account_Team__c>()
                    );
                }
                accountWithAccountTeammemberMap.get( AccTeamMember.NSP_Account__c ).add( AccTeamMember );
            }
        }
        return accountWithAccountTeammemberMap;
    }

    private List<NSP_Termination_Form__c> getReinstatementList() {
        List<NSP_Termination_Form__c> reinstatementList = [
            SELECT
                Id ,
                Name ,
                NSP_Status__c ,
                Approval_Date__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c ,
                NSP_How_many_employees_were_moved__c ,
                NSP_Number_of_Active_Employees__c ,
                NSP_Client_Term_Date__c ,
                Previous_term_date__c ,
                NSP_Term_Reason__c ,
                NSP_Last_Date_Wages_Paid_Through__c ,
                NSP_Revision__c ,
                NSP_New_Client_Name__c ,
                NSP_New_Client_Number__c ,
                NSP_SubTerm_reason__c ,
                NSP_Benefit_Termination_Date__c ,
                Previous_Bene_Date__c ,
                Previous_Term_Reason__c ,
                Previous_Sub_Term_Reason__c ,
                Previous_Client_Term_Date__c ,
                NSP_Client_Sub_Account_Numbers__c
            FROM NSP_Termination_Form__c
            WHERE (
                ( Approval_Date__c > :NSP_TerminationForm_Batch.dateBefore )
                AND ( Approval_Date__c < :NSP_TerminationForm_Batch.dateAfter )
                AND ( NSP_Status__c = 'Term Team Approved' )
                AND ( NSP_Project_Task__r.Name = :NSP_ServiceConstants.REINSTATEMENT_REQUESTED_TASK )
            )
        ];
        return reinstatementList;
    }

    private List<NSP_Termination_Form__c> getTermFormList() {
        List<NSP_Termination_Form__c> terminationFormList = [
            SELECT
                Id ,
                Name ,
                NSP_Client_Term_Date__c ,
                NSP_Term_Reason__c ,
                NSP_Status__c ,
                NSP_Term_Code__c ,
                NSP_Benefit_Termination_Date__c ,
                NSP_Last_Date_Wages_Paid_Through__c ,
                NSP_Revision__c ,
                NSP_New_Client_Name__c ,
                NSP_New_Client_Number__c ,
                Previous_term_date__c ,
                NSP_SubTerm_reason__c ,
                Approval_Date__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c ,
                NSP_How_many_employees_were_moved__c ,
                NSP_Number_of_Active_Employees__c ,
                Previous_Bene_Date__c ,
                Previous_Term_Reason__c ,
                Previous_Sub_Term_Reason__c ,
                Previous_Client_Term_Date__c ,
                NSP_Client_Sub_Account_Numbers__c
            FROM NSP_Termination_Form__c
            WHERE (
                ( Approval_Date__c > :NSP_TerminationForm_Batch.dateBefore )
                AND ( Approval_Date__c < :NSP_TerminationForm_Batch.dateAfter )
                AND ( NSP_Status__c = 'Term Team Approved' )
                AND ( NSP_Project_Task__r.Name = 'Submit Termination Checklist' )
            )
        ];
        return terminationFormList;
    }

    private Map<String,String> getRoleMap( Map<Id,List<NSP_Account_Team__c>> accountWithAccountTeammemberMap , Id accountId ) {
        Map<String,String> roleMap = new Map<String,String>();
        if ( isValidInput( accountWithAccountTeammemberMap , accountId ) ) {
            List<NSP_Account_Team__c> teamMembers = accountWithAccountTeammemberMap.get( accountId );
            for ( NSP_Account_Team__c accTeamMember : teamMembers ) {
                addTeamMemberToRoleMap( roleMap , accTeamMember );
            }
        }
        return roleMap;
    }

    private Boolean isValidInput( Map<Id,List<NSP_Account_Team__c>> accountWithAccountTeammemberMap , Id accountId ) {
        return (
            ( accountId != null )
            && ( accountWithAccountTeammemberMap != null )
            && accountWithAccountTeammemberMap.containsKey( accountId )
        );
    }
    
    private void addTeamMemberToRoleMap( Map<String,String> roleMap , NSP_Account_Team__c accTeamMember ) {
        String role = accTeamMember.NSP_Role__c;
        String fullName = accTeamMember.NSP_First_Name__c + ' ' + accTeamMember.NSP_Last_Name__c;
        if ( accTeamMember.NSP_Primary__c ) {
            roleMap.put(
                role ,
                fullName + (roleMap.containsKey(role) ? ', ' + roleMap.get(role) : '')
            );
        } else {
            roleMap.put(
                role ,
                roleMap.containsKey(role) ? roleMap.get(role) + ', ' + fullName : fullName
            );
        }
    }

    // Getting the Document Id and creating a Document Url.
    public String getTopLogoUrl() {
        return new NSP_EmailImageController().getServiceOperationsLogoUrl();
    }

    // Getting the Document Id and creating a Document Url.
    public String getBottomLogoUrl() {
        return new NSP_EmailImageController().getCopyWriteLogoUrl();
    }

    // Getting the Document Id and creating a Document Url.
    public String getAddressLogoUrl() {
        return new NSP_EmailImageController().getHRLogoLogoUrl();
    }


}