/**
* Represents the Event trigger helper which handles all the logic.
*/
public class NSP_EventTriggerHelper {
    
    public static String DISCOVERY_CALL = 'Discovery Call';
    /* Iterates throught the list of new Event and passes the required attributes to other methods.
    * @param newList List of New Event.  
    * @return void             
    *                
    */
        public void beforeInsertDirector(List<Event> newList){
            
             updateEventSales(newList,null);
        }
        
        /**
    * Iterates throught the map of new Event and passes the required attributes to other methods.
    * @param newList List of New Event.  
    * @param eventNewMap Map of Event id and Event records.
    * @return void             
    *                
    */
        
        public void afterInsertDirector(List<Event> newList, Map<Id, Event> eventNewMap){ 
            
            updateOpportunitiesWithDiscoverCalls(newList);
            updateActivityDate(newList,null);  
        }
        
        /**
    * Iterates throught the Event map and identifies the records that needs to worked based on various criterias.
    * @param eventNewMap Map of New Event. 
    * @param eventOldMap Map of Old Event. 
    * @return void             
    *                
    */
        
        public void beforeUpdateDirector(Map<Id, Event> eventNewMap, Map<Id, Event> eventOldMap){
            updateEventSales(eventNewMap.values(),eventOldMap);
            
        }    
        
        /**
    * Iterates throught the list of new Events and passes the required attributes to other methods.
    * @param eventNewMap Map of New Event. 
    * @param eventOldMap Map of Old Event.   
    * @return void             
    *                
    */
        
        public void afterUpdateDirector(Map<Id, Event> eventNewMap, Map<Id, Event> eventOldMap){        
            
            updateOpportunitiesWithDiscoverCalls(eventNewMap.values());
            updateActivityDate(eventNewMap.values(),eventOldMap);
        }   
        
        
    public void updateOpportunitiesWithDiscoverCalls(List<Event> newList) {

        String opportunity_prefix = Schema.SObjectType.Opportunity.getKeyPrefix();

        Set<ID> updateOpportunityIDList = new Set<ID>();
        List<Opportunity> updateOpportunityList = new List<Opportunity>();
        for(Event event : newList){
            if(event != NULL && event.WhatId != NULL && event.NSP_Event_Subtype__c != NULL){
                if(event.NSP_Event_Subtype__c.equalsIgnoreCase(DISCOVERY_CALL) && 
                   ((String)event.WhatId).startsWith(opportunity_prefix)){
                    updateOpportunityIDList.add(event.WhatId);
                }           
            }  
        }
        List<Opportunity> listOpportunity = [SELECT ID, NSP_Ready_for_Integration_Sync__c FROM Opportunity 
                                             WHERE ID IN: updateOpportunityIDList]; //Capitalized WHERE Condition as part of code fix
        for(Opportunity oppty : listOpportunity){
            Opportunity opp = new Opportunity();
            opp.Id = oppty.Id;
            opp.NSP_Ready_for_Integration_Sync__c = true;
            updateOpportunityList.add(opp);
        }
        if(!updateOpportunityList.isEmpty()){
            Database.update(updateOpportunityList);
        }
        
    }
  /**
* Method Name : updateActivityDate 
* Description : Method to update last activity date on all related leads with same DUNS.
* Date : 31/03/2021
* @param newList List of New Event. 
* @param eventOldMap Map of Old Event.   
* @return void  
*/
        public void updateActivityDate(List<Event> newList,Map<Id,Event> eventOldMap){
            Set < Id > leadIdSet = new Set < Id > ();
            List < Lead > leadResult = new List<Lead> ();
            List < Lead > leadWithDuns = new List<Lead> ();
            Map < String, Date > lastActivityDateMap = new Map < String, Date > ();
            List < Lead > leadToUpdate = new List<Lead> ();
            for(Event event : newList){
                Event oldEvent = eventOldMap != null ? eventOldMap.get(event.Id):null;
                if((Trigger.isInsert || event.StartDateTime != oldEvent.StartDateTime) && event.StartDateTime != null && event.WhoId!= null)
                leadIdSet.add(event.WhoId);
            }
            if(!leadIdSet.isEmpty()){
                leadResult = [SELECT Id, Salutation, FirstName, MiddleName, LastName, NSP_Parent_Lead__c, DNBoptimizer__DNB_D_U_N_S_Number__c,LastActivityDate FROM Lead WHERE Id IN: leadIdSet];
                if(!leadResult.isEmpty()) {
                    for(Lead leadObj :leadResult){
                        if(leadObj.LastActivityDate != null && leadObj.DNBoptimizer__DNB_D_U_N_S_Number__c !=null) {
                            lastActivityDateMap.put(leadObj.DNBoptimizer__DNB_D_U_N_S_Number__c,leadObj.LastActivityDate);
                        }
                    }
                    if(!lastActivityDateMap.isEmpty()) {
                        leadWithDuns = [SELECT Id, Salutation, FirstName, NSP_Last_Activity__c, LastName, NSP_Parent_Lead__c, DNBoptimizer__DNB_D_U_N_S_Number__c,LastActivityDate FROM Lead WHERE DNBoptimizer__DNB_D_U_N_S_Number__c IN: lastActivityDateMap.keySet()];
                        Lead lastActive = [SELECT LastActivityDate FROM Lead WHERE DNBoptimizer__DNB_D_U_N_S_Number__c IN: lastActivityDateMap.keySet() AND LastActivityDate != null ORDER BY LastActivityDate DESC LIMIT 1];
                        if(!leadWithDuns.isEmpty()){
                            for(Lead leadObject : leadWithDuns){
                                 leadObject.NSP_Last_Activity__c = lastActive.LastActivityDate;
                                 leadToUpdate.add(leadObject);
                               }
                        }
                    }
                }
            }
            try{
                if(!leadToUpdate.isEmpty()){
                    update leadToUpdate;
                }
            }
            catch(Exception ex){
                NSP_ErrorLogHandler.logSaveException('NSP_EventTriggerHelper', 'updateActivityDate', ex.getMessage());
            }
        }
    
/**
* Method Name : updateEventSales 
* Description : Method to update sales region, sales devison and sales office.
* Date : 08/12/2022
* @param newList List of New Event. 
* @param OldEventMap Map of Old Event.   
* @return void  
*/

