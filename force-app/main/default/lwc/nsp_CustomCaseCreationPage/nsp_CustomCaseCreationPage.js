import { LightningElement, api, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import hasPermission from '@salesforce/customPermission/NSP_DisplayTypeScreenOnCase';
import getCategoryList from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryList';
import getAllCategoryList from '@salesforce/apex/NSP_CustomCaseCreationPageController.getAllCategoryList';
import getFieldSetFieldsBySobject from '@salesforce/apex/NSP_Utilities.getAllFieldSetFieldsBySObjectName';
import getContactParent from '@salesforce/apex/NSP_CustomCaseCreationPageController.getContactParent';
import getAssetParent from '@salesforce/apex/NSP_CustomCaseCreationPageController.getAssetParent';
import getCaseFromConfig from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCaseFromConfig';
import saveFiles from '@salesforce/apex/NSP_CustomCaseCreationPageController.saveFiles';
import getCategoryDependenciesMap from '@salesforce/apex/NSP_CustomCaseCreationPageController.getCategoryDependenciesMap';
import getRelatedSubCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedSubCategory';
import getRelatedDetail from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedDetail';
import getRelatedVersion from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedVersion';
import getRelatedCategory from '@salesforce/apex/NSP_CustomCaseCreationPageController.getRelatedCategory';
import autoPopulateAsset from '@salesforce/apex/NSP_CustomCaseCreationPageController.autoPopulateAsset';
import isContactHasMultipleACRs from '@salesforce/apex/NSP_CustomCaseCreationPageController.isContactHasMultipleACRs';
import multipleAccountsAssociatedWithContact from "@salesforce/label/c.NSP_MultipleAccountsAssociatedWithContact";
import getProfileName from '@salesforce/apex/NSP_CustomCaseCreationPageController.getProfileName';
import isMemberOfPrivateSection125Visibility from '@salesforce/apex/NSP_CustomCaseCreationPageController.isMemberOfPrivateSection125Visibility';
import getMapOfObjectNameAndKeyPrefix from '@salesforce/apex/NSP_CustomCaseCreationPageController.getMapOfObjectNameAndKeyPrefix';
import recordAccessErrorMessage from "@salesforce/label/c.NSP_RecordAccessErrorMessage";
import caseCreationAndTransferring from "@salesforce/label/c.NSP_Case_Creation_and_Transferring";
import bpsTemplate from './nsp_CustomCaseCreationPageBPSUser.html';
import defaultTemplate from './nsp_CustomCaseCreationPage.html';
import retTemplate from './nsp_CustomCaseCreationPageRETUser.html';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import CASE_OBJ from "@salesforce/schema/Case";
import PARENTCASE_ACCOUNTID from '@salesforce/schema/Case.AccountId';
const ACCOUNTFIELDS = [
    'Account.Name',
    'Account.NSP_AIMS_Client__c'
];

export default class Nsp_CustomCaseCreationPage extends NavigationMixin(LightningElement) {
    get isCustomPermissionEnabled() {
        return hasPermission;
    }

    label = {
        typeHeader: 'Select Type',
        typeButton: 'Next',
        previous: "Previous",
        multipleAccountsAssociatedWithContact : multipleAccountsAssociatedWithContact
    }

    @api objectApiName = 'Case';
    @api parentId = '';
    @api retParentId = '';
    @api recordId;
    popUpWindow = false;
    pageNumber = 1;
    @api isMultipleContacts = false;
    @api isMultipleContactsSelected = false;
    @api isMultipleACRs;

    hasBPSAccess = false;
    showCaseType = false;
    showCaseForm = false;
    oCase = {};
    //Added By Sruthi - start
    @track isBPSUser = false;
    @track showAllCategory = false;
    @track showAllSubCategory = false;
    @track showAllSubCategoryButton = false;
    @track showFilterSubCategoryButton = false;
    filesUploaded = [];
    @track attachmentFilesName = [];
    @track fileNames = '';
    @track value = ''; 
    @track chosenValue = '';
    @track selectedRecTypeId='';
    selectedType = '';
    categoryOptions= [];
    subCategoryOptions= [];
    detailOptions= [];
    versionOptions= [];
    categoryWrapper = {};
    showDetail = false;
    showVersion = false;
    selectedVersion;
    showAllDetail = false;
    allCategoryWrapper = {};
    selectedAllRecordTypeMap = new Map();
    //added By sruthi - end
    categorySubCategoryConfidentialMap = new Map();
    categorySubCategoryDetailConfidentialMap = new Map();
    categorySubCategoryDetailMap = new Map();

    @wire(CurrentPageReference)
    pageRef;

    enableWedgeClaim = false;
    disableButton = false;
    elementSize = 6;
    selectedCategory;
    selectedSubCategory;
    selectedDetail;
    accountID = '';
    contactID = '';
    @track assetId = '';
    projectId = '';
    caseParentId = '';
    caseIssueId = '';
    fieldSetMap = new Map();
    recordTypeCategoryMap = new Map();
    categorySubCategoryMap = new Map();
    categoryConfidentialMap = new Map();
    categoryDetailMap = new Map();
    categoryArray = false;
    detailArray = false;
    subCategoryArray = false;
    open = false;
    error;
    caseFields;
    wageClaimInfoFields;
    wageClaimInfoLabel;
    wageCliantInfoFields;
    wageCliantInfoLabel;
    wageEmployeeInfoFields;
    wageEmployeeInfoLabel;
    wageConfrenceInfoFields;
    wageConfrenceInfoLabel;
    wageAmountPaidByNSPFields;
    wageAmountPaidByNSPLabel;
    wageAmountPaidByClientFields;
    wageAmountPaidByClientLabel;
    wageAmountSavedFields;
    wageAmountSavedLabel;
    recordTypeID;
    recordTypeMap = new Map();
    enableBPSFields = false;
    enableDOLAudits = false;
    confidential = false;
    /* Added as part of STY-03083*/
    peoCaseFields;
    selectedRecordTypeName = '';
    profileName = '' ;
    selectedOwnerId = Id;
    noteButtonClicked = false;
    serviveProfiles = ['PEO Service', 'Retirement Services', 'Contact Center'];
    /* Added as part of STY-03083*/
    isMemberOfPrivateSection125Visibility = false;
    caseCreationAndTransferring = caseCreationAndTransferring;
    recordAccessErrorMessage = recordAccessErrorMessage ; 
    submitted = false;  
    errorMessageToDisplay = '';
    showError = false;
    edID = '';
    planID = '';
    subplanID = '';
    disableEd;
    disablePlan;
    disableSubPlan;
    getAllInputFields = [];
    objectNameKeyPrefixMap = new Map();
    fieldValueMap = {};

    @wire(getObjectInfo, { objectApiName: CASE_OBJ })
    wireObjectInfo(result) {
        if (result.data) {
            if (result.data.recordTypeInfos) {
                this.selectedRecTypeId = this.pageRef.state.recordTypeId != undefined ? this.pageRef.state.recordTypeId : result.data.defaultRecordTypeId;
                this.getCatDependenciesMap();
                if( this.selectedRecTypeId){
                    const rtis = result.data.recordTypeInfos;
                    this.recordTypeMap = new Map();
                    const selectedRT = Object.values(rtis).find(rt=> rt.recordTypeId === this.selectedRecTypeId);
                    this.selectedRecordTypeName = selectedRT.name;
                    if(selectedRT.name === 'BPS' && this.isCustomPermissionEnabled === true){
                        this.hasBPSAccess = true;
                        this.showCaseType = true;
                    }
                    else{
                        this.showCaseForm = true;
                        this.hasBPSAccess = false;
                        this.showCaseType = false;
                    
                    } 
                }
                else{
                    this.showCaseForm = true;
                    this.hasBPSAccess = false;
                    this.showCaseType = false;
                    this.selectedRecTypeId='';
                }
            }
        }else if (result.error) {
            this.error = result.error;
        }
    }

    @wire(getRecord, { recordId: '$accountID', fields: ACCOUNTFIELDS })
    getAccountDetails({error, data}){
        if(data){
            let acccountName = data.fields.Name.value;
            let clientNumber = data.fields.NSP_AIMS_Client__c.value;
            if(this.oCaseConfig){
                let subject = this.oCaseConfig.NSP_Subject__c || '';
                let userNotes = this.oCaseConfig.NSP_User_Notes__c || '';
                this.oCase.Subject = subject.replace('<NAME>',acccountName).replace('<CLIENTNUMBER>',clientNumber);
                this.oCase.NSP_User_Notes__c = userNotes.replace('<NAME>',acccountName).replace('<CLIENTNUMBER>',clientNumber);

                this.caseFields = this.caseFields.map(obj => {
                    let tempObj = { ...obj };
                    if (tempObj.apiName == 'Subject') {
                        tempObj.value = this.oCase.Subject;
                    }
                    return tempObj;
                });

                this.bpsFields = this.bpsFields.map(obj => {
                    let tempObj = { ...obj };
                    if (tempObj.apiName == 'NSP_User_Notes__c') {
                        tempObj.value = this.oCase.NSP_User_Notes__c;
                    }
                    return tempObj;
                });
            }
        }else if(error){
            this.error = error;
        }
    }
    get showTypeField(){
        return (this.showCaseType && this.hasBPSAccess);
    }
    handleTypeChange(event) {
        let type = this.template.querySelector('.caseType').value;
        if(type){
            this.getCaseValues(type);
        }else{
            this.showCaseForm = true;
            this.showCaseType = false;
        }
        
    }
    getCaseValues(type){
        getCaseFromConfig({
            type: type,
            accountId: this.accountID
        }).then(result => {
            if (result.status) {
                let caseWrapper = JSON.parse(result.data);
                this.oCase = caseWrapper.oCase
                this.oCaseConfig = caseWrapper.oCaseConfig;
                this.selectedCategory = this.oCase.NSP_Category__c;
                this.selectedSubCategory = this.oCase.NSP_SubCategory__c;
                this.selectedDetail = this.oCase.NSP_Detail__c;
                this.selectedVersion = this.oCase.NSP_Version__c;
                if(this.selectedSubCategory && this.selectedDetail ){   
                    this.showDetail = true;
                }
                
                this.ownerId = this.oCase.OwnerId;
                this.selectedOwnerId = this.oCase.OwnerId != undefined ? this.oCase.OwnerId : this.selectedOwnerId;
                this.getCatDependenciesMap();
                this.fieldValueMap = {}; // Reset object
                this.caseFields = this.caseFields.map(obj => {
                    let tempObj = { ...obj };
                    if (tempObj.apiName in this.oCase) {
                        tempObj.value = this.oCase[tempObj.apiName];
                        this.fieldValueMap[tempObj.apiName] = tempObj.value;
                    }
                    return tempObj;
                });
                let bpsFields = this.fieldSetMap.get('nsp_bps_fields');
                this.bpsFields = bpsFields.map(obj => {
                    let tempObj = { ...obj };
                    if (tempObj.apiName in this.oCase) {
                        tempObj.value = this.oCase[tempObj.apiName];
                        this.fieldValueMap[tempObj.apiName] = tempObj.value;
                    }
                    return tempObj;
                });

                this.populateSubCategory(null);
                this.populateDetailValues(null);
                this.showCaseForm = true;
                this.showCaseType = false;
                this.enableBPSFields = true;
            } else {
                this.showToast('error', response.errorMessage);
            }

        }).catch(error => {
            this.showToast('error', error.body.message);
        });
    }

    autoPopulateFieldValue() {
        if(this.caseFields){
        this.caseFields = this.caseFields.map(obj => {
            let tempObj = { ...obj };
            tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID : '';
            return tempObj;
        });
    }
    }
    handleCaseFieldChange(event){
        let eField = event.target.fieldName;
        if(eField === 'AccountId'){
            this.accountID = event.target.value;
            if(this.accountID && this.accountID.length>0)
            {
                //auto populate asset based on the  sub cat value change for the case
                this.handlePopulateAsset(event);
        }
        }        
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
            let assetLookupEle = this.template.querySelector('c-nsp_case-custom-look-up[data-id="assetLookup"]');
            if(assetLookupEle){
                assetLookupEle.getDefaultRecord(this.assetId, 'Asset', '');
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

    contactParent(parentId) {
        getContactParent({ idParent: parentId })
            .then((result) => {
                if (result[0].AccountId != undefined && result[0].AccountId != null) {
                    this.accountID = result[0].AccountId;
                }
                this.error = undefined;
                this.autoPopulateFieldValue();

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
    assetParent( parentId ) {
        getAssetParent({ idParent : parentId })
            .then((result) => {
                if(result[0].AccountId != undefined && result[0].AccountId != null){
                    this.accountID =  result[0].AccountId  ;

                }
                if(result[0].NSP_RET_Education__c != undefined && result[0].NSP_RET_Education__c != null){
                    this.edID =  result[0].NSP_RET_Education__c  ;
                    this.disableEd = true;
                }

                this.error = undefined;
                this.autoPopulateFieldValue();
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
    connectedCallback() {
       this.getMapOfObjectNameAndKeyPrefix();
        this.handleProfileName();
        this.handlePrivateCheckbox();

        window.addEventListener("popstate", () => {
            eval("$A.get('e.force:refreshView').fire();");
            this.accountID = '';
            this.parentId = '';

        });

        window.onpopstate = (ev) => {
            // get the state for the history entry the user is going to be on
            const state = ev.state
            if (state && state.pageNumber) {
                this.pageNumber = state.pageNumber;
            }
        };

    }

    getMapOfObjectNameAndKeyPrefix(){
        getMapOfObjectNameAndKeyPrefix().
        then((result) => {
            this.objectNameKeyPrefixMap = result;            
            if (this.parentId != null && this.parentId != undefined) {                                               
                if (this.parentId.substring(0, 3) == result.accountID) {
                    this.accountID = this.parentId;
                } else if (this.parentId.substring(0, 3) == result.contactID) {
                    this.contactID = this.parentId;
                    this.handleMultipleACRs(this.contactID);
                    this.contactParent(this.parentId);
                } else if (this.parentId.substring(0, 3) == result.assetId) {
                    this.assetId = this.parentId;
                    this.assetParent(this.parentId);
                } else if (this.parentId.substring(0, 3) == result.projectId) {
                    this.projectId = this.parentId;
                }else if(this.parentId.substring(0, 3) == result.caseParentId){
                    this.caseParentId = this.parentId;
                }else if(this.parentId.substring(0, 3) == result.caseIssueId){
                    this.caseIssueId = this.parentId; 
                }else if(this.parentId.substring(0, 3) == result.planID){
                    this.planID = this.parentId; 
                    this.disablePlan = true; 
                } else if(this.parentId.substring(0, 3) == result.subplanID){
                    this.subplanID = this.parentId; 
                    this.disableSubPlan = true; 
                }                    
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

    // Added as part of DF-03856 to populate the account Id, if the child case is created from the parent Case
    @wire(getRecord , { recordId : '$caseParentId', fields: [PARENTCASE_ACCOUNTID] })
    getParentCaseFields(value){
        const { error, data} = value;
        if(data){
            this.accountID = data.fields.AccountId.value;
            let accountLookupEle = this.template.querySelector('c-nsp_case-custom-look-up[data-id="accountLookup"]');
            if(accountLookupEle){
                accountLookupEle.getDefaultRecord(this.accountID, 'Account', '');
            }             
        }else if(error){
            this.data = null;
            this.error = error;
        }
    }

    @wire(getFieldSetFieldsBySobject, { objectApiName: '$objectApiName' })
    wiredFieldsToFetchSobject(result) {
        if (result.data) {
            this.error = undefined;
            this.fieldSetMap = new Map(Object.entries(result.data));
            let casefirstFields = this.fieldSetMap.get('nsp_accountcontactasset');
            if (casefirstFields != null && casefirstFields.length > 1) {
                this.firstFieldUpdateSection(casefirstFields);
            }
        } else if (result.error) {
            this.error = result.error;
        }
    }

    firstFieldUpdateSection(fieldSet) {
        this.caseFields = fieldSet.map(obj => {
            let tempObj = { ...obj };
            tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID  :
                tempObj.apiName == "NSP_Case_Sub_Status__c" ? 'Unassigned' : null;
            return tempObj;
        });
    }

    loadWageClaimFieldset() {
        let claimInfo = this.fieldSetMap.get('nsp_wageclaiminfo');
        if (claimInfo != null && claimInfo.length > 1) {
            this.wageClaimInfoFields = claimInfo.map(obj => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID : null ;
                return tempObj;
            });

            this.wageClaimInfoLabel = this.wageClaimInfoFields[0].fieldSetName;
        }
        let claintInfo = this.fieldSetMap.get('nsp_wageclientinfo');
        if (claintInfo != null && claintInfo.length > 1) {
            this.wageCliantInfoFields = claintInfo.map(obj => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID : null;
                return tempObj;
            });

            this.wageCliantInfoLabel = this.wageCliantInfoFields[0].fieldSetName;
        }

        let employeeInfo = this.fieldSetMap.get('nsp_wageemployeeinfo');
        if (employeeInfo != null && employeeInfo.length > 1) {
            this.wageEmployeeInfoFields = employeeInfo.map(obj => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID : null;
                return tempObj;
            });
            this.wageEmployeeInfoLabel = this.wageEmployeeInfoFields[0].fieldSetName;
        }

        let confrenceInfo = this.fieldSetMap.get('nsp_wageconferenceinfo');
        if (confrenceInfo != null && confrenceInfo.length > 1) {
            this.wageConfrenceInfoFields = confrenceInfo.map(obj => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID : null;
                return tempObj;
            });
            this.wageConfrenceInfoLabel = this.wageConfrenceInfoFields[0].fieldSetName;
        }

        let amountPaidByNSP = this.fieldSetMap.get('nsp_wageamountspaidbyinsperity');
        if (amountPaidByNSP != null && amountPaidByNSP.length > 1) {
            this.wageAmountPaidByNSPFields = amountPaidByNSP.map(obj => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID : null;
                return tempObj;
            });
            this.wageAmountPaidByNSPLabel = this.wageAmountPaidByNSPFields[0].fieldSetName;
        }

        let amountPaidByClient = this.fieldSetMap.get('nsp_wageamountspaidbyclient');
        if (amountPaidByClient != null && amountPaidByClient.length > 1) {
            this.wageAmountPaidByClientFields = amountPaidByClient.map(obj => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID :null;
                return tempObj;
            });
            this.wageAmountPaidByClientLabel = this.wageAmountPaidByClientFields[0].fieldSetName;
        }

        let amountSaved = this.fieldSetMap.get('nsp_wageamountssaved');
        if (amountSaved != null && amountSaved.length > 1) {
            this.wageAmountSavedFields = amountSaved.map(obj => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID :  null;
                return tempObj;
            });
            this.wageAmountSavedLabel = this.wageAmountSavedFields[0].fieldSetName;
        }
        this.enableWedgeClaim = true;
    }


    get dolAuditsFieldset() {
        let claimInfo = this.fieldSetMap.get('nsp_dolaudits');
        if (claimInfo != null && claimInfo.length > 1) {
            this.wageClaimInfoFields = claimInfo.map(obj => {
                let tempObj = { ...obj };
                tempObj.value = tempObj.apiName == "AccountId" ? this.accountID : tempObj.apiName == "ContactId" ? this.contactID : null;
                return tempObj;
            });
            return claimInfo;
        }
    }

    @wire(getAllCategoryList, {recordTypeId: '$selectedRecTypeId'})
    wiredgetAllCategoryList(result){
        if (result.data) {
            this.selectedAllRecordTypeMap = new Map();

            result.data.forEach(element => {
                if(!this.selectedAllRecordTypeMap.has(element.NSP_Category__c)){
                    this.selectedAllRecordTypeMap.set(element.NSP_Category__c, this.recordTypeMap.get(element.NSP_RecordType__c));
                } 
                if(element.NSP_UserTitle__c == 'BPS User'){
                    this.isBPSUser = true;
                }else{
                    this.isBPSUser = false;
                }
            });   
        }
    }

    @wire(getCategoryList, {recordTypeId: '$selectedRecTypeId', isCatViewAll : '$showAllCategory'})
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
                let categorySubCategoryKey = element.NSP_Category__c + '-' + element.NSP_Subcategory__c;
                let categorySubCategoryKeyDetail = element.NSP_Category__c + '-' + element.NSP_Subcategory__c + '-' + element.NSP_Detail__c;
                if (!this.recordTypeCategoryMap.has(categorySubCategoryKey)) {
                    this.recordTypeCategoryMap.set(categorySubCategoryKey, this.recordTypeMap.get(element.NSP_RecordType__c));
                }
                if (!this.categorySubCategoryMap.has(element.NSP_Category__c)) {
                    this.categorySubCategoryMap.set(element.NSP_Category__c, new Array());
                } this.categorySubCategoryMap.get(element.NSP_Category__c).push(element.NSP_Subcategory__c);
                if (!this.categoryConfidentialMap.has(element.NSP_Category__c)) {
                    this.categoryConfidentialMap.set(element.NSP_Category__c, new Array());
                } this.categoryConfidentialMap.get(element.NSP_Category__c).push(element.NSP_Display_confidential_popup__c);

                if (!this.categoryDetailMap.has(categorySubCategoryKey)) {
                    this.categoryDetailMap.set(categorySubCategoryKey, new Array());
                    this.categorySubCategoryConfidentialMap.set(categorySubCategoryKey, new Array());
                    
                    
                } this.categoryDetailMap.get(categorySubCategoryKey).push(element.NSP_Detail__c);
                this.categorySubCategoryConfidentialMap.get(categorySubCategoryKey).push(element.NSP_Display_confidential_popup__c);
 
                if (!this.categorySubCategoryDetailMap.has(categorySubCategoryKeyDetail)) {
                    this.categorySubCategoryDetailConfidentialMap.set(categorySubCategoryKeyDetail, new Array());
                } this.categorySubCategoryDetailConfidentialMap.get(categorySubCategoryKeyDetail).push(element.NSP_Display_confidential_popup__c);

            });
            let arrayTemp = Array.from(this.categorySubCategoryMap.keys());
            arrayTemp.forEach(element => {
                this.categoryArray.push({ label: element, value: element });
                this.open = true;
            });
            //Added by sruthi
            
            //this.getAllCatSubDetValues();
            //End

        } else if (result.error) {
            this.error = result.error;
        }
    }

    populateSubCategory(event) {
        this.subCategoryArray = new Array();
        this.detailArray = false;
        if (event) {
            this.selectedDetail = '';
            let eDetail = this.template.querySelector('lightning-combobox[data-fname="detail"]');
            if (eDetail != null && eDetail.value != null) {
                eDetail.value = '';
            }
        }

        let arrayTemp = Array.from(new Set(this.categorySubCategoryMap.get(this.selectedCategory)));
        window.confidentialTemp = this.categoryConfidentialMap.get(this.selectedCategory);
        if(arrayTemp){
            arrayTemp.forEach(element => {
                    this.subCategoryArray.push({ label: element, value: element });
                    this.open = true;
            });
        }
    }
    populateDetailValues(event) {
        this.detailArray = false;
        let eCategory = this.template.querySelector('lightning-combobox[data-fname="category"]');
        if (event) {
            this.selectedDetail = '';
            let eDetail = this.template.querySelector('lightning-combobox[data-fname="detail"]');
            if (eDetail != null && eDetail.value != null) {
                eDetail.value = '';
            }
        }

        if (this.selectedSubCategory == 'Wage Claim') {
            this.enableDOLAudits = false;
            this.loadWageClaimFieldset();
        }
        else if (this.selectedSubCategory == 'DOL Audit') {
            this.enableWedgeClaim = false;
            this.enableDOLAudits = true;
        }
        else {
            this.enableWedgeClaim = false;
            this.enableDOLAudits = false;
        }

        if (this.template.querySelector('lightning-combobox') != null) {
            if (eCategory != null && eCategory.value != null) {
                let categoryValue = eCategory.value;
                if (this.recordTypeCategoryMap.get(categoryValue + '-' + this.selectedSubCategory)) {
                    let recordTypeName = this.recordTypeCategoryMap.get(categoryValue + '-' + this.selectedSubCategory)
                    this.recordTypeID = this.recordTypeMap.get(recordTypeName);
                }

                if (this.categoryDetailMap.get(categoryValue + '-' + this.selectedSubCategory) != null && this.categoryDetailMap.get(categoryValue + '-' + this.selectedSubCategory) != '') {
                    this.detailArray = new Array();
                    let tempArray = this.categoryDetailMap.get(categoryValue + '-' + this.selectedSubCategory);
                    if(tempArray){
                        tempArray.forEach(element => {
                            this.detailArray.push({ label: element, value: element });
                        });
                    }
                }
            }
        }
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
            //this.populateSubCategory();
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
            if(this.selectedCategory.length>0 && this.selectedSubCategory.length>0 && this.accountID.length>0){
                this.handlePopulateAsset(event);
            }
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
        
        if (this.disableButton) this.disableButton = false;
    }


    handleSuccess(event) {
        //Added By Sruthi - start
        this.recordId = event.detail.id;
        this.isMultipleContactsSelected = this.isMultipleContacts;
        saveFiles({filesToInsert: this.filesUploaded, recordId: this.recordId});
        if(this.noteButtonClicked){
           this.handleNotesInsertion(this.recordId);
        }
        this.noteButtonClicked = false;
        //Added By Sruthi - End
        // Close the modal window and display a success toast
        let successMessage = this.isMultipleContacts == true ? 'Case Created Successfully. Please Add Contacts !' : 'Case Created Successfully.';
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: successMessage,
                variant: 'success'
            })
        );
        
      
if(this.isMultipleContactsSelected === false){
    this.resetFormAction(event);
    // Modified as part of DF-03869
    this[NavigationMixin.GenerateUrl]({
        type: 'standard__recordPage',
        attributes: {
            recordId: this.recordId,
            actionName: 'view',
        },
           }).then(url => {window.open(url, '_self')});  
    }
}

    goBacktoTypeScreen(){
        this.clearAllFieldValues();
        this.showCaseType = true;
        this.showCaseForm = false;
    }
    clearAllFieldValues(){
        this.oCase = {};
        this.oCaseConfig = {};
        this.selectedCategory = null;
        this.selectedSubCategory = null;
        this.selectedDetail = null;
        this.selectedVersion = null;
        this.ownerId = null;

        this.caseFields = this.caseFields.map(obj => {
            let tempObj = { ...obj };
            tempObj.value = '';
            return tempObj;
        });

        this.bpsFields = this.bpsFields.map(obj => {
            let tempObj = { ...obj };
            tempObj.value = '';
            return tempObj;
        });
    }
    
    handleNotes(){
        this.noteButtonClicked = true;
    }
    handleCancelNotes(){
        this.noteButtonClicked = false;
    }
    handleNotesInsertion(createdCaseId){
        const notesFields = this.template.querySelectorAll("lightning-input-field");
        notesFields.forEach(field => {
            if (field.fieldName === 'Case__c') {
                field.value = createdCaseId;
            }
        });
        this.template.querySelector('[data-id = "note-record-form"]').submit();
    }
    handleCancel(event) {
        this.resetFormAction(event);
        this.disableButton = true;
        // Added as part of DF-03869 to close the case create tab once the case is created
        var getCreatedRecId = this.recordId;
        const closeConsoleTab = new CustomEvent('closeconsoletab', {
            detail: {getCreatedRecId  },
        });
        this.dispatchEvent(closeConsoleTab);         
        if (this.parentId != null && this.parentId.length > 14) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.parentId,
                    actionName: 'view',
                },
            });

            // Add your cancel button implementation here
        } else {

            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: 'Case',
                    actionName: 'list'
                }
            });
        }

    }

    handleButtonClick() {
        let errorFields = '';
        this.showError = false;
        this.errorMessageToDisplay = '';
        let requiredFields = ['Status', 'Origin','Subject'];
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        
        if(this.selectedRecordTypeName === 'BPS'){
            requiredFields = [...requiredFields, 'Priority'];
            requiredFields = [...requiredFields, 'NSP_Case_Sub_Status__c'];
        }
        inputFields.forEach(field => {
            if(requiredFields.includes(field.fieldName) && field.required && 
            (field.value == '' || field.value == null || field.value == undefined)){
                errorFields += field.title + ',';
            }
        });
        if(errorFields !== ''){
        let errorMessage = ('Please fill required data before submitting : '+errorFields).replace(/,\s*$/, "");
        this.showError = true;
        this.errorMessageToDisplay = errorMessage;
        }        
    }


    handleLoad() {
    }

    handleSaveAndAdd(event){
    this.isMultipleContacts = true;
        this.handleSubmit(event);
    }

    handleSubmit(event) {
        this.showError = false;
        this.errorMessageToDisplay = '';
        event.preventDefault();
        if(!this.submitted){
        let errorFields = '';
        if(this.selectedRecordTypeName !== 'RET Time Tracking' && (this.selectedCategory === undefined || this.selectedCategory === null)){ 
        errorFields += "Category,"
        }
        if(this.selectedRecordTypeName !== 'RET Time Tracking' && (this.selectedSubCategory === undefined || this.selectedSubCategory === null || this.selectedSubCategory === '')){
            errorFields += "Sub Category,"
        }
        if(this.accountID === ''){
            errorFields += "Account,"
        }
        if(this.selectedOwnerId === ''){
            errorFields += "Case Owner,"
        }
        this.getAllInputFields = event.detail.fields;
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        if(errorFields == '' && inputFields){
            if(this.getDisplayConfidentialCheckBox === true){
                inputFields.forEach(field => {
                    if(field.fieldName === 'NSP_Confidential__c'){
                        if ((field.value === true || 
                            ( field.value === false && this.getDisplayConfidentialCheckBox == false)) ){
                            this.popUpWindow = false;
                        } else if (field.value === false && this.getDisplayConfidentialCheckBox == true) {
                            this.popUpWindow = true;
                        }
                    }
                });
                if(this.popUpWindow === false){
                    this.handleinputSubmitFields(this.getAllInputFields, false);
                }
            }else{
                this.handleinputSubmitFields(this.getAllInputFields, false);
            }
            this.disableButton = true;
        }  else{
            let errorMessage = ('Please fill required data before submitting : '+errorFields).replace(/,\s*$/, "");
            this.showError = true;
            this.errorMessageToDisplay = errorMessage;
        }
    }             
    }

    updateCaseWithConfidential(event) {
        this.handleinputSubmitFields(this.getAllInputFields, true);
        this.popUpWindow = false;
    }

    updateCaseWithoutConfidential() {
        this.handleinputSubmitFields(this.getAllInputFields, false);
        this.popUpWindow = false;
    }

    handleinputSubmitFields(inputFields, isConfidential){ 
        inputFields.AccountId = this.accountID;
        inputFields.ContactId = (this.contactID !== '' && this.contactID !== undefined) ? this.contactID : inputFields.ContactId;
        inputFields.OwnerId = (this.selectedOwnerId !== '' && this.selectedOwnerId !== undefined) ? this.selectedOwnerId : inputFields.ownerId;
        inputFields.ParentId = (this.caseParentId !== '' && this.caseParentId !== undefined) ? this.caseParentId : inputFields.ParentId;
        inputFields.NSP_Case_Issue__c =  (this.caseIssueId !== '' && this.caseIssueId !== undefined) ? this.caseIssueId : inputFields.NSP_Case_Issue__c;
        inputFields.AssetId = (this.assetId !== '' && this.assetId !== undefined) ? this.assetId : inputFields.AssetId;
        inputFields.NSP_Confidential__c = isConfidential ? isConfidential : inputFields.NSP_Confidential__c;    
        inputFields.NSP_Show_Confidential_Checkbox__c = this.getDisplayConfidentialCheckBox;
        var RET_CONSTANTS = this.objectNameKeyPrefixMap;
        if(this.selectedRecordTypeName === 'RET Time Tracking' && this.parentId !== '' && this.parentId !== undefined){
            this.parentId = this.retParentId !== '' ? this.retParentId : this.parentId; // Added as part of DF-03872
            inputFields.NSP_RET_Amendment_Checklist__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Amendment_Checklist__c ) ? this.parentId : '';   
            inputFields.NSP_RET_Sales_to_Implementation__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Sales_to_Implementation__c ) ? this.parentId : '';   
            inputFields.NSP_RET_Monthly_Participation__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Monthly_Participation__c ) ? this.parentId : '';   
            inputFields.NSP_RET_EOY_Amendments__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_EOY_Amendments__c ) ? this.parentId : '';   
            inputFields.NSP_RET_Compliance__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Compliance__c ) ? this.parentId : '';   
            inputFields.NSP_RET_CGNDQ__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_CGNDQ__c ) ? this.parentId : '';   
            inputFields.NSP_RET_5500_Plan_Tracking__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_5500_Plan_Tracking__c ) ? this.parentId : '';   
            inputFields.NSP_RET_Eligibility__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Eligibility__c ) ? this.parentId : '';   
            inputFields.NSP_RET_Deconversion__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Deconversion__c ) ? this.parentId : '';   
            inputFields.NSP_RET_Contribution__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Contribution__c ) ? this.parentId : '';   
            inputFields.NSP_RET_Client_Sub_Plan_History__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Client_Sub_Plan_History__c ) ? this.parentId : '';   
            inputFields.NSP_RET_Client_Change__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Client_Change__c ) ? this.parentId : '';   
            inputFields.NSP_RET_Sub_Plan_Change_History__c =( this.parentId.substring(0, 3) == RET_CONSTANTS.NSP_RET_Sub_Plan_Change_History__c ) ? this.parentId : '';           
        }
            this.template.querySelector('[data-id = "case-record-form"]').submit(inputFields);
            this.submitted = true;
        }
    

    get pageRefString() {
        return JSON.stringify(this.pageRef);
    }


    resetFormAction(event) {
        const lwcInputFields = this.template.querySelectorAll(
            'lightning-input-field'
        );
        if (lwcInputFields) {
            lwcInputFields.forEach(field => {
                field.reset();
            });
        }

        const comboBoxFields = this.template.querySelectorAll(
            'lightning-combobox'
        );

        if (comboBoxFields) {
            comboBoxFields.forEach(field => {
                field.value = "";
            });
        }
    }

    handleError(event) {
        let errorMessage = event.detail.detail;
        this.showError = true;
        this.errorMessageToDisplay = errorMessage;
        if(errorMessage.includes(this.recordAccessErrorMessage)){
            this.navigateToRecentListView();
            this.showToastMessage('', this.caseCreationAndTransferring, 'warning');
        }
        if (this.disableButton) this.disableButton = false;
        this.submitted = false;
    }

    //Added By Sruthi - start
    openfileUpload(event) {
        if(event.target.files.length > 0) {
            let fileSize = event.target.files.length;
            
            for(let i=0; i<fileSize; i++){
                let filesName = '';
                let file = event.target.files[i];
                filesName = filesName + file.name;
                let freader = new FileReader();
                this.attachmentFilesName.push(filesName);
                freader.onload = f => {
                    let base64 = 'base64,';
                    let content = freader.result.indexOf(base64) + base64.length;
                    let fileContents = freader.result.substring(content);
                    this.filesUploaded.push({
                        Title: filesName,
                        FileContent: fileContents,
                        FileType: file.type
                    });
                };
                freader.readAsDataURL(file);
            }  
        }
    }
    //Added By Sruthi - end

    //Added by Sruthi - start
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
        //updated by rahul for bug 210402
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
            if(this.selectedCategory.length>0 && this.selectedSubCategory.length>0 && this.accountID.length>0){
                this.handlePopulateAsset(event);
            }
        }
        if (event.currentTarget.name == 'Detail') {
            this.selectedDetail = event.target.value;
            this.getFiteredVersionValues();
        }
        if (event.currentTarget.name == 'Version') {
            this.selectedVersion = event.detail.value;
        }
    }
    handleCategoryViewAll(event){
        this.showAllCategory = true;
        this.showAllSubCategory = true;
        this.showAllSubCategoryButton = false;
        this.showFilterSubCategoryButton = false;
        this.getAllCatSubDetValues();
        this.getFiteredSubCatValues();        
        this.getCatDependenciesMap(); //updated as part of DF-03430     
    }

    handleSubCategoryViewAll(event){
        this.showAllSubCategory = true;
        this.showFilterSubCategoryButton = true;
        this.showAllSubCategoryButton = false;
        this.getFiteredSubCatValues();
    }

    handleSubCategoryFiltered(event){
        this.showAllSubCategory = false;
        this.showAllSubCategoryButton = true;
        this.showFilterSubCategoryButton = false;
        this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.selectedCategory]);
    }
    handleCategoryFilteredView(event){
        
        
        this.showAllCategory = false;
        this.showAllSubCategory = true;
        this.subCategoryOptions = this.createOptions(this.categoryWrapper.mCatToSubCatogories[this.selectedCategory]);
    }

    handlelookupRecord(event){
        let selectedRecord = event.detail.recId;
        let objectApiName = event.detail.sObjectApiName;
        if(objectApiName === 'Account'){
            this.accountID = selectedRecord != '' ? selectedRecord : '';
            if(this.selectedRecordTypeName !== 'RET Time Tracking'){
                this.handlePopulateAsset(event);
                }
        }else if(objectApiName === 'Asset'){
            this.assetId = selectedRecord != '' ? selectedRecord : '';
        }else if(objectApiName === 'Contact'){
            this.contactID = selectedRecord != '' ? selectedRecord : '';
            this.retParentId = this.parentId;
            this.parentId = this.contactID;
            if(this.contactID){
            this.handleMultipleACRs(this.contactID);
            }else{
                this.isMultipleACRs = false;
            }
        } else {
            this.selectedOwnerId = selectedRecord != '' ? selectedRecord : ''; 
        }                
  }

  handleMultipleACRs(contId){
    isContactHasMultipleACRs({
        contId:contId}).
    then((result) => {
        if (result) {
            this.isMultipleACRs = result;
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

  handlePrivateCheckbox(){
    isMemberOfPrivateSection125Visibility().
    then((result) => {
        if (result) {
            this.isMemberOfPrivateSection125Visibility = result;
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

  showToastMessage(title, message, variant){
    const evt = new ShowToastEvent({
        title: title,
        message: message,
        variant: variant,
        mode: 'dismissable'
    });
    this.dispatchEvent(evt);
  }

  navigateToRecentListView(){
    this[NavigationMixin.Navigate]({
        type: 'standard__objectPage',
        attributes: {
            objectApiName: 'Case',
            actionName: 'list'
        },
        state: {       
            filterName: 'Recent' 
        }
    });
  }

    getCatDependenciesMap(){
        getCategoryDependenciesMap({recordTypeId: this.selectedRecTypeId, isCatViewAll : this.showAllCategory}).then((response) => {
            let result = JSON.parse(response);
            this.categoryOptions = this.createOptions(Object.keys(result.mCatToSubCatogories).sort());
            let isSystemAdmin = ( this.profileName && this.profileName.startsWith( 'System Admin' ) );
            if ( !isSystemAdmin && ( result.mCatToSubCatogories["HR Employee Relations"] != null ) ) {
                result.mCatToSubCatogories["HR Employee Relations"] = result.mCatToSubCatogories["HR Employee Relations"].filter(value => value !== "Separation Agreement Request");
            }
            this.subCategoryOptions = this.createOptions(result.mCatToSubCatogories[this.oCase.NSP_Category__c]);
            this.detailOptions = this.createOptions(result.mCatSubToDetails[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c]);
            this.versionOptions = this.createOptions(result.mCatSubDetailToVersions[this.oCase.NSP_Category__c + '-' + this.oCase.NSP_SubCategory__c + '-' + this.oCase.NSP_Detail__c]);
            this.categoryWrapper = result;
        }).catch((error) => {
        })
    }
    getAllCatSubDetValues(){
        let role = 'BPS User';
        getRelatedCategory({selectedRole: role,recordTypeId: this.selectedRecTypeId }).then((response) => {
            this.categoryOptions = this.createOptions(response);
        }).catch((error) => {
        })
    }
    
    getFiteredSubCatValues(){
        this.subCategoryOptions = [];
        getRelatedSubCategory({selectedCategory: this.selectedCategory, recordTypeId: this.selectedRecTypeId, isviewAllSubCat: this.showAllSubCategory}).then((response) => {
            let isSystemAdmin = ( this.profileName && this.profileName.startsWith( 'System Admin' ) );
            if ( !isSystemAdmin ) {
                response = response.filter(value => value !== "Separation Agreement Request");
            }
            this.subCategoryOptions = this.createOptions(response);
        }).catch((error) => {
            
        })
    }
    /*Commented as part of 210402
    getFiteredDetailValues(){
        getRelatedDetail({selectedSubCategory: this.selectedSubCategory, recordTypeId: this.selectedRecTypeId}).then((response) => {
            this.detailOptions = this.createOptions(response);
            if(this.detailOptions.length > 0){
                this.showAllDetail = true;
                this.showDetail = fasle;
            }else{
                this.showAllDetail = false;
                this.showDetail = false;
            }
        }).catch((error) => {
            
        })
    }*/

    getFiteredVersionValues(){
        getRelatedVersion({selectedDetail: this.selectedDetail, recordTypeId: this.selectedRecTypeId}).then((response) => {
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

    createOptions(lValues){
        lValues = lValues || [];
        return lValues.map( (row) => {
            return { label : row , value : row }
        });
    }

   
    //Added by Sruthi - end
    get inputVariables() {
        return [
            {
                name: 'caseRecordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    get getDisplayConfidentialCheckBox(){
        let showConfidentialField = false; 
        if(this.selectedSubCategory != null && this.selectedCategory != null && this.selectedDetail != null){
            let catSubCatDetail = this.selectedCategory + '-' + this.selectedSubCategory + '-' + this.selectedDetail;
            showConfidentialField = this.categorySubCategoryDetailConfidentialMap.get(catSubCatDetail) != null ? this.categorySubCategoryDetailConfidentialMap.get(catSubCatDetail)[0] : false;
    }else if(this.selectedSubCategory != null && this.selectedCategory != null && this.showDetail != true){
        let catSubCategory = this.selectedCategory + '-' + this.selectedSubCategory;
        showConfidentialField = this.categorySubCategoryConfidentialMap.get(catSubCategory) != null ? this.categorySubCategoryConfidentialMap.get(catSubCategory)[0] : false;
    }
    return showConfidentialField;
    }

    get isPEORecordType(){
        let isPEO = false;
         if(this.selectedRecordTypeName === 'PEO' || this.serviveProfiles.includes(this.profileName)){
            isPEO = true;
         }
         return isPEO;
    }

    get showPrivateCheckbox(){
        let showPrivateCheckBox = false;
        if(this.isMemberOfPrivateSection125Visibility && 
            this.selectedCategory === 'H&W Section 125' &&
            (this.selectedRecordTypeName === 'PEO' || this.serviveProfiles.includes(this.profileName))
            ){
                showPrivateCheckBox = true;
        }
        return showPrivateCheckBox;
    }

    render(){
        return ((this.selectedRecordTypeName === 'BPS') ? bpsTemplate : (this.selectedRecordTypeName === 'RET Time Tracking') ? retTemplate : defaultTemplate);
    } 
}