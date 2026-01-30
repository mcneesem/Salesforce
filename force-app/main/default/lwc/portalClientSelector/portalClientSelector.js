import { LightningElement , wire } from 'lwc';
import { getRecords } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/Portal_Client__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Client__c.Name";
import CLIENT_NUMBER_FIELD from "@salesforce/schema/Portal_Client__c.Client_Number__c";

export default class PortalClientSelector extends LightningElement {
    recordId;
    error;
    records;
    @wire(getRecords, {
        records: [
            {
                recordIds : [
                ] ,
                fields : [
                    ID_FIELD ,
                    NAME_FIELD ,
                    CLIENT_NUMBER_FIELD ,
                ] ,
            } ,
        ] ,
    })
    recordsInfo({ error, data }) {
        if ( data ) {
            let local = [];
            data.results.forEach((record) => {
                let label = record.result.fields.Name.value + ' (' + record.result.fields.Client_Number__c.value + ')'
                local.push({
                    label : label ,
                    value : record.result.fields.Id.value ,
                });
            });
            this.records = local;
            if ( this.records.length > 0 ) {
                this.recordId = this.records[0].value;
            }
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.records = undefined;
        }
    }

    handleChange( event ) {
        this.recordId = event.detail.value;
    }

}
//