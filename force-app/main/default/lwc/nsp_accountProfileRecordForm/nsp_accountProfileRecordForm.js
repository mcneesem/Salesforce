import { api, LightningElement, track, wire } from 'lwc';
import { FIELDS } from './fields';
import getAccountProfileRelatedInfo from '@salesforce/apex/NSP_AccountProfileController.getAccountProfileRelatedInfo';
import getRecentlyUpdatedFields from '@salesforce/apex/NSP_AccountProfileController.getRecentlyUpdatedFields';
import { FIELD_VISIBILITY_CONFIG } from './fieldVisibilityConfig';
import { LABEL } from './labels';

import cssResource from '@salesforce/resourceUrl/StandardFieldStyles';
import { loadStyle } from 'lightning/platformResourceLoader';

export default class Nsp_accountProfileRecordForm extends LightningElement {
  @api recordId;

  error = null;
  @track fieldsConfig = {};

  @wire(getAccountProfileRelatedInfo, { accId: '$recordId' })
  getInfo({ data, error }) {
    if (data) {
      getRecentlyUpdatedFields({ accId: this.recordId })
        .then((res) => {
          this.createFieldConfig(data, res);
        })
        .catch((error) => {
          this.error = error.body.message;
        });
    } else if (error) {
      this.error = error.body.message;
    }
  }

  connectedCallback() {
    loadStyle(this, cssResource);
  }

  createFieldConfig(relatedFieldValueMap, recentlyUpdatedFields) {
    const fieldsConfig = {};
    let childFields = JSON.parse(JSON.stringify(this.childFields));

    Object.keys(relatedFieldValueMap).forEach((fieldName) => {
      const { value, label, type, isURL, urlLabel, checkRichText, isDisable, isChecked } = relatedFieldValueMap[fieldName];
      const isHidden = childFields.includes(fieldName);
      const disabled = isDisable == 'FALSE' ? false: true;

      if (isHidden) {
        childFields = childFields.filter((f) => f !== fieldName);
      }

      fieldsConfig[fieldName] = {
        value,
        isCustom: true,
        disabled,
        label,
        isHidden,
        type,
        isRichText : checkRichText == 'TRUE',
        urlLabel,
        isURL,
        isChecked : isChecked == 'TRUE',
      };
      
    });

    childFields.forEach((fieldName) => {
      fieldsConfig[fieldName] = {
        isHidden: true,
      };
    });

    Object.keys(LABEL).forEach((fieldName) => {
      const config = fieldsConfig[fieldName] || {};
      if (!config.isCustom) {
        config.label = LABEL[fieldName];
        config.variant = 'label-hidden';
        fieldsConfig[fieldName] = config;
      }
    });

    recentlyUpdatedFields.forEach((fieldName) => {
      const config = fieldsConfig[fieldName] || {};

      config.className = 'nsp-highlight';
      fieldsConfig[fieldName] = config;
    });

    this.fieldsConfig = fieldsConfig;
  }

  get childFields() {
    let childFields = [];

    Object.keys(FIELD_VISIBILITY_CONFIG).forEach((parentField) => {
      FIELD_VISIBILITY_CONFIG[parentField].forEach(({ dependentFields }) => {
        childFields = [...childFields, ...dependentFields];
      });
    });

    return childFields;
  }

  get fieldVisibilityConfig() {
    return FIELD_VISIBILITY_CONFIG;
  }

  get config() {
    const { fieldsConfig, fieldVisibilityConfig } = this;

    return { fieldsConfig, fieldVisibilityConfig, columns: 2, fields: FIELDS };
  }
}
