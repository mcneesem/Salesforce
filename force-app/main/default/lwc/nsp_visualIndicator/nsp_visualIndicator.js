import { api, track, LightningElement } from 'lwc';
import nsp_ReportingResource from '@salesforce/resourceUrl/NSP_ReportingResource';
import gethisAccount from '@salesforce/apex/NSP_VisualIndicatorHelper.gethisAccount';
import getAccountId from '@salesforce/apex/NSP_VisualIndicatorHelper.getAccountId';


export default class vi2 extends LightningElement {
    @api recordId;
    accountId;
    @track showPaperless = false;
    @track showNeutral = false;
    @track showSomewhat_fav = false;
    @track showSomewhat_unfav = false;
    @track showSomewhat_unfav = false;
    @track showUnfav = false;
    @track showFav = false;
    @track showFav_AH = false;
    @track showNeutral_AH = false;
    @track showSomewhat_fav_AH = false;
    @track showSomewhat_unfav_AH = false;
    @track showUnfav_AH = false;
    @track showContractExempt = false;
    @track accountsDetails;
    @track showWorkSyncClientTrue = false;
    @track whoClient100True = false; 
    @track showClientAndInsperity = false;
    @track showPendingTermination = false;
    @track vocSurveyIndicator = false;
    
    contract_exempt = nsp_ReportingResource + '/nsp_ReportingResource/images/contract_exempt.png';
    somewhat_fav = nsp_ReportingResource + '/nsp_ReportingResource/images/somewhat_fav.jfif';
    paperless = nsp_ReportingResource + '/nsp_ReportingResource/images/not_paperless.png';
    neutral = nsp_ReportingResource + '/nsp_ReportingResource/images/neutral.jfif';
    somewhat_unfav = nsp_ReportingResource + '/nsp_ReportingResource/images/somewhat_unfav.jfif';
    fav = nsp_ReportingResource + '/nsp_ReportingResource/images/fav.jfif';
    unfav = nsp_ReportingResource + '/nsp_ReportingResource/images/unfav.jfif';
    pending_termination = nsp_ReportingResource + '/nsp_ReportingResource/images/pending_termination.png';
    voc6mo = nsp_ReportingResource + '/nsp_ReportingResource/images/voc6mo.png';
    wf_sync = nsp_ReportingResource + '/nsp_ReportingResource/images/wf_sync.png';
    crwc = nsp_ReportingResource + '/nsp_ReportingResource/images/crwc.png';

    connectedCallback(){
        this.callGetAccountId();
    }  
    
    callGetThisAccount(){
        gethisAccount({accId: this.accountId})
            .then((data) =>{
                this.accountsDetails = data;
                //For Service Exemptions
                if (this.accountsDetails[0].serviceExceptionPresent){
                    this.showContractExempt = true; 
                }
                //For Asset Paperless                
                if (this.accountsDetails[0].assetPaperlessPresent){
                    this.showPaperless = true; 
                }  
                //For workforce sync client                
                if (this.accountsDetails[0].workSyncClientTrue){
                    this.showWorkSyncClientTrue = true; 
                } 
                //For client100True              
                if (this.accountsDetails[0].client100True){
                    this.whoClient100True = true; 
                } 
                //For clientAndInsperity              
                if (this.accountsDetails[0].clientAndInsperity){
                    this.showClientAndInsperity = true; 
                }  
                //For PendingTermination                 
                if (this.accountsDetails[0].pendingTermination){
                    this.showPendingTermination = true; 
                }
                //For VOC indicator
                if (this.accountsDetails[0].vocSurveyIndicator){
                    this.vocSurveyIndicator = true;
                }                                                                              
                //For Renewal Probability Indicator
                if (this.accountsDetails[0].accRecord.NSP_Renewal_Probability__c == 'Neutral'){
                    this.showNeutral = true;
                }       
                if (this.accountsDetails[0].accRecord.NSP_Renewal_Probability__c == 'Somewhat favorable'){
                    this.showSomewhat_fav= true;
                } 
                if (this.accountsDetails[0].accRecord.NSP_Renewal_Probability__c == 'Somewhat unfavorable'){
                    this.showSomewhat_unfav= true;
                }
                if (this.accountsDetails[0].accRecord.NSP_Renewal_Probability__c == 'Unfavorable'){
                    this.showUnfav= true;
                } 
                if (this.accountsDetails[0].accRecord.NSP_Renewal_Probability__c == 'Favorable'){
                    this.showFav= true;
                }                          
                //For Account Health Indicator
               
                if (this.accountsDetails[0].accRecord.NSP_Account_Health__c == "Favorable"){
                    this.showFav_AH = true;
                }   
                if (this.accountsDetails[0].accRecord.NSP_Account_Health__c == 'Neutral'){
                    this.showNeutral_AH = true;
                }       
                if (this.accountsDetails[0].accRecord.NSP_Account_Health__c == 'Somewhat favorable'){
                    this.showSomewhat_fav_AH = true;
                } 
                if (this.accountsDetails[0].accRecord.NSP_Account_Health__c == 'Somewhat unfavorable'){
                    this.showSomewhat_unfav_AH = true;
                }
                if (this.accountsDetails[0].accRecord.NSP_Account_Health__c == 'Unfavorable'){
                    this.showUnfav_AH = true;
                } 

            })
            .catch((error)=>{
            console.log('@@error: '+error);
        });
    }

    callGetAccountId(){
        getAccountId({accId: this.recordId})
        .then(result => {
            this.accountId = result;
            this.callGetThisAccount();
        })
        .catch((error)=>{
            console.log('@@error: '+error);
            });
    }          
}