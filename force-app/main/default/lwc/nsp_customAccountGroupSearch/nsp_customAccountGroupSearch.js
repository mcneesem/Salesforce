import { LightningElement, api, wire, track } from 'lwc';
import { debounce } from 'c/nsp_utils';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';
import ACCOUNT_GROUP_OBJECT from '@salesforce/schema/NSP_Account_Group__c';

import TYPE_FIELD from '@salesforce/schema/NSP_Account_Group__c.NSP_Type__c';
import getAccGroupRecords from '@salesforce/apex/NSP_AccountGroupSelector.searchRecordsByFilters';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    { label: 'Account Group', fieldName: 'accountGroup', type: 'text', wrapText: true },
    { label: 'Group Type', fieldName: 'groupType', type: 'text', wrapText: true },
    { label: 'Account', fieldName: 'accountName', type: 'text', wrapText: true },
    { label: 'AIMS Client #', fieldName: 'NSP_AIMS_Client_ID__c', type: 'text', wrapText: true },
]
const EXCLUDED_PICKLIST_VALUES = ['Controlled Group', 'EEO', 'Renew & Review Together', 'WX Account Group']

export default class Nsp_customAccountGroupSearch extends LightningElement {
    @api selectedAccountGroupId;
    groupType;
    account;
    aimsClient;
    columns = COLUMNS;
    @track data = [];
    noResults;
    isLoaded = false;

    @wire(getObjectInfo, { objectApiName: ACCOUNT_GROUP_OBJECT })
    accountGroupInfo;

    get recordTypeId() {
        const rtis = this.accountGroupInfo.data.recordTypeInfos;
        return Object.keys(rtis).find(rti => rtis[rti].name === 'Master');
    }

    @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: TYPE_FIELD })
    typePicklistOptions;

    handleSearch() {
        this.isLoaded = !this.isLoaded;
        this.noResults = '';
        this.selectedAccountGroupId = null;
        const { account, aimsClient } = this;
        const searchConfig = JSON.stringify({
            groupType: this.defaultDropDown,
            account,
            aimsClient,
        });
        this.getResults(searchConfig);
    }

    getResults = debounce((searchConfig) => {
        getAccGroupRecords({ searchConfig })
            .then((results) => {
                this.isLoaded = false;
                this.data = results.map(record => {
                    let accountGroup = record.NSP_Group__r?.Name;
                    let groupType = record.NSP_Group__r?.NSP_Type__c;
                    let accountName = record.NSP_Member_Account__r?.Name;
                    let groupId = record.NSP_Group__c;
                    return { ...record, accountGroup, groupType, accountName, groupId }
                });
                if (!this.data?.length) {
                    this.isLoaded = false;
                    this.noResults = 'No Results Found';
                }
            }).catch((e) => { this.isLoaded = false; this.showNotification('Error', e?.body?.message, 'error'); });
    }, 100);

    handleChange(event) {
        const { value } = event.detail;
        this[event.target.dataset.name] = value;
    }

    get options() {
        return this.typePicklistOptions?.data?.values.filter(record =>
            !EXCLUDED_PICKLIST_VALUES.includes(record.label)
        )
    }

    get searchButton() {
        if (this.aimsClient) {
            return false
        } else if (this.account) {
            return false
        } else return true
    }

    handleSelect() {
        this.groupType = this.template.querySelector('select.slds-select')?.value;
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows
        this.selectedAccountGroupId = selectedRows && selectedRows[0]?.groupId;
    }

    get defaultDropDown() {
        return this.template.querySelector('select.slds-select').value;
    }

    @api
    validate() {
        if (this.selectedAccountGroupId) {
            return { isValid: true };
        } if (!this.selectedAccountGroupId && this.data.length > 0) {
            return {
                isValid: false,
                errorMessage: 'Select any Account Group to Proceed'
            };
        } if (!this.aimsClient || !this.account) {
            return {
                isValid: false,
                errorMessage: 'Provide an Account or an AIMS client#'
            };
        }
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(evt);
    }

}