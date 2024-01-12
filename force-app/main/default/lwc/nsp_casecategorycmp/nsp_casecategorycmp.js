import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCategoryDependenciesMap from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryDependenciesMap';
import getAllDependenciesValues from '@salesforce/apex/NSP_CustomCaseCreationPageController.getAllDependenciesValues';
import CATEGORY_FIELD from '@salesforce/schema/Case.NSP_Category__c';
import SUBCATEGORY_FIELD from '@salesforce/schema/Case.NSP_SubCategory__c';
import DETAIL_FIELD from '@salesforce/schema/Case.NSP_Detail__c';
import VERSION_FIELD from '@salesforce/schema/Case.NSP_Version__c';
import ID_FIELD from '@salesforce/schema/Case.Id';
import getCategoryList from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryList';
import getRelatedCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedCategory';
import getRelatedSubCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedSubCategory';
import getRelatedDetail from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedDetail';
import getRelatedVersion from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedVersion';
import strUserId from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';

const CASEFIELDS = [
    'Case.NSP_Category__c',
    'Case.NSP_SubCategory__c',
    'Case.NSP_Detail__c',
    'Case.NSP_Version__c',
    'Case.RecordTypeId'
];

export default class Nsp_casecategorycmp extends LightningElement {
    // HARD CODED
    label = {
        header : "Case Category/Subcategory/Detail",
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
    // PUBLIC 
    @api recordId;
    @api objectApiName;
    @api error;
    //Added By Sruthi - start
    @track isBPSUser = false;
    @track recordTypeId;
    categorySubCategoryMap = new Map();
    //Added By Sruthi - end

    // UI
    view = true;
    isLoading = false;
    explicitSpinner = false;
    showingAllCategories = false;
    showingAllSubCategories = false;
    showingResetSubCategories = false;

    // Data variables
    caseDetails;
    oCase = {};
    categoryWrapper = {};
    allCategoryWrapper = {};
    categoryOptions= [];
    subCategoryOptions= [];
    detailOptions= [];
    versionOptions= [];
    allCategoryOptions = []
    allSubCategoryOptions = [];
    allDetailsOptions = [];
    allVersionOptions = [];
    @track prfName;
    @track isBpsProfile=false;
    isNonAdminProfile = false;
    userId = strUserId;

    // added as a part of DF-02152
    @wire(getRecord, {recordId: strUserId,fields: [PROFILE_NAME_FIELD]}) 
    wireuser({error,data}) {
        if (error) {
        this.error = error ; 
        } else if (data) {
            this.prfName =data.fields.Profile.value.fields.Name.value;
            let isSystemAdmin = ( this.prfName && this.prfName.startsWith( 'System Admin' ) );
            if ( !isSystemAdmin ) {
                this.isNonAdminProfile = true;
            }
            if(this.prfName=='BPS Service'){
                this.isBpsProfile =true;
            }
        }
    }
    

    editCase(){
                    this.view = false;
            this.showingAllCategories = false;
            this.showingAllSubCategories = true;
            this.showingResetSubCategories = false;
            refreshApex(this.caseDetails);
            this.handleReloadOfCase(this.caseDetails);            
            this.getCatDependenciesMap();
            this.getAllCatSubDetValues();
            this.isLoading = true;
             getRelatedDetail({selectedSubCategory: this.oCase.NSP_SubCategory__c,selectedCategory : this.oCase.NSP_Category__c, recordTypeId: this.recordTypeId}).then((response) => {    
                this.detailOptions = this.createOptions(response);
                this.isLoading = false;
            }).catch((error) => {
            }) 
        
    }       
         //LIFECYCLE - HOOKS
     @wire(getRecord, { recordId: '$recordId', fields: CASEFIELDS })
     getCaseDetails(value){
         this.caseDetails = value;
         const { data,error } = value;
         if(data){
             let oCase = {
                 'NSP_Category__c' : data.fields.NSP_Category__c.value,
                 'NSP_SubCategory__c' : data.fields.NSP_SubCategory__c.value,
                 'NSP_Detail__c' : data.fields.NSP_Detail__c.value,
                 'NSP_Version__c' : data.fields.NSP_Version__c.value,
                 'RecordTypeId' : data.fields.RecordTypeId.value
             }
             this.oCase = oCase;
             this.recordTypeId = this.oCase.RecordTypeId;
         }else if(error){
            this.error = error;
         }
     }

    //Added by Shruti - Start
    @wire(getCategoryList, {recordTypeId: '$recordTypeId'})
    wiredgetCategoryList(result) {
        if (result.data) {
            result.data.forEach(element => {
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
    }
    //Added by Shruti - End    
   
   
    renderedCallback(){
        if(this.explicitSpinner){
            this.isLoading = false;
            this.explicitSpinner = false;
        }
            
    }

    getCatDependenciesMap(){
        getCategoryDependenciesMap({recordTypeId: this.recordTypeId, isCatViewAll: this.showingAllCategories}).then((response) => {
            let result = JSON.parse(response);
            if( this.isNonAdminProfile && result.mCatToSubCatogories["HR Employee Relations"] != null){
                result.mCatToSubCatogories["HR Employee Relations"] = result.mCatToSubCatogories["HR Employee Relations"].filter(value => value !== "Separation Agreement Request");
            }

            let categoryValues = this.addIfNotIncluded(Object.keys(result.mCatToSubCatogories).sort(),this.oCase.NSP_Category__c)
            this.categoryOptions = this.createOptions(categoryValues);
            let subCategoryValues = this.addIfNotIncluded(result.mCatToSubCatogories[this.oCase.NSP_Category__c],this.oCase.NSP_SubCategory__c)
            this.subCategoryOptions = this.createOptions(subCategoryValues);
            let detailValues = this.addIfNotIncluded(result.mCatSubToDetails[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c],this.oCase.NSP_Detail__c);
            this.detailOptions = this.createOptions(detailValues);
            let versionValues = this.addIfNotIncluded(result.mCatSubDetailToVersions[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c + '-' + this.oCase.NSP_Detail__c],this.oCase.NSP_Version__c);
            this.versionOptions = this.createOptions(versionValues);
            this.categoryWrapper = result;
        }).catch((error) => {
            //DO Errro AND SHOW ERROR
        })
    }

    getAllCatSubDetValues(){
        getAllDependenciesValues({recordTypeId: this.recordTypeId}).then((response) => {
            let result = JSON.parse(response);
            this.allCategoryOptions = this.createOptions(result.sCategories);
            this.allSubCategoryOptions = this.createOptions(result.sSubCategories);
            this.allDetailsOptions = this.createOptions(result.sDetails);
            this.allVersionOptions = this.createOptions(result.sVersions);
        }).catch((error) => {
            //DO Errro AND SHOW ERROR
        })
    }

    handleCategoryChange(event){
        let category = event.detail.value;
        this.handleSubcategoriesList(category);
    }

    handleSubcategoriesList(categorySelected){
        this.oCase.NSP_Category__c = categorySelected;
        let subCategoryValues = this.categoryWrapper.mCatToSubCatogories[categorySelected];
        this.clearIfNotPresent(subCategoryValues,"NSP_SubCategory__c");
        this.subCategoryOptions = this.createOptions(subCategoryValues);
        let detailValues = this.categoryWrapper.mCatSubToDetails[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c];
        this.clearIfNotPresent(detailValues,"NSP_Detail__c");
        this.detailOptions = this.createOptions(detailValues);
        let versionValues = this.categoryWrapper.mCatSubDetailToVersions[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c + '-' + this.oCase.NSP_Detail__c];
        this.clearIfNotPresent(versionValues,"NSP_Version__c");
        this.versionOptions = this.createOptions(versionValues);
        this.showingAllSubCategories = true; 
        if (this.categorySubCategoryMap.has(this.oCase.NSP_Category__c)){
           this.showingResetSubCategories = false;
        }else{
            getRelatedSubCategory({selectedCategory: this.oCase.NSP_Category__c, recordTypeId: this.recordTypeId,
                                    isviewAllSubCat : this.showingResetSubCategories}).then((response) => {
                this.subCategoryOptions = this.createOptions(response);
            }).catch((error) => {
                
            })           
        }
    }

    handleSubCategoryChange(event){
        let subcategory = event.detail.value;
        this.oCase.NSP_SubCategory__c = subcategory;
        let detailValues = this.categoryWrapper.mCatSubToDetails[this.oCase.NSP_Category__c + '-' + subcategory]
        this.clearIfNotPresent(detailValues,"NSP_Detail__c");
        this.detailOptions = this.createOptions(detailValues);
        let versionValues = this.categoryWrapper.mCatSubDetailToVersions[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c + '-' + this.oCase.NSP_Detail__c];
        this.clearIfNotPresent(versionValues,"NSP_Version__c");
        this.versionOptions = this.createOptions(versionValues);
            getRelatedDetail({selectedSubCategory: this.oCase.NSP_SubCategory__c,selectedCategory : this.oCase.NSP_Category__c, recordTypeId: this.recordTypeId}).then((response) => {
                this.detailOptions = this.createOptions(response);
            }).catch((error) => {
            })
    }

    handleDetailChange(event){
        let detail = event.detail.value;
        this.oCase.NSP_Detail__c = detail;
        let versionValues = this.categoryWrapper.mCatSubDetailToVersions[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c + '-' + detail];
        this.clearIfNotPresent(versionValues,"NSP_Version__c");
        this.versionOptions = this.createOptions(versionValues);
            getRelatedVersion({selectedDetail: this.oCase.NSP_Detail__c, recordTypeId: this.recordTypeId}).then((response) => {
                this.versionOptions = this.createOptions(response);
            }).catch((error) => {
                //DO Errro AND SHOW ERROR
            })
    }

    handleVersionChange(event){
        this.oCase.NSP_Version__c = event.detail.value;
    }

    showAllCategories(){
        this.showingAllCategories = true;
        this.showingResetSubCategories = false
        this.showingAllSubCategories = false;
        this.getCatDependenciesMap();
    }
    resetCategories(){
        
        this.showingAllCategories = false;
        this.showingResetSubCategories = false
        this.showingAllSubCategories = false;
        this.getCatDependenciesMap();
    }

    showAllSubCategories(){
        this.showingResetSubCategories = true;
        this.showingAllSubCategories = false;
        this.oCase.NSP_Detail__c = null;
        this.oCase.NSP_Version__c = null;
        this.detailOptions = [];
        this.versionOptions = [];
        getRelatedSubCategory({selectedCategory: this.oCase.NSP_Category__c, recordTypeId: this.recordTypeId,
                                isviewAllSubCat : this.showingResetSubCategories}).then((response) => {
            if(this.isNonAdminProfile){
                response = response.filter(value => value !== "Separation Agreement Request");
            }
            this.subCategoryOptions = this.createOptions(response);
        }).catch((error) => {
            
        })
    }
    resetSubCategories(){
        this.showingAllSubCategories = true;
        this.showingResetSubCategories = false;
        this.oCase.NSP_Detail__c = null;
        this.oCase.NSP_Version__c = null;
        this.detailOptions = [];
        this.versionOptions = [];
        this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.oCase.NSP_Category__c]);
    }

    updateCase(){

        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[CATEGORY_FIELD.fieldApiName] = this.oCase.NSP_Category__c;
        fields[SUBCATEGORY_FIELD.fieldApiName] = this.oCase.NSP_SubCategory__c;
        fields[DETAIL_FIELD.fieldApiName] = this.oCase.NSP_Detail__c;
        fields[VERSION_FIELD.fieldApiName] = this.oCase.NSP_Version__c;
        const recordInput = {fields};

        this.isLoading = true;
        updateRecord(recordInput)
                .then(() => {
                    this.explicitSpinner = true;
                    this.view = true;
                })
                .catch(error => {
                    this.isLoading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'An error occured while trying to update the record. Please try again.',
                            message: error.body.output.errors[0].message, 
                            variant: 'error'
                        })
                    );
                });
    }

    cancel(){
        refreshApex(this.caseDetails); 
        this.handleReloadOfCase(this.caseDetails);          
        this.explicitSpinner = true;
        this.view = true;
    }

    handleReloadOfCase(caseDetails){
        const { data } = caseDetails;
        if(data){
            let oCase = {
                'NSP_Category__c' : data.fields.NSP_Category__c.value,
                'NSP_SubCategory__c' : data.fields.NSP_SubCategory__c.value,
                'NSP_Detail__c' : data.fields.NSP_Detail__c.value,
                'NSP_Version__c' : data.fields.NSP_Version__c.value,
                'RecordTypeId' : data.fields.RecordTypeId.value,                 
            }
            this.oCase = oCase;
            this.recordTypeId = this.oCase.RecordTypeId;
        }
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
    createOptions(lValues){
        lValues = lValues || [];
        return lValues.map( (row) => {
            return { label : row , value : row }
        });
    }

    //GETTER
    get showCaseVersion(){
        return (this.oCase.NSP_Version__c || this.versionOptions.length > 0) ? true : false ;
    }

    //Show view all
    get showViewAll(){        
        return (this.isBPSUser == false && this.showingAllCategories == false) ? true : false;
    }

    get showCaseDetail(){
        return (this.oCase.NSP_Detail__c || this.detailOptions.length > 0 || this.oCase.NSP_Category__c == 'Service Operations') ? true : false ;
    }
}