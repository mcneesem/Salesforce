import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { FIELDS } from './fields';
import { COLUMNS } from './columns';
import { DYNAMIC_FIELDS, REDUCTION_FIELDS, GROWTH_TYPE } from './fieldsConfig';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

const TODAY = new Date();
const CURRENT_QUARTER = 'Q' + Math.floor((TODAY.getMonth() + 3) / 3) + '/' + TODAY.getFullYear();

export default class AccountGroupGrowthForeCast extends LightningElement {
    @api recordId;
    @track accountGroup;
    @track data = [];
    @track wiredAccountGroup;
    @track draftValues = [];
    isLoading = true;

    @wire(getRecord, { recordId: '$recordId', fields: Object.values(FIELDS) })
    accountGroupRecord(result) {
        this.wiredAccountGroup = result;
        const { data, error } = result;
        if (data) {
            this.accountGroup = data;
            this.error = undefined;
            this.prepareAccountGroupData();
            this.isLoading = false;
        } else if (error) {
            this.error = error;
            this.accountGroup = undefined;
            this.isLoading = false;
        }
    }


    getAcquisitionData() {
        let acquisition = {
            account: getFieldValue(this.accountGroup, FIELDS.ACCOUNT_FIELD),
            currentMonth: CURRENT_QUARTER,
            GrowthType: this.growthType.acquisition,
            Current_Quarter: getFieldValue(this.accountGroup, FIELDS.ACQUISITION_CURRENT_Q_FIELD),
            Current_Quarter1: getFieldValue(this.accountGroup, FIELDS.ACQUISITION_CURRENT_Q1_FIELD),
            Current_Quarter2: getFieldValue(this.accountGroup, FIELDS.ACQUISITION_CURRENT_Q2_FIELD),
            Current_Quarter3: getFieldValue(this.accountGroup, FIELDS.ACQUISITION_CURRENT_Q3_FIELD),
            total: getFieldValue(this.accountGroup, FIELDS.ACQUISITION_TOTAL_FIELD),
            editable: true,
        };
        return acquisition;
    }

    getReductionData() {
        let reduction = {
            account: getFieldValue(this.accountGroup, FIELDS.ACCOUNT_FIELD),
            currentMonth: CURRENT_QUARTER,
            GrowthType: this.growthType.reduction,
            Current_Quarter: getFieldValue(this.accountGroup, FIELDS.REDUCTION_CURRENT_Q_FIELD),
            Current_Quarter1: getFieldValue(this.accountGroup, FIELDS.REDUCTION_CURRENT_Q1_FIELD),
            Current_Quarter2: getFieldValue(this.accountGroup, FIELDS.REDUCTION_CURRENT_Q2_FIELD),
            Current_Quarter3: getFieldValue(this.accountGroup, FIELDS.REDUCTION_CURRENT_Q3_FIELD),
            total: getFieldValue(this.accountGroup, FIELDS.REDUCTION_TOTAL_FIELD),
            textColor: "slds-text-color_destructive",
            editable: true,
        };
        return reduction;
    }

    getOrganicData() {
        let organic = {
            account: getFieldValue(this.accountGroup, FIELDS.ACCOUNT_FIELD),
            currentMonth: CURRENT_QUARTER,
            GrowthType: this.growthType.organic,
            Current_Quarter: getFieldValue(this.accountGroup, FIELDS.ORG_CURRENT_Q_FIELD),
            Current_Quarter1: getFieldValue(this.accountGroup, FIELDS.ORGANIC_CURRENT_Q1_FIELD),
            Current_Quarter2: getFieldValue(this.accountGroup, FIELDS.ORGANIC_CURRENT_Q2_FIELD),
            Current_Quarter3: getFieldValue(this.accountGroup, FIELDS.ORGANIC_CURRENT_Q3_FIELD),
            total: getFieldValue(this.accountGroup, FIELDS.ORGANIC_TOTAL_FIELD),
            editable: true,
        };
        return organic;
    }

    //Prepare Account Group Data table structure
    prepareAccountGroupData() {
        const acquisition = this.getAcquisitionData();
        const reduction = this.getReductionData();
        const organic = this.getOrganicData();

        let total = {
            GrowthType: this.growthType.total,
            total: getFieldValue(this.accountGroup, FIELDS.TOTAL_FIELD),
            editable: false,
        };
        this.data = [acquisition, organic, reduction, total];
    }

    get columns() {
        return COLUMNS;
    }

    //Save the data of Account Group 
    handleSave() {
        this.isLoading = true;
        try {

            let fields = this.prepareFieldsToUpdate(this.dataTable.draftValues);

            this.updateAccountGroup(fields);

        } catch (error) {
            this.showToast('Error updating record', error.body.message, 'error');
            this.isLoading = false;
        }
    }

    prepareFieldsToUpdate(draftValues) {
        let fields = {};
        draftValues.forEach((draftValue) => {
            let config;
            let growthType = draftValue['GrowthType'];
            if (growthType) {
                config = this.dynamicFields[growthType];
            }
            Object.keys(draftValue).forEach((fieldName) => {
                if ('GrowthType' != fieldName) {
                    if (config) {
                        fields[config[fieldName]] = draftValue[fieldName];
                    }
                }
            })
        });

        this.reductionFields.forEach(reductionField => {
            if (fields[reductionField]) {
                fields[reductionField] = fields[reductionField] && fields[reductionField] > 0 ? fields[reductionField] * (-1) : fields[reductionField];
            }
        })

        return fields;
    }

    //Update Account Group Fields with Updated Values
    async updateAccountGroup(fields) {

        fields['Id'] = this.recordId;
        fields[FIELDS.PAST_QUARTER_FIELD.fieldApiName] = CURRENT_QUARTER;
        fields[FIELDS.PAST_QUARTER_DATE_FIELD.fieldApiName] = this.currentDate;

        await updateRecord({ fields })
            .then(() => {
                this.showToast('Success', 'Account Group has been updated successfully', 'success');
                this.dataTable.draftValues = [];
                this.isLoading = false;
                return refreshApex(this.wiredAccountGroup);
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error updating record', error.body.message, 'error');
            });
    }

    //Show Toast when Success and Error MessagesAndAlerts
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    //on updating the column mark cell as red color
    handleCellChange({ detail }) {
        const [draftValues] = detail.draftValues;
        Object.keys(draftValues).forEach((fieldName) => {
            if ('GrowthType' == fieldName) {
                this.data = this.data.map(record => {
                    let textColor;
                    if (record.GrowthType == 'Reduction') {
                        textColor = 'slds-text-color_destructive';
                    }
                    return { ...record, textColor }
                });
            }
        })
    }

    get reductionFields() {
        return REDUCTION_FIELDS;
    }

    get dynamicFields() {
        return DYNAMIC_FIELDS;
    }

    get growthType() {
        return GROWTH_TYPE;
    }

    //handle Cancel and Refresh the data
    async handleCancel() {
        if (this.dataTable.draftValues.length > 0) {
            this.dataTable.draftValues = [];
        }
        await refreshApex(this.wiredAccountGroup);
    }

    get enableFooter() {
        return this.dataTable && this.dataTable.draftValues && this.dataTable.draftValues.length;
    }

    get dataTable() {
        return this.template.querySelector('lightning-datatable');
    }

    get currentDate(){
        let date = new Date()
        let day = date.getDate();
        let month = date.getMonth() + 1;
        let year = date.getFullYear();
        return `${year}-${month}-${day}`;
    }

}