import { LightningElement , api } from 'lwc';
import { updateRecord } from "lightning/uiRecordApi";
import logInfo from "@salesforce/apex/PortalClientSelector.logInfo";
import createPortalLinks from "@salesforce/apex/PortalClientSharing.createPortalLinks";
import PORTAL_TASK_ID_FIELD from "@salesforce/schema/Portal_Task__c.Id";
import PORTAL_TASK_STATUS_FIELD from "@salesforce/schema/Portal_Task__c.Status__c";
import PORTAL_TASK_VALUE_DATE_FIELD from "@salesforce/schema/Portal_Task__c.Value_Date__c";
import PORTAL_TASK_VALUE_DATETIME_FIELD from "@salesforce/schema/Portal_Task__c.Value_DateTime__c";
import PORTAL_TASK_VALUE_INTEGER_FIELD from "@salesforce/schema/Portal_Task__c.Value_Integer__c";
import PORTAL_TASK_VALUE_TEXT_FIELD from "@salesforce/schema/Portal_Task__c.Value_Text__c";
import viewErrorPanel from "@salesforce/customPermission/View_Error_Panel";

export default class PortalTaskAction extends LightningElement {
    //

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

    get recordId() {
        return ( this.record?.fields?.Id?.value ? this.record.fields.Id.value : undefined );
    }

    get name() {
        return ( this.record?.fields?.Name?.value ? this.record.fields.Name.value : undefined );
    }

    get action() {
        return ( this.record?.fields?.Action__c?.value ? this.record.fields.Action__c.value : undefined );
    }

    get status() {
        return ( this.record?.fields?.Status__c?.value );
    }

    get hasProjectTask() {
        return ( this.record?.fields?.Has_Project_Task__c?.value );
    }

    //

    @api disabled;

    get isInputDisabled() {
        return ( this.isLoading || this.disabled );
    }

    get isLoading() {
        return (
            this.isSaving
            || this.isSharing
        );
    }

    //

    get showFileUploadInput() {
        return ( this.action == "File" );
    }

    get showDocusignInput() {
        return ( this.action == "Docusign" );
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
    //
    //

    stopPropagation( event ) {
        event?.stopPropagation();
    }

    handleClickAction( event ) {
        if ( this.showFileUploadInput || this.showValueInput ) {
            this.stopPropagation( event );
        }
    }

    handleKeyDown( event ) {
        // only created to appease sonar...
    }

    handleUploadFinished( event ) {
        if ( event?.detail?.files?.length ) {
            let messageSuccess = "File Uploaded";
            if ( event?.detail?.files?.length > 1 ) {
                messageSuccess = "Files Uploaded";
            }
            this.showToastSuccess( "Success" , messageSuccess );
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
            if ( this.hasProjectTask ) {
                // share files uploaded to the Portal_Task__c back to the internal Project_Task__c...
                const contentDocumentIds = event?.detail?.files.map(
                    file => file.documentId
                );
                this.handleShares( contentDocumentIds );
            }
        }
    }

    isSharing;
    async handleShares( contentDocumentIds ) {
        if ( contentDocumentIds?.length ) {
            this.isSharing = true;
            try {
                await createPortalLinks(
                    {
                        recordId: this.recordId ,
                        contentDocumentIds: contentDocumentIds ,
                    }
                );
            } catch ( error ) {
                this.handleLogInfo( 'handleShares' , JSON.stringify( error ) );
            }
            this.isSharing = false;
        }
    }

    modstamp; // is-a timestamp in milliseconds
    modified() {
        this.modstamp = Date.now();
        this.dispatchEvent(
            new CustomEvent(
                "modified" ,
                {
                    detail: this.modstamp ,
                }
            )
        );
    }

    //
    //
    //

    inputValue;
    handleChangeInput( event ) {
        let value = event?.detail?.value;
        let valueFloored = value;
        if ( this.showInputInteger && value && !Number.isNaN( value ) ) {
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

    //

    isSaving;
    async handleSave() {
        if ( !this.isSaveDisabled ) {
            this.recordValue = this.inputValue;
            this.isSaving = true;
            try {
                await updateRecord( this.updateRecordInput );
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
                    className: 'PortalTaskAction' ,
                    methodName: log ,
                    info: message ,
                }
            );
        } catch ( error ) {
            // suppress logging failures...
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
        this.dispatchEvent(
            new CustomEvent(
                "toasted" ,
                {
                    detail: {
                        label: label ,
                        message: message ,
                        variant: variant ,
                    }
                }
            )
        );
    }

}
//