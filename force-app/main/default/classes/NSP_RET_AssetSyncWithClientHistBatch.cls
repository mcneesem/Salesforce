/**************************************************************************************************************************
* @description  :  Batch Class to Syn RET Asset status based on Client subplanchange history
* @date 11/25/2022
* Author : Ramya Ravi
* Name : NSP_RET_AssetSyncWithClientHistBatch
* Story : STY-03794 - RET Automation Retirement Services Asset Status Field Updates
* Version : V1
**************************************************************************************************************************/
public class NSP_RET_AssetSyncWithClientHistBatch implements Schedulable,Database.Batchable<SObject>{

    //start method to query all RET Asset records (RET choice/ RET WO) with status as Onboarding
   public Database.QueryLocator start(Database.BatchableContext bc){        
       // Get RET choice and RET WO asset record type IDs 
       Id RETCHOICEASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_Choice');
       Id RETWOASSETRECORDTYPE = NSP_GenericRecordType.getRecordTypeId('Asset', 'RET_WO');
       // Query to get RET Asset records with status as onboarding
       String query = 'Select ID, Opportunity__c FROM Asset ';
       query+= 'WHERE (RecordTypeId =: RETCHOICEASSETRECORDTYPE OR RecordTypeId =: RETWOASSETRECORDTYPE ) ' ;        
       query+= 'AND Status = ' +'\''+ NSP_ServiceConstants.ASSET_ONBOARDING_STATUS  +'\''+ '';        
       return Database.getQueryLocator(query);
   }
   
   //Execute method to populate plan subplan values from asset to project records
   public void execute(Database.BatchableContext bc, List<Asset> assetList){
        try{ 
            //Variable declarations
            List<ID> assetIDS = new List<ID>();
            Set<ID> opportunityIDS = new Set<ID>();
            List<Asset> assetLstActiveUpdate = new List<Asset>();
            Map<ID,ID> mapAssetOpptyID = new Map<ID,ID>();
            List<ID> opptyToUpdate = new List<ID>();
            List<ID> assetNotToCheck = new List<Id>();
            
            //Get list of asset IDs and oppty IDs, Map of <AssetID,OpptID>
            for(Asset asst: assetList){
                assetIDS.add(asst.ID);
                if(asst.Opportunity__c!=null){
                    opportunityIDS.add(asst.Opportunity__c);
                    mapAssetOpptyID.put(asst.ID,asst.Opportunity__c);
                }
            }                     
            // Check if project status is Cancelled / Lost / Closed for project records linked to these opptys
            for(pse__Proj__c proj: [Select ID , pse__Opportunity__c FROM pse__Proj__c WHERE pse__Opportunity__c IN : opportunityIDS AND 
                                   (pse__Project_Status__c =: NSP_ServiceConstants.PROJECTSTATUSCANCELLED OR                                   
                                    pse__Project_Status__c = :NSP_ServiceConstants.PROJECTSTATUSCLOSED  )]){                              
                                     opptyToUpdate.add(proj.pse__Opportunity__c)  ;
                                   }

            //check if NSP_Client_Sub_Plan_History__c record exists with start date as TODAY or greater than TODAY for these assets
            for(NSP_Client_Sub_Plan_History__c subplanHist : [Select ID, NSP_Asset__c,NSP_Start_Date__c FROM NSP_Client_Sub_Plan_History__c WHERE 
                                                              NSP_Asset__c in : assetIDS]){  
                                                                  assetNotToCheck.add(subplanHist.NSP_Asset__c);
                                                                  // Check if start date is today and update Asset status to 'Active'
                                                                  if(subplanHist.NSP_Start_Date__c == system.today()){                                                                        
                                                                      assetLstActiveUpdate.add(setAssetStatus(subplanHist.NSP_Asset__c, NSP_ServiceConstants.ASSET_ACTIVE_STATUS));                                                                         
                                                                  }
                                                                  //Check if start date is greater than today and related project is closed/cancelled/lost ( via opportunity) and update Asset status to 'Terminated'
                                                                  if(subplanHist.NSP_Start_Date__c > system.today() && mapAssetOpptyID.containsKey(subplanHist.NSP_Asset__c)){                                                                        
                                                                      Id opptyID =  mapAssetOpptyID.get(subplanHist.NSP_Asset__c)  ;
                                                                      if(opptyToUpdate.contains(opptyID)){                                                                                                                                                     
                                                                          assetLstActiveUpdate.add(setAssetStatus(subplanHist.NSP_Asset__c, NSP_ServiceConstants.TERMINATED)); 
                                                                      }                                                                         
                                                                  }                                                                     
                                                              }
            
            // To check if there is  no subplan history record linked to the Asset and project status -Lost/ Closed/ Cancelled
            for(ID assetID: mapAssetOpptyID.keySet()){
                if(!assetNotToCheck.contains(assetID)){
                    Id opptyID =  mapAssetOpptyID.get(assetID); 
                    if(opptyToUpdate.contains(opptyID)){                      
                        assetLstActiveUpdate.add(setAssetStatus(assetID, NSP_ServiceConstants.TERMINATED)); 
                    }
                }                                               
            }
            
            //Update the Asset record List - DML Update
            if(!assetLstActiveUpdate.isEmpty()){
                Database.update(assetLstActiveUpdate,false);
            }                                              
        }catch(Exception ex){
           NSP_ErrorLogHandler.logSaveException('NSP_RET_AssetSyncWithClientHistBatch', 'Execute', ex.getMessage());
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
   
   // Method to set status for Asset records
   public static Asset setAssetStatus(ID assetID, String assetStatus ){
       Asset assetUpdate = new Asset();
       assetUpdate.ID =assetID;
       assetUpdate.Status = assetStatus;
       return assetUpdate;
   }
}