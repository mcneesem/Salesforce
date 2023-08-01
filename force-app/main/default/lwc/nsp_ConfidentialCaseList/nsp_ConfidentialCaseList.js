import { LightningElement, wire, api, track} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import getRelatedCases from '@salesforce/apex/NSP_Display_ConfidentialCases.getRelatedCases';
import CASE_STATUS from '@salesforce/schema/Case.Status';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CASE_OBJECT from '@salesforce/schema/Case';
import { OPERATOR_OPTIONS } from './constants';

export default class nsp_ConfidentialCaseList extends LightningElement {
    @track items = []; 
    @api recordId;
    @api objectApiName;
    options = [];
    selectedStatusValue = '';
    selectedOpenDateValue = null;
    selectedClosedDateValue = null;
    selectedClosedDateFilter = '';
    selectedOpenDateFilter = '';
    @track data = []; 
    @track page = 1;
    @track startingRecord = 1;
    @track endingRecord = 0; 
    @api pageSize = 10; 
    @track totalRecountCount = 0;
    @track totalPage = 0;
    @track isPageChanged = false;
    @api showRecords = false;

    @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
    caseInfo;

    @wire(getRelatedCases, {statusValue: '$selectedStatusValue', openDate : '$selectedOpenDateValue',
    closedDate : '$selectedClosedDateValue',
    parentId: '$recordId', 
    parentObject : '$objectApiName', 
    openDateFilter : '$selectedOpenDateFilter',
    closeDateFilter : '$selectedClosedDateFilter'})
    
    wiredAccounts({ error, data }) {
        if (data) {
            this.processRecords(data);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
        }
    }

    @wire( getPicklistValues, { recordTypeId: '$caseInfo.data.defaultRecordTypeId', fieldApiName: CASE_STATUS } )
    wiredData( { error, data } ) {
        if ( data ) {                     
            this.options = data.values.map( objPL => {
                return {
                    label: `${objPL.label}`,
                    value: `${objPL.value}`
                };
            });
        } 
    }

    handleValueChange( event ){
        const fieldName = event.target.dataset.id = 'undefined' ? event.target.name : event.target.dataset.id;
     const value = event.target.value;
        if(fieldName === 'status'){
            this.selectedStatusValue =  value;
        }else if(fieldName === 'openDate'){
            this.selectedOpenDateValue =  value; 
        }else if(fieldName === 'closedDate'){
            this.selectedClosedDateValue =  value;
        }else if(fieldName === 'Open Date Filter'){
            this.selectedOpenDateFilter = value;
        }else if(fieldName === 'Close Date Filter'){
            this.selectedClosedDateFilter = value;
        }
    }

     //clicking on previous button this method will be called
     previousHandler() {
        this.isPageChanged = true;
        if (this.page > 1) {
            this.page = this.page - 1; //decrease page by 1
            this.displayRecordPerPage(this.page);
        }
    }

    //clicking on next button this method will be called
    nextHandler() {
        this.isPageChanged = true;
        if((this.page<this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; //increase page by 1
            this.displayRecordPerPage(this.page);            
        }
    }
 //this method displays records page by page
 displayRecordPerPage(page){

    this.startingRecord = ((page -1) * this.pageSize) ;
    this.endingRecord = (this.pageSize * page);

    this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                        ? this.totalRecountCount : this.endingRecord; 

    this.data = this.items.slice(this.startingRecord, this.endingRecord);
    this.startingRecord = this.startingRecord + 1;
}  

    processRecords(data){        

        if(data.length > 0){ 
            this.page = 1;
            this.showRecords = true;
            this.items = data.map( record => Object.assign(
            { "Owner.Name": record.Owner.Name, "Account.Name": record.Account.Name},
            record));
            this.totalRecountCount = data.length; 
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize); 
            
            this.data = this.items.slice(0,this.pageSize); 
            this.endingRecord = this.pageSize;
        }else{
            this.showRecords = false;
        }
    }

    get dateFilters(){
        return OPERATOR_OPTIONS;
    }

    get bDisableFirst() {
        return this.page == 1;
    }
    get bDisableLast() {
        return this.page == this.totalPage;
    }

}