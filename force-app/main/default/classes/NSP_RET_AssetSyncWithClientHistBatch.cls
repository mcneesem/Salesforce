/**************************************************************************************************************************
* @description  :  Batch Class to Syn RET Asset status based on Client subplanchange history
* @date 11/25/2022
* Author : Ramya Ravi
* Name : NSP_RET_AssetSyncWithClientHistBatch
* Story : STY-03794 - RET Automation Retirement Services Asset Status Field Updates
* Version : V1
**************************************************************************************************************************/
public without sharing class NSP_RET_AssetSyncWithClientHistBatch implements Schedulable,Database.Batchable<SObject>{
    
    private static final String STATUS_ACTIVE = 'Active';
	private static final String STATUS_BACKOUT = 'Backout';
    private static final String OBJECT_ASSET = 'Asset';
    
    //start method to query all RET Asset records (RET choice/ RET WO) with status as Onboarding
    public Database.QueryLocator start(Database.BatchableContext bc){        
        // Get RET choice and RET WO asset record type IDs 
        Id RETCHOICEASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId(OBJECT_ASSET, 'RET_Choice');
        Id RETWOASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId(OBJECT_ASSET, 'RET_WO');
        // Query to get RET Asset records with status as onboarding
        return Database.getQueryLocator ([SELECT ID, Opportunity__c, AccountId FROM Asset
                                WHERE (RecordTypeId =: RETCHOICEASSETRECORDTYPE OR RecordTypeId =: RETWOASSETRECORDTYPE )
                                AND Status IN ( 'Onboarding','Terminated') ]);
    }
    
    //Execute method to populate plan subplan values from asset to project records
    public void execute(Database.BatchableContext bc, List<Asset> assetList){
        try{ 
            //Variable declarations
            Set<ID> assetIDS = new Set<ID>();
            Set<ID> opportunityIDS = new Set<ID>();
            List<Asset> assetListToUpdate = new List<Asset>();
            Map<ID,ID> mapAssetOpptyID = new Map<ID,ID>();
            Map<ID,Date> opptyToProjDateMap = new Map<ID,Date>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> accountsWithActiveWO = new Set<Id>();
            Map<Id,NSP_Client_Sub_Plan_History__c> assetToSubplanHistMap = new Map<Id,NSP_Client_Sub_Plan_History__c>();
            
            //Get list of asset IDs and oppty IDs, Map of <AssetID,OpptID>
            if(assetList != null){
                for(Asset asst: assetList){
                    if(asst != null){
                        assetIDS.add(asst.ID);
                        if(asst.Opportunity__c!=null){
                            opportunityIDS.add(asst.Opportunity__c);
                            mapAssetOpptyID.put(asst.ID,asst.Opportunity__c);
                            
                        }
                        if(asst.AccountId != null){
                            accountIDs.add(asst.AccountId);
                        }
                    }
                }
            }
            // Check if Account has Active WO Asset
            accountsWithActiveWO = getAccountsWithActiveWO( accountIDs );
            
            // Check if project status is Cancelled / Closed/Lost for project records linked to these opptys
            opptyToProjDateMap = getOpptyToProjDateMap( opportunityIDS );
            
            //Latest Client Sub Plan History per Asset
            assetToSubplanHistMap = getAssetToSubplanHistMap( assetIDS );
            
            // get Backout Asset List       
            assetListToUpdate = getBackoutAssetList( mapAssetOpptyID , opptyToProjDateMap );
            
            // get Active Asset list
            assetListToUpdate.addAll( getActiveAssetList( assetList , assetListToUpdate, assetToSubplanHistMap , accountsWithActiveWO ));
            
            //Update the Asset record List - DML Update
            if(!assetListToUpdate.isEmpty()){
                List<Database.SaveResult> results = Database.update( assetListToUpdate , false );
                NSP_ErrorLogHandler.logResults(NSP_RET_AssetSyncWithClientHistBatch.class.getName() , 'Execute' , results);
            }                                              
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException(NSP_RET_AssetSyncWithClientHistBatch.class.getName(), 'Execute', ex.getMessage());
        }        
    }
    
    //finish method
    public void finish(Database.BatchableContext bc){
        
    }
    
    // Schedulable execute method to fire the batch class
    public void execute(SchedulableContext scon){
        //To fire the Batchclass
        Database.executeBatch(new NSP_RET_AssetSyncWithClientHistBatch(),200);
    }
    
    // Method to get BackoutAssetList 
    private static List<Asset> getBackoutAssetList( Map<ID,ID> mapAssetOpptyID , Map<ID,Date> opptyToProjDateMap ){
        List<Asset> backoutAssetList = new List<Asset>();
        if(mapAssetOpptyID != null && mapAssetOpptyID.keySet() != null){
            for(ID assetID: mapAssetOpptyID.keySet()){
                Id opptyID =  mapAssetOpptyID.get(assetID); 
                Date termdate = null;
                if(opptyToProjDateMap != null && opptyToProjDateMap.containsKey(opptyID)){
                    termdate = opptyToProjDateMap.get(opptyID);
                }
                if(opptyToProjDateMap.containsKey(opptyID)){         
                    backoutAssetList.add(setAssetFields(assetID, STATUS_BACKOUT ,termdate)); 
                }                                            
            }
        }
        return backoutAssetList;
    }
    
    // Method to get Active Asset list
    private static List<Asset> getActiveAssetList( List<Asset> assetList , List<Asset> backoutAssetList, 
                                                  Map<Id,NSP_Client_Sub_Plan_History__c> assetToSubplanHistMap ,
                                                  Set<Id> accountsWithActiveWO ){
                                                      Date today = Date.today();
                                                      List<Asset> activeAssetList = new List<Asset>();
                                                      if(assetList != null && assetToSubplanHistMap != null){
                                                          for(Asset eachAsset : assetList){
                                                              NSP_Client_Sub_Plan_History__c subplanHist = null;
                                                              if(eachAsset != null && eachAsset.Id != null && assetToSubplanHistMap.containsKey(eachAsset.Id) && !backoutAssetList.contains(eachAsset)){
                                                                  subplanHist = assetToSubplanHistMap.get(eachAsset.Id);
                                                              }
                                                              // Check if start date is today or before today and enddate is null or future and update Asset status to 'Active'
                                                              if( subplanHist != null && subplanHist.NSP_Start_Date__c <= today
                                                                 && ( subplanHist.NSP_End_Date__c == null || subplanHist.NSP_End_Date__c > today )
                                                                     && subplanHist.NSP_Current_Subplan__c 
                                                                ){                                                                        
                                                                    activeAssetList.add(setAssetFields(subplanHist.NSP_Asset__c, STATUS_ACTIVE , null));                                                                         
                                                                }
                                                              
                                                              // Check if start date is before today and future end date and Account has Active WO Asset 
                                                              if( subplanHist != null && ( subplanHist.NSP_Start_Date__c < today && subplanHist.NSP_End_Date__c > today 
                                                                   && subplanHist.NSP_Current_Subplan__c 
                                                                   && accountsWithActiveWO != null 
                                                                   && accountsWithActiveWO.contains(subplanHist.NSP_Asset__r.AccountId))){
                                                                       activeAssetList.add(setAssetFields(subplanHist.NSP_Asset__c, STATUS_ACTIVE , null));  
                                                                   }
                                                          }
                                                      }
                                                      return activeAssetList;
                                                  }
    
    //Method to Check if Account has Active WO Asset
    private static Set<Id> getAccountsWithActiveWO( Set<Id> accountIDs ){
        Set<Id> accountsWithActiveWO = new Set<Id>();
        Id WOASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId(OBJECT_ASSET, 'WO');
        if(accountIDs != null){
            for(Asset ast : [SELECT ID, AccountId FROM Asset WHERE AccountId IN : accountIDs AND
                             RecordTypeId = : WOASSETRECORDTYPE AND
                             Status = :STATUS_ACTIVE]){
                                 if(ast != null && ast.AccountId != null){
                                     accountsWithActiveWO.add(ast.AccountId);
                                 }
                             }
        }
        return accountsWithActiveWO;
    }
    
    // Method to check if project status is Cancelled / Closed/Lost for project records linked to these opptys
    private static Map<Id,Date> getOpptyToProjDateMap( Set<Id> opportunityIDS ){
        Map<ID,Date> opptyToProjDateMap = new Map<ID,Date>();
        if(opportunityIDS != null){
            for(pse__Proj__c proj: [Select ID , pse__Opportunity__c, Project_Cancelled_Date__c FROM pse__Proj__c WHERE pse__Opportunity__c IN : opportunityIDS AND 
                                    (pse__Project_Status__c =: NSP_ServiceConstants.PROJECTSTATUSCANCELLED OR                                   
                                     pse__Project_Status__c = :NSP_ServiceConstants.PROJECTSTATUSCLOSED  )]){   
                                         if(proj != null && proj.pse__Opportunity__c != null){
                                             opptyToProjDateMap.put(proj.pse__Opportunity__c, proj.Project_Cancelled_Date__c);
                                         }
                                     }
        }
        return opptyToProjDateMap;
    }
    
    //Method to get latest Client Sub Plan History per Asset
    private static Map<Id,NSP_Client_Sub_Plan_History__c> getAssetToSubplanHistMap( Set<Id> assetIDS ){
        Map<Id,NSP_Client_Sub_Plan_History__c> assetToSubplanHistMap = new Map<Id,NSP_Client_Sub_Plan_History__c>();
        if(assetIDS != null){
            for(NSP_Client_Sub_Plan_History__c subplanHist : [Select ID, NSP_Asset__c, NSP_Start_Date__c, Createddate, NSP_End_Date__c,
                                                              NSP_Current_Subplan__c, NSP_Asset__r.AccountId FROM NSP_Client_Sub_Plan_History__c WHERE 
                                                              NSP_Asset__c in : assetIDS AND NSP_Current_Subplan__c = TRUE Order By Createddate DESC]){
                                                                  //Consider only the latest if there are more than one NSP_Client_Sub_Plan_History__c
                                                                  if (subplanHist != null && subplanHist.NSP_Asset__c != null && !assetToSubplanHistMap.containsKey(subplanHist.NSP_Asset__c)){
                                                                      assetToSubplanHistMap.put(subplanHist.NSP_Asset__c,subplanHist);
                                                                  }
                                                              }
        }
        return assetToSubplanHistMap;
    }
    
    // Method to set status for Asset records
    private static Asset setAssetFields(ID assetID, String assetStatus, Date terminationDate ){
        Asset assetUpdate = new Asset();
        assetUpdate.ID = assetID;
        assetUpdate.Status = assetStatus;
        if(assetStatus == STATUS_ACTIVE && assetUpdate.NSP_Termination_Date__c != null){
            assetUpdate.NSP_Termination_Date__c = null;
        }
        else if(terminationDate != null ){
            assetUpdate.NSP_Termination_Date__c = terminationDate;
        }
        return assetUpdate;
    }
    
    public static void schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        System.schedule(
            'NSP_RET_AssetSyncWithClientHistBatch ~ Update Asset ~ everyday at 12 AM' + suffix ,
            '0 0 0 * * ?', // this is for Every Day at 12:00 AM...
            new NSP_RET_AssetSyncWithClientHistBatch()
        );
    }
}