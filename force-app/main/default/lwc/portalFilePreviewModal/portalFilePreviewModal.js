import { api , wire } from "lwc";
import LightningModal from "lightning/modal";
import isCommunityContext from "@salesforce/apex/PortalClientSelector.isCommunityContext";
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/ContentDocument.Id";
import TITLE_FIELD from "@salesforce/schema/ContentDocument.Title";
import CONTENTSIZE_FIELD from "@salesforce/schema/ContentDocument.ContentSize";
import FILETYPE_FIELD from "@salesforce/schema/ContentDocument.FileType";
import LATESTPUBLISHEDVERSIONID_FIELD from "@salesforce/schema/ContentDocument.LatestPublishedVersionId";
import LASTMODIFIEDDATE_FIELD from "@salesforce/schema/ContentDocument.LastModifiedDate";

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
            CONTENTSIZE_FIELD ,
            FILETYPE_FIELD ,
            LASTMODIFIEDDATE_FIELD ,
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

    // https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_files_preview_format.htm

    @api
    get hasPreview() {
        const previewableFileTypes = [
            'PDF' ,
            'JPG' ,
            'PNG' ,
            'DOCX' ,
            'XLSX' ,
            'PPTX' ,
            'TEXT'
        ];
        return (
            this.versionId
            && this.previewUrl
            && this.contentSize
            && ( this.contentSize < 25000000 ) // PMCC ~ must be less than 25 MB to generate a preview...
            && this.fileType
            && previewableFileTypes.includes( this.fileType ) // PMCC ~ must be a "previewable" file type...
            && this.lastModifiedDate
            && ( this.millisecondsSinceLastModifiedDate > ( 5 * 60 * 1000 ) ) // 5 minutes ~ PMCC ~ using slight delay (for now) until ContentVersionRenditionContent exist for preview...
        );
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

    get contentSize() {
        return this.record?.fields?.ContentSize?.value;
    }

    get fileType() {
        return this.record?.fields?.FileType?.value;
    }

    get lastModifiedDate() {
        return this.record?.fields?.LastModifiedDate?.value;
    }

    get millisecondsSinceLastModifiedDate() {
        let local = 0;
        if ( this.lastModifiedDate ) {
            local = ( ( new Date() ) - new Date( this.lastModifiedDate ) )
        }
        return local;
    }

}
//