import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import getAllFieldSetFieldsBySObjectName from "@salesforce/apex/NSP_Utilities.getAllFieldSetFieldsBySObjectName";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from "lightning/actions";
import peoOrRetTemplate from "./nsp_newProjectTaskPEOCreationForm.html";
import defaultTemplate from "./nsp_newProjectTaskCreationForm.html";
import PROJECT_TASK from "@salesforce/schema/pse__Project_Task__c";
import PROJECT_TYPEFIELD from '@salesforce/schema/pse__Proj__c.pse__Project_Type__c';
import PROJECT_ACCOUNTFIELD from '@salesforce/schema/pse__Proj__c.pse__Account__c';
import getPeoProjectRelatedRecordTypes from "@salesforce/apex/NSP_CreateProjectTaskController.getPeoProjectRelatedRecordTypes";

export default class Nsp_newProjectTaskCreationForm extends NavigationMixin(LightningElement) {
    @api selectedRecTypeId = "";
    @api selectedRecordTypeName = "";
    @api projectId;
    @api projectTaskId;
    @api isPEORelated = false;
    @api objectApiName = "pse__Project_Task__c";
    @api recordId;
    @api isLoading = false;
    projectType;
    selectedCategory = "";
    selectedSubCategory = "";
    selectedDetail = "";
    selectedVersion = "";
    fieldSetMap = new Map();
    elementSize = 6;
    bpsInfoFields = [];
    bpsInfoLabel;
    bpsTaskHierarchyFields = [];
    bpsTaskHierarchyLabel;
    bpsTaskSystemInfoFields = [];
    bpsTaskSystemInfoLabel;
    peoTaskInfoFields = [];
    peoTaskInfoLabel;
    fieldServiceInfoFields = [];
    fieldServiceInfoLabel;
    error;
    errorMessageToDisplay = "";
    showError = false;
    disableButton = false;
    milestoneId = ''; 
    isCatSubCatShown = false;
    projectAccountId;
    @wire(CurrentPageReference)
    pageRef;

  renderedCallback() {
        if (this.projectId !== undefined && this.projectTaskId !== undefined && this.isCatSubCatShown !== true) {
            this.handleIsPeoProjectRelated(this.selectedRecordTypeName, this.projectId);
        }
    } 

    /* get ProjectTask RecordTypeInfo */
    @wire(getObjectInfo, { objectApiName: PROJECT_TASK })
    getProjectTaskRecordTypeDetails(result) {
        this.handleProjectTaskData(result);
    }
    
    @wire(getRecord , { recordId : '$projectId', fields: [PROJECT_TYPEFIELD, PROJECT_ACCOUNTFIELD] })
    getProjectRecord(value){
        const { error, data} = value;
        if(data){
            this.projectType = data.fields.pse__Project_Type__c.value;
            this.projectAccountId = data.fields.pse__Account__c.value;
            this.error = null;
        }else if(error){
            this.data = null;
            this.error = error;
        }
    }

    /* get all the fieldsets related to Project Task */
    @wire(getAllFieldSetFieldsBySObjectName, { objectApiName: "$objectApiName" })
    wiredFieldsToFetchSobject(result) {
        if (result.data) {
            this.fieldSetMap = new Map(Object.entries(result.data));
            this.loadBPSProjectTask();
        } else if (result.error) {
            this.isLoading = false;
            this.error = result.error;
        }
    }

    /* Map all the fieldsets accordingly */
    loadBPSProjectTask() {
        let bpsInfoSection = this.fieldSetMap.get("nsp_bps_project_task_information");
        if (bpsInfoSection != null && bpsInfoSection.length > 1) {
            this.bpsInfoFields = bpsInfoSection.map((obj) => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "pse__Project__c" ? (this.projectId !== undefined ? this.projectId : null) : null;
                return tempObj;
            });
            this.bpsInfoLabel = this.bpsInfoFields[0].fieldSetName;
        }

        let bpsTaskHierarchy = this.fieldSetMap.get("nsp_bps_project_task_task_hierarchy");
        if (bpsTaskHierarchy != null && bpsTaskHierarchy.length > 1) {
            this.bpsTaskHierarchyFields = bpsTaskHierarchy;
            this.bpsTaskHierarchyLabel = this.bpsTaskHierarchyFields[0].fieldSetName;
        }

        let bpsTaskSystemInfo = this.fieldSetMap.get("nsp_bps_project_task_system_information");
        if (bpsTaskSystemInfo != null && bpsTaskSystemInfo.length > 1) {
            this.bpsTaskSystemInfoFields = bpsTaskSystemInfo;
            this.bpsTaskSystemInfoLabel = this.bpsTaskSystemInfoFields[0].fieldSetName;
        }

