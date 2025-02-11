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

    @wire(getCategoryList, { recordTypeId: '$recTypeId', isCatViewAll: '$showAllCategory' })
    wiredgetCategoryList(result) {
        if (result.data) {
            this.initializeMaps();
            this.isBPSUser = result.data.some(element => element.NSP_UserTitle__c === 'BPS User');
            
            result.data.forEach(element => {
                this.populateMaps(element);
            });
            
            this.categoryArray = Array.from(this.categorySubCategoryMap.keys()).map(key => ({ label: key, value: key }));
        } else if (result.error) {
            this.error = result.error;
        }
    }

    initializeMaps() {
        this.error = undefined;
        this.categoryArray = [];
        this.recordTypeCategoryMap = new Map();
        this.categorySubCategoryMap = new Map();
        this.categoryConfidentialMap = new Map();
        this.categoryDetailMap = new Map();
        this.categorySubCategoryConfidentialMap = new Map();
        this.categorySubCategoryDetailMap = new Map();
        this.categorySubCategoryDetailConfidentialMap = new Map();
    }

    populateMaps(element) {
        let categorySubCategoryKey = `${element.NSP_Category__c}-${element.NSP_Subcategory__c}`;
        let categorySubCategoryKeyDetail = `${categorySubCategoryKey}-${element.NSP_Detail__c}`;

        this.updateMap(this.categorySubCategoryMap, element.NSP_Category__c, element.NSP_Subcategory__c);
        this.updateMap(this.categoryConfidentialMap, element.NSP_Category__c, element.NSP_Display_confidential_popup__c);
        this.updateMap(this.categoryDetailMap, categorySubCategoryKey, element.NSP_Detail__c);
        this.updateMap(this.categorySubCategoryConfidentialMap, categorySubCategoryKey, element.NSP_Display_confidential_popup__c);
        this.updateMap(this.categorySubCategoryDetailConfidentialMap, categorySubCategoryKeyDetail, element.NSP_Display_confidential_popup__c);
    }

    updateMap(map, key, value) {
        if (!map.has(key)) {
            map.set(key, []);
        }
        map.get(key).push(value);
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
        const { name, value, fieldName } = event.currentTarget;
        
        switch (name) {
            case 'Category':
                this.handleCategoryChange(value);
                break;
            case 'Sub Category':
                this.handleSubCategoryChange(value);
                break;
            case 'Detail':
                this.handleDetailChange(value);
                break;
            case 'Version':
                this.selectedVersion = event.detail.value;
                break;
        }
        
        if (fieldName === 'Type') {
            this.selectedType = event.detail.value;
        }
        
        this.handleDisplayConfidentialCheckBox();
        this.dispatchEvent(new CustomEvent('changefields', {}));
    }

    handleCategoryChange(value) {
        this.selectedCategory = value;
        this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.selectedCategory]);
        this.resetDetailAndVersion();
        
        if (!this.isBPSUser && this.subCategoryOptions.length > 0) {
            this.showAllSubCategoryButton = true;
        }
    }

    handleSubCategoryChange(value) {
        this.selectedSubCategory = value;
        this.detailOptions = this.createOptions(this.categoryWrapper.mCatSubToDetails[`${this.selectedCategory}-${value}`]);
        this.showDetail = this.detailOptions.length > 0;
        
        this.versionOptions = this.createOptions(this.categoryWrapper.mCatSubDetailToVersions[`${this.selectedCategory}-${this.selectedSubCategory}-${this.selectedDetail}`]);
        this.showVersion = this.versionOptions.length > 0;
        
        this.recordTypeID = this.recordTypeCategoryMap.get(`${this.selectedCategory}-${this.selectedSubCategory}`);
    }

    handleDetailChange(value) {
        this.selectedDetail = value;
        this.versionOptions = this.createOptions(this.categoryWrapper.mCatSubDetailToVersions[`${this.selectedCategory}-${this.selectedSubCategory}-${value}`]);
        this.showVersion = this.versionOptions.length > 0;
    }

    resetDetailAndVersion() {
        this.showDetail = this.showVersion = this.showAllDetail = this.showAllSubCategory = false;
        this.selectedDetail = this.selectedVersion = null;
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