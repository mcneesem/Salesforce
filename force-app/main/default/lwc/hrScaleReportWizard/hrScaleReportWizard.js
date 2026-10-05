import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadStyle } from 'lightning/platformResourceLoader';
import REPORT_REQUEST_OBJ from '@salesforce/schema/NSP_ReportRequest__c';
import cssResource from '@salesforce/resourceUrl/WizardCustomHeaderStyle';
import wizardHeader from '@salesforce/label/c.Wizard_HR_Scale_Report_Name';

const HRSCALE_RECORD_TYPE = 'HRScale';

export default class HrScaleReportWizard extends LightningElement {
    @api recordId;

    @track recordObj = {
        RecordTypeId: null,
        NSP_ClientName__c: { displayValue: null, value: null }
    };

    recordTypeId;
    label = { wizardHeader };

    @api
    get checkRequiredFields() {
        return this.recordId && this.recordTypeId;
    }

    @wire(getObjectInfo, { objectApiName: REPORT_REQUEST_OBJ })
    getObjectInfoCallback({ data, error }) {
        if (data?.recordTypeInfos) {
            const matched = Object.values(data.recordTypeInfos).find(
                rt => rt.name !== 'Master' && rt.available && rt.name.includes(HRSCALE_RECORD_TYPE)
            );
            if (matched) {
                this.recordTypeId = matched.recordTypeId;
                this.recordObj.RecordTypeId = matched.recordTypeId;
            }
        } else if (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error?.body?.message ?? error.message,
                    variant: 'error'
                })
            );
        }
    }

    connectedCallback() {
        loadStyle(this, cssResource);
    }

    renderedCallback() {
        if (!this.recordObj.NSP_ClientName__c.value) {
            this.recordObj.NSP_ClientName__c.value = this.recordId;
        }
    }

    handleCloseModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}