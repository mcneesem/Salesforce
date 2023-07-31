import { LightningElement, api, track, wire } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { LABEL } from './constants';
import * as LABELS from 'c/nsp_implementationLabels';
import {
  RL_FIELDS,
  SECTION_FIELDS,
  SYNC_FIELDS,
  POST_SYNC_IP_FIELDS,
  UNEMPLOYMENT_STATES,
} from './fields';
import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  ANSWERED_CLASS_NAME,
  RL_CLASS_NAME,
  RL_FIELD_ACCEPTED_VALUES,
} from 'c/nsp_utils';

export default class Nsp_workersSafetymm extends LightningElement {
  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @track field = {};
  @track visibility = {};
  @api disabledFields = {};
  @track styles = getFieldStylesByHierarchy(DYNAMIC_FIELDS);
  @track state = {
    isLoadingFirstTime: true,
  };

  @track empStateLabelValueMap = {};

  @api getFormValues() {
    const formValues = {};

    this.inputFields.forEach(({ fieldName, value }) => {
      formValues[fieldName] = value;
    });

    return { ...formValues, ...this.field };
  }

  @wire(getPicklistValues, {
    fieldApiName:
      'Implementation_Profile__c.Employees_work_in_the_following_states__c',
    recordTypeId: '$recordTypeId',
  })
  getPicklistValuesCallback({ data, error }) {
    if (data) {
      data.values.forEach(
        ({ label, value }) => (this.empStateLabelValueMap[value] = label)
      );
    }
    if (error) {
      this.dispatchEvent(new CustomEvent('error', error));
    }
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

      if (Object.keys(SYNC_FIELDS).includes(fieldName)) {
        this.field[SYNC_FIELDS[fieldName]] = value;
      }
      this.postSyncOperations(fieldName, value);
      this.addStyleToPrePopulatedQuestions(fieldName, value);
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
    try {
      const fieldName = target.dataset.name;
      const { value } = detail;

      this.field[fieldName] = isMultiSelectCheckbox(target)
        ? value.join(';')
        : value;
      this.updateDependentFieldVisibility(fieldName, value);
      this.addStyleToAnsweredQuestion(target, value);
    } catch (e) {
    }
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
      const empWorkState =
        this.fieldValues['Employees_work_in_the_following_states__c']?.value;
      if (empWorkState) {
        this.updateEmployeesWorkStates(empWorkState);
        this.styles.NSP_collected_copies_of_state_WC_policy__c =
        this.field.NSP_collected_copies_of_state_WC_policy__c ? 
        this.getLabelClassName(
          'NSP_collected_copies_of_state_WC_policy__c',
          this.field.NSP_collected_copies_of_state_WC_policy__c
        ) : null;
      }
    }
  }
  postSyncOperations(fieldName, value) {
    const postSyncOperationFn = POST_SYNC_IP_FIELDS[SYNC_FIELDS[fieldName]];
    if (postSyncOperationFn && postSyncOperationFn in this) {
      this[postSyncOperationFn](value);
      this.addStyleToPrePopulatedQuestions(fieldName, value);
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

  removeAnswerClasses(fieldApiName) {
    this.styles[fieldApiName] = this.styles[fieldApiName]
      .replace(ANSWERED_CLASS_NAME, '')
      .replace(RL_CLASS_NAME, '');
  }

  updateEmployeesWorkStates(value) {
    const stateCodes = value.split(';');
    const selectedUnemployeeTaxStates = stateCodes.filter((stateCode) =>
      UNEMPLOYMENT_STATES.includes(stateCode)
    );

    if (selectedUnemployeeTaxStates.length) {
      const stateNames = selectedUnemployeeTaxStates.map(
        (stateCode) => this.empStateLabelValueMap[stateCode]
      );

      this.field.employeesWorktaxStates = stateNames.join(', ');
    } else {
      this.field.employeesWorktaxStates = null;
    }
  }

  get labelWithStatesIncluded() {
    return this.label.CollectedCopiesofStateWCPolicyForState.replace(
      '<insert each state checked >',
      this.field.employeesWorktaxStates
    );
  }

  get title() {
    return LABEL.workersSafety;
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
}
