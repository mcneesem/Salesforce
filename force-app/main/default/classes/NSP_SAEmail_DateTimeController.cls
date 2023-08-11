/*
 *
* @description  :  Controller class for  vf component to get the Date/time in user's time zone instead of in GMT.
* @date 06/08/2023
* Author : Harsha Khiroya
* Name : NSP_SAEmail_DateTimeController
*/

public class NSP_SAEmail_DateTimeController {
    
	public DateTime date_time {get;set;}
    public String defined_format {get;set;}
    public DateTime startDate {get;set;}
    public DateTime endDate {get;set;}
    public String operatingHrsName {get;set;}
    //store service appointment Id
    public static String recId;
    //Store Operating Hrs Name
    public static String operHrsCancelSA;
   
    //set the service appointment Id from the component current record Id
    public static void setrecId (String recordId) {
        recId = recordId;
    }
    //get recordId
    public static String getrecId() {
        return recId;
    } 
    
    /***********************************************************************************************
    MethodName: getAssignedResource
    Description: This method is used to retrieve the assigned resource for a specific service appointment. 
    Params: None
    ********************************************************************************************/
    public AssignedResource getAssignedResource() {
        // Query the service appointment record
        List<String> assResourceFields = new List<String>{'Id','ServiceAppointmentId','ServiceResourceId'};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.ASSIGNEDRES_SOBJECT_NAME, assResourceFields)
            					.addFilter('ServiceAppointmentId', recId)
            					.addLimit(1).build();
        AssignedResource assignRes = Database.query(query);
        return assignRes;
    }
    
    /************************************************************************************************
    MethodName: getOperatingHours
    Description: This method retrieves the operating hours for a specific service appointment by querying the assigned resource and service territory records.
    Params: None
    ***********************************************************************************************/
    public String getOperatingHours() {
        
        AssignedResource assignRes = getAssignedResource();
        // Query the service territory record from Service Terr Mem for Assign Service Resource
        ServiceTerritory serviceTerr = [SELECT Id, OperatingHoursId, TopLevelTerritoryId
                                    FROM ServiceTerritory
                                    WHERE Id IN (
                                        SELECT ServiceTerritoryId
                                        FROM ServiceTerritoryMember
                                        WHERE ServiceResourceId =: assignRes.ServiceResourceId
                                    )];
        //query operating hrs 
        List<String> operHrsFields = new List<String>{'Id','Name'};
        String query = new NSP_QueryBuilder('OperatingHours', operHrsFields)
            					.addFilter('Id', serviceTerr.OperatingHoursId)
            					.addLimit(1).build();
        OperatingHours operHrs = Database.query(query);
        //return operating hrs name
        return operHrs.Name;
    }
    
    /***********************************************************************************************
    MethodName: getOperatingHoursName
    Description : This method returns the name of the operating hours based on the operating hours value.
    Params: None
    Return: String (Operating Hrs Name)
    ********************************************************************************************/
    public String getOperatingHoursName() {
    	Map<String,String> operatingNames = new Map<String,String>{'EST'=> NSP_ServiceConstants.OPR_HRS_EST,'CST'=> NSP_ServiceConstants.OPR_HRS_CST,'PST'=> NSP_ServiceConstants.OPR_HRS_PST};
        String operatingHrs = !checkStatusofSA() ? getOperatingHours(): operHrsCancelSA;
        operatingHrsName = operatingNames.get(operatingHrs);    
        return operatingHrsName;
    }
    
    /***********************************************************************************************
    MethodName: getOperatingHoursName
    Description : This method returns the true or false basef on service appointment status
    Params: None
    Return: Booleab(True if service appointment status is canceled and false if not)
    ********************************************************************************************/
    public Boolean checkStatusofSA(){
        List<String> servicAppFields = new List<String>{'Id','NSP_Old_Operating_Hrs__c','Status'};
        String query = new NSP_QueryBuilder(NSP_ServiceConstants.SA_SOBJECT_NAME, servicAppFields)
            					.addFilter('Id', recId)
            					.addLimit(1).build();
        ServiceAppointment serviceApp = Database.query(query);
        operHrsCancelSA = serviceApp.Status == NSP_ServiceConstants.PROJECT_TASK_CANCELLED ? serviceApp.NSP_Old_Operating_Hrs__c: '';
        return serviceApp.Status == NSP_ServiceConstants.PROJECT_TASK_CANCELLED ? true: false;
    }
    
    public String getFormattedDatetime() {
       
       String operatingHrs;
       //get the operating hrs name
       operatingHrs = !checkStatusofSA() ? getOperatingHours(): operHrsCancelSA;
       return date_time.format(defined_format, operatingHrs); //Specify Time zone like IST,CST
    }
    
    public String getStartTime(){
        return date_time.format('hh:mm aa');
    }
    
    public String getEndTime(){
        return endDate.format('hh:mm aa');
    }
    
}