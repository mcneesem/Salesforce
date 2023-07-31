import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import * as LABELS from 'c/nsp_implementationLabels';
import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  isSelectionBox,
  ANSWERED_CLASS_NAME,
} from 'c/nsp_utils';
import { SECTION_FIELDS, SYNC_FIELDS } from './fields';

export default class Nsp_generalPayInformation extends LightningElement {
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
    if (values && values.fieldName) {
      const { fieldName, value } = values;
      const localFieldName = SYNC_FIELDS[fieldName];
      if (Object.keys(SYNC_FIELDS).includes(fieldName)) {
        this.field[localFieldName] = value;
        const dataType = this.objFields[fieldName]?.dataType;
        const updatedValue =
            dataType == 'MultiPicklist' ? value.split(';') : value;
        this.updateDependentFieldVisibility(localFieldName, updatedValue);
      }
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
  }

  doOneTimeActions() {
    if (this.fieldValues) {
      Object.keys(this.fieldValues).forEach((fieldName) => {
        const { value } = this.fieldValues[fieldName];

        if (SECTION_FIELDS.includes(fieldName) && value) {
          this.field[fieldName] = value;
          const dataType = this.objFields[fieldName]?.dataType;
          const updatedValue =
            dataType == 'MultiPicklist' ? value.split(';') : value;
          this.updateDependentFieldVisibility(fieldName, updatedValue);
          this.addStyleToPrePopulatedQuestions(fieldName, value);
        }

        const employeeStates = this.fieldValues['Employees_work_in_the_following_states__c']?.value;
        if(employeeStates){
          this.field.employeeStates = employeeStates;
        }
      });
    }
  }

  addStyleToPrePopulatedQuestions(name, value) {
    const existingClass = this.styles[name];
    if (existingClass) {
      this.styles[name] = `${existingClass} ${ANSWERED_CLASS_NAME}`;
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
      if (isSelectionBox(target)) {
        elm.className = isValuePresent ? ANSWERED_CLASS_NAME : null;
      } else {
        if (isValuePresent) {
          elm.classList.add(ANSWERED_CLASS_NAME);
        } else {
          elm.classList.remove(ANSWERED_CLASS_NAME);
        }
      }
    }
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
      Object.keys(updatedValues)
      .forEach((fieldApiName) => {
        if(updatedValues[fieldApiName]){
          this.visibility[fieldApiName] = true;
        }else{
          this.field[fieldApiName] = null;
          this.visibility[fieldApiName] = false;
          this.removeAnswerClasses(fieldApiName);
          this.updateDependentFieldVisibility(fieldApiName, null);
        }
      })
    }
  }

  removeAnswerClasses(fieldApiName) {
    this.styles[fieldApiName] = this.styles[fieldApiName]
      .replace(ANSWERED_CLASS_NAME, '')
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

  get messageAppletForPieceRateAndCA(){
    const { NSP_Employees_with_multiple_types_of_pay__c, employeeStates } = this.field;
    if(!NSP_Employees_with_multiple_types_of_pay__c || !employeeStates){
      return false;
    }

    this.multiplePay = this.field.NSP_Employees_with_multiple_types_of_pay__c.split(';');
    return this.multiplePay.includes('Piece Rate') && this.field.employeeStates.split(';').includes('CA');
  }
}