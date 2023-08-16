/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  FEB 28, 2023                                                             
Function             :  This Class describes about checking whether the Parent Project and selected project task is PEO or Not.
Test class           :  NSP_CreateProjectTaskControllerTest
Story                : STY-04028                                                                      
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  
***************************************************************************************************/
public class NSP_CreateProjectTaskController {
    private static final List<String> PROJECT_FIELDS = new List<String>{'Id','recordTypeId','recordType.DeveloperName'};
        private static final List<String> PROJECT_TASK_FIELDS = new List<String>{'Id','pse__Project__c'};
         
        /**
* @MethodName: getPeoProjectRelatedRecordTypes
* @Description: This method describes about checking whether the Parent Project and selected project task is PEO or Not..
    * @param : String selectedRecordTypeName, String projectId
* @createdDate : 02/28/2023
* @Story : STY-04038
* @return void                          
*/

        @AuraEnabled
        public static Boolean getPeoProjectRelatedRecordTypes(String selectedRecordTypeName, String projectId){
            List<String> peoProjectRelatedRecTypes = new List<String>{NSP_ServiceConstants.PROJECT_PEO_RECORDTYPE, NSP_ServiceConstants.PEO_BILL_RECORDTYPE};
                try{
                    if(String.isNotBlank(selectedRecordTypeName) && String.isNotBlank(projectId)){
                        String queryProj = new NSP_QueryBuilder('pse__Proj__c', PROJECT_FIELDS)
                            .addFilter('Id', String.escapeSingleQuotes(projectId)).addLimit(1).build();
                        List<pse__Proj__c> getParentProject = Database.query(queryProj);
                        if(!getParentProject.isEmpty()){
                            return (peoProjectRelatedRecTypes.contains(getParentProject[0].recordType.DeveloperName) && String.escapeSingleQuotes(selectedRecordTypeName) == NSP_ServiceConstants.PEO_PROJECT_TASK_NAME);
                        }
                    }        
                    return false;
                }catch (Exception except) { throw new AuraHandledException(except.getMessage()); }
        }
    
           /**
     @MethodName: getProjectIdFromProjectTask
     @Description: This method describes about fetching project from project task
     @param : String projectTaskId
     @createdDate : 03/14/2023
     @Story : STY-04038
     @return void                          
*/
    @AuraEnabled
    public static String getProjectIdFromProjectTask(String projectTaskId){
        try{
            if(String.isNotBlank(projectTaskId)){
                String peoPrjTaskQuery = new NSP_QueryBuilder('pse__Project_Task__c', PROJECT_TASK_FIELDS)
                    .addFilter('Id', String.escapeSingleQuotes(projectTaskId))
                    .addLimit(1).build();
                List<pse__Project_Task__c> projectTaskList = Database.query(peoPrjTaskQuery);
                return !projectTaskList.isEmpty() ? projectTaskList[0].pse__Project__c : NSP_ServiceConstants.EMPTY_STRING;
            }else{
                return NSP_ServiceConstants.EMPTY_STRING;
            }
        }catch (Exception except) { throw new AuraHandledException(except.getMessage()); }
    }
}