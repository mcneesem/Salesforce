import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import ID_FIELD from '@salesforce/schema/Implementation_Profile__c.Id';
import { NavigationMixin } from 'lightning/navigation';
import * as labels from 'c/nsp_implementationLabels';
import {
  SECTION,
  VERTICAL_SPACE,
  SCROLL_DELAY_MS,
  SECTION_MARGIN,
  SUCCESS_MESSAGE,
  SUCCESS_TOAST_CONFIG,
  ERROR_TOAST_CONFIG,
  BUTTON_HANDLER_MAPPING,
  POST_UPSERT_ACTION_MAPPING,
  SAVE_AND_EXIT_DIALOG_BUTTON_CONFIG,
  NON_COPY_ABLE_SECTIONS,
  NON_COPY_ABLE_FIELDS,
  COPY_ABLE_IP_CHILD_OBJECTS,
  RELATED_FIELD_NAME,
} from './constants';
import { PREVIOUS_VALUE_FIELDS_MAPPING } from './fields';
import {
  constructNameLabelArray,
  debounce,
  isNonEmptyArray,
  getErrorMessage,
  createMapWithValueProperty
} from 'c/nsp_utils';
import saveEmployeeData from '@salesforce/apex/NSP_ImplementationProfileController.saveEmployeeData';
import copyIpRecordData from '@salesforce/apex/NSP_ImplementationProfileController.copyIpRecordData';
import saveAndDeleteRecords from '@salesforce/apex/NSP_ImplementationProfileController.saveAndDeleteRecords';
import getIPRelatedRecords from '@salesforce/apex/NSP_ImplementationProfileController.getIPRelatedRecords';
import loadIPRecords from '@salesforce/apex/NSP_FSOImplementationController.loadAutomationRecords';

