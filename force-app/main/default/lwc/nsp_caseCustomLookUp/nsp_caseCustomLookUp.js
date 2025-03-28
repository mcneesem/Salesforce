import { LightningElement, api, wire } from 'lwc';
import fetchLookupData from '@salesforce/apex/NSP_CustomLookUpController.fetchLookupData';
import fetchDefaultRecord from '@salesforce/apex/NSP_CustomLookUpController.fetchDefaultRecord';

const DELAY = 300;

export default class nsp_contactCustomLookUp extends LightningElement {
    @api label = '';
    @api placeholder = 'search Contacts here.....';
    @api iconName = 'standard:contact';
    @api sObjectApiName = 'Contact';
    _defaultRecordId = '';
    @api caseAccRecId = '';
    @api createdCaseRecId = '';
    @api selectedContactRecId = '';
    @api defaultContactRecId = '';
    @api parentId = '';
    @api showUserOrQueue = false;
    @api element = "8";
    @api isRequired = false;
    @api disabled = false;
    @api error;
    userOrQueue = 'User';

    lstResult = []; // to store list of returned records   
    hasRecords = true;
    @api searchKey=''; // to store input field value    
    isSearchLoading = false; // to control loading spinner  
    delayTimeout;
    selectedRecord = {}; // to store selected lookup record in object formate 
    rendered = false;

    @api
    get defaultRecordId() {
        return this._defaultRecordId;
    }
    set defaultRecordId(value) {
        if (value !== this._defaultRecordId) {
            this._defaultRecordId = value;
            if (value) {
                this.getDefaultRecord(value, this.sObjectApiName, this.parentId);
            } else if (this.rendered) {
                this.handleRemove(new Event('default'));
            }
        }
    }

    connectedCallback() {
        if (this.defaultRecordId) {
            this.getDefaultRecord(this.defaultRecordId, this.sObjectApiName, this.parentId);
        }
    }

    renderedCallback() {
        this.rendered = true;
    }

    handleChange(event) {
        this.sObjectApiName = event.detail.value;
        this.handleRemove(event);
        if (this.sObjectApiName === 'User') {
            this.iconName = "standard:user";
        } else {
            this.iconName = "standard:queue";
        }
    }

    @api
    getDefaultRecord(defaultRecordId, sObjectApiName, parentId) {
        fetchDefaultRecord({ recordId: defaultRecordId, sObjectApiName: sObjectApiName, parentId: parentId })
            .then((result) => {
                if (result) {
                    this.selectRecord({ ...result });
                    this.error = undefined;
                }
            })
            .catch((error) => {
                this.error = error;
                this.selectedRecord = {};
            });
    }

    @wire(fetchLookupData, { searchKey: '$searchKey', sObjectApiName: '$sObjectApiName', accId: '$caseAccRecId', parentId: '$parentId' })
    searchResult({ data, error }) {
        this.isSearchLoading = false;
        if (data) {
            this.hasRecords = data.length === 0 ? false : true;
            this.lstResult = JSON.parse(JSON.stringify(data));
        } else if (error) {
            this.error = error;
        }
    }

    handleKeyChange(event) {
        if (!this.disabled) {
            this.isSearchLoading = true;
            window.clearTimeout(this.delayTimeout);
            const searchKey = event.target.value;
            this.delayTimeout = setTimeout(() => {
                this.searchKey = searchKey;
            }, DELAY);
        }
    }

    toggleResult(event) {
        if (!this.disabled) {
            const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
            if (lookupInputContainer) {
                const clsList = lookupInputContainer.classList;
                const whichEvent = event.target.getAttribute('data-source');
                switch (whichEvent) {
                    case 'searchInputField':
                        clsList.add('slds-is-open');
                        break;
                    case 'lookupContainer':
                        clsList.remove('slds-is-open');
                        break;
                }
            }
        }
    }

    handleRemove(event) {
        event.preventDefault();
        this.searchKey = '';
        this.selectedRecord = {};
        this.selectedContactRecId = '';
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        const pillDiv = this.template.querySelector('.pillDiv');
        if (searchBoxWrapper && pillDiv) {
            searchBoxWrapper.classList.remove('slds-hide');
            searchBoxWrapper.classList.add('slds-show');
            pillDiv.classList.remove('slds-show');
            pillDiv.classList.add('slds-hide');
        }
        this.lookupUpdatehandler('', this.sObjectApiName);
    }

    handelSelectedRecord(event) {
        if (!this.disabled) {
            const recId = event.target.getAttribute('data-recid');
            this.selectRecord(this.lstResult.find(data => data.Id === recId));
        }
    }

    selectRecord(selectedRecord) {
        this.selectedRecord = selectedRecord;
        this.selectedContactRecId = selectedRecord.Id;
        this.lookupUpdatehandler(selectedRecord.Id, this.sObjectApiName);
        this.handelSelectRecordHelper();
    }

    handelSelectRecordHelper() {
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
        const pillDiv = this.template.querySelector('.pillDiv');
        if (lookupInputContainer && searchBoxWrapper && pillDiv) {
            lookupInputContainer.classList.remove('slds-is-open');
            searchBoxWrapper.classList.remove('slds-show');
            searchBoxWrapper.classList.add('slds-hide');
            pillDiv.classList.remove('slds-hide');
            pillDiv.classList.add('slds-show');
        }
    }

    lookupUpdatehandler(value, sObjectApiName) {
        const oEvent = new CustomEvent('lookupupdate', {
            detail: { recId: value, sObjectApiName: sObjectApiName }
        });
        this.dispatchEvent(oEvent);
    }

    get options() {
        return [
            { label: 'User', value: 'User' },
            { label: 'Queue', value: 'Group' }
        ];
    }

    get showLabel() {
        return this.label && this.label.length > 0;
    }

    get controlWidth() {
        return this.label && this.label.length > 0 ? this.element : 12;
    }
}