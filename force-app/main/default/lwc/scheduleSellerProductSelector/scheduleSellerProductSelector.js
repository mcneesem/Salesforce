import { LightningElement, api, wire } from 'lwc';
import { getRecord,getFieldValue  } from 'lightning/uiRecordApi';
import hasPermission from '@salesforce/customPermission/Schedule_Seller_Admin';

//Oportunity fields
import ACCOUNT_SEGMENT from '@salesforce/schema/Opportunity.NSP_Account_Segment__c';
import ACCOUNT_ID from '@salesforce/schema/Opportunity.AccountId';
import ACCOUNT_IS_CLIENT from '@salesforce/schema/Opportunity.Account.NSP_Sales_Service_Account_Status__c';

const FIELDS = [ACCOUNT_SEGMENT, ACCOUNT_ID, ACCOUNT_IS_CLIENT];

export default class ScheduleSellerProductSelector extends LightningElement {
    @api selectedProduct;
    @api recordId;
    opportunity;
    error;

    // Loading state
    isLoading = true;

    // Cached fields
    _accountSegment;
    _accountIsClient;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS})
        wiredOpportunity( { data , error } ) {
            // Normalize to nulls to avoid undefined
            if (data) {
                this.opportunity = data;
                this._accountSegment = getFieldValue(data, ACCOUNT_SEGMENT) ?? null;
                this._accountIsClient = getFieldValue(data, ACCOUNT_IS_CLIENT) ?? null;
                this.isLoading = false;
            } else if (error) {
                this.error = error;
                this._accountSegment = null;
                this._accountIsClient = null;
                this.isLoading = false;
            } else {
                // Neither data nor error (intermediate state) - keep loading true
                this._accountSegment = this._accountSegment ?? null;
                this._accountIsClient = this._accountIsClient ?? null;
            }
        }

     get accountSegment() {
        const seg = this._accountSegment ?? null;
        return seg;
    }

    // Convenience getter for templates
    get isLoaded() {
        return !this.isLoading;
    }

    // Product options for different account segments
    get productOptions() {
        const seg = this._accountSegment ?? null;
        const isClient = this._accountIsClient ?? null;

        // Define base options per segment
        const baseBySeg = {
            MidMarket: [
                { label: 'HR360 Solution', value: 'Schedule_Seller_HR360_MidMarket' },
                { label: 'HRCore Solution', value: 'Schedule_Seller_HRCore_MidMarket' },
                { label: 'HRScale', value: 'Schedule_Seller_HRScale' }
            ],
            Enterprise: [
                { label: 'HR360 Solution', value: 'Schedule_Seller_HR360_Enterprise' },
                { label: 'HRCore Solution', value: 'Schedule_Seller_HRCore_Enterprise' },
                { label: 'HRScale', value: 'Schedule_Seller_HRScale' }
            ],
            Default: [
                { label: 'HR360 Solution', value: 'Schedule_Seller_HR360' },
                { label: 'HRCore Solution', value: 'Schedule_Seller_HRCore' },
                { label: 'HRScale', value: 'Schedule_Seller_HRScale' }
            ]
        };

        // Extended options shown only when user has permission and client is Active
        const extended = [
            { label: 'Time and Attendance', value: 'Schedule_Seller_Time_Attendance' },
            { label: 'Performance Management', value: 'Schedule_Seller_Performance_Management' }
        ];

        // Pick base list by segment
        const base =
            seg === 'MidMarket' ? baseBySeg.MidMarket
          : seg === 'Enterprise' ? baseBySeg.Enterprise
          : baseBySeg.Default;

        // Single flag to decide if extended options apply
        const canShowExtended = hasPermission === true && isClient === 'Active';

        // Return base plus extended (when allowed) or just base
        return canShowExtended ? [...base, ...extended] : base;
    }

    handleProductChange(event) {
        const value = event && event.detail ? event.detail.value : null;
        this.selectedProduct = value;
    }

    get showProductOptions() {
        const seg = this.accountSegment;
        const show = seg !== undefined && seg !== null;
        return show;
    }
}