import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createProject from '@salesforce/apex/NSP_CreateProjectTemplateFromCase.insertProject';

export default class CreateProjectTemplateFromCase extends LightningElement {
    @api recordId;
    isExecuting = false;

    @api async invoke(){
        if (this.isExecuting) {
            return;
        }
        this.ShowToast('Success', 'Project Creation Started successfully', 'SUCCESS')
      //  this.isExecuting = true;
        await this.sleep(2000);
        createProject({caseId:this.recordId})
        .then(data=> {
            if(data === 'Project Successfully Created'){
                this.ShowToast('Success', data, 'SUCCESS');
            }else{
                this.ShowToast('Warning', data, 'Warning');
            }
        })
        .catch(error => {
            this.ShowToast('Error', error, 'ERROR');
        })
  //      this.isExecuting = false;
    }

    ShowToast(title,message,variant){
        const ShowToastEvt = new ShowToastEvent({
            title:title,
            message:message,
            variant:variant
        });

        this.dispatchEvent(ShowToastEvt);
    } 

    sleep(ms) {
        return new Promise((resolve) => setTimeout(resolve, ms));
    }

    // NavigateToCaseRecordPage(){
    //     this[NavigationMixin.Navigate]({
    //         type: 'standard__recordPage',
    //         attributes: {
    //             objectApiName: 'Case',
    //             actionName: 'home',
    //         },
    //     });
    // }
}