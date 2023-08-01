import { LightningElement, api, track } from "lwc";
import { IP_FIELDS, LABEL,SYNC_FIELDS } from "./constants";
import IP_OBJECT from "@salesforce/schema/Implementation_Profile__c";
import getTeamMembers from "@salesforce/apex/NSP_ImplementationProfileController.getTeamMembers";
import { ANSWERED_CLASS_NAME,SYNC_FIELD_EVENT_NAME} from "c/nsp_utils";
import prepopulateIPData from "@salesforce/apex/NSP_ImplementationProfileController.populateIPData";

export default class Nsp_clientProjectInfoFso extends LightningElement {
  @api field = {};
  @api recordId;
  @api fieldValues = {};
  @api disabledFields = {};
  @track styles = {};
  @track state = {
    isLoadingFirstTime: true,
  };
  bpo;
  bpaIds;

  @api getFormValues() {
    const formValues = {};

    this.template.querySelectorAll("lightning-input-field").forEach((elm) => {
      const { fieldName, value } = elm;

      formValues[fieldName] = value;
    });

    return formValues;
  }

  publishIpPrefilledValueUpdateEvent(ip)
  {
    if(ip)
    {
      this.dispatchEvent(
        new CustomEvent(SYNC_FIELD_EVENT_NAME, { detail: { fieldName: 'Account__c', value: ip } })
      );
      
    }
  }

  publishSyncEvent(fieldName) {
    if (Object.values(SYNC_FIELDS).includes(fieldName)) {
      const value = this.field[fieldName];
      this.dispatchEvent(
        new CustomEvent(SYNC_FIELD_EVENT_NAME, { detail: { fieldName, value } })
      );
    }
  }

  handleLoad() {
    const { state } = this;

    if (state.isLoadingFirstTime) {
      state.isLoadingFirstTime = false;
      this.doOneTimeActions();
    }
  }

  handleError(error) {
  }

  handleProjectChange({ detail, target }) {
    if (!this.account) {
      this.updateBPOValue(detail, false);
    }

    this.addStyleToAnsweredQuestion(target, detail.value[0]);
  }

  handleAccountChange({ detail, target }) {
    this.account = detail.value[0];
    this.updateBPOValue(detail, true);
    this.addStyleToAnsweredQuestion(target, this.account);
    this.populateIpPrefilledValues();
  }

  handleValueChange({ detail, target }) {
    this.addStyleToAnsweredQuestion(target, detail.value[0]);
  }

  doOneTimeActions() {
    if (this.fieldValues) {
      this.addStylesToPrePopulatedField();
      this.populateBPOField();
    }
  }

  addStylesToPrePopulatedField() {
    const clientName = IP_FIELDS.clientName.fieldApiName;
    const clientNumber = IP_FIELDS.clientNumber.fieldApiName;
    const project = IP_FIELDS.project.fieldApiName;
    const account = IP_FIELDS.account.fieldApiName;
    const asset = IP_FIELDS.asset.fieldApiName;
    const bpa = IP_FIELDS.bpaBpc.fieldApiName;

    this.styles[clientName] = this.fieldValues[clientName] && this.fieldValues[clientName].value
      ? ANSWERED_CLASS_NAME
      : "";
    this.styles[clientNumber] = this.fieldValues[clientNumber] && this.fieldValues[clientNumber].value
      ? ANSWERED_CLASS_NAME
      : "";

    this.styles[project] = this.fieldValues[project] && this.fieldValues[project].value ? ANSWERED_CLASS_NAME : "";
    this.styles[account] = this.fieldValues[account] && this.fieldValues[account].value ? ANSWERED_CLASS_NAME : "";
    this.styles[asset] = this.fieldValues[asset] && this.fieldValues[asset].value ? ANSWERED_CLASS_NAME : "";
    this.styles[bpa] = this.fieldValues[bpa] && this.fieldValues[bpa].value ? ANSWERED_CLASS_NAME : "";
  }

  addStyleToAnsweredQuestion(target, value) {
    if (value) {
      target.classList.add(ANSWERED_CLASS_NAME);
    } else {
      target.classList.remove(ANSWERED_CLASS_NAME);
    }
  }

  populateBPOField() {
    const accField = this.fieldValues[IP_FIELDS.account.fieldApiName];
    if (accField) {
      this.account = accField.value;
      this.updateBPOValue({ value: [this.account] }, true);
    }
  }

  populateIpPrefilledValues(){
    if(!this.recordId && this.account){
      prepopulateIPData({accountId:this.account})
      .then((response) => {
        this.publishIpPrefilledValueUpdateEvent(response);
      }).catch((error) => {
      });
     }
  }

  updateBPOValue(detail, isAccountId) {
    if (detail.value && detail.value.length > 0) {
      getTeamMembers({ recordId: detail.value[0], isAccountId })
        .then((response) => {
          this.bpo = response.memberNames || null;
          this.field[IP_FIELDS.bpaBpc.fieldApiName]=this.bpo;
          this.publishSyncEvent(IP_FIELDS.bpaBpc.fieldApiName);
          this.bpaIds = response.memberIds || null;
        })
        .catch((error) => {
        });
    } else {
      this.bpo = null;
      this.field[IP_FIELDS.bpaBpc.fieldApiName]=this.bpo;
      this.publishSyncEvent(IP_FIELDS.bpaBpc.fieldApiName);
      this.bpaIds= null;
    }
  }

  get title() {
    return LABEL.clientProject;
  }

  get objectApiName() {
    return IP_OBJECT.objectApiName;
  }

  get fields() {
    return IP_FIELDS;
  }
}