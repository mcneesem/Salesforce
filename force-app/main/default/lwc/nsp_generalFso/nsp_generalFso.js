import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import * as LABELS from 'c/nsp_implementationLabels';
import IP_CLIENT_RELATED_CLIENT from '@salesforce/schema/NSP_IP_Related_Client__c';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import {
  SYNC_FIELDS,
  RL_FIELDS,
  FIELD_CHANGE_HANDLER_MAPPING,
  PREFILLED_FIELDS,
  POST_SYNC_IP_FIELDS,
  SECTION_FIELDS,
  IP_CLIENT_RELATED_CLIENT_FIELDS
} from './fields';

import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  ANSWERED_CLASS_NAME,
  SYNC_FIELD_EVENT_NAME,
  RL_CLASS_NAME,
  RL_FIELD_ACCEPTED_VALUES,
  getClientFEINValue,
  onFEINKeyPress,
  isNonEmptyArray,
} from 'c/nsp_utils';

export default class Nsp_generalFso extends LightningElement {
  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @api disabledFields = {};
  @api ipClientRelatedClient;
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

    if(this.ipRelatedClientElm){
      this.updatePostUpsertRecords(
        IP_CLIENT_RELATED_CLIENT.objectApiName,
        this.ipRelatedClientElm.getAllRecords()
      );
      this.updateRelatedClientsOnIPRecord();
    }
    return { ...formValues, ...this.field };
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

  _objectInfo;
  @api get objectInfo() {
    return this._objectInfo;
  }
  set objectInfo(value) {
    if (value) {
      this._objectInfo = value?.fields;
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

  handleError(error) {
    this.error = error;
  }

  handleValueChange({ detail, target }) {
    const fieldName = target.dataset.name;
    const value  = detail.value ;
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
    this.publishSyncEvent(fieldName);
  }

  publishSyncEvent(fieldName) {
    if (Object.values(SYNC_FIELDS).includes(fieldName)) {
      let value = this.field[fieldName];
      if (fieldName == 'Select_BPSes__c' && value) {
        const itemsTobeRemoved = ['Employment Screening', 
                                  'Certify', 
                                  'Expense Management',
                                  'Organization Planning',
                                  'Insurance Services',
                                  'Recruiting Services',
                                  'Payroll Services (non co-employment/WOSS)',
                                  'International Payroll Services',
                                  'Premier Performance'];
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
      .replace(RL_CLASS_NAME, '');
  }

  updatePostUpsertRecords(objectApiName, records) {
    if (isNonEmptyArray(records)) {
      const postUpsertRecords = this.field.postUpsertRecords || {};

      postUpsertRecords[objectApiName] = records;
      this.field.postUpsertRecords = postUpsertRecords;
    }
  }

  get ipRelatedClientElm(){
    return this.template.querySelector(
      'c-nsp_record-form[data-id=ipRelatedClients]'
    );
  }

  get inputFields() {
    return this.template.querySelectorAll('lightning-input-field');
  }

  get title() {
    return LABELS.clientProject;
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

  updateRelatedClientsOnIPRecord() {
    this.field.NSP_Related_Clients__c = this.realtedClients.getAllRecords()
            .map((rec) => `${rec.NSP_Related_Client__c}`)
            .join(', ');
  }

  get realtedClients() {
    return this.template.querySelector('c-nsp_record-form');
  }

  get checkIfIpisActive(){
    return this.userData?.Profile?.displayValue !== LABELS.SYSTEM_ADMIN && this.fieldValues && this.fieldValues?.NSP_Inactive__c?.value
  }
}