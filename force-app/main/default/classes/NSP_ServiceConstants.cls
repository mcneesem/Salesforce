// Represents the contant class used for service track.
public class NSP_ServiceConstants {
    // test w/ NSP_ServiceConstantsTest (100%)

    public static final String EMPTY_STRING = '';
    public static final String ACCOUNT_OBJECT = 'Account';
    public static final String CONTACT_OBJECT = 'Contact';
    public static final String USER_OBJECT = 'User';
    public static final String TYPE_GROUP = 'Group';
    public static final String ADMIN_QUEUE = 'NSP_Admin_Queue';
    public static final String DATA_MIGRATION ='Data Migration';
    // TERMINATION FORM CONSTANTS
    public static final String PR_SUPERVISOR_APPROVED = 'PR Supervisor Approved';
    public static final String TERM_SUPERVISOR_APPROVED = NSP_ServiceConstants.TERM_TEAM_APPROVED;
    public final static String terminationFormTaskName = 'Termination request form';
    public static final String NSP_Payroll_Specialist_Form = 'NSP_Payroll_Specialist_Form';
    public static final String NSP_Client_Reinstatement = 'NSP_Client_Reinstatement';

    // PROJECT CONSTANSTS
    public static final String PROJECT_TASK_SOBJECT_TYPE = 'pse__Project_Task__c';
    public static final String PROJECTSTATUSACTIVE = 'Active';
    public static final String PROJECTSTATUSONHOLD = 'On Hold';
    public static final String PROJECTSTATUSCLOSED = 'Close/Lost';
    public static final String PROJECTSTATUSCOMPLETED = 'Complete';
    public static final String PROJECTSTATUSCANCELLED = 'Cancelled';
    private static final String NOT_STARTED = 'Not Started';
    public static final String PROJECTSTATUSNOTSTARTED = NSP_ServiceConstants.NOT_STARTED;
    public static final String FINISH_To_START = 'Finish to Start (FS)';
    public static final String CANCELLED_REASON = 'Other';
    public static final String PROJECT_TYPE_SERVICE = 'Service Plan';
    public static final String PROJECT_TYPE_BILLABLE = 'Service - Billable';
    public static final String PROJECT_TYPE = 'Implementation';
    public static final String PROJECT_RET_RECORDTYPE = 'RET_Deconversion_2020_Form';
    public static final String PROJECT_TEMPLATE_NAME = 'BT EP';
    //Exact Names might change
    public static final String PROJECT_GENERAL_BUSINESS_TEMPLATE = 'RET General Business Plan Project';
    public static final String PROJECT_NON_REIMBURSABLE = 'RET Non Reimbursable Plan Project';
    public static final String PROJECT_ORK_RELATED = 'RET ORK Related Plan Project';
    public static final String PROJECT_STANDARD_PLAN_PROJECT = 'RET Standard Plan Project';

    public static final String PLAN_AMENDMENT_TEMPLATE = 'RET Plan Amendment 2020 Form';
    public static final String SAFE_HARBOUR_TEMPLATE = 'RET Safe Harbor Retractions 2020 Form';
    public static final String DECONVERSION_TEMPLATE = 'RET Deconversion 2020';
    public static final String PROTOTYPE_AMENDMENT_TEMPLATE = 'RET Prototype Amendment';
    public static final String SALES_NSP401K_TEMPLATE = 'RET Sales to NSP 401k';
    public static final String NSPK_INSTALL_TEMPLATE = 'NSPK Install for Conversion Form';
    public static final String STARTUP_SETUP_TEMPLATE = 'RET Startup Set Up';
    public static final String PROJECT_SOBJECT_NAME = 'pse__proj__c';
    public static final String PROJECT_PEO_RECORDTYPE = 'PEO_Project';
    public static final String PEO_BILL_RECORDTYPE = 'PEO_Project_Billable';
    public static final String PROJECT_CORE_TEMPLATE = 'Core/EG Year 1 EP';
    public static final String PROJECT_MM_FOUNDATIONAL_TEMPLATE = 'MM Foundational 90 day Engagement Plan';
    public static final String PEER_REVIEW_SENT_TO_REVIEW = 'Sent to Review Team';
    public static final String PEER_REVIEW_IN_PROGRESS= 'In-Progress';
    public static final String PEO_PROJECT_TASK_NAME= 'PEO Project Task';
    public static final String PROJECT_MM_90_DAY_EP_TEMPLATE = 'MM 90 day EP';
    public static final String PROJECT_MM_ENTERPRISE_EP_TEMPLATE = 'MM Enterprise 90 day EP';

    // PROJECT TASK CONSTANTS
    public static final String PROJECT_TASK_PEO_RECORDTYPE = 'PEO_Project_Task';
    public static final String PROJECT_TASK_BPS_RECORDTYPE = 'BPS_Project_Task';
    public static final String PROJECT_TASK_RET_RECORDTYPE = 'RET_Project_Task';
    public static final String PROJECTTASKRETCOMPLIANCE = 'RET Compliance';
    public static final String PROJECTTASKRETEXECUTIVE = 'RET Executive & Project';
    private static final String IN_PROGRESS = 'In Progress';
    public static final String PROJECT_TASK_IN_PROGRESS = NSP_ServiceConstants.IN_PROGRESS;
    public static final String PROJECT_TASK_NOT_STARTED = NSP_ServiceConstants.NOT_STARTED;
    public static final String TASKCOMPLETE = 'Complete';
    public static final String REINSTATEMENT_REQUESTED_TASK = 'Reinstatement Requested';
    public static final String ASSET_OFFSET_DATE = 'Asset Renewal Date';
    public static final String QTP1 = 'QTP1';
    public static final String QTP2 = 'QTP2';
    public static final String PTO_PLAN = 'PTO Plan Smartsheet submission';
    public static final String DISPATCH_REGION = 'FSO National';
    public static final String CHILD_DISPATCH_REGION = 'Central';
    public static final String ORIENTATION_ADDRESS ='HYB';
    public static final String CONFIGURATION_TASK = 'Configuration';
    public static final String PROJECT_TASK_CANCELLED = 'Canceled';

    //Service Appointment
    public final static String SA_SOBJECT_NAME = 'ServiceAppointment';
    public final static String unscheduleStatus = 'Scheduled';
    public final Static String OPR_HRS_CST = 'Central Time';
    public final Static String OPR_HRS_PST = 'Pacific Time';
    public final Static String OPR_HRS_EST = 'Eastern Time';

    // Assigned Resource
    public final static String ASSIGNEDRES_SOBJECT_NAME = 'AssignedResource';

    //Service Resource
    public final static String SERVICERES_SOBJECT_NAME = 'ServiceResource';

    //SUB CLIENT CONSTANTS
    public static final String ZERO_ZERO_SUFFIX = '00';

    //WORK TYPE Name
    public static final String WORKTYPE_NAME='Generic';

    // TERMINATION FROM STATUS
    public static final String TERMINATION_FORM_APPROVED_STATUS = 'PR Supervisor Approved';
    public static final String TERMINATION_FORM_PR_APPROVED_STATUS = NSP_ServiceConstants.TERM_TEAM_APPROVED;
    // PROJECT TASK ASSIGNMENT CONSTANTS
    public static final String PTASSIGNMENTROLE = 'Architect';
    public static final String PRIMARY_RESOURCETYPE = 'Primary';

