import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class WizardResumePrompt extends LightningElement {
  showModal = false;
  @api show() {
    this.showModal = true;
}

@api hide() {
    this.showModal = false;
}

  handleResume(event){
    this.dispatchEvent(new CustomEvent('resume'));
    this.hide();
  }

  handleStartOver(event){
    this.dispatchEvent(new CustomEvent('startover'));
    this.hide();
  }
  
  handleCloseModal(event){
    this.hide();
  }

}