import { LightningElement,wire,api, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CREDIT_APPROVAL from '@salesforce/schema/NSP_ReportRequest__c.NSP_CreditApproval__c';
import getUserAndFinanceLevel from '@salesforce/apex/NSP_ReportRequestWizardController.getHRspecialistAndFinanceLevel';
import retrieveContactRecords from '@salesforce/apex/NSP_ReportRequestWizardController.retrieveContactRecords';
import { SYNC_FIELDS } from "./fields";
export default class nsp_separationWizardPageTwo extends LightningElement {
@api reReqId;
@api recordObj;
@api clientId = '';
@api clientAccId = '';
@track accContacts =[ { ContactId:"00",Name:"None"}];
isPrevClick=false;
isSaveClick=false;
recordTypeId = '012000000000000AAA';
error;
filesize = 0 ;
pageNumber = 2;
fieldsData
creditApprovalValue;
multipleEmployeesValue;
enableTotalAgreement =false;
enableMultipleEmployee=false;
pickValueYesNo = [
        { "attributes": null, "label": "Yes", "value": "Yes"},
        { "attributes": null, "label": "No", "value": "No" }
      ];
userID;
financeLevel;
segmentType;
isOnloaded = true;
cname='';
NSP_ClientName__c='';
clientContact='';
NSP_Client_Contact__c='';
isOnloadCalled =false;
NSP_Request_TotalAgreementsRequested_Value= '';
NSP_Request_Severance_Total_Value = '';

@wire(getPicklistValues, {
        recordTypeId: '$recordTypeId' ,
        fieldApiName: CREDIT_APPROVAL
})
creditApproval;


connectedCallback(){
}

handleOnload(event){
    this.clientAccId = this.template.querySelector('lightning-input-field[data-fname="clientName"]').value ;
    if(event.detail != null &&  event.detail.records != null){
        this.isOnloadCalled=true;
        this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
        this.clientId = this.fieldsData.NSP_ClientName__c.value;
        this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
        if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){
            if(this.fieldsData.NSP_CreditApproval__c != null  && this.fieldsData.NSP_CreditApproval__c.value != null
                && this.creditApprovalValue == null){
                    this.creditApprovalValue = this.fieldsData.NSP_CreditApproval__c.value;
            }
            
            if(this.fieldsData.NSP_AgreementType__c != null  && this.fieldsData.NSP_AgreementType__c.value != null
                && this.fieldsData.NSP_AgreementType__c.value  == 'Insperity-Prepared'){	
                this.enableMultipleEmployee = true;
            }
            if(this.fieldsData.NSP_RequestingMultipleEmployees__c != null  && this.fieldsData.NSP_RequestingMultipleEmployees__c.value != null
                && this.multipleEmployeesValue == null){
                this.multipleEmployeesValue =  this.fieldsData.NSP_RequestingMultipleEmployees__c.value;
                this.enableTotalAgreement =  (this.fieldsData.NSP_RequestingMultipleEmployees__c.value == 'Yes');
                
                if(this.fieldsData.NSP_TotalAgreementsRequested__c.value != null && this.enableTotalAgreement == true){
                    this.NSP_Request_TotalAgreementsRequested_Value = this.fieldsData.NSP_TotalAgreementsRequested__c.value;
                }
                if(this.fieldsData.NSP_Severance_Total__c.value != null && this.enableTotalAgreement == true){
                    this.NSP_Request_Severance_Total_Value = this.fieldsData.NSP_Severance_Total__c.value;
                }
            }

            if(this.isOnloaded){
            if(this.fieldsData.NSP_ClientName__c != null  && this.fieldsData.NSP_ClientName__c.value != null &&
                this.fieldsData.NSP_FinanceLevel__c != null  && this.fieldsData.NSP_FinanceLevel__c.value == null &&
                this.fieldsData.NSP_HRSpeciallist__c != null  && this.fieldsData.NSP_HRSpeciallist__c.value == null &&
                this.userID == null && this.financeLevel == null ){
                this.isOnloaded = false;
                this.handleAccountLookup(this.fieldsData.NSP_ClientName__c.value);
                this.publishSyncEvent('NSP_ClientName__c',this.fieldsData.NSP_ClientName__c.value);
               // this.enableTotalAgreement =  (this.fieldsData.NSP_RequestingMultipleEmployees__c.value == 'Yes');
            }
            //DF-03925 start
            if(this.fieldsData != null && this.fieldsData.NSP_ClientName__c != null  && 
                this.fieldsData.NSP_ClientName__c.value != null) {                    
                    this.getContactRecord(this.fieldsData.NSP_ClientName__c.value);

                    if(this.fieldsData.NSP_Client_Contact__c != null  && 
                        this.fieldsData.NSP_Client_Contact__c.value != null) {
                            this.clientContact = this.fieldsData.NSP_Client_Contact__c.value;
                            let contactLookup = this.template.querySelector('c-nsp_case-custom-look-up[data-id="contactLookup"]');
                            if(contactLookup){
                                contactLookup.getDefaultRecord(this.clientContact, 'Contact', '');
                            }
                    }  
            }
            
            //DF-03925 end
          }
       }
   }
}

handleSave(event) {
    this.isSaveClick=true;
    this.template.querySelector('lightning-record-edit-form').submit();
}

handleSuccess(event){
    if(!this.isPrevClick && !this.isSaveClick){
        const reReqId = event.detail.id;
        this.dispatchEvent(new CustomEvent('next', {detail: reReqId}));
        }
        else if(this.isSaveClick){
            const saveEvent = new CustomEvent('saveexit', { bubbles: true });
            this.dispatchEvent(saveEvent);
        }
}

handleAccountLookup(recordId) {
    if(recordId != null && recordId.length > 14  ){
    getUserAndFinanceLevel({ accountID : recordId })
        .then((result) => {
            this.userID =  result.UserId != 'Not Found'? result.UserId :'';
            this.financeLevel = result.FinanceLevel != 'Not Found' ? result.FinanceLevel :'';
            this.segmentType = result.segment != 'Not Found' ? result.segment :'';
            this.error = undefined;
        })
        .catch((error) => {
            this.error = error;
            this.reportRequest  = undefined;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: error.message,
                    variant: 'error',
                }),
            );
        });
    }
}

