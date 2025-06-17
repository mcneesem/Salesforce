import { LightningElement, api, wire, track } from 'lwc';

import getCaseGuidance from '@salesforce/apex/CaseGuidanceController.getCaseGuidance';
import getCaseGuidanceSetting from '@salesforce/apex/CaseGuidanceController.getCaseGuidanceSetting';


export default class CaseGuidance extends LightningElement {
    @api recordId;
    guidance = '';
    @track showCaseGuidance = false;
    @track activeSections = 'caseGuidance';
    @track caseGuidanceCustomSettingData;

    @wire(getCaseGuidanceSetting, {})
    getCaseGuidanceSetting({data, error}){
        if(data){
           this.caseGuidanceCustomSettingData = data;
           console.log('caseGuidanceCustomSettingData', data);
           
        }
        else if(error){
            console.log('error occured', error);
        }
    }

    handleSectionToggle(event) {
        if(this.caseGuidanceCustomSettingData.Is_Enabled__c){
            
            const openSections = event.detail.openSections;
            console.log(openSections);
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
                console.log('guidance', data);
            }
        }
        else if (error) {
            console.log('error occured', error);
            // send it to error pannel
        }
    }
}