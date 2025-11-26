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
    coulums =[{label: 'Name', fieldName: 'contactName', type: 'text', minColumnWidth:150},
        {label: 'Account', fieldName: 'accountName', type: 'text',  minColumnWidth:150},
        {label: 'Work Phone', fieldName: 'workPhone', type: 'text',  minColumnWidth:150},
        {label: 'Work Email', fieldName: 'workEmail', type: 'email',  minColumnWidth:150},
        {label: 'Job Title', fieldName: 'jobTitle', type: 'text',  minColumnWidth:150},
        {label: 'Status', fieldName: 'status', type: 'text',  minColumnWidth:150},
        {label: 'Workday Employee Id', fieldName: 'workdayEmployeeId', type: 'text', minColumnWidth:180}
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

}