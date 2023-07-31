import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord } from 'lightning/uiRecordApi';
import fetchAccountGroupMemberRecords from '@salesforce/apex/NSP_AccountGroupMemberController.fetchAccountGroupMemberRecords';
import createSelfGroup from '@salesforce/apex/NSP_AccountGroupMemberController.createSelfGroup';
import isSelfAccountGroup from '@salesforce/apex/NSP_AccountGroupMemberController.isSelfAccountGroup';
import { TABLE1, TABLE2, AURA_COMP, ACCOUNT_GROUPS } from './constants';
import NSP_AccountGroupToOtherAccountGroup from '@salesforce/label/c.NSP_AccountGroupToOtherAccountGroup';
import NSP_AccountGroupRemoveMessage from '@salesforce/label/c.NSP_AccountGroupRemoveMessage';
//Error Message changes done By Virendra as part of STY-02843
import PROFILE_NAME from "@salesforce/schema/NSP_Account_Group__c.CreatedBy.Profile.Name";
import GRP_TYPE from "@salesforce/schema/NSP_Account_Group__c.NSP_Type__c";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import AGM_ERROR_MESSAGE from '@salesforce/label/c.NSP_Error_MessageForAGM';
const fields =[PROFILE_NAME , GRP_TYPE];
export default class Nsp_accountGroupMemberRelatedListOnCase extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  @track error;
  @track data;
  @track accountgroupList;
  @track showLoadingSpinner = false;
  @track data;
  @track columns;
  label={AGM_ERROR_MESSAGE};
  resultData;
  isDialogVisible = false;
  originalMessage;
  nspType;
  accountId;
  accountName;
  groupMemberId;
  //Error Message changes done By Virendra as part of STY-02843
  @wire(getRecord, {
    recordId: "$recordId",
    fields
  })
  accountGrp;
  get profileName() {
    return getFieldValue(this.accountGrp.data, PROFILE_NAME);
  }
  get accntGrType() {
    return getFieldValue(this.accountGrp.data, GRP_TYPE);
  }
  @wire(fetchAccountGroupMemberRecords, { accountGroupId: '$recordId' })
  columnsData(result) {
    this.resultData = result;
    if (result.data) {
      let accountGroup = Object.keys(result.data);
      this.columns = accountGroup[0] == 'Controlled Group' ? TABLE1 : TABLE2;
      this.data = result.data[accountGroup[0]].map((record) => {
        let accountGroupMemberRecordUrl = '/' + record.Id;
        let memberAccountUrl = '/'+record.NSP_Member_Account__c;
        return {...record, accountGroupMemberRecordUrl,memberAccountUrl};
      });

      this.error = undefined;
    } else if (result.error) {
      this.error = result.error;
      this.data = undefined;
    }
  }

 //Onclick of New Button
 handleClickNew() {
  //Error Message codnition added By Virendra as part of STY-02843
  if(this.profileName === 'Integration User' && this.accntGrType === 'Controlled Group'){
    const evt = new ShowToastEvent({
      title: 'Validation Error',
      message: this.label.AGM_ERROR_MESSAGE,
      variant: 'error',
      mode: 'sticky'
    });
    this.dispatchEvent(evt);
  }
  else{
    this[NavigationMixin.Navigate]({
      type: 'standard__component',
      attributes: {
        componentName: AURA_COMP.Account_Group_Member,
      },
      state: {
        c__relatedId: this.recordId,
      },
    });
  }
}

  //On click of View All
  handleClickViewAll() {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordRelationshipPage',
      attributes: {
        recordId: this.recordId,
        objectApiName: 'NSP_Account_Group__c',
        relationshipApiName: 'Account_Group_Members__r',
        actionName: 'view',
      },
    });
  }

  //For handling each row action:Edit and Delete
  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    switch (actionName) {
      case 'delete':
        this.deleteRecordDetails(row);
        break;

      case 'Edit':
        this.showRecordDetails(row.Id);
        break;
    }
  }

  deleteRecordDetails(row) {
    if(row.NSP_Type__c && ACCOUNT_GROUPS.includes(row.NSP_Type__c)){
      this.nspType = row.NSP_Type__c;
      this.accountId = row.NSP_Member_Account__c;
      this.accountName = row.NSP_Account_Name__c;
      this.groupMemberId = row.Id;

      isSelfAccountGroup({ groupRecordId : this.recordId, groupMemberAccName : this.accountName})
      .then((result) => {
        if(result) {
          //prevent to delete self group record
          this.dispatchEvent(
            new ShowToastEvent({
              message: NSP_AccountGroupToOtherAccountGroup,
              variant: 'info',
            })
          );
        } else {
          this.isDialogVisible = true;
        }
      })
      .catch((error) => {
      });
    } else {
      deleteRecord(row.Id)
        .then(() => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Success',
              message: 'Record deleted',
              variant: 'success',
            })
          );
          refreshApex(this.resultData);
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error when deleting record',
              message: error.body.message,
              variant: 'error',
            })
          );
        });
    }
  }

  showRecordDetails() {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        recordId: this.recordId,
        objectApiName: 'NSP_Account_Group_Member__c',
        actionName: 'edit',
      },
    });
  }

  //STY-04139 - start
  deleteReportRequest(event) {
    if(event.target.name === 'deleteRequest'){
    this.originalMessage = this.recordid ;
    //shows the component
    this.isDialogVisible = true;
  }else if(event.target.name === 'confirmModal'){

    //when user clicks outside of the dialog area, the event is dispatched with detail value  as 1
    if(event.detail !== 1){
        if(event.detail.status === 'confirm') {
            const recordId =  event.detail.originalMessage;
           this.createSelfGroupForAccount();

        }else if(event.detail.status === 'cancel'){
            this.dispatchEvent(
              new ShowToastEvent({
                message: NSP_AccountGroupRemoveMessage,
                variant: 'info',
              })
            );
            this.isDialogVisible = false;
        }
    }
    //hides the component
    this.isDialogVisible = false;
  }
}

createSelfGroupForAccount(  ) {
  createSelfGroup({ accountGrpMember : this.groupMemberId, accountId : this.accountId, nspType : this.nspType, accName : this.accountName })
      .then((result) => {
        refreshApex(this.resultData);
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: 'Self Group created',
            variant: 'success',
          })
        );
      })
      .catch((error) => {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error in Self Group creation',
            message: error.body.message,
            variant: 'error',
          })
        );
      });
  }
  //STY-04139 - end
}
