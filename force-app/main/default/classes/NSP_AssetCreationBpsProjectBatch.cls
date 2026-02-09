public class NSP_AssetCreationBpsProjectBatch implements ISelfSchedulable , Schedulable , Database.Batchable<sObject> {
    // test w/ NSP_AssetCreationBpsProjectBatch_Test (85%)

    private static final Map<Id,Project_Account__c> accIdWithProject = new Map<Id,Project_Account__c>();
    private static final Map<Id,Set<String>> mapAcctIdwithProjTemp = new Map<Id,Set<String>>();
    private static final Map<Id,Set<String>> mapAcctIdwithAssetRecType = new Map<Id,Set<String>>();

    //
    // Schedulable
    //

    public void execute( SchedulableContext sc ) {
        Database.executeBatch( new NSP_AssetCreationBpsProjectBatch() , 200 );
    }

    // runs everyday at 12am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_AssetCreationBpsProjectBatch ~ When an active account is added to a BPS project AND it does not have an existing Asset that corresponds to the project template THEN an Asset will be created automatically ~ everyday at 12 AM' + suffix ,
            '0 0 0 ? * * *' ,
            new NSP_AssetCreationBpsProjectBatch()
        );
    }

    //
    // Batchable
    //

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        List<String> projectFields = new List<String>{
            'Id' ,
            'Account__c' ,
            'Account__r.Name' ,
            'Account__r.NSP_AIMS_Client__c' ,
            'Project__c' ,
            'Project__r.TemplateName__c' ,
            'Project__r.recordTypeId' ,
            'Account__r.NSP_Sales_Service_Account_Status__c'
        };
        List<String> templateNames = new List<String>{
            NSP_ServiceConstants.ITA_IMPLEMENTATION ,
            NSP_ServiceConstants.PERFORMSMART_IMPLEMENTATION ,
            NSP_ServiceConstants.INTEGRA_IMPLEMENTATION ,
            NSP_ServiceConstants.XML_IMPLEMENTATION
        };

        String query = new NSP_QueryBuilder( 'Project_Account__c' , projectFields )
            .addFilter( 'Project__r.recordTypeId', NSP_GenericRecordType.getRecordTypeId( 'pse__Proj__c' , 'TES_BPS' ) )
            .addFilter( 'Account__r.NSP_Sales_Service_Account_Status__c' , 'Active' )
            .addFilter( 'Project__r.TemplateName__c' , templateNames , NSP_QueryBuilder.Operator.INCLUDES )
            .build();
        return Database.getQueryLocator( query );
    }

    public void execute( Database.BatchableContext bc , List<Project_Account__c> projAccounts ) {
        try {
            Map<String,String> mapOfProjTempServiceAsset = new Map<String,String>();
            List<NSP_Asset_Template_Mapping__mdt> assTempMap = NSP_Asset_Template_Mapping__mdt.getAll().values();
            for ( NSP_Asset_Template_Mapping__mdt pT : assTempMap ) {
                mapOfProjTempServiceAsset.put(
                    pT.NSP_Project_Template__c ,
                    pT.NSP_Service_Asset_Record_Type__c
                );
            }
            for ( Project_Account__c prjAcc1 : projAccounts ) {
                accIdWithProject.put( prjAcc1.Account__c,prjAcc1 );
                if ( !mapAcctIdwithProjTemp.containskey( prjAcc1.Account__c ) ) {
                    mapAcctIdwithProjTemp.put(
                        prjAcc1.Account__c ,
                        new Set<String>()
                    );
                }
                mapAcctIdwithProjTemp.get( prjAcc1.Account__c ).add( mapOfProjTempServiceAsset.get( prjAcc1.Project__r.TemplateName__c ) );
            }
            for ( Asset ast : [
                        SELECT Id , RecordType.DeveloperName , AccountId
                        FROM Asset
                        WHERE ( AccountId IN :mapAcctIdwithProjTemp.keySet() )
                    ]
                )
            {
                if ( !mapAcctIdwithAssetRecType.containskey( ast.AccountId ) ) {
                    mapAcctIdwithAssetRecType.put(
                        ast.AccountId ,
                        new Set<String>()
                    );
                }
                mapAcctIdwithAssetRecType.get( ast.AccountId ).add( ast.RecordType.DeveloperName );
            }
            creatingAssetRecords();
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_AssetCreationBpsProjectBatch.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    // insert Asset Records and ProjectAsset into the database
    private void creatingAssetRecords() {
        Map<String,String> mapOfAcctIdRecordType = new Map<String,String>();
        NSP_AssetTriggerHandler.TriggerDisabled = true;
        List<Asset> lstAssetToInsert = new List<Asset>();
        for ( String accountId : mapAcctIdwithProjTemp.keySet() )   {
            for ( String assetRecordType : mapAcctIdwithProjTemp.get( accountId ) ) {
                if ( !mapAcctIdwithAssetRecType.containsKey( accountId )
                    || ( mapAcctIdwithAssetRecType.containsKey( accountId )
                        && !mapAcctIdwithAssetRecType.get( accountId ).isEmpty()
                        && !mapAcctIdwithAssetRecType.get( accountId ).contains( assetRecordType )
                        )
                    || mapAcctIdwithAssetRecType.isEmpty()
                    )
                {
                    Asset newAsset = new Asset();
                    newAsset.Name = accIdWithProject.get( accountId ).Account__r.name;
                    newAsset.AccountId = accountId;
                    newAsset.Status = NSP_ServiceConstants.ASSET_ONBOARDING_STATUS;
                    newAsset.NSP_Client__c = accIdWithProject.get( accountId ).Account__r.NSP_AIMS_Client__c;
                    newAsset.NSP_Signature_Date__c = System.today();
                    newAsset.recordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , assetRecordType );
                    mapOfAcctIdRecordType.put(
                        accountId + '_' + newAsset.RecordTypeId ,
                        accIdWithProject.get( accountId ).Project__c
                    );
                    lstAssetToInsert.add( newAsset );
                }
            }
        }
        List<Project_Asset__c> lstProjAssetToInsert = new List<Project_Asset__c>();
        if ( !lstAssetToInsert.isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( lstAssetToInsert , false ); // throws ~ DUPLICATE_VALUE, duplicate value found: NSP_Client__c duplicates value on record with id: 02iXXXXXXXXXXXXXXX
            NSP_ErrorLogHandler.logResults(
                NSP_AssetCreationBpsProjectBatch.class.getName() ,
                'creatingAssetRecords:Asset' ,
                results
            );
            for ( Asset asst : lstAssetToInsert ) {
                // Prevent DmlExceptions: REQUIRED_FIELD_MISSING, Required fields are missing: [Asset__c]
                if ( asst.Id != null ) {
                    Project_Asset__c newProjAsset = new Project_Asset__c();
                    newProjAsset.Asset__c = asst.Id;
                    newProjAsset.Project__c = mapOfAcctIdRecordType.get( asst.AccountId + '_' + asst.RecordTypeId );
                    lstProjAssetToInsert.add( newProjAsset );
                }
            }
        }
        if ( !lstProjAssetToInsert.isEmpty() ) {
            List<Database.SaveResult> results = Database.insert( lstProjAssetToInsert , false );
            NSP_ErrorLogHandler.logResults(
                NSP_AssetCreationBpsProjectBatch.class.getName() ,
                'creatingAssetRecords:Project_Asset__c' ,
                results
            );
        }
    }

    public void finish( Database.BatchableContext bc ) {
    }

}
//