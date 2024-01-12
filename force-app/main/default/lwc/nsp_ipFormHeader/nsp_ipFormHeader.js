import { LightningElement, api } from 'lwc';
import saveAndExit from '@salesforce/label/c.NSP_Save_And_Exit';
import exit from '@salesforce/label/c.NSP_Exit';
import copyButton from '@salesforce/label/c.NSP_Copy_Button';

export default class Nsp_ipFormHeader extends LightningElement {
  @api mainTitle;
  @api subTitle;
  @api readOnly = false;

  label = {
    saveAndExit,
    copyButton,
    exit,
  };

  handleButtonClick({ target }) {
    this.dispatchEvent(new CustomEvent('buttonclick', { detail: target.name }));
  }
}
