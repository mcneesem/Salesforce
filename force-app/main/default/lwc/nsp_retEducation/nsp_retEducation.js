import {LightningElement, track, wire, api } from 'lwc';

// importing apex class methods
import getRETEducationOverview from '@salesforce/apex/RETEducationController.getRETEducationOverview';
import UpdateRETRecords from '@salesforce/apex/RETEducationController.updateRETRecords';

// importing to show toast notifictions
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

// importing to refresh the apex if any record changes the datas
import {refreshApex} from '@salesforce/apex';

export default class nsp_RETEducation extends LightningElement { 
    // reactive variable
    @track data;    
    @track record = [];
    @track noData = false;
    @track currentRecordId;
    @track hasRecord = false;
    @track showLoadingSpinner = false;
    @track FormValues = {};
    @track showWarning=false;
    @track noDataCheck = true;

    @api recordId;

   // non-reactive variables      
    objectApiName = 'AssetRETEducationAssociation__c';
    error;

    @wire(getRETEducationOverview, {recordID: '$recordId'})
    getRETEducationOverview(result) {      
        this.FormValues = result;        
        if (result.data) {
            this.FormValues = result.data;                     
            this.error = undefined;
           
            if(Object.keys(this.FormValues).length !== 0 ) 
            {           
             this.noDataCheck = false;
            }       
        } else if (result.error) {
            this.FormValues = result.error;
            this.data = undefined;
        } 
    }   

    // handling record edit form submit
    handleFormSubmit(event) {          
    event.preventDefault();  
   
    //if(this.FormValues["data"] === null || this.FormValues["data"] === undefined || this.FormValues["data"] === "") 
    if(this.FormValues.Id === undefined) 
    {       
        let fields = event.detail.fields;
        fields['Asset__c'] = this.recordId;
        delete fields["AIMs__c"];       
        this.template.querySelector('lightning-record-edit-form').submit(fields);
        this.showToast();               
        setTimeout(() => {
            refreshApex(this.FormValues);      
          }, 1000);             
    }
    else{
        let fields = event.detail.fields; 
        UpdateRETRecords({
            'RETEducation' : fields
        })
            .then(result => {
                 this.dispatchEvent(new ShowToastEvent({
            title: 'Success!!',
            message:' RET Education record Updated Successfully!',
            variant: 'success'
        }),);
         refreshApex(this.FormValues);
            })
            .catch(error => {
                // TODO Error handling
            });
    }
    }

    handleReset() {       
        const inputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );  
       let  dataAsset = this.template.querySelector(
            'lightning-input-field[data-asset="asset"]'
        ).value;              
            if (inputFields) {            
            inputFields.forEach(field => {                            
                field.reset();
            });           
        }
        this.template.querySelector(
            'lightning-input-field[data-asset="asset"]'
        ).value =   dataAsset;  
     }

    // handling record edit form submit   
    showToast()
    {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success!!',
            message:' RET Education created Successfully!',
            variant: 'success'
        }),);       
    }    
}