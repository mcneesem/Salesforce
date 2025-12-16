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

    // Display save button when mandatory fields are not empty
    get isUpdateCaseAllowed() {
        return ( this.oCase && this.oCase.NSP_Category__c && this.oCase.NSP_SubCategory__c );
    }

    get isSaveDisabled() {
        return !this.isUpdateCaseAllowed;
    }

    // Event handlers
    editCase() {
        this.isEditing = true;
    }

    cancel() {
        this.isEditing = false;
        this.oCase = { ...this.originalCase };
        this.showCaseDetail = Boolean(this.oCase.NSP_Detail__c);
        this.showCaseVersion = Boolean(this.oCase.NSP_Version__c);
    }

    handleSelectionChange( event ) {
        let {
            category ,
            subCategory ,
            detail ,
            version ,
            detailOptions ,
            versionOptions
        } = event.detail;
        const prevCategory = this.oCase.NSP_Category__c;
        // when Category value actually changes, clear SubCategory, Detail, and Version...
        if ( prevCategory !== category ) {
            subCategory = null;
            detail = null;
            version = null;
        }
        this.oCase.NSP_Category__c = category;
        this.oCase.NSP_SubCategory__c = subCategory;
        this.oCase.NSP_Detail__c = detail;
        this.oCase.NSP_Version__c = version;
        if ( detailOptions?.length > 0 ) {
            this.showCaseDetail = true;
        }
        if ( versionOptions?.length > 0 ) {
            this.showCaseVersion = true;
        }
    }

    updateCase() {
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
        Toast.show({
            message: error,
            mode: 'sticky',
            variant: 'error'
        }, this);
    }
}