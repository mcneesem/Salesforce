import { LightningElement, wire, api } from 'lwc';
import getAccessibleRecordTypes from '@salesforce/apex/RecordTypeSelectorController.getRecordTypes';

export default class RecordtypeSelectionNew extends LightningElement {
    @api objectApiName; 
    recordTypes = [];
    error;
    @api selectedRecordTypeId;
    
    @wire(getAccessibleRecordTypes, { objectApiName: '$objectApiName' })
    wiredRecordTypes({ error, data }){
        if (data){
            this.recordTypes = data.map(recordType => ({
                label: recordType.Name,
                value: recordType.Id
            }));
            
            this.error = undefined;

            if (this.recordTypes.length > 0) {
                this.selectedRecordTypeId = this.recordTypes[0].value;
            }
        }else if(error){
            this.recordTypes = [];
            this.selectedRecordTypeId = undefined;
            this.error = error;
        }
    }


    handleRecordTypeChange(event) {
        if (event && event.target && event.target.value) {
            this.selectedRecordTypeId = event.target.value;
        }
    }

    @api 
    validate() {
        const response = { isValid: !!this.selectedRecordTypeId };

        if (!response.isValid) {
            response.errorMessage = "Please select a record type.";
        }

        return response;
    }
}