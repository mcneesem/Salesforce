import { LightningElement , api , wire } from 'lwc';
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

export default class PortalTask extends LightningElement {
    @api record;

    isVisibleBody = false;
    get showBody() {
        return ( this.isChild || this.isVisibleBody );
    }
    get hasBody() {
        return ( this.hasGuidance || this.isParent );
    }
    handleClick( event ) {
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

    error;
    links;
    @wire(getRelatedListRecords, {
        parentRecordId: '$record.fields.Id.value' ,
        relatedListId: 'ContentDocumentLinks' ,
        fields: [
            'ContentDocumentLink.Id' ,
        ] ,
        sortBy: [ 'ContentDocumentLink.Id' ]
    })
    linkInfo({ error, data }) {
        if ( data ) {
            this.links = data.records;
            this.error = undefined;
        } else if ( error ) {
            this.error = error;
            this.links = undefined;
        }
    }
    get totalRelatedFiles() {
        return ( ( this.links ) ? this.links.length : 0 );
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

    get showFileUpload() {
        return false;
    }
    handleUploadFinished( event ) {
        const uploadedFiles = event.detail.files;
        console.log( "PortalTask.handleUploadFinished ~ uploadedFiles.length ~ " + uploadedFiles.length );
    }

}
//