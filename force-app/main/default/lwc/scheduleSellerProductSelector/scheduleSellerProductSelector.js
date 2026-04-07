import { LightningElement , api , wire } from 'lwc';
import { getRecord , getFieldValue  } from 'lightning/uiRecordApi';
import hasPermission from '@salesforce/customPermission/Schedule_Seller_Admin';

//Oportunity fields
import ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import ACCOUNT_IS_CLIENT from '@salesforce/schema/Opportunity.Account.NSP_Sales_Service_Account_Status__c';
import ACCOUNT_SEGMENT from '@salesforce/schema/Opportunity.NSP_Account_Segment__c';

const FIELDS = [
    ACCOUNT_ID ,
    ACCOUNT_IS_CLIENT ,
    ACCOUNT_SEGMENT ,
];

export default class ScheduleSellerProductSelector extends LightningElement {
    @api selectedProduct;
    @api recordId;
    record;
    error;

    // Loading state
    _isLoaded = false;

    // Cached fields
    _accountSegment;
    _accountIsClient;

    @wire(
        getRecord ,
        { recordId: '$recordId' , fields: FIELDS }
    )
    wiredRecord( { data , error } ) {
        this._isLoaded = false;
        // Normalize to nulls to avoid undefined
        if ( data ) {
            this.record = data;
            this._accountSegment = getFieldValue( this.record , ACCOUNT_SEGMENT );
            this._accountIsClient = getFieldValue( this.record , ACCOUNT_IS_CLIENT );
            this._isLoaded = true;
        } else if ( error ) {
            this.error = error;
            this._accountSegment = undefined;
            this._accountIsClient = undefined;
        }
    }

    get showProductOptions() {
        return ( this._isLoaded && ( this.productOptions?.length > 0 ) );
    }

    // Product options for different account segments
    /* For new skill addition follow the next steps:
        Permission Set: add new Permission Set
        Custom Permission: add new Custom Permission
        Apex: UserAvailabilityService.getStepMinutes() (add to the map)
        LWC: scheduleSellerProductSelector.productOptions() (add to the map)
        Custom Metadata:
            Schedule_Seller_Time_Slot__mdt.Product__c (add picklist value)
            Schedule_Seller_Time_Slot__mdt (Time Slots) – add records
    */

    get productOptions() {
        // Define base options per segment
        const baseBySeg = {
            MidMarket: [
                { label: 'HR360 Solution' , value: 'Schedule_Seller_HR360_MidMarket' } ,
                { label: 'HRCore Solution' , value: 'Schedule_Seller_HRCore_MidMarket' } ,
                { label: 'HRScale' , value: 'Schedule_Seller_HRScale' } ,
            ] ,
            Enterprise: [
                { label: 'HR360 Solution' , value: 'Schedule_Seller_HR360_Enterprise' } ,
                { label: 'HRCore Solution' , value: 'Schedule_Seller_HRCore_Enterprise' } ,
                { label: 'HRScale' , value: 'Schedule_Seller_HRScale' } ,
            ] ,
            Default: [
                { label: 'HR360 Solution' , value: 'Schedule_Seller_HR360' } ,
                { label: 'HRCore Solution' , value: 'Schedule_Seller_HRCore' } ,
                { label: 'HRScale' , value: 'Schedule_Seller_HRScale' } ,
            ] ,
        };
        // Extended options shown only when user has permission and client is Active
        const extended = [
            { label: 'Time and Attendance' , value: 'Schedule_Seller_Time_Attendance' } ,
            { label: 'Performance Management' , value: 'Schedule_Seller_Performance_Management' } ,
            { label: 'Performance Management / Time & Attendance' , value: 'Schedule_Seller_Performance_Management_Time_Attendance' }
        ];
        // Pick base list by segment
        let base = baseBySeg.Default;
        if ( this._accountSegment === 'MidMarket' ) {
            base = baseBySeg.MidMarket;
        } else if ( this._accountSegment === 'Enterprise' ) {
            base = baseBySeg.Enterprise;
        }
        // Single flag to decide if extended options apply
        const canShowExtended = ( ( hasPermission === true ) && ( this._accountIsClient === 'Active' ) );
        // Return base plus extended (when allowed) or just base
        return ( canShowExtended ? [...base, ...extended] : base );
    }

    handleProductChange( event ) {
        this.selectedProduct = event?.detail?.value;
    }

}
//