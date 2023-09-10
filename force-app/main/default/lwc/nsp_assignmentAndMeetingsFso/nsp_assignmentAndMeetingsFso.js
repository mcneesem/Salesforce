import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues, getObjectInfo } from 'lightning/uiObjectInfoApi';
import * as LABELS from 'c/nsp_implementationLabels';

import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import EMPLOYEE_ORIENTATION from '@salesforce/schema/Employee_Orientation__c';
import SALES_OFFICE from '@salesforce/schema/Account.NSP_Sales_Office__c';

import {
  isMultiSelectCheckbox,
  isSelectionBox,
  isNonEmptyArray,
  ANSWERED_CLASS_NAME,
} from 'c/nsp_utils';
import {
  PREFILLED_FIELDS,
  SYNC_FIELDS,
  POST_SYNC_IP_FIELDS,
} from './constants';
import { SECTION_FIELDS, EMPLOYEE_ORIENTATION_FIELDS } from './fields';

export default class Nsp_assignmentAndMeetingsFso extends LightningElement {
  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @api disabledFields = {};
  @api empOrientationRecords;

  @track state = {
    isLoadingFirstTime: true,
  };
  @track field = {};
  @track styles = {};

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
        this.field[SYNC_FIELDS[fieldName]] = value;
      }
      this.postSyncOperations(fieldName, value);
      this.addStyleToPrePopulatedQuestions(fieldName, value);
    }
  }

  @wire(getObjectInfo, { objectApiName: 'Account' })
  accObjectInfo;
  
  @wire(getPicklistValues, { recordTypeId: '$accObjectInfo.data.defaultRecordTypeId', fieldApiName: SALES_OFFICE })
  salesOfficePicklistValues;

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

  @api getFormValues() {
    const formValues = {};

    this.inputFields.forEach(({ fieldName, value }) => {
      formValues[fieldName] = value;
    });

    this.updatePostUpsertRecords(
      EMPLOYEE_ORIENTATION.objectApiName,
      this.empOrientationElm.getAllRecords()
    );

    return { ...formValues, ...this.field };
  }

  handleLoad() {
    const { state } = this;

    if (state.isLoadingFirstTime) {
      state.isLoadingFirstTime = false;
      this.doOneTimeActions();
      this.dispatchEvent(new CustomEvent('formload'));
    }
  }

  handleError(error) {
    this.dispatchEvent(new CustomEvent('error', { detail: error?.detail?.message }));
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

  doOneTimeActions() {
    if (this.fieldValues) {
      Object.keys(this.fieldValues).forEach((fieldName) => {
        const { value } = this.fieldValues[fieldName];

        if (SECTION_FIELDS.includes(fieldName) && value) {
          this.field[fieldName] = value;
          this.addStyleToPrePopulatedQuestions(fieldName, value);
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

  get empOrientationElm() {
    return this.template.querySelector(
      'c-nsp_record-form[data-id=empOrientation]'
    );
  }

  get objectApiName() {
    return IP_OBJECT.objectApiName;
  }

  get label() {
    return LABELS;
  }

  get employeeObjectApiName() {
    return EMPLOYEE_ORIENTATION.objectApiName;
  }

  get empOrientationFields() {
    return EMPLOYEE_ORIENTATION_FIELDS;
  }
  
  get checkIfIpisActive(){
    return this.userData?.Profile?.displayValue !== LABELS.SYSTEM_ADMIN && this.fieldValues && this.fieldValues?.NSP_Inactive__c?.value
  }

  get salesOfficePicklistLabel() {
    const selectedValue = this.fieldValues?.Sales_Office__c?.value; 
    if (this.salesOfficePicklistValues.data && selectedValue) {
      const selectedOption = this.salesOfficePicklistValues.data.values.find(option => option.value === selectedValue);
      return selectedOption ? selectedOption.label : '';
    }
    return '';
  }
}
