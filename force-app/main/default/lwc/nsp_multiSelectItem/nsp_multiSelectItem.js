import { LightningElement, api } from 'lwc';

export default class Nsp_multiSelectItem extends LightningElement {
    /**
   * Single selectable item received from the multi select combobox parent component.
   * @type {Object}
   */
    @api item;

    get itemClass() {
        return `slds-listbox__item ${this.item.selected ? 'slds-is-selected' : ''}`;
    }

    handleClick() {
        this.dispatchEvent(
            new CustomEvent('change', {
                detail: { item: this.item, selected: !this.item.selected }
            })
        );
    }
}