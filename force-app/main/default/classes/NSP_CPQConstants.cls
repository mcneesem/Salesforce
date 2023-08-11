/**
 * Represents the contant class used for cpq track.
 * Author CPQ Team
 */

public class NSP_CPQConstants {
    // test w/ NSP_CPQConstants (100%)

    // To set the Quote Approval status Pending
    public static final String QUOTE_APPROVAL_STATUS_PENDING = 'Pending'; 
    // To set the Quote Approval status Approved  
    public static final String QUOTE_APPROVAL_STATUS_APPROVED = 'Approved';  
    // To set the Quote Approval status Reject
    public static final String QUOTE_APPROVAL_STATUS_REJECTED ='Rejected';  
    // To set the Quote Approval status Recalled
    public static final String QUOTE_APPROVAL_STATUS_RECALLED ='Recalled';
    // To set the Quote status Submitted for Approval
    public static final String QUOTE_STATUS_SFA ='Submitted For Approval';
    // To set the Quote status Approved
    public static final String QUOTE_STATUS_APPROVED ='Approved';
    // To set the Quote status Draft
    public static final String QUOTE_STATUS_REJECTED ='Draft';
    // To set the Quote status Draft
    public static final String QUOTE_STATUS_RECALLED ='Draft';
    
    public static final String SCHOLARSHIP_PUBLIC_GROUP ='Scholarship Applicable BPA';
    public static final String SE_APPROVAL_Chain = 'SE Approval Chain';
    public static final String APPLICABLE_TRANSACTION_TYPE = 'Supplemental';
    public static final String SUPPLEMENTAL_ONLY_TRANSACTION_TYPE = 'Supplemental Only';
    public static final String OPPORTUNITY_TYPE_NEW_BUSINESS = 'New Product';
    public static final String OPPORTUNITY_TYPE_EXISTING_BUSINESS = 'Existing Product';
    // Static values for Quote Type
    public static final String QUOTE_TYPE_NEW ='New Product';
    public static final String QUOTE_TYPE_AMENDMENT ='Amendment';
    public static final String QUOTE_TYPE_RENEWAL ='Renewal';
    public static final String QUOTE_TYPE_TERMINATION ='Termination';
    public static final String SUPPLEMENTAL ='Supplemental';
    public static final String SUPPLEMENT ='Supplement';
    public static final String SUPPLEMENTBPS ='SupplementBPS';
    public static final String PROPOSAL ='Proposal';
    // Static values for required Product Type
    public static final String QUOTE_PRODUCT_TYPE_TC ='Talent Connect';
    public static final String QUOTE_PRODUCT_TYPE_WX ='Workforce Acceleration';
    public static final String QUOTE_PRODUCT_TYPE_WA ='Workforce Administration';
    public static final String QUOTE_PRODUCT_TYPE_HRCS ='HR Consulting Services';
    public static final String QUOTE_PRODUCT_TYPE_ORGPLUS ='Organizational Planning';
    public static final String QUOTE_PRODUCT_TYPE_PERFORMSMART ='Performance Management';
    public static final String QUOTE_PRODUCT_TYPE_LEARNDEV ='Learning and Development';
    public static final String QUOTE_NEW_SHOW_DISCOUNT_BPS = 'BPSWithDiscount';
    public static final String QUOTE_NEW_SHOW_DISCOUNT_Timestar = 'TimestarWithDiscount';
    public static final String QUOTE_AMENDMENT_SHOW_DISCOUNT_BPS = 'AmendmentBPSWithDiscount';
    public static final String QUOTE_RENEWAL_SHOW_DISCOUNT_BPS = 'RenewalBPSWithDiscount';
    public static final String QUOTE_SCHOLARSHIP = 'IWXScholarship';
    //Static values for required pricing model
    public static final String LIST_PRICE_MODEL ='List Price';
    public static final String WX_PRICE_MODEL ='WX';
    //Static values for Product Codes
    public static final String RECRUITING_BUNDLE ='RecruitingBundle';

    public static final String NONE_VALUE ='None';
    public static final String MONTHLY ='Monthly';
    public static final String ALTULA ='ALTULA';
    public static final String CLIENT_WOWS ='WO/WS';
    public static final String OPPTY_WO ='WO';

    public static final String QUOTELINE_APPLICABLEPRODUCT = 'IWXBundleW2;IWXBundle';
    public static final String QUOTELINE_APPLICANTTRACKING = 'Applicant Tracking';

    public static final String PRODUCT_CHARGETYPE_RECURRING = 'Recurring';
    
    public static final String NOT_ASSIGNED ='Not Assigned';
    public static final String SBQQ_TYPE_FIELD_API ='SBQQ__Type__c';
    public static final String ADDRESS ='Address';
    public static final String ACCOUNT ='Account';
    
    //Static Codes for Order Product Activation Trigger
    public static final String  FIRSTUSAGEUPLOAD ='First Usage Upload';
    public static final String  PROJGOLIVEDATE ='Project Go Live';
    public static final String  PLANACTIVATION ='Plan Activation';
    public static final String  IMMEDIATE ='Immediate';
    public static final String  MILESTONEBASED ='Milestone Based';

