/**
* Represents the Client qGoal trigger helper which handles all the logic.
*/
public class NSP_ClientGoalTriggerHelper {
    
    public Id peoProjectRecordTypeId = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('PEO_Project').getRecordTypeId();
    public final String PROJECTTASKSTATUSCOMPLETE = 'Complete';
    public final String PROJECTTASKSTATUSCANCELLED = 'Cancelled';    
    
    
    /**
    * Iterates throught the list of new leads and passes the required attributes to other methods.
    * @param newList List of New Client Goal.    
    * @return void             
    *                
    */
    public void afterInsertDirector(List<NSP_ClientGoal__c> newList){
        Set<Id> setOfAccountId = new Set<Id>();	
        Map<Id,Id> projectMap = new Map<Id,Id>();
        Map<id,NSP_ClientGoal__c> goalMap = new Map<id,NSP_ClientGoal__c>();
    	
        for(NSP_ClientGoal__c clientGoal : newList){
           if(clientGoal.NSP_Account__c != null){
               setOfAccountId.add( clientGoal.NSP_Account__c );
               goalMap.put(clientGoal.NSP_Account__c,clientGoal);
           }
        }
        
        projectMap = getProjectDetails(setOfAccountId);
        
        if(projectMap != null && !projectMap.isEmpty()){
            copyClientGoalFromAccountOnProjectGoalOnProject(goalMap,projectMap);
        }
        
    }
    /**
    * Iterates throught the Map of new NSP_ClientGoal__c and passes the required attributes to other methods.
    * @param Map<Id, NSP_ClientGoal__c> newMap,Map<Id, NSP_ClientGoal__c> oldMap  
    * @return void             
    *                
    */
    public void afterUpdateDirector(Map<Id, NSP_ClientGoal__c> newMap,Map<Id, NSP_ClientGoal__c> oldMap){
        List<NSP_ProjectGoal__c> projectGoalList = new List<NSP_ProjectGoal__c>();
        List<String> clientGoalName =  new List<String>();
        for(NSP_ClientGoal__c clientGoal : newMap.Values()){
            if(clientGoal.name != null){
                clientGoalName.add(clientGoal.name);
            }
        }
       projectGoalList = [SELECT id, Client_Goals_Name__c, NSP_GoalType__c, NSP_PG_Date__c, NSP_PG_Goal_Target_Date__c, NSP_PG_Status__c, NSP_PG_Contact__c, NSP_PG_Asset__c, NSP_Details__c, NSP_Project__c, NSP_Project__r.pse__Project_Status__c FROM NSP_ProjectGoal__c 
                          	WHERE Client_Goals_Name__c!= null 
                          	AND NSP_Project__r.pse__Project_Status__c NOT IN ('Complete','Cancelled')
                        	AND Client_Goals_Name__c IN :clientGoalName];
       
       updateClientGoalToProjectGoal(projectGoalList,newMap);

    }
    
    /***********************************************************************************************
    * MethodName: getProjectDetails
    * params : Set<Id> accountIds
    * ********************************************************************************************/
    public static Map<Id,Id> getProjectDetails(Set<Id> accountIds){
        Map<Id,Id> projectMap = new Map<Id,Id>();
    	Id peoProjectRecordTypeId = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('PEO_Project').getRecordTypeId();
        Id billableSerRecordTypeId = NSP_GenericRecordType.getRecordTypeId('pse__Proj__c', NSP_ServiceConstants.PEO_BILL_RECORDTYPE);
    
        List<pse__Proj__c> pseProjects = [SELECT Id,pse__Account__c,pse__Project_Status__c FROM pse__Proj__c 
                                         WHERE pse__Account__c IN:accountIds 
                                         AND pse__Project_Status__c NOT IN ('Complete','Cancelled') 
                                         AND (RecordTypeId = :peoProjectRecordTypeId  OR
                                         RecordTypeId = :billableSerRecordTypeId)
                                          ];
        if(!pseProjects.isEmpty()){
            for(pse__Proj__c proj : pseProjects){
                projectMap.put(proj.id,proj.pse__Account__c);
            }
            return projectMap;
        }
        
        return new Map<Id,Id>();
        }
        
    
    
    /* Description : This will copy all the client goals associated with
                    account to Project goals associated with Project
     * Date        : 11/05/2022 */
    
