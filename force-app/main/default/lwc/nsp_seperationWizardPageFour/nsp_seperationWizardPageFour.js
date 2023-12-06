import { LightningElement,wire,api } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import REVIEW_STATUS from '@salesforce/schema/NSP_ReportRequest__c.NSP_ReviewStatus__c';
import WHO_RESPONSIBLE_STOCK from '@salesforce/schema/NSP_ReportRequest__c.NSP_WhoResponsibleForStockEquityPaymt__c';
import BONUS_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_BonusSelectOne__c';
import COBRA_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_COBRASelectOne__c';
import COMMISION_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_CommissionsSelectOne__c';
import EQUIPMENT_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_EquipmentSelection__c';
import OUTPLACEMENT_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_OutplacementServicesValue__c';
import TRANSITION_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_TransitionOfDutiesValue__c';
import INSTALLMENT_PICKLIST from '@salesforce/schema/NSP_ReportRequest__c.NSP_Installments__c';
export default class nsp_seperationWizardPageFour extends LightningElement {
@api reReqId ;
NSP_BonusSelectOne__c;
NSP_COBRASelectOne__c;
NSP_CommissionsSelectOne__c;
NSP_EquipmentSelection__c;
NSP_OutplacementServicesValue__c;
NSP_TransitionOfDutiesValue__c;
NSP_Termination_Date__c;
NSP_ReferenceTospecificClientDocument__c;
NSP_TransitionDate__c;
NSP_Installments__c;
filesize = 0;
preparedFields=['NSP_BonusSelectOne__c','NSP_TransitionDate__c','NSP_ReferenceTospecificClientDocument__c','NSP_COBRASelectOne__c','NSP_CommissionsSelectOne__c','NSP_EquipmentSelection__c',
'NSP_OutplacementServicesValue__c','NSP_TransitionOfDutiesValue__c','NSP_Termination_Date__c','NSP_Installments__c'];
preparedFormLoad=false; 

/** disable field */
NSP_RemoveNoRehireClause = false;
NSP_KeepNorehireParagraphForcompany =false;
NSP_NonSolicitationofCustomers_Company= false ;

NSP_MutualNonDisparagement =false;
NSP_MutualConfidentiality =false;
isPrevClick=false;
isSaveClick=false;
/**   below are required */
NSP_SpecialItems =false ;
NSP_TransitionOfDuties =false;
NSP_SignatureBlockforClientRequired =false;
NSP_OutplacementServices = false;
NSP_IncludeTerminationDate =false;
NSP_Equipment =false;
NSP_Commissions =false;
NSP_COBRA = false;
NSP_Bonus =false;
NSP_Installments = false;
NSP_Mid_Market_or_Mid_Market_Enterprise__c = false;
hrsstopMsgStock = "display:none";

/**
get hrsstopMsgStock(){

    if( this.reviewType =='HRS Review' && this.IsanyReferenceStock =="Yes" ){
        return "display:''"
    }else{
        return "display:none"
    }
}
 */

get NSP_NumberOfMonthsOfOutplacement_Service(){
    return (this.NSP_OutplacementServices && this.NSP_OutplacementServicesValue__c != null && this.NSP_OutplacementServicesValue__c.includes('Standard Outplacement') && this.enableInsperityPrepared) ? true :false;

}

get NSP_AmountOfReimbursement(){
    return (this.NSP_OutplacementServices && this.NSP_OutplacementServicesValue__c != null && this.NSP_OutplacementServicesValue__c.includes('Reimbursement of Outplacement') && this.enableInsperityPrepared) ? true :false;

}

get NSP_ExpirationDate(){
    return (this.NSP_OutplacementServices && this.NSP_OutplacementServicesValue__c != null && this.enableInsperityPrepared) ? true :false;

}

get NSP_COBRA_Amount(){

    return ( this.NSP_COBRA &&  this.enableInsperityPrepared) && 
    (this.NSP_COBRASelectOne__c !=null &&
        ( this.NSP_COBRASelectOne__c.includes('COBRA2') || this.NSP_COBRASelectOne__c.includes('COBRA3') || this.NSP_COBRASelectOne__c.includes('COBRA5')
    || this.NSP_COBRASelectOne__c.includes('COBRA6') ) )? true :false;
    //NSP_COBRA_Amount__c
}

get NSP_NumberOfMonthsCOBRA(){
    return ( this.NSP_COBRA && this.NSP_COBRASelectOne__c != null && this.NSP_COBRASelectOne__c.includes('COBRA4') && this.enableInsperityPrepared ) ? true :false;

}

get NSP_CommissionAmount(){

    return (this.NSP_Commissions && this.NSP_CommissionsSelectOne__c != null && this.NSP_CommissionsSelectOne__c.includes('additional compensation') && this.enableInsperityPrepared) ? true :false;
}

get NSP_EnterBonusAmmount(){
    return (this.NSP_Bonus && this.NSP_BonusSelectOne__c != null &&  this.NSP_BonusSelectOne__c.includes('Payment of bonus') && this.enableInsperityPrepared) ? true :false;
}

get NSP_Installments(){
    
    return (this.NSP_Installments && this.NSP_Installments__c != null && this.enableInsperityPrepared) ? true :false;
}

/**
verifyBox(){
    const inputFields = this.template.querySelectorAll('lightning-input-field');
    if (inputFields) {
        inputFields.forEach(field => {
            if(this.checkBoxField.includes(field.fieldName) && field.value == true){
                this.requireOneBox = false;
            }
            
        });
    }
}


get CommissionAmount(){
return this.NSP_CommissionAmount?"display:''" : "display:none"
}

get  NumberOfMonthsCOBRA(){
    return this.NSP_NumberOfMonthsCOBRA?"display:''" : "display:none"

}

 */

get transitionDate(){
    if(this.NSP_TransitionOfDuties){
    return this.NSP_TransitionDate__c
    }else{
        return '';
    }
}


radioRequiredFields=['NSP_SpecialItems','NSP_TransitionOfDuties','NSP_SignatureBlockforClientRequired','NSP_OutplacementServices',
'NSP_IncludeTerminationDate','NSP_Equipment','NSP_Commissions','NSP_COBRA','NSP_Bonus','NSP_Installments_Check'];


checkBoxField = ["NSP_COBRA__c","NSP_Bonus__c","NSP_RemoveNotaryRequirement__c",
"NSP_RemoveNoRehireClause__c","NSP_KeepNorehireParagraphForcompany__c","NSP_Commissions__c",
"NSP_RemoveNotaryRequirement__c","NSP_MutualNonDisparagement__c","NSP_OutplacementServices__c",
"NSP_SignatureBlockforClientRequired__c","NSP_VerificationOfEmploymentHotline__c",
"NSP_DontContestUnemployment__c","NSP_ReferenceTospecificClientDocument__c","NSP_TransitionOfDuties__c",
"NSP_MutualConfidentiality__c","NSP_Equipment__c","NSP_IncludeTerminationDate__c","NSP_Installments_Check__c"];


recordTypeId = '012000000000000AAA';
error;
pageNumber = 4;
fieldsData;
pickValueYesNo = [
        { "attributes": null, "label": "No", "value": "No" },
        { "attributes": null, "label": "Yes", "value": "Yes"}
        
      ];
userID;
financeLevel;
isclicked;
currentPageFields=['NSP_RemoveNoRehireClause__c','NSP_KeepNorehireParagraphForcompany__c','NSP_RemoveNotaryRequirement__c','NSP_Installments__c','NSP_NumberOfpayments__c','NSP_Installments_Check__c',
'NSP_Bonus__c','NSP_BonusSelectOne__c','NSP_Installments_Check__c','NSP_EnterBonusAmmount__c','NSP_NumberOfpayments__c','NSP_COBRA__c','NSP_COBRASelectOne__c','NSP_COBRA_Amount__c','NSP_NumberOfMonthsCOBRA__c','NSP_Commissions__c',
'NSP_CommissionsSelectOne__c','NSP_CommissionAmount__c','NSP_Equipment__c','NSP_EquipmentSelection__c','NSP_ManufacturerNameandModel__c','NS_FairMarketValue__c','NSP_MutualNonDisparagement__c',
'NSP_MutualConfidentiality__c','NSP_NonSolicitationofCustomers_Company__c','NSP_IncludeTerminationDate__c','NSP_Termination_Date__c','NSP_OutplacementServices__c','NSP_OutplacementServicesValue__c',
'NSP_NumberOfMonthsOfOutplacement_Service__c','NSP_AmountOfReimbursement__c','NSP_ExpirationDate__c','NSP_SignatureBlockforClientRequired__c','NSP_NameOnSignature__c','NSP_SignatureTitle__c',
'NSP_VerificationOfEmploymentHotline__c','NSP_DontContestUnemployment__c','NSP_ReferenceTospecificClientDocument__c','NSP_TransitionOfDuties__c','NSP_TransitionOfDutiesValue__c','NSP_TransitionDate__c','NSP_Mid_Market_or_Mid_Market_Enterprise__c'];
fieldValue =  { currentTarget : { name :'', value :''} };

// event.currentTarget.value == true? this.template.querySelector('div.'+event.currentTarget.fieldName).style.display='':
//this.template.querySelector('div.'+event.currentTarget.fieldName).style.display='none';


radioOnChange(event){

    
    let key = event.currentTarget.fieldName;
    let value = event.currentTarget.value;

    if(this.radioRequiredFields.includes(key.slice(0,-3))){
        this[key.slice(0,-3)] = ( value == true );
    }
/**
    if(value == true ){
        this.requireOneBox = false ;
    }else{
        this.requireOneBox = true
        this.verifyBox();
    }
**/

    if( this.template.querySelector('div.'+key) != null){
        [...this.template.querySelectorAll('div.' + key)].map(x =>{
            value == true? x.style.display='': (x.style.display='none',x.value='');
       });


       if( this.template.querySelector('lightning-radio-group.'+key) != null){
        value == true? this.template.querySelector('lightning-radio-group.'+key).style.display='':this.template.querySelector('lightning-radio-group.'+key).style.display='none';
          }
  
       if( this.template.querySelector('lightning-input-field.'+key) != null){
              [...this.template.querySelectorAll('lightning-input-field.' + key)].map(x =>{
                value == true? x.style.display='':x.style.display='none';
              });
       }

    }


    if(value == false){
        if(this.template.querySelector('lightning-input-field.'+event.currentTarget.fieldName+'_childNode')!=null){
            [...this.template.querySelectorAll('lightning-input-field.'+ event.currentTarget.fieldName+'_childNode')].map(x =>{
                event.currentTarget.value == true? x.style.display='': (x.style.display='none',x.value='');
            });
        
        }

        if(this.template.querySelector('div.'+event.currentTarget.fieldName+'_childNode')!=null){
            [...this.template.querySelectorAll('div.'+ event.currentTarget.fieldName+'_childNode')].map(x =>{
                event.currentTarget.value == true? x.style.display='': (x.style.display='none',x.value='');
            });
        
        }

        if(this.template.querySelector('lightning-radio-group.'+event.currentTarget.fieldName+'_childNode')!=null){
            [...this.template.querySelectorAll('lightning-radio-group.'+ event.currentTarget.fieldName+'_childNode')].map(x =>{
                event.currentTarget.value == true? x.style.display='': (x.style.display='none',x.value='');
            });
        
        }
        //event.currentTarget.fieldName
        if(event.currentTarget.fieldName =='NSP_Commissions__c'){
            this.NSP_CommissionsSelectOne__c  ='';
            this.NSP_CommissionsSelectOne__c = null;
        }
        if(event.currentTarget.fieldName =='NSP_Bonus__c'){
            this.NSP_BonusSelectOne__c ='';
            this.NSP_BonusSelectOne__c = null;
        }
        
        if(event.currentTarget.fieldName =='NSP_Equipment__c'){
            this.NSP_EquipmentSelection__c ='';
            this.NSP_EquipmentSelection__c = null;
        }
        if(event.currentTarget.fieldName =='NSP_COBRA__c'){
            this.NSP_COBRASelectOne__c ='';
            this.NSP_COBRASelectOne__c = null;

        }
        if(event.currentTarget.fieldName =='NSP_OutplacementServices__c'){
            this.NSP_OutplacementServicesValue__c ='';
            this.NSP_OutplacementServicesValue__c = null;
        }

        if(event.currentTarget.fieldName =='NSP_TransitionOfDuties__c'){
            this.NSP_TransitionOfDutiesValue__c ='';
            this.NSP_TransitionOfDutiesValue__c = null;
        }
        if(event.currentTarget.fieldName =='NSP_Installments_Check__c'){
            this.NSP_Installments__c ='';
            this.NSP_Installments__c = null;
        }
        

        
    }

    if( this.template.querySelector('lightning-input-field.'+event.currentTarget.fieldName) != null){
        [...this.template.querySelectorAll('lightning-input-field.' + event.currentTarget.fieldName)].map(x =>{
             event.currentTarget.value == true? x.style.display='':(x.style.display='none',x.value='');
        });
    }

    if(event.currentTarget.fieldName != null && ( event.currentTarget.fieldName == 'NSP_RemoveNoRehireClause__c'|| event.currentTarget.fieldName == 'NSP_KeepNorehireParagraphForcompany__c' )){
        if(event.currentTarget.value == true){
            this[event.currentTarget.fieldName.slice(0,-3)] = true;
        }else{
            this[event.currentTarget.fieldName.slice(0,-3)] = false;
        }
    }

    if(key == 'NSP_ReferenceTospecificClientDocument__c'){
        this.NSP_ReferenceTospecificClientDocument__c =value;
    }
}

//lightning-input-field.NSP_EnterBonusAmmount__c
/** */
onchangeNspPrepared(event){
    if(this.preparedFields.includes(event.currentTarget.name)){
        this[event.currentTarget.name] = event.currentTarget.value;
    }

     if(this.template.querySelector('lightning-input-field.NSP_EnterBonusAmmount__c') != null){
        if(this.NSP_BonusSelectOne__c != null && this.NSP_BonusSelectOne__c.includes('Payment of bonus')){
            this.template.querySelector('lightning-input-field.NSP_EnterBonusAmmount__c').style.display='';   
        }else{
            this.template.querySelector('lightning-input-field.NSP_EnterBonusAmmount__c')
            this.template.querySelector('lightning-input-field.NSP_EnterBonusAmmount__c').style.display='none';
            this.template.querySelector('lightning-input-field.NSP_EnterBonusAmmount__c').value=''
        }
      }

    if( event.currentTarget.name == "NSP_COBRASelectOne__c" && event.currentTarget.value != null){
        this.NSP_COBRASelectOne__c=  event.currentTarget.value;

        if(this.template.querySelector('lightning-input-field.NSP_COBRA_Amount__c')!= null){
            if(this.NSP_COBRASelectOne__c.includes('COBRA2') || this.NSP_COBRASelectOne__c.includes('COBRA3') || this.NSP_COBRASelectOne__c.includes('COBRA5')
            || this.NSP_COBRASelectOne__c.includes('COBRA6') ){
                this.template.querySelector('lightning-input-field.NSP_COBRA_Amount__c').style.display='';
            }else{
                this.template.querySelector('lightning-input-field.NSP_COBRA_Amount__c').style.display='none';
                this.template.querySelector('lightning-input-field.NSP_COBRA_Amount__c').value='';
            }
        }
        
        if(this.NSP_COBRASelectOne__c!=null && this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsCOBRA__c')!= null){
            if(this.NSP_COBRASelectOne__c.includes('COBRA4')){
                this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsCOBRA__c').style.display=''
            }else{
                this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsCOBRA__c').style.display='none';
                this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsCOBRA__c').value='';
            }
            
            
        }
         
    }

    if( event.currentTarget.name == "NSP_CommissionsSelectOne__c" && event.currentTarget.value != null){
        this.NSP_CommissionsSelectOne__c = event.currentTarget.value ;

    
     if(this.template.querySelector('lightning-input-field.NSP_CommissionAmount__c')!=null && this.NSP_CommissionsSelectOne__c != null){
        if(this.NSP_CommissionsSelectOne__c.includes('additional compensation')){
            this.template.querySelector('lightning-input-field.NSP_CommissionAmount__c').style.display='';
        }else{
            this.template.querySelector('lightning-input-field.NSP_CommissionAmount__c').style.display='none';
            this.template.querySelector('lightning-input-field.NSP_CommissionAmount__c').value='';
        }
    }
    }
    //additional compensation
    if( event.currentTarget.name == "NSP_OutplacementServicesValue__c" && event.currentTarget.value != null){
        this.NSP_OutplacementServicesValue__c = event.currentTarget.value ;
        if(this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsOfOutplacement_Service__c')!= null){
            if(this.NSP_OutplacementServicesValue__c.includes('Standard Outplacement')){
                this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsOfOutplacement_Service__c').style.display='';
            }else{
                this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsOfOutplacement_Service__c').style.display='none';
                this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsOfOutplacement_Service__c').value='';
            }
            
        }
        if(this.template.querySelector('lightning-input-field.NSP_AmountOfReimbursement__c')!=null){
            if(this.NSP_OutplacementServicesValue__c.includes('Reimbursement of Outplacement')){
                this.template.querySelector('lightning-input-field.NSP_AmountOfReimbursement__c').style.display='';
            }else{
                this.template.querySelector('lightning-input-field.NSP_AmountOfReimbursement__c').style.display='none';
                this.template.querySelector('lightning-input-field.NSP_AmountOfReimbursement__c').value='';
            }
            
        }
        if(this.template.querySelector('lightning-input-field.NSP_ExpirationDate__c')!=null )
        {
            this.template.querySelector('lightning-input-field.NSP_ExpirationDate__c').style.display='';
        }if(this.template.querySelector('div.OutplacementServices')!=null){
            this.template.querySelector('div.OutplacementServices').style.display='';
        }
    }

    if( event.currentTarget.name == "NSP_TransitionOfDutiesValue__c" && event.currentTarget.value != null){
        this.NSP_TransitionOfDutiesValue__c = event.currentTarget.value ;
        if(this.template.querySelector('div.Transition1') !=null){
            if(this.NSP_TransitionOfDutiesValue__c.includes('Transition 1')){
                this.template.querySelector('div.Transition1').style.display=''
            }else{
                this.template.querySelector('div.Transition1').style.display='none';
                this.template.querySelector('div.Transition1').value='';
            }
            
        }

        if(this.template.querySelector('div.Transition2')!=null){
            if(this.NSP_TransitionOfDutiesValue__c.includes('Transition 2')){
                this.template.querySelector('div.Transition2').style.display='';
            }else{
                this.template.querySelector('div.Transition2').style.display='none';
                this.template.querySelector('div.Transition2').value='';
            }
        }
    }

    if( event.currentTarget.name == "NSP_Installments__c" && event.currentTarget.value != null){
        this.NSP_Installments__c = event.currentTarget.value ;
        this.NSP_Installments = true;
       //this.template.querySelector('div.NSP_Installments_Check__c').style.display='';
    }
    if(this.template.querySelector('lightning-input-field.NSP_NumberOfpayments__c') != null){
        if(this.NSP_Installments__c != null){
            this.template.querySelector('lightning-input-field.NSP_NumberOfpayments__c').style.display='';
        }else{
            this.template.querySelector('lightning-input-field.NSP_NumberOfpayments__c')
            this.template.querySelector('lightning-input-field.NSP_NumberOfpayments__c').style.display='none';
            this.template.querySelector('lightning-input-field.NSP_NumberOfpayments__c').value='';
        }
      }
}



showMsg(event){
    if(this.isclicked){
        this.template.querySelector('div.showMsg').style.display='';
        this.isclicked = false;
        }else{
            this.template.querySelector('div.showMsg').style.display='none';
            this.isclicked = true;
        }
    }

/***   Coprorate Review Fields only    */
get isCorporateReview(){
  if(this.ReviewStatusOption.data){
    return (this.reviewType =='Corporate Review');
  }else{
      return false;
  }
}

reviewStatusValue;

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: TRANSITION_PICKLIST
})
transitionOption;

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: INSTALLMENT_PICKLIST
})
instalmentOption;

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: EQUIPMENT_PICKLIST
})
equipmentOption;

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: OUTPLACEMENT_PICKLIST
})
outplacementOption;

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: COMMISION_PICKLIST
})
commissionOption;

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: COBRA_PICKLIST
})
cobraOption;

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: BONUS_PICKLIST
})
bonusOptions;


