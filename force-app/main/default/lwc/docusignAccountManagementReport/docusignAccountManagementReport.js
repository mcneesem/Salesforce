import { LightningElement, api,wire } from 'lwc';  
import { CloseActionScreenEvent } from 'lightning/actions';
import getDocusignURL from '@salesforce/apex/DocusignAccountManagementReport.getDocusignURL';
import getPrimaryAccount from '@salesforce/apex/DocusignAccountManagementReport.getPrimaryAccount';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = ['Account.Name'];
export default class DocusignAccountManagementReport extends LightningElement {
    @api recordId; // This will hold the current Account record ID  
    accountName; // To hold the Account Name  
    accountId;  
    primaryAccountId;  
    clmBaseUrl;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
        if (data) {
            this.accountName = data.fields.Name.value;
        }else if(error){
            this.error = error;
        }
    }

    @wire(getDocusignURL)  
    getCustomSettingValues({ error, data }) {  
        if (data) {  
            this.accountId = data.Docusign_Account_Id__c;  
            this.clmBaseUrl = data.CLM_Base_URL__c;  
        }else if(error) {
            this.showToast('Error', error.message, 'error');
        }
    } 

    handleClientOnlyClick() {  
        if (this.clmBaseUrl != null &&  this.accountId != null) {  
            const url = this.constructDocusignURL(this.clmBaseUrl,this.accountId, 'Account Management Report Client Only', this.recordId, this.accountName);

            window.open(url, '_blank');
            this.dispatchEvent(new CloseActionScreenEvent());  
        }else {
            this.showToast('Error', 'Invalid URL', 'error');
        }
    }  
    
    handleRenewalProbabilityClick() {  
        this.openPrimaryAccount(); 
    } 

    openPrimaryAccount(){
        getPrimaryAccount({ accountId: this.recordId })  
            .then(result => {
                if(result != null && this.clmBaseUrl != null && this.accountId != null){
                    // Handle success  
                    const keys = Object.keys(result);
                    if(keys != null){
                        this.primaryAccountId = keys[0];
                    }
                    this.accountName = result[this.primaryAccountId];
                    const url = this.constructDocusignURL(this.clmBaseUrl,this.accountId, 'Account Management Report', this.primaryAccountId, this.accountName);

                    window.open(url, '_blank');
                    this.dispatchEvent(new CloseActionScreenEvent());  
                }else{
                    this.showToast('Error', 'No Primary Account Found', 'error');
                }
            })  
            .catch((error) => {
                this.error = error;
                this.showToast('Error', error.message, 'error');
            });
    }

    constructDocusignURL(clmBaseUrl,docuSignId,accountType,accountId,accountName){
        let url = '';
        if(clmBaseUrl != null && docuSignId != null && accountType != null && accountId != null && accountName != null) {
            url = 'https://'+`${clmBaseUrl}/atlas/doclauncher/OneClickDocGen?aid=${docuSignId}&config=${accountType}&eos[0].Id=${encodeURIComponent(accountId)}&eos[0].System=Salesforce&eos[0].Type=Account&eos[0].Name=${encodeURIComponent(accountName)}&eos[0].ScmPath=/Salesforce/Account/`; 
        } else {
            this.showToast('Error', 'Invalid URL', 'error');
        }
        return url;
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