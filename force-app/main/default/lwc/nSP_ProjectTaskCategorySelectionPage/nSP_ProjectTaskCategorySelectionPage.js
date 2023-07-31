import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import CAT_FIELD from '@salesforce/schema/pse__Project_Task__c.NSP_Category__c';
import SUBCAT_FIELD from '@salesforce/schema/pse__Project_Task__c.NSP_Sub_Category__c';
import DETAIL_FIELD from '@salesforce/schema/pse__Project_Task__c.NSP_Detail__c';
import VERSION_FIELD from '@salesforce/schema/pse__Project_Task__c.NSP_Version__c';
import SYNC_FIELD from '@salesforce/schema/pse__Project_Task__c.pse__Synchronize_Milestone_And_Task__c';
import PROJECT_FIELD from '@salesforce/schema/pse__Project_Task__c.pse__Project__c';
import RECORD_TYPE_ID_FIELD from '@salesforce/schema/pse__Project_Task__c.RecordTypeId';
import TEMPLATE_GENERATED_FIELD from '@salesforce/schema/pse__Project_Task__c.NSP_Template_Generated__c';
import PROJECT_TEMPLATE_FIELD from '@salesforce/schema/pse__Proj__c.pse__Is_Template__c';
import getCategoryDependenciesMap from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryDependenciesMap';
import { refreshApex } from '@salesforce/apex';
import ID_FIELD from '@salesforce/schema/pse__Project_Task__c.Id';
import getCategoryList from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryList';
import getRelatedCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedCategory';
import getRelatedSubCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedSubCategory';
import getRelatedDetail from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedDetail';
import getRelatedVersion from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedVersion';

export default class ProjectTaskCategorySubCategoryPage extends NavigationMixin(LightningElement) {
    // HARD CODED
    label = {
        header : "Task Category/Subcategory/Detail",
        editCase : "Edit",
        category : "Category",
        subcategory : "Subcategory",
        detail : "Detail",
        version : "Version",
        viewAll : "View All",
        reset : "Role Favorites",
        save : "Save",
        cancel : "Cancel"
    }

    @api recordId;
    @api isFromCreationPage = false;
    @api projectId;
    @api objectApiName;
    @api showPopUp = false;
    view = true;
    oProject= {};
    projectTask;
    category;
    subcategory;
    detail;
    version;
    sync;
    @api recordTypeId;
    templateGeneratedTask;
    categoryOptions= [];
    subCategoryOptions= [];
    detailOptions= [];
    categoryWrapper = {};
    selectedCategory;
    selectedSubCategory;
    selectedDetail;
    selectedVersion;
    showcategory = false;
    showsubcategory = false;
    showdetail = false;
    showVersion = false;
    submitLabel = 'Save';
    explicitSpinner = false;
    isLoading = false;
    //Added By Sruthi - start
    @track isBPSUser = false;
    categorySubCategoryMap = new Map();
    showingAllCategories = false;
    showingAllSubCategories = false;
    showingResetSubCategories = false;
    versionOptions= [];
    showEditComponent = false;

    connectedCallback(){
        this.fetchCategoryList();
        if(this.isFromCreationPage){
            this.getCatDependenciesMap();
            this.showcategory = true;
            this.showsubcategory = true;
        }
    }

