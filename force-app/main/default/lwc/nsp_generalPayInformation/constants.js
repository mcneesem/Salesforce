import IP_DO_TRACK_HOURS from '@salesforce/schema/Implementation_Profile__c.NSP_Do_you_track_hours__c';
import IP_COMPENSATION_OTHER from '@salesforce/schema/Implementation_Profile__c.NSP_Employee_with_compensation_other__c';
import IP_40HOURWEEK from '@salesforce/schema/Implementation_Profile__c.NSP_DoTheEmployeeWorkA40HourWorkWeek__c';
import IP_AN_YOT_EXPECTAIONS from '@salesforce/schema/Implementation_Profile__c.NSP_Are_there_any_OT_exceptions__c';
import IP_GOVT_JOB from '@salesforce/schema/Implementation_Profile__c.NSP_Do_you_have_GovernmentContracted_job__c';
import IP_SALARY_EMPLOYEE_OVERTIME from '@salesforce/schema/Implementation_Profile__c.NSP_SalaryExemptEmployeeReceiveOvertime__c';
import IP_EMPLOYEE_TYPES from '@salesforce/schema/Implementation_Profile__c.NSP_Employee_Types__c';
import IP_EMPLOYEE_MULTPLE_PAY from '@salesforce/schema/Implementation_Profile__c.NSP_Employees_with_multiple_types_of_pay__c';
import IP_APPORVALSTATUS from '@salesforce/schema/Implementation_Profile__c.NSP_Daily_Rate_approval_status__c';
import IP_PAYROLL_REPORTS from '@salesforce/schema/Implementation_Profile__c.NSP_Are_Certified_Payroll_reports_needed__c';
import IP_PAYROLL_SPECIALIST from '@salesforce/schema/Implementation_Profile__c.NSP_Payroll_Specialist_to_confirm__c';
import IP_TYPE from '@salesforce/schema/Implementation_Profile__c.NSP_Type__c';

const IP_FIELDS = [
    IP_DO_TRACK_HOURS,
    IP_COMPENSATION_OTHER,
    IP_40HOURWEEK,
    IP_AN_YOT_EXPECTAIONS,
    IP_GOVT_JOB,
    IP_SALARY_EMPLOYEE_OVERTIME,
    IP_EMPLOYEE_TYPES,
    IP_EMPLOYEE_MULTPLE_PAY,
    IP_APPORVALSTATUS,
    IP_PAYROLL_REPORTS,
    IP_PAYROLL_SPECIALIST,
    IP_TYPE
];

const EMPLOYEETYPE = {
    fullTime: 'Full Time',
    partTime: 'Part Time',
    hourly: 'Hourly',
    salariedExempt: 'Salaried Exempt',
    salaryNonExempt: 'Salary Non-Exempt',
}

const EMPLOYEEVALUES = {
    fullTime: false,
    partTime: false,
    hourly: false,
    salariedExempt: false,
    salaryNonExempt: false
}

const EMPLOYEEMULTIPLEPAY = {
    multiplePayRates: 'Multiple Pay Rates',
    shiftDifferentials: 'Shift Differentials',
    pieceRate: 'Piece Rate',
    carAllowance: 'Car Allowance',
    housingAllowance: 'Housing Allowance',
    perDiem: 'Per Diem',
    feeBased: 'Fee Based',
    onCall: 'On-Call',
    dailyRate: 'Daily Rate',
    NA: 'NA',
}

const EMPLOYEEMULTIPLEVALUES = {
    multiplePayRates: false,
    shiftDifferentials: false,
    pieceRate: false,
    carAllowance: false,
    housingAllowance: false,
    perDiem: false,
    feeBased: false,
    onCall: false,
    dailyRate: false,
    NA: false
}

const messageApplet = ' If employees are working in CA and paid Piece Rate, California Labor Law requires: '
+'Employees must be separately compensated for rest and recovery breaks and "other" non-productive time.'
+'Wage statements must state totoal hours of compensable rest & recovery periods & gross wages paid during the period'

const YES_NO_OPTIONS = {
    YES: 'Yes',
    NO: 'No'
};

const MultipleTypesOfPayLabel = 'Are there employees with multiple types of pay? Check all that apply';
const SALARIEDEXEMPT = 'Salaried Exempt';
export { IP_FIELDS, YES_NO_OPTIONS, EMPLOYEETYPE, SALARIEDEXEMPT, EMPLOYEEVALUES, EMPLOYEEMULTIPLEVALUES , EMPLOYEEMULTIPLEPAY, messageApplet, MultipleTypesOfPayLabel}