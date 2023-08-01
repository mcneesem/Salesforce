/**
* Represents the Amendment checklist trigger helper which handles all the logic.
* Version - STY       - AUTHOR          - DESCRIPTION                                     - TAG
* V1.0    - STY-02743 - Ramya Ravi -      S2I : Creation of new RET Education Record      <STY-02743>
*/

public class NSP_SalesToImplementationHelper {       
    
    /***********************************************************************************************
    * MethodName: afterInsert
    * Description : Iterates throught the list of new S2I 
    * Params:       List < NSP_Sales_to_Implementation__c > newList
    * Author :      Ramya Ravi
    *********************************************************************************************/  
        public void afterInsert(List < NSP_Sales_to_Implementation__c > newList) {
            Set < Id > setOfS2IIds = new Set < Id > ();
            Set < Id > planSubplanIDs = new Set < Id > ();
            Map < Id, NSP_Sales_to_Implementation__c > mapS2I= new Map < Id, NSP_Sales_to_Implementation__c > ();                      
            // Check if status date is populated
            for(NSP_Sales_to_Implementation__c S2I: newList)        {
                if(S2I.NSP_Status_Date__c != null)            {
                    setOfS2IIds.add(S2I.Id);
                    mapS2I.put(S2I.Id, S2I);
                    if(S2I.NSP_Subplan_Plan_Details_Record__c!=null){
                        planSubplanIDs.add(S2I.NSP_Subplan_Plan_Details_Record__c);
                    }
                }
            }
            if(!setOfS2IIds.isEmpty() ){
              createRETEd(setOfS2IIds,mapS2I,planSubplanIDs);      
            }                  
        }
        
    /***********************************************************************************************
    * MethodName: afterUpdate
    * Description : Iterates through the map of updated S2I 
    * Params:       Map < Id, NSP_Sales_to_Implementation__c > newMap, Map < Id, NSP_Sales_to_Implementation__c > oldMap
    * Author :      Ramya Ravi
    * ********************************************************************************************/  
        public void afterUpdate(Map<Id, NSP_Sales_to_Implementation__c> newMap, Map<Id, NSP_Sales_to_Implementation__c> oldMap){ 
            Set < Id > setOfS2IIds = new Set < Id > ();
            Set < Id > planSubplanIDs = new Set < Id > ();
            Map < Id, NSP_Sales_to_Implementation__c > mapS2I= new Map < Id, NSP_Sales_to_Implementation__c > ();               
            // Check if status date is populated for the first time
            for(NSP_Sales_to_Implementation__c S2I: newMap.values()){
                //check if Status date is filled for the first time
                if(S2I.NSP_Status_Date__c != null && oldMap.get(S2I.Id).NSP_Status_Date__c == null){            
                    setOfS2IIds.add(S2I.Id);
                    mapS2I.put(S2I.Id, S2I);
                    if(S2I.NSP_Subplan_Plan_Details_Record__c!=null){ 
                    planSubplanIDs.add(S2I.NSP_Subplan_Plan_Details_Record__c);
                    }
                }
            }
            if(!setOfS2IIds.isEmpty() ){
              createRETEd(setOfS2IIds,mapS2I,planSubplanIDs);      
            }   
        }
        
    /***********************************************************************************************
    * MethodName: createRETEd
    * Description : Iterates through the map of updated S2I 
    * Params:       Set < Id > setOfS2IIds,  Map < Id, NSP_Sales_to_Implementation__c > mapS2I
    * Author :      Ramya Ravi
    * ********************************************************************************************/  
        public void createRETEd(Set < Id > setOfS2IIds,  Map < Id, NSP_Sales_to_Implementation__c > mapS2I, Set<Id> planSubplanIDs){      
            Map < Id, Id > mapS2IToRETEducation = new Map < Id, Id > ();
            List<NSP_RET_Education__c> ListRETEdToInsert = new List<NSP_RET_Education__c>();
            List<Messaging.SingleEmailMessage> lstEmailMessages = new List<Messaging.SingleEmailMessage>();
            List<Id> insertedIds = new List<Id>();  
            Map< Id, String > plansubplanMap = new Map< Id, String >();
           
           // Gets education Team email address for Recipient email 
           NSP_Retirement_Services__mdt RetirementServicemdt =  NSP_Retirement_Services__mdt.getInstance(NSP_ServiceConstants.EDUCATION_TEAM);
            
            // query for any existing RET education records associated to S2I	
            for(NSP_RET_Education__c mappingRET: [Select Id,Sales_to_Implementation__c from NSP_RET_Education__c WHERE Sales_to_Implementation__c in : setOfS2IIds] ){
                mapS2IToRETEducation.put(mappingRET.Sales_to_Implementation__c ,mappingRET.Id);            
            }
            //query plan subplan to get subplan ID 
            for(NSP_Plan_SubPlan__c mappingPlanSubplan :[Select Id, NSP_Subplan_ID__c from NSP_Plan_SubPlan__c WHERE id in : planSubplanIDs]){
                plansubplanMap.put(mappingPlanSubplan.Id, mappingPlanSubplan.NSP_Subplan_ID__c);
            }
            // create new RET education record and associate it to S2I  
            for(NSP_Sales_to_Implementation__c S2I: mapS2I.values()){
                if(!(mapS2IToRETEducation.containsKey(S2I.Id))){
                    NSP_RET_Education__c RETed = new NSP_RET_Education__c();
                    if(plansubplanMap.containskey(S2I.NSP_Subplan_Plan_Details_Record__c)){
                       RETed.Name = plansubplanMap.get(S2I.NSP_Subplan_Plan_Details_Record__c) + ': '; 
                    }
                    if(RETed.Name!= null){
                       RETed.Name += 'RET Education Record'; 
                    }else{
                         RETed.Name = 'RET Education Record'; 
                    }
                    RETed.Name = 'RET Education Record';
                    RETed.Sales_to_Implementation__c = S2I.Id;
                    ListRETEdToInsert.add(RETed)   ;                               
                }
            }
            //insert RET education records
            if(ListRETEdToInsert.size()>0){
                Database.SaveResult[] srList = Database.insert(ListRETEdToInsert, false);           
                for (Database.SaveResult sr : srList){
                    insertedIds.add(sr.getId());
                }
            }
            // send email to Education team for each RET education record created     
            if(insertedIds.size()>0){
                
              EmailTemplate emailTemp =  [SELECT Id, BrandTemplateId, Subject, HTMLValue, Body, DeveloperName FROM EmailTemplate WHERE DeveloperName =:  NSP_ServiceConstants.RET_Education_Creation_Email LIMIT 1];
              List<String> sendTo = new List<String>();
              sendTo.add(RetirementServicemdt.NSP_Email_Address__c);
                if(emailTemp!=null){
                    for(Id idList:insertedIds){              
                        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                        email= Messaging.renderStoredEmailTemplate(emailTemp.Id, null ,idList);
                        email.setTemplateId(emailTemp.Id); 
                        email.setToAddresses(sendTo);
                        email.setWhatId(idList);  
                        lstEmailMessages.add(email);
                    }              
                }                      
            }
            if(!lstEmailMessages.isEmpty()){
                Messaging.sendEmail(lstEmailMessages);
            }             
        }
    }