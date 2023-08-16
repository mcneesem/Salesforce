import { LightningElement,api,wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import REPORT_REQUEST_OBJ from "@salesforce/schema/NSP_ReportRequest__c";
export default class LaunchWizardOnAccount extends LightningElement {
    @api recordId;
    @api error;
    recordObj={ RecordTypeId:'',NSP_ClientName__c:{displayValue: null, value: null}};
    isLoading = true;
    recordTypes;
    wizardName ='Edit Wizard';
    recordTypeMapping = {
                          survey : 'HR Survey Request',
                          development : 'Request a WebFocus or WIRE Report',
                          separation : 'Separation Agreement Request',
                          edit: 'Edit Wizard'
                        };

  get header(){
      const recTypeName = this.getRecordTypeName(this.wizardName);

      return this.recordTypeMapping[recTypeName];
  }
  get layoutSize(){
    return this.recordTypes.length ? 12 / this.recordTypes.length : 12;
  }
  get showDevelopReport(){
    return this.wizardName.includes('Development');
  }
  get showSurvey(){
    return  this.wizardName.includes('Survey');
  }
  get showSeperation(){
    return  this.wizardName.includes('Separation');
  }

    @wire(getObjectInfo, { objectApiName: REPORT_REQUEST_OBJ })
    objectInfo(result){
      if(result.data){
        if (result.data.recordTypeInfos) {
          let rtis = result.data.recordTypeInfos;
          this.recordTypes =[];
          Object.values(rtis).forEach((eachValues) => {
              if(eachValues.name !== 'Master' && eachValues.available &&
               ( eachValues.name.includes("Development") || eachValues.name.includes("Survey") || eachValues.name.includes("Separation"))){
                const tempObj  = { ...eachValues };
                const recTypeName = this.getRecordTypeName(tempObj.name);

                tempObj.label = this.recordTypeMapping[recTypeName];
                this.recordTypes.push(tempObj);
              }
           });
        }
      }
      else if (result.error) {
        this.error = result.error;
      }
    };

    openWizard(event){
        this.wizardName = event.currentTarget.name;
        this.recordObj.RecordTypeId = event.currentTarget.value;
        this.recordObj.NSP_ClientName__c.value = this.recordId;
        const modal = this.template.querySelector('c-modal');
        modal.show();
    }

    handleCloseModal() {
      const modal = this.template.querySelector('c-modal');
      modal.hide();
      document.location.reload();
      // return refreshApex(this.wiredReportRequestResult); 
  }

  getRecordTypeName(wizardName){
    return wizardName.includes('Survey') 
      ? 'survey' : wizardName.includes('Separation') 
      ? 'separation' : wizardName.includes('Development') 
      ? 'development' : 'edit';
  }
}