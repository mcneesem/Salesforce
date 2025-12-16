import { LightningElement , wire , api } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import NSP_Reason_for_Separation from '@salesforce/schema/NSP_ReportRequest__c.NSP_Reason_for_Separation__c';
import getWSEEDetails from '@salesforce/apex/NSP_ReportRequestWizardController.getWSEEDetails';
export default class nsp_separationWizardPageThree extends LightningElement {
@api reReqId;
recordTypeId ='012000000000000AAA' ;
MailingState;
dateOfBirth;
subClientNumber;
employeeStatus;
terminationDate;
readOnlyTerminationDate=false;
readOnlyWorkState=false;
readOnlyDob=false;
NSP_Age_Range_Is__c = 'Unknown';
pageNumber = 3;
IsMultipleEmployee = false;
NSP_WSEE_SameUnit_as_Others_Last_90_days = false;
isDisable=false;
NSP_WSEE_SameUnit_as_Others_Last_90_days__c
NSP_Was_Separation_Involuntary__c;
NSP_Reason_for_Separation__c;
NSP_CSC_matter_for_any_WSEE__c;
NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c;
NSP_HR_COEAdvisortermWSEELOA__c;
isOnloaded = true;
fieldValue =  { currentTarget : { name :'', value :''} };
clientName;
WSEE='';
contactName='';
isOnloadCalled =false;
currentPageFields=['NSP_WSEE_SameUnit_as_Others_Last_90_days__c','NSP_Was_Separation_Involuntary__c','NSP_Reason_for_Separation__c',
'NSP_CSC_matter_for_any_WSEE__c','NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c','NSP_HR_COEAdvisortermWSEELOA__c'];

get findAge(){
  
    let startDateInput =  this.template.querySelector('lightning-input-field.NSP_DOB__c')!=null?
    this.template.querySelector('lightning-input-field.NSP_DOB__c').value : null;

    let endDateInput = this.template.querySelector('lightning-input-field.NSP_Termination_Date__c')!=null?
    this.template.querySelector('lightning-input-field.NSP_Termination_Date__c').value : null;

    if( startDateInput != null && startDateInput != ''
     && endDateInput != null && endDateInput != '')
     {
    // convert user input values into date object
    let startDate = new Date(startDateInput);
    let endDate  = new Date(endDateInput);

    // get difference between two date;
    let difference=endDate - startDate.getTime(); 

    let  ageDate = new Date(difference); 
    let age = Math.abs(ageDate.getUTCFullYear() - 1970);
        if(age >= 40)
        {
        this.template.querySelector('div.AgeOverForty')!=null?
        ( this.template.querySelector('div.AgeOverForty').style.display='',this.NSP_WSEE_SameUnit_as_Others_Last_90_days = true ) : ''; 
        this.NSP_Age_Range_Is__c=  'Over 40'
            return this.NSP_Age_Range_Is__c ;
        } else {
            if ( this.template.querySelector('div.AgeOverForty') != null ) {
                this.template.querySelector('div.AgeOverForty').style.display = 'none';
            }
            this.NSP_WSEE_SameUnit_as_Others_Last_90_days = false;
            this.NSP_WSEE_SameUnit_as_Others_Last_90_days__c = null;
            if ( this.template.querySelector('div.NSP_WSEE_SameUnit_as_Others_Last_90_days__c') != null ) {
                this.template.querySelector("div.NSP_WSEE_SameUnit_as_Others_Last_90_days__c").style.display = 'none';
            }
            this.NSP_Age_Range_Is__c = 'Under 40'
            return this.NSP_Age_Range_Is__c ;
        }
     } 
     else {
        return this.NSP_Age_Range_Is__c;
     }
    

}

isPrevClick=false;
isSaveClick=false;
error;
fieldsData
pickValueYesNo = [
    { "attributes": null, "label": "No", "value": "No" },
    { "attributes": null, "label": "Yes", "value": "Yes"}
    
  ];


@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: NSP_Reason_for_Separation
})
ReasonforSeparationValues;





    connectedCallback() {
        // only populated to appease sonar...
    }

handleOnload(event){
    if(event.detail != null &&  event.detail.records != null){
        this.isOnloadCalled=true;
        this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
        this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
        if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){
            if ( this.fieldsData.NSP_ClientName__c?.value != null ) {
                this.clientName=this.fieldsData.NSP_ClientName__c.value;
            }
            if ( this.fieldsData.NSP_RequestingMultipleEmployees__c?.value != null ) {
                this.IsMultipleEmployee =  (this.fieldsData.NSP_RequestingMultipleEmployees__c.value  == 'Yes');
            }
            if ( this.fieldsData.NSP_ReviewType__c?.value != null ) {
                if ( this.fieldsData.NSP_ReviewType__c.value == 'HRS Review' ) {
                    this.template.querySelector("lightning-radio-group.NSP_CSC_matter_for_any_WSEE__c")!= null ?
                    (this.template.querySelector("lightning-radio-group.NSP_CSC_matter_for_any_WSEE__c").value = 'No', this.isDisable = true , this.NSP_CSC_matter_for_any_WSEE__c ='No'):null;

                    this.template.querySelector("lightning-radio-group.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c")!= null ?
                    (this.template.querySelector("lightning-radio-group.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c").value = 'No', this.isDisable = true , this.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c ='No'):null; 
                }
                 
            }
            
            if(this.isOnloaded){

                if( this.fieldsData?.NSP_WSEE__c?.value !=null && this.fieldsData?.NSP_WSEE__c?.value.length >14 ){
                    this.WSEE=this.fieldsData.NSP_WSEE__c.value;
                    this.handleContactLookup(this.WSEE);
                    }

                if(this.ReasonforSeparationValues.data != null )
                    { 
                        for (let key in this.fieldsData) {
                            if( this.fieldsData[key]!= null && this.fieldsData[key].value !=null 
                                && this.fieldsData[key].value != '' && this.currentPageFields.includes(key)){
                                    this[key]=this.fieldsData[key].value;
                                    this.fieldValue.currentTarget.name = key ;
                                    this.fieldValue.currentTarget.value = this.fieldsData[key].value; 

                                    this.handleChange(this.fieldValue);
                            }
                        }
                        if((this.IsMultipleEmployee && this.template.querySelector("lightning-radio-group.NSP_WSEE_SameUnit_as_Others_Last_90_days__c") !=null && 
                        this.template.querySelector("div.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c")!= null ) ||  ( !this.IsMultipleEmployee &&
                            this.template.querySelector("div.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c")!= null && this.fieldsData.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c != null
                        )){
                            this.isOnloaded=false;
                        }
                   }
                }
            
       }
   }
}

