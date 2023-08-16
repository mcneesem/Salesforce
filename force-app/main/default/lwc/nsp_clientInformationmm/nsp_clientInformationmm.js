import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import IP_CLIENT_RELATED_CLIENT from '@salesforce/schema/NSP_IP_Related_Client__c';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import { LABEL } from './constants';
import * as LABELS from 'c/nsp_implementationLabels';
import ADDITIONAL_CLIENT_CONTACTS from '@salesforce/schema/NSP_IP_Additional_Client_Contact__c';
import {
  RL_FIELDS,
  FIELD_CHANGE_HANDLER_MAPPING,
  PREFILLED_FIELDS,
  POST_SYNC_IP_FIELDS,
  SYNC_FIELDS,
  SECTION_FIELDS,
  BACKUP_PC_FIELDS,
  PHONE_NUMBER_FIELDS,
  IP_CLIENT_RELATED_CLIENT_FIELDS,
  DEPENDENT_FIELDS_MAPPING,
  ADDITIONAL_CLIENT_CONTACTS_FIELDS,
} from './fields';
import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  ANSWERED_CLASS_NAME,
  RL_CLASS_NAME,
  RL_FIELD_ACCEPTED_VALUES,
  getClientFEINValue,
  onFEINKeyPress,
  toNorthAmericanPhoneNumber,
  isNonEmptyArray,
} from 'c/nsp_utils';

export default class Nsp_clientInformationmm extends LightningElement {
  @api recordId;
  @api error;
  @api recordTypeId;
  @api fieldValues = {};
  @api ipClientRelatedClient;
  @api addnClientContactRecords;

  @track field = {};
  @track visibility = {};
  @track formattedValue = {};

  @track styles = getFieldStylesByHierarchy(DYNAMIC_FIELDS);
  @track state = {
    isLoadingFirstTime: true,
  };

  @track disabled = {};

  @api
  get disabledFields() {
    return this.disabled;
  }
  set disabledFields(value) {
    if (value && Object.keys(value).length) {
      this.disabled = JSON.parse(JSON.stringify(value));
    }
  }

  @api getFormValues() {
    const formValues = {};

    this.inputFields.forEach(({ fieldName, value }) => {
      formValues[fieldName] = value;
    });

    if(this.ipRelatedClientElm){
      this.updatePostUpsertRecords(
        IP_CLIENT_RELATED_CLIENT.objectApiName,
        this.ipRelatedClientElm.getAllRecords()
      );
      this.updateRelatedClientsOnIPRecord();
    }
  
    if(this.addnClientContactsElm){
      this.updatePostUpsertRecords(
        ADDITIONAL_CLIENT_CONTACTS.objectApiName,
        this.addnClientContactsElm.getAllRecords()
      );
    }

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
          const fieldValue = values[fieldName];
          const value =
            typeof fieldValue === 'string' || fieldValue instanceof String
              ? fieldValue.trim()
              : fieldValue;
          this.field[fieldName] = value;
          this.addStyleToPrePopulatedQuestions(fieldName, value);
        }
      });
    }
  }

  getClientFEINValue = getClientFEINValue;
  onFEINKeyPress = onFEINKeyPress;

  handleLoad() {
    const { state } = this;

    if (state.isLoadingFirstTime) {
      state.isLoadingFirstTime = false;
      this.doOneTimeActions();
    }
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

  handleValueChange({ detail, target }) {
    try {
      const fieldName = target.dataset.name;
      const { value } = detail;
      const fnName = FIELD_CHANGE_HANDLER_MAPPING[fieldName];

      if (value && fnName && fnName in this) {
        this.field[fieldName] = this[fnName](fieldName, value);
      } else {
        this.field[fieldName] = isMultiSelectCheckbox(target)
          ? value.join(';')
          : value;
      }

      this.updateDependentFieldVisibility(fieldName, value);
      this.addStyleToAnsweredQuestion(target, value);
    } catch (error) {
      this.error = error;
    }
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
      if (this.fieldValues.NSP_No_back_up_PC__c?.value) {
        this.makeBackupPCdisable(true);
      }
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

  updatePostUpsertRecords(objectApiName, records) {
    if (isNonEmptyArray(records)) {
      const postUpsertRecords = this.field.postUpsertRecords || {};

      postUpsertRecords[objectApiName] = records;
      this.field.postUpsertRecords = postUpsertRecords;
    }
  }

  updateRelatedClientsOnIPRecord() {
    this.field.NSP_Related_Clients__c = this.ipRelatedClientElm.getAllRecords()
    .map((rec) => `${rec.NSP_Related_Client__c}`)
    .join(', ');
  }

  get ipRelatedClientElm(){
    return this.template.querySelector(
      'c-nsp_record-form[data-id=ipRelatedClients]'
    );
  }

  get title() {
    return LABEL.clientInformation;
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

  get ipRelatedClientApiName(){
    return IP_CLIENT_RELATED_CLIENT.objectApiName;
  }

  get ipRelatedClientFields(){
    return IP_CLIENT_RELATED_CLIENT_FIELDS;
  }
  
  get addnClientContactsFields() {
    return ADDITIONAL_CLIENT_CONTACTS_FIELDS;
  }
  
  get addnClientContactsObjectApiName() {
    return ADDITIONAL_CLIENT_CONTACTS.objectApiName;
  }
  
  get addnClientContactsElm() {
    return this.template.querySelector(
      'c-nsp_record-form[data-id=addnClientContacts]'
    );
  }

  get checkIfIpisActive(){
    return this.userData?.Profile?.displayValue !== LABELS.SYSTEM_ADMIN && this.fieldValues && this.fieldValues?.NSP_Inactive__c?.value
  }
}