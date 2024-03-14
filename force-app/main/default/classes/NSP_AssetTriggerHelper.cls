/**
* Represents the Asset trigger helper which handles all the logic.
* Modification History
* Rahul Singh        Sept  30 2022    
* Rahul Singh        June  02 2023   
*/

public class NSP_AssetTriggerHelper {    
    // test w/ NSP_AssetTriggerHelperTest (87%)    
        
    private static final string assetWoType = 'WO';
    private static final string assetwxType = 'WX_WA';
    private static final string activeStatus = 'Active';
    private static final string onboardingStatus = 'Onboarding';    
    private static final Id new_Asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get(assetWoType).getRecordTypeId();
    private static final Id asset_RT_ID = Schema.SObjectType.Asset.RecordTypeInfosByName.get(assetwxType).getRecordTypeId();
    private static final String ASSET_TRIGGER_HELPER = 'NSP_AssetTriggerHelper';
    Static final Id WOAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
    Static final Id CPQAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset','NSP_CPQ_Asset');
    private static final string BACKOUT= 'Backout';
    private static final string TERMINATED= 'Terminated';
    private static final string RETURNED= 'Returned';
    private static final string INACTIVE= 'Inactive';

    
    /**
* Iterates throught the list of new Account and passes the required attributes to other methods.
* @param newList List of New Accounts.  
* @return void             
*                
*/       
    public void beforeInsertDirector(List<Asset> newList){ 
     
     /*  try{
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
        } */
		
       try {
       
       updatePayDateonAsset(newList,null); // added for STY-03387
            
            // Added for STY-02728 
            //Moved the parent Id update code to NSP_UpdateAsset class
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException(ASSET_TRIGGER_HELPER, 'beforeInsertDirector', ex.getMessage());
        } 
        
        
    }
    
/**
* Iterates throught the list of new Account and passes the required attributes to other methods.
* @param newList List of New Account.
* @param newMap List of New Account.
* @return void
*                
*/    
    public void afterInsertDirector(List<Asset> newList, Map<Id, Asset> newMap) {
        List<Asset> ast = new List<Asset>();
        updateInvoiceDate(newList,newMap);
        peoTESClientStatus(newList,newMap);
        updateRETAsset(newList,newMap);
        List<Asset> docusignAsset = new List<Asset>();
        try {
           for(Asset assetObj: newList){              
                if(assetObj.Status != null && (assetObj.Status == activeStatus || assetObj.Status == onboardingStatus))
                {
                 ast.add(assetObj);
                }
                if(assetObj.Status != null && assetObj.RecordTypeId != WOAssetRecordTypeId && assetObj.RecordTypeId != CPQAssetRecordTypeId){
                      docusignAsset.add(assetObj); 
                   }
            }
            if(!docusignAsset.isEmpty()){
                updateAssetInDocusign(docusignAsset);
            }
       if(!ast.isEmpty()){
           updateActiveAssets(ast);
       }
        
        
            }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_AssetTriggerHelper', 'beforeInsertDirector', ex.getMessage());
        }
    }
    
    
    /**
* Iterates throught the list of new Assets and passes the required attributes to other methods.
* @param newMap, oldMap List of Assets.  
* @return void             
*                
*/
    public void beforeUpdateDirector(Map<Id, Asset> newMap, Map<Id, Asset> oldMap){ 
        try{
            List<Asset> assetListToUpdate = new List<Asset>();
            Set<String> aimsClientSet = new Set<String>();

            // Looping through Asset records
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

    //
    // Iterates throught the list of new Assets and passes the required attributes to other methods.
    // @param newMap, oldMap List of Assets.
    // @return void
    //
    public void afterUpdateDirector( Map<Id,Asset> newMap , Map<Id,Asset> oldMap ) { 
        if ( ( newMap != null ) && ( newMap.size() > 0 ) ) {
            NSP_SObjectHistoryTrackingHelper.enqueueJob(
                (Map<Id,sObject>)newMap ,
                (Map<Id,sObject>)oldMap
            );
        }
       Set<Id> asstIdSet = new Set<Id>();        
       List<Asset> ast = new List<Asset>();
       List<Asset> astremove = new List<Asset>();
       List<Asset> docusignAsset = new List<Asset>();
       updateInvoiceDate(newMap.values(),oldMap);
       peoTESClientStatus(newMap.values(),oldMap);
       updateRETAsset(newMap.values(),oldMap);
       
       for(Asset asst : newMap.values()){
           if(asst.NSP_Government_Contractor__c != oldMap.get(asst.Id).NSP_Government_Contractor__c && asst.recordTypeId == WOAssetRecordTypeId
             ){
                 asstIdSet.add(asst.Id);
             }           

            if(asst.Status != oldMap.get(asst.Id).Status)
            {
                 ast.add(asst);
       }
           if(asst.Status != oldMap.get(asst.Id).Status && asst.RecordTypeId != WOAssetRecordTypeId && asst.RecordTypeId != CPQAssetRecordTypeId){
                 docusignAsset.add(asst); 
             
       }
           if(!docusignAsset.isEmpty()){
               updateAssetInDocusign(docusignAsset);
           }

       if(!ast.isEmpty()){
           updateActiveAssets(ast);
       }
       
       if(!asstIdSet.isEmpty()){
           mapGovernmentContratcorOnPDS(asstIdSet);
       }               
       }
   }
   
    /**
    * @MethodName: updateAssetInDocusign
    * @Description: Active asset for docusign use
    * @param :List<Asset> ast
    * @return void                          
    */    
    public static void updateAssetInDocusign(List<Asset> ast) {
    Map<Id, Set<String>> accountToAssetRecordtypeMap = new Map<Id, Set<String>>();
    Map<Id, RecordTypeInfo> rtinfos = Asset.sObjectType.getDescribe().getRecordTypeInfosById();
    List<Id> accountList = new List<Id>();
    try{    
    for (Asset eachAsset : ast) {
        if (eachAsset.AccountId != null ) {
            accountList.add(eachAsset.AccountId);
        }
    }
        
    List <Asset> assetList = new List<Asset>();
    assetList = [SELECT ID, recordtypeId, recordtype.name, AccountId, Status from Asset WHERE AccountId IN:accountList 
                 AND RecordTypeId != :WOAssetRecordTypeId AND RecordTypeId != :CPQAssetRecordTypeId AND Status != :TERMINATED AND Status != :BACKOUT AND Status != :RETURNED AND Status != :INACTIVE
                 ];
        
    for (Asset eachAsset : assetList) {
        if (eachAsset.AccountId != null) { 
            if (!accountToAssetRecordtypeMap.containsKey(eachAsset.AccountId)) {
                accountToAssetRecordtypeMap.put(eachAsset.AccountId, new Set<String>());
            }
          
          String rtName;
          if(rtinfos.containsKey(eachAsset.RecordTypeId)) {
                 rtName = rtinfos.get(eachAsset.RecordTypeId).getName();
             }
            // Adding all recordtype here from all related assets
            accountToAssetRecordtypeMap.get(eachAsset.AccountId).addAll(rtName.split(','));

           
        }
    }

    List<Account> acctLst = new List<Account>();

    for (Account eachAccount : [SELECT Id, Docusign_Assets__c FROM Account WHERE ID IN :accountList]) {
        //Clearing old value for Docusign_Assets__c
        eachAccount.Docusign_Assets__c = Null;
        if (accountToAssetRecordtypeMap.containsKey(eachAccount.Id)) {
			//Adding value into Set for dedupe
            Set<String> existingassetsrecordtype = accountToAssetRecordtypeMap.get(eachAccount.Id);
            //Adding value from set to List
            List<String> ActiveAssetList = new List<String>();
            ActiveAssetList.addAll(existingassetsrecordtype);
			//Updating the Docusign_Assets__c
            if(ActiveAssetList.size() > 0){
                eachAccount.Docusign_Assets__c = String.join(ActiveAssetList, ', ');
            }
            
        }
            acctLst.add(eachAccount);
    }
    	update acctLst;
    }catch (exception ex) {
                NSP_ErrorLogHandler.logSaveException(ASSET_TRIGGER_HELPER, 'updateAssetInDocusign', ex.getMessage());
            }
    }
    
   /**
    * @MethodName: updateActiveAssets
    * @Description: This method is used to Update Active Asset on Account
    * @param :List<Asset> ast
    * @Defect : STY-04435
    * @return void                          
    */    
    public static void updateActiveAssets(List<Asset> ast) {
    Map<Id, Set<String>> mp = new Map<Id, Set<String>>();
    Map<Id, RecordTypeInfo> rtinfos = Asset.sObjectType.getDescribe().getRecordTypeInfosById();
    
    List<Id> accountList = new List<Id>();
    for (Asset eachAsset : ast) {
        if (eachAsset.AccountId != null ) {
            accountList.add(eachAsset.AccountId);
        }
    }
        List<Account> accList =[SELECT id, NSP_Active_Assets__c from account WHERE ID IN:accountList];
            for(Account acc: accList){
                acc.NSP_Active_Assets__c = '';
            }
            update accList;
        
    List <Asset> assetList = new List<Asset>();
    assetList = [SELECT id, recordtypeId, recordtype.name, AccountId, Status from Asset WHERE AccountId IN:accountList AND (Status = :activeStatus OR Status = :onboardingStatus)];
 
    for (Asset eachAsset : assetList) {
        if (eachAsset.AccountId != null ) { 
        
            if (!mp.containsKey(eachAsset.AccountId)) {
                mp.put(eachAsset.AccountId, new Set<String>());
            }
          
          String rtName;
          if(rtinfos.containsKey(eachAsset.RecordTypeId)) {
                 rtName = rtinfos.get(eachAsset.RecordTypeId).getName();
             }

            // Adding all recordtype here from all related assets
            mp.get(eachAsset.AccountId).addAll(rtName.split(';'));
        }
    }

    List<Account> acctLst = [SELECT Id, NSP_Active_Assets__c FROM Account WHERE ID IN :mp.KeySet()];

    for (Account a : acctLst) {
        if (mp.ContainsKey(a.Id)) {
            Set<String> existingassetsrecordtype = mp.get(a.Id);

            //Updating the NSP_Active_Assets__c
            List<String> ActiveAssetList = new List<String>();
            ActiveAssetList.addAll(existingassetsrecordtype);
            a.NSP_Active_Assets__c = String.join(ActiveAssetList, ';');
        }
    }
    update acctLst; 
}
     
   /**
    * @MethodName: mapGovernmentContratcorOnPDS
    * @Description: This method is used to map Government Contractor checkbox on PDS after Asset Update
    * @param :Set<Id> assetIdSet
    * @createdDate : 10/11/2022
    * @Defect : STY-03277
    * @return void                          
    */
    public void mapGovernmentContratcorOnPDS(Set<Id> assetIdSet){
        Map<Id, Boolean> isSubClientGovConMap = new Map<Id, Boolean>();
        List<NSP_Payroll__c> payRollList = new List<NSP_Payroll__c>();
        for(NSP_Sub_Client__c  subClient :[SELECT Id, 
                                           NSP_Asset__c, 
                                           NSP_Asset__r.NSP_Government_Contractor__c,
                                           NSP_Asset__r.recordTypeId
                                           FROM NSP_Sub_Client__c 
                                           WHERE NSP_Asset__c IN: assetIdSet] ){
                                               isSubClientGovConMap.put(subClient.Id, subClient.NSP_Asset__r.NSP_Government_Contractor__c);    
                                           }
        if(!isSubClientGovConMap.isEmpty()){
            for(NSP_Payroll__c pRoll : [SELECT Id, NSP_Sub_Client_Name__c, 
                                        NSP_Government_Contractor__c 
                                        FROM NSP_Payroll__c 
                                        WHERE NSP_Sub_Client_Name__c IN:isSubClientGovConMap.keySet() ]){
                                            pRoll.NSP_Government_Contractor__c = isSubClientGovConMap.get(pRoll.NSP_Sub_Client_Name__c);
                                            payRollList.add(pRoll);
                                        }
            try{
                if(!payRollList.isEmpty()){
                    Database.update(payRollList);
                }
            } catch (exception ex) {
                NSP_ErrorLogHandler.logSaveException(ASSET_TRIGGER_HELPER, 'mapGovernmentContratcorOnPDS', ex.getMessage());
            }
        }
    } 

    /**
    * @MethodName: createPlatformEventForAsset
    * @Description: This method is used to fire platform event for Asset field change based on metadata.
    * @param :List<Asset> newAssets, map<Id, Asset> oldAssets
    * @createdDate : 11/03/2022
    * @Defect : STY-03624
    * @return void                          
    */
  
    public static void createPlatformEventForAsset(List<Asset> newAssets, map<Id, Asset> oldAssets) {
        //Boolean to check if any field is changed
        Boolean isAssetFIeldChanged = false;
        List<Asset_Event__e> assetEventToBeInserted = New List<Asset_Event__e>();
        List<NSP_Error_Log__c> logList = new List<NSP_Error_Log__c>();
        List<string> assetFieldDetails = new List<string>();
        
        // get record type Id Of 'WO' 
        Id wORecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
        //Get Record details for Metadata
        NSP_Platform_Event_Fields_Management__mdt assetFieldFromMdt = NSP_Platform_Event_Fields_Management__mdt.getInstance('Asset_Fields');
        
        if(assetFieldFromMdt.NSP_Active__c == True){            
            assetFieldDetails.addall(assetFieldFromMdt.NSP_Fields__c.split(';'));         
        }
        for(Asset asset : newAssets) {
            for(String assetField : assetFieldDetails) {
                Asset oldAsset = OldAssets.get(asset.Id);
                if(asset.RecordTypeId == wORecordTypeId && asset.get(assetField) != oldAsset.get(assetField)) {
                    isAssetFIeldChanged = true;                  
                }
            }
            if(isAssetFIeldChanged) {
                Asset_Event__e assetEventToBeCreated = New Asset_Event__e();
                assetEventToBeCreated.NSP_Substance_Abuse_Policy__c = asset.NSP_Substance_Abuse_Policy__c;
                assetEventToBeCreated.NSP_ES_e_Verify_Client__c = asset.NSP_IES_e_Verify_Client__c;
                assetEventToBeCreated.NSP_AIMS_Client__c = asset.NSP_Client__c;
                assetEventToBeCreated.NSP_Minor_Job_Position__c = asset.NSP_Minor_Job_Position__c;
                assetEventToBeInserted.add(assetEventToBeCreated);
            }
        }
        
        if(!assetEventToBeInserted.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(assetEventToBeInserted);
            // Inspect publishing result for each event
            
            for (Database.SaveResult sr : results) {
                NSP_Error_Log__c log = new NSP_Error_Log__c();
                log.NSP_Class__c = ASSET_TRIGGER_HELPER;
                log.NSP_Method__c = 'publishEventBus';                
                log.NSP_Description__c = String.valueOf(sr.getErrors()[0].getMessage()) + '  '+String.valueOf(sr.getErrors()[0].getStatusCode());
                log.NSP_Record_Id__c = sr.getId();
                logList.add(log);  
            }
            
            if(logList.size() > 0){
                insert logList;
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
                if(newAsset.opportunity__c!=null){
          		Asset oldAsset = oldMap != null ? oldMap.get(newAsset.Id):null;
				if((Trigger.isInsert && newAsset.RecordTypeId == new_Asset_RT_ID && newAsset.NSP_AIMS_First_Pay_Date__c != NULL)
                  ||(newAsset.NSP_AIMS_First_Pay_Date__c != oldAsset.NSP_AIMS_First_Pay_Date__c && newAsset.RecordTypeId == new_Asset_RT_ID && newAsset.NSP_AIMS_First_Pay_Date__c != NULL) 
                  ||(newAsset.opportunity__c != oldAsset.opportunity__c && newAsset.RecordTypeId == new_Asset_RT_ID && newAsset.NSP_AIMS_First_Pay_Date__c != NULL) ){
					idSet.add(newAsset.opportunity__c);
				}
				else if((Trigger.isInsert && newAsset.RecordTypeId == asset_RT_ID && newAsset.NSP_First_Pay_Date__c != NULL)
                       ||(newAsset.NSP_First_Pay_Date__c != oldAsset.NSP_First_Pay_Date__c  && newAsset.RecordTypeId == asset_RT_ID && newAsset.NSP_First_Pay_Date__c != NULL)
                       ||(newAsset.opportunity__c != oldAsset.opportunity__c  && newAsset.RecordTypeId == asset_RT_ID && newAsset.NSP_First_Pay_Date__c != NULL)){
					idwxset.add(newAsset.opportunity__c);
                   
				}
                }
		}

        if(idSet.Size() > 0) {
            List<Asset> assetResult = [SELECT Id, NSP_AIMS_First_Pay_Date__c,opportunity__c FROM Asset WHERE opportunity__c In :IdSet AND NSP_AIMS_First_Pay_Date__c !=NULL order by NSP_AIMS_First_Pay_Date__c DESC limit 1];
            for(Asset assetWo: assetResult){
                oppList.add(new Opportunity(id = assetWo.opportunity__c,Nsp_1st_Pay_Invoice_Date_Reporting__c = assetWo.NSP_AIMS_First_Pay_Date__c));
            }
        }
	
	    // if(idwxset.Size() > 0) {
        //     List<Asset> assetWxResult = [SELECT Id, NSP_First_Pay_Date__c, opportunity__c FROM Asset WHERE opportunity__c In :idwxset AND NSP_First_Pay_Date__c !=NULL order by NSP_First_Pay_Date__c DESC limit 1];
        //     for(Asset assetWx: assetWxResult){
        //         oppList.add(new Opportunity(id = assetWx.opportunity__c,Nsp_1st_Pay_Invoice_Date_Reporting__c = assetWx.NSP_First_Pay_Date__c));
        //     }	
		// }

       try{
        if(!oppList.isEmpty()){
            update oppList;
        }
    }
    catch(Exception ex){
        NSP_ErrorLogHandler.logSaveException(ASSET_TRIGGER_HELPER, 'updateInvoiceDate', ex.getMessage());
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
		for(Asset newAsset : newList){
			Asset oldAsset = oldMap != null ? oldMap.get(newAsset.Id):null;
			
			if(newAsset.Opportunity__c != null && newAsset.RecordTypeId == new_Asset_RT_ID && (Trigger.isInsert || newAsset.Opportunity__c != oldAsset.Opportunity__c) ){
				opportunityIdSet.add(newAsset.Opportunity__c); // get opportunity id
			}
		}
		
		if(opportunityIdSet.Size() > 0){
			// create opportunity to checklist map
			for(NSP_Checklist__c eachChecklist : [SELECT Id,NSP_Requested_First_Pay_Date__c,NSP_Opportunity__c FROM NSP_Checklist__c 
											WHERE NSP_Opportunity__c IN :opportunityIdSet AND
											NSP_Opportunity__r.NSP_PrimaryProduct__c IN ('WS','WO') AND 
											recordtypeId =: soldToCheckListRecordTypeId AND
											NSP_Requested_First_Pay_Date__c != null
											]){
				opportunityIdToChecklistMap.put(eachChecklist.NSP_Opportunity__c,eachChecklist);
			}
			
			for(Asset newAsset : newList){
				Asset oldAsset = oldMap != null ? oldMap.get(newAsset.Id):null;
				
				if(newAsset.Opportunity__c != null && newAsset.RecordTypeId == new_Asset_RT_ID && (Trigger.isInsert || newAsset.Opportunity__c != oldAsset.Opportunity__c) 
					&& opportunityIdToChecklistMap.containsKey(newAsset.Opportunity__c)){
					NSP_Checklist__c objChecklist = opportunityIdToChecklistMap.get(newAsset.Opportunity__c);
					newAsset.NSP_Projected_First_Pay_Date__c = objChecklist.NSP_Requested_First_Pay_Date__c; // assign value
				}
			}
		}
	}
    

/***********************************************************************************************
    * MethodName: updateAssetServiceRegion
    * Description : This method is used to update Service Region Field on before Insert.
    * Params:       List<Asset> Boolean isInsert
    * ********************************************************************************************/
        
    Public Static void updateAssetServiceRegion(List<Asset> newList){
        Id wORecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
        Map<id,NSP_Account_Team__c> accountTeamById = new Map<id,NSP_Account_Team__c>();
        set<Id> setofAccountIds = new set<Id>();
        for(Asset asset : newList){            
            //accountId should not be null and record type should be 'WO'
            if(asset.AccountId != null && asset.RecordTypeId == wORecordTypeId){
                setofAccountIds.add(asset.AccountId);
            }
        }
        
        if(!setofAccountIds.isEmpty()) {
            //Build Account Map for Service Region
            for(NSP_Account_Team__c accountTeam : [SELECT Id, Name,NSP_Account__c, NSP_User__r.NSP_Service_Region__c, NSP_Role__c FROM NSP_Account_Team__c WHERE NSP_Account__c =: setofAccountIds AND NSP_Role__c = 'Manager, HR Services' AND NSP_User__c != null]){
                accountTeamById.put(accountTeam.NSP_Account__c,accountTeam);
            }
            
            for(Asset asset : newList){
                if(accountTeamById.ContainsKey(asset.AccountId)){
                     asset.NSP_Service_Region__c = accountTeamById.get(asset.AccountId).NSP_User__r.NSP_Service_Region__c;
                }
            }
        }
        
    }

    /***********************************************************************************************
    * MethodName: processLeadParentFromAsset
    * Description : Method to process lead parent on plan subplan and child asset. story STY-03796
    * Params:       List<Id> 
    * ********************************************************************************************/
    
    @InvocableMethod(label='processLeadParentFromAsset' description='Method to process lead parent on plan subplan and child asset' category='Asset')
    public static void processLeadParentFromAsset(list<id> assetIds){	
        NSP_ProcessAssetforLeadParent.processLeadParent(new set<Id>(assetIds));
    }

/**
* Iterates throught the list of new Assets and passes the required attributes to other methods.
* @param newList, oldMap List of Assets.  
* @return void   
* description: logic to populate peoTESClientStatus          
* Date :6/2/2023 for STY-04442
*/    
    public void peoTESClientStatus(List<Asset> newList,Map<Id, Asset> oldMap){
        List <Account> accListLookup = new List<Account> ();
		set<id> assetIdSet = new set<id>();
        set<id> accIdSet = new set<id>(); 
        Id wORecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
        Id wX_WARecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WX_WA).getRecordTypeId();
        Map<id,Asset> assetWoOnboard = new Map<id,Asset>();
        Map<id,Asset> assetWxOnboard = new Map<id,Asset>();
        Map<id,Asset> assetWoWxTerm = new Map<id,Asset>();
        Map<id,Asset> assetWoTerm = new Map<id,Asset>();
        Map<id,Asset> assetWxTerm = new Map<id,Asset>();
        Map<id,Asset> assetWxLatestTerm = new Map<id,Asset>();
        Map<id,Asset> assetWoLatestTerm = new Map<id,Asset>();
        Map<id,Asset> assetWoWxLatestTerm = new Map<id,Asset>();
        List <ID> onboardList = new List<ID> ();
        List <ID> onactiveList = new List<ID> ();
        List <ID> woWxActiveList = new List<ID> ();
        List<String> status = new List<String>{'Onboarding', 'Active','Terminated'};
		for(Asset newAsset : newList){
			Asset oldAsset = oldMap != null ? oldMap.get(newAsset.Id):null;
			
			if( ((newAsset.RecordTypeId == wORecordTypeId ||newAsset.RecordTypeId == wX_WARecordTypeId)&&(status.contains(newAsset.Status)) ) 
                && ((Trigger.isInsert && newAsset.AccountId!= NULL) ||(Trigger.isUpdate && newAsset.Status != oldAsset.Status && newAsset.AccountId!= NULL) ) ){
				accIdSet.add(newAsset.AccountId); // get asset id

                if((newAsset.Status == 'Onboarding' || newAsset.Status == 'Active') && newAsset.RecordTypeId == wORecordTypeId ){
                    assetWoOnboard.put(newAsset.AccountId, newAsset);
                }
                Else If((newAsset.Status == 'Onboarding' || newAsset.Status == 'Active') && newAsset.RecordTypeId == wX_WARecordTypeId ){
                    assetWxOnboard.put(newAsset.AccountId, newAsset);
                }
                Else If(newAsset.Status == 'Terminated' && (newAsset.RecordTypeId == wORecordTypeId || newAsset.RecordTypeId == wX_WARecordTypeId ) ){
                    assetWoWxTerm.put(newAsset.AccountId, newAsset);
                }
                if((newAsset.Status == 'Terminated') && newAsset.RecordTypeId == wORecordTypeId ){
                    assetWoTerm.put(newAsset.AccountId, newAsset);
                }
                if((newAsset.Status == 'Terminated') && newAsset.RecordTypeId == wX_WARecordTypeId ){
                    assetWxTerm.put(newAsset.AccountId, newAsset);
                }
                
               
			}
            
           
		}
        
        If(assetWoWxTerm.Size() > 0){
        for(Asset assetLi : [SELECT id,accountid FROM Asset WHERE (RecordTypeId =: wORecordTypeId OR RecordTypeId =: wX_WARecordTypeId) AND (Status= 'Active' OR Status= 'Onboarding') AND accountid IN :assetWoWxTerm.KeySet() ]){
    	woWxActiveList.add(assetLi.accountid);
		}    
        for(Account acc : [SELECT id,(SELECT id,accountid,NSP_Termination_Date__c,Status,NSP_Product_Line__c FROM Assets WHERE NSP_Termination_Date__c!=NUll AND Status = 'Terminated' AND (RecordTypeId =: wORecordTypeId OR RecordTypeId =: wX_WARecordTypeId) order by NSP_Termination_Date__c desc limit 1) FROM account WHERE ID IN :assetWoWxTerm.KeySet()]){    
    		for( asset asobj : acc.Assets){
                
                 assetWoWxLatestTerm.put(asobj.AccountId, asobj);

    			}
		} 
            
        }
        If(assetWoTerm.Size() > 0){
		for(Asset assetLi : [SELECT id,accountid FROM Asset WHERE RecordTypeId =: wORecordTypeId AND (Status= 'Active' OR Status= 'Onboarding') AND accountid IN :assetWoTerm.KeySet() ]){
    	onboardList.add(assetLi.accountid);
		}
          
        for(Account acc : [SELECT id,(SELECT id,accountid,NSP_Termination_Date__c FROM Assets WHERE NSP_Termination_Date__c!=NUll AND Status = 'Terminated' AND RecordTypeId =: wORecordTypeId order by NSP_Termination_Date__c desc limit 1) FROM account WHERE ID IN :assetWoTerm.KeySet()]){    
    		for( asset asobj : acc.Assets){               
                 assetWoLatestTerm.put(asobj.AccountId, asobj);                
    			}
		} 
            
        }
        
        If(assetWxTerm.Size() > 0){
        for(Asset assetLi : [SELECT id,accountid FROM Asset WHERE RecordTypeId =: wX_WARecordTypeId AND (Status= 'Active' OR Status= 'Onboarding') AND accountid IN :assetWxTerm.KeySet() ]){
    	onactiveList.add(assetLi.accountid);
		}    
        for(Account acc : [SELECT id,(SELECT id,accountid,NSP_Termination_Date__c FROM Assets WHERE NSP_Termination_Date__c!=NUll AND Status = 'Terminated' AND RecordTypeId =: wX_WARecordTypeId order by NSP_Termination_Date__c desc limit 1) FROM account WHERE ID IN :assetWxTerm.KeySet()]){    
    		for( asset asobj : acc.Assets){                
                 assetWxLatestTerm.put(asobj.AccountId, asobj);                 
    			}
		} 
            
        }
        
        
        If(accIdSet.Size() > 0){
            
            For(Id accId :accIdSet ){
                Account accObject = new Account();
                accObject.Id = accId;
                If(assetWoOnboard.containsKey(accId)){
                  
                    if(assetWoOnboard.get(accId).NSP_Product_Line__c != null){
                    String NSP_Product = assetWoOnboard.get(accId).NSP_Product_Line__c;
                    String NSP_Status = assetWoOnboard.get(accId).Status;
                    String NSP_Client_Status = NSP_Product+' - '+NSP_Status;
                    accObject.PEO_TES_Client_Status__c = NSP_Client_Status;
                    
                    }
                    else{
                    String NSP_Status = assetWoOnboard.get(accId).Status;
                    accObject.PEO_TES_Client_Status__c = NSP_Status;
                    }
                }
                Else If(assetWxOnboard.containsKey(accId)){
                    
                    if(assetWxOnboard.get(accId).NSP_Product_Line__c != null){
                    String NSP_Product = assetWxOnboard.get(accId).NSP_Product_Line__c;
                    String NSP_Status = assetWxOnboard.get(accId).Status;
                    String NSP_Client_Status = NSP_Product+' - '+NSP_Status;
                    accObject.PEO_TES_Client_Status__c = NSP_Client_Status;                   
                    }
                    else{
                    String NSP_Status = assetWxOnboard.get(accId).Status;
                    accObject.PEO_TES_Client_Status__c = NSP_Status;
                    }
                }
                 Else If(assetWoWxTerm.containsKey(accId) && !woWxActiveList.contains(accId) && !assetWoWxLatestTerm.isEmpty()){
                                         
                    if(assetWoWxLatestTerm.get(accId).NSP_Product_Line__c != null){
                    String NSP_Product = assetWoWxLatestTerm.get(accId).NSP_Product_Line__c;
                    String NSP_Status = assetWoWxLatestTerm.get(accId).Status;
                    String NSP_Client_Status = NSP_Product+' - '+NSP_Status;
                    accObject.PEO_TES_Client_Status__c = NSP_Client_Status;
                    }
                    else
                    {
                    String NSP_Status = assetWoWxLatestTerm.get(accId).Status;
                    accObject.PEO_TES_Client_Status__c = NSP_Status;
                    }
                }
                Else If(assetWoWxTerm.containsKey(accId) && !woWxActiveList.contains(accId) && assetWoWxLatestTerm.isEmpty()){
                                         
                    if(assetWoWxTerm.get(accId).NSP_Product_Line__c != null){
                    String NSP_Product = assetWoWxTerm.get(accId).NSP_Product_Line__c;
                    String NSP_Status = assetWoWxTerm.get(accId).Status;
                    String NSP_Client_Status = NSP_Product+' - '+NSP_Status;
                    accObject.PEO_TES_Client_Status__c = NSP_Client_Status;
                    }
                    else
                    {
                    String NSP_Status = assetWoWxTerm.get(accId).Status;
                    accObject.PEO_TES_Client_Status__c = NSP_Status;
                    }
                }
                
                If(assetWoOnboard.containsKey(accId)){
                    accObject.WO_Asset__c =assetWoOnboard.get(accId).Id;
                
                }
                Else If(assetWoTerm.containsKey(accId) && !onboardList.contains(accId) && !assetWoLatestTerm.isEmpty()){
                   accObject.WO_Asset__c =assetWoLatestTerm.get(accId).Id;
                
                }
                Else If(assetWoTerm.containsKey(accId) && !onboardList.contains(accId) && assetWoLatestTerm.isEmpty()){
                   accObject.WO_Asset__c =assetWoTerm.get(accId).Id;
                
                }
                
                If(assetWxOnboard.containsKey(accId)){
                    accObject.WX_Asset__c =assetWxOnboard.get(accId).Id;
                
                }
                Else If(assetWxTerm.containsKey(accId) && !onactiveList.contains(accId) && !assetWxLatestTerm.isEmpty()){
                    accObject.WX_Asset__c =assetWxLatestTerm.get(accId).Id;
                
                }
                 Else If(assetWxTerm.containsKey(accId) && !onactiveList.contains(accId) && assetWxLatestTerm.isEmpty()){
                    accObject.WX_Asset__c =assetWxTerm.get(accId).Id;
                
                }
                 
               accListLookup.add(accObject); 
            }
            
            
        }
        
        try{
        if(!accListLookup.isEmpty()){           
            update accListLookup;            
        }
       
    	}
    	catch(Exception ex){
        	NSP_ErrorLogHandler.logSaveException(ASSET_TRIGGER_HELPER, 'peoTESClientStatus', ex.getMessage());
    	}
        

}
    
/**
* Iterates throught the list of new Assets and passes the required attributes to other methods.
* @param newList, oldMap List of Assets.  
* @return void   
* description: logic to populate updateRETAsset          
* Date :6/2/2023 for STY-04442
*/   
    public void updateRETAsset(List<Asset> newList,Map<Id, Asset> oldMap){
        
        List <ID> onRetList = new List<ID> ();
		List <Account> retList = new List<Account> ();
        List <Account> accListLookup = new List<Account> ();
		set<id> assetIdSet = new set<id>();
        set<id> accIdSet = new set<id>(); 
        Id retRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE).getRecordTypeId();
        Id ret_ChoiceRecordTypeId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE).getRecordTypeId();
        Map<id,Asset> assetRetOnboard = new Map<id,Asset>();
        Map<id,Asset> assetChoiceOnboard = new Map<id,Asset>();
        Map<id,Asset> assetRet_ChoiceTerm = new Map<id,Asset>();
        Map<id,Asset> assetRet_ChoiceLatestTerm = new Map<id,Asset>();
        Map<id,Asset> assetWoLatestTerm = new Map<id,Asset>();
        Map<id,Asset> assetWoWxLatestTerm = new Map<id,Asset>();
		for(Asset newAsset : newList){
			Asset oldAsset = oldMap != null ? oldMap.get(newAsset.Id):null;
			if( (Trigger.isInsert && newAsset.AccountId!= NULL) ||(Trigger.isUpdate && newAsset.Status != oldAsset.Status && newAsset.AccountId!= NULL) ){
				accIdSet.add(newAsset.AccountId); // get asset id
                if((newAsset.Status == 'Onboarding' || newAsset.Status == 'Active') && newAsset.RecordTypeId == retRecordTypeId ){
                    assetRetOnboard.put(newAsset.AccountId, newAsset);                    
                }
                Else If((newAsset.Status == 'Onboarding' || newAsset.Status == 'Active') && newAsset.RecordTypeId == ret_ChoiceRecordTypeId ){
                    assetChoiceOnboard.put(newAsset.AccountId, newAsset);                    
                }
                Else If(newAsset.Status == 'Terminated' && (newAsset.RecordTypeId == retRecordTypeId || newAsset.RecordTypeId == ret_ChoiceRecordTypeId ) ){
                    assetRet_ChoiceTerm.put(newAsset.AccountId, newAsset);
                }
                
                
               
			}
            
           
		}
        
        If(assetRet_ChoiceTerm.Size() > 0){
        for(Asset assetLi : [SELECT id,accountid FROM Asset WHERE (RecordTypeId =: retRecordTypeId OR RecordTypeId =: ret_ChoiceRecordTypeId) AND (Status= 'Active' OR Status= 'Onboarding') AND accountid IN :assetRet_ChoiceTerm.KeySet() ]){
    	onRetList.add(assetLi.accountid);
		}      
        for(Account acc : [SELECT id,(SELECT id,accountid,NSP_Termination_Date__c FROM Assets WHERE NSP_Termination_Date__c!=NUll AND (RecordTypeId =: retRecordTypeId OR RecordTypeId =: ret_ChoiceRecordTypeId) order by NSP_Termination_Date__c desc limit 1) FROM account where ID IN :assetRet_ChoiceTerm.KeySet()]){    
    		for( asset asobj : acc.Assets){
                 assetRet_ChoiceLatestTerm.put(asobj.AccountId, asobj);

    			}
		} 
            
        }
                
        If(accIdSet.Size() > 0){
            
            For(Id accId :accIdSet ){
                                                                 
                If(assetRetOnboard.containsKey(accId)){
                    retList.add(new Account(id = accId,RET_Asset__c =assetRetOnboard.get(accId).Id )); 
                }
                Else If(assetChoiceOnboard.containsKey(accId)){
                    retList.add(new Account(id = accId,RET_Asset__c =assetChoiceOnboard.get(accId).Id ));
                
                }
				Else If(assetRet_ChoiceTerm.containsKey(accId)  && !onRetList.contains(accId) && !assetRet_ChoiceLatestTerm.isEmpty()){
                    retList.add(new Account(id = accId,RET_Asset__c =assetRet_ChoiceLatestTerm.get(accId).Id ));
                
                }
                Else If(assetRet_ChoiceTerm.containsKey(accId)  && !onRetList.contains(accId) && assetRet_ChoiceLatestTerm.isEmpty()){
                    retList.add(new Account(id = accId,RET_Asset__c =assetRet_ChoiceTerm.get(accId).Id ));
                
                }   
                
            }
            
            
        }
        
        try{
        if(!retList.isEmpty()){
            update retList;
            
        }
        
    	}
    	catch(Exception ex){
        	NSP_ErrorLogHandler.logSaveException(ASSET_TRIGGER_HELPER, 'updateRETAsset', ex.getMessage());
    	}
        

}
}