    public void copyClientGoalFromAccountOnProjectGoalOnProject(Map<Id,NSP_ClientGoal__c> goalMap, map<Id, Id> projectMap){
        list<NSP_ProjectGoal__c> listOfProjectGoals = new list<NSP_ProjectGoal__c>();
        
        for(Id projectId : projectMap.keySet()){
            NSP_ProjectGoal__c createProjectGoal = new NSP_ProjectGoal__c();                                     
            createProjectGoal.NSP_GoalType__c = goalMap.get(projectMap.get(projectId)).NSP_Goal_Type__c;                                    
            createProjectGoal.NSP_Project__c  = projectId;
            createProjectGoal.NSP_PG_Date__c = goalMap.get(projectMap.get(projectId)).NSP_Date__c;
            createProjectGoal.NSP_PG_Goal_Target_Date__c = goalMap.get(projectMap.get(projectId)).NSP_Goal_Date__c;
            createProjectGoal.NSP_PG_Status__c = goalMap.get(projectMap.get(projectId)).NSP_Status__c;
            createProjectGoal.NSP_PG_Contact__c = goalMap.get(projectMap.get(projectId)).NSP_Contact__c;
            createProjectGoal.NSP_PG_Asset__c = goalMap.get(projectMap.get(projectId)).Asset__c;
            createProjectGoal.Client_Goals_Name__c = goalMap.get(projectMap.get(projectId)).Name;
            if(goalMap.get(projectMap.get(projectId)).NSP_Goal_Details__c!=null && goalMap.get(projectMap.get(projectId)).NSP_Goal_Details__c.length()>255){
                createProjectGoal.NSP_Details__c      = goalMap.get(projectMap.get(projectId)).NSP_Goal_Details__c.subString(0,255);
            } else {
                createProjectGoal.NSP_Details__c      = goalMap.get(projectMap.get(projectId)).NSP_Goal_Details__c;
            }
            
            listOfProjectGoals.add(createProjectGoal);
        }
        
        if(!listOfProjectGoals.isEmpty()) {
            Database.insert(listOfProjectGoals);
        }
    }

    /***********************************************************************************************
    Method Name : updateClientGoalToProjectGoal
    Description : This will copy updates from Client gaol on Account to Project Goal on Project
     ** @param List<NSP_ProjectGoal__c> projectGoalList, Map<Id, NSP_ClientGoal__c> newMap
     ** @return void 
    *************************************************************************************************/  
    public void updateClientGoalToProjectGoal(List<NSP_ProjectGoal__c> projectGoalList, Map<Id, NSP_ClientGoal__c> newMap){
        List<NSP_ProjectGoal__c> updatedProjectGoalList = new List<NSP_ProjectGoal__c>();       
        
        for(NSP_ProjectGoal__c projectGoal : projectGoalList){
            String pClientGoalName = projectGoal.Client_Goals_Name__c;
            for(NSP_ClientGoal__c clientGoal : newMap.Values()){
                String clientGName = clientGoal.Name;
                if(pClientGoalName == clientGName){
                    projectGoal.NSP_GoalType__c = clientGoal.NSP_Goal_Type__c;
                    projectGoal.NSP_PG_Date__c = clientGoal.NSP_Date__c;
                    projectGoal.NSP_PG_Goal_Target_Date__c = clientGoal.NSP_Goal_Date__c;
                    projectGoal.NSP_PG_Status__c = clientGoal.NSP_Status__c;
                    projectGoal.NSP_PG_Contact__c = clientGoal.NSP_Contact__c;
                    projectGoal.NSP_PG_Asset__c = clientGoal.Asset__c;
                    projectGoal.NSP_Details__c = clientGoal.NSP_Goal_Details__c;
                    updatedProjectGoalList.add(projectGoal);
                }
            }
        }
        if(!updatedProjectGoalList.isEmpty()){
            Database.update(updatedProjectGoalList);
        }
        
    }

    /***********************************************************************************************
    * MethodName: getRSAPDetails
    * params : Set<Id> accountIds
    * ********************************************************************************************/
    
    public static Map<Id,NSP_Relationship_Strategy_Action_Plan__c> getRSAPDetails(Set<Id> accountIds){
        Map<Id,NSP_Relationship_Strategy_Action_Plan__c> RSAPMap = new Map<Id,NSP_Relationship_Strategy_Action_Plan__c>();
    	//Id peoProjectRecordTypeId = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByDeveloperName().get('PEO_Project').getRecordTypeId();
    
        List<NSP_Relationship_Strategy_Action_Plan__c> RSAPrecords = [SELECT Id,NSP_Account__c,NSP_Status__c FROM NSP_Relationship_Strategy_Action_Plan__c WHERE NSP_Account__c IN:accountIds AND NSP_Status__c NOT IN ('Completed','Cancelled')];
        if(!RSAPrecords.isEmpty()){
            for(NSP_Relationship_Strategy_Action_Plan__c rsap : RSAPrecords){
                RSAPMap.put(rsap.NSP_Account__c,rsap);
            }
            return RSAPMap;
        }
        
        return new Map<Id,NSP_Relationship_Strategy_Action_Plan__c>();
    }
}