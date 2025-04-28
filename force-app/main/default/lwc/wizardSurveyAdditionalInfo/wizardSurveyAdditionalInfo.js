import { LightningElement, wire, api, track } from 'lwc';
import SurveyRevisionRequestForm from '@salesforce/label/c.NSP_SurveyRevisionRequestFormPageNexus';
import surveyRevisionHyperLink from '@salesforce/label/c.NSP_SurveyRevisionRequestFileHyperLinks';
import getHRspecialist from '@salesforce/apex/NSP_ReportRequestWizardController.getHRspecialist';
export default class wizardSurveyAdditionalInfo extends LightningElement {

   customLabel ={
    surveyRevisionHyperLink,
    SurveyRevisionRequestForm
    };
    @api reReqId;
    @api revisionValue;
    @api showUploadMessage;
    NSP_AnyRevisionsDeletionsToStdQuestions__c;
    filesize =0;
    fileCounts =0;
    pageNumber = 4;
    isPrevClick =false;
    fileHyperLink = this.customLabel.SurveyRevisionRequestForm;
    customLabelObj= Object.create({});
    isOnloaded = true;
    isSaveClick=false;
    userID;

    handleAccountLookup(recordId) {
    if(recordId != null && recordId.length > 14  ){
        getHRspecialist({ accountID : recordId })
        .then((result) => {
            if(result !=null && result !=''){
            this.userID =  result;
            }
            this.error = undefined;
        })
        .catch((error) => {
            this.error = error;
        });
      }
    }

    /**
    customLabelToObject() {
        let toArray =[] ;
        if(this.customLabel.surveyRevisionHyperLink.includes("\r\n")){
            toArray = this.customLabel.surveyRevisionHyperLink.split("\r\n");
        }else if(this.customLabel.surveyRevisionHyperLink.includes("\n")){
            toArray = this.customLabel.surveyRevisionHyperLink.split("\n");
        }
        toArray.forEach( each =>{
        if(each != '' && each.includes(':') && each.length > 10){
          let key = each.substring(0,each.indexOf(":")).trim();
          let value = each.substring(each.indexOf(":")+1, each.length).trim();
          this.customLabelObj[key] = value ;
          }
        });
        console.log( this.customLabelObj );
      }    
 */

    get yesNoOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' }
        ];
    }
    
    findFileSize(event){
        if( event.detail != null && event.detail.length != null){
            this.filesize = event.detail.length;
        }

        if(this.fileCounts <= this.filesize ){
            this.template.querySelector("div.AttachmentVerify").style.display ='none';
        }
    }

    connectedCallback(){
      
    }

    handleOnLoad(event) {
        if(event.detail != null &&  event.detail.records != null){
            this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
            if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){
                if(this.isOnloaded){
            /**
                    if(this.fieldsData.NSP_Survey_Type__c != null  && this.fieldsData.NSP_Survey_Type__c.value != null ){
                        this.customLabelToObject();
                        if(this.customLabelObj != null && Object.keys(this.customLabelObj).length > 0){
                            if(this.customLabelObj[this.fieldsData.NSP_Survey_Type__c.value] != null){
                                this.fileHyperLink = this.customLabelObj[this.fieldsData.NSP_Survey_Type__c.value];                                
                            }else { 
                                 for(let key in this.customLabelObj){
                                     if(key.includes(this.fieldsData.NSP_Survey_Type__c.value)){
                                         this.fileHyperLink = this.customLabelObj[key];
                                      }
                                 }
                           }
                        }

                    }
                     */

                    if(this.fieldsData.NSP_AnyRevisionsDeletionsToStdQuestions__c != null && this.fieldsData.NSP_AnyRevisionsDeletionsToStdQuestions__c.value != null){
                        this.NSP_AnyRevisionsDeletionsToStdQuestions__c = this.fieldsData.NSP_AnyRevisionsDeletionsToStdQuestions__c.value;
                        if (this.NSP_AnyRevisionsDeletionsToStdQuestions__c == 'Yes') {
                            this.fileCounts =1;
                            this.showUploadMessage = true;
                        } else {
                            this.fileCounts =0;
                            this.showUploadMessage = false;
                            this.template.querySelector("div.AttachmentVerify").style.display ='none';
                        }

                    }
                    if(this.fieldsData.NSP_ClientName__c != null  && this.fieldsData.NSP_ClientName__c.value != null &&
                        this.userID == null ){
                        this.handleAccountLookup( this.fieldsData.NSP_ClientName__c.value );
                    }
                    
                    this.isOnloaded =false;
                }
            }
        }
    }

    handlePrev(event){
        this.isPrevClick=true;
        this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));
      }

    handleSuccess(event) {
          if(!this.isPrevClick && !this.isSaveClick){
            let fieldsData = JSON.parse(JSON.stringify(event.detail.fields));
            fieldsData = { ...fieldsData, Id : event.detail.id };
            this.dispatchEvent(new CustomEvent('next', {detail: fieldsData}));
            }
            else if(this.isSaveClick){
                const saveEvent = new CustomEvent('saveexit', { bubbles: true });
                this.dispatchEvent(saveEvent);
            }
    }

    handleChange(event) {
        if(event.currentTarget.name != null && event.currentTarget.value != null){

        if (event.currentTarget.name == 'NSP_AnyRevisionsDeletionsToStdQuestions__c') {
            this.NSP_AnyRevisionsDeletionsToStdQuestions__c = event.currentTarget.value;
            if (this.NSP_AnyRevisionsDeletionsToStdQuestions__c == 'Yes') {
                this.fileCounts =1;
                this.showUploadMessage = true;
            } else {
                this.fileCounts =0;
                this.showUploadMessage = false;
                this.template.querySelector("div.AttachmentVerify").style.display ='none';
            }
        }
        //console.log('survey type ' + this.surveyType);
      }
    }
    
    handleError(event){
        alert('in error');
    }

    handleSave(event) {
        this.isSaveClick=true;
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    handleSubmit(event){
        if(!this.isSaveClick){
            event.preventDefault(); // it will prevent the submit
            if(  this.fileCounts <= this.filesize ){
                const fields = event.detail.fields;        
                this.template.querySelector('lightning-record-edit-form').submit(fields);
                
                if (this.userID !=null && this.userID != ''){
                    fields.NSP_HRSpeciallist__c = this.userID;
                }
                        
            }
            if( this.filesize < this.fileCounts ){
                this.template.querySelector("div.AttachmentVerify").style.display ='';
            }
        }
    }
}