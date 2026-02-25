import { LightningElement , api , wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import autoPopulateAsset from '@salesforce/apex/NSP_CustomCaseCreationPageController.autoPopulateAsset';
import getRelatedCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedCategory';
import getRelatedSubCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedSubCategory';
import getCategoryList from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryList';
import getAllCategoryList from '@salesforce/apex/NSP_CustomCaseCreationPageController.getAllCategoryList';
import getCategoryDependenciesMap from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryDependenciesMap';
import isUserInQueue from '@salesforce/apex/NSP_CustomCaseCreationPageController.isUserInQueue';
import getProfileName from '@salesforce/apex/NSP_CustomCaseCreationPageController.getProfileName';

export default class CaseCatSubcatDetail extends LightningElement {
    @api oCase = {};
    profileName = '' ;
    recordTypeID;
    @api recTypeId='';
    @api cqaChildCase = false;
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
    open = false;
    disableButton = false;
    accountID = '';
    projectId = '';
    contactID = '';
    @api parentId = '';
    assetId = '';
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
    isConnectedWithSelectedCategory = false;
    isConnectedWithShowAllCategory = false;
    isConnectedWithShowAllSubCategory = false;

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
                } else {
                    this.isBPSUser = false;
                }
            });
            // Call getCatDependenciesMap here after data is processed
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
                this.open = true;
            });
        } else if (result.error) {
            this.error = result.error;
        }
    }
    connectedCallback() {
        this.handleProfileName();
        if ( this.selectedCategory !== undefined ) {
            this.isConnectedWithSelectedCategory = true;
        }
        if ( this.showAllCategory ) {
            this.isConnectedWithShowAllCategory = true;
            this.handleCategoryViewAll();
        }
        if ( this.showAllSubCategory ) {
            this.isConnectedWithShowAllSubCategory = true;
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

    dispatchSelectionUpdate() {
        this.dispatchEvent(
            new CustomEvent(
                'selectionchange' ,
                {
                    detail: {
                        category: this.selectedCategory ,
                        subCategory: this.selectedSubCategory ,
                        detail: this.selectedDetail ,
                        version: this.selectedVersion ,
                        detailOptions: this.detailOptions ,
                        versionOptions: this.versionOptions
                    }
                }
            )
        );
    }

    handleChange(event) {
        const { name, fieldName, value } = event.currentTarget;
        if (name) {
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
        } else if (fieldName === 'Type') {
            this.selectedType = event.detail.value;
        }
        if (this.disableButton) {
            this.disableButton = false;
        }
        this.handleDisplayConfidentialCheckBox();
        this.dispatchChangeFields();
    }

    handleCategoryChange(value) {
        this.selectedCategory = value;
        let options = [];
        let localKey = value;
        if ( this.categoryWrapper?.mCatToSubCatogories
            && localKey
            && ( localKey in this.categoryWrapper.mCatToSubCatogories )
            )
        {
            options = this.categoryWrapper.mCatToSubCatogories[localKey];
        }
        this.subCategoryOptions = this.createOptions( options );
        this.resetSelection( [ 'SubCategory' , 'Detail' , 'Version' ] );
        this.showAllSubCategoryButton = !this.isBPSUser && this.subCategoryOptions.length > 0;
        this.dispatchEvent(new CustomEvent('catsubcatselect', {
            detail: { type: 'Category', value: this.selectedCategory }
        }));
    }

    handleSubCategoryChange(value) {
        this.selectedSubCategory = value;
        this.dispatchEvent(new CustomEvent('catsubcatselect', {
            detail: { type: 'SubCategory', value }
        }));
        let localKey = `${this.selectedCategory}-${value}`;
        let options = [];
        if ( this.categoryWrapper?.mCatSubToDetails
            && localKey
            && ( localKey in this.categoryWrapper.mCatSubToDetails )
            )
        {
            options = this.categoryWrapper.mCatSubToDetails[localKey];
        }
        this.detailOptions = this.createOptions( options );
        this.resetSelection( [ 'Detail' , 'Version' ] );
        this.showDetail = this.detailOptions.length > 0;
        localKey = `${this.selectedCategory}-${this.selectedSubCategory}-${this.selectedDetail}`;
        options = [];
        if ( this.categoryWrapper?.mCatSubDetailToVersions
            && localKey
            && ( localKey in this.categoryWrapper.mCatSubDetailToVersions )
            )
        {
            options = this.categoryWrapper.mCatSubDetailToVersions[localKey];
        }
        this.versionOptions = this.createOptions( options );
        this.showVersion = this.versionOptions.length > 0;
        this.recordTypeID = this.recordTypeCategoryMap.get(`${this.selectedCategory}-${this.selectedSubCategory}`);
        if (this.selectedCategory && this.selectedSubCategory && this.accountID) {
            this.handlePopulateAsset();
        }
    }

    handleDetailChange(value) {
        this.selectedDetail = value;
        let options = [];
        let localKey = `${this.selectedCategory}-${this.selectedSubCategory}-${value}`;
        if ( this.categoryWrapper?.mCatSubDetailToVersions
            && localKey
            && ( localKey in this.categoryWrapper.mCatSubDetailToVersions )
            )
        {
            options = this.categoryWrapper.mCatSubDetailToVersions[localKey];
        }
        this.versionOptions = this.createOptions( options );
        this.showVersion = this.versionOptions.length > 0;
    }

    resetSelection( fields ) {
        if ( fields.includes( 'SubCategory' ) ) {
            this.selectedSubCategory = null;
        }
        if ( fields.includes( 'Detail' ) ) {
            this.showDetail = false;
            this.selectedDetail = null;
        }
        if ( fields.includes( 'Version' ) ) {
            this.showVersion = false;
            this.selectedVersion = null;
        }
    }

    createOptions(lValues){
        lValues = lValues || [];
        return lValues.map( (row) => {
            return { label : row , value : row }
        });
    }

    handlePopulateAsset(){
        autoPopulateAsset({
            category:this.selectedCategory,
            subCategory: this.selectedSubCategory,
            accountId: this.accountID}).
        then((result) => {
            if(result != null || (result == null && this.selectedCategory != undefined) ){
                this.assetId = result != null && result.length >= 1 ? result[0].Id : '';
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

    handleCategoryViewAll(event){
        this.showAllCategory = true;
        this.showAllSubCategory = true;
        this.showAllSubCategoryButton = false;
        this.showFilterSubCategoryButton = false;
        this.getAllCatSubDetValues();
        this.getFiteredSubCatValues();
        this.getCatDependenciesMap();
        if(this.isConnectedWithSelectedCategory && !this.isConnectedWithShowAllCategory){
            this.selectedSubCategory = null;
            this.selectedDetail = null;
            this.handleDisplayConfidentialCheckBox();
        }
        this.dispatchChangeFields();
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
            this.selectedSubCategory = null; // Added
            this.selectedDetail = null;
            this.selectedVersion = null;
            this.recordTypeID = this.selectedAllRecordTypeMap.get(event.target.value);
            this.showAllSubCategory = true;
            this.showAllSubCategoryButton = false;
            this.showFilterSubCategoryButton = false;
            this.getFiteredSubCatValues();
            const selectEvent = new CustomEvent('catsubcatselect',{detail: {type:'Category',value:this.selectedCategory}});
            this.dispatchEvent(selectEvent);
        }
        if (event.currentTarget.name == 'Sub Category') {
            this.selectedSubCategory = event.target.value;
            let options = [];
            let localKey = this.selectedCategory + '-' + event.target.value;
            if ( this.categoryWrapper?.mCatToSubCatogories
                && localKey
                && ( localKey in this.categoryWrapper.mCatToSubCatogories )
                )
            {
                options = this.categoryWrapper.mCatToSubCatogories[localKey];
            }
            this.subCategoryOptions = this.createOptions( options );
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
            if(this.selectedCategory.length>0 && this.selectedSubCategory.length>0 && this.accountID.length>0){
                this.handlePopulateAsset(event);
            }
            const selectEvent = new CustomEvent('catsubcatselect',{detail: {type:'SubCategory',value:this.selectedSubCategory}});
            this.dispatchEvent(selectEvent);
        }
        if (event.currentTarget.name == 'Detail') {
            this.selectedDetail = event.target.value;
            this.getFiteredVersionValues();
        }
        if (event.currentTarget.name == 'Version') {
            this.selectedVersion = event.detail.value;
        }
        this.handleDisplayConfidentialCheckBox();
        this.dispatchChangeFields();
    }

    handleCategoryFilteredView(event){
        this.showAllCategory = false;
        this.showAllSubCategory = true;
        let options = [];
        let localKey = this.selectedCategory;
        if ( this.categoryWrapper?.mCatToSubCatogories
            && localKey
            && ( localKey in this.categoryWrapper.mCatToSubCatogories )
            )
        {
            options = this.categoryWrapper.mCatToSubCatogories[localKey];
        }
        this.subCategoryOptions = this.createOptions( options );
        this.handleDisplayConfidentialCheckBox();
        this.dispatchChangeFields();
    }

    handleSubCategoryViewAll(event){
        this.showAllSubCategory = true;
        this.showFilterSubCategoryButton = true;
        this.showAllSubCategoryButton = false;
        this.getFiteredSubCatValues();
        this.handleDisplayConfidentialCheckBox();
        this.dispatchChangeFields();
    }

    handleSubCategoryFiltered(event){
        this.showAllSubCategory = false;
        this.showAllSubCategoryButton = true;
        this.showFilterSubCategoryButton = false;
        let options = [];
        let localKey = this.selectedCategory;
        if ( this.categoryWrapper?.mCatToSubCatogories
            && localKey
            && ( localKey in this.categoryWrapper.mCatToSubCatogories )
            )
        {
            options = this.categoryWrapper.mCatToSubCatogories[localKey];
        }
        this.subCategoryOptions = this.createOptions( options );
        this.handleDisplayConfidentialCheckBox();
        this.dispatchChangeFields();
    }

    getCatDependenciesMap() {
        if ( this.isSidebar || this.isUnfiltered ) {
            this.showAllCategory = true;
        }
        getCategoryDependenciesMap({recordTypeId: this.recTypeId, isCatViewAll : this.showAllCategory}).then((response) => {
            let result = JSON.parse(response);
            if(this.categoryOptions.length == 0 ){
                this.categoryOptions = this.createOptions(Object.keys(result.mCatToSubCatogories).sort());
            }
            let isSystemAdmin = ( this.profileName && this.profileName.startsWith( 'System Admin' ) );
            if ( !isSystemAdmin && ( result.mCatToSubCatogories["HR Employee Relations"] != null ) ) {
                result.mCatToSubCatogories["HR Employee Relations"] = result.mCatToSubCatogories["HR Employee Relations"].filter(value => value !== "Separation Agreement Request");
            }
            if(!isSystemAdmin && !this.userPartOfQueue && result.mCatToSubCatogories["Compensation Services"]!==null && result.mCatToSubCatogories["Compensation Services"]!==undefined){
                result.mCatToSubCatogories["Compensation Services"] = result.mCatToSubCatogories["Compensation Services"].filter(value => (value == "Client Consultation" || value == "Salary Survey"));
            }
            if(this.subCategoryOptions.length == 0 ){
                this.subCategoryOptions = this.createOptions(result.mCatToSubCatogories[this.oCase.NSP_Category__c]);
            }
            if(this.detailOptions.length == 0){
                this.detailOptions = this.createOptions(result.mCatSubToDetails[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c]);
            }
            if(this.versionOptions.length == 0){
                this.versionOptions = this.createOptions(result.mCatSubDetailToVersions[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c + '-' + this.oCase.NSP_Detail__c]);
            }
            this.categoryWrapper = result;

        }).catch((error) => {
        })
    }

    dispatchChangeFields(){
        this.dispatchEvent(new CustomEvent('changefields', {}));
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

    renderedCallback() {
        if (this.shouldRenderCallback()) {
            this.renderCallOnce = true;
            this.handleSubCategoryRendering();
            this.handleDetailRendering();
            this.handleVersionRendering();
            this.handleDisplayConfidentialCheckBox();
        }
        if ( this.isSidebar ) {
            this.dispatchSelectionUpdate();
        }
    }

    shouldRenderCallback() {
        return (
            this.categoryWrapper.mCatToSubCatogories !== undefined &&
            this.categoryWrapper.mCatSubToDetails !== undefined &&
            this.selectedCategory !== undefined &&
            this.selectedSubCategory !== undefined &&
            !this.renderCallOnce
        );
    }

    handleSubCategoryRendering() {
        if (!this.isConnectedWithShowAllSubCategory) {
            this.handleSubCategoryFiltered();
        } else {
            this.getFiteredSubCatValues();
        }
    }

    handleDetailRendering() {
        const localKey = `${this.selectedCategory}-${this.selectedSubCategory}`;
        if ( ( this.selectedDetail !== undefined ) || ( this.isSidebar && ( this.selectedDetail === null ) ) ) {
            this.detailOptions = this.createOptions(this.categoryWrapper.mCatSubToDetails[localKey]);
            this.showDetail = this.detailOptions.length > 0;
        }
    }

    handleVersionRendering() {
        const localKey = `${this.selectedCategory}-${this.selectedSubCategory}`;
        if ( ( this.selectedVersion !== undefined ) || ( this.isSidebar && ( this.selectedVersion === null ) ) ) {
            this.versionOptions = this.createOptions(this.categoryWrapper.mCatSubDetailToVersions[`${localKey}-${this.selectedDetail}`]);
            this.showVersion = this.versionOptions.length > 0;
        }
    }

    @api variant;

    get isSidebar() {
        return ( this.variant === "sidebar" );
    }

    get isUnfiltered() {
        return ( this.variant === "unfiltered" );
    }

    get showTitle() {
        return !this.isSidebar;
    }

    get smallDeviceSize() {
        return "12";
    }

    get mediumDeviceSize() {
        return ( this.isSidebar ? this.smallDeviceSize : "6" );
    }

    get largeDeviceSize() {
       return this.mediumDeviceSize;
    }

}
//