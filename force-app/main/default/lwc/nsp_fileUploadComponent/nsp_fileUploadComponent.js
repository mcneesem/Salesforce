import { LightningElement, api, wire, track} from 'lwc';
export default class Nsp_fileUploadComponent extends LightningElement {
    @track attachmentFilesName = [];
    @api filesUploaded = [];


    openfileUpload(event) {
        if(event.target.files.length > 0) {
            let fileSize = event.target.files.length;
            for(let i=0; i<fileSize; i++){
                let filesName = '';
                let file = event.target.files[i];
                filesName = filesName + file.name;
                let freader = new FileReader();
                this.attachmentFilesName.push(filesName);
                freader.onload = f => {
                    let base64 = 'base64,';
                    let content = freader.result.indexOf(base64) + base64.length;
                    let fileContents = freader.result.substring(content);
                    this.filesUploaded.push({
                        Title: filesName,
                        FileContent: fileContents,
                        FileType: file.type
                    });
                };
                freader.readAsDataURL(file);
            }  
            
        }
    }

}