    //TEMPLATE NAMES
    public final static String BPS_DEPENDENTTASKNOTIFICATIONTEMPLATE = 'NSP_BPS_Preceding_Task_Completion_Notification';
    public final static String PEO_DEPENDENTTASKNOTIFICATIONTEMPLATE = 'NSP_PEO_Preceding_Task_Completion_Notification';
    public final static String completeTerminationANalysisTaskName = 'Complete termination analysis';
    public final static String RET_Education_Creation_Email = 'NSP_RET_Education_Creation_Email';
    public final static String ITA_Project_Creation_Email = 'NSP_ITA_Project_Creation_Email';
    //ROLES
    public final static String CLIENT_REINSTATEMENT = 'Client Reinstatement';
    public final static String PAYROLL_SPECIALIST = 'Payroll Specialist';
    public final static String BUS_TEAM_HRSP_CL = 'Bus. Team-HRSp/CL';
    public final static String PAYROLL_SUPERVISOR = 'Payroll Supervisor';
    public final static String SALES_REPRESENTATIVE = 'Sales Representative';
    public final static String MANAGER_HRSERVICES = 'Manager, HR Services';
    public final static String CLIENT_LIAISION = 'Client Liaison';
    public final static String SAFETY_CONSULTANT = 'Safety Consultant';
    public final static String ACCOUNT_EXECUTIVE = 'Account Executive';
    public final static String MID_MARKET_ACC_EX = 'MidMarket Account Exec';
    public final static String NATIONAL_ACC_EX = 'National Account Exec';
    public final static String PERFOMANCE_SPECIALIST = 'Performance Specialist';
    public final static String EXECUTIVE = 'Executive';
    public final static String CUSTOMER_SPECIALIST = 'Customer Success Specialist';
    //CASE CONSTANTS
    public final static String CASE_CATEGORY_RANDOM = 'ITSWOSU';
    public final static String CASE_CLOSED_STATUS = 'Closed';
    public static final String HCM_CASE_SUBJECT = 'iSolved HCM Audit Task | ';
    public static final String CASE_SUB_STATUS_NOT_STARTED = NSP_ServiceConstants.NOT_STARTED;
    public static final String CASE_STATUS_NOT_STARTED = NSP_ServiceConstants.NOT_STARTED;
    public static final String CASE_CATEGORY_WX_WA = 'WX/WA';
    public static final String CASE_SUB_CATEGORY_PROJECTS = 'Projects';
    public static final String CASE_DETAIL_HCM_AUDIT = 'HCM Audit';
    public static final String CASE_ASIGNED_QUEUE_WX_IMPL_SUPPORT = 'WX IMPL Support';
    public static final String HCM_CASE_DATA_TEMPLATE = 'HCMCase_Data_Template';
    public static final String CASE_OBJECT_NAME = 'Case';
    public final static String CASE_CANCELLED_STATUS = 'Cancelled';
    public final static String CASE_RATING = 'Neutral';
    public static final String HCM_CASE_COMPLETION_EMAIL_TEMPLATE_NAME ='NSP_iSolved_HCM_Audit_Case_Completion';
    public static final String HCM_TEST_CASE_SUBJECT = 'iSolved HCM Audit Task | iSolved HCM Implementation';
    public static final String OPEN_BRACE = '[';
    public static final String CLOSE_BRACE = ']';
    public static final String BLANK_SPACE = ' ';
    public final static String BANK_AUDIT_CASE_SUBJECT = 'Bank Audit Request | ';
    public static final String TES_HCM_BANK_AUDIT = 'Bank Audit Task';
    public static final String CASE_DETAIL_BANK_AUDIT = 'Bank Audit';
    public static final String LINE_BREAK = '\n';
    public static final String BANK_AUDIT_CASE_CREATION_SUBJECT = 'Please complete the change audit:' + LINE_BREAK +
        'Company Name:' + LINE_BREAK +
        'Company ID:' + LINE_BREAK +
        'Type of Change:' + LINE_BREAK +
        'First Check Date change is effective:' + LINE_BREAK +
        'Special Notes:';
    public static final String FLSA_SUBCATEGORY = 'FLSA Full Service';
    public static final String FLSA_CATEGORY = 'HR Admin Compliance - FLSA';
    public static final String FIRST_LIVE_PAYROLL_CASE_SUB = 'First Live Payroll Processed | ';
    public static final String FIRST_LIVE_PAYROLL_DETAIL = 'First Live Payroll Processed';
    public static final String FIRST_LIVE_PAYROLL_DATA_TEMPLATE = 'Company Name:' + LINE_BREAK +
        'Company ID:' + LINE_BREAK +
        'First Check Date: ' + LINE_BREAK +
        'Payroll Processing Frequency: ' + LINE_BREAK +
        'Client Payroll Type: ' + LINE_BREAK +
        'Prior Compensation Loaded and Balanced: ' + LINE_BREAK +
        'Date Prior Compensation Loaded: ' + LINE_BREAK +
        'Additional Notes:';
    public static final String CASE_CATEGORY_SERVICE_OPERATIONS = 'Service Operations';
    public static final String CASE_SUB_CATEGORY_REQUEST_CUSTOMIZED_REPORT = 'Request - Customized Report';
    public static final String CASE_DETAIL_REQUEST_NOT_COMPLETE = 'Request Not Complete';
    public static final String CASE_DETAIL_REFERRED_TO_EXISTING = 'Referred to Existing';
    public static final String CASE_SUB_STATUS_WIRE_MIGRATION_COMPLETE = 'WIRE - Migration Complete';
    public static final String CASE_SUB_STATUS_AWAITING_VERIFICATION = 'Awaiting Verification';
    public static final String NON_INSPERITY_EMPLOYEE = 'Non-Insperity Employee';
    public final static String CASE_OPEN_STATUS = 'Open';
    public final static String CASE_SUB_STATUS_WAITING_ON_CUSTOMER = 'Waiting on Customer';
    public final static String CASE_PRIORITY_HIGH = 'High';
    public final static String CASE_ORIGIN_EMAIL = 'Email';
    public final static String CASE_CATEGORY_TIME_AND_ATTENDANCE = NSP_ServiceConstants.TIME_AMP_ATTENDANCE;
    public final static String CASE_SUBCATEGORY_TIMESTAR_WO = 'TimeStar WO';
    public final static String CASE_CATEGORY_EMP_SCREENING = NSP_ServiceConstants.EMPLOYMENT_SCREENING;
    public static final String IMPACT_FOCUS_ITEM_ORIGIN = 'Impact Focus Item';
    public final static String SEASONAL_EMP_DETAIL = 'Seasonal Employer Requests';
    public final static String RESOLVED = 'Resolved';
    public final static String CASE_ASSIGNED = 'Assigned';
    public final static String CASE_REFERRED_TO_PAYROLL = 'Referred to Payroll';

    //ASSET CONSTANTS
    public final static String ASSET_SOBJECT_TYPE ='Asset';
    public final static String AIMS_STATUS = 'Active';
    public final static String PAID_NON_PAID_WSEE = 'Paid WSEE';
    public final static String PAID_NON_PAID_ACTIVE = 'Active Non-Paid User';
    public final static String WO_ASSET_RECORDTYPE = 'WO';
    public final static String TIME_ATTENDANCE_ASSET = 'Time_Attendance';
    public final static String PERFORMANCE_MANAGEMENT_ASSET = 'Performance_Management';
    public final static String ORGANIZATIONAL_PLANNING_ASSET = 'Organizational Planning';
    public final static String INTEGRA_ASSET = 'Integra';
    public final static String XML_ASSET = 'XML';
    public final static String WORKFORCE_ASSET = 'Workforce Optimization/Synchronization';
    public final static String WX_WA = 'NSP_Asset_Product';
    public final static String WX_WA_RECORD_TYPE = 'WX_WA';
    public final static String HARDWARE_LOANER_RECORD_TYPE = 'Hardware_Loaner_Asset';
    public final static String HARDWARE_RECORD_TYPE = 'Hardware_Asset';
    public final static String EMPLOYMENT_SCREENING_RECORD_TYPE = 'Employment_Screening';
    public final static String APPLICANT_TRACKING_RECORD_TYPE = 'Applicant_Tracking';
    public final static String ISOLVED = 'WX Account Group';
    public final static String ASSET_ONBOARDING_STATUS = 'Onboarding';
    public final static String ASSET_ONDEMAND_STATUS = 'On Demand';
    public final static String ASSET_ACTIVE_STATUS = 'Active';
    public final static String ASSET_RECRUITING_SERVICES = 'Recruiting_Services';
    public final static String LEARNING_DEVELOPMENT = 'Learning_Development';
    public final static String RET_CHOICE_ASSET_RECORDTYPE = 'RET_Choice';
    public final static String INSURANCE_SERVICES_RECORDTYPE = 'Insurance_Service';
    public final static String RET_WO_ASSET_RECORDTYPE = 'RET_WO';
    public final static String WA_PRODUCT_BUNDLE = 'WA';
    //Account Team Constant
    public final static String WXWA_BENEFITS = 'WX/WA Benefits Specialist';
    public final static String WXWA_PAYROLL = 'WA/WX Payroll Specialist';
    public final static String PLAN_CONSULTANT = '401k Plan Consultant';
    public final static String BENEFITS_SPECIALIST = 'Benefits Specialist';

    //Account Groups
    public final static String AUTOMATICALLY_CREATED = 'Automatically_Created';
    public final static String GROWTH_FORECAST = 'Growth Forecast';
    public final static String ACCOUNT_HEALTH = 'Account Health';
    public final static String RENEWAL_PROBABILITY = 'Renewal Probability';
    public final static String TYPECONTROLLEDGROUP = 'Controlled Group';
    public final static String BUSINESS_PERFORMANCE_ADVISOR = 'Business Performance Advisor';
    public final static String BUSINESS_PERFORMANCE_CONSULTANT = 'Business Performance Consultant';

    // Random Constants
    public final static String ASSIGNMENTNOTIFICATIONTEMPLATE = 'NSP_Project_Task_Resource_Assignment';
    public final static String FROM_OBJECT_ASSET = 'AssetOpportunity';
    public final static String NO_REPLY = 'no reply';


