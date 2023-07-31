import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { BUTTON_CONFIG, CONF_MESSAGE } from "./constants";
import { getRecord } from "lightning/uiRecordApi";
import { updateRecord } from "lightning/uiRecordApi";
import CASE_STATUS from "@salesforce/schema/Case.Status";
import CASE_CONFIDENTIAL_ELIGIBLE from "@salesforce/schema/Case.NSP_Show_Confidential_Checkbox__c";
import CASE_CONFIDENTIAL_POPUP from "@salesforce/schema/Case.NSP_Show_Confidential_PopUp__c";
import CONFIDENTIAL_CHECKBOX from "@salesforce/schema/Case.NSP_Confidential__c";
import CASE_ID from "@salesforce/schema/Case.Id";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class Nsp_showConfidentialPopUp extends NavigationMixin(LightningElement) {
    @api recordId;
    @api isShowPopUp = false;
    @api caseConfidentialCheckbox = false;

    @wire(getRecord, { recordId: "$recordId", fields: [CASE_STATUS, CASE_CONFIDENTIAL_ELIGIBLE, CASE_CONFIDENTIAL_POPUP, CONFIDENTIAL_CHECKBOX] })
    checkWhetherToShowConfidentialPopu(value) {
        const { error, data } = value;
        if (data) {
            this.caseConfidentialCheckbox = data.fields.NSP_Confidential__c.value;
            if (data.fields.Status.value === "Closed" && data.fields.NSP_Show_Confidential_Checkbox__c.value === true && data.fields.NSP_Show_Confidential_PopUp__c.value === false && data.fields.NSP_Confidential__c.value === false) {
                this.isShowPopUp = true;
                this.error = null;
            } else if (error) {
                this.data = null;
                this.error = error;
            }
        }
    }

    handleButtonClick(event) {
        if (event.detail === "Yes" && this.caseConfidentialCheckbox === false) {
            this.handleConfidentialCaseUpdate(true);
        }
        if (event.detail === "No") {
            this.handleConfidentialCaseUpdate(false);
        }
    }

    handleConfidentialCaseUpdate(isConfidential) {
        this.isShowPopUp = false;
        const fields = {};
        fields[CONFIDENTIAL_CHECKBOX.fieldApiName] = isConfidential;
        fields[CASE_CONFIDENTIAL_POPUP.fieldApiName] = true;
        fields[CASE_ID.fieldApiName] = this.recordId;
        const recordInput = { fields };
        console.log(recordInput);

        updateRecord(recordInput)
            .then(() => {
                if(isConfidential){
                this.showToast("Success!!", "Case updated successfully!!", "success", "dismissable");
                }
            })
            .catch((error) => {
                this.showToast("Error!!", error.body.message, "error", "dismissable");
            });
    }

    showToast(title, message, variant, mode) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode,
        });
        this.dispatchEvent(evt);
    }

    get buttonConfig() {
        return BUTTON_CONFIG;
    }

    get confMessage() {
        return CONF_MESSAGE;
    }
}