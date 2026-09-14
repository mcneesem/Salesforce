import { api, wire, LightningElement, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import {
  isMultiSelectCheckbox,
  isNonEmptyArray,
  getUpdatedFieldVisibility,
  isSelectionBox,
  ANSWERED_CLASS_NAME,
  RL_FIELD_ACCEPTED_VALUES,
  RL_CLASS_NAME
} from 'c/nsp_utils';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import { SECTION_FIELDS, PAY_FREQUENCY_FIELDS, ERROR_TOAST_CONFIG, RL_FIELDS } from './fields';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Nsp_payFrequencyForm extends LightningElement {
  @api recordId;
  @api fieldValues = {};
  @track existingFieldValues = {};
  @track styles = {};
  @track visibility = {};
  @track field = {};
  @api disabled;
  @track state = {
    isLoadingFirstTime: true,
    isRenderingFirstTime : true,
  };
  payFrequencyFields = PAY_FREQUENCY_FIELDS;

  @api getFormValues() {
    const formValues = {};

    this.template.querySelectorAll('lightning-input-field').forEach((elm) => {
      if (elm.value) {
        formValues[elm.fieldName] = elm.value;
      }
    });

    return { ...formValues, ...this.field };
  }

  @wire(getRecord, {
    recordId: '$recordId',
    fields: '$payFrequencyFields'
  })
  getPayFrequencyData({ error, data }) {
    if (error) {
      this.showErrorToast(error.body.message);
    } else if (data) {
      this.existingFieldValues = data.fields;
    }
  }

  handleLoad() {
    const { state } = this;

    if (state.isLoadingFirstTime) {
      state.isLoadingFirstTime = false;
      this.doOneTimeActions();
    }
  }
  renderedCallback(){
    const { state } = this;
    if(state.isRenderingFirstTime && this.visibility.Have_credit_services_approved__c) {
          this.addStyleToPrePopulatedQuestions('Have_credit_services_approved__c', this.existingFieldValues['Have_credit_services_approved__c']?.value);
          this.addStyleToPrePopulatedQuestions('Does_arrearage_comply_with_state_laws__c', this.existingFieldValues['Does_arrearage_comply_with_state_laws__c']?.value);
          state.isRenderingFirstTime = false;
    }
  }

  handleValueChange({ detail, target }) {
    const fieldName = target.dataset.name;
    const { value } = detail;

    this.field[fieldName] = isMultiSelectCheckbox(target)
      ? value.join(';')
      : value;
    this.updateDependentFieldVisibility(fieldName, value);
    this.addStyleToAnsweredQuestion(target, value);
    this.removeValuesFromHiddenFields(fieldName, value);
  }

  updateDependentFieldVisibility(fieldName, value) {
    const fieldConfig = DYNAMIC_FIELDS[fieldName];

    if (fieldConfig?.length) {
      const updatedValues = getUpdatedFieldVisibility(fieldConfig, value);
      this.visibility = { ...this.visibility, ...updatedValues };
    }
  }

  addStyleToPrePopulatedQuestions(name, value) {
    const existingClass = this.styles[name] || '';
    const elm = this.template.querySelector(`[data-name=${name}]`);

    this.styles[name] = `${existingClass} ${ANSWERED_CLASS_NAME}`;
    if (elm) {
      this.addStyleToAnsweredQuestion(elm, value);
    }
  }

  addStyleToAnsweredQuestion(target, value) {
    const fieldName = target.dataset.name;
    const elm = this.getCustomLabelElm(fieldName) || target;
    const isValuePresent = Array.isArray(value) ? !!value.length : !!value;

    if (elm) {
      const className = ANSWERED_CLASS_NAME;

      if (isSelectionBox(target)) {
        elm.className = isValuePresent ? className : null;
      } else {
        if (isValuePresent) {
          elm.classList.add(className);
        } else {
          elm.classList.remove(ANSWERED_CLASS_NAME);
        }
      }
      const className1 = this.getLabelClassName(fieldName, value);
      elm.classList.remove(ANSWERED_CLASS_NAME);
      elm.classList.remove(RL_CLASS_NAME);
      if (isValuePresent) {
          elm.classList.add(className1);
      }
    }
  }

  getLabelClassName(fieldName, value) {
    return RL_FIELDS.includes(fieldName) &&
      RL_FIELD_ACCEPTED_VALUES.includes(value)
      ? RL_CLASS_NAME
      : ANSWERED_CLASS_NAME;
  }

  removeValuesFromHiddenFields(fieldName, value) {
    const fieldConfig = DYNAMIC_FIELDS[fieldName];
    if (fieldConfig) {
      fieldConfig.forEach(({ dependentFields, expValue }) => {
        dependentFields.forEach((fieldApiName) => {
          if (fieldApiName !== fieldName) {
            if (isNonEmptyArray(value)) {
              value.forEach((val) => {
                if (!expValue.includes(val)) {
                  this.field[fieldApiName] = null;
                }
              });
            } else if (value && !expValue.includes(value)) {
              this.field[fieldApiName] = null;
            }
          }
        });
      });
    }
  }

  doOneTimeActions() {
    if (this.existingFieldValues) {
      Object.keys(this.existingFieldValues).forEach((fieldName) => {
        const { value } = this.existingFieldValues[fieldName];

        if (SECTION_FIELDS.includes(fieldName) && value) {
          this.field[fieldName] = value;
          this.updateDependentFieldVisibility(fieldName, value);
          this.addStyleToPrePopulatedQuestions(fieldName, value);
        }
      });
    }

    if(this.fieldValues.Frequency__c){
      this.addStyleToPrePopulatedQuestions('Frequency__c', this.fieldValues.Frequency__c);
    }
  }

  showErrorToast(message) {
    this.showToast({
      ...ERROR_TOAST_CONFIG,
      message,
    });
  }

  showToast(config) {
    this.dispatchEvent(new ShowToastEvent({ ...config }));
  }

  getCustomLabelElm(fieldName) {
    return this.template.querySelector(
      `lightning-formatted-text[data-field=${fieldName}]`
    );
  }
}