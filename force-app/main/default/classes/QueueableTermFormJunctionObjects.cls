/* 
*    ClassName:QueueableTermFormJunctionObjects
*    @description: Represents the Contact trigger helper and Termination Form Trigger Helper US Contact Related List.
*    @date: 12/19/2023
*    @author: Roberto
*/
public class QueueableTermFormJunctionObjects implements Queueable {
    // test w/ NSP_TerminationFormTriggerHelperTest (97%)

    private List<SObject> newTerm;
    private Map<Id,SObject> oldTerm;
    private String triggerEventType;

    public QueueableTermFormJunctionObjects(List<SObject> newList, Map<Id, SObject> oldMap, String triggerEventType) {
        this.newTerm = newList.deepClone(true,false,false);
        this.oldTerm = oldMap; 
        this.triggerEventType = triggerEventType;
    }

    public void execute(QueueableContext context) {
         if (newTerm != null && !newTerm.isEmpty()) {
            // Process the first record
            SObject firstRecord = newTerm.remove(0);
            SObject oldEvent = oldTerm != null ? oldTerm.get(firstRecord.Id):null;
            processFirstRecord(firstRecord,oldEvent,triggerEventType);			
            // Check if there are remaining records to be re-enqueued
            if (!newTerm.isEmpty()) {
                // Re-enqueue the remaining records
                if(!Test.isRunningTest()){
                    System.enqueueJob(
                        new QueueableTermFormJunctionObjects(
                            newTerm ,
                            oldTerm ,
                            triggerEventType
                        )
                    );
                }
            }
        }
    }

