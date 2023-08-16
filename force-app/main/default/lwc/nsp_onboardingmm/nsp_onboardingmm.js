import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import { LABEL, HELP_TEXT } from './constants';
import * as LABELS from 'c/nsp_implementationLabels';
import {
  RL_FIELDS,
  PREFILLED_FIELDS,
  SYNC_FIELDS,
  POST_SYNC_IP_FIELDS,
  SECTION_FIELDS,
} from './fields';
import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  isSelectionBox,
  ANSWERED_CLASS_NAME,
  RL_CLASS_NAME,
  RL_FIELD_ACCEPTED_VALUES,
} from 'c/nsp_utils';

export default class Nsp_onboardingmm extends LightningElement {
  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @api disabledFields = {};

  @track field = {};
  @track visibility = {};
  @track styles = getFieldStylesByHierarchy(DYNAMIC_FIELDS);
  @track state = {
    isLoadingFirstTime: true,
  };

  @api getFormValues() {
    const formValues = {};

    this.inputFields.forEach(({ fieldName, value }) => {
      formValues[fieldName] = value;
    });

    return { ...formValues, ...this.field };
  }

  objFields;
  @api get objectInfo() {
    return this.objFields;
  }
  set objectInfo(value) {
    if (value) {
      this.objFields = value?.fields;
    }
  }

  @api
  get syncFieldValues() {
    return null;
  }
  set syncFieldValues(values) {
    if (values) {
      const { fieldName, value } = values;
      const localFieldName = SYNC_FIELDS[fieldName];
      if (Object.keys(SYNC_FIELDS).includes(fieldName)) {
        this.field[localFieldName] = value;
      }
      const dataType = this.objFields[fieldName]?.dataType;
      const updatedValue =
          dataType == 'MultiPicklist' ? value.split(';') : value;
      this.updateDependentFieldVisibility(localFieldName, updatedValue);
    }
  }

  postSyncOperations(fieldName, value) {
    const postSyncOperationFn = POST_SYNC_IP_FIELDS[SYNC_FIELDS[fieldName]];
    if (postSyncOperationFn && postSyncOperationFn in this) {
      this[postSyncOperationFn](value);
      this.addStyleToPrePopulatedQuestions(fieldName, value);
    }
  }

  updatePrefilledIpValues(values) {
    if (values && !this.recordId) {
      Object.keys(PREFILLED_FIELDS).forEach((fieldName, i) => {
        if (values[fieldName]) {
          const value = values[fieldName];
          this.field[fieldName] = value;
          this.addStyleToPrePopulatedQuestions(fieldName, value);
        }
      });
    }
  }

  handleLoad() {
    const { state } = this;

    if (state.isLoadingFirstTime) {
      state.isLoadingFirstTime = false;
      this.doOneTimeActions();
    }
  }

  handleError(error) {
  }

  handleValueChange({ detail, target }) {
    const fieldName = target.dataset.name;
    const { value } = detail;

    this.field[fieldName] = isMultiSelectCheckbox(target)
      ? value.join(';')
      : value;
    this.updateDependentFieldVisibility(fieldName, value);
    this.addStyleToAnsweredQuestion(target, value);
    this.publishSyncEvent(fieldName);
  }

  removeAnswerClasses(fieldApiName) {
    this.styles[fieldApiName] = this.styles[fieldApiName]
      .replace(ANSWERED_CLASS_NAME, '')
      .replace(RL_CLASS_NAME, '');
  }

  doOneTimeActions() {
    if (this.fieldValues) {
      Object.keys(this.fieldValues).forEach((fieldName) => {
        const { value } = this.fieldValues[fieldName];

        if (SECTION_FIELDS.includes(fieldName) && value) {
          this.field[fieldName] = value;
          this.updateDependentFieldVisibility(fieldName, value);
          this.addStyleToPrePopulatedQuestions(fieldName, value);
        }
      });
      const empWorkState = this.fieldValues['Employees_work_in_the_following_states__c']?.value?.split(';');
      if(empWorkState && empWorkState.length){
        this.updateDependentFieldVisibility('employee_states', empWorkState);
      }
    }
  }

  publishSyncEvent(fieldName) {
    if (Object.values(SYNC_FIELDS).includes(fieldName)) {
      const value = this.field[fieldName];
      this.dispatchEvent(
        new CustomEvent('syncfields', { detail: { fieldName, value } })
      );
    }
  }

  addStyleToPrePopulatedQuestions(name, value) {
    const existingClass = this.styles[name];
    if (existingClass) {
      const className = this.getLabelClassName(name, value);
      this.styles[name] = `${existingClass} ${className}`;
    } else {
      const elm = this.template.querySelector(`[data-name=${name}]`);
      if (elm) {
        this.addStyleToAnsweredQuestion(elm, value);
      }
    }
  }

  addStyleToAnsweredQuestion(target, value) {
    const fieldName = target.dataset.name;
    const elm = this.getCustomLabelElm(fieldName) || target;
    const isValuePresent = Array.isArray(value) ? !!value.length : !!value;

    if (elm) {
      const className = this.getLabelClassName(fieldName, value);

      elm.classList.remove(ANSWERED_CLASS_NAME);
      elm.classList.remove(RL_CLASS_NAME);
      if (isValuePresent) {
          elm.classList.add(className);
      }
    }
  }

  
  getLabelClassName(fieldName, value) {
    return RL_FIELDS.includes(fieldName) &&
      RL_FIELD_ACCEPTED_VALUES.includes(value)
      ? RL_CLASS_NAME
      : ANSWERED_CLASS_NAME;
  }

  getCustomLabelElm(fieldName) {
    return this.template.querySelector(
      `lightning-formatted-text[data-field=${fieldName}]`
    );
  }

  updateDependentFieldVisibility(fieldName, value) {
    const fieldConfig = DYNAMIC_FIELDS[fieldName];
    if (fieldConfig && fieldConfig.length) {
      const updatedValues = getUpdatedFieldVisibility(fieldConfig, value);
      Object.keys(updatedValues).forEach((fieldApiName) => {
        if (updatedValues[fieldApiName]) {
          this.visibility[fieldApiName] = true;
        } else {
          this.field[fieldApiName] = null;
          this.visibility[fieldApiName] = false;
          this.removeAnswerClasses(fieldApiName);
          this.updateDependentFieldVisibility(fieldApiName, null);
        }
      });
    }
  }

  get title() {
    return LABEL.onBoarding;
  }

  get inputFields() {
    return this.template.querySelectorAll('lightning-input-field');
  }

  get objectApiName() {
    return IP_OBJECT.objectApiName;
  }

  get label() {
    return LABELS;
  }

  get helpText() {
    return HELP_TEXT;
  }
}
