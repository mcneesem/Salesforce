import { LightningElement,api,wire,track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ADDITIONAL_LANGUAGE from '@salesforce/label/c.Additional_language_options';
import ANONYMOUS_CONFIDENTIAL from '@salesforce/label/c.Is_this_survey_anonymous_or_confidential';
import PAID_WEES from '@salesforce/label/c.Non_Insperity_paid_WSEEs';

export default class WizardSurveyConsiderations extends LightningElement {
    @api reReqId;
    allowNext=true;
    showLanguages = false;
    showWsees = false;
    isSaveClick =false;
    @track visibility ={};
    errorMsg;
    showField = false;
    pageNumber = 4;
    label = {
        additionalLanguage: ADDITIONAL_LANGUAGE,
        anonymousConfidential: ANONYMOUS_CONFIDENTIAL,
        paidWsees: PAID_WEES
    };

    handlePrev(){
        this.isPrevClick=true;
        if(this.reReqId != null){
            this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));
        }
      }

    handleSuccess(event) {
        if(this.allowNext){
            this.reReqId = event.detail.id;
            if(this.reReqId != null){
                this.dispatchEvent(new CustomEvent('next', {detail: this.reReqId }));
            }
          } else if(this.isSaveClick){
            const saveEvent = new CustomEvent('saveexit', { bubbles: true });
            this.dispatchEvent(saveEvent);
          }
    }

    @wire(getRecord, { recordId: '$reReqId', fields: '$fields' })
        account({ error, data }) {
            if (data) {
    
                this.updateFieldVisibility(data.fields);
                this.errorMsg = undefined;
            } else {
                this.errorMsg = error;
            }
        }

    updateFieldVisibility(fields) {
    if (fields) {
        Object.keys(fields).forEach(fieldName => {
            const { value } = fields[fieldName];
            if (value == 'Yes') {
                this.visibility[fieldName] = true;
            }
        });
        }
    }
    
    additionalLanguage(event){
        const language = event.detail.value;
        if(language != null && language === 'Yes'){
            this.visibility['Are_additional_language_options_required__c'] = true;
        } else {
            this.visibility['Are_additional_language_options_required__c'] = false;
        }
    }

    paidWsees(event){
        const wsees = event.detail.value;
        if(wsees != null && wsees === 'Yes'){
            this.visibility['Sent_to_any_non_Insperity_paid_WSEEs__c'] = true;
        } else {
            this.visibility['Sent_to_any_non_Insperity_paid_WSEEs__c'] = false;
            
        }
    }

    handleSave() {
        this.isSaveClick=true;
        this.allowNext =false;
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    handleSubmit(event){
        const fields = event.detail.fields;    
        
        if(fields != null) {
            this.template.querySelector('lightning-record-edit-form').submit(fields);
        }
    }

    
    handleOnload(event) {
        let record = event.detail.records;
        if (record) {
            let fields = record[this.reReqId]?.fields;
            if (fields) {
                this.updateFieldVisibility(fields);
            }
        }
    }


    handleError(){
        alert('in error');
    }
}