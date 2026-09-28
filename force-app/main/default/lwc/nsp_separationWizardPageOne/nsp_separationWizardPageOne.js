import { LightningElement, wire, api } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import AGREEMENT_TYPE from '@salesforce/schema/NSP_ReportRequest__c.NSP_AgreementType__c';
import REVIEW_TYPE from '@salesforce/schema/NSP_ReportRequest__c.NSP_ReviewType__c';
import separationAgreementTermsList from '@salesforce/label/c.Separation_Agreement_Terms_List';
import separationAgreementList from '@salesforce/label/c.Seperation_Agreement_List';
import STATUS_OF_AGREEMENT from '@salesforce/schema/NSP_ReportRequest__c.NSP_StatusOfAgreement__c';
import MIDMARKET_ENTERPRISE from '@salesforce/schema/NSP_ReportRequest__c.NSP_Mid_Market_or_Mid_Market_Enterprise__c';
import WRITTEN_APPROVAL_FROMMHRS from '@salesforce/schema/NSP_ReportRequest__c.NSP_Written_Approval_From_The_MHRS__c';
export default class nsp_separationWizardPageOne extends LightningElement {
label = {
	separationAgreementTermsList,
  separationAgreementList
}
NSP_AgreementType =false;
NSP_ReviewType = false ;
NSP_StatusOfAgreement= false;
NSP_AgreementType__c;
NSP_Mid_Market_or_Mid_Market_Enterprise__c;
NSP_Written_Approval_From_The_MHRS__c;
NSP_StatusOfAgreement__c;
NSP_ConfirmationOfAgreementStatement__c= '';
NSP_ReviewType__c;
NSP_ClientName__c;
NSP_WSEE__c;
NSP_ShowSeperationList='';
fieldValue =  { currentTarget : { name :'', value :''} };
  @api reReqId;
  @api recordObj;
  recordTypeId;
   isSaveClick=false;
   isEnablePrev=false;
   //@track clientId
   //internalAccId ;
   error;
   pageNumber = 1;
   fieldsData ;
   isOnloaded= true;
   createDate;
   reportName = null;
   currentPageFields=['NSP_AgreementType__c','NSP_WSEE__c','NSP_Mid_Market_or_Mid_Market_Enterprise__c','NSP_Written_Approval_From_The_MHRS__c','NSP_StatusOfAgreement__c','NSP_ConfirmationOfAgreementStatement__c','NSP_ReviewType__c','NSP_ClientName__c'];
pickValueYesNo = [
  { "attributes": null, "label": "No", "value": "No" },
  { "attributes": null, "label": "Yes", "value": "Yes"}

];

get reportRecordName (){
  this.NSP_AgreementType__c != null ? (this.reportName =  this.NSP_AgreementType__c) : '';

  (this.NSP_AgreementType__c != null  && this.NSP_ReviewType__c != null )? (this.reportName = this.NSP_AgreementType__c+' - '+this.NSP_ReviewType__c) :
   this.NSP_ReviewType__c != null ? (this.reportName = this.NSP_ReviewType__c + '- Created On '+ this.createDate ):
    this.reportName == null?
    (this.reportName =  'Separation Report Created On '+ this.createDate) : this.reportName.startsWith('a7Y1')?
    (this.reportName =  'Separation Report Created On '+ this.createDate):'';

  return this.reportName;
};

