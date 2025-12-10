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
            this.intervalId = setInterval(
                function() {
                    this.currentTimestamp = new Date();
                    if ( !this.hasData // stop summary refresh when data is missing...
                        || !this.secondsSinceLastUpdate
                        || ( this.secondsSinceLastUpdate > ( 2 * 60 * 60 ) ) // stop summary refresh after 2 hours...
                        )
                    {
                        if ( this.intervalId ) {
                            clearInterval( this.intervalId );
                        }
                        this.intervalId = undefined;
                    }
                }.bind( this ) ,
                ( 60 * 1000 ) // refresh once per minute ( 1 minute == 60 seconds == 60000 milliseconds )
            );
        }
    }

    handleViewAll() {
       this.displayDataList = this.acrDetailsData;
    }

    handleRefresh() {
        refreshApex( this.wireData );
    }

    get hasData() {
        return ( this.total > 0 );
    }

    // title helpers...

    get title() {
        return "Account Contact Information (" + this.total + ")";
    }

    get total() {
        return ( this.displayDataList ? this.displayDataList.length : 0 );
    }

    // summary helpers...

    get summary() {
        return ( "" + this.total + " items" + this.lastUpdatedSummary );
    }

    get lastUpdatedSummary() {
        return ( this.hasSummaryTimestamps ? " • Updated " + this.lastUpdatedFriendly + " ago" : "" );
    }

    get lastUpdatedFriendly() {
        let response = "";
        if ( this.hoursSinceLastUpdate ) {
            if ( this.hoursSinceLastUpdate > 1 ) {
                response = "" + this.hoursSinceLastUpdate + " hours";
            } else if ( this.hoursSinceLastUpdate > 0 ) {
                response = "an hour";
            }
        } else if ( this.minutesSinceLastUpdate ) {
            if ( this.minutesSinceLastUpdate > 1 ) {
                response = "" + this.minutesSinceLastUpdate + " minutes";
            } else if ( this.minutesSinceLastUpdate > 0 ) {
                response = "a minute";
            }
        } else if ( this.secondsSinceLastUpdate || ( this.secondsSinceLastUpdate === 0 ) ) {
            response = "a few seconds";
        }
        return response;
    }

    get hoursSinceLastUpdate() {
        return ( this.secondsSinceLastUpdate ? Math.floor( this.minutesSinceLastUpdate / 60 ) : undefined );
    }

    get minutesSinceLastUpdate() {
        return ( this.secondsSinceLastUpdate ? Math.floor( this.secondsSinceLastUpdate / 60 ) : undefined );
    }

    get secondsSinceLastUpdate() {
        return ( this.hasSummaryTimestamps ? Math.floor( ( this.currentTimestamp - this.lastUpdatedTimestamp ) / 1000 ) : undefined );
    }

    get hasSummaryTimestamps() {
        return ( this.currentTimestamp && this.lastUpdatedTimestamp );
    }

    // dynamic style class helpers...

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
        return ( "slds-show_inline slds-align-middle slds-m-left_small" );
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
//