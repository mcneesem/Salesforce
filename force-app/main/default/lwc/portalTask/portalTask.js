import { LightningElement , api , wire } from "lwc";
import LightningConfirm from "lightning/confirm";
import { NavigationMixin } from "lightning/navigation";
import Toast from "lightning/toast";
import { deleteRecord } from "lightning/uiRecordApi";
import { getRelatedListRecords } from "lightning/uiRelatedListApi";
import PortalFileListModal from "c/portalFileListModal";
import PortalFilePreviewModal from "c/portalFilePreviewModal";
import logInfo from "@salesforce/apex/PortalClientSelector.logInfo";
import viewErrorPanel from "@salesforce/customPermission/View_Error_Panel";

export default class PortalTask extends NavigationMixin(LightningElement) {

    _record; // is-a Portal_Task__c
    get record() {
        return this._record;
    }
    @api
    set record( value ) {
        this._record = value;
        this.modified();
    }

    _children; // is-a List<Portal_Task__c>
    get children() {
        return this._children;
    }
    @api
    set children( value ) {
        this._children = value;
        this.calculateSummaryStatus();
    }

    get hasChildren() {
        return ( this.children?.length > 0 );
    }

    @wire(getRelatedListRecords, {
        parentRecordId: "$recordId" ,
        relatedListId: "Child_Portal_Tasks__r" ,
        fields: [
            "Portal_Task__c.Id" ,
            "Portal_Task__c.Status__c" ,
        ] ,
        sortBy: [ "Portal_Task__c.Rank__c" ]
    })
    childrenInfo({ error, data }) {
        if ( data ) {
            this.children = data.records;
            // only show visible children...
            // ~ ignore children with a "Hidden" status...
            this.children = data.records?.filter(
                ( child ) => {
                    return ( child?.fields?.Status__c?.value != "Hidden" );
                }
            );
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.children = undefined;
        }
    }

    //
    // Field Accessors
    //

    get recordId() {
        return ( this.record?.fields?.Id?.value ? this.record.fields.Id.value : undefined );
    }

    get action() {
        return ( this.record?.fields?.Action__c?.value ? this.record.fields.Action__c.value : undefined );
    }

    get dueDate() {
        return ( this.record?.fields?.Due_Date__c?.value ? this.record.fields.Due_Date__c.value : undefined );
    }

    get guidanceId() {
        return ( this.record?.fields?.Portal_Guidance__c?.value ? this.record.fields.Portal_Guidance__c.value : undefined );
    }

    get hasProjectTask() {
        return ( this.record?.fields?.Has_Project_Task__c?.value );
    }

    get isEditable() {
        return ( this.record?.fields?.Is_Editable__c?.value );
    }

    get name() {
        return ( this.record?.fields?.Name?.value ? this.record.fields.Name.value : undefined );
    }

    get recordStatus() {
        return this.record?.fields?.Status__c?.value;
    }

    get status() {
        let local = this.recordStatus;
        if ( this.summaryStatus ) {
            local = this.summaryStatus;
        }
        return local;
    }

    get isSummary() {
        return ( this.recordStatus == "Summary" );
    }

    summaryStatus;
    calculateSummaryStatus() {
        let local;
        if ( this.isSummary && this.hasChildren ) {
            const rankedStatuses = [
                "Pending" ,
                "Pending - Client" ,
                "Pending - Insperity" ,
                "Completed" ,
            ];
            const uniqueChildStatuses = Array.from(
                this.children.reduce(
                    ( accumulator , currentValue ) => {
                        let childStatus = currentValue?.fields?.Status__c?.value;
                        if ( childStatus && rankedStatuses.includes( childStatus ) ) {
                            accumulator.add( childStatus );
                        }
                        return accumulator;
                    } ,
                    new Set()
                )
            );
            const sortedChildStatuses = uniqueChildStatuses.slice().sort(
                ( a , b ) => {
                    let order = 0;
                    if ( rankedStatuses.includes( a ) && rankedStatuses.includes( b ) ) {
                        order = ( rankedStatuses.indexOf( a ) - rankedStatuses.indexOf( b ) );
                    } else if ( rankedStatuses.includes( a ) >= 0 ) {
                        order = -1;
                    } else {
                        order = 1;
                    }
                    return order;
                }
            );
            local = rankedStatuses[0];
            if ( sortedChildStatuses.length > 0 ) {
                local = sortedChildStatuses[0];
            }
        }
        this.summaryStatus = local;
    }

    get isVisible() {
        return ( this.record && ( this.recordStatus != "Hidden" ) && ( !this.isSummary || this.hasChildren ) );
    }

    //
    // Guidance
    //

    get showBody() {
        return ( this.isChild || this.isVisibleBody );
    }

    get hasBody() {
        return ( this.hasGuidance || this.isParent );
    }

    get hasGuidance() {
        return ( this.guidanceId );
    }

    isVisibleBody = false;
    toggleVisibleBody( event ) {
        this.stopPropagation( event );
        this.isVisibleBody = !this.isVisibleBody;
        this.modified();
    }

    stopPropagation( event ) {
        event?.stopPropagation();
    }

    handleClickAccordion( event ) {
        if ( !this.isVisibleBody ) {
            this.toggleVisibleBody( event );
        }
    }

    handleClickTitle( event ) {
        this.toggleVisibleBody( event );
    }

    handleKeyDown( event ) {
        // only created to appease sonar...
    }

    //
    // Status Icon
    //

    get chevronSize() {
        return "xx-small";
    }

    get iconSize() {
        return "x-small";
    }

    get statusIconTitle() {
        let result = this.status;
        if ( this.status === "Pending - Insperity" ) {
            result = "Pending Review by Insperity";
        } else if ( this.status === "Pending - Client" ) {
            result = "Action Required - Resubmit";
        }
        return result;
    }

