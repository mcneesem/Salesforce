import { LightningElement, api, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import EMPLOYEE_FIELD from "@salesforce/schema/NSP_ReportRequest__c.NSP_ClientName__r.NumberOfEmployees";
import ROLEOPTION_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_RoleOptionSelection__c';
import SERVICELENGTH_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_ServiceLengthSelection__c';
import STATUS_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_HRSurveyStatusSelection__c';
import getActiveEmployeeCount from '@salesforce/apex/NSP_ReportRequestWizardController.getActiveEmployeeCount';
import wizardFilterMessage from '@salesforce/label/c.NSP_HR_Survey_Wizard_Filter_Message';
const fields = [EMPLOYEE_FIELD];
export default class WizardSurveyPageFilters extends LightningElement {
    customLabel ={
        wizardFilterMessage
    };
    @api reReqId ;
    @api recordObj;
    isPrevClick=false;
    recordTypeId = '012000000000000AAA';
    showLocation = false;
    showDivision = false;
    showRole = false;
    showService = false;
    showStatus = false;
    showCustomRole = false;
    showCustomService = false;
    roleValue = [];
    serviceValue = [];
    statusValue = [];
    pageNumber = 2;
    isOnloaded= true;
    errorMsg;
    enableFilter = false;
    employeeCount;
    handlePrevNA(event){
        this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));
    }
    handleSaveNA(event){
        const saveEvent = new CustomEvent('saveexit', {
            bubbles: true
        });
        this.dispatchEvent(saveEvent);

    }

    handleNextNA(event){

        this.dispatchEvent(new CustomEvent('next', {detail: this.reReqId }));
    }

    roleOptionErrorMsg = 'display:none';
    serviceLengthErrorMsg ='display:none';
    surveyStatusErrorMsg = 'display:none';

    @wire(getRecord, { recordId: '$reReqId', fields })
    account({ error, data }) {
        if (data) {
           this.employeeCount =  getFieldValue(data, EMPLOYEE_FIELD);
            this.errorMsg = undefined;
        } else {
            this.errorMsg = error;
        }
    }

  /**  get revenue() {
        return getFieldValue(this.account.data, EMPLOYEE_FIELD);
    }
 */
    pleaseWait = [{
        "attributes": null,
        "label": "Please Wait",
        "validFor": [],
        "value": "Please Wait"
    }];

    checkBoxFields=['NSP_HRSurveyStatus__c','NSP_ServiceLength__c','NSP_RoleOptions__c','NSP_ClientDepartmentsDivision__c','NSP_ClientLocation__c'];
    comboGroupFields=['NSP_RoleOptionSelection__c','NSP_ServiceLengthSelection__c','NSP_HRSurveyStatusSelection__c'];
    currentPageFields =['NSP_CustomServiceLength__c','NSP_CustomRoleList__c','NSP_ListOfDepartmentsDivisions__c','NSP_ListOfLocations__c'];
    

    NSP_ClientLocation__c = [];
    NSP_ClientDepartmentsDivision__c;
    NSP_RoleOptions__c;
    NSP_HRSurveyStatus__c;
    NSP_Manager__c;

 //required 
   NSP_ClientLocation = false;
   NSP_ClientDepartmentsDivision =false;
   NSP_RoleOptions =false;
   NSP_ServiceLength =false;
   NSP_HRSurveyStatus =false;
   NSP_CustomRoleList =false;
   NSP_CustomServiceLength=false;
   NSP_Manager =false;

//storage
    ListOfLocations
    ListOfDepartmentsDivisions
    RoleOptionSelection
    ServiceLengthSelection
    HRSurveyStatusSelection

//dependent field value store
    get NSP_ListOfLocations__c(){
        return this.NSP_ClientLocation?this.ListOfLocations: '';
    }
    set NSP_ListOfLocations__c( input ){
        this.ListOfLocations = input;
    }

    get NSP_ListOfDepartmentsDivisions__c(){
        return this.NSP_ClientDepartmentsDivision? this.ListOfDepartmentsDivisions: '';
    }

    set NSP_ListOfDepartmentsDivisions__c(input){
        this.ListOfDepartmentsDivisions = input;
    }
