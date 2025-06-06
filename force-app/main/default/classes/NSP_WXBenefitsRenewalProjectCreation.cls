/**
Apex Class Name      :  NSP_WXBenefitsRenewalProjectCreation
Version              :  1.0 
Author               :  Simran
Function             :  Creates Project with WX Rebewal Template
Story                :  As part of STY-02160
*/

/********************************** SAMPLE EXECUTION ************************************/
// NSP_WXBenefitsRenewalProjectCreation.RequestWrapper reqWrapper = new NSP_WXBenefitsRenewalProjectCreation.RequestWrapper();
// reqWrapper.fieldName        									= 'Medical_Benefits_Renewal_Date__c';
// reqWrapper.role             									= 'WX Open Enrollment Specialist';
// reqWrapper.daysCount        									= 75;
// reqWrapper.templateName     									= 'NSP_WX_Benefits_Renewal_Project';
//  reqWrapper.excludeAssetStatus 									= new List<string>{'Terminated', 'Backout'};
// 
// Database.executeBatch(new NSP_WXBenefitsRenewalProjectCreation(reqWrapper), 1);



public class NSP_WXBenefitsRenewalProjectCreation implements ISelfSchedulable, Schedulable,Database.Batchable<sObject> 
{
    // test w/ NSP_WXBenefitsRenewalProjCreat_Test (96%)
    
    /************************* GLOBAL VARIABLES *****************************/
    public RequestWrapper batchClassWrapper;
    
    /************************ CONSTRUCTORS *********************************/
    //== Constructor Method
    public NSP_WXBenefitsRenewalProjectCreation(RequestWrapper requestWrapper)
    {
        Map<String, schema.SObjectField> fieldMap 	= Asset.SObjectType.getDescribe().fields.getMap();
        this.batchClassWrapper 							= requestWrapper;
        
        // property setting
        if(fieldMap.containsKey(requestWrapper.fieldName))
        {
            this.batchClassWrapper.fieldAPIName = fieldMap.get(requestWrapper.fieldName);
        }
    }
    
    //== Execute Method
    public void execute(SchedulableContext scon) 
    {           
        //Executes Batch for Medical Benefits Renewal Date
        Database.executeBatch(new NSP_WXBenefitsRenewalProjectCreation(batchClassWrapper), 1);
        
        // Execute Batch for Ancillary Benefits Renewal Date
        batchClassWrapper.fieldName        									= 'Ancillary_Benefits_Renewal_Date__c';
        Database.executeBatch(new NSP_WXBenefitsRenewalProjectCreation(batchClassWrapper), 1);
        
        // Execute Batch for Fringe Benefits Renewal Date
        batchClassWrapper.fieldName        									= 'Fringe_Benefits_Renewal_Date__c';
        Database.executeBatch(new NSP_WXBenefitsRenewalProjectCreation(batchClassWrapper), 1);
    }

    public static string schedule()
    {
        NSP_WXBenefitsRenewalProjectCreation.RequestWrapper reqWrapper 	= new NSP_WXBenefitsRenewalProjectCreation.RequestWrapper();
        reqWrapper.fieldName        									= 'Medical_Benefits_Renewal_Date__c';
        reqWrapper.role             									= 'WX Open Enrollment Specialist';
        reqWrapper.daysCount        									= 75;
        reqWrapper.templateName     									= 'NSP_WX_Benefits_Renewal_Project';
        reqWrapper.excludeAssetStatus 									= new List<string>{'Terminated', 'Backout'};


        String suffix = '';
        if ( Test.isRunningTest() ) 
        {
            suffix = ' ~ TEST';
        }

        return System.schedule(
            'NSP_WXBenefitsRenewalProjectCreation ~ When a WX asset has a Benefits Renewal Date field populated = Today + 65 Days, then the system creates WX Benefits Renewal project & related task linked to the WX asset record ~ Everyday 1 am' + suffix,
            '0 0 1 * * ?',
            new NSP_WXBenefitsRenewalProjectCreation(reqWrapper)
        );
    }
    
    //== Start Method
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        // Helper variables
        Date comparingDate 				= Date.today().addDays(batchClassWrapper.daysCount);
        Id WX_RECORDTYPE_ID 			= NSP_GenericRecordType.getRecordTypeId('Asset', 'NSP_Asset_Product');
        String formattedStatusValues 	= '\'' + String.join(batchClassWrapper.excludeAssetStatus, '\',\'') + '\'';
        
        string query = ('SELECT ID, RecordTypeId, AccountId, Status,  ' + 
                        batchClassWrapper.fieldAPIName + 
                        ' FROM Asset ' + 
                        ' WHERE ' + 
                        batchClassWrapper.fieldAPIName + 
                        ' = ' + 
                        String.ValueOf(comparingDate) + 
                        ' AND ' +
                        ' RecordTypeId =: WX_RECORDTYPE_ID ' +
                        ' AND ' + 
                        ' Status NOT IN ( ' + 
                        formattedStatusValues + 
                        ' ) '  + 
                        ' WITH SECURITY_ENFORCED'
                       );
        
        System.debug(LoggingLevel.WARN, ' Query string : ' + query);
        
        return Database.getQueryLocator(query);
    }
    
    //== Executing the business logic
    public void execute(Database.BatchableContext bc, List<Asset> listOfAssets)
    {
        try
        {
            System.debug(LoggingLevel.WARN, ' Asset List : ' + listOfAssets);
            // Preparing the request for Helper class
            WXBenefitsRenewalProjectHelper.RequestWrapper helperReqWrapper = new WXBenefitsRenewalProjectHelper.RequestWrapper();
            helperReqWrapper.assetList		= listOfAssets;
            helperReqWrapper.className 		= 'NSP_WXBenefitsRenewalProjectCreation';
            helperReqWrapper.methodName 	= 'execute';
            helperReqWrapper.role 			= batchClassWrapper.role;
            helperReqWrapper.templateName 	= batchClassWrapper.templateName;
            
            WXBenefitsRenewalProjectHelper helpClass = new WXBenefitsRenewalProjectHelper();
            helpClass.createProjectFromTemplateBasedOnAccountAndAsset(helperReqWrapper);
        }
        catch(Exception ex)
        {
            NSP_ErrorLogHandler.logException('NSP_WXBenefitsRenewalProjectCreation', 'execute', ex);
        }
        
    }
    
    //== Finish Method
    public void finish(Database.BatchableContext bc)
    {
        
    }
    
    //== REQUEST WRAPPER CLASS
    public class RequestWrapper
    {
        public schema.SObjectField fieldAPIName { get; set; }
        public string role { get; set; }
        public integer daysCount { get; set; }
        public string fieldName { get; set; }
        public string templateName { get; set; }
        public List<string> excludeAssetStatus { get; set; }
    }
}