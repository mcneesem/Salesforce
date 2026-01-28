import { LightningElement, wire, api } from 'lwc';
import getACRDetails from '@salesforce/apex/CaseAccountContactRelationController.getACRDetails';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
export default class CaseAccountContactRelationships extends LightningElement {
    @api recordId;
    acrDetailsData;
    acrPrimaryData;
    isViewAll = false;
    relatedWireResult;
    wireData;
    lastUpdatedTimestamp;
    currentTimestamp;
    intervalId = null;
    acrDetailsError;
    sortedBy;
    sortedDirection = 'asc';
    
    coulums =[{label: 'Name', fieldName: 'contactName', type: 'text', sortable: true},
        {label: 'Account', fieldName: 'accountName', type: 'text', sortable: true},
        {label: 'Work Phone', fieldName: 'workPhone', type: 'text', sortable: true},
        {label: 'Work Email', fieldName: 'workEmail', type: 'text', sortable: true},
        {label: 'Job Title', fieldName: 'jobTitle', type: 'text', sortable: true},
        {label: 'Status', fieldName: 'status', type: 'text', sortable: true},
        {label: 'Workday Employee Id', fieldName: 'workdayEmployeeId', type: 'text', sortable: true}
    ]


    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: 'Case_Contact_Roles__r',
        fields: ['NSP_Case_Contacts__c.NSP_Case__c', 'NSP_Case_Contacts__c.Id']
    })
    listInfo( response ) {
        this.relatedWireResult = response;
        if ( response ) {
            const { error, data } = response;
            if ( data ) {
                this.lastUpdatedTimestamp = new Date();
                this.getACRDataDetails();
            } else if ( error ) {
                this.acrDetailsError = error;
                this.lastUpdatedTimestamp = undefined;
            }
        }   
    }
    
    getACRDataDetails() {
        getACRDetails({ caseId: this.recordId })
            .then(result => {
                this.acrDetailsData = result;
                this.lastUpdatedTimestamp = new Date();
                this.isViewAll = false;
                this.handleLastUpdatedInterval();
            })
            .catch(err => {
                this.acrDetailsError = err;
                this.lastUpdatedTimestamp = undefined;
            });
        
    }

    handleSort( event ) {
        if ( event?.detail) {
            this.sortedBy = event.detail.fieldName;
            this.sortedDirection = event.detail.sortDirection;
            this.sortData();
        }
    }

    sortData() {
        if ( this.acrDetailsData && this.sortedBy && this.sortedDirection ) {
            const isReverse = ( ( this.sortedDirection === 'asc' ) ? 1 : -1 );
            const cloneData = [...this.acrDetailsData];
            cloneData.sort( ( a , b ) => {
                const x = ( a[this.sortedBy] ? a[this.sortedBy] : '' );
                const y = ( b[this.sortedBy] ? b[this.sortedBy] : '' );
                return ( isReverse * ( ( x > y ) - ( y > x ) ) );
            });
            this.acrDetailsData = cloneData;
        }
    }

    handleViewAll() { 
       this.isViewAll = true;
    }

    handleRefresh() {
        this.getACRDataDetails();
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

    handleLastUpdatedInterval() {
        this.currentTimestamp = new Date();
        if ( !this.intervalId ) {
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

      get displayDataList() {
        let response = this.acrDetailsData;
        if ( !this.isViewAll && this.acrDetailsData ) {
            response = this.acrDetailsData.filter( rec => rec.isPrimary );
        }
        if ( !response || ( response.length === 0 ) ) {
            response = this.acrDetailsData;
        }
        return response;
    }
}
//