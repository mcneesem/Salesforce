/**
Apex Class Name      :  NSP_WXBenefitsRenewalProjectCreation
Version              :  1.0 
Author               :  Simran
Function             :  Creates Project with WX Rebewal Template
Story                :  As part of STY-02160
*/

public class NSP_WXBenefitsRenewalProjectCreation implements ISelfSchedulable, Schedulable,Database.Batchable<sObject> 
{
    
    // test w/ NSP_WXBenefitsRenewalProjCreat_Test (96%)
    
    private schema.SObjectField fieldApiName = null;
    
    /************************ CONSTRUCTORS *********************************/
    //== Constructor Method
    public NSP_WXBenefitsRenewalProjectCreation(string fieldName)
    {
        Map<String, schema.SObjectField> fieldMap 	= Asset.SObjectType.getDescribe().fields.getMap();
        
        // property setting
        if(string.isNotBlank(fieldName) && fieldMap.containsKey(fieldName))
        {
            this.fieldAPIName = fieldMap.get(fieldName);
        }
    }
    
    //== Default Constructor
    public NSP_WXBenefitsRenewalProjectCreation()
    {
        
    }
    
    //== Execute Method
    public void execute(SchedulableContext scon) 
    {  
        Benefits_Renewal_Batch_Settings__c settingsLocal = Benefits_Renewal_Batch_Settings__c.getInstance(UserInfo.getUserId());
        if(settingsLocal != null)
        {       
            if(settingsLocal.IsEnabledDefault__c == true)
            {
                //Executes Batch for Medical Benefits Renewal Date
                Database.executeBatch(new NSP_WXBenefitsRenewalProjectCreation('Medical_Benefits_Renewal_Date__c'), 1);
            }
            
            if(settingsLocal.IsEnabledAncillary__c == true)
            {
                // Execute Batch for Ancillary Benefits Renewal Date
                Database.executeBatch(new NSP_WXBenefitsRenewalProjectCreation('Ancillary_Benefits_Renewal_Date__c'), 1);
                
            }
            
            if(settingsLocal.IsEnabledFringe__c == true)
            {
                // Execute Batch for Fringe Benefits Renewal Date
                Database.executeBatch(new NSP_WXBenefitsRenewalProjectCreation('Fringe_Benefits_Renewal_Date__c'), 1);
            }
        }
    }
    
    public static string schedule()
    {
        String suffix = '';
        if ( Test.isRunningTest() ) 
        {
            suffix = ' ~ TEST';
        }
        
        return System.schedule(
            'NSP_WXBenefitsRenewalProjectCreation ~ When a WX asset has a Benefits Renewal Date field populated = Today + 65 Days, then the system creates WX Benefits Renewal project & related task linked to the WX asset record ~ Everyday 1 am' + suffix,
            '0 0 1 * * ?',
            new NSP_WXBenefitsRenewalProjectCreation()
        );
    }
    
    //== Start Method
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        // Helper variables
        Date comparingDate 				= Date.today().addDays(75);
        Id WX_RECORDTYPE_ID 			= NSP_GenericRecordType.getRecordTypeId('Asset', 'NSP_Asset_Product');
        List<String> excludeAssetStatus = new List<string>{'Terminated', 'Backout'};
            String formattedStatusValues 	= '\'' + String.join(excludeAssetStatus, '\',\'') + '\'';
        
        string query = 'SELECT ID FROM Asset WHERE ID = NULL';
        if(fieldAPIName != null)
        {
            query = ('SELECT ID, RecordTypeId, AccountId, Status,  ' + 
                        fieldAPIName + 
                        ' FROM Asset ' + 
                        ' WHERE ' + 
                        fieldAPIName + 
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
        }
                
        return Database.getQueryLocator(query);
    }
    
    //== Executing the business logic
    public void execute(Database.BatchableContext bc, List<Asset> listOfAssets)
    {
        try
        {            
            WXBenefitsRenewalProjectHelper helpClass = new WXBenefitsRenewalProjectHelper();
            helpClass.createProjectFromTemplateBasedOnAccountAndAsset(listOfAssets);
        }
        catch(Exception ex)
        {
            NSP_ErrorLogHandler.logException(
                NSP_WXBenefitsRenewalProjectCreation.class.getName() ,
                'execute' ,
                ex
                );
        }
        
    }
    
    //== Finish Method
    public void finish(Database.BatchableContext bc)
    {
        
    }
}