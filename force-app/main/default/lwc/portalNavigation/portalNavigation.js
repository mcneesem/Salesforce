import { LightningElement , wire , api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getRecord , getRecords } from "lightning/uiRecordApi";
import getPortalClients from "@salesforce/apex/PortalClientSelector.getPortalClients";
import isCommunityContext from "@salesforce/apex/PortalClientSelector.isCommunityContext";
import portalStaticResources from '@salesforce/resourceUrl/Portal';
import PORTAL_CLIENT_ID_FIELD from "@salesforce/schema/Portal_Client__c.Id";
import PORTAL_CLIENT_NAME_FIELD from "@salesforce/schema/Portal_Client__c.Name";
import PORTAL_CLIENT_CLIENT_NUMBER_FIELD from "@salesforce/schema/Portal_Client__c.Client_Number__c";
import USER_ID_FIELD from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';

export default class PortalNavigation extends NavigationMixin(LightningElement) {
    @api showVerticalNavigation;

    logoInsperity = portalStaticResources + '/svg/Insperity_Logo_Notag_WHITE.svg';
    iconAvatarBlue = portalStaticResources + '/svg/Name_BLUE_CIRCLE_RGB_30.svg';
    iconAvatarGreen = portalStaticResources + '/svg/Name_GREEN_CIRCLE_RGB_30.svg';

    userName;
    @wire( getRecord , { recordId: USER_ID_FIELD , fields: [USER_NAME_FIELD] })
    wiredUser( { error , data } ) {
        if ( data ) {
            this.userName = data.fields?.Name?.value;
        } else if ( error ) {
            this.error = error;
            this.userName = undefined;
        }
    }

    isCommunity = false;
    @wire( isCommunityContext )
    wiredIsCommunityContext( { error , data } ) {
        if ( !error && data && ( typeof data === 'boolean' ) ) {
            this.isCommunity = data;
        }
    }

    get logoutPageReference() {
        let pageReference;
        if ( this.isCommunity ) {
            // external logout url...
            pageReference = {
                type: 'comm__loginPage' ,
                attributes: {
                    actionName: 'logout' ,
                } ,
            };
        } else {
            // internal logout url...
            pageReference = {
                type: 'standard__webPage' ,
                attributes: {
                    url: "/secur/logout.jsp" ,
                } ,
            };
        }
        return pageReference;
    }

    handleUserMenuSelect( event ) {
        const value = event?.detail?.value;
        if ( ( value == "logout" ) && this.logoutPageReference ) {
            this[NavigationMixin.Navigate](
                this.logoutPageReference
            );
        }
    }

    //
    //
    //

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
                                PORTAL_CLIENT_ID_FIELD ,
                                PORTAL_CLIENT_NAME_FIELD ,
                                PORTAL_CLIENT_CLIENT_NUMBER_FIELD ,
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