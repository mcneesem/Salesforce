import { LightningElement, api, track } from 'lwc';
import { isNonEmptyArray } from 'c/nsp_utils';

export default class Nsp_modalDialog extends LightningElement {
  @api heading;
  @api modalContentStyle;

  @track config = {
    filteredButtons: [],
    buttons: null,
  };

  @api
  get buttons() {
    return this.config.buttons;
  }
  set buttons(val) {
    const { config } = this;

    config.buttons = val;
    if (isNonEmptyArray(val)) {
      this.config.filteredButtons = this.getFilteredButtons(val);
    }
  }

  handleButtonClick({ target }) {
    this.dispatchEvent(new CustomEvent('buttonclick', { detail: target.name }));
  }

  getFilteredButtons(buttons) {
    return buttons
      .filter((button) => !!button.label)
      .map((button) => ({
        ...button,
        name: button.name || button.label.toLowerCase().split(' ').join(''),
      }));
  }
}