    //Milestone Constatns
    public final static String PEOMILSTONE = 'PEO_Milestone';
    public final static String BPSMILESTONE = 'BPS_Milestone';
    public final static String MILESTONESTATUSCOMPLETE = 'Complete';
    public final static String MILESTONESTATUSINPROGRESS = NSP_ServiceConstants.IN_PROGRESS;

    //contact Contains
    public final static String Resource_Role = 'Insperity';
    public final static String EXT = 'ext';

    //Account Constants
    public final static String Account_Status = 'Active';

    //Plan SubPlan Constants
    public final static String STATUS_ACTIVE = 'Active';

    //SubPlanChangeHistory Constants
    public final static String CHOICE_RT_NAME = 'Choice';
    public final static String WO_RT_NAME = 'WO';

    //Category Constants
    public final static String Client_Management = 'Client Management';
    public final static String Quality_Touch_Point = 'Quality Touch Point';
    public static final String CREDIT_SERVICES = 'Credit Services';

    //Subcategory Constants
    public static final String CRITICAL_BUSINESS_CHALLENGES = 'Critical Business Challenges';
    public static final String EXTENSIVE_SLALARY_REDUCTION = 'Extensive Salary Reduction';
    public static final String FINANCIAL_BUSINESS_CHALLENGES = 'Financial Business Challenges';
    public static final String NOT_FOLLOWING_GUIDELINES = 'Not Following Guidelines';
    public static final String HEADCOUNT_REDUCTION = 'Headcount Reduction';

    //Focus Item Constants
    public static final String FOCUS_ITEM = 'Focus Item';
    public static final String BUSINESS_RESTRUCTURE = 'Business Restructure';
    public static final String ECONOMIC_SHIFTS = 'Economic Shifts';
    public static final String FINANCIAL_RISK = 'Financial Risk';
    public static final String RISK_MITIGATION = 'Risk Mitigation';
    public static final String RAPID_GROWTH_OR_DECLINE = 'Rapid Growth or Decline';
    public static final String DECLINING_20_PERCENT_OR_MORE = 'Declining 20% or more in WSEE over 12 months or less';

    //Subcategory Constants
    public final static String Renewal_Consultation ='Renewal Consultation';

    //Work Type Constants
    public final static String durationType = 'Hours';
    //Project Constants
    public final static String MM_PROJECT_TEMPLATE_KEY = 'MM - Implementation';
    public final static String FSO_PROJECT_TEMPLATE_KEY = 'FSO - Implementation';
    public final static String HRSCALE_PROJECT_TEMPLATE_KEY = 'HRScale - Implementation';// AZD-513688
    public final static String ImplementationProjectType = 'Implementation';
    public final static String PEOProject = 'PEO_Project';
    public final static String FSOProfile = 'FSO';
    public final static String MIDDLEMARKET = 'Middle Market';
    public final static String MMProfile = 'Middle_Market';
    public final static String ProjectManager = 'Project Manager';
    public final static String TransitionSpecialist = 'Transition Specialist';
    public final static String SrBenefitRep = 'Sr Benefit Rep';
    public final static String PayrollProjectManager = 'Payroll Project Manager';
    public final static String PayrollSpecialist = 'Payroll Specialist';
    public final static String OrientationRep = 'Orientation Rep';
    public final static String OSCoordinator = 'OS Coordinator';
    public final static String OTCoordinator = 'OT Coordinator';
    public final static String HCMAnalyst = 'HCM Analyst';
    public final static String FCPayroll = 'Functional Consultant Payroll';
    public final static String TimeAnalyst = 'Time Analyst';
    public final static String HCMPayrollAnalyst = 'HCM Payroll Analyst';
    public final static String FCTalent = 'Functional Consultant Talent';
    public final static String CompAnalyst = 'Compensation Analyst';
    public final static String OTPlanner = 'OT Planner';
    public final static String LostProject = 'Close/Lost';
    public final static String ProjectStatus = 'Not Yet Active';
    public final static String PSE_PROJECT = 'pse__Project__c';
    public final static string HCM_PROJECT_NAME = 'iSolved HCM Implementation';
    public final static String NEW_TAX_IMPL_PROJECT = 'WX/WA New Tax IMPL';
    public final static String WX_WA_DATA_MIGRATION_PROJECT = 'WX/WA Data Migration';
    public final static String PSE_MILESTONE = 'pse__Milestone__c';
    public final static String SoftwareAnalyst = 'Software Analyst';
    public final static String IntakeSpecialist = 'Intake Specialist';

    // Asset Constants
    public final static String MMAssetSegment = 'Middle Market';
    public final static String MMEAssetSegment = 'Middle Market Enterprise';
    public final static String EG100AssetSegment = 'Emerging Growth (100+ EEs)';
    public final static String EG50AssetSegment = 'Emerging Growth (50 - 99 EEs)';
    public final static String CoreAssetSegment = 'Core';
    public final static String BTAssetSegment = 'Business Team';
    public final static String ASSETBLACKOUT = 'Backout';
    public final static String ASSET_OP_RECORDTYPE = 'Organizational_Planning';
    public final static String ASSET_TT_RECORDTYPE = 'Time_Attendance';


    //To set opportunity stage as closed won
    public static final String CLOSED_WON ='Closed Won';
    public static final String CLOSED_LOST ='Closed Lost';
    public static final String TRANSITION_TYPE_PEO_WX ='PEO to WX';
    public static final String TRANSITION_TYPE_WX_PEO ='WX to PEO';
    public static final String LOST_REASON_CURRENT_SOLUTION ='Stayed with Current Insperity Solution';

    public final static String TERMINATED = 'Terminated';
    public final static String BACKOUT = 'Backout';

    //Profile Names
    public final static String PEOSERVICE = 'PEO Service';
    public final static String CONTACTCENTER = 'Contact Center';
    public final static String BPSSERVICE = 'BPS Service';
    public final static String RT = 'Retirement Services';
    public final static String INTEGRATION_USER = 'Integration User';
    //Case Record Type
    public final static String PEO = 'PEO';
    public final static String BPS = 'BPS';
    public final static String WX_IMPL= 'NSP_WX_IMPL';
    //Case Status
    public final static String OPEN = 'Open';
    //Case Status
    public final static String UNASSIGNED = 'Unassigned';
    //Case Priority
    public final static String MEDIUM = 'Medium';
    //Case Origin
    public final static String FOLLOWUP = 'Follow-up';
    //Client Goal
    public final static String ActiveClientGoal = 'Active';
    //IP Picklist values
    public final static String YES = 'Yes';
    public final static String NO = 'No';
    public final static Boolean VALUE_TRUE = True;
    //case fields
    public final static String CATEGORY1 = 'FSA';
    public final static String SUBCATEGORY1 ='Inquiries/Communications';
    public final static String SUBJECT1='Follow up with UHC on reactivating FSA cards for returning Employees';
    public final static String CATEGORY2 = 'Ben Service - Eligibility';
    public final static String SUBCATEGORY2 ='Employee';
    public final static String SUBJECT2='is in a previous wait period less than NSP’s';
    public final static String SUBJECT3='has an urgent medical need';
    public final static String CATEGORY4 = 'Onboarding Follow Up';
    public final static String SUBCATEGORY4 ='Workers Comp';
    public final static String SUBJECT4='Client has an immediate need for WC Certs. See IP for certs requested';
    public final static String CATEGORY5 = 'H&W Benefits Compliance';
    public final static String SUBCATEGORY5 ='Seasonal Employer';
    public final static String COMMENTS ='See the Implementation Profile for Seasonal Employee details.';
    public final static String CATEGORY6 = 'Payroll Services';
    public final static String SUBCATEGORY6 ='RRP';
    public final static String SUBJECT6='RRP for';
    public final static String CATEGORY7 = 'HSA';
    public final static String SUBJECT7='Client has a HSA with Optum Bank – Code:';
    public final static String SUBJECT8='Client has a HSA with Optum Bank. Code and Group unavailable at the Client Transition Meeting.';
    public final static String SUBCATEGORY9='Leave & Disability';
    public final static String LOAPAPERWORK='Leave Documents';
    public final static String SUBJECT9='Client has Employees on Leave';
    public final static String LOACOMMETNS='Add all LOA Contacts to the case, attach the completed LOA Spreadsheet and all LOA Paperwork and reassign the case to the Health & Welfare Leave Admin queue';
    public final static String FORMERCLIENT ='Former client returning within 12 months';
    public final static String CASE_TIME_ATTENDENCE = NSP_ServiceConstants.TIME_AMP_ATTENDANCE;
    public final static String CASE_ORGPLUS_SOFTWARE = 'OrgPlus Software';
    public final static String CASE_PERFORM_SOFTWARE = 'PerformSmart Software';
    public final static String CASE_WX_WA = 'WX/WA';
    public final static String OR_NSP_ACCOUNT_SEGMENT_EQUALS = ' OR NSP_Account_Segment__c = ';
    public final static String LOADETAILS='Leave Letters/Forms';

