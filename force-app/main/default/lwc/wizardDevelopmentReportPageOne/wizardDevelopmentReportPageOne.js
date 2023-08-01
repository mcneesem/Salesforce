import { LightningElement, wire, api, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import INTERNAL_CLEINT from '@salesforce/schema/NSP_ReportRequest__c.NSP_InternalClientReport__c';
import EXISTING_MEWRPORT from '@salesforce/schema/NSP_ReportRequest__c.NSP_Existing_NewReport__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import internalAccountId from '@salesforce/apex/NSP_ReportRequestWizardController.getInternalAccountId';
export default class WizardDevelopmentReportPageOne extends LightningElement {
  @api reReqId;
  @api recordObj;
  recordTypeId;
   allowNext=true;
   //enableClient=false;
   isEnablePrev=false;
   @track internalClientReport;
   @track existingNewReport;
   @track clientId
   internalAccId ;
   error;
   pageNumber = 1;
   fieldsData ;
   reportName;
   createDate;
   isOnloaded = true;

handleOnload(event){
  if(event.detail.records != null){
    this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
    this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
    if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){
      if(this.fieldsData.NSP_InternalClientReport__c != null  && this.fieldsData.NSP_InternalClientReport__c.value != null){
        this.internalClientReport = this.fieldsData.NSP_InternalClientReport__c.value;
        if(this.internalClientReport ==='Client Report' ){
          if( this.fieldsData.NSP_ClientName__c != null && this.fieldsData.NSP_ClientName__c.value != null){
            this.clientId = this.fieldsData.NSP_ClientName__c.value;
            }
            this.template.querySelector("div.clientDiv").style.display='';
          }     
          else if(this.internalClientReport ==='Internal Report'){
         this.clientId = this.internalAccId;
          this.template.querySelector("div.clientDiv").style.display='none';
        }
      }
      
      if(this.fieldsData.NSP_Existing_NewReport__c != null && this.fieldsData.NSP_Existing_NewReport__c.value != null){
          this.existingNewReport = this.fieldsData.NSP_Existing_NewReport__c.value;
      }

      if(this.fieldsData.Name != null && this.fieldsData.Name.value != null && !this.fieldsData.Name.value.startsWith('a7Y1')){
          this.reportName =this.fieldsData.Name.value;
        }
      }
    }
    if(this.reportName == null ){
      
      this.reportName = this.existingNewReport != null? this.existingNewReport +'-'+ this.createDate: 'Report Created On '+ this.createDate;
    }else if(this.reportName.startsWith('a7Y1') || this.reportName.startsWith('Report Created')
     ||  this.reportName.startsWith('Change to')|| this.reportName.startsWith('New Report') ){
       if(this.existingNewReport != null){
        this.reportName =    this.existingNewReport +'-'+ this.createDate;
       }
      
    }
    if(this.isOnloaded && this.template.querySelector("div.clientDiv")!= null &&
      this.recordObj != null && this.recordObj.NSP_ClientName__c != null && this.clientId == null && this.recordObj.NSP_ClientName__c.value != null){
        this.clientId =  this.recordObj.NSP_ClientName__c.value ;
        this.template.querySelector("div.clientDiv").style.display=''; 
        this.internalClientReport ='Client Report' ;
      this.isOnloaded = false;
    }   
}

connectedCallback()
{
  let today = new Date().toUTCString();  
  this.createDate = today.substring(today.indexOf(',')+2, today.indexOf(':')-2) ;
  this.getInternalAccountId();
  if(this.recordObj!= null && this.recordObj.RecordTypeId != null){
         this.recordTypeId =this.recordObj.RecordTypeId ;
  }else if( this.recordTypeId == null ||  this.recordTypeId == undefined  ) {
    this.recordTypeId = '012000000000000AAA';
  }

}

getInternalAccountId() {
  internalAccountId()
      .then((result) => {
          this.internalAccId = result;
          this.error = undefined;
      })
      .catch((error) => {
          this.error = error;
          this.relatedfile = undefined;
          this.dispatchEvent(
              new ShowToastEvent({
                  title: 'Error!!',
                  message: error.message,
                  variant: 'error',
              }),
          );
      });
}


@wire(getPicklistValues, {
  recordTypeId: '$recordTypeId' ,
  fieldApiName: INTERNAL_CLEINT
})
internalClientValues;

@wire(getPicklistValues, {
  recordTypeId: '$recordTypeId' ,
  fieldApiName: EXISTING_MEWRPORT
})
existingNewReportValues;

handleSuccess(event) {
  if(this.allowNext){
    let recordField = JSON.parse(JSON.stringify(event.detail.fields)) ;
    recordField.Id=event.detail.id;
    this.dispatchEvent(new CustomEvent('next', {detail:recordField }));
  }
}

handleSubmit(event){
  }

  handlePrev(event){
    const reReqId = event.detail.id;
    this.dispatchEvent(new CustomEvent('prev', {detail: reReqId}));
  }

  handleChange(event){
      if(event.currentTarget.name == 'NSP_InternalClientReport__c'){
            this.internalClientReport = event.currentTarget.value;
            if(this.internalClientReport ==='Client Report' ){
              this.clientId = null;
              this.template.querySelector("div.clientDiv").style.display='';
              
          }
          else if(this.internalClientReport ==='Internal Report' ){
            this.template.querySelector("div.clientDiv").style.display='none';
            this.clientId= this.internalAccId;
          }
        } 

       if(event.currentTarget.name == 'NSP_Existing_NewReport__c') {
        this.existingNewReport = event.currentTarget.value;
        
        this.reportName =    this.existingNewReport +'-'+ this.createDate;
        }
    }

    handleSave(event) {
      this.allowNext=false;
      this.pageNumber = 1;
      this.template.querySelector('lightning-record-edit-form').submit();
      const saveEvent = new CustomEvent('saveexit', {
          bubbles: true
      });
      this.dispatchEvent(saveEvent);
  }

  handleClear(){
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
    }

}