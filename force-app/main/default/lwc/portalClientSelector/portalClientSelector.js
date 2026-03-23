import { LightningElement , wire } from "lwc";
import { getRecords } from "lightning/uiRecordApi";
import getPortalClients from "@salesforce/apex/PortalClientSelector.getPortalClients";
import isCommunityContext from "@salesforce/apex/PortalClientSelector.isCommunityContext";
import { CurrentPageReference } from 'lightning/navigation';
import ID_FIELD from "@salesforce/schema/Portal_Client__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Client__c.Name";
import CLIENT_NUMBER_FIELD from "@salesforce/schema/Portal_Client__c.Client_Number__c";

export default class PortalClientSelector extends LightningElement {

    isCommunity = false;
    @wire( isCommunityContext )
    wiredIsCommunityContext( { error , data } ) {
        if ( !error && data && ( typeof data === 'boolean' ) ) {
            this.isCommunity = data;
        }
    }

    isCommunityBuilder = false;
    @wire( CurrentPageReference )
    wiredCurrentPageReference( reference ) {
        if ( reference?.state?.app === "commeditor" ) {
            this.isCommunityBuilder = true;
        }
    }

    parameterObject;
    clients = [];
    @wire( getPortalClients )
    wiredPortalClients( { error , data } ) {
        if ( data ) {
            this.clients = data;
            this.parameterObject = [];
            this.clients.forEach(
                ( client ) => {
                    this.parameterObject.push(
                        {
                            recordIds: [ client.Id ] ,
                            fields: [
                                ID_FIELD ,
                                NAME_FIELD ,
                                CLIENT_NUMBER_FIELD ,
                            ] ,
                        }
                    );
                }
            );
        } else if ( error ) {
            this.clients = undefined;
            this.parameterObject = undefined;
        }
    }

    recordId;
    error;
    records;
    @wire( getRecords , { records: "$parameterObject" } )
    recordsInfo( { error , data } ) {
        if ( data ) {
            this.records = data?.results?.map(
                function( record ) {
                    let label = record.result.fields.Name.value;
                    if ( record.result.fields.Client_Number__c.value ) {
                        label = label + ' (' + record.result.fields.Client_Number__c.value + ')';
                    }
                    return {
                        label: label ,
                        value: record.result.fields.Id.value ,
                    };
                }
            );
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