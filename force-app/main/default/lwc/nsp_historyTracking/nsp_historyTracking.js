import { LightningElement, api, wire, track } from 'lwc';
import { columns, payPeriodcolumns } from './columns';
import * as LABELS from 'c/nsp_implementationLabels';

import getRecords from '@salesforce/apex/NSP_SingleRelatedListController.getIPHistoryRecords';
import getImplementationPayPeriodHistory from '@salesforce/apex/NSP_SingleRelatedListController.getImplementationPayPeriodHistory';

export default class Nsp_historyTracking extends LightningElement {
    //@api recordId;
    @api relatedFieldApiName;
    @api fields;
    _recordId;
    @api sobjectApiName;
    @track data;
    columns = columns;
    payPeriodcolumns = payPeriodcolumns;

    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    @track state = {
        pageSize: 10,
        pageNumber: 1,
        totalPages: undefined,
        totalRecords: undefined,
        recordStart: 1,
        recordEnd: 0,
        error: undefined,
        buttonState: '',
        isLoading: false
    }

    parameterObject;

    @api getFormValues() {
        const formValues = {};

        return { ...formValues };
    }

    @api get recordId() {
        return null;
    }
    set recordId(value) {
        if (value) {
            this._recordId = value;
            this.parameterObject = JSON.stringify({
                fields: 'NSP_Field_Label__c,NSP_Field_Name__c,NSP_Modified_Date__c,NSP_Old_Value__c,NSP_New_Value__c,NSP_Modified_By__r.Name,NSP_Index__c',
                relatedFieldApiName: 'NSP_Sobject_Record_Id__c',
                sobjectApiName: 'NSP_IP_History_Tracking__b', // DEPRECATED
                recordId: value,
                numberOfRecords: 10,
                pageNumber: null
            });
        }
    }

    @wire(getRecords, {
        jsonData: '$parameterObject'
    })
    async wiredRecords({ error, data }) {

        if (data) {
            try {

                this.data = await data;
                let { pageSize, totalPages, totalRecords } = this.state;

                this.state.recordCount = this.data?.length;

                if (!totalPages && !totalRecords) {
                    this.state.totalPages = Math.ceil(this.data[0]?.NSP_Index__c / pageSize);
                    this.state.totalRecords = this.data[0]?.NSP_Index__c;

                    this.state.recordEnd = this.state.recordEnd + this.state.recordCount;
                }
                this.handlePageNumbers();
                this.state.error = undefined;
                this.state.isLoading = false;
            } catch (e) {
            }
        } else if (error) {
            this.state.error = error;
            this.data = undefined;
            this.state.isLoading = false;
        }

    }

    handleNavigation({ target }) {
        let buttonName = target.label;
        this.state.buttonState = buttonName;

        if (buttonName == 'First') {
            this.handleFirst();
        } else if (buttonName == 'Next') {
            this.handleNext();
        } else if (buttonName == 'Previous') {
            this.handlePrevious();
        } else if (buttonName == 'Last') {
            this.handleLast();
        }

    }

    handlePageNumbers() {
        const { buttonState, pageNumber, totalPages, recordStart, recordEnd, pageSize, recordCount } = this.state;

        if (buttonState == 'First') {
            this.state.recordStart = 1;
            this.state.recordEnd = 1 * recordCount;
        } else if (buttonState == 'Next') {
            this.state.recordStart = recordEnd;
            this.state.recordEnd = recordEnd + recordCount;
        } else if (buttonState == 'Previous') {
            this.state.recordStart = pageNumber == 1 ? 1 : recordStart - pageSize;
            this.state.recordEnd = recordStart;
        } else if (buttonState == 'Last') {
            this.state.recordStart = (totalPages - 1) * pageSize;
            this.state.recordEnd = this.state.recordStart + recordCount;
        }
    }

    handleFirst() {

        this.state.pageNumber = 1;
        let json = JSON.parse(this.parameterObject);
        json.pageNumber = this.state.totalRecords + 1;
        this.parameterObject = JSON.stringify(json);
        this.state.isLoading = true;
    }

    handlePrevious() {
        const { pageNumber } = this.state;
        const [first] = this.data;
        let pagNumber = first && first?.NSP_Index__c;
        this.state.pageNumber = pageNumber > 1 ? pageNumber - 1 : 1;

        let json = JSON.parse(this.parameterObject);
        json.pageNumber = pagNumber + 11;
        this.parameterObject = JSON.stringify(json);
        this.state.isLoading = true;
    }

