import { LightningElement, api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import CASE_OBJECT from '@salesforce/schema/Case';
import {getRecordCreateDefaults,generateRecordInputForCreate } from 'lightning/uiRecordApi';
import getQueueID from '@salesforce/apex/NSP_ReportRequestWizardController.getQueueByName';
export default class DevelopmentReportWizard extends NavigationMixin(LightningElement) {
    
  //  @track currentStep = '1';
 
    steps = [{label: "New/Change", value: "1"}, {label: "Report Name", value: "2"}, {label: "Report Information", value: "3"}];
    @api currentStep;
    currentIndex = 0;
    showProgress = true;
    @api reReqId;
    @api repReqObj;
    reportDevelopmentQueueName = "Report Development";
    openSummery = false;
    caseCreateDefaults;
    reportDevelopmentQueueID ;
    @wire(getRecordCreateDefaults, { objectApiName: CASE_OBJECT })
    wiredcases({ error, data }) {
        if (data) {
            this.caseCreateDefaults = data ;
        } else if (error) {
            this.caseCreateDefaults = undefined;
        }
    }

    get recordInputForCreate() {
        if (!this.caseCreateDefaults) {
            return undefined;
        }

        const caseObjectInfo = this.caseCreateDefaults.objectInfos[
            CASE_OBJECT.objectApiName
        ];
        const recordDefaults = this.caseCreateDefaults.record;
        const recordInput = generateRecordInputForCreate(
            recordDefaults,
            caseObjectInfo
        );
        recordInput.fields.OwnerId= this.reportDevelopmentQueueID;
        return recordInput;      
    }


    @wire(getQueueID,{queueLabel: '$reportDevelopmentQueueName'})
    wiredgetQueueByName(result) {
        if (result.data) {
            this.reportDevelopmentQueueID = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.reportDevelopmentQueueID = undefined;
        }
    }


    connectedCallback(){
        if(this.currentStep!= null & this.currentStep != "0" & this.currentStep != 0){
        this.currentIndex = this.currentStep -1;
        this.currentStep = this.currentStep.toString();
        }
    }

    get step1() {
        return this.currentStep == this.steps[0].value;
    }

    get step2() {
        return this.currentStep == this.steps[1].value;
    }

    get step3() {
        return this.currentStep == this.steps[2].value;
    }

    handleNext(event) {
        if( typeof event.detail== "object" ) {
            this.repReqObj = JSON.parse(JSON.stringify(event.detail));
            this.reReqId =  this.repReqObj.Id ;
        }else {
        this.reReqId = event.detail;
           }
        if(this.currentIndex + 1 == this.steps.length) {
        this.showProgress = false;
            /**
            console.log(this.reReqId);
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.reReqId,
                    actionName: 'view'
                }
            });
             */
        } else {
            this.currentIndex++;
            this.currentStep = this.steps[this.currentIndex].value;
        }
        
    }


    handleSummery(){
       // this.openSummery= true;
    }
 
    handlePrev(event){
        this.reReqId = event.detail;
        if(this.currentIndex != 0){
            this.currentIndex--;
            this.currentStep = this.steps[this.currentIndex].value;
        }
    }
 
    handleFinish(){
    }

    showSummaryPage(){

        
    }

    handleSave(event) {
        const saveEvent = new CustomEvent('saveexit', {
            bubbles: true
        });
        this.dispatchEvent(saveEvent);
    }

}