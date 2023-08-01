import { LightningElement ,api, track} from 'lwc';
import getClientGoalsList from '@salesforce/apex/NSP_ClientGoalsController.getClientGoalsList';

export default class LightningDatatableLWCExample extends LightningElement {
    refreshTable;
    @track columns = [{
            label: 'Client Goal name',
            fieldName: 'Name',
            type: 'text',
            sortable: true
        },
        {
            label: 'Goal Type',
            fieldName: 'NSP_Goal_Type__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Goal Details',
            fieldName: 'NSP_Goal_Details__c',
            type: 'longTextArea',
            sortable: true
        },
        {
            label: 'Status',
            fieldName: 'NSP_Status__c',
            type: 'text',
            sortable: true
        },
       
    ];
    @api recordId;
    @track error;
    @track clientGoalsList ;
    
    
   
    connectedCallback() {
        getClientGoalsList({ rsapId: this.recordId })
            .then(result => {
                this.clientGoalsList = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.clientGoalsList = undefined;
            });
    }
   
}

    
