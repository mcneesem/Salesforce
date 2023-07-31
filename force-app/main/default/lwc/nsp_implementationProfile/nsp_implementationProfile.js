import { api, LightningElement, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import IP_OBJECT from '@salesforce/schema/Implementation_Profile__c';
import * as labels from 'c/nsp_implementationLabels';
import cssResource from '@salesforce/resourceUrl/StandardFieldStyles';
import { loadStyle } from 'lightning/platformResourceLoader';
import USER_ID from '@salesforce/user/Id';
import USER_PROFILE_NAME from '@salesforce/schema/User.Profile.Name';
import USER_Email_ID from '@salesforce/schema/User.Email';
import getRecordWithAllFields from '@salesforce/apex/NSP_ImplementationProfileController.getRecordWithAllFields';
import { createMapWithValueProperty } from 'c/nsp_utils';

export default class Nsp_implementationProfile extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @api recordTypeId;
  @api error;

  label = labels;
  objectApiName = IP_OBJECT.objectApiName;
  defaultRecordTypeId;
  objectInfo = null;
  selectedRecTypeId = null;
  subTitle = '';

  @track userData = {};
  fieldValues = {};

  // WIRE SERVICES
  @wire(getObjectInfo, { objectApiName: IP_OBJECT })
  getImplementationInfo({ data, error }) {
    if (data) {
      this.defaultRecordTypeId = data.defaultRecordTypeId;
      this.objectInfo = data;
    } else if (error) {
      this.error = error;
    }
  }

  @wire(CurrentPageReference)
  getStateParameters(currentPageReference) {
    if (currentPageReference?.state?.recordTypeId) {
      this.selectedRecTypeId = currentPageReference.state.recordTypeId;
    }
  }

  @wire(getRecord, {
    recordId: USER_ID,
    fields: [USER_PROFILE_NAME, USER_Email_ID],
  })
  getUser({ error, data }) {
    if (error) {
      this.error = error;
    } else if (data) {
      this.userData = data.fields;
    }
  }

  connectedCallback() {
    const { objectApiName, recordId } = this;

    loadStyle(this, cssResource);
    if (recordId) {
      getRecordWithAllFields({ objectApiName, recordId }).then(data => this.setIPFieldValues(data)).catch(error => this.error = error);
    }
  }

  setIPFieldValues(data) {
    this.selectedRecTypeId = data.RecordTypeId;
    this.fieldValues = createMapWithValueProperty(data);
    this.updateSubTitle();
  }

  updateSubTitle() {
    const { NSP_AIMS_ClientNo__c, NSP_AIMS_Client_Name__c } = this.fieldValues;
    const clientNum = NSP_AIMS_ClientNo__c?.value || '';
    const clientName = NSP_AIMS_Client_Name__c?.value || '';

    this.subTitle =
      !clientName && !clientNum ? '' : `${clientName} (${clientNum})`;
  }

  get isFsoRecordType() {
    const { selectedRecTypeId, objectInfo, fieldValues } = this;

    return (
      objectInfo &&
      fieldValues &&
      selectedRecTypeId &&
      objectInfo.recordTypeInfos[selectedRecTypeId].name === 'FSO'
    );
  }

  get isMidMarketRecordType() {
    const { selectedRecTypeId, objectInfo, fieldValues } = this;

    return (
      objectInfo &&
      fieldValues &&
      selectedRecTypeId &&
      objectInfo.recordTypeInfos[selectedRecTypeId].name === 'Middle Market'
    );
  }
}
