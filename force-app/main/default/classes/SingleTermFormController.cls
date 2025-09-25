public with sharing class SingleTermFormController {
    // test w/ SingleTermFormController_Test (92%)

    public String passedRecordId { get; set; }
    public List<WrapTermination> wrapList = new List<WrapTermination>();
    private static final String REINSTATEMENT = 'Reinstatement';
    private static final String TERMINATION = 'Termination';

    //constructor
    public SingleTermFormController(){}

    //this method returns the single term form record as a list
    public List<WrapTermination> getWrapTerminationList() {
        List<WrapTermination> returnList = null;
        if ( passedRecordId != null ) {
            returnList = generateReturnList( TERMINATION , wrapList , passedRecordId );
        }
        return returnList;
    }

    //this getter method returns Single Reinstatement record as a list
    public List<WrapTermination> getWrapReinstatementList() {
        List<WrapTermination> returnList = null;
        if ( passedRecordId != null ) {
            returnList = generateReturnList( REINSTATEMENT , wrapList , passedRecordId );
        }
        return returnList;
    }

    //method to generate Return list with single record
    private static List<WrapTermination> generateReturnList(
        String formType , 
        List<WrapTermination> wrapList ,
        String passedRecordId
        )
    {
        List<NSP_Termination_Form__c> form = null;
        if ( formType == TERMINATION ) {
            form = fetchTermFormRecord( 'Submit Termination Checklist' , passedRecordId );
        } else if ( formType == REINSTATEMENT ) {
            form = fetchTermFormRecord( 'Reinstatement Requested' , passedRecordId );
        }
        List<WrapTermination> returnList = null;
        if ( ( form != null )
            && !form.isEmpty()
            && String.isNotBlank( formType )
            )
        {
            Map<Id,NSP_Termination_Form__c> accountWithTerminationMap = SingleTermFormController.getMapAccountsToTerminations( form );
            Map<Id,List<NSP_Account_Team__c>> accountWithTeam = SingleTermFormController.getAccountWithAccountTeammemberMap( accountWithTerminationMap );
            Map<String,String> roleMap = SingleTermFormController.getRoleMap( accountWithTeam , getAccountId( form[0] ) );
            WrapTermination wrapper = new WrapTermination( form[0] , roleMap );
            if ( wrapper != null ) {
                wrapList.add( wrapper );
            }
            returnList = wrapList;
        }
        return returnList;
    }

    //method to fetch termform record
    private static List<NSP_Termination_Form__c> fetchTermFormRecord( String projectTaskName , String passedRecordId ){
        List<NSP_Termination_Form__c> form = new List<NSP_Termination_Form__c>();
        if ( String.isNotBlank( projectTaskName ) && String.isNotBlank( passedRecordId ) ) {
            form = [
                SELECT
                    Id , Name , NSP_Client_Term_Date__c , NSP_Term_Reason__c , NSP_Status__c ,
                    NSP_Term_Code__c , NSP_Benefit_Termination_Date__c , NSP_Last_Date_Wages_Paid_Through__c ,
                    NSP_Revision__c , NSP_New_Client_Name__c , NSP_New_Client_Number__c , Previous_term_date__c ,
                    NSP_SubTerm_reason__c , Approval_Date__c , NSP_Project_Task__r.Name ,
                    NSP_Project_Task__r.pse__Project__r.pse__Account__c ,
                    NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name ,
                    NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c ,
                    NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c ,
                    NSP_How_many_employees_were_moved__c , NSP_Number_of_Active_Employees__c ,
                    Previous_Bene_Date__c , Previous_Term_Reason__c , Previous_Sub_Term_Reason__c ,
                    Previous_Client_Term_Date__c , NSP_Client_Sub_Account_Numbers__c
                FROM NSP_Termination_Form__c
                WHERE (
                    ( Id = :passedRecordId )
                    AND ( NSP_Status__c = :NSP_ServiceConstants.TERM_TEAM_APPROVED )
                    AND ( NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c != :NSP_ServiceConstants.COMPLETE_STATUS )
                    AND ( NSP_Project_Task__r.Name = :projectTaskName )
                )
                LIMIT 1
            ];
        }
        return form;
    }

    //method to fetch account Id from
    private static Id getAccountId( NSP_Termination_Form__c form ) {
        Id accId = null;
        if ( ( form != null )
            && ( form.NSP_Project_Task__c != null )
            && ( form.NSP_Project_Task__r.pse__Project__c != null )
            && ( form.NSP_Project_Task__r.pse__Project__r.pse__Account__c != null )
            )
        {
            accId = form.NSP_Project_Task__r.pse__Project__r.pse__Account__c;
        }
        return accId;
    }

    //method to create termForm Map
    private static Map<Id,NSP_Termination_Form__c> getMapAccountsToTerminations( List<NSP_Termination_Form__c> terminationFormList ) {
        Map<Id,NSP_Termination_Form__c> accountWithTerminationMap = new Map<Id,NSP_Termination_Form__c>();
        if ( terminationFormList != null ) {
            for ( NSP_Termination_Form__c termination : terminationFormList ) {
                Id accountId = getAccountId( termination );
                if ( accountId != null ) {
                    accountWithTerminationMap.put( accountId , termination );
                }
            }
        }
        return accountWithTerminationMap;
    }

    //method to get Account Team Map
    private static Map<Id,List<NSP_Account_Team__c>> getAccountWithAccountTeammemberMap( Map<Id,NSP_Termination_Form__c> accountWithTerminationMap ) {
        Map<Id,List<NSP_Account_Team__c>> accountWithAccountTeammemberMap = new Map<Id,List<NSP_Account_Team__c>>(); 
        if ( ( accountWithTerminationMap != null ) && !accountWithTerminationMap.isEmpty() ) {
            for ( NSP_Account_Team__c accTeamMember : [
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
                if ( accTeamMember.NSP_Account__c == null ) {
                    continue;
                }
                if ( !accountWithAccountTeammemberMap.containsKey( accTeamMember.NSP_Account__c ) ) {
                    accountWithAccountTeammemberMap.put(
                        accTeamMember.NSP_Account__c ,
                        new List<NSP_Account_Team__c>()
                    );
                }
                if ( ( accountWithAccountTeammemberMap.containsKey( accTeamMember.NSP_Account__c ) )
                    && ( accountWithAccountTeammemberMap.get( accTeamMember.NSP_Account__c ) != null )
                    )
                {
                    accountWithAccountTeammemberMap.get( accTeamMember.NSP_Account__c ).add( accTeamMember );
                }
            }
        }
        return accountWithAccountTeammemberMap;
    }

    //method to get Role Map
    private static Map<String,String> getRoleMap( Map<Id,List<NSP_Account_Team__c>> accountWithAccountTeammemberMap , Id accountId ) {
        Map<String,String> roleMap = new Map<String,String>();
        if ( isValidInput( accountWithAccountTeammemberMap , accountId ) ) {
            List<NSP_Account_Team__c> teamMembers = accountWithAccountTeammemberMap.get( accountId );
            for ( NSP_Account_Team__c accTeamMember : teamMembers ) {
                roleMap = addTeamMemberToRoleMap( roleMap , accTeamMember );
            }
        }
        return roleMap;
    }

    //validate input for Role Map
    private static Boolean isValidInput( Map<Id,List<NSP_Account_Team__c>> accountWithAccountTeammemberMap , Id accountId ) {
        return (
            ( accountId != null )
            && ( accountWithAccountTeammemberMap != null )
            && accountWithAccountTeammemberMap.containsKey( accountId )
        );
    }

    //method to add team member to role map
    private static Map<String,String> addTeamMemberToRoleMap( Map<String,String> roleMap , NSP_Account_Team__c accTeamMember ) {
        String role = '';
        String fullName = '';
        if ( ( accTeamMember!= null ) && ( accTeamMember.NSP_Role__c != null ) ) {
            role = accTeamMember.NSP_Role__c;
            fullName = generateFullName( accTeamMember );
        }
        if ( roleMap == null ) {
            roleMap = new Map<String,String>();
        }
        String value = fullName;
        if ( accTeamMember.NSP_Primary__c ) {
            if ( roleMap.containsKey( role ) ) {
                value += ', ' + roleMap.get( role );
            }
            roleMap.put( role , value );
        } else {
            if ( roleMap.containsKey( role ) ) {
                value = roleMap.get( role ) + ', ' + fullName;
            }
            roleMap.put( role , value );
        }
        return roleMap;
    }

    //method to generate full Account Team name
    private static String generateFullName( NSP_Account_Team__c accTeamMember ) {
        String fullName = '';
        if ( accTeamMember != null ) {
            if ( String.isNotBlank( accTeamMember.NSP_First_Name__c ) ) {
                fullName = accTeamMember.NSP_First_Name__c;
            }
            fullName += ' ';
            if ( String.isNotBlank( accTeamMember.NSP_Last_Name__c ) ) {
                fullName += accTeamMember.NSP_Last_Name__c;
            }
        }
        return fullName;
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
//