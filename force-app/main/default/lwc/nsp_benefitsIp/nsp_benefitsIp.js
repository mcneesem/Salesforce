import { api, LightningElement, wire , track} from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import PACKAGE_FIELD from '@salesforce/schema/Implementation_Profile__c.Benefits_Package__c';
import MEDICAL_LEVEL_FIELD from '@salesforce/schema/Implementation_Profile__c.Medical_Level__c';
import CLIENT_TERMINATED_PREVIOUS_BENEFIT_FIELD from '@salesforce/schema/Implementation_Profile__c.client_terminated_old_benefit_coverage__c';
import CLIENT_HAVE_EE_IN_NY_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_have_any_EEs_that_work_in_NY__c';
import CLIENT_MAINTAINING_EPLI_POLICY_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_maintaining_existing_EPLI_policy__c';
import CLIENT_COPY_EPLI_POLICY_FIELD from '@salesforce/schema/Implementation_Profile__c.Wnt_cpy_of_Insperity_EPLI_policy_cert__c';
import INSPERITY_WAITING_PERIOD_FIELD from '@salesforce/schema/Implementation_Profile__c.Insperity_benefits_waiting_period__c';
import CLIENT_HAVE_EE_IN_WAITING_PERIOD from '@salesforce/schema/Implementation_Profile__c.Any_EEs_in_clients_waiting_period__c';
import CLIENT_PREVIOUS_WAITING_PERIOD from '@salesforce/schema/Implementation_Profile__c.Client_s_previous_waiting_period__c';
import BENEFITS_CLASSING_PERIOD from '@salesforce/schema/Implementation_Profile__c.Will_there_be_benefits_classing__c';
import SCHEDULE_B_SKO_PERIOD from '@salesforce/schema/Implementation_Profile__c.Did_the_sch_B_change_at_the_SKO__c';
import CHECK_ALL_APPLY_SCHEDULE_PERIOD from '@salesforce/schema/Implementation_Profile__c.Check_all_sch_B_changes_that_apply__c';
import INSPERITY_REPLACING_PRIOR_OFFERING from '@salesforce/schema/Implementation_Profile__c.Insperity_grp_hlth_plan_replacing_prior__c';
import PREVIOUS_GROUP_PLAN_TERMINATING_PERIOD from '@salesforce/schema/Implementation_Profile__c.Previous_group_plan_is_terminating__c';
import PREVIOUS_GROUP_PLAN_COVERAGE_PERIOD from '@salesforce/schema/Implementation_Profile__c.Old_grp_health_plan_coverage_period_was__c';
import OLD_ADMIN_WAS_PEO_PERIOD from '@salesforce/schema/Implementation_Profile__c.Old_plan_administrator_was_another_PEO__c';
import PREVIOUS_GROUP_PLAN_ADMINISTRATOR from '@salesforce/schema/Implementation_Profile__c.Previous_group_health_plan_administrator__c';
import PREVIOUS_COVERAGE_TYPES from '@salesforce/schema/Implementation_Profile__c.Previous_group_health_plan_coverage_type__c';
import EE_URGENT_NEED_FIELD from '@salesforce/schema/Implementation_Profile__c.Any_EEs_with_urgent_medical_needs__c';
import CIGNA_TAKOVER_FIELD from '@salesforce/schema/Implementation_Profile__c.Does_the_Cigna_takeover_apply_to_client__c';
import COBRA_ELIGIBILITY_FIELD from '@salesforce/schema/Implementation_Profile__c.Participants_on_COBRA_eligibility_period__c';
import COBRA_TAKEOVER_QUESTION_FIELD from '@salesforce/schema/Implementation_Profile__c.Have_name_s_of_COBRA_takeovr_employees__c';
import ARE_THERE_LOA_FIELD from '@salesforce/schema/Implementation_Profile__c.Are_there_any_EEs_on_Leave_of_Absence__c';
import DO_YOU_HAVE_LOA_INFO_FIELD from '@salesforce/schema/Implementation_Profile__c.Do_you_have_the_LOA_information__c';
import DID_INFORM_EE_ABOUT_ELIGIBILITY_FIELD from '@salesforce/schema/Implementation_Profile__c.Told_EE_ineligble_for_active_at_work_ben__c';
import CLIENT_HSA_FIELD from '@salesforce/schema/Implementation_Profile__c.Does_the_client_offer_a_HSA__c';
import CLIENT_HSA_WITH_OPTUM_BANK_FIELD from '@salesforce/schema/Implementation_Profile__c.Is_client_s_current_HSA_with_Optum_Bank__c';
import CLIENT_CODE_FIELD from '@salesforce/schema/Implementation_Profile__c.Does_client_have_their_code_group_ID__c';
import EMPLOYER_EE_HSA_FIELD from '@salesforce/schema/Implementation_Profile__c.Any_employer_contributions_to_EE_HSA__c';
import CLIENT_MAINTAINING_SPONSORED_PLAN_FIELD from '@salesforce/schema/Implementation_Profile__c.Spnsrd_pln_when_Insperity_hndles_payroll__c';
import SPONSORED_CONTRIBUTIONS_TYPE_FIELD from '@salesforce/schema/Implementation_Profile__c.Sponsored_plan_contribution_type__c';
import PRE_TAX_PLAN_TYPE_FIELD from '@salesforce/schema/Implementation_Profile__c.Pre_tax_Client_Sponsored_Plan_CSP_Type__c';

