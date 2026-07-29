import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';


export default class RecordTypeSelector extends LightningElement {
    @api objectApiName;
    recordTypes = [];
    error;
    @api selectedRecordTypeId;

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({ data, error }) {
        if (data) {
            const rtInfos = data.recordTypeInfos ?? {};
            this.recordTypes = Object.values(rtInfos)
                .filter(rt => rt.available && !rt.master)
                .map(rt => ({ label: rt.name, value: rt.recordTypeId }));

            this.selectedRecordTypeId = data.defaultRecordTypeId
                || (this.recordTypes.length > 0 ? this.recordTypes[0].value : undefined);
            this.error = undefined;
        } else if (error) {
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
            response.errorMessage = 'Selection required.';
        }
        return response;
    }

}
