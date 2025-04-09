/**
Apex Class Name      :  NSP_ServicePlanProjectTaskBatch
Version              :  1.0                                                                          
Created Date         :  6/1/2022  
Function             :  Represents batch class for NSP_ServicePlanProjectTaskBatch 
Story                :                                                                      
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Jatin Ahuja                   6/9/2022           First Iteration
* Suhas Sutar                   3/11/2025          Added custom settings for hardcoded values
*/
public class NSP_ServicePlanProjectTaskBatch implements Database.Batchable<sObject> {
    // test w/ NSP_ServicePlanProjectTaskBatch_Test (90%)

    public Database.QueryLocator start(Database.BatchableContext bc){
        //Using SOQL QUery to fetch Template Name, project status from Project Task object
        String query = 'SELECT Id, Name, TemplateName__c, pse__Project_Status__c, pse__Project_Type__c, pse__Account__c '+
            'FROM pse__Proj__c WHERE '+
            'TemplateName__c = '+'\''+ NSP_ServiceConstants.PROJECT_TEMPLATE_NAME +'\''+
            'AND pse__Is_Template__c = False '+
            'AND pse__Project_Type__c = '+'\''+ NSP_ServiceConstants.PROJECT_TYPE_SERVICE +'\''+
            'AND pse__Account__r.NSP_Sales_Service_Account_Status__c = '+'\''+ NSP_ServiceConstants.Account_Status +'\''+
            'AND (pse__Project_Status__c != '+'\''+ NSP_ServiceConstants.PROJECTSTATUSCANCELLED +'\''+
            'AND pse__Project_Status__c != '+'\''+ NSP_ServiceConstants.PROJECTSTATUSCOMPLETED +'\''+')';
        return Database.getQueryLocator(query);   
    }
    
    public void execute(Database.BatchableContext bc, List<pse__Proj__c> relatedProjectList){
        List<sObject> lstOfRecords = new List<sObject>();
        Map<Id, Date> mapOfAccountIdAndRenewalDate = new Map<Id, Date> ();
        Set<Id> accountIdSet = new Set<Id>();
        set<pse__Proj__c> validProjectsSet = new set<pse__Proj__c>();
        
        String peoProjectTaskRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'pse__Project_Task__c', 'PEO_Project_Task'  );

        // check relatedprojectlist not empty
        if(relatedProjectList.size() > 0){
            //iterating over project list
            for(pse__Proj__c prj : relatedProjectList){
                accountIdSet.add(prj.pse__Account__c);
            }
        }
        
