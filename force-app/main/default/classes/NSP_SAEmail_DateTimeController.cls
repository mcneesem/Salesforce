// intentionally `without sharing` to preserve default sharing at api version 57...
public without sharing class NSP_SAEmail_DateTimeController {
    // test w/ NSP_SAEmail_DateTimeControllerTest (84%)

    public DateTime date_time {get;set;}
    public String defined_format {get;set;}
    public DateTime startDate {get;set;}
    public DateTime endDate {get;set;}
    public String operatingHrsName {get;set;}
    //store service appointment Id
    public static String recId;

    // Caching variables
    private ServiceAppointment serviceApp;
    private OperatingHours operHrs;

    //set the service appointment Id from the component current record Id
    public static void setrecId( String recordId ) {
        recId = recordId;
    }

    //get recordId
    public static String getrecId() {
        return recId;
    }

    //
    // MethodName: getAssignedResource
    // Description: This method is used to retrieve the service appointment.
    // Params: None
    //
    public ServiceAppointment getServiceAppointment() {
        // Query the service appointment record
        if ( recId != null && serviceApp == null ) {
            List<String> servicAppFields = new List<String>{
                'Id' ,
                'ServiceTerritoryId'
            };
            String query = new NSP_QueryBuilder( NSP_ServiceConstants.SA_SOBJECT_NAME , servicAppFields )
                .addFilter( 'Id' , recId )
                .addLimit( 1 )
                .build();
            serviceApp = Database.query( query );
        }
        return serviceApp;
    }

    //
    // MethodName: getOperatingHours
    // Description: This method retrieves the operating hours for a specific service appointment by querying the assigned resource and service territory records.
    // Params: None
    //
    public OperatingHours getOperatingHours() {
        if ( operHrs == null ) {
            ServiceAppointment serviceApp = this.getServiceAppointment();
            if ( ( serviceApp != null ) && ( serviceApp.ServiceTerritoryId != null ) ) {
                // Query the service territory record from Service Terr Mem for Assign Service Resource
                ServiceTerritory serviceTerr = null;
                List<ServiceTerritory> serviceTerrList = [
                    SELECT Id , OperatingHoursId , TopLevelTerritoryId
                    FROM ServiceTerritory
                    WHERE ( Id = :serviceApp.ServiceTerritoryId )
                ];
                if ( !serviceTerrList.isEmpty() ) {
                    serviceTerr = serviceTerrList[0];
                }
                //query operating hrs
                if ( ( serviceTerr != null ) && ( serviceTerr.OperatingHoursId != null ) ) {
                    List<String> operHrsFields = new List<String>{
                        'Id' ,
                        'Name' ,
                        'TimeZone'
                    };
                    String query = new NSP_QueryBuilder( 'OperatingHours' , operHrsFields )
                        .addFilter( 'Id' , serviceTerr.OperatingHoursId )
                        .addLimit( 1 )
                        .build()
                        ;
                    operHrs = Database.query( query );
                }
            }
        }
        //return operating hrs name
        return operHrs;
    }

    //
    // MethodName: getOperatingHoursName
    // Description : This method returns the name of the operating hours based on the operating hours value.
    // Params: None
    // Return: String (Operating Hrs Name)
    //
    public String getOperatingHoursName() {
        OperatingHours operHrs = getOperatingHours();
        if ( operHrs != null && operHrs.Name != null ) {
            Map<String,String> operatingNames = new Map<String,String>{
                'EST'=> NSP_ServiceConstants.OPR_HRS_EST ,
                'CST'=> NSP_ServiceConstants.OPR_HRS_CST ,
                'PST'=> NSP_ServiceConstants.OPR_HRS_PST
            };
            if ( operatingNames.containsKey( operHrs.Name ) ) {
                operatingHrsName = operatingNames.get( operHrs.Name );
            }
        }
        return operatingHrsName;
    }

    public String getFormattedDatetime() {
        OperatingHours operHrs = getOperatingHours();
        String formattedDateTime = null;
        if ( operHrs != null
            && operHrs.TimeZone != null
            && date_time != null
            && defined_format != null
            )
        {
            formattedDateTime = date_time.format( defined_format , operHrs.TimeZone ); //Specify Time zone like IST,CST
        }
        return formattedDateTime;
    }

    public String getStartTime(){
        OperatingHours operHrs = getOperatingHours();
        String startTime = null;
        if ( operHrs != null
            && operHrs.TimeZone!= null
            && date_time != null
            )
        {
            startTime = date_time.format( 'hh:mm aa' , operHrs.TimeZone );
        }
        return startTime;
    }

    public String getEndTime(){
        OperatingHours operHrs = getOperatingHours();
        String endTime = null;
        if ( operHrs != null
            && operHrs.TimeZone != null
            && endDate != null
            )
        {
            endTime = endDate.format( 'hh:mm aa' , operHrs.TimeZone );
        }
        return endTime;
    }

}
//