        let peoInfoSection = this.fieldSetMap.get("nsp_peo_project_task_information");
        if (peoInfoSection != null && peoInfoSection.length > 1) {
            this.peoTaskInfoFields = peoInfoSection.map((obj) => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "pse__Project__c" ? (this.projectId !== undefined ? this.projectId : null) : null;
                return tempObj;
            });
            this.peoTaskInfoLabel = this.peoTaskInfoFields[0].fieldSetName;
        }

        let fieldServiceSection = this.fieldSetMap.get("nsp_field_service_section");
        if (fieldServiceSection != null && fieldServiceSection.length > 1) {
            this.fieldServiceInfoFields = fieldServiceSection;
            this.fieldServiceInfoLabel = this.fieldServiceInfoFields[0].fieldSetName;
        }
    }

    /* Reset the form once the user clicks on cancel or the record is saved */
    resetFormAction() {
        const lwcInputFields = this.template.querySelectorAll("lightning-input-field");
        if (lwcInputFields) {
            lwcInputFields.forEach((field) => {
                field.reset();
            });
        }
    }

    handleChange(event){
        this.projectId = event.currentTarget.value;
    }

    handleProjectTaskData(result){
        if (result.data) {  
            if (result.data.recordTypeInfos) {
                this.selectedRecTypeId = this.pageRef.state.recordTypeId;
                this.selectedRecTypeId = this.selectedRecTypeId == undefined ? result.data.defaultRecordTypeId : this.selectedRecTypeId;
                if (this.selectedRecTypeId) {
                    const rtis = result.data.recordTypeInfos;
                    this.recordTypeMap = new Map();
                    const selectedRT = Object.values(rtis).find((rt) => rt.recordTypeId === this.selectedRecTypeId);
                    this.selectedRecordTypeName = selectedRT.name;
                }
        
                if (this.projectId !== undefined) {
                    this.handleIsPeoProjectRelated(this.selectedRecordTypeName, this.projectId);
                }
            } else if (result.error) {
                this.error = result.error;
            }
        }
    }

    /* return Boolean depending on project and project task selection */
    handleIsPeoProjectRelated(selectedRecordTypeName, parentId) {
        getPeoProjectRelatedRecordTypes({
            selectedRecordTypeName: selectedRecordTypeName,
            projectId: parentId,
        })
            .then((result) => {
                if (result) {
                    this.isPEORelated = result;
                    this.isCatSubCatShown = true;
                }
                this.error = undefined;
            })
            .catch((error) => {
                this.error = error;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error!!",
                        message: error.message,
                        variant: "error",
                    })
                );
            });
    }

    handlelookupRecord(event){
        let selectedRecord = event.detail.recId;
        this.mileStoneId = selectedRecord != '' ? selectedRecord : '';
    }

    /* Event handling for Category and Sub category Selection */
    handleRecordCreation(event) {
        this.selectedCategory = event.detail.selCategory;
        this.selectedSubCategory = event.detail.selSubCategory;
        this.selectedDetail = event.detail.selDetail;
        this.selectedVersion = event.detail.selVersion;
        this.isPEORelated = false;
    }

    handleButtonClick() {}

    handleSubmit(event) {
        event.preventDefault();
        this.isLoading = true;
        this.showError = false;
        this.errorMessageToDisplay = "";
        this.disableButton = true;
        const fields = event.detail.fields;
        fields.pse__Milestone__c = this.mileStoneId;
        this.template.querySelector("lightning-record-edit-form").submit(fields);
    }

    handleSuccess(event) {
        this.isLoading = false;
        this.recordId = event.detail.id;
        let successMessage = "Project task Created Successfully.";
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(
            new ShowToastEvent({
                title: "Success",
                message: successMessage,
                variant: "success",
            })
        );

        this.resetFormAction(event);
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.recordId,
                actionName: "view",
            },
        });
    }

    handleError(event) {
        this.isLoading = false;
        let errorMessage = event.detail.detail;
        this.showError = true;
        this.errorMessageToDisplay = errorMessage;
        if (this.disableButton) this.disableButton = false;
    }

    handleCancel(event) {
        this.isLoading = true;
        this.resetFormAction(event);
        this.disableButton = true;
        if (this.projectTaskId != null && this.projectTaskId.length > 14) {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: this.projectTaskId,
                    actionName: "view",
                },
            });
        }  else if (this.projectId != null && this.projectId.length > 14) {
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: this.projectId,
                    actionName: "view",
                },
            }); 
        }else {
            this[NavigationMixin.Navigate]({
                type: "standard__objectPage",
                attributes: {
                    objectApiName: "pse__Project_Task__c",
                    actionName: "list",
                },
            });
        }
        this.isLoading = fasle;
    }

    get headerName() {
        return "New Project Task : " + this.selectedRecordTypeName;
    }

    get isShowFieldServiceSection() {
        return this.projectType == 'Implementation' && this.selectedRecordTypeName === "PEO Project Task";
    }

     //Added as part of Defect DF-03232
    get isRETProjectRecordType(){
        return this.selectedRecordTypeName === "RET Project Task";
    }

    render() {
        return this.selectedRecordTypeName === "PEO Project Task" || this.selectedRecordTypeName === "RET Project Task" ? peoOrRetTemplate : defaultTemplate;
    }
}