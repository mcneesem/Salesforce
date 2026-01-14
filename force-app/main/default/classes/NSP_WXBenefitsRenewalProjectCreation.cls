public class NSP_WXBenefitsRenewalProjectCreation implements ISelfSchedulable , Schedulable , Database.Batchable<sObject> {
    // test w/ NSP_WXBenefitsRenewalProjCreat_Test (91%)

    //
    // Schedulable
    //

    //== Execute Method
    public void execute( SchedulableContext sc ) {
        if ( NSP_WXBenefitsRenewalProjectCreation.isEnabledDefault ) {
            // Executes Batch for Medical Benefits Renewal Date
            Database.executeBatch(
                new NSP_WXBenefitsRenewalProjectCreation( 'Medical_Benefits_Renewal_Date__c' ) ,
                NSP_WXBenefitsRenewalProjectCreation.batchSize
            );
        }
        if ( NSP_WXBenefitsRenewalProjectCreation.isEnabledAncillary ) {
            // Execute Batch for Ancillary Benefits Renewal Date
            Database.executeBatch(
                new NSP_WXBenefitsRenewalProjectCreation( 'Ancillary_Benefits_Renewal_Date__c' ) ,
                NSP_WXBenefitsRenewalProjectCreation.batchSize
            );
        }
        if ( NSP_WXBenefitsRenewalProjectCreation.isEnabledFringe ) {
            // Execute Batch for Fringe Benefits Renewal Date
            Database.executeBatch(
                new NSP_WXBenefitsRenewalProjectCreation( 'Fringe_Benefits_Renewal_Date__c' ) ,
                NSP_WXBenefitsRenewalProjectCreation.batchSize
            );
        }
    }

    // runs everyday at 1am central...
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_WXBenefitsRenewalProjectCreation ~ When a WX asset has a Benefits Renewal Date field populated, then create a WX Benefits Renewal project and related tasks linked to the WX asset record ~ everyday at 1 AM' + suffix ,
            '0 0 1 ? * * *' ,
            new NSP_WXBenefitsRenewalProjectCreation()
        );
    }

    //
    // Batchable
    //

    private Schema.SObjectField fieldApiName = null;

    //== Constructor Method
    public NSP_WXBenefitsRenewalProjectCreation( String fieldName ) {
        if ( String.isNotBlank( fieldName ) ) {
            Map<String,Schema.SObjectField> fieldMap = Asset.SObjectType.getDescribe().fields.getMap();
            if ( ( fieldMap != null ) && fieldMap.containsKey( fieldName ) ) {
                this.fieldApiName = fieldMap.get( fieldName );
            }
        }
    }

    //== Default Constructor
    public NSP_WXBenefitsRenewalProjectCreation() {
    }

    //== Start Method
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        String query = 'SELECT Id FROM Asset WHERE ( Id = null )';
        if ( this.fieldApiName != null ) {
            Date comparingDate = Date.today().addDays( NSP_WXBenefitsRenewalProjectCreation.soqlDaysLimit );
            Id wxRecordTypeId = NSP_GenericRecordType.getRecordTypeId( 'Asset' , 'NSP_Asset_Product' );
            List<String> excludeAssetStatus = new List<String>{ 'Terminated' , 'Backout' };
            String formattedStatusValues = '\'' + String.join( excludeAssetStatus , '\',\'' ) + '\'';
            query = ''
                + 'SELECT Id , RecordTypeId , AccountId , Status , ' + this.fieldApiName
                + ' FROM Asset'
                + ' WHERE'
                + ' ( ' + this.fieldApiName + ' = ' + String.ValueOf( comparingDate ) + ')'
                + ' AND ( RecordTypeId = \'' + wxRecordTypeId + '\' )'
                + ' AND ( Status NOT IN ( ' + formattedStatusValues + ' ) )'
                + ' WITH SECURITY_ENFORCED'
                ;
        }
        return Database.getQueryLocator( query );
    }

    //== Executing the business logic
    public void execute( Database.BatchableContext bc , List<Asset> scope ) {
        try {
            WXBenefitsRenewalProjectHelper helpClass = new WXBenefitsRenewalProjectHelper();
            helpClass.createProjectFromTemplateBasedOnAccountAndAsset( scope );
        } catch ( Exception e ) {
            NSP_ErrorLogHandler.logException(
                NSP_WXBenefitsRenewalProjectCreation.class.getName() ,
                'execute' ,
                e
            );
        }
    }

    //== Finish Method
    public void finish( Database.BatchableContext bc ) {
    }

    //
    // Custom Settings
    //

    private static Benefits_Renewal_Batch_Settings__c settings {
        get {
            if ( settings == null ) {
                settings = Benefits_Renewal_Batch_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabledDefault {
        get {
            if ( isEnabledDefault == null ) {
                Boolean local = False;
                if ( NSP_WXBenefitsRenewalProjectCreation.settings != null ) {
                    local = NSP_WXBenefitsRenewalProjectCreation.settings.IsEnabledDefault__c;
                }
                isEnabledDefault = local;
            }
            return isEnabledDefault;
        }
        private set;
    }

    private static Boolean isEnabledAncillary {
        get {
            if ( isEnabledAncillary == null ) {
                Boolean local = False;
                if ( NSP_WXBenefitsRenewalProjectCreation.settings != null ) {
                    local = NSP_WXBenefitsRenewalProjectCreation.settings.IsEnabledAncillary__c;
                }
                isEnabledAncillary = local;
            }
            return isEnabledAncillary;
        }
        private set;
    }

    private static Boolean isEnabledFringe {
        get {
            if ( isEnabledFringe == null ) {
                Boolean local = False;
                if ( NSP_WXBenefitsRenewalProjectCreation.settings != null ) {
                    local = NSP_WXBenefitsRenewalProjectCreation.settings.IsEnabledFringe__c;
                }
                isEnabledFringe = local;
            }
            return isEnabledFringe;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 1;
                if ( ( NSP_WXBenefitsRenewalProjectCreation.settings != null )
                    && ( NSP_WXBenefitsRenewalProjectCreation.settings.BatchSize__c != null )
                    )
                {
                    local = NSP_WXBenefitsRenewalProjectCreation.settings.BatchSize__c.intValue();
                }
                // batch size must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                // batch size must be less than or equal to 2000...
                if ( local > 2000 ) {
                    local = 2000;
                }
                batchSize = local;
            }
            return batchSize;
        }
        private set;
    }

    // how far (in days) should be queried???
    private static Integer soqlDaysLimit {
        private get {
            if ( soqlDaysLimit == null ) {
                Integer local = 75;
                if ( ( NSP_WXBenefitsRenewalProjectCreation.settings != null )
                    && ( NSP_WXBenefitsRenewalProjectCreation.settings.SoqlDaysLimit__c != null )
                    )
                {
                    local = NSP_WXBenefitsRenewalProjectCreation.settings.SoqlDaysLimit__c.intValue();
                }
                // limit must be non-negative...
                if ( local < 0 ) {
                    local = 0;
                }
                soqlDaysLimit = local;
            }
            return soqlDaysLimit;
        }
        private set;
    }

}
//