import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import Id from '@salesforce/user/Id';
import linkProjectToOLI from "@salesforce/apex/NSP_CreateProjFromFlow.linkProjectToOrderLines";
import validateUserRole from "@salesforce/apex/NSP_CreateProjFromFlow.validateUserRole";
import { CloseActionScreenEvent } from "lightning/actions";

export default class NSP_linkProjectToOrderItems extends NavigationMixin(LightningElement) {
    @api recordId;
    @api userId = Id;
    role;
    isValidRole;
    isLoaded;
    
    connectedCallback() {
        this.validateUserRole();
    }
    @api invoke(){
      this.closeAction();
    }

    //Apex call to check if User Role is valid
    validateUserRole() {
        validateUserRole({})
            .then((result) => {
                //console.log('==Sucess=='+result);
                if (result) {
                    this.isLoaded = false;
                    this.linkProjectToOLIFunc(this.recordId);
                } else {
                    this.isLoaded = true;
                    this.showToast("Error", 'You dont have access to create Project', "error");
                    this.closeAction();

                }
            })
            .catch((error) => {
                this.error = error;
                console.log('==error==' + JSON.stringify(this.error));
            });
    }

    //Apex call to create Project
    linkProjectToOLIFunc(recordId) {
        console.log('====this.recordId==' + recordId);
        linkProjectToOLI({
            orderId: recordId,
        })
            .then((result) => {
                console.log('==Sucess==' + result);
                this.isLoaded = true;
                if (result) {
                this.showToast("Success", 'Project linked to Order Items', "success");
                }
                else {
                    this.showToast("Error", 'No Project linked to Order', "error");
                }
                this.closeAction();
            })
            .catch((error) => {
                this.error = error;
                console.log('==error==' + JSON.stringify(error));
            });
    }

  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(event);
  }

}