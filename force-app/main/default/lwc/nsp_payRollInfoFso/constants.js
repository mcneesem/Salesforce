import IP_USER_UPDATED_AIMS from '@salesforce/schema/Implementation_Profile__c.Have_the_user_roles_been_updated_in_AIMS__c';
import IP_NONPIAD_USERS from '@salesforce/schema/Implementation_Profile__c.Are_there_any_non_paid_users__c';
import IP_PAYROLL_MULTIPLE_CONTACTS from '@salesforce/schema/Implementation_Profile__c.Payroll_submitted_frm_multiple_contacts__c';
import IP_CANNOT_SEE_SALARY from '@salesforce/schema/Implementation_Profile__c.Any_users_who_cannot_see_salary__c';
import IP_TIME_ZONE from '@salesforce/schema/Implementation_Profile__c.NSP_TimeZone__c';
import IP_WORK_HOURS from '@salesforce/schema/Implementation_Profile__c.NSP_Work_Hours__c';
import IP_COMPLIANCE_WITHEACHSTATE from '@salesforce/schema/Implementation_Profile__c.NSP_ArrearageInComplianceWithEachState__c';
import IP_VERIFY_CALENDER_IN_AIMS from '@salesforce/schema/Implementation_Profile__c.NSP_Did_you_verify_Calendar_in_AIMS__c';
import IP_PAYROLL_CALL_DATE from '@salesforce/schema/Implementation_Profile__c.NSP_What_is_the_Live_Payroll_Call_Date__c';
import IP_AUTO_APPROVAL from '@salesforce/schema/Implementation_Profile__c.NSP_ClientInterestedHavingAutoApproval__c';
import IP_HAS_ADDENDUM_COLLECTED from '@salesforce/schema/Implementation_Profile__c.NSP_Has_the_addendum_been_collected__c';
import IP_SUB_ACCOUNTS_SETUP from '@salesforce/schema/Implementation_Profile__c.NSP_Are_the_subaccounts_set_up__c';
import IP_DIFFERENT_CONTACTS from '@salesforce/schema/Implementation_Profile__c.NSP_Different_contact_for_subaccounts__c';
import IP_IS_SUB_ACCOUNT_NEEDED from '@salesforce/schema/Implementation_Profile__c.Is_there_a_need_for_a_subaccount__c';
import IP_PAYROLLCALLDATE from '@salesforce/schema/Implementation_Profile__c.NSP_What_is_the_Live_Payroll_Call_Date__c';
import IP_KICKOFF_METTING from '@salesforce/schema/Implementation_Profile__c.NSP_States_added_since_Kickoff_Meeting__c';



const IP_FIELDS = [IP_USER_UPDATED_AIMS,
    IP_NONPIAD_USERS,
    IP_PAYROLL_MULTIPLE_CONTACTS,
    IP_CANNOT_SEE_SALARY,
    IP_TIME_ZONE,
    IP_WORK_HOURS,
    IP_COMPLIANCE_WITHEACHSTATE,
    IP_VERIFY_CALENDER_IN_AIMS,
    IP_PAYROLL_CALL_DATE,
    IP_AUTO_APPROVAL,
    IP_HAS_ADDENDUM_COLLECTED,
    IP_DIFFERENT_CONTACTS,
    IP_SUB_ACCOUNTS_SETUP,
    IP_IS_SUB_ACCOUNT_NEEDED,
    IP_PAYROLLCALLDATE,
    IP_KICKOFF_METTING
];

const YES_NO_OPTIONS = {
    YES: 'Yes',
    NO: 'No'
};


export { IP_FIELDS, YES_NO_OPTIONS }