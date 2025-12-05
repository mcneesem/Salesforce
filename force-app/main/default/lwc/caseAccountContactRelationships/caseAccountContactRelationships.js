import { LightningElement, wire, api } from 'lwc';
import getACRDetails from '@salesforce/apex/CaseAccountContactRelationController.getACRDetails';
import { refreshApex } from '@salesforce/apex';
export default class CaseAccountContactRelationships extends LightningElement {
    @api recordId;
    acrDetailsData;
    acrPrimaryData;
    displayDataList;
    wireData;
    lastUpdatedTimestamp;
    currentTimestamp;
    intervalId;
    acrDetailsError;
    coulums =[{label: 'Name', fieldName: 'contactName', type: 'text'},
        {label: 'Account', fieldName: 'accountName', type: 'text'},
        {label: 'Work Phone', fieldName: 'workPhone', type: 'text'},
        {label: 'Work Email', fieldName: 'workEmail', type: 'text'},
        {label: 'Job Title', fieldName: 'jobTitle', type: 'text'},
        {label: 'Status', fieldName: 'status', type: 'text'},
        {label: 'Workday Employee Id', fieldName: 'workdayEmployeeId', type: 'text'}
    ]

    @wire(getACRDetails, { caseId: '$recordId' })
    acrDetails(result){
        this.wireData = result;
        if (result.data) {
            this.acrDetailsData = result.data;
            this.lastUpdatedTimestamp = new Date();
            this.displayDataList = this.acrDetailsData.filter(rec => rec.IsPrimary);
            if(this.displayDataList == null || this.displayDataList.length == 0 ||this.displayDataList == undefined){
                this.displayDataList = this.acrDetailsData;
            }
        } else if (result.error) {
            this.acrDetailsError = result.error;
            this.lastUpdatedTimestamp = undefined;
        }
        if ( this.lastUpdatedTimestamp && this.hasData ) {
            this.currentTimestamp = new Date();
        }
    }


    handleViewAll(){
       this.displayDataList = this.acrDetailsData;
    }


    handleRefresh(){
        refreshApex(this.wireData);
    }

    get hasData() {
        return ( this.total > 0 );
    }

    get title() {
        return "Account Contact Information (" + this.total + ")";
    }

    get total() {
        return ( this.displayDataList ? this.displayDataList.length : 0 );
    }

    get summary() {
        return ( "" + this.total + " items" );
    }

     get containerClass() {
        return ( "container-border" );
    }

    get cardClass() {
        return ( "card-header-spacing-block-end-zero card-body-spacing-block-zero card-footer-spacing-block-zero card-color-background" );
    }

    get titleSlotClass() {
        return ( "slds-m-left_small " + ( this.hasData ? "slds-m-left_small slds-p-top_small slds-p-bottom_small" : "slds-m-left_small slds-p-top_x-small slds-p-bottom_x-small" ) );
    }

    get titleClass() {
        return ( "slds-show_inline slds-m-left_small" );
    }

    get summaryClass() {
        return ( "slds-text-body_small font-weight-400 slds-m-left_small slds-p-bottom_small" );
    }

    get datatableClass() {
        return ( "datatable-border-top" );
    }

    get footerSlotClass() {
        return ( "slds-p-left_small slds-p-right_small card-footer-background" );
    }
}