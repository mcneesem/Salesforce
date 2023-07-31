import { LightningElement, api, wire, track } from "lwc";
import loadIPRecords from "@salesforce/apex/NSP_FSOImplementationController.loadAutomationRecords";
import runIpAutomation from "@salesforce/apex/NSP_FSOImplementationController.runIpAutomations";

const columns = [
  {
    label: "Type",
    cellAttributes: {
      iconName: { fieldName: "iconsName" },
      iconPosition: "left",
    },
  },
  { label: "Automation", fieldName: "automationName" },
  {
    label: "Re Run",
    type: "button-icon",
    initialWidth: 75,
    typeAttributes: {
      iconName: "utility:play",
      name: "rerun",
      alternativeText: "Re Run",
      iconClass: { fieldName: "rerunCss" },
    },
  },
  { label: "Last Run", fieldName: "lastrun" },
];

export default class Nsp_implementationAutomations extends LightningElement {
  @api
  recordTypeId;
  @api
  recordId;
  @api
  objectApiName;

  column = columns;
  wiredActivities;
  @track _ipAutomationTable = [];
  @api 
  get ipAutomationTable(){
    return this._ipAutomationTable;
  }

  set ipAutomationTable(value){
    this._ipAutomationTable = this.clone(value);
  }

  @api getFormValues() {
    return {};
  }

  loadAutomationTable(){
    const { recordTypeId, recordId } = this;

    loadIPRecords({ recordTypeId, recordId }).then( wireResult => {
      if (wireResult) {
        this._ipAutomationTable = this.clone(wireResult);
      }
    }).catch((error) => {
      this.message = undefined;
      this.error = error;
    });
  }

  handleRowAction(event) {
    if (event.detail.action.name === "rerun") {
      var sectionIndex = event.target.dataset.itemindex;
      let list = this.ipAutomationTable[sectionIndex].automationTableList;
      let row = event.detail.row;
      let rowindex = list.findIndex(
        (list) => row.automationName === list.automationName
      );
      if (!row.isDisabled) {
        this.runIpAutomations(event, row, sectionIndex, rowindex);
      }
    }
  }
  runIpAutomations(event, row, sectionIndex, rowindex) {
    this.handleIconClick(sectionIndex, rowindex);
    runIpAutomation({
      recordId: this.recordId,
      automationType: row.automationType,
      automationMethodName: row.automationMethodName,
      ipRecordType:row.automationRecordType
    })
      .then((result) => {
        this.message = result;
        this.error = undefined;
        if (
          this.message !== undefined ||
          this.message !== "" ||
          result !== undefined ||
          result !== ""
        ) {
          if (result == true) {
            this.handleLogACall();
          }
        }
      })
      .catch((error) => {
        this.message = undefined;
        this.error = error;
      });
  }

  handleLogACall() {
    this.loadAutomationTable();
  }

  handleIconClick(sectionIndex, rowindex) {
    const elements =
      this.ipAutomationTable[sectionIndex].automationTableList[rowindex];
    let automationType = elements.automationType;
    let updatedIconName =
      automationType == "Email"
        ? "utility:email"
        : automationType == "PROJECT TASK CREATION"
        ? "utility:task"
        : automationType == "CASE CREATION"
        ? "utility:case"
        : "";
    let iconName = { ...elements, iconsName: updatedIconName };
    this._ipAutomationTable[sectionIndex].automationTableList[rowindex] =
      iconName;
    this._ipAutomationTable = this.clone(this._ipAutomationTable);
  }

  clone(value){
    return JSON.parse(JSON.stringify(value));
  }
}