@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: REVIEW_STATUS
})
ReviewStatusOption;

@wire(getPicklistValues, {
    recordTypeId: '$recordTypeId' ,
    fieldApiName: WHO_RESPONSIBLE_STOCK
})
whoIsResponsibleStock;

reviewType ;

/***   HRS Review  Fields only  */
get isHRSReview() {
      return (this.reviewType =='HRS Review');
  }

  get NSP_NumberOfpayments(){
    return (this.NSP_Installments && this.NSP_Installments__c != null);
}

isIncludedReleaseParty;
IsNSPDisclaimerIncluded;
whoResponsibleStok=false;

/** Insperity Prepared*/
enableInsperityPrepared =false;

/**  Common Fields**/
enableAddendumStock =false;
NSPResponsible = false;
prepareDocTerminationValue;
NSP_Attached_Approval_Email__c='';
IsanyReferenceStock;
whoResponsibleStokcValue;
adddendumValue;
NSP_HaveYouattachedPreparedAgreement__c = '';  // need to verify later

isOnloaded =true ;
connectedCallback(){
 this.isHRSReview ;
}

handleOnload(event){
    if(event.detail != null &&  event.detail.records != null){
     if(this.isOnloaded){
        this.fieldsData =Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].fields
        }

        this.recordTypeId =  Object.values(JSON.parse(JSON.stringify(event.detail.records)))[0].recordTypeId;
        if(this.fieldsData != null &&  this.fieldsData != undefined && this.fieldsData !='' ){
            this.NSP_Mid_Market_or_Mid_Market_Enterprise__c = this.fieldsData.NSP_Mid_Market_or_Mid_Market_Enterprise__c?.value =='Yes' ? ( this.fileCounts++ ,true ) : false;
            if(this.fieldsData.NSP_ReviewType__c != null  && this.fieldsData.NSP_ReviewType__c.value != null){
                    this.reviewType = this.fieldsData.NSP_ReviewType__c.value;
            }
            
            if(this.fieldsData.NSP_AgreementType__c != null  && this.fieldsData.NSP_AgreementType__c.value != null
                && this.fieldsData.NSP_AgreementType__c.value  == 'Insperity-Prepared'){	
                this.enableInsperityPrepared= true; 
            }
            
            
            if(this.fieldsData.NSP_RequestingMultipleEmployees__c != null  && this.fieldsData.NSP_RequestingMultipleEmployees__c.value != null){
            if(this.fieldsData.NSP_RequestingMultipleEmployees__c.value = 'No'){
                if(this.fieldsData.NSP_WorkState__c != null  && this.fieldsData.NSP_WorkState__c.value != null && this.fieldsData.NSP_WorkState__c.value !='') 
                    if( this.fieldsData.NSP_WorkState__c.value  == 'CA'){	
                        this.NSP_RemoveNoRehireClause = true;
                        this.NSP_KeepNorehireParagraphForcompany =true;
                        this.NSP_NonSolicitationofCustomers_Company= true ;
                    }
                    if( this.fieldsData.NSP_WorkState__c.value  == 'IL'){	
                        this.NSP_MutualNonDisparagement =true;
                        this.NSP_MutualConfidentiality =true;
                    }
                   if (this.fieldsData.NSP_WorkState__c.value  != 'IL' && this.fieldsData.NSP_WorkState__c.value  != 'CA'){
                       /**
                        if(this.template.querySelector('div.California') != null){
                            this.template.querySelector('div.California').style.display='none';
                        }
                        if(this.template.querySelector('div.Illinois') != null){
                            this.template.querySelector('div.Illinois').style.display='none';
                        }
                         */
                    }
                } 
            
          }

            if(this.fieldsData.NSP_AnyProvisionInPreparedDocRefersStock__c != null  && this.fieldsData.NSP_AnyProvisionInPreparedDocRefersStock__c.value != null){
                this.IsanyReferenceStock = this.fieldsData.NSP_AnyProvisionInPreparedDocRefersStock__c.value;
                this.whoResponsibleStok = (this.IsanyReferenceStock == "Yes");
                if(this.whoResponsibleStok){
                    if(this.isHRSReview){
                        this.hrsstopMsgStock = "display:''";
                        if(this.template.querySelector('div.clientResponsible')!=null)this.template.querySelector('div.clientResponsible').style.display='';
                    }else{
                        if(this.template.querySelector('div.WhoResponsibleForStockEquityPaymt') != null){
                            this.template.querySelector('div.WhoResponsibleForStockEquityPaymt').style.display='';
                        }
                    }
                }else{
                    this.whoResponsibleStokcValue ='';
                    this.adddendumValue =''
                    if(this.isHRSReview){
                        if(this.template.querySelector('div.clientResponsible')!=null)this.template.querySelector('div.clientResponsible').style.display='none';
                            }else{
                     
                    if(this.template.querySelector('div.WhoResponsibleForStockEquityPaymt') != null){
                        this.template.querySelector('div.WhoResponsibleForStockEquityPaymt').style.display='none';
                        this.whoResponsibleStokcValue ='';
                        this.adddendumValue =''
                        this.enableAddendumStock = false;
                        this.template.querySelector('div.clientResponsible')!=null?this.template.querySelector('div.clientResponsible').style.display='none':'';

                        this.template.querySelector('div.AaddendumNO')!=null?this.template.querySelector('div.AaddendumNO').style.display='none':'';

                        this.template.querySelector('div.AaddendumYES')!=null?this.template.querySelector('div.AaddendumYES').style.display='none':'';

                        if(this.template.querySelector('div.NSPResponsible')!=null)this.template.querySelector('div.NSPResponsible').style.display='none';  
                    }
                    }
                }

            }

            if(this.fieldsData.NSP_WhoResponsibleForStockEquityPaymt__c != null  && this.fieldsData.NSP_WhoResponsibleForStockEquityPaymt__c.value != null){	
                this.whoResponsibleStokcValue = this.fieldsData.NSP_WhoResponsibleForStockEquityPaymt__c.value;
                if(this.template.querySelector('div.WhoResponsibleForStockEquityPaymt')!=null)this.template.querySelector('div.WhoResponsibleForStockEquityPaymt').style.display='';
                this.enableAddendumStock = (this.whoResponsibleStokcValue == "Insperity");
                if(this.template.querySelector('div.AaddendumNO')!=null)this.template.querySelector('div.AaddendumNO').style.display='none';
                if(this.template.querySelector('div.NSPResponsible')!=null)this.template.querySelector('div.NSPResponsible').style.display="none";
                if(this.template.querySelector('div.AaddendumYES')!=null)this.template.querySelector('div.AaddendumYES').style.display='none';
                this.adddendumValue ='';
                if(this.enableAddendumStock){
                    if(this.template.querySelector('div.clientResponsible')!=null)this.template.querySelector('div.clientResponsible').style.display='none';
                    if(this.template.querySelector('div.NSPResponsible')!=null)this.template.querySelector('div.NSPResponsible').style.display='';
                    if(this.template.querySelector('lightning-radio-group[data-fname="addendum"]')!=null)this.template.querySelector('lightning-radio-group[data-fname="addendum"]').value ="";
                }    
                 else{
                    this.enableAddendumStock = false;
                    if(this.template.querySelector('div.clientResponsible')!=null)this.template.querySelector('div.clientResponsible').style.display='';
                    }
            }

            if( this.fieldsData.NSP_CSAaddendumForStockEquity__c != null  && this.fieldsData.NSP_CSAaddendumForStockEquity__c.value != null){
                this.adddendumValue = this.fieldsData.NSP_CSAaddendumForStockEquity__c.value;
                if(this.template.querySelector('lightning-radio-group[data-fname="addendum"]')!= null)this.template.querySelector('lightning-radio-group[data-fname="addendum"]').value =this.adddendumValue;
                if(this.adddendumValue == "Yes"){
                    if(this.template.querySelector('div.AaddendumNO')!=null)this.template.querySelector('div.AaddendumNO').style.display='none';
                    if(this.template.querySelector('div.AaddendumYES')!=null)this.template.querySelector('div.AaddendumYES').style.display='';
                }else{
                    if(this.template.querySelector('div.AaddendumNO')!=null)this.template.querySelector('div.AaddendumNO').style.display='';
                    if(this.template.querySelector('div.AaddendumYES')!=null)this.template.querySelector('div.AaddendumYES').style.display='none';
                }
            }

            
            if( this.fieldsData.NSP_ReviewStatus__c && this.fieldsData.NSP_ReviewStatus__c.value != null ){
               this.reviewStatusValue = this.fieldsData.NSP_ReviewStatus__c .value;        
            }
        
            if( this.fieldsData.NSP_AnyPreparedDocumentForTermination__c && this.fieldsData.NSP_AnyPreparedDocumentForTermination__c.value != null ){
                this.prepareDocTerminationValue = this.fieldsData.NSP_AnyPreparedDocumentForTermination__c.value; 
                if(this.isHRSReview && this.template.querySelector('div.AttachmentVerify')!= null ){
                    this.prepareDocTerminationValue == "Yes" ? this.template.querySelector('div.AttachmentVerify').style.display='':
                    this.template.querySelector('div.AttachmentVerify').style.display='none';
                }
             }
             if( this.fieldsData.NSP_Attached_Approval_Email__c && this.fieldsData.NSP_Attached_Approval_Email__c.value != null){
                this.NSP_Attached_Approval_Email__c = this.fieldsData.NSP_Attached_Approval_Email__c.value;
                if( this.template.querySelector('div.NSP_Attached_Approval_Email__c')!= null){
                    if( this.NSP_Attached_Approval_Email__c == "No" ){
                        this.template.querySelector('div.NSP_Attached_Approval_Email__c').style.display='';
                    }else{
                        this.template.querySelector('div.NSP_Attached_Approval_Email__c').style.display='none';
                    }
                }

             }



             if( this.fieldsData.NSP_HaveYouattachedPreparedAgreement__c && this.fieldsData.NSP_HaveYouattachedPreparedAgreement__c.value != null){
                this.NSP_HaveYouattachedPreparedAgreement__c = this.fieldsData.NSP_HaveYouattachedPreparedAgreement__c.value;
                if( this.template.querySelector('div.NSP_HaveYouattachedPreparedAgreement__c')!= null){
                    if( this.NSP_HaveYouattachedPreparedAgreement__c == "No" ){
                        this.template.querySelector('div.NSP_HaveYouattachedPreparedAgreement__c').style.display='';
                    }else{
                        this.template.querySelector('div.NSP_HaveYouattachedPreparedAgreement__c').style.display='none';
                    }
                }

             }
            // if(this.fieldsData.NSP_ != null  && this.fieldsData.NSP_.value != null){	

            if(this.isHRSReview){
                if(this.fieldsData.NSP_IsInsperityIncludedAsReleasedParty__c && this.fieldsData.NSP_IsInsperityIncludedAsReleasedParty__c.value != null){
                    this.isIncludedReleaseParty =  this.fieldsData.NSP_IsInsperityIncludedAsReleasedParty__c.value;
                    if( this.template.querySelector('div.showIncludePartyMsg')!= null){
                        if( this.isIncludedReleaseParty == "No" ){
                            this.template.querySelector('div.showIncludePartyMsg').style.display='';

                        }else{
                            this.template.querySelector('div.showIncludePartyMsg').style.display='none';
                        }
                    }
                }
                if(this.fieldsData.NSP_IsInsperityDisclaimerIncluded__c && this.fieldsData.NSP_IsInsperityDisclaimerIncluded__c.value != null){
                    this.IsNSPDisclaimerIncluded =this.fieldsData.NSP_IsInsperityDisclaimerIncluded__c.value ;
                    if( this.template.querySelector('div.showIncludePartyMsg')!= null){
                        if( this.IsNSPDisclaimerIncluded == "No"){
                            this.template.querySelector('div.showIncludeDisclaimeryMsg').style.display='';
                        }else{
                            this.template.querySelector('div.showIncludeDisclaimeryMsg').style.display='none';
                        }
                    }
                }

                if(this.fieldsData.NSP_IsInsperityDisclaimerIncluded__c && this.fieldsData.NSP_IsInsperityDisclaimerIncluded__c.value != null){
                    this.IsNSPDisclaimerIncluded =this.fieldsData.NSP_IsInsperityDisclaimerIncluded__c.value ;

                }

            }

        if(this.enableInsperityPrepared){
            for (const key in this.fieldsData) {
                if(this.checkBoxField.includes(key)){
                    let value = this.fieldsData[key].value;
                if( this.template.querySelector('div.'+key) != null){
                    this.fieldsData[key].value == true? this.template.querySelector('div.'+key).style.display='':this.template.querySelector('div.'+key).style.display='none';
                    }

                 if( this.template.querySelector('lightning-input-field.'+key) != null){
                        [...this.template.querySelectorAll('lightning-input-field.' + key)].map(x =>{
                            value == true ? x.style.display='':x.style.display='none';
                            /**
                            console.log( 'Field value ' + this.fieldsData[key].value +'---'+ this.fieldsData[key].value == true );
                            console.log( 'Field Name ' + key );
                            console.log( 'Field Sytle ' + x.style.display );
                             */
                        });
                 }
                    if( this.template.querySelector('lightning-radio-group.'+key) != null){
                     value == true? this.template.querySelector('lightning-radio-group.'+key).style.display='':this.template.querySelector('lightning-radio-group.'+key).style.display='none';
                    }

                if(this.template.querySelector('lightning-radio-group.'+key+'_childNode')!=null){
                    [...this.template.querySelectorAll('lightning-radio-group.'+ key+'_childNode')].map(x =>{
                        value == true? x.style.display='': (x.style.display='none',x.value='');
                    });
                }
               }
              }

              if((this.fieldsData.NSP_RemoveNoRehireClause__c && this.fieldsData.NSP_RemoveNoRehireClause__c.value != null) ||
                (this.fieldsData.NSP_KeepNorehireParagraphForcompany__c && this.fieldsData.NSP_KeepNorehireParagraphForcompany__c.value != null))
                {
                     if(this.fieldsData.NSP_RemoveNoRehireClause__c.value == true){
                    this.NSP_RemoveNoRehireClause = true;
                    }else{
                        this.NSP_RemoveNoRehireClause = false;
                    }

                    if(this.fieldsData.NSP_KeepNorehireParagraphForcompany__c.value == true){
                        this.NSP_KeepNorehireParagraphForcompany = true;
                     }else{
                            this.NSP_KeepNorehireParagraphForcompany = false;
                    }
                }
            }
            if(this.isOnloaded){
            if(this.transitionOption.data != null && this.equipmentOption.data != null && this.outplacementOption.data != null && this.enableInsperityPrepared && this.instalmentOption.data !=null
                && this.commissionOption.data !=null && this.cobraOption.data != null && this.bonusOptions.data != null && this.ReviewStatusOption.data != null)
                { 
                    for (let key in this.fieldsData) {
                        if( this.fieldsData[key]!= null && this.fieldsData[key].value !=null 
                            && this.fieldsData[key].value != ''){
                            if(this.preparedFields.includes(key)){
                                this[key]=this.fieldsData[key].value;
                                }

                                if(this.currentPageFields.includes(key)){
                                this.fieldValue.currentTarget.name = key ;
                                this.fieldValue.currentTarget.value = this.fieldsData[key].value; 
                                this.onchangeNspPrepared(this.fieldValue);
                                }
                                if(this.radioRequiredFields.includes(key.slice(0,-3))){
                                    this[key.slice(0,-3)] = ( this.fieldsData[key].value == true );
                                }

                                if(this.checkBoxField.includes(key) && this.fieldsData[key].value == true){
                                    
                                }
                        }
                    }
                    if(this.template.querySelector('lightning-input-field.NSP_EnterBonusAmmount__c') !=null && 
                    this.template.querySelector('lightning-input-field.NSP_COBRA_Amount__c')!= null && this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsCOBRA__c')!= null
                    && this.template.querySelector('lightning-input-field.NSP_NumberOfMonthsOfOutplacement_Service__c')!=null
                    && this.template.querySelector('lightning-input-field.NSP_AmountOfReimbursement__c')!=null && this.template.querySelector('lightning-input-field.NSP_ExpirationDate__c')!=null &&
                    this.template.querySelector('div.OutplacementServices')!=null && this.template.querySelector('div.Transition1') !=null && this.template.querySelector('div.Transition2') !=null
                    ){
                        this.isOnloaded=false;
                    }
                    
              }
            }

       }
  
   }
}

