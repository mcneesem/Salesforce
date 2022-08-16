/**
* Represents Batch class to keep the sales office details on user synced with sales office mapping.
*/

global class NSP_SyncSalesOfficeDetailsOnUserBatch implements Database.Batchable<sobject>,schedulable {
    /**
* Represents execute method of the schedulable Interface
* @param Database.SchedulableContext SC
* @return N/A
*
*/
    global void execute(SchedulableContext SC) {
        NSP_SyncSalesOfficeDetailsOnUserBatch bch = new NSP_SyncSalesOfficeDetailsOnUserBatch();
        if(Test.isRunningTest())
        {
          Database.executeBatch(bch,2000);  
        }
        else{
            Database.executeBatch(bch,20);
        }
        
    }
    
    /*
* Query Active user that have sales office value set on them.
*/
    global Database.QueryLocator start(Database.BatchableContext BC){
        return database.getQueryLocator([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c 
                                         FROM User where NSP_Sales_Office__c != null AND isActive = true]);
        
    }
    
    /**
* Represents execute method of the Batch Interface.The main logic is here.
* @param Database.BatchableContext bc
* @param List<User> scope
* @return N/A
*
*/
    
    global void execute(Database.BatchableContext BC,list<User> scope)
    {
        set<string> salesOfficeSet = new set<string>();
        for(User eachuser : scope)
        {
            salesOfficeSet.add(eachuser.NSP_Sales_Office__c); // add to set
        }
        
        if(salesOfficeSet.Size() > 0)
        {
            list<User> userUpdateList = new list<User>();
            map<String,NSP_Sales_Office_Mapping__c> salesOfficeToMappingMap =  new map<String,NSP_Sales_Office_Mapping__c>();
            // query NSP_Sales_Office_Mapping__c to create Map
            for(NSP_Sales_Office_Mapping__c eachMapping : [SELECT Id,NSP_Sales_Office__c,NSP_Sales_Division__c,NSP_Sales_Region__c 
                                                           FROM NSP_Sales_Office_Mapping__c 
                                                           WHERE NSP_Sales_Office__c In : salesOfficeSet AND isActive__c = true])
            {
                salesOfficeToMappingMap.put(eachMapping.NSP_Sales_Office__c,eachMapping);
            }
            
            
            for(User eachuser : scope)
            {
                boolean valueassigned = false;
                if(salesOfficeToMappingMap.containsKey(eachuser.NSP_Sales_Office__c))
                {
                    NSP_Sales_Office_Mapping__c officeMapping = salesOfficeToMappingMap.get(eachuser.NSP_Sales_Office__c); // get value from map
                    
                    if(eachuser.NSP_SalesDivision__c != officeMapping.NSP_Sales_Division__c) // check if value is different
                    {
                        eachuser.NSP_SalesDivision__c = officeMapping.NSP_Sales_Division__c;// set value
                        valueassigned = true;
                    }
                    
                    if(eachuser.NSP_SalesRegion__c != officeMapping.NSP_Sales_Region__c) // check if value is different
                    {
                        eachuser.NSP_SalesRegion__c = officeMapping.NSP_Sales_Region__c; // set value
                        valueassigned = true;
                    }
                    
                    if(valueassigned)
                    {
                        userUpdateList.add(eachuser);  // add to list
                    }
                }     
                
            }
            
            if(userUpdateList.Size() > 0)
                {
                     Database.update(userUpdateList,false); // update user list
                }
        }    
    }
    
    /**
* Represents Finish method of the Batch Interface.
* @param Database.BatchableContext bc
* @return N/A
*/
    global void finish(Database.BatchableContext BC)
    {
        
    }                        
    
    
}