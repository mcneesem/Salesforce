import { LightningElement,api, track, wire } from 'lwc';
import releatedFiles from '@salesforce/apex/NSP_FileUploadMultiController.releatedFiles';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { BUTTON_CONFIG, DELETE_MESSAGE } from './constants';
import { getRecord } from 'lightning/uiRecordApi';
import hasIpPermission from '@salesforce/customPermission/NSP_Implementation_Profile_permission_set';

const IP_FIELDS = [
    'Implementation_Profile__c.NSP_Inactive__c'
]

export default class FileUpload extends NavigationMixin(LightningElement) {
	@api recordId;
	wiredRelatedFileResult;
	relatedfile;
	error;
	@track filesData = [];
	ipRec = {};

	@api getFormValues() {
		return {};
	}
	@api isDeleteClicked = false;
	@api selectedFileId = '';
	@api showSpinner = false;


	showToast(title, variant, message) {
		const event = new ShowToastEvent({
			title: title,
			message: message,
			variant: variant
		});
		this.dispatchEvent(event);
	}

	@wire(getRecord, { recordId: '$recordId', fields: IP_FIELDS })
	getIpDetails(value){
		const { data,error } = value;		
		if(data){
			let ipRec = {
				'NSP_Inactive__c' : data.fields.NSP_Inactive__c.value
			}
			this.ipRec = ipRec;
		}else if(error){
			this.error = error;
		}
	}

	getBaseUrl() {
		return 'https://' + location.host + '/';
	}

	connectedCallback() {
		this.handleFilelist();
		this.baseUrl = this.getBaseUrl();
	}
	handleUploadFinished(event) {
		let strFileNames = '';
		const uploadedFiles = event.detail.files;

		if (uploadedFiles.length > 0) {
			for (let i = 0; i < uploadedFiles.length; i++) {
				strFileNames += uploadedFiles[i].name + ', ';
			}
			this.showToast('Success!!', 'success', strFileNames + ' Files uploaded Successfully!!!');
			this.handleFilelist();
		}
	}

	handleFilelist() {
		releatedFiles({
				ipRecordId: this.recordId
			})
			.then((result) => {
				this.relatedfile = result;
				this.error = undefined;
			})
			.catch((error) => {
				this.error = error;
				this.relatedfile = undefined;
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error!!',
						message: error.message,
						variant: 'error',
					}),
				);
			});
	}

	downloadFile(event) {
		const recordId = event.target.dataset.recordid;
		const downloadUrl = this.baseUrl + 'sfc/servlet.shepherd/document/download/' + recordId;
		this[NavigationMixin.Navigate]({
			type: 'standard__webPage',
			attributes: {
				url: downloadUrl
			}
		}, false);
	}

	handleDeleteRelatedFile(event) {
		this.isDeleteClicked = true;
		this.selectedFileId = event.target.dataset.recordid;
	}

	handleButtonClick(event) {
		if (event.detail === 'cancel') {
			this.isDeleteClicked = false;
		}
		if (event.detail === 'Yes') {
			this.showSpinner = true; 
			this.deleteRelatedFile(event);
			this.isDeleteClicked = false;
		}
	}

	deleteRelatedFile(event) {
		deleteRecord(this.selectedFileId)
			.then(() => {
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Success',
						message: 'File deleted',
						variant: 'success'
					})
				);
				this.handleFilelist();
				this.showSpinner = false;
				return refreshApex(this.relatedfile);

			})
			.catch((error) => {
				this.showSpinner = false;
				this.dispatchEvent(
					new ShowToastEvent({
						title: 'Error deleting record',
						message: error,
						variant: 'error'
					})
				);
			});
	}

	get buttonConfig() {
		return BUTTON_CONFIG;
	}

	get deleteMessage() {
		return DELETE_MESSAGE;
	}

	get isHavingPermission(){
		return hasIpPermission && !this.ipRec.NSP_Inactive__c;
	}

}