/***********    -----------------------------------------------------    ******/

handleSave(event) {
    this.isSaveClick=true;
    this.template.querySelector('lightning-record-edit-form').submit();
}

handleSuccess(event){
    if(!this.isPrevClick && !this.isSaveClick){
        const reReqId = event.detail.id;
        this.dispatchEvent(new CustomEvent('next', {detail: reReqId}));
        }
        else if(this.isSaveClick){
            const saveEvent = new CustomEvent('saveexit', { bubbles: true });
            this.dispatchEvent(saveEvent);
        }
}


handleSubmit(event){
    this.findFileSize(event);
    
    if(this.filesize < 1 && this.NSP_ReferenceTospecificClientDocument__c !=null && this.NSP_ReferenceTospecificClientDocument__c == true )
    {
        event.preventDefault(); // it will prevent the submit
    }

    if(this.filesize < 1 && this.whoResponsibleStokcValue !=null && this.whoResponsibleStokcValue == 'Client'){
        event.preventDefault(); // it will prevent the submit
    }

    if(this.filesize < 1 && this.prepareDocTerminationValue !=null && this.prepareDocTerminationValue == 'Yes'){
        event.preventDefault(); // it will prevent the submit
    }
    if(this.NSP_Attached_Approval_Email__c == 'No' || this.filesize < 1 && this.NSP_Attached_Approval_Email__c == 'Yes' ){
        this.template.querySelector('div.NSP_Attached_Approval_Email__c').style.display='block';
        event.preventDefault();
    }
    if(this.NSP_HaveYouattachedPreparedAgreement__c == 'No' || this.filesize < 1 && this.NSP_HaveYouattachedPreparedAgreement__c == 'Yes' ){
        this.template.querySelector('div.NSP_HaveYouattachedPreparedAgreement__c').style.display='block';
        event.preventDefault();
    }
    if(this.filesize < 1 && this.reviewType =='HRS Review' && this.IsanyReferenceStock =="Yes" ){
        this.hrsstopMsgStock = "display:''";
        event.preventDefault();
    }
}