    fetchCategoryList(){
        getCategoryList({recordTypeId : this.recordTypeId, isCatViewAll : false})
        .then(result => {
            if(result){
                result.forEach(element => {
                    if(element.NSP_UserTitle__c == 'BPS User'){
                        this.isBPSUser = true;
                    }else{
                        this.isBPSUser = false;
                    }
                    if (!this.categorySubCategoryMap.has(element.NSP_Category__c)) {
                        this.categorySubCategoryMap.set(element.NSP_Category__c, new Array());
                    } this.categorySubCategoryMap.get(element.NSP_Category__c).push(element.NSP_Subcategory__c);
                }); 
            }
        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error retrieving category list',
                    message: error.body.output.errors[0].message,
                    variant: 'error'
                })
            );
        });
    }
    
    //Added by Shruti - End
    @wire(getRecord, { recordId: '$recordId', fields: [CAT_FIELD, SUBCAT_FIELD, DETAIL_FIELD, VERSION_FIELD, SYNC_FIELD,PROJECT_FIELD, TEMPLATE_GENERATED_FIELD,RECORD_TYPE_ID_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.handleReloadProjectTask(data);
        }
    }
    @wire(getRecord , { recordId : '$projectId', fields: [PROJECT_TEMPLATE_FIELD] })
    getProjectRecord(value){
        this.projectData = value;
        const { error, data} = value;
        if(data){
            this.oProject = {
                'pse__Is_Template__c' : data.fields.pse__Is_Template__c.value
            }
            this.error = null;
        }else if(error){
            this.data = null;
            this.oProject = null;
        }
    }

    renderedCallback(){
        if(this.explicitSpinner){
            this.isLoading = false;
            this.explicitSpinner = false;
        }   
    }
    editCategory(){
        if(this.sync == false){
            this.showEditComponent = true;
        }else{
            this.showEditComponent = false;
        }
        this.view = false;
        this.showingResetSubCategories = false;
        this.showingAllSubCategories = true; 
        this.showingAllCategories = false;  
        this.getCatDependenciesMap();
        if(this.subCategoryOptions.length > 0 || this.selectedSubCategory != null){
            this.showsubcategory = true;
        }else{
            this.showsubcategory = false;
        }
        getRelatedDetail({selectedSubCategory: this.selectedSubCategory, recordTypeId: this.recordTypeId}).then((response) => {
            this.detailOptions = this.createOptions(response);
            if(this.detailOptions.length > 0){
                this.showdetail = true;
            }else{
                this.showdetail = false;
            }
            }).catch((error) => {
        })
        
        getRelatedVersion({selectedDetail: this.selectedDetail, recordTypeId: this.recordTypeId}).then((response) => {
            this.versionOptions = this.createOptions(response);
            if(this.versionOptions.length > 0){
                this.showVersion = true;
            }else{
                this.showVersion = false;
            }
        }).catch((error) => {
            //DO Errro AND SHOW ERROR
        })
        refreshApex(this.projectTask);
        this.handleReloadProjectTask(this.projectTask);
    }
    handleChange(event) {            
        if (event.currentTarget.name == 'Category') {
            this.selectedSubCategory = null;
            this.selectedDetail =  null;
            this.selectedVersion = null;
            this.showdetail = false;
            this.showVersion = false;
            this.selectedCategory = event.target.value;
                this.showingAllSubCategories = true;
                this.showingResetSubCategories = false; 
                this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.selectedCategory]);
        }
        if (event.currentTarget.name == 'Subcategory') {
            this.selectedSubCategory = event.target.value;
            getRelatedDetail({selectedSubCategory: this.selectedSubCategory, recordTypeId: this.recordTypeId}).then((response) => {
                this.detailOptions = this.createOptions(response);
                if(this.detailOptions.length > 0){
                    this.showdetail = true;
                }else{
                    this.showdetail = false;
                }
                }).catch((error) => {
            })
        }
        if (event.currentTarget.name =='Detail') {
            this.selectedDetail = event.target.value;
            getRelatedVersion({selectedDetail: this.selectedDetail, recordTypeId: this.recordTypeId}).then((response) => {
                this.versionOptions = this.createOptions(response);
                if(this.versionOptions.length > 0){
                    this.showVersion = true;
                }else{
                    this.showVersion = false;
                }
            }).catch((error) => {
                //DO Errro AND SHOW ERROR
            })
        }
        if (event.currentTarget.name =='Version') {
            this.selectedVersion = event.target.value;
        }
        
    }
    handleChange1(event) {
        if (event.target.value != null) {
            this.selectedCategory = event.target.value;
            this.selectedSubCategory = null;
            this.selectedDetail =  null;
            this.selectedVersion = null;
            this.showdetail = false;
            this.showVersion = false;
                this.showingAllSubCategories = true;
                this.showingResetSubCategories = false;
                this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.selectedCategory]);
        }
    }
    handleChange2(event) {
        if (event.target.value != null) {
            this.selectedSubCategory = event.target.value;
            this.selectedDetail =  null;
            this.selectedVersion = null;
            this.showdetail = false;
            this.showVersion = false;
            getRelatedDetail({selectedSubCategory: this.selectedSubCategory, recordTypeId: this.recordTypeId}).then((response) => {
                this.detailOptions = this.createOptions(response);
                if(this.detailOptions.length > 0){
                    this.showdetail = true;
                }else{
                    this.showdetail = false;
                }
                }).catch((error) => {
            })
        }
    }
    handleChange3(event) {
        if (event.target.value != null) {
            this.selectedDetail = event.target.value;
            this.selectedVersion = null;
            this.showVersion = false;
            getRelatedVersion({selectedDetail: this.selectedDetail, recordTypeId: this.recordTypeId}).then((response) => {
                this.versionOptions = this.createOptions(response);
                if(this.versionOptions.length > 0){
                    this.showVersion = true;
                }else{
                    this.showVersion = false;
                }
            }).catch((error) => {
                //DO Errro AND SHOW ERROR
            })
        }
    }
    handleChange4(event) {
        if (event.target.value != null) {
            this.selectedVersion = event.target.value;
        }
    }
    cancelDetails(){
        this.showPopUp = false;
    }
    cancel(){
        refreshApex(this.projectTask);
        this.handleReloadProjectTask(this.projectTask);
        this.view = true;
        if(this.selectedSubCategory != null){
            this.showsubcategory = true;
        }else{
            this.showsubcategory = false;
        }
    }

    handleReloadProjectTask(data){
        this.projectTask = data;
        this.category = this.projectTask.fields.NSP_Category__c.value;
        this.subcategory = this.projectTask.fields.NSP_Sub_Category__c.value;
        this.detail = this.projectTask.fields.NSP_Detail__c.value;
        this.version = this.projectTask.fields.NSP_Version__c.value;
        this.templateGeneratedTask = this.projectTask.fields.NSP_Template_Generated__c.value;
        this.projectId = this.projectTask.fields.pse__Project__c.value;
        this.recordTypeId = this.projectTask.fields.RecordTypeId.value;
        this.fetchCategoryList();
        this.selectedCategory = this.category;
        this.selectedSubCategory = this.subcategory;
        this.selectedDetail = this.detail;
        this.selectedVersion = this.version;
        if(this.selectedSubCategory != null){
            this.showsubcategory = true;
        }else{
            this.showsubcategory = false;
        }
         /* Added as part of DF-02175 */
        if(this.selectedDetail != null){
            this.showdetail = true;
        }else{
            this.showdetail = false;
        }
        /* Added as part of DF-02175 */
        this.sync = this.projectTask.fields.pse__Synchronize_Milestone_And_Task__c.value;
        if(this.sync == false){
            this.showEditComponent = true;
        }else{
            this.showEditComponent = false;
        }
        if (this.category == null && this.subcategory == null && this.detail == null && this.version == null && this.sync == false){
            this.showPopUp = true;
            if (this.category == null){
                this.showcategory = true;
                this.showsubcategory = true;
            }
        }
        else {
            this.showPopUp = false;
        }
        this.getCatDependenciesMap();
    }

    handleRecordCreation(){
     var detail = {selCategory: this.selectedCategory, selSubCategory: this.selectedSubCategory,
                          selDetail: this.selectedDetail, selVersion: this.selectedVersion};
     const oEvent = new CustomEvent('hanldeselectedcatsubcat',{ detail });
     this.dispatchEvent(oEvent); 
    }

    handleCancelRecordCreation(){
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.projectId,
                actionName: "view",
            },
        });
    }

    submitDetails() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[CAT_FIELD.fieldApiName] = this.selectedCategory;
        fields[SUBCAT_FIELD.fieldApiName] = this.selectedSubCategory;
        fields[DETAIL_FIELD.fieldApiName] = this.selectedDetail;
        fields[VERSION_FIELD.fieldApiName] = this.selectedVersion;
        const recordInput = {fields};

        this.isLoading = true;
        updateRecord(recordInput)
        .then(() => {
            this.explicitSpinner = true;
            this.showPopUp = false;
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Category/Sub-Categpry and Details data updated.',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: error.body.output.errors[0].message,
                    variant: 'error'
                })
            );
        });
    }
    saveDetails() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[CAT_FIELD.fieldApiName] = this.selectedCategory;
        fields[SUBCAT_FIELD.fieldApiName] = this.selectedSubCategory;
        fields[DETAIL_FIELD.fieldApiName] = this.selectedDetail;
        fields[VERSION_FIELD.fieldApiName] = this.selectedVersion;
        const recordInput = {fields};
        if(this.selectedSubCategory != null){
            this.showsubcategory = true;
        }else{
            this.showsubcategory = false;
        }

        this.isLoading = true;
        updateRecord(recordInput)
        .then(() => {
            this.explicitSpinner = true;
            this.view = true;
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Category/Sub-Categpry and Details data updated.',
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            this.isLoading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: error.body.output.errors[0].message,
                    variant: 'error'
                })
            );
        });
    }
    get showEditButton(){
        return this.view && !( this.templateGeneratedTask && ( this.category && this.subcategory ) && !this.oProject.pse__Is_Template__c);
    }
    getCatDependenciesMap(){
        getCategoryDependenciesMap( {recordTypeId: this.recordTypeId , isCatViewAll: this.showingAllCategories}).then((response) => {
            let result = JSON.parse(response);
            let categoryValues = this.addIfNotIncluded(Object.keys(result.mCatToSubCatogories).sort(),this.category)
            this.categoryOptions = this.createOptions(categoryValues);
            let subCategoryValues = this.addIfNotIncluded(result.mCatToSubCatogories[this.category],this.subcategory)
            this.subCategoryOptions = this.createOptions(subCategoryValues);
            let detailValues = this.addIfNotIncluded(result.mCatSubToDetails[this.category + '-' + this.subcategory],this.detail);
            this.detailOptions = this.createOptions(detailValues);
            let versionValues = this.addIfNotIncluded(result.mCatSubDetailToVersions[this.category + '-' + this.subcategory + '-' + this.detail],this.version);
            this.versionOptions = this.createOptions(versionValues);
            this.categoryWrapper = result;
        }).catch((error) => {
            //DO Errro AND SHOW ERROR
        })
    }
    createOptions(lValues){
        lValues = lValues || [];
        return lValues.map( (row) => {
            return { label : row , value : row }
        });
    }
    addIfNotIncluded(lValues,value){
        lValues = lValues || [];
        if(value && !lValues.includes(value)){
            lValues.push(value);
        }
        return lValues;
    }
    clearIfNotPresent(lValues,fieldName){
        lValues = lValues || [];
        if(!lValues.includes(this.oCase[fieldName])){
            this.oCase[fieldName] = null;
        }
    }
    showAllCategories(){
        this.showsubcategory = true;
        this.showingAllCategories = true;
        this.selectedDetail =  null;
        this.selectedVersion = null;
        this.selectedSubCategory = null;
        this.showdetail = false;
        this.showVersion = false;  
        this.detailOptions =[];
        this.versionOptions = [];
        this.subCategoryOptions = [];
        this.getCatDependenciesMap();
    }
    resetCategories(){
        this.showingAllCategories = false;
        this.selectedSubCategory = null;
        this.selectedDetail =  null;
        this.selectedVersion = null;
        this.showdetail = false;
        this.showVersion = false;
        this.detailOptions =[];
        this.versionOptions = [];
        this.subCategoryOptions = [];
        this.getCatDependenciesMap();
    }

    showAllSubCategories(){
        this.selectedDetail =  null;
        this.selectedVersion = null;
        this.showdetail = false;
        this.showVersion = false;
        this.detailOptions =[];
        this.versionOptions = [];
        this.showingResetSubCategories = true;
        this.showingAllSubCategories = false;
        getRelatedSubCategory({selectedCategory: this.selectedCategory, recordTypeId: this.recordTypeId, isviewAllSubCat: this.showingAllSubCategories}).then((response) => {
            this.subCategoryOptions = this.createOptions(response);
        }).catch((error) => {
            
        })
    }
    resetSubCategories(){
        this.selectedDetail =  null;
        this.selectedVersion = null;
        this.showdetail = false;
        this.showVersion = false;
        this.detailOptions =[];
        this.versionOptions = [];
        this.showingAllSubCategories = true;
        this.showingResetSubCategories = false;
        this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.selectedCategory]);
    }
    //Show view all
    get showViewAll(){        
        return (this.isBPSUser == false && this.showingAllCategories == false) ? true : false;
    }
}