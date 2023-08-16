import { LightningElement, api,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
export default class nsp_separationWizard extends NavigationMixin(LightningElement) {
    
  //  @track currentStep = '1';
 
    steps = [{label: "Agreement Type", value: "1"}, {label: "Client Information", value: "2"}, {label: "WSEE Information", value: "3"},{label: "Agreement Information", value: "4"},{label: "Document Validation", value: "5"}];
    @api currentStep;
    currentIndex = 0;
    showProgress = true;
    @api reReqId;
    @api repReqObj;
    openSummery = false;
    syncFieldValues = {};
    get recordInputForCreate() {
        return null;
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

    get step4() {
        return this.currentStep == this.steps[3].value;
    }
    
    get step5() {
        return this.currentStep == this.steps[4].value;
    }

    handleSync({ detail }) {
        this.syncFieldValues = detail;
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
        } 
        else {
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