    //IP client sponspored plan
    public final static String HCFSA='Health Care Flexible Spending Account (HCFSA)';
    public final static String HSA='Health Savings Account';
    public final static String DCFSA='Dependent Care Flexible Spending Account (DCFSA)';
    public final static String MEDICAL='Medical (Pretax)';
    public final static String DENTAL='Dental (Pretax)';
    public final static String VISION='Vision (Pretax)';
    //milestone name
    public final static String MILESTONE='System Setup';
    public final static String REQUESTED='Requested';
    public final static String CLIENTCATEGORY='Client Sponsored Plans';
    //project task sub categories
    public final static String FSA='HC FSA';
    public final static String HSAA='HSA';
    public final static String MED='Medical';
    public final static String DCFS='DC FSA';
    public final static String DENT='Dental';
    public final static String VIS='Vision';
    public final static String PTO='PTO Plan Analysis, Development and Tracking';
    public final static String STATUTORY='Statutory EE Deduction';
    public final static String ELECTIVE='Elective EE Deduction';
    public final static String ORKDEDUCTION='ORK EE Deduction';
    public final static String SPECIALREPORT='Special Client Report';
    public final static String CUSTREPORTS='Custom Reports';
    public final static String COBRASubcat='Takeover Verifi & Submission';
    public final static String COBRA_MISSING_NAMES='COBRA Takeovers – need Employee names and forms';
    //PROJECT TASK CATEGORY NAMES
    public final static String ONBOARDING='Onboarding';
    public final static String INFRASTRUCTURE='HR Infrastructure';
    public final static String PAROLLIMP='Payroll Implementation';
    public final static String PPMREQUEST='PPM Request';
    public final static String COBRA='COBRA';
    public final static String CONFIGURATION='Configuration Call';
    public final static String CLIENTIMPL='Client Implementation';
    //project task name
    public final static String HEALTHCARE='Health Care FSA';
    public final static String MEDCSP='Medical CSP';
    public final static String DC='Dependent Care FSA';
    public final static String DCSP='Dental CSP';
    public final static String VCSP='Vision CSP';
    public final static String CERTIFICATE='General/Auto Liability Certificate of Coverage';
    public final static String EEO='EEO1 Number/Questionnaire';
    public final static String PRIMINGDATA='Employee Priming Data Provided';
    public final static String LOCATIONSETUP='Location Setup';
    public final static String DEPARTMENTSETUP='Department Setup';
    public final static String JOBSETUP='Job Costing Setup';
    public final static String ENROLLFEE='Confirm Enrollment Fee';
    public final static String CPR='Current Payroll Register';
    public final static String GARNISHMENT='Employee Garnishments Provided';
    public final static String LEVIEIS='Employee Levies Provided';
    public final static String AUTHFORM='Employee Deduction Authorization Forms';
    public final static String AUTHFORMORK='Employee Deduction Authorization Form - ORK';
    public final static String NYDEDUCTION='Post-Tax deductions - Employee Level – NY';
    public final static String CUSTOMPAYSETUP='Custom Pay Code setup - Client Level';
    public final static String JOBCOSTREPORT='Job Costing Reports';
    public final static String INTEGRA_RESPONSE_TASK_NAME='Complete the Client Integra Responses Smartsheet';
    public final static String FINANCEREPORT='Finance Reports';
    public final static String REPORT401K='401k reports';
    public final static String COBRATask = 'COBRA Takeovers – need info';
    public final static String COBRA_FORM_COLLECTED_YES = 'COBRA Takeover Form collected: <WSEE Name> verify eligibility';
    public final static String COBRA_FORM_COLLECTED_NO = 'Need COBRA Takeover Form: <WSEE Name>';
    public final static String EMPLOYEE_LOA_INFO = 'Employees Currently on LOA – need info';
    public final static String EMPLOYEE_LOA_INFO_YES = '<WSEE Name>: LOA Form needed';
    public final static String FEIN='FEIN documentation';
    public final static String FUNDINGDOCUMENTS='Verify Funding Documents Received';
    public final static String TESTPAYROLL='Test Payroll';
    public final static String FIRSTPAYROLL='First Payroll';
    public final static String FORMCOLLECTED='Generate Form 8973';
    public final static String PAYROLLAPPROVED='First Payroll Approved';
    public final static String GARNISHDOC=' garnishment documentation';
    public final static String LEVYDOC=' levy documentation';
    public final static String EMP_ON_LOA = 'Employees currently on LOA';
    public final static String HEALTH_SAVING = 'Health Savings Account';
    public static final String PROJECT_TASK_DISCOVERY = 'Discovery';
    public static final String GO_LIVE = 'Go Live';
    //IP fields constants
    public final static String XML='XML Upload';
    public final static String PAYROLL='Web Payroll';
    public final static String NOTCOLLECTED='Requested - Not Collected';
    public final static String COLLECTED='Collected';
    public final static String EMPLOYEEPRIMING='Employee Priming';
    public final static String EMPLOYEEDEDUCTION='Payroll - Employee Deductions (Pre/Post Tax, Other) Setup';
    public final static String POSTTAX='Post-Tax';
    public final static String CSP401K='CSP 401K and wants to keep it';
    public final static String SIMPLEIRA='Simple IRA';
    public final static String CLIENTB='403B';
    public final static String NY='NY';
    public final static String PAYSETUP='Payroll - Employee Types of Pay Setup';
    private final static String JOB_COSTING = 'Job Costing';
    public final static String COSTING = NSP_ServiceConstants.JOB_COSTING;
    public final static String REPORITNTNEED='Payroll - Client Reporting Needs';
    public final static String REPORT401='Custom 401(k) report';
    public final static String OTHREPORTS='Other Custom Reports';
    public final static String BENEFITS='Benefits';
    public final static String AIMS='Track in AIMS';
    public final static String AM='Assignments and Meetings';
    public final static String RECEIVED='Received';
    public final static String MILITARY_LEAVE = 'Military Leave';
    public final static String WORKER = 'Workers\' Comp';
    public final static String SALARY = 'Salary continuation while on leave';
    public final static String GREATER_THAN = 'Greater than 84 days';
    public final static String SUBSTANCE = 'Substance Abuse Policy';
    public final static String STANDARD_LETTER = 'Standard Offer Letter';
    public final static String SCREENING = NSP_ServiceConstants.EMPLOYMENT_SCREENING;
    public final static String PERFORMANCE = 'Performance Management';
    public final static String ORGANIZATIONAL = 'Organization Planning';
    public final static String INSURANCE = 'Insurance Services';
    public final static String RECRUITING = 'Recruiting Services';
    public final static String CERTIFY = 'Certify';


    //email template names
    public final static String CONGRATULATIONTEMPLATE='NSP_Congratulation_Payroll_Template';
    public final static String CONGRATULATIONTEMPLATEMM='NSP_Congratulation_Payroll_Template_MM';
    public final static String IPACONTROLLER='NSP_ImplprofileAutomation_Controller';
    //automation case creation constants
    public final static String FSACLIENT='Former Client/FSA';
    public final static String WPA='Wait Period Employees';
    public final static String MEDNEEDS='Urgent Medical Needs';
    public final static String WCERTS='Need WC Certs';
    public final static String SEASONEMP='Seasonal Employees';
    public final static String RRP='RRP';
    public final static String OPTOCOLLECTED='HSA Optum Info collected';
    public final static String OPTOMISSING='HSA Optum Info missing';
    //IP Section
    public final static String GENERAL='General';
    public final static String SERVICETEAM='Service Team';
    public final static String PROLL='Payroll';
    public final static String MISCELLANEOUS='Miscellaneous';
    public final static String EMPLOYEE_SEC = 'Employees';


