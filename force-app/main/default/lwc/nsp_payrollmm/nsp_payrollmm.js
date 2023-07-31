import { LightningElement, api, track, wire } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import PAY_PERIOD_OBJECT from '@salesforce/schema/Implementation_Pay_Period__c';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import { LABEL, HELP_TEXT } from './constants';
import * as LABELS from 'c/nsp_implementationLabels';
import {
  RL_FIELDS,
  EMP_TABLE_FIELDS,
  PREFILLED_FIELDS,
  SYNC_FIELDS,
  POST_SYNC_IP_FIELDS,
  SECTION_FIELDS,
  UNEMPLOYMENT_TAX_STATES,
  PHONE_NUMBER_FIELDS,
  BACKUP_PC_FIELDS,
  COPY_FIELDS_MAPPING
} from './fields';
import IP_EMP_DATA_OBJECT from '@salesforce/schema/NSP_Employee_Data__c';

import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  ANSWERED_CLASS_NAME,
  RL_CLASS_NAME,
  RL_FIELD_ACCEPTED_VALUES,
  isNonEmptyArray,
  toNorthAmericanPhoneNumber,
} from 'c/nsp_utils';

export default class Nsp_payrollmm extends LightningElement {
  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @api empData;
  @api error;
  @api readOnlyMode = false;
  @api disabledFields = {};
  @api userData;
  @track field = {};
  @track visibility = {};
  @track styles = getFieldStylesByHierarchy(DYNAMIC_FIELDS);
  @track state = {
    isLoadingFirstTime: true,
  };
  @track empStateLabelValueMap = {};
  @track formattedValue = {};
  @track disabled = {};
  @track _sectionData;

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
    if (values &&  values.fieldName) {
      const { fieldName, value } = values;
      const localFieldName = SYNC_FIELDS[fieldName];
      if (Object.keys(SYNC_FIELDS).includes(fieldName)) {
        this.field[localFieldName] = value;
      }
      const dataType = this.objFields[fieldName]?.dataType;
      const updatedValue =
          dataType == 'MultiPicklist' ? value.split(';') : value;
      this.updateDependentFieldVisibility(localFieldName, updatedValue);
      this.postSyncOperations(fieldName, value);
      this.addStyleToPrePopulatedQuestions(fieldName, value);
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
        this.payFrequencyRecordIds.push({ Id: element, fieldValues: {}, uid : Math.random() });
      });
    }
  }

  @api
