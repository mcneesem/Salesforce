/**
 * Represents the Sub Client trigger helper which handles all the logic.
 * Created by : Hemali Patel
 * Created Date : 6/11/2021
*/

public class NSP_SubClientTriggerHelper {
	
    /**
     * Iterates throught the list of new NSP_Sub_Client__c and passes the required attributes to other methods.
     * @param newList List of New NSP_Sub_Client__c.
     * @return void
     *                
     */
    public void beforeInsertDirector(List<NSP_Sub_Client__c> newList){
        Set<String> aimsClientStr = new Set<String>();
        List<NSP_Sub_Client__c> newSubClientToPopulateAsset = new List<NSP_Sub_Client__c>();
        
        for(NSP_Sub_Client__c subClientObj : newList){
            if(!String.isBlank(subClientObj.NSP_Client__c)){
            	aimsClientStr.add(subClientObj.NSP_Client__c);
                newSubClientToPopulateAsset.add(subClientObj);
            }
        }
    }
    
     Public Void updatePaperlessBatchDateBeforeInsertOrUpdate(List<NSP_Sub_Client__c> NewList , Map<Id, NSP_Sub_Client__c> OldMap){ 
         Set<Id> AssetIds = New Set<Id>();
         for(NSP_Sub_Client__c Sc : NewList){
             If(Sc.NSP_Asset__c != null){
                 AssetIds.Add(Sc.NSP_Asset__c);
             }
         }
         Map<Id , Asset> AssetMap = New Map<Id , Asset>();
         For(Asset Ast : [Select Id, NSP_Account_Status__c FROM Asset WHERE Id =: AssetIds]){
              AssetMap.Put(Ast.Id , Ast);
       }
         
        For(NSP_Sub_Client__c SubClientObj : NewList){
          
            If((SubClientObj.NSP_Account_Status__c != null && OldMap == null && AssetMap.containsKey(SubClientObj.NSP_Asset__c) &&
               AssetMap.get(SubClientObj.NSP_Asset__c).NSP_Account_Status__c == 'Active') ||
                (OldMap != null && OldMap.containskey(SubClientObj.Id) && AssetMap.containsKey(SubClientObj.NSP_Asset__c) &&
               AssetMap.get(SubClientObj.NSP_Asset__c).NSP_Account_Status__c == 'Active' &&
                SubClientObj.NSP_Account_Status__c != OldMap.get(SubClientObj.Id).NSP_Account_Status__c)){                    
                SubClientObj.NSP_Paperless_Batch_Date__c = System.Today();
            }        
        }
    }
        
        /*
        if(aimsClientStr.size() > 0){
            populateAssetIdOnSubClient(newSubClientToPopulateAsset,aimsClientStr);
        } */
            
    	
    
    /**
     * Iterates throught the list of new NSP_Sub_Client__c and passes the required attributes to other methods.
     * @param newList List of New NSP_Sub_Client__c.
     * @param newMap List of New NSP_Sub_Client__c.
     * @return void
     *                
     */
	public void afterInsertDirector(List<NSP_Sub_Client__c> newList, Map<Id, NSP_Sub_Client__c> newMap) {

		Set<Id> assetIdSet = new Set<Id>();
        
        for(NSP_Sub_Client__c subClientObj : newList){
            assetIdSet.add(subClientObj.NSP_Asset__c);
        }
        
        if(assetIdSet.size() > 0){
            populateStatusAndStatusDateOnAsset(assetIdSet);
        }
            
        
        //Set<String> subClientAIMSClientIdSetWithUnionEmployees = new Set<String>();
        // if(subClientObj.NSP_Union_Employees__c)
        //   subClientAIMSClientIdSetWithUnionEmployees.add(subClientObj.NSP_Client__c);
      
        
       /* if(subClientAIMSClientIdSetWithUnionEmployees.size() > 0){
          //  setUnionEmployeesOnAsset(subClientAIMSClientIdSetWithUnionEmployees);
        }*/
            
    }
    
    
     /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *                
     */