    //IP automation methods
    public final static String CREATECASEFSA='createCaseFSA';
    public final static String CREATECASENSP='createCaseNSP';
    public final static String CREATECASEMEDNEED='createCaseMedicalNeeds';
    public final static String CREATECASECOMPCERT='createCaseCompCertificates';
    public final static String CREATECASESEASONAL='createCaseSeasonal';
    public final static String CREATECASERRP='createCaseRRP';
    public final static String CREATECASEHSA='createCaseHSA';
    public final static String CREATECASEOPTUM='createCaseOPTUM';
    public final static String CREATECASE9='createCaseCondition9';
    public final static String PEOMULTIPLIER='PEO Multiple Employer Plan (MEP)';
    public final static String CSP401KNSP = 'CSP 401K and wants to move to NSP RS';
    public final static String REMOVE_EMPLOYEE_DIR = 'Remove employee directory';
    public final static String AUTOMATION_STOCK_PURCHASE = 'Stock Purchase Plan';
    public final static String AUTOMATION_EPLI_NOTIFY = 'EPLI Notification';
    public final static String AUTOMATION_EXIST_RET_PLAN_KEEP = 'Existing Retirement Plan/Keep';
    public final static String AUTOMATION_EXIST_RET_PLAN_MOVE = 'Existing Retirement Plan/Move to NSP 401(k)';
    public final static String EEO_INFO = 'EEO Information';
    public final static String AUTOMATION_NEW_401 = 'New 401(k)';
    public final static String AUTOMATION_SRP_NOTIFY = 'SRP Notification';


    //email templates
    public final static String CAFETERIAPLAN='NSP_CafetariaPlan';
    public final static String COMMISSION='NSP_CommissionOnlyEEs';
    public final static String RETIRMENTPLAN='NSP_RetirementPlan';

    // Project Constants
    public final static String AccountExecutive = 'MidMarket Account Exec';
    public final static String HRSpecialist = 'HR Specialist';
    public final static String SrHrSpecialist = 'Sr HR Specialist';
    // Project Tasks Constants
    public final static String IPIC = 'NSP_IPIC';
    public final static String IPICQUEUE = 'IPIC';
    public final static String HWProducts = 'NSP_Health_Welfare_Products';
    public final static String GroupType = 'Queue';
    public final static String PayCodeEmpTask='Pay Code Assignment - Employee level';
    public final static String PayCodeClientTask='Pay Code Assignment - Client level';
    public final static String ClientPackingTask='Client Packing slip setup';
    public final static String EnrollmentTask='Confirm Enrollment Fee';
    public final static String CurrentPayrollTask='Current Payroll Register';
    public final static String ClientOptumTask='Client is using Optum Bank';
    public final static String PTOTask='PTO Policy Analysis, Development and Tracking for ';
    public final static String LOCATIONS='Locations';
    public final static String DEPARTMENTS='Departments';
    public final static String JOBCOSTING = NSP_ServiceConstants.JOB_COSTING;
    public final static String TIMEENTRY = 'Time entry method is ';
    public final static String HRSREVIEW='HRS to review accrual policy(ies) with Client/create any new policies as needed, once compliant, then submit PTO SmartForm with attached policy(ies). Once complete, close this case.';
    public final static String SEASONALCOMMENT='See the Implementation Profile for Seasonal Employee details.';

    // IP Automation Names
    public final static String CSPDOCSNOTRECEIVED = 'CSP doc(s) not received';
    public final static String GENERALlIABILITY = 'General Liability & Auto';
    public final static String CLIENTPOLICY = 'Client policies';
    public final static String TIMEENTRYMETHOD = 'XML Upload/Webpayroll';
    public final static String EDC = 'EDC';
    public final static String PAYROLLLOCATIONS = 'Custom Reporting Needs - Locations';
    public final static String PAYROLLDEPARTMENTS = 'Custom Reporting Needs – Departments';
    public final static String PAYROLLJOBCOSTING = 'Custom Reporting Needs – Job Costing';
    public final static String ENROLLMENTFEE = 'Enrollment Fee';
    public final static String PAYROLLREGISTER = 'Payroll Register';
    public final static String GARNISHMENTS = 'Garnishments';
    public final static String LEVIES = 'Levies';
    public final static String POSTTAXDEDUCT = 'Post-tax deductions';
    public final static String EMPLOYEEDEDUCT= 'Employee Deductions – non NSP Retirement Plan';
    public final static String NYWSEE= 'Post-tax deductions – NY WSEE';
    public final static String RELABELING= 'Special Pay Codes/Relabeling';
    public final static String JOBCOST = NSP_ServiceConstants.JOB_COSTING;
    public final static String INTEGRA='Integra';
    public final static String INSPERITY_INTEGRA='Quickbooks Integration(Insperity Integra)';
    public final static String INTEGRARESPONSE='Integra Responses SmartSheet';
    public final static String CUSTOMREPORT='Custom Report';
    public final static String CUSTOM401K='Custom 401(k)';
    public final static String MISSINGCOBRA='Missing COBRA Names';
    public final static String COBRAFOLLOWUP='COBRA Form Followup';
    public final static String COBRAELIGIBITY='Verify COBRA eligibility';
    public final static String EEONLOA='EEs on LOA';
    public final static String MISSINGLOAINFO='Missing LOA Info';
    public final static String MISSINGLOAFORMS='Missing LOA forms';
    public final static String TIMEENTRYHOURS='Time Entry';
    public final static String SEASONEMPHW='Season Employees H&W';
    public final static String EESONLOA='EEs on LOA';
    public final static String FIELDAPINAMECOBRA ='Have_name_s_of_COBRA_takeovr_employees__c';
    public final static String FIELDAPINAMELOA ='Do_you_have_the_LOA_information__c';

    //IP SECTIONS
    public final static String PAYROLLSEC = 'Payroll';
    public final static String PAYOUTSSEC = 'Additional Pay Outs';
    public final static String REPORTINGSEC = 'Reporting';
    public final static String EMPLOYEESEC = 'Employees';
    public final static String CLIENTINFO = 'Client Information';
    public final static String STATE_RET_PLAN = 'State Retirement Plan';
    public final static String SERVICE_TEAM_SEC = 'Service Team';

    //Project Team Constants
    public final static String MMProjectTeamRecordType = 'NSP_Middle_Market_Project_Team';
    public final static String FSOProjectTeamRecordType = 'NSP_FSO_Project_Team';

    //IP MM Automation Email Tempaltes
    public final static String EEO_INFORMATION = 'NSP_EEO_information';
    public final static String EPLI_NOTIFICATION = 'NSP_EPLI_Notification';
    public final static String ER_PLAN_KEEP = 'NSP_Existing_Retirement_Plan_Keep';
    public final static String ER_PLAN_MOVE = 'NSP_Existing_Retirement_Plan_Move';
    public final static String NEW_401 = 'NSP_New_401_k';
    public final static String REMOVE_EMP_DIR = 'NSP_Remove_Employee_Directory';
    public final static String PURCHASE_PLAN = 'NSP_Stock_Purchase_Plan';
    public final static String SRP_NOTIFY = 'NSP_SRP_Notification';
    public final static String SRP_NOTIFY_401 = 'NSP_SRP_Notification_401';
    public final static String SRP_RET_SALES = 'SRP_Notification_RetSales';
    //MM Metadata Identifer
    public final static String MM_EEO_INFORMATION = 'NSP_MM_EEO_information';
    public final static String MM_EPLI_NOTIFICATION = 'NSP_MM_EPLI_Notification';
    public final static String MM_ER_PLAN_KEEP = 'NSP_MM_Existing_Retirement_Plan_Keep';
    public final static String MM_ER_PLAN_MOVE = 'NSP_MM_Existing_Retirement_Plan_Move';
    public final static String MM_NEW_401 = 'NSP_MM_New_401_k';
    public final static String MM_REMOVE_EMP_DIR = 'NSP_MM_Remove_Employee_Directory';
    public final static String MM_PURCHASE_PLAN = 'NSP_MM_Stock_Purchase_Plan';
    public final static String MM_SRP_NOTIFY = 'NSP_MM_SRP_Notification';
    public final static String MM_SRP_NOTIFY_401 = 'NSP_MM_SRP_Notification_401';
    public final static String MM_SRP_RET_SALES = 'NSP_MM_SRP_Notification_RetSales';

    //Group Names
    public final static String HEALTH_WELFARE = 'Health & Welfare Benefits Compliance';
    public final static String HEALTH_WELFARE_PRODUCT = 'Health & Welfare Products';
    public final static String NATIONAL_BENEFIT_TEAM = 'National Benefits Team';


