import { LightningElement, wire, api, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord , deleteRecord} from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAccountName from '@salesforce/apex/NSP_ImplementationProfileController.getAccountName';
import getRelatedClients from '@salesforce/apex/NSP_ImplementationProfileController.getRelatedClients';
import saveGeneralForm from '@salesforce/apex/NSP_ImplementationProfileController.saveGeneralDetails';
import IP_CLIENT_RELATED_CLIENT from '@salesforce/schema/NSP_IP_Related_Client__c';
import IS_CLIENT_FROM_ANOTHER_PEO from '@salesforce/schema/Implementation_Profile__c.Is_the_client_coming_from_another_PEO__c';
import CLIENT_IMPLEMENTING_OTHER_BUSINESS from '@salesforce/schema/Implementation_Profile__c.Implementing_biz_Performance_solutions__c';
import TIME_ENTRY_METHOD from '@salesforce/schema/Implementation_Profile__c.Time_Entry_Method__c';
import CLIENT_PROFILE_INFORMATION from '@salesforce/schema/Implementation_Profile__c.Client_Profile_Information__c';
import HUSH_PROTOCOL__C from '@salesforce/schema/Implementation_Profile__c.Hush_Protocol__c';
import WILL_BPA_ATTENDING_SKO from '@salesforce/schema/Implementation_Profile__c.Will_the_BPA_s_Be_attending_the_SKO__c';
import CLIENT_LOGO_BEEN_COLLECTED from '@salesforce/schema/Implementation_Profile__c.NSP_Has_the_client_s_logo_been_collected__c';
import HAS_FEIN_DOCUMENT_COLLECTED from '@salesforce/schema/Implementation_Profile__c.Has_FEIN_documentation_been_collected__c';
import CLIENT_HAVE_MORE_FIEN_COLLECTED from '@salesforce/schema/Implementation_Profile__c.NSP_Does_the_client_more_FEIN__c';
import SUI_TAX_RATE_COLLECTED from '@salesforce/schema/Implementation_Profile__c.SUI_Tax_rate_notice_s_collected__c';
import RECENT_PAYROLL_COLLECTED from '@salesforce/schema/Implementation_Profile__c.Recent_Payroll_Register_Collected__c';
import EMPLOYEE_DATA_COLLECTED from '@salesforce/schema/Implementation_Profile__c.Employee_Data_Collection_EDC_collected__c';
import WILL_OWNER_BE_PAYROLL from '@salesforce/schema/Implementation_Profile__c.Will_the_owner_s_be_on_payroll__c';
import SOLE_PROPRIETORSHIP_FIELD from '@salesforce/schema/Implementation_Profile__c.Sole_Proprietorship_or_partnership__c';
import OWNER_W2_WAGES_FIELD from '@salesforce/schema/Implementation_Profile__c.Owner_aware_they_will_not_get_W2_wages__c';
import CAFETERIA_PLAN_FIELD from '@salesforce/schema/Implementation_Profile__c.Chngs_for_cafeteria_plan_questionnaire__c';
import CLIENT_EEO_FILLING_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_have_EEO_filing_under__c';
import COVERAGE_CERT_GENERAL_LIABILITY_FIELD from '@salesforce/schema/Implementation_Profile__c.Gotten_Cvrg_Cert_Gen_Liability_Auto__c';
//import SELECT_BPS_FIELD from '@salesforce/schema/Implementation_Profile__c.Select_BPSes__c';
import CLIENT_OWNED_ENTITY from '@salesforce/schema/Implementation_Profile__c.Client_entity_owned_or_a_non_profit__c';
import CLIENT_FEIN_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_FEIN__c';
import ALL_EE_PAID_FIELD from '@salesforce/schema/Implementation_Profile__c.All_EEs_paid_under_same_FEIN_currently__c';
import REMOVE_EMP_DIRECTORY_FIELD from '@salesforce/schema/Implementation_Profile__c.remove_employee_directory_from_premier__c';
import * as labels from 'c/nsp_implementationLabels';

export default class Nsp_generalIp extends LightningElement {
    label = labels;
    pickValueYesNo = [
        { "attributes": null, "label": this.label.No, "value": "No" },
        { "attributes": null, "label": this.label.Yes, "value": "Yes" }
    ];

    @api
    recordId;
    @api
    objectApiName;
    ipRelatedClientName = IP_CLIENT_RELATED_CLIENT.objectApiName;;
    @track fields = {};
    @api
    defaultRecordTypeId;
    @api error;
    isLoading = true;
    //RENDERING FIELDS
    showPEOName = false;
    showHowSoonClientLikeSolutionImplemntedfield = false;
    showClientAnyOtherBusinessSolutions = false;
    showListofRelatedClients = false;
    showNationalAccount = false;
    showFEINAdditionalField = false;
    showDeadLineDate = false;
    showClientBusinessTypeSole = false;
    showIsOwnerAwareWages = false;
    showListofChanges = false;
    showClientBusinessTypeNo = false;

