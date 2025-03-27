import { LightningElement } from 'lwc';
import executeBatch from '@salesforce/apex/JobRunnerController.executeBatch';
import getBatchJobStatuses from '@salesforce/apex/JobRunnerController.getBatchJobStatuses';
import getRecentBatchClasses from '@salesforce/apex/JobRunnerController.getRecentBatchClasses';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class JobRunner extends LightningElement {
    selectedBatchClass = '';
    showStatus = false;
    jobStatuses = [];
    isLoading = false;
    currentPage = 1;
    batchClassOptions = [];
    pageSize = 20;

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
        }
    ];

    connectedCallback() {
        this.loadBatchClassOptions();
    }

    async loadBatchClassOptions() {
        try {
            this.isLoading = true;
            const options = await getRecentBatchClasses();
            this.batchClassOptions = options.map(opt => ({
                label: opt.label,
                value: opt.value
            }));
        } catch (error) {
            this.showToast('Error', 'Failed to load batch classes: ' + (error.body?.message || error.message), 'error');
        } finally {
            this.isLoading = false;
        }
    }

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

    get isDisabled() {
        return !this.selectedBatchClass || this.selectedBatchClass.trim() === '' || this.isLoading;
    }

    handleBatchClassChange(event) {
        this.selectedBatchClass = event.detail.value;
        this.showStatus = false;
        this.currentPage = 1;
    }

    async handleExecute() {
        if (!this.selectedBatchClass) {
            this.showToast('Error', 'Please select a batch class.', 'error');
            return;
        }

        try {
            this.isLoading = true;
            await executeBatch({ batchClassName: this.selectedBatchClass });
            this.showToast('Success', 'Batch job has been successfully started.', 'success');
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Failed to execute batch.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async handleStatus() {
        if (!this.selectedBatchClass) {
            this.showToast('Error', 'Please select a batch class.', 'error');
            return;
        }

        this.isLoading = true;
        try {
            const result = await getBatchJobStatuses({ batchClassName: this.selectedBatchClass });
            this.jobStatuses = result.map(job => ({
                Id: job.Id,
                CreatedDate: job.CreatedDate,
                Status: job.Status,
                ExtendedStatus: job.ExtendedStatus,
                TotalJobItems: job.TotalJobItems,
                JobItemsProcessed: job.JobItemsProcessed,
                NumberOfErrors: job.NumberOfErrors,
                CompletedDate: job.CompletedDate
            }));
            this.showStatus = true;
            this.currentPage = 1;
            this.showToast('Success', 'Job statuses refreshed!', 'success');
        } catch (error) {
            console.error('Error fetching statuses:', error);
            this.showToast('Error', error.body?.message || 'Failed to fetch job statuses.', 'error');
        } finally {
            this.isLoading = false;
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