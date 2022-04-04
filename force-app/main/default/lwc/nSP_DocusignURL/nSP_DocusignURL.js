import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from "lightning/uiRecordApi";
import QUOTE_STATUS_FIELD from "@salesforce/schema/Opportunity.NSP_Quote_Status__c";
import TEMPLATE_FIELD from "@salesforce/schema/Opportunity.NSP_Selected_Template__c";
import NAME_FIELD from "@salesforce/schema/Opportunity.Name";
import ACCOUNT_NAME_FIELD from "@salesforce/schema/Opportunity.NSP_Account_Name__c";
import CUSTOMER_SIGNER from "@salesforce/schema/Opportunity.NSP_Customer_Signer__c";
import INSPERITY_SIGNER from "@salesforce/schema/Opportunity.NSP_Insperity_Signer__c";
import HAS_QUOTE from "@salesforce/schema/Opportunity.NSP_Has_Primary_Quote__c";
import PRIMARY_PRODUCT from "@salesforce/schema/Opportunity.NSP_PrimaryProduct__c";
import BYPASS_DOCUSIGN from "@salesforce/schema/Opportunity.NSP_Bypass_Docusign_Signature__c";
import CLIENT_FOR_LIFE from "@salesforce/schema/Opportunity.NSP_Client_For_Life__c";
import BILLING_ACCOUNT from "@salesforce/schema/Opportunity.NSP_Billing_Account__c";
import DO_SIGNED from "@salesforce/schema/Opportunity.NSP_DO_Sign_By_Billing_Account__c";
import getDocuSignUrl from "@salesforce/apex/NSP_Quote_Service.getDocuSignUrl";
import validateCustomerSigner from "@salesforce/apex/NSP_Quote_Service.validateCustomerSigner";
import { CloseActionScreenEvent } from "lightning/actions";
import docusignAccountId from "@salesforce/label/c.NSP_Docusign_Account_Id";

export default class NSP_DocusignURL extends NavigationMixin(LightningElement) {
  @api recordId;
  @track showButton;
  @track error;
  @track data;
  @api isQuoteValid;
  @api quoteStatus;
  @api quoteId;
  @api templateId;
  @api generatedURL;
  @api name;
  @api accountName;
  @api genUrl;
  @api customerSigner;
  @api insperitySigner;
  @api hasQuote;
  @api primaryProduct;
  @api bypassDocusign;
  @api clientForLife;
  @api billingAccount;
  @api doSigned;
  isValid;
  contact;
  label = {
    docusignAccountId,
  };
  connectedCallback() {}

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [
      QUOTE_STATUS_FIELD,
      TEMPLATE_FIELD,
      NAME_FIELD,
      CUSTOMER_SIGNER,
      ACCOUNT_NAME_FIELD,
      INSPERITY_SIGNER,
      HAS_QUOTE,
      PRIMARY_PRODUCT,
      BYPASS_DOCUSIGN,
      CLIENT_FOR_LIFE,
      BILLING_ACCOUNT,
      DO_SIGNED,
    ],
  })
  recordUpdated({ error, data }) {
    if (data) {
      this.quoteStatus = data.fields.NSP_Quote_Status__c.value;
      this.templateId = data.fields.NSP_Selected_Template__c.value;
      this.name = data.fields.Name.value;
      this.accountName = data.fields.NSP_Account_Name__c.value;
      this.customerSigner = data.fields.NSP_Customer_Signer__c.value;
      this.insperitySigner = data.fields.NSP_Insperity_Signer__c.value;
      this.hasQuote = data.fields.NSP_Has_Primary_Quote__c.value;
      this.primaryProduct = data.fields.NSP_PrimaryProduct__c.value;
      this.bypassDocusign = data.fields.NSP_Bypass_Docusign_Signature__c.value;
      this.clientForLife = data.fields.NSP_Client_For_Life__c.value;
      this.billingAccount = data.fields.NSP_Billing_Account__c.value;
      this.doSigned = data.fields.NSP_DO_Sign_By_Billing_Account__c.value;

      if (
        this.hasQuote &&
        (this.primaryProduct == "Retirement Services" ||
          this.primaryProduct == "Learning & Development" ||
          (this.primaryProduct == "HR Consulting Services" &&
            this.clientForLife == "WO/WS") ||
          this.bypassDocusign)
      ) {
        this.isQuoteValid = false;
        this.showToast(
          "Error",
          "Delivery order generation is not applicable for this Primary Product",
          "error"
        );
      } else if (
        this.quoteStatus != "Approved" &&
        this.customerSigner &&
        this.insperitySigner
      ) {
        this.isQuoteValid = false;
        this.showToast(
          "Error",
          "You can generate delivery order documents only for approved quotes",
          "error"
        );
      } else if (
        !this.customerSigner &&
        this.quoteStatus == "Approved" &&
        this.insperitySigner
      ) {
        this.isQuoteValid = false;
        this.showToast("Error", "Please update Customer Signer", "error");
      } else if (
        this.customerSigner &&
        this.quoteStatus == "Approved" &&
        !this.insperitySigner
      ) {
        this.isQuoteValid = false;
        this.showToast("Error", "Please update Insperity Signer", "error");
      } else if (!this.customerSigner && this.quoteStatus != "Approved") {
        this.isQuoteValid = false;
        this.showToast(
          "Error",
          "Please update Customer Signer and you can generate delivery order documents only for approved quotes",
          "error"
        );
      } else if (!this.insperitySigner && this.quoteStatus != "Approved") {
        this.isQuoteValid = false;
        this.showToast(
          "Error",
          "Please update Insperity Signer and you can generate delivery order documents only for approved quotes",
          "error"
        );
      } else if (
        !this.customerSigner &&
        this.quoteStatus == "Approved" &&
        !this.insperitySigner
      ) {
        this.isQuoteValid = false;
        this.showToast(
          "Error",
          "Please update Customer Signer and Insperity Signer",
          "error"
        );
      } else {
        if (this.doSigned) {
          this.validateCustomerSigner();
        } else {
          this.isQuoteValid = true;
          this.navigateToVFPage();
        }
      }

      this.closeAction();
    }

    if (error) {
      this.error = error;
    }
  }

  validateCustomerSigner() {
    validateCustomerSigner({
      billingAccount: this.billingAccount,
      customerSigner: this.customerSigner,
    })
      .then((result) => {
        this.isValid = result;
        if (this.isValid === false) {
          this.isQuoteValid = false;
          this.showToast(
            "Error",
            "Customer Signer must be a contact of Billing Account",
            "error"
          );
        } else if (this.isValid) {
          this.navigateToVFPage();
        }
      })
      .catch((error) => {
        this.error = error;
      });
  }

  //Navigate to visualforce page
  navigateToVFPage() {
    getDocuSignUrl({
      recordId: this.recordId,
      templateId: this.templateId,
      name: this.name,
      accountName: this.accountName,
      aid: docusignAccountId,
    })
      .then((result) => {
        this.genUrl = result;
        this.navigateToVFPages(this.genUrl);
      })
      .catch((error) => {
        this.error = error;
      });
  }
  navigateToVFPages() {
    // Navigate to a URL
    this[NavigationMixin.Navigate]({
      type: "standard__webPage",
      attributes: {
        url: this.genUrl,
      },
    });
  }

  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(event);
  }

  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}