    isCAMClient;
    isFormerClientReturning;
    isRelatedClients;
    isNationalAccount;
    isWXClient;
    isWSClient;
    isWOClient;
    showAdditionalFEINField = false;
    showGenLiabilityField = false;
    showSolutionImplementedField = false;

    reloadField = true;
    relatedClientIds = [];
    lRelatedClients = [];
    relatedClientPills= [];

    firstTimeRendered = true;
    // multiSelectFields = ['Select_BPSes__c'];
    lFieldsWithRequestedValues = ['NSP_Has_the_client_s_logo_been_collected__c','Has_FEIN_documentation_been_collected__c','SUI_Tax_rate_notice_s_collected__c',
    'Recent_Payroll_Register_Collected__c','Employee_Data_Collection_EDC_collected__c'];
    renderedCallback(){
        if(this.firstTimeRendered && Object.keys(this.fields).length > 0){
            let allColoredFields = [].concat(this.lFieldsWithRequestedValues);
            for(let field of allColoredFields){
                this.handleRequestedColor(field);
            }
            this.firstTimeRendered = false;
        }
    }

    @wire(getRecord, {
        recordId: '$recordId', fields: [IS_CLIENT_FROM_ANOTHER_PEO, IS_CLIENT_IMPLEMENTING_PERFORMANCE, CLIENT_IMPLEMENTING_OTHER_BUSINESS,
            TIME_ENTRY_METHOD, CLIENT_PROFILE_INFORMATION, HUSH_PROTOCOL__C, WILL_BPA_ATTENDING_SKO, CLIENT_LOGO_BEEN_COLLECTED, HAS_FEIN_DOCUMENT_COLLECTED,CLIENT_HAVE_MORE_FIEN_COLLECTED,
            SOLE_PROPRIETORSHIP_FIELD,OWNER_W2_WAGES_FIELD,CAFETERIA_PLAN_FIELD,CLIENT_EEO_FILLING_FIELD,WILL_OWNER_BE_PAYROLL,EMPLOYEE_DATA_COLLECTED,RECENT_PAYROLL_COLLECTED,
            SUI_TAX_RATE_COLLECTED, COVERAGE_CERT_GENERAL_LIABILITY_FIELD, CLIENT_FEIN_FIELD, ALL_EE_PAID_FIELD, CLIENT_OWNED_ENTITY, REMOVE_EMP_DIRECTORY_FIELD]
    })
    getImplementationProfileDetails(value) {
        this.implementationProfileDetails = value;
        const { data, error } = value;
        if (data) {
            let fields = data.fields;
            let oImpProfileFields = {};
            for(let field in fields){
                oImpProfileFields[field] = fields[field].value;
                this.showDynamicFields(field, fields[field].value);
            }
            this.updateCheckboxFields(oImpProfileFields);
            this.fields = oImpProfileFields;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: TIME_ENTRY_METHOD })
    timeEntryMethod;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_PROFILE_INFORMATION })
    clientProfileInformation;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: WILL_BPA_ATTENDING_SKO })
    willBPABeAttendingSKO;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_LOGO_BEEN_COLLECTED })
    clientLogoBeenCollected;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: HAS_FEIN_DOCUMENT_COLLECTED })
    hasFEINDocumentsCollected;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: SUI_TAX_RATE_COLLECTED })
    hasSUITaxRateCollected;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: RECENT_PAYROLL_COLLECTED })
    recentPayrollCollected;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: EMPLOYEE_DATA_COLLECTED })
    employeeDataCollected;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: WILL_OWNER_BE_PAYROLL })
    willOwnerByPayroll;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: COVERAGE_CERT_GENERAL_LIABILITY_FIELD })
    coverageCertGeneralLiability;
    // @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: SELECT_BPS_FIELD })
    // selectBPSesOptions;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_OWNED_ENTITY })
    clientOwnedEntity;

    handleChange(event) {
        let value = event.detail.value;
        let field = event.target.name;
        this.fields[field] = value;
        this.showDynamicFields(field, value);
        this.handleRequestedColor(field);
    }

    async handleRelatedClients(event){
        try{
            let value = Array.isArray(event.detail.value) ? event.detail.value[0] : event.detail.value;
            if(!this.relatedClientIds.includes(value)){
                this.relatedClientIds.push(value);
                let response = await this.getAccountData(value);
                this.lRelatedClients.push({ 
                    NSP_Related_Client__c : response[0].Id,
                    NSP_Related_Client__r : {
                        Name : response[0].Name
                    },
                    Id : null,
                });
                this.createPills(this.lRelatedClients);
            }
            this.reloadField = false;
            setTimeout( () => this.reloadField = true, 0);
        }catch(error){
            if(error && error.body.message){
                this.error = error;
            }
        }
    }

    getAccountData(value){
        return getAccountName({clientIds : [value]})
    }

    @wire( getRelatedClients, { recordId : '$recordId'})
    getRelatedClientsDetails( { data, error}){
        if(data){
            this.relatedClientIds = data.map( row => row.NSP_Related_Client__r.Id);
            this.lRelatedClients = JSON.parse(JSON.stringify(data));
            this.createPills(data);
        }else if(error){
            this.error = error;
        }
    }

    createPills(lRelatedClients){
        let relatedClientPills = lRelatedClients.map( row => {
            return { 
                label : row.NSP_Related_Client__r.Name,
                name : row.Id,
                accountId : row.NSP_Related_Client__c
            }
        });
        this.relatedClientPills = relatedClientPills;
    }

    handleItemRemove(event) {
        const relationId = event.detail.item.name;
        const index = event.detail.index;
    
        if(relationId && this.recordId){
            deleteRecord(relationId)
            .then( () => {
                // DELETED
                this.removePillByIndex(index);
            }).catch( (error) => {
            })
        }else{
            this.removePillByIndex(index);
        }
    }
    
    removePillByIndex(index){
        let accountId = this.relatedClientPills[index];
        let indexOfAccountId = this.relatedClientIds.indexOf(accountId);
        this.relatedClientIds.splice(indexOfAccountId,1);
        this.lRelatedClients.splice(index,1);
        this.createPills(this.lRelatedClients);
    }
    handleCheckboxChange(event) {
        let value = event.detail.value;
        let field = event.target.name;
        this.fields[field] = value.join(';');
        this.showDynamicFields(field, value);
    }

    handleCustomCheckboxChange(event){
        let checked = event.detail.checked;
        let field = event.target.name;
        let value = event.target.value;
        if(checked){
            if(this.fields[field] && this.fields[field] != ''){
                let values = this.fields[field].split(';');
                values.push(value);
                this.fields[field] = values.join(';');
            }else{
                this.fields[field] = value;
            }
        }else{
            let values = this.fields[field].split(';');
            let indexOf = values.indexOf(value);
            values.splice(indexOf,1);
            this.fields[field] = values.join(';');
        }
        this.showDynamicFields(field, this.fields[field]);
    }

    showDynamicFields(field, value) {
        if (field === 'Is_the_client_coming_from_another_PEO__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showPEOName = true;
            } else {
                this.fields.PEO_Name__c = null;
                this.showPEOName = false;
            }
            return;
        }

        if (field === 'Implementing_biz_Performance_solutions__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showClientAnyOtherBusinessSolutions = true;
            } else {
                this.fields.NSP_List_BPS_Implementation_Timeframe__c = '';
                this.showClientAnyOtherBusinessSolutions = false;
            }
            return;
        }

        if (field === 'Client_Profile_Information__c') {
            value = value || '';
            if (value.includes(this.label.relatedClientValue)) {
                this.showListofRelatedClients = true;
            } else {
                this.showListofRelatedClients = false;
                this.relatedClientIds = [];
                this.lRelatedClients = [];
                this.relatedClientPills= [];
            }
            if (value.includes(this.label.nationalClient)) {
                this.showNationalAccount = true;
            } else {
                this.showNationalAccount = false;
                this.fields.Account_Executive__c = '';
                this.fields.Hush_Protocol__c = '';
            }
            return;
        }

        if (field === 'NSP_Does_the_client_more_FEIN__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showFEINAdditionalField = true;
            } else {
                this.showFEINAdditionalField = false;
                this.fields.List_additional_FEIN_s__c = null;
            }
            return;
        }

        if (field === 'Employee_Data_Collection_EDC_collected__c') {
            if (value === this.label.employeeDataRequested) {
                this.showDeadLineDate = true;
            } else {
                this.showDeadLineDate = false;
                this.fields.Provide_deadline_date__c = null;
            }
            return;
        }

        if (field === 'Will_the_owner_s_be_on_payroll__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showClientBusinessTypeSole = true;
            } else {
                this.showClientBusinessTypeNo = value === this.label.No;
                this.showClientBusinessTypeNA = value === 'N/A';

                this.showClientBusinessTypeSole = false;
                this.fields.Sole_Proprietorship_or_partnership__c = null;
                this.fields.Owner_aware_they_will_not_get_W2_wages__c = null;
            }
            return;
        }

        if (field === 'Sole_Proprietorship_or_partnership__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showIsOwnerAwareWages = true;
            } else {
                this.showIsOwnerAwareWages = false;
                this.fields.Owner_aware_they_will_not_get_W2_wages__c = null;
            }
            return;
        }
        if (field === 'Chngs_for_cafeteria_plan_questionnaire__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showListofChanges = true;
            } else {
                this.showListofChanges = false;
                this.fields.List_change_s__c = null;
            }
            return;
        }
        if(field === 'All_EEs_paid_under_same_FEIN_currently__c'){
            this.showAdditionalFEINField = value === this.label.No;
            return;
        }

        if(field === 'Gotten_Cvrg_Cert_Gen_Liability_Auto__c'){
            this.showGenLiabilityField = (value === 'Received' || value === 'Requested');
            return;
        }
    }

    handleSyncChange(event){
        let field = event.currentTarget.dataset.id;
        let value = event.target.value;
        if(field === 'PEO_Name__c'){
            this.dispatchEvent(new CustomEvent('syncfields',{ detail: {field, value} }));
        }
    }

    @api handleSync(event){
        if(event.detail?.field === 'Provide_PEO_Name__c'){
            this.fields.PEO_Name__c = event.detail?.value;
        }
    }

    get syncFields(){
        if(this.showPEOName && this.fields.PEO_Name__c){
            const temp = this.template.querySelector('lightning-input-field[data-id="PEO_Name__c"]').value;
            temp.value = this.fields.PEO_Name__c;
        }
    }

    handleRequestedColor(field) {
        if (this.lFieldsWithRequestedValues.includes(field)) {
            let value = this.fields[field] || '';
            let eField = this.template.querySelector(`.${field}`);
            if(eField){
                if (value.includes(this.label.requested)) {
//                    eField.classList.add('requestedField');
                } else {
//                    eField.classList.remove('requestedField');
                }
            }
        }
    }

    updateCheckboxFields(fields){
        if(!fields){
            return;
        }
        if(fields.Client_Profile_Information__c){
            let fieldValues = fields.Client_Profile_Information__c.split(';');
            if(fieldValues.includes(this.label.camValue)){
                this.isCAMClient = true;
            }else{
                this.isCAMClient = false;
            }
            if(fieldValues.includes(this.label.formerClientReturningValue)){
                this.isFormerClientReturning = true;
            }else{
                this.isFormerClientReturning = false;
            }
            if(fieldValues.includes(this.label.wxClientValue)){
                this.isWXClient = true;
            }else{
                this.isWXClient = false;
            }
            if(fieldValues.includes(this.label.wsClientValue)){
                this.isWSClient = true;
            }else{
                this.isWSClient = false;
            }
            if(fieldValues.includes(this.label.woClientValue)){
                this.isWOClient = true;
            }else{
                this.isWOClient = false;
            }
            if(fieldValues.includes(this.label.relatedClientValue)){
                this.isRelatedClients = true;
            }else{
                this.isRelatedClients = false;
            }
            if(fieldValues.includes(this.label.nationalAccountValue)){
                this.isNationalAccount = true;
            }else{
                this.isNationalAccount = false;
            }
        }
    }

    // RECORD EDIT FORM
    handleLoad() {
        this.isLoading = false;
    }
    @api
    saveForm(newRecordId) {
        this.isLoading = true;
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        let fields = JSON.parse(JSON.stringify(this.fields));
        inputFields.forEach(field => {
            fields[field.fieldName] = field.value;
        });
        fields['Id'] = this.recordId || newRecordId;
        let lRelatedClients = [];
        let mAccountIdwithNames = new Map();
        this.relatedClientPills.forEach( row => {
            mAccountIdwithNames.set(row.accountId,row.label);
            lRelatedClients.push({
                NSP_Related_Client__c : row.accountId,
                NSP_Implementation_Profile__c : this.recordId,
                Id : row.name
            });
        });

        const params = JSON.stringify({
            'oIProfile' : fields,
            'lRelatedClients' : lRelatedClients
        });

        saveGeneralForm({
            'sIProfileGeneralWrapper' : params
        }).then( (response) =>{
            response.lRelatedClients.forEach(row => {
                row.NSP_Related_Client__r = {
                    'Name' : mAccountIdwithNames.get(row.NSP_Related_Client__c)
                }
            });
            this.lRelatedClients = response.lRelatedClients;
            this.createPills(this.lRelatedClients);
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('success', {detail : { "recordId" : response.oIProfile.Id}}));
            this.showToast(this.label.successTitle, this.label.implementationSavedMessage, 'success');
        }).catch( (error) => {
            this.isLoading = false;
            this.showToast(this.label.errorTitle, error.body.message, 'error');
            this.dispatchEvent(new CustomEvent('error', {detail : { "error" : error.body.message}}));
        });
    }
    showToast(title, message, type) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: type,
            }),
        );
    }
}