/**
* Represents the Event trigger helper which handles all the logic.
*/
public class NSP_EventTriggerHelper {
    
    /* Iterates throught the list of new Event and passes the required attributes to other methods.
    * @param newList List of New Event.  
    * @return void             
    *                
    */
        public void beforeInsertDirector(List<Event> newList){        
        }
        
        /**
    * Iterates throught the map of new Event and passes the required attributes to other methods.
    * @param newList List of New Event.  
    * @param eventNewMap Map of Event id and Event records.
    * @return void             
    *                
    */
        
        public void afterInsertDirector(List<Event> newList, Map<Id, Event> eventNewMap){ 
            
            Set<ID> updateOpportunityIDList = new Set<ID>();
            List<Opportunity> updateOpportunityList = new List<Opportunity>();
            for(Event event : newList){
                if(event.NSP_Event_Subtype__c != null && event.NSP_Event_Subtype__c.equalsIgnoreCase('Discovery Call') && String.isNotBlank(event.WhatId) &&
                   ((String)event.WhatId).startsWith('006')){
                    updateOpportunityIDList.add(event.WhatId);
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
    * Iterates throught the Event map and identifies the records that needs to worked based on various criterias.
    * @param eventNewMap Map of New Event. 
    * @param eventOldMap Map of Old Event. 
    * @return void             
    *                
    */
        
        public void beforeUpdateDirector(Map<Id, Event> eventNewMap, Map<Id, Event> eventOldMap){
            
        }    
        
        /**
    * Iterates throught the list of new Events and passes the required attributes to other methods.
    * @param eventNewMap Map of New Event. 
    * @param eventOldMap Map of Old Event.   
    * @return void             
    *                
    */
        
        public void afterUpdateDirector(Map<Id, Event> eventNewMap, Map<Id, Event> eventOldMap){        
            Set<ID> updateOpportunityIDList = new Set<ID>();
            List<Opportunity> updateOpportunityList = new List<Opportunity>();
            for(Id eventId : eventNewMap.keySet()){   
                Event event = eventNewMap.get(eventId);
                if(event != NULL && event.NSP_Event_Subtype__c.equalsIgnoreCase('Discovery Call') && 
                   ((String)event.WhatId).startsWith('006')){
                    updateOpportunityIDList.add(event.WhatId);
                }           
                
            }
            List<Opportunity> listOpportunity = [SELECT ID, NSP_Ready_for_Integration_Sync__c FROM Opportunity 
                                                 WHERE ID IN: updateOpportunityIDList];  //Capitalized WHERE Condition as part of code fix
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
        
    }