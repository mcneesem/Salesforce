import { LightningElement , wire , api } from "lwc";
import { getRecords } from "lightning/uiRecordApi";
import getPortalClients from "@salesforce/apex/PortalClientSelector.getPortalClients";
import ID_FIELD from "@salesforce/schema/Portal_Client__c.Id";
import NAME_FIELD from "@salesforce/schema/Portal_Client__c.Name";
import CLIENT_NUMBER_FIELD from "@salesforce/schema/Portal_Client__c.Client_Number__c";

export default class PortalNavigation extends LightningElement {
    @api showVerticalNavigation;

    error;
    parameterObject;
    navigationItems;
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
            if ( this.parameterObject && ( this.parameterObject.length <= 0 ) ) {
                // default navigation items...
                this.navigationItems = [
                    {
                        label: "Home" ,
                        name: "home" ,
                        iconName: "utility:home" ,
                    } ,
                ];
            }
        } else if ( error ) {
            this.error = error;
            this.clients = undefined;
            this.parameterObject = undefined;
        }
    }

    recordId;
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
                // select first navigation item...
                this.navigationItems = [
                    {
                        label: "Onboarding" ,
                        name: "onboarding" ,
                        iconName: "utility:task" ,
                    } ,
                ];
            }
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.records = undefined;
        }
    }

    get isLoading() {
        return !this.navigationItems;
    }

    get selectedItem() {
        return ( ( this.navigationItems && ( this.navigationItems.length > 0 ) ) ? this.navigationItems[0].name : undefined );
    }

    handleChange( event ) {
        this.recordId = event.detail.value;
    }

}
//