export default class NSP_MidMarketFormIp extends NavigationMixin(
  LightningElement
) {
  @track sectionsData = {};
  @track sections = constructNameLabelArray(SECTION);
  @api recordId;
  @api subTitle;
  @api recordTypeId;
  @api fieldValues = {};
  @api userData = {};

  syncFieldValues = {};
  _objectInfo;
  @api
  get objectInfo() {
    return this._objectInfo;
  }
  set objectInfo(value) {
    this._objectInfo = value;
    if (value) {
      this.populatePermissibleFieldsMap();
    }
  }

  @track state = {
    isLoading: true,
    selectedTab: this.sections[0].name,
    isFormCompleted: false,
    availableHeight: null,
    updateableFields: [],
    createableFields: [],
    showSaveAndExitDialog: false,
    showCopyDialog: false,
    selectedSections: [],
    copiedTargetRecords: [],
    copiedExistingRecordOptions: [],
    isSaveAndExitAction: false,
  };
  postUpsertRecords = {};
  disabledFields = {};
  relatedRecords = {};
  @track ipAutomationTable = [];
  copySectionChanged = false;

  connectedCallback() {
    this.disableFieldsIfIpInActive();
    window.addEventListener('resize', this.handleReSizeIpForm);

    // Fetch Related objects records
    if (this.recordId) {
        this.fetchIpRelatedRecords();
        this.loadAutomationTable();
    }
  }

  disconnectedCallback() {
    window.removeEventListener('resize', this.handleReSizeIpForm);
  }

  handleReSizeIpForm = debounce(() => {
    this.calculateAvailableHeight();
  }, SCROLL_DELAY_MS);

  updateRelatedRecords(objectApiName, records) {
    this.relatedRecords[objectApiName] = records.map(({ id }) => id);
  }

  disableFieldsIfIpInActive() {
    if (
      this.fieldValues?.NSP_Inactive__c?.value &&
      this.userData?.Profile?.displayValue !== labels.SYSTEM_ADMIN
    ) {
      Object.keys(this._objectInfo.fields).forEach((fieldName) => {
        this.disabledFields[fieldName] = true;
      });
    }
  }

  renderedCallback() {
    this.calculateAvailableHeight();
  }

  handleButtonClick({ detail }) {
    const fnName = BUTTON_HANDLER_MAPPING[detail];

    if (fnName && fnName in this) {
      this[fnName]();
    }
  }

  calculateAvailableHeight() {
    const { state, header, footer } = this;

    if (header && footer) {
      //!state.availableHeight &&
      const availHeight = Math.min(
        document.documentElement.clientHeight || 0,
        window.innerHeight || 0
      );
      const mainBodyPos = header.getBoundingClientRect().bottom;
      const footerHeight = footer.offsetHeight;
      state.availableHeight =
        availHeight - mainBodyPos - footerHeight - VERTICAL_SPACE;

      document.body.style.setProperty(
        '--availableHeight',
        `${state.availableHeight}px`
      );
    }
  }

  handleTabClick({ target }) {
    const tabId = target.name;

    this.getComponentByName(tabId).scrollIntoView({ behavior: 'smooth' });
    this.state.selectedTab = tabId;
  }

  handleScroll() {
    this.doHandleScroll();
  }

  handleSaveAndExit() {
    this.state.showSaveAndExitDialog = true;
  }

  handleSaveAndExitDialog({ detail }) {
    const { state } = this;

    state.isFormCompleted = detail === 'Yes';
    state.isSaveAndExitAction = true;
    state.showSaveAndExitDialog = false;

    this.saveForm();
  }

  handleCopyHBClick() {
    this.state.showCopyDialog = true;
  }

  handleCopyDialogClose() {
    this.state.showCopyDialog = false;
  }

  handleCopyDBClick({ detail }) {
    this.generateCopyRequest(detail.records);
  }

  handleSave() {
    this.state.isFormCompleted = false;
    this.saveForm();
  }

  handleComponentLoad() {
    this.hideLoadingSpinner();
  }

  handleComponentError({ detail }) {
    this.hideLoadingSpinner();
  }

  handleSync({ detail }) {
    this.syncFieldValues = detail;
  }

  handleExit() {
    this.navigateToParentRecord();
  }

  handleCopySectionChange({ detail }) {
    this.state.selectedSections = detail.value;
    this.copySectionChanged = true;
  }

  generateCopyRequest(records) {
    this.showLoadingSpinner();
    const { state, recordId, userData } = this;
    state.showCopyDialog = false;

    const recordIds = records.map((rec) => rec.value);
    const fieldValues = this.getFieldValuesToCopy(recordIds);
    const fields = this.getOnlyPermittedFields(
      fieldValues,
      state.updateableFields
    );
    const config = {
      fieldValues: JSON.stringify(fields),
      sourceId: recordId,
      recType: 'MM',
      userEmail: userData?.Email?.value,
      postUpsertRecords: JSON.stringify(fieldValues.postUpsertRecords),
    };

    copyIpRecordData({
      recordIds,
      config,
    })
      .then(() => {
        this.showSuccessToast('Copy Data Job queued successfully.');
        state.copiedTargetRecords = recordIds;
        state.copiedExistingRecordOptions = records;
        this.hideLoadingSpinner();
      })
      .catch((error) => {
        this.showErrorToast(error.body.message);
        this.hideLoadingSpinner();
      });
  }

  getCopyDataOptions(value) {
    const iconName = 'standard:account';

    return value.map((val) => {
      const [, value, label] = val.split('~');

      return { label, value, iconName };
    });
  }

  getChildRecordsForAllTargetIpRecords(
    objApiName,
    childRecords = [],
    targetIPs = []
  ) {
    const ipFieldName = RELATED_FIELD_NAME[objApiName];
    const clonedRecs = [];

    childRecords.forEach((rec) => {
      targetIPs.forEach((targetIpRecId) => {
        const recObj = { ...rec };
        delete recObj.Id;
        recObj[ipFieldName] = targetIpRecId;
        recObj.attributes = { type: objApiName };
        clonedRecs.push(recObj);
      });
    });
    return clonedRecs;
  }

  addCopyDataRecords() {
    const { state, postUpsertRecords } = this;

    postUpsertRecords.NSP_Implementation_Profile_Copy_Data__c =
      state.copiedTargetRecords.map((recId) => {
        return { NSP_Target_Record__c: recId };
      });
    state.copiedTargetRecords = [];
  }

  getFieldValuesToCopy(targetRecordIds) {
    const fieldValues = this.state.selectedSections.reduce(
      (fieldValues, sectionName) => {
        const sectionFields = {
          ...this.getComponentByName(sectionName).getFormValues(),
        };
        const sectionPostUpsertRecs = sectionFields.postUpsertRecords;

        if (sectionPostUpsertRecs) {
          this.sanitizePostUpsertRecords(sectionPostUpsertRecs, fieldValues, targetRecordIds, sectionFields);

          delete sectionFields.postUpsertRecords;
        }

        return {
          ...fieldValues,
          ...sectionFields,
        };
      },
      { postUpsertRecords: [] }
    );

    NON_COPY_ABLE_FIELDS.forEach((fieldName) => {
      delete fieldValues[fieldName];
    });

    return fieldValues;
  }

  sanitizePostUpsertRecords(sectionPostUpsertRecs, fieldValues, targetRecordIds) {
    Object.keys(sectionPostUpsertRecs)
      .filter((objName) => COPY_ABLE_IP_CHILD_OBJECTS.includes(objName))
      .forEach((objName) => {
        const objWiseChildRecs = sectionPostUpsertRecs[objName];
        fieldValues.postUpsertRecords = [
          ...fieldValues.postUpsertRecords,
          ...this.getChildRecordsForAllTargetIpRecords(
            objName,
            objWiseChildRecs,
            targetRecordIds
          ),
        ];
      });
  }

  saveForm() {
    this.showLoadingSpinner();

    if (this.recordId) {
      this.updateIPRecord();
    } else {
      this.createIPRecord();
    }
  }

  populatePermissibleFieldsMap() {
    const { state, _objectInfo } = this;
    const createableFields = [];
    const updateableFields = [];

    Object.keys(_objectInfo.fields).forEach((fieldName) => {
      const { createable, updateable } = _objectInfo.fields[fieldName];

      if (createable) {
        createableFields.push(fieldName);
      }

      if (updateable) {
        updateableFields.push(fieldName);
      }

      this.disabledFields[fieldName] = this.recordId
        ? !updateable
        : !createable;
    });

    createableFields.push(ID_FIELD.fieldApiName);
    updateableFields.push(ID_FIELD.fieldApiName);

    state.createableFields = createableFields;
    state.updateableFields = updateableFields;
  }

  getOnlyPermittedFields(allValues, permittedFields) {
    const filteredValues = {};

    Object.keys(allValues).forEach((fieldName) => {
      if (permittedFields.includes(fieldName)) {
        filteredValues[fieldName] = allValues[fieldName];
      }
    });

    return filteredValues;
  }

  createIPRecord() {
    try {
      const { allValues, state } = this;
      const fields = this.getOnlyPermittedFields(
        allValues,
        state.createableFields
      );

      createRecord({ apiName: IP_OBJECT.objectApiName, fields })
        .then((rec) => {
          this.recordId = rec.id || rec.Id;
          this.showSuccessToast(SUCCESS_MESSAGE.create);
          this.doPostUpsertActions();
          if (state.isSaveAndExitAction) {
            this.navigateToParentRecord();
          } else {
            this.fieldValues = { ...this.fieldValues, ...createMapWithValueProperty(fields) };
            this.hideLoadingSpinner();
          }
        })
        .catch((error) => {
          const errorMessages = getErrorMessage(error);
          this.showErrorToast(errorMessages);
          this.hideLoadingSpinner();
        });
    } catch (e) {
    }
  }

  updateIPRecord() {
    try {
      const { allValues, state } = this;
      const fields = this.getOnlyPermittedFields(
        allValues,
        state.updateableFields
      );

      updateRecord({ fields })
        .then(() => {
          this.showSuccessToast(SUCCESS_MESSAGE.edit);
          this.doPostUpsertActions();
          if (state.isSaveAndExitAction) {
            this.navigateToParentRecord();
          } else {
            this.fieldValues = { ...this.fieldValues, ...createMapWithValueProperty(fields) };
            this.hideLoadingSpinner();
          }
        })
        .catch((error) => {
          const errorMessages = getErrorMessage(error);
          this.showErrorToast(errorMessages);
          this.hideLoadingSpinner();
        });
    } catch (e) {
    }
  }

  doPostUpsertActions() {
    const postUpsertRecObjNames = Object.keys(this.postUpsertRecords);
    if (postUpsertRecObjNames.length) {
      postUpsertRecObjNames.forEach((objName) => {
        const fnName = POST_UPSERT_ACTION_MAPPING[objName];
        if (fnName && fnName in this) {
          const records = this.postUpsertRecords[objName].map((rec) => {
            const relatedFieldName = RELATED_FIELD_NAME[objName];
            if (relatedFieldName) {
              rec[relatedFieldName] = this.recordId;
            }

            return rec;
          });
          this[fnName](records, objName);
        }
      });
    }
    if (!this.state.isSaveAndExitAction) {
      this.loadAutomationTable();
    }
  }

  // Below methods are being called dynamically on the basis of mapping given in constant.js file
  saveRelatedRecords(newRecords, objectApiName) {
    const existingRecords = this.relatedRecords[objectApiName] || [];
    if (newRecords.length || existingRecords.length) {
      const newlySelectedRecords =
      objectApiName === 'NSP_Implementation_Profile_Copy_Data__c'
        ? []
        : newRecords;

      const recordsToDelete = this.getDeletedRecords(
        newlySelectedRecords,
        existingRecords
      );

      const recordsConfig = JSON.stringify({
        recordsToUpsert: newRecords,
        recordsToDelete,
      });

      saveAndDeleteRecords({ recordsConfig, objectApiName })
        .then(() => {
          this.fetchIpRelatedRecords();
        })
        .catch((error) => {
          this.showErrorToast(error.body.message);
        });
    }
  }

  formatRelatedData(res) {
    const data = { ...res };
    const ipCopyData = res.NSP_Implementation_Profile_Copy_Data__c;

    if (isNonEmptyArray(ipCopyData)) {
      this.state.copiedExistingRecordOptions =
        this.getCopyDataOptions(ipCopyData);
      data.NSP_Implementation_Profile_Copy_Data__c = ipCopyData.map(
        (val) => val.split('~')[0]
      );
    }

    return data;
  }

  getDeletedRecords(newRecords, existingRecords) {
    const updatedExistingRecords = newRecords
      .map(({ Id }) => Id)
      .filter((id) => !!id);

    const recordsToDelete = existingRecords
      .filter(
        (id) => typeof id === 'string' && !updatedExistingRecords.includes(id)
      )
      .map((Id) => {
        return { Id };
      });

    return recordsToDelete;
  }

  saveEmpDataRecords(empRecords) {
    if (empRecords.length) {
      const parentFieldNames = [
        ...new Set(empRecords.map((rec) => rec.NSP_Parent_Field_API_Name__c)),
      ];
      saveEmployeeData({
        records: JSON.stringify(empRecords),
        ipRecId: this.recordId,
        parentFieldNames,
      })
        .then(() => {
          this.showSuccessToast(SUCCESS_MESSAGE.employeeData);
          this.fetchIpRelatedRecords();
        })
        .catch((error) => this.showErrorToast(error.body.message));
    }
  }

  navigateToParentRecord() {
    const recId = sessionStorage.getItem('getParentRecId') || this.recordId;

    this.navigateToRecord(recId);
    sessionStorage.removeItem('getParentRecId');
  }

  navigateToRecord(getRecordId) {
    const config = {
      type: 'standard__recordPage',
      attributes: {
        recordId: getRecordId,
        actionName: 'view',
      },
    };

    this[NavigationMixin.GenerateUrl](config)
      .then((url) => {
        window.location.replace(url);
      });
  }

  getComponentByName(name) {
    return this.template.querySelector(`[data-id=${name}]`);
  }

  doHandleScroll = debounce(() => {
    const { scrollTop } = this.contentElm;
    const { selectedTab } = this.state;

    this.sectionElms.forEach((section) => {
      const { offsetHeight, offsetTop, dataset } = section;

      if (
        scrollTop >= offsetTop - SECTION_MARGIN &&
        scrollTop < offsetHeight + offsetTop - SECTION_MARGIN &&
        selectedTab !== dataset.id
      ) {
        this.state.selectedTab = dataset.id;
        const tab = this.template.querySelector(
          `lightning-vertical-navigation-item[data-section=${dataset.id}]`
        );
        tab.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    });
  }, SCROLL_DELAY_MS);

  showToast(config) {
    this.dispatchEvent(new ShowToastEvent({ ...config }));
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

  showLoadingSpinner() {
    this.state.isLoading = true;
  }

  hideLoadingSpinner() {
    this.state.isLoading = false;
  }

  handleRefreshRequest({ detail }) {
    const sectionData = this.template.querySelector(`[data-id=${detail}]`).getFormValues();
    this.sectionsData = { ...this.sectionsData, [detail]: sectionData }
  }

  loadAutomationTable() {
    const { recordTypeId, recordId } = this;
    loadIPRecords({ recordTypeId, recordId }).then(wireResult => {
      if (wireResult) {
        this.ipAutomationTable = wireResult;
      }
    }).catch((error) => {
      this.showErrorToast(error.body.message);
    });
  }

  fetchIpRelatedRecords() {
    this.showLoadingSpinner();

    getIPRelatedRecords({ recordId: this.recordId })
      .then((data) => (this.relatedRecords = this.formatRelatedData(data)))
      .catch((error) => this.showErrorToast(error.body.message))
      .finally(() => this.hideLoadingSpinner());
  }

  get contentElm() {
    return this.template.querySelector('.content');
  }

  get header() {
    return this.template.querySelector('c-nsp_ip-form-header');
  }

  get footer() {
    return this.template.querySelector('.nsp_footer');
  }

  get objFields() {
    return this.objectInfo ? this.objectInfo.fields : {};
  }

  get objectApiName() {
    return IP_OBJECT.objectApiName;
  }

  get label() {
    return labels;
  }

  get sectionElms() {
    return this.template.querySelectorAll('[data-id]');
  }

  get saveAndExitButtonConfig() {
    return SAVE_AND_EXIT_DIALOG_BUTTON_CONFIG;
  }

  get allValues() {
    let formValues = {};
    const { recordId, state, fieldValues } = this;
    this.postUpsertRecords = {};
    if (isNonEmptyArray(state.copiedTargetRecords)) {
      this.addCopyDataRecords();
    }

    this.sectionElms.forEach((section) => {
      const sectionValues = section.getFormValues();

      this.updatePostUpsertRecords(sectionValues);
      // Prevent sections from overwriting user's updated value of a field.
      if (fieldValues) {
        Object.keys(sectionValues).forEach((fieldName) => {
          const updatedValue = sectionValues[fieldName];
          const existingValue = fieldValues[fieldName]
            ? fieldValues[fieldName].value
            : null;

          if (updatedValue !== existingValue) {
            formValues[fieldName] = updatedValue;
          }
        });
      } else {
        formValues = { ...formValues, ...sectionValues };
      }
    });
    formValues[ID_FIELD.fieldApiName] = recordId;
    formValues.NSP_Form_Completed__c = state.isFormCompleted;

    // Store previous values of specific fields in object if their value got changed
    this.updatePreviousValuesInFields(formValues);

    formValues.NSP_Copy_Section_Selections__c =
      state.selectedSections.join(';');

    return formValues;
  }

  updatePostUpsertRecords(sectionValues) {
    const { postUpsertRecords } = sectionValues;
    if (postUpsertRecords) {
      Object.keys(postUpsertRecords).forEach((objName) => {
        const rec = this.postUpsertRecords[objName] || [];
        this.postUpsertRecords[objName] = [
          ...rec,
          ...postUpsertRecords[objName],
        ];
      });
    }
  }

  updatePreviousValuesInFields(formValues) {
    const updatedFields = Object.keys(formValues);

    Object.keys(PREVIOUS_VALUE_FIELDS_MAPPING).forEach(fieldName => {
      if (updatedFields.includes(fieldName)) {
        const oldValueFieldName = PREVIOUS_VALUE_FIELDS_MAPPING[fieldName];

        formValues[oldValueFieldName] = this.fieldValues[fieldName]?.value;
      }
    })
  }

  get isReadOnly() {
    const { createable, updateable } = this._objectInfo;

    return this.recordId ? !updateable : !createable;
  }

  get copyAbleSections() {
    return this.sections.filter(
      ({ name }) => !NON_COPY_ABLE_SECTIONS.includes(name)
    );
  }

  get selectedCopySections() {
    const { state, fieldValues } = this;

    if (isNonEmptyArray(state.selectedSections) || this.copySectionChanged) {
      return state.selectedSections;
    }

    const allSections = this.copyAbleSections.map(({ name }) => name);
    if (this.recordId && fieldValues?.NSP_Copy_Section_Selections__c?.value) {
      const selections =
        fieldValues.NSP_Copy_Section_Selections__c.value.split(';');
      state.selectedSections = isNonEmptyArray(selections)
        ? selections
        : allSections;
    } else {
      state.selectedSections = allSections;
    }

    return state.selectedSections;
  }

}
