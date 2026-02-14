import { LightningElement , wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import loadData from '@salesforce/apex/FileUploadController.loadData';
import hasPermission from '@salesforce/apex/FileUploadController.hasPermission';

export default class FileUpload extends LightningElement {
    error;
    isLoaded = false;
    get acceptedFormats() {
        return ['.csv'];
    }
    @wire(hasPermission)
    hasPermission; 

    uploadFileHandler( event ) {
        this.isLoaded = true;
        const uploadedFiles = event.detail.files;
        loadData( { contentDocumentId : uploadedFiles[0].documentId } )
        .then( result => {
            if (result) {
                // Assign the map to the mapData property  
                this.mapData = Object.entries(result).map(([key, value]) => ({
                    key,
                    value
                }));
            }
            this.isLoaded = false;
            this.strMessage = result;
            this.dispatchEvent(
                new ShowToastEvent( {
                    title: 'success',
                    message: result,
                    variant: 'success',
                    mode: 'sticky'
                } ),
            );
        })
        .catch( error => {
            this.isLoaded = false;
            this.error = error;
            this.dispatchEvent(
                new ShowToastEvent( {
                    title: 'Error!!',
                    message: 'Please verify the file',
                    variant: 'error',
                    mode: 'sticky'
                } ),
            );
        } )
    }

}