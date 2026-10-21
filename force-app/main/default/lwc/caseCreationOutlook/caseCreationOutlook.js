import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import HAS_PERMISSION from '@salesforce/customPermission/Case_Creation_Outlook';

export default class CaseCreationOutlook extends NavigationMixin(LightningElement) {
    isFlowVisible = false;

    flowInputVariables = [
        { name: 'isOutlook', type: 'Boolean', value: true }
    ];

    get hasPermission() {
        return HAS_PERMISSION === true;
    }

    handleClickNew() {
        this.isFlowVisible = true;
    }

    handleCancelFlow() {
        this.isFlowVisible = false;
    }

    handleStatusChange({ detail }) {
        const { status, outputVariables } = detail;
        if (['FINISHED', 'FINISHED_SCREEN'].includes(status)) {
            const caseRecordVar = outputVariables?.find(v => v.name === 'caseRecordId');
            const createdCaseId = caseRecordVar?.value;
            if (createdCaseId) {
                this.isFlowVisible = false;
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: createdCaseId,
                        actionName: 'view'
                    }
                });
            } else {
                this.isFlowVisible = false;
            }
        }
    }
}
