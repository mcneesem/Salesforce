import { LightningElement, api, wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { LABEL_CLASSES } from 'c/nsp_utils';

const DEFAULT_LABEL_CLASSES = 'slds-form-element__label slds-m-left_xx-small';

export default class Nsp_selectionBox extends LightningElement {
  @api label;
  @api fieldApiName;
  @api valueMap;
  @api value;
  @api recordTypeId;
  @api multiple = false;
  @api className;
  @api noOfColumns = null;
  @api disabled = false;
  @api helpText;
  @api
  get fieldName() {
    return this._fieldName;
  }
  picklistValues = null;

  @wire(getPicklistValues, {
    fieldApiName: '$fieldApiName',
    recordTypeId: '$recordTypeId',
  })
  getPicklistValuesCallback({ data, error }) {
    if (data) {
      this.picklistValues = data.values;
    }
    if (error) {
      this.dispatchEvent(new CustomEvent('error', error));
    }
  }

  connectedCallback() {
    this.setFieldName(this.fieldApiName);
  }

  setFieldName(fieldApiName) {
    this._fieldName =
      fieldApiName && fieldApiName.includes('.')
        ? fieldApiName.split('.')[1]
        : fieldApiName;
  }

  get finalValue() {
    if (
      !this.value &&
      this.valueMap &&
      this.fieldName &&
      this.valueMap[this.fieldName]
    ) {
      return this.valueMap[this.fieldName].value;
    }

    return this.value;
  }

  get values() {
    const { finalValue } = this;

    return finalValue
      ? Array.isArray(finalValue)
        ? finalValue
        : finalValue.split(';')
      : [];
  }

  get labelClass() {
    let labelClasses = this.className || '';
    const { classList } = this;

    LABEL_CLASSES.forEach((className) => {
      if (classList.contains(className)) {
        labelClasses += ` ${className}`;
      }
    });

    return `${DEFAULT_LABEL_CLASSES} ${labelClasses}`;
  }

  get inlineStyles() {
    const { noOfColumns } = this;

    if (noOfColumns) {
      const columnsLength = Number.parseInt(noOfColumns);

      return Number.isInteger(columnsLength) && columnsLength > 1
        ? `columns: ${noOfColumns};`
        : '';
    }
  }
}
