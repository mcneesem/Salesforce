import { api, LightningElement } from 'lwc';
import { isNonEmptyArray } from 'c/nsp_utils';

export default class Nsp_multiSelectLookup extends LightningElement {
  @api label;
  @api filterTypes;
  @api filterLabel;
  @api options = [];
  @api selectedOptions;
  @api filterBy;
  @api placeholder;
  @api required = false;

  handleFilterTypeChange({ detail }) {
    this.dispatchEvent(
      new CustomEvent('filtertypechange', { detail: detail.value })
    );
  }

  handlePillRemoval({ detail }) {
    const removedPillName = detail.item.name;

    this.dispatchEvent(
      new CustomEvent('lookupdeselect', { detail: removedPillName })
    );
  }

  get optionPills() {
    return isNonEmptyArray(this.selectedOptions)
      ? this.selectedOptions.map(({ label, value, iconName, info }) => ({
          label,
          name: value,
          iconName,
          type: 'icon',
          alternativeText: info,
          title: info,
        }))
      : null;
  }

  get lookupBoxClass(){
    return this.filterTypes ? 'slds-col slds-size_3-of-4' : 'slds-col slds-size_1-of-1';
  }
}
