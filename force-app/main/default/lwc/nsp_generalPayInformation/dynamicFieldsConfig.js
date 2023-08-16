const DYNAMIC_FIELDS = {
    NSP_Employee_Types__c: [
        {
          expValue: ["Salaried Exempt"],
          dependentFields: ["NSP_SalaryExemptEmployeeReceiveOvertime__c"],
        },
      ],
      NSP_Employee_with_compensation_other__c: [
        {
          expValue: ["Yes"],
          dependentFields: ["NSP_compensation_structu_Provide_Details__c"],
        },
      ],
      NSP_Employees_with_multiple_types_of_pay__c: [
        {
          expValue: ["Daily Rate"],
          dependentFields: ["NSP_Daily_Rate_approval_status__c"],
        },
        {
          expValue: [
            "Multiple Pay Rates",
            "Shift Differentials",
            "Piece Rate",
            "Car Allowance",
            "Housing Allowance",
            "Per Diem",
            "Fee Based",
            "Phone Allowance",
            "On-Call",
            "Daily Rate",
          ],
          dependentFields: ["NSP_Payroll_Specialist_to_confirm__c"],
        },
      ],
    
      NSP_DoTheEmployeeWorkA40HourWorkWeek__c: [
        {
          expValue: ["No"],
          dependentFields: ["NSP_employee_40_hour_work_Week_PDetails__c"],
        },
      ],
      NSP_Are_there_any_OT_exceptions__c: [
        {
          expValue: ["Yes"],
          dependentFields: ["NSP_Any_OT_Expections_Provide_Details__c"],
        },
      ],
      NSP_Do_you_have_GovernmentContracted_job__c: [
        {
          expValue: ["Yes"],
          dependentFields: [
            "NSP_Type__c",
            "NSP_Are_Certified_Payroll_reports_needed__c",
          ],
        },
      ],
      NSP_Type__c:[
        {
          expValue: ["Other"],
          dependentFields: [
            "NSP_Govt_Type_Other_Provide_Details__c",
          ],
        },
      ],
    
};

export { DYNAMIC_FIELDS };