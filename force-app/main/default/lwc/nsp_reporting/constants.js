import IP_SELECT_ALL_APPLY from '@salesforce/schema/Implementation_Profile__c.NSP_Select_all_that_apply__c';
import IP_PAYROLL_REPORTS from '@salesforce/schema/Implementation_Profile__c.What_current_payroll_reports_being_used__c';
import IP_GLINTERFACE from '@salesforce/schema/Implementation_Profile__c.Is_there_a_need_for_a_GL_interface__c';
import IP_GL_CODES from '@salesforce/schema/Implementation_Profile__c.NSP_Chart_of_Accounts_GL_codes__c';
import IP_GL_REPORT from '@salesforce/schema/Implementation_Profile__c.NSP_Sample_of_current_GL_report__c';



const IntergraMessage = 'Remember to complete a referral for Integra';
const Intergra = 'Intergra';

const IP_FIELDS = [
    IP_SELECT_ALL_APPLY,
    IP_PAYROLL_REPORTS,
    IP_GLINTERFACE,
    IP_GL_CODES,
    IP_GL_REPORT
];

const CONSTLABELS = {
    IntergraMessage,
    Intergra
}

export { IP_FIELDS, CONSTLABELS }