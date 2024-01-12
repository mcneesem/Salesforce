import { LightningElement, wire, api, track } from 'lwc';
import getFieldSetFieldsByFieldSetName from '@salesforce/apex/NSP_Utilities.getFieldSetFieldsByFieldSetName';

export default class NSP_DisplayPlanFields extends LightningElement {
    @api heading;
    @api recordId;
    @api objectName;
    @api fieldSetName;
    @api _columns;
    @api error;

    @api
    get columns(){
        return this._columns;
    }
    set columns(val){
        this._columns = val && Number.parseInt(val) !== NaN ? Number.parseInt(val) : 1;
    }

    @api
    get formValues(){
        const formValues = {};

        this.inputFields.forEach(({ fieldName, value }) => {
            formValues[fieldName] = value;
        });
        return { ...formValues, ...this.field };
    }
    set formValues(val){
    }

    @track fieldsGroup = [];
    @track state = {
        isLoading: true,
    }

    @wire(getFieldSetFieldsByFieldSetName, {objectApiName: '$objectName', fieldSetName: '$fieldSetName'})
    getFieldNamesCallBack({data, error}){
        if(data){
            this.fieldsGroup = this.groupFields(data);
            this.error = undefined;
        }
        if(error){
            this.error = error;
            this.fieldsGroup = [];
        }
    }

    handleError(error){
    this.error = error;
    }

    handleLoad(){
        const { state } = this;
        if(state.isLoading)
            state.isLoading = false;
    }

    groupFields(data){
        const fieldsGroup = [];
        const { _columns } = this;
        const fieldApiNames = data.map(field => field.apiName);

        if(_columns > 1 && fieldApiNames.length > 1){
            const noOfFieldsInSingleColumn = fieldApiNames.length / _columns;
            for (let index = 0; index < _columns; index++) {
                const startIndex = index * noOfFieldsInSingleColumn;
                const lastIndex = startIndex + noOfFieldsInSingleColumn;
                const columnFields = fieldApiNames.slice(startIndex, lastIndex);
                fieldsGroup.push(columnFields);
            }
        } else{
            fieldsGroup.push(fieldApiNames);
        }

        return fieldsGroup;
    }

    get colClassName(){
        return `slds-col slds-size_1-of-${this._columns}`;
    }

    get inputFields() {
        return this.template.querySelectorAll('lightning-input-field');
    }

    get uniqueValue(){
        return Math.random();
    }

    
}