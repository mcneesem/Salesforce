/*
 *
* @description  :  Controller class for  vf component to get the Date/time in user's time zone instead of in GMT.
* @date 06/08/2023
* Author : Harsha Khiroya
* Name : NSP_SAEmail_DateTimeController
*/

public class NSP_SAEmail_DateTimeController {
    // test w/ NSP_SAEmail_DateTimeControllerTest (??%)

	public DateTime date_time {get;set;}
    public String defined_format {get;set;}
    public DateTime startDate {get;set;}
    public DateTime endDate {get;set;}
    public String operatingHrsName {get;set;}
    //store service appointment Id
    public static String recId;
   
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
    Description: This method is used to retrieve the service appointment. 
    Params: None
    ********************************************************************************************/
    public ServiceAppointment getServiceAppointment() {
        // Query the service appointment record
       List<String> servicAppFields = new List<String>{'Id','ServiceTerritoryId'};
       String query = new NSP_QueryBuilder(NSP_ServiceConstants.SA_SOBJECT_NAME, servicAppFields)
            					.addFilter('Id', recId)
            					.addLimit(1).build();
        ServiceAppointment serviceApp = Database.query(query);
        return serviceApp;
    }
    
    /************************************************************************************************
    MethodName: getOperatingHours
    Description: This method retrieves the operating hours for a specific service appointment by querying the assigned resource and service territory records.
    Params: None
    ***********************************************************************************************/
    public OperatingHours getOperatingHours() {
        
        ServiceAppointment serviceApp =  getServiceAppointment();
        // Query the service territory record from Service Terr Mem for Assign Service Resource
        ServiceTerritory serviceTerr = [SELECT Id, OperatingHoursId, TopLevelTerritoryId
                                    FROM ServiceTerritory
                                    WHERE Id =: serviceApp.ServiceTerritoryId];
        //query operating hrs 
        List<String> operHrsFields = new List<String>{'Id','Name', 'TimeZone'};
        String query = new NSP_QueryBuilder('OperatingHours', operHrsFields)
            					.addFilter('Id', serviceTerr.OperatingHoursId)
            					.addLimit(1).build();
        OperatingHours operHrs = Database.query(query);
        //return operating hrs name
        return operHrs;
    }
    
     /***********************************************************************************************
    MethodName: getOperatingHoursName
    Description : This method returns the name of the operating hours based on the operating hours value.
    Params: None
    Return: String (Operating Hrs Name)
    ********************************************************************************************/
    public String getOperatingHoursName() {
    	Map<String,String> operatingNames = new Map<String,String>{'EST'=> NSP_ServiceConstants.OPR_HRS_EST,'CST'=> NSP_ServiceConstants.OPR_HRS_CST,'PST'=> NSP_ServiceConstants.OPR_HRS_PST};
        operatingHrsName = operatingNames.get(getOperatingHours().Name);    
        return operatingHrsName;
    }
    
   public String getFormattedDatetime() {
       
       return date_time.format(defined_format, getOperatingHours().TimeZone); //Specify Time zone like IST,CST
    }
    
    public String getStartTime(){
        return date_time.format('hh:mm aa',getOperatingHours().TimeZone);
    }
    
    public String getEndTime(){
        return endDate.format('hh:mm aa',getOperatingHours().TimeZone);
    }
    
}