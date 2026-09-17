import { LightningElement, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import REPORT_REQUEST_OBJ from "@salesforce/schema/NSP_ReportRequest__c";
import { LABEL } from './constants';

export default class WizardHomePage extends LightningElement {
    objectApiName;

    @wire(getObjectInfo, { objectApiName: REPORT_REQUEST_OBJ })
    objectInfo;

    handleSectionToggle(event) {
    }

    get recordTypes() {
      if (this.objectInfo.data) {
        if (this.objectInfo.data.recordTypeInfos) {
          const rtis = this.objectInfo.data.recordTypeInfos;
          let recordTypes =[];
          Object.values(rtis).forEach((eachValues) => {
              if(eachValues.name !== 'Master' && eachValues.available){
                let recordType={...eachValues};

                if(eachValues.name.includes(LABEL.wizardRecordType)){
                  recordType.name=LABEL.wizardReportName;
                }
                if(eachValues.name.includes(LABEL.wizardSeperationRecordType)){
                  recordType.name=LABEL.wizardSeperationRequest;
                }
                if (eachValues.name.includes(LABEL.wizardHRScaleRecordType)) {
                  recordType.name = LABEL.wizardHRScaleReportName;
                }

                recordTypes.push(recordType);
              }
           });

           return JSON.parse(JSON.stringify(recordTypes));;
        }
      }
      return null;
    }

    handleCloseModal(){

        const draftWizard = this.template.querySelector('c-handle-draft-wizards');
        draftWizard.refreshdraft();
       // this.showDrafts = true ;
    }
}