   handleOnload(event){
  if(event.detail.records != null){
    this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
    this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
    if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){

      this.NSP_ConfirmationOfAgreementStatement__c =  this.fieldsData.NSP_ConfirmationOfAgreementStatement__c != null ?
      this.fieldsData.NSP_ConfirmationOfAgreementStatement__c.value: '' , console.log(this.fieldsData.NSP_ConfirmationOfAgreementStatement__c.value);

      if(this.isOnloaded){
      if(this.reviewTypeValues.data!=null&& this.statusOfAgreementValues.data !=null && this.agreementTypeValues.data != null){
            for (let key in this.fieldsData) {
              if( this.fieldsData[key]!= null && this.currentPageFields.includes(key) && this.fieldsData[key].value !=null
                  && this.fieldsData[key].value != ''){
                      this[key]=this.fieldsData[key].value;
                      this.fieldValue.currentTarget.name = key ;
                      this.fieldValue.currentTarget.value = this.fieldsData[key].value;
                      this.handleChange(this.fieldValue);
                    }
          }

          if( this.template.querySelector("div.NSP_AgreementType__c") != null  && this.template.querySelector("div.midMarketEnterprise") != null
          && this.template.querySelector("div.statusAgreementDiv") !=null
        && this.template.querySelector("div.confirmationDiv") != null){
            this.isOnloaded = false;
          }
        }
       }
      }
    }
    if(this.isOnloaded ){
    if(this.recordObj?.NSP_ClientName__c?.value != null && this.NSP_ClientName__c == null){
      this.NSP_ClientName__c = this.recordObj.NSP_ClientName__c.value;
     }

    if(this.recordObj.NSP_WSEE__c != null && this.recordObj.NSP_WSEE__c.value != null && this.NSP_WSEE__c == null){
      this.NSP_WSEE__c = this.recordObj.NSP_WSEE__c.value;
     }
  }
}

connectedCallback()
{
  let today = new Date().toUTCString();
  this.createDate = today.substring(today.indexOf(',')+2, today.indexOf(':')-2) ;
  if(this.recordObj!= null && this.recordObj.RecordTypeId != null){
    if(this.recordObj.RecordTypeId.value != null && this.recordObj.RecordTypeId.value.length == 18 ){
      this.recordTypeId =this.recordObj.RecordTypeId.value ;
    }else if(this.recordObj.RecordTypeId.length == 18){
      this.recordTypeId = this.recordObj.RecordTypeId;
    }
  }else if( this.recordTypeId == null ||  this.recordTypeId == undefined  ) {
    this.recordTypeId = '012000000000000AAA';
  }

}

@wire(getPicklistValues, {
  recordTypeId: '$recordTypeId' ,
  fieldApiName: AGREEMENT_TYPE
})
agreementTypeValues;

@wire(getPicklistValues, {
  recordTypeId: '$recordTypeId' ,
  fieldApiName: REVIEW_TYPE
})
reviewTypeValues;

@wire(getPicklistValues, {
	recordTypeId: '$recordTypeId' ,
	fieldApiName: STATUS_OF_AGREEMENT
  })
statusOfAgreementValues;

@wire(getPicklistValues, {
	recordTypeId: '$recordTypeId' ,
	fieldApiName: MIDMARKET_ENTERPRISE
  })
midMarketOrEnterPriseValues;

@wire(getPicklistValues, {
	recordTypeId: '$recordTypeId' ,
	fieldApiName: WRITTEN_APPROVAL_FROMMHRS
  })
writtenApprovalFromMhrsValues;


handleSuccess(event) {
  if(!this.isSaveClick){
    let recordField = JSON.parse(JSON.stringify(event.detail.fields)) ;
    recordField.Id=event.detail.id;
    this.dispatchEvent(new CustomEvent('next', {detail:recordField }));
  }else if(this.isSaveClick){
      const saveEvent = new CustomEvent('saveexit', { bubbles: true });
      this.dispatchEvent(saveEvent);
  }
}

handleSave(event) {
  this.isSaveClick=true;
  this.template.querySelector('lightning-record-edit-form').submit();
}

