import { LightningElement, api, wire } from "lwc";
import { getPicklistValues } from "lightning/uiObjectInfoApi";

export default class Nsp_radioGroup extends LightningElement {
    @api value = ''; // selected values

    @api label; // checkbox group label

    @api fieldInfo; // field Information

    @api recordTypeId; // recordTypeId picklist values based on recordtypeId

    @api objectApiName; // object Name

    @api fieldApiName; // field Name

    @api required;

    @api options = []; // List of values to display

    _fieldApiName;

    fieldType; // datatype of the field


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

    //Handle selected values from the radiogroup
    handleChange(event) {
        // selected values
        this.selectedValue = event.detail.value;
        this.value = event.detail.value;
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