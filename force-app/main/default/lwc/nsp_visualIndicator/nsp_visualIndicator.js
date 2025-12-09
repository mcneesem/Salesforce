import { api, track, LightningElement, wire } from 'lwc';
import nsp_ReportingResource from '@salesforce/resourceUrl/NSP_ReportingResource';
import gethisAccount from '@salesforce/apex/NSP_VisualIndicatorHelper.gethisAccount';
import getAccountId from '@salesforce/apex/NSP_VisualIndicatorHelper.getAccountId';
import isCaseFromEmail from '@salesforce/apex/NSP_VisualIndicatorHelper.isCaseFromEmail';


export default class vi2 extends LightningElement {
    @api recordId;
    accountId;
    @track showPaperless = false;
    @track showNationalAccount = false;
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
    @track showEmailToCase = false;
    showHRScale = false;
    
    contract_exempt = nsp_ReportingResource + '/nsp_ReportingResource/images/contract_exempt.png';
    somewhat_fav = nsp_ReportingResource + '/nsp_ReportingResource/images/somewhat_fav.jfif';
    paperless = nsp_ReportingResource + '/nsp_ReportingResource/images/not_paperless.png';
    nationalAccount = nsp_ReportingResource + '/nsp_ReportingResource/images/nationalAccount.png';
    neutral = nsp_ReportingResource + '/nsp_ReportingResource/images/neutral.jfif';
    somewhat_unfav = nsp_ReportingResource + '/nsp_ReportingResource/images/somewhat_unfav.jfif';
    fav = nsp_ReportingResource + '/nsp_ReportingResource/images/fav.jfif';
    unfav = nsp_ReportingResource + '/nsp_ReportingResource/images/unfav.jfif';
    pending_termination = nsp_ReportingResource + '/nsp_ReportingResource/images/pending_termination.png';
    voc6mo = nsp_ReportingResource + '/nsp_ReportingResource/images/voc6mo.png';
    wf_sync = nsp_ReportingResource + '/nsp_ReportingResource/images/wf_sync.png';
    crwc = nsp_ReportingResource + '/nsp_ReportingResource/images/crwc.png';
    emailToCase = nsp_ReportingResource + '/nsp_ReportingResource/images/emailToCase.png';
    hrScale = nsp_ReportingResource + '/nsp_ReportingResource/images/HRScale.png'; 

    @wire(isCaseFromEmail, { caseId: '$recordId' })
    wiredResult({ error, data }) {
        if (data !== undefined) {
            this.showEmailToCase = data;
        } else if (error) {
            console.log('@@error: '+error);
        }
    }

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
                //For Asset National Account
                if (this.accountsDetails[0].assetNationalAccount){
                    this.showNationalAccount = true;
                }
                //For workforce sync client                
                if (this.accountsDetails[0].workSyncClientTrue){
                    this.showWorkSyncClientTrue = true; 
                } 
                // For HRScale
                if (this.accountsDetails[0].hrScale) {
                this.showHRScale = true;
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
                this.handleRenewalProbabilityIndicator(this.accountsDetails[0].accRecord);            
                //For Account Health Indicator
                this.handleAccountHealthIndicator(this.accountsDetails[0].accRecord);

            })
            .catch((error)=>{
            console.log('@@error: '+error);
        });
    }
    handleRenewalProbabilityIndicator(accRecord) {
        if(accRecord.NSP_Renewal_Probability__c != null){
            const renewal = accRecord.NSP_Renewal_Probability__c;

            this.showNeutral = renewal === 'Neutral';
            this.showSomewhat_fav = renewal === 'Somewhat favorable';
            this.showSomewhat_unfav = renewal === 'Somewhat unfavorable';
            this.showUnfav = renewal === 'Unfavorable';
            this.showFav = renewal === 'Favorable';
        }
    }
    handleAccountHealthIndicator(accRecord) {
        if(accRecord.NSP_Account_Health__c != null){
            const health = accRecord.NSP_Account_Health__c;

            this.showFav_AH = health === 'Favorable';
            this.showNeutral_AH = health === 'Neutral';
            this.showSomewhat_fav_AH = health === 'Somewhat favorable';
            this.showSomewhat_unfav_AH = health === 'Somewhat unfavorable';
            this.showUnfav_AH = health === 'Unfavorable';
        }
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