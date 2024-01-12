import { LightningElement,api, track, wire    } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';
import { getRecord } from 'lightning/uiRecordApi';
import isClientSubPlanAssociatedWithAsset from '@salesforce/apex/NSP_RetAssetWithClntSubPlnController.isClientSubPlanAssociatedWithAsset';
import getRecordTypeIdByName from '@salesforce/apex/NSP_RetAssetWithClntSubPlnController.getRecordTypeIdByName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import labelName from '@salesforce/label/c.nsp_Associate_Client_subplan_History';

export default class nsp_AssociateRetAssetWithClientSubPlan extends NavigationMixin( LightningElement ) {


@api objectApiName;
@api recordId;
@track asset;
@track showClientSubPlanAssociateButton ;
recordTypeName = 'Choice';
clientSubPlanHisName = 'NSP_Client_Sub_Plan_History__c';
buttonlabel = labelName;

//wire method to update component whenever Asset rec is updated   
    @wire(getRecord, { recordId: '$recordId', fields: [ 'Asset.Id' ]})
        getAssetRec({ data, error }) {
        if (data) {
            this.asset = data;
            //call processRelatedObjects to check association of Client Subplan his with this asset
            this.processRelatedObjects();                       
        } else if (error) {
        }
    }

    // check if Client sub plan is associated with this asset
    async processRelatedObjects() {  
        await isClientSubPlanAssociatedWithAsset({ assetId: this.asset.id })
		.then(result => {
			this.showClientSubPlanAssociateButton = result;
			this.error = undefined;
		})
		.catch(error => {
			this.error = error;
			this.asset = undefined;
		})
    }

    //Show message when Client subplan his is already associated with the asset
    showClientSubplanAssociationInfo() {
        const evt = new ShowToastEvent({
            title: 'Info',
            message: 'A Plan History record is already associated to this client',
            variant: 'info',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    };

    //Button functionality to navigate to new ClientSubPlanHis rec
    async handleOnClick() {
        await this.processRelatedObjects();
			if(this.showClientSubPlanAssociateButton){
                const defaultValues = encodeDefaultFieldValues({
                    NSP_Asset__c: this.recordId,
                   
                });
                //fetch 'choice' recordType Id 
                getRecordTypeIdByName({sObjectName: this.clientSubPlanHisName,recTypeName: this.recordTypeName})
                .then( (result ) => {

            // Navigate to the new Client Sub Plan History Record page
            this[NavigationMixin.Navigate]({
                type: 'standard__objectPage',
                attributes: {
                    objectApiName: this.clientSubPlanHisName,
                    actionName: 'new',
                },
                state: {
                    recordTypeId: result,
                    defaultFieldValues: defaultValues,
                }
                }); 
            })
            .catch((error) => {
                this.error =error;
             });
        }
            else{
                this.showClientSubplanAssociationInfo();
            }
    }
}