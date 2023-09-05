import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {
    updateRecord,
    createRecord
} from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import CASE_LOOKUP from '@salesforce/schema/NSP_ReportRequest__c.NSP_Case__c';
import ID_FIELD from '@salesforce/schema/NSP_ReportRequest__c.Id';
import IS_DRAFT from '@salesforce/schema/NSP_ReportRequest__c.NSP_IsDraft__c';
import SUBMITEDDATE from '@salesforce/schema/NSP_ReportRequest__c.NSP_Date_Requested__c';
import getQueueID from '@salesforce/apex/NSP_ReportRequestWizardController.getQueueByName';
import getWoAssetId from '@salesforce/apex/NSP_ReportRequestWizardController.getAccountWoAsset';
import CASE_OBJ from "@salesforce/schema/Case";
import { LABEL } from './constants';
export default class WizardCaseCreation extends NavigationMixin(LightningElement)  {
 @api reReqObj;
 @api recordInput;
  error;
  woasset = '';
  fieldsData ;
  recordTypeID = '012000000000000AAA';


  
defultRecordInputCreation(queueID){
    const fields = {
        Subject:'',
        RecordTypeId : this.recordTypeID,
        OwnerId : queueID,
        NSP_Category__c:'',
        NSP_SubCategory__c:'',
        Status:'',
        NSP_Case_Sub_Status__c:'',
        Origin:'',
        AssetId: '',
    };
return { apiName: CASE_OBJ.objectApiName, fields };
}

separationQueueName ='HR Separation Agreement Team';
getQueueIdbyName( queueName ) {
    getQueueID({ queueLabel : queueName })
        .then((result) => {
            let recordInput = this.defultRecordInputCreation(result);
            this.createCaseRecord(recordInput);
            this.error = undefined;
        })
        .catch((error) => {
            this.error = error;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: error.message,
                    variant: 'error',
                }),
            );
        });
}



@wire(getObjectInfo, { objectApiName: CASE_OBJ })
    wireObjectInfo(result){
        if (result.data) {
            if (result.data.recordTypeInfos) {
              const rtis = result.data.recordTypeInfos;
              let peoRecordtype = Object.values(rtis).filter(each => each.name == 'PEO');
              if(peoRecordtype != null && peoRecordtype.length >0 && peoRecordtype[0].recordTypeId != null ){
                    this.recordTypeID = peoRecordtype[0].recordTypeId
                    if(this.recordInput != null){
                        const caseRecord = JSON.parse(JSON.stringify(this.recordInput));
                        this.createCaseRecord(caseRecord);
                      }
                      else if( this.reReqObj != null &&  this.reReqObj.NSP_AgreementType__c != null && this.reReqObj.NSP_AgreementType__c.value != null 
                            && this.reReqObj.NSP_AgreementType__c.value  != '') {
                                this.getQueueIdbyName(this.separationQueueName);
                      }else if( this.reReqObj != null &&  this.reReqObj.NSP_Survey_Type__c != null && this.reReqObj.NSP_Survey_Type__c.value != null 
                            && this.reReqObj.NSP_Survey_Type__c.value  != '') {
                                this.getQueueIdbyName('HR COE Survey Team');
                     }else{
                         this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error!!',
                                message:'Required Data is missing to create case record on  WizardCaseCreation.JS File',
                                variant: 'error',
                            }),
                        );
                        this.hideSpinner();
                        this.reloadMainPage();

                     }
                }
            }
          }
          else if (result.error) {
            this.error = result.error;
          }
   }

connectedCallback(){

}

