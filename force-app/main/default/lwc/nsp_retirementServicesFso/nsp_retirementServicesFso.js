import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import IP_EMP_DATA_OBJECT from '@salesforce/schema/NSP_Employee_Data__c';
import { EMP_TABLE_FIELDS, SECTION_FIELDS } from './fields';
import * as LABELS from 'c/nsp_implementationLabels';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  isSelectionBox,
  ANSWERED_CLASS_NAME,
  isNonEmptyArray,
} from 'c/nsp_utils';

export default class Nsp_retirementServicesFso extends LightningElement {
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
    }
  }

  removeValuesFromHiddenFields(fieldName, value, isParentField) {
    const fieldConfig = DYNAMIC_FIELDS[fieldName];
    
    if (fieldConfig) {
      fieldConfig.forEach(({ dependentFields, expValue }) => {
        dependentFields
          .filter((fieldApiName) => fieldApiName !== fieldName)
          .forEach((fieldApiName) => {
            if (!isParentField) {
              if (isNonEmptyArray(value)) {
                value.forEach((val) => {
                  if (!expValue.includes(val)) {
                    this.field[fieldApiName] = null;
                  }
                });
              } else if (value && !expValue.includes(value)) {
                this.field[fieldApiName] = null;
              }
            } else {
              this.field[fieldApiName] = null;
              this.visibility[fieldApiName] = false;
            }
            this.removeValuesFromHiddenFields(fieldApiName, null, true);
          });
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
    const { Client_working_with_an_NSP_RS_rep__c, NSP_Is_the_client_working_an_NSP_RS_rep__c } = fieldSpecificRecords;
      if(isNonEmptyArray(Client_working_with_an_NSP_RS_rep__c)){
        this.updateRsContactDetails(
          Client_working_with_an_NSP_RS_rep__c,
          EMP_TABLE_FIELDS.Client_working_with_an_NSP_RS_rep__c
        );
      }
      if(isNonEmptyArray(NSP_Is_the_client_working_an_NSP_RS_rep__c)){
        this.updateRsContactDetails(NSP_Is_the_client_working_an_NSP_RS_rep__c, 
          EMP_TABLE_FIELDS.NSP_Is_the_client_working_an_NSP_RS_rep__c);
      }
    const postUpsertRecords = this.field.postUpsertRecords || {};
    postUpsertRecords[IP_EMP_DATA_OBJECT.objectApiName] = allEmployeeRecords;
    this.field.postUpsertRecords = postUpsertRecords;
  }

  updateRsContactDetails(empDataRecords, fields) {
    if (empDataRecords) {
      this.field.NSP_RS_Contact__c = empDataRecords
        .map((rec) => `${rec[fields[0]]}`)
        .join(',');
    }
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

  get checkIfIpisActive(){
    return this.userData?.Profile?.displayValue !== LABELS.SYSTEM_ADMIN && this.fieldValues && this.fieldValues?.NSP_Inactive__c?.value
  }
}