    get statusIconName() {
        let result = "utility:clock";
        if ( this.status === "Completed" ) {
            result = "utility:success";
        } else if ( this.status === "Pending - Insperity" ) {
            result = "utility:submit_for_approval";
        } else if ( this.status === "Pending - Client" ) {
            result = "utility:warning";
        }
        return result;
    }

    get statusIconVariant() {
        let result;
        if ( this.status === "Completed" ) {
            result = "success";
        } else if ( this.status === "Pending - Insperity" ) {
            result = "warning";
        } else if ( this.status === "Pending - Client" ) {
            result = "error";
        }
        return result;
    }

    //
    // Variant
    //

    @api variant;

    get isParent() {
        return ( !this.isChild );
    }

    get isChild() {
        return ( this.variant === "child" );
    }

    //
    // Column Attributes
    //

    get titleSize() {
        let value = "5";
        if ( this.isChild ) {
            value = "7";
        }
        if ( this.isCompact ) {
            value = "12";
        }
        return value;
    }

    get titleClass() {
        return ( this.isCompact ? "slds-m-bottom_medium" : "" );
    }

    get showDueDate() {
        return ( this.isParent && this.isComfy );
    }

    get dueDateSize() {
        return ( this.isCompact ? "0" : "2" );
    }

    get actionSize() {
        return ( this.isCompact ? "8" : "3" );
    }

    get fileCountSize() {
        return ( this.isCompact ? "2" : "1" );
    }

    get statusSize() {
        return ( this.isCompact ? "2" : "1" );
    }

    //
    // Density
    //

    @api density;

    get isComfy() {
        return ( !this.isCompact );
    }

    get isCompact() {
        return ( this.density === "compact" );
    }

    get isMultipleRows() {
        return ( this.isCompact );
    }

    //
    // Errors
    //

    get isErrorDebugger() {
        return ( viewErrorPanel === true );
    }

    async handleLogInfo( log , message ) {
        try {
            await logInfo(
                {
                    className: "PortalTask" ,
                    methodName: log ,
                    info: message ,
                }
            );
        } catch ( error ) {
            // suppress logging failures...
        }
    }

    //
    // Files
    //

    get showFileUploadInput() {
        return ( this.action == "File" );
    }

    get showRelatedFiles() {
        return ( this.showFileUploadInput || this.showDocusignInput );
    }

    get showDocusignInput() {
        return ( this.action == "Docusign" );
    }

    get parentRecordId() {
        return ( this.recordId ? this.recordId : undefined );
    }

    get isLoading() {
        return (
            !this.links
            || this.isDeleting
        );
    }

    get totalRelatedFiles() {
        return ( ( this.links ) ? this.links.length : 0 );
    }

    get isInputDisabled() {
        return ( this.isLoading || !this.isEditable );
    }

    //
    // Event Handlers
    //

    links;
    handleLoaded( event ) {
        if ( event ) {
            this.links = event?.detail;
        }
    }

    modstamp; // is-a timestamp in milliseconds
    modified() {
        this.modstamp = Date.now();
    }

    handleModified( event ) {
        this.stopPropagation( event );
        this.modified();
    }

    async handleClickFiles( event ) {
        if ( this.totalRelatedFiles > 0 ) {
            this.stopPropagation( event );
            await PortalFileListModal.open(
                {
                    label: ( this.name ? this.name : "Files" ) ,
                    size: "large" ,
                    description: "Displays linked files." ,
                    links: this.links ,
                    disabled: this.isInputDisabled ,
                    onnavigate: ( e ) => {
                        this.handleNavigate( e );
                    } ,
                }
            );
        }
    }

    handleNavigate( event ) {
        this.stopPropagation( event );
        switch ( event?.detail?.type ) {
            case "external__filePreview":
                this.handleModalFilePreview( event?.detail?.state );
                break;
            case "external__delete":
                this.handleModalConfirmDelete( event?.detail?.state );
                break;
            case "standard__namedPage":
                this[NavigationMixin.Navigate]( event?.detail );
                break;
            case "standard__recordPage":
                this[NavigationMixin.Navigate]( event?.detail );
                break;
            case "standard__webPage":
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
                    onnavigate: ( e ) => {
                        this.handleNavigate( e );
                    } ,
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
                let errorLabel = "Error";
                let errorMessage = "Error Deleting File";
                if ( this.isErrorDebugger ) {
                    errorLabel = errorMessage;
                    errorMessage = JSON.stringify( error );
                }
                this.showToastError( errorLabel , errorMessage );
                this.handleLogInfo( "handleDeleteRecord" , JSON.stringify( error ) );
            }
            this.modified();
            this.isDeleting = false;
        }
    }

    //
    // Toasters
    //

    handleToasted( event ) {
        this.stopPropagation( event );
        if ( event?.detail ) {
            const detail = event?.detail;
            this.showToastVariant(
                detail?.label ,
                detail?.message ,
                detail?.variant
            );
        }
    }

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
            let parameters = {
                label: label ,
                message: message ,
                variant: variant ,
            };
            parameters.mode = "dismissible";
            if ( this.isErrorDebugger && ( variant == "error" ) ) {
                parameters.mode = "sticky"; // make errors sticky for easier debugging...
            }
            this.showToast( parameters );
        }
    }

    // https://developer.salesforce.com/docs/platform/lightning-component-reference/guide/lightning-toast.html
    // ~ LWR does not support lightning/platformShowToastEvent, use lightning-toast instead...

    showToast( parameters ) {
        if ( parameters ) {
            Toast.show( parameters , this );
        }
    }

}
//