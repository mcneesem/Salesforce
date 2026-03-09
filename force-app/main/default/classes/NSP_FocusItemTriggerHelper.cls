/**
* Represents the Focus Item trigger helper which handles all the logic.
*/
public class NSP_FocusItemTriggerHelper {
   private NSP_FocusItemTriggerHelper(){} 
   /***********************************************************************
    * @MethodName : beforeInsertDirector
    * @Description: Iterates throught the list of new Focus Items
    * @param      : List<NSP_Focus_Item__c> newList
    * @Story      : STY-03807
    * @return     : void                          
**************************************************************************/
    public static void beforeInsertDirector(List<NSP_Focus_Item__c> newList){
        try{
           List<NSP_Focus_Item__c> focusItemToCheck = new List<NSP_Focus_Item__c>();
            // check if asset field is populated
            for(NSP_Focus_Item__c focusItem: newList){
                if(focusItem.NSP_Asset__c != null ) {
                    focusItemToCheck.add(focusItem);
                } 
            }// if asset field is populated, send the list of focus item records to check account related to asset field
            if(!focusItemToCheck.isEmpty()){
                 checkAssetRelatedToAccount(focusItemToCheck);  
            }           
        } catch(Exception exc){          
            NSP_ErrorLogHandler.logSaveException('NSP_FocusItemTriggerHelper','beforeInsertDirector', exc.getMessage());
        }
    }
    
   /***********************************************************************
   * @MethodName : beforeUpdateDirector
    * @Description: Iterates throught the list of  focus items
    * @param      : Map<Id, NSP_Focus_Item__c> newMap,  Map<Id, NSP_Focus_Item__c> oldMap
    * @Story      : STY-03807
    * @return     : void                          
    **************************************************************************/
    public static void beforeUpdateDirector( Map<Id, NSP_Focus_Item__c> newMap,  Map<Id, NSP_Focus_Item__c> oldMap){
        try{
            List<NSP_Focus_Item__c> focusItemToCheck = new List<NSP_Focus_Item__c>();
            // check if asset field is changed during the update
            for(NSP_Focus_Item__c focusItem: newMap.values()){
                if(focusItem.NSP_Asset__c != oldMap.get(focusItem.ID).NSP_Asset__c ) {
                    focusItemToCheck.add(focusItem);
                } 
            }// if asset field is populated, send the list of focus item records to check account related to asset field
            if(!focusItemToCheck.isEmpty()){
                 checkAssetRelatedToAccount(focusItemToCheck);  
            }
        } catch(Exception exc){          
            NSP_ErrorLogHandler.logSaveException('NSP_FocusItemTriggerHelper','beforeUpdateDirector', exc.getMessage());
        }
    }