async createCaseRecord(inputData){
    
    await this.handleRetrieveWoassetId(this.reReqObj.NSP_ClientName__c.value); 
    if(inputData != null && this.reReqObj != null ){
    let today = new Date();  
    let subject = today.toISOString();

    const { wizardReportSubcategory, wizardReportCategory,wizardSeparationCategory, wizardSeparationSubcategory} = LABEL;
    const { fields } = inputData;
    if(this.reReqObj.NSP_ReportName__c !=null && this.reReqObj.NSP_ReportName__c.value !=null){
        subject = this.reReqObj.NSP_ReportName__c.value;
        fields.NSP_SubCategory__c=wizardReportSubcategory;
        fields.NSP_Category__c=wizardReportCategory;
    }
    if( this.reReqObj.NSP_ReportName__c != null && this.reReqObj.NSP_Existing_NewReport__c != null && this.reReqObj.NSP_ReportLocation__c != null &&
         this.reReqObj.NSP_ReportLocation__c.value != null &&  this.reReqObj.NSP_ReportLocation__c.value == 'Premier Reporting (WIRE)' && this.reReqObj.NSP_Existing_NewReport__c.value != null){
                subject =  this.reReqObj.NSP_Existing_NewReport__c.value == 'New Report' ? 'WRN '+this.reReqObj.NSP_ReportName__c.value :
                this.reReqObj.NSP_Existing_NewReport__c.value == 'Change to Existing Report' ? 'WRU '+ this.reReqObj.NSP_ReportName__c.value : this.reReqObj.NSP_ReportName__c;
                fields.NSP_SubCategory__c=wizardReportSubcategory;
                fields.NSP_Category__c=wizardReportCategory;
    }
    else 
    if( this.reReqObj.NSP_AgreementType__c != null && this.reReqObj.NSP_ReviewType__c != null &&
         (this.reReqObj.NSP_AgreementType__c.value != null || this.reReqObj.NSP_ReviewType__c.value !=null) ){
            fields.NSP_SubCategory__c=wizardSeparationSubcategory;
            fields.NSP_Category__c=wizardSeparationCategory;
        if(this.reReqObj.NSP_AgreementType__c.value != null){
            subject = this.reReqObj.NSP_AgreementType__c.value ;
        }
        if( this.reReqObj.NSP_ReviewType__c.value !=null){
            subject = subject +' - '+ this.reReqObj.NSP_ReviewType__c.value ;
        }
        if(this.reReqObj.NSP_RequestingMultipleEmployees__c != null && this.reReqObj.NSP_RequestingMultipleEmployees__c.value !=null){
            subject = this.reReqObj.NSP_RequestingMultipleEmployees__c.value == 'Yes' ? subject +' - '+ 'Requested for Multiple Employee' :subject ;
        }

    } else if(this.reReqObj.NSP_Survey_Type__c != null && this.reReqObj.NSP_Survey_Type__c.value != null && this.reReqObj.NSP_Survey_Type__c.value  != '') {
        fields.NSP_Category__c='HR Client Support';
        if(this.reReqObj.NSP_Survey_Type__c.value =='Exit'){
            fields.NSP_SubCategory__c  ='Exit Interview';
        }else{
            fields.NSP_SubCategory__c  ='Employee Surveys';
        }
        subject = this.reReqObj.NSP_Survey_Type__c.value +' Survey Request';
    }
    // updated for user story - 206842
    if( this.reReqObj != null &&  this.reReqObj.NSP_AgreementType__c != null && this.reReqObj.NSP_AgreementType__c.value != null 
        && this.reReqObj.NSP_AgreementType__c.value  != '') {
            fields.NSP_Confidential__c = true;   
     }

    fields.Subject = subject;
    fields.Status ='Open';
    fields.NSP_Case_Sub_Status__c='Unassigned';
    fields.Origin='Other';
    fields.RecordTypeId = this.recordTypeID;
    fields.AccountId = this.reReqObj.NSP_ClientName__c.value;
    fields.AssetId = this.woasset != '' ? this.woasset : '';
    // recordInput.fields.OwnerId= this.reportDevelopmentQueueID;

    createRecord(inputData)
        .then(result => {
          this.updateReportRequest(result);
    })
    .catch(error => {
        this.error = error;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error creating record',
                message: error.body.message,
                variant: 'error'
            })
        );
        this.hideSpinner();
    });
 }
 else {
    this.hideSpinner();
 }

}


updateReportRequest(result) {
        // Create the recordInput object        
        let today = new Date();
        const fields = {};
        fields[SUBMITEDDATE.fieldApiName]= today.toISOString();
        fields[ID_FIELD.fieldApiName] = this.reReqObj.Id;
        fields[CASE_LOOKUP.fieldApiName] = result.id;
        fields[IS_DRAFT.fieldApiName] = false;
        if(result?.fields?.CaseNumber?.value && result?.fields?.Subject?.value){
            if(result.fields.Subject.value.includes('Survey')){
                fields['Name']='Case Number: '+ result.fields.CaseNumber.value;
            }
        }
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                    this.hideSpinner();
                      this[NavigationMixin.GenerateUrl]({
                          type: 'standard__recordPage',
                          attributes: {
                              recordId: result.id,
                              actionName: 'view'
                          }
                       }).then(url => {
                        var baseurl= window.location.origin;
                        var vurl= baseurl+url;
                          window.open(vurl);

                     });
                       this.reloadMainPage();
                // Display fresh data in the form
            })
            .catch(error => {
                this.hideSpinner();
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
}


hideSpinner(){
    if( this.template.querySelector("[data-id=spinner]")!=null){
        this.template.querySelector("[data-id=spinner]").classList.add('slds-hide');
       }
}

reloadMainPage(){
    const saveEvent = new CustomEvent('saveexit', {
        bubbles: true
    });
    this.dispatchEvent(saveEvent);
}

async handleRetrieveWoassetId(accountId){
    await getWoAssetId({accountId :accountId})
		.then(result => {
			this.woasset = result;
			this.error = undefined;
		})
		.catch(error => {
			this.error = error;
			this.woasset = '';
		})
    
}


}