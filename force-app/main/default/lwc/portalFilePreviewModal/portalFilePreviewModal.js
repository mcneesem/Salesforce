import { api , wire } from "lwc";
import LightningModal from "lightning/modal";
import isCommunityContext from "@salesforce/apex/PortalClientSelector.isCommunityContext";
import { getRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/ContentDocument.Id";
import TITLE_FIELD from "@salesforce/schema/ContentDocument.Title";
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

    get versionId() {
        return this.record?.fields?.LatestPublishedVersionId?.value;
    }

    get rendition() {
        // JPGZ ~ jpeg thumbnail...
        // THUMB120BY90 ~ x-small thumbnail...
        // THUMB240BY180 ~ small thumbnail...
        // THUMB720BY480 ~ large thumbnail...
        return "THUMB720BY480";
    }

    get previewUrl() {
        return ( this.isCommunity ? './sfsites/c' : '' )
            + '/sfc/servlet.shepherd/version/renditionDownload'
            + '?rendition=' + this.rendition
            + '&versionId=' + this.versionId
            ;
    }

    get hasPreviewUrl() {
        return ( this.versionId && this.previewUrl );
    }

    // img.onload OR img.onerror will fire after img.src is populated with the previewUrl...
    isPreviewLoaded;
    handleImageLoad( event ) {
        this.isPreviewLoaded = true;
        this.isPreviewErrored = false;
    }

    // img.onload OR img.onerror will fire after img.src is populated with the previewUrl...
    isPreviewErrored;
    handleImageError( event ) {
        this.isPreviewErrored = true;
        this.isPreviewLoaded = false;
    }

    // true only if img.onerror has fired...
    get hasPreviewError() {
        return this.isPreviewErrored;
    }

    // true until img.onload OR img.onerror have fired...
    get isPreviewLoading() {
        return ( !this.isPreviewLoaded && !this.hasPreviewError );
    }

    //
    // preview lifecyle...
    // ~ show loading message and spinner
    // ~ wire record
    // ~ has versionId
    // ~ has previewUrl
    // ~ img starts loading
    // ~ img onload/onerror fires
    //   ~ img.onload OR img.onerror occurrs
    //     ~ onload
    //       ~ is loaded / show image
    //     ~ onerror
    //       ~ is errored / show button
    //

    // hide image while image loading...
    // hide image if error during image loading...
    get imageClass() {
        return ( ( this.isPreviewLoading || this.hasPreviewError ) ? "slds-hide" : "slds-show" );
    }

    // show download button if error during image loading...
    get buttonClass() {
        return ( this.hasPreviewError ? "slds-show" : "slds-hide" );
    }

    // true if any message is ready to be displayed...
    get hasMessage() {
        return ( this.message && ( this.message != "" ) );
    }

    // translate image loading/error state to text...
    get message() {
        let local = "";
        if ( !this.hasPreviewUrl || this.isPreviewLoading ) {
            local = "Loading preview...";
        } else if ( this.hasPreviewError ) {
            local = "No preview available";
        }
        return local;
    }

    handleDownloadClick( event ) {
        this.download();
    }

    // "File Download"
    // ~ navigate to standard internal File Download Page...
    pageReference;
    download() {
        if ( this.selectedRecordId ) {
            this.pageReference = {
                type: 'standard__webPage' ,
                attributes: {
                    url: ( this.isCommunity ? './sfsites/c' : '' ) + '/sfc/servlet.shepherd/document/download/' + this.selectedRecordId ,
                } ,
            };
        }
    }

}
//