import { LightningElement, api, track, wire } from "lwc";

import { CloseActionScreenEvent } from "lightning/actions";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from '@salesforce/apex';

import getRecordDetails from "@salesforce/apex/NSP_NAICSandSICCompController.getRecordDetails";
import saveRecordApex from "@salesforce/apex/NSP_NAICSandSICCompController.saveRecord";

import nspCodesjs from "@salesforce/resourceUrl/NSP_NAICSAndSICCodes";
import { loadScript } from "lightning/platformResourceLoader";
import { getRecordNotifyChange } from 'lightning/uiRecordApi'; //DF-1164 
let sicAndNaics;
export default class NspNaicsAndSicComp extends LightningElement {
  @track Account = {};
  @api searchKeyword = "";
  @api recordId;
  @track industry_description; //variable to store NAICS/SIC description
  @track industry_code; //variable to store NAICS/SIC code
  @track naicsOrSic; //stores if current selection on screen is SIC or NAICS
  @track select_list = []; //list to store all filtered values(code+description)
  @track searchFieldLabel;
  @track buttonLabel; //Save button label to Save NAICS or SIC
  @track sObjectApiName;
  wireResult;
  accountName;
  doneTypingInterval = 300;
  typingTimer;

  NAICS_codes = []; //list to store NAICS Codes from static resource js file
  NAICS_descs = []; //list to store NAICS Descriptions from static resource js file

  SIC_codes = []; //list to store SIC Codes from static resource js file
  SIC_descs = []; //list to store SIC Descriptions from static resource js file

  CODES = []; //list to store picklist Codes based on NAICS/SIC selection
  DESCS = []; //list to store picklist Codes based on NAICS/SIC selection

  //to fetch initial field values from the account record and display on screen
  @wire(getRecordDetails, { recordId: "$recordId" })
  getAccountDetails(result) {
    this.wireResult = result;
    //set SIC/NAICS Codes/Descs with values present in the static resource js file
    if (typeof sicAndNaics != "undefined") {
      this.NAICS_codes = sicAndNaics.naicsCode;
      this.NAICS_descs = sicAndNaics.naicsDesc;
      this.SIC_codes = sicAndNaics.sicCode;
      this.SIC_descs = sicAndNaics.sicDesc;
    }

    //set initial field values on screen load
    if (result && result.data != undefined) {
      this.Account = result.data.recordMap;
      this.sObjectApiName = result.data.sObjectName;
      this.accountName = result.data.recordMap.Name;
      this.setPicklistValues();          
    }
    //this.setPicklistValues();
  }

  //input values for Radio button to choose between NAICS and SIC
  get codeOptions() {
    return [
      { label: "NAICS", value: "NAICS" },
      { label: "SIC", value: "SIC" },
    ];
  }

  //method to assign input field values when Input changes for Industry Descriptions or Codes
  handleFieldValueChange(event) {
    if (event.target.name === "industry_code") {
      this.industry_code = event.target.value;
    } else if (event.target.name === "industry_description") {
      this.industry_description = event.target.value;
    }
  }

  //set correct field labels, picklists and existing values based
  // on NAICS or SIC selection in radio buttons
  handleNaicsSicChange(event) {
    const selectedOption = event.detail.value;
    if (selectedOption == "NAICS") {
      this.naicsOrSic = "NAICS";
      this.DESCS = this.NAICS_descs;
      this.CODES = this.NAICS_codes;
      this.setPicklistValues();
    } else if (selectedOption == "SIC") {
      this.naicsOrSic = "SIC";
      this.DESCS = this.SIC_descs;
      this.CODES = this.SIC_codes;

      this.setPicklistValues();
    }
  }

  //search codes/descriptions based on the input value/searchKeyword
  //added debouncing to search after 300ms interval
  filterNAICS(event) {
    clearTimeout(this.typingTimer);
    this.searchKeyword = event.target.value;

    this.typingTimer = setTimeout(() => {
      this.searchNAICS_SIC(event);
    }, this.doneTypingInterval);
  }

  //set values to SIC/NAICS code/desc fields based on the selection after search
  handlePicklistChange(event) {
    this.industry_code = event.target.value.split(" - ")[0];
    this.industry_description = event.target.value.split(" - ")[1];
  }

  //initialise fields, picklists on component load
  connectedCallback() {
    loadScript(this, nspCodesjs).then(() => {
      sicAndNaics = fetchIndustryCodes();
    });

    this.naicsOrSic = "SIC";
    this.DESCS = this.NAICS_descs;
    this.CODES = this.NAICS_codes;
    this.setPicklistValues();
  }

