import { LightningElement, api, wire, track } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getRecord, deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

import getPayPeriods from '@salesforce/apex/NSP_ImplementationProfileController.getPayPeriods';
import savePayrollDetails from '@salesforce/apex/NSP_ImplementationProfileController.savePayrollDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import IMPLEMENTATION_PAY_PERIOD from '@salesforce/schema/Implementation_Pay_Period__c'
import BENEFITS_EFFECTIVE_DATE_FIELD from '@salesforce/schema/Implementation_Profile__c.Benefit_effective_date_carry_from_tab_4__c';
import INSPERITY_PAY_PERIOD from '@salesforce/schema/Implementation_Profile__c.Insperity_pay_frequency__c';
import WEEKLY_PAY_PERIOD from '@salesforce/schema/Implementation_Profile__c.NSP_Weekly_Pay_Period__c';
import BIWEEKLY_PAY_PERIOD from '@salesforce/schema/Implementation_Profile__c.NSP_Biweekly_Pay_Period__c';
import SEMIMONTHLY_PAY_PERIOD from '@salesforce/schema/Implementation_Profile__c.NSP_Semimonthly_Pay_Period__c';
import NON_EXEMPT_SEMI_MONTHLY_PAY_FREQUENCY from '@salesforce/schema/Implementation_Profile__c.Non_exempt_EEs_on_semi_monthly_pay_freq__c';
import SEMIMONTHLY_STATE_LAW_FIELD from '@salesforce/schema/Implementation_Profile__c.Semi_monthly_pay_freq_comply_w_state_law__c';
import MONTHLY_PAY_PERIOD from '@salesforce/schema/Implementation_Profile__c.NSP_Monthly_Pay_Period__c';
import MONTHLY_STATE_LAW_FIELD from '@salesforce/schema/Implementation_Profile__c.Monthly_pay_freq_comply_w_state_laws__c';
import IS_NEED_FOR_SUBACCOUNT_FIELD from '@salesforce/schema/Implementation_Profile__c.Is_there_a_need_for_a_subaccount__c';
import WHY_SUBACCOUNT_NEEDED_FIELD from '@salesforce/schema/Implementation_Profile__c.Why_is_subaccount_needed__c';
import CLASSING_REQ_FIELD from '@salesforce/schema/Implementation_Profile__c.classing_req_a_new_download_for_Subacc__c';
import WORK_WEEK_FIELD from '@salesforce/schema/Implementation_Profile__c.Work_week__c';
import HOLIDAY_WEEKEND_FIELD from '@salesforce/schema/Implementation_Profile__c.Holiday_or_weekend_rule__c';
import EE_LIVE_CHECK_MAIL_FIELD from '@salesforce/schema/Implementation_Profile__c.Where_to_mail_EE__c';
import CLIENT_WORKFORCE_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_co_employ_100_of_client_workforce__c';
import NON_INSPERITY_CONTRACTORS_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_non_Insperity_paid_emps_contractors__c';
import CLIENT_EE_VISA_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_have_any_EEs_on_F1_or_J1_Visa_s__c';
import CLIENT_COMMISSION_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_have_any_Commission_only_EEs__c';
import FLSA_APPROVED_FIELD from '@salesforce/schema/Implementation_Profile__c.Has_FLSA_team_approved__c';
import CLIENT_MINOR_EE_FIELD from '@salesforce/schema/Implementation_Profile__c.Does_client_have_any_Minor_EEs__c';
import CLIENT_SEASONAL_EE_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_have_will_have_any_Seasonal_EEs__c';
import CLIENT_MINISTERS_FIELD from '@salesforce/schema/Implementation_Profile__c.Does_client_employ_ministers_or_teachers__c';
import CLIENT_MINISTERS_CHECK_ALL_FIELD from '@salesforce/schema/Implementation_Profile__c.Check_all_tht_apply_ministers_teachers__c';
import CLIENT_UNION_EE_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_union_EE_Check_all_that_Apply__c';
import CLIENT_UNION_FIELD from '@salesforce/schema/Implementation_Profile__c.Does_the_client_have_any_union_EEs__c';
import CLIENT_FEDERAL_FIELD from '@salesforce/schema/Implementation_Profile__c.Is_the_client_a_federal_contractor__c';
import CLIENT_EEO_NUMBER_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_have_EEO_filing_under__c';
import EE_GARNISHMENT_FIELD from '@salesforce/schema/Implementation_Profile__c.Do_any_EEs_have_garnishments__c';
import EE_TAX_FIELD from '@salesforce/schema/Implementation_Profile__c.Do_any_EEs_have_tax_levies__c';
import CLIENT_EXPENSE_ALLOWANCE_FIELD from '@salesforce/schema/Implementation_Profile__c.Has_expenses_allowances_through_payroll__c';
import ALLOWANCE_FIELD from '@salesforce/schema/Implementation_Profile__c.Allowances__c';
import EXPENSE_FIELD from '@salesforce/schema/Implementation_Profile__c.Expenses__c';
import SCA_EE_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_has_Service_Contract_Act_SCA_EEs__c';
import GARNISH_DOC_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_Documents_garnishments__c';

