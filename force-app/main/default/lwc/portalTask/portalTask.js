import { LightningElement , api } from "lwc";
import LightningConfirm from "lightning/confirm";
import { NavigationMixin } from "lightning/navigation";
import Toast from "lightning/toast";
import { deleteRecord , updateRecord } from "lightning/uiRecordApi";
import PortalFileListModal from "c/portalFileListModal";
import PortalFilePreviewModal from "c/portalFilePreviewModal";
import logInfo from "@salesforce/apex/PortalClientSelector.logInfo";
import PORTAL_TASK_ID_FIELD from "@salesforce/schema/Portal_Task__c.Id";
import PORTAL_TASK_STATUS_FIELD from "@salesforce/schema/Portal_Task__c.Status__c";
import PORTAL_TASK_VALUE_DATE_FIELD from "@salesforce/schema/Portal_Task__c.Value_Date__c";
import PORTAL_TASK_VALUE_DATETIME_FIELD from "@salesforce/schema/Portal_Task__c.Value_DateTime__c";
import PORTAL_TASK_VALUE_INTEGER_FIELD from "@salesforce/schema/Portal_Task__c.Value_Integer__c";
import PORTAL_TASK_VALUE_TEXT_FIELD from "@salesforce/schema/Portal_Task__c.Value_Text__c";
import viewErrorPanel from "@salesforce/customPermission/View_Error_Panel";

export default class PortalTask extends NavigationMixin(LightningElement) {

    _record; // is-a Portal_Task__c
    get record() {
        return this._record;
    }
    @api
    set record( value ) {
        this._record = value;
        if ( this.showInputDate ) {
            this.recordValue = this.record?.fields?.Value_Date__c?.value;
        } else if ( this.showInputDateTime ) {
            this.recordValue = this.record?.fields?.Value_DateTime__c?.value;
        } else if ( this.showInputInteger ) {
            this.recordValue = this.record?.fields?.Value_Integer__c?.value;
        } else if ( this.showInputText ) {
            this.recordValue = this.record?.fields?.Value_Text__c?.value;
        }
        this.modified();
    }

    _recordValue; // is-an ANY ~ populated from various Portal_Task__c.Value_***__c fields...
    get recordValue() {
        return this._recordValue;
    }
    set recordValue( value ) {
        this._recordValue = value;
        // when undefined, initialize input value to record value...
        if ( !this.inputValue ) {
            this.inputValue = value;
        }
    }

    get recordId() {
        return ( this.record?.fields?.Id?.value ? this.record.fields.Id.value : undefined );
    }

    get updateRecordInput() {
        const fields = {};
        fields[PORTAL_TASK_ID_FIELD.fieldApiName] = this.recordId;
        if ( this.hasProjectTask ) {
            fields[PORTAL_TASK_STATUS_FIELD.fieldApiName] = "Pending - Insperity"; // force-pending state for regular Portal Tasks...
        } else {
            fields[PORTAL_TASK_STATUS_FIELD.fieldApiName] = "Completed"; // auto-complete orphaned Portal Tasks...
        }
        if ( this.showValueInput ) {
            if ( this.showInputDate ) {
                fields[PORTAL_TASK_VALUE_DATE_FIELD.fieldApiName] = this.recordValue;
            } else if ( this.showInputDateTime ) {
                fields[PORTAL_TASK_VALUE_DATETIME_FIELD.fieldApiName] = this.recordValue;
            } else if ( this.showInputInteger ) {
                fields[PORTAL_TASK_VALUE_INTEGER_FIELD.fieldApiName] = this.recordValue;
            } else if ( this.showInputText ) {
                fields[PORTAL_TASK_VALUE_TEXT_FIELD.fieldApiName] = this.recordValue;
            }
        }
        return { fields };
    }

    //
    //
    //

