import { LightningElement, wire,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled }  from 'lightning/empApi';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord } from 'lightning/uiRecordApi';
import PROJ_OBJ from "@salesforce/schema/pse__Proj__c";

const PROJECTFIELDS = [
    'pse__Proj__c.pse__Project_Status__c'
];
export default class Nps_CreateServicePlanProjectOnClosure extends LightningElement {
@api recordId;
subscription = {};
@api channelName = '/event/PlatfromEventOne__e';
projectStatus = null;

 // Initializes the component
 connectedCallback() {   
    // Register error listener     
  //  this.registerErrorListener();
  //  this.handleSubscribe();
}

//
@wire(getRecord, { recordId: '$recordId', fields: PROJECTFIELDS })
getProjectDetails({error, data}){
    if(data){
        if(this.projectStatus == null ){
        this. projectStatus = data.fields.pse__Project_Status__c.value;
        }
        else{
        if ( data.fields.pse__Project_Status__c.value == 'Close/Lost' && data.fields.pse__Project_Status__c.value != this.projectStatus ){
                this.handleShowModal();
            }else{
                this. projectStatus = data.fields.pse__Project_Status__c.value;
            }
        }
    }else if(error){
        this.error = error;
    }
}


// Handles subscribe button click
handleSubscribe() {
    // Callback invoked whenever a new event message is received
    const thisReference = this;
    const messageCallback = function(response) {
        
        var obj = JSON.parse(JSON.stringify(response));
        const evt = new ShowToastEvent({
            title: 'Congrats!!',
            message: obj.data.payload.Message__c,
            variant: 'success',
        });

        thisReference.dispatchEvent(evt);
        // Response contains the payload of the new message received
    };

    // Invoke subscribe method of empApi. Pass reference to messageCallback
    subscribe(this.channelName, -1, messageCallback).then(response => {
        // Response contains the subscription information on subscribe call
        this.subscription = response;
    });
}

/* In case you want to unsubscribe use this
// Handles unsubscribe button click
handleUnsubscribe() {

    // Invoke unsubscribe method of empApi
    unsubscribe(this.subscription, response => {
        // Response is true for successful unsubscribe
    });
}
*/

registerErrorListener() {
    // Invoke onError empApi method
    onError(error => {
        // Error contains the server-side error
    });
}

handleShowModal() {
    const modal = this.template.querySelector('c-modal');
    modal.show();
}

}