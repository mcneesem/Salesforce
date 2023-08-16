import { LightningElement, api, wire } from 'lwc';
import SurveyRevisionRequestForm from '@salesforce/label/c.NSP_SurveyRevisionRequestFormPageNexus';
export default class SurveyWizard extends LightningElement {
    steps = [{ label: "Survey Information", value: "1" }, { label: "Survey Filters", value: "2" }, { label: "Custom Questions", value: "3" }, { label: "Additional Information", value: "4" }];
    @api currentStep;
    currentIndex = -1;
    showProgress = true;
    showDisclaimer = false;
    @api reReqId;
    @api repReqObj;
    get recordInputForCreate() {
        return null;
    }
    customLabel ={
        SurveyRevisionRequestForm
        };

    get step1() {
        return this.currentStep == this.steps[0].value;
    }

    get step2() {
        return this.currentStep == this.steps[1].value;
    }

    get step3() {
        return this.currentStep == this.steps[2].value;
    }

    get step4() {
        return this.currentStep == this.steps[3].value;
    }
    connectedCallback() {

        // console.log('object ' + JSON.stringify(this.repReqObj));
        // console.log('type ' + this.repReqObj.RecordTypeId);
        // console.log('conn type 2 ' + this.repReqObj.recordTypeId);
        if (this.currentStep == "-1") {
            this.showDisclaimer = true;
            this.reReqId = null;

        } else {
            this.showDisclaimer = false;
        }
        
         if(this.currentStep!= null && this.currentStep != "0" && this.currentStep != 0 && this.currentStep != -1 ){
            this.currentIndex = this.currentStep -1;
            this.currentStep = this.currentStep.toString();
        }
         

    }

    handleSummery(){
        // this.openSummery= true;
     }

    handleNext(event) {
        this.showDisclaimer = false;
            if( typeof event.detail== "object" ) {
                 this.repReqObj = JSON.parse(JSON.stringify(event.detail));
                 this.reReqId =  this.repReqObj.Id ;
             }else if ( this.repReqObj != null && typeof this.repReqObj== "object" && this.repReqObj.Id != null ){
                this.reReqId =  this.repReqObj.Id ;
             }else if (typeof event.detail == "string" && event.detail.length > 17){
                this.reReqId = event.detail;
             }
                if( this.reReqId !=null || this.currentStep == -1 ){
                    if (this.currentIndex + 1 == this.steps.length) {
                        this.showProgress = false;
                    } else {
                        this.currentIndex++;
                        this.currentStep = this.steps[this.currentIndex].value;
                    }
                }
    }

    handleStart(){

    }

    handleCancel() {
        const saveEvent = new CustomEvent('saveexit', {
            bubbles: true
        });
        this.dispatchEvent(saveEvent);
    }

    handlePrev(event) {
        this.reReqId = event.detail;
        if (this.currentIndex != 0 && this.currentIndex != -1) {
            this.currentIndex--;
            this.currentStep = this.steps[this.currentIndex].value;
        }
    }

    handleSave(event) {
        const saveEvent = new CustomEvent('saveexit', {
            bubbles: true
        });
        this.dispatchEvent(saveEvent);
    }
}