import { LightningElement, api, track } from 'lwc';
import * as LABELS from 'c/nsp_implementationLabels';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import ADDITIONAL_CLIENT_CONTACTS from '@salesforce/schema/NSP_IP_Additional_Client_Contact__c'

import {
  isMultiSelectCheckbox,
  isSelectionBox,
  ANSWERED_CLASS_NAME,
  getFieldApiNameMapIndexedByLocalName,
  toNorthAmericanPhoneNumber,
  isNonEmptyArray
} from 'c/nsp_utils';
import { BACKUP_PC_FIELDS, SECTION_FIELDS, PHONE_NUMBER_FIELDS,ADDITIONAL_CLIENT_CONTACTS_FIELDS,DEPENDENT_FIELDS_MAPPING } from './fields';

export default class Nsp_clientContactsFso extends LightningElement {
  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @api addnClientContactRecords;

  @track state = {
    isLoadingFirstTime: true,
  };
  @track field = {};
  @track styles = {};
  @track disabled = {};
  @track fieldNames = getFieldApiNameMapIndexedByLocalName(SECTION_FIELDS);
  @track formattedValue = {};
  @api 
  get disabledFields(){
    return this.disabled;
  }
  set disabledFields(value){
    if (value && Object.keys(value).length) {
      this.disabled = JSON.parse(JSON.stringify(value));
    }
  }

  @api getFormValues() {
    const formValues = {};

    this.inputFields.forEach(({ fieldName, value }) => {
      formValues[fieldName] = value;
    });

    this.updatePostUpsertRecords(
      ADDITIONAL_CLIENT_CONTACTS.objectApiName,
      this.addnClientContactsElm.getAllRecords()
    );

    return { ...formValues, ...this.field };
  }

  _objectInfo;
  @api get objectInfo() {
    return this._objectInfo;
  }
  set objectInfo(value) {
    if (value) {
      this._objectInfo = value?.fields;
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

    if (isMultiSelectCheckbox(target)) {
      this.field[fieldName] = value.join(';');
    } else if (Array.isArray(value)) {
      // When field is a lookup
      this.field[fieldName] = value.length ? value[0] : null;
    } else {
      this.field[fieldName] = value;
    }
    this.addStyleToAnsweredQuestion(target, value);
  }

  handleCheckBoxChange({ detail, target }) {
    const { fieldName } = target;
    this.field[fieldName] = detail.checked;
    if (detail.checked && Object.keys(DEPENDENT_FIELDS_MAPPING).includes(fieldName)) {
      this.copyFieldValues(DEPENDENT_FIELDS_MAPPING[fieldName]);
    }
    
    if (target.fieldName === 'NSP_No_back_up_PC__c') {
      this.makeBackupPCdisable(detail.checked);
    }
    this.addStyleToAnsweredQuestion(target, detail.checked); //added as part of STY-03065
  }

  copyFieldValues(fieldsMapping){
    Object.keys(fieldsMapping).forEach((fieldName) => {
      const parentFieldName = fieldsMapping[fieldName];
      const value = this.field[parentFieldName];
      if(PHONE_NUMBER_FIELDS.includes(fieldName)){
        this.formattedValue[fieldName] = this.formattedValue[parentFieldName];
      }

      this.field[fieldName] = value;
      this.addStyleToPrePopulatedQuestions(fieldName, value);
    });
  }

  makeBackupPCdisable(isCheckedOrNot) {
    this.assignValueToMultipleFields(BACKUP_PC_FIELDS, this.disabled, isCheckedOrNot);
    if (isCheckedOrNot) {
      this.assignValueToMultipleFields(BACKUP_PC_FIELDS, this.field, null);
      this.addOrRemoveAnsweredClass(BACKUP_PC_FIELDS, true);
    } else {
      this.addOrRemoveAnsweredClass(BACKUP_PC_FIELDS);
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
        if(add){
          elm.classList.add(ANSWERED_CLASS_NAME);
        }else{
          elm.classList.remove(ANSWERED_CLASS_NAME);
        }
      }
    });
  }

  handlePhoneFieldFocus({target}){
    const fieldName = target.dataset.name;
    this.formattedValue[fieldName] = this.field[fieldName];
  } 

  handlePhoneFieldBlur({target}){
    const fieldName = target.dataset.name;
    this.formattedValue[fieldName] = toNorthAmericanPhoneNumber(this.field[fieldName]);
  }

  doOneTimeActions() {
    if (this.fieldValues) {
      const sectionFields = Object.values(this.fieldNames);

      Object.keys(this.fieldValues)
        .filter((fieldName) => sectionFields.includes(fieldName))
        .forEach((fieldName) => {
          const { value } = this.fieldValues[fieldName];

          if ( value) {
            this.field[fieldName] = value;
            if(PHONE_NUMBER_FIELDS.includes(fieldName)){
              this.formattedValue[fieldName] = toNorthAmericanPhoneNumber(value);
            }
            this.addStyleToPrePopulatedQuestions(fieldName, value);
          }
        });

        if(this.fieldValues.NSP_No_back_up_PC__c?.value){
          this.makeBackupPCdisable(true);
        }
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

  updatePostUpsertRecords(objectApiName, records) {
    if (isNonEmptyArray(records)) {
      const postUpsertRecords = this.field.postUpsertRecords || {};

      postUpsertRecords[objectApiName] = records;
      this.field.postUpsertRecords = postUpsertRecords;
    }
  }

  get inputFields() {
    return this.template.querySelectorAll('lightning-input-field');
  }

  get addnClientContactsElm() {
    return this.template.querySelector(
      'c-nsp_record-form[data-id=addnClientContacts]'
    );
  }

  get objectApiName() {
    return IP_OBJECT.objectApiName;
  }

  get addnClientContactsObjectApiName() {
    return ADDITIONAL_CLIENT_CONTACTS.objectApiName;
  }

  get addnClientContactsFields() {
    return ADDITIONAL_CLIENT_CONTACTS_FIELDS;
  }

  get label() {
    return LABELS;
  }

  get checkIfIpisActive(){
    return this.userData?.Profile?.displayValue !== LABELS.SYSTEM_ADMIN && this.fieldValues && this.fieldValues?.NSP_Inactive__c?.value
  }
}