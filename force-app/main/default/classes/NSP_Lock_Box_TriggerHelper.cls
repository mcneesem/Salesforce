/**
* Represents the Lock Box trigger helper.
*/


public class NSP_Lock_Box_TriggerHelper {
    
    /**
* Iterates throught the list of new lock box records and passes the required attributes to other methods.
* @param newList List of New Lock Box Records.  
* @return void             
*                
*/
public void beforeInsertDirector(List<NSP_Lock_Box__c> newList){        
    
populateFieldValuesOnInsert(newList);
}


/**
* Iterates throught the list of new lock box records and populates field values before record insert.
* @param newList List of New Lock Box Records. 
* @return void             
*                
*/    
public void populateFieldValuesOnInsert (List<NSP_Lock_Box__c> newList) {
    
Map<String,Id> accountNameToIdMap = new Map<String,Id>();
Map<String,blng__Invoice__c> invoiceNumberToInvoiceMap = new Map<String,blng__Invoice__c>();
Set<String> accountNames = new Set<String>();
Set<String> invoiceNumbers = new Set<String>();

for (NSP_Lock_Box__c lb : newList ) {
    if(lb.NSP_Remitter_Name__c !=null ){
        accountNames.add(lb.NSP_Remitter_Name__c);
    }
    if(lb.NSP_Invoice_Number__c !=null) {
        invoiceNumbers.add(lb.NSP_Invoice_Number__c);
    }

}

for (Account acc : [SELECT Id, Name, AccountNumber FROM Account WHERE Name LIKE :accountNames]) {
    accountNameToIdMap.put(acc.Name, acc.Id);
}

for (blng__Invoice__c inv : [SELECT Id, Name, blng__Account__c,blng__InvoiceStatus__c,blng__Balance__c FROM blng__Invoice__c WHERE Name IN :  invoiceNumbers ]) {
    invoiceNumberToInvoiceMap.put(inv.Name, inv);
}

for (NSP_Lock_Box__c lb : newList ) {
    List<String> matchStatus = new List<String>();
    if(accountNameToIdMap.containsKey(lb.NSP_Remitter_Name__c)){
        lb.NSP_Account__c = accountNameToIdMap.get(lb.NSP_Remitter_Name__c);
    }
    if(invoiceNumberToInvoiceMap.containsKey(lb.NSP_Invoice_Number__c)){
        blng__Invoice__c matchedInv = invoiceNumberToInvoiceMap.get(lb.NSP_Invoice_Number__c);
        lb.NSP_Invoice__c = matchedInv.Id;
        matchStatus.add(NSP_BillingConstants.INVOICE_MATCH);
        if(lb.NSP_Account__c == matchedInv.blng__Account__c) {
            matchStatus.add(NSP_BillingConstants.ACCOUNT_MATCH);
        }
        if(lb.NSP_Check_Amount__c.round() == matchedInv.blng__Balance__c.round()){
            matchStatus.add(NSP_BillingConstants.ALLOCATION_MATCH);
        }

    }

    lb.NSP_Allocation_Amount__c = lb.NSP_Check_Amount__c;
    lb.NSP_Status__c = NSP_BillingConstants.PENDING;
    if(matchStatus.size()>0) {
        lb.NSP_Match_Status__c = String.join(matchStatus,';');
    }
}

}

/**
* Iterates throught the NSP_Lock_Box__c map and identifies the records that needs to worked based on various criterias.
* @param leadNewMap Map of New NSP_Lock_Box__c. 
* @param leadOldMap Map of Old NSP_Lock_Box__c. 
* @return void             
*                
*/
public void afterUpdateDirector(Map < Id, NSP_Lock_Box__c > lockboxNewMap, Map < Id, NSP_Lock_Box__c > lockboxOldMap) {

/* try{
    List<NSP_NotificationUtility.notificationEventWrapper> eventNotificationList = new List<NSP_NotificationUtility.notificationEventWrapper>();
   
for (NSP_Lock_Box__c lb : lockboxNewMap.values() ) {
        if(lb.NSP_Payment__c != lockboxOldMap.get(lb.Id).NSP_Payment__c && lb.NSP_Status__c==NSP_BillingConstants.SUCCESS) {
        NSP_NotificationUtility.notificationEventWrapper newevt = new NSP_NotificationUtility.notificationEventWrapper();
        newevt.typeid = NSP_BillingConstants.GENERIC_BELL_NOTIFICATION;
        newevt.title = NSP_BillingConstants.LOCKBOX_NOTIF_PART1+lb.Name;
        newevt.body = NSP_BillingConstants.LOCKBOX_NOTIF_PART2+lb.Name+NSP_BillingConstants.LOCKBOX_NOTIF_PART3;
        Set<String> deliveryids= new Set<String>();
        deliveryids.add(lb.OwnerId);
        newevt.userIds =  deliveryids;
        newevt.targetid = lb.NSP_Payment__c;

        eventNotificationList.add(newevt);
        
    }
}

if(eventNotificationList.size()>0) NSP_NotificationUtility.publishNotificationEvent(eventNotificationList);

}
catch (Exception ex){
    NSP_ErrorLogHandler.logSaveException('NSP_Lock_Box_TriggerHelper','afterUpdateDirector',ex.getMessage());
    
} */
// ABOVE CODE IS COMMENTED BECAUSE NOTIFICATION WAS REMOVED DURING DISCUSSIONS. KEEPING IT INTACT TO ENABLE OR DISABLED BASED UPON BIZ FEEDBACK.

// BELOW CODE IS ADDED IN AFTER UPDATE TO TRIGGER THE LOCK BOX PROCESS PAYMENT LOGIC ON CLICK OF CHECKBOX
List<String> lockboxIdsForProcess = new List<String>();
    Integer totalRecords=0;
    Integer successRecords=0;
    Integer failedRecords=0;

for (NSP_Lock_Box__c lb : lockboxNewMap.values() ) {
    if(lb.NSP_Status__c == NSP_BillingConstants.PENDING && lb.NSP_Payment__c==null && lb.NSP_Account__c!=null && lb.NSP_Ready_to_Convert__c == TRUE 
    && lb.NSP_Ready_to_Convert__c != lockboxOldMap.get(lb.Id).NSP_Ready_to_Convert__c) {
    lockboxIdsForProcess.add(lb.Id);
    }
}
if(lockboxIdsForProcess.size()>0) {
List<NSP_LockBox_Controller.lockboxWrapper> resArr = NSP_LockBox_Controller.processLockBoxRecords(lockboxIdsForProcess);
    for(NSP_LockBox_Controller.lockboxWrapper lbwrap : resArr) {
        totalRecords+=1;
        if(lbwrap.success) {
            successRecords+=1;
        }
        else {
            failedRecords+=1;
        }
    }

}

}

/**
* Iterates throught the NSP_Lock_Box__c map and identifies the records that needs to worked based on various criterias.
*Based on criteria status is changed to pending in before update
* @param leadNewMap Map of New NSP_Lock_Box__c. 
* @param leadOldMap Map of Old NSP_Lock_Box__c. 
* @return void             
*                
*/
public void beforeUpdateDirector(Map < Id, NSP_Lock_Box__c > lockboxNewMap, Map < Id, NSP_Lock_Box__c > lockboxOldMap) {

for (NSP_Lock_Box__c lb : lockboxNewMap.values() ) {

    if(lb.NSP_Status__c == NSP_BillingConstants.PROCESS_FAILED && lb.NSP_Payment__c==null && lb.NSP_Ready_to_Convert__c == FALSE 
        &&  lb.NSP_Ready_to_Convert__c != lockboxOldMap.get(lb.Id).NSP_Ready_to_Convert__c) {
            lb.NSP_Status__c = NSP_BillingConstants.PENDING;
        }
}
}

}