handleSubmit(event){
  }

  handlePrev(event){
    const reReqId = event.detail.id;
    this.dispatchEvent(new CustomEvent('prev', {detail: reReqId}));
  }

  handleChange(event){

    if(this.currentPageFields.includes(event.currentTarget.name)){
      this[event.currentTarget.name] =  event.currentTarget.value;
    }
/** Agreement Type */
      if(event.currentTarget.name == 'NSP_AgreementType__c' && event.currentTarget.value != null){
        this.NSP_AgreementType__c = event.currentTarget.value;
        const key= event.currentTarget.name;
        if(this.template.querySelector("div."+key) !=null){
            if(this.NSP_AgreementType__c =='Client-Prepared' ){
              this.template.querySelector("div."+key ).style.display='';
              this[event.currentTarget.name.slice(0,-3)] = true;
          }else{
            this.template.querySelector("div."+key).style.display='none';
            this[event.currentTarget.name.slice(0,-3)] = false;
        }

        this.template.querySelector('lightning-radio-group.NSP_ReviewType__c') != null?this.template.querySelector('lightning-radio-group.NSP_ReviewType__c').value ='':
        this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise__c') != null?this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise__c').value ='':
        this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c') != null?this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c').value ='':
        this.template.querySelector('lightning-radio-group.NSP_StatusOfAgreement__c') != null?this.template.querySelector('lightning-radio-group.NSP_StatusOfAgreement__c').value ='':
        this.template.querySelector("div.midMarketEnterprise") !=null?this.template.querySelector("div.midMarketEnterprise").style.display='none' :'';
        this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c') != null?this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c').value ='':''
        this.template.querySelector("div.confirmationDiv") !=null?this.template.querySelector("div.confirmationDiv").style.display='none' :'';
        this.template.querySelector("div.statusAgreementDiv") !=null?this.template.querySelector("div.statusAgreementDiv").style.display='none' :'';
        this.NSP_ReviewType__c = null;
        this.NSP_ReviewType =false;
        this.NSP_Mid_Market_or_Mid_Market_Enterprise__c = null;
        this.NSP_Mid_Market_or_Mid_Market_Enterprise =false;
        this.NSP_Written_Approval_From_The_MHRS__c=null;
        this.NSP_Written_Approval_From_The_MHRS=false;
        this.NSP_StatusOfAgreement__c = null;
        this.NSP_StatusOfAgreement =false;
        this.NSP_ConfirmationOfAgreementStatement__c = null;
        this.NSP_ConfirmationOfAgreementStatement =false;
        }
    }
