const SECTION_FIELDS = [
  'NSP_Employee_Types__c',
  'Implementation_Profile__c',
  'NSP_SalaryExemptEmployeeReceiveOvertime__c',
  'NSP_Do_you_track_hours__c',
  'NSP_Employee_with_compensation_other__c',
  'NSP_compensation_structu_Provide_Details__c',
  'NSP_Employees_with_multiple_types_of_pay__c',
  'NSP_Daily_Rate_approval_status__c',
  'NSP_Payroll_Specialist_to_confirm__c',
  'NSP_DoTheEmployeeWorkA40HourWorkWeek__c',
  'NSP_employee_40_hour_work_Week_PDetails__c',
  'NSP_Are_there_any_OT_exceptions__c',
  'NSP_Any_OT_Expections_Provide_Details__c',
  'NSP_Do_you_have_GovernmentContracted_job__c',
  'NSP_Type__c',
  'NSP_Govt_Type_Other_Provide_Details__c',
  'NSP_Are_Certified_Payroll_reports_needed__c',
];

const SYNC_FIELDS = {
Employees_work_in_the_following_states__c: 'employeeStates',
}

export { SECTION_FIELDS, SYNC_FIELDS};