public without sharing class NSP_WC_NotificationController {
    // test w/ NSP_WC_NotificationControllerTest (97%)

    private static Map<String,String> statesApiAndNames = new Map<String,String>{
        'MA'=>'Massachusetts' ,
        'NY'=>'New York' ,
        'VA'=>'Virginia' ,
        'RI'=>'Rhode Island'
    };

    public static String recId;

    //set recordId
    public static void setrecId (String recordId) {
        recId = recordId;
    }

    //get recordId
    public static String getrecId() {
        return recId;
    } 
    
    //get Implemtation profile record based on the recordId
    public static Implementation_Profile__c imptProfile {
        public get {
            if ( recId != null ) {
                List<Implementation_Profile__c> records = [
                    SELECT
                        Id ,
                        toLabel( Employees_work_in_the_following_states__c ) ,
                        Effective_Date_Payroll_Worker_comp_EPLI__c ,
                        RecordType.Name ,
                        Client_does_business_in_MA_NY_or_VA__c ,
                        NSP_Business_Meeting_States__c
                    FROM Implementation_Profile__c
                    WHERE ( Id = :recId )
                    LIMIT 1
                ];
                if ( !records.isEmpty() ) {
                    imptProfile = records[0];
                }
            }
            return imptProfile;
        }
        public set;
    }
    
    //get Implemtation profile record based on the employeeWork values
    public static String employeesWhoWork{
        get{
            if ( imptProfile != null ){
                if(imptProfile.Employees_work_in_the_following_states__c != null){
                    Set<String> statesRequired = new Set<String> {'Massachusetts','New York','Rhode Island','Virginia'};
                    List<String> allEmpWorkList = imptProfile.Employees_work_in_the_following_states__c.split(';');
                    List<String> checkEmpWork = new List<String>();
                    for(String empWork : allEmpWorkList ){
                        if(statesRequired.contains(empWork)){
                            checkEmpWork.add(empWork);
                        }
                    }
                    if(!checkEmpWork.isEmpty()){
                         employeesWhoWork = String.join(checkEmpWork, ', ');
                    }           
                }
            }
            return employeesWhoWork;
        }
        set;
    }

    //get Implemtation profile record based on the employeeWork values
    public static String clientDoesBusiness{
        get{
            if ( imptProfile != null && String.isNotBlank(imptProfile.NSP_Business_Meeting_States__c)){
                List<String> allClientWorkList = imptProfile.NSP_Business_Meeting_States__c.split(';');
                    List<String> checkclientBusiness = new List<String>();
                    for(String clientWork : allClientWorkList ){
                        if(statesApiAndNames.containsKey(clientWork)){
                            checkclientBusiness.add(statesApiAndNames.get(clientWork));
                        }
                    }
                    if(!checkclientBusiness.isEmpty()){
                        clientDoesBusiness = String.join(checkclientBusiness, ', ');
                    }           
            }
            return clientDoesBusiness;
        }
        set;
    }
    
    //get Implemtation profile record based on the employeeWork values
    public static List<String> employeesWhoWorkList{
        get{
            if ( imptProfile != null ){
                if(imptProfile.Employees_work_in_the_following_states__c != null){
                    Set<String> statesRequired = new Set<String> {'Wyoming','North Dakota','Washington','Ohio'};
                    List<String> allEmpWorkList = imptProfile.Employees_work_in_the_following_states__c.split(';');
                    List<String> finalEmpWork = new List<String>();
                    for(String empWork : allEmpWorkList ){
                        if(statesRequired.contains(empWork)){
                              finalEmpWork.add(empWork);
                        }
                    }
                    employeesWhoWorkList = finalEmpWork;
                }
            }
            return employeesWhoWorkList;
        }
        set;
    }
    
    
}