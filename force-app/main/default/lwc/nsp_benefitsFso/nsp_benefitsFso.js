import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import IP_EMP_DATA_OBJECT from '@salesforce/schema/NSP_Employee_Data__c';
import * as LABELS from 'c/nsp_implementationLabels';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import {
  SYNC_FIELDS,
  EMP_TABLE_FIELDS,
  RL_FIELDS,
  PREFILLED_FIELDS,
  POST_SYNC_IP_FIELDS,
  SECTION_FIELDS,
} from './fields';
import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  ANSWERED_CLASS_NAME,
  SYNC_FIELD_EVENT_NAME,
  RL_CLASS_NAME,
  RL_FIELD_ACCEPTED_VALUES,
} from 'c/nsp_utils';

export default class Nsp_benefitsFso extends LightningElement {
  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @api empData;
  @api disabledFields = {};
  @api readOnlyMode = false;
  @api error;
  @track state = {
    isLoadingFirstTime: true,
  };

  @track field = {};
  @track visibility = {};
  @track styles = getFieldStylesByHierarchy(DYNAMIC_FIELDS);

  @api getFormValues() {
    const formValues = {};

    this.inputFields.forEach(({ fieldName, value }) => {
      formValues[fieldName] = value;
    });

    this.updateEmpDetailsOnIPRecord();

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

      if (Object.keys(SYNC_FIELDS).includes(fieldName)) {
        this.field[SYNC_FIELDS[fieldName]] = value;
      }
      this.postSyncOperations(fieldName, value);
      this.addStyleToPrePopulatedQuestions(fieldName, value);
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
    this.error = error;
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

  publishSyncEvent(fieldName) {
    if (Object.values(SYNC_FIELDS).includes(fieldName)) {
      const value = this.field[fieldName];
      this.dispatchEvent(
        new CustomEvent(SYNC_FIELD_EVENT_NAME, { detail: { fieldName, value } })
      );
    }
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
      });
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

  getEmployeeRecords() {
    let allEmployeeRecords = [];
    let fieldSpecificRecords = {};

    this.empDataTables.forEach((empForm) => {
      const formValues = empForm.getAllRecords();

      fieldSpecificRecords[empForm.parentField] = [...formValues];

      if (formValues.length > 0) {
        allEmployeeRecords = [...allEmployeeRecords, ...formValues];
      }
    });

    return { allEmployeeRecords, fieldSpecificRecords };
  }

  updateEmpDetailsOnIPRecord() {
    const { allEmployeeRecords, fieldSpecificRecords } =
      this.getEmployeeRecords();

    this.updateCobraEmployees(
      fieldSpecificRecords.Have_name_s_of_COBRA_takeovr_employees__c,
      EMP_TABLE_FIELDS.Have_name_s_of_COBRA_takeovr_employees__c
    );
    this.updateLOADetails(
      fieldSpecificRecords.Do_you_have_the_LOA_information__c,
      EMP_TABLE_FIELDS.Do_you_have_the_LOA_information__c
    );
    /* added as part of STY-03177 */
    this.updateMedicalNeeds(
      fieldSpecificRecords.Any_EEs_with_urgent_medical_needs__c,
      EMP_TABLE_FIELDS.Any_EEs_with_urgent_medical_needs__c
    );
    this.updateClientWaitingPeriodEmpNames(
      fieldSpecificRecords.Client_s_previous_waiting_period__c,
      EMP_TABLE_FIELDS.Client_s_previous_waiting_period__c
    );
    /* added as part of STY-03177 */

    const postUpsertRecords = this.field.postUpsertRecords || {};

    postUpsertRecords[IP_EMP_DATA_OBJECT.objectApiName] = allEmployeeRecords;
    this.field.postUpsertRecords = postUpsertRecords;
  }

  updateCobraEmployees(empDataRecords, fields) {
    if (empDataRecords) {
      this.field.NSP_COBRA_Takeover_Emp_Details__c = empDataRecords
        .map((rec) => `${rec[fields[0]]}~${rec[fields[1]]}`)
        .join(',');
    }
  }

  updateLOADetails(empDataRecords, fields) {
    if (empDataRecords) {
      this.field.NSP_Employees_on_LOA__c = empDataRecords
        .map((rec) => `${rec[fields[0]]}`)
        .join(',');
    }
    if (empDataRecords) {
      this.field.NSP_Employee_Details_On_LOA__c = empDataRecords
        .map((rec) => `${rec[fields[0]]}~${rec[fields[1]]}~${rec[fields[2]]}`)
        .join(', ');
    }
    
  }
  /* added as part of STY-03177 */
  updateMedicalNeeds(empDataRecords, fields) {
    if (empDataRecords) {
      this.field.NSP_Urgent_Medical_Needs_Emp_Details__c = empDataRecords
        .map((rec) => `${rec[fields[0]]}`)
        .join(',');
    }
  }
  updateClientWaitingPeriodEmpNames(empDataRecords, fields) {
    if (empDataRecords) {
      this.field.NSP_List_Employee_Names__c = empDataRecords
        .map((rec) => `${rec[fields[0]]}`)
        .join(',');
    }
  }

  getNumericValue(val) {
    return val ? parseInt(val.split(' ')[0]) : 0;
  }

  get inputFields() {
    return this.template.querySelectorAll('lightning-input-field');
  }

  get title() {
    return LABEL.clientProject;
  }

  get objectApiName() {
    return IP_OBJECT.objectApiName;
  }

  get label() {
    return LABELS;
  }

  get empTableFields() {
    return EMP_TABLE_FIELDS;
  }

  get empDataTables() {
    return this.template.querySelectorAll('c-nsp_employee-data');
  }

  get showWaitingEmployeeTable() {
    const {
      Insperity_benefits_waiting_period__c,
      Client_s_previous_waiting_period__c,
    } = this.field;

    if (
      !Insperity_benefits_waiting_period__c ||
      !Client_s_previous_waiting_period__c
    ) {
      return false;
    }

    const insperityWaitingPeriod = this.getNumericValue(
      Insperity_benefits_waiting_period__c
    );
    const clientWaitingPeriod = this.getNumericValue(
      Client_s_previous_waiting_period__c
    );

    return insperityWaitingPeriod > clientWaitingPeriod;
  }

  get checkIfIpisActive(){
    return this.userData?.Profile?.displayValue !== LABELS.SYSTEM_ADMIN && this.fieldValues && this.fieldValues?.NSP_Inactive__c?.value
  }
}