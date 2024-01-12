import {
  CLASS_BY_ORDER,
  SELECTION_BOX,
  ANSWERED_CLASS_NAME,
  RL_CLASS_NAME,
  LABEL_CLASSES,
  SYNC_FIELD_EVENT_NAME,
  RL_FIELD_ACCEPTED_VALUES,
} from './constants';
import { toNorthAmericanPhoneNumber } from './phoneify';

const debounce = function (func, delay = 0) {
  let timer;
  return function (...args) {
    clearTimeout(timer);
    timer = setTimeout(() => {
      func.apply(this, args);
    }, delay);
  };
};

const isSelectionBox = function (elm) {
  return !!elm && elm.tagName.toUpperCase() === SELECTION_BOX;
};

const isMultiSelectCheckbox = function (elm) {
  return isSelectionBox(elm) && elm.multiple;
};

const getUpdatedFieldVisibility = function (fieldConfig, value) {
  const fieldVisibility = {};

  fieldConfig.forEach(({ expValue, dependentFields }) => {
    dependentFields.forEach((field) => {
      if (Array.isArray(value)) {
        let isVisible = false;
        value.forEach((val) => {
          if (expValue.includes(val)) {
            isVisible = true;
          }
        });
        if (
          !(field in fieldVisibility) ||
          (isVisible && !fieldVisibility[field])
        ) {
          fieldVisibility[field] = isVisible;
        }
      } else {
        const isVisible = expValue.includes(value);
        if (
          !(field in fieldVisibility) ||
          (isVisible && !fieldVisibility[field])
        ) {
          fieldVisibility[field] = isVisible;
        }
      }
    });
  });

  return fieldVisibility;
};

const getFieldHierarchy = function (mapping) {
  const fieldHierarchy = {};

  Object.keys(mapping).forEach((fieldName) => {
    if (!(fieldName in fieldHierarchy)) {
      fieldHierarchy[fieldName] = 0;
    }

    const childOrder = fieldHierarchy[fieldName] + 1;

    mapping[fieldName].forEach(({ dependentFields }) => {
      dependentFields.forEach((dependentField) => {
        fieldHierarchy[dependentField] = childOrder;
      });
    });
  });

  return fieldHierarchy;
};

const getFieldStylesByHierarchy = function (mapping) {
  const styles = {};
  const fieldHierarchyMap = getFieldHierarchy(mapping);

  Object.keys(fieldHierarchyMap).forEach((fieldName) => {
    const fieldHierarchy = fieldHierarchyMap[fieldName];
    styles[fieldName] = CLASS_BY_ORDER[fieldHierarchy];
  });

  return styles;
};

const getFieldApiNameMapIndexedByLocalName = function (fieldsMap = {}) {
  const fieldApiNames = {};

  Object.keys(fieldsMap).forEach((localName) => {
    fieldApiNames[localName] = fieldsMap[localName].fieldApiName;
  });

  return fieldApiNames;
};

const getChildFieldsFromFieldsConfig = function (config = {}) {
  let childFields = [];

  Object.keys(config).forEach((parentField) => {
    config[parentField].forEach(({ dependentFields }) => {
      childFields = [...childFields, ...dependentFields];
    });
  });

  return childFields;
}

const constructNameLabelArray = function (obj) {
  return Object.keys(obj).map((name) => {
    return { name, label: obj[name], value: name };
  });
};

const getClientFEINValue = function (fieldName, value) {
  //format the value 12-1234567
  const matchFEIN = value.replace(/\D+/g, '').match(/(\d{2})(\d{7})/);

  const matchOnlyNumber = value.replace(/\D+/g, '').match(/(\d{0,9})/);

  if (matchFEIN) {
    return !matchFEIN[2] ? matchFEIN[1] : `${matchFEIN[1]}-${matchFEIN[2]}`;
  } else if (matchOnlyNumber) {
    return matchOnlyNumber[0];
  }
};

const onFEINKeyPress = function (event) {
  //to restrict input of letters
  const theEvent = event || window.event;
  let key = theEvent.keyCode || theEvent.which;
  key = String.fromCharCode(key);

  const regex = /[0-9]|\./;
  if (!regex.test(key)) {
    theEvent.returnValue = false;
    if (theEvent.preventDefault) theEvent.preventDefault();
  }
};

const isNonEmptyArray = function (val) {
  return val && Array.isArray(val) && val.length;
};

const prepareMapByValue = function (arr) {
  const map = {};
  arr.forEach((elm) => {
    if (elm.value) {
      map[elm.value] = elm;
    }
  });

  return map;
};

const getErrorMessage = function (response) {
  const { body } = response;

  if (body.output && body.output.fieldErrors) {
    const errors = [];
    const { fieldErrors } = body.output;

    Object.keys(fieldErrors).forEach((fieldName) => {
      fieldErrors[fieldName].forEach(error => errors.push(error.message));
    });

    return errors.join();
  }
  return body.message;
};

const createMapWithValueProperty = function (obj) {
  return Object.keys(obj).reduce((acc, fieldName) => {
    return { ...acc, [fieldName]: { value: obj[fieldName], displayValue: null } };
  }, {});
}

export {
  debounce,
  isSelectionBox,
  isMultiSelectCheckbox,
  getFieldStylesByHierarchy,
  getUpdatedFieldVisibility,
  getFieldApiNameMapIndexedByLocalName,
  constructNameLabelArray,
  isNonEmptyArray,
  ANSWERED_CLASS_NAME,
  RL_CLASS_NAME,
  LABEL_CLASSES,
  SYNC_FIELD_EVENT_NAME,
  RL_FIELD_ACCEPTED_VALUES,
  getClientFEINValue,
  onFEINKeyPress,
  getChildFieldsFromFieldsConfig,
  toNorthAmericanPhoneNumber,
  prepareMapByValue,
  getErrorMessage,
  createMapWithValueProperty
};