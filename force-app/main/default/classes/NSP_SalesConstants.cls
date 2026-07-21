/**
* @Author : Tejas Patkar
* @description  : Represents the contant class used for sales track.
* @date 06/11/2021
* Name : NSP_SalesConstants
*/
public class NSP_SalesConstants {
    // test w/ NSP_SalesConstantsTest (100%)

    //To set lead stage as sales ready
    public static final String LEAD_STAGE_SRL = 'Sales Ready';
    //To set lead stage non Prioritized
    public static final String LEAD_STAGE_SUSPECT = 'Non-Prioritized';
    //To set lead stage as Prioritized
    public static final String LEAD_STAGE_MPL ='Prioritized';
    //To set opportunity stage as closed lost
    public static final String CLOSED_LOST ='Closed Lost';
    //To set opportunity stage as closed won
    public static final String CLOSED_WON ='Closed Won';

    public static final String ACTIVE ='Active';
    public static final String AVAILABLE ='Available';
    public static final String ASSIGNED ='Assigned';
    public static final String INACTIVE ='Inactive';
    public static final String PROSPECTING ='Prospecting';
    public static final String SOLD ='Sold';
    public static final String UPSELLING ='Upselling';
    // To set primary product as WO
    public static final String WO ='WO';
    public static final String WS ='WS';
    public static final String HRScale ='HRScale';
    // To set primary product as WX
    public static final String WX ='WX';
    public static final String WA ='WA';
    public static final String WOSS ='WOSS';
    public static final String CONTRACTOR_MANAGEMENT ='Contractor Management';
    public static final String STAND_ALONE ='Stand Alone';
    // To set opportunity type as CAMS
    public static final String OPPORTUNITY_TYPE_CAMS ='CAMS';
    // To set primary product as Retirement services
    public static final String RETIREMENT_SERVICE ='Retirement Services';
    // To set primary product as Insurance services
    public static final String INSURANCE_SERVICE ='Insurance Services';
    // To set opportunity type as Needs Analysis
    public static final String OPPORTUNITY_STAGENAME_ANALYSIS ='Needs Analysis';
    public static final String STR_NEW ='New';
    // 118442- To set opportunity type as Client Growth Credit
    public static final String CLIENT_GROWTH_CREDIT ='Client Growth Credit';
    // To set opportunity type as New Product
    public static final String NEW_BUSINESS_OPPORTUNITY ='New Product';
    // To set opportunity type as Prospecting
    public static final String PROSPECTING_STAGE ='Prospecting';
    // To set opportunity type as Data Collection
    public static final String DATA_COLLECTION_STAGE ='Data Collection';
    // To set opportunity type as Discovery
    public static final String BID_STATUS_LOCKED = 'Bid Locked';
    public static final String DISCOVERY_STAGE ='Discovery';
    // To set opportunity type as Analysis
    public static final String ANALYSIS_STAGE ='Analysis';
    public static final String BID_STATUS_APPROVED = 'Approved';
    // To set opportunity type as Proposal
    public static final String PROPOSAL_STAGE ='Proposal';
    public static final String DISCOVERY_CALL_ACTIVITY = 'Discovery Call';
    public static final String DISCOVERY_CALL_COMPLETED = 'Completed';
    public static final String WO_BUSINESS_PROFILE = 'WO Business Profile';
    public static final String WO_PROPOSAL = 'WO Proposal';
    public static final String CLOSING_STAGE = 'Closing';
    //To set opportunity stage as closed won
    public static final String CLOSED_WON_STAGE = 'Closed Won';
    public static final String FORECAST_STATUS_PENDING = 'Pending-Docs Submitted to NCS';
    public static final String FORECAST_STATUS_SOLDBOOKED = 'Sold-Booked';
    //To set opportunity stage as closed lost
    public static final String CLOSED_LOST_STAGE = 'Closed Lost';
    public static final String LOCKED_OPPORTUNITY = 'Opportunity_Locked';
    public static final String APPROVAL_STATUS_PENDING = 'Pending';
    public static final String APPROVAL_STATUS_APPROVED = 'Approved';
    public static final String APPROVAL_STATUS_REJECTED ='Rejected';
    public static final String APPROVAL_STATUS_RECALLED ='Recalled';
    public static final String COMPLETED ='Completed';
    public static final String OPEN ='Open';
    public static final String WORKFORCE_OPTIMIZATION ='Workforce Optimization';
    public static final String APPROVAL_REQUESTED='Approval Requested';
    public static final String MARGIN_APPROVAL_REQUESTED='Margin Approval Requested';
    public static final String MARGIN_APPROVED = 'Margin Approved';
    public static final String MARGIN_REJECTED = 'Margin Rejected';
    public static final String APPROVAL_REQUIRED = 'Approval Required';
    public static final String NOT_REQUIRED = 'Not Required';
    public static final String NON_CPQ_PRICEBOOK = 'Non-CPQ Product Pricebook';
    public static final String RENEWAL_OPPORTUNITY = 'Renewal';
    public static final String CLIENT_REFERENCE_TASKTYPE = 'Client reference';

