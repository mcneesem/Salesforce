import { LightningElement, api,wire } from 'lwc';
import wizardsubmitmsg from '@salesforce/label/c.NSP_WizardSubmitMsg';
export default class Nsp_separationWizardPageFive extends LightningElement {

    @api reReqId ; 
    isPrevClick=false;
    isSaveClick=false;
    isDialogVisible = false;
    isOnloaded  = true;
    /** ={ fields : null , form : null } */
    originalMessage ;
    pageNumber = 5;
    recordTypeId = '012000000000000AAA';
    originalMessage ;
    customLabel ={
        wizardsubmitmsg,
    };
    fileCounts =0;
    filesize = 0;
    get attachmentMsg(){
        return  this.fileCounts >0 ?'Check each document below to verify it is attached':
         'There are no required documents for this agreement, but if you have anything that needs to be attached, add it now.';
    }
    NSP_RequestingMultipleEmployees__c=false;
    NSP_CreditApproval__c =false;
    NSP_HaveYouattachedPreparedAgreement__c=false;
    NSP_WhoResponsibleForStockEquityPaymt__c=false;
    NSP_ReferenceTospecificClientDocument__c=false;
    NSP_Attached_Approval_Email__c=false;
    NSP_Mid_Market_or_Mid_Market_Enterprise__c = false;

    currentPageFields=[
        "NSP_RequestingMultipleEmployees__c",
        "NSP_CreditApproval__c",
        "NSP_HaveYouattachedPreparedAgreement__c",
        "NSP_Attached_Approval_Email__c",
        "NSP_WhoResponsibleForStockEquityPaymt__c",
        "NSP_ReferenceTospecificClientDocument__c" ];


    handleSuccess(event) {
        if(!this.isPrevClick && !this.isSaveClick){

            let fieldsData = JSON.parse(JSON.stringify(event.detail.fields));
            fieldsData = { ...this.fieldsData, Id : event.detail.id };

            this.dispatchEvent(new CustomEvent('next', {detail: fieldsData}));
            }
            else if(this.isSaveClick){
                const saveEvent = new CustomEvent('saveexit', { bubbles: true });
                this.dispatchEvent(saveEvent);
            }
    }

    handleChange(event){
        if( event.currentTarget != null && event.currentTarget.name !=null) {
      }
    }
    findFileSize(event){
        if( event.detail != null && event.detail.length != null){
            this.filesize = event.detail.length;
        }

        if(this.fileCounts <= this.filesize ){
            this.template.querySelector("div.AttachmentVerify").style.display ='none';
        }

    }

    handleOnload(event){
        if(event.detail != null &&  event.detail.records != null){
            this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
            this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
            if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){
                if(this.isOnloaded){
                this.NSP_Mid_Market_or_Mid_Market_Enterprise__c = this.fieldsData.NSP_Mid_Market_or_Mid_Market_Enterprise__c?.value =='Yes' ? true : false;
                    if(!this.NSP_Mid_Market_or_Mid_Market_Enterprise__c){
                        this.fieldsData.NSP_Attached_Approval_Email__c = 'No';
                    }
                this.NSP_RequestingMultipleEmployees__c = (this.fieldsData.NSP_RequestingMultipleEmployees__c != null && this.fieldsData.NSP_RequestingMultipleEmployees__c.value  == 'Yes' ) ?( this.fileCounts ++ ,true ): false ;
                this.NSP_CreditApproval__c = this.fieldsData.NSP_CreditApproval__c != null && this.fieldsData.NSP_CreditApproval__c.value == "Approval Obtained" ? ( this.fileCounts++ ,true )  : false ;
                this.NSP_HaveYouattachedPreparedAgreement__c = this.fieldsData.NSP_HaveYouattachedPreparedAgreement__c?.value =='Yes' ? ( this.fileCounts++ ,true ) : false;
                this.NSP_Attached_Approval_Email__c = this.fieldsData.NSP_Attached_Approval_Email__c?.value =='Yes' ? ( this.fileCounts++ ,true ) : false;
                this.NSP_WhoResponsibleForStockEquityPaymt__c = this.fieldsData.NSP_WhoResponsibleForStockEquityPaymt__c != null && this.fieldsData.NSP_WhoResponsibleForStockEquityPaymt__c.value =='Client' ? ( this.fileCounts++ ,true ) : 
                this.fieldsData.NSP_ReviewType__c?.value == 'HRS Review' &&  this.fieldsData.NSP_AnyProvisionInPreparedDocRefersStock__c?.value=='Yes'?( this.fileCounts++ ,true ):false ;
                this.NSP_ReferenceTospecificClientDocument__c = this.fieldsData.NSP_ReferenceTospecificClientDocument__c != null && this.fieldsData.NSP_ReferenceTospecificClientDocument__c.value ? ( this.fileCounts++ ,true ):
                this.fieldsData.NSP_AnyPreparedDocumentForTermination__c?.value =='Yes' ? ( this.fileCounts++ ,true ) : false ; 
               
                this.currentPageFields.forEach(key =>{
                    if( this.fieldsData[key]!= null && this.fieldsData[key].value !=null){
                    }
                });
                
                this.isOnloaded = false;
            }
                
           }
       }
    }


    handleSubmit(event){



        if(!this.isSaveClick){
        
        

        event.preventDefault(); // it will prevent the submit
        if(  this.fileCounts <= this.filesize ){
        if(event.target.name === undefined ){
            this.originalMessage = event.detail.fields;
           // this.originalMessage.form =   this.template.querySelector('lightning-record-edit-form');
            this.isDialogVisible = true;
        }
         if(event.target.name === 'confirmModal'){
                //when user clicks outside of the dialog area, the event is dispatched with detail value  as 1
                if(event.detail !== 1){
                    //gets the detail message published by the child component    
                    //you can do some custom logic here based on your scenario
                    if(event.detail.status === 'confirm') {
                        const fields = event.detail.originalMessage
                        this.isDialogVisible = false;
                     //   let submitform = event.detail.originalMessage.form
                       // submitform.submit(fields); 
                       this.template.querySelector('lightning-record-edit-form').submit(fields); // it will submit the form

                        //do something
                    }else if(event.detail.status === 'cancel'){
                        //do something else
                    }
                }
    
                //hides the component
                this.isDialogVisible = false;
            }
         }
        if( this.filesize < this.fileCounts ){
            this.template.querySelector("div.AttachmentVerify").style.display ='';
        }
        }
      }
    
  handleSave(event) {
        this.isSaveClick=true;
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    handlePrev(event){
        this.isPrevClick=true;
        this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));
    }



}