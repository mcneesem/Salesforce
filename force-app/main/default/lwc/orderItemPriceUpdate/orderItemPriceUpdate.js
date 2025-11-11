import { LightningElement, track } from 'lwc';
import startBatchJob from '@salesforce/apex/OrderItemBatchController.startBatchJob';
import checkPermission from '@salesforce/apex/OrderItemBatchController.checkPermission';
import executeBatch from '@salesforce/apex/GeneratePriceIncreasesBatch.executeBatch';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { subscribe, unsubscribe } from 'lightning/empApi';

export default class OrderItemPriceUpdate extends LightningElement {
    @track stage = '';
    @track spinner = false;
    @track isProcessing = false;
    isGenerating = false;
    successCounts = {};  // To store success counts for each object
    failureCounts = {};  // To store failure counts for each object
    subscription = {};
    channelName = '/event/PriceUpdateBatchJobStatus__e';

    handleGenerate() {
        this.isGenerating  = true;
        executeBatch().then(result => {
            this.showToast(
                "Generating Price Increase Records" ,
                result ,
                "success"
            );
        }).catch(error => {
            this.showToast(
                "Error Generating Price Increase Records" ,
                error.body.message ,
                "error"
            );
        });
    }

    handleKeySonar() {
        // only created to appease sonar...
    }

    //handle click of button
    handleClick() {
        if(this.isProcessing) return;
        this.isProcessing = true; //hide button while processing

        //check user permission
        checkPermission().then(result => {
            if(result){ //user has permission
                this.stage = '-> User Permission Checked';
                startBatchJob().then(() => { //call the batch
                    this.stage = '-> Batch Called';
                    this.handleSubscribe(); //subscribe to platform event
                }).catch(error => {
                    this.showToast("Error",error.body.message,"error");
                });
            }else{
                this.stage = '-> User Permission Denied';
                this.isProcessing = false;
                this.showToast("Access Denied", "User does not have permission to run batch job","error");
            }
        }).catch(error => {
            console.log(error);
        });
    }

    proxyToObj(obj){ //convert platform event response to Json
        return JSON.parse(JSON.stringify(obj));
    }

    //subscribe to the platform event
    handleSubscribe() {
        const messageCallback = (response) => {

            // Response contains the payload of the new message received
            let obj = JSON.parse(JSON.stringify(response));
            if(obj.data.payload.Status__c === 'Running'){
                this.spinner = true;
            }
            // extract PE info from response
            this.stage = '-> Batch ' + obj.data.payload.Status__c;
            this.successCounts = {
                SubscriptionCSRate: obj.data.payload.SubscriptionCSRateSuccess__c,
                Subscription: obj.data.payload.SubscriptionSuccess__c,
                OrderItemCSRate: obj.data.payload.OrderItemCSRateSuccess__c,
                OrderItem: obj.data.payload.OrderItemSuccess__c
            };

            this.failureCounts = {
                SubscriptionCSRate: obj.data.payload.SubscriptionCSRateFail__c,
                Subscription: obj.data.payload.SubscriptionFail__c,
                OrderItemCSRate: obj.data.payload.OrderItemCSRateFail__c,
                OrderItem: obj.data.payload.OrderItemFail__c
            };

            if(obj.data.payload.Status__c === 'Executed'){
                this.spinner = false;
                this.handleUnsubscribe();// unsubscribe from PE
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            // Response contains the subscription information on subscribe call
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
        });
    }

    get hasSuccessCounts(){
        return Object.values(this.successCounts).some(
            value => value > 0);
    }

    get hasFailureCounts(){
        return Object.values(this.failureCounts).some(
            value => value > 0);
    }

    get hasResults(){
        return Object.values(this.successCounts).some(value => value > 0)
        || Object.values(this.failureCounts).some(value => value > 0);
    }

    showToast(title, message, variant){
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

}
//