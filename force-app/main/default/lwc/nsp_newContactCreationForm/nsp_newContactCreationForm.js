import { LightningElement,wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import USER_ID from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';
import SERVICE_PROFILES from '@salesforce/label/c.NSP_Service_User_Profiles';

export default class NewContactCreationForm extends NavigationMixin(LightningElement) {
    showServiceLayout = false;
    prfName = '';
    label = {SERVICE_PROFILES};

    @wire(getRecord, {
        recordId: USER_ID,
        fields: [PROFILE_NAME_FIELD]
    }) wireuser({
        error,
        data
    }) {
        if (error) {
           this.error = error ; 
        } else if (data) {
            this.prfName = data.fields.Profile.value.fields.Name.value;  
            if(this.label.SERVICE_PROFILES.includes(this.prfName)) {
                this.showServiceLayout = true;    
            }else {
                window.open('/lightning/o/Contact/new?count=2&nooverride=1','_self');
            } 
        }
    }


    handleSuccess(event) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.detail.id,
                actionName: 'view'
            }
        });
    }

    hideClose() {
        window.history.back();
    }
}