get sectionsData(){
  return this._sectionsData;
}
set sectionsData(value){
  this._sectionData = value;
    if(value && Object.keys(value).length){
      this.doDataSpecificActions(value);
  }
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
      this.doFieldSpecificAction(fieldName,value);
      this.field[fieldName] = isMultiSelectCheckbox(target)
        ? value.join(';')
        : value;
      this.updateDependentFieldVisibility(fieldName, value);
      this.addStyleToAnsweredQuestion(target, value);
    } catch (error) {
      this.error = error;
    }
  }

  handlePayFrequencyAddRow({ target }) {
    const i = Number.parseInt(target.dataset.index) + 1;
    this.payFrequencyRecordIds.splice(i, 0, {
      Id: '',
      uid : Math.random(),
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

  handleCheckBoxChange({ detail, target }) {
    const { fieldName } = target;

    this.field[fieldName] = detail.checked;
    if( target.fieldName === 'NSP_PC_is_same_as_OSS__c' &&  detail.checked){
      this.dispatchEvent( new CustomEvent(  'refreshsectiondata', {detail: 'clientInformation'}));
    }

    if (target.fieldName === 'NSP_No_back_up_PC__c' ) {
      this.makeBackupPCdisable(detail.checked);
    }
    this.addStyleToAnsweredQuestion(target, detail.checked); //added as part of STY-03065
  }

  handlePhoneFieldFocus({ target }) {
    const fieldName = target.dataset.name;
    this.formattedValue[fieldName] = this.field[fieldName];
  }

  handlePhoneFieldBlur({ target }) {
    const fieldName = target.dataset.name;
    this.formattedValue[fieldName] = toNorthAmericanPhoneNumber(
      this.field[fieldName]
    );
  }

  makeBackupPCdisable(isCheckedOrNot) {
    this.assignValueToMultipleFields(
      BACKUP_PC_FIELDS,
      this.disabled,
      isCheckedOrNot
    );
    if (isCheckedOrNot) {
      this.assignValueToMultipleFields(BACKUP_PC_FIELDS, this.field, null);
      this.addOrRemoveAnsweredClass(BACKUP_PC_FIELDS, true);
    } else {
      this.addOrRemoveAnsweredClass(BACKUP_PC_FIELDS, false);
    }
  }

  assignValueToMultipleFields(fieldNames, targetObj, value) {
    fieldNames.forEach((fieldName) => {
      targetObj[fieldName] = value;
    });
  }

  addOrRemoveAnsweredClass(fieldNames, add) {
    fieldNames.forEach((fieldName) => {
      const elm = this.template.querySelector(`[data-name=${fieldName}]`);
      if (elm) {
        if (add) {
          elm.classList.add(ANSWERED_CLASS_NAME);
        } else {
          elm.classList.remove(ANSWERED_CLASS_NAME);
        }
      }
    });
  }

  handleError(error) {
    this.error = error;
  }

  doDataSpecificActions(value){
      if(this.fieldValues.NSP_PC_is_same_as_OSS__c){
            this.copyOSSValuesInTarget(value.clientInformation);
      }
    }

    copyOSSValuesInTarget(srcValues){  
      Object.keys(COPY_FIELDS_MAPPING).forEach(fieldName => {
        const parentFieldName = COPY_FIELDS_MAPPING[fieldName];
        const value = srcValues[parentFieldName];
        this.field[fieldName] = value;

        if(PHONE_NUMBER_FIELDS.includes(fieldName)){
          this.formattedValue[fieldName] = toNorthAmericanPhoneNumber( value );        
        }

        this.addStyleToPrePopulatedQuestions(fieldName, value);
      });
    }

  doOneTimeActions() {
    if (this.fieldValues) {
      Object.keys(this.fieldValues).forEach((fieldName) => {
        const { value } = this.fieldValues[fieldName];

        if (SECTION_FIELDS.includes(fieldName) && value) {
          this.field[fieldName] = value;
          if (PHONE_NUMBER_FIELDS.includes(fieldName)) {
            this.formattedValue[fieldName] = toNorthAmericanPhoneNumber(value);
          }
          const dataType = this.objFields[fieldName]?.dataType;
          const updatedValue =
            dataType == 'MultiPicklist' ? value.split(';') : value;
          this.updateDependentFieldVisibility(fieldName, updatedValue);
          this.addStyleToPrePopulatedQuestions(fieldName, value);
        }
      });
      
      const empWorkState =
      this.fieldValues['Employees_work_in_the_following_states__c']?.value;
      if (empWorkState) {
        this.field.employeesWorkStates = empWorkState;
        this.updateEmployeesWorkStates(empWorkState);
      }

      if (this.fieldValues.NSP_No_back_up_PC__c?.value) {
        this.makeBackupPCdisable(true);
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

  addPayFrequencyInForm(frequency) {
    this.payFrequencyRecordIds.push({
      Id: '',
      uid: Math.random(),
      fieldValues: {
        Frequency__c: frequency,
      },
    });
  }

  updateEmployeesWorkStates(value) {
    const stateCodes = value.split(';');

    this.field.employeesWorkStatesUnemployment = null;
    this.field.NSP_employees_working_unemployment_tax_IL = stateCodes.includes('IL');

    const selectedUnemployeeTaxStates = stateCodes.filter((stateCode) =>
    UNEMPLOYMENT_TAX_STATES.includes(stateCode)
    );
    if (selectedUnemployeeTaxStates.length) {
      const stateNames = selectedUnemployeeTaxStates.map(
        (stateCode) => this.empStateLabelValueMap[stateCode]
      );

      this.field.employeesWorkStatesUnemployment = stateNames.join(', ');
    }
  }

  get employeesWorkStatesLabelIL(){
    return this.label.selectedStateLabelIllinois
  }

  get employeesWorkStatesLabel() {
    return this.label.selectedStatesLabel.replace(
      '__states__',
      this.field.employeesWorkStatesUnemployment
    );
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
      this.field.NSP_EE_Name__c = this.getCSVFromObjectList(
        empDataRecords,
        fields[0]
      );
    }
  }

  getCSVFromObjectList(arr, fieldName) {
    return arr.map((obj) => obj[fieldName]).join(',');
  }

  isCheckedNewValueInMultiPick(fieldName,value){
    if ((this.field[fieldName] == undefined && value != '') || (this.field[fieldName] != undefined &&
      this.field[fieldName].toString().split(';').length < value.toString().split(',').length && value != '') || (value != '' && this.field[fieldName] == '')){
         return true;
       }else{
         return false;
       }
   }
   doFieldSpecificAction(fieldName, value) {
     if (fieldName === 'Insperity_pay_frequency__c' && this.isCheckedNewValueInMultiPick(fieldName,value)) {
      this.payFrequencyRecordIds.push({
        Id: '',
        uid : Math.random(),
        fieldValues: {
          Frequency__c: this.getNewCheckedValue(
            value,
            this.field.Insperity_pay_frequency__c
          ),
        },
      });     }
   } 
   getNewCheckedValue(newList,oldList){
     if(oldList == undefined && newList != ''){
       return newList.toString().split(',')[0];
     }else{
       return newList.toString().split(',').filter(function (obj) {
         return oldList.toString().split(';').indexOf(obj) === -1;
       })[0];
     }
   }

  get label() {
    return LABELS;
  }

  get title() {
    return LABEL.payroll;
  }

  get objectApiName() {
    return IP_OBJECT.objectApiName;
  }

  get inputFields() {
    return this.template.querySelectorAll('lightning-input-field');
  }

  get helpText() {
    return HELP_TEXT;
  }

  get empDataTables() {
    return this.template.querySelectorAll('c-nsp_employee-data');
  }

  get empTableFields() {
    return EMP_TABLE_FIELDS;
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
  
  get checkIfIpisActive(){
    return this.userData?.Profile?.displayValue !== LABELS.SYSTEM_ADMIN && this.fieldValues && this.fieldValues?.NSP_Inactive__c?.value
  }

  get messageApplet(){
    if(!this.field.NSP_Employees_with_multiple_types_of_pay__c){
      return false;
    }

    this.multiplePay = this.field.NSP_Employees_with_multiple_types_of_pay__c.split(';');
    return this.multiplePay.includes('Piece Rate') && this.field.employeesWorkStates.split(';').includes('CA');
  }
}