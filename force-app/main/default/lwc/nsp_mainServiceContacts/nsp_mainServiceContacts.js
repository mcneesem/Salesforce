import { LightningElement, wire, api } from 'lwc';
import getContactRollUpRecords from '@salesforce/apex/NSP_ContactRollupController.getContactRollUpRecords';
import { NavigationMixin } from "lightning/navigation";
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import { CurrentPageReference } from 'lightning/navigation';

import ACR_OBJECT from '@salesforce/schema/AccountContactRelation';
import SUPPORTROLE_FIELD from '@salesforce/schema/AccountContactRelation.NSP_Support_Role__c';
import SERVICEROLE_FIELD from '@salesforce/schema/AccountContactRelation.NSP_Service_Roles__c';
import HRSCALECLIENTROLE_FIELD from '@salesforce/schema/AccountContactRelation.HRScale_Client_Roles__c'; // Added
import Client_Communication_Contact_FIELD from '@salesforce/schema/AccountContactRelation.Client_Communication_Contact__c';

import SITESUP_FIELD from '@salesforce/schema/NSP_Sub_Client_Contact__c.NSP_On_Site_Supervisor__c';
import PAYROLLCON_FIELD from '@salesforce/schema/NSP_Sub_Client_Contact__c.NSP_Payroll_Contact__c';
import CLIENTADMIN_FIELD from '@salesforce/schema/NSP_Sub_Client_Contact__c.NSP_Client_Leave_Administrator__c';
import WCCONTACT_FIELD from '@salesforce/schema/NSP_Sub_Client_Contact__c.NSP_WC_Contact__c';
import HRCONTACT_FIELD from '@salesforce/schema/NSP_Sub_Client_Contact__c.NSP_HR_Contact__c';
import BENIFIT_FIELD from '@salesforce/schema/NSP_Sub_Client_Contact__c.NSP_Benefits_Contact__c';
import BACKGROUND_FIELD from '@salesforce/schema/NSP_Sub_Client_Contact__c.NSP_Background_Contact__c';
import UNEMPLOYMENT_FIELD from '@salesforce/schema/NSP_Sub_Client_Contact__c.NSP_Unemployment_Contact__c';



const COLUMNS = [
    { label: 'All Roles', type: 'text', fieldName: 'allRoles', wrapText: true, },
    {
        label: 'Contact Name',
        type: 'customContactName',
        wrapText: true,
        typeAttributes: {
            contact: { fieldName: 'contact' },
            contactName: { fieldName: 'contactName' },
        },
    },
    {
        label: 'Preferred Name',
        type: 'customPreferredName',
        wrapText: true,
        typeAttributes: {
            contact: { fieldName: 'contact' },

        },
    },
    { label: 'Job Title', type: 'text', fieldName: 'jobTitle', wrapText: false, },
    { label: 'Employee Status', type: 'text', fieldName: 'employeeStatus', wrapText: true, },
    { label: 'Work Phone', type: 'text', fieldName: 'workPhone', wrapText: true, },
    { label: 'Work Email', type: 'text', fieldName: 'workEmail', wrapText: true, },
    {
        label: 'Sub Client',
        type: 'customSubClients',
        wrapText: true,
        typeAttributes: {
            subClients: { fieldName: 'subClients' },
        },
    },
    {
        label: 'Account',
        type: 'customAccountName',
        wrapText: true,
        typeAttributes: {
            account: { fieldName: 'account' },
        },
    }
];

