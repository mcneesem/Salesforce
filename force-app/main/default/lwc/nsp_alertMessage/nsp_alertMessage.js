import { api, LightningElement } from 'lwc';

const VALID_MODES = ['error', 'warning', 'success'];
const DEFAULT_MODE = 'error';

export default class Nsp_alertMessage extends LightningElement {
  /**
   * This API property is used to display the message inside the alert banner.
   */
  @api message;

  /**
   * This API property controls the UI of the alert message banner.
   * Currently, it supports 3 values - error/warning/success
   * In case of null or invalid mode given, it takes error mode as default.
   */
  _mode;
  @api
  get mode() {
    return this._mode;
  }
  set mode(value) {
    const val = !!value ? value.trim().toLowerCase() : DEFAULT_MODE;

    this._mode = VALID_MODES.includes(val) ? val : DEFAULT_MODE;
  }

  get variant() {
    return this._mode;
  }

  get icon(){
    return `utility:${this._mode}`;
  }

  get alertClass(){
    return `slds-notify slds-notify_alert slds-alert_${this._mode}`;
  }
}