/** Review Type */
		if(event.currentTarget.name == 'NSP_ReviewType__c' && event.currentTarget.value != null ){
            this.NSP_ReviewType__c = event.currentTarget.value;
        if(this.template.querySelector("div.midMarketEnterprise") !=null){

            if(this.NSP_ReviewType__c ==='HRS Review' ){
              this.template.querySelector("div.midMarketEnterprise").style.display='';
              this[event.currentTarget.name.slice(0,-3)] = true;
              this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise__c') != null? this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise__c').value ='':'';
              this.template.querySelector("div.ChangeToCorporateReivew")!=null?this.template.querySelector("div.ChangeToCorporateReivew").style.display='none':'';
          }else{
          //  this.template.querySelector("div.ChangeToCorporateReivew")!=null?this.template.querySelector("div.ChangeToCorporateReivew").style.display='block':'';
            this.template.querySelector("div.midMarketEnterprise").style.display='none';
            this[event.currentTarget.name.slice(0,-3)] = false;
            this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise__c') != null? this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise__c').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c') != null? this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c').value ='' :'';
            this.template.querySelector("div.confirmationDiv") !=null?this.template.querySelector("div.confirmationDiv").style.display='none' :'';
            this.NSP_Mid_Market_or_Mid_Market_Enterprise__c = null;
            this.NSP_Mid_Market_or_Mid_Market_Enterprise = false;
          this.NSP_ConfirmationOfAgreementStatement__c = null;
          this.NSP_StatusOfAgreement =false;
          this.NSP_ConfirmationOfAgreementStatement =false;
          }

        }
     }
     if(this.NSP_Mid_Market_or_Mid_Market_Enterprise__c ==='Yes' && this.NSP_Written_Approval_From_The_MHRS__c==='Yes' && this.NSP_StatusOfAgreement__c ==='Agreement Executed by WSEE'){
      this.NSP_ShowSeperationList=separationAgreementList;
     }else if(this.NSP_Mid_Market_or_Mid_Market_Enterprise__c ==='No' && this.NSP_StatusOfAgreement__c ==='Agreement Executed by WSEE'){
      this.NSP_ShowSeperationList=separationAgreementTermsList;
     }



     /**Middle Market or Middle Market Enterprise client */
     if(event.currentTarget.name == 'NSP_Mid_Market_or_Mid_Market_Enterprise__c' && event.currentTarget.value != null){
      this.NSP_Mid_Market_or_Mid_Market_Enterprise__c = event.currentTarget.value;
      if(this.template.querySelector("div.writtenApprovalFromMhrs") !=null){
        if(this.NSP_Mid_Market_or_Mid_Market_Enterprise__c ==='Yes' ){
          this[event.currentTarget.name.slice(0,-3)] = true;
          this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c') != null? this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c').value ='':'';
          this.template.querySelector("div.statusAgreementDiv") !=null?this.template.querySelector("div.statusAgreementDiv").style.display='none' :'';
          this.NSP_StatusOfAgreement__c=null;
          this.NSP_StatusOfAgreement=false;
          this.NSP_ConfirmationOfAgreementStatement__c = null;
          this.NSP_ConfirmationOfAgreementStatement = false;
          this.template.querySelector("div.confirmationDiv") !=null?this.template.querySelector("div.confirmationDiv").style.display='none' :'';

        }else{
            this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise__c') != null? this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise__c').value ='':'';
            this.template.querySelector("div.statusAgreementDiv").style.display='';
            this[event.currentTarget.name.slice(0,-3)] = false;
            this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c') != null? this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c').value =null:'';
            this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c') != null? this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c').value =null :'';
            this.template.querySelector("div.confirmationDiv") !=null?this.template.querySelector("div.confirmationDiv").style.display='none' :'';
          this.NSP_Written_Approval_From_The_MHRS__c = null;
          this.NSP_Written_Approval_From_The_MHRS = false;
          this.NSP_ConfirmationOfAgreementStatement__c = null;
          this.NSP_StatusOfAgreement__c=null;
          this.NSP_StatusOfAgreement=false;


          this.NSP_ConfirmationOfAgreementStatement =false;
          }
      }
    }


    /**Written approval from MHRS */
    if(event.currentTarget.name == 'NSP_Written_Approval_From_The_MHRS__c' && event.currentTarget.value != null){
            this.NSP_Written_Approval_From_The_MHRS__c = event.currentTarget.value;
          if(this.template.querySelector("div.statusAgreementDiv")!=null){
            if(this.NSP_Written_Approval_From_The_MHRS__c ==='Yes' ){
              this.template.querySelector("div.statusAgreementDiv").style.display='';
              this[event.currentTarget.name.slice(0,-3)] = true;
              //this.template.querySelector("div.confirmationDiv")!=null?this.template.querySelector("div.confirmationDiv").style.display='none':'';
              this.NSP_ConfirmationOfAgreementStatement__c = null;
              this.NSP_ConfirmationOfAgreementStatement = false;
          }else{
            this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise') != null? this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c') != null? this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_StatusOfAgreement__c') != null? this.template.querySelector('lightning-radio-group.NSP_StatusOfAgreement__c').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c') != null? this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c').value ='' :'';
            this.template.querySelector("div.statusAgreementDiv").style.display='none';
            this.template.querySelector("div.confirmationDiv") !=null?this.template.querySelector("div.confirmationDiv").style.display='none' :'';
            this.template.querySelector("div.midMarketEnterprise") !=null?this.template.querySelector("div.midMarketEnterprise").style.display='none' :'';
            this.template.querySelector("div.ChangeToCorporateReivew")!=null?this.template.querySelector("div.ChangeToCorporateReivew").style.display='block':'';
            this.NSP_Written_Approval_From_The_MHRS__c=null;
            this.NSP_Written_Approval_From_The_MHRS=false;
            this.NSP_Mid_Market_or_Mid_Market_Enterprise=null;
            this.NSP_Mid_Market_or_Mid_Market_Enterprise=false;
            this.NSP_StatusOfAgreement__c = null;
            this.NSP_StatusOfAgreement = false;
            this.NSP_ReviewType__c = 'Corporate Review';
            this.NSP_ReviewType = false;
            this[event.currentTarget.name.slice(0,-3)] = false;
            this.NSP_ConfirmationOfAgreementStatement__c = null;
            this.NSP_ConfirmationOfAgreementStatement = false;

          }
         }
      }


     /**  Status of Agreeemnt */
		if(event.currentTarget.name == 'NSP_StatusOfAgreement__c' && event.currentTarget.value != null){
            this.NSP_StatusOfAgreement__c = event.currentTarget.value;
          if(this.template.querySelector("div.confirmationDiv")!=null){
            if(this.NSP_StatusOfAgreement__c ==='Agreement Executed by WSEE' ){
              this.template.querySelector("div.confirmationDiv").style.display='';
              this[event.currentTarget.name.slice(0,-3)] = true;
              this.NSP_ConfirmationOfAgreementStatement__c=null;
              this.NSP_Mid_Market_or_Mid_Market_Enterprise=false;
              this.template.querySelector("div.ChangeToCorporateReivew")!=null?this.template.querySelector("div.ChangeToCorporateReivew").style.display='none':'';
          }else{
            this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise') != null? this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c') != null? this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_StatusOfAgreement__c') != null? this.template.querySelector('lightning-radio-group.NSP_StatusOfAgreement__c').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c') != null? this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c').value ='' :'';
            this.template.querySelector("div.midMarketEnterprise").style.display='none';
            this.template.querySelector("div.statusAgreementDiv").style.display='none';
            this.NSP_StatusOfAgreement__c = '';
            this.NSP_ReviewType__c ='Corporate Review';
            this.NSP_ReviewType = false;
              this.template.querySelector("div.confirmationDiv").style.display='none';
              this[event.currentTarget.name.slice(0,-3)] = false;
              this.NSP_ConfirmationOfAgreementStatement__c = null;
              this.template.querySelector("div.ChangeToCorporateReivew")!=null?this.template.querySelector("div.ChangeToCorporateReivew").style.display='block':'';

          }
         }
      }
