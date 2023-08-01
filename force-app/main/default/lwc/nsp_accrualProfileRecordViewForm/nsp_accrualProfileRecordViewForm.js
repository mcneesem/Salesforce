import { api, LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import WORK_EMAIL_FIELD from '@salesforce/schema/Contact.NSP_Work_email__c';
import ACCRUAL_PROFILE_OBJECT from '@salesforce/schema/NSP_Accrual_Profile__c';
import NAME_FIELD from '@salesforce/schema/NSP_Accrual_Profile__c.Name';
import itaForm from './nsp_accrualProfileRecordITAViewForm.html';
import aimsForm from './nsp_accrualProfileRecordAIMSViewForm.html';

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
  APSR_FIELDS,
  ERROR_TOAST_CONFIG,
  INFO_MESSAGE,
  LABEL,
  STATUS_OPTIONS,
  STATUS_OPTIONS_AIMS,
  YES,
  ACTIVE_SECTIONS,
  EXISTING_FIELD_API_VALUE
} from './constants';

import {
  getUpdatedFieldVisibility,
  isNonEmptyArray,
} from 'c/nsp_utils';
import { DYNAMIC_FIELDS } from './dynamicFieldsConfig';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

// APEX IMPORTS
import getPlanOptions from '@salesforce/apex/NSP_AccrualProfileController.getPlanOptions';

export default class Nsp_accrualProfileRecordViewForm extends LightningElement {
    @api recordId;

  @track state = {
    isLoading: true,
    errorMessage: null,
    recordTypeOptions: [],
  };

  @track selectedSubClients = [];
  @track selectedAccounts = [];
  @track visibility = {};
  @track fieldValue = { 'Accrual_rates_are_based_Input_Number__c' : '' };

  planOptions = {};
  nameOfThePlanBeingReplaced;
  allAccrualProfileFields = null;

  @track _apgData = [];

  _objectInfo;
  @api get objectInfo() {
    return this._objectInfo;
  }
  set objectInfo(value) {
    if (value) {
      this._objectInfo = value?.fields;
    }
  }

  render() {
    return this.recordTypeIdITA === this.fieldValue.recordTypeId
      ? itaForm
      : aimsForm;
  }

  @wire(getObjectInfo, { objectApiName: ACCRUAL_PROFILE_OBJECT })
  getAccrualProfileInfo({ data, error }) {
    if (data) {
      this.populateObjectInfoData(data);
    } else if (error) {
      this.showErrorToast(error.body.message);
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
        const fieldNames = Object.keys(EXISTING_FIELD_API_VALUE).filter(name => EXISTING_FIELD_API_VALUE[name] === fieldApiName);

        const { value } = fields[fieldApiName];
        if(value){
          this.fieldValue[fieldApiName] = value;
          const dataType = this._objectInfo[fieldApiName]?.dataType;
            const updatedValue =
              dataType == 'MultiPicklist' ? value.split(';') : value;
  
          if (isNonEmptyArray(fieldNames)) {
            fieldNames.forEach(name => this.updateDependentFieldVisibility(name, updatedValue))
          } else {
            this.updateDependentFieldVisibility(fieldApiName, updatedValue);
          }
        }
      });

      this.fieldValue.recordTypeId = data.recordTypeId;
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
      this.fieldValue.NSP_Contact_email__c = getFieldValue(
        data,
        WORK_EMAIL_FIELD
      );
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
      this.populateApgRows(data.records);
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
    if (data) {
      this.populateAparRows(data.records);
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
    if (data) {
      this.populateApsrRows(data.records);
    } else if (error) {
      this.showErrorToast(error.body.message);
    }
  }

  handleError(error) {
    this.hideLoadingSpinner();
    this.showErrorToast(error.body.message);
  }

  handleLoad() {
    this.hideLoadingSpinner();
  }

  populateObjectInfoData(data) {
    this.objectInfo = data;
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

  populateApgRows(records) {
    this._apgData = records.map((row) => {
      const { fields } = row;

      return Object.keys(fields).reduce((rec, fieldName) => {
        return { ...rec, [fieldName]: fields[fieldName].value };
      }, {});
    });
  }

  populateApsrRows(records) {
    this.selectedSubClients = this.getPreSelectedOptions(
      records,
      'NSP_Sub_Client__r',
      'NSP_Sub_Client__c'
    );
  }

  populateAparRows(records) {
    this.selectedAccounts = this.getPreSelectedOptions(
      records,
      'NSP_Account__r',
      'NSP_Account__c'
    );
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

  updateDependentFieldVisibility(fieldName, value) {
    const fieldConfig = DYNAMIC_FIELDS[fieldName];
    if (fieldConfig && fieldConfig.length) {
      const updatedValues = getUpdatedFieldVisibility(fieldConfig, value);
      Object.keys(updatedValues).forEach((fieldApiName) => {
        if (updatedValues[fieldApiName]) {
          this.visibility[fieldApiName] = true;
        } else {
          this.visibility[fieldApiName] = false;
          this.updateDependentFieldVisibility(fieldApiName, null);
        }
      });
    }
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
      if(dataType == 'MultiPicklist'){
        multipicklistFields.push(fieldName);
      }
    });
    this.creatableFields = creatableFields;
    this.referenceFields = referenceFields;
    this.multipicklistFields = multipicklistFields;
  }

  handleSubClientClick(event) {
    // Get the record ID from the data-value attribute of the clicked element
    let recordId = event.target.dataset.value;
    // Construct the URL for the record page
    let recordUrl = "/lightning/r/" + recordId + "/view";
    // Open the record in a new tab
    window.open(recordUrl, '_blank');
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

    let status = this.createComboBoxOptions(STATUS_OPTIONS);;
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

    const options =
      ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CALENDAR_YEAR[fieldValue];

    return options ? this.createComboBoxOptions(options) : null;
  }

  get accrualLevelChangesOptionsAnniversaryYear() {
    const fieldValue = this.fieldValue.NSP_time_accrue_under_plan_anniv_year__c;

    const options =
      ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_ANNIVERSARY_YEAR[fieldValue];

    return options ? this.createComboBoxOptions(options) : null;
  }

  get accrualLevelChangesOptionsClientFiscalYear() {
    const fieldValue =
      this.fieldValue.NSP_time_accrue_under_plan_fiscal_year__c;

    const options =
      ACCRUAL_LEVEL_CHANGES_FIELD_MAPPING_CLIENT_FISCAL_YEAR[fieldValue];

    return options ? this.createComboBoxOptions(options) : null;
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

    return columnConfig;
  }

  get doBalancesCarryOverLabel() {
    return this.replacePlaceHolder(
      LABEL.NSP_Do_balances_carry_over_into_next_yer__c,
      this.fieldValue.NSP_What_is_the_plan_year__c
    );
  }

  get contactFieldValue() {
    return this.fieldValue?.NSP_Contact__c?.[0];
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

  get activeSections() {
    return ACTIVE_SECTIONS
  }

  get accrualProfileObject(){
    return ACCRUAL_PROFILE_OBJECT;
  }
}