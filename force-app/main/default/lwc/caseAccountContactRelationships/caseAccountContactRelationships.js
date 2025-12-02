import { LightningElement, wire, api } from 'lwc';
import getACRDetails from '@salesforce/apex/CaseAccountContactRelationController.getACRDetails';
import { refreshApex } from '@salesforce/apex';
export default class CaseAccountContactRelationships extends LightningElement {
    @api recordId;
    acrDetailsData;
    acrPrimaryData;
    displayDataList;
    wireData;
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
            this.displayDataList = this.acrDetailsData.filter(rec => rec.IsPrimary);
            if(this.displayDataList == null || this.displayDataList.length == 0 ||this.displayDataList == undefined){
                this.displayDataList = this.acrDetailsData;
            }
        } else if (result.error) {
            this.acrDetailsError = result.error;
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
}