    public void updateEventSales(List<Event> newList,Map<Id,Event> OldEventMap){
    
    set<Id> ownerIdSet = new set<Id>();
    for(Event newEvent : newList)
    {
        Event oldEvent = OldEventMap != null ? OldEventMap.get(newEvent.Id):null;
        
        if(Trigger.isInsert || newEvent.OwnerId != oldEvent.OwnerId )
        {
            ownerIdSet.add(newEvent.ownerId);    
        }
    }
    
    if(ownerIdSet.Size() > 0)
    {
        Map<Id,User> userIdMap = new Map<Id,User>([SELECT Id,NSP_SalesDivision__c,NSP_Sales_Office__c,NSP_SalesRegion__c from user where Id In :ownerIdSet AND NSP_Sales_Office__c != null ]);
        
        for(Event newEvent : newList)
        {
            Event oldEvent = OldEventMap != null ? OldEventMap.get(newEvent.Id):null;
            
            if(Trigger.isInsert || newEvent.OwnerId != oldEvent.OwnerId )
            {
                if(userIdMap.containsKey(newEvent.ownerId))
                {
                    user eachUser = userIdMap.get(newEvent.OwnerId);
                    newEvent.NSP_Sales_Region__c = eachUser.NSP_SalesRegion__c;  // sales region
                    newEvent.NSP_Sales_Division__c = eachUser.NSP_SalesDivision__c; // sales division
                    newEvent.NSP_Sales_Office__c = eachUser.NSP_Sales_Office__c; // sales office
                }                   
            }
        }    
    }
  }  
    
    }