    private void processFirstRecord(SObject lTerminationForms,SObject oldTerminationForms,String triggerEventType ) {
    
		Map<Id,Id> oldAccountId = new Map<Id,Id>();
        set<Id> newAccountId = new set<Id>();
        Map<Id,Id> termTask = new Map<Id,Id>();
        Id oldAccount = null;
        Id oldId = null;
        Id oldAccId = null;
        final String projectTask = 'NSP_Project_Task__c';
        final String accountField = 'NSP_Account__c';
        final String accountId = 'AccountId';
        final String relatedSite = 'NSP_Related_Site__c';
        final String NSP_Termination_Form = 'NSP_Termination_Form__c';
        final String idField = 'Id';
        final String NSP_Address = 'NSP_Address__c';
        final String contactObj = 'Contact';
        final String addressTypeField = 'NSP_Address_Type__c';
        String objectType = String.valueOf(lTerminationForms.getSObjectType());
        Map<String, Schema.SObjectField> fieldMap = lTerminationForms.getSObjectType().getDescribe().fields.getMap();
        //Old Termination Form (Update)
        if(oldTerminationForms != null){
            Map<String, Schema.SObjectField> oldfieldMap = oldTerminationForms.getSObjectType().getDescribe().fields.getMap();
            if(oldfieldMap != null){
                if(objectType == NSP_Termination_Form){			
                    if (oldfieldMap.containsKey(accountField)) {
                        oldAccount = (Id)oldTerminationForms.get(accountField);
                        oldId = (Id)oldTerminationForms.get(idField);
                        oldAccId = (Id)oldTerminationForms.get(accountField);
                    }
                }
                else if(objectType == contactObj){			
                    if (oldfieldMap.containsKey(accountId)) {
                        oldAccount = (Id)oldTerminationForms.get(accountId);
                        oldAccId = (Id)oldTerminationForms.get(accountId);
                    }
                } 
                else if(objectType == NSP_Address){			
                    if (oldfieldMap.containsKey(relatedSite)) {
                        oldAccount = (Id)oldTerminationForms.get(relatedSite);
                        oldAccId = (Id)oldTerminationForms.get(relatedSite);
                    }
                }
            }
        }
        
        //new Termination Form (Insert)
        Id accountObj = null;
        Id updateAccount = null;
        String addressType;
        if(objectType == NSP_Termination_Form){			
            if (fieldMap.containsKey(accountField)) {
                accountObj = (Id)lTerminationForms.get(accountField);
                updateAccount = (Id)lTerminationForms.get(accountField);
            }
        }
        else if(objectType == contactObj){
            if (fieldMap.containsKey(accountId)) {
                accountObj = (Id)lTerminationForms.get(accountId);
                updateAccount = (Id)lTerminationForms.get(accountId);
            }
        }
        else if(objectType == NSP_Address){
            if (fieldMap.containsKey(relatedSite)) {
                accountObj = (Id)lTerminationForms.get(relatedSite);
                updateAccount = (Id)lTerminationForms.get(relatedSite);
                addressType = (String)lTerminationForms.get(addressTypeField);
                
            }
        }
        if( triggerEventType == NSP_ServiceConstants.INSERT_TRIGGER && accountObj!=null)
        {	
            termTask.put(lTerminationForms.Id,accountObj);
            newAccountId.add(accountObj);
        }
        if(triggerEventType == NSP_ServiceConstants.INSERT_TRIGGER && accountObj!=null && addressType == NSP_ServiceConstants.US_MAIL) {
            termTask.put(lTerminationForms.Id,accountObj);
            newAccountId.add(accountObj);
        }
        ///UPDATE
        if(triggerEventType == NSP_ServiceConstants.UPDATE_TRIGGER && updateAccount != oldAccount && accountObj!=null && oldId != null && oldAccId != null)
        {
            termTask.put(lTerminationForms.Id,accountObj);
            newAccountId.add(accountObj);
            oldAccountId.put(oldId,oldAccId);
        }
        	Map<Id,List<Contact>> contactMap = new Map<Id,List<Contact>>();
        	Map<Id,List<NSP_Address__c>> addressMap = new Map<Id,List<NSP_Address__c>>();
        	Map<Id,List<NSP_Termination_Form__c>> termFormMap = new Map<Id,List<NSP_Termination_Form__c>>();
            if(newAccountId != null){
                if(objectType == NSP_Termination_Form){
                	for(Contact addList: [SELECT Id, Name, AccountId, NSP_Work_email__c, NSP_Work_Phone__c, NSP_Job_Title__c FROM Contact WHERE AccountId IN: newAccountId]) {
                         if(addList != null){
                            if(!contactMap.containskey(addList.AccountId)){
                                contactMap.put(addList.AccountId, new list<Contact>());
                            }
                            contactMap.get(addList.AccountId).add(addList);
                         }
         			}
                    
                    for(NSP_Address__c addList: [SELECT Id,NSP_Address__c,Name,NSP_Related_Site__c FROM NSP_Address__c WHERE NSP_Related_Site__c IN: newAccountId AND NSP_Address_Type__c =: NSP_ServiceConstants.US_MAIL]) {
                         if(addList != null){
                            if(!addressMap.containskey(addList.NSP_Related_Site__c)){
                                addressMap.put(addList.NSP_Related_Site__c, new list<NSP_Address__c>());
                            }
                            addressMap.get(addList.NSP_Related_Site__c).add(addList);
                         }
         			}
                    
                }
                else if(objectType == contactObj || objectType == NSP_Address || objectType == NSP_Termination_Form){
                    for(NSP_Termination_Form__c addList: [SELECT Id, NSP_Account__c FROM NSP_Termination_Form__c WHERE NSP_Account__c IN: newAccountId]) {
                        if(addList != null){
                            if(!termFormMap.containskey(addList.NSP_Account__c)){    
                                termFormMap.put(addList.NSP_Account__c, new list<NSP_Termination_Form__c>());
                            }
                            termFormMap.get(addList.NSP_Account__c).add(addList);
                        }
                    }
                }
            }
        
            List<US_Contact__c> usMailContacts = new List<US_Contact__c>();
        	List<US_Mail_Address__c> usAddressMails = new List<US_Mail_Address__c>();
        	String jobTitle;
            String workPhone;
    		String workEmail;
    		String name;
            final String contact_Name_Pref_First_Name = 'NSP_Contact_Name_Pref_First_Name__c';
            final String job_Title = 'NSP_Job_Title__c';
            final String work_Phone = 'NSP_Work_Phone__c';
            final String work_email = 'NSP_Work_email__c';
            final String nameField = 'Name';
            if(objectType == contactObj && !fieldMap.isEmpty()){
                if (fieldMap.containsKey(contact_Name_Pref_First_Name)) {
                    name = (String)lTerminationForms.get(contact_Name_Pref_First_Name);
                }
                if (fieldMap.containsKey(job_Title)) {
                    jobTitle = (String)lTerminationForms.get(job_Title);
                }
                if (fieldMap.containsKey(work_Phone)) {
                    workPhone = (String)lTerminationForms.get(work_Phone);
                }
                if (fieldMap.containsKey(work_email)) {
                    workEmail = (String)lTerminationForms.get(work_email);
                }
            }
            String address;
            if(objectType == NSP_Address && !fieldMap.isEmpty()){
                if (fieldMap.containsKey(NSP_Address)) {
                    address = (String)lTerminationForms.get(NSP_Address);
                }
                if (fieldMap.containsKey(nameField)) {
                    name = (String)lTerminationForms.get(nameField);
                }
            }
            
            if(termTask.containsKey(lTerminationForms.Id)){
                if(!contactMap.isEmpty() && contactMap.containsKey(termTask.get(lTerminationForms.Id))){
                    List<Contact> contactListUs = contactMap.get(termTask.get(lTerminationForms.Id));
                    if(contactListUs != null){
                        for(Contact addUS : contactListUs){
                            US_Contact__c us = new US_Contact__c(
                                Name = addUS.Name,
                                Termination_Form__c =lTerminationForms.Id ,
                                Contact__c = addUS.Id,
                                Job_Title__c = addUs.NSP_Job_Title__c,
                                Work_Phone__c = addUs.NSP_Work_Phone__c,
                                Work_Email__c = addUs.NSP_Work_email__c
                            ); 
                            usMailContacts.add(us); 
                        }
                    } 
                }
                if(termFormMap.containsKey(termTask.get(lTerminationForms.Id))){
                    List<NSP_Termination_Form__c> contactListUs = termFormMap.get(termTask.get(lTerminationForms.Id));
                    if(contactListUs != null){   
                        if(objectType == contactObj){
                            for(NSP_Termination_Form__c addUS : contactListUs){
                                US_Contact__c us = new US_Contact__c(
                                    Name = name,
                                    Termination_Form__c = addUS.Id ,
                                    Contact__c = lTerminationForms.Id,
                                    Job_Title__c = jobTitle,
                                    Work_Phone__c = workPhone,
                                    Work_Email__c = workEmail
                                ); 
                                usMailContacts.add(us); 
                            }
                            
                        }
                        if(objectType == NSP_Address){
                            for(NSP_Termination_Form__c addUS : contactListUs){
                                US_Mail_Address__c us = new US_Mail_Address__c(
                                    
                                    USAddress__c = address,
                                    Name = name ,
                                    Termination_Form__c = addUs.Id,
                                    Address__c = lTerminationForms.Id
                                ); 
                                usAddressMails.add(us);   
                            }
                        }
                    }
                }
                if(!addressMap.isEmpty() && objectType == NSP_Termination_Form && addressMap.containsKey(termTask.get(lTerminationForms.Id))){
                    List<NSP_Address__c> contactListUs = addressMap.get(termTask.get(lTerminationForms.Id));
                    if(contactListUs != null){
                        for(NSP_Address__c addUS : contactListUs){
                            US_Mail_Address__c us = new US_Mail_Address__c( 
                                USAddress__c = (String)addUS.NSP_Address__c,
                                Name = addUS.Name ,
                                Termination_Form__c = lTerminationForms.Id,
                                Address__c = addUs.Id); 
                            usAddressMails.add(us);
                        }
                    }
                }
            }
        	Map<Id,List<Contact>> oldContactMap = new Map<Id,List<Contact>>();
        	List<US_Contact__c> oldUsContact = new List<US_Contact__c>();
        	List<US_Mail_Address__c> oldUsAddress = new List<US_Mail_Address__c>();
            if(oldAccountId != null){
                for(Contact addOldList: [SELECT Id,Name,AccountId FROM Contact WHERE AccountId IN: oldAccountId.values()]) {
                    if(addOldList != null){
                        if(!oldContactMap.containskey(addOldList.AccountId)){
                        	oldContactMap.put(addOldList.AccountId, new list<Contact>());
                        }
                    	oldContactMap.get(addOldList.AccountId).add(addOldList);
                    }
                }
                for(US_Contact__c usTermOldList:[SELECT Contact__c, Id, Termination_Form__c FROM US_Contact__c where Termination_Form__c IN: oldAccountId.keyset()]){
                    if(oldAccountId.containskey(usTermOldList.Termination_Form__c) && oldContactMap.containsKey(oldAccountId.get(usTermOldList.Termination_Form__c))){
                    	List<Contact> addOldListUs = oldContactMap.get(oldAccountId.get(usTermOldList.Termination_Form__c));
                         if(addOldListUs != null){
                             for(Contact addUS : addOldListUs){ 
                                 if(usTermOldList.Contact__c == addUS.Id){
                                    US_Contact__c usOld = new US_Contact__c(               
                                    Id = usTermOldList.Id
                                    ); 
                                	oldUsContact.add(usOld);    
                                 }
                             }
                         }                   
                    }
                }
                
                Map<Id,List<NSP_Address__c>> oldAddressMap = new Map<Id,List<NSP_Address__c>>();
                for(NSP_Address__c addOldList: [SELECT Id,NSP_Address__c,Name,NSP_Related_Site__c FROM NSP_Address__c WHERE NSP_Related_Site__c IN: oldAccountId.values() AND NSP_Address_Type__c =: NSP_ServiceConstants.US_MAIL]) {
                    if(addOldList != null){
                        If(!oldAddressMap.containskey(addOldList.NSP_Related_Site__c)){
                            oldAddressMap.put(addOldList.NSP_Related_Site__c, new list<NSP_Address__c>());
                        }
                        oldAddressMap.get(addOldList.NSP_Related_Site__c).add(addOldList);
                    }
                }
                for(US_Mail_Address__c usTermOldList:[SELECT Address__c, Id, Termination_Form__c FROM US_Mail_Address__c where Termination_Form__c IN: oldAccountId.keyset()]){
                if(oldAccountId.containskey(usTermOldList.Termination_Form__c) && oldAddressMap.containskey(oldAccountId.get(usTermOldList.Termination_Form__c))){
                     List<NSP_Address__c> addOldListUs = oldAddressMap.get(oldAccountId.get(usTermOldList.Termination_Form__c));
                     if(addOldListUs != null){
                         for(NSP_Address__c addUS : addOldListUs){ 
                             if(usTermOldList.Address__c == addUS.Id){
                                US_Mail_Address__c usOld = new US_Mail_Address__c(               
                                Id = usTermOldList.Id
                                ); 
                                oldUsAddress.add(usOld);    
                             	}
                         	}
                     	}                   
                	}
                }       
            }
        
        try{
            
            if(!usMailContacts.isEmpty()){
                Insert usMailContacts;
            }
            if(!usAddressMails.isEmpty()){
                Insert usAddressMails;
            }
            if(!oldUsAddress.isEmpty()){
                Delete oldUsAddress;
            }
            if(!oldUsContact.isEmpty()){
                Delete oldUsContact;
            }
        }catch(Exception ex){
            NSP_ErrorLogHandler.logSaveException('NSP_QueueableTermFormJunctionObjects', 'execute', ex.getMessage());
        }  

        // Your logic to process the first record goes here

        // Add your specific logic for processing the first record

    }
}