    isVisibleBody = false;
    get showBody() {
        return ( this.isChild || this.isVisibleBody );
    }
    get hasBody() {
        return ( this.hasGuidance || this.isParent );
    }
    stopPropagation( event ) {
        event?.stopPropagation();
    }
    toggleVisibleBody( event ) {
        this.stopPropagation( event );
        this.isVisibleBody = !this.isVisibleBody;
        this.modified();
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
    get hasGuidance() {
        return ( this.record?.fields?.Portal_Guidance__c?.value );
    }
    get isEditable() {
        return ( this.record?.fields?.Is_Editable__c?.value );
    }
    get hasProjectTask() {
        return ( this.record?.fields?.Has_Project_Task__c?.value );
    }

    // status icon...
    get status() {
        return ( this.record?.fields?.Status__c?.value );
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
    //
    //

    handleClickAction( event ) {
        if ( this.showFileUploadInput || this.showValueInput ) {
            this.stopPropagation( event );
        } else {
            this.handleClickAccordion( event );
        }
    }

    inputValue;
    handleChangeInput( event ) {
        let value = event?.detail?.value;
        let valueFloored = value;
        if ( this.showInputInteger && value && !isNaN( value ) ) {
            // floor all integer inputs...
            valueFloored = Math.floor( value );
        }
        if ( value != ( "" + valueFloored ) ) {
            // reset to initial value any time the input is not valid...
            value = this.recordValue;
        }
        this.inputValue = value;
    }

    handleFocusInput( event ) {
        if ( this.isAutoSaveEnabled ) {
            // in auto save mode, initialize input value to record value...
            this.inputValue = this.recordValue;
        }
    }

    handleBlurInput( event ) {
        if ( this.isAutoSaveEnabled ) {
            this.handleSave(); // start auto save...
        }
    }

    handleClickSave( event ) {
        this.stopPropagation( event );
        // start manual save...
        this.handleSave();
    }

    isSaving;
    async handleSave() {
        if ( !this.isSaveDisabled ) {
            this.recordValue = this.inputValue;
            this.isSaving = true;
            try {
                await updateRecord( this.updateRecordInput )
                let successMessage = "Record Saved";
                if ( this.name ) {
                    successMessage = "Record Saved (" + this.name + ")";
                }
                this.showToastSuccess( "Success" , successMessage );
            } catch ( error ) {
                let errorLabel = "Error";
                let errorMessage = "Error Saving Record";
                if ( this.name ) {
                    errorMessage = "Error Saving Record (" + this.name + ")";
                }
                if ( this.isErrorDebugger ) {
                    errorLabel = errorMessage;
                    errorMessage = JSON.stringify( error );
                }
                this.showToastError( errorLabel , errorMessage );
                this.handleLogInfo( 'handleSave' , JSON.stringify( error ) );
            }
            this.isSaving = false;
        }
    }

    get isInputDisabled() {
        return ( this.isLoading || !this.isEditable );
    }

    get saveButtonVariant() {
        return ( this.isSaveDisabled ? undefined : "brand" );
    }

    get isSaveDisabled() {
        return (
            this.isLoading
            || ( this.showValueInput && ( this.inputValue == this.recordValue ) )
        );
    }

    @api saveVariant; // auto, icon, text...
    get isAutoSaveEnabled() {
        return ( !this.saveVariant || ( this.saveVariant == "auto" ) );
    }

    get showSaveButtonIcon() {
        return ( this.showValueInput && !this.isAutoSaveEnabled && ( this.saveVariant == "icon" ) );
    }

    get showSaveButton() {
        return ( this.showValueInput && !this.isAutoSaveEnabled && ( this.saveVariant == "text" ) && !this.isSaveDisabled );
    }

    get showValueInput() {
        return (
            this.showInputDate
            || this.showInputDateTime
            || this.showInputInteger
            || this.showInputText
        );
    }

    get showInputDate() {
        return ( this.action == "Date" );
    }

    get showInputDateTime() {
        return ( this.action == "DateTime" );
    }

    get showInputInteger() {
        return ( this.action == "Integer" );
    }

    get showInputText() {
        return ( this.action == "Text" );
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
                    className: 'PortalTask' ,
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

    links;
    handleLoaded( event ) {
        if ( event ) {
            this.links = event?.detail;
        }
    }

    get isLoading() {
        return ( !this.links || this.isDeleting || this.isSaving );
    }

    get totalRelatedFiles() {
        return ( ( this.links ) ? this.links.length : 0 );
    }

    get action() {
        return ( this.record?.fields?.Action__c?.value ? this.record.fields.Action__c.value : undefined );
    }

    handleUploadFinished( event ) {
        if ( event?.detail?.files?.length ) {
            this.showToastSuccess( "Success" , "File Uploaded" );
            this.modified();
            let requiresSave = false;
            if ( this.isAutoSaveEnabled ) {
                requiresSave = !this.hasProjectTask; // always save orphaned Portal Tasks...
                if ( this.hasProjectTask && ( this.status !== "Pending - Insperity" ) ) {
                    requiresSave = true; // conditionally save regular Portal Tasks...
                }
            }
            if ( requiresSave ) {
                this.handleSave();
            }
        }
    }

    modstamp; // is-a timestamp in milliseconds
    modified() {
        this.modstamp = Date.now();
    }

    get name() {
        return ( this.record?.fields?.Name?.value ? this.record.fields.Name.value : undefined );
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
                this.handleLogInfo( 'handleDeleteRecord' , JSON.stringify( error ) );
            }
            this.modified();
            this.isDeleting = false;
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