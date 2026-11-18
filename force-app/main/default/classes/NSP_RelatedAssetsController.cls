/**
* Represents the NSP_RelatedAssetsController for RelatedAssets logic email Templates.
*/
public with sharing class NSP_RelatedAssetsController {
    // test w/ NSP_RelatedAssetsController_Test (100%)

    public static String recId;
    public static String state;
    public static  NSP_RelatedAssetsWrapper ipWrapper{get; set;}
    public static List<String> empWrapperList {get; set;} 
    public static List<String> garnishmentEmpList {get; set;}
    public static List<String> leviesEmpList {get; set;} 
    private static Id woAssetId = SObjectType.Asset.getRecordTypeInfosByDeveloperName().get(NSP_ServiceConstants.WO_ASSET_RECORDTYPE).getRecordTypeId();
    
    //set recordId
    public static void setrecId (String recordId) {
        recId = recordId;
        getFSOEmail();
        visaEmpData(recId);
        garnishmentEmpData(recId);
        leviesEmpData(recId);
        
    }
    //get recordId
    public static String getrecId() {
        return recId;
    } 
    
    //set recordId
    public static void setState (String states) {
        state = states;
    }
    //get recordId
    public static String getState() {
        return state;
    }
    
    //get Related IP AccountId
    public static String accountId {
        get{
            if ( recId != null ){
                accountId = [SELECT 
                             Id, Account__c
                             FROM Implementation_Profile__c
                             WHERE Id = : recId].Account__c;
            }
            return accountId;
        }
        set;
    }
    
    public static List<Asset> relatedAssets {
        get{
            if ( accountId != null ){
                List<Asset> local = [SELECT Id, 
                                 AccountId, 
                                 NSP_Client__c, 
                                 NSP_Company_Name__c 
                                 FROM Asset 
                                 WHERE AccountId =: accountId 
                                 AND RecordTypeId =: woAssetId ];
                relatedAssets = local;
            }
            return relatedAssets;
        }
        set;
    }
    
    public static List<String> regulatedAreaStates{
        get{
            List<String> lstStates = new List<String>();
            List<String> ipStateList =  state?.split(';');
            if ( ipStateList != null ){
                for(NSP_Regulated_Area__c regArea :[SELECT Id, 
                                                    NSP_State__c
                                                    FROM NSP_Regulated_Area__c 
                                                    WHERE NSP_Regulation_Type__c =: NSP_ServiceConstants.STATE_RET_PLAN
                                                    AND NSP_State__c IN: ipStateList]){
                                                        if(string.isNotBlank(regArea.NSP_State__c)){
                                                            lstStates.add(regArea.NSP_State__c);
                                                        }
                                                    }
            }
            return lstStates;
        }
        set;
    }
    
    public static List<NSP_IP_Related_Client__c> ipRelatedClients {
        get{
            if ( recId != null ){
                List<NSP_IP_Related_Client__c> local = [SELECT Id, 
                                    NSP_Implementation_Profile__c, 
                                    NSP_Implementation_Profile__r.Client_Profile_Information__c,
                                    NSP_Related_Client__r.Name
                                    FROM NSP_IP_Related_Client__c 
                                    WHERE NSP_Implementation_Profile__c =: recId AND
                                    NSP_Related_Client__c!=null AND 
                                    NSP_Implementation_Profile__r.Client_Profile_Information__c INCLUDES ('Related Clients')];
                ipRelatedClients = local;
            }
            return ipRelatedClients;
        }
        set;
    }
    
    public static NSP_RelatedAssetsWrapper getFSOEmail(){
        NSP_RelatedAssetsWrapper iWrap = new NSP_RelatedAssetsWrapper();
        if ( recId != null ){
            for( Implementation_Profile__c imp : [SELECT Id, First_Pay_Date__c, 
                                                  Num_of_Worksite_Employees_Full_Time__c,
                                                  Num_of_Worksite_Employees_Part_Time__c,
                                                  Num_of_Worksite_Employees_Seasonal__c             
                                                  FROM Implementation_Profile__c 
                                                  WHERE Id =:recId ]){
                                                      if(imp.First_Pay_Date__c!=null){
                                                          datetime fpayDate= Date.Valueof(imp.First_Pay_Date__c); 
                                                          iWrap.firstPayDate = fpayDate.formatGMT('MM/dd/YYYY');
                                                      }
                                                      if(imp.Num_of_Worksite_Employees_Full_Time__c!=null){
                                                          iWrap.fullTimeEmpCount = Integer.valueOf(imp.Num_of_Worksite_Employees_Full_Time__c);
                                                      }
                                                      if(imp.Num_of_Worksite_Employees_Part_Time__c!=null){
                                                          iWrap.partTimeEmpCount = Integer.valueOf(imp.Num_of_Worksite_Employees_Part_Time__c);
                                                      }
                                                      if(imp.Num_of_Worksite_Employees_Seasonal__c!=null){
                                                          iWrap.seasonalTimeEmpCount = Integer.valueOf(imp.Num_of_Worksite_Employees_Seasonal__c);
                                                      }
                                                  }
            ipWrapper=iWrap;
        }
        return ipWrapper;
    }
    
    public static void visaEmpData(String recId){
        empWrapperList = new List<String>();
        if ( recId != null ){
            for( Implementation_Profile__c imp : [SELECT Id ,NSP_EE_Name__c ,Client_have_any_EEs_on_F1_or_J1_Visa_s__c FROM Implementation_Profile__c 
                                                  WHERE Id =:recId AND Client_have_any_EEs_on_F1_or_J1_Visa_s__c =: NSP_ServiceConstants.YES]){
                                                      if(imp.NSP_EE_Name__c!=Null){  
                                                          for(String empData:imp.NSP_EE_Name__c.Split(',') ){ 
                                                              empWrapperList.add(empData.replace('~', ', '));  
                                                          }                                        
                                                      }  
                                                  }  
        }
    } 
    public static void garnishmentEmpData(String recId){
        garnishmentEmpList = new List<String>();
        if ( recId != null ){
            for( Implementation_Profile__c imp : [SELECT Id ,NSP_Employee_Names_List_garnishments__c,Do_any_EEs_have_garnishments__c FROM Implementation_Profile__c 
                                                  WHERE Id =:recId AND Do_any_EEs_have_garnishments__c  =: NSP_ServiceConstants.YES]){
                                                      if(imp.NSP_Employee_Names_List_garnishments__c!=null){
                                                          for(String empData:imp.NSP_Employee_Names_List_garnishments__c.Split(',') ){ 
                                                              garnishmentEmpList.add(empData);  
                                                          }   
                                                      }     
                                                  }   
        }
    }
    public static void leviesEmpData(String recId){
        leviesEmpList = new List<String>();
        if ( recId != null ){
            for( Implementation_Profile__c imp : [SELECT Id ,NSP_List_Employee_Names_Levies__c,Do_any_EEs_have_tax_levies__c FROM Implementation_Profile__c 
                                                  WHERE Id =:recId AND Do_any_EEs_have_tax_levies__c  =: NSP_ServiceConstants.YES]){
                                                      if(imp.NSP_List_Employee_Names_Levies__c!=null){
                                                          for(String empData:imp.NSP_List_Employee_Names_Levies__c.Split(',') ){ 
                                                              leviesEmpList.add(empData);  
                                                          }   
                                                      }     
                                                  }   
        }
    } 
    public class NSP_RelatedAssetsWrapper{
        public String  firstPayDate {get; set;}
        public Integer fullTimeEmpCount {get; set;}    
        public Integer partTimeEmpCount {get; set;}    
        public Integer seasonalTimeEmpCount {get; set;}    
    }   
}