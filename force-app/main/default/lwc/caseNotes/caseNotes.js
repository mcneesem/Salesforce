import { LightningElement,api } from 'lwc';

export default class CaseNotes extends LightningElement {
    noteButtonClicked = false;
    @api showfields;
    @api recordId;

    handleNotes(){
        this.noteButtonClicked = true;
        this.dispatchEvent( new CustomEvent( "selected" ) );
    }

    handleCancelNotes(){
        this.noteButtonClicked = false;
        this.dispatchEvent( new CustomEvent( "canceled" ) );
    }

    @api submit( createdCaseId ) {
            const notesFields = this.template.querySelectorAll( "lightning-input-field" );
            if ( notesFields ) {
                notesFields.forEach( field => {
                    if ( field.fieldName === 'Case__c' ) {
                        field.value = createdCaseId;
                    }
                });
                this.template.querySelector( '[data-id = "note-record-form"]' ).submit();
            }
        }

    handleSuccess(event){
        event.preventDefault();
        event.stopPropagation();
    }
}