import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from "@salesforce/schema/Implementation_Profile__c";
import { DYNAMIC_FIELDS } from "./dynamicFieldsConfig";
import {LABEL,PREFILLED_FIELDS,SYNC_FIELDS,POST_SYNC_IP_FIELDS} from './constants';
import * as LABELS from "c/nsp_implementationLabels";
import {
    getUpdatedFieldVisibility,
    getFieldStylesByHierarchy,
    isMultiSelectCheckbox,
    isSelectionBox,
    ANSWERED_CLASS_NAME,
    isNonEmptyArray
} from "c/nsp_utils";
import { SECTION_FIELDS } from "./fields";

export default class Nsp_meetingDetailsmm extends LightningElement {

  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @api disabledFields ={};
  @track field = {};
  @track visibility = {};
  @track styles = getFieldStylesByHierarchy(DYNAMIC_FIELDS);
  @track state = {
      isLoadingFirstTime: true,
  };

  @api getFormValues() {
      const formValues = {};

      this.inputFields.forEach(({ fieldName, value }) => {
          formValues[fieldName] = value;
      });

      return { ...formValues, ...this.field };
  }

  _objectInfo;
  @api get objectInfo() {
      return this._objectInfo;
  }
  set objectInfo(value) {
      if (value) {
          this._objectInfo = value?.fields;
      }
  }

  @api
    get syncFieldValues() {
      return null;
    }
    set syncFieldValues(values) {
      if (values) {
        const { fieldName, value } = values;
  
        if (Object.keys(SYNC_FIELDS).includes(fieldName)) {
          this.field[SYNC_FIELDS[fieldName]] = value;
        }
        this.postSyncOperations( fieldName, value);
        this.addStyleToPrePopulatedQuestions(fieldName, value);
      }
    }
  
    postSyncOperations(fieldName, value){
      const postSyncOperationFn=POST_SYNC_IP_FIELDS[SYNC_FIELDS[fieldName]];
      if(postSyncOperationFn && postSyncOperationFn in this){
        
        this[postSyncOperationFn](value);
        this.addStyleToPrePopulatedQuestions(fieldName, value);
  
  
      }
    }
  
    updatePrefilledIpValues(values){
  
      if (values && !this.recordId) {
  
        Object.keys(PREFILLED_FIELDS).forEach((fieldName,i)=>{
          
          if(values[fieldName])
          {
            const value=values[fieldName];
          this.field[fieldName]=value;
          this.addStyleToPrePopulatedQuestions(fieldName,value);
  
          }
        });  
  
      }
    }

  handleLoad() {
      const { state } = this;

      if (state.isLoadingFirstTime) {
          state.isLoadingFirstTime = false;
          this.doOneTimeActions();
          this.dispatchEvent(new CustomEvent("load"));
      }
  }

  handleError(error) {
      this.dispatchEvent(new CustomEvent("error", { detail: error?.detail?.message }));
  }

  handleValueChange({ detail, target }) {
    try{
        const fieldName = target.dataset.name;
        const { value } = detail;
  
        this.field[fieldName] = isMultiSelectCheckbox(target)
            ? value.join(";")
            : value;
        this.updateDependentFieldVisibility(fieldName, value);
        this.addStyleToAnsweredQuestion(target, value);
        this.removeValuesFromHiddenFields(fieldName, value, false);
    }catch(e){

    }
  }

    removeValuesFromHiddenFields(fieldName, value, isParentField) {
        const fieldConfig = DYNAMIC_FIELDS[fieldName];
        if (fieldConfig) {
            fieldConfig.forEach(({ dependentFields, expValue }) => {
                dependentFields
                    .filter((fieldApiName) => fieldApiName !== fieldName)
                    .forEach((fieldApiName) => {
                        if (!isParentField) {
                            if (isNonEmptyArray(value)) {
                                value.forEach((val) => {
                                    if (!expValue.includes(val)) {
                                        this.field[fieldApiName] = null;
                                    }
                                });
                            } else if (value && !expValue.includes(value)) {
                                this.field[fieldApiName] = null;
                            }
                        } else {
                            this.field[fieldApiName] = null;
                        }
                        this.removeValuesFromHiddenFields(fieldApiName, null, true);
                    });
            });
        }
    }

  doOneTimeActions() {
      if (this.fieldValues) {
          Object.keys(this.fieldValues).forEach(fieldName => {
              const { value } = this.fieldValues[fieldName];

              if (SECTION_FIELDS.includes(fieldName) && value) {
                  this.field[fieldName] = value;
                  this.updateDependentFieldVisibility(fieldName, value);
                  this.addStyleToPrePopulatedQuestions(fieldName, value);
              }
          });
      }
  }

  addStyleToPrePopulatedQuestions(name, value) {
      const existingClass = this.styles[name];
      if (existingClass) {
          this.styles[name] = `${existingClass} ${ANSWERED_CLASS_NAME}`;
      } else {
          const elm = this.template.querySelector(`[data-name=${name}]`);
          if (elm) {
              this.addStyleToAnsweredQuestion(elm, value);
          }
      }
  }

  addStyleToAnsweredQuestion(target, value) {
      const fieldName = target.dataset.name;
      const elm = this.getCustomLabelElm(fieldName) || target;

      if (elm) {
          if (isSelectionBox(target)) {
              elm.className = value ? ANSWERED_CLASS_NAME : null;
          } else {
              if (value) {
                  elm.classList.add(ANSWERED_CLASS_NAME);
              } else {
                  elm.classList.remove(ANSWERED_CLASS_NAME);
              }
          }
      }
  }

  getCustomLabelElm(fieldName) {
      return this.template.querySelector(
          `lightning-formatted-text[data-field=${fieldName}]`
      );
  }

  updateDependentFieldVisibility(fieldName, value) {
      const fieldConfig = DYNAMIC_FIELDS[fieldName];

      if (fieldConfig && fieldConfig.length) {
          const updatedValues = getUpdatedFieldVisibility(fieldConfig, value);
          this.visibility = { ...this.visibility, ...updatedValues };
      }
  }

  get title() {
    return LABEL.meetingDetails;
  }
  
  get inputFields() {
      return this.template.querySelectorAll("lightning-input-field");
  }

  get objectApiName() {
      return IP_OBJECT.objectApiName;
  }

  get label() {
      return LABELS;
  }
}