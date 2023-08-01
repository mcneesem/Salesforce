import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import NSP_GA_ReportCheckList from '@salesforce/label/c.NSP_GA_ReportCheckList';
import NSP_GL_ReportCheckList from '@salesforce/label/c.NSP_GL_ReportCheckList';
import NSP_401k from '@salesforce/label/c.NSP_401k';
import REPORT_LOCATION from '@salesforce/schema/NSP_ReportRequest__c.NSP_ReportLocation__c';
export default class WizardDevelopmentReportPageTwo extends NavigationMixin(LightningElement) {
    @api reReqId;
    isPrevClick=false;
    isSaveClick=false;
    reportTypeOne;
    hideRerportLocation = false;
    get showReportlocation(){
        if(this.reportLocationOption?.data && !this.hideRerportLocation ){
            return true;
        }else {
            return false;
        }
    }
    reportName;
    reportPlaceLabel ='Where would you like us to place this report ?';
    reportPlace=false;
    otherReportType=false;
    additionalClient =false;
    wiredRelatedFileResult;
    relatedfile;
    recordTypeId = '012000000000000AAA';
    enableReportType=true;
    error;
    isReport
    reportTypeSelectionInfo;
    baseUrl ; 
    reportPlaceValue;
    pageNumber = 2;
    filesize = 0;
    customLabel ={
        NSP_GL_ReportCheckList,
        NSP_GA_ReportCheckList,
        NSP_401k,
    };
 onloadform = true;
    selectedReportLocationOption;
    reportType401k;
    reportTypeGeneral;

    additionalClinetOption = [
        { "attributes": null, "label": "Yes", "value": "Yes"},
        { "attributes": null, "label": "No", "value": "No" }
      ];


