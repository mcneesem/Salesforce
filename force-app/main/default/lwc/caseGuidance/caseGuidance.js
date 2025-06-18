import { LightningElement, api, wire } from "lwc";

import { getRecord } from "lightning/uiRecordApi";
import getCaseGuidance from "@salesforce/apex/CaseGuidanceController.getCaseGuidance";
import getCaseGuidanceSetting from "@salesforce/apex/CaseGuidanceController.getCaseGuidanceSetting";

const FIELDS = [
  "Case.NSP_Category__c", 
  "Case.NSP_SubCategory__c", 
  "Case.NSP_Detail__c"
];

export default class CaseGuidance extends LightningElement {
  @api recordId;

  guidance          = "";
  showCaseGuidance  = false;
  activeSections    = "caseGuidance";
  error             = "";

  caseGuidanceCustomSettingData;

  @wire(getRecord, { recordId: "$recordId", fields: FIELDS })
  wiredRecord({ error, data }) {
    if (data) {
      this.refreshGuidance();
    } else if (error) {
      this.error = error;
      this.clearGuidance();
    }
  }

  @wire(getCaseGuidanceSetting, {})
  getCaseGuidanceSetting({ data, error }) {
    if (data) {
      this.caseGuidanceCustomSettingData = data;
    } else if (error) {
      this.error = error;
      this.clearGuidance();
    }
  }

  handleSectionToggle(event) {
    if (this.caseGuidanceCustomSettingData.IsEnabledActiveSections__c) {
      const openSections = event.detail.openSections;
      this.activeSections = openSections.length > 0 ? openSections : "";
    } else {
      this.activeSections = "";
    }
  }

  async refreshGuidance() {
    try {
      const result = await getCaseGuidance({ caseId: this.recordId });

      if (result && result !== this.guidance) {
        this.guidance = result;
        this.showCaseGuidance = true;
      } else {
        this.clearGuidance();
      }
    } catch (error) {
      this.error = error;
      this.clearGuidance();
    }
  }

  clearGuidance() {
    this.guidance = "";
    this.showCaseGuidance = false;
  }
}
