import { LightningElement , api , wire } from 'lwc';
import { getRecords } from "lightning/uiRecordApi";
import getPortalLinks from "@salesforce/apex/PortalClientSelector.getPortalLinks";
import { refreshApex } from "@salesforce/apex";
import CONTENTDOCUMENTLINK_ID_FIELD from "@salesforce/schema/ContentDocumentLink.Id";
import CONTENTDOCUMENTLINK_CONTENTDOCUMENTID_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocumentId";
import CONTENTDOCUMENTLINK_CONTENTDOCUMENT_CONTENTSIZE_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.ContentSize";
import CONTENTDOCUMENTLINK_CONTENTDOCUMENT_FILETYPE_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.FileType";
import CONTENTDOCUMENTLINK_CONTENTDOCUMENT_OWNERID_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.OwnerId";
import CONTENTDOCUMENTLINK_CONTENTDOCUMENT_OWNER_NAME_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.Owner.Name";
import CONTENTDOCUMENTLINK_CONTENTDOCUMENT_TITLE_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.Title";
import CONTENTDOCUMENTLINK_CONTENTDOCUMENT_LASTMODIFIEDDATE_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.LastModifiedDate";

export default class PortalRelatedFiles extends LightningElement {
    @api linkedEntityId; // is-a ANY.Id

    error;
    parameterObject; // is-a { recordIds: [...] , fields: [...] }
    wiredPortalLinksInfo;
    @wire( getPortalLinks , { linkedEntityId: "$linkedEntityId" } )
    wiredPortalLinks( value ) {
        this.wiredPortalLinksInfo = value;
        const { error , data } = value;
        if ( data ) {
            // reduce the getPortalLinks wire response data to an array of ContentDocumentLink.Id values...
            // ~ data is-a List<ContentDocumentLink>
            const linkIds = data.map(
                function( link ) {
                    return link.Id;
                }
            );
            if ( linkIds?.length > 0 ) {
                this.links = undefined; // continue showing loading spinner...
            } else {
                this.links = []; // show empty state...
            }
            // populate the parameter object for the getRecords wire...
            this.parameterObject = [
                {
                    recordIds: linkIds ,
                    fields: [
                        CONTENTDOCUMENTLINK_ID_FIELD ,
                        CONTENTDOCUMENTLINK_CONTENTDOCUMENTID_FIELD ,
                        CONTENTDOCUMENTLINK_CONTENTDOCUMENT_CONTENTSIZE_FIELD ,
                        CONTENTDOCUMENTLINK_CONTENTDOCUMENT_FILETYPE_FIELD ,
                        CONTENTDOCUMENTLINK_CONTENTDOCUMENT_OWNERID_FIELD ,
                        CONTENTDOCUMENTLINK_CONTENTDOCUMENT_OWNER_NAME_FIELD ,
                        CONTENTDOCUMENTLINK_CONTENTDOCUMENT_TITLE_FIELD ,
                        CONTENTDOCUMENTLINK_CONTENTDOCUMENT_LASTMODIFIEDDATE_FIELD ,
                    ] ,
                }
            ];
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.parameterObject = undefined;
        }
    }

    _links;
    get links() {
        return this._links;
    }
    set links( value ) {
        this._links = value;
        this.dispatchEvent(
            new CustomEvent(
                "loaded" ,
                {
                    detail: this._links ,
                }
            )
        );
    }

    @wire( getRecords , { records: "$parameterObject" } )
    wiredRecords( { error , data } ) {
        if ( data ) {
            this.links = data?.results?.map(
                function( record ) {
                    return record?.result;
                }
            );
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.links = undefined;
        }
    }

    _modstamp; // is-a timestamp in milliseconds
    @api
    get modstamp() {
        return this._modstamp;
    };
    set modstamp( value ) {
        let isModified = (
            this._modstamp
            && ( this._modstamp != value )
        );
        this._modstamp = value;
        if ( isModified ) {
            this.refresh();
        }
    };
    async refresh() {
        await refreshApex( this.wiredPortalLinksInfo );
    }

}
//