    selectedAdditionalClinetOption = null;

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId' ,
        fieldApiName: REPORT_LOCATION
      })
      reportLocationOption;

    handleOnload(event)
    {
        if(this.template.querySelector('lightning-input-field') != null){
            if(this.template.querySelector('lightning-input-field[data-fname="NReportType"]') != null &&
             this.template.querySelector('lightning-input-field[data-fname="NReportType"]').value !=null){
            let targetValue =  this.template.querySelector('lightning-input-field[data-fname="NReportType"]').value;
            if(targetValue =='401(k)'){
              this.reportTypeOne=  this.customLabel.NSP_401k;
              this.reportType401k =targetValue;
              
            }
            else if (targetValue == "General Account/General Ledger"){
                this.reportTypeOne=  null ;
                this.reportTypeGeneral=targetValue;
                if(this.template.querySelector('lightning-formatted-text.reportTypeTwo')?.style != null){
                    this.generateGAGLFormLink();
                }
            }
            else{
                this.reportTypeOne=null;
                this.template.querySelector("div.NSP_ReportType__c").style.display ='none';
            }

         }
         if(this.template.querySelector('lightning-input-field[data-fname="ReportLocation"]') != null &&
         this.template.querySelector('lightning-input-field[data-fname="ReportLocation"]').value !=null){
             if(this.template.querySelector('lightning-input-field[data-fname="ReportLocation"]').value == "WebFocus (MRE)"){
                this.reportPlace =true;
             } else{
                this.reportPlace =false;
            }
           }
        }
        if(event.detail.records != null){
            this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
            this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
            if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){
                if(this.fieldsData.NSP_AreThereAdditionalClients_subAccount__c != null  && this.fieldsData.NSP_AreThereAdditionalClients_subAccount__c.value != null
                    && this.selectedAdditionalClinetOption == null){
                    this.selectedAdditionalClinetOption =  this.fieldsData.NSP_AreThereAdditionalClients_subAccount__c.value; 
                    this.additionalClient = (this.selectedAdditionalClinetOption === "Yes") 
                }
                if(this.fieldsData.NSP_ReportLocation__c != null  && this.fieldsData.NSP_ReportLocation__c.value != null
                    && this.selectedReportLocationOption == null){
                    this.selectedReportLocationOption =  this.fieldsData.NSP_ReportLocation__c.value; 
                    this.reportPlace = (this.selectedReportLocationOption === "WebFocus (MRE)" );
                }
                if(this.fieldsData.Name != null  && this.fieldsData.Name.value != null && this.onloadform){
                    this.reportName =  this.fieldsData.Name.value; 
                    this.onloadform = false;
                }

                if(this.fieldsData.NSP_Existing_NewReport__c?.value?.startsWith('Change to') ){
                    this.enableReportType =false;
                    this.reportPlaceLabel = 'Where is the report?';
                }else{
                    this.enableReportType =true;
                    this.reportPlaceLabel = 'Where would you like us to place this report ?';
                }

                if(this.fieldsData.NSP_InternalClientReport__c?.value?.startsWith('Internal Report')){
                    this.hideRerportLocation = true;
                    this.reportPlace =true;
                }
          }
      }

 }

    handleSuccess(event){
        if(!this.isPrevClick && !this.isSaveClick){
        const reReqId = event.detail.id;
        this.dispatchEvent(new CustomEvent('next', {detail: reReqId}));
        }
        else if(this.isSaveClick){
            const saveEvent = new CustomEvent('saveexit', {
                bubbles: true
            });
            this.dispatchEvent(saveEvent);
        }
    }

    handleSubmit(event){
        this.findFileSize(event);
    
        if(this.filesize < 1 && this.reportType401k !=null && this.reportType401k  == '401(k)' ){
            this.template.querySelector('div.NSP_ReportType__c').style.display='block';
            event.preventDefault(); // it will prevent the submit
        }
        if(this.filesize < 1 && this.reportTypeGeneral !=null && this.reportTypeGeneral  == 'General Account/General Ledger' ){
            this.template.querySelector('div.NSP_ReportType__c').style.display='block';
            event.preventDefault(); // it will prevent the submit
        }

    }


    handleSave(event) {
        this.isSaveClick=true;
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    handlePrev(event){
        this.isPrevClick=true;
        this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));

      //  this.template.querySelector('lightning-record-edit-form').submit();
      }

    handleChange(event){

        if(event.currentTarget.name == "additionalClient" ){
            this.selectedAdditionalClinetOption =   event.currentTarget.value;
            this.additionalClient = (event.currentTarget.value === "Yes");
        }

        if( event.currentTarget.name == "reportLocation" ){
            this.selectedReportLocationOption = event.currentTarget.value;
            this.reportPlace = (event.currentTarget.value === "WebFocus (MRE)");
            if(!this.reportPlace){
                if(this.template.querySelector('lightning-input-field[data-fname="ReportPlace"]') != null &&
                 this.template.querySelector('lightning-input-field[data-fname="ReportPlace"]').value != null ){
                    this.template.querySelector('lightning-input-field[data-fname="ReportPlace"]').value = '';
                    this.reportPlaceValue ='';
                }
           }

        }
        if( event.currentTarget != null && event.currentTarget.fieldName !=null ){
        if(event.currentTarget.fieldName == "NSP_ReportType__c" ){
            this.otherReportType=false;
            if(event.target.value =='401(k)'){
                this.reportTypeOne=  this.customLabel.NSP_401k
                this.reportTypeSelectionInfo ='';
                this.template.querySelector('lightning-formatted-text.reportTypeTwo').style.display='none';
                this.reportType401k =event.target.value ;
            }
            else if (event.target.value == "General Account/General Ledger"){
                this.reportTypeOne=null;
                this.reportTypeGeneral=event.target.value;
                this.generateGAGLFormLink();
            }
            else if(event.target.value == "Other"){
                this.otherReportType = true;
                this.template.querySelector("div.NSP_ReportType__c").style.display ='none';
                this.reportType401k=null;
                this.reportTypeGeneral=null;
            }
            else{
                this.template.querySelector('lightning-formatted-text.reportTypeTwo').style.display='none';
                this.reportTypeOne=null;
                this.template.querySelector("div.NSP_ReportType__c").style.display ='none';
                this.reportType401k=null;
                this.reportTypeGeneral=null;
            }

           }
           if(event.currentTarget.fieldName == "NSP_ReportName__c" ){
              if(event.target.value !=null){
                this.reportName =   event.target.value.length > 40? event.target.value.substring(0, 40): event.target.value;
              }
           }
         }
    }

    generateGAGLFormLink(){
            let indexTxt =  this.customLabel.NSP_GA_ReportCheckList?.indexOf(':');
            let gaLabel = this.customLabel.NSP_GA_ReportCheckList?.slice(0,indexTxt).trim();
            let gaURL = this.customLabel.NSP_GA_ReportCheckList?.slice(indexTxt+1).trim();
            indexTxt =0;
            indexTxt = this.customLabel.NSP_GL_ReportCheckList?.indexOf(':');
            let glLabel = this.customLabel.NSP_GL_ReportCheckList?.slice(0,indexTxt).trim();
            let glURL = this.customLabel.NSP_GL_ReportCheckList?.slice(indexTxt+1).trim();
            let gaglElement = this.template.querySelector('lightning-formatted-text.reportTypeTwo');
            gaglElement.style.display='block';
            gaglElement.innerHTML=
            "<div class='slds-form-element slds-form-element_horizontal' ><label class='slds-form-element__label' for='horizontal-hyperText-id-01'>"+
            "Please complete and attach the appropriate checklist"+
            "</label><div class='slds-form-element__control'><a id='horizontal-hyperText-id-01' href='"+ gaURL +"' target='_blank' >"+  gaLabel   +"</a></div></div>" + 
            "<div class='slds-form-element slds-form-element_horizontal' ><label class='slds-form-element__label' for='horizontal-hyperText-id-01'>"+
            "</label><div class='slds-form-element__control'><a id='horizontal-hyperText-id-01' href='"+ glURL +"' target='_blank' rel='noopener noreferrer' >"+ glLabel    +"</a></div></div>" ;
    }

    findFileSize(event){
        if( event.detail != null && event.detail.length != null){
            this.filesize = event.detail.length;
        }
    
        if(this.filesize <1 && this.fieldsData!=null){
            if((this.reportType401k  !=null && this.reportType401k  == '401(k)') ||
               (this.reportTypeGeneral !=null && this.reportTypeGeneral =='General Account/General Ledger')  && this.template.querySelector("div.NSP_ReportType__c")!= null ){
                this.template.querySelector("div.NSP_ReportType__c").style.display ='';
            }
        }else {

            if((this.reportType401k  ==null || this.reportType401k  !=  '401(k)' || this.reportTypeGeneral ==null || 
                this.reportTypeGeneral !='General Account/General Ledger' || this.filesize >0 ) && this.template.querySelector("div.NSP_ReportType__c")!= null ){
                this.template.querySelector("div.NSP_ReportType__c").style.display ='none';
            }
        }
    }

        
       /**  if( event.currentTarget != null && event.currentTarget.fieldName !=null && event.currentTarget.fieldName == "NSP_AreThereAdditionalClients_subAccount__c" ){
            
            if(event.currentTarget.value==true){
                this.additionalClient = true;
            }else{
                this.additionalClient =false;
            }
        }
        */
      
}