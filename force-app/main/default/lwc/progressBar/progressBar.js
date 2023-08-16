import { LightningElement,api } from 'lwc';

export default class NewProgressBar extends LightningElement {
    @api steps;
    @api currentStep;
    activeSteps;

    connectedCallback(){
        this.activeSteps = this.steps.map(obj => {
            let tempObj = { ...obj };
            tempObj.Name = 'step'+obj.value;
            return tempObj;
        });
    }


    renderedCallback(){
        var elements = this.template.querySelectorAll('.slds-is-current','.slds-is-active');
        if(elements.length >0){
            elements.forEach(elem => {
                elem.classList.remove('slds-is-current','slds-is-active');
            });
        }
        if(this.template.querySelector('[data-name="step'+this.currentStep+'"]')!=null){
        this.template.querySelector('[data-name="step'+this.currentStep+'"]').classList.add("slds-is-current","slds-is-active");
        }
    }

}