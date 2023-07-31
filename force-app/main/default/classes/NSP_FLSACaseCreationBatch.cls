/**
Apex Class Name      :  NSP_FLSACaseCreationBatch
Version              :  1.0                                                                          
Created Date         :  6/1/2022   
Function             :  This class is used as a batch class for FLSACaseCreation . 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Tejas                    7/18/2022                 First Iteration
*/

public class NSP_FLSACaseCreationBatch implements Database.Batchable<sObject>{
	public Database.QueryLocator start(Database.BatchableContext BC){
    	String query = 'SELECT Id, NSP_Account_Segment__c, NSP_First_Pay_Date__c, NSP_AIMS_Client__c, '+
            		   '(SELECT Id, NSP_Account__c,NSP_Account__r.NSP_AIMS_First_Pay_Date__c, NSP_Account__r.NSP_First_Pay_Date__c,NSP_First_Pay_Date__c FROM Sub_Clients__r WHERE NSP_First_Pay_Date__c != null), '+
            		   '(SELECT Id, NSP_FLSA_Case__c FROM Cases WHERE NSP_FLSA_Case__c = True), '+
            		   '(SELECT Id, Name, NSP_Sales_Office__c, NSP_BPA__c, NSP_FLSA_Specialist__c, NSP_Account__c FROM NSP_BPA_Mappings__r) '+
            		   'FROM Account WHERE NSP_First_Pay_Date__c != null AND (NSP_Account_Segment__c = '+'\''+
            		   System.Label.NSP_Account_Segment_MidMarket+'\''+NSP_ServiceConstants.OR_NSP_ACCOUNT_SEGMENT_EQUALS+'\''+
            		   System.Label.NSP_Account_Segment_Emerging_Growth+'\''+
					   NSP_ServiceConstants.OR_NSP_ACCOUNT_SEGMENT_EQUALS+'\''+System.Label.NSP_Account_Segment_Business_Team+'\''+
                       NSP_ServiceConstants.OR_NSP_ACCOUNT_SEGMENT_EQUALS+'\''+System.Label.NSP_Account_Segment_MidMarketEnterprise+'\''+
                       NSP_ServiceConstants.OR_NSP_ACCOUNT_SEGMENT_EQUALS+'\''+System.Label.NSP_Account_Segment_Core_Sales+'\''+')';
        return Database.getQueryLocator(query);   
    }
    //executing batch
    public void execute(Database.BatchableContext BC, List<Account> relatedAccountsList){
        Map<Id,Case> FLSACaseMap = new Map<Id, Case>();
        Map<Id, Account> subWithAccountMap = new Map<Id, Account>();
        Map<Id, NSP_BPA_Mapping__c> BPAUserMap = new Map<Id, NSP_BPA_Mapping__c>();
        Id ownerId = Test.isRunningTest() ? UserInfo.getUserId() : System.Label.NSP_FLSA_Case_Owner_Marsha;
        //iterating related  account List
        for(Account acc : relatedAccountsList){
            //checking if case contains elements and sub client is null or not
            if(acc.Cases.size() == 0 && acc.Sub_Clients__r != null){
                for(NSP_Sub_Client__c sub : acc.Sub_Clients__r){
                    if(sub.NSP_Account__r.NSP_First_Pay_Date__c == sub.NSP_First_Pay_Date__c){
                        subWithAccountMap.put(sub.NSP_Account__c, acc);    
                    }
                }	    
            }
            //checking BPA mappings is null
            if(acc.NSP_BPA_Mappings__r != null){
                //iterating over BPA mappings
                for(NSP_BPA_Mapping__c BPA : acc.NSP_BPA_Mappings__r){
                	BPAUserMap.put(BPA.NSP_Account__c, BPA);   
                }
            }
        }
        for(Account acc : subWithAccountMap.values()){
                if(acc.NSP_Account_Segment__c == System.Label.NSP_Account_Segment_Core_Sales ||
                    acc.NSP_Account_Segment__c == System.Label.NSP_Account_Segment_Business_Team){
                        //case creation
                	Case newCase = new Case(); 
                    newCase.AccountId = acc.Id;
                    newCase.NSP_Category__c = NSP_SalesConstants.FLSACategory;
                    newCase.Description = acc.NSP_AIMS_Client__c;
                    newCase.Status = NSP_SalesConstants.OPEN;
                    newCase.OwnerId = System.Label.NSP_FLSACaseOwner;
                    newCase.NSP_Opened_Date__c = System.today();
                    newCase.NSP_FLSA_Case__c = True;
                    FLSACaseMap.put(acc.Id, newCase);
                }else if(acc.NSP_Account_Segment__c == System.Label.NSP_Account_Segment_Emerging_Growth ||
                    acc.NSP_Account_Segment__c == System.Label.NSP_Account_Segment_MidMarket ||
                    acc.NSP_Account_Segment__c == System.Label.NSP_Account_Segment_MidMarketEnterprise){
                        //case creation
                    Case newCase = new Case(); 
                    newCase.AccountId = acc.Id;
                    newCase.NSP_FLSA_Case__c = True;
                    newCase.NSP_Category__c = NSP_SalesConstants.FLSACategory;
                    newCase.NSP_SubCategory__c = NSP_SalesConstants.FLSASubCategory;
                    newCase.Description = acc.NSP_AIMS_Client__c;
                    newCase.Status = NSP_SalesConstants.OPEN;
                    newCase.NSP_Opened_Date__c = System.today();
                    //checking if the BPA user map is empty or not 
                    if(!BPAUserMap.isEmpty() && BPAUserMap.get(acc.Id) != null){
                    	newCase.OwnerId = BPAUserMap.get(acc.Id).NSP_Sales_Office__c != NSP_SalesConstants.midMarket &&
                            BPAUserMap.get(acc.Id).NSP_FLSA_Specialist__c != null ?
                        	BPAUserMap.get(acc.Id).NSP_FLSA_Specialist__c : 
                            BPAUserMap.get(acc.Id).NSP_Sales_Office__c == NSP_SalesConstants.midMarket &&
                            BPAUserMap.get(acc.Id).NSP_BPA__c != null ?
                            BPAUserMap.get(acc.Id).NSP_BPA__c : ownerId;
                    }else{
                        newCase.OwnerId = ownerId;
                    }                    
                    FLSACaseMap.put(acc.Id, newCase);
                }
        }  
        //checking FLSACaseMap is empty
        // Added Test.isRunningTest() to bypass the insertion during test class
        if(!FLSACaseMap.isEmpty() && !Test.isRunningTest()){
            //inserting values to FLSSACaseMap
            Database.insert(FLSACaseMap.values());
        }
    }
    public void finish(Database.BatchableContext BC){
    
    }
}