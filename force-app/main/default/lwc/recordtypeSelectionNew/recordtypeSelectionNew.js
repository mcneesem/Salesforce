import { LightningElement, wire, api } from 'lwc';
import getAccessibleRecordTypes from '@salesforce/apex/CreateCaseController.getRecordTypes';

export default class RecordtypeSelectionNew extends LightningElement {
    @api objectApiName = 'Case';
    recordTypes = [];
    error;
    @api selectedRecordTypeId;
    @api availableActions = [];

    // Fetch accessible record types from Apex
    @wire(getAccessibleRecordTypes, { objectApiName: '$objectApiName' })
    wiredRecordTypes({ error, data }) {
        if (data) {
            if(data.length===1){
               this.selectedRecordTypeId = data[0].Id;
               this.handleNext();
            }
            else{
            this.recordTypes = data.map(recordType=>(
                {
                 label : recordType.Name,
                 value : recordType.Id
                }
            ));
            this.error = undefined;
            }
        } else if (error) {
            this.recordTypes = [];
            this.error = error;
        }
    }

    // Handle radio button selection
    handleRecordTypeChange(event) {
        this.selectedRecordTypeId = event.target.value;
    }

    @api 
    validate(event){
        let isValid = true;
        if(this.selectedRecordTypeId===undefined || this.selectedRecordTypeId===null || this.selectedRecordTypeId===''){
            isValid = false;
        }
        if(!isValid) { 
            return {
                isValid: false,
                errorMessage: "Please select recordtype."
            }
        } 
        else{
            return {
                isValid: true,
               }       
        }
    }
} 