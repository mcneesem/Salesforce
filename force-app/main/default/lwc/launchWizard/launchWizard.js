import { LightningElement,api,wire } from 'lwc';
import selectWizard from '@salesforce/label/c.NSP_SelectWizard';
import REPORT_REQUEST_OBJECT from '@salesforce/schema/NSP_ReportRequest__c';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
export default class MiscModal extends LightningElement {
    @api recordTypes;
    repReqObj;
    content = 'The modal content';

    get header() {
        let returnValue = 'Edit Wizard';
        if (this.wizardName.includes('Development')) {
            returnValue =  'Request a WebFocus or Wire Report';
        } else if (this.wizardName.includes('Survey')) {
            returnValue =  'HR Survey Request';
        } else if (this.wizardName.includes('Separation')) {
            returnValue =  'Separation Agreement Request';
        } else if (this.wizardName.includes('HRScale')) {
            returnValue = 'Request an HRScale Report';
        }

        return returnValue;
    }

    customLabel ={
        selectWizard
    }
    wizardName =''



    get showDevelopReport(){
        return  this.wizardName.includes('Development Report') || this.wizardName.includes('HRScale');
    }
    get showSurvey(){
        return  this.wizardName.includes('Survey');
    }
    get showSeperation(){
        return  this.wizardName.includes('Separation');
    }


    get recordTypeArray(){
        if(this.recordTypes!= null){
            let recordTypeList =[];
            Object.values(this.recordTypes).forEach((eachValues) => {
                if(eachValues.name !== 'Master' && eachValues.available){
                    recordTypeList.push({ label: eachValues.name, value : eachValues.recordTypeId});
                }
             });
           return   recordTypeList;
        } else{
            return null;
        }
    }
    @wire(getObjectInfo, { objectApiName: REPORT_REQUEST_OBJECT })
    objectInfo;

    handleChange(event){
        if(event.currentTarget.value!=null){
            this.repReqObj= { RecordTypeId : event.currentTarget.value };
            // determine record type.  If summary, change which modal components are shown
            const repReqRecId = this.repReqObj.RecordTypeId;
            const rtis = this.objectInfo.data.recordTypeInfos;
            this.wizardName = rtis[repReqRecId].name;
        }
    }

    handleHeaderChange(event) {
        this.header = event.target.value;
    }

    handleContentChange(event) {
        this.content = event.target.value;
    }

    handleShowModal() {
       if(this.repReqObj !=null && typeof this.repReqObj == 'object'){
        const modal = this.template.querySelector('c-modal');
        modal.show();
        }
        else{
            alert('Please select a Wizard');
        }
    }

    handleCancelModal() {
        const modal = this.template.querySelector('c-modal');
        modal.hide();
    }

    handleCloseModal() {
       // alert('this from Modal');
        const modal = this.template.querySelector('c-modal');
        modal.hide();
    }

}