    //SUB CATEGORY NAMES
    public final static String LEAVE_DISABILITY = 'Leave & Disability';
    //IP Automation class name
    public final static String IP_CASE_AUTOMATIONCLASS ='NSP_Implementationprofile_ServiceHelper';
    public final static String IP_PROJECTTASK_AUTOMATIONCLASS ='NSP_Implprofile_ServiceHelperUpdate';
    public final static String IP_PROJECTTASKMM_AUTOMATIONCLASS ='NSP_MMImplProfile_ServHelpUpdate';
    //email id constants
    public final static String ORIENT_COORDINATOR='NSP_Orientation_Coordinator';
    public final static String ORIENT_REQUEST='NSP_Orientation_Request';
    //IP Constants
    public final static String ALLOWANCES='Allowances';
    public final static String EXPENSES='Expenses';
    public final static String CLIENTMANAGEDATA='Client Managed Data';
    public final static String CERTIFIEDREPORT='Certified Payroll Reports';
    //project task name
    public final static String SECTIONQUESTIONNAIRE='Section 125 Questionnaire';
    public final static String FEINDOCUMENT='FEIN Documentation';
    public final static String PRETAX='Pre-Tax';
    public final static String HOUSINGALLOWANCE='Housing Allowance';
    public final static String PHONEALLOWANCE='Phone Allowance';
    public final static String PERDIEM='Per Diem';
    public final static String CARALLOWANCE='Car Allowance';
    public final static String HANDBOOK='Handbook Development';
    public final static String JOBDESCRIPTION='Job Descriptions';
    public final static String SEVERANCEAGREEMENT='Employment/Severance Agreements';
    public static final String WO_WX_TEMPLATE= 'WO to WX';

    public final static String MISSING_COBRA_NAMES = 'Missing_COBRA_Names';
    public final static String COBRA_FOLLOWUP = 'COBRA_Form_Followup';
    public final static String VERIFY_COBRA = 'Verify_COBRA_eligibility';
    public final static String MISSING_LOA_INFO = 'Missing_LOA_Info';
    public final static String MISSING_LOA_FORMS = 'Missing_LOA_forms';
    public final static String SETUP = 'Set up ';

    //Project task names might get updated
    public final static String PREPARE_AMENDMENT = 'Prepare Amendment for Client Signature';
    public final static String SUBMIT_COVERSHEET = 'Submit Coversheet to Ops for Processing';
    public final static String VERIFY_ALL_INFO = 'Verify all information received from client';
    public final static String COLLECT_SIGNED = 'Collect signed amendment';
    public final static String COLLECT_DOCUMENT = 'Collect all documents & reports from client for the due diligence review';
    public final static String SUBMIT_EA_PACKAGE = 'Submit EA Package to Implementation for QC';
    public final static String VALIDATION_PPTT_INSTALL = 'Validation of pptt feed to OMNI';
    public final static String VALIDATION_PPTT_STARTUP = 'Validation of PPTT feed to OMNI';

    //FSO Form Constants
    public final static String FSOAutomations = 'FSO';
    public final static String EmailAutomation = 'Email';
    public final static String ProjectAutomation = 'PROJECT TASK CREATION';
    public final static String CaseAutomation = 'CASE CREATION';
    public final static String EmailIcon = 'utility:email';
    public final static String ProjectIcon = 'utility:task';
    public final static String CaseIcon = 'utility:case';
    public final static String AutomationEmailIcon = 'standard:email';
    public final static String AutomationProjectIcon = 'standard:task';
    public final static String AutomationCaseIcon = 'standard:case';
    public final static String EnableButton = 'slds-icon-text-success';
    public final static String DisableButton = 'slds-icon-text-inverse';
    public final static String UpdateEmailSubject = 'Update ';

    //RelatedInformation Constants
    public final static String SECURITY_TYPE_PUBLIC = 'Public';
    public final static String SECURITY_TYPE_PRIVATE = 'Private';
    public final static String APPEND_NAME = 'RI - ';
    public final static String CONFIDENTIAL_CHECK_BOX_PERMISSION = 'NSP Confidential Checkbox Permission';

    // Sharing Constants
    public final static String BEN_SERVICE_CLAIMS = 'Ben Service - Claims';
    public final static String HR_EMPLOYEE_RELATIONS = 'HR Employee Relations';
    public final static String HW_QMCSCO = 'H&W QMCSO';
    public final static String RETIREMENT_SVC_COMPLIANCE = 'Retirement Svc-Compliance';
    public final static String HW_SECTION_125 = 'H&W Section 125';
    public final static String ALL_DATA_VISIBILTY = 'All Data Visibility';
    public final static String HR_DATA_VISIBILTY = 'HR Data Visibility';
    public final static String BENEFITS_DATA_VISIBILTY = 'Benefits Data Visibility';
    public final static String HW_DATA_VISIBILTY = 'H&W / Benefits Data Visibility';
    public final static String RETIREMENT_SERVICES_VISIBILTY = 'Retirement Services Visibility';
    public final static String SECTION_125_VISIBILTY = 'Section 125 Visibility';
    public static final String manualRowCause = 'Manual';
    public static final String editSharingAccess = 'Edit';
    public static final String SECTION_125_PRIVATE_CASE_VISIBILTY = 'NSP_Section_125_Private_Case_Visibility';
    public static final String TYPE_REGULAR = 'Regular';
    public final static String ALL_DATA_GROUP='NSP_All_Data_Visibility';
    public static final String ACTIVATED = 'Activated';

    //project task names
    public static final String CLIENTTRANSITION = 'Client Transition Meeting - PM';
    public static final String INTERNALDISCOVERY = 'Internal Discovery Meeting Debrief';
    public static final String ONSITEDISCOVERY = 'On-Site Discovery Meeting';
    public static final String COREPOLICY = 'Core Policy Book Development';
    public static final String POLICYREVIEW = 'Policy Review & Accrual Profiles';
    // Case Constants
    public static final String STATUSCANCELLED = 'Cancelled';
    public static final String SUBJECTRELATEDTOOPTUM = 'Client has a HSA with Optum Bank';
    public static final String MASTER_CQA_TASK = 'Master CQA Case';
    public static final String CATEGORY_TIME_ATTENDANCE = NSP_ServiceConstants.TIME_AMP_ATTENDANCE;
    public static final String SUB_CATEGORY_ITA_CQA = 'ITA CQA';
    public static final String NSP_ITA_CQA = 'NSP_ITA_CQA';
    public final static String REOPENED = 'ReOpened';
    public final static String L1_PAYROLL_CRITICAL = 'L1-Payroll Critical';
    public final static String L2_CRUCIAL = 'L2-Crucial';
    public final static String L3_LOW = 'L3-Low';
    public final static String L4_NONE = 'L4-None';
    public final static String L3_UX_IMPACT = '(L3) UX Impact';
    public final static String L1_CA_ACCURALS_MISCALCULATION = '(L1) CA Accruals Miscalculation';
    public final static String DO_AUDITS_RECORDTYPE = 'NSP_DOLAudits';
    public final static String WAGE_CLAIMS_RECORDTYPE = 'NSP_WageClaims';
    public final static String CASE_SUB_CATEGORY_WAGE_CLAIMS = 'Wage Claim';
    public final static String CASE_SUB_CATEGORY_DOL_AUDITS = 'DOL Audit';
    public final static String CORP_CASE_VISIBILITY = 'NSP_Corp_Cases_Visibility';
    public final static String SERVICE_PROFILE_GROUP_MEMBERS = 'NSP_Service_Profile_Group_Members';
    public static final String CATEGORY_ADAPTION = 'Adaption';
    public static final String SUB_CATEGORY_CLAIM = 'Claim';
    //email constants
    public static final String ALLOSCOORDINATOR ='NSP_AllOSCordinator';
    public static final String HRSUPPORT ='NSP_HRSupportTeam';
    public static final String ORIENTCOORDINATOR ='NSP_Orientation_Coordinator';
    public static final String CLIENTACCOUNTMANAGEMENT ='NSP_ClientAccountManagement';
    public static final String EDUCATION_TEAM ='NSP_RET_Education_Team_Email_Address';
    public static final String RESOURCE_REQUEST_ROLE = 'NSP_Resource_Request_Role_Email';
    public static final String PROJECT_ASSIGNMENT = 'Project_Assignment_Email';

    public static final String RET_401KASFPLAN = 'NSP_RET_401kasfplan_email';
    public static final String RET_401KCOMPLIANCE = 'NSP_RET_401kcompliance';
    public static final String RET_KWRSBUISNESS = 'NSP_RET_KWRSBusinessSolutions';
    public static final String RET_VIRGINIA_BARNES = 'NSP_RET_Virginia_Barnes';
    public static final String RET_FINANCEMDT = 'NSP_RET_Finance';
    public static final String RET_NBICONVERSIONMDT = 'NSP_RET_NBI_Conversion_Ork';
    public static final String RET_NBIIMPLEMENTATIONMDT = 'NSP_RET_NBI_Implementation';
    public static final String RET_QCANALYSTMDT = 'NSP_RET_NBI_QC_Analyst';
    public static final String RET_PLANCONSULTINGMDT = 'NSP_RET_Plan_Consulting';
    public static final String RET_SALESMDT = 'NSP_RET_Sales';
    public static final String RET_CSPPROCESSINGMDT = 'NSP_RET_CSP_Processing';
    public static final String RET_CSPIMPLEMENTATIONMDT = 'NSP_RET_CSP_Implementation';
    public static final String RET_CSPCOMPLIANCEMDT = 'NSP_RET_CSP_Compliance';
    public static final String RET_CSPCONSULTINGMDT = 'NSP_RET_CSP_Consulting';
    public static final String RET_SRPMDT = 'NSP_RET_SRP';
    public static final String RET_ORKMDT = 'NSP_RET_ORK';
    public static final String RET_OPSOMNIMDT = 'NSP_RET_Ops_OMNI';