hanldeNext(event){
}



handlePrev(event){
    this.isPrevClick=true;
    this.dispatchEvent(new CustomEvent('prev', {detail: this.reReqId}));
  }

  handleChange(event){

    if( event.currentTarget.name == "AnyProvisionInPreparedDocRefersStock" && event.currentTarget.value != null){
        this.IsanyReferenceStock = event.currentTarget.value;
        this.whoResponsibleStok = (event.currentTarget.value === "Yes");
        if(this.whoResponsibleStok){
            if(this.isHRSReview){
                if(this.template.querySelector('div.clientResponsible')!=null)this.template.querySelector('div.clientResponsible').style.display='';
            }else{
                if(this.template.querySelector('div.WhoResponsibleForStockEquityPaymt')!=null)this.template.querySelector('div.WhoResponsibleForStockEquityPaymt').style.display='';
            }
        }else{
            if(this.isHRSReview){
                if(this.template.querySelector('div.clientResponsible')!=null)this.template.querySelector('div.clientResponsible').style.display='none';
            }else{
            if(this.template.querySelector('div.WhoResponsibleForStockEquityPaymt')!=null)this.template.querySelector('div.WhoResponsibleForStockEquityPaymt').style.display='none';
            this.whoResponsibleStokcValue ='';
            this.adddendumValue =''
            if(this.template.querySelector('div.clientResponsible')!=null)this.template.querySelector('div.clientResponsible').style.display='none';
            if(this.template.querySelector('div.AaddendumNO')!=null)this.template.querySelector('div.AaddendumNO').style.display='none';
            if(this.template.querySelector('div.AaddendumYES')!=null)this.template.querySelector('div.AaddendumYES').style.display='none';
            if(this.template.querySelector('div.NSPResponsible')!=null)this.template.querySelector('div.NSPResponsible').style.display='none';
            }
            this.enableAddendumStock = false;
        }
    }
    
    if( event.currentTarget.name == "WhoResponsibleForStockEquityPaymt" && event.currentTarget.value !=null ){
        this.whoResponsibleStokcValue = event.currentTarget.value;
        this.enableAddendumStock = (event.currentTarget.value == "Insperity");
        if(this.template.querySelector('div.AaddendumNO')!=null)this.template.querySelector('div.AaddendumNO').style.display='none';
        if(this.template.querySelector('div.NSPResponsible')!=null)this.template.querySelector('div.NSPResponsible').style.display="none";
        if(this.template.querySelector('div.AaddendumYES')!=null)this.template.querySelector('div.AaddendumYES').style.display='none';
        this.adddendumValue ='';
        if(this.enableAddendumStock){
            this.enableAddendumStock = true;
            if(this.template.querySelector('div.clientResponsible')!=null)this.template.querySelector('div.clientResponsible').style.display='none';
            if(this.template.querySelector('div.NSPResponsible')!=null)this.template.querySelector('div.NSPResponsible').style.display='';
            if(this.template.querySelector('lightning-radio-group[data-fname="addendum"]')!=null)this.template.querySelector('lightning-radio-group[data-fname="addendum"]').value ="";
            }else{
            this.enableAddendumStock = false;
            if(this.template.querySelector('div.clientResponsible')!=null)this.template.querySelector('div.clientResponsible').style.display='';
            }
    }

    if( event.currentTarget.name == "AaddendumForStockEquity" && event.currentTarget.value !=null ){
        this.adddendumValue = event.currentTarget.value;
        if( event.currentTarget.value == "Yes"){
            if(this.template.querySelector('div.AaddendumNO')!=null)this.template.querySelector('div.AaddendumNO').style.display='none';
            if(this.template.querySelector('div.AaddendumYES')!=null)this.template.querySelector('div.AaddendumYES').style.display='';
        }else{
            if(this.template.querySelector('div.AaddendumNO')!=null)this.template.querySelector('div.AaddendumNO').style.display='';
            if(this.template.querySelector('div.AaddendumYES')!=null)this.template.querySelector('div.AaddendumYES').style.display='none';
        }
    }

    if( event.currentTarget.name == "IsInsperityIncludedAsReleasedParty" && event.currentTarget.value != null){
        this.isIncludedReleaseParty =  event.currentTarget.value;
        if( event.currentTarget.value == "No"){
            if(this.template.querySelector('div.showIncludePartyMsg')!=null)this.template.querySelector('div.showIncludePartyMsg').style.display='';
        }else{
            if(this.template.querySelector('div.showIncludePartyMsg')!=null)this.template.querySelector('div.showIncludePartyMsg').style.display='none';
        }
    }

    if( event.currentTarget.name == "IsInsperityDisclaimerIncluded" && event.currentTarget.value != null){
        this.IsNSPDisclaimerIncluded =event.currentTarget.value ;
        if( event.currentTarget.value == "No"){
            if(this.template.querySelector('div.showIncludePartyMsg')!=null)this.template.querySelector('div.showIncludeDisclaimeryMsg').style.display='';
        }else{
            if(this.template.querySelector('div.showIncludePartyMsg')!=null)this.template.querySelector('div.showIncludeDisclaimeryMsg').style.display='none';
        }
    }
    
    if( event.currentTarget.name == "ReviewStatus" && event.currentTarget.value != null ){
       this.reviewStatusValue = event.currentTarget.value;        
    }

    if( event.currentTarget.name == "AnyPreparedDocumentForTermination" && event.currentTarget.value != null ){
        this.prepareDocTerminationValue = event.currentTarget.value; 
      /**  if(this.isHRSReview && this.template.querySelector('div.AttachmentVerify')!= null ){
        this.prepareDocTerminationValue == "Yes" ? this.template.querySelector('div.AttachmentVerify').style.display='':
        this.template.querySelector('div.AttachmentVerify').style.display='none';
        }
         */
     }

     if( event.currentTarget.name == "AnyAttachedApprovalEmail" && event.currentTarget.value != null ){
        this.NSP_Attached_Approval_Email__c = event.currentTarget.value;  
        if( this.template.querySelector('div.NSP_Attached_Approval_Email__c')!= null){
            if( this.NSP_Attached_Approval_Email__c == "No" ){
                this.template.querySelector('div.NSP_Attached_Approval_Email__c').style.display='';
            }else{
                this.template.querySelector('div.NSP_Attached_Approval_Email__c').style.display='none';
            }
        }  
     }
     if( event.currentTarget.name == "HaveYouattachedPreparedAgreement" && event.currentTarget.value != null ){
        this.NSP_HaveYouattachedPreparedAgreement__c = event.currentTarget.value;  
        if( this.template.querySelector('div.NSP_HaveYouattachedPreparedAgreement__c')!= null){
            if( this.NSP_HaveYouattachedPreparedAgreement__c == "No" ){
                this.template.querySelector('div.NSP_HaveYouattachedPreparedAgreement__c').style.display='';
            }else{
                this.template.querySelector('div.NSP_HaveYouattachedPreparedAgreement__c').style.display='none';
            }
        }  
     }
  }


  findFileSize(event){
    if( event.detail != null && event.detail.length != null){
        this.filesize = event.detail.length;
    }

    if(this.filesize <1){

        if((this.NSP_ReferenceTospecificClientDocument__c !=null && this.NSP_ReferenceTospecificClientDocument__c == true ) && this.template.querySelector("div.ReferenceTospecificClientDocument")!= null ){
            this.template.querySelector("div.ReferenceTospecificClientDocument").style.display ='';
        }

        if(this.whoResponsibleStokcValue !=null && this.whoResponsibleStokcValue == 'Client' && this.template.querySelector("div.clientResponsiblefile")!= null ){
            this.template.querySelector("div.clientResponsiblefile").style.display ='';
        }

        if(this.prepareDocTerminationValue !=null && this.prepareDocTerminationValue == 'Yes' && this.template.querySelector("div.AttachmentVerify")!= null ){
            this.template.querySelector("div.AttachmentVerify").style.display ='';
        }


        if((this.NSP_ReferenceTospecificClientDocument__c ==null || this.NSP_ReferenceTospecificClientDocument__c != true) && this.template.querySelector("div.ReferenceTospecificClientDocument")!= null ){
            this.template.querySelector("div.ReferenceTospecificClientDocument").style.display ='none';
        }
        if((this.whoResponsibleStokcValue ==null || this.whoResponsibleStokcValue != 'Client' ) && this.template.querySelector("div.clientResponsiblefile")!= null ){
            this.template.querySelector("div.clientResponsiblefile").style.display ='none';
        }

        if((this.prepareDocTerminationValue == null || this.prepareDocTerminationValue != 'Yes' ) && this.template.querySelector("div.AttachmentVerify")!= null ){
            this.template.querySelector("div.AttachmentVerify").style.display ='none';
        }

    }else {

        if((this.NSP_ReferenceTospecificClientDocument__c ==null || this.NSP_ReferenceTospecificClientDocument__c != true || this.filesize >0 ) && this.template.querySelector("div.ReferenceTospecificClientDocument")!= null ){
            this.template.querySelector("div.ReferenceTospecificClientDocument").style.display ='none';
        }
        if((this.whoResponsibleStokcValue ==null || this.whoResponsibleStokcValue != 'Client' || this.filesize > 0 ) && this.template.querySelector("div.clientResponsiblefile")!= null ){
            this.template.querySelector("div.clientResponsiblefile").style.display ='none';
        }

        if((this.prepareDocTerminationValue == null || this.prepareDocTerminationValue != 'Yes' || this.filesize > 0) && this.template.querySelector("div.AttachmentVerify")!= null ){
            this.template.querySelector("div.AttachmentVerify").style.display ='none';
        }
        if(this.NSP_Attached_Approval_Email__c == 'Yes' &&  this.filesize > 0 && this.template.querySelector('div.NSP_Attached_Approval_Email__c')!=null){
            this.template.querySelector('div.NSP_Attached_Approval_Email__c').style.display='none';
        }

        if(this.NSP_HaveYouattachedPreparedAgreement__c == 'Yes' &&  this.filesize > 0 && this.template.querySelector('div.NSP_HaveYouattachedPreparedAgreement__c')!=null){
        this.template.querySelector('div.NSP_HaveYouattachedPreparedAgreement__c').style.display='none';
        }
        this.hrsstopMsgStock ="display:none";

 }
}
}