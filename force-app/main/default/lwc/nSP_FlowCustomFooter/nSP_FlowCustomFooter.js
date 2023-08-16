import { LightningElement , api } from 'lwc';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class NSP_FlowCustomFooter extends LightningElement {

    @api availableActions = [];
    @api proceed = false;
    @api next;
    @api previous;
    @api IsExit;

    handleCancel(){
        if(this.previous=='Back To Quote'){
            this.navigateToQLE();
        }
        else{
            this.goToNextScreen();
        }
    }

    handleSaveClick(){
        this.proceed = true;
        this.goToNextScreen();
    }

    goToNextScreen(){
        // check if NEXT is allowed on this screen
        if (this.availableActions.find((action) => action === 'NEXT')) {
            // navigate to the next screen
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }
    navigateToQLE(){
        this.dispatchEvent(new FlowAttributeChangeEvent('IsExit', true));
        this.dispatchEvent(new FlowNavigationNextEvent());
    }
}