import CLIENT_TAX_DEDUCTION_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_has_any_post_tax_deductions__c';
import CLIENT_PAYROLL_NEED_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_has_any_special_payroll_needs__c';
import STATE_FIELD from '@salesforce/schema/Implementation_Profile__c.Employees_work_in_the_following_states__c';
import CLIENT_BUSINESS_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_does_business_in_MA_NY_or_VA__c';
import EES_TRAVEL_INTERNATIONAL_FIELD from '@salesforce/schema/Implementation_Profile__c.Any_EEs_travel_internationally_for_work__c';
import CLIENT_TRACKING_PTO_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_interested_in_NSP_tracking_PTO__c';
import CLIENT_PROVIED_COPY_OF_POLICY_FIELD from '@salesforce/schema/Implementation_Profile__c.Gave_copy_of_PTO_sick_leave_other_policy__c';
import CLIENT_UTILIZING_TIMESTAR_FIELD from '@salesforce/schema/Implementation_Profile__c.Client_utilizing_Insperity_s_TimeStar__c';
import TIMEZONE_FIELD from '@salesforce/schema/Implementation_Profile__c.What_time_zone_do_EEs_work__c';
import USER_ENTRY_FIELD from '@salesforce/schema/Implementation_Profile__c.Who_will_enter_time_worked__c';
import PUNCH_IN_OUT_FIELD from '@salesforce/schema/Implementation_Profile__c.EEs_to_punch_in_out_or_use_timesheet__c';
import PREPOPULATE_TIMECARD_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_Prepop_Timecards_w_Stndrd_hrs__c';
import CLIENT_HOLIDAY_CALENDAR_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_Client_s_holiday_calendar__c';
import FORM_8973_FIELD from '@salesforce/schema/Implementation_Profile__c.Has_form_8973_been_discussed__c';
import ARBITRATION_AGREEMENT_FIELD from '@salesforce/schema/Implementation_Profile__c.Arbitration_Agreement_been_discussed__c';
import PTO_TRACK_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_Where_will_PTO_be_tracked__c';
import BUSINESS_MEETING_STATES_FIELD from '@salesforce/schema/Implementation_Profile__c.NSP_Business_Meeting_States__c';
import SELECT_PAYROLL_FIELD from '@salesforce/schema/Implementation_Profile__c.Select_all_payroll_needs_that_apply__c';
import * as labels from 'c/nsp_implementationLabels';

export default class Nsp_payrollIp extends LightningElement {
    label = labels;
    isLoading = true;
    @api
    recordId;
    newRecordId;
    @api
    objectApiName;
    payPeriodObjectName = IMPLEMENTATION_PAY_PERIOD.objectApiName;
    @api
    defaultRecordTypeId;
    @api empData;
    @api error;

    @track fields = {};
    @track
    lPayPeriodDetails = [];
    weeklyPay;
    biWeeklyPay;
    semiMonthlyPay;
    monthlyPay;
    showMonthlyPayProvideDetails = false;
    showSemiMonthlyPayProvideDetails = false;
    showSubaccountReason = false;
    showFLSAApprovedField = false;
    showEEsGarnishmentDetails = false;
    showEEsTaxLeviesDetails = false;
    showAllowanceAndExpenses = false;
    showPostTaxExpensefields = false;
    showOtherPostTaxDetails = false;
    allowances = [];
    expenses = [];
    timezones = [];
    businessMeetingStates = [];
    whySubaccountNeeded = [];
    showPayrollNeedDetails = false;
    stateCheckboxes = [];
    showBusinessStateField = false;
    showTimestarAIMSField = false;
    showAllTimestarField = false;
    show8973fields = false;
    firstTimeRendered = true;
    showLiveCheckDetailsField = false;
    showEEVisaDetailsForm = false;
    isMinisterTeachEmployee = false;
    hasAnyEEUnion = false;
    noExemptEEYes = false;
    showProviderAllowanceDetails = false;
    showOtherExpenseDetails = false;
    showNonInsperityEmplDetailsField = false;
    hasSCA_EE = false;
    hasSCA_approved = false;
    isFillingUnderEEO = false;
    isEEOAndFillingAddressProvided = false;
    isEEOAndFillingAddressNotProvided = false;
    isPastEmployeesGettingSeverance = false;
    anyEEsTravelInternationallyForWork = false;
    ministerTeacherCheckbox = [];
    unionEECheckbox = [];
    lBlueFieldscolor = ['']; //removed NSP_Provide_Tracking_details__c as part of DF-02091
    lFieldsWithRequestedValues = ['Gave_copy_of_PTO_sick_leave_other_policy__c', 'NSP_Client_s_holiday_calendar__c'];
    syncPayroll = false;
    childAnswerFields = {
                            Client_have_any_EEs_on_F1_or_J1_Visa_s__c : ['NSP_Name__c', 'NSP_Visa_Type__c'],
                            Do_any_EEs_have_garnishments__c: ['NSP_Name__c', 'NSP_Documents__c'],
                            Do_any_EEs_have_tax_levies__c: ['NSP_Name__c', 'NSP_Documents__c']
                        };

