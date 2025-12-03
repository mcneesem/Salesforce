import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
// Import fields
import CATEGORY_FIELD from '@salesforce/schema/Case.NSP_Category__c';
import SUBCATEGORY_FIELD from '@salesforce/schema/Case.NSP_SubCategory__c';
import DETAIL_FIELD from '@salesforce/schema/Case.NSP_Detail__c';
import VERSION_FIELD from '@salesforce/schema/Case.NSP_Version__c';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/Case.RecordTypeId';
import ID_FIELD from '@salesforce/schema/Case.Id';
import Toast from 'lightning/toast';

export default class Nsp_casecategorycmp extends LightningElement {
    // HARD CODED
    label = {
        header : "Case Category/Subcategory/Detail",
        editCase : "Edit",
        category : "Category",
        subcategory : "Subcategory",
        detail : "Detail",
        version : "Version",
        viewAll : "View All",
        reset : "Role Favorites",
        save : "Save",
        cancel : "Cancel"
    }

    @api recordId;
    @api objectApiName = 'Case';

    isLoading = false;
    @track oCase = {}; // Case data
    originalCase = {} // store original case data
    showError = false; // Flag to show validation error

    showCaseDetail = false;
    showCaseVersion = false;

    // Wire the Case record
    @wire(getRecord, {
        recordId: '$recordId',
        fields: [CATEGORY_FIELD, SUBCATEGORY_FIELD, DETAIL_FIELD, VERSION_FIELD, RECORD_TYPE_ID_FIELD]
    })
    wiredCase({ error, data }) {
        if (data) {
            this.oCase = {
                Id: this.recordId,
                RecordTypeId: data.fields.RecordTypeId? data.fields.RecordTypeId.value : null,
                NSP_Category__c: data.fields.NSP_Category__c.value,
                NSP_SubCategory__c: data.fields.NSP_SubCategory__c.value,
                NSP_Detail__c: data.fields.NSP_Detail__c.value,
                NSP_Version__c: data.fields.NSP_Version__c.value
            };

            this.showCaseDetail = Boolean(this.oCase.NSP_Detail__c);
            this.showCaseVersion = Boolean(this.oCase.NSP_Version__c);

            this.originalCase = { ...this.oCase };
            this.isLoading = false;

        } else if (error) {
            this.handleError(error);
        }
    }

    isEditing = false; // Start in view mode

    get view() {
        return !this.isEditing;
    }

    // Event handlers
    editCase() {
        this.isEditing = true;
        this.showError = false; // Reset validation on edit
    }

    cancel() {
        this.isEditing = false;
        this.oCase = { ...this.originalCase };
        this.showCaseDetail = Boolean(this.oCase.NSP_Detail__c);
        this.showCaseVersion = Boolean(this.oCase.NSP_Version__c);
        this.showError = false; // Reset validation on cancel
    }

    handleSelectionChange(event) {
        const { category, subCategory, detail, version, detailOptions, versionOptions } = event.detail;

        const prevCategory = this.oCase.NSP_Category__c;
        // set Category from event
        this.oCase.NSP_Category__c = category;

        // when Category value actually changes, clear SubCategory and Detail
        if (prevCategory !== category) {
            this.oCase.NSP_SubCategory__c = null;
            this.oCase.NSP_Detail__c = null;
        } else {
            // Preserve incoming selections when Category did not change
            this.oCase.NSP_SubCategory__c = subCategory;
            this.oCase.NSP_Detail__c = detail;
        }

        if (detailOptions.length > 0) {
            this.showCaseDetail = true;
        }
        if(versionOptions.length > 0) {
            this.showCaseVersion = true;
        }
    }

    updateCase() {
        // Prevent save if SubCategory is null/empty while Category is set
        const category = this.oCase.NSP_Category__c;
        const subCategory = this.oCase.NSP_SubCategory__c;

        // Show validation error if Category is set but SubCategory is unset
        if (category && (subCategory === null || subCategory === undefined || subCategory === '')) {
            this.showError = true;
            return; // Block save
        }
        this.isLoading = true;

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[CATEGORY_FIELD.fieldApiName] = this.oCase.NSP_Category__c;
        fields[SUBCATEGORY_FIELD.fieldApiName] = this.oCase.NSP_SubCategory__c;
        fields[DETAIL_FIELD.fieldApiName] = this.oCase.NSP_Detail__c;
        fields[VERSION_FIELD.fieldApiName] = this.oCase.NSP_Version__c;


        const recordInput = { fields };
        updateRecord(recordInput)
            .then(() => {
                this.isEditing = false;
                this.isLoading = false;
            })
            .catch(error => {
                this.handleError(error);
            });
    }

    handleError(error) {
        // Handle string errors by converting to object
        if (typeof error === 'string') {
            error = { message: error };
        }
        Toast.show({
            message: error,
            mode: 'sticky',
            variant: 'error'
        }, this);
    }
}