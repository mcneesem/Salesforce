import { LightningElement, api,wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import SACCOUNT_FIELD from "@salesforce/schema/NSP_Sub_Client__c.NSP_Account__c";
import REPORT_REQUEST_OBJ from "@salesforce/schema/NSP_ReportRequest__c";
import CACCOUNT_FIELD from "@salesforce/schema/Contact.AccountId";
import getAMISNumb from "@salesforce/apex/NSP_ReportRequestWizardController.getAIMSfromPEOasset";
import AIMSCLIENT from "@salesforce/schema/NSP_Sub_Client__c.NSP_Asset__r.NSP_Client__c";
//NSP_Client__c
export default class LaunchWizardOnSubClientContact extends LightningElement {
    @api recordId;
    @api error;
    recordObj={ RecordTypeId:'',NSP_ClientName__c:{displayValue: null, value: null}, NSP_WSEE__c :{displayValue: null, value: null} , 
    NSP_Client_Number__c :{displayValue: null, value: null} };
    isLoading = true;
    recordTypeId;
    recordData;
    get isContactObj(){
        if(this.recordId !=null && this.recordId.startsWith('003')){
            return true;
        }else{
            return false;
        }
    }

    get objField(){
        if(this.recordId.startsWith('003')){
            return [ CACCOUNT_FIELD ];
        }else{
            return [ SACCOUNT_FIELD,AIMSCLIENT ];
        }
    }

    @wire(getRecord, { recordId: '$recordId',  fields: '$objField' })
    subAccount({ error, data }) {
        if (data) {
            this.recordData = data;
            this.errorMsg = undefined;
        } else {
            this.errorMsg = error;
        }
    }

    connectedCallback(){
    }

    @wire(getObjectInfo, { objectApiName: REPORT_REQUEST_OBJ })
    objectInfo(result){
      if(result.data){
        if (result.data.recordTypeInfos) {
          let rtis = result.data.recordTypeInfos;
          Object.values(rtis).forEach((eachValues) => {
            if(eachValues.name == "Separation Request"){
              this.recordTypeId = eachValues.recordTypeId;
            }
           });
        } }
         else if (result.error) {
            this.error = result.error;
    }
  };

openWizard(event){
   this.recordObj.RecordTypeId = this.recordTypeId;
   if(this.isContactObj){
    this.recordObj.NSP_ClientName__c.value = getFieldValue(this.recordData , CACCOUNT_FIELD);
    this.recordObj.NSP_WSEE__c.value = this.recordId;
    }else{
    this.recordObj.NSP_ClientName__c.value = getFieldValue(this.recordData , SACCOUNT_FIELD);
        if(this.recordData?.fields?.NSP_Asset__r?.value?.recordTypeInfo?.name =='WO'){
            if(this.recordData?.fields?.NSP_Asset__r?.value?.fields?.NSP_Client__c?.value !=null){
                this.recordObj.NSP_Client_Number__c.value =    this.recordData.fields.NSP_Asset__r.value.fields.NSP_Client__c.value;
            }
        }
    }

    if(this.recordObj?.NSP_ClientName__c?.value != null && this.recordObj.NSP_Client_Number__c.value == null){
        getAMISNumb({ accountID : this.recordObj.NSP_ClientName__c.value})
        .then((result) =>{
            if(result!=null){
                this.recordObj.NSP_Client_Number__c.value =  result;
            }
            const modal = this.template.querySelector('c-modal');
            modal.show();   
        })
        .catch((error) =>{
            const modal = this.template.querySelector('c-modal');
            modal.show();   
        });
    }else{
        const modal = this.template.querySelector('c-modal');
        modal.show();   
    }
}

handleCloseModal() {
    const modal = this.template.querySelector('c-modal');
    modal.hide();
    // return refreshApex(this.wiredReportRequestResult); 
}

}