    //Retirement Services constants
    public static final String RET_COMPLIANCE = 'RET Compliance';
    public static final String RET_FINANCE = 'RET Finance';
    public static final String RET_NBICONVERSION = 'RET NBI - Conversion & Ork';
    public static final String RET_NBIIMPLEMENTATION = 'RET NBI - Implementation';
    public static final String RET_QCANALYST = 'RET NBI - QC Analyst';
    public static final String RET_PLANCONSULTING = 'RET Plan Consulting';
    public static final String RET_SALES = 'RET Sales';
    public static final String RET_CSPPROCESSING = 'RET CSP Processing';
    public static final String RET_CSPIMPLEMENTATION = 'RET CSP Implementation';
    public static final String RET_CSPCOMPLIANCE = 'RET CSP Compliance';
    public static final String RET_SRP = 'RET SRP';
    public static final String RET_ORK = 'RET ORK';
    public static final String RET_OPSOMNI = 'RET Ops - OMNI';
    public static final String RETOPSPROCESSING = 'RET Ops - Processing';

    //FIEDL API NAMES
    public static final String MORETHANONEFEIN ='NSP_Does_company_have_more_than_one_FEIN__c';
    public static final String COMMISSIONONLYEE ='NSP_Commission_only_employees__c';
    public static final String NEWPRODUCT='New Product';

    public static final String SYSTEM_ADMINISTRATOR ='System Administrator';
    public static final String PSE_ASSIGNMENT = 'pse__Project_Task_Assignment__c';
    public static final String implProfile = 'Implementation_Profile__c';
    public static final String BPA = 'BPA';
    public static final String PTOSICKLEAVE='PTO, paid sick leave, or other accrual policy received';
    public static final String MAILINGSTATE = 'MailingState';
    public static final String NOTFOUND ='Not Found';
    public static final String FINALLEVEL = 'FinanceLevel';
    public static final String USERID ='UserId';
    public static final String DATE_OF_BIRTH = 'dateOfBirth';


    //Queue DeveloperNames
    public static final String INTEGRA_QUEUE = 'Integra';
    public static final String CERTIFY_QUEUE ='NSP_Certify';
    public static final String SERVICE_REFERRAL =  'Service_Referrals';
    public static final String RECRUITING_SERVICES ='NSP_Recruiting_Services';
    public static final String CONTINGENT_WORKFORCE = 'Contingent_Workforce';
    public static final String I9_ASSIST_EVERIFY = 'I_9_Assist_E_Verify';
    public static final String CONTRACTOR_MANAGEMENT = 'Contractor_Management';
    public static final String INSURANCE_SERVICES ='NSP_Insurance_Services';
    public static final String HR_CONSULTING =  'NSP_Human_Capital_Consulting';
    public static final String RETIREMENT_SERVICES ='NSP_Retirement_Services';
    public static final String WX_IMPL_SUPPORT = 'NSP_WX_IMPL_Support';
    public static final String NATIONAL_BUSINESS_TEAM = 'NSP_National_Business_Team';
    public static final String HRCORE_ONBOARDING_AMENDMENT = 'HRCore_Onboarding_Amendment';

    //Products of Interest Tasks
    public static final String EMPLOYMENT_SCREENING = 'Employment Screening';
    public static final String EXPENSE_MANAGEMENT = 'Expense Management';
    public static final String FULL_SERVICE_HR_WO = 'Full Service HR (Workforce Optimization)';
    public static final String HR_CONSULTING_SERVICES = 'HR Consulting Services';
    public static final String PI_INSURANCE_SERVICES = 'Insurance Services';
    public static final String ORGANIZATIONAL_PLANNING = 'Organizational Planning';
    public static final String PAYROLL_HR_MANAGEMENT_WA = 'Payroll & Human Capital Management(Workforce Acceleration)';
    public static final String PERFORMANCE_MANAGEMENT = 'Performance Management';
    public static final String TIME_AMP_ATTENDANCE = 'Time & Attendance';
    public static final String TIME_ATTENDANCE = NSP_ServiceConstants.TIME_AMP_ATTENDANCE;
    public static final String PI_RECRUITING_SERVICES = 'Recruiting Services';
    public static final String PI_CONTINGENT_WORKFORCE =  'Contingent Workforce';
    public static final String PI_I9_ASSIST_EVERIFY = 'I-9 Assist & E-Verify';
    public static final String PI_CONTRACTOR_MANAGEMENT = 'Contractor Management';
    public static final String PI_RETIREMENT_SERVICES = 'Retirement Services';
    public static final String TIME_AND_ATTENDANCE = 'Time and Attendance';
    public static final String APPLICANT_TRACKING = 'Applicant Tracking';
    public static final String REFERRAL_RECORDTYPE = 'Referral_Task';
    public static final String INTAKE = 'Intake';
    public static final String INTEGRA_IMPLEMENTATION = 'Integra - Implementation';
    public static final String PERFORMSMART_IMPLEMENTATION = 'PerformSmart Implementation';
    public static final String PERFORMANCE_ASSET = 'Performance_Management';
    public static final String XML_IMPLEMENTATION = 'XML Utility – Implementation';
    public static final String BT_ENGAGEMENT_PLAN = 'BT Engagement Plan';
    public static final String TES_TERMINATION = 'TES Termination';
    public static final String WX_BENEFIT_RENEW_PROJ = 'WX Benefits Renewal Project';
    public static final String ITA_IMPLEMENTATION = 'ITA-Implementation';
    public static final String ITA_OTHER = 'ITA-Other';
    public static final String CLIENT_REINSTATE = 'NSP_Client_Reinstatement';
    public static final String TERM_TEAM_APPROVED = 'Term Team Approved';
    public static final String DEPLOYMENT_MANAGER = 'Deployment Manager';
    public static final String PI_HRCORE_ONBOARDING_AMENDMENT = 'HRCore Onboarding Amendment';

    // community Constants
    public static final String peoCommunityAccess = 'PEO Projects';
    public static final String communityUserProfilePlus = 'Customer Community Plus User';
    public static final String projectCommunityPerm = 'NSP_Project_Community_User';
    public static final String RemovePermission = 'RemovePermission';
    public static final String DeactivateUser = 'DeactivateUser';
    public final static String InsperitySharing = 'InsperitySharing';
    public final static String readAccess = 'Read';
    public final static String userAlias = 'Insp';
    public final static String CUSTOMER_COMMUNITY_PLUS ='Customer Community Plus User';
    public final static String READ_ACCESS = 'Read';
    public final static String InProgressStatus = NSP_ServiceConstants.IN_PROGRESS;
    public final static String scheduleStatus = 'Scheduled';
    public final static String dispatchStatus = 'Dispatched';
    public final static String workOrder = 'WorkOrder';
    public final static String NoneStatus = 'None';
    public final static String SerAppDispatchedEmailTemplate = 'NSP_Sales_Region_Rep_Med_Plan';
    public final static String SerAppRecordChangeEmailTemplate = 'NSP_Sales_Region_Rep_Med_Plan_address';
    public final static String SerAppNoneEmailTemplate = 'NSP_Sales_Region_Rep_Med_Plan_Cancelled';
    public final static String SerAppReScheduleEmailTemplate = 'NSP_Sales_Region_Rep_Med_Plan_Reschedule';
    public final static String Task   = 'Task';
    public final static String peoTask   = 'PEO_Service_Task';
    // Lead Constants
    public final static String SERVICE_REFERRAL_RT = 'Service_Referral_Lead';
    //Wizard Output constnats
    public final static String DEVELOPMENT_REPORT = 'Development Report';
    public final static String NEW_REPORT = 'New Report';
    public final static String INTERNAL_REPORT = 'Internal Report';
    public final static String WIZARD_DEVELOPMENT = 'Development';
    public final static String INTERNAL_CLIENT_REPORT = 'Internal – Not for Client';
    public final static String WEBFOCUS_MRE = 'WebFocus (MRE)';
    public final static String WIZARD_MAINTENANCE = 'Maintenance';
    public final static String PREMIER_REPORTING = 'Premier Reporting (WIRE)';
    public final static String WIRE = 'Wire';
    public final static String NON_WIRE = 'Non Wire';
    public final static String bpsAssetPermSet = 'NPS_BPS_Create_Assets_Permission';
    public final static String RSTalentConnectIMP = 'RS TalentConnect Implementation';
    public final static String OPRTImpl = 'OPRT Implementation';
    public final static String TERMINATED_STATUS = 'TERMINATED';

