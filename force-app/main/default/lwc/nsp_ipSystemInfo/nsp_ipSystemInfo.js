import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import * as LABELS from 'c/nsp_implementationLabels';
import { DYNAMIC_FIELDS,SECTION_FIELDS } from './dynamicFieldsConfig';

import {
  getUpdatedFieldVisibility,
  getFieldStylesByHierarchy,
  isMultiSelectCheckbox,
  isSelectionBox,
  ANSWERED_CLASS_NAME,
} from 'c/nsp_utils';

export default class Nsp_ipSystemInfo extends LightningElement {
  @api recordId;
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

    if (this.inputFields) {
      this.inputFields.forEach(({ fieldName, value }) => {
        formValues[fieldName] = value;
      });
    }

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
  }

  handleValueChange({ detail, target }) {
    const fieldName = target.dataset.name;
    const value = detail.value || detail.checked;

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

    if (elm) {
      if (isSelectionBox(target)) {
        elm.className = value ? ANSWERED_CLASS_NAME : null;
      } else {
        if (value) {
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
      this.visibility = { ...this.visibility, ...updatedValues };
    }
  }

  get objectApiName() {
    return IP_OBJECT.objectApiName;
  }

  get label() {
    return LABELS;
  }

  objFields;
  @api get objectInfo() {
    return this.objFields;
  }
  set objectInfo(value) {
    if (value) {
      this.objFields = value;
    }
  }

  _recordTypeId;
  @api get recordTypeId() {
    return this._recordTypeId;
  }
  set recordTypeId(value) {
    this.field['RecordTypeId'] = value ? value : '';
  }

  get options() {
    var recordtypeinfo = this.objFields?.recordTypeInfos;
    var uiCombobox = [];
    for (var eachRecordtype in recordtypeinfo) {
      if (
        recordtypeinfo.hasOwnProperty(eachRecordtype) &&
        recordtypeinfo[eachRecordtype].name !== 'Master'
      )
        uiCombobox.push({
          label: recordtypeinfo[eachRecordtype].name,
          value: recordtypeinfo[eachRecordtype].recordTypeId,
        });
    }
    return uiCombobox;
  }
}