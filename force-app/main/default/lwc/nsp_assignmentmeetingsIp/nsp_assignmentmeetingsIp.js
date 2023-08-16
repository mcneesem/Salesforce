import { api, LightningElement, track, wire } from 'lwc';
import EMPLOYEE_ORIENTATION from '@salesforce/schema/Employee_Orientation__c';
import saveAssignmentForm from '@salesforce/apex/NSP_ImplementationProfileController.saveAssignmentDetails';
import getAllEmplyeeOrientations from '@salesforce/apex/NSP_ImplementationProfileController.getEmployeeOrientations';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { deleteRecord } from 'lightning/uiRecordApi';
import * as labels from 'c/nsp_implementationLabels';

export default class Nsp_assignmentmeetingsIp extends LightningElement {
    @api
    recordId;
    @api error;
    @api
    objectApiName;
    employeeObjectApiName = EMPLOYEE_ORIENTATION.objectApiName;
    @track
    lEmployeeOrientations = [{
        Id : ''
    }];
    label = labels;
    isLoading= true;

    handleEOChange(event){
        let index = event.target.dataset.index;
        let field = event.target.fieldName;
        let value = event.detail.value;
        if(this.lEmployeeOrientations){
            this.lEmployeeOrientations[index][field] = value;
        }
    }
    addMoreOrientation(){
        this.lEmployeeOrientations.push({
            Id : ""
        });
    }

    deleteOrientationRow(event){
        let index = event.target.dataset.index;
        let employeeOrientationId = event.target.dataset.id;
        if(this.recordId && employeeOrientationId){
            deleteRecord(employeeOrientationId)
            .then( () => {
                // DELETED
                this.removeEmployeeOrientationRecord(index);
            }).catch( (error) => {
                this.error = error;
            })
        }else{
            this.removeEmployeeOrientationRecord(index);
        }
    }

    removeEmployeeOrientationRecord(index){
        if(this.lEmployeeOrientations.length === 1){
            this.lEmployeeOrientations = [];
            setTimeout( () => {
                this.lEmployeeOrientations = [{
                    Id : ''
                }];
            },0);
            return;
        }                
        this.lEmployeeOrientations.splice(index,1);
    }
    
    @wire( getAllEmplyeeOrientations, { recordId : "$recordId"})
    getAllEmplyeeOrientations({data,error}){
        if(data){
            if(data.length > 0){
                this.lEmployeeOrientations = JSON.parse(JSON.stringify(data));
            }else{
                this.lEmployeeOrientations = [{
                    Id : ''
                }];
            }
        }else if(error){
            this.showToast(this.label.errorTitle,error.body.message,'error');
        }
    }
    // RECORD EDIT FORM
    handleLoad(){
        this.isLoading = false;
    }
    @api
    saveForm(newRecordId){
        this.isLoading = true;
        if(this.lEmployeeOrientations.length === 1 && !this.checkIfEmployeeOrientationsHasValues()){
            // this.template.querySelector('lightning-record-edit-form').submit();
            // return;
        }

        const inputFields = this.template.querySelectorAll('.ipProfile lightning-input-field');
        let fields = {
            Id : this.recordId || newRecordId
        };
        inputFields.forEach(field => {
            fields[field.fieldName] = field.value;
        });
        let lEmployeeOrientations = this.lEmployeeOrientations.map( (row) => {
            let oEmployee = {...row};
            oEmployee.Orientation_Rep__c = Array.isArray(row.Orientation_Rep__c) ? row.Orientation_Rep__c[0] : row.Orientation_Rep__c;
            oEmployee.Id = row.Id || null;
            return oEmployee;
        });
        saveAssignmentForm({
            'sAssigmentMeetingWrapper' : JSON.stringify({
                'oIProfile' : fields,
                'lEmployeeOrientations' : lEmployeeOrientations
            })
        }).then( (response) =>{
            this.showToast(this.label.successTitle, this.label.implementationSavedMessage,'success');
            this.dispatchEvent(new CustomEvent('success', {detail : { "recordId" : response.oIProfile.Id}}));
            this.lEmployeeOrientations = response.lEmployeeOrientations;
            this.isLoading = false;
        }).catch( (error) => {
            this.isLoading = false;
            this.showToast(this.label.errorTitle,error.body.message,'error');
            this.dispatchEvent(new CustomEvent('error', {detail : { "error" : error.body.message}}));
        });
    }
    handleSuccess(event){
        //Id is event.detail.id
        this.showToast(this.label.successTitle,this.label.implementationSavedMessage,'success');
        this.dispatchEvent(new CustomEvent('success', {detail : { "recordId" : event.detail.id}}));
    }
    handleError(event){
        this.showToast(this.label.errorTitle,event.detail.detail,'error');
        // Maybe fire Error event for the Parent Component
    }

    // UTIL METHODS
    checkIfEmployeeOrientationsHasValues(){
        if( this.lEmployeeOrientations[0].Date_and_Time__c || this.lEmployeeOrientations[0].Meeting_Type__c || this.lEmployeeOrientations[0].Orientation_Rep__c){
            return true;
        }
    }
    showToast(title,message,type){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: type,
            }),
        );
    }
}