        // Get Account Team Map
        Map<Id,List<NSP_Account_Team__c>> accountTeamMap = NSP_ServicePlanProjectTaskBatch.getAccountTeamMap( accountIdSet );
        
        
        // Get Sub Client
        for(pse__Proj__c project : [
                    SELECT
                        Id , TemplateName__c , pse__Account__c , pse__Account__r.NSP_AIMS_Renewal_Date__c ,
                        pse__Project_Type__c , RecordTypeId , pse__Start_Date__c , pse__End_Date__c , OwnerId, 
                        (
                            SELECT Id , Name , pse__Start_Date_Time__c
                            FROM pse__Project_Tasks__r
                            WHERE (
                                ( Name IN ( :NSP_ServiceConstants.QTP1 , :NSP_ServiceConstants.QTP2 ) )
                                AND ( pse__Start_Date_Time__c!=null )
                            )
                            ORDER BY pse__Start_Date_Time__c DESC
                        )
                    FROM pse__Proj__c 
                    WHERE (
                        ( Id IN :relatedProjectList )
                        AND ( pse__Account__c != null )
                    )
                ]
            )
        {
            Date renewalDate = project.pse__Account__r.NSP_AIMS_Renewal_Date__c;
            if(!mapOfAccountIdAndRenewalDate.containsKey(project.id)){
                mapOfAccountIdAndRenewalDate.put(project.pse__Account__c, renewalDate);
            }
            if(renewalDate==System.today()){
                validProjectsSet.add(project);
            } else {
                if(renewalDate!=null){
                    Integer lookupDays = renewalDate.daysBetween(System.today());
                    if ( lookupDays <= NSP_ServicePlanProjectTaskBatch.renewalDateLookupDays ) {
                        if ( ( project.pse__Project_Tasks__r != null )
                            && !project.pse__Project_Tasks__r.isEmpty()
                            )
                        {
                            Boolean taskPresent = false;
                            for(pse__Project_Task__c projTask : project.pse__Project_Tasks__r){
                                Date startDate = Date.valueOf(projTask.pse__Start_Date_Time__c);
                                if(projTask.Name == NSP_ServiceConstants.QTP1){
                                    if ( ( startDate == renewalDate.addDays( NSP_ServicePlanProjectTaskBatch.qtp1StartDays ) )
                                        || ( startDate > renewalDate )
                                        )
                                    {
                                        taskPresent = true;
                                        break;
                                    }
                                } else {
                                    if ( ( startDate == renewalDate.addDays( NSP_ServicePlanProjectTaskBatch.qtp2StartDays ) )
                                        || ( startDate > renewalDate )
                                        )
                                    {
                                        taskPresent = true;
                                        break;
                                    }
                                }
                            }
                            if(!taskPresent){
                                validProjectsSet.add(project);
                            }
                        }else{
                            validProjectsSet.add(project);
                        }
                    }
                }
            }
        }
        if(!validProjectsSet.isEmpty()){
            for(pse__Proj__c prj : validProjectsSet){
                Integer randomNumber = Integer.valueof((Math.random() * 1847263450));
                // Get Owner Id from Account Teams
                String ownerId = NSP_ServicePlanProjectTaskBatch.getOwnerIdFromAccountTeams( prj , accountTeamMap );
                String roleName = NSP_ServicePlanProjectTaskBatch.getRoleBasedOnOwnerId(ownerId, prj, accountTeamMap);

                pse__Project_Task_Assignment__c projTaskAssigmt = new pse__Project_Task_Assignment__c();
                projTaskAssigmt.pse__Resource_Role__c =roleName;
                projTaskAssigmt.NSP_Priority__c = 1;
                pse__Project_Task__c projectTaskReference = new pse__Project_Task__c(pse__External_Task_ID__c = prj.Id+'-'+NSP_ServiceConstants.QTP1+'-'+randomNumber);
                projTaskAssigmt.pse__Project_Task__r = projectTaskReference;
                
                pse__Project_Task_Assignment__c projTaskAssigmt2 = new pse__Project_Task_Assignment__c();
                projTaskAssigmt2.pse__Resource_Role__c = roleName;
                projTaskAssigmt2.NSP_Priority__c = 1;
                pse__Project_Task__c projectTaskReference2 = new pse__Project_Task__c(pse__External_Task_ID__c = prj.Id+'-'+NSP_ServiceConstants.QTP2+'-'+randomNumber);
                projTaskAssigmt2.pse__Project_Task__r = projectTaskReference2;
                
                //create project task
                pse__Project_Task__c projectTask = new pse__Project_Task__c();
                projectTask.Name = NSP_ServiceConstants.QTP1;
                projectTask.pse__Project__c = prj.Id;
                projectTask.RecordTypeId = peoProjectTaskRecordTypeId;
                projectTask.pse__Start_Date_Time__c = mapOfAccountIdAndRenewalDate.get( prj.pse__Account__c ).addDays( NSP_ServicePlanProjectTaskBatch.qtp1StartDays );
                projectTask.pse__End_Date_Time__c = mapOfAccountIdAndRenewalDate.get( prj.pse__Account__c ).addDays( NSP_ServicePlanProjectTaskBatch.qtp1EndDays );
                projectTask.NSP_Category__c = NSP_ServiceConstants.Client_Management;
                projectTask.NSP_Sub_Category__c = NSP_ServiceConstants.Quality_Touch_Point;
                projectTask.pse__External_Task_ID__c = prj.Id+'-'+NSP_ServiceConstants.QTP1+'-'+randomNumber;
                if ( ownerId != null ) {
                    projectTask.OwnerId = ownerId;     
                }
                
                lstOfRecords.add(projectTask);
                lstOfRecords.add(projTaskAssigmt);
                
                //create project task
                pse__Project_Task__c projectTask1 = new pse__Project_Task__c();
                projectTask1.Name = NSP_ServiceConstants.QTP2;
                projectTask1.pse__Project__c = prj.Id;
                projectTask1.RecordTypeId = peoProjectTaskRecordTypeId;
                projectTask1.pse__Start_Date_Time__c = mapOfAccountIdAndRenewalDate.get( prj.pse__Account__c ).addDays( NSP_ServicePlanProjectTaskBatch.qtp2StartDays );
                projectTask1.pse__End_Date_Time__c = mapOfAccountIdAndRenewalDate.get( prj.pse__Account__c ).addDays( NSP_ServicePlanProjectTaskBatch.qtp2EndDays );
                projectTask1.NSP_Category__c = NSP_ServiceConstants.Client_Management;
                projectTask1.NSP_Sub_Category__c = NSP_ServiceConstants.Quality_Touch_Point;
                projectTask1.pse__External_Task_ID__c = prj.Id+'-'+NSP_ServiceConstants.QTP2+'-'+randomNumber;
                if ( ownerId != null ) {
                    projectTask1.OwnerId = ownerId; 
                }
                lstOfRecords.add(projectTask1);
                lstOfRecords.add(projTaskAssigmt2);
            }
        }
        //insert projectTasklist if not empty
        if(lstOfRecords.size() > 0){
            lstOfRecords.sort();
            NSP_ProjectTasksTriggerServiceHelper.runOwnerAssignmentLogic = false;
            Database.SaveResult[] results = Database.insert(lstOfRecords, false);
            NSP_ErrorLogHandler.logResults(
                NSP_ServicePlanProjectTaskBatch.class.getName() ,
                'execute' ,
                results
            );
        }
    }

    // Method to get the owner Id from Account Teams
    private static String getOwnerIdFromAccountTeams( pse__Proj__c prj , Map<Id,List<NSP_Account_Team__c>> accountTeamMap ) {
        String ownerId = null;
        if ( accountTeamMap.containskey( prj.pse__Account__c ) ) {
            List<NSP_Account_Team__c> accountTeams = accountTeamMap.get( prj.pse__Account__c );
            if ( !accountTeams?.isEmpty() ) {
                for ( NSP_Account_Team__c accountTeam : accountTeams ) {
                    // Check if the Account Team is Primary
                    if ( accountTeam.NSP_Primary__c ) {
                        // If primary, assign the ownerId if the role is 'Business Team HRSP/CL'
                        if ( NSP_ServiceConstants.BUS_TEAM_HRSP_CL.equalsIgnoreCase( accountTeam.NSP_Role__c ) ) {
                            ownerId = accountTeam.NSP_User__c;
                        }
                    } else {
                        // If not primary, assign ownerId if the role is 'Business Team HRSP/CL'
                        if ( NSP_ServiceConstants.BUS_TEAM_HRSP_CL.equalsIgnoreCase( accountTeam.NSP_Role__c ) ) {
                            ownerId = accountTeam.NSP_User__c;
                        } else {
                            // If not primary, assign ownerId if the role is 'Manager HRServices' and it is primary
                            if ( NSP_ServiceConstants.MANAGER_HRSERVICES.equalsIgnoreCase( accountTeam.NSP_Role__c ) && accountTeam.NSP_Primary__c ) {
                                ownerId = accountTeam.NSP_User__c;
                            } else {
                                // If not primary, assign ownerId if the role is 'Manager HRServices'
                                if ( NSP_ServiceConstants.MANAGER_HRSERVICES.equalsIgnoreCase( accountTeam.NSP_Role__c ) ) {
                                    ownerId = accountTeam.NSP_User__c;
                                }
                            }
                        }
                    }
                }
            }
        }
        return ownerId;
    }


    
    //== Method to return the User Role
    private static String getRoleBasedOnOwnerId(String ownerId , pse__Proj__c prj,  Map<Id,List<NSP_Account_Team__c>> accountTeamMap )
    {
        String roleName = null;
        if ( ownerId != null && accountTeamMap.containskey( prj.pse__Account__c ) ) 
        {
            List<NSP_Account_Team__c> accountTeams = accountTeamMap.get( prj.pse__Account__c );
            if ( !accountTeams?.isEmpty() ) 
            {
                for ( NSP_Account_Team__c accountTeam : accountTeams ) 
                {
                    if( accountTeam.NSP_User__c == ownerId )
                    {
                        roleName = accountTeam.NSP_Role__c;
                    }
                }
            }
        }
        
        return roleName;
    }

    //== Method to return the Account Team Map 
    private static Map<Id,List<NSP_Account_Team__c>> getAccountTeamMap( Set<Id> accountIdSet ) {
        Map<Id,List<NSP_Account_Team__c>> accountTeamMap = new Map<Id,List<NSP_Account_Team__c>>();
        // check accountIDset not empty
        if ( !accountIdSet.isEmpty() ) {
            List<NSP_Account_Team__c> accountTeamList = NSP_ServicePlanProjectTaskBatch.getAccountTeamQuery( accountIdSet );
            for ( NSP_Account_Team__c team : accountTeamList ) {
                if ( team != null ) {
                    if ( !accountTeamMap.containsKey( team.NSP_Account__c ) ) {
                        accountTeamMap.put( team.NSP_Account__c , new List<NSP_Account_Team__c>() );
                    }
                    accountTeamMap.get( team.NSP_Account__c ).add( team );
                }
            }
        }
        return accountTeamMap;
    }

    public void finish( Database.BatchableContext bc ){
    }

    //
    // @param accountIds Set of accountIds that is associated with project Account
    // @return void
    //
    public static List<NSP_Account_Team__c> getAccountTeamQuery( Set<Id> accountIds ) {
        List<String> roles = new List<String>{
            NSP_ServiceConstants.MANAGER_HRSERVICES ,
            NSP_ServiceConstants.BUS_TEAM_HRSP_CL
        };
        List<NSP_Account_Team__c> accountTeamList = [
            SELECT Id , NSP_Account__c , NSP_Role__c , NSP_User__c , NSP_Primary__c , NSP_First_Name__c
            FROM NSP_Account_Team__c
            WHERE (
                ( NSP_Role__c = :roles )
                AND ( NSP_Account__c = :accountIds )
            )
            WITH SECURITY_ENFORCED
        ];
        return accountTeamList;
    }
    

    //
    // attributes controlled by Custom Settings...
    // ~ intentionlly static to allow Custom Settings to modify the attributes a Scheduled job...
    //

    private static ServicePlanProjectTaskBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = ServicePlanProjectTaskBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Integer renewalDateLookupDays {
        private get {
            if ( renewalDateLookupDays == null ) {
                Integer local = 0;
                if ( ( NSP_ServicePlanProjectTaskBatch.settings != null )
                    && ( NSP_ServicePlanProjectTaskBatch.settings.RenewalDateLookupDays__c != null )
                    )
                {
                    local = NSP_ServicePlanProjectTaskBatch.settings.RenewalDateLookupDays__c.intValue();
                }
                // must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                renewalDateLookupDays = local;
            }
            return renewalDateLookupDays;
        }
        private set;
    }

    private static Integer qtp1StartDays {
        private get {
            if ( qtp1StartDays == null ) {
                Integer local = 90;
                if ( ( NSP_ServicePlanProjectTaskBatch.settings != null )
                    && ( NSP_ServicePlanProjectTaskBatch.settings.QTP1StartDays__c != null )
                    )
                {
                    local = NSP_ServicePlanProjectTaskBatch.settings.QTP1StartDays__c.intValue();
                }
                // value must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                qtp1StartDays = local;
            }
            return qtp1StartDays;
        }
        private set;
    }

    private static Integer qtp1EndDays {
        private get {
            if ( qtp1EndDays == null ) {
                Integer local = 120;
                if ( ( NSP_ServicePlanProjectTaskBatch.settings != null )
                    && ( NSP_ServicePlanProjectTaskBatch.settings.QTP1EndDays__c != null )
                    )
                {
                    local = NSP_ServicePlanProjectTaskBatch.settings.QTP1EndDays__c.intValue();
                }
                // end days must be greater than or equal to start days...
                if ( local < NSP_ServicePlanProjectTaskBatch.qtp1StartDays ) {
                    local = NSP_ServicePlanProjectTaskBatch.qtp1StartDays;
                }
                qtp1EndDays = local;
            }
            return qtp1EndDays;
        }
        private set;
    }

    private static Integer qtp2StartDays {
        private get {
            if ( qtp2StartDays == null ) {
                Integer local = 185;
                if ( ( NSP_ServicePlanProjectTaskBatch.settings != null )
                    && ( NSP_ServicePlanProjectTaskBatch.settings.QTP2StartDays__c != null )
                    )
                {
                    local = NSP_ServicePlanProjectTaskBatch.settings.QTP2StartDays__c.intValue();
                }
                // value must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                qtp2StartDays = local;
            }
            return qtp2StartDays;
        }
        private set;
    }

    private static Integer qtp2EndDays {
        private get {
            if ( qtp2EndDays == null ) {
                Integer local = 215;
                if ( ( NSP_ServicePlanProjectTaskBatch.settings != null )
                    && ( NSP_ServicePlanProjectTaskBatch.settings.QTP2EndDays__c != null )
                    )
                {
                    local = NSP_ServicePlanProjectTaskBatch.settings.QTP2EndDays__c.intValue();
                }
                // end days must be greater than or equal to start days...
                if ( local < NSP_ServicePlanProjectTaskBatch.qtp2StartDays ) {
                    local = NSP_ServicePlanProjectTaskBatch.qtp2StartDays;
                }
                qtp2EndDays = local;
            }
            return qtp2EndDays;
        }
        private set;
    }

}