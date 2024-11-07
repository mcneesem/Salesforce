import { api, LightningElement, track, wire } from 'lwc';
import { FIELDS } from './fields';
import { FIELD_VISIBILITY_CONFIG } from './fieldVisibilityConfig';
import { LABEL } from './labels';
import getAccountProfileRelatedInfo from '@salesforce/apex/NSP_AccountProfileController.getAccountProfileRelatedInfo';
import getRecentlyUpdatedFields from '@salesforce/apex/NSP_AccountProfileController.getRecentlyUpdatedFields';
import getRecordWithAllFields from '@salesforce/apex/NSP_AccountProfileController.getRecordWithAllFields';
import { refreshApex } from '@salesforce/apex';

import cssResource from '@salesforce/resourceUrl/StandardFieldStyles';
import { loadStyle } from 'lightning/platformResourceLoader';
import { createMapWithValueProperty } from 'c/nsp_utils';

export default class Nsp_accountProfileRecordForm extends LightningElement {
  @api recordId;

  error = null;
  @track allFieldsValue = {};
  @track recordWithAllFields = {};
  @track fieldsConfig = {};
  @track relatedDependentFields=[];

  @wire(getRecordWithAllFields, { recordId: '$recordId' })
  getInfo(value) {
    this.recordWithAllFields=value;
    if(this.recordWithAllFields.data){
      this.allFieldsValue = JSON.parse(JSON.stringify(createMapWithValueProperty(this.recordWithAllFields.data)));
      getAccountProfileRelatedInfo({ accId: this.recordId })
        .then((relatedInfo) => {
          Object.keys(relatedInfo).forEach((fieldName) => {
            if(fieldName in this.allFieldsValue){
              if(relatedInfo[fieldName].value !== undefined && this.allFieldsValue[fieldName].value !== undefined && relatedInfo[fieldName].value !== this.allFieldsValue[fieldName].value){
                this.allFieldsValue[fieldName].value = relatedInfo[fieldName].value;
              }
            }
          })
          getRecentlyUpdatedFields({ accId: this.recordId })
            .then((updatedInfo) => {
              this.createFieldConfig(relatedInfo, updatedInfo);
          }).catch((error) => {
              this.error = error;
        });
      }).catch((error) => {
        this.error = error;
      });
    }else if (this.recordWithAllFields.error) {
      this.error = this.recordWithAllFields.error;
    }
  }

  connectedCallback() {
    loadStyle(this, cssResource);
  }