import HCFSA_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c';
import HSA_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_HSA_Ongoing_CSP_cafeteria_document__c';
import DCFSA_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c';
import MEDICAL_DOCUMENT_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c';
import DENTAL_DOCUMENT_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c';
import VISION_DOCUMENT_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c';
import PRIOR_MDEICAL_CONTRI from '@salesforce/schema/Implementation_Profile__c.NSP_prior_medical_contributions__c';
import SELECT_APPLICABLE_LOA from '@salesforce/schema/Implementation_Profile__c.Select_the_applicable_LOA_types__c';
import ANY_EMP_ENROLLED from '@salesforce/schema/Implementation_Profile__c.Any_employees_currently_enrolled__c';
import OFFER_FSA_FIELD from '@salesforce/schema/Implementation_Profile__c.Does_the_client_currently_offer_a_FSA__c';
import OWN_FSA from '@salesforce/schema/Implementation_Profile__c.Client_maintain_own_FSA__c';
import saveEmployeeData from '@salesforce/apex/NSP_ImplementationProfileController.saveEmployeeData';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import * as labels from 'c/nsp_implementationLabels';

export default class Nsp_benefitsIp extends LightningElement {
    label = labels;
    @api
    recordId;
    @api error;
    @api
    objectApiName;
    @track fields = {PRIOR_MDEICAL_CONTRI: []};
    @api
    defaultRecordTypeId;
    @api empData;
    isLoading = true;
    showTerminationDate = false;
    showWaitingPeriodFields = false;
    showSKOFields = false;
    showListEmployeeNames = false;
    showPreviousGroupPlanFields = false;
    showPreviousStartandEndDate = false;
    showPreviousGroupAdminFields = false;
    showPEONameField = false;
    showEEsName = false;
    showCOBRAFields = false;
    showCOBRAProvideDetails = false;
    showLOAFields = false;
    showStatusOfLOAField = false;
    showClientHSAFields = false;
    showClientCodeQuestion = false;
    showClientCodeField = false;
    showContributionProvideDetails = false;
    showPrePostTaxFields = false;
    checkAllApplySchedulePeriods = [];
    previousCoverageTypes = [];
    preTax = false;
    postTax = false;
    HCFSAPreTax = false;
    HSAPreTax = false;
    DCFSAPreTax = false;
    medicalPreTax = false;
    dentalPreTax = false;
    visionPreTax = false;
    showHCFSADetails = false;
    showHSADetails = false;
    showDCFSADetails = false;
    showMedicalPretaxDetails = false;
    showDentalPretaxDetails = false;
    showVisionPretaxDetails = false;
    isValidScheduleBChanges = false;
    showCOBRAEmpTable = false;
    showLOAEmpTable = false;
    hasFSA = false;
    validOptions = ['Benefit package changed', 'HSA Client Distribution', 'Other'];
    pickValueYesNo = [
        { attributes : null, label : this.label.No, value : "No" },
        { attributes : null, label : this.label.Yes, value : "Yes" }
    ];
    multiSelectFields = ['Select_the_applicable_LOA_types__c'];