    renderedCallback() {
        if (this.firstTimeRendered && Object.keys(this.fields).length > 0) {
            let allColoredFields = [].concat(this.lFieldsWithRequestedValues);
            for (let field of allColoredFields) {
                this.handleRequestedColor(field);
                this.handleEmptyColor(field, this.fields[field]);
            }
            this.firstTimeRendered = false;
        }
    }

    //POST_TAX_DEDUCTION_EXPENSE_FIELD
    @wire(getRecord, {
        recordId: '$recordId', fields: [INSPERITY_PAY_PERIOD, WEEKLY_PAY_PERIOD, BIWEEKLY_PAY_PERIOD, SEMIMONTHLY_PAY_PERIOD, NON_EXEMPT_SEMI_MONTHLY_PAY_FREQUENCY, SEMIMONTHLY_STATE_LAW_FIELD, MONTHLY_PAY_PERIOD, MONTHLY_STATE_LAW_FIELD, IS_NEED_FOR_SUBACCOUNT_FIELD, WHY_SUBACCOUNT_NEEDED_FIELD, CLASSING_REQ_FIELD, WORK_WEEK_FIELD, HOLIDAY_WEEKEND_FIELD, EE_LIVE_CHECK_MAIL_FIELD, CLIENT_WORKFORCE_FIELD, NON_INSPERITY_CONTRACTORS_FIELD, CLIENT_EE_VISA_FIELD, CLIENT_COMMISSION_FIELD, FLSA_APPROVED_FIELD, CLIENT_MINOR_EE_FIELD, CLIENT_SEASONAL_EE_FIELD, CLIENT_MINISTERS_FIELD, CLIENT_UNION_FIELD, CLIENT_FEDERAL_FIELD, CLIENT_EEO_NUMBER_FIELD, EE_GARNISHMENT_FIELD, EE_TAX_FIELD, CLIENT_EXPENSE_ALLOWANCE_FIELD, ALLOWANCE_FIELD, EXPENSE_FIELD, CLIENT_TAX_DEDUCTION_FIELD, CLIENT_PAYROLL_NEED_FIELD, STATE_FIELD, CLIENT_BUSINESS_FIELD, EES_TRAVEL_INTERNATIONAL_FIELD, CLIENT_TRACKING_PTO_FIELD, CLIENT_PROVIED_COPY_OF_POLICY_FIELD, CLIENT_UTILIZING_TIMESTAR_FIELD, TIMEZONE_FIELD, CLIENT_JOB_COSTING_FIELD, USER_ENTRY_FIELD, PUNCH_IN_OUT_FIELD, PREPOPULATE_TIMECARD_FIELD, CLIENT_HOLIDAY_CALENDAR_FIELD, FORM_8973_FIELD, ARBITRATION_AGREEMENT_FIELD,
            PTO_TRACK_FIELD, BUSINESS_MEETING_STATES_FIELD, SELECT_PAYROLL_FIELD]
    })
    getImplementationProfileDetails(value) {
        this.implementationProfileDetails = value;
        const { data, error } = value;
        if (data) {
            let fields = data.fields;
            let oImpProfileFields = {};
            for (let field in fields) {
                oImpProfileFields[field] = fields[field].value;
                this.showDynamicFields(field, fields[field].value);
            }
            this.updateCheckboxFields(oImpProfileFields);
            this.fields = oImpProfileFields;
        } else if (error) {
            this.error = error;
        }
    }

