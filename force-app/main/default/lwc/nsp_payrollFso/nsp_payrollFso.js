import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import IP_EMP_DATA_OBJECT from '@salesforce/schema/NSP_Employee_Data__c';
import PAY_PERIOD_OBJECT from '@salesforce/schema/Implementation_Pay_Period__c';
import * as LABELS from 'c/nsp_implementationLabels';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import {
  SYNC_FIELDS,
  RL_FIELDS,
  EMP_TABLE_FIELDS,
  EMP_DATA_RL_FIELDS,
  POST_SYNC_IP_FIELDS,
  PREFILLED_FIELDS,
  SECTION_FIELDS,
  PAY_FREQUENCY_FIELDS
} from './fields';
import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  ANSWERED_CLASS_NAME,
  SYNC_FIELD_EVENT_NAME,
  RL_CLASS_NAME,
  RL_FIELD_ACCEPTED_VALUES,
  isNonEmptyArray,
} from 'c/nsp_utils';

export default class Nsp_payrollFso extends LightningElement {
  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @api empData;
  @api userData;
  @api error;
  @api disabledFields = {};
  @api readOnlyMode = false;
  @track field = {};
  @track visibility = {};
  @track styles = getFieldStylesByHierarchy(DYNAMIC_FIELDS);
  @track state = {
    isLoadingFirstTime: true,
  };

