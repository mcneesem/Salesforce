import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedCategory';
import getRelatedSubCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedSubCategory';
import getCategoryList from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryList';
import getAllCategoryList from '@salesforce/apex/NSP_CustomCaseCreationPageController.getAllCategoryList';
import getCategoryDependenciesMap from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryDependenciesMap';
import isUserInQueue from '@salesforce/apex/NSP_CustomCaseCreationPageController.isUserInQueue';
import getProfileName from '@salesforce/apex/NSP_CustomCaseCreationPageController.getProfileName';

export default class CaseCategorySubcategoryComponent extends LightningElement {
    profileName = '' ;
    recordTypeID;
    @api recTypeId='';
    showAllSubCategoryButton = false;
    showFilterSubCategoryButton = false;
    showDetail = false;
    @api selectedDetail = null;
    showVersion = false;
    versionOptions= [];
    @api selectedVersion = null;
    showAllDetail = false;
    @api showAllSubCategory = false;
    subCategoryOptions= [];
    detailOptions= [];
    categoryOptions= [];
    @api selectedCategory;
    @api selectedSubCategory;
    categoryWrapper = {};
    isBPSUser = false;
    @api showAllCategory = false;
    categoryArray = false;
    recordTypeCategoryMap = new Map();
    categorySubCategoryMap = new Map();
    categoryConfidentialMap = new Map();
    categoryDetailMap = new Map();
    categorySubCategoryConfidentialMap = new Map();
    categorySubCategoryDetailMap = new Map();
    @api categorySubCategoryDetailConfidentialMap = new Map();
    selectedAllRecordTypeMap = new Map();
    recordTypeMap = new Map();
    renderCallOnce = false;
    userPartOfQueue = false;
    isPreviousButtonClicked = false;
    isShowAllFromPrevious = false;
    isShowAllSubCatFromPrevious = false;

    verifyCompensationQueue(){
        isUserInQueue()
        .then(result => {
			this.userPartOfQueue = result;
		})
		.catch(error => {
            this.userPartOfQueue = false;
		})
    }

    @wire(getAllCategoryList, {recordTypeId: '$recTypeId'})
    wiredgetAllCategoryList(result){
        if (result.data) {
            this.selectedAllRecordTypeMap = new Map();
            result.data.forEach(element => {
                this.recordTypeMap = new Map();
                if(!this.selectedAllRecordTypeMap.has(element.NSP_Category__c)){
                    this.selectedAllRecordTypeMap.set(element.NSP_Category__c, this.recordTypeMap.get(element.NSP_RecordType__c));
                } 
                if(element.NSP_UserTitle__c == 'BPS User'){
                    this.isBPSUser = true;
                }else{
                    this.isBPSUser = false;
                }
            });
                this.verifyCompensationQueue();
                this.getCatDependenciesMap();
        }
    }

