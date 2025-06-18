import { LightningElement, api, wire} from 'lwc';

import getCaseGuidance from '@salesforce/apex/CaseGuidanceController.getCaseGuidance';
import getCaseGuidanceSetting from '@salesforce/apex/CaseGuidanceController.getCaseGuidanceSetting';


export default class CaseGuidance extends LightningElement {
    @api recordId;
    guidance = '';
    showCaseGuidance = false;
    activeSections = 'caseGuidance';
    caseGuidanceCustomSettingData;
    error = '';

    @wire(getCaseGuidanceSetting, {})
    getCaseGuidanceSetting({data, error}){
        if(data){
           this.caseGuidanceCustomSettingData = data;
           
        }
        else if(error){
            this.error = error;
        }
    }

    handleSectionToggle(event) {
        if(this.caseGuidanceCustomSettingData.IsEnabledActiveSections__c){
            
            const openSections = event.detail.openSections;
            this.activeSections = openSections.length > 0 ? openSections : '';
        }else{
            this.activeSections = '';
        }    
    }

    @wire(getCaseGuidance, { caseId: '$recordId' })
    doGetGuidance({ error, data }) {
        if (data) {
            if (data.length > 0) {
                this.showCaseGuidance = true;
                this.guidance = data;
            }
        }
        else if (error) {
            // send it to error pannel
            this.error = error;
        }
    }
}