handleChange(event){
    if(this.currentPageFields.includes(event.currentTarget.name)){
        this[event.currentTarget.name] = event.currentTarget.value;
    }

    if(event.currentTarget.name == 'NSP_WSEE_SameUnit_as_Others_Last_90_days__c' && event.currentTarget.value != null ){
        
    if(this.template.querySelector("div.NSP_WSEE_SameUnit_as_Others_Last_90_days__c") !=null){
        if(this[event.currentTarget.name] =='Yes' ){
          this.template.querySelector("div.NSP_WSEE_SameUnit_as_Others_Last_90_days__c").style.display='';
      }else{
        this.template.querySelector("div.NSP_WSEE_SameUnit_as_Others_Last_90_days__c").style.display='none';
      }
    }
  }

  if(event.currentTarget.name == 'NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c' && event.currentTarget.value != null ){
        
    if(this.template.querySelector("div.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c") !=null){
        if(this[event.currentTarget.name] =='Yes' ){
          this.template.querySelector("div.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c").style.display='';
          this.NSP_HR_COEAdvisortermWSEELOA = true;
      }else{
        this.template.querySelector("div.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c").style.display='none';
        this.template.querySelector("lightning-input-field.NSP_IsThisWSEEon_any_LOA_Type_beside_TLO__c").value=null;
        this.NSP_HR_COEAdvisortermWSEELOA__c = null;
        this.NSP_HR_COEAdvisortermWSEELOA = false
      }
    }
  }
  
  if( event.currentTarget.fieldName == "NSP_WSEE__c" ){
    if(event.currentTarget.value != null && event.currentTarget.value.length > 14 ){
        this.handleContactLookup(event.currentTarget.value);
    }else{
        this.MailingState = null;
        this.dateOfBirth=null;
        this.subClientNumber = null;
        this.employeeStatus = null;
        this.terminationDate = null;
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

@api
  get syncFieldValues() {
    return null;
  }
  set syncFieldValues(values) {
    if (values) {
        const { fieldName, value } = values;
        if(fieldName=='NSP_ClientName__c')
        {
            this.clientName=value;
        }
    }     
  }

handleContactLookup(recordId) {
    if(recordId != null && recordId.length > 14  ){
        getWSEEDetails({ contactID : recordId,
            accountId:  this.clientName })
        .then((result) => {
            if(result && result.length>0){
                this.contactName = result[0].contactName;
            
                this.MailingState =  result[0].mailingState != 'Not Found'? result[0].mailingState :'';
                if(result[0].mailingState!=null){
                    this.readOnlyWorkState=true;
                }
                else{
                    this.readOnlyWorkState=false;
                }
                
                if(result[0].dateOfBirth != null){
                    this.dateOfBirth =  result[0].dateOfBirth ;
                    this.readOnlyDob=true;
                }
                else{
                    this.readOnlyDob=false;
                }
                
                if(result[0].subClientNum != null ){
                    this.subClientNumber = result[0].subClientNum;
                }
                if(result[0].empStatus != null){
                    this.employeeStatus = result[0].empStatus;
                }
                if(result[0].terminationDate != null){
                    this.terminationDate = result[0].terminationDate;
                    this.readOnlyTerminationDate = true;
                }else{
                    
                    this.readOnlyTerminationDate = false;
                }
                
                this.error = undefined;
            }
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
}

handlelookupRecord(event){
    let selectedRecord = event.detail.recId;
    this.WSEE=selectedRecord;
    if( this.WSEE!=null && this.WSEE.length >14 ){
        this.handleContactLookup(this.WSEE);
    }
    else{
        this.MailingState = null;
        this.dateOfBirth=null;
        this.subClientNumber = null;
        this.employeeStatus = null;
        this.terminationDate = null;
        this.contactName ='';
    }

}

    handleSubmit( event ) {
        // only populated to appease sonar...
    }

    hanldeNext( event ) {
        // only populated to appease sonar...
    }

    handlePrev( event ) {
        this.isPrevClick = true;
        this.dispatchEvent(
            new CustomEvent(
                'prev' ,
                { detail : this.reReqId }
            )
        );
    }

    findFileSize() {
        // only populated to appease sonar...
    }

}
//