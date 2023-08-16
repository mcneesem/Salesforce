import { LightningElement, api, wire } from 'lwc';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';

export default class CheckboxGroup extends LightningElement {
    @api selectedValue = []; // selected values

    @api label; // checkbox group label

    @api fieldInfo; // field Information

    @api recordTypeId; // recordTypeId picklist values based on recordtypeId

    @api objectApiName; // object Name

    @api fieldApiName; // field Name

    @api required;
    
    @api showTwoColomuns = false;

    @api options = []; // List of values to display

    _fieldApiName;

    _value = [];

    fieldType; // datatype of the field

    @api get value() {
        return this._value;
    }

    get adjustColumns(){
        return this.showTwoColomuns ? 'columns: 2;': '';
        }
        

    set value(value) {
        if (value) {
            this.selectedValue = value ? value?.split(";") : []
        }
    }

    connectedCallback() {
        this.fieldType = this.fieldInfo?.dataType;
        this._fieldApiName = {
            objectApiName: this.objectApiName,
            fieldApiName: this.fieldApiName,
        };
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: '$_fieldApiName'
    })
    picklistValues;

    //Handle selected values from the checkbox group
    handleChange(event) {
        // selected values
        this.selectedValue = event.detail.value;
        // values to pass
        const { label, fieldApiName, objectApiName, selectedValue, fieldType } = this;
        // Dispatches the event.
        this.dispatchEvent(
            new CustomEvent("selected", {
                detail: { label, fieldApiName, objectApiName, selectedValue, fieldType },
            })
        );
    }

    get fieldLabel() {
        if (this.label) return this.label;
        if (this.fieldInfo?.inlineHelpText) return this.fieldInfo?.inlineHelpText;
        else if (this.fieldInfo?.label) return this.fieldInfo?.label;
    }

    //check for any picklist values or Options
    get listOfOptions() {
        if (this.picklistValues.data && this.picklistValues.data.values) return this.picklistValues.data.values;
        else if (this.options) return this.options;
        else return [];
    }
}