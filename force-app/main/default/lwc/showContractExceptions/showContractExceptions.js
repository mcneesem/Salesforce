import { LightningElement, api, track, wire } from 'lwc';
import getExceptionList from '@salesforce/apex/NSP_ShowContractExceptionsController.getExceptionList';
import getURLTarget from '@salesforce/apex/NSP_ShowContractExceptionsController.getTargetURL';

export default class ShowContractExceptions extends LightningElement {
    @api accountId;
    @api contactId;
    @api recordId;
    @track urlTarget = '_blank'; 

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
            target: this.urlTarget},
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
            target: this.urlTarget},
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

    connectedCallback(){
        this.fetchURLTarget();
    }

    fetchURLTarget() {
        getURLTarget()
            .then(result => {
                this.urlTarget = result || '_blank'; // Default to '_self' if no result
            })
            .catch(error => {
                console.error('Error fetching URL target: ', error);
                this.urlTarget = '_blank'; // Fallback to '_blank' on error
            })
            .finally(() => {
                this.updateColumnAttributes(); // Ensure this is always called
            });
    }

    @wire(getExceptionList,  {  contactId: '$contactId' })
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

    updateColumnAttributes() {
        this.mainPagecolumns = this.mainPagecolumns.map(column => {
            if (column.fieldName === 'nameUrl') {
                return {
                    ...column,
                    typeAttributes: { label: { fieldName: 'Name' }, target: this.urlTarget }
                };
            }
            return column;
        });

        this.columns = this.columns.map(column => {
            if (column.fieldName === 'nameUrl') {
                return {
                    ...column,
                    typeAttributes: { label: { fieldName: 'Name' }, target: this.urlTarget }
                };
            }
            return column;
        });
    }

    closeModal(){
        this.showContractModal = false;
        
    }
    handleShowModal(event){
        this.showContractModal = true;
    }

}