export default class Nsp_mainServiceContacts extends NavigationMixin(LightningElement) {
    columns = COLUMNS;
    @api recordId;
    @api fullView = false;
    data = [];
    error;
    offSetCount = 0; // offSetCount to send to apex to get the subsequent result. 0 in offSetCount signifies for the initial load of records on component load.
    loadMoreStatus;
    targetDatatable; // capture the loadmore event to fetch data and stop infinite loading
    filterState = false;
    isClientCommunicationContactACRfilter;
    value = [];
    serviceRoles = [];
    supportRoles = [];
    hrScaleClientRoles = [];
    allFilters = [];
    isLoading = true;
    selectedSubClientOptions = [];
    selectedACROptions = [];
    subClientFilter = '';
    acrFilter = '';


    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: SUPPORTROLE_FIELD
    })
    supportRolePicklist;

    @wire(getPicklistValues, {
        recordTypeId: '012000000000000AAA',
        fieldApiName: SERVICEROLE_FIELD
    })
    serviceRolePicklist;

    @wire(getPicklistValues, {
        recordTypeId: "012000000000000AAA",
        fieldApiName: HRSCALECLIENTROLE_FIELD
    })
    hrScaleClientRolePicklist;

    //get currentPage reference and values when navigating to full view and rerender
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            if (currentPageReference.state.c__recordId) {
                this.isLoading = true
                this.recordId = currentPageReference.state.c__recordId;
                this.fullView = currentPageReference.state.c__fullView;
                this.allFilters = null;
                this.subClientFilter = '';
                this.acrFilter = '';
                this.offSetCount = 0;
                this.isClientCommunicationContactACRfilter = false
                this.data = [];
                this.value = [];
                this.serviceRoles = [];
                this.supportRoles = [];
                this.hrScaleClientRoles = [];
                this.template.querySelectorAll('c-multi-select')?.forEach(element => {
                    element?.removeFilters();
                });
            }
        }
    }

    //picklist options for SupportRole
    get supportPicklistValues() {
        return this.supportRolePicklist?.data?.values.map(row => {
            return { label: row.label, value: row.value }
        });
    }

    //picklist options for serviceRole
    get serviceRolePicklistValues() {
        return this.serviceRolePicklist?.data?.values.map(row => {
            return { label: row.label, value: row.value }
        });
    }

    get hrScaleClientRolePicklistValues() {
        return this.hrScaleClientRolePicklist?.data?.values.map((row) => {
            return { label: row.label, value: row.value };
        });
    }

    //Handle selected values form Combobox for Support and service role
    handleSelect(event) {
        let fieldApiName = event.detail?.fieldApiName;
        let values = JSON.parse(JSON.stringify(event.detail?.values));
        if (fieldApiName === 'NSP_Support_Role__c') {
            this.supportRoles = values ? values.map(row => row.value) : null;
            this.selectedACROptions = values ? values.map(row => row.label) : null;
        } else if (fieldApiName === 'NSP_Service_Roles__c') {
            this.serviceRoles = values ? values.map(row => row.value) : null;
            this.selectedACROptions = values ? values.map(row => row.label) : null;
        } else if (fieldApiName === 'HRScale_Client_Roles__c') {
            this.hrScaleClientRoles = values ? values.map((row) => row.value) : null;
            this.selectedACROptions = values ? values.map((row) => row.label) : null;
        }
    }

    //get records of ACR and SubClient Contacts
    @wire(getContactRollUpRecords, {
        recordId: '$recordId',
        offSetCount: 0,
        fullView: '$fullView',
        allFilters: null,
        subClientFilter: '',
        acrFilter: ''
    })
    async wiredContacts({ error, data }) {
        if (data) {
            await this.handleData(data);
            this.isLoading = false
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.loadMoreStatus = 'No more data to load';
            this.isLoading = false
        }
    }

    //assign data and handle loadmore
    async handleData(result) {
        if (result && result.length > 0) {
            this.data = await [...this.data, ...result];
            this.error = undefined;
            this.loadMoreStatus = '';
            if (this.targetDatatable) this.targetDatatable.enableInfiniteLoading = true;
        } else {
            //stop Infinite Loading when threshold is reached
            if (this.targetDatatable) this.targetDatatable.enableInfiniteLoading = false;
            //Display "No more data to load" when threshold is reached
            this.loadMoreStatus = 'No more data to load';
        }
        //Disable a spinner to signal that data has been loaded
        if (this.targetDatatable) this.targetDatatable.isLoading = false;
        return;
    }

    async loadData() {
        return getContactRollUpRecords({
            recordId: this.recordId,
            offSetCount: this.offSetCount,
            fullView: this.fullView,
            allFilters: this.allFilters,
            subClientFilter: this.subClientFilter,
            acrFilter: this.acrFilter
        })
            .then((result) => {
                this.handleData(result);
                this.isLoading = false
            })
            .catch((error) => {
                this.error = error;
            });
    }

    // Event to handle onloadmore on lightning datatable markup
    handleLoadMore(event) {
        event.preventDefault();
        // increase the offset count by 50 on every loadmore event
        this.offSetCount = this.offSetCount + 50;
        //Display a spinner to signal that data is being loaded
        event.target.isLoading = true;
        //Set the onloadmore event taraget to make it visible to imperative call response to apex.
        this.targetDatatable = event.target;
        //Display "Loading" when more data is being loaded
        this.loadMoreStatus = 'Loading';
        // Get new set of records and append to this.data
        this.loadData()
            .then(() => {
                this.isLoading = false;
            });

    }

    handleClick() {

        const navConfig = {
            type: "standard__component",
            attributes: {
                componentName: "c__nsp_mainServiceContactsListView"
            },
            state: {
                c__recordId: this.recordId,
                c__fullView: true
            }
        };

        //4. Invoke Naviate method
        this[NavigationMixin.Navigate](navConfig);
    }

    get viewType() {
        return this.fullView ? 'height: ' + (window.innerHeight - 250) + 'px;width: ' + (window.innerWidth - 30) + 'px;' : '';
    }

    get sldsPanel() {
        return 'background-color:#fafaf9;position:relative;overflow:hidden;overflow-x: scroll;display:flex;flex-direction:row-reverse;height: ' + (window.innerHeight - 240) + 'px;width: ' + (window.innerWidth - 30) + 'px;';
    }

    get enableInfiniteLoading() {
        return this.fullView;
    }

    get loadMoreOffset() {
        return this.fullView ? 50 : 10;
    }

    //handle open and close filterpanel
    handlefilterButtonClick() {
        let divblock = this.template.querySelector('[data-id="divblock"]');
        this.filterState = !this.filterState;
        if (divblock) {
            if (this.filterState) {
                divblock.classList.add('slds-is-open');
            }
            if (!this.filterState) {
                divblock.classList.remove('slds-is-open');
            }
        }
    }

    //handle Close filters and reset all the values
    async handleClearFilter() {
        this.isLoading = true
        this.allFilters = null;
        this.subClientFilter = null;
        this.acrFilter = null;
        this.offSetCount = 0;
        this.isClientCommunicationContactACRfilter = false
        this.data = [];
        this.value = [];
        this.serviceRoles = [];
        this.supportRoles = [];
        this.hrScaleClientRoles = [];
        this.selectedSubClientOptions = [];
        this.template.querySelectorAll('c-nsp_multi-select')?.forEach(element => {
            element?.removeFilters();
        });
        await this.loadData()
            .then(() => {
                this.isLoading = false;
            });
    }

    get options() {
        return [
            { label: 'On-Site Supervisor', value: SITESUP_FIELD.fieldApiName },
            { label: 'Payroll Contact', value: PAYROLLCON_FIELD.fieldApiName },
            { label: 'Client Leave Administrator', value: CLIENTADMIN_FIELD.fieldApiName },
            { label: 'WC Contact', value: WCCONTACT_FIELD.fieldApiName },
            { label: 'HR Contact', value: HRCONTACT_FIELD.fieldApiName },
            { label: 'Benefits  Contact', value: BENIFIT_FIELD.fieldApiName },
            { label: 'Background Contact', value: BACKGROUND_FIELD.fieldApiName },
            { label: 'Unemployment Contact', value: UNEMPLOYMENT_FIELD.fieldApiName }
        ];
    }

    //handle Subclient Filters
    handleSubChange(e) {
        this.value = e.detail.value;
        this.selectedSubClientOptions = this.value.map(option => this.options.find(o => o.value === option).label);

    }

    //handle isClientCommunicationContat and Filter Condition Input
    handleInput(event) {
        let name = event.target.dataset.name;
        if (name === 'isClientCommunicationContact') {
            this.isClientCommunicationContactACRfilter = !this.isClientCommunicationContactACRfilter;
        }
    }

    async handleFilter() {

        this.isLoading = true;
        //ACR filters
        let allFilters = [];

        if (this.isClientCommunicationContactACRfilter) {
            allFilters.push('Client Communication Contact');
        }

        if (this.serviceRoles && this.serviceRoles.length > 0) {
            this.serviceRoles.forEach((value) => {
                allFilters.push(value);
            });
        }

        if (this.supportRoles && this.supportRoles.length > 0) {
            this.supportRoles.forEach((value) => {
                allFilters.push(value);
            });
        }

        if (this.hrScaleClientRoles && this.hrScaleClientRoles.length > 0) {
            this.hrScaleClientRoles.forEach((value) => {
                allFilters.push(value);
            });
        }

        if (this.selectedSubClientOptions && this.selectedSubClientOptions.length > 0) {
            this.selectedSubClientOptions.forEach((value) => {
                allFilters.push(value);
            });
        }

        this.allFilters = allFilters;

        //ACR filters
        let aCRFilter = [];
        let serviceRoles = '(' + this.serviceRoles?.join(';') + ')';
        let supportRoles = '(' + this.supportRoles?.join(';') + ')';
        let hrScaleClientRoles = '(' + this.hrScaleClientRoles?.join(';') + ')';

        if (this.isClientCommunicationContactACRfilter) {
            aCRFilter.push(Client_Communication_Contact_FIELD.fieldApiName + ' = true')
        }
        if (this.serviceRoles?.length) {
            aCRFilter.push(SERVICEROLE_FIELD.fieldApiName + ' INCLUDES ' + serviceRoles)
        }
        if (this.supportRoles?.length) {
            aCRFilter.push(SUPPORTROLE_FIELD.fieldApiName + ' INCLUDES ' + supportRoles)
        }
        if (this.hrScaleClientRoles?.length) {
            aCRFilter.push(HRSCALECLIENTROLE_FIELD.fieldApiName + " INCLUDES " + hrScaleClientRoles);
        }

        //SubClient filters
        let subCFilter = []
        for (let x of this.value) {
            subCFilter.push(x)
        }
        //Assign Values to the varaiable, prepare condition
        this.subClientFilter = subCFilter.join(' , ');
        this.acrFilter = aCRFilter.join(' AND ');

        this.offSetCount = 0;
        this.data = [];

        await this.loadData()
            .then(() => {
                this.isLoading = false;
            });
    }


}