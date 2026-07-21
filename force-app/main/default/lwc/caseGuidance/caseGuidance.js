import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from "@salesforce/apex";
import { getRecord } from "lightning/uiRecordApi";
import getCaseGuidance from '@salesforce/apex/CaseGuidanceController.getCaseGuidance';
import getCaseGuidanceSetting from '@salesforce/apex/CaseGuidanceController.getCaseGuidanceSetting';

const FIELDS = [
    'Case.NSP_Category__c' ,
    'Case.NSP_SubCategory__c' ,
    'Case.NSP_Detail__c'
];

export default class CaseGuidance extends LightningElement {
    @api recordId;
    guidance = '';
    showCaseGuidance = false;
    activeSections = 'caseGuidance';
    caseGuidanceCustomSettingData;
    wiredCaseGuidance;

    @wire( getRecord , { recordId : '$recordId' , fields : FIELDS } )
    wiredRecord( { error, data } ) {
        if ( data ) {
            refreshApex( this.wiredCaseGuidance );
        } else if ( error ) {
            this.error = error;
            this.showCaseGuidance = false;
            this.guidance = '';
        }
    }

    @wire( getCaseGuidanceSetting , {} )
    getCaseGuidanceSetting( { data , error } ) {
        if ( data ) {
            this.caseGuidanceCustomSettingData = data;
        } else if ( error ) {
            this.error = error;
        }
    }

    handleSectionToggle( event ) {
        if ( this.caseGuidanceCustomSettingData.IsEnabledActiveSections__c ) {
            const openSections = event.detail.openSections;
            this.activeSections = ( ( openSections.length > 0 ) ? openSections : '' );
        } else {
            this.activeSections = '';
        }
    }

    @wire( getCaseGuidance , { caseId: '$recordId' } )
    doGetGuidance( value ) {
        if (value != this.wiredCaseGuidance) {
            this.wiredCaseGuidance = value;
            if ( this.wiredCaseGuidance.data
                && ( this.wiredCaseGuidance.data.length > 0 )
                )
            {
                this.showCaseGuidance = true;
                this.guidance = this.wiredCaseGuidance.data;
            } else if ( this.wiredCaseGuidance.error ) {
                this.error = this.wiredCaseGuidance.error;
            } else {
                this.showCaseGuidance = false;
                this.guidance = "";
            }
        } else {
            this.showCaseGuidance = false;
            this.guidance = "";
        }
    }
}
