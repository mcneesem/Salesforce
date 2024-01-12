import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class AddMultipleAccountsFlowFooter extends LightningElement {
    createMoreRecords = false;

    @api
    availableActions = [];

    @api createMore;

    handleAddMoreClick(){
        this.dispatchEvent(new FlowAttributeChangeEvent('createMore', true));  
        this.goToNextScreen();
    }

    handleSaveClick(){
        this.goToNextScreen();
    }

    goToNextScreen(){
        // check if NEXT is allowed on this screen
        if (this.availableActions.find((action) => action === 'NEXT')) {
            // navigate to the next screen
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }
}