    @wire(getCategoryList, {recordTypeId: '$recTypeId', isCatViewAll : '$showAllCategory'})
    wiredgetCategoryList(result) {
        if (result.data) {
            this.error = undefined;
            this.categoryArray = new Array();
            this.recordTypeCategoryMap = new Map();
            this.categorySubCategoryMap = new Map();
            this.categoryConfidentialMap = new Map();
            this.categoryDetailMap = new Map();
            this.categorySubCategoryConfidentialMap = new Map();
            this.categorySubCategoryDetailMap = new Map();
            this.categorySubCategoryDetailConfidentialMap = new Map();
            result.data.forEach(element => {
                if(element.NSP_UserTitle__c == 'BPS User'){
                    this.isBPSUser = true;
                }else{
                    this.isBPSUser = false;
                }
                this.recordTypeMap = new Map();
                let categorySubCategoryKey = element.NSP_Category__c + '-' + element.NSP_Subcategory__c;
                let categorySubCategoryKeyDetail = element.NSP_Category__c + '-' + element.NSP_Subcategory__c + '-' + element.NSP_Detail__c;
                if (!this.recordTypeCategoryMap.has(categorySubCategoryKey)) {
                    this.recordTypeCategoryMap.set(categorySubCategoryKey, this.recordTypeMap.get(element.NSP_RecordType__c));
                }
                if (!this.categorySubCategoryMap.has(element.NSP_Category__c)) {
                    this.categorySubCategoryMap.set(element.NSP_Category__c, new Array());
                }
                this.categorySubCategoryMap.get(element.NSP_Category__c).push(element.NSP_Subcategory__c);
                if (!this.categoryConfidentialMap.has(element.NSP_Category__c)) {
                    this.categoryConfidentialMap.set(element.NSP_Category__c, new Array());
                }
                this.categoryConfidentialMap.get(element.NSP_Category__c).push(element.NSP_Display_confidential_popup__c);
                if (!this.categoryDetailMap.has(categorySubCategoryKey)) {
                    this.categoryDetailMap.set(categorySubCategoryKey, new Array());
                    this.categorySubCategoryConfidentialMap.set(categorySubCategoryKey, new Array());
                }
                this.categoryDetailMap.get(categorySubCategoryKey).push(element.NSP_Detail__c);
                this.categorySubCategoryConfidentialMap.get(categorySubCategoryKey).push(element.NSP_Display_confidential_popup__c);
                if (!this.categorySubCategoryDetailMap.has(categorySubCategoryKeyDetail)) {
                    this.categorySubCategoryDetailConfidentialMap.set(categorySubCategoryKeyDetail, new Array());
                }
                this.categorySubCategoryDetailConfidentialMap.get(categorySubCategoryKeyDetail).push(element.NSP_Display_confidential_popup__c);
            });
            let arrayTemp = Array.from(this.categorySubCategoryMap.keys());
            arrayTemp.forEach(element => {
                this.categoryArray.push({ label: element, value: element });
            });
        } else if (result.error) {
            this.error = result.error;
        }
    }
    connectedCallback() {
        this.handleProfileName();
        if(this.selectedCategory!==undefined){
           this.isPreviousButtonClicked = true;
        }
        if(this.showAllCategory){
           this.isShowAllFromPrevious = true;
           this.handleCategoryViewAll();
        }
        if(this.showAllSubCategory){
           this.isShowAllSubCatFromPrevious = true;
           this.handleSubCategoryViewAll();
        }
    }
    handleProfileName(){
        getProfileName().
        then((result) => {
            if (result) {
                this.profileName = result;
            }
            this.error = undefined;
        })
        .catch((error) => {
            this.error = error;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error!!',
                    message: error.message,
                    variant: 'error',
                }),
            );
        });
    
    }

    handleChange(event) {
        if (event.currentTarget.name == 'Category') {
            this.selectedCategory = event.target.value;
            this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.selectedCategory]);
            this.showDetail = false;
            this.selectedDetail = null;
            this.showVersion = false;
            this.selectedVersion = null;
            this.showAllDetail = false;
            this.showAllSubCategory = false;
            if(this.isBPSUser == false && this.subCategoryOptions.length > 0){
                this.showAllSubCategoryButton = true;
            }
        }
        if (event.currentTarget.name == 'Sub Category') {
            this.selectedSubCategory = event.target.value;
            this.detailOptions = this.createOptions(this.categoryWrapper.mCatSubToDetails[this.selectedCategory + '-' + event.target.value]);
            if(this.detailOptions.length > 0){
                this.showDetail = true;
                this.showAllDetail = false;
            }else{
                this.showDetail = false;
                this.showAllDetail = false;
                this.selectedDetail = null;
            }
            this.versionOptions = this.createOptions(this.categoryWrapper.mCatSubDetailToVersions[this.selectedCategory + '-' + this.selectedSubCategory + '-' + this.selectedDetail]);
            if(this.versionOptions.length > 0){
                this.showVersion = true;
            }else{
                this.showVersion = false;
                this.selectedVersion = null;
            }
            this.recordTypeID = this.recordTypeCategoryMap.get(this.selectedCategory + '-' + this.selectedSubCategory);
        }
        if (event.currentTarget.name == 'Detail') {
            this.selectedDetail = event.target.value;
            this.versionOptions = this.createOptions(this.categoryWrapper.mCatSubDetailToVersions[this.selectedCategory + '-' + this.selectedSubCategory + '-' + event.target.value]);
            if(this.versionOptions.length > 0){
                this.showVersion = true;
            }else{
                this.showVersion = false;
                this.selectedVersion = null;
            }
        }
        if (event.currentTarget.name == 'Version') {
            this.selectedVersion = event.detail.value;
        }
        if(event.currentTarget.fieldName = 'Type'){
            this.selectedType = event.detail.value;
        }
        this.handleDisplayConfidentialCheckBox();
        //to pass selected values to confidential component
        const selectEvent = new CustomEvent('changefields',{});
        this.dispatchEvent(selectEvent);
    }

    createOptions(lValues){
        lValues = lValues || [];
        return lValues.map( (row) => {
            return { label : row , value : row }
        });
    }
    
    handleCategoryViewAll(event){
        this.showAllCategory = true;
        this.showAllSubCategory = true;
        this.showAllSubCategoryButton = false;
        this.showFilterSubCategoryButton = false;
        this.getAllCatSubDetValues();
        this.getFiteredSubCatValues();
        this.getCatDependenciesMap();
        if(this.isPreviousButtonClicked && !this.isShowAllFromPrevious){
           this.selectedSubCategory = null;
           this.selectedDetail = null;
           this.handleDisplayConfidentialCheckBox();
        }
    }

    getAllCatSubDetValues(){
        let role = 'BPS User';
        getRelatedCategory({selectedRole: role,recordTypeId: this.recTypeId }).then((response) => {
            this.categoryOptions = this.createOptions(response);
        }).catch((error) => {
        })
    }

    getFiteredSubCatValues(){
        this.subCategoryOptions = [];
        getRelatedSubCategory({selectedCategory: this.selectedCategory, recordTypeId: this.recTypeId, isviewAllSubCat: this.showAllSubCategory}).then((response) => {
            let isSystemAdmin = ( this.profileName && this.profileName.startsWith( 'System Admin' ) );
            if ( !isSystemAdmin ) {
                response = response.filter(value => value !== "Separation Agreement Request");
            }
            if(this.selectedCategory==='Compensation Services' && !isSystemAdmin && !this.userPartOfQueue){
                response = response.filter(value => (value === "Client Consultation" || value == "Salary Survey"));
            }
            this.subCategoryOptions = this.createOptions(response);
        }).catch((error) => {
            
        })
    }

    handleChange1(event) {
        if (event.currentTarget.name == 'Category') {
            this.selectedCategory = event.target.value;
            this.showAllDetail = false;
            this.showDetail = false;
            this.showVersion = false;
            this.selectedDetail = null;
            this.selectedVersion = null;
            this.recordTypeID = this.selectedAllRecordTypeMap.get(event.target.value);
            this.showAllSubCategory = true;
            this.showAllSubCategoryButton = false;
            this.showFilterSubCategoryButton = false;
            this.getFiteredSubCatValues();
        }
        if (event.currentTarget.name == 'Sub Category') {
            this.selectedSubCategory = event.target.value;
            this.detailOptions = this.createOptions(this.categoryWrapper.mCatSubToDetails[this.selectedCategory + '-' + event.target.value]);
            if(this.detailOptions.length > 0){
                this.showDetail = true;
                this.showAllDetail = false;
            }else{
                this.showDetail = false;
                this.showAllDetail = false;
                this.selectedDetail = null;
            }
            this.showVersion = false;
            this.selectedVersion = null;
        }
        if (event.currentTarget.name == 'Detail') {
            this.selectedDetail = event.target.value;
            this.getFiteredVersionValues();
        }
        if (event.currentTarget.name == 'Version') {
            this.selectedVersion = event.detail.value;
        }
        this.handleDisplayConfidentialCheckBox();
        const selectEvent = new CustomEvent('changefields',{});
        this.dispatchEvent(selectEvent);
    }

    handleCategoryFilteredView(event){
        this.showAllCategory = false;
        this.showAllSubCategory = true;
        this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.selectedCategory]);
        this.handleDisplayConfidentialCheckBox();
    }

    handleSubCategoryViewAll(event){
        this.showAllSubCategory = true;
        this.showFilterSubCategoryButton = true;
        this.showAllSubCategoryButton = false;
        this.getFiteredSubCatValues();
        this.handleDisplayConfidentialCheckBox();
    }

    handleSubCategoryFiltered(event){
        this.showAllSubCategory = false;
        this.showAllSubCategoryButton = true;
        this.showFilterSubCategoryButton = false;
        if(this.categoryWrapper.mCatToSubCatogories!==undefined){
          this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.selectedCategory]);
        }
        this.handleDisplayConfidentialCheckBox();        
    }

    getCatDependenciesMap(){
        getCategoryDependenciesMap({recordTypeId: this.recTypeId, isCatViewAll : this.showAllCategory}).then((response) => {
            let result = JSON.parse(response);
            this.categoryOptions = this.createOptions(Object.keys(result.mCatToSubCatogories).sort());
            let isSystemAdmin = ( this.profileName && this.profileName.startsWith( 'System Admin' ) );
            if ( !isSystemAdmin && ( result.mCatToSubCatogories["HR Employee Relations"] != null ) ) {
                result.mCatToSubCatogories["HR Employee Relations"] = result.mCatToSubCatogories["HR Employee Relations"].filter(value => value !== "Separation Agreement Request");
            }
            if(!isSystemAdmin && !this.userPartOfQueue && result.mCatToSubCatogories["Compensation Services"]!==null && result.mCatToSubCatogories["Compensation Services"]!==undefined){
                result.mCatToSubCatogories["Compensation Services"] = result.mCatToSubCatogories["Compensation Services"].filter(value => (value == "Client Consultation" || value == "Salary Survey"));
            }
            this.categoryWrapper = result;
        }).catch((error) => {
        })
    }

    @api
    getAllComboboxes() {
        return this.template.querySelectorAll('lightning-combobox');
    }
    handleDisplayConfidentialCheckBox(){
        let showConfidentialField = false; 
        if(this.selectedSubCategory != null && this.selectedCategory != null && this.selectedDetail != null){
                let catSubCatDetail = this.selectedCategory + '-' + this.selectedSubCategory + '-' + this.selectedDetail;
                showConfidentialField = this.categorySubCategoryDetailConfidentialMap.get(catSubCatDetail) != null ? this.categorySubCategoryDetailConfidentialMap.get(catSubCatDetail)[0] : false;
        }else if(this.selectedSubCategory != null && this.selectedCategory != null && !this.showDetail){
            let catSubCategory = this.selectedCategory + '-' + this.selectedSubCategory;
            showConfidentialField = this.categorySubCategoryConfidentialMap.get(catSubCategory) != null ? this.categorySubCategoryConfidentialMap.get(catSubCategory)[0] : false;
        }
        const confidentailevent = new CustomEvent('confidentailevent', {
            detail: showConfidentialField
        });
        this.dispatchEvent(confidentailevent);
    }
    
    renderedCallback(){
        if(this.categoryWrapper.mCatToSubCatogories!==undefined && this.categoryWrapper.mCatSubToDetails!==undefined  && this.selectedCategory!==undefined && this.selectedSubCategory!==undefined && !this.renderCallOnce){
            this.renderCallOnce = true;
            if(!this.isShowAllSubCatFromPrevious){
              this.handleSubCategoryFiltered();
            }
            else{
              this.getFiteredSubCatValues();
            }
            
            const localKey = this.selectedCategory + '-' + this.selectedSubCategory;
            if(this.selectedDetail!==undefined && this.selectedDetail!==null){
                this.showDetail = true;
                if(this.categoryWrapper.mCatSubToDetails!==undefined){
                    this.detailOptions = this.createOptions(
                    this.categoryWrapper.mCatSubToDetails[localKey]
                    );
                }
            }
            if(this.selectedVersion!==undefined && this.selectedVersion!==null){
                this.showVersion = true;
                this.versionOptions = this.createOptions(
                    this.categoryWrapper.mCatSubDetailToVersions[localKey + '-' + this.selectedDetail]
                );
            }
            this.handleDisplayConfidentialCheckBox();
        }
    }
}