import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import CASE_OBJECT from '@salesforce/schema/Case';
import ASSET_OBJECT from '@salesforce/schema/Asset';
import createProjectfromTemplate from '@salesforce/apex/NSP_CreateProjectFromTemplate.createProject';

export default class CreateProjectFromTemplate extends NavigationMixin(LightningElement)  {

    // CONST ATTRIBUTES
    label = {
        cancel: 'Cancel',
        createProject: 'Create Project',
        projectStartDate: "Start Date",
        mandatoryFieldsMessage : 'Please provide all field Values',
        heading : 'Create Project From Template',
        projectName : 'Project Name'
    }

    // PUBLIC 
    @api recordId;
    @api objectApiName;

    // PRIVATE
    isLoading = false;
    projectStartDate;

    // GETTERS
    get showCaseTemplate() {
        return (this.objectApiName === CASE_OBJECT.objectApiName ? true : false);
    }
    get showAssetTemplate() {
        return (this.objectApiName === ASSET_OBJECT.objectApiName ? true : false);
    }


    // ACTION
    createProjectAction() {
        var sub;
        this.isLoading = true;
        if (this.objectApiName === CASE_OBJECT.objectApiName) {
            if(this.template.querySelector('.subject').value != ''){
               sub =  this.template.querySelector('.subject').value;
            } 
            let oCase = {
                Subject:sub,
                Project_Template__c: this.template.querySelector('.projectTemplateId').value
            };
            
            let startDate = this.template.querySelector('.projectStartDate').value;
            if (!(oCase.Project_Template__c && startDate)) {
                this.isLoading = false;
                this.showToast('error',this.label.mandatoryFieldsMessage);
                return;
            }
            this.createProject(this.objectApiName,this.recordId,JSON.stringify(oCase),startDate);
        } else if(this.objectApiName === ASSET_OBJECT.objectApiName){
            let oAsset = {
                name : this.template.querySelector('.projectName').value,
                Project_Template__c: this.template.querySelector('.projectTemplateId').value
            };
            let startDate = this.template.querySelector('.projectStartDate').value;
            if (!(oAsset.name && oAsset.Project_Template__c && startDate)) {
                this.isLoading = false;
                this.showToast('error',this.label.mandatoryFieldsMessage);
                return;
            }
            this.createProject(this.objectApiName,this.recordId,JSON.stringify(oAsset),startDate);
        }
    }
    createProject(sobjName,recordId,objVal,startDate){
        createProjectfromTemplate({
            sobjName: sobjName,
            recordId: recordId,
            objVal: objVal,
            startDate: startDate
        }).then(response => {
            this.isLoading = false;
            if (response.status) {
                this.navigateToRecord(response.data);
            } else {
                this.showToast('error',response.errorMessage);
            }
        }).catch(error => {
            this.isLoading = false;
            this.showToast('error',error.body.message);
        });
    }
    navigateToRecord(recordId){
        if(this.objectApiName === ASSET_OBJECT.objectApiName){
            this.dispatchEvent(new CustomEvent('success', { detail : {
                id: recordId
            }}));
        }else if(this.objectApiName === CASE_OBJECT.objectApiName){
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: recordId,
                    actionName: 'view'
                }
            });
        }
    }
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    closeAssetQuickAction(){
        this.dispatchEvent(new CustomEvent('closeaction'));
    }
    showToast(type, message) {
        const event = new ShowToastEvent({
        variant: type,
        message: message,
        });
        this.dispatchEvent(event);
    }
}