/** Confirmation of Agreement */
        if(event.currentTarget.name == 'NSP_ConfirmationOfAgreementStatement__c' && event.currentTarget.value != null){
          this.NSP_ConfirmationOfAgreementStatement__c = event.currentTarget.value;
          if(this.NSP_ConfirmationOfAgreementStatement__c == 'Yes'){
            this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise') != null? this.template.querySelector('lightning-radio-group.NSP_Mid_Market_or_Mid_Market_Enterprise').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c') != null? this.template.querySelector('lightning-radio-group.NSP_Written_Approval_From_The_MHRS__c').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_StatusOfAgreement__c') != null? this.template.querySelector('lightning-radio-group.NSP_StatusOfAgreement__c').value ='':'';
            this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c') != null? this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c').value ='' :'';
            this.template.querySelector("div.statusAgreementDiv").style.display='none';
            this.NSP_StatusOfAgreement__c = null;
            this.NSP_StatusOfAgreement = false;
            this.NSP_Mid_Market_or_Mid_Market_Enterprise__c = null;
            this.NSP_Mid_Market_or_Mid_Market_Enterprise = false;
            this.NSP_Written_Approval_From_The_MHRS__c = null;
            this.NSP_Written_Approval_From_The_MHRS = false;
            this.NSP_ReviewType__c ='Corporate Review';
            this.NSP_ReviewType = false;
            this.template.querySelector("div.midMarketEnterprise").style.display='none';
              this.template.querySelector("div.confirmationDiv").style.display='none';

              this.template.querySelector("div.ChangeToCorporateReivew")!=null?this.template.querySelector("div.ChangeToCorporateReivew").style.display='':'';
              this.NSP_ConfirmationOfAgreementStatement__c =null;
              this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c') != null? this.template.querySelector('lightning-radio-group.NSP_ConfirmationOfAgreementStatement__c').value =null:'';
          } else{
            this.NSP_ConfirmationOfAgreementStatement__c  = 'No';
          }
      }

      if(this.currentPageFields.includes(event.currentTarget.name)){
        /**   this[event.currentTarget.name] =  event.currentTarget.value;*/
      }
    }



  handleClear(){
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }
    }

    findFileSize(){

    }
}