    handleNext() {
        const { pageNumber, totalPages } = this.state;

        this.state.pageNumber = pageNumber >= totalPages ? totalPages : pageNumber + 1;
        let pgeNumber = this.data && this.data?.slice(-1)[0]?.NSP_Index__c;
        let json = JSON.parse(this.parameterObject);
        json.pageNumber = pgeNumber;
        this.parameterObject = JSON.stringify(json);
        this.state.isLoading = true;
    }

    handleLast() {
        const { totalPages } = this.state;
        this.state.pageNumber = totalPages;
        const lastPage = String(this.state.totalRecords).slice(-1);
        let json = JSON.parse(this.parameterObject);
        json.pageNumber = Number(lastPage) + 1;
        this.parameterObject = JSON.stringify(json);
        this.state.isLoading = true;
    }

    get disablePreviousButtons() {
        return this.state.pageNumber == 1;
    }

    get disableNextButtons() {
        return (this.state.pageNumber == this.state.totalPages || !this.state.totalPages);
    }

    get isPageButtonsAvailable() {
        return this.data && this.data.length;
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                return primer(x[field]);
            }
            : function (x) {
                return x[field];
            };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort({ detail }) {
        const { fieldName: sortedBy, sortDirection } = detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    get label() {
        return LABELS;
    }

    @track statePayRecords = {
        pageSize: 10,
        pageNumber: 1,
        totalPages: undefined,
        totalRecords: undefined,
        recordStart: 1,
        recordEnd: 0,
        error: undefined,
        buttonState: '',
        isLoading: false,
        recordCount: 0
    }

    payPeriodHistoriesData;
    @wire(getImplementationPayPeriodHistory, { recordId: '$_recordId', pageNumber: '$statePayRecords.pageNumber' })
    wiredData({ error, data }) {
        if (data) {

            if(data?.lstRecords){
                this.payPeriodHistoriesData = data && data?.lstRecords?.map(record => {
                    let urlName = record?.Parent?.Name
                    let nameUrl = `/${record.ParentId}`;
                    let lastModifiedName = record.CreatedBy.Name;
                    return { ...record, lastModifiedName, nameUrl, urlName }
                });
            } else {
                this.payPeriodHistoriesData = undefined;
            }

            this.statePayRecords.recordCount = data?.lstRecords?.length;

            if (!this.statePayRecords.totalRecords) {
                this.statePayRecords.totalRecords = data.recordCount;
                this.statePayRecords.recordEnd = this.statePayRecords.recordEnd + this.statePayRecords.recordCount;
                this.statePayRecords.totalPages = Math.ceil(data.recordCount / 10)
            }

            this.error = undefined;
            this.handlePayPageNumbers();
        } else if (error) {
            this.payPeriodHistoriesData = undefined;
            this.error = error;
        }
    }

    handlePayPageNumbers() {
        const { buttonState, pageNumber, totalPages, recordStart, recordEnd, pageSize, recordCount } = this.statePayRecords;

        if (buttonState == 'First') {
            this.statePayRecords.recordStart = 1;
            this.statePayRecords.recordEnd = 1 * recordCount;
        } else if (buttonState == 'Next') {
            this.statePayRecords.recordStart = recordEnd;
            this.statePayRecords.recordEnd = recordEnd + recordCount;
        } else if (buttonState == 'Previous') {
            this.statePayRecords.recordStart = pageNumber == 1 ? 1 : recordStart - pageSize;
            this.statePayRecords.recordEnd = recordStart;
        } else if (buttonState == 'Last') {
            this.statePayRecords.recordStart = (totalPages - 1) * pageSize;
            this.statePayRecords.recordEnd = this.statePayRecords.recordStart + recordCount;
        }
    }

    handlePayNavigation({ target }) {
        let buttonName = target.label;
        const { pageNumber, totalPages } = this.statePayRecords
        this.statePayRecords.buttonState = buttonName;

        if (buttonName == 'First') {
            this.statePayRecords.pageNumber = 1;
        } else if (buttonName == 'Next') {
            this.statePayRecords.pageNumber = pageNumber >= totalPages ? totalPages : pageNumber + 1;
        } else if (buttonName == 'Previous') {
            this.statePayRecords.pageNumber = pageNumber > 1 ? pageNumber - 1 : 1;
        } else if (buttonName == 'Last') {
            this.statePayRecords.pageNumber = totalPages;
        }
    }

    get disablePayPreviousButtons() {
        return this.statePayRecords.pageNumber == 1;
    }

    get disablePayNextButtons() {
        return (this.statePayRecords.pageNumber == this.statePayRecords.totalPages || !this.statePayRecords.totalPages);
    }

    get isPagePayButtonsAvailable() {
        return this.payPeriodHistoriesData && this.payPeriodHistoriesData.length;
    }
}