    public void afterUpdateDirector(Map<Id, NSP_Sub_Client__c> newMap,Map<Id, NSP_Sub_Client__c> oldMap) {
        
        //Set<String> subClientAIMSClientIdSetWithUnionEmployees = new Set<String>();
        Set<Id> assetId = new Set<Id>();
        Set<Id> subClientIDs = new Set<Id>();
        
        for(NSP_Sub_Client__c subClientObj : newMap.values()){
           // if(subClientObj.NSP_Union_Employees__c && !oldMap.get(subClientObj.Id).NSP_Union_Employees__c)
             //   subClientAIMSClientIdSetWithUnionEmployees.add(subClientObj.NSP_Client__c);
           if(subClientObj.NSP_Account_Status__c != oldMap.get(subClientObj.Id).NSP_Account_Status__c ||
              subClientObj.NSP_Account_Status_Date__c != oldMap.get(subClientObj.Id).NSP_Account_Status_Date__c || 
              subClientObj.NSP_Asset__c != oldMap.get(subClientObj.Id).NSP_Asset__c){
                 assetId.add(subClientObj.NSP_Asset__c); 
              }

            if(subClientObj.NSP_States_of_Operations__c != oldMap.get(subClientObj.Id).NSP_States_of_Operations__c){
                subClientIDs.add(subClientObj.Id);
            }
        }
        
        if(assetId.size() > 0){
            populateStatusAndStatusDateOnAsset(assetId);
        }

        if(subClientIDs.size() > 0){
            updateSooValueOnRelatedPDS(subClientIDs, newMap);
        }
        
        /*if(subClientAIMSClientIdSetWithUnionEmployees.size() > 0){
            setUnionEmployeesOnAsset(subClientAIMSClientIdSetWithUnionEmployees);
        }*/
        
        //for tracking history
        //NSP_SObjectFieldHistoryHelper objectFieldHistoryHelper = new NSP_SObjectFieldHistoryHelper();
        //objectFieldHistoryHelper.fieldHistoryLogData((Map<Id, sObject>)newMap, (Map<Id, sObject>)oldMap);
    }
    
    /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *                
     */

    /*public void setUnionEmployeesOnAsset(Set<String> subClientIdSet) {
        
        List<Asset> assetList = [SELECT Id,NSP_Union_Employees__c from Asset where 
                                 NSP_Client__c IN: subClientIdSet AND 
                                 NSP_Union_Employees__c = false];     
        
        for(Asset oAsset : assetList){
            oAsset.NSP_Union_Employees__c = true;
        }
        
        if(assetList.size() > 0)
        	update assetList;
    }*/
    
    /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *                
     */
    /*public void populateAssetIdOnSubClient(List<NSP_Sub_Client__c> newSubClientList, Set<String> aimsClient){
        Map<String,Id> assetClientMap = new Map<String,Id>();
        List<Asset> assetList = [Select Id from Asset WHERE NSP_Client__c IN: aimsClient];
        
        for(Asset assetObj : assetList){
            assetClientMap.put(assetObj.NSP_Client__c,assetObj.Id);
        }
        
        for(NSP_Sub_Client__c subClientObj : newSubClientList){
            subClientObj.NSP_Asset__c = assetClientMap.get(subClientObj.NSP_Client__c);
        }
        
    }*/
    
    /**
     * Iterates throught the list of new Sub Client and passes the required attributes to other methods.
     * @param newList List of New Sub Client.
     * @param newMap List of New Sub Client.
     * @return void
     *                
     */
    public void populateStatusAndStatusDateOnAsset(Set<Id> assetId){
        
        List<Asset> assetList = [SELECT Id,(Select Id,NSP_Account_Status__c,NSP_Account_Status_Date__c from Sub_Clients__r order by createddate asc limit 1) 
                                     FROM Asset WHERE Id in: assetId];
        
        for(Asset assetObj : assetList){
            assetObj.NSP_Account_Status__c = assetObj.Sub_Clients__r[0].NSP_Account_Status__c;
            assetObj.NSP_Account_Status_Date__c = assetObj.Sub_Clients__r[0].NSP_Account_Status_Date__c;
        }
        
        update assetList;
        
    }