    /***********************************************************************
   * @MethodName : afterInsertDirector
    * @Description: Iterates throught the list of new Account GroupMembers
    * @param      : List<NSP_Focus_Item__c> newList , Map<Id, NSP_Focus_Item__c> newMap
    * @Story      : STY-01437
    * @return     : void                          
    **************************************************************************/
    public static void afterInsertDirector(List<NSP_Focus_Item__c> newList , Map<Id, NSP_Focus_Item__c> newMap){
        try{
            List<NSP_Focus_Item__c> businessRestructureList = new List<NSP_Focus_Item__c>();
            List<NSP_Focus_Item__c> extnsvSalaryReductionList = new List<NSP_Focus_Item__c>();
            List<NSP_Focus_Item__c> ecoShiftOrFinRiskList = new List<NSP_Focus_Item__c>();
            List<NSP_Focus_Item__c> riskMitigationList = new List<NSP_Focus_Item__c>();
            List<NSP_Focus_Item__c> rapidGrowthOrDeclineList = new List<NSP_Focus_Item__c>();
            Set<Id> focusItemIdSet = new Set<Id>();
            Id woRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
            for(NSP_Focus_Item__c focusItems : newList){
            	focusItemIdSet.add(focusItems.Id);
            }
            
            if(!focusItemIdSet.isEmpty() && woRecordTypeId != null ){
                for(NSP_Focus_Item__c focusItems : [SELECT Id, NSP_Detail__c, NSP_Asset__r.AccountId, NSP_Asset__r.NSP_Client__c, 
                                                    NSP_Asset__c, NSP_Asset__r.RecordTypeId, NSP_Asset__r.NSP_Account_Status__c, 
                                                    Focus_Item__c, NSP_Account_Group__r.NSP_Type__c, Details__c 
                                                    FROM NSP_Focus_Item__c 
                                                    WHERE Id IN : focusItemIdSet
                                                    AND NSP_Asset__r.RecordTypeId =: woRecordTypeId
                                                    AND NSP_Is_Duplicate__c = false
                                                    AND NSP_Asset__r.NSP_Account_Status__c =: NSP_ServiceConstants.AIMS_STATUS
                                                    AND (NSP_Account_Group__r.NSP_Type__c =: NSP_ServiceConstants.ACCOUNT_HEALTH 
                                                    OR NSP_Account_Group__r.NSP_Type__c =: NSP_ServiceConstants.RENEWAL_PROBABILITY)]){
    
                    if(focusItems.Focus_Item__c == NSP_ServiceConstants.BUSINESS_RESTRUCTURE){
                        businessRestructureList.add(focusItems);
                    }
                      
                    if(focusItems.Focus_Item__c == NSP_ServiceConstants.FINANCIAL_RISK 
                       && focusItems.NSP_Detail__c == NSP_ServiceConstants.EXTENSIVE_SLALARY_REDUCTION){
                        extnsvSalaryReductionList.add(focusItems);
                    }
                    
                    if((focusItems.Focus_Item__c == NSP_ServiceConstants.ECONOMIC_SHIFTS 
                        || focusItems.Focus_Item__c == NSP_ServiceConstants.FINANCIAL_RISK)
                      	&& focusItems.NSP_Detail__c != NSP_ServiceConstants.EXTENSIVE_SLALARY_REDUCTION){
                        ecoShiftOrFinRiskList.add(focusItems);
                    }
                                                        
                    if(focusItems.Focus_Item__c == NSP_ServiceConstants.RISK_MITIGATION){
                        riskMitigationList.add(focusItems);
                    }
                                                        
                    if(focusItems.Focus_Item__c == NSP_ServiceConstants.RAPID_GROWTH_OR_DECLINE
                        && focusItems.NSP_Detail__c == NSP_ServiceConstants.DECLINING_20_PERCENT_OR_MORE){
                        rapidGrowthOrDeclineList.add(focusItems);
                    }                                    
                }
        	} 

            if(!businessRestructureList.isEmpty() && getCreditServiceQueueId() != null){
                createCaseAfterInsertOfFocusItem(businessRestructureList, getCreditServiceQueueId(), NSP_ServiceConstants.CRITICAL_BUSINESS_CHALLENGES);
            }
            
            if(!extnsvSalaryReductionList.isEmpty() && getCreditServiceQueueId() != null){
                createCaseAfterInsertOfFocusItem(extnsvSalaryReductionList, getCreditServiceQueueId(), NSP_ServiceConstants.EXTENSIVE_SLALARY_REDUCTION);
            }
            
            if(!ecoShiftOrFinRiskList.isEmpty() && getCreditServiceQueueId() != null){
                createCaseAfterInsertOfFocusItem(ecoShiftOrFinRiskList, getCreditServiceQueueId(), NSP_ServiceConstants.FINANCIAL_BUSINESS_CHALLENGES);
            }
            
            if(!riskMitigationList.isEmpty() && getCreditServiceQueueId() != null){
                createCaseAfterInsertOfFocusItem(riskMitigationList, getCreditServiceQueueId(), NSP_ServiceConstants.NOT_FOLLOWING_GUIDELINES);
            }
            
            if(!rapidGrowthOrDeclineList.isEmpty() && getCreditServiceQueueId() != null){
                createCaseAfterInsertOfFocusItem(rapidGrowthOrDeclineList, getCreditServiceQueueId(), NSP_ServiceConstants.HEADCOUNT_REDUCTION);
            }
        } catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException('NSP_FocusItemTriggerHelper','afterInsertDirector', exc.getMessage());
        }
    }

    /***********************************************************************
    * @MethodName : getCreditServiceQueueId
    * @Description: To get NSP_Credit_Services queue Id
    * @param      : NA
    * @Story      : STY-01437
    * @return     : Id                          
    **************************************************************************/
    private static Id getCreditServiceQueueId(){
        List<String> fields = new List<String>{'Id','DeveloperName','Type'};
        String query = new NSP_QueryBuilder('Group', fields)
                            .addFilter('DeveloperName', 'NSP_Credit_Services')
                            .addFilter('Type', 'Queue').build();
        Group fsCreditServiceQueue = Database.query(query);

        return fsCreditServiceQueue.Id;
    }

    /***********************************************************************
    * @MethodName : createCaseAfterInsertOfFocusItem
    * @Description: Iterates throught the list of new Account GroupMembers
    * @param      : List<NSP_Focus_Item__c> focusItemList, Id peoRecordTypeId
    * @Story      : STY-01437
    * @return     : void                          
    **************************************************************************/
    private static void createCaseAfterInsertOfFocusItem(List<NSP_Focus_Item__c> focusItemList, Id queueId, String subCategoryValue){
        
        try{
            List<Case> caseList = new List<Case>();
            Id peoRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Case',NSP_ServiceConstants.PEO);

            for(NSP_Focus_Item__c focusItemRec : focusItemList){
                if(peoRecordTypeId != null){
                    caseList.add(peoCaseFieldMapping(focusItemRec, peoRecordTypeId, queueId, subCategoryValue));
                }
            }

            if(!caseList.isEmpty()){
                Database.SaveResult[] insertCaseList = Database.insert(caseList,false);
                NSP_ErrorLogHandler.logSaveResultsException('NSP_FocusItemTriggerHelper', 'createCaseAfterInsertOfFocusItem:CaseInsert', insertCaseList);
            }
        }catch(Exception exc){
            NSP_ErrorLogHandler.logSaveException('NSP_FocusItemTriggerHelper', 'createCaseAfterInsertOfFocusItem', exc.getMessage());
        }
        
    }
    
    /***********************************************************************
    * @MethodName: peoCaseFieldMapping
    * @Description: This method will map the PEO type case field values 
    * @param : NSP_Focus_Item__c focusItemRec, Id peoRecordTypeId,
    * 		   Id queueId, String subCategoryValue
    * @Story : STY-01437
    * @return: case                          
    **************************************************************************/
    private static case peoCaseFieldMapping(NSP_Focus_Item__c focusItemRec, Id peoRecordTypeId, Id queueId, String subCategoryValue){
        Case caseObj = new Case();
        caseObj.RecordTypeId = peoRecordTypeId;
        caseObj.Subject = NSP_ServiceConstants.FOCUS_ITEM;
        caseObj.NSP_Category__c = NSP_ServiceConstants.CREDIT_SERVICES;
        caseObj.NSP_SubCategory__c = subCategoryValue;
        caseObj.Status = NSP_ServiceConstants.CASE_OPEN_STATUS;
        caseObj.NSP_Case_Sub_Status__c = NSP_ServiceConstants.UNASSIGNED;
        caseObj.Origin =  NSP_ServiceConstants.IMPACT_FOCUS_ITEM_ORIGIN;
        caseObj.Description = createDescriptionString(focusItemRec);
        caseObj.NSP_Due_Date__c = System.today().addDays(2);
        caseObj.AccountId = focusItemRec.NSP_Asset__r.AccountId;
        caseObj.AssetId = focusItemRec.NSP_Asset__c;
        caseObj.NSP_ClientNumber__c = focusItemRec.NSP_Asset__r.NSP_Client__c;
        caseObj.OwnerId = queueId;
        
        return caseObj;
    }
    
    /***********************************************************************
    * @MethodName : createDescriptionString
    * @Description: To create case description
    * @param      : NSP_Focus_Item__c focusItem
    * @Story      : STY-01437
    * @return     : String                          
    **************************************************************************/
    private static String createDescriptionString(NSP_Focus_Item__c focusItem){
        String description = '';
        
        if(String.isNotBlank(focusItem.Focus_Item__c)){
            description = focusItem.Focus_Item__c;
        }
        if(String.isNotBlank(focusItem.NSP_Detail__c)){
            description+= ' : '+focusItem.NSP_Detail__c;
        }
        if(String.isNotBlank(focusItem.Details__c)){
            description+= ' : '+focusItem.Details__c;
        }
        
        return description;
    }
  
        /***********************************************************************
    * @MethodName : checkAssetRelatedToAccount
    * @Description: To validate asset added is related to the account of the account group
    * @param      : List<NSP_Focus_Item__c>
    * @Story      : STY-03807
    * @return     : void                          
    **************************************************************************/
    private static void  checkAssetRelatedToAccount(List<NSP_Focus_Item__c> newList){
        List<ID>  accountGroupIDs = new  List<ID> ();
        List<ID> AssetIDs = new  List<ID>();
        Map<ID,ID> assetAccountIDs = new Map<ID,ID>();
        Map<ID,Set<ID>> accountGrpLstOfAccount = new  Map<ID,Set<ID>>();
        // Get list of asset and account groups
        for(NSP_Focus_Item__c focusItem:newList){
            if(focusItem.NSP_Asset__c != null){
                assetIDs.add(focusItem.NSP_Asset__c); 
            }
            accountGroupIDs.add(focusItem.NSP_Account_Group__c);
        }
        // Get Map of Asset and Account ID linked to it
        for(Asset asst:[Select ID, accountID FROM Asset WHERE ID IN : AssetIDs]){
            assetAccountIDs.put(asst.ID, asst.accountID);
        }
        //Store account group and corresponding accounts in MAP<AccountID , Set<AssetID>>
        for(NSP_Account_Group_Member__c acctGroupMem:[Select ID,NSP_Group__c,NSP_Member_Account__c FROM NSP_Account_Group_Member__c WHERE NSP_Group__c  IN : accountGroupIDs ]){             
            Set<ID> accountIDs = new Set<ID>();
            // check if the accountgroup key already exist in the map
            if(accountGrpLstOfAccount.containskey(acctGroupMem.NSP_Group__c)){
                accountIDs = accountGrpLstOfAccount.get(acctGroupMem.NSP_Group__c);
            }
            accountIDs.add(acctGroupMem.NSP_Member_Account__c);
            accountGrpLstOfAccount.put(acctGroupMem.NSP_Group__c, accountIDs)  ;
        }
        // Loop through focus item record and validate if asset is linked to the account of account group
        for(NSP_Focus_Item__c focusItem:newList){
            if(focusItem.NSP_Asset__c != null){
                ID AssetAccount ;
                Set<ID> accountIDs = new Set<ID>();
                // get the account related to asset
                if(assetAccountIDs.containsKey(focusItem.NSP_Asset__c)){
                    AssetAccount =  assetAccountIDs.get(focusItem.NSP_Asset__c);   
                }
                // get the accounts related to account group
                if(accountGrpLstOfAccount.containsKey(focusItem.NSP_Account_Group__c)){
                    accountIDs =  accountGrpLstOfAccount.get(focusItem.NSP_Account_Group__c);
                }
                //check if the account from asset matches with any of the account IDs in the list
                if(!accountIDs.contains(AssetAccount) && !Test.isRunningTest()){
                    // throw an error if it doesn't match with any of the account IDs                   
                      focusItem.addError(System.Label.NSP_SelectRelatedAsset) ;                                                       
                }
            }
        }
    }
}