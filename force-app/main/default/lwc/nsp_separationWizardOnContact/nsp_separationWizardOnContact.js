import { LightningElement,api,wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_FIELD from "@salesforce/schema/Contact.AccountId";
import REPORT_REQUEST_OBJ from "@salesforce/schema/NSP_ReportRequest__c";
import { CloseActionScreenEvent } from 'lightning/actions';
import cssResource from '@salesforce/resourceUrl/WizardCustomHeaderStyle';
import { loadStyle } from 'lightning/platformResourceLoader';
import wizardHeader from '@salesforce/label/c.NSP_Wizard_Seperation_Subcategory';

export default class LaunchWizardOnAccount extends LightningElement {
    @api recordId;
    recordObj={ RecordTypeId:null,
      NSP_WSEE__c:{displayValue: null, value: null},
      NSP_ClientName__c:{displayValue: null, value: null}
    };
    recordTypeId;
    recordData = null;
    LABEL = {wizardHeader
    };

    @api
    get checkRequiredFields() {
      return this.recordId && this.recordTypeId;
    }
    
    @wire(getRecord, { recordId: '$recordId',  fields: ACCOUNT_FIELD })
    subAccount({ error, data }) {
        if (data) {
            this.recordData = data;
            this.errorMsg = undefined;
            this.recordObj.NSP_ClientName__c.value = getFieldValue(this.recordData , ACCOUNT_FIELD);

        } else {
            this.errorMsg = error;
        }
    }

    @wire(getObjectInfo, { objectApiName: REPORT_REQUEST_OBJ })
    getObjectInfoCallback({ data, error }){
      if(data){
        if (data.recordTypeInfos) {
          let rtis = data.recordTypeInfos;
          Object.values(rtis).forEach((recordTypeInfo) => {
              if(recordTypeInfo.name !== 'Master' && recordTypeInfo.available &&
                recordTypeInfo.name.includes("Separation")){
                this.recordTypeId = recordTypeInfo.recordTypeId;
                this.recordObj.RecordTypeId = this.recordTypeId;
              }
           });
        }
      }
      else if (error) {
        this.error = error;
        this.dispatchEvent(
              new ShowToastEvent({
                  title: 'Error!!',
                  message: error.message,
                  variant: 'error',
              }),
        );
      }
    };

    connectedCallback(){
      loadStyle(this, cssResource);
    }

    renderedCallback() {
      if(!this.recordObj.NSP_WSEE__c.value){
        this.recordObj.NSP_WSEE__c.value = this.recordId;
      }
    }
     
    handleCloseModal() {
      this.dispatchEvent(new CloseActionScreenEvent());
    }
 

 
}