//radio group value store 
   get NSP_RoleOptionSelection__c(){
       if(this.NSP_RoleOptions && this.RoleOptionSelection !=null && this.RoleOptionSelection != undefined && this.RoleOptionSelection.length >0){
        return this.arrayToMultiSelectObject(this.RoleOptionSelection)
       }else{
        return '';     
       }
   }

    set NSP_RoleOptionSelection__c(input){
        this.RoleOptionSelection = input;
   }

    get NSP_ServiceLengthSelection__c(){
       if(this.NSP_ServiceLength && this.ServiceLengthSelection !=null && this.ServiceLengthSelection != undefined && this.ServiceLengthSelection.length >0
        ){
        return this.arrayToMultiSelectObject(this.ServiceLengthSelection)
       }else{
        return [];     
       }
    }

    set NSP_ServiceLengthSelection__c(input){
       this.ServiceLengthSelection = input;
    }
    
    get NSP_HRSurveyStatusSelection__c(){
       if(this.NSP_HRSurveyStatus && this.HRSurveyStatusSelection !=null && this.HRSurveyStatusSelection != undefined && this.HRSurveyStatusSelection.length > 0){
        return this.arrayToMultiSelectObject(this.HRSurveyStatusSelection)
       }else{
        return '';     
       }
    }

    set NSP_HRSurveyStatusSelection__c(input){
       this.HRSurveyStatusSelection = input;

    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId' ,
        fieldApiName: ROLEOPTION_PICKLIST
    })
    roleOptionsSelect;
    
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId' ,
        fieldApiName: SERVICELENGTH_PICKLIST
    })
    serviceOptionsSelect;
    
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId' ,
        fieldApiName: STATUS_PICKLIST
    })
    statusOptionsSelect;
    

    get roleOptions() {
        return  this.roleOptionsSelect != null && this.roleOptionsSelect.data != null ? this.roleOptionsSelect.data.values: this.pleaseWait;
    }
    get statusOptions() {
        return  this.statusOptionsSelect != null && this.statusOptionsSelect.data != null  ? this.statusOptionsSelect.data.values:this.pleaseWait;
    }
    get serviceOptions() {
        return  this.serviceOptionsSelect != null && this.serviceOptionsSelect.data != null ? this.serviceOptionsSelect.data.values:this.pleaseWait;
    }

    connectedCallback(){
        if(this.recordObj!= null && this.recordObj.RecordTypeId != null){
            this.recordTypeId =this.recordObj.RecordTypeId ;
          }else if( this.recordTypeId == null ||  this.recordTypeId == undefined  ) {
            this.recordTypeId = '012000000000000AAA';
          }
    }

    handleComboChange(event) {
        if(event.currentTarget !=null && event.currentTarget.name !=null && event.currentTarget.value !=null){
            let key = event.currentTarget.name;
            let value = event.currentTarget.value;
            switch (key) {
                case "NSP_RoleOptionSelection__c":
                    this.NSP_RoleOptionSelection__c = value;
                    if( this.template.querySelector('div.'+key) != null){
                        value.includes('Custom Role Options')? (this.template.querySelector('div.' + key).style.display = '', this.NSP_CustomRoleList = true) : (this.template.querySelector('div.' + key).style.display = 'none', this.NSP_CustomRoleList = false, (this.template.querySelector('lightning-input-field.' + key).value != null ? this.template.querySelector('lightning-input-field.' + key).value = '' : ''));
                       }
                       this.roleOptionErrorMsg = 'display:none';
                    break;
                    case "NSP_ServiceLengthSelection__c":
                        this.NSP_ServiceLengthSelection__c = value;
                        if( this.template.querySelector('div.'+key) != null){
                            value.includes("Custom Service Length") ? (this.template.querySelector('div.' + key).style.display = '', this.NSP_CustomServiceLength = true) : (this.template.querySelector('div.' + key).style.display = 'none', this.NSP_CustomServiceLength = false, (this.template.querySelector('lightning-input-field.' + key).value != null ? this.template.querySelector('lightning-input-field.' + key).value = '' : ''));
                        }
                        this.serviceLengthErrorMsg='display:none';
                        break;
                    case "NSP_HRSurveyStatusSelection__c":
                        this.NSP_HRSurveyStatusSelection__c = value;
                        this.surveyStatusErrorMsg='display:none';
                        break;
            }
        }
    }

    radioOnChange(event) {
        if(event.currentTarget !=null && event.currentTarget.fieldName !=null && event.currentTarget.value !=null){
            let key = event.currentTarget.fieldName;
             let value = event.currentTarget.value;
            switch (key) {
                case "NSP_ClientLocation__c":

                    if (value) {
                        this.NSP_ClientLocation = true;
                    } else {
                        this.NSP_ClientLocation = false;
                    }
                    if( this.template.querySelector('div.'+key) != null){
                        value == true? this.template.querySelector('div.'+key).style.display='':this.template.querySelector('div.'+key).style.display='none';
                       }
                    if(!this.isOnloaded && this.enableFilter && this.template.querySelector('lightning-input-field.NSP_ClientLocation__c')!= null){
                         this.template.querySelector('lightning-input-field.NSP_ClientLocation__c').value = null;
                    }
                    break;
                case "NSP_ClientDepartmentsDivision__c":

                    if (value) {
                        this.NSP_ClientDepartmentsDivision = true;
                    } else {
                        this.NSP_ClientDepartmentsDivision = false;
                    }
                    if( this.template.querySelector('div.'+key) != null){
                        value == true? this.template.querySelector('div.'+key).style.display='block':this.template.querySelector('div.'+key).style.display='none';
                       }
                    if(!this.isOnloaded && this.enableFilter && this.template.querySelector('lightning-input-field.NSP_ClientDepartmentsDivision__c')!=null){
                        this.template.querySelector('lightning-input-field.NSP_ClientDepartmentsDivision__c').value = null;
                    }
                    break;
                case "NSP_RoleOptions__c":
                    if (value) {
                        this.NSP_RoleOptions = true;
                        if(this.NSP_RoleOptionSelection__c == null || this.NSP_RoleOptionSelection__c == '' || this.NSP_RoleOptionSelection__c == []){
                            this.roleOptionErrorMsg = "display:''";
                        }
                    } else {
                        this.NSP_RoleOptions = false;
                        this.NSP_RoleOptionSelection__c= [];
                        this.NSP_RoleOptionSelection = false;
                        this.NSP_CustomRoleList=false;
                        this.roleOptionErrorMsg = "display:none";
                        this.template.querySelector('lightning-input-field.NSP_RoleOptionSelection__c').value != null ? this.template.querySelector('lightning-input-field.NSP_RoleOptionSelection__c').value = '' : '';
                        this.template.querySelector('div.NSP_RoleOptionSelection__c').style.display = 'none'
                    }
                    
                    if( this.template.querySelector('lightning-checkbox-group.'+key) != null){
                        value == true? this.template.querySelector('lightning-checkbox-group.'+key).style.display='':(this.template.querySelector('lightning-checkbox-group.'+key).style.display='none',this.template.querySelector('lightning-checkbox-group.'+key).value !=null ? this.template.querySelector('lightning-checkbox-group.'+key).value =[]:'');
                       }

                       if(!this.isOnloaded && this.enableFilter && this.template.querySelector('lightning-input-field.NSP_RoleOptionSelection__c')!= null){
                        this.template.querySelector('lightning-input-field.NSP_RoleOptions__c')!=null?this.template.querySelector('lightning-input-field.NSP_RoleOptions__c').value = null:'';
                        this.template.querySelector('lightning-input-field.NSP_RoleOptionSelection__c').value = null;
                      }

                    break;

                    case "NSP_ServiceLength__c":
                        if (value) {
                            this.NSP_ServiceLength = true;
                            if(this.NSP_ServiceLengthSelection__c == null || this.NSP_ServiceLengthSelection__c == '' || this.NSP_ServiceLengthSelection__c == []){
                                this.serviceLengthErrorMsg = "display:''";
                            }
                        } else {
                            this.NSP_ServiceLength = false;
                            this.NSP_ServiceLengthSelection__c= [];
                            this.serviceLengthErrorMsg = "display:none";
                            this.NSP_CustomServiceLength = false;
                            this.template.querySelector('div.NSP_ServiceLengthSelection__c').style.display = 'none'
                            this.template.querySelector('lightning-input-field.NSP_ServiceLengthSelection__c').value != null ? this.template.querySelector('lightning-input-field.NSP_ServiceLengthSelection__c').value = '' : '';
                        }
                    if( this.template.querySelector('lightning-checkbox-group.'+key) != null){
                        value == true? this.template.querySelector('lightning-checkbox-group.'+key).style.display='': this.template.querySelector('lightning-checkbox-group.'+key).style.display='none';
                        this.template.querySelector('lightning-checkbox-group.'+key).value =null;
                        }

                        if(!this.isOnloaded && this.enableFilter && this.template.querySelector('lightning-input-field.NSP_ServiceLengthSelection__c')!=null){
                            this.template.querySelector('lightning-input-field.NSP_ServiceLength__c') != null ? this.template.querySelector('lightning-input-field.NSP_ServiceLength__c').value = null:'';
                             this.template.querySelector('lightning-input-field.NSP_ServiceLengthSelection__c').value = null;
                          }
                        break;

                    case "NSP_HRSurveyStatus__c":
                        if (value) {
                            this.NSP_HRSurveyStatus = true;
                            if(this.NSP_HRSurveyStatusSelection__c == null || this.NSP_HRSurveyStatusSelection__c == '' || this.NSP_HRSurveyStatusSelection__c == []){
                                this.surveyStatusErrorMsg = "display:''";
                            }
                        } else {
                            this.NSP_HRSurveyStatus = false;
                            this.NSP_HRSurveyStatusSelection__c =[];
                            this.surveyStatusErrorMsg = "display:none";
        
                        }
                        if( this.template.querySelector('lightning-checkbox-group.'+key) != null){
                            value == true? this.template.querySelector('lightning-checkbox-group.'+key).style.display='':(this.template.querySelector('lightning-checkbox-group.'+key).style.display='none',this.template.querySelector('lightning-checkbox-group.'+key).value !=null ? this.template.querySelector('lightning-checkbox-group.'+key).value =[]:'');
                        }
                        if(!this.isOnloaded && this.enableFilter && this.template.querySelector('lightning-input-field.NSP_HRSurveyStatus__c') !=null){
                            this.template.querySelector('lightning-input-field.NSP_HRSurveyStatus__c').value = null;
                          }
                        break;
              }
          }
    }

    fieldValue =  { currentTarget : { fieldName :'',name:'',value :''} };

    handleOnload(event) {
        if(event.detail != null &&  event.detail.records != null){
            this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
            this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
            if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){

            if(this.isOnloaded){                                
                if(this.fieldsData.NSP_Survey_Type__c != null  && this.fieldsData.NSP_Survey_Type__c.value != null ){
                    this.NSP_Manager =  (this.fieldsData.NSP_Survey_Type__c.value =='Exit');
                    
                }
                if(this.fieldsData.NSP_ClientName__c != null  && this.fieldsData.NSP_ClientName__c.value != null ){
                    this.isActiveEmployeeCount(this.fieldsData.NSP_ClientName__c.value);
                }
               for (let key in this.fieldsData) {
                    if( this.fieldsData[key]!= null && this.fieldsData[key].value !=null && this.fieldsData[key].value != ''){
                      if(this.checkBoxFields.includes(key)){
                          this.fieldValue.currentTarget.fieldName = key 
                          this.fieldValue.currentTarget.value = this.fieldsData[key].value; 
                          this.isOnloaded =true;
                           this.radioOnChange(this.fieldValue);
                           this.isOnloaded =false;
                        }
                        
                        if(this.comboGroupFields.includes(key) && this.fieldsData[key].value != null){
                            this.fieldValue.currentTarget.name = key 
                            this.fieldValue.currentTarget.value =  this.stringToArray(this.fieldsData[key].value); 
                            this.isOnloaded =true;
                             this.handleComboChange(this.fieldValue);
                            this.isOnloaded =false;
                          }
                    }
                }
           }
        }
    }
}

    handleSuccess(event) {
        if(!this.isSaveClick && !this.isPrevClick){
            this.reReqId = event.detail.id;
            //recordField.Id=event.detail.id;
            this.dispatchEvent(new CustomEvent('next', {detail: this.reReqId }));
        }else if(this.isSaveClick){
            const saveEvent = new CustomEvent('saveexit', { bubbles: true });
            this.dispatchEvent(saveEvent);
          }
    }

    handleOnSubmit(event) {
        
        if(!this.enableFilter){
            event.preventDefault();
            this.currentPageFields = this.currentPageFields.concat(this.comboGroupFields);
            let fields = event.detail.fields;
            this.checkBoxFields.forEach(each=>{
                fields[each] =false;
            } ) 
            
            this.currentPageFields.forEach(each=>{
                fields[each] = null;
             })
            this.template.querySelector('lightning-record-edit-form').submit(fields); // it will submit the form
        }
    }
    handlePrev(event){
        this.isPrevClick=true;
        //const reReqId = event.detail.id;
        this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));
      }
      handleError(event){
        alert('in error'); //added as part of code scan
      }

  arrayToMultiSelectObject(inputValue){
    let myString;
    let inputArray = JSON.parse(JSON.stringify(inputValue));
   if(Array.isArray(inputArray)){
    inputArray.forEach( keyValue =>{
    if(myString != null){
       myString = myString+';' +keyValue;
       }else{
    myString = keyValue;
    }
    })
    }
    return myString;
  }

stringToArray(inputValue){
    if(inputValue.includes(';')){
        return inputValue.split(';');
    }
    else {
        return [inputValue];
    }
}
  
handleSave(event) {
     this.isSaveClick=true;
    this.template.querySelector('lightning-record-edit-form').submit();
}

isActiveEmployeeCount (parentId) {
    getActiveEmployeeCount({ accountId : parentId })
    .then((result) => {
        if (result!=undefined) {
            this.enableFilter=this.NSP_Manager || result;
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