    @wire(getPayPeriods, { recordId: "$recordId" })
    getAllPayPeriods({ data, error }) {
        if (data) {
            if (data.length > 0) {
                let lPayPeriodDetails = JSON.parse(JSON.stringify(data));
                lPayPeriodDetails.forEach((oPayPeriod) => {
                    if (oPayPeriod.Is_arrearage_7_days__c === this.label.YES_CONSTANT) {
                        oPayPeriod.ifArrerageIsGreater = true;
                        oPayPeriod.ifArrerageIsSmaller = false;
                    } else if (oPayPeriod.Is_arrearage_7_days__c === this.label.NO_CONSTANT) {
                        oPayPeriod.ifArrerageIsGreater = false;
                        oPayPeriod.ifArrerageIsSmaller = true;
                    }
                });
                this.lPayPeriodDetails = lPayPeriodDetails;
            } else {
                this.lPayPeriodDetails = [{
                    Id: ''
                }];
            }
        } else if (error) {
            this.error = error;
           // this.showToast(this.label.errorTitle, error.body.message, 'error');
        }
    }

    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: WEEKLY_PAY_PERIOD })
    payPeriodValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: NON_EXEMPT_SEMI_MONTHLY_PAY_FREQUENCY })
    nonExemptEESemiMonthlyValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: WORK_WEEK_FIELD })
    workWeekValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: HOLIDAY_WEEKEND_FIELD })
    holidayOrWeekendValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: EE_LIVE_CHECK_MAIL_FIELD })
    eeLiveCheckMailValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: ALLOWANCE_FIELD })
    allowancesValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: EXPENSE_FIELD })
    expensesValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: SCA_EE_FIELD })
    scaEEOptions;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_PROVIED_COPY_OF_POLICY_FIELD })
    clientGaveCopyOfPoliciesValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: TIMEZONE_FIELD })
    timezoneValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: USER_ENTRY_FIELD })
    userEntringValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: PUNCH_IN_OUT_FIELD })
    punchInOutValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_HOLIDAY_CALENDAR_FIELD })
    clientHolidayCalendarQuestion;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: PTO_TRACK_FIELD })
    ptoTrackValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: BUSINESS_MEETING_STATES_FIELD })
    businessMeetingStatesValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: WHY_SUBACCOUNT_NEEDED_FIELD })
    whyIsSubaccountNeededValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_MINISTERS_CHECK_ALL_FIELD })
    checkAllThatApplyMinistersTeachers;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: CLIENT_UNION_EE_FIELD })
    checkAllThatApplyUnionEE;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: GARNISH_DOC_FIELD })
    garnishDocumentValues;
    @wire(getPicklistValues, { recordTypeId: '$defaultRecordTypeId', fieldApiName: STATE_FIELD })
    formStateCheckGroupValues(picklistValues) {
        if (picklistValues.data) {
            // label, value, checked
            let values = picklistValues.data.values;
            let fieldValue = this.fields.Employees_work_in_the_following_states__c || '';
            let fields = fieldValue.split(';');
            let stateCheckboxes = values.map((state) => {
                return {
                    label: state.label,
                    value: state.value,
                    checked: fields.includes(state.value)
                }
            });
            this.stateCheckboxes = stateCheckboxes;
        } else if (picklistValues.error) {
            this.error = JSON.stringify(picklistValues.error);
        }
    }

    updateCheckboxFields(fields) {
        if (!fields) {
            return;
        }
        if (fields[INSPERITY_PAY_PERIOD.fieldApiName]) {
            const { weeklyPicklistValue, biWeeklyPicklistValue, semiMonthlyPicklistValue, monthlyPicklistValue } = this.label;
            let fieldValues = fields[INSPERITY_PAY_PERIOD.fieldApiName].split(';');

            this.weeklyPay = fieldValues.includes(weeklyPicklistValue);
            this.biWeeklyPay = fieldValues.includes(biWeeklyPicklistValue);
            this.semiMonthlyPay = fieldValues.includes(semiMonthlyPicklistValue);
            this.monthlyPay = fieldValues.includes(monthlyPicklistValue);
        }

        let timeZoneFieldValue = fields[TIMEZONE_FIELD.fieldApiName] || '';
        this.timezones = timeZoneFieldValue.split(';');

        let allowanceFieldValue = fields[ALLOWANCE_FIELD.fieldApiName] || '';
        this.allowances = allowanceFieldValue.split(';');

        let expenseFieldValue = fields[EXPENSE_FIELD.fieldApiName] || '';
        this.expenses = expenseFieldValue.split(';');

        if (this.stateCheckboxes.length > 0) {
            let fieldValue = fields[STATE_FIELD.fieldApiName] || '';
            let fieldValues = fieldValue.split(';');
            this.stateCheckboxes.forEach(row => {
                row.checked = fieldValues.includes(row.value);
            });
        }

        let businessMeetingStateFieldValue = fields[BUSINESS_MEETING_STATES_FIELD.fieldApiName] || '';
        this.businessMeetingStates = businessMeetingStateFieldValue.split(';');

        let whySubaccountFieldValue = fields[WHY_SUBACCOUNT_NEEDED_FIELD.fieldApiName] || '';
        this.whySubaccountNeeded = whySubaccountFieldValue.split(';');

        const ministerTeacherCheckboxAllValues = fields[CLIENT_MINISTERS_CHECK_ALL_FIELD.fieldApiName] || '';
        this.ministerTeacherCheckbox = ministerTeacherCheckboxAllValues.split(';');

        const unionEECheckboxAllValues = fields[CLIENT_UNION_EE_FIELD.fieldApiName] || '';
        this.unionEECheckbox = unionEECheckboxAllValues.split(';');
    }

    //Pay Period/Pay Frequency
    handlePPChange(event) {
        let index = event.target.dataset.index;
        let field = event.target.fieldName;
        let value = event.detail.value;
        if (this.lPayPeriodDetails) {
            this.lPayPeriodDetails[index][field] = value;
            this.showPayPeriodDynamicFields(field, value, index);
        }
    }

    showPayPeriodDynamicFields(field, value, index) {
        if (field === 'Is_arrearage_7_days__c') {
            if (value === this.label.YES_CONSTANT) {
                this.lPayPeriodDetails[index].ifArrerageIsGreater = true;
                this.lPayPeriodDetails[index].ifArrerageIsSmaller = false;
                this.lPayPeriodDetails[index].Does_the_client_have_prior_wages__c = null;
                this.lPayPeriodDetails[index].Final_pay_period_prior_to_Insperity__c = null;
                this.lPayPeriodDetails[index].Final_pay_date_prior_to_Insperity__c = null;
            } else {
                this.lPayPeriodDetails[index].ifArrerageIsGreater = false;
                this.lPayPeriodDetails[index].ifArrerageIsSmaller = true;
                this.lPayPeriodDetails[index].Have_credit_services_approved__c = null;
                this.lPayPeriodDetails[index].Provide_credit_services_detaIls__c = null;
                this.lPayPeriodDetails[index].Does_arrearage_comply_with_state_laws__c = null;
                this.lPayPeriodDetails[index].Provide_arrearage_details__c = null;
                this.lPayPeriodDetails[index].Does_the_client_have_prior_wages__c = null;
                this.lPayPeriodDetails[index].Final_pay_period_prior_to_Insperity__c = null;
                this.lPayPeriodDetails[index].Final_pay_date_prior_to_Insperity__c = null;
            }
            return;
        }
        if (field === 'Have_credit_services_approved__c') {
            this.lPayPeriodDetails[index].haveCreditServicesApproved = value === this.label.YES_CONSTANT;
        }
        if (field === 'Does_arrearage_comply_with_state_laws__c') {
            this.lPayPeriodDetails[index].complyWithStateLaw = value === this.label.YES_CONSTANT;
        }
        if (field === 'Does_the_client_have_prior_wages__c') {
            this.lPayPeriodDetails[index].havePriorWages = value === this.label.YES_CONSTANT;
        }
    }

    handleAddMoreClick() {
        this.addMorePayPeriod();
    }

    addMorePayPeriod(config) {
        this.lPayPeriodDetails.push({
            Id: "",
            ...config
        });
    }

    deletePayPeriodRow(event) {
        let index = event.target.dataset.index;
        let payPeriodId = event.target.dataset.id;
        if (this.recordId && payPeriodId) {
            deleteRecord(payPeriodId)
                .then(() => {
                    // DELETED
                    this.removePayPeriodRecordByIndex(index);
                }).catch((error) => {
                    this.error = error;
                })
        } else {
            this.removePayPeriodRecordByIndex(index);
        }
    }

    removePayPeriodRecordByIndex(index) {
        if (this.lPayPeriodDetails.length === 1) {
            this.lPayPeriodDetails = [];
            setTimeout(() => {
                this.lPayPeriodDetails = [{
                    Id: ''
                }];
            }, 0);
            return;
        }
        this.lPayPeriodDetails.splice(index, 1);
    }

    // RECORD EDIT FORM
    handleLoad() {
        this.isLoading = false;
        this.fixLabelColor();
    }

    fixLabelColor() {
        const inputFields = this.template.querySelectorAll('.ipProfile lightning-input-field');
        inputFields.forEach(field => {
            if (this.lBlueFieldscolor.includes(field.fieldName)) {
                this.handleEmptyColor(field.fieldName, field.value);
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
        this.handleEmptyColor(field, value);
    }

    handleCheckboxChange(event) {
        let value = event.detail.value;
        let field = event.target.name;
        this.fields[field] = value.join(';');
        this.showDynamicFields(field, this.fields[field]);
    }

    handleCustomCheckboxChange({ detail, target }) {
        let checked = detail.checked;
        let field = target.name;
        let value = target.value;
        if (checked) {
            if (this.fields[field] && this.fields[field] != '') {
                let values = this.fields[field].split(';');
                values.push(value);
                this.fields[field] = values.join(';');
            } else {
                this.fields[field] = value;
            }

            if (target.name == 'Insperity_pay_frequency__c') {
                this.addMorePayPeriod({ Frequency__c: value });
            }
        } else {
            let values = this.fields[field].split(';');
            let indexOf = values.indexOf(value);
            values.splice(indexOf, 1);
            this.fields[field] = values.join(';');
        }
        this.showDynamicFields(field, this.fields[field]);
    }

    showDynamicFields(field, value) {
        try {
            /* Added as part STY-03012 */
            if (field === 'Allowances__c') {
                if (value === this.label.OTHER_CONSTANT) {
                    this.showProviderAllowanceDetails = true;
                } else {
                    this.showProviderAllowanceDetails = false;
                    this.fields.Provide_allowance_details__c = null;
                }
                return;
            }
            if (field === 'Expenses__c') {
                if (value && value.split(';').includes(this.label.OTHER_CONSTANT)) {
                    this.showOtherExpenseDetails = true;
                    this.showOtherPostTaxDetails = true;
                } else {
                    this.showOtherExpenseDetails = false;
                    this.showOtherPostTaxDetails = false;
                    this.fields.Other_expense_details__c = null;
                    this.fields.NSP_How_will_client_reimburse_expenses__c = null;
                    this.fields.Provide_expense_details__c = null;
                }
                return;
            }
            if (field === 'Insperity_pay_frequency__c') {
                value = value || '';
                let values = value.split(';');
                if (values.includes(this.label.weeklyPicklistValue)) {
                    this.weeklyPay = true;
                } else {
                    this.weeklyPay = false;
                    this.fields.NSP_Weekly_Pay_Period__c = null;
                }
                if (values.includes(this.label.biWeeklyPicklistValue)) {
                    this.biWeeklyPay = true;
                } else {
                    this.biWeeklyPay = false;
                    this.fields.NSP_Biweekly_Pay_Period__c = null;
                }
                if (values.includes(this.label.semiMonthlyPicklistValue)) {
                    this.semiMonthlyPay = true;
                } else {
                    this.semiMonthlyPay = false;
                    this.fields.NSP_Semimonthly_Pay_Period__c = null;
                    this.fields.Non_exempt_EEs_on_semi_monthly_pay_freq__c = null;
                    this.fields.Semi_monthly_pay_freq_comply_w_state_law__c = null;
                }
                if (values.includes(this.label.monthlyPicklistValue)) {
                    this.monthlyPay = true;
                } else {
                    this.monthlyPay = false;
                    this.fields.NSP_Monthly_Pay_Period__c = null;
                    this.fields.Monthly_pay_freq_comply_w_state_laws__c = null;
                }
                return;
            }
            if (field === 'Monthly_pay_freq_comply_w_state_laws__c') {
                if (value === this.label.NO_CONSTANT) {
                    this.showMonthlyPayProvideDetails = true;
                } else {
                    this.showMonthlyPayProvideDetails = false;
                    this.fields.NSP_Provide_Monthly_pay_frequency_detail__c = null;
                }
                return;
            }
            if (field === 'Semi_monthly_pay_freq_comply_w_state_law__c') {
                if (value === this.label.NO_CONSTANT) {
                    this.showSemiMonthlyPayProvideDetails = true;
                } else {
                    this.showSemiMonthlyPayProvideDetails = false;
                    this.fields.Semi_monthly_pay_st_law_provide_details__c = null;
                }
                return;
            }
            if (field === 'Is_there_a_need_for_a_subaccount__c') {
                if (value === this.label.YES_CONSTANT) {
                    this.showSubaccountReason = true;
                    this.dispatchEvent(new CustomEvent('selected', { detail: { 'field': field, 'value': true } }));
                } else {
                    this.showSubaccountReason = false;
                    this.dispatchEvent(new CustomEvent('selected', { detail: { 'field': field, 'value': false } }));
                    this.whySubaccountNeeded = [];
                    this.fields.Why_is_subaccount_needed__c = null;
                    this.fields.classing_req_a_new_download_for_Subacc__c = null;
                }
            }
            if (field === 'Client_have_any_Commission_only_EEs__c') {
                if (value === this.label.YES_CONSTANT) {
                    this.showFLSAApprovedField = true;
                } else {
                    this.showFLSAApprovedField = false;
                    this.fields.Has_FLSA_team_approved__c = null;
                }
                return;
            }
            if (field === 'Do_any_EEs_have_garnishments__c') {
                if (value === this.label.YES_CONSTANT) {
                    this.showEEsGarnishmentDetails = true;
                } else {
                    this.showEEsGarnishmentDetails = false;
                    this.fields.NSP_EEs_garnishments_details__c = null;
                }
                return;
            }
            if (field === 'Do_any_EEs_have_tax_levies__c') {
                if (value === this.label.YES_CONSTANT) {
                    this.showEEsTaxLeviesDetails = true;
                } else {
                    this.showEEsTaxLeviesDetails = false;
                    this.fields.NSP_Provide_EEs_tax_levies_details__c = null;
                }
                return;
            }
            if (field === 'Has_expenses_allowances_through_payroll__c') {
                if (value === this.label.YES_CONSTANT) {
                    this.showAllowanceAndExpenses = true;
                } else {
                    this.showAllowanceAndExpenses = false;
                    this.fields.Allowances__c = '';
                    this.fields.Expenses__c = '';
                    this.fields.Provide_allowance_details__c = null;
                    this.fields.NSP_How_will_client_reimburse_expenses__c = null;
                    this.fields.Provide_expense_details__c = null;
                    this.fields.Other_expense_details__c = null;
                }
                return;
            }
            if (field === 'Client_has_any_post_tax_deductions__c') {
                this.showPostTaxExpensefields = (value === this.label.YES_CONSTANT);
                return;
            }

            if (field === 'Client_has_any_special_payroll_needs__c') {
                if (value === this.label.YES_CONSTANT) {
                    this.showPayrollNeedDetails = true;
                } else {
                    this.showPayrollNeedDetails = false;
                    this.fields.Other_payroll_details__c = null;
                }
                return;
            }
            if (field === 'Client_does_business_in_MA_NY_or_VA__c') {
                if (value === this.label.YES_CONSTANT) {
                    this.showBusinessStateField = true;
                } else {
                    this.showBusinessStateField = false;
                    this.businessMeetingStates = [];
                    this.fields.NSP_Business_Meeting_States__c = null;
                }
                return;
            }
            if (field === 'Client_interested_in_NSP_tracking_PTO__c') {
                if (value === this.label.YES_CONSTANT) {
                    this.showTimestarAIMSField = true;
                } else {
                    this.showTimestarAIMSField = false;
                    this.fields.NSP_Where_will_PTO_be_tracked__c = null;
                }
                return;
            }
            if (field === 'Client_utilizing_Insperity_s_TimeStar__c') {
                if (value === this.label.YES_CONSTANT) {
                    this.showAllTimestarField = true;
                } else {
                    this.showAllTimestarField = false;
                    // SET ALL VALUES TO BE BLANK
                    this.fields.What_time_zone_do_EEs_work__c = null;
                    this.timezones = [];
                    this.fields.Who_will_enter_time_worked__c = null;
                    this.fields.EEs_to_punch_in_out_or_use_timesheet__c = null;
                    this.fields.NSP_Prepop_Timecards_w_Stndrd_hrs__c = null;
                    this.fields.NSP_Client_s_holiday_calendar__c = null;
                }
                return;
            }
            if (field === 'Has_form_8973_been_discussed__c') {
                if (value === this.label.YES_CONSTANT || value === this.label.NO_CONSTANT) {
                    this.show8973fields = true;
                } else {
                    this.show8973fields = false;
                    this.fields.Form_8973_Contact__c = null;
                    this.fields.Contact_Information__c = null;
                }
                return;
            }
            if (field === 'Where_to_mail_EE__c') {
                this.showLiveCheckDetailsField = (value === 'Multiple locations');
                return;
            }
            if (field === 'NSP_non_Insperity_paid_emps_contractors__c') {
                this.showNonInsperityEmplDetailsField = (value === this.label.YES_CONSTANT);
                return;
            }
            if (field === 'Client_have_any_EEs_on_F1_or_J1_Visa_s__c') {
                this.showEEVisaDetailsForm = (value === this.label.YES_CONSTANT);
                return;
            }
            if (field === 'Does_client_employ_ministers_or_teachers__c') {
                this.isMinisterTeachEmployee = (value === this.label.YES_CONSTANT);
                return;
            }
            if (field === 'Does_the_client_have_any_union_EEs__c') {
                this.hasAnyEEUnion = (value === this.label.YES_CONSTANT);
                return;
            }
            if (field === 'Non_exempt_EEs_on_semi_monthly_pay_freq__c') {
                this.noExemptEEYes = (value === this.label.YES_CONSTANT);
                return;
            }
            if (field === 'Is_the_client_a_federal_contractor__c') {
                this.hasSCA_EE = (value === this.label.YES_CONSTANT);
                return;
            }
            if (field === 'Client_has_Service_Contract_Act_SCA_EEs__c') {
                this.hasSCA_approved = (value === this.label.YES_CONSTANT);
                return;
            }
            if (field === 'Client_have_EEO_filing_under__c') {
                this.isFillingUnderEEO = (value === this.label.YES_CONSTANT);
                return;
            }
            if (field === 'Can_client_provide_EEO_filing_address__c') {
                this.isEEOAndFillingAddressProvided = (value === this.label.YES_CONSTANT);
                this.isEEOAndFillingAddressNotProvided = (value === this.label.No);
                return;
            }
            if (field === 'Past_employees_crntly_getting_severance__c') {
                this.isPastEmployeesGettingSeverance = (value === this.label.YES_CONSTANT);
            }
            if (field === 'Any_EEs_travel_internationally_for_work__c') {
                this.anyEEsTravelInternationallyForWork = (value === this.label.YES_CONSTANT);
            }
            if (field === 'Employees_work_in_the_following_states__c') {
                value = value || '';
                let values = value.split(';');
                if (values.includes('CA')) {
                    this.weeklyPay = true;
                    this.dispatchEvent(new CustomEvent('selected', { detail: { 'field': field, 'value': true } }));
                } else {
                    this.weeklyPay = false;
                    this.dispatchEvent(new CustomEvent('selected', { detail: { 'field': field, 'value': false } }));
                }
            }
            if (field === 'Select_all_payroll_needs_that_apply__c') {
                if (value == null) {
                    this.syncPayroll = true;
                }
            }
        } catch (error) {
            this.error = error;
        }
    }

    handleSyncChange(event) {
        let field = event.currentTarget.dataset.id;
        let value = event.target.value;
        if (field === 'PEO_Name__c') {
            this.dispatchEvent(new CustomEvent('syncfields', { detail: { field, value } }));
        }
        if (field === 'Insperity_benefits_effective_date__c') {
            this.dispatchEvent(new CustomEvent('syncfields', { detail: { field, value } }));
        }
        if (field === 'Select_all_payroll_needs_that_apply__c') {
            if (this.syncPayroll && (!value.includes('Other') || !value.includes('Billing Groups'))) {
                this.dispatchEvent(new CustomEvent('syncfields', { detail: { field, value } }));
            }
        }
    }

    @api handleSync(event) {
        if (event.detail?.field === 'Benefit_effective_date_carry_from_tab_4__c') {
            this.fields.Insperity_benefits_effective_date__c = event.detail?.value;
        }
    }

    get syncFields() {
        if (this.fields?.Insperity_benefits_effective_date__c) {
            const temp = this.template.querySelector('lightning-input-field[data-id="Insperity_benefits_effective_date__c"]').value;
            temp.value = this.fields.Insperity_benefits_effective_date__c;
        }
    }

    handleRequestedColor(field) {
        if (this.lFieldsWithRequestedValues.includes(field)) {
            let value = this.fields[field] || '';
            let eField = this.template.querySelector(`.${field}`);
            if (eField) {
                if (value.includes(this.label.requested)) {
                    eField.classList.add('requestedField');
                } else {
                    eField.classList.remove('requestedField');
                }
            }
        }
    }

    handleEmptyColor(field, value) {
        if (this.lBlueFieldscolor.includes(field)) {
            let eField = this.template.querySelector(`.${field}`);
            if (eField) {
                if (value) {
                    eField.classList.remove('emptyField');
                } else {
                    eField.classList.add('emptyField');
                }
            }
        }
    }

    @api
    async saveForm(newRecordId) {
        this.isLoading = true;
        const inputFields = this.template.querySelectorAll('.ipProfile lightning-input-field');
        let fields = JSON.parse(JSON.stringify(this.fields));
        fields['Id'] = this.recordId || newRecordId;
        inputFields.forEach(field => {
            fields[field.fieldName] = field.value;
        });
        fields[BENEFITS_EFFECTIVE_DATE_FIELD.fieldApiName] = fields['Insperity_benefits_effective_date__c'];
        let lPayPeriods = this.lPayPeriodDetails.filter((row) => {
            return this.checkIfPayPeriodHasValues(row);
        }).map(row => {
            row.Id = row.Id || null;
            return row;
        });

        const { allEmployeeRecords, parentFieldNames, fieldSpecificRecords } = this.getEmployeeRecords();
        this.updateEmpDetailsOnIPRecord(fields, fieldSpecificRecords);

        await savePayrollDetails({
            'sPayrollWrapper': JSON.stringify({
                'oIProfile': fields,
                'lPayPeriods': lPayPeriods,
                'empRecords': allEmployeeRecords,
                'parentFieldNames': parentFieldNames
            })
        }).then((response) => {
            this.showToast(this.label.successTitle, this.label.implementationSavedMessage, 'success');
            this.dispatchEvent(new CustomEvent('success', { detail: { "recordId": response.oIProfile.Id } }));
            let lPayPeriodDetails = response.lPayPeriods;
            lPayPeriodDetails.forEach((oPayPeriod) => {
                if (oPayPeriod.Is_arrearage_7_days__c === this.label.YES_CONSTANT) {
                    oPayPeriod.ifArrerageIsGreater = true;
                    oPayPeriod.ifArrerageIsSmaller = false;
                } else if (oPayPeriod.Is_arrearage_7_days__c === this.label.NO_CONSTANT) {
                    oPayPeriod.ifArrerageIsGreater = false;
                    oPayPeriod.ifArrerageIsSmaller = true;
                }
            });
            this.lPayPeriodDetails = lPayPeriodDetails;
            refreshApex(this.implementationProfileDetails);
            this.isLoading = false;
        }).catch((error) => {
            this.isLoading = false;
            this.showToast(this.label.errorTitle, error.body.message, 'error');
            this.dispatchEvent(new CustomEvent('error', { detail: { "error": error.body.message } }));
        });
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

    updateEmpDetailsOnIPRecord(ipRecord, fieldSpecificRecords) {
        this.updateVisaDetails(
            fieldSpecificRecords.Client_have_any_EEs_on_F1_or_J1_Visa_s__c,
            this.childAnswerFields.Client_have_any_EEs_on_F1_or_J1_Visa_s__c,
            ipRecord
        );
        this.updateEEGarnishments(
            fieldSpecificRecords.Do_any_EEs_have_garnishments__c,
            this.childAnswerFields.Do_any_EEs_have_garnishments__c,
            ipRecord
        );
        this.updateTaxLevies(
            fieldSpecificRecords.Do_any_EEs_have_tax_levies__c,
            this.childAnswerFields.Do_any_EEs_have_tax_levies__c,
            ipRecord
        );
    }

    updateVisaDetails(childRecords, fields, ipRecord){
        if(childRecords){
            ipRecord.NSP_EE_Name__c = this.getCSVFromObjectList(childRecords, fields[0]);
            //ipRecord.EE_Visa_Type__c = this.getCSVFromObjectList(childRecords, fields[1]);
        }
    }

    updateEEGarnishments(childRecords, fields, ipRecord){
        if(childRecords){
            const onlyEmpRequestedRec = childRecords.filter(rec => this.label.employeeDataRequested.toLowerCase() == rec[fields[1]].toLowerCase());

            ipRecord.NSP_Employee_Names_List_garnishments__c = this.getCSVFromObjectList(onlyEmpRequestedRec, fields[0]);
            ipRecord.NSP_Documents_garnishments__c = childRecords.map(rec => `${rec[fields[0]]}~${rec[fields[1]]}`).join(',');
        }
    }

    updateTaxLevies(childRecords, fields, ipRecord){
        if(childRecords){
            const onlyEmpRequestedRec = childRecords.filter(rec => this.label.employeeDataRequested.toLowerCase() == rec[fields[1]].toLowerCase());
            ipRecord.NSP_List_Employee_Names_Levies__c = this.getCSVFromObjectList(onlyEmpRequestedRec, fields[0]);
        }
    }

    getCSVFromObjectList(arr, fieldName){
        return arr.map(obj => obj[fieldName]).join(',');
    }

    checkIfPayPeriodHasValues(record) {
        for (let field in record) {
            if (record[field]) {
                return true;
            }
        }
        return false;
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

    get isMinisterTeachEmployeeFlag() {
        return this.isMinisterTeachEmployee && this.checkAllThatApplyMinistersTeachers.data && this.checkAllThatApplyMinistersTeachers.data.values.length;
    }

    get hasAnyEEUnionFalg() {
        return this.hasAnyEEUnion && this.checkAllThatApplyUnionEE.data && this.checkAllThatApplyUnionEE.data.values.length;
    }
}