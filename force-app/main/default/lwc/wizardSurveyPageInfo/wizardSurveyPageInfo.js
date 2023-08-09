import { LightningElement, wire, api, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord,createRecord } from 'lightning/uiRecordApi';
import SURVEY_FIELD from '@salesforce/schema/NSP_ReportRequest__c.NSP_Survey_Type__c';
import CONTACT from '@salesforce/schema/NSP_ReportRequest__c.NSP_Contact__c';
import ID_FIELD from '@salesforce/schema/NSP_ReportRequest__c.Id';
import ACC_FIELD from '@salesforce/schema/NSP_ReportRequest__c.NSP_ClientName__c';
import REPORT_REQ_OBJ from "@salesforce/schema/NSP_ReportRequest__c";
import retrieveContactRecords from '@salesforce/apex/NSP_ReportRequestWizardController.retrieveContactRecords';
import retrieveSurveyRegion from '@salesforce/apex/NSP_ReportRequestWizardController.getHRspecialistAndFinanceLevel';
export default class WizardSurveyPageInfo extends LightningElement {
    @api reReqId ;
    @api recordObj;
    @api clientId;
    @api clientAccId = '';
    @api cname='';
    isSaveClick =false;
    recordTypeId = '012000000000000AAA';
    allowNext=true;
    pageNumber = 1;
    showEndDate = "display:block;";
    endDateRequired= true;
    currentConactId;
    nameField;
    showButton = false;
    cemail;
    NSP_End_Date__c;
    disableContact =true;
    enableContact = true;
    NSP_BargainingUnitEmployeesComplete__c = '';
    NSP_Survey_Type__c;
    isOnloaded = true;
    reportName;
    @track showUnion = false;
    NSP_Contact__c='';
    @track NSP_Survey_Type__c;
    @track mergeObjectList = [];
    @track accContacts =[ { ContactId:"00",Name:"None"}];
    showErroMsg = "display:none";
    @track savedAccContacts;
    @track WSEEName;
    contactOptions;
    region;
    isOnloadCalled=false;

    columns = [
        { label: 'Name', fieldName: 'name' },
        { label: 'Email', fieldName: 'NSP_Work_email__c' },

        {
            type: 'button-icon',
            typeAttributes:
            {
                iconName: 'utility:delete',
                name: 'delete',
                iconClass: 'slds-icon-text-error'
            }
        }
    ];


