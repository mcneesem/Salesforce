/**
Apex Class Name      :  NSP_AssetCreationBpsProjectBatch
Version              :  1.0 
Author               :  Simran
Function             :  Creates Asset Record.
Story                :  As part of STY-03262                                                                    

*/
public class NSP_AssetCreationBpsProjectBatch implements Schedulable,Database.Batchable<sObject> {

    private static final String PROJ_ACCOUNT_OBJECT_API_NAME = 'Project_Account__c';
    private static final List<Asset> lstAssetToInsert = new List<Asset>();
    private static final List<Project_Asset__c> lstProjAssetToInsert = new List<Project_Asset__c>();
    private static final Map<String,String> mapOfProjTempServiceAsset = new Map<String,String>();
    private static final Map<String, String> mapOfAcctIdRecordType = new Map<String, String>();
    private static final Map<Id,Project_Account__c> accIdWithProject = new Map<Id,Project_Account__c>();
    private static final Map<Id,Set<String>> mapAcctIdwithProjTemp = new Map<Id,Set<String>>();
  	private static final Map<Id,Set<String>> mapAcctIdwithAssetRecType = new Map<Id,Set<String>>();
    private static final Id TES_BPS_RECTYPE_ID = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', 'TES_BPS');
    private static final List<String> PR0J_ACNT_FIELDS = new List<String>{
        	'Id', 
            'Account__c','Account__r.Name','Account__r.NSP_AIMS_Client__c', 'Project__c', 
            'Project__r.TemplateName__c','Project__r.recordTypeId',
            'Account__r.NSP_Sales_Service_Account_Status__c'
            };
    List<String> templateNames = new List<String>{
        NSP_ServiceConstants.ITA_IMPLEMENTATION,
        NSP_ServiceConstants.PERFORMSMART_IMPLEMENTATION,
        NSP_ServiceConstants.INTEGRA_IMPLEMENTATION,
        NSP_ServiceConstants.XML_IMPLEMENTATION
    };
    //starting the batch
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = new NSP_QueryBuilder(PROJ_ACCOUNT_OBJECT_API_NAME, PR0J_ACNT_FIELDS)
        .addFilter('Project__r.recordTypeId', TES_BPS_RECTYPE_ID)
        .addFilter('Account__r.NSP_Sales_Service_Account_Status__c', NSP_ServiceConstants.Account_Status)
        .addFilter('Project__r.TemplateName__c', templateNames, NSP_QueryBuilder.Operator.INCLUDES)
        .build();
        return Database.getQueryLocator(query);
                            
     }
    //executing the batch
    public void execute(Database.BatchableContext bc, List<Project_Account__c> projAccounts){ 
  
        
        //Iterating the loop to get the custom setting values 
        
        List<NSP_Asset_Template_Mapping__mdt> assTempMap = NSP_Asset_Template_Mapping__mdt.getAll().values();
        for(NSP_Asset_Template_Mapping__mdt pT : assTempMap){
            mapOfProjTempServiceAsset.put(pT.NSP_Project_Template__c, pT.NSP_Service_Asset_Record_Type__c);
        }

        for(Project_Account__c prjAcc1 : projAccounts){
            accIdWithProject.put(prjAcc1.Account__c,prjAcc1);
            if(mapAcctIdwithProjTemp.containskey(prjAcc1.Account__c)){
                mapAcctIdwithProjTemp.get(prjAcc1.Account__c).add(mapOfProjTempServiceAsset.get(prjAcc1.Project__r.TemplateName__c));
            } 
            else {
                mapAcctIdwithProjTemp.put(prjAcc1.Account__c, new Set<String>{mapOfProjTempServiceAsset.get(prjAcc1.Project__r.TemplateName__c)});
            }
        }

        for(Asset ast : [SELECT Id, recordType.developerName,accountId 
                        FROM Asset
                        WHERE accountId IN: mapAcctIdwithProjTemp.keySet()] ){
            if(mapAcctIdwithAssetRecType.containskey(ast.accountId)){
                mapAcctIdwithAssetRecType.get(ast.accountId).add(ast.recordType.developerName);
            } 
            else {
                mapAcctIdwithAssetRecType.put(ast.accountId, new Set<String>{ast.recordType.developerName});
            }
        }
        

        try{
            creatingAssetRecords();
        }
        catch (Exception ex){
			 NSP_ErrorLogHandler.logSaveException('NSP_AssetCreationBpsProjectBatch', 'execute', ex.getMessage());            
        }
    }
        
    /*
     * @description insert Asset Records and ProjectAsset into the database
     */
    private void creatingAssetRecords() {
        NSP_AssetTriggerHandler.TriggerDisabled= True;
        for(String accountId: mapAcctIdwithProjTemp.keySet() )   {
            for(String assetRecordType : mapAcctIdwithProjTemp.get(accountId)){
                if(!mapAcctIdwithAssetRecType.containsKey(accountId) || (mapAcctIdwithAssetRecType.containsKey(accountId) && !mapAcctIdwithAssetRecType.get(accountId).isEmpty() &&
                    !mapAcctIdwithAssetRecType.get(accountId).contains(assetRecordType)) || mapAcctIdwithAssetRecType.isEmpty()){
                    Asset newAsset = new Asset();
                    newAsset.Name = accIdWithProject.get(accountId).Account__r.name;
                    newAsset.AccountId = accountId;
                    newAsset.Status = NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
                    newAsset.NSP_Client__c = accIdWithProject.get(accountId).Account__r.NSP_AIMS_Client__c;
                    newAsset.NSP_Signature_Date__c = system.today();
                    newAsset.recordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', assetRecordType);
                    mapOfAcctIdRecordType.put(accountId+'_'+newAsset.recordTypeId,accIdWithProject.get(accountId).Project__c);

                    lstAssetToInsert.add(newAsset);
                }
            }
        }

        if (!lstAssetToInsert.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(lstAssetToInsert, false);
            NSP_ErrorLogHandler.logSaveResult('NSP_AssetCreationBpsProjectBatch', 'creatingAssetRecords', results );
            for(Asset asst : lstAssetToInsert){
                Project_Asset__c newProjAsset = new Project_Asset__c();
                newProjAsset.Asset__c = asst.Id;
                newProjAsset.Project__c = mapOfAcctIdRecordType.get(asst.AccountId+'_'+asst.RecordTypeId);
                lstProjAssetToInsert.add(newProjAsset); 
            }
            Database.insert(lstProjAssetToInsert, false);
            NSP_ErrorLogHandler.logSaveResult('NSP_AssetCreationBpsProjectBatch', 'creatingAssetRecords', results );
        }
    }

    public void finish(Database.BatchableContext bc){
        
    }

    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_AssetCreationBpsProjectBatch(),200);
    }
}