import { LightningElement , wire } from 'lwc';
import isAccessible from '@salesforce/apex/JobRunnerController.isAccessible';
import getPageSize from '@salesforce/apex/JobRunnerController.getPageSize';
import getClickWaitingSeconds from '@salesforce/apex/JobRunnerController.getClickWaitingSeconds';
import getBatchClassOptions from '@salesforce/apex/JobRunnerController.getBatchClassOptions';
import getBatchJobStatuses from '@salesforce/apex/JobRunnerController.getBatchJobStatuses';
import requestJobExecution from '@salesforce/apex/JobRunnerController.requestJobExecution';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JobRunner extends LightningElement {
    selectedBatchClass = '';
    loadedBatchClass = '';
    showStatus = false;
    jobStatuses = [];
    isLoading = false;
    isWaiting = false;
    currentPage = 1;

    isAccessible = false;
    @wire(isAccessible)
    wireIsAccessible({ error , data }) {
        if ( error ) {
            this.isAccessible = false;
        } else if ( data ) {
            this.isAccessible = data;
        }
    }

    pageSize = 10;
    @wire(getPageSize)
    wireGetPageSize({ error , data }) {
        if ( error ) {
            this.pageSize = 10;
            this.showToast('Error', 'Failed to load page size: ' + error, 'error');
        } else if ( data ) {
            this.pageSize = data;
        }
    }

    clickWaitingMilliseconds = 7000;
    @wire(getClickWaitingSeconds)
    wireGetClickWaitingSeconds({ error , data }) {
        if ( error ) {
            this.clickWaitingMilliseconds = 7000;
            this.showToast('Error', 'Failed to load click waiting seconds: ' + error, 'error');
        } else if ( data ) {
            const clickWaitingSeconds = data;
            this.clickWaitingMilliseconds = ( clickWaitingSeconds * 1000 );
        }
    }

    batchClassOptions = [];
    @wire(getBatchClassOptions)
    wireGetBatchClassOptions({ error , data }) {
        if ( error ) {
            this.batchClassOptions = [];
            this.showToast('Error', 'Failed to load batchable classes: ' + (error.body?.message || error.message), 'error');
        } else if ( data ) {
            this.batchClassOptions = data.map(option => ({
                label: option.label,
                value: option.value
            }));
        }
    }

    columns = [
        {
            label: 'Submitted Date/Time',
            fieldName: 'CreatedDate',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'numeric',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            }
        },
        { label: 'Submitted By', fieldName: 'CreatedBy' },
        { label: 'Apex Class', fieldName: 'ApexClass' },
        { label: 'Status', fieldName: 'Status' },
        { label: 'Status Detail', fieldName: 'ExtendedStatus', wrapText: true },
        { label: 'Total Batches', fieldName: 'TotalJobItems', type: 'number' },
        { label: 'Batches Processed', fieldName: 'JobItemsProcessed', type: 'number' },
        { label: 'Failures', fieldName: 'NumberOfErrors', type: 'number' },
        {
            label: 'Completion Date/Time',
            fieldName: 'CompletedDate',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'numeric',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            }
        },
        { label: 'Apex Job ID', fieldName: 'Id' },
    ];

    get paginatedData() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.jobStatuses.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.jobStatuses.length / this.pageSize) || 1;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    get spinnerClass() {
        return ( this.isLoading ? 'slds-show' : 'slds-hide' );
    }

    get isDisabled() {
        return !this.selectedBatchClass || this.selectedBatchClass.trim() === '' || this.isLoading;
    }

    get isDisabledExecute() {
        return (
            this.isDisabled
            || this.isWaiting
            || !this.showStatus
            || ( this.loadedBatchClass != this.selectedBatchClass )
        );
    }

    handleBatchClassChange(event) {
        this.selectedBatchClass = event.detail.value;
    }

    showToastMissingSelection() {
        this.showToast('Error', 'Please select a batchable class.', 'error');
    }

    async handleExecute() {
        if ( !this.selectedBatchClass ) {
            this.showToastMissingSelection();
        } else {
            try {
                this.isLoading = true;
                await requestJobExecution( { batchClassName : this.selectedBatchClass } );
                this.showToast('Success', 'Job has been successfully requested.', 'success');
            } catch (error) {
                this.showToast('Error', error.body?.message || 'Failed to request job execution.', 'error');
            } finally {
                this.isLoading = false;
            }
            // disable the 'Execute' button for an additional amount of time after clicks...
            this.isWaiting = true;
            setTimeout(
                function() {
                    this.unlockExecuteButton();
                }.bind( this ) ,
                this.clickWaitingMilliseconds
            );
        }
    }

    unlockExecuteButton() {
        this.isWaiting = false;
        // reload status of currently selected job...
        this.handleStatus();
    }

    async handleStatus() {
        if ( !this.selectedBatchClass ) {
            this.showToastMissingSelection();
        } else {
            this.isLoading = true;
            try {
                const result = await getBatchJobStatuses({ batchClassName: this.selectedBatchClass });
                this.jobStatuses = result.map(job => ({
                    Id: job.Id,
                    CreatedDate: job.CreatedDate,
                    CreatedBy: job.CreatedBy.Name,
                    ApexClass: job.ApexClass.Name,
                    Status: job.Status,
                    ExtendedStatus: job.ExtendedStatus,
                    TotalJobItems: job.TotalJobItems,
                    JobItemsProcessed: job.JobItemsProcessed,
                    NumberOfErrors: job.NumberOfErrors,
                    CompletedDate: job.CompletedDate,
                }));
                this.showStatus = true;
                this.loadedBatchClass = this.selectedBatchClass;
                this.currentPage = 1;
                this.showToast('Success', 'Job statuses refreshed!', 'success');
            } catch (error) {
                console.error('Error fetching statuses:', error);
                this.showToast('Error', error.body?.message || 'Failed to fetch job statuses.', 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    handlePrevious() {
        if (!this.isFirstPage) this.currentPage--;
    }

    handleNext() {
        if (!this.isLastPage) this.currentPage++;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }

}