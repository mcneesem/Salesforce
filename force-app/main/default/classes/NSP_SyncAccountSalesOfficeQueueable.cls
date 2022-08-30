/**
* Represents the queueanle class that updates account sales office
* details when user office details are updated
*/
public class NSP_SyncAccountSalesOfficeQueueable implements Queueable  {
	
    set<String> salesOfficeSet = new set<String>();
    set<Id> ownerIdSet = new set<Id>();
    public NSP_SyncAccountSalesOfficeQueueable(set<Id> userIdSet)
    {
        this.ownerIdSet = userIdSet;
    }
    public void execute(QueueableContext context) {
        // get account removed the asset condition
        list<Account> accountUpdateList = new list<Account>();
        for(Account eachAccount : [SELECT id,NSP_Sales_Office__c,NSP_SalesRegion__c,NSP_Sales_Division__c,Owner.NSP_Sales_Office__c ,Owner.NSP_SalesDivision__c,Owner.NSP_SalesRegion__c
                                  	FROM Account WHERE ownerId IN : ownerIdSet  ])
        {
            
               eachAccount.NSP_SalesRegion__c = eachAccount.Owner.NSP_SalesRegion__c;  // sales region
               eachAccount.NSP_Sales_Division__c = eachAccount.Owner.NSP_SalesDivision__c; // sales division
               eachAccount.NSP_Sales_Office__c = eachAccount.Owner.NSP_Sales_Office__c; // sales office
               accountUpdateList.add(eachAccount);
            
        }
        
        if(accountUpdateList.Size() > 0)
        {
            update accountUpdateList; // update account list
        }
    }
}