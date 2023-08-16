import { api, LightningElement } from 'lwc';
import { isNonEmptyArray } from 'c/nsp_utils';

const LIST_ITEM_CLASSES = 'slds-listbox__item lookupOptions';
const DISABLED_OPTION_CLASS = 'nsp_disabled-option';
export default class Nsp_lookupBox extends LightningElement {
  @api label;
  @api placeholder;
  @api required = false;

  showOptions = false;
  _options = [];
  @api
  get options() {
    return this._options;
  }
  set options(val) {
    this._options = this.getConfiguredOptions(val || []);
  }

  handleSearchBoxFocus() {
    this.showOptions = true;
  }

  handleSearchBoxBlur() {
    if (this.hoveredOption) {
      this.searchBox.focus();
    } else {
      this.showOptions = false;
    }
  }

  handleSearchTermChange({ detail }) {
    this.dispatchEvent(
      new CustomEvent('searchtermchange', {
        detail: detail.value,
        bubbles: true,
        composed: true,
      })
    );
  }

  handleOptionClick({ target }) {
    const parentLi = this.findParentNode(target, 'li');

    if (parentLi.dataset.disabled !== 'true') {
      this.dispatchLookupSelectEvent(parentLi);
    }
  }

  getConfiguredOptions(rawOptions) {
    return rawOptions.map((option) => {
      const liClass = option.disabled
        ? `${LIST_ITEM_CLASSES} ${DISABLED_OPTION_CLASS}`
        : LIST_ITEM_CLASSES;

      return { ...option, liClass };
    });
  }

  dispatchLookupSelectEvent(parentLi) {
    const { value } = parentLi.dataset;

    this.dispatchEvent(
      new CustomEvent('lookupselect', {
        detail: value,
        bubbles: true,
        composed: true,
      })
    );
  }

  findParentNode(node, tagName) {
    const parent = node.parentNode;

    if (parent.tagName === tagName.toUpperCase()) {
      return parent;
    }

    return this.findParentNode(parent, tagName);
  }

  get isOptionBoxVisible() {
    return isNonEmptyArray(this.options) && this.showOptions;
  }

  get hoveredOption() {
    return this.template.querySelector('.nsp-option-container:hover');
  }

  get lookupOptions() {
    return this.template.querySelectorAll('li.lookupOptions');
  }

  get searchBox() {
    return this.template.querySelector('lightning-input');
  }
}
