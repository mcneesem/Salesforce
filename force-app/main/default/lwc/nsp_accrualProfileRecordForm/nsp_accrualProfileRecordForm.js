import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import WORK_EMAIL_FIELD from '@salesforce/schema/Contact.NSP_Work_email__c';
import ACCRUAL_PROFILE_OBJECT from '@salesforce/schema/NSP_Accrual_Profile__c';
import NAME_FIELD from '@salesforce/schema/NSP_Accrual_Profile__c.Name';
import itaForm from './nsp_accrualProfileRecordForm.html';
import aimsForm from './nsp_accrualProfileRecordFormAIMS.html';

import {
  ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CALENDAR_YEAR,
  ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_ANNIVERSARY_YEAR,
  ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CLIENT_FISCAL_YEAR,
  ACCRUAL_LEVEL_CHANGES_FISCAL_YEAR_AIMS,
  ACCRUAL_LEVEL_CHANGES_CALENDAR_YEAR_AIMS,
  ACCRUAL_LEVEL_CHANGES_ANNIVERSARY_YEAR_AIMS,
  APAR_FIELDS,
  APG_COLUMNS,
  APG_COLUMNS_AIMS,
  APG_FIELDS,
  APG_ROWS_WITH_ZERO,
  APSR_FIELDS,
  ERROR_TOAST_CONFIG,
  INFO_MESSAGE,
  LABEL,
  STATUS_OPTIONS,
  STATUS_OPTIONS_AIMS,
  SUCCESS_TOAST_CONFIG,
  TOAST_MESSAGE,
  YES,
  SEPARATOR,
  ACTIVE_SECTIONS,
  EXISTING_FIELD_API_VALUE,
  SPECIAL_FIELDS
} from './constants';

import {
  debounce,
  prepareMapByValue,
  getUpdatedFieldVisibility,
  isNonEmptyArray,
  isMultiSelectCheckbox,
  getMultiDependentFieldVisibility
} from 'c/nsp_utils';
import { DYNAMIC_FIELDS, MULTIPLE_DEPENDENT_FIELDS } from './dynamicFieldsConfig';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getRecord, getFieldValue, createRecord } from 'lightning/uiRecordApi';

// APEX IMPORTS
import searchRecordsByFilters from '@salesforce/apex/NSP_sObjectOperationController.searchRecordsByFilters';
import upsertAndDeleteRecords from '@salesforce/apex/NSP_sObjectOperationController.upsertAndDeleteRecords';
import linkFilesToRecord from '@salesforce/apex/NSP_AccrualProfileController.linkFilesToRecord';
import getPlanOptions from '@salesforce/apex/NSP_AccrualProfileController.getPlanOptions';

