import { api , wire } from "lwc";
import LightningModal from "lightning/modal";
import isCommunityContext from "@salesforce/apex/PortalClientSelector.isCommunityContext";
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/ContentDocument.Id";
import TITLE_FIELD from "@salesforce/schema/ContentDocument.Title";
import FILETYPE_FIELD from "@salesforce/schema/ContentDocument.FileType";
import LATESTPUBLISHEDVERSIONID_FIELD from "@salesforce/schema/ContentDocument.LatestPublishedVersionId";

export default class PortalFilePreviewModal extends LightningModal {
    @api recordIds // is-a comma-separated String of ContentDocument.Id values
    @api selectedRecordId // is-a ContentDocument.Id

    handleClose() {
        this.close( "close" );
    }

    @api label;
    get modalLabel() {
        return ( ( this.label ) ? this.label : "File Preview" );
    }

    isCommunity = false;
    @wire( isCommunityContext )
    wiredIsCommunityContext( { error , data } ) {
        if ( !error && data && ( typeof data === 'boolean' ) ) {
            this.isCommunity = data;
        }
    }

    error;
    record; // is-a ContentDocument
    @wire( getRecord , {
        recordId: "$selectedRecordId" ,
        fields: [
            ID_FIELD ,
            TITLE_FIELD ,
            FILETYPE_FIELD ,
            LATESTPUBLISHEDVERSIONID_FIELD ,
        ] ,
    })
    recordInfo( { error , data } ) {
        if ( data ) {
            this.record = data;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.record = undefined;
        }
    }

    @api
    get previewUrl() {
        return ( this.isCommunity ? './sfsites/c' : '' )
            + '/sfc/servlet.shepherd/version/renditionDownload'
            + '?rendition=' + this.rendition
            + '&versionId=' + this.versionId
            ;
    }

    get rendition() {
        // JPGZ ~ jpeg thumbnail...
        // THUMB120BY90 ~ x-small thumbnail...
        // THUMB240BY180 ~ small thumbnail...
        // THUMB720BY480 ~ large thumbnail...
        return "THUMB720BY480";
    }

    get versionId() {
        return this.record?.fields?.LatestPublishedVersionId?.value;
    }

}
//