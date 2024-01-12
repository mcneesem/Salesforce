import { LightningElement, api, track } from 'lwc';
import EMP_DATA_OBJECT from '@salesforce/schema/NSP_Employee_Data__c';
import {
  RL_FIELD_ACCEPTED_VALUES,
  ANSWERED_CLASS_NAME,
  RL_CLASS_NAME,
} from 'c/nsp_utils';

export default class Nsp_employeeData extends LightningElement {
  @api title;
  @api readOnlyMode = false;
  @api fields;
  @api parentField;
  @api rlFields = [];
  @api disabled;

  @track recordIDs = [''];
  @track recordsMap = [{ id: '', uid: 0 }];
  @track formLoaded = [];

  @api
  get records() {
    return this.recordIDs;
  }
  set records(value) {
    if (value && Array.isArray(value) && value.length > 0) {
      this.recordIDs = [...value];
      this.recordsMap = this.recordIDs.map((id, i) => { return { id, uid: i } });
    }
  }

  @api getAllRecords(ipRecordId) {
    const allRecords = [];
    this.template
      .querySelectorAll('lightning-record-edit-form')
      .forEach((recForm) => {
        const fields = { NSP_Implementation_Profile__c: ipRecordId };

        recForm.querySelectorAll('lightning-input-field').forEach((field) => {
          fields[field.fieldName] = field.value;
        });

        if (this.recHasAnyValue(fields)) {
          allRecords.push(fields);
        }
      });

    return allRecords;
  }

  handleLoad({ target }) {
    const { uid } = target.dataset;

    this.formLoaded = [Number.parseInt(uid), ...this.formLoaded];

    if (!target.recordId) {
      return;
    }

    target.querySelectorAll('lightning-input-field').forEach((field) => {
      if (field.value) {
        const className = this.getLabelClassName(field.fieldName, field.value);

        field.classList.add(className);
      }
    });
  }

  handleError(error, target) {
    const { uid } = target.dataset;

    this.formLoaded = [Number.parseInt(uid), ...this.formLoaded];
    this.dispatchEvent(new CustomEvent('error', { detail: error?.detail?.message }));
  }

  handleAddRow({ target }) {
    const i = Number.parseInt(target.dataset.index) + 1;
    this.recordIDs.splice(i, 0, '');
    this.recordsMap.splice(i, 0, { id: '', uid: this.uniqueId });
  }

  handleDeleteRow({ target }) {
    if (this.recordIDs.length > 1) {
      const i = Number.parseInt(target.dataset.index);
      this.recordIDs.splice(i, 1);
      this.recordsMap.splice(i, 1);
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

  recHasAnyValue(record) {
    return this.fields.reduce((validSoFar, fieldName) => {
      return validSoFar || !!record[fieldName];
    }, false);
  }

  get uniqueId() {
    const excludedSet = new Set(this.existingUIDs);

    while (true) {
      const randomNumber = Math.floor(Math.random() * 100) + 1;

      if (!excludedSet.has(randomNumber)) {
        return randomNumber;
      }
    }
  }

  get objectApiName() {
    return EMP_DATA_OBJECT.objectApiName;
  }

  get isLoading() {
    if (!this.recordsMap?.length) {
      return false;
    }

    let isLoadingFlag = false;

    this.existingUIDs.forEach(uid => {
      if (!this.formLoaded.includes(uid)) {
        isLoadingFlag = true;
      }
    });

    return isLoadingFlag;
  }

  get existingUIDs() {
    return this.recordsMap.map(({ uid }) => uid);
  }
}