    //SubClientContact EmployeeStatus
    public final static String FMLA_STATUS = 'FMLA';
    public final static String FMLA_WORKERS_STATUS = 'FMLA - WORKERS COMP';
    public final static String FUTURE_HIRED_STATUS = 'FUTURE HIRED';
    public final static String HIRED_STATUS = 'HIRED';
    public final static String LOA_STATUS = 'L.O.A.';
    public final static String LOA_EDU_STATUS = 'L.O.A. - EDUCATION';
    public final static String LOA_MILITARY_STATUS = 'L.O.A. - MILITARY';
    public final static String PRIMED_STATUS = 'PRIMED';
    public final static String REHIRED_STATUS = 'REHIRED';
    public final static String WORKER_COMP_STATUS = 'WORKER\'S COMP';
    public final static String WORK_SITE = 'Worksite';
    public final static String SOURCE = 'AIMS';
    public final static String US_MAIL = 'U.S. Mail';


    //Note constants
    public static final String NOTE_SOBJECT_TYPE = 'NSP_Note__c';
    public final static String XMLProject = 'XML Utility – Implementation';
    public final static String ITA_Prj_Temp = 'ITA-Implementation';
    public final static String PROJECT =  'pse__Proj__c';
    public final static String Premier_Time_Att =  'Premier Time & Attendance';
    public final static String Premier_Timesheet =  'Premier Timesheet';
    public final static String WXWOAsset =  'WX (WO to WX)';
    public final static String TES_BPS = 'TES+BPS';

    //OrgWideEmailAddress Constants
    public static final String ORG_WIDE_EMAIL_SOBJECT_TYPE = 'OrgWideEmailAddress';
    public static final String PROJECT_BPS_RECORDTYPE = 'TES_BPS';

    //Task constants
    public static final String QUARTERLY_MEETING = 'Quarterly Client Meeting';
    public static final String FOLLOW_UP_QUARTERLY = 'Follow Quarterly Call process documentation in Knowledge Base.';
    public static final String WxCarrierConnectionProject = 'WX Carrier Connection';
    public static final String isolvedProject = 'iSolved Benefits';
    public static final String wxEmailTemplate = 'NSP_Wx_Carrier_Project_Notification';
    public static final String PEO_CASE_SUBJECT = 'ITA Implementation in progress for existing client';
    public static final String HR_SHARED_QUEUE = 'NSP_HR_Shared_Services';
    public static final String STAY_STRONG_TP_BASED_ON_UNFAVOURABLE_RATING = 'Stay Strong TP based on unfavorable rating';

    //EmailMessage Constants
    public static final String POSTMASTER_EMAIL_ADDRESS = 'postmaster@';
    public static final String EFAX_CORPORATE_EMAIL_ADDRESS = 'message@inbound.efax.com';
    public static final String CORPORATE_PAYROLL_EMAIL_ADDRESS = 'corporatepayroll@insperity.com';
    public static final String MICROSOFT_VIVA_EMAIL_ADDRESS = 'viva-noreply@microsoft.com';
    public static final String PS_TECH_SUPPORT_EMAIL_ADDRESS = 'pstechsupport@insperity.com';
    public static final String RESTRICTED_EMAIL_ERROR_MESSAGE = 'EmailMessage cannot be created as sender is from restricted list.';
    public final static String WoWSAsset =  'WO/WS';
    public final static String INTERNAL_EMAIL_ADD = '@insperity.com';
    public static final String ClosedCaseIssue = 'Closed';

    //Generic Status Constants
    public static final String SCHEDULED_STATUS = 'Scheduled';
    public static final String COMPLETE_STATUS = 'Complete';
    public static final String CANCELLED_STATUS = 'Cancelled';
    public static final String CLOSED_STATUS = 'Closed';

    //Focus Item constants
    public static final String EARLY_TENURE = 'Early Tenure';
    public static final String EARLY_TENURE_CLIENT = 'Early Tenure Client';
    public static final String UNFAVORABLE = 'Unfavorable';
    public static final String FOCUS_COMMENTS = 'These Client#\'s are less than 2 years old:';
    public static final String FOCUS_401_COMMENTS = 'These Client# do not have an Insperity 401k:';
    public static final String NEUTRAL = 'Neutral';
    public static final String NO_INSPERITY_401K = 'No Insperity 401k';
    public static final String CUSTOMER_RELATIONSHIP = 'Customer Relationship';
    public static final String SOME_WHAT_UNFAVORABLE = 'Somewhat Unfavorable';
    public static final String ORK = 'ORK';
    public static final String UnitedStatesRegion = 'United States';

    //PermissionSet Name constants
    public static final String FSL_DISPATCHER_LICENSE_PS = 'FSL_Dispatcher_License';
    public static final String FSL_DISPATCHER_PERMISSIONS_READ_ONLY_PS = 'FSL_Dispatcher_Permissions_Read_Only';
    public static final String FSL_DISPATCHER_PERMISSIONS_PS = 'FSL_Dispatcher_Permissions';
    public static final String FSL_RESOURCE_PERMISSIONS_PS = 'FSL_Resource_Permissions';
    public static final String FSL_RESOURCE_LICENSE_PS = 'FSL_Resource_License';
    public static final String FSL_READ_ONLY_PS = 'FSL_Read_Only_Permissions';
    public static final String FSL_EDIT_FIELDS_PS = 'Edit_SFS_Fields';
    public static final String EINSTEIN_ACTIVITY_CAPTURE_INCLUDED_PS = 'EinsteinActivityCaptureIncluded';

    public static final String SALESFORCE_FIELD_SERVICE_DISPATCHER = 'Dispatcher';
    public static final String SALESFORCE_FIELD_SERVICE_RESOURCE = 'Resource';
    public static final String SALESFORCE_FIELD_SERVICE_SFS_READONLY = 'SFS read only';
    public static final String SALESFORCE_FIELD_SERVICE_DISPATCHER_RESOURCE = 'Dispatcher + Resource';

    // EmailMessage
    public static final String TASK_SUBJECT_STARTS_WITH_EMAIL = 'Email: ';
    public static final String PermierPerformanceTask = 'Premier Performance Setup';
    public static final String PremierPerformance  = 'Premier Performance';
    public static final String ReviewenrollmentFeeTask  = 'Review and enter Enrollment fee';
    public static final String ReviewenrollmentFee = 'Enrollment fee is charged';
    public static final String PayrollTraining_ML = 'Payroll Training';
    public static final String ClientTrainingCat = 'Client Invoice Training';
    public static final String WebPyPremierTraing = 'Web Payroll/Premier Training';
    public static final String VerifyEnrollFeeTask = 'Verify Enrollment Fee is charged';
    public static final String AssetStatusOnDemand = 'On Demand';
    public static final String REPORTDEVELOPMENT='NSP_ReportDevelopment';
    public static final String BulkPrimingSubCat = 'Bulk Priming (update to Priming)';

    //Event Constant
    public static final String  RESOURCE_ABSENCE_TYPE ='Resource Absence';
    public static final String  Priming_SubCat='Priming';
    public static final String  COBRA_FORM_YES='COBRA Takeover Form collected:';
    public static final String  COBRA_FORM_NO='Need COBRA Takeover Form:';
    public static final String  CAR='Car';
    public static final String  PHONE='Cell Phone';
    public static final String  PER_DIEM='Per Diem';
    public static final String  HOUSE='House';
    public static final String  PC_TYPE ='PC';
    public static final String UNIDENTIFIED_ORK='Unidentified ORK';

    //Sub Category Constants
    public static final String  SUBCATEGORY_NOT_ON_UI ='NOT ON UI';
    public static final String  SUBCATEGORY_PAID_SICK_LEAVE ='Paid Sick Leave';
    public static final String PHONE_CHANNEL = 'Phone';
    public static final String GARNISH_API_NAME='Do_any_EEs_have_garnishments__c';
    public static final String LEVIES_API_NAME='Do_any_EEs_have_tax_levies__c';

    public static final String ONBOARDING_MEETING_REQUEST= 'Onboarding_Meeting_Request';
    public final static String ORIENTATION_MEETING_REQUEST = 'Orientation_Meeting_Request';
    public final static String HR_CLIENT_IMPLEMENTATION_QUEUE = 'NSP_HR_Client_Implementation';
    public static final String UPDATE_TRIGGER = 'update';
    public static final String INSERT_TRIGGER = 'insert';

}
//