    updateReportRequest(accountID) {
     const fields = {};
    if(this.reReqId != null &&  this.reReqId.length > 17 && accountID !=null && accountID.length > 17 ){
      //  fields[CONTACT.fieldApiName] = null;
        fields[ID_FIELD.fieldApiName] = this.reReqId;
        fields[ACC_FIELD.fieldApiName] = accountID;
        fields[CONTACT.fieldApiName] ='';
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.enableContact= true
                // Display fresh data in the form
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: error.body.message,
                        variant: 'error'
                    })

                );
                this.enableContact= true
            });
        }
        else if( accountID !=null && accountID.length > 17 &&
            this.recordTypeId != null && this.recordTypeId.length > 17 ){
            const fields = {
                RecordTypeId : this.recordTypeId,
                NSP_ClientName__c : accountID,
                NSP_Contact__c : '',
            };
            const recordInput = { apiName: REPORT_REQ_OBJ.objectApiName, fields };
            createRecord(recordInput).then(result => {
                this.reReqId =  result.id;
                this.enableContact= true
            })
            .catch(error => {
                this.error = error;
                this.enableContact= true
            });
        }
        
    }

    get yesNoValues() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: SURVEY_FIELD
    })
    surveyTypeValues;

    /**
    @wire(retrieveContactRecords, { accountId: '$clientId' })
    wireConRecord({ error, data }) {
        if (data) {
            this.accContacts = data;
            this.savedAccContacts = data;
            this.errorMsg = undefined;
            //console.log('cons ' + JSON.stringify(this.accContacts)); 
        } else {
            this.errorMsg = error;
            this.accContacts = undefined;
            //console.log('error' + this.errorMsg);
        }
    }
 */

    getContactRecord( parentId ) {
        retrieveContactRecords({ accountId : parentId })
            .then((result) => {
                if (result) {
                    this.accContacts = result;
                    this.savedAccContacts = result;
                    this.errorMsg = undefined;
                }
            })
            .catch((error) => {
                this.errorMsg = error;
                this.accContacts = undefined;
            });
    }

    getSurveyRegion (parentId) {
        retrieveSurveyRegion({ accountID : parentId })
        .then((result) => {
            if (result) {
                this.region = result.region != 'Not Found' ? result.region :'';
                this.userID =  result.UserId != 'Not Found'? result.UserId :'';
                this.segmentType = result.segment != 'Not Found' ? result.segment :'';
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

    handleChangeAccountAction(event) {
        this.accountId = event.detail;
    }

    connectedCallback() {
        let today = new Date().toUTCString();  
        this.reportName ='Survey Request' + today.substring(today.indexOf(',')+2, today.indexOf(':')-2) ;
        if(this.recordObj != null && this.recordObj.RecordTypeId !=null){
            this.recordTypeId = this.recordObj.RecordTypeId;
            if (this.recordTypeId  === undefined){
            //     this.recordTypeId = this.recordObj.recordTypeId;
            }
        }
    }

    handleOnLoad(event) {
        this.isOnloadCalled=true;
        this.clientAccId = this.template.querySelector('lightning-input-field[data-fname="clientName"]').value ;
    if(this.isOnloaded && this.recordObj != null && this.recordObj.NSP_ClientName__c != null && 
            this.clientId == null && this.recordObj.NSP_ClientName__c.value != null){
            this.clientId = this.recordObj.NSP_ClientName__c.value ;
            this.getContactRecord(this.recordObj.NSP_ClientName__c.value );
            this.updateReportRequest(this.clientId);
            this.getSurveyRegion(this.clientId);
            this.enableContact =true;
            this.disableContact =false;
     }
    if(event.detail != null &&  event.detail.records != null){
        if(this.isOnloaded){
        this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
        this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
        if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){


            if( this.fieldsData.NSP_Survey_Type__c != null && this.fieldsData.NSP_Survey_Type__c.value != null ){
                this.NSP_Survey_Type__c = this.fieldsData.NSP_Survey_Type__c.value ;
                if (this.NSP_Survey_Type__c === 'Exit') {
                    this.showEndDate = "display:none;";
                    this.endDateRequired= false;
                    this.NSP_End_Date__c =null;
                } else {
                    this.showEndDate = "display:block;";
                    this.endDateRequired= true;
                }
            }

            if( this.fieldsData.NSP_BargainingUnitEmployeesComplete__c != null && this.fieldsData.NSP_BargainingUnitEmployeesComplete__c.value != null ){
                this.NSP_BargainingUnitEmployeesComplete__c = this.fieldsData.NSP_BargainingUnitEmployeesComplete__c.value ;
            }

            if( this.fieldsData.NSP_WhoAtclientCccessToOnlineResul__c != null && this.fieldsData.NSP_WhoAtclientCccessToOnlineResul__c.value != null ){
                this.mergeObjectList =  this.textAreaToArray(this.fieldsData.NSP_WhoAtclientCccessToOnlineResul__c.value);
               // this.mergeObjectList = this.reArrangeOrder(this.mergeObjectList);
                }

                if( this.fieldsData.NSP_ClientName__c != null && this.fieldsData.NSP_ClientName__c.value != null ){
                    this.getContactRecord(this.fieldsData.NSP_ClientName__c.value );
                    this.enableContact =true;
                    this.disableContact =false;
                }
          }
           this.NSP_Contact__c = '';

           if(this.fieldsData.NSP_BargainingUnitEmployeesComplete__c != null &&
           this.fieldsData.NSP_WhoAtclientCccessToOnlineResul__c != null &&
           this.fieldsData.NSP_ClientName__c != null && this.fieldsData.NSP_Survey_Type__c != null ){
            this.isOnloaded =false;
           }


        }
    }
    }

    handleAccSuccess(event) {
            this.reReqId = event.detail.id;
            this.enableContact= true
    }


    handleSuccess(event) {
        if(this.allowNext){
            let recordField = JSON.parse(JSON.stringify(event.detail.fields)) ;
            this.reReqId = event.detail.id;
            recordField.Id=event.detail.id;
            this.dispatchEvent(new CustomEvent('next', {detail: this.reReqId }));
          }
          else if(this.isSaveClick){
            const saveEvent = new CustomEvent('saveexit', { bubbles: true });
            this.dispatchEvent(saveEvent);
          }

    }

    handleOnSubmit(event) {
               
        /**
         * event.preventDefault();
        //add fields & do validation
        let fields = event.detail.fields;
        if (this.NSP_Survey_Type__c != null) {
            fields.NSP_Survey_Type__c = this.NSP_Survey_Type__c;
        }
        fields.NSP_LastSavedPageNumber__c = this.pageNumber;
        console.log('fields ' + JSON.stringify(fields));
        this.template.querySelector('lightning-record-edit-form').submit(fields);
         */
    }

    handleRowAction(event) {
        if (event.detail.action.name === 'delete') {
            this.mergeObjectList = this.mergeObjectList.filter((row => row.NSP_Work_email__c !== event.detail.row.NSP_Work_email__c) && 
            (row => row.name !== event.detail.row.name));
        }
    }

    handleContact(event) {
        // this.currentConactId = event.detail.value;
     
  }

  handleChangeEmail(event){
    if(event.currentTarget.name == 'cemail'){
      //  this.cemail = event.currentTarget.value;
    }
  }

  changeEmail(event){
  }

    handleAddContact(event) {
    let emailAddress;
        if(this.template.querySelector('lightning-input-field[data-fname="NSP_Contact__c"]') != null && this.template.querySelector('lightning-input-field[data-fname="NSP_Contact__c"]').value !=null ){
            let contactID =this.template.querySelector('lightning-input-field[data-fname="NSP_Contact__c"]').value ;
            if(contactID != null &&  contactID.length > 17){
                this.currentConactId = contactID;
                const conObj = this.accContacts.find(row => row.ContactId === this.currentConactId);
                this.cname = conObj.Contact.Name; 
              }else{
                this.cname = '';
              }
        }
        if( this.template.querySelector('lightning-input[data-fname="emailAddress"]') !=null && this.template.querySelector('lightning-input[data-fname="emailAddress"]').checkValidity() == true
        && this.template.querySelector('lightning-input[data-fname="emailAddress"]').value !=''){
            emailAddress = this.template.querySelector('lightning-input[data-fname="emailAddress"]').value;
        }else{
            emailAddress =null
        }

        if(emailAddress != null && this.cname != null) {
        /*
        var obj = this.mergeObjectList.filter(row => row.email === emailAddress);
        if (obj.length == 0) {*/
          var tempContact = new Object();
          tempContact.name = this.cname;
          tempContact.NSP_Work_email__c = emailAddress;
          this.mergeObjectList = [...this.mergeObjectList, tempContact]; 
          this.NSP_Contact__c = '';
          this.cemail = null;
          this.cname = '';
          this.template.querySelector('lightning-input[data-fname="emailAddress"]').value = null;
          this.template.querySelector('lightning-input-field[data-fname="NSP_Contact__c"]').value = '';
        /*}else{
            alert('This email address already exit');
        }*/
      } else{
            alert('Please enter valid Email / Contact');
      }
        // this.accContacts = this.accContacts.filter(row => row.Id !== this.currentConactId);
    }

    handleChange(event) {
        if (event.currentTarget.name == 'NSP_Survey_Type__c') {
            this.NSP_Survey_Type__c = event.currentTarget.value;
            if (this.NSP_Survey_Type__c === 'Exit') {
                this.showEndDate = "display:none;";
                this.endDateRequired= false;
                if(this.template.querySelector('lightning-input-field.NSP_End_Date__c') != null ){
                    this.template.querySelector('lightning-input-field.NSP_End_Date__c').value =null }
            } else {
                this.showEndDate = "display:block;";
                this.endDateRequired= true;
            }
        } else if (event.currentTarget.name == 'NSP_BargainingUnitEmployeesComplete__c') {
            this.NSP_BargainingUnitEmployeesComplete__c = event.currentTarget.value;
            if (this.NSP_BargainingUnitEmployeesComplete__c == "Yes") {
                this.showUnion = true;
            } else {
                this.showUnion = false;
            }
        }
    }


    handleAccChange(event) {
        this.NSP_Contact__c = '';
        if(event.target.value != null &&  event.target.value.length > 17){
            this.isOnloaded = false ;
            this.isOnloadCalled=true;
            this.cname = '';
            this.cemail = null;
            this.enableContact =false;
            this.clientId = event.target.value;
            // this.template.querySelector('lightning-record-edit-form.NSP_ClientName__c').submit(formObj);
            this.getContactRecord(this.clientId);
            this.getSurveyRegion(this.clientId);

            this.updateReportRequest(this.clientId);
            this.disableContact=false;
            }else{
                this.disableContact =true;
            }
        //this.retrieveContactRecords(event);
    }

    handleError(event){
        alert('in error');

        for(let i=0; this.mergeObjectList.length; i++) {
            if(this.mergeObjectList[i][i] != null && his.mergeObjectList[i][i] != undefined ){
                this.mergeObjectList[i][i]=i+1
            }
            
        }
    }
    
    /** 
    reArrangeOrder(arrayObject){
        let index = 0
        let newArrayObj = [];
        newArrayObj = arrayObject.map( item => {
        return { ...item}
        })

        return newArrayObj;
    }
 */
    
    get arrayToTextArea(){
     let tempStr = '';
        for (let i in this.mergeObjectList) {
            for (let key in this.mergeObjectList[i]) {
                if (tempStr == '' ||  tempStr.endsWith('\r\n')) {
                    tempStr = tempStr + this.mergeObjectList[i][key];
                } else {
                    tempStr = tempStr + " : " + this.mergeObjectList[i][key];
                    if(i<this.mergeObjectList.length-1){
                        tempStr=tempStr+',';
                    }
                }
            }
            tempStr = tempStr + '\r\n';
        }
        return tempStr; 
     }

     textAreaToArray( textArea ){
        let loadObjectList = [];
        let splitStrArray = textArea.split('\r\n');
        splitStrArray.forEach( key_val =>{
                this.attrs = key_val;
                let values = this.attrs.split(":");
                let obj = {};
                if(values != null && values != "" && values != " " && values[0] != null && values[1] != null ){
                    obj['name'] = values[0].trim();
                    obj['NSP_Work_email__c'] = values[1].trim().replace(',', '');
                }
                if( Object.keys(obj).length != 0){
                loadObjectList.push(obj);
                }
        })

        return loadObjectList;
    }


    /***
     
get arrayToTextArea(){
     let tempStr = '';
        for (let i in this.mergeObjectList) {
            for (let key in this.mergeObjectList[i]) {
                if (tempStr == '' ||  tempStr.endsWith('\r\n')) {
                    tempStr = tempStr + key + ": " + this.mergeObjectList[i][key];
                } else {
                    tempStr = tempStr + ',' + key + ": " + this.mergeObjectList[i][key];
                }

            }
            tempStr = tempStr + '\r\n';
        }
        return tempStr;
        
     }

    textAreaToArray( textArea ){
        let loadObjectList = [];
        let splitStrArray = textArea.split('\r\n');
        splitStrArray.forEach( key_val =>{
                this.attrs = key_val;
                let values = this.attrs.split(",");
                let obj = {};
                if(values != null && values != "" && values != " ")
                for(let i=0; i<values.length; i++) {
                    let keyValue = values[i].split(":");
                    obj[keyValue[0].trim()] = keyValue[1].trim();
                }
                console.log(obj);
                if( Object.keys(obj).length != 0){
                loadObjectList.push(obj);
                }
            console.log(key_val );
        })

        return loadObjectList;
    }


     */

    handleNext(){
        if(this.arrayToTextArea ==  null || this.arrayToTextArea == ''){
            this.showErroMsg ="display=''";
        }
    }


    handleSave(event) {
        this.isSaveClick=true;
        this.allowNext =false;
        this.template.querySelector('lightning-record-edit-form').submit();
    }

    handlelookupRecord(event){
        let selectedRecord = event.detail.recId;
        this.NSP_Contact__c=selectedRecord;
        if(this.NSP_Contact__c != null && this.NSP_Contact__c.length > 17){
            this.currentConactId =this.NSP_Contact__c;
            const conObj = this.accContacts.find(row => row.ContactId === this.currentConactId);
            this.cname = conObj.Contact.name;
            this.cemail = conObj.NSP_Work_Email__c;
          }else{
            this.cname = '';
            this.cemail = null;
            this.NSP_Contact__c=''; 
          }
    }
}