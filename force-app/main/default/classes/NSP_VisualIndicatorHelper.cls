/*
* @Description:      This class is created to apply logic to display visual indicators on Account, Service Exceptions 
				      and Asset objects for Reporting
* @CreatedDate:      1/31/2023
* @LastModifiedDate: 3/24/2023 Updated for Change Request DF-03195: Gourav Das (PwC)
* @Story:            STY-00909
* */  
public without sharing class NSP_VisualIndicatorHelper {
    
    /**
* returns the account details for 
* @param accId Id related to account.    
* @return void             
*                
*/     
    @AuraEnabled(cacheable=true)
    public static List<VisualIndicatorWrapper> gethisAccount(String accId) {
        try{
            List<NSP_Service_Exception__c> expList = new List<NSP_Service_Exception__c>();	
            List<Asset> assetList = new List<Asset>();
            List<NSP_Survey__c> surveyList = new List<NSP_Survey__c>();
            List<VisualIndicatorWrapper> accWrapperList = new List<VisualIndicatorWrapper>();

            Id vocSruveyRecordTypeId = Schema.SObjectType.NSP_Survey__c.getRecordTypeInfosByDeveloperName().get('VOC').getRecordTypeId();

            List<Account> accList = [SELECT Id, NSP_Renewal_Probability__c, NSP_Account_Health__c, NSP_Paperless__c, Name, Industry,
                                            (SELECT Id, NSP_End_Date__c FROM Service_Exceptions__r),
                                            (SELECT Id, NSP_Paperless__c,NSP_Workforce_Sync__c, NSP_Client_Retained_Workers_Comp__c,
                                                    NSP_Pending_Termination__c, NSP_Service_Package__c, RecordTypeId FROM Assets),
                                            (SELECT Id, Survey_End_Date__c FROM Surveys__r 
                                                    WHERE RecordTypeId =:vocSruveyRecordTypeId AND Survey_End_Date__c !=null Order by Survey_End_Date__c Desc LIMIT 1) 
                                            FROM Account 
                                            WHERE Id = :accId];
            
            VisualIndicatorWrapper accWrapper = new VisualIndicatorWrapper();
                            
            for (Account accRecord: accList){
                if (!accRecord.Service_Exceptions__r.isEmpty()){
                    for (NSP_Service_Exception__c relExp: accRecord.Service_Exceptions__r){
                        expList.add(relExp);
                    }                
                }
                
                if (accRecord.Assets.size()>0){     
                    for (Asset eachAsset : accRecord.assets){
                        assetList.add(eachAsset);
                    }                
                }
                if (accRecord.Surveys__r.size()>0){
                    surveyList.add(accRecord.Surveys__r);
                }            
            }
            //To check if service exception is present 
            for (NSP_Service_Exception__c eachException: expList){
                //Updated for Change Request DF-03195
                //change 7/20 If end date us greater than today or null, the indicator will be present
                if(eachException.NSP_End_Date__c > = Date.today() || eachException.NSP_End_Date__c == null ){
                    accWrapper.serviceExceptionPresent = NSP_ServiceConstants.VALUE_TRUE;
                } 
            }
            Id woAssetRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
            
            
            for (Asset atleastAsset: assetList) {
                //To check if any 1 asset is paperless
                if(atleastAsset.RecordTypeId == woAssetRecordTypeId && atleastAsset.NSP_Paperless__c == NSP_ServiceConstants.VALUE_TRUE) {
                    accWrapper.assetPaperlessPresent = NSP_ServiceConstants.VALUE_TRUE;
                }
                if(atleastAsset.NSP_Service_Package__c != null  && atleastAsset.NSP_Service_Package__c.startswith('WS') ) {
                    accWrapper.workSyncClientTrue = NSP_ServiceConstants.VALUE_TRUE;
                }             
                if(atleastAsset.NSP_Client_Retained_Workers_Comp__c != null && atleastAsset.NSP_Client_Retained_Workers_Comp__c  == '100% Client' ) {
                    accWrapper.client100True = NSP_ServiceConstants.VALUE_TRUE;
                }  
                if(atleastAsset.NSP_Client_Retained_Workers_Comp__c != null && atleastAsset.NSP_Client_Retained_Workers_Comp__c == 'Client & Insperity' ) {
                    accWrapper.clientAndInsperity = NSP_ServiceConstants.VALUE_TRUE;
                }
                if(atleastAsset.NSP_Pending_Termination__c == NSP_ServiceConstants.VALUE_TRUE ) {
                    accWrapper.pendingTermination = NSP_ServiceConstants.VALUE_TRUE;
                }            
            }
            accWrapper.vocSurveyIndicator = False;
            
            if (surveyList.size()>0) {
                Date nspDaysLimit = surveyList[0].Survey_End_Date__c.addDays(180);
                
                Integer daysCalc = Date.today().daysBetween(nspDaysLimit);
                if (daysCalc >= 0){
                    accWrapper.vocSurveyIndicator = NSP_ServiceConstants.VALUE_TRUE;
                }
                // accWrapper.vocSurveyIndicator = Date.today().daysBetween(nspDaysLimit) <= 0? True:False ;            

            }     

            
            if(!accList.isEmpty()){
                for(Account eachAccRecord : accList){
                    
                    accWrapper.accRecord = eachAccRecord;
                    accWrapperList.add(accWrapper);
                }
            }
            return accWrapperList;
        } catch (Exception excep) {
            throw NSP_Utilities.getAuraException(excep);
        }
    }
    /**
* returns the account Id for the object that component is placed on(Case,Asset,Account) 
* @param accId Id related to object Id.    
* @return String             
*                
*/
    @AuraEnabled(cacheable=true)
    public static String getAccountId(String accId) {
        Id objectId = accId;
        Id accountId;
        SObjectType objectName = objectId.getSObjectType();
        if(String.valueOf(objectName) == 'Account'){
            accountId = accId;
        }else if(String.valueOf(objectName) == 'Asset'){
            Asset a = [SELECT Id,AccountId FROM Asset WHERE Id=:accId limit 1];
            accountId = a.AccountId;
        }else if(String.valueOf(objectName) == 'Case'){
            Case c = [SELECT Id,AccountId FROM Case WHERE Id=:accId limit 1];
            accountId = c.AccountId;
        }
        return accountId;
    }
    /**
* returns the account details wrapper for 
* @param    
* @return void             
*                
*/     
    public class VisualIndicatorWrapper{
        @AuraEnabled
        public Account accRecord {get;set;}
        @AuraEnabled
        public Boolean serviceExceptionPresent {get;set;}
        @AuraEnabled
        public Boolean assetPaperlessPresent {get;set;}
        @AuraEnabled
        public Boolean workSyncClientTrue {get;set;}  
        @AuraEnabled
        public Boolean client100True {get;set;} 
        @AuraEnabled
        public Boolean clientAndInsperity {get;set;}  
        @AuraEnabled
        public Boolean pendingTermination {get;set;}
        @AuraEnabled
        public Boolean vocSurveyIndicator {get;set;}          
    }    
}