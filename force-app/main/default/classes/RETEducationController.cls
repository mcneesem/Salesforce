/******************************************************************************
 * Class Name:      RETEducationController
 * Author:          Ramya Ravi
 * Sprint :         Service_Sprint22
 * Description:     Controller class for RET Education tab in RET Asset layout
 * Date Created:    08-Sept-2022 
 * Version :        1.0
 * Story:           STY-03274
 * Version           Author         Story       Description                                         Tag
 * V2                Ramya Ravi    STY-03528    WX & RET Asset - View Account Team data             <STY-03528>
 ********************************************************************************/

 global with sharing  class RETEducationController {

    // Method to query all the RET education records related to Asset    
    @AuraEnabled(Cacheable = true)
    public static AssetRETEducationAssociation__c getRETEducationOverview(string recordID){
        try{
            List<AssetRETEducationAssociation__c> RETEd= [select id, createdDate, name,  NSP_AIMs__c,NSP_Subplan__c,NSP_Status__c,
                                                          NSP_Language_Needs__c, NSP_Education_Client__c, NSP_Name__c
                                                          from AssetRETEducationAssociation__c WHERE NSP_Education_Client__c = : recordID order by createdDate asc];
            if(RETEd.size()>=1) {
                return RETEd[0];        
            }       
            
            else {
                return null;
            }
        } catch (Exception ex) {
            throw NSP_Utilities.getAuraException(ex);
        }
            
    }  
    
      // Method to query all the RET education records with Collateral educator details related to Asset
      @AuraEnabled
      public static void updateRETRecords(AssetRETEducationAssociation__c RETEducation){
          try{
              List<AssetRETEducationAssociation__c> RETEdList = [SELECT id, createdDate, name,  NSP_AIMs__c,NSP_Subplan__c,NSP_Status__c,
                                                                 NSP_Language_Needs__c, NSP_Education_Client__c, NSP_Name__c
                                                                 FROM AssetRETEducationAssociation__c WHERE NSP_Education_Client__c =: RETEducation.NSP_Education_Client__c];
              List<AssetRETEducationAssociation__c> RETEdListToUpdate = new List<AssetRETEducationAssociation__c>();
              for(AssetRETEducationAssociation__c lst:RETEdList){
                  if(lst.NSP_Name__c != RETEducation.NSP_Name__c ||
                     lst.NSP_Subplan__c != RETEducation.NSP_Subplan__c ||
                     lst.NSP_Language_Needs__c != RETEducation.NSP_Language_Needs__c ||                 
                     lst.NSP_Status__c != RETEducation.NSP_Status__c
                    ){
                        AssetRETEducationAssociation__c newRETEd = new AssetRETEducationAssociation__c();
                        newRETEd.id = lst.id;
                        newRETEd.NSP_Name__c = RETEducation.NSP_Name__c;
                        newRETEd.NSP_Subplan__c = RETEducation.NSP_Subplan__c;
                        newRETEd.NSP_Language_Needs__c = RETEducation.NSP_Language_Needs__c;
                        newRETEd.NSP_Status__c = RETEducation.NSP_Status__c;
                        RETEdListToUpdate.add(newRETEd);
                    }
              }
              
              if(!RETEdListToUpdate.isEmpty()){
                  Database.update(RETEdListToUpdate, false);           
              }
          } catch (Exception ex) {
              throw NSP_Utilities.getAuraException(ex);
          }
               
    } 
    //Get account team members with roles 
    //<STY-03528> Changes
     @AuraEnabled(Cacheable = true)
     public static  Map<String, String> getAccountTeam(string recordID){
         try{
             Map<String, String> nameRoleList = new  Map<String, String>();   
             // Get all account team roles for WX asset from custom label
             List<string> accountTeamRolesForWXAsset = System.Label.NSP_ACCOUNTTEAM_ROLES_WXASSET.split(',');
             
             //Get Asset record types 
             ID WXAssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WX_WA);
             ID RET_CHOICE_AssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.RET_CHOICE_ASSET_RECORDTYPE);
             ID RET_WO_AssetRecordTypeId = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.RET_WO_ASSET_RECORDTYPE);
             
             // Get account and record type for the current asset
             List<Asset> assetLst=[Select id, accountId, recordTypeId from Asset WHERE Id = : recordId limit 1];
             
             // FOR RET CHOIE AND RET WO ASSET -> get account team data
             if(assetLst[0].recordTypeId == RET_CHOICE_AssetRecordTypeId || 
                assetLst[0].recordTypeId == RET_WO_AssetRecordTypeId){
                    //get list of AccountContactRelation and store it as Contact name, Roles
                    for(AccountContactRelation lst: [select id, NSP_Owner__c , Roles, Contact.name ,  NSP_Service_Roles__c, NSP_Support_Role__c
                                                     from AccountContactRelation 
                                                     WHERE AccountID = : assetLst[0].accountId and NSP_Owner__c = true]){
                                                         nameRoleList.put(lst.Contact.name,lst.NSP_Service_Roles__c) ;
                                                     }
                    //get list of NSP_Account_Team__c and store it as User name, Roles
                    for(NSP_Account_Team__c lst:[select id, NSP_Account__c, NSP_Role__c, NSP_User__r.name 
                                                 from NSP_Account_Team__c 
                                                 WHERE NSP_Account__c =: assetLst[0].accountId    ]){                                                                 
                                                     nameRoleList.put(lst.NSP_User__r.name, lst.NSP_Role__c)  ;
                                                 }  
                }
             
             //FOR WX ASSET -> get account team data
             if(assetLst[0].recordTypeId == WXAssetRecordTypeId){
                 //get list of NSP_Account_Team__c and store it as User name, Roles
                 for(NSP_Account_Team__c lst:[select id, NSP_Account__c, NSP_Role__c, NSP_User__r.name 
                                              from NSP_Account_Team__c 
                                              WHERE NSP_Account__c =: assetLst[0].accountId  and NSP_Role__c in : accountTeamRolesForWXAsset]){                                                                                                     
                                                  nameRoleList.put(lst.NSP_User__r.name, lst.NSP_Role__c)  ;
                                              }  
             } 
             
             return nameRoleList;
             
         } catch (Exception ex) {
             throw NSP_Utilities.getAuraException(ex);
         }
	}
     
 }