import { LightningElement, wire, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';

import retrieveProjectTask from '@salesforce/apex/Nps_CloneServicePlanProjectController.retrieveProjectTask';
import getFieldSetFieldsBySobject from '@salesforce/apex/NSP_Utilities.getFieldSetFieldsByFieldSetName';
import retrieveRecordTypes from '@salesforce/apex/Nps_CloneServicePlanProjectController.retrieveRecordTypes';
import getProjectRelatedRecordsData from '@salesforce/apex/Nps_CloneServicePlanProjectController.getProjectRelatedRecordsData';
import getProjectTemplatesBySegmentType from '@salesforce/apex/Nps_CloneServicePlanProjectController.getProjectTemplatesBySegmentType';
import createProjectRelatedRecords from '@salesforce/apex/Nps_CloneServicePlanProjectController.createProjectRelatedRecords';
import createProjectFromTemplate from '@salesforce/apex/Nps_CloneServicePlanProjectController.createProjectFromTemplate';

import {
  PROJECT_ACCOUNT_COLUMNS,
  MESSAGE,
  PROJECT_TASK_COLUMNS,
  PROJECT_OBJ_FIELDS,
} from './constants';

export default class Nps_CloneServicePlanProjectOnClosure extends NavigationMixin(
  LightningElement
) {
  @api recordId;

  @track state = {
    warningMessage: null,
    projTemplateId: null,
    isLoading: true,
  };

  copyProjectName = '';
  taskRecordTypeMap = new Map();
  taskRecordTypeId;

  recordTypeId;
  recordTypeName;
  isDialogVisible = false;
  projectStatus = null;
  servicePlanProjFields = [];
  fieldSetMap;
  accountID;
  OpportunityId;

  defaultPageSize = 100;
  error = null;

  taskItems = [];
  taskVisalbleData = [];
  taskRowpreSelectedRows = [];
  taskTableHight = 'task-table-default';

  taskDataTable;
  projectTemplates = null;

  prevStatus;
  // Initializes the component
  connectedCallback() {
    this.projectStatus = null;
  }

  @wire(getRecord, { recordId: '$recordId', fields: PROJECT_OBJ_FIELDS })
  getProjectDetails({ error, data }) {
    if (data) {
      //temp
      const { fields } = data;
      if (fields?.pse__Project_Type__c?.value == 'Service Plan') {
        const projectSavedStatus = fields.pse__Project_Status__c.value;
        if (
          ['Complete', 'Close/Lost'].includes(projectSavedStatus) &&
          projectSavedStatus != this.projectStatus &&
          this.projectStatus != null
        ) {
          const accountId = fields?.pse__Account__c.value;
          getProjectRelatedRecordsData({ projectId: this.recordId, accountId })
            .then((relatedData) => {
              this.relatedData = relatedData;
              if (relatedData.segmentType === 'Business Team') {
                if (Number.parseInt(relatedData.openProjectTasksCount)) {
                  this.showToast(MESSAGE.openTaskErrorMessage);
                }
              } else {
                this.isDialogVisible = true;
              }
            })
            .catch((error) => {
              this.error = error;
            });
        }
        this.prevStatus = this.projectStatus;
        this.projectStatus = data.fields.pse__Project_Status__c.value;

        this.getMetaDataFieldSet(data);
        if (data?.fields?.RecordTypeId?.value != null) {
          this.recordTypeId = data.fields.RecordTypeId.value;
          this.recordTypeName = data.fields.RecordType.displayValue;
        }
      }
    } else if (error) {
      this.error = error;
    }
  }

  getMetaDataFieldSet(data) {
    getFieldSetFieldsBySobject({
      objectApiName: 'pse__Proj__c',
      fieldSetName: 'NSP_CloneServicePlanProjectClosure',
    })
      .then((result) => {
        this.error = undefined;
        this.fieldSetMap = new Map(Object.entries(result));
        this.servicePlanProjFields = [];
        if (this.fieldSetMap != null && this.fieldSetMap.size > 1) {
          this.fieldSetMap.forEach((obj) => {
            let tempObj = { ...obj };
            switch (tempObj.apiName) {
              case 'pse__Account__c':
                tempObj.value = data.fields.pse__Account__c.value;
                break;
              case 'pse__Is_Billable__c':
                tempObj.value = data.fields.pse__Is_Billable__c.value;
                break;
              case 'Name':
                tempObj.value = data.fields.Name.value;
                this.copyProjectName = data.fields.Name.value;
                break;
              case 'pse__Is_Active__c':
                tempObj.value = true;
                break;
              case 'pse__Project_Status__c':
                tempObj.value = 'Active';
                break;
            }
            this.servicePlanProjFields.push(tempObj);
          });
        }
      })
      .catch((error) => {
        this.error = error;
      });
  }

  retrieveRelatedRecord() {
    const { segmentType } = this.relatedData;

    getProjectTemplatesBySegmentType({ segmentType })
      .then((result) => {
        this.projectTemplates = result;
      })
      .catch((error) => {
        this.error = error;
      });

    retrieveProjectTask({ recordId: this.recordId })
      .then((result) => {
        this.taskItems = result;
        if (result.length > 20) {
          this.taskTableHight = 'task-table-expanded';
        }
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
      });
  }

  updateProjectTaskpage({ detail }) {
    this.taskVisalbleData = [...detail.records];
    this.taskRowpreSelectedRows = [];
    this.taskVisalbleData = this.taskVisalbleData.map((obj) => {
      this.taskRowpreSelectedRows.push(obj.Id);
      let tempObj = { ...obj };

      if (tempObj.pse__Parent_Task__c != null) {
        tempObj.linkName = '/' + tempObj.pse__Parent_Task__c;
        if (tempObj.pse__Parent_Task__r.Name != null) {
          tempObj.ParentTask = tempObj.pse__Parent_Task__r.Name;
        }
      }

      return tempObj;
    });
  }

  taskRowSelection(event) {
    const selectedRows = event.detail.selectedRows;

    // If any open task unselected.
    if (selectedRows.length < this.taskItems.length) {
      this.state.warningMessage = MESSAGE.unselectedOpenTaskAvailableWarning;
    } else {
      this.state.warningMessage = null;
    }
  }

  handleProjectTemplateChange({ detail }) {
    this.state.projTemplateId = detail.value;
  }

  handleDialogAction({ detail, target }) {
    if (target.name === 'confirmModal') {
      if (detail !== 1) {
        if (detail.status === 'confirm') {
          this.isDialogVisible = false;
          this.handleShowModal();
        } else if (detail.status === 'cancel') {
          this.handleProcessTermination();
        }
      }
      //hides the component
      this.isDialogVisible = false;
    }
  }

  handleProcessTermination() {
    if (Number.parseInt(this.relatedData.openProjectTasksCount)) {
      this.showToast(MESSAGE.openTaskErrorMessage);
      updateRecord({ fields: { Id: this.recordId, pse__Project_Status__c: this.prevStatus } })
        .then()
        .catch((error) => {
          this.error = error;
        });
    }
  }

  handleSubmit(event) {
    event.preventDefault();
    this.state.isLoading = true;

    // Copy all form field values in a separate object
    const fields = { ...event.detail.fields };

    // Do pre-save operations here
    this.populateAdditionalFieldsValue(fields);

    this.createProject(fields);
  }

  createProject(projFields){
    createProjectFromTemplate({ templateId: this.state.projTemplateId,  fields: JSON.stringify(projFields)})
    .then((result) => {
      if(result){
        this.createProjPostSaveActions(result);
      }
    })
    .catch((error) => {
      this.error = error;
    });
  }

  populateAdditionalFieldsValue(fields) {
    const { projTemplateId } = this.state;

    // Populate selected Project template label in current record.
    if (projTemplateId) {
      fields.Templates_Used__c = this.projectTemplates.find(
        ({ value }) => value === projTemplateId
      ).label;
      fields.TemplateName__c = fields.Templates_Used__c;
    }
  }

  createProjPostSaveActions(newProjId) {
    
    const config = this.getProjectRelatedRecordsParamMap(newProjId);

    // After creating Project record successfully, create other records related to the Project
    createProjectRelatedRecords({ config })
      .then((errorList) => {
        this.doPostSaveAction(errorList, newProjId);
        this.state.isLoading = false;
      })
      .catch((error) => {
        this.error = error;
        this.state.isLoading = false;
      });
  }

  doPostSaveAction(errorList, newProjId) {
    if (errorList.length) {
      this.showToast(
        'Project related records process has been completed with the displayed errors!',
        'error'
      );
      this.error = errorList;
    } else {
      this.showToast('Project related records have been created.', 'success');
    }
    this.navigateToRecord(newProjId);
  }

  getProjectRelatedRecordsParamMap(newProjId) {
    const { selectedProjectTasks, selectedProjectAccounts } = this;
    const prevProjectTaskIds = selectedProjectTasks.map(({ Id }) => Id);
    const projectAccountIds = selectedProjectAccounts.map(
      ({ Account__c }) => Account__c
    );

    return JSON.stringify({
      projectTemplateId: this.state.projTemplateId,
      projectId: newProjId,
      prevProjectTaskIds: JSON.stringify(prevProjectTaskIds),
      projectAccountIds: JSON.stringify(projectAccountIds),
      oldProjectId: this.recordId,
    });
  }

  navigateToRecord(recordId) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId,
        actionName: 'view',
      },
    });
  }

  getRecordTypesDetail() {
    let objectList = ['pse__Project_Task__c'];
    retrieveRecordTypes({ sobjectList: objectList })
      .then((result) => {
        result.forEach((obj) => {
          let tempObj = { ...obj };

          if (tempObj.SobjectType.includes('Task')) {
            this.taskRecordTypeMap.set(obj.DeveloperName, obj.Id);
            if (
              this.recordTypeName.includes('PEO') &&
              obj.DeveloperName.includes('PEO')
            ) {
              this.taskRecordTypeId = obj.Id;
            } else if (obj.DeveloperName.includes('BPS')) {
              this.taskRecordTypeId = obj.Id;
            }
          }
        });
      })
      .catch((error) => {
        this.error = error;
      });
  }

  handleShowModal() {
    const modal = this.template.querySelector('c-modal');

    this.retrieveRelatedRecord();
    this.getRecordTypesDetail();

    modal.show();
  }

  handleFormLoad() {
    this.state.isLoading = false;
  }

  handleFormError(error) {
    this.error = error;
    this.state.isLoading = false;
  }

  handleCancelModal() {
    this.template.querySelector('c-modal').hide();
    this.handleProcessTermination();
  }

  showToast(message, toastVariant) {
    const variant = toastVariant || 'error';
    const event = new ShowToastEvent({
      title: variant,
      message,
      variant,
    });
    this.dispatchEvent(event);
  }

  get projectAccountRows() {
    return this.relatedData ? JSON.parse(this.relatedData.projectAccounts) : [];
  }

  get projectTaskColumns() {
    return PROJECT_TASK_COLUMNS;
  }

  get message() {
    return MESSAGE;
  }

  get selectedProjectAccounts() {
    return (
      this.template
        .querySelector('lightning-datatable.projectAccountDataTable')
        ?.getSelectedRows() || []
    );
  }

  get selectedProjectTasks() {
    return (
      this.template
        .querySelector('lightning-datatable.taskDataTable')
        ?.getSelectedRows() || []
    );
  }

  get projectAccountColumns() {
    return PROJECT_ACCOUNT_COLUMNS;
  }

  get isCreateProjectButtonDisabled() {
    return !this.state.projTemplateId;
  }
}