    //Order Status
    public static final String ORDER_ACTIVATED ='Activated';
    public static final String ORDER_REVIEWED ='Reviewed';
    public static final String ORDER_DRAFT ='Draft';
    public static final String BLNGFREQ_MONTHLY ='Monthly';
    public static final String BLNGFREQ_ANNUAL ='Annual';
    public static final String ORDER_TYPE_NEW ='New Product';
    public static final String ORDER_TYPE_AMENDMENT ='Amendment';
    
    public static final String ORDERITEM_RECALCULATIONSTATUS_NA ='Not Applicable';

    //Quote Line Actions
    public static final String ACTION_NEW ='Add Product';
    public static final String ACTION_DOWNGRADE ='Downgrade';
    public static final String ACTION_UPSELL ='Upsell';
    public static final String ACTION_AMEND ='Amend';

    //Static values Billing Transaction
    public static final String PROJ_GO_LIVE = 'Project Go Live';
    public static final String BLNG_STATUS_PENDING = 'Pending';
    public static final String PROJ_COMPLETE = 'Project Completion';
    public static final String BLNGTYPE_ADVANCE = 'Advance';
    public static final String BLNGTYPE_ARREARS = 'Arrears';
    public static final String FIRSTDAYOFMONTH = '1';
    public static final String INVRUN_PENDING = 'Pending Billing';
    
    //Recurssion Flag
    public static Boolean HAS_BLK_RAN = false;

    //Static values Revenue Recognition
    public static final String PROJ_REV_REC12_INV_DIST='Project Rev Rec 12 (Invoice)';
    public static final String PROJ_REV_REC_INV_DIST='Project Rev Rec (Invoice)';
    public static final String PROJ_REV_REC_CRED_DIST='Project Rev Rec (Credit)';
    public static final String PROJ_REV_REC12_CRED_DIST='Project Rev Rec 12 (Credit)';
    public static final String PROJ_REV_REC='Project Rev Rec';
    public static final String PROJ_REV_REC12='Project Rev Rec 12';
    public static final String DELAY_12_1='12 Delay 1';
    public static final String IMMEDIATE_REV='Immediate';
    public static final String MONTH_12='12 Month';
    public static final String NO_TAX='No Tax - BPS';
    public static final String PAYMYENT_GL_RULE='BPS Cash (Invoice-AR)';
    public static final String HARDWARE_ASSET= 'Hardware Asset';
    public static final String ACTIVE='Active';
    public static final String PURCHASED='Purchased';
    public static final String HARDWARE=' Hardware';
    public static final String TERMINATED='Terminated';
    public static final String HARWARE_ASSET_RECORDTYPE='Hardware_Asset';
    public static final String FINBOOK='Insperity Salesforce Finance Book';
    public static final String ACCOUNTING='Accounting';
    public static final String TIME_AND_ATTENDANCE='Time & Attendance Hardware';
    public static final String INVOICE_PLAN='Invoice Plan';
    public static final String INVOICE_UP_FRONT_PLAN='Invoice Upfront Plan';
    public static final String ANNUAL='Annual';
    public static final String IWXSU='IWXSU';
    public static final String IWASU='IWASU';

    //Exception handeling error messages
    public static final String EXCEP_VALID_RECORD_CHECK= 'checkValidRecordForProcess';
    public static final String EXCEP_PROC_LOCKBOX= 'callProcessLockBoxLogic';

     //Subscription Start Date values
     public static final String SUBS_PROJGOLIVE = 'Project go-live date';
     public static final String SUBS_ODERACTIVATEPLUS1MONTH = 'Order Activated plus 1 Month';

     //Subscription Type
     public static final String SUBS_EVERGREEN = 'Evergreen';
     public static final String SUBS_RENEWABLE = 'Renewable';

     //Boolean values
     public static final String YES = 'YES';

     public static final String ASSETDEFAULTS = 'NSP_TestDataFactory.AssetDefaults';
     public static final String PROJECTDEFAULTS = 'NSP_TestDataFactory.ProjectDefaults';
     public static final String FOCUSITEM_DEFAULTS = 'NSP_TestDataFactory.focusItemDefaults';

     public static final String DUNNING = 'Dunning';

     public static final String INVOICESTATUS = 'Posted';

     public static final String ASSET = 'Asset';
     public static final String NAME = 'Name';
     public static final String ASSET_NSPCLIENT = '0089';
     public static final String NSPCLIENT_APINAME = 'NSP_Client__c';

     public static final String TESTVALUE = 'Test Value';
     public static final String TESTLABEL = 'Test Label';
     public static final String TESTINFO = 'Test info';
     public static final String TESTICONNAME = 'Test iconName';

     //FocusItem
     public static final String FOCUSITEM_NAME = 'Focus Item';    

     //AccountGroup
     public static final String ACCOUNTGROUP_NAME1 = 'OrgPlus Support Group - Test Grp 2';
     public static final String ACCOUNTGROUP_NAME2 = 'Account Health - Test Grp 1';
     public static final String ACCOUNTGROUP_APINAME = 'NSP_Account_Group__c';

     //InvoiceBatch
     public static final String RETSERVICES = 'Retirement Services';
     public static final String RETINVBATCHWO = 'Retirement Services Recurring - WO';
     public static final String RETINVBATCHNONWO = 'Retirement Services Recurring - Non WO';

}