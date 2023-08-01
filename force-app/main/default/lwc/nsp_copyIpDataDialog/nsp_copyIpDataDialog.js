import { api, LightningElement } from 'lwc';
import { BUTTON_CONFIG, SEARCH_CATEGORIES } from './constants';
import { prepareMapByValue } from './utils';
import { debounce, isNonEmptyArray } from 'c/nsp_utils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// APEX IMPORTS
import getIPRecords from '@salesforce/apex/NSP_IPSelector.searchRecordsByFilters';
import { LABEL } from './labels';

export default class Nsp_copyIpDataDialog extends LightningElement {
  @api sections;
  @api selectedSections = [];
  @api recordTypeId;

  @api
  get targetRecords() {
    return this.selectedOptions;
  }
  set targetRecords(value) {
    if (isNonEmptyArray(value)) {
      this.selectedOptions = [...value];
    }
  }

  searchOptions = [];
  selectedOptions = [];
  filterBy = SEARCH_CATEGORIES[0].value;
  optionsMap = {};

  handleButtonClick({ detail }) {
    if (detail === 'cancel') {
      this.dispatchEvent(new CustomEvent('close'));
    }
    if (detail === 'copy') {
      this.handleCopyButtonClick();
    }
  }

  handleSearchTermChange({ detail }) {
    this.showSearchResults(detail);
  }

  handleCopyButtonClick() {
    const records = this.selectedOptions;

    if (isNonEmptyArray(records)) {
      this.dispatchEvent(new CustomEvent('copy', { detail: { records } }));
    }
  }

  handleOptionSelection({ detail }) {
    const selectedOption = this.optionsMap[detail];
    selectedOption.label = this.appendInfoInOptionLabel(selectedOption);

    this.selectedOptions = [...this.selectedOptions, selectedOption];
    this.searchOptions = this.searchOptions.filter(
      (option) => option.value !== detail
    );
  }

  handleOptionDeselection({ detail }) {
    this.selectedOptions = this.selectedOptions.filter(
      (option) => option.value !== detail
    );
  }

  handleSectionChange({ detail }) {
    this.dispatchEvent(new CustomEvent('sectionchange', { detail }));
  }

  handleFilterTypeChange({ detail }) {
    this.filterBy = detail;
  }

  showSearchResults = debounce((searchTerm) => {
    const { filterBy, selectedOptionIds, recordTypeId } = this;
    const searchConfig = JSON.stringify({
      searchCategory: filterBy,
      searchTerm,
      preSelectedRecs: JSON.stringify(selectedOptionIds),
      recordTypeId,
    });

    getIPRecords({ searchConfig })
      .then((results) => {
        this.searchOptions = results;
        this.optionsMap = prepareMapByValue(results);
      })
      .catch((e) => this.showErrorToast(e.body.message));
  }, 100);

  showErrorToast(message) {
    this.showToast({
      title: 'Error',
      variant: 'error',
      message,
    });
  }

  showToast(config) {
    this.dispatchEvent(new ShowToastEvent({ ...config }));
  }

  appendInfoInOptionLabel({ label, info }) {
    return info ? label + ' | ' + info : label;
  }

  get selectedOptionIds() {
    return this.selectedOptions.map(({ value }) => value);
  }

  get lookupLabel() {
    return LABEL.lookupLabel;
  }

  get lookupPlaceholder() {
    return LABEL.lookupPlaceholder;
  }

  get buttonConfig() {
    return BUTTON_CONFIG;
  }

  get filterTypes() {
    return SEARCH_CATEGORIES;
  }

  get filterLabel() {
    return LABEL.filterLabel;
  }
}