export default class Nsp_accrualProfileRecordForm extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api objectApiName;
  @api isClone = false;
  @api error;
  @track state = {
    isLoading: true,
    errorMessage: null,
    recordTypeOptions: [],
  };

  @track selectedSubClients = [];
  @track selectedAccounts = [];
  @track subClientSearchResults = [];
  @track accountSearchResults = [];
  @track subClientMap = {};
  @track accountMap = {};
  @track visibility = {};
  @track fieldValue = {
    'Accrual_rates_are_based_Input_Number__c': '',
    'NSP_Status__c' : 'Draft'
  };
  @track apgDraftValues = [];
  @track unlinkedFiles = [];
  createableFields = [];
  referenceFields = [];
  multipicklistFields = [];

  planOptions = {};
  nameOfThePlanBeingReplaced;
  allAccrualProfileFields = null;
  isFirstTimeCopyAction = false;
  filesUploadedCount = 0;

  @track _apgData = [
    { NSP_From__c: 0, NSP_Completed_Months_of_Service__c: 0, uid: 0 },
  ];
  _apgDataToDelete = [];
  _apscrRecords = [];
  _aparRecords = [];
  deletedSubClients = [];
  deletedAccounts = [];
  objectFieldsInfo;
  objectInfo;

  render() {
    return this.recordTypeIdITA === this.fieldValue.recordTypeId
      ? itaForm
      : aimsForm;
  }

  @wire(CurrentPageReference)
  getPageReferenceParameters(currentPageReference) {
    if (currentPageReference && currentPageReference.state) {
      this.populatePageRefenceData(currentPageReference);
    }
  }

  @wire(getObjectInfo, { objectApiName: ACCRUAL_PROFILE_OBJECT })
  getAccrualProfileInfo({ data, error }) {
    if (data) {
      this.populateObjectInfoData(data);
    } else if (error) {
      this.error = error;
    }
  }

  @wire(getRecord, {
    recordId: '$recordId',
    fields: '$allAccrualProfileFields',
  })
  getAccrualProfileCallback({ data, error }) {
    if (data) {
      const { fields } = data;

      this.fieldValue.recordTypeId = data.recordTypeId;

      Object.keys(fields).map((fieldApiName) => {
        const { value } = fields[fieldApiName];
        this.fieldValue[fieldApiName] = value;
      });

      this.isFirstTimeCopyAction = true;

      Object.keys(this.fieldValue).map((fieldApiName) => {
        const fieldNames = Object.keys(EXISTING_FIELD_API_VALUE).filter(name => EXISTING_FIELD_API_VALUE[name] === fieldApiName);

        const value = this.fieldValue[fieldApiName];
        const dataType = this.objectFieldsInfo[fieldApiName]?.dataType;
        const updatedValue = dataType === 'MultiPicklist' ? value?.split(';') : value;

        if (isNonEmptyArray(fieldNames)) {
          fieldNames.forEach(name => this.updateDependentFieldVisibility(name, updatedValue))
        } else {
          this.updateDependentFieldVisibility(fieldApiName, updatedValue);
        }
      });

      this.isFirstTimeCopyAction = false;

      if (this.isClone) {
        this.fieldValue.NSP_Status__c = 'Draft';
      }

      this.doOneTimeActions(this.fieldValue);
    }
    if (error) {
      this.showErrorToast(error.body.message);
    }
  }

  @wire(getPlanOptions, {
    subClientIds: '$selectedSubClientIds',
  })
  getPlanOptions({ data, error }) {
    if (data) {
      this.planOptions = data;
    }
    if (error) {
      this.showErrorToast(error.body.message);
    }
  }

  @wire(getRecord, {
    recordId: '$contactFieldValue',
    fields: [WORK_EMAIL_FIELD],
  })
  getContactDetails({ data, error }) {
    if (data) {
      if (!this.fieldValue.NSP_Contact_email__c) {
        this.fieldValue.NSP_Contact_email__c = getFieldValue(
          data,
          WORK_EMAIL_FIELD
        );
      }
    }
    if (error) {
      this.showErrorToast(error.body.message);
    }
  }

  @wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: 'Accrual_Profile_Grids__r',
    fields: APG_FIELDS,
    sortBy: [APG_FIELDS[1]],
  })
  getApgRecordsCallback({ error, data }) {
    if (data) {
      this.updateApgRows(data.records);
    } else if (error) {
      this.showErrorToast(error.body.message);
    }
  }

  @wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: 'Accrual_Profile_Account_Relationships__r',
    fields: APAR_FIELDS,
  })
  getAparRecordsCallback({ error, data }) {
    if (data && !this.isClone) {
      this._aparRecords = data.records;
      this.updateAparRows(data.records);
    } else if (error) {
      this.showErrorToast(error.body.message);
    }
  }

  @wire(getRelatedListRecords, {
    parentRecordId: '$recordId',
    relatedListId: 'Accrual_Profile_Subclient_Relationship__r',
    fields: APSR_FIELDS,
  })
  getApsrRecordsCallback({ error, data }) {
    if (data && !this.isClone) {
      this._apscrRecords = data.records;
      this.updateApsrRows(data.records);
    } else if (error) {
      this.showErrorToast(error.body.message);
    }
  }

  handleSubClientSearchTermChange({ detail }) {
    this.showSubClientSearchResults(detail);
  }

  handleSubClientSelection({ detail }) {
    const selectedOption = { ...this.subClientMap[detail] };

    selectedOption.label = this.appendInfoInOptionLabel(selectedOption);
    this.selectedSubClients = [...this.selectedSubClients, selectedOption];
    this.addParentAccount(selectedOption);

    this.subClientSearchResults = this.subClientSearchResults.filter(
      (option) => option.value !== detail
    );
  }

  handleSubClientDeselection({ detail }) {
    this.selectedSubClients = this.selectedSubClients.filter(
      (option) => option.value !== detail
    );
    this.deletedSubClients = this.getListOfRecordsWithAllFields(this._apscrRecords)
    .filter(record => !this.selectedSubClientIds.includes(record.NSP_Sub_Client__c))
  }

  handleAccountSearchTermChange({ detail }) {
    this.showAccountSearchResults(detail);
  }

  handleAccountSelection({ detail }) {
    const selectedOption = this.accountMap[detail];

    this.selectedAccounts = [...this.selectedAccounts, selectedOption];
    this.accountSearchResults = this.accountSearchResults.filter(
      (option) => option.value !== detail
    );
  }

  handleAccountDeselection({ detail }) {
    this.selectedAccounts = this.selectedAccounts.filter(
      (option) => option.value !== detail
    );
    this.deletedAccounts = this.getListOfRecordsWithAllFields(this._aparRecords)
    .filter(record => !this.selectedAccountIds.includes(record.NSP_Account__c))
  }

  handleError(event) {
    this.hideLoadingSpinner();
    let message = event.detail.detail;
    this.showErrorToast(message);
  }

  handleLoad() {
    this.hideLoadingSpinner();
  }

  handleSuccess({ detail }) {
    this.recordId = detail.id;
    this.showSuccessToast(TOAST_MESSAGE.accrualProfileRecordSaveSucess);
    this.saveRelatedRecords();
  }

  handleSaveButtonClick() {
    this.showLoadingSpinner();
    if(this.handleRequiredFields()) {
      if (this.isClone) {
        this.cloneRecord();
      } else {
        this.template
          .querySelector('lightning-record-edit-form')
          .submit(this.fieldValue);
      }
    } else {
      this.showErrorToast(TOAST_MESSAGE.requiredFields);
      this.hideLoadingSpinner();
    }
  }

  handleRequiredFields(){
    return this.selectedAccountIds.length > 0;
  }

  handleValueChange({ detail, target }) {
    const { name, visibilityName } = target.dataset;
    const value = detail.value || detail.checked || null;

    this.fieldValue[name] = isMultiSelectCheckbox(target)
      ? value.join(';')
      : value;
    this.updateDependentFieldVisibility(visibilityName || name, value);
    this.doFieldSpecificAction(name, value);
  }

  handleChange(event) {
    event.preventDefault();
    const { target } = event;
    const fieldName = target.dataset.name;
    const value = target.value || null;

    this.fieldValue[fieldName] = value;
  }

  handleCheckBoxChange({ detail, target }) {
    const { name } = target.dataset;
    const value = detail.checked;

    this.fieldValue[name] = value;
  }

  handleLookUpChange({ detail, target }) {
    const fieldName = target.dataset.name;
    const value = detail?.value[0] || null;

    this.fieldValue[fieldName] = value;
  }

  handleApgRowAction({ detail }) {
    const { row, action } = detail;

    if (action.name === 'delete') {
      this.deleteApgRow(row);
    }

    if (action.name === 'addRow') {
      this.addApgRow(row);
    }
  }


  handleCellChange({ detail }) {
    const [draftValues] = detail.draftValues;
    Object.keys(draftValues).forEach((fieldName) => {
      this._apgData = this._apgData.map(record => {
        if (draftValues.uid == record.uid || (draftValues.uid == 'row-0' && record.uid == 0)) {
          record[fieldName] = draftValues[fieldName];
          return { ...record }
        } else {
          return { ...record }
        }
      })
    })
  }

  handleFileUploadFinished({ detail }) {
    // Get the list of uploaded files
    const uploadedFiles = detail.files;
    if (!this.recordId) {
      uploadedFiles.forEach(({ documentId }) => {
        this.unlinkedFiles.push(documentId);
      });
    }

    this.showSuccessToast('No. of files uploaded : ' + uploadedFiles.length);
    this.filesUploadedCount = uploadedFiles.length;
  }

  populateObjectInfoData(data) {
    this.objectInfo = data;
    this.objectFieldsInfo = data?.fields;
    const { apiName, fields, recordTypeInfos } = data;
    this.allAccrualProfileFields = this.getAllFields(apiName, fields);
    this.populateFieldsInfo(fields);
    this.state.recordTypeOptions = Object.keys(recordTypeInfos)
      .filter((id) => recordTypeInfos[id].name !== 'Master')
      .map((id) => {
        const { name, recordTypeId } = recordTypeInfos[id];

        return { label: name, value: recordTypeId };
      });
  }

  populatePageRefenceData(currentPageReference) {
    const { defaultFieldValues } = currentPageReference.state;
    if (defaultFieldValues) {
      const paramMap = {};
      defaultFieldValues.split(',').forEach((param) => {
        const [key, value] = param.split('=');
        paramMap[key] = value;
      });

      const { type, sourceId, sourceLabel, relatedRecLabel, relatedRecId } = paramMap;
      const option = this.getOption(sourceLabel, sourceId);

      if (type == 'acc') {
        this.selectedAccounts = [option];
      } else {
        this.selectedSubClients = [option];
        if (relatedRecId) {
          this.selectedAccounts = [this.getOption(relatedRecLabel, relatedRecId)];
        }
      }
    }
  }

  addParentAccount(selectedOption) {
    const { accId, accName } = selectedOption;
    if (!this.selectedAccountIds.includes(accId)) {
      this.selectedAccounts.push(this.getOption(accName, accId));
    }
  }

  appendInfoInOptionLabel({ label, info }) {
    return info ? label + SEPARATOR + info : label;
  }

  updateApgRows(records) {
    this._apgData = records.map((row, index) => {
      const record = { uid: index };
      const { fields } = row;

      return Object.keys(fields).reduce((rec, fieldName) => {
        return { ...rec, [fieldName]: fields[fieldName].value };
      }, record);
    });
  }

  updateApsrRows(records) {
    this.selectedSubClients = this.getPreSelectedOptions(
      records,
      'NSP_Sub_Client__r',
      'NSP_Sub_Client__c'
    );
  }

  updateAparRows(records) {
    this.selectedAccounts = this.getPreSelectedOptions(
      records,
      'NSP_Account__r',
      'NSP_Account__c'
    );
  }

  cloneRecord() {
    createRecord({
      apiName: ACCRUAL_PROFILE_OBJECT.objectApiName,
      fields: this.sanitizedFieldValues,
    }).then((rec) => {
      this.recordId = rec.id || rec.Id;
      this.showSuccessToast(TOAST_MESSAGE.accrualProfileRecordCloneSuccess);
      this.saveRelatedRecords();
    });
  }

  getPreSelectedOptions(records, labelField, valueField) {
    return records.map((row) => {
      const { fields } = row;

      return this.getOption(
        fields[labelField].displayValue,
        fields[valueField].value,
        row.id
      );
    });
  }

  getOption(label, value, id) {
    return {
      disabled: false,
      iconName: 'standard:account',
      label,
      value,
      id,
    };
  }

  showSubClientSearchResults = debounce((searchTerm) => {
    const { selectedSubClientIds } = this;
    const searchConfig = JSON.stringify({
      searchTerm,
      preSelectedRecs: JSON.stringify(selectedSubClientIds),
      objectApiName: 'NSP_Sub_Client__c',
      searchCategory: 'Name',
      additionalInfoField: [
        'NSP_Sub_Client__c',
        'NSP_Account__c',
        'NSP_Account__r.Name',
        'NSP_Client__c',
      ].join(','),
      resultSize: 10,
    });

    searchRecordsByFilters({ searchConfig })
      .then((results) => {
        const options = results.map((option) => {
          const infoObj = JSON.parse(option.info);
          const accName = infoObj['NSP_Account__r.Name'];
          const accId = infoObj.NSP_Account__c;
          const info =
            (infoObj.NSP_Sub_Client__c || '') +
            SEPARATOR +
            (infoObj.NSP_Client__c || '');

          return { ...option, info, accName, accId };
        });

        this.subClientSearchResults = options;
        this.subClientMap = prepareMapByValue(options);
      })
      .catch((e) => this.showErrorToast(e.body.message));
  }, 100);

  saveRelatedRecords() {
    const { apgRecords, aparRecords, apsrRecords, _apgDataToDeleteRecords , aparDataToDeleteRecords, apscrDataToDeleteRecords} = this;
    const recordsToUpsertMap = {
      NSP_Accrual_Profile_Grid__c: apgRecords,
      NSP_Accrual_Profile_Account_Relationship__c: aparRecords,
      NSP_Accrual_Profile_Subclient_Relation__c: apsrRecords,
    };
    const recordsToDeleteMap = {
      NSP_Accrual_Profile_Grid__c: _apgDataToDeleteRecords,
      NSP_Accrual_Profile_Account_Relationship__c : aparDataToDeleteRecords,
      NSP_Accrual_Profile_Subclient_Relation__c : apscrDataToDeleteRecords
    };

    upsertAndDeleteRecords({ recordsToUpsertMap, recordsToDeleteMap })
      .then(() => this.navigateToRecord())
      .catch((error) => {
        this.showErrorToast(error.body.message);
      });

    const unlinkedFilesCount = this.unlinkedFiles.length;
    if (unlinkedFilesCount) {
      linkFilesToRecord({
        recordId: this.recordId,
        contentDocumentIds: this.unlinkedFiles,
      })
        .then(() => {
          this.unlinkedFiles = [];
          this.showSuccessToast(
            `${unlinkedFilesCount} files have been linked to accrual profile record.`
          );
        })
        .catch((error) => this.showErrorToast(error.body.message));
    }
  }

  showAccountSearchResults = debounce((searchTerm) => {
    const { selectedAccountIds } = this;
    const searchConfig = JSON.stringify({
      searchTerm,
      preSelectedRecs: JSON.stringify(selectedAccountIds),
      objectApiName: 'Account',
      searchCategory: 'Name',
      resultSize: 10,
    });

    searchRecordsByFilters({ searchConfig })
      .then((results) => {
        this.accountSearchResults = [...results];
        this.accountMap = prepareMapByValue(results);
      })
      .catch((e) => this.showErrorToast(e.body.message));
  }, 100);

  addApgRow(row) {
    const draftValues = this.template.querySelector('lightning-datatable').draftValues;
    const { uid } = row;
    const index = this.findRowIndexByUid(uid);

    if (index !== -1) {
      this._apgData.splice(index + 1, 0, { uid: this.uniqueId });
      this._apgData = [...this._apgData];
      this.updateAccrualLevelValue();
    }
    this.template.querySelector('lightning-datatable').draftValues = draftValues;
  }

  updateAccrualLevelValue() {
    this.fieldValue.NSP_Accrual_Levels__c = this._apgData.length;
  }

  deleteApgRow(row) {
    if (this._apgData.length > 1) {
      const { uid } = row;
      if(row.Id){
        this._apgDataToDelete.push(row);
      }
      const data = this._apgData;
      const index = this.findRowIndexByUid(uid);

      if (index !== -1) {
        this._apgData = data.slice(0, index).concat(data.slice(index + 1));
        this.updateAccrualLevelValue();
      }
    }
  }

  findRowIndexByUid(uid) {
    let ret = -1;
    this._apgData.some((row, index) => {
      if (row.uid == uid) {
        ret = index;
        return true;
      }
      return false;
    });

    return ret;
  }

  doFieldSpecificAction(fieldName, value) {
    if (fieldName === 'NSP_Accrual_Levels__c') {
      this.updateAccrualProfileGrid(value);
    }
    if (
      fieldName === 'NSP_Delay_in_the_Accrual_start_time__c' &&
      value === YES
    ) {
      this.prependZeroValueRowInApg();
    }
    if (
      (fieldName === 'NSP_time_accrue_under_plan_fiscal_year__c' ||
        fieldName === 'NSP_time_accrue_under_plan_anniv_year__c' ||
        fieldName === 'NSP_Accrue_under_plan_cal_year__c') &&
      value ===
        'Last of Pay Period: Accrual is added on the last day of each pay period'
    ) {
      this.fieldValue.NSP_When_do_accrual_level_changes_happen__c =
        'Beginning of the Pay Period that contains the Anniversary Date';
    }
    if (
      (fieldName === 'NSP_time_accrue_under_plan_anniv_year__c' ||
        fieldName === 'NSP_Accrue_under_plan_cal_year__c') &&
      value === 'Hours Worked: Accrual is added based on actual hours worked'
    ) {
      this.fieldValue.NSP_When_do_accrual_level_changes_happen__c =
        'Beginning of the Pay Period that contains the Anniversary Date';
    }
    if (
      fieldName === 'NSP_time_accrue_under_plan_fiscal_year__c' &&
      value === 'Hours Worked: Accrual is added based on actual hours worked'
    ) {
      this.fieldValue.NSP_When_do_accrual_level_changes_happen__c =
        'Beginning of the Pay Period that contains the Anniversary Date';
    }
    if (fieldName === 'NSP_Accrual_Profile__c' && value === 'other') {
      this.fieldValue.NSP_Accrual_Profile__c = null;
    }
    if (
      fieldName === 'NSP_Does_this_plan_replace_other_plans__c' &&
      (value === 'Yes' || value === 'No')
    ) {
      this.nameOfThePlanBeingReplaced = '';
    }
    if (
      fieldName === 'NSP_Does_this_plan_replace_other_plans__c' && (value === 'Yes'|| value === 'No')
    ) {
      this.nameOfThePlanBeingReplaced = '';
    }
  }

  prependZeroValueRowInApg() {
    this._apgData = [
      { uid: this.uniqueId, ...APG_ROWS_WITH_ZERO },
      ...this._apgData,
    ];
    this.updateAccrualLevelValue();
  }

  updateAccrualProfileGrid(accrualLevelCount) {
    const rows = [];

    for (let i = 0; i < accrualLevelCount; i++) {
      const apgRow = { uid: i };

      if (i === 0) {
        apgRow.NSP_Completed_Months_of_Service__c = 0;
      }

      rows.push(apgRow);
    }

    this._apgData = rows;
  }

  updateDependentFieldVisibility(fieldName, value) {
    const fieldConfig = DYNAMIC_FIELDS[fieldName];
    let updatedValues = {};
    if (fieldConfig && fieldConfig.length) {
      let dependentField = fieldConfig[0].dependentFields;
      if(MULTIPLE_DEPENDENT_FIELDS[dependentField] != null) {
        updatedValues = getMultiDependentFieldVisibility(dependentField, this.fieldValue, DYNAMIC_FIELDS, MULTIPLE_DEPENDENT_FIELDS);
      } else {
        updatedValues = getUpdatedFieldVisibility(fieldConfig, value);
      }
      Object.keys(updatedValues).forEach((fieldApiName) => {
        const actualFieldName = EXISTING_FIELD_API_VALUE.hasOwnProperty(fieldApiName) ? EXISTING_FIELD_API_VALUE[fieldApiName] : fieldApiName;
        this.updateSpecialFieldValues(fieldName);
        if (updatedValues[fieldApiName]) {
          this.visibility[fieldApiName] = true;
        } else {
          if (!this.isFirstTimeCopyAction) {
            this.fieldValue[actualFieldName] = null;
          }
          this.visibility[fieldApiName] = false;
          this.updateDependentFieldVisibility(fieldApiName, null);
        }
      });
    }
  }

  updateSpecialFieldValues(fieldApiName) {
    if (SPECIAL_FIELDS.includes(fieldApiName) && !this.isFirstTimeCopyAction) {
      this.fieldValue.NSP_When_do_accrual_level_changes_happen__c = null;
    }
  }

  navigateToRecord() {
    this.navigate(this.recordId);
  }

  navigate(recordId) {
    const config = {
      type: 'standard__recordPage',
      attributes: {
        recordId,
        actionName: 'view',
      },
    };

    this[NavigationMixin.GenerateUrl](config)
    .then((url) => {
      window.location.replace(url);
    });
  }

  showSuccessToast(message) {
    this.showToast({
      ...SUCCESS_TOAST_CONFIG,
      message,
    });
  }

  showErrorToast(message) {
    this.showToast({
      ...ERROR_TOAST_CONFIG,
      message,
    });
  }

  showToast(config) {
    this.dispatchEvent(new ShowToastEvent({ ...config }));
  }

  hideLoadingSpinner() {
    this.state.isLoading = false;
  }

  showLoadingSpinner() {
    this.state.isLoading = true;
  }

  createComboBoxOptions(options) {
    return options.map((value) => {
      return { label: value, value };
    });
  }

  replacePlaceHolder(label, value) {
    return label.replace('<placeholder>', value || '');
  }

  getAllFields(objectApiName, fields) {
    const allFields = Object.keys(fields).map((fieldApiName) => {
      return { fieldApiName, objectApiName };
    });

    return [NAME_FIELD, ...allFields];
  }

  populateFieldsInfo(fields) {
    const creatableFields = [];
    const referenceFields = [];
    const multipicklistFields = [];
    Object.keys(fields).forEach((fieldName) => {
      const { createable, dataType } = fields[fieldName];
      if (createable) {
        creatableFields.push(fieldName);
      }
      if (dataType === 'Reference') {
        referenceFields.push(fieldName);
      }
      if (dataType === 'MultiPicklist') {
        multipicklistFields.push(fieldName);
      }
    });
    this.creatableFields = creatableFields;
    this.referenceFields = referenceFields;
    this.multipicklistFields = multipicklistFields;
  }

  doOneTimeActions(fieldValue) {
    if (fieldValue) {
      const { NSP_Accrual_Profile__c, NSP_Other_Plan__c } = fieldValue;

      if (!NSP_Accrual_Profile__c && NSP_Other_Plan__c) {
        this.visibility.NSP_Other_Plan__c = true;
        this.nameOfThePlanBeingReplaced = 'other';
      } else {
        this.nameOfThePlanBeingReplaced = NSP_Accrual_Profile__c;
      }
    }
  }

  get selectedAccountIds() {
    return this.selectedAccounts.map(({ value }) => value);
  }

  get selectedSubClientIds() {
    return this.selectedSubClients.map(({ value }) => value);
  }

  get statusOptions() {

    let status = this.createComboBoxOptions(STATUS_OPTIONS);
    const { NSP_Status__c } = this.fieldValue;
    if (NSP_Status__c && !status.includes(NSP_Status__c)) {
      status.push({ label: NSP_Status__c, value: NSP_Status__c });
    }
    return status;
  }

  get statusOptionsAims() {
    let status = this.createComboBoxOptions(STATUS_OPTIONS_AIMS);
    const { NSP_Status__c } = this.fieldValue;
    if (NSP_Status__c && !status.includes(NSP_Status__c)) {
      status.push({ label: NSP_Status__c, value: NSP_Status__c });
    }
    return status;
  }

  get accrualLevelChangesOptionsCalenderYear() {
    const fieldValue = this.fieldValue.NSP_Accrue_under_plan_cal_year__c;

    if (fieldValue) {
      const options =
        ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CALENDAR_YEAR[fieldValue];

      return options ? this.createComboBoxOptions(options) : null;
    }

    return null;
  }

  get accrualLevelChangesOptionsAnniversaryYear() {
    const fieldValue = this.fieldValue.NSP_time_accrue_under_plan_anniv_year__c;

    if (fieldValue) {
      const options =
        ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_ANNIVERSARY_YEAR[fieldValue];

      return options ? this.createComboBoxOptions(options) : null;
    }

    return null;
  }

  get accrualLevelChangesOptionsClientFiscalYear() {
    const fieldValue =
      this.fieldValue.NSP_time_accrue_under_plan_fiscal_year__c;

    if (fieldValue) {
      const options =
        ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CLIENT_FISCAL_YEAR[fieldValue];

      return options ? this.createComboBoxOptions(options) : null;
    }

    return null;
  }

  get label() {
    return LABEL;
  }

  get infoMessage() {
    return INFO_MESSAGE;
  }

  get annualAccrualLimitLabel() {
    return this.replacePlaceHolder(
      LABEL.NSP_Once_limit_is_hit_they_do_not_accrue__c,
      this.fieldValue.NSP_What_is_the_plan_year__c
    );
  }

  get apgColumns() {
    const {
      NSP_Is_there_a_Maximum_Balance_Cap__c,
      NSP_Accrual_Period_Limit__c,
      NSP_Do_balances_carry_over_into_next_yer__c,
      NSP_Does_carryover_expire__c,
      NSP_Once_limit_is_hit_they_do_not_accrue__c,
      NSP_Carryover_in_Hours_or_percentage__c,

    } = this.fieldValue;

    const {
      completedMonthsService,
      accrualRate,
      annualAccrualLimit,
      maximumBalanceCapHours,
      accrualPeriodLimitsHours,
      maxCarryOverHours,
      maxCarryOverPercent,
      carryoverExpiresDaysDate,
      action,
    } = APG_COLUMNS;
    const columnConfig = [completedMonthsService, accrualRate];

    if (NSP_Once_limit_is_hit_they_do_not_accrue__c === YES) {
      columnConfig.push(annualAccrualLimit);
    }

    if (NSP_Is_there_a_Maximum_Balance_Cap__c === YES) {
      columnConfig.push(maximumBalanceCapHours);
    }

    if (NSP_Accrual_Period_Limit__c === YES) {
      columnConfig.push(accrualPeriodLimitsHours);
    }

    if (NSP_Do_balances_carry_over_into_next_yer__c === YES) {
      if (NSP_Carryover_in_Hours_or_percentage__c === 'Hours') {
        columnConfig.push(maxCarryOverHours);
      }
      if (NSP_Carryover_in_Hours_or_percentage__c === 'Percent') {
        columnConfig.push(maxCarryOverPercent);
      }
    }

    if (NSP_Does_carryover_expire__c === YES) {
      columnConfig.push(carryoverExpiresDaysDate);
    }

    columnConfig.push(action);

    return columnConfig;
  }

  get apgColumnsAims() {
    const {
      NSP_Is_there_a_Maximum_Balance_Cap__c,
      NSP_balances_paid_in_lieu_of_carryover__c,
      NSP_Carryover_in_Hours_or_percentage__c,
      NSP_Does_carryover_expire__c,
      NSP_Carryover_in_Hours_or_paid_in_lieu__c
    } = this.fieldValue;

    const {
      from,
      through,
      unit,
      accrualRate,
      action,
      maximumBalanceCapHours,
      maxCarryOverHours,
      maxCarryOverPercent,
      maxInLieuOfPayoutHours,
      maxInLieuOfPayoutPercent,
      carryoverExpiresDaysDate,
      maxAmountThatExpires,
    } = APG_COLUMNS_AIMS;

    const columnConfig = [from, through, unit, accrualRate];
    if (NSP_Is_there_a_Maximum_Balance_Cap__c === YES) {
      columnConfig.push(maximumBalanceCapHours);
    }
    if (NSP_Carryover_in_Hours_or_percentage__c === 'Hours') {
      columnConfig.push(maxCarryOverHours);
    }
    if (NSP_Carryover_in_Hours_or_percentage__c === 'Percent') {
      columnConfig.push(maxCarryOverPercent);
    }
    if (NSP_balances_paid_in_lieu_of_carryover__c === YES) {
      if (NSP_Carryover_in_Hours_or_paid_in_lieu__c === 'Hours') {
        columnConfig.push(maxInLieuOfPayoutHours);
      } else if (NSP_Carryover_in_Hours_or_paid_in_lieu__c === '%') {
        columnConfig.push(maxInLieuOfPayoutPercent);
      }
    }
    if (NSP_Does_carryover_expire__c === YES) {
      columnConfig.push(carryoverExpiresDaysDate);
    }
    if (NSP_Does_carryover_expire__c === YES) {
      columnConfig.push(maxAmountThatExpires);
    }
    columnConfig.push(action);

    return columnConfig;
  }

  get selectedTimeAccrual() {
    return null;
  }

  get selectedPayFrequency() {
    return null;
  }

  get apgRecords() {
    return this._apgData.map((row, index) => {
      const rec = { ...row };
      rec.NSP_Accrual_Profile__c = this.recordId;
      rec.NSP_Index__c = index + 1;

      delete rec.uid;
      if (this.isClone) {
        delete rec.Id;
      }

      return JSON.stringify(rec);
    });
  }

  get _apgDataToDeleteRecords() {
    return this._apgDataToDelete.map((row) => {
      const rec = { ...row };
      rec.NSP_Accrual_Profile__c = this.recordId;

      delete rec.uid;
      if (this.isClone) {
        delete rec.Id;
      }

      return JSON.stringify(rec);
    });

  }

  get apscrDataToDeleteRecords() {

    return this.deletedSubClients.map((row) => {
      const rec = { ...row };

      delete rec.NSP_Sub_Client__r;
      return JSON.stringify(rec);
    });
  }

  get aparDataToDeleteRecords() {

    return this.deletedAccounts.map((row) => {
      const rec = { ...row };

      delete rec.NSP_Account__r;
      return JSON.stringify(rec);
    });
  }

  get aparRecords() {
    const existingRecords = this.getListOfRecordsWithAllFields(this._aparRecords)
    return this.filterValidRecords(this.selectedAccounts, existingRecords, 'NSP_Account__c')
      .map(({ value, id }) =>
        JSON.stringify({
          Id: id,
          NSP_Account__c: value,
          NSP_Accrual_Profile__c: this.recordId,
        })
      );
  }

  get apsrRecords() {
    const existingRecords = this.getListOfRecordsWithAllFields(this._apscrRecords)
    return this.filterValidRecords(this.selectedSubClients, existingRecords, 'NSP_Sub_Client__c')
      .map(({ value, id }) =>
        JSON.stringify({
          Id: id,
          NSP_Sub_Client__c: value,
          NSP_Accrual_Profile__c: this.recordId,
        })
      );
  }

  filterValidRecords(selectedRecords, existingRecords, fieldName) {
    existingRecords.forEach((existingRecord, existingRecordIndex) => {
      selectedRecords.forEach((selectedRecord, selectedRecordIndex) => {
        if (existingRecord[fieldName] === selectedRecord.value && existingRecordIndex !== selectedRecordIndex) {
          selectedRecords.splice(existingRecordIndex, 1);
        }
      });
    });
    
    return selectedRecords;
  }

  getListOfRecordsWithAllFields(records) {
    return records.reduce((acc, row) => {
      const { fields } = row;
      let record = {};
      Object.keys(fields).forEach((fieldName) => {
        const { value } = fields[fieldName];

        record[fieldName] = value;
      });

      return [...acc, record];

    }, []);
  }

  get uniqueId() {
    const highestUid = this._apgData.reduce(
      (highestUid, { uid }) => (uid > highestUid ? uid : highestUid),
      0
    );

    return highestUid + 1;
  }

  get doBalancesCarryOverLabel() {
    return this.replacePlaceHolder(
      LABEL.NSP_Do_balances_carry_over_into_next_yer__c,
      this.fieldValue.NSP_What_is_the_plan_year__c
    );
  }

  get contactFieldValue() {
    return this.fieldValue?.NSP_Contact__c;
  }

  get accrualLevelNumber() {
    return this.replacePlaceHolder(
      LABEL.NSP_Hours_paid_for_earning_accruals__c,
      this.fieldValue.NSP_Accrual_Levels__c
    );
  }

  get accrualLevelChangesAimsFiscalYear() {
    return this.createComboBoxOptions(ACCRUAL_LEVEL_CHANGES_FISCAL_YEAR_AIMS);
  }

  get accrualLevelChangesAimsCalendarYear() {
    return this.createComboBoxOptions(ACCRUAL_LEVEL_CHANGES_CALENDAR_YEAR_AIMS);
  }

  get accrualLevelChangesAimsAnniversaryYear() {
    return this.createComboBoxOptions(
      ACCRUAL_LEVEL_CHANGES_ANNIVERSARY_YEAR_AIMS
    );
  }

  get unit() {
    return this.fieldValue.NSP_When_do_accrual_level_changes_happen__c ===
      'Anniversary Month: Accrual rate increase on the first day of each employee’s anniversary month'
      ? 'MONTHS'
      : 'YEARS';
  }

  get apgData() {
    const { unit, _apgData } = this;

    return _apgData.map((row) => {
      return { ...row, NSP_Unit__c: unit };
    });
  }

  get isRecordTypeSelected() {
    return this.recordId || this.fieldValue.recordTypeId;
  }

  get recordTypeIdITA() {
    return this.state.recordTypeOptions.find(({ label }) => label === 'ITA')
      ?.value;
  }

  get sanitizedFieldValues() {
    const fields = { ...this.fieldValue };
    const restrictedFields = Object.keys(fields).filter(
      (fieldName) => !this.creatableFields.includes(fieldName)
    );

    restrictedFields.forEach((fieldName) => {
      delete fields[fieldName];
    });

    this.multipicklistFields.forEach((fieldName) => {
      const value = fields[fieldName];
      if (isNonEmptyArray(value)) {
        fields[fieldName] = value.join(';');
      }
    });

    delete fields.Id;

    return fields;
  }

  get activeSections() {
    return ACTIVE_SECTIONS;
  }

  get title() {
    return this.isRecordTypeSelected ? 'Accrual Profile (AIMS)' : 'Accrual Profile';
  }

}