  //method to set picklist values, field/button labels based on
  // the selection of NAICS or SIC in radio button
  setPicklistValues() {
    let select_list_2 = [];
    this.codeFieldLabel = this.naicsOrSic + " Code";
    this.descFieldLabel = this.naicsOrSic + " Description";
    this.buttonLabel = "Save " + this.naicsOrSic;
    this.searchFieldLabel = "Search and Select " + this.naicsOrSic;
    if (this.naicsOrSic === "NAICS") {
      for (let i = 0; i < this.NAICS_descs.length; i++) {
        select_list_2.push({
          label: this.NAICS_codes[i] + " - " + this.NAICS_descs[i],
          value: this.NAICS_codes[i] + " - " + this.NAICS_descs[i],
        });
      }
      this.industry_code = this.Account.Naics;
      this.industry_description = this.Account.NaicsDesc;
    } else if (this.naicsOrSic === "SIC") {
      for (let i = 0; i < this.SIC_descs.length; i++) {
        select_list_2.push({
          label: this.SIC_codes[i] + " - " + this.SIC_descs[i],
          value: this.SIC_codes[i] + " - " + this.SIC_descs[i],
        });
      }
      this.industry_code = this.Account.Sic;
      this.industry_description = this.Account.SicDesc;
    }

    this.select_list = select_list_2;
  }

  //method called when clicked on Save SIC/NAICS button
  // fields updated on Account record will be based on the radio button selection
  handleSave() {
    let recordMap = new Map();    
    recordMap['Id'] = this.recordId;
      
      //assign values in input fields to appropriate account fields based on SIC/NAICS selection
      if (this.naicsOrSic == "NAICS") {        
        recordMap['Sic'] = this.Account.Sic;
        recordMap['SicDesc'] = this.Account.SicDesc;
        //update only NAICS fields from the value in the input fields based on selected radio button
        recordMap['Naics'] = this.industry_code;
        recordMap['NaicsDesc'] = this.industry_description;

      } else if (this.naicsOrSic == "SIC") {
        recordMap['Naics'] =  this.Account.Naics;
        recordMap['NaicsDesc'] =  this.Account.NaicsDesc;
        //update only SIC fields from the value in the input fields based on selected radio button
        recordMap['Sic'] =  this.industry_code;
        recordMap['SicDesc'] =  this.industry_description;
      }   
    saveRecordApex({recordMap : recordMap, objectApiName : this.sObjectApiName})
    .then((result) => {
      //DF-1164 - refresh page on save
      getRecordNotifyChange([{recordId: this.recordId}]);
      let successMessage = this.naicsOrSic == "SIC" ? "SIC" : "NAICS";
      this.showToast(
        "Success",
        successMessage + " updated Successfully!",
        "success"
      );
      //to refresh the result variable to update the record with latest values
      //in the record retrieved from @wire method
      refreshApex(this.wireResult);
      
    }).catch((error) => {
      this.showToast(
        "error",
        error,
        "error"
      );
    })
  }

  //method used to search NAICS/SIC based on the radio button selection and
  // search keyWord
  searchNAICS_SIC(event) {
    let select_list_2 = [];
    for (let i = 0; i < this.DESCS.length; i++) {
      if (isNaN(this.searchKeyword)) {
        let naicsDesc = this.DESCS[i].toLowerCase(); //the search term
        let each_naicsDesc = naicsDesc.split(" "); //each word in the array item

        //for each array word, see if it matches
        for (let j = 0; j < each_naicsDesc.length; j++) {
          let searchstr = this.searchKeyword.toLowerCase();
          if (each_naicsDesc[j].match("^" + searchstr)) {
            //if string matches
            if (select_list_2.length == 0)
              //if empty, that means we're adding the first value, so add a default value first
              select_list_2.push({
                label: "--Choose an option--",
                value: "",
              });

            select_list_2.push({
              label: this.CODES[i] + " - " + this.DESCS[i],
              value: this.CODES[i] + " - " + this.DESCS[i],
            });
            break; //we don't want to add the same option twice
          }
        }
      } else {
        //if string matches
        if (this.CODES[i].match("^" + this.searchKeyword)) {
          if (select_list_2.length == 0)
            //if empty, that means we're adding the first value, so add a default value first
            select_list_2.push({ label: "--Choose an option--", value: "" });
          select_list_2.push({
            label: this.CODES[i] + " - " + this.DESCS[i],
            value: this.CODES[i] + " - " + this.DESCS[i],
          });
          //break; //we don't want to add the same option twice
        }
      }
    }

    this.select_list = select_list_2;
    // select_list_2;
  }

  renderedCallback() {}

  //call this method with appropriate parameters to show success or error toast messages
  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
      mode: "dismissable",
    });
    this.dispatchEvent(event);
  }

  closeQuickAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }
}