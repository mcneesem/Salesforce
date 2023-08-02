/**
* @description  :  Controller Class for Account Group Member Related Cases for Account Group
* Author : Simran Thukral
* Name : NSP_AccountGroupMemberController
*/
public with sharing class NSP_AccountGroupMemberController {

   @AuraEnabled(cacheable=true)
   /***********************************************************************************************
    * MethodName: fetchAccountGroupMemberRecords
    * Description : To display fetch data of Account Group Member associated wih Account Group
    * Params:    String accountGroupId 
    * Author :      Simran Thukral
    *************************************************************************/
   public static Map<String, List<NSP_Account_Group_Member__c>> fetchAccountGroupMemberRecords(String accountGroupId){
      String OBJECT_NAME = 'NSP_Account_Group__c';
      List<String> FIELDS = new List<String>{'Id', 'NSP_Type__c'}; 
      List<String> COLUMNSFIELDS = new List<String>();
      //Mapping the Type and List of Account Group Members
      Map<String, List<NSP_Account_Group_Member__c>> mapOfAccgroupMemRecord = new Map<String, List<NSP_Account_Group_Member__c>>();
      //Quering on Account Group with specific Id
      NSP_Account_Group__c accGroupRecord = (NSP_Account_Group__c) new NSP_sObjectSelector(OBJECT_NAME,FIELDS).selectById(accountGroupId);
      if(accGroupRecord.NSP_Type__c != NSP_ServiceConstants.TYPECONTROLLEDGROUP){
            COLUMNSFIELDS.add('Id') ;
            COLUMNSFIELDS.add('Name') ;
            COLUMNSFIELDS.add('NSP_AIMS_Client_ID__c') ;
            COLUMNSFIELDS.add('NSP_Primary__c') ;
            COLUMNSFIELDS.add('NSP_Type__c') ;
            COLUMNSFIELDS.add('NSP_Payroll_Employees__c') ;
            COLUMNSFIELDS.add('NSP_Account_Name__c') ;
            COLUMNSFIELDS.add('NSP_Member_Account__c') ;
         
      }else{
         COLUMNSFIELDS.add('Id') ;
         COLUMNSFIELDS.add('NSP_Account_Name__c') ;
         COLUMNSFIELDS.add('NSP_AIMS_Client_ID__c') ;
         COLUMNSFIELDS.add('NSP_Insperity_Client__c') ;
         COLUMNSFIELDS.add('NSP_Enter_Date__c') ;
         COLUMNSFIELDS.add('NSP_Hicomp_EEs__c') ;
         COLUMNSFIELDS.add('NSP_Total_EEs__c') ;
         COLUMNSFIELDS.add('NSP_Member_Account__c') ;
         COLUMNSFIELDS.add('NSP_Type__c') ;
      }
      Integer recordSize = 10;
      //Returning the List of Account Group Members associated with particular Account Group Records
      String query = new NSP_QueryBuilder('NSP_Account_Group_Member__c', COLUMNSFIELDS).addFilter('NSP_Group__c', accountGroupId).addLimit(recordSize).build();
      List<NSP_Account_Group_Member__c> accGroupMember = (List<NSP_Account_Group_Member__c>) Database.query(query);
      mapOfAccgroupMemRecord.put(accGroupRecord.NSP_Type__c, accGroupMember);
      return mapOfAccgroupMemRecord;

   }

   /***********************************************************************
    * @MethodName : createSelfGroup
    * @Description: This method will delete existing Account Group member and will create self group
    * @param      : String accountGrpMember, String accountId, String nspType, String accName
    * @Story      : STY-04139
    * @return     : void                          
    **************************************************************************/
    @AuraEnabled
    public static void createSelfGroup(String accountGrpMember, String accountId, String nspType, String accName) {
         
      //check WO Asset for Growth Forecast
      Boolean hasAccountWO = false;        
      Id wORecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE);
		Set<NSP_Account_Group__c> lstAccGroups = new Set<NSP_Account_Group__c>();
		List<NSP_Account_Group_Member__c> lstAccGroupMembrs = new List<NSP_Account_Group_Member__c>();
        
        if(nspType == NSP_ServiceConstants.GROWTH_FORECAST && accountId != null) {
            String assetQuery = new NSP_QueryBuilder('Asset', new List<String>{'Id', 'Name', 'recordtypeId'})
                                .addFilter('AccountId', accountId).build();
            List<Asset> assetList = (List<Asset>) Database.query(assetQuery);            
            for (Asset asset : assetList) {
                if(asset.recordtypeId == wORecordTypeId) {
                    hasAccountWO = true;
                    break;
                }
            }       
        }
        if(accountGrpMember == null || (!hasAccountWO && nspType == NSP_ServiceConstants.GROWTH_FORECAST)) {
            return;
        } else {
            String accGroupQuery = new NSP_QueryBuilder('NSP_Account_Group_Member__c', new List<String>{'Id', 'NSP_ByPassValidation__c'})
                                .addFilter('Id', accountGrpMember).build();
            NSP_Account_Group_Member__c groupRecord  =  (NSP_Account_Group_Member__c)Database.query(accGroupQuery);            
            groupRecord.NSP_ByPassValidation__c = true;
            update groupRecord;
            delete groupRecord;
        }
          
        Id autoCreatedRecordTypeId = NSP_GenericRecordType.getRecordTypeId('NSP_Account_Group__c',NSP_ServiceConstants.AUTOMATICALLY_CREATED);         
        if(nspType == NSP_ServiceConstants.GROWTH_FORECAST && hasAccountWO) {
                lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.GROWTH_FORECAST, 
                                                          NSP_Account__c = accName, 
                                                          NSP_Type__c = NSP_ServiceConstants.GROWTH_FORECAST));                
        }else if(nspType == NSP_ServiceConstants.RENEWAL_PROBABILITY) {
                lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.RENEWAL_PROBABILITY, 
                                                          NSP_Account__c = accName, 
                                                          NSP_Type__c = NSP_ServiceConstants.RENEWAL_PROBABILITY));                
        }else if(nspType == NSP_ServiceConstants.ACCOUNT_HEALTH) {
                lstAccGroups.add(new NSP_Account_Group__c(RecordTypeId = autoCreatedRecordTypeId, Name = NSP_ServiceConstants.ACCOUNT_HEALTH, 
                                                          NSP_Account__c =  accName, 
                                                          NSP_Type__c = NSP_ServiceConstants.ACCOUNT_HEALTH));              
        }
            
        //Establish New Relation for Created/Existing Groups with Account Group Member
       	if(!lstAccGroups.isEmpty()){ 
            List<NSP_Account_Group__c> lstAccGrps = new List<NSP_Account_Group__c>();
            lstAccGrps.addAll(lstAccGroups);
            Database.insert(lstAccGrps, false);
            
            for(NSP_Account_Group__c accGroup : lstAccGroups){
                 lstAccGroupMembrs.add(new NSP_Account_Group_Member__c(NSP_Member_Account__c = accountId, 
                                                                          NSP_Group__c = accGroup.Id, 
                                                                          NSP_Primary__c = true));
             }
        }
        if(!lstAccGroupMembrs.isEmpty()){
        	Database.Insert(lstAccGroupMembrs, false);
       	}
    }
    
    /***********************************************************************
    * @MethodName : isSelfAccountGroup
    * @Description: This method is used to verify self group for  Account Group Member using Primary check.
    * 				return true if Account Group Member is self group else return false
    * @param      : String groupMemberRecordId
    * @Story      : STY-04139
    * @return     : Boolean                          
    **************************************************************************/
    @AuraEnabled
    public static Boolean isSelfAccountGroup(String groupMemberRecordId) {
        
        //DF-05559 - Use primary field of Account Group member to identify the Self Account Group
        String accountQuery = new NSP_QueryBuilder('NSP_Account_Group_Member__c', new List<String>{'Id', 'NSP_Primary__c'})
                                .addFilter('Id', groupMemberRecordId).build();
        NSP_Account_Group_Member__c groupMemberRecord  =  (NSP_Account_Group_Member__c)Database.query(accountQuery);                
        return groupMemberRecord.NSP_Primary__c;
    }

}