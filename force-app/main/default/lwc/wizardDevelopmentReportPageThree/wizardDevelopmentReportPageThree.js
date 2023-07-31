import { LightningElement, api,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import REPORT_SORT from '@salesforce/schema/NSP_ReportRequest__c.NSP_IsReportSeparatedbytheFirstSort__c'
import OUTPUT_FORMAT from '@salesforce/schema/NSP_ReportRequest__c.NSP_OutputFormatToProduced__c';
export default class WizardDevelopmentReportPageThree extends LightningElement {
    @api reReqId;
    isPrevClick=false;
    isSaveClick=false;
    otherFormat=false;
    enable_HowIsReportUsed =true;
    pageNumber = 3;
    
    recordTypeId = '012000000000000AAA';
    selectedOutputFormat = null;
    selectedReportSepartedSort = null;

    handleSuccess(event) {
        if(!this.isPrevClick && !this.isSaveClick){
            let fieldsData = JSON.parse(JSON.stringify(event.detail.fields));
            fieldsData = { ...this.fieldsData, Id : event.detail.id };

            this.dispatchEvent(new CustomEvent('next', {detail: fieldsData}));
            }
            else if(this.isPrevClick )
            {

            }else if(this.isSaveClick){
                const saveEvent = new CustomEvent('saveexit', {
                    bubbles: true
                });
                this.dispatchEvent(saveEvent);
            }
    }

    handleOnload(event){
      
        /**
            if(this.template.querySelector('lightning-input-field') != null ){
            if(this.template.querySelector('lightning-input-field[data-fname="OtherOutputFormat"]') != null &&
            this.template.querySelector('lightning-input-field[data-fname="OtherOutputFormat"]').value != null){
                if(this.template.querySelector('lightning-input-field[data-fname="OtherOutputFormat"]').value == 'Other'){
                    this.otherFormat = true;
                }else{
                    this.otherFormat = false;
                }
            }
        }
         */

        if(event.detail.records != null){
            this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
            this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
            if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){
                if(this.fieldsData.NSP_IsReportSeparatedbytheFirstSort__c != null  && this.fieldsData.NSP_IsReportSeparatedbytheFirstSort__c.value != null
                    && this.selectedReportSepartedSort == null){
                    this.selectedReportSepartedSort =  this.fieldsData.NSP_IsReportSeparatedbytheFirstSort__c.value; 
                }
                if(this.fieldsData.NSP_OutputFormatToProduced__c != null  && this.fieldsData.NSP_OutputFormatToProduced__c.value != null
                    && this.selectedOutputFormat == null){
                    this.selectedOutputFormat =  this.fieldsData.NSP_OutputFormatToProduced__c.value; 
                    this.otherFormat = (this.selectedOutputFormat ==='Other' );
                }
                if(this.fieldsData.NSP_Existing_NewReport__c?.value?.startsWith('Change to') ){
                    
                        this.enable_HowIsReportUsed = false;
                    
                }
          }
      } 
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId' ,
        fieldApiName: REPORT_SORT
      })
      reportSepartedSortOption;

      @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId' ,
        fieldApiName: OUTPUT_FORMAT
      })
      outputFormatOption;


    handleSubmit(event){
        if(!this.isSaveClick){
            event.preventDefault(); // it will prevent the submit
            const fields = event.detail.fields;        
            this.template.querySelector('lightning-record-edit-form').submit(fields); 
        }
    }


    handleSave(event) {
        this.pageNumber = 2;
        this.isSaveClick=true;
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    handlePrev(event){
        this.isPrevClick=true;

        this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));
      }

      handleChange(event){
        if( event.currentTarget != null && event.currentTarget.name !=null) {
            if(event.currentTarget.name == "reportSepartedSort" ){
                this.selectedReportSepartedSort =  event.currentTarget.value;
            }
        
            if( event.currentTarget.name == "outputformat" ){
                this.selectedOutputFormat = event.currentTarget.value;
                this.otherFormat  = (event.currentTarget.value === 'Other');
            }
      }
    }
        
}