import { LightningElement,api,wire} from 'lwc';
import fetchLookupData from '@salesforce/apex/NSP_CustomLookUpController.fetchLookupData';
import fetchDefaultRecord from '@salesforce/apex/NSP_CustomLookUpController.fetchDefaultRecord';

const DELAY = 300; 

export default class nsp_contactCustomLookUp extends LightningElement { 
    @api label = '';
    @api placeholder = 'search Contacts here.....'; 
    @api iconName = 'standard:contact';
    @api sObjectApiName = 'Contact';
    @api defaultRecordId = '';
    @api caseAccRecId = '';
    @api createdCaseRecId = '';
    @api selectedContactRecId = '';
    @api defaultContactRecId = '';
    @api parentId = '';
    @api showUserOrQueue = false;
    @api element = "8";
    @api isRequired = false;
    @api error;
    userOrQueue = 'User';
   
   
    lstResult = []; // to store list of returned records   
    hasRecords = true; 
    @api searchKey=''; // to store input field value    
    isSearchLoading = false; // to control loading spinner  
    delayTimeout;
    selectedRecord = {}; // to store selected lookup record in object formate 

    connectedCallback(){
            this.getDefaultRecord(this.defaultRecordId, this.sObjectApiName, this.parentId);
    } 

    handleChange(event) {
        this.sObjectApiName = event.detail.value;
        this.handleRemove(event);
        if(this.sObjectApiName === 'User'){
            this.iconName = "standard:user"
        } else{
            this.iconName = "standard:queue";
        }
    }

 @api
 getDefaultRecord(defaultRecordId, sObjectApiName, parentId){
    fetchDefaultRecord( { recordId: defaultRecordId, sObjectApiName : sObjectApiName, parentId : parentId })
    .then((result) => {
        if(result){
            this.selectRecord({...result});
            this.error = undefined;
        }              
    })
    .catch((error) => {
        this.error = error;
        this.selectedRecord = undefined;
    });
 }
 
    @wire(fetchLookupData, { searchKey: '$searchKey' , sObjectApiName : '$sObjectApiName', accId : '$caseAccRecId', parentId : '$parentId' })
     searchResult(value) {
        const { data, error } = value;
        this.isSearchLoading = false;
        if (data) {
             this.hasRecords = data.length == 0 ? false : true; 
             this.lstResult = JSON.parse(JSON.stringify(data)); 
         }
        else if (error) {
            this.error = error;
        }
    };
       
    handleKeyChange(event) {
        this.isSearchLoading = true;
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        this.delayTimeout = setTimeout(() => {
        this.searchKey = searchKey;
        }, DELAY);
    }

    toggleResult(event){
        const lookupInputContainer = this.template.querySelector('.lookupInputContainer');
        const clsList = lookupInputContainer.classList;
        const whichEvent = event.target.getAttribute('data-source');
        switch(whichEvent) {
            case 'searchInputField':
                clsList.add('slds-is-open');
               break;
            case 'lookupContainer':
                clsList.remove('slds-is-open');    
            break;                    
           }
    }

   handleRemove(event){
    event.preventDefault();
    this.searchKey = '';    
    this.selectedRecord = {};
    this.selectedContactRecId = ''; 
   const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
     searchBoxWrapper.classList.remove('slds-hide');
     searchBoxWrapper.classList.add('slds-show');

     const pillDiv = this.template.querySelector('.pillDiv');
     pillDiv.classList.remove('slds-show');
     pillDiv.classList.add('slds-hide'); 
     this.lookupUpdatehandler('', this.sObjectApiName);   
  } 


handelSelectedRecord(event){   
     var recId = event.target.getAttribute('data-recid'); 
   this.selectRecord(this.lstResult.find(data => data.Id === recId));
}

selectRecord(selectedRecord){
    this.lookupUpdatehandler(selectedRecord.Id, this.sObjectApiName); 
    this.selectedRecord = selectedRecord; 
    this.selectedContactRecId = selectedRecord.Id;
    this.handelSelectRecordHelper(); 
}

handelSelectRecordHelper(){
    this.template.querySelector('.lookupInputContainer').classList.remove('slds-is-open');

     const searchBoxWrapper = this.template.querySelector('.searchBoxWrapper');
     searchBoxWrapper.classList.remove('slds-show');
     searchBoxWrapper.classList.add('slds-hide');

     const pillDiv = this.template.querySelector('.pillDiv');
     pillDiv.classList.remove('slds-hide');
     pillDiv.classList.add('slds-show');     
}

lookupUpdatehandler(value, sObjectApiName){   
    var detailObj = {recId: value, sObjectApiName: sObjectApiName};
    const oEvent = new CustomEvent('lookupupdate',
     {
         'detail': detailObj
     }
 );
 this.dispatchEvent(oEvent); 
 }

 get options() {
    return [
        { label: 'User', value: 'User' },
        { label: 'Queue', value: 'Group' }       
    ];
}

get showLabel(){
    return this.label && this.label.length>0;
}

get controlWidth(){
    return this.label && this.label.length>0 ?  this.element :12;
}

}