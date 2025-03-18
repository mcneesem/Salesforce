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

    public List<wrapTermination> wrapTerminationList {get; set;}
    public List<NSP_Termination_Form__c> reinstatementList {get;set;}

    public NSP_TerminationFormTemplateController(){
        initializeWrapTerminationList();
    }

    private void initializeWrapTerminationList() {
        List<NSP_Termination_Form__c> terminationFormList = getTerFormList();
        reinstatementList = getReinstatementList();
        if(wrapTerminationList == null) {
            wrapTerminationList = new List<wrapTermination>();
            Map<Id, NSP_Termination_Form__c> accountWithTerminationMap = getMapAccountsToTerminations(terminationFormList);
            Map<Id, List<NSP_Account_Team__c>> accountWithAccountTeammemberMap = getAccountWithAccountTeammemberMap (accountWithTerminationMap);
            if(!terminationFormList.isEmpty() && !accountWithTerminationMap.isEmpty() && !accountWithAccountTeammemberMap.isEmpty()){
                for(NSP_Termination_Form__c termination : terminationFormList){
                    Id accountId = termination.NSP_Project_Task__r?.pse__Project__r?.pse__Account__c;
                    Map<String,String> roleMap = getRoleMap(accountWithAccountTeammemberMap,accountId);
                    wrapTerminationList.add(new wrapTermination(termination, roleMap));
                }
            }
        }
    }

    private Map<Id, NSP_Termination_Form__c> getMapAccountsToTerminations( List<NSP_Termination_Form__c> terminationFormList ) {
        Map<Id, NSP_Termination_Form__c> accountWithTerminationMap = new Map<Id, NSP_Termination_Form__c>();
        for (NSP_Termination_Form__c termination : terminationFormList) {
            Id accountId = termination.NSP_Project_Task__r?.pse__Project__r?.pse__Account__c;
            if (accountId != null) {
                accountWithTerminationMap.put(accountId, termination);
            }
        }
        return accountWithTerminationMap;
    }

    private Map<Id, List<NSP_Account_Team__c>> getAccountWithAccountTeammemberMap( Map<Id,NSP_Termination_Form__c> accountWithTerminationMap ) {
        Map<Id, List<NSP_Account_Team__c>> accountWithAccountTeammemberMap = new Map<Id, List<NSP_Account_Team__c>>(); 
        if(!accountWithTerminationMap.isEmpty()){
            for ( NSP_Account_Team__c AccTeamMember : [
                        SELECT
                            Id ,
                            NSP_Role__c ,
                            NSP_Account__c ,
                            NSP_Email__c ,
                            NSP_First_Name__c ,
                            NSP_Last_Name__c
                        FROM NSP_Account_Team__c
                        WHERE (
                            ( NSP_Account__c IN :accountWithTerminationMap.keySet() )
                            AND ( NSP_Role__c != null )
                        )
                    ]
                )
            {
                if(!accountWithAccountTeammemberMap.containsKey(AccTeamMember.NSP_Account__c)){
                    accountWithAccountTeammemberMap.put(AccTeamMember.NSP_Account__c, new List<NSP_Account_Team__c>());
                } 
                accountWithAccountTeammemberMap.get(AccTeamMember.NSP_Account__c).add(AccTeamMember); 
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
                NSP_Client_Term_Date__c ,
                NSP_Term_Reason__c ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name ,
                NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c ,
                NSP_How_many_employees_were_moved__c ,
                NSP_Number_of_Active_Employees__c
            FROM NSP_Termination_Form__c
            WHERE (
                ( Approval_Date__c > :NSP_TerminationForm_Batch.dateBefore )
                AND ( Approval_Date__c < :NSP_TerminationForm_Batch.dateAfter )
                AND ( NSP_Status__c = 'Term Team Approved' )
                AND ( NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c != 'Complete' )
                AND ( NSP_Project_Task__r.Name = :NSP_ServiceConstants.REINSTATEMENT_REQUESTED_TASK )
            )
        ];
        return reinstatementList;
    }

    private List<NSP_Termination_Form__c> getTerFormList() {
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
                NSP_Number_of_Active_Employees__c
            FROM NSP_Termination_Form__c
            WHERE (
                ( Approval_Date__c > :NSP_TerminationForm_Batch.dateBefore )
                AND ( Approval_Date__c < :NSP_TerminationForm_Batch.dateAfter )
                AND ( NSP_Status__c = 'Term Team Approved' )
                AND ( NSP_Project_Task__r.pse__Project__r.pse__Project_Status__c != 'Complete' )
                AND ( NSP_Project_Task__r.Name = 'Submit Termination Checklist' )
            )
        ];
        return terminationFormList;
    }

    private Map<String,String> getRoleMap( Map<Id,List<NSP_Account_Team__c>> accountWithAccountTeammemberMap , Id accountId ) {
        Map<String,String> roleMap = new Map<String,String>();
        if(accountId != null && accountWithAccountTeammemberMap != null && accountWithAccountTeammemberMap.containsKey(accountId) ){
            for(NSP_Account_Team__c accTeamMember : accountWithAccountTeammemberMap.get(accountId)){
                String role = accTeamMember.NSP_Role__c;
                String fullName = accTeamMember.NSP_First_Name__c + ' ' + accTeamMember.NSP_Last_Name__c;
                if (roleMap.containsKey(role)) {
                    roleMap.put(role, roleMap.get(role) + ', ' + fullName);
                } else {
                    roleMap.put(role, fullName);
                }
            }
        }
        return roleMap;
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

    // This is our wrapper/container class. A container class is a class, a data structure, or an abstract data type whose instances are collections of other objects. In this example a wrapper class contains both the standard salesforce object Account and a Boolean value
    public class wrapTermination {
        public String clinetName {get; set;}
        public String clinetNumber {get; set;}
        public Decimal eeNumber {get; set;}
        public String psName {get; set;}
        public String clName {get; set;}
        public Date csaTerm {get; set;}
        public Date beneterm {get; set;}
        public String reason {get; set;}
        public String saName {get; set;}
        public String clientnumber {get; set;}
        public String clientname {get; set;}
        public String revision {get; set;}
        public Date previousTermDate {get; set;}
        public String subTermReason {get; set;}

        //This is the contructor method. When we create a new wrapAccount object we pass a Account that is set to the acc property. We also set the selected value to false
        public wrapTermination( NSP_Termination_Form__c termination , Map<String,String> roleMapDetails ) {
            clinetName = termination.NSP_Project_Task__r.pse__Project__r.pse__Account__r.Name;
            clinetNumber = termination.NSP_Project_Task__r.pse__Project__r.pse__Account__r.NSP_AIMS_Client__c;
            eeNumber = termination.NSP_Number_of_Active_Employees__c;
            if ( ( termination.NSP_Term_Reason__c == '1900 Merger with Insperity Client' )
                || ( termination.NSP_Term_Reason__c == '2700 Change in FEIN' )
                )
            {
                eeNumber = termination.NSP_How_many_employees_were_moved__c;
            }
            if (roleMapDetails != null) {
                psName = getRoleName(roleMapDetails, NSP_ServiceConstants.PAYROLL_SPECIALIST);
                clName = getJoinedRoleNames(
                    roleMapDetails ,
                    new List<String>{
                        NSP_ServiceConstants.CLIENT_LIAISION ,
                        NSP_ServiceConstants.BUS_TEAM_HRSP_CL ,
                        NSP_ServiceConstants.MID_MARKET_ACC_EX
                    }
                );
                saName = getJoinedRoleNames(
                    roleMapDetails ,
                    new List<String>{
                        NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR ,
                        NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT
                    }
                );
            }
            csaTerm = termination.NSP_Last_Date_Wages_Paid_Through__c;
            beneterm = termination.NSP_Benefit_Termination_Date__c;
            reason = termination.NSP_Term_Reason__c;
            clientnumber = termination.NSP_New_Client_Number__c;
            clientname = termination.NSP_New_Client_Name__c;
            revision = termination.NSP_Revision__c;
            previousTermDate = termination.Previous_term_date__c;
            subTermReason = termination.NSP_SubTerm_reason__c;
        }

        private String getRoleName(Map<String, String> roleMap, String roleKey) {
            return roleMap.containsKey(roleKey) ? roleMap.get(roleKey) : '';
        }

        private String getJoinedRoleNames(Map<String, String> roleMap, List<String> roleKeys) {
            List<String> names = new List<String>();
            for (String key : roleKeys) {
                if (roleMap.containsKey(key)) {
                    names.add(roleMap.get(key));
                }
            }
            return names.isEmpty() ? '' : String.join(names, ', ');
        }
    }

}