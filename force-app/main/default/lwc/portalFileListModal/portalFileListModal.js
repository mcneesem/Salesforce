import { api , wire } from "lwc";
import LightningModal from "lightning/modal";
import isCommunityContext from "@salesforce/apex/PortalClientSelector.isCommunityContext";
import useFileActions from "@salesforce/customPermission/Portal_Use_File_Actions";

export default class PortalFileListModal extends LightningModal {
    @api links; // is-a ContentDocumentLink[]
    @api disabled; // is-a Boolean

    isCommunity = false;
    @wire( isCommunityContext )
    wiredIsCommunityContext( { error , data } ) {
        if ( !error && data && ( typeof data === 'boolean' ) ) {
            this.isCommunity = data;
        }
    }

    handleClose() {
        this.close( "close" );
    }

    @api label;
    get modalLabel() {
        return ( ( this.label ) ? this.label : "Uploaded Files" );
    }

    // comma separated string of all linked ContentDocument.Id values...
    get documentIds() {
        let contentDocumentIds = [];
        if ( this.links ) {
            contentDocumentIds = this.links.map( link => link.fields.ContentDocumentId.value );
        }
        let response = '';
        if ( contentDocumentIds && ( contentDocumentIds.length > 0 ) ) {
            response = contentDocumentIds.join( ',' );
        }
        return response;
    }

    _columns;
    get columns() {
        if ( !this._columns ) {
            this._columns = [
                {
                    label: 'Title' ,
                    fieldName: 'title' ,
                    type: 'text' ,
                    sortable: false ,
                    cellAttributes: {
                        iconName: { fieldName: 'titleIcon' } ,
                        iconAlternativeText: 'File Type' ,
                    } ,
                } ,
                {
                    label: 'Owner' ,
                    fieldName: 'owner' ,
                    type: 'text' ,
                    sortable: false ,
                } ,
                {
                    label: 'Last Modified' ,
                    fieldName: 'lastModified' ,
                    type: 'date' ,
                    typeAttributes: {
                        year: "numeric" ,
                        month: "numeric" ,
                        day: "numeric" ,
                        hour: "2-digit" ,
                        minute: "2-digit" ,
                        timeZoneName: "short" ,
                    } ,
                    sortable: false ,
                } ,
                {
                    label: 'Size' ,
                    fieldName: 'size' ,
                    type: 'text' ,
                    sortable: false ,
                } ,
            ];
            if ( this.hasActions ) {
                this._columns.push(
                    {
                        type: 'action' ,
                        typeAttributes: { rowActions: this.actions } ,
                    },
                );
            }
        }
        return this._columns;
    }

    _data;
    get data() {
        if ( !this._data && this.links ) {
            this._data = this.links.map(link => {
                return {
                    documentId: link.fields.ContentDocumentId.value ,
                    titleIcon: this.fileTypeIcon( link.fields.ContentDocument.value.fields.FileType.value ) ,
                    title: link.fields.ContentDocument.value.fields.Title.value ,
                    owner: link.fields.ContentDocument.value.fields.Owner.value.fields.Name.value ,
                    lastModified: link.fields.ContentDocument.value.fields.LastModifiedDate.value ,
                    size: this.printableContentSize( link.fields.ContentDocument.value.fields.ContentSize.value ) ,
                }
            });
        }
        return this._data;
    }

    fileTypeIcon( value ) {
        let response = "utility:form";
        if ( value ) {
            switch ( value ) {
                case "TEXT":
                    response = "doctype:txt";
                    break;
                case "WORD_X":
                    response = "doctype:word";
                    break;
                default:
            }
        }
        return response;
    }

    printableContentSize( value ) {
        let response = "";
        if ( value ) {
            response = "" + Math.floor( value ) + "B";
            if ( value >= 1000 ) {
                response = "" + Math.floor( value/1000 ) + "KB";
            }
            if ( value >= 1000000 ) {
                response = "" + Math.floor( value/1000000 ) + "MB";
            }
            if ( value >= 1000000000 ) {
                response = "" + Math.floor( value/100000000 ) + "GB";
            }
            if ( value >= 1000000000000 ) {
                response = "" + Math.floor( value/100000000000 ) + "TB";
            }
        }
        return response;
    }

    get canUseFileActions() {
        return ( useFileActions === true );
    }

    // PMCC ~ each action may be gated by Custom Permission or other criteria...
    _actions;
    get actions() {
        if ( !this._actions ) {
            let local = [];
            if ( this.canUseFileActions ) {
                local.push( { label: 'Preview' , name: 'previewExternal' } );
                local.push( { label: 'Download' , name: 'download' } );
                if ( !this.disabled ) {
                    local.push( { label: 'Delete' , name: 'deleteExternal' } );
                }
            } else {
                local.push( { label: 'No actions available' , name: 'none' , disabled: true } );
            }
            this._actions = local;
        }
        return this._actions;
    }

    get hasActions() {
        return ( this.actions?.length > 0 );
    }

    handleRowAction( event ) {
        const actionName = event?.detail?.action?.name;
        const row = event?.detail?.row;
        switch ( actionName ) {
            case 'previewExternal':
                this.previewExternal( row );
                break;
            case 'download':
                this.download( row );
                break;
            case 'deleteExternal':
                this.deleteExternal( row );
                break;
            default:
                console.log( "handleRowAction: unsupported event.detail.action.name: " + event?.detail?.action?.name );
        }
    }

    //
    // https://developer.salesforce.com/docs/platform/lwc/guide/use-navigate-modal.html
    // Navigate From a Modal
    //

    //
    // (internal) standard navigation row actions...
    //

    pageReference;

    // "File Download"
    // ~ navigate to standard internal File Download Page...
    download( row ) {
        if ( row?.documentId ) {
            this.pageReference = {
                type: 'standard__webPage' ,
                attributes: {
                    url: ( this.isCommunity ? './sfsites/c' : '' ) + '/sfc/servlet.shepherd/document/download/' + row.documentId ,
                } ,
            };
        }
    }

    //
    // (external) custom community row actions...
    //

    // "File Preview (External)"
    // ~ navigate to custom external File Preview Modal...
    previewExternal( row ) {
        const local = this.documentIds;
        if ( row?.documentId && local ) {
            this.pageReference = {
                type: 'external__filePreview' ,
                attributes: {
                    pageName: "filePreview",
                } ,
                state: {
                    recordIds: local ,
                    selectedRecordId: row.documentId ,
                } ,
            };
        }
    }

    // "Delete File"
    // ~ navigate to custom external delete Cotent Document action...
    async deleteExternal( row ) {
        if ( row?.documentId ) {
            this.pageReference = {
                type: 'external__delete' ,
                attributes: {
                    pageName: "delete",
                } ,
                state: {
                    recordId: row.documentId ,
                    name: row.title ,
                } ,
            };
        }
    }

}
//