    public static final String ONBOARDING = 'Onboarding';
    public static final String PARTNER_AGREEMENT = 'Partner Agreement';
    public static final String CHANNELS = 'Channels';
    public static final String PARTNER_CONTRACT_GENERATED = 'Partner Contract Generated';

    public static final Integer MIDMARKET_NUMBEROFEMPS = 150;
    public static final Integer CORESALES_NUMBEROFEMPS = 50;
    public static final String CORE_SALES = 'Core';
    public static final String MIDMARKET_SALES = 'MidMarket';
    public static final String EMERGING_GROWTH = 'Emerging Growth';
    public static final String ENTERPRISE_SALES = 'Enterprise';

    public static final String NCS_SALES_GROUP = 'NSP_NCS_Group';
    public static final String NCS_SALES_TASK_SUBJECT = 'HSA Addendum Request';
    public static final String ADDENDUMREQUEST_TASKTYPE = 'Addendum Request';

    public static final String CALL_BACK_TASK = 'Call Back';
    public static final String LeadQualifier = 'Lead Qualifier';
    public static final String LEAD_STATUS_QUALIFIED = 'Qualified';
    public static final String Account = 'Account';
    public static final String successResponse = 'success';
    public static final String existsResponse = 'exists';
    public static final String BPA_User = 'Business Performance Advisor';
    public static final String DUMMY_USER_SIGNER = 'Dummy User Signer';
    // Added to set Session Type in NSP_FinancialAnaylsisToolController
    public static final String SessionType = 'AURA';
    public static final String TRANSACTION_TYPE_TERMINATION = 'Termination';
    public static final String OPPORTUNITY_TYPE_EXISTING_PRODUCT = 'Existing Product';
    public static final String OPPORTUNITY_TYPE_RENEWAL = 'Renewal';
    public static final String EVALUATION = 'Evaluation';
    //Added for manual Sharing
    public static final String bPARole = 'Business Performance Advisor';
    public static final String aBPARole = 'Associate Business Performance Advisors';
    //Added user roles
    public static final String BUSINESS_PERFORMANCE_CONSULTANT = 'Business Performance Consultant';
    public static final String RETIREMENT_SALES_CONSULTANT = 'Retirement Sales Consultant';
    public static final String INSURANCE_SALES = 'Insurance Sales';
    public static final String RECRUITING_SALES = 'Recruiting Sales';
    public static final String channelOperation = 'Channel Operations';
    public static final String manualRowCause = 'Manual';
    public static final String editSharingAccess = 'Edit';
    public static final String readSharingAccess = 'Read';
    public static final String OPPORTUNITY_SUBTYPE_AMENDMENT = 'Amendment';
    public static final String MIDMARKETSALESOFFICE = '4499';
    public static final String SalesOfficeObject = 'User';
    public static final String SalesOffice = 'NSP_Sales_Office__c';
    public static final String HR_CONSULTING_SERVICES = 'HR Consulting Services';
    public static final String WO_WS = 'WO/WS';
    public static final String BPC_USER = 'Business Performance Consultant';
    public static final String NEW_CLIENT_SALES = 'New Client Sales';
    public static final String MIDMARKETREGION  = 'MidMarket';
    public static final String EloquaTaskRecordType  = 'Eloqua Task RT';
    public static final String OpportunityTeamMemberRole  = 'Other';
    public static final String TECHNOLOGY_SALES = 'Technology Sales';
    public static final String officeProcessing = 'Processing Complete';
    //Added as part of 128176
    public static final String SalesManager = 'Sales Manager';
    public static final String Account_View_All_Modify_All ='Account_View_All_Modify_All';
    public static final String userId = '005';
        //Case related constants
    public static final String HR_SERVICES = 'HR Services';
    public static final String Discuss_Paid_Sick_Leave = 'Discuss Paid Sick Leave';
    //Account related Constants
    public static final String CUSTOMER = 'Customer';
    //Account Team member constants
    public static final String MANAGERHRSERVICE = 'Manager, HR Services';
    public static final String ClientLiaison = 'Client Liaison';
    public static final String HRSpecialist = 'HR Specialist';
    public static final String BPSUser = 'BPS User';
    // QuoteLine related constants
    public static final String ACTION_TYPE = 'Add Product';
    // Project related constants
    public static final String WO_PROJECT_TEMPLATE_KEY = 'Workforce Optimization/Synchronization';
    //PTO Smartforms constants
    public static final String AIMS = 'NSP_AIMS';
    public static final String ITA = 'NSP_ITA';
    public static final String Queue = 'Queue';
    public static final String NSP_AIMS_form = 'NSP_AIMS_form';
    public static final String NSP_ITA_form = 'NSP_ITA_form';
    public static final String NSP_Middle_Market_PTO = 'NSP_Middle_Market_PTO';
    public static final String Submitted = 'Submitted';
    public static final String NSP_National_PTO = 'NSP_National_PTO';
    public static final String HRInfrastructure = 'HR Infrastructure';
    public static final String PTOPlanAnalysisDevelopmentandtracking = 'PTO Plan Analysis, Development and tracking';
    public static final String PTOSmartformSetup = 'PTO Smartform Setup';
    public static final String Resubmit = 'Resubmit';
    public static final String Draft = 'Draft';
    public static final String Closed = 'Closed';
    public static final String Cancelled = 'Cancelled';
    public static final String PTOSmartformresubmitted = 'PTO Smartform resubmitted';
    public static final String CaseSubject = 'Case sub-status has been updated to PTO Smartform resubmitted';
    public static final String Reopened = 'Reopened';
    public static final String Yes = 'Yes';
    public static final String No = 'No';
    public static final String FLSACategory = 'HR Admin Compliance – FLSA';
    public static final String FLSASubCategory = 'FLSA Full Service';
    public static final String midMarket = '4499 MidMarket';
    public static final String FLSASubCategory1 = 'FLSA Basic Service';
    public static final String FLSASubCategory2 = 'FLSA Quick Check Service';
    public static final String PayrollSpecialist = 'Payroll Specialist';
    public static final String InProgress = 'In Progress';
    public static final String Resolved = 'Resolved';
    //Asset related constants
    public static final String ONDEMAND_STATUS = 'On Demand';
    public static final String PROD_RECRUITING = 'Recruiting Services';
    public static final String PROD_EMPSCREENING = 'Employment Screening';
    public static final String PROD_EXPENSEMANAGEMENT = 'Expense Management';
    public static final String PROD_INSURANCE = 'Insurance Services';
    public static final String ASSETRECTYPE_INSURANCE = 'Insurance Service';
    public static final String ASSETRECTYPE_CERTIFY = 'Certify';
    public static final String BACKOUT_STATUS = 'Backout';
    public static final String TERMINATED_STATUS = 'Terminated';
    public static final String ACTIVE_STATUS = 'Active';
    public static final String ACTIVATED_STATUS = 'Activated';
    public static final String PROD_WX = 'Workforce Acceleration';
    public static final String PROD_WA = 'Workforce Administration';
    public static final String RET_Plan_Activation = 'Plan Activation';
    public static final String PEOTOWX = 'PEO to WX';
    public static final String WOTOWX = 'WX (WO to WX)';
    public static final String WOTOWA = 'WA (WO to WA)';
    //Added as part of user story 128436
    public static final String Task_Type ='Core Sales';
    public static final String Task_SubType = 'WX Quote';
    //Added as part of user story 280309
    public static final String INTEGRATION_USER_PROFILE_ID = '00e4x0000012vOHAAY';
}