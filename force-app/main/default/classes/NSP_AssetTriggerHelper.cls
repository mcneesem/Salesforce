/**
* Represents the Asset trigger helper which handles all the logic.
*/

public class NSP_AssetTriggerHelper {
    
    
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
    
}