  _objectInfo;
  @api get objectInfo() {
    return this._objectInfo;
  }
  set objectInfo(value) {
    if (value) {
      this._objectInfo = value?.fields;
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
        const localName = SYNC_FIELDS[fieldName];
        this.field[localName] = value;
        this.postSyncOperations(fieldName, value);
        this.addStyleToPrePopulatedQuestions(fieldName, value);
      }
    }
  }

  payFrequencyRecordIds = [];
  _payFrequencies;
  @api
  get payFrequencies() {
    return this._payFrequencies;
  }
  set payFrequencies(value) {
    this._payFrequencies = value;
    if (isNonEmptyArray(value)) {
      this.payFrequencyRecordIds = [];
      value.forEach((element) => {
        this.payFrequencyRecordIds.push({ Id: element, fieldValues: {}, uid: Math.random() });
      });
    }
  }

  @api getFormValues() {
    const formValues = {};

    this.inputFields.forEach(({ fieldName, value }) => {
      formValues[fieldName] = value;
    });

    this.updateEmpDetailsOnIPRecord();
    this.updatePostUpsertRecords(
      PAY_PERIOD_OBJECT.objectApiName,
      this.payFrequencyValues
    );
    this.updatePayFrequencyOnIPRecord();

    return { ...formValues, ...this.field };
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
    this.doFieldSpecificAction(fieldName, value);
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
      let value = this.field[fieldName];

      if (fieldName == 'Select_all_payroll_needs_that_apply__c' && value) {
        const itemsTobeRemoved = ['Other', 'Billing Groups'];
        let valueArray = value.split(';');
        value = this.removeItemsFromArray(valueArray, itemsTobeRemoved).join(';');
      }
      this.dispatchEvent(
        new CustomEvent(SYNC_FIELD_EVENT_NAME, { detail: { fieldName, value } })
      );
    }
  }

  removeItemsFromArray(strArray, itemsTobeRemoved) {
    return strArray && strArray.length > 0 ? strArray.filter(x => !itemsTobeRemoved.includes(x)) : [];
  }

  doOneTimeActions() {
    if (this.fieldValues) {
      Object.keys(this.fieldValues).forEach((fieldName) => {
        const { value } = this.fieldValues[fieldName];

        if (SECTION_FIELDS.includes(fieldName) && value) {
          this.field[fieldName] = value;
          const dataType = this._objectInfo[fieldName]?.dataType;
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

  postSyncOperations(fieldName, value) {
    const postSyncOperationFn = POST_SYNC_IP_FIELDS[SYNC_FIELDS[fieldName]];
    if (postSyncOperationFn && postSyncOperationFn in this) {
      this[postSyncOperationFn](value);
      this.addStyleToPrePopulatedQuestions(fieldName, value);
    }
  }

  updatePrefilledIpValues(values) {
    if (values && !this.recordId) {
      Object.keys(PREFILLED_FIELDS).forEach((fieldName) => {
        const value = values[fieldName];
        if (value) {
          if(fieldName === 'Insperity_pay_frequency__c'){
            const frequency = value === 'Biweekly' ? 'Bi-Weekly' : value;
            const existingValues = this.field.Insperity_pay_frequency__c ? this.field.Insperity_pay_frequency__c.split(';') : [];
            existingValues.push(frequency);
            
            this.field.Insperity_pay_frequency__c = existingValues.join(';');
            this.addPayFrequencyInForm(frequency);
            this.updateDependentFieldVisibility(fieldName, existingValues);
          } else {
            this.field[fieldName] = value;
            this.updateDependentFieldVisibility(fieldName, value);
          }
          this.addStyleToPrePopulatedQuestions(fieldName, value);
        }
      });
    }
  }

  updateDependentFieldVisibility(fieldName, value) {
    const fieldConfig = DYNAMIC_FIELDS[fieldName];

    if (fieldConfig?.length) {
      const updatedValues = getUpdatedFieldVisibility(fieldConfig, value);
      Object.keys(updatedValues)
        .forEach((fieldApiName) => {
          if (updatedValues[fieldApiName]) {
            this.visibility[fieldApiName] = true;
          } else {
            this.field[fieldApiName] = null;
            this.visibility[fieldApiName] = false;
            this.removeAnswerClasses(fieldApiName);
            this.updateDependentFieldVisibility(fieldApiName, null);
          }
        })
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

    this.updateVisaDetails(
      fieldSpecificRecords.Client_have_any_EEs_on_F1_or_J1_Visa_s__c,
      EMP_TABLE_FIELDS.Client_have_any_EEs_on_F1_or_J1_Visa_s__c
    );
    this.updateEEGarnishments(
      fieldSpecificRecords.Do_any_EEs_have_garnishments__c,
      EMP_TABLE_FIELDS.Do_any_EEs_have_garnishments__c
    );
    this.updateTaxLevies(
      fieldSpecificRecords.Do_any_EEs_have_tax_levies__c,
      EMP_TABLE_FIELDS.Do_any_EEs_have_tax_levies__c
    );

    this.updatePostUpsertRecords(
      IP_EMP_DATA_OBJECT.objectApiName,
      allEmployeeRecords
    );
  }

  updatePostUpsertRecords(objectApiName, records) {
    if (isNonEmptyArray(records)) {
      const postUpsertRecords = this.field.postUpsertRecords || {};

      postUpsertRecords[objectApiName] = records;
      this.field.postUpsertRecords = postUpsertRecords;
    }
  }

  updateVisaDetails(empDataRecords, fields) {
    if (empDataRecords) {
      this.field.NSP_EE_Name__c = 
        empDataRecords
        .map((rec) => `${rec[fields[0]]}~${rec[fields[1]]}`)
        .join(',');
    
    }
  }

  updateEEGarnishments(empDataRecords, fields) {
    if (empDataRecords) {
      const onlyEmpRequestedRec = empDataRecords.filter(
        (rec) =>
          this.label.employeeDataRequested.toLowerCase() ==
          rec[fields[1]]?.toLowerCase()
      );

      this.field.NSP_Employee_Names_List_garnishments__c =
        this.getCSVFromObjectList(onlyEmpRequestedRec, fields[0]);
      this.field.NSP_Documents_garnishments__c = empDataRecords
        .map((rec) => `${rec[fields[0]]}~${rec[fields[1]]}`)
        .join(',');
    }
  }

  updateTaxLevies(empDataRecords, fields) {
    if (empDataRecords) {
      const onlyEmpRequestedRec = empDataRecords.filter(
        (rec) =>
          this.label.employeeDataRequested.toLowerCase() ==
          rec[fields[1]]?.toLowerCase()
      );
      this.field.NSP_List_Employee_Names_Levies__c = this.getCSVFromObjectList(
        onlyEmpRequestedRec,
        fields[0]
      );
    }
  }

  getCSVFromObjectList(arr, fieldName) {
    return arr.map((obj) => obj[fieldName]).join(',');
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
        .map((rec) => `${rec[fields[0]]}~${rec[fields[2]]}`)
        .join(',');
    }
  }

  handlePayFrequencyAddRow({ target }) {
    const i = Number.parseInt(target.dataset.index) + 1;
    this.payFrequencyRecordIds.splice(i, 0, {
      Id: '',
      uid: Math.random(),
      fieldValues: { Frequency__c: undefined },
    });
    this.payFrequencyRecordIds = [...this.payFrequencyRecordIds];
  }

  handlePayFrequencyDeleteRow({ target }) {
    if (this.payFrequencyRecordIds.length > 1) {
      const i = Number.parseInt(target.dataset.index);
      this.payFrequencyRecordIds.splice(i, 1);
      this.payFrequencyRecordIds = [...this.payFrequencyRecordIds];
    }
  }

  isCheckedNewValueInMultiPick(fieldName, value) {
    if ((this.field[fieldName] == undefined && value != '') || (this.field[fieldName] != undefined &&
      this.field[fieldName].toString().split(';').length < value.toString().split(',').length && value != '') || (value != '' && this.field[fieldName] == '')) {
      return true;
    } else {
      return false;
    }
  }

  doFieldSpecificAction(fieldName, value) {
    if (fieldName === 'Insperity_pay_frequency__c' && this.isCheckedNewValueInMultiPick(fieldName, value)) {
      this.addPayFrequencyInForm(this.getNewCheckedValue(
        value,
        this.field.Insperity_pay_frequency__c
      ));
    }
  }

  addPayFrequencyInForm(frequency) {
    this.payFrequencyRecordIds.push({
      Id: '',
      uid: Math.random(),
      fieldValues: {
        Frequency__c: frequency,
      },
    });
  }

  getNewCheckedValue(newList, oldList) {
    if (oldList == undefined && newList != '') {
      return newList.toString().split(',')[0];
    } else {
      return newList.toString().split(',').filter(function (obj) {
        return oldList.toString().split(';').indexOf(obj) === -1;
      })[0];
    }
  }

  get inputFields() {
    return this.template.querySelectorAll('lightning-input-field');
  }

  get objectApiName() {
    return IP_OBJECT.objectApiName;
  }

  get empTableFields() {
    return EMP_TABLE_FIELDS;
  }

  get label() {
    return LABELS;
  }

  get empDataTables() {
    return this.template.querySelectorAll('c-nsp_employee-data');
  }

  get empDataRlFields() {
    return EMP_DATA_RL_FIELDS;
  }

  get payFrequencyForms() {
    return this.template.querySelectorAll('c-nsp_pay-frequency-form');
  }

  get payFrequencyValues() {
    const formValues = [];

    this.payFrequencyForms.forEach((form) => {
      const valueObj = form.getFormValues();
      if (Object.keys(valueObj).length) {
        formValues.push(valueObj);
      }
    });

    return formValues;
  }

  updatePayFrequencyOnIPRecord() {
    const formValues = this.payFrequencyValues;
    if (formValues.length > 0 && formValues[0][PAY_FREQUENCY_FIELDS.Does_the_client_have_prior_wages__c]) {
      this.field.NSP_Does_the_client_have_prior_wages__c = formValues[0][PAY_FREQUENCY_FIELDS.Does_the_client_have_prior_wages__c];
    }
  }

  get checkIfIpisActive() {
    return this.userData?.Profile?.displayValue !== LABELS.SYSTEM_ADMIN && this.fieldValues && this.fieldValues?.NSP_Inactive__c?.value
  }
}