import { LightningElement , api , wire } from "lwc";
import LightningConfirm from "lightning/confirm";
import { NavigationMixin } from "lightning/navigation";
import Toast from "lightning/toast";
import { deleteRecord , getRecords } from "lightning/uiRecordApi";
import PortalFileListModal from "c/portalFileListModal";
import PortalFilePreviewModal from "c/portalFilePreviewModal";
import { refreshApex } from "@salesforce/apex";
import getPortalLinks from "@salesforce/apex/PortalClientSelector.getPortalLinks";
import ID_FIELD from "@salesforce/schema/ContentDocumentLink.Id";
import CONTENTDOCUMENTID_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocumentId";
import CONTENTDOCUMENT_CONTENTSIZE_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.ContentSize";
import CONTENTDOCUMENT_FILETYPE_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.FileType";
import CONTENTDOCUMENT_OWNERID_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.OwnerId";
import CONTENTDOCUMENT_OWNER_NAME_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.Owner.Name";
import CONTENTDOCUMENT_TITLE_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.Title";
import CONTENTDOCUMENT_LASTMODIFIEDDATE_FIELD from "@salesforce/schema/ContentDocumentLink.ContentDocument.LastModifiedDate";

export default class PortalTask extends NavigationMixin(LightningElement) {
    @api record; // is-a Portal_Task__c

    isVisibleBody = false;
    get showBody() {
        return ( this.isChild || this.isVisibleBody );
    }
    get hasBody() {
        return ( this.hasGuidance || this.isParent );
    }
    handleClickAccordion( event ) {
        event.stopPropagation();
        this.isVisibleBody = !this.isVisibleBody;
    }
    handleKeyDown( event ) {
        // only created to appease sonar...
    }
    get hasGuidance() {
        return false;
    }
    get isCompleted() {
        return ( this.record?.fields?.Status__c?.value === "Completed" );
    }

    @api variant;
    get isParent() {
        return ( !this.isChild );
    }
    get isChild() {
        return ( this.variant === "child" );
    }
    get titleSize() {
        return ( this.isChild ? "7" : "5" );
    }

    //
    // Files
    //

    get parentRecordId() {
        return ( this.record?.fields?.Id?.value ? this.record.fields.Id.value : undefined );
    }

    error;
    parameterObject; // is-a { recordIds: [...] , fields: [...] }
    wiredPortalLinksInfo;
    @wire( getPortalLinks , { linkedEntityId: "$parentRecordId" } )
    wiredPortalLinks( value ) {
        this.wiredPortalLinksInfo = value;
        const { error , data } = value;
        this.links = [];
        if ( data ) {
            // reduce the getPortalLinks wire response data to an array of ContentDocumentLink.Id values...
            // ~ data is-a List<ContentDocumentLink>
            const linkIds = data.map(
                function( link ) {
                    return link.Id;
                }
            );
            // populate the parameter object for the getRecords wire...
            this.parameterObject = [
                {
                    recordIds: linkIds ,
                    fields: [
                        ID_FIELD ,
                        CONTENTDOCUMENTID_FIELD ,
                        CONTENTDOCUMENT_CONTENTSIZE_FIELD ,
                        CONTENTDOCUMENT_FILETYPE_FIELD ,
                        CONTENTDOCUMENT_OWNERID_FIELD ,
                        CONTENTDOCUMENT_OWNER_NAME_FIELD ,
                        CONTENTDOCUMENT_TITLE_FIELD ,
                        CONTENTDOCUMENT_LASTMODIFIEDDATE_FIELD ,
                    ] ,
                }
            ];
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.parameterObject = undefined;
        }
    }

    links;
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

    handleClickUpload( event ) {
        event.stopPropagation();
    }

    get isLoading() {
        return ( !this.links || this.isDeleting );
    }

    get totalRelatedFiles() {
        return ( ( this.links ) ? this.links.length : 0 );
    }

    get showFileUpload() {
        return ( this.record?.fields?.Action__c?.value == "Box" );
    }

    handleUploadFinished( event ) {
        if ( event?.detail?.files?.length ) {
            this.showToastSuccess( "Success" , "File Uploaded" );
            this.refresh();
        }
    }

    async refresh() {
        await refreshApex( this.wiredPortalLinksInfo );
    }

    async handleClickFiles( event ) {
        if ( this.totalRelatedFiles > 0 ) {
            event.stopPropagation();
            await PortalFileListModal.open(
                {
                    label: ( this.record?.fields?.Name?.value ? this.record?.fields?.Name?.value : "Files" ) ,
                    size: "large" ,
                    description: "Displays linked files." ,
                    links: this.links ,
                    onnavigate: ( e ) => {
                        this.handleNavigate( e );
                    } ,
                }
            );
        }
    }

    handleNavigate( event ) {
        event.stopPropagation();
        switch ( event?.detail?.type ) {
            case 'external__filePreview':
                this.handleModalFilePreview( event?.detail?.state );
                break;
            case 'external__delete':
                this.handleModalConfirmDelete( event?.detail?.state );
                break;
            case 'standard__namedPage':
                this[NavigationMixin.Navigate]( event?.detail );
                break;
            case 'standard__recordPage':
                this[NavigationMixin.Navigate]( event?.detail );
                break;
            case 'standard__webPage':
                this[NavigationMixin.Navigate]( event?.detail );
                break;
            default:
                console.log( "handleNavigate: unsupported event.detail.type: " + event?.detail?.type );
        }
    }

    async handleModalFilePreview( state ) {
        if ( state ) {
            await PortalFilePreviewModal.open(
                {
                    label: "File Preview" ,
                    size: "large" ,
                    recordIds: state.recordIds ,
                    selectedRecordId: state.selectedRecordId ,
                }
            );
        }
    }

    // https://developer.salesforce.com/docs/platform/lightning-component-reference/guide/lightning-confirm.html
    // ~ use standard components where possible...

    async handleModalConfirmDelete( state ) {
        if ( state ) {
            let message = "Delete this file?";
            if ( state.name ) {
                message = "Delete the file (" + state.name + ")?";
            }
            const confirmation = await LightningConfirm.open(
                {
                    label: "Confirm File Delete" ,
                    message: message ,
                    theme: "warning" ,
                }
            );
            if ( confirmation ) {
                this.handleDeleteRecord( state );
            }
        }
    }

    isDeleting;
    async handleDeleteRecord( state ) {
        if ( state?.recordId ) {
            this.isDeleting = true;
            try {
                await deleteRecord( state?.recordId );
                this.showToastSuccess( "Success" , "File Deleted" );
            } catch ( error ) {
                this.showToastError( "Error Deleting File" , JSON.stringify( error ) );
            }
            this.isDeleting = false;
            this.refresh();
        }
    }

    //
    // Toasters
    //

    showToastSuccess( label , message ) {
        if ( label && message ) {
            this.showToastVariant( label , message , "success" );
        }
    }

    showToastError( label , message ) {
        if ( label && message ) {
            this.showToastVariant( label , message , "error" );
        }
    }

    showToastVariant( label , message , variant ) {
        if ( label && message && variant ) {
            this.showToast(
                {
                    label: label ,
                    message: message ,
                    variant: variant ,
                }
            );
        }
    }

    // https://developer.salesforce.com/docs/platform/lightning-component-reference/guide/lightning-toast.html
    // ~ LWR does not support lightning/platformShowToastEvent, use lightning-toast instead...

    showToast( toast ) {
        if ( toast ) {
            Toast.show( toast , this );
        }
    }

}
//