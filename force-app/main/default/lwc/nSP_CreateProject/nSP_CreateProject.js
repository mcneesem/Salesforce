import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
import checkCreateProject from "@salesforce/apex/NSP_CreateProjFromFlow.checkCreateProject";
import PROJECT_NAME from "@salesforce/schema/Order.NSP_Project_Name__c";
import PROJECT from "@salesforce/schema/Order.NSP_HasProject__c";
import Id from '@salesforce/user/Id';
import validateUserRole from "@salesforce/apex/NSP_CreateProjFromFlow.validateUserRole";
import { CloseActionScreenEvent } from "lightning/actions";
import { updateRecord } from 'lightning/uiRecordApi';

export default class NSP_CreateProject extends NavigationMixin(LightningElement) {
  @api recordId;
  @api userId = Id;
  projectName;
  project;
  updateResult;
  role;
  isValidRole;
  isLoaded;
  connectedCallback() {}
  @api invoke() {
      this.closeAction();
  }
  @wire(getRecord, {
      recordId: "$recordId",
      fields: [
          PROJECT_NAME,
          PROJECT,
      ],
  })
  recordUpdated({
      error,
      data
  }) {
      if (data) {
          this.projectName = data.fields.NSP_Project_Name__c.value;
          this.project = data.fields.NSP_HasProject__c.value;
          if (this.project == true) {
              this.isLoaded = true;
              this.showToast("Error", 'Order is already linked to Project', "error");
              this.closeAction();
          } else if (this.projectName && (this.project == false)) {
              this.validateUserRole();
          }
          //this.closeAction();
      }
      if (error) {
          this.error = error;
          this.closeAction();
      }
  }

  //Apex call to check if User Role is valid
  validateUserRole() {
      validateUserRole({})
          .then((result) => {
              if (result) {
                  this.isLoaded = false;
                  this.checkCreateProject(this.recordId);

              } else {
                  this.isLoaded = true;
                  this.showToast("Error", 'You dont have access to create Project', "error");
                  this.closeAction();

              }
          })
          .catch((error) => {
              this.error = error;
              this.closeAction();
          });
  }
  //Apex call to create Project
  checkCreateProject(recordId) {
      checkCreateProject({
              recordId: recordId,
          })
          .then((result) => {

              this.isLoaded = true;
              this.showToast("Success", 'Project Creation Request has been submitted', "success");
              updateRecord({
                  fields: {
                      Id: this.recordId
                  }
              })
              //window.location.reload();
              this.closeAction();


          })
          .catch((error) => {
              this.error = error;
              this.closeAction();
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