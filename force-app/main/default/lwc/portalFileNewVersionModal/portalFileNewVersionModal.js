import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class PortalFileNewVersionModal extends LightningModal {
    @api recordId // is-a ContentDocument.Id

    handleClose() {
        this.close( "close" );
    }

    @api label;
    get modalLabel() {
        return ( ( this.label ) ? this.label : "Upload New Version" );
    }

    handleUploadFinished( event ) {
        const uploadedFiles = event.detail.files;
        console.log( "PortalFileNewVersionModal.handleUploadFinished ~ uploadedFiles.length ~ " + uploadedFiles.length );
    }

    versionData;
    handleFileChange( event ) {
        console.log( "PortalFileNewVersionModal.handleFileChange" );
        console.log( JSON.stringify( event ) );
        console.log( JSON.stringify( event?.target ) );
        console.log( JSON.stringify( event?.target?.files ) );
        const file = event.target.files[0];
        let reader = new FileReader();
        reader.onload = () => {
            let base64 = reader.result.split( ',' )[1]
            this.versionData = {
                filename: file.name ,
                base64: base64 ,
                recordId: this.recordId ,
            }
            console.log( this.versionData );
        }
        reader.readAsDataURL( file );
    }

}
//