    /**
     * Iterates through the list of Sub Client records and populate the updated State of Opertaions value in the related PDS records.
     * @param Set<Id> List of Sub Client record IDs.
     * @param Map<Id, NSP_Sub_Client__c> Map of new Sub Client records.
     * @return void          
     */
    private void updateSooValueOnRelatedPDS(Set<Id> subClientIDs, Map<Id, NSP_Sub_Client__c> newMap){
        List<NSP_Payroll__c> payrolls = [SELECT Id, NSP_States_of_Operation__c, NSP_Sub_Client_Name__c FROM NSP_Payroll__c WHERE NSP_Sub_Client_Name__c IN :subClientIDs];

        for(NSP_Payroll__c payrollRec : payrolls){
			payrollRec.NSP_States_of_Operation__c = newMap.get(payrollRec.NSP_Sub_Client_Name__c).NSP_States_of_Operations__c;
        }

        update payrolls;
    }

    /***********************************************************************************************
    * MethodName: updateAssetTerminationForm
    * Description :  This method will clear the asset termination information section
    * Params:   List<NSP_Sub_Client__c> NewList   Map<Id, NSP_Sub_Client__c> oldMapSubClient  
    * Author: Bindushree R
    * ********************************************************************************************/
    
    public void updateAssetTerminationForm(List<NSP_Sub_Client__c> NewList, Map<Id, NSP_Sub_Client__c> oldMapSubClient){
        //added as part of STY-03529 changes
        Map<Id, NSP_Sub_Client__c> mapOfSubAccount = new Map<Id,NSP_Sub_Client__c> ();
        List<Asset> updatedAssetList = new List<Asset>();
        try{
            for(NSP_Sub_Client__c sc :NewList ){
                if(sc.NSP_Sub_Client__c!=null && sc.NSP_Sub_Client__c.endsWith('00') && sc.NSP_Renewal_Date__c!=null &&
                   sc.NSP_Renewal_Date__c!=oldMapSubClient.get(sc.Id).NSP_Renewal_Date__c && sc.NSP_Account__c!=null){
                       mapOfSubAccount.put(sc.NSP_Account__c,sc);
                       
                   }
            }
            //clear asset termination form section values
            if(!mapOfSubAccount.isEmpty()){
                for(Asset asset: [SELECT AccountId,NSP_Renewal_Date__c,NSP_Client__c, NSP_Verbal_Term_recd__c,NSP_Verbal_Term_Date__c,NSP_Verbal_Term_Updatedby__c,
                              NSP_Written_Term_recd__c,NSP_Written_Term_Date__c,NSP_Written_Termination_Updated_By__c,
                              NSP_Anticipated_Date_Of_Termination__c,NSP_Reason_for_Term__c,NSP_Pending_Termination__c FROM Asset WHERE AccountId IN:mapOfSubAccount.keyset()  ]){
                    
                      if(mapOfSubAccount.get(asset.AccountId).NSP_Renewal_Date__c>= asset.NSP_Anticipated_Date_Of_Termination__c){
                        
                              if(asset.NSP_Verbal_Term_recd__c==true){
                                  asset.NSP_Verbal_Term_recd__c =false;
                                  asset.NSP_Verbal_Term_Date__c=null;
                                  asset.NSP_Verbal_Term_Updatedby__c=Label.NSP_Deployment_Manager;
                                  asset.NSP_Anticipated_Date_Of_Termination__c=null;
                                  asset.NSP_Reason_for_Term__c=null;
                                  asset.NSP_Pending_Termination__c=false;
                               }
                               if(asset.NSP_Written_Term_recd__c==true){
                                  asset.NSP_Written_Term_recd__c =false;
                                  asset.NSP_Written_Term_Date__c=null;
                                  asset.NSP_Written_Termination_Updated_By__c=Label.NSP_Deployment_Manager;
                                  asset.NSP_Anticipated_Date_Of_Termination__c=null;
                                  asset.NSP_Reason_for_Term__c=null;
                                  asset.NSP_Pending_Termination__c=false;
                               }
                               
                          updatedAssetList.add(asset);
                        
                    }
                }
            }
            if(!updatedAssetList.isEmpty()){
                database.update(updatedAssetList);
           }
      } catch (Exception ex) {
                NSP_ErrorLogHandler.logSaveException('NSP_SubClientTriggerHelper', 'updateAssetTerminationForm', ex.getMessage());
      }
            
        
    }
    
}