    firstTimeRendered = true;
    lBlueFieldscolor = ['Previous_group_health_plan_carrier_s__c'];
    lFieldsWithRequestedValues = ['NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c','NSP_HSA_Ongoing_CSP_cafeteria_document__c','NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c',
    'NSP_Medical_Ongoing_CSP_cafeteria_Doc__c','NSP_Dental_Ongoing_CSP_cafeteria_Doc__c','NSP_Vision_Ongoing_CSP_cafeteria_Doc__c'];
    lCafeteriaFields = ['NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c','NSP_HSA_Ongoing_CSP_cafeteria_document__c','NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c',
        'NSP_Medical_Ongoing_CSP_cafeteria_Doc__c','NSP_Dental_Ongoing_CSP_cafeteria_Doc__c','NSP_Vision_Ongoing_CSP_cafeteria_Doc__c'];
    childAnswerFields = {
        Have_name_s_of_COBRA_takeovr_employees__c : ['NSP_Name__c', 'NSP_Form_Collected__c'],
        Do_you_have_the_LOA_information__c : ['NSP_Name__c', 'NSP_LOA_Start_Date__c', 'NSP_LOA_Form_Collected__c'],
    };
    renderedCallback(){
        if(this.firstTimeRendered && Object.keys(this.fields).length > 0){
            let allColoredFields = [].concat(this.lFieldsWithRequestedValues);
            for(let field of allColoredFields){
                this.handleRequestedColor(field);
                this.handleEmptyColor(field,this.fields[field]);
            }
            this.firstTimeRendered = false;
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: PACKAGE_FIELD })
    packageValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: MEDICAL_LEVEL_FIELD })
    medicalLevelValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_TERMINATED_PREVIOUS_BENEFIT_FIELD })
    clientTerminatedBenefits;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_HAVE_EE_IN_NY_FIELD })
    clientHaveEEsInNYValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: INSPERITY_WAITING_PERIOD_FIELD })
    insperityWaitingPeriodValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_PREVIOUS_WAITING_PERIOD })
    clientWaitingPeriodValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CHECK_ALL_APPLY_SCHEDULE_PERIOD })
    checkAllApplySchedulePeriodValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: PREVIOUS_GROUP_PLAN_TERMINATING_PERIOD })
    previousGroupTerminatingValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: PREVIOUS_GROUP_PLAN_COVERAGE_PERIOD })
    previousGroupCoveragePeriod;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: PREVIOUS_GROUP_PLAN_ADMINISTRATOR })
    previousGroupPlanAdminValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: PREVIOUS_COVERAGE_TYPES })
    previousCoverageTypeValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: SPONSORED_CONTRIBUTIONS_TYPE_FIELD })
    sponsoredContributionTypes;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: HCFSA_FIELD })
    ongoingCSPdocumentValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: SELECT_APPLICABLE_LOA })
    selectApplicableLoa;

    @wire(getRecord, {
        recordId: '$recordId', fields: [ PACKAGE_FIELD, MEDICAL_LEVEL_FIELD, CLIENT_TERMINATED_PREVIOUS_BENEFIT_FIELD,CLIENT_HAVE_EE_IN_NY_FIELD,
            CLIENT_MAINTAINING_EPLI_POLICY_FIELD,CLIENT_COPY_EPLI_POLICY_FIELD, INSPERITY_WAITING_PERIOD_FIELD, CLIENT_HAVE_EE_IN_WAITING_PERIOD,
            CLIENT_PREVIOUS_WAITING_PERIOD,BENEFITS_CLASSING_PERIOD,SCHEDULE_B_SKO_PERIOD, CHECK_ALL_APPLY_SCHEDULE_PERIOD,CLIENT_CODE_FIELD,
            INSPERITY_REPLACING_PRIOR_OFFERING, PREVIOUS_GROUP_PLAN_TERMINATING_PERIOD,PREVIOUS_GROUP_PLAN_COVERAGE_PERIOD,PREVIOUS_GROUP_PLAN_ADMINISTRATOR,
            OLD_ADMIN_WAS_PEO_PERIOD,PREVIOUS_COVERAGE_TYPES,EE_URGENT_NEED_FIELD,CIGNA_TAKOVER_FIELD,COBRA_ELIGIBILITY_FIELD,COBRA_TAKEOVER_QUESTION_FIELD,
            ARE_THERE_LOA_FIELD,DO_YOU_HAVE_LOA_INFO_FIELD,DID_INFORM_EE_ABOUT_ELIGIBILITY_FIELD,CLIENT_HSA_FIELD,CLIENT_HSA_WITH_OPTUM_BANK_FIELD,
            EMPLOYER_EE_HSA_FIELD,CLIENT_MAINTAINING_SPONSORED_PLAN_FIELD,SPONSORED_CONTRIBUTIONS_TYPE_FIELD,PRE_TAX_PLAN_TYPE_FIELD,HCFSA_FIELD, HSA_FIELD,
            DCFSA_FIELD,MEDICAL_DOCUMENT_FIELD,DENTAL_DOCUMENT_FIELD,VISION_DOCUMENT_FIELD, PRIOR_MDEICAL_CONTRI, ANY_EMP_ENROLLED,SELECT_APPLICABLE_LOA,
            OFFER_FSA_FIELD, OWN_FSA
        ]
    })
    getIPRecDetails(value) {
        this.implemenatioProfileDetails = value;
        const { data, error } = value;
        if (data) {
            let fields = data.fields;
            let oImpProfileFields = {};
            for(let field in fields){
                const val = fields[field].value;
                oImpProfileFields[field] = this.multiSelectFields.includes(field) ? (val || '').split(';') : val;
                this.showDynamicFields(field, val);
            }
            this.updateCheckboxFields(oImpProfileFields);
            this.fields = oImpProfileFields;
            this.updateCustomLogic();
        } else if (error) {
            this.error = error;
        }
    }

    // RECORD EDIT FORM
    handleLoad(){
        this.isLoading = false;
        this.fixLabelColor();
    }
    
    fixLabelColor(){
        const inputFields = this.template.querySelectorAll('.ipProfile lightning-input-field');
        inputFields.forEach(field => {
            if(this.lBlueFieldscolor.includes(field.fieldName)){
                this.handleEmptyColor(field.fieldName,field.value);
            }
        });
    }

    handleChange(event) {
        let value = event.detail.value;
        let field = event.target.name;
        this.fields[field] = value;
        this.showDynamicFields(field, value);
        this.handleRequestedColor(field);
    }

    handleInputChange(event) {
        let value = event.detail.value;
        let field = event.currentTarget.fieldName;
        this.handleEmptyColor(field,value);
    }

    handleCheckboxChange(event){
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
        if (field === 'client_terminated_old_benefit_coverage__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showTerminationDate = true;
            } else {
                this.showTerminationDate = false;
                this.fields.Prior_Benefits_Termination_Date__c = null;
            }
            return;
        }

        if (field === 'Any_EEs_in_clients_waiting_period__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showWaitingPeriodFields = true;
            } else {
                this.showWaitingPeriodFields = false;
                this.fields.NSP_List_Employee_Names__c = null;
            }
            return;
        }
        if (field === 'Insperity_benefits_waiting_period__c') {
            this.updateCustomLogic();
            return;
        }

        if (field === 'Client_s_previous_waiting_period__c') {
            this.updateCustomLogic();
            return;
        }

        if (field === 'Did_the_sch_B_change_at_the_SKO__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showSKOFields = true;
            } else {
                this.showSKOFields = false;
                this.fields.NSP_Provide_Schedule_B_details__c = null;
            }
            return;
        }

        if (field === 'Insperity_grp_hlth_plan_replacing_prior__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showPreviousGroupPlanFields = true;
            } else {
                this.showPreviousGroupPlanFields = false;
                // SET ALL FIELDS AS BLANK
                this.fields.Previous_group_plan_is_terminating__c = null;
                this.fields.Old_grp_health_plan_coverage_period_was__c = null;
                this.fields.Provide_start_end_dates_of_plan_year__c = null;
                this.fields.Previous_group_health_plan_administrator__c = null;
                this.fields.Old_plan_administrator_was_another_PEO__c = null;
                this.fields.Provide_PEO_Name__c = null;
                this.fields.Previous_group_health_plan_coverage_type__c = null;
                this.previousCoverageTypes = [];
            }
            return;
        }

        if (field === 'Old_grp_health_plan_coverage_period_was__c') {
            if (value === this.label.OTHER_PLAN_YEAR_VALUE) {
                this.showPreviousStartandEndDate = true;
            } else {
                this.showPreviousStartandEndDate = false;
                this.fields.Provide_start_end_dates_of_plan_year__c = null;
            }
            return;
        }

        if (field === 'Previous_group_health_plan_administrator__c') {
            if (value === this.label.OTHER_ADMINISTRATOR_VALUE) {
                this.showPreviousGroupAdminFields = true;
            } else {
                this.showPreviousGroupAdminFields = false;
                this.fields.Old_plan_administrator_was_another_PEO__c = null;
                this.fields.Provide_PEO_Name__c = null;
            }
            return;
        }

        if (field === 'Old_plan_administrator_was_another_PEO__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showPEONameField = true;
            } else {
                this.showPEONameField = false;
                this.fields.Provide_PEO_Name__c = null;
            }
            return;
        }

        if (field === 'Any_EEs_with_urgent_medical_needs__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showEEsName = true;
            } else {
                this.showEEsName = false;
                // this.fields.NSP_List_EEs_Names__c = null;
            }
            return;
        }

        if (field === 'Participants_on_COBRA_eligibility_period__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showCOBRAFields = true;
            } else {
                this.showCOBRAFields = false;
                this.fields.Have_name_s_of_COBRA_takeovr_employees__c = false;
                this.fields.Provide_details_for_no_COBRA_employees__c = null;
            }
            return;
        }

        if (field === 'Have_name_s_of_COBRA_takeovr_employees__c') {
            if (value === this.label.NO_CONSTANT) {
                this.showCOBRAProvideDetails = true;
                this.showCOBRAEmpTable = false;
            } else if(value === this.label.YES_CONSTANT) {
                this.showCOBRAProvideDetails = false;
                this.showCOBRAEmpTable = true;
                this.fields.Provide_details_for_no_COBRA_employees__c = null;
            }
            return;
        }

        if (field === 'Are_there_any_EEs_on_Leave_of_Absence__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showLOAFields = true;
            } else {
                this.showLOAFields = false;
                this.fields.Do_you_have_the_LOA_information__c = null;
                this.fields.What_is_the_status_of_the_LOA_info__c = null;
                this.fields.Told_EE_ineligble_for_active_at_work_ben__c = null;
                this.fields.How_will_EE_complete_their_enrollment__c = null;
            }
            return;
        }

        if (field === 'Do_you_have_the_LOA_information__c') {
            if (value === this.label.NO_CONSTANT) {
                this.showStatusOfLOAField = true;
                this.showLOAEmpTable = false;
            } else if(value === this.label.YES_CONSTANT) {
                this.showStatusOfLOAField = false;
                this.showLOAEmpTable = true;
                this.fields.What_is_the_status_of_the_LOA_info__c = null;
            }
            return;
        }

        if (field === 'Does_the_client_offer_a_HSA__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showClientHSAFields = true;
            } else {
                this.showClientHSAFields = false;
                this.fields.Is_client_s_current_HSA_with_Optum_Bank__c = null;
                this.fields.Does_client_have_their_code_group_ID__c = null;
                this.fields.Optum_Bank_HSA_Code__c = null;
                this.fields.Optum_Bank_HSA_Group__c = null;
            }
            return;
        }

        if (field === 'Is_client_s_current_HSA_with_Optum_Bank__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showClientCodeQuestion = true;
            } else {
                this.showClientCodeQuestion = false;
                this.fields.Does_client_have_their_code_group_ID__c = null;
                this.fields.Optum_Bank_HSA_Code__c = null;
                this.fields.Optum_Bank_HSA_Group__c = null;
            }
            return;
        }

        if (field === 'Does_client_have_their_code_group_ID__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showClientCodeField = true;
            } else {
                this.showClientCodeField = false;
                this.fields.Optum_Bank_HSA_Code__c = null;
                this.fields.Optum_Bank_HSA_Group__c = null;
            }
            return;
        }

        if (field === 'Any_employer_contributions_to_EE_HSA__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showContributionProvideDetails = true;
            } else {
                this.showContributionProvideDetails = false;
                this.fields.NSP_Employer_contributions_details__c = null;
            }
            return;
        }

        if (field === 'Spnsrd_pln_when_Insperity_hndles_payroll__c') {
            if (value === this.label.YES_CONSTANT) {
                this.showPrePostTaxFields = true;
            } else {
                this.showPrePostTaxFields = false;
                this.preTax = false;
                this.postTax = false;
                this.fields.Sponsored_plan_contribution_type__c = null;
                this.HCFSAPreTax = false;
                this.fields.Pre_tax_Client_Sponsored_Plan_CSP_Type__c = null;
                this.fields.NSP_HCFSA_Delayed_Start_Date__c = null;
                this.fields.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c = null;
                this.fields.NSP_HCFSA_Provide_Details__c = null;
                this.HSAPreTax = false;
                this.fields.NSP_Health_Savings_Account_Delayed_Start__c = null;
                this.fields.NSP_HSA_Ongoing_CSP_cafeteria_document__c = null;
                this.fields.NSP_HSA_Provide_Details__c = null;
                this.DCFSAPreTax = false;
                this.fields.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c = null;
                this.fields.NSP_DCFSA_Provide_details__c = null;
                this.medicalPreTax = false;
                this.fields.NSP_Medical_Pretax_Delayed_Start__c = null;
                this.fields.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c = null;
                this.fields.NSP_Medical_Pretax_Provide_details__c = null;
                this.dentalPreTax = false;
                this.fields.NSP_Dental_Pretax_Delayed_Start__c = null;
                this.fields.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c = null;
                this.fields.NSP_Dental_Pretax_Provide_Details__c = null;
                this.visionPreTax = false;
                this.fields.NSP_Vision_Pretax_Delayed_Start__c = null;
                this.fields.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c = null;
                this.fields.NSP_Vision_Pretax_Provide_Details__c = null;
                this.fields.Post_tax_suppl_insurance_provide_details__c = null;
            }
            return;
        }

        if(field === 'Sponsored_plan_contribution_type__c'){
            value = value || '';
            let values = value.split(';');
            if(values.includes(this.label.preTaxValue)){
                this.preTax = true;
            }else{
                this.preTax = false;
                this.HCFSAPreTax = false;
                this.fields.Pre_tax_Client_Sponsored_Plan_CSP_Type__c = null;
                this.fields.NSP_HCFSA_Delayed_Start_Date__c = null;
                this.fields.NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c = null;
                this.fields.NSP_HCFSA_Provide_Details__c = null;
                this.HSAPreTax = false;
                this.fields.NSP_Health_Savings_Account_Delayed_Start__c = null;
                this.fields.NSP_HSA_Ongoing_CSP_cafeteria_document__c = null;
                this.fields.NSP_HSA_Provide_Details__c = null;
                this.DCFSAPreTax = false;
                this.fields.NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c = null;
                this.fields.NSP_DCFSA_Provide_details__c = null;
                this.medicalPreTax = false;
                this.fields.NSP_Medical_Pretax_Delayed_Start__c = null;
                this.fields.NSP_Medical_Ongoing_CSP_cafeteria_Doc__c = null;
                this.fields.NSP_Medical_Pretax_Provide_details__c = null;
                this.dentalPreTax = false;
                this.fields.NSP_Dental_Pretax_Delayed_Start__c = null;
                this.fields.NSP_Dental_Ongoing_CSP_cafeteria_Doc__c = null;
                this.fields.NSP_Dental_Pretax_Provide_Details__c = null;
                this.visionPreTax = false;
                this.fields.NSP_Vision_Pretax_Delayed_Start__c = null;
                this.fields.NSP_Vision_Ongoing_CSP_cafeteria_Doc__c = null;
                this.fields.NSP_Vision_Pretax_Provide_Details__c = null;
            }

            if(values.includes(this.label.postTaxValue)){
                this.postTax = true;
            }else{
                this.postTax = false;
                this.fields.Post_tax_suppl_insurance_provide_details__c = null;
            }
            return;
        }

        if(field === 'Pre_tax_Client_Sponsored_Plan_CSP_Type__c'){
            value = value || '';
            let values = value.split(';');
            if(values.includes(this.label.HCFSAValue)){
                this.HCFSAPreTax = true;
            }else{
                this.HCFSAPreTax = false;
            }

            if(values.includes(this.label.HSAValue)){
                this.HSAPreTax = true;
            }else{
                this.HSAPreTax = false;
            }

            if(values.includes(this.label.DCFSAValue)){
                this.DCFSAPreTax = true;
            }else{
                this.DCFSAPreTax = false;
            }

            if(values.includes(this.label.medicalPreTaxValue)){
                this.medicalPreTax = true;
            }else{
                this.medicalPreTax = false;
            }

            if(values.includes(this.label.dentalPreTaxValue)){
                this.dentalPreTax = true;
            }else{
                this.dentalPreTax = false;
            }

            if(values.includes(this.label.visionPreTaxValue)){
                this.visionPreTax = true;
            }else{
                this.visionPreTax = false;
            }
            return;
        }

        if(field === 'NSP_HCFSA_Ongoing_CSP_cafeteria_plan_Doc__c') {
            if (value === this.label.NAValue) {
                this.showHCFSADetails = true;
            } else {
                this.showHCFSADetails = false;
                this.fields.NSP_HCFSA_Provide_Details__c = null;
            }
            return;
        }

        if(field === 'NSP_HSA_Ongoing_CSP_cafeteria_document__c') {
            if (value === this.label.NAValue) {
                this.showHSADetails = true;
            } else {
                this.showHSADetails = false;
                this.fields.NSP_HSA_Provide_Details__c = null;
            }
            return;
        }

        if(field === 'NSP_DCFSA_Ongoing_CSP_Cafeteria_document__c') {
            if (value === this.label.NAValue) {
                this.showDCFSADetails = true;
            } else {
                this.showDCFSADetails = false;
                this.fields.NSP_DCFSA_Provide_details__c = null;
            }
            return;
        }

        if(field === 'NSP_Medical_Ongoing_CSP_cafeteria_Doc__c') {
            if (value === this.label.NAValue) {
                this.showMedicalPretaxDetails = true;
            } else {
                this.showMedicalPretaxDetails = false;
                this.fields.NSP_Medical_Pretax_Provide_details__c = null;
            }
            return;
        }

        if(field === 'NSP_Dental_Ongoing_CSP_cafeteria_Doc__c') {
            if (value === this.label.NAValue) {
                this.showDentalPretaxDetails = true;
            } else {
                this.showDentalPretaxDetails = false;
                this.fields.NSP_Dental_Pretax_Provide_Details__c = null;
            }
            return;
        }

        if(field === 'NSP_Vision_Ongoing_CSP_cafeteria_Doc__c') {
            if (value === this.label.NAValue) {
                this.showVisionPretaxDetails = true;
            } else {
                this.showVisionPretaxDetails = false;
                this.fields.NSP_Vision_Pretax_Provide_Details__c = null;
            }
            return;
        }

        if(field === 'Check_all_sch_B_changes_that_apply__c') {
            let isVisible = false;
            const val = value ? (!Array.isArray(value) ? value.split(';') : value) : [];
            val.forEach(v => {
                if(this.validOptions.includes(v)){
                    isVisible = true;
                }
            });
            this.isValidScheduleBChanges = isVisible;
            return;
        }

        if(field === 'Does_the_client_currently_offer_a_FSA__c'){
            this.hasFSA = (value === this.label.YES_CONSTANT);
            return;
        }

        if(field === 'Provide_PEO_Name__c'){
            this.dispatchEvent(new CustomEvent('syncfields',{ detail: {field, value} }));
            return;
        }
    }

    handleSyncChange(event){
        let field = event.currentTarget.dataset.id;
        let value = event.target.value;
        if(field === 'Provide_PEO_Name__c'){
            this.dispatchEvent(new CustomEvent('syncfields',{ detail: {field, value} }));
        }
        if(field === 'Benefit_effective_date_carry_from_tab_4__c'){
            this.dispatchEvent(new CustomEvent('syncfields',{ detail: {field, value} }));
        }
    }

    @api handleSync(event){
        if(event.detail?.field === 'PEO_Name__c'){
            this.fields.Provide_PEO_Name__c = event.detail?.value;
        }
        if(event.detail?.field === 'Insperity_benefits_effective_date__c'){
            this.fields.Benefit_effective_date_carry_from_tab_4__c = event.detail?.value;
        }
    }

    get syncFields(){
        if(this.showPEONameField && this.fields.Provide_PEO_Name__c){
            const temp = this.template.querySelector('lightning-input-field[data-id="Provide_PEO_Name__c"]').value;
            temp.value = this.fields.Provide_PEO_Name__c;
        }
        if(this.fields.Benefit_effective_date_carry_from_tab_4__c){
            const temp = this.template.querySelector('lightning-input-field[data-id="Benefit_effective_date_carry_from_tab_4__c"]').value;
            temp.value = this.fields.Benefit_effective_date_carry_from_tab_4__c;
        }
    }

    handleRequestedColor(field) {
        if (this.lFieldsWithRequestedValues.includes(field)) {
            let eField;
            if(this.lCafeteriaFields.includes(field)){
                eField = this.template.querySelector('.ongoingCafeteriaheading');
            }else{
                eField = this.template.querySelector(`.${field}`);
            }

            let value = this.fields[field] || '';
            if(eField){
                if (value.includes(this.label.requested)) {
                    eField.classList.add('requestedField');
                } else {
                    eField.classList.remove('requestedField');
                }
            }
        }
    }

    handleEmptyColor(field,value) {
        if(this.lBlueFieldscolor.includes(field)){
            let eField = this.template.querySelector(`.${field}`);
            if(eField){
                if (value) {
                    eField.classList.remove('emptyField');
                } else {
                    eField.classList.add('emptyField');
                }
            }
        }
    }
    
    get showProvideDetailscolumn(){
        return (this.showHCFSADetails || this.showHSADetails || this.showDCFSADetails || this.showMedicalPretaxDetails || this.showDentalPretaxDetails || this.showVisionPretaxDetails)
    }

    updateCustomLogic(){
        let nspWaitingPeriodValues = this.fields.Insperity_benefits_waiting_period__c || '';
        let clientWaitingPeriodValues = this.fields.Client_s_previous_waiting_period__c || '';
        if(nspWaitingPeriodValues === '' || clientWaitingPeriodValues === '')
            return;
        let nspDays = nspWaitingPeriodValues.split(' ');
        let clientDays = clientWaitingPeriodValues.split(' ');
        let nspDay = 0;
        let clientDay = 0;
        if(nspDays.length === 2){
            nspDay = parseInt(nspDays[0]);
        }
        if(clientDays.length === 2){
            clientDay = parseInt(clientDays[0]);
        }
        if(nspDay > clientDay){
            this.showListEmployeeNames = true;
        }else{
            this.showListEmployeeNames = false;
            this.fields.NSP_List_Employee_Names__c = null;
        }
        return;
    }

    updateCheckboxFields(fields){
        if(!fields){
            return;
        }
        let checkAllScheduleValue = fields[CHECK_ALL_APPLY_SCHEDULE_PERIOD.fieldApiName] || '';
        this.checkAllApplySchedulePeriods = checkAllScheduleValue.split(';');
        
        let previousCoverageTypeValue = fields[PREVIOUS_COVERAGE_TYPES.fieldApiName] || '';
        this.previousCoverageTypes = previousCoverageTypeValue.split(';');
    }

    @api
    saveForm(newRecordId){
        this.isLoading = true;
        const inputFields = this.template.querySelectorAll('lightning-input-field');
        let fields = JSON.parse(JSON.stringify(this.fields));
        inputFields.forEach(field => {
            fields[field.fieldName] = field.value;
        });

        const existingRecordId = this.recordId || newRecordId;
        const { allEmployeeRecords, parentFieldNames, fieldSpecificRecords } = this.getEmployeeRecords();
        this.updateEmpDetailsOnIPRecord(fields, fieldSpecificRecords);

        if (existingRecordId) {
            fields['Id'] = existingRecordId;
            updateRecord({ fields })
                .then((oImpProfile) => {
                    this.isLoading = false;
                    this.saveEmployeeRecords(allEmployeeRecords, existingRecordId, parentFieldNames)
                    this.showToast(this.label.successTitle, this.label.implementationSavedMessage, 'success');
                    this.dispatchEvent(new CustomEvent('success', { detail: { "recordId": oImpProfile.id } }));
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showToast(this.label.errorTitle, error.body.message, 'error');
                    this.dispatchEvent(new CustomEvent('error', {detail : { "error" : error.body.message}}));
                });
        } else {
            const recordInput = { apiName: this.objectApiName, fields };
            createRecord(recordInput)
                .then(oImpProfile => {
                    this.isLoading = false;
                    this.saveEmployeeRecords(allEmployeeRecords, oImpProfile.id, parentFieldNames);
                    this.showToast(this.label.successTitle, this.label.implementationSavedMessage, 'success');
                    this.dispatchEvent(new CustomEvent('success', { detail: { "recordId": oImpProfile.id } }));
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showToast(this.label.errorTitle, error.body.message, 'error');
                    this.dispatchEvent(new CustomEvent('error', {detail : { "error" : error.body.message}}));
                });
        }
    }

    getEmployeeRecords() {
        const parentFieldNames = [];
        let allEmployeeRecords = [];
        let fieldSpecificRecords = {};

        this.template.querySelectorAll('c-nsp_employee-data').forEach(empForm => {
            const parentFieldName = empForm.parentField;
            const formValues = empForm.getAllRecords();

            parentFieldNames.push(parentFieldName);
            fieldSpecificRecords[parentFieldName] = [...formValues];

            if(formValues.length > 0) {
                allEmployeeRecords = [ ...allEmployeeRecords, ...formValues ];
            }
        });

        return { allEmployeeRecords, parentFieldNames, fieldSpecificRecords };
    }

    saveEmployeeRecords(allEmployeeRecords, ipRecId, parentFieldNames){
        if(allEmployeeRecords.length > 0){
            saveEmployeeData({ records: JSON.stringify(allEmployeeRecords), ipRecId, parentFieldNames })
            .then(()=> console.log('Benefits Employuee records saved'))
            .catch(error => console.error('Benefits Employee Error', error.body.message));
        }
    }

    updateEmpDetailsOnIPRecord(ipRecord, fieldSpecificRecords) {
        this.updateCobraEmployees(
            fieldSpecificRecords.Have_name_s_of_COBRA_takeovr_employees__c,
            this.childAnswerFields.Have_name_s_of_COBRA_takeovr_employees__c,
            ipRecord
        );
        this.updateLOADetails(
            fieldSpecificRecords.Do_you_have_the_LOA_information__c,
            this.childAnswerFields.Do_you_have_the_LOA_information__c,
            ipRecord
        );
    }

    updateCobraEmployees(childRecords, fields, ipRecord){
        if(childRecords){
            ipRecord.NSP_COBRA_Takeover_Emp_Details__c = childRecords.map(rec => `${rec[fields[0]]}~${rec[fields[1]]}`).join(',');
        }
    }

    updateLOADetails(childRecords, fields, ipRecord){
        if(childRecords){
            ipRecord.NSP_Employees_on_LOA__c = childRecords.map(rec => `${rec[fields[0]]}~${rec[fields[2]]}`).join(',');
        }
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