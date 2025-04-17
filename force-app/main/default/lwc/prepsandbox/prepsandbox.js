import { LightningElement, track } from 'lwc';
import runManualSteps from '@salesforce/apex/NSP_PrepSandbox.runManualSteps';
import runManualSteps2 from '@salesforce/apex/NSP_PrepSandbox.runManualSteps2';
import runE2CAddresses from '@salesforce/apex/NSP_PrepSandbox.runE2CAddresses';

export default class PrepSandbox extends LightningElement {
  @track result = '';

  async runManualStepsButton() {
    try {
      const result = await runManualSteps();
      this.result = result;
    } catch (error) {
      this.result = 'Error running Manual Steps: ' + error.body.message;
    }
  }

  async runManualStepsButton2() {
    try {
      const result = await runManualSteps2();
      this.result = result;
    } catch (error) {
      this.result = 'Error running Manual Steps 2: ' + error.body.message;
    }
  }

  async runE2CAddressesButton() {
    try {
      const result = await runE2CAddresses();
      this.result = result;
    } catch (error) {
      this.result = 'Error running E2C Addresses: ' + error.body.message;
    }
  }
}