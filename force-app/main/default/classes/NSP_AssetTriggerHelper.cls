/**
* Represents the Asset trigger helper which handles all the logic.
*/

public class NSP_AssetTriggerHelper {
    
    
    private static final string assetWoType = 'WO';
    private static final string assetwxType = 'WX_WA';
    private static final Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get(assetWoType).getRecordTypeId();
    private static final Id asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get(assetwxType).getRecordTypeId();
    
    /**
* Iterates throught the list of new Account and passes the required attributes to other methods.
* @param newList List of New Accounts.  
* @return void             
*                
*/
    public void beforeInsertDirector(List<Asset> newList){ 
        try{
            List<Asset> assetListToUpdate = new List<Asset>();
            Set<String> aimsClientSet = new Set<String>();
            
            for(Asset assetObj : newList) {
                if(assetObj.NSP_Need_Rollup_Recalculation__c != null && 
                   assetObj.NSP_Need_Rollup_Recalculation__c){
                       assetListToUpdate.add(assetObj);
                       aimsClientSet.add(assetObj.NSP_Client__c);
                   }
            }
            
            //check assetListToUpdate size
            //if(aimsClientSet.size() > 0){
              //  rollUpSubClientToAsset(aimsClientSet,assetListToUpdate);
            //}
        }catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
		updatePayDateonAsset(newList,null); // added for STY-03387
    }
    
    /**
* Iterates throught the list of new Account and passes the required attributes to other methods.
* @param newList List of New Account.
* @param newMap List of New Account.
* @return void
*                
*/    
    public void afterInsertDirector(List<Asset> newList, Map<Id, Asset> newMap) {
        
        updateInvoiceDate(newList,newMap);
    }
    
