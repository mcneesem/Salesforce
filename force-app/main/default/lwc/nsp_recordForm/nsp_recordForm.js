import { LightningElement, api, track, wire } from 'lwc';
import horizontalFormTemplate from './horizontalForm.html';
import verticalFormTemplate from './verticalForm.html';
import {
  RL_FIELD_ACCEPTED_VALUES,
  ANSWERED_CLASS_NAME,
  isNonEmptyArray,
  RL_CLASS_NAME,
} from 'c/nsp_utils';

import { getRecords } from 'lightning/uiRecordApi';

export default class Nsp_recordForm extends LightningElement {
  @api title;
  @api objectApiName;
  @api fields;
  @api variant = 'horizontal';
  @api rlFields = [];
  @api fieldsGroup;
  @api error;
  @api disabled;

  @track recordIDs = [''];
  @track fieldValue = {};

  @api
  get records() {
    return this.recordIDs;
  }
  set records(value) {
    if (isNonEmptyArray(value)) {
      this.recordIDs = [...value];
    }
  }

  @api getAllRecords() {
    const allRecords = [];

    this.recordForms.forEach((recForm) => {
      const fields = {};

      recForm.querySelectorAll('lightning-input-field').forEach((field) => {
        fields[field.fieldName] = field.value;
      });

      if (this.recHasAnyValue(fields)) {
        allRecords.push(fields);
      }
    });

    return allRecords;
  }

  @wire(getRecords, {
    records: '$recordsParam',
  })
  getRecordsCallback({ data, error }) {
    if (data) {
      this.addStylesToPopulatedFields(data);
    }
    if (error) {
      this.error = error;
    }
  }

  render() {
    return this.isVerticalForm ? verticalFormTemplate : horizontalFormTemplate;
  }

  handleAddRow({ target }) {
    const i = Number.parseInt(target.dataset.index) + 1;
    this.recordIDs.splice(i, 0, '');
  }

  handleDeleteRow({ target }) {
    if (this.recordIDs.length > 1) {
      const i = Number.parseInt(target.dataset.index);
      this.recordIDs.splice(i, 1);
    }
  }

  handleValueChange({ detail, target }) {
    const fieldName = target.dataset.name;
    const { classList } = target;
    const { value } = detail;

    const isValuePresent = Array.isArray(value) ? !!value.length : !!value;
    const className = this.getLabelClassName(fieldName, value);

    classList.remove(ANSWERED_CLASS_NAME);
    classList.remove(RL_CLASS_NAME);

    if (isValuePresent) {
      classList.add(className);
    }
  }

  getLabelClassName(fieldName, value) {
    return this.rlFields.includes(fieldName) &&
      RL_FIELD_ACCEPTED_VALUES.includes(value)
      ? RL_CLASS_NAME
      : ANSWERED_CLASS_NAME;
  }

  addStylesToPopulatedFields(data) {
    const successRecords = data.results
      .filter(({ statusCode }) => statusCode === 200)
      .map(({ result }) => result);

    successRecords.forEach(({ fields, id }) => {
      Object.keys(fields).forEach(fieldName => {
        const { value } = fields[fieldName];
        if (value) {
          const elmSelector = `lightning-record-edit-form[data-id=${id}] lightning-input-field[data-name=${fieldName}]`;
          const elm = this.template.querySelector(elmSelector);
          if (elm) {
            const className = this.getLabelClassName(fieldName, value);
            elm.classList.add(className);
          }
        }
      });
    });
  }

  recHasAnyValue(record) {
    return !!Object.values(record).filter((i) => !!i).length;
  }

  getFieldsFromGroup(fieldsGroup){
    const fields = [];

    fieldsGroup.forEach(fieldsArray => {
      fieldsArray.forEach(fieldName => {
        fields.push(fieldName);
      })
    });

    return fields;
  }

  get recordForms() {
    return this.template.querySelectorAll('lightning-record-edit-form');
  }

  get isVerticalForm() {
    return this.variant === 'vertical';
  }

  get isHorizontalForm() {
    return this.variant === 'horizontal';
  }

  get isRequiredDataAvailable() {
    return (
      this.objectApiName &&
      isNonEmptyArray(this.fields) &&
      isNonEmptyArray(this.recordIDs)
    );
  }

  get recordIdList() {
    return this.isRequiredDataAvailable ? this.recordIDs : null;
  }

  get recordsParam() {
    const { recordIDs, objectApiName, fields, fieldsGroup } = this;

    if (isNonEmptyArray(recordIDs) && objectApiName && (fields || fieldsGroup)) {
      const fieldNames = fieldsGroup ? this.getFieldsFromGroup(fieldsGroup) : fields;
      const fieldFullNames = fieldNames.map(
        (fieldName) => `${objectApiName}.${fieldName}`
      );

      return [
        {
          recordIds: recordIDs,
          fields: fieldFullNames,
        },
      ];
    }

    return [];
  }
}
