trigger ApexExceptionLogTrigger on ApexExceptionLog__c ( before insert , before update ) {
    // test w/ ApexExceptionLogControllerTest (100%)
    // test w/ ApexExceptionLogTriggerTest (??%)
    static final String DEBUG_PREFIX = ' ~ ApexExceptionLogTrigger';
    TriggerContextHandler.debug( DEBUG_PREFIX );
    if ( Trigger.isBefore && ( Trigger.isInsert || Trigger.isUpdate ) ) {
        // collect all the unique ClassNames, NamespacePrefixes, PageNames, TriggerNames, and UserIds...
        Set<String> classNames = new Set<String>();
        Set<String> namespacePrefixes = new Set<String>();
        Set<String> pageNames = new Set<String>();
        Set<String> triggerNames = new Set<String>();
        Set<Id> userIds = new Set<Id>();
        for ( ApexExceptionLog__c record : Trigger.new ) {
            if ( String.isNotBlank( record.ClassName__c ) ) {
                classNames.add( record.ClassName__c );
            }
            if ( String.isNotBlank( record.NamespacePrefix__c ) ) {
                namespacePrefixes.add( record.NamespacePrefix__c );
            }
            if ( String.isNotBlank( record.PageName__c ) ) {
                pageNames.add( record.PageName__c );
            }
            if ( String.isNotBlank( record.TriggerName__c ) ) {
                triggerNames.add( record.TriggerName__c );
            }
            if ( String.isNotBlank( record.UserId__c )
                && ( record.UserId__c InstanceOf Id )
               )
            {
                userIds.add( record.UserId__c );
            }
        }
        System.debug( DEBUG_PREFIX + ' ~ classNames=' + classNames );
        System.debug( DEBUG_PREFIX + ' ~ namespacePrefixes=' + namespacePrefixes );
        System.debug( DEBUG_PREFIX + ' ~ pageNames=' + pageNames );
        System.debug( DEBUG_PREFIX + ' ~ triggerNames=' + triggerNames );
        System.debug( DEBUG_PREFIX + ' ~ userIds=' + userIds );
        // build Map<ClassName,ApexClass>...
        List<ApexClass> apexClasses = [
            SELECT Id , Name FROM ApexClass WHERE ( Name IN :classNames )
        ];
        Map<String,ApexClass> apexClassMap = new Map<String,ApexClass>();
        for ( ApexClass record : apexClasses ) {
            apexClassMap.put( record.Name , record );
        }
        // build Map<PageName,ApexPage>...
        List<ApexPage> apexPages = [
            SELECT Id , Name FROM ApexPage WHERE ( Name IN :pageNames )
        ];
        Map<String,ApexPage> apexPageMap = new Map<String,ApexPage>();
        for ( ApexPage record : apexPages ) {
            apexPageMap.put( record.Name , record );
        }
        // build Map<TriggerName,ApexTrigger>...
        List<ApexTrigger> apexTriggers = [
            SELECT Id , Name FROM ApexTrigger WHERE ( Name IN :triggerNames )
        ];
        Map<String,ApexTrigger> apexTriggerMap = new Map<String,ApexTrigger>();
        for ( ApexTrigger record : apexTriggers ) {
            apexTriggerMap.put( record.Name , record );
        }
        // build Map<NamespacePrefix,PackageLicense>...
        List<PackageLicense> packageLicenses = [
            SELECT Id , NamespacePrefix FROM PackageLicense WHERE ( NamespacePrefix IN :namespacePrefixes )
        ];
        Map<String,PackageLicense> packageLicenseMap = new Map<String,PackageLicense>();
        for ( PackageLicense record : packageLicenses ) {
            packageLicenseMap.put( record.NamespacePrefix , record );
        }
        // build Map<UserId,User>...
        Map<Id,User> userMap = new Map<Id,User>(
            [
                SELECT Id , Name
                FROM User
                WHERE ( Id IN :userIds )
            ]
        );
        // second pass, update related Id values...
        // ~ populate ApexClassId__c...
        // ~ populate ApexPageId__c...
        // ~ populate ApexTriggerId__c...
        // ~ populate PackageLicenseId__c...
        // ~ populate UserId__c...
        for ( ApexExceptionLog__c record : Trigger.new ) {
            // ~ populate ApexClassId__c...
            if ( String.isNotBlank( record.ClassName__c )
                && ( apexClassMap != null )
                && apexClassMap.containsKey( record.ClassName__c )
                && ( apexClassMap.get( record.ClassName__c ) != null )
               )
            {
                record.ApexClassId__c = apexClassMap.get( record.ClassName__c ).Id;
            }
            // ~ populate ApexPageId__c...
            if ( String.isNotBlank( record.PageName__c )
                && ( apexPageMap != null )
                && apexPageMap.containsKey( record.PageName__c )
                && ( apexPageMap.get( record.PageName__c ) != null )
               )
            {
                record.ApexPageId__c = apexPageMap.get( record.PageName__c ).Id;
            }
            // ~ populate ApexTriggerId__c...
            if ( String.isNotBlank( record.TriggerName__c )
                && ( apexTriggerMap != null )
                && apexTriggerMap.containsKey( record.TriggerName__c )
                && ( apexTriggerMap.get( record.TriggerName__c ) != null )
               )
            {
                record.ApexTriggerId__c = apexTriggerMap.get( record.TriggerName__c ).Id;
            }
            // ~ populate PackageLicenseId__c...
            if ( String.isNotBlank( record.NamespacePrefix__c )
                && ( packageLicenseMap != null )
                && packageLicenseMap.containsKey( record.NamespacePrefix__c )
                && ( packageLicenseMap.get( record.NamespacePrefix__c ) != null )
               )
            {
                record.PackageLicenseId__c = packageLicenseMap.get( record.NamespacePrefix__c ).Id;
            }
            // ~ populate UserId__c...
            if ( String.isNotBlank( record.UserId__c )
                && ( userMap != null )
                && userMap.containsKey( record.UserId__c )
                && ( userMap.get( record.UserId__c ) != null )
               )
            {
                record.User__c = userMap.get( record.UserId__c ).Id;
            }
        }
    }
}
//