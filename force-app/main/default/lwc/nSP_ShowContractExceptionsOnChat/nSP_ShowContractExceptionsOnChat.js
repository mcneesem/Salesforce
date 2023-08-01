import { LightningElement, api, track, wire } from 'lwc';
import ACCOUNT_FIELD from '@salesforce/schema/LiveChatTranscript.ContactId';
import getExceptionListFromContact from '@salesforce/apex/NSP_ShowContractExceptionsController.getExceptionListFromContact';
import { getRecord  } from 'lightning/uiRecordApi';

export default class ShowContractExceptions extends LightningElement {
    @api recordId;
    @api acctId;
    contact;
    exceptions = [];
    showContractModal = false;
    showContractButton = false;
    totalExceptions = 0;

    @track mainPagecolumns = [
        {
            label: 'Exception #',
            fieldName: 'nameUrl',
            type: 'url',
            typeAttributes: {label: { fieldName: 'Name' }, 
            target: '_blank'},
            sortable: true
        },
        {
            label: 'Notes',
            fieldName: 'Notes',
            type: 'text',
            sortable: true
        },
        {
            label: 'Start Date',
            fieldName: 'StartDate',
            type: 'date',
            sortable: true
        },
        {
            label: 'Expiration Date',
            fieldName: 'EndDate',
            type: 'date',
            sortable: true
        },
        
    ];

   @track columns = [
        {
            label: 'Exception #',
            fieldName: 'nameUrl',
            type: 'url',
            typeAttributes: {label: { fieldName: 'Name' }, 
            target: '_blank'},
            sortable: true
        },
        {
            label: 'Notes',
            fieldName: 'Notes',
            type: 'text',
            sortable: true,
            wrapText: true,
            initialWidth: 300
        },
        {
            label: 'Client',
            fieldName: 'Client',
            type: 'text',
            sortable: true
        },
        {
            label: 'AIMS Client #',
            fieldName: 'AIMS',
            type: 'text',
            sortable: true
        },
        {
            label: 'Start Date',
            fieldName: 'StartDate',
            type: 'date',
            sortable: true
        },
        {
            label: 'Expiration Date',
            fieldName: 'EndDate',
            type: 'date',
            sortable: true
        },
        {
            label: 'Created By',
            fieldName: 'CreatedBy',
            type: 'text',
            sortable: true
        },
        {
            label: 'Create Date',
            fieldName: 'CreateDate',
            type: 'date',
            sortable: true
        },
        {
            label: 'Updated By',
            fieldName: 'UpdatedBy',
            type: 'text',
            sortable: true
        },
        {
            label: 'Update Date',
            fieldName: 'UpdateDate',
            type: 'date',
            sortable: true
        },
    ];

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_FIELD] })
    wiredRecord({ error, data }) {
        if (error) {
            let message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
        } else if (data) {
            this.contact = data;
            this.acctId = this.contact.fields.ContactId.value;
        }
    }

    connectedCallback(){
       
        // get questions for separation  for now there's only one type 
    }

   @wire(getExceptionListFromContact,  {  conId: '$acctId' })
    wiredQuestions({ error, data }) {
        if (data) {  
            if (data.length >0){
                this.totalExceptions = data.length;
                data.forEach(ex => {
                    let clientExcept = {};
                    clientExcept.Id = ex.Id;
                    clientExcept.Name = ex.Name;
                    clientExcept.nameUrl = '/'+ex.Id;
                    clientExcept.Notes = ex.NSP_Exception_Notes__c;
                    clientExcept.Client = ex.NSP_Account__r.Name;
                    clientExcept.AIMS = ex.NSP_Account__r.NSP_AIMS_Client__c;
                    clientExcept.StartDate = ex.NSP_Start_Date__c;
                    clientExcept.EndDate = ex.NSP_End_Date__c;
                    clientExcept.CreatedBy = ex.CreatedBy.Name;
                    clientExcept.UpdatedBy = ex.LastModifiedBy.Name;
                    clientExcept.UpdateDate = ex.LastModifiedDate;
                    clientExcept.CreateDate = ex.CreatedDate;
                    this.exceptions.push(clientExcept);
                });
                this.showContractModal=true;
                this.showContractButton = true;
            }
            this.error = undefined;
        } else if (error) {
            let message;
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
        }
    }

    closeModal(){
        this.showContractModal = false;
        
    }
    handleShowModal(event){
        this.showContractModal = true;
    }

}