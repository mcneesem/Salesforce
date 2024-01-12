import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { isObject } from './utils';
import { getUpdatedFieldVisibility } from 'c/nsp_utils';

// IMPORT HTML TEMPLATES
import recordFormSimple from './nsp_recordFormSimple.html';
import recordFormWithSections from './nsp_recordFormWithSections.html';

export default class Nsp_recordFormAdvanced extends LightningElement {
  @api heading;
  @api recordId;
  @api objectName;
  @api fieldSetName;
  @api showSaveButton = false;
  @api additionalValues = {};

  _config = {};
  @api
  get config() {
    return this._config;
  }
  set config(value) {
    this._config = value;
    if (value) {
      this.populateValuesInClassVariables(value);
      this.buildSections(); // Populate sections according to the given config
    }
  }

  @api
  get formValues() {
    const { standardFieldValues, customFieldValues, additionalValues } = this;

    return {
      ...standardFieldValues,
      ...customFieldValues,
      ...additionalValues,
    };
  }
  set formValues(val) {}

  @track fieldsGroup = [];
  @track fieldsConfig = {};
  @track fieldVisibilityConfig = {};
  @track fields = {};
  @track sections = null;

  @track state = {
    isLoading: true,
    isFirstTimeLoad: true,
  };

  columns = 1;

  render() {
    return isObject(this.fields) ? recordFormWithSections : recordFormSimple;
  }

  handleError(error) {
    this.showToast({
      title: 'Error',
      variant: 'error',
      message: error,
    });

    this.state.isLoading = false;
  }

  handleLoad() {
    const { state } = this;

    if (state.isFirstTimeLoad && state.isLoading) {
      state.isLoading = false;
      state.isFirstTimeLoad = false;
    }
  }

  handleValueChange({ detail, target }) {
    const fieldName = target.dataset.name;
    const { value } = detail;

    this.updateDependentFieldVisibility(fieldName, value);
  }

  handleSubmit(event) {
    event.preventDefault(); // stop the form from submitting

    this.state.isLoading = true;
    this.recordForm.submit(this.formValues);
  }

  handleSuccess({ detail }) {
    this.recordId = detail.id;
    this.showSuccessToast('Data saved successfully.');
    this.state.isLoading = false;
  }

  populateValuesInClassVariables(value) {
    const { fieldsConfig, fieldVisibilityConfig, columns, fields } = value;

    // Update values in instance variables
    this.fieldsConfig = fieldsConfig;
    this.fieldVisibilityConfig = fieldVisibilityConfig;
    this.columns =
      Number.parseInt(columns) !== NaN ? Number.parseInt(columns) : 1;
    this.fields = fields;
  }

  updateDependentFieldVisibility(fieldName, value) {
    const fieldConfig = this.fieldVisibilityConfig[fieldName];

    if (fieldConfig && fieldConfig.length) {
      const fieldVisibilities = getUpdatedFieldVisibility(fieldConfig, value);
      Object.keys(fieldVisibilities).forEach((fieldName) => {
        const visibility = fieldVisibilities[fieldName];
        const classToRemove = visibility ? 'slds-hide' : 'slds-show';
        const classToAdd = visibility ? 'slds-show' : 'slds-hide';
        const elmClassList = this.template.querySelector(
          '[data-container=' + fieldName + ']'
        ).classList;

        elmClassList.add(classToAdd);
        elmClassList.remove(classToRemove);
        if(!visibility){
          this.updateDependentFieldVisibility(fieldName, null);}
      });
    }
  }

  showToast(config) {
    this.dispatchEvent(new ShowToastEvent({ ...config }));
  }

  showSuccessToast(message) {
    this.showToast({
      title: 'Success',
      variant: 'success',
      message,
    });
  }

  getFieldsConfig(fieldApiNames) {
    const fieldConfigArray = [];

    fieldApiNames.forEach((name) => {
      const fieldConfig = { name };
      if (this.fieldsConfig && name in this.fieldsConfig) {
        const {
          isCustom,
          type,
          value,
          label,
          disabled,
          isHidden,
          isURL,
          urlLabel,
          isRichText,
          variant,
          className,
          isChecked,
        } = this.fieldsConfig[name];

        fieldConfig.isCustom = !!isCustom;
        fieldConfig.type = type || 'text';
        fieldConfig.label = label;
        fieldConfig.value = value;
        fieldConfig.variant = variant || 'label-stacked';
        fieldConfig.disabled = !!disabled;
        fieldConfig.className = className || '';
        fieldConfig.containerClassName = !isHidden ? 'slds-show' : 'slds-hide';
        fieldConfig.isHidden = !!isHidden;
        fieldConfig.isRichText = !!isRichText;
        fieldConfig.className = className || '';
        fieldConfig.isURL = !!isURL;
        fieldConfig.isChecked = !!isChecked;
        fieldConfig.urlLabel = urlLabel;
      }

      fieldConfigArray.push(fieldConfig);
    });

    return fieldConfigArray;
  }

  groupFields(fields) {
    const fieldsGroup = [];
    const { columns } = this;

    if (columns > 1 && fields.length > 1) {
      const noOfFieldsInSingleColumn = Math.ceil(fields.length / columns);
      for (let index = 0; index < columns; index++) {
        const startIndex = index * noOfFieldsInSingleColumn;
        const lastIndex = startIndex + noOfFieldsInSingleColumn;
        const columnFields = fields.slice(startIndex, lastIndex);

        fieldsGroup.push(columnFields);
      }
    } else {
      fieldsGroup.push(fields);
    }

    return fieldsGroup;
  }

  groupFieldsBySection(val) {
    const sectionWiseFields = [];

    Object.keys(val).forEach((sectionName) => {
      const sectionFields = { name: sectionName };
      const subSections = val[sectionName];

      Object.keys(subSections).forEach((subSectionName) => {
        const fieldsConfig = this.getFieldsConfig(subSections[subSectionName]);
        const fieldsGroup = this.groupFields(fieldsConfig);

        if (subSectionName === 'fields') {
          sectionFields.fieldsGroup = fieldsGroup;
        } else {
          if (!sectionFields.subSections) {
            sectionFields.subSections = [];
          }
          sectionFields.subSections.push({
            name: subSectionName,
            fieldsGroup,
          });
        }
      });
      sectionWiseFields.push(sectionFields);
    });

    return sectionWiseFields;
  }

  buildSections() {
    const { fields } = this;

    this.sections = isObject(fields) ? this.groupFieldsBySection(fields) : [];
  }

  get colClassName() {
    return `slds-col slds-size_1-of-${this.columns}`;
  }

  get standardFields() {
    return this.template.querySelectorAll('lightning-input-field');
  }

  get customFields() {
    return this.template.querySelectorAll('lightning-input');
  }

  get standardFieldValues() {
    const values = {};
    this.standardFields.forEach(
      ({ fieldName, value }) => (values[fieldName] = value)
    );

    return values;
  }

  get uniqueValue() {
    return Math.random();
  }

  get recordForm() {
    return this.template.querySelector('lightning-record-edit-form');
  }

  get customFieldValues() {
    const values = {};
    this.customFields.forEach(({ name, value, disabled }) => {
      if (!disabled) {
        values[name] = value;
      }
    });

    return values;
  }
}
