import { LightningElement, api, track, wire } from 'lwc';
import { getRecord} from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import NSP_RENEWAL_PROBABILITY from '@salesforce/schema/NSP_Account_Group__c.NSP_Renewal_Probability__c';
 
export default class PostChangeSurveyAccountGroup extends NavigationMixin(LightningElement) {
    @api recordId;
    @track showFirstModal = false;
    lastValue;
    // Wire the field NSP_Renewal_Probability__c
    @wire(getRecord, { recordId: '$recordId', fields: [NSP_RENEWAL_PROBABILITY] })
    wiredRecord({ data }) {
        if (data) {
            const currentValue = data.fields.NSP_Renewal_Probability__c.value;
            // If the field was updated (value changed), show popup
            if (this.lastValue !== undefined && this.lastValue !== currentValue && currentValue != null) {
                this.showFirstModal = true;
            }
            // Always store latest value for comparison next time
            this.lastValue = currentValue;
        }
    }
    handleYes() {
        this.showFirstModal = false;
    }
    handleNo() {
        this.showFirstModal = false;
        // Open standard New Focus Item action
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'NSP_Focus_Item__c',
                actionName: 'new'
            },
            state: {
                defaultFieldValues: `NSP_Account_Group__c=${this.recordId}`,
                navigationLocation:'RELATED_LIST'
            }
        });
    }
}