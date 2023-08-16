import IP_ENROLLMENT_FEE from '@salesforce/schema/Implementation_Profile__c.NSP_Is_there_an_Enrollment_fee__c';
import IP_DISCUSSED_CLIENT from '@salesforce/schema/Implementation_Profile__c.NSP_Discussed_E_Verify_with_the_client__c';
import IP_CREATE_BRP from '@salesforce/schema/Implementation_Profile__c.NSP_Check_to_create_the_RRP_Case__c';
import IP_SUMMARY_EMAIL from '@salesforce/schema/Implementation_Profile__c.NSP_CheckToSendTheClient_Summary_email__c';
import IP_PAYROLL_SPECIALIST from '@salesforce/schema/Implementation_Profile__c.NSP_CheckToSendPayrollSpecialist_Summary__c';
import IP_PAYROLL_NOTES from '@salesforce/schema/Implementation_Profile__c.NSP_Payroll_Onboarding_Notes__c';
import IP_PROVIDE_DETAILS from '@salesforce/schema/Implementation_Profile__c.NSP_Provide_Details_Enrollment_fee__c';

const IP_FIELDS = [
    IP_ENROLLMENT_FEE,
    IP_DISCUSSED_CLIENT,
    IP_CREATE_BRP,
    IP_PAYROLL_NOTES,
    IP_SUMMARY_EMAIL,
    IP_PROVIDE_DETAILS,
    IP_PAYROLL_SPECIALIST
];


export { IP_FIELDS }