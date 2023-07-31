import { LightningElement, api, track } from 'lwc';
import IP_OBJECT from "@salesforce/schema/Implementation_Profile__c";
import {LABEL,SYNC_FIELDS} from './constants';
import * as LABELS from "c/nsp_implementationLabels";
import {
    isMultiSelectCheckbox,
    isSelectionBox,
    ANSWERED_CLASS_NAME,
} from "c/nsp_utils";
import { SECTION_FIELDS } from "./fields";

export default class Nsp_assignmentsmm extends LightningElement {
  @api recordId;
  @api recordTypeId;
  @api fieldValues = {};
  @api disabledFields ={};
  @track field = {};
  @track visibility = {};
  @track styles = {}
  @track state = {
      isLoadingFirstTime: true,
  };

  @api getFormValues() {
    const formValues = {};

    this.template.querySelectorAll("lightning-input-field").forEach((elm) => {
      const { fieldName, value } = elm;

      formValues[fieldName] = value;
    });

    return formValues;
  }

  objFields;
  @api get objectInfo() {
      return this.objFields;
  }
  set objectInfo(value) {
      if (value) {
          this.objFields = value?.fields;
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
      
      this.addStyleToPrePopulatedQuestions(fieldName, value);
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

    handleValueChange({ detail, target }) {
    try{
        const fieldName = target.dataset.name;
        const { value } = detail;

        this.field[fieldName] = isMultiSelectCheckbox(target)
            ? value.join(";")
            : value;
        this.addStyleToAnsweredQuestion(target, value);
    }catch(e){

    }
        
    }

    doOneTimeActions() {
        if (this.fieldValues) {
            Object.keys(this.fieldValues).forEach(fieldName => {
                const { value } = this.fieldValues[fieldName];

                if (SECTION_FIELDS.includes(fieldName) && value) {
                    this.field[fieldName] = value;
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
        const isValuePresent = Array.isArray(value) ? !!value.length : !!value;

        if (elm) {
            if (isSelectionBox(target)) {
                elm.className = isValuePresent ? ANSWERED_CLASS_NAME : null;
            } else {
                if (isValuePresent) {
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

    removeAnswerClasses(fieldApiName) {
        this.styles[fieldApiName] = this.styles[fieldApiName]
        .replace(ANSWERED_CLASS_NAME, '')
    }
  
    get title() {
    return LABEL.assignments;
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