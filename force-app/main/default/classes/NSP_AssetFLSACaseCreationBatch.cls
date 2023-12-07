/**
Apex Class Name      :  NSP_AssetFLSACaseCreationBatch
Version              :  1.0                                                                          
Created Date         :  12/13/2022  
Function             :  Represents batch class for NSP_AssetBatchClass 
Story                :  STY-02080                                                               
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                Description                                    
* -------------------------------------------------------------------------------------------------  
* Srushti Bikkannavar        12/13/2022           First Iteration
*/

// test w/ NSP_AssetFLSACaseCreationBatchTest (90%)

public class NSP_AssetFLSACaseCreationBatch implements Schedulable,Database.Stateful, Database.Batchable < sObject >{
         Integer segmentDays;
         Integer btCoreEgMinDays;
         Integer btCoreEgMaxDays;
         Integer egMmMinDays;
         Integer egMmMaxDays;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        try{
            //Get segment days range info    
            if(String.isNotBlank(System.Label.Segment_Days)){
                segmentDays = Integer.valueOf(System.Label.Segment_Days);
            }        
            
            if(String.isNotBlank(System.Label.BTCoreEgMinMaxRange)){
                btCoreEgMinDays = Integer.valueOf(System.Label.BTCoreEgMinMaxRange.split(';')[0]);
                btCoreEgMaxDays = Integer.valueOf(System.Label.BTCoreEgMinMaxRange.split(';')[1]);
            }
            if(String.isNotBlank(System.Label.EGMMMinMaxRange)){
                egMmMinDays = Integer.valueOf(System.Label.EGMMMinMaxRange.split(';')[0]);
                egMmMaxDays = Integer.valueOf(System.Label.EGMMMinMaxRange.split(';')[1]);
            }  

            //Get WO Asset Record Type Id
            Id WOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset', 'WO');
            String ageDays;
            if(segmentDays!=NULL){
                ageDays = (System.today().addDays(segmentDays)+'').split(' ')[0];
            }
            //Asset fields to query
            List<String> assetFields = new List<String>{
                'NSP_Client_Segment_type__c',
                'NSP_Unique_Active_Employee__c',
                'RecordTypeId',
                'AccountId'
            };
            //Asset client segments
            List<String> clientSegmentTypes = new List<String>{
                NSP_ServiceConstants.BTAssetSegment,
                NSP_ServiceConstants.CoreAssetSegment,
                NSP_ServiceConstants.EG100AssetSegment,
                NSP_ServiceConstants.EG50AssetSegment,
                NSP_ServiceConstants.MMAssetSegment,
                NSP_ServiceConstants.MMEAssetSegment
            };
            //Query to get all the assets of WO RT and where segment in clientSegmentTypes
            NSP_QueryBuilder queryBuilder = new NSP_QueryBuilder(NSP_ServiceConstants.ASSET_SOBJECT_TYPE, assetFields)
                                                .addFilter('RecordTypeId', WOAssetRecordTypeId)
                                                .addFilter('NSP_Client_Segment_type__c', clientSegmentTypes, NSP_QueryBuilder.Operator.INCLUDES)
                                                .addFilter('NSP_Account_Status__c', 'Terminated', NSP_QueryBuilder.Operator.NOT_EQUALS, true)
                                                .addFilter('NSP_AIMS_First_Pay_Date__c', ageDays, NSP_QueryBuilder.Operator.GREATER_THAN_OR_EQUALS, false)
                                                .setSecurityEnforce(false);
            String query = queryBuilder.build();
            return Database.getQueryLocator(query);

        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AssetFLSACaseCreationBatch', 'start', ex.getMessage());
            return null;
        }
    }
    
    public void execute(Database.BatchableContext BC, List<Asset> assetList){

        List<String> segmentList = new List<String>{
            NSP_ServiceConstants.BTAssetSegment,
            NSP_ServiceConstants.CoreAssetSegment
        };
	
        List<String> segmentListEmpGrtFifty = new List<String>{
            NSP_ServiceConstants.EG50AssetSegment,
            NSP_ServiceConstants.EG100AssetSegment
        };

        Case flsaCase;
        List<Case> flsaCaseList = new List<Case>();
        List<NSP_Sub_Client__c> subClientList = new List<NSP_Sub_Client__c>();
        //Query all the subclient related to the asset   
        try{     
            for(NSP_Sub_Client__c subClientRecord: [SELECT Id, NSP_Asset__r.NSP_AIMS_First_Pay_Date__c, 
                                                    NSP_Asset__r.NSP_Client_Segment_type__c,
                                                    NSP_Asset__r.NSP_Unique_Active_Employee__c,
                                                    NSP_Case_created_from_FLSA_Batch__c,
                                                    NSP_Account__r.NSP_AIMS_Client__c,
                                                    NSP_Sub_Client__c
                                                    FROM NSP_Sub_Client__c 
                                                    WHERE NSP_Asset__c IN: assetList AND 
                                                    NSP_Case_created_from_FLSA_Batch__c = false]){
                                                        
                                                        if(btCoreEgMinDays!=NULL && btCoreEgMaxDays!=NULL && subClientRecord.NSP_Asset__r.NSP_AIMS_First_Pay_Date__c < System.today().addDays(btCoreEgMinDays) && 
                                                           subClientRecord.NSP_Asset__r.NSP_AIMS_First_Pay_Date__c >= System.today().addDays(btCoreEgMaxDays)){
                                                               //Condition for BT and Core Segment Type
                                                               if(segmentList.contains(subClientRecord.NSP_Asset__r.NSP_Client_Segment_type__c)){
                                                                   flsaCase = createCase(subClientRecord.NSP_Account__c, subClientRecord.NSP_Sub_Client__c, NSP_ServiceConstants.SUBCATEGORY_NOT_ON_UI , System.Label.NSP_FLSA_QueueId);
                                                                   flsaCaseList.add(flsaCase);
                                                                   subClientRecord.NSP_Case_created_from_FLSA_Batch__c = True;
                                                                   subClientList.add(subClientRecord);
                                                               }
                                                               //Condition for EG Segment Types
                                                               else if(segmentListEmpGrtFifty.contains(subClientRecord.NSP_Asset__r.NSP_Client_Segment_type__c) && 
                                                                       subClientRecord.NSP_Asset__r.NSP_Unique_Active_Employee__c < 50){
                                                                           flsaCase = createCase(subClientRecord.NSP_Account__c, subClientRecord.NSP_Sub_Client__c, NSP_ServiceConstants.SUBCATEGORY_NOT_ON_UI , System.Label.NSP_FLSA_QueueId);
                                                                           flsaCaseList.add(flsaCase);
                                                                           subClientRecord.NSP_Case_created_from_FLSA_Batch__c = True;
                                                                           subClientList.add(subClientRecord);   
                                                               }
                                                        }
 
                                                        else if(egMmMinDays!=NULL && egMmMaxDays!=NULL && subClientRecord.NSP_Asset__r.NSP_AIMS_First_Pay_Date__c < System.today().addDays(egMmMinDays) && 
                                                                subClientRecord.NSP_Asset__r.NSP_AIMS_First_Pay_Date__c >= System.today().addDays(egMmMaxDays)){
                                                                    //Condition for EG Segment Types
                                                                    if(segmentListEmpGrtFifty.contains(subClientRecord.NSP_Asset__r.NSP_Client_Segment_type__c) &&
                                                                       subClientRecord.NSP_Asset__r.NSP_Unique_Active_Employee__c >= 50){
                                                                           Id flsaOwner = getFLSASpecialist(subClientRecord);
                                                                           flsaCase = createCase(subClientRecord.NSP_Account__c, subClientRecord.NSP_Sub_Client__c, NSP_ServiceConstants.FLSA_SUBCATEGORY , flsaOwner);
                                                                           flsaCaseList.add(flsaCase);
                                                                           subClientRecord.NSP_Case_created_from_FLSA_Batch__c = True;
                                                                           subClientList.add(subClientRecord);
                                                                    }
                                                                    //For MM Segment Type Asset
                                                                    else if(subClientRecord.NSP_Asset__r.NSP_Client_Segment_type__c == NSP_ServiceConstants.MMAssetSegment){
                                                                            Id flsaOwner = getFLSASpecialist(subClientRecord);
                                                                            flsaCase = createCase(subClientRecord.NSP_Account__c, subClientRecord.NSP_Sub_Client__c, NSP_ServiceConstants.FLSA_SUBCATEGORY , flsaOwner);
                                                                            flsaCaseList.add(flsaCase);
                                                                            subClientRecord.NSP_Case_created_from_FLSA_Batch__c = True;
                                                                            subClientList.add(subClientRecord);
                                                                    }
                                                                    //For MME Segment Type Asset
                                                                    else if(subClientRecord.NSP_Asset__r.NSP_Client_Segment_type__c == NSP_ServiceConstants.MMEAssetSegment){
                                                                            flsaCase = createCase(subClientRecord.NSP_Account__c, subClientRecord.NSP_Sub_Client__c, NSP_ServiceConstants.FLSA_SUBCATEGORY , System.Label.NSP_Marsha_Bustos);
                                                                            flsaCaseList.add(flsaCase);
                                                                            subClientRecord.NSP_Case_created_from_FLSA_Batch__c = True;
                                                                            subClientList.add(subClientRecord);
                                                                    }	
                                                        }
                                                    }
            if(!flsaCaseList.isEmpty()){
                List<Database.SaveResult> results = Database.insert(flsaCaseList,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AssetFLSACaseCreationBatch', 'ExecuteMethod', results );
            }
            if(!subClientList.isEmpty()){
                List<Database.SaveResult> results = Database.update(subClientList,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_AssetFLSACaseCreationBatch', 'ExecuteMethod', results );
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AssetFLSACaseCreationBatch', 'execute', ex.getMessage());
        }
    }
    
    /***********************************************************************************************
    * MethodName: createCase
    * Description : Helper mehtod which will create a case per sub client record
    * Params: NSP_Sub_Client__c rec, String subject, String subCat, Id owner
    * ********************************************************************************************/ 
    
    private Case createCase(Id accId, String subject, String subCat, Id owner){
        Id peoCaseRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Case', 'PEO');
        Case newCaseRec = new Case();
        newCaseRec.RecordTypeId = peoCaseRecordTypeId;
        newCaseRec.AccountId = accId;
        newCaseRec.NSP_Category__c = NSP_ServiceConstants.FLSA_CATEGORY;
        newCaseRec.NSP_SubCategory__c = subCat;
        newCaseRec.Subject = subject;
        newCaseRec.NSP_FLSA_Case__c = True;
        newCaseRec.Origin = NSP_ServiceConstants.CANCELLED_REASON;
        newCaseRec.Status = NSP_ServiceConstants.OPEN;   	
        newCaseRec.NSP_Opened_Date__c = System.today();
        newCaseRec.OwnerId = owner;
        return newCaseRec;
    }
    
    /***********************************************************************************************
    * MethodName : getFLSASpecialist
    * Description : Helper mehtod which will return FLSA Specialist based on the sales office 
    * 				of the account linked to sub client record
    * Params : NSP_Sub_Client__c subClientList
    * Return : Id flsaSpecialist
    * ********************************************************************************************/ 
    
   private Id getFLSASpecialist(NSP_Sub_Client__c subClientList){
       Id flsaSpecialist;
       List<String> midMarketsalesOffices = new List<String>{'4499', '4491', '4492', '4493', '4466'};
           
       //Get all the bpa mapping records
       List<String> bpaMappingList = new List<String>{
               'Id', 
               'NSP_Sales_Office__c', 
               'NSP_FLSA_Specialist__c', 
               'NSP_BPA__c'};
       NSP_QueryBuilder bpaQueryBuilder = new NSP_QueryBuilder('NSP_BPA_Mapping__c', bpaMappingList)
            								.setSecurityEnforce(false);
       String bpaMappingQuery = bpaQueryBuilder.build();
       List<NSP_BPA_Mapping__c> flsaList = (List<NSP_BPA_Mapping__c>) Database.query(bpaMappingQuery);
       
       List<String> subClientFields = new List<String>{
           	   'Id', 
               'NSP_Account__c', 
               'NSP_Account__r.NSP_AIMS_Client__c', 
               'NSP_Account__r.NSP_Sales_Office__c',  
               'NSP_Account__r.ParentId',
               'NSP_Account__r.Parent.NSP_Sales_Office__c'
       };
       NSP_QueryBuilder subClientQueryBuilder = new NSP_QueryBuilder('NSP_Sub_Client__c', subClientFields)
            								.setSecurityEnforce(false)
           									.addFilter('Id', subClientList.Id);
       String subClientQuery = subClientQueryBuilder.build();
       NSP_Sub_Client__c subClientRecord = Database.query(subClientQuery);
       
       //get account team record where role is BPA
       List<String> accountTeamFields = new List<String>{
           'Id',
           'NSP_Account__c',
           'NSP_User__c',
           'NSP_Role__c'
       };
       NSP_QueryBuilder bpaAccTeamQueryBuilder = new NSP_QueryBuilder('NSP_Account_Team__c', accountTeamFields)
            								.setSecurityEnforce(false)
           									.addFilter('NSP_Account__c', subClientRecord.NSP_Account__c)
           									.addFilter('NSP_Role__c',  NSP_ServiceConstants.BUSINESS_PERFORMANCE_ADVISOR)
           									.addLimit(1);
       String bpaQuery = bpaAccTeamQueryBuilder.build();
       List<NSP_Account_Team__c> bpaAccountTeamList = (List<NSP_Account_Team__c>) Database.query(bpaQuery);
      
       //get account team record where role is BPC
       NSP_QueryBuilder bpcAccTeamQueryBuilder = new NSP_QueryBuilder('NSP_Account_Team__c', accountTeamFields)
            								.setSecurityEnforce(false)
           									.addFilter('NSP_Account__c', subClientRecord.NSP_Account__c)
           									.addFilter('NSP_Role__c',  NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT)
           									.addLimit(1);
       String bpcQuery = bpcAccTeamQueryBuilder.build();
       List<NSP_Account_Team__c> bpcAccountTeamList = (List<NSP_Account_Team__c>) Database.query(bpcQuery);
       
       //Get the sales office of the account linked to subclient record
       //If the acc is sub acc go to it's parent acc and fetch the sales office
       String salesOfficeOnAccount;
       salesOfficeOnAccount = subClientRecord.NSP_Account__r.ParentId == NULL ? 
           subClientRecord.NSP_Account__r.NSP_Sales_Office__c : subClientRecord.NSP_Account__r.Parent.NSP_Sales_Office__c;
       
       if(!flsaList.isEmpty()){
           Boolean isBPCFound = false;
           Boolean isflsaSpecialistAssigned =false;
           for(NSP_BPA_Mapping__c flsaMapping: flsaList){
               //if salesoffice doesn't contain 'Mid Market' OR contains 'Mid Market'
               if(salesOfficeOnAccount != NULL && 
                  ((!midMarketsalesOffices.contains(salesOfficeOnAccount) && flsaMapping.NSP_Sales_Office__c == salesOfficeOnAccount) ||                  
                  (midMarketsalesOffices.contains(salesOfficeOnAccount) &&
                   ((!bpcAccountTeamList.isEmpty() && flsaMapping.NSP_BPA__c == bpcAccountTeamList[0].NSP_User__c) ||
                    (!bpaAccountTeamList.isEmpty() && flsaMapping.NSP_BPA__c == bpaAccountTeamList[0].NSP_User__c && !isBPCFound) ||
                    (!bpcAccountTeamList.isEmpty() && !bpaAccountTeamList.isEmpty() &&
                     flsaMapping.NSP_BPA__c == bpcAccountTeamList[0].NSP_User__c && !isBPCFound))))){
                         
                         if(!bpcAccountTeamList.isEmpty() && NSP_ServiceConstants.BUSINESS_PERFORMANCE_CONSULTANT == bpcAccountTeamList[0].NSP_Role__c ){
                            isBPCFound = true;                         	
                         }
						 flsaSpecialist = flsaMapping.NSP_FLSA_Specialist__c;
                         isflsaSpecialistAssigned = true;
                     }
               
               //Assign flsaSpecialist as Marsha Bustos salesoffice is not there or
               //salesoffice contain 'Mid Market' and BPA/BPC is not part of FLSA Admin Table then Assign flsaSpecialist as Marsha Bustos
               else if(salesOfficeOnAccount == NULL || 
                       (!isflsaSpecialistAssigned && midMarketsalesOffices.contains(salesOfficeOnAccount) && 
                       ((!bpaAccountTeamList.isEmpty() && flsaMapping.NSP_BPA__c != bpaAccountTeamList[0].NSP_User__c) || 
                        (!bpcAccountTeamList.isEmpty() && flsaMapping.NSP_BPA__c != bpcAccountTeamList[0].NSP_User__c)))){
                            flsaSpecialist = System.Label.NSP_Marsha_Bustos;
                        }
           }
       }
       return flsaSpecialist;
   }
    
    public void finish(Database.BatchableContext bc) {
        
    }
    
    public void execute(SchedulableContext scon) {
        //Executes Batch
        Database.executeBatch(new NSP_AssetFLSACaseCreationBatch(),200);
    }
}