    /**
* Iterates throught the list of new Assets and passes the required attributes to other methods.
* @param newMap, oldMap List of Assets.  
* @return void             
*                
*/
    public void beforeUpdateDirector(Map<Id, Asset> newMap,Map<Id, Asset> oldMap){ 
        try{
            List<Asset> assetListToUpdate = new List<Asset>();
            Set<String> aimsClientSet = new Set<String>();
            
            for(Asset assetObj : newMap.values()) {
                if(assetObj.NSP_Need_Rollup_Recalculation__c != null && 
                   assetObj.NSP_Need_Rollup_Recalculation__c != oldMap.get(assetObj.Id).NSP_Need_Rollup_Recalculation__c &&
                   assetObj.NSP_Need_Rollup_Recalculation__c && assetObj.NSP_Client__c != null){
                       assetListToUpdate.add(assetObj);
                       aimsClientSet.add(assetObj.NSP_Client__c);
                   }
                   //if client segment type(future value to be assigned on effective date/client Segment date - backup the old value in current client segment type)
                   /* if(assetObj.NSP_Client_Segment_type__c != null &&
                    assetObj.NSP_Client_Segment_type__c != oldMap.get(assetObj.Id).NSP_Client_Segment_type__c && 
                    assetObj.NSP_Client_SegmentDate__c > system.today()){
                            assetObj.NSP_Current_Client_Segment_type__c = oldMap.get(assetObj.Id).NSP_Client_Segment_type__c;
                    }*/
            }
            
            //if(aimsClientSet.size() > 0){
               // rollUpSubClientToAsset(aimsClientSet,assetListToUpdate);
            //}
        }
        catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
		updatePayDateonAsset(newMap.values(),oldMap); // added for STY-03387
    }
   
  
     /**
* Iterates throught the list of new Assets and passes the required attributes to other methods.
* @param newMap, oldMap List of Assets.  
* @return void             
*                
*/
    public void afterUpdateDirector(Map<Id, Asset> newMap,Map<Id, Asset> oldMap){        
        if(newMap.size() > 0){
            NSP_SObjectHistoryTrackingHelper objectFieldHistoryHelper = new NSP_SObjectHistoryTrackingHelper((Map<Id, sObject>)newMap, (Map<Id, sObject>)oldMap);
            If( Limits.getQueueableJobs() != Limits.getLimitQueueableJobs()) {
                System.enqueueJob(objectFieldHistoryHelper);  
            }
        }
        
         updateInvoiceDate(newMap.values(),oldMap);
    }
    /*
    public void rollUpSubClientToAsset(Set<String> aimsClientSet,List<Asset> assetListToUpdate){
        //check assetListToUpdate size
        if(assetListToUpdate.size() > 0){
            Map<String,List<NSP_Sub_Client__c>> aimsClientSubClientMap = new Map<String,List<NSP_Sub_Client__c>>();
            Map<String,Set<String>> aimsClientWSEEEmployeeStateMap = new Map<String,Set<String>>();
            List<NSP_Sub_Client__c> subClientList = [Select Id,NSP_Client__c, NSP_Paid_Employees_Last_Month__c,
                                                     NSP_Actual_Full_Time_EE_Count__c,NSP_Actual_Part_Time_EE_Count__c,
                                                     NSP_Actual_Seasonal_Time_EE_Count__c ,NSP_Contractual_Full_time_EE_Count__c ,
                                                     NSP_Contractual_Part_time_EE_Count__c ,NSP_Contractual_Seasonal_Time_EE_Count__c,
                                                     NSP_Union_Employees__c, (Select NSP_State__c FROM WSEE_Employees__r where NSP_State__c != null)
                                                     FROM NSP_Sub_Client__c 
                                                     where NSP_Client__c IN: aimsClientSet];
            
            //prepare map
            for(NSP_Sub_Client__c subClientObj : subClientList){
                if(aimsClientSubClientMap.containsKey(subClientObj.NSP_Client__c)){
                    List<NSP_Sub_Client__c> subClientTempList = aimsClientSubClientMap.get(subClientObj.NSP_Client__c);
                    subClientTempList.add(subClientObj);
                    aimsClientSubClientMap.put(subClientObj.NSP_Client__c,subClientTempList);
                    Set<String> wseeStateList = aimsClientWSEEEmployeeStateMap.get(subClientObj.NSP_Client__c);
                    for(NSP_WSEE_Employee__c wseeEmployeeObj : subClientObj.WSEE_Employees__r){
                        wseeStateList.add(wseeEmployeeObj.NSP_State__c);
                    }
                    aimsClientWSEEEmployeeStateMap.put(subClientObj.NSP_Client__c,wseeStateList);
                }else{
                    List<NSP_Sub_Client__c> subClientTempList = new List<NSP_Sub_Client__c>();
                    subClientTempList.add(subClientObj);
                    aimsClientSubClientMap.put(subClientObj.NSP_Client__c,subClientTempList);
                    Set<String> wseeStateList = new Set<String>();
                    for(NSP_WSEE_Employee__c wseeEmployeeObj : subClientObj.WSEE_Employees__r){
                        wseeStateList.add(wseeEmployeeObj.NSP_State__c);
                    }
                    aimsClientWSEEEmployeeStateMap.put(subClientObj.NSP_Client__c,wseeStateList);
                }
                
            }
            
            //update values in Asset
            for(Asset assetObj : assetListToUpdate) {
                decimal paidEmployessLastMonth = 0;
                decimal actualfullTimeEECount = 0;
                decimal actualpartTimeEECount = 0;
                decimal actualsesonalEECount = 0;
                decimal contractualfullTimeEECount = 0;
                decimal contractualpartTimeEECount = 0;
                decimal contractualsesonalEECount = 0;
                
                if(aimsClientSubClientMap.containsKey(assetObj.NSP_Client__c)){
                    boolean hasUnionEmployees = false;
                    for(NSP_Sub_Client__c subClientObj : aimsClientSubClientMap.get(assetObj.NSP_Client__c)){
                        if(subClientObj.NSP_Paid_Employees_Last_Month__c != null)
                        	paidEmployessLastMonth = paidEmployessLastMonth + subClientObj.NSP_Paid_Employees_Last_Month__c;
                        if(subClientObj.NSP_Actual_Full_Time_EE_Count__c != null)
                        actualfullTimeEECount = actualfullTimeEECount + subClientObj.NSP_Actual_Full_Time_EE_Count__c;
                        if(subClientObj.NSP_Actual_Part_Time_EE_Count__c != null)
                        actualpartTimeEECount = actualpartTimeEECount + subClientObj.NSP_Actual_Part_Time_EE_Count__c;
                        if(subClientObj.NSP_Actual_Seasonal_Time_EE_Count__c != null)
                        actualsesonalEECount = actualsesonalEECount + subClientObj.NSP_Actual_Seasonal_Time_EE_Count__c;
                        if(subClientObj.NSP_Contractual_Full_time_EE_Count__c != null)
                        contractualfullTimeEECount = contractualfullTimeEECount + subClientObj.NSP_Contractual_Full_time_EE_Count__c;
                        if(subClientObj.NSP_Contractual_Part_time_EE_Count__c != null)
                        contractualpartTimeEECount = contractualpartTimeEECount + subClientObj.NSP_Contractual_Part_time_EE_Count__c;
                        if(subClientObj.NSP_Contractual_Seasonal_Time_EE_Count__c != null)
                        contractualsesonalEECount = contractualsesonalEECount + subClientObj.NSP_Contractual_Seasonal_Time_EE_Count__c;
                        if(!hasUnionEmployees && subClientObj.NSP_Union_Employees__c)
                            hasUnionEmployees = true;
                    }
                    assetObj.NSP_Paid_Employees_Last_Month__c =  paidEmployessLastMonth;
                    assetObj.NSP_Actual_Full_Time_EE_Count__c = actualfullTimeEECount;
                    assetObj.NSP_Actual_Part_Time_EE_Count__c = actualpartTimeEECount;
                    assetObj.NSP_Actual_Seasonal_Time_EE_Count__c =  actualsesonalEECount;
                    assetObj.NSP_Contractual_Full_time_EE_Count__c = contractualfullTimeEECount;
                    assetObj.NSP_Contractual_Part_time_EE_Count__c = contractualpartTimeEECount;
                    assetObj.NSP_Contractual_Seasonal_time_EE_Count__c =  contractualsesonalEECount;
                    assetObj.NSP_Union_Employees__c = hasUnionEmployees;
                    assetObj.NSP_Need_Rollup_Recalculation__c = false;
                }
                
                //for states
                if(aimsClientWSEEEmployeeStateMap.containsKey(assetObj.NSP_Client__c)){
                    String strState = '';
                    integer i = 0;
                    for(String stateStr : aimsClientWSEEEmployeeStateMap.get(assetObj.NSP_Client__c)){
                        if(i == 0)
                        	strState = strState + stateStr;
                        else
                           strState = strState + ' , ' +stateStr;
                        i++;
                    }
                    assetObj.NSP_States_of_Operations__c = strState;
                }
                
            }  
            
            
            /*Map<String,AggregateResult> aggregrateMap = new Map<String,AggregateResult>();
            
            List<AggregateResult> subClientList = [Select NSP_Client__c, SUM(NSP_Paid_Employees_Last_Month__c),
                                                   SUM(NSP_Actual_Full_Time_EE_Count__c),SUM(NSP_Actual_Part_Time_EE_Count__c),
                                                   SUM(NSP_Actual_Seasonal_EE_Count__c) ,SUM(NSP_Contractual_Full_time_EE_Count__c) ,
                                                   SUM(NSP_Contractual_Part_time_EE_Count__c) ,SUM(NSP_Contractual_Seasonal_EE_Count__c)
                                                   FROM NSP_Sub_Client__c 
                                                   GROUP BY NSP_Client__c HAVING NSP_Client__c IN: aimsClientSet ];
            
            for(AggregateResult arObj : subClientList){
                aggregrateMap.put((String)arObj.get('NSP_Client__c'),arObj);
            }
            
            for(Asset assetObj : assetListToUpdate) {
                if(aggregrateMap.containsKey(assetObj.NSP_Client__c)){
                    AggregateResult arObj = aggregrateMap.get(assetObj.NSP_Client__c);
                    assetObj.NSP_Paid_Employees_Last_Month__c =  (decimal)arObj.get('expr0');
                    assetObj.NSP_Actual_Full_Time_EE_Count__c = (decimal)arObj.get('expr1');
                    assetObj.NSP_Actual_Part_Time_EE_Count__c = (decimal)arObj.get('expr2');
                    assetObj.NSP_Actual_Seasonal_EE_Count__c =  (decimal)arObj.get('expr3');
                    assetObj.NSP_Contractual_Full_time_EE_Count__c = (decimal)arObj.get('expr4');
                    assetObj.NSP_Contractual_Part_time_EE_Count__c = (decimal)arObj.get('expr5');
                    assetObj.NSP_Contractual_Seasonal_EE_Count__c =  (decimal)arObj.get('expr6');
                    assetObj.NSP_Need_Rollup_Recalculation__c = false;
                }
            }*/
      //  }
   // } */
   // 
  
/**
* Iterates throught the list of new Assets and passes the required attributes to other methods.
* @param newList, oldMap List of Assets.  
* @return void             
* Created By: Rahul Singh
* Date :8/29/2022
*/
    public void updateInvoiceDate(List<Asset> newList,Map<Id, Asset> oldMap){
        
      set<Id> idSet = new set<Id>();
      set<Id> idwxset = new set<Id>();   
        List <opportunity> oppList = new List<opportunity> (); 
        if(newList.size() > 0){
            for(Asset newAsset :newList){
          		Asset oldAsset = oldMap != null ? oldMap.get(newAsset.Id):null;
				if((Trigger.isInsert && newAsset.RecordTypeId == new_Asset_RT_ID && newAsset.NSP_AIMS_First_Pay_Date__c != NULL)
                  ||(newAsset.NSP_AIMS_First_Pay_Date__c != oldAsset.NSP_AIMS_First_Pay_Date__c && newAsset.RecordTypeId == new_Asset_RT_ID && newAsset.NSP_AIMS_First_Pay_Date__c != NULL) ){
					idSet.add(newAsset.opportunity__c);
				}
				else if((Trigger.isInsert && newAsset.RecordTypeId == asset_RT_ID && newAsset.NSP_First_Pay_Date__c != NULL)
                       ||(newAsset.NSP_First_Pay_Date__c != oldAsset.NSP_First_Pay_Date__c  && newAsset.RecordTypeId == asset_RT_ID && newAsset.NSP_First_Pay_Date__c != NULL)){
					idwxset.add(newAsset.opportunity__c);
                   
				}
		
		}

	if(idSet.Size() > 0){
		List<Asset> assetResult = [SELECT Id, NSP_AIMS_First_Pay_Date__c,opportunity__c FROM Asset where opportunity__c In :IdSet AND NSP_AIMS_First_Pay_Date__c !=NULL order by NSP_AIMS_First_Pay_Date__c DESC limit 1];
        for(Asset assetWo: assetResult){
            oppList.add(new Opportunity(id = assetWo.opportunity__c,Nsp_1st_Pay_Invoice_Date_Reporting__c = assetWo.NSP_AIMS_First_Pay_Date__c));
	
        }
			}

	
	if(idwxset.Size() > 0){
			List<Asset> assetWxResult = [SELECT Id, NSP_First_Pay_Date__c, opportunity__c FROM Asset where opportunity__c In :idwxset AND NSP_First_Pay_Date__c !=NULL order by NSP_First_Pay_Date__c DESC limit 1];
		   for(Asset assetWx: assetWxResult){
             oppList.add(new Opportunity(id = assetWx.opportunity__c,Nsp_1st_Pay_Invoice_Date_Reporting__c = assetWx.NSP_First_Pay_Date__c));
				
        }	
       
			}

       try{
        if(!oppList.isEmpty()){
            update oppList;
        }
    }
    catch(Exception ex){
        NSP_ErrorLogHandler.logSaveException('NSP_AssetTriggerHelper', 'updateInvoiceDate', ex.getMessage());
    }

        }
    }


/**
* Iterates throught the list of new Assets and passes the required attributes to other methods.
* @param newList, oldMap List of Assets.  
* @return void   
* description: logic to copy to Asset Projected First Pay Date with opportunity with primary product  WS/WO  
* from check list Requested First Pay Date from check list.          
* Date :9/27/2022 for STY-03387
*/
	public void updatePayDateonAsset(List<Asset> newList,Map<Id, Asset> oldMap){
		
		Id  soldToCheckListRecordTypeId = Schema.SObjectType.NSP_Checklist__c.getRecordTypeInfosByDeveloperName().get('NSP_Sold_to_Paid_Checklist').getRecordTypeId();
		
		set<id> opportunityIdSet = new set<id>(); 
		map<id,NSP_Checklist__c> opportunityIdToChecklistMap = new map<id,NSP_Checklist__c>();
		for(Asset newAsset : newList)
		{
			Asset oldAsset = oldMap != null ? oldMap.get(newAsset.Id):null;
			
			if(newAsset.Opportunity__c != null && newAsset.RecordTypeId == new_Asset_RT_ID && (Trigger.isInsert || newAsset.Opportunity__c != oldAsset.Opportunity__c) ) // check opportunity is updated
			{
				opportunityIdSet.add(newAsset.Opportunity__c); // get opportunity id
			}
		}
		
		if(opportunityIdSet.Size() > 0)
		{
			// create opportunity to checklist map
			for(NSP_Checklist__c eachChecklist : [SELECT Id,NSP_Requested_First_Pay_Date__c,NSP_Opportunity__c from NSP_Checklist__c 
											where NSP_Opportunity__c IN :opportunityIdSet AND
											NSP_Opportunity__r.NSP_PrimaryProduct__c IN ('WS','WO') AND 
											recordtypeId =: soldToCheckListRecordTypeId AND
											NSP_Requested_First_Pay_Date__c != null
											])
			{
				opportunityIdToChecklistMap.put(eachChecklist.NSP_Opportunity__c,eachChecklist);
			}
			
			for(Asset newAsset : newList)
			{
				Asset oldAsset = oldMap != null ? oldMap.get(newAsset.Id):null;
				
				if(newAsset.Opportunity__c != null && newAsset.RecordTypeId == new_Asset_RT_ID && (Trigger.isInsert || newAsset.Opportunity__c != oldAsset.Opportunity__c) 
					&& opportunityIdToChecklistMap.containsKey(newAsset.Opportunity__c))
				{
					NSP_Checklist__c objChecklist = opportunityIdToChecklistMap.get(newAsset.Opportunity__c);
					newAsset.NSP_Projected_First_Pay_Date__c = objChecklist.NSP_Requested_First_Pay_Date__c; // assign value
				}
			}
		}
	}
    
}