  createFieldConfig(relatedFieldValueMap, recentlyUpdatedFields) {
    const fieldsConfig = {};
    let configDependentFields = JSON.parse(JSON.stringify(this.configDependentFields));
    let childFields = JSON.parse(JSON.stringify(this.childFields));

    Object.keys(relatedFieldValueMap).forEach((fieldName) => {
      const { value, label, type, isURL, urlLabel, checkRichText, isDisable, isChecked } = relatedFieldValueMap[fieldName];
      const isHidden = childFields.includes(fieldName);
      const disabled = isDisable == 'FALSE' ? false: true;

      if(Object.keys(FIELD_VISIBILITY_CONFIG).includes(fieldName)){

        if(FIELD_VISIBILITY_CONFIG[fieldName]
            && FIELD_VISIBILITY_CONFIG[fieldName][0]
            && FIELD_VISIBILITY_CONFIG[fieldName][0].expValue
            && FIELD_VISIBILITY_CONFIG[fieldName][0].expValue[0]
            && relatedFieldValueMap[fieldName].value
        ){
          if( FIELD_VISIBILITY_CONFIG[fieldName][0].expValue[0].toString() !== relatedFieldValueMap[fieldName].value.toString()){
            //Adding dependent fields to configDependentFields to allow visibility.
            FIELD_VISIBILITY_CONFIG[fieldName].forEach(({ dependentFields }) => {
              if (! this.relatedDependentFields.includes(dependentFields)) {
                this.relatedDependentFields = [...this.relatedDependentFields, ...dependentFields];
              }
            });
          }
        }
      }
      
      if (isHidden) {
        childFields = childFields.filter((f) => f !== fieldName);
      }
      if (configDependentFields.includes(fieldName)) {
        configDependentFields = configDependentFields.filter((f) => f != fieldName);
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
    Object.keys(recentlyUpdatedFields).forEach((fieldName) => {
      if (configDependentFields.includes(fieldName)) {
        configDependentFields = configDependentFields.filter((f) => f != fieldName);
      }

      if(fieldName in Object.keys(FIELD_VISIBILITY_CONFIG)){
        if( FIELD_VISIBILITY_CONFIG[fieldName][0].expValue[0] === recentlyUpdatedFields[fieldName]){
          //Adding dependent fields to configDependentFields to allow visibility.
          FIELD_VISIBILITY_CONFIG[fieldName].forEach(({ dependentFields }) => {
            if (! configDependentFields.includes(dependentFields)) {
              configDependentFields = [...configDependentFields, ...dependentFields];
            }
          });
        }else{
          //Adding dependent fields to childFields to remove visibility.
          FIELD_VISIBILITY_CONFIG[fieldName].forEach(({ dependentFields }) => {
            if (! childFields.includes(dependentFields)) {
              childFields = [...childFields, ...dependentFields];
            }
          });
        }
      }
      //Either field is not dependent field, or parent value matches with expected value
      if (!childFields.includes(fieldName)) {
        const config = fieldsConfig[fieldName] || {};
        config.isHidden = false;
        config.className = 'nsp-highlight';
        fieldsConfig[fieldName] = config;
      }
    });
    
    //dependent fields, where parent field value does not match with expected value.
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
    configDependentFields.forEach((fieldName) => {
      if(!(Object.keys(recentlyUpdatedFields).includes(fieldName))){
        const isHidden = childFields.includes(fieldName);
        if (isHidden) {
          childFields = childFields.filter((f) => f !== fieldName);
        }
        const config = fieldsConfig[fieldName] || {};
        config.isHidden = false;
        fieldsConfig[fieldName] = config;
      }
    });

    this.fieldsConfig = fieldsConfig;
  }

  get configDependentFields() {
    let configDependentFields = [];
    Object.keys(FIELD_VISIBILITY_CONFIG).forEach((parentField) => {
      const {expValue, dependentFields} = FIELD_VISIBILITY_CONFIG[parentField][0];
      if(parentField in this.allFieldsValue){
        if(expValue[0] === this.allFieldsValue[parentField].value){
                configDependentFields = [...configDependentFields, ...dependentFields];
        }
      }
    });
    return configDependentFields;
  }

  get childFields() {
    let childFields = [];

    Object.keys(FIELD_VISIBILITY_CONFIG).forEach((parentField) => {
      const {expValue, dependentFields} = FIELD_VISIBILITY_CONFIG[parentField][0];
      let addChilds=false;
      if(!(parentField in this.allFieldsValue)){
        addChilds=true;
      }else if(parentField in this.allFieldsValue){
        if ( expValue[0]
          && this.allFieldsValue[parentField].value
          && ( expValue[0].toString() !== this.allFieldsValue[parentField].value.toString() )
          )
        {
          addChilds=true;
        }
      }
      if(addChilds){
        FIELD_VISIBILITY_CONFIG[parentField].forEach(({ dependentFields }) => {
          childFields = [...childFields, ...dependentFields];
        });
      }
    });

    return childFields;
  }

  get fieldVisibilityConfig() {
    return FIELD_VISIBILITY_CONFIG;
  }

  get config() {
    const { fieldsConfig, fieldVisibilityConfig, relatedDependentFields} = this;

    return { fieldsConfig, fieldVisibilityConfig, relatedDependentFields, columns: 2, fields: FIELDS,  };
  }

  refreshData() {
    refreshApex(this.recordWithAllFields);
  }
}
