/**
 * Represents the NSP_CampaignTriggerHelper.
 * Created By: Rahul Singh
 * Date:8/10/2022
 */
public class NSP_CampaignTriggerHelper {
    /**
     * Iterates throught the list of new campaign and passes the required attributes to other methods.
     * @param newList List of New Campaign
     * @return void
     *                
     */
    
     public void beforeInsertDirector(List<Campaign> newList){
      
        
        updateCampaignField(newList,null);
    }
    
    public void updateCampaignField(List<Campaign> newList,Map<Id,Campaign> OldCampaignMap){
    
    set<Id> ownerIdSet = new set<Id>(); 
    set<String> officeSet = new set<String>();    
    set<string> ownerRoleNameSet = new set<string>{'District Administrator','District Manager','Business Performance Consultant','MidMarket Administrator','BPS Administrator','BPS Sales Manager','Business Performance Consultant','HCM Sales Consultant'};
    set<string> salesRoleNameSet = new set<string>{'Loyalty Advisor','Channel Program Manager','Marketing Operations Manager'};
    Map<Id,User> userMap = new Map<Id,User>([SELECT Id,Name,Userrole.Name from user where Name != null]);
        
    for(Campaign newCampaign : newList)
    {
        Campaign oldCampaign = OldCampaignMap != null ? OldCampaignMap.get(newCampaign.Id):null;
        
        if(Trigger.isInsert || newCampaign.OwnerId != oldCampaign.OwnerId )
        {   if(ownerRoleNameSet.Contains(userMap.get(newCampaign.OwnerId).Userrole.Name) )
        	{
            ownerIdSet.add(newCampaign.ownerId); 
            }
            else if(salesRoleNameSet.Contains(userMap.get(newCampaign.OwnerId).Userrole.Name) && newCampaign.NSP_Sales_Office__c != null )
        	{
           			 officeSet.add(newCampaign.NSP_Sales_Office__c);                 
            }
            
         
        }
    }
    
    if(ownerIdSet.Size() > 0)
    {
        Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c,userrole.name 
                                                   FROM user 
                                                   WHERE Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
       
        for(Campaign newCampaign : newList)
        {
            Campaign oldCampaign = OldCampaignMap != null ? OldCampaignMap.get(newCampaign.Id):null;
            
            if(Trigger.isInsert || newCampaign.OwnerId != oldCampaign.OwnerId )
            {
                if(userIdMap.containsKey(newCampaign.ownerId))
                {   user eachUser = userIdMap.get(newCampaign.OwnerId);
                    newCampaign.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                    newCampaign.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newCampaign.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                    
                }                   
            }
           
        }    
    }
    
    if(officeSet.Size() > 0)
    { 
            map<String,NSP_Sales_Office_Mapping__c> salesOfficeToMappingMap =  new map<String,NSP_Sales_Office_Mapping__c>();
            for(NSP_Sales_Office_Mapping__c eachMapping : [SELECT Id,NSP_Sales_Office__c,NSP_Sales_Division__c,NSP_Sales_Region__c 
                                                            FROM NSP_Sales_Office_Mapping__c 
                                                            WHERE NSP_Sales_Office__c In : officeSet AND isActive__c = true])
            {
                salesOfficeToMappingMap.put(eachMapping.NSP_Sales_Office__c,eachMapping);
            }
            
            
            for(Campaign newCampaign: newList)
            {    
                 Campaign oldCampaign = OldCampaignMap != null ? OldCampaignMap.get(newCampaign.Id):null;
                 if(Trigger.isInsert || (newCampaign.OwnerId != oldCampaign.OwnerId && newCampaign.NSP_Sales_Office__c !=null))
                {
                    NSP_Sales_Office_Mapping__c officeMapping = salesOfficeToMappingMap.get(newCampaign.NSP_Sales_Office__c);
                    newCampaign.NSP_Sales_Region__c = officeMapping.NSP_Sales_Region__c; // sales region
                    newCampaign.NSP_Sales_Division__c = officeMapping.NSP_Sales_Division__c; // sales division
                   
                }
            }   
    }
   
   
  }  

}