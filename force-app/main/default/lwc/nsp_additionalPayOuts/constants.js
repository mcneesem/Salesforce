import IP_DO_YOU_PAY from '@salesforce/schema/Implementation_Profile__c.NSP_Do_you_pay__c';
import IP_SPECIALPAY_CODE from '@salesforce/schema/Implementation_Profile__c.NSP_Any_special_pay_codes_Needed__c';
import IP_STOCK_PURCHASE from '@salesforce/schema/Implementation_Profile__c.Does_the_client_offer_a_Stock_Purchase__c';
import IP_STOCK_OPTIONS from '@salesforce/schema/Implementation_Profile__c.NSP_Does_the_client_offer_Stock_Options__c';
import IP_NON_DISCRETORY_BONUS from '@salesforce/schema/Implementation_Profile__c.NSP_Non_Discretionary_Bonus__c';
import IP_DISCRETORY_FREQUENCY from '@salesforce/schema/Implementation_Profile__c.Non_Discretionary_Bonus_Input_frequency__c';
import IP_COMISSIONFREQUENCY from '@salesforce/schema/Implementation_Profile__c.NSP_Commission_Frequency__c';
import IP_DISCRETORY_BONUS from '@salesforce/schema/Implementation_Profile__c.NSP_Discretionary_Bonus__c';
import IP_COMISSION_TYPE from '@salesforce/schema/Implementation_Profile__c.NSP_Commission_Type__c';
import IP_NON_EXEMPT_EMPLOYEES from '@salesforce/schema/Implementation_Profile__c.Do_you_pay_non_exempt_employees__c';
import IP_DISCRETORY_CODES from '@salesforce/schema/Implementation_Profile__c.NSP_NonDiscretionaryDiscretionaryPayCode__c';


const IP_FIELDS = [
    IP_DO_YOU_PAY,
    IP_SPECIALPAY_CODE,
    IP_STOCK_PURCHASE,
    IP_STOCK_OPTIONS,
    IP_NON_DISCRETORY_BONUS,
    IP_DISCRETORY_FREQUENCY,
    IP_COMISSIONFREQUENCY,
    IP_DISCRETORY_BONUS,
    IP_COMISSION_TYPE,
    IP_NON_EXEMPT_EMPLOYEES,
    IP_DISCRETORY_CODES
];


export { IP_FIELDS }