handleSubmit(event){
    //
    this.findeFileSize(event);
    
    if(this.filesize < 1 && this.multipleEmployeesValue !=null && this.multipleEmployeesValue == 'Yes')
    {
        event.preventDefault(); // it will prevent the submit
    }

    if(this.filesize < 1 && this.creditApprovalValue !=null && this.creditApprovalValue == 'Approval Obtained'){
        event.preventDefault(); // it will prevent the submit
    }

}

hanldeNext(event){
}


handlePrev(event){
    this.isPrevClick=true;
    const reReqId = event.detail.id;
    this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));
  }

  handleChange(event){

    if( event.currentTarget.name == "creditApproval" ){
        this.creditApprovalValue = event.currentTarget.value;

       // this.findeFileSize(event);
    }
    
    if( event.currentTarget.name == "RequestingMultipleEmployees" ){
        this.multipleEmployeesValue = event.currentTarget.value;
        this.enableTotalAgreement = (event.currentTarget.value === "Yes");
       // this.findeFileSize(event);
       if(this.enableTotalAgreement == true){
            this.refs.SeveranceTotal.style.display = '';
        }

        if(event.currentTarget.value === "No"){
            this.enableTotalAgreement = (event.currentTarget.value === "No");
            this.refs.SeveranceTotal.style.display = 'none';
            this.NSP_Request_TotalAgreementsRequested_Value = null;
            this.NSP_Request_Severance_Total_Value = null;
        }
    }

    if( event.currentTarget.fieldName == "NSP_ClientName__c" ){
        if(event.currentTarget.value != null && event.currentTarget.value.length > 14 ){
            this.clientAccId = event.currentTarget.value;
            this.handleAccountLookup(event.currentTarget.value);
            this.getContactRecord(event.currentTarget.value);
            this.publishSyncEvent(event.currentTarget.fieldName,event.currentTarget.value);
        }else{
            this.userID = '';
            this.financeLevel = '';
        }
    }

  }


  get NSP_TotalAgreementsRequested(){
    return this.multipleEmployeesValue=='Yes' ? true : false;
  }

  get NSP_Severance_Total(){
    return this.multipleEmployeesValue=='Yes' ? true : false;
  }

  publishSyncEvent(fieldName,value) {
    if(Object.values(SYNC_FIELDS).includes(fieldName)){      
      this.dispatchEvent(new CustomEvent('syncfields', { detail: { fieldName, value } }));
    }
  }

  findeFileSize(event){
        if( event.detail != null && event.detail.length != null){
            this.filesize = event.detail.length;
        }
        if(this.filesize <1){

            if((this.multipleEmployeesValue !=null && this.multipleEmployeesValue == 'Yes') && this.template.querySelector("div.NSP_RequestingMultipleEmployees__c")!= null ){
                this.template.querySelector("div.NSP_RequestingMultipleEmployees__c").style.display ='';
            }

            if((this.multipleEmployeesValue ==null || this.multipleEmployeesValue != 'Yes' ) && this.template.querySelector("div.NSP_RequestingMultipleEmployees__c")!= null ){
                this.template.querySelector("div.NSP_RequestingMultipleEmployees__c").style.display ='none';
            }

            if(this.creditApprovalValue !=null && this.creditApprovalValue == 'Approval Obtained' && this.template.querySelector("div.NSP_CreditApproval__c")!= null ){
                this.template.querySelector("div.NSP_CreditApproval__c").style.display ='';
            }

            if((this.creditApprovalValue ==null || this.creditApprovalValue != 'Approval Obtained' ) && this.template.querySelector("div.NSP_CreditApproval__c")!= null ){
                this.template.querySelector("div.NSP_CreditApproval__c").style.display ='none';
            }

        }else {

            if((this.creditApprovalValue ==null || this.creditApprovalValue != 'Approval Obtained' || this.filesize >0 ) && this.template.querySelector("div.NSP_CreditApproval__c")!= null ){
                this.template.querySelector("div.NSP_CreditApproval__c").style.display ='none';

            if((this.multipleEmployeesValue ==null || this.multipleEmployeesValue != 'Yes' || this.filesize > 0 ) && this.template.querySelector("div.NSP_RequestingMultipleEmployees__c")!= null ){
                this.template.querySelector("div.NSP_RequestingMultipleEmployees__c").style.display ='none';
            }
        }

     }
  }

  //DF-03925 start
  getContactRecord( parentId ) {
    retrieveContactRecords({ accountId : parentId })
        .then((result) => {
            if (result) {
                this.accContacts = result;
                this.errorMsg = undefined;
            }
        })
        .catch((error) => {
            this.errorMsg = error;
            this.accContacts = undefined;
        });
    }

    handlelookupRecord(event){
        let selectedRecord = event.detail.recId;
        this.NSP_Client_Contact__c=selectedRecord;
        if(this.NSP_Client_Contact__c != null && this.NSP_Client_Contact__c.length > 17){
            const conObj = this.accContacts.find(row => row.ContactId === selectedRecord);
            if(conObj != undefined){
            this.cname = conObj.Contact.name;
            }
            this.clientContact = selectedRecord;
          }else{
            this.cname = '';
            this.NSP_Client_Contact__c='';
          }    
    }
    //DF-03925 end

}