public class GenerateRenewalOpportunitiesJob implements Callable , IJobRunnable , Database.Batchable<SObject> , Database.Stateful {
    // test w/ GenerateRenewalOpportunitiesJobTest (88%)

    // Inputs from Flow/Invocable (selected month & year)
    private Integer runMonth = null;
    private Integer runYear = null;
    private Set<String> clientNumbers = new Set<String>();
    private String renewalCreated = null;

    // Derived eligibility: one year prior selected month
    private Date eligibleStart;
    private Date eligibleEnd;

    Map<String,NSP_Sales_Office_Mapping__c> salesOfficeMap = new Map<String,NSP_Sales_Office_Mapping__c>();
    Map<Id,Id> accountParentOpportunityMap = new Map<Id,Id>();
    Map<Id,String> accountSubClientMap = new Map<Id,String>();
    Set<String> opportunityBenefitPackageKeys = new Set<String>();
    Map<String,NSP_Sub_Client__c> entryOpportunityMap = new Map<String,NSP_Sub_Client__c>();
    private Map<String,Decimal> fullTimeWSEEMap = new Map<String,Decimal>();
    private Map<String,Decimal> partTimeWSEEMap = new Map<String,Decimal>();
    private Map<String,Decimal> seasonalTimeWSEEMap = new Map<String,Decimal>();
    private List<Database.SaveResult> dmlSaveResults = new List<Database.SaveResult>();
    private List<Exception> executeExceptions = new List<Exception>();

    //
    // argument-free constructor is required to be "runnable"...
    //

    public GenerateRenewalOpportunitiesJob() {
    }

    //
    // Callable
    //

    public Object call( String action , Map<String,Object> args ) {
        Object response = null;
        if ( action == 'run' ) {
            response = this.run();
        }
        return response;
    }

    //
    // IJobRunnable
    //

    public Id run() {
        return GenerateRenewalOpportunitiesJob.executeBatch( null , null , null );
    }

    //
    // Batchable
    //

    public static Id executeBatch( Integer monthNum , Integer yearNum , Set<String> clientNumbers ) {
        Id response = null;
        if ( GenerateRenewalOpportunitiesJob.isEnabled ) {
            response = Database.executeBatch(
                new GenerateRenewalOpportunitiesJob( monthNum , yearNum , clientNumbers ) ,
                GenerateRenewalOpportunitiesJob.batchSize
            );
        }
        return response;
    }

    public GenerateRenewalOpportunitiesJob( Integer monthNum , Integer yearNum , Set<String> clientNumbers ) {
        if ( ( monthNum != null ) && ( yearNum != null ) ) {
            this.runMonth = monthNum;
            this.runYear  = yearNum;
            this.renewalCreated = monthNum + '/' + yearNum;
            // Example: user selects Dec 2026 => eligible window is Dec 2025
            Integer eligibleYear = ( yearNum - 1 );
            this.eligibleStart = Date.newInstance( eligibleYear , monthNum , 1 );
            this.eligibleEnd = this.eligibleStart.addMonths( 1 ).addDays( -1 );
        }
        if ( clientNumbers != null && !clientNumbers.isEmpty() ) {
            this.clientNumbers.addAll( clientNumbers );
        }
    }

    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Database.queryLocator queryLocator = null;
        if ( ( this.eligibleStart != null )
            && ( this.eligibleEnd != null )
            && String.isNotBlank( this.renewalCreated )
            )
        {
            queryLocator = Database.getQueryLocator(
                    [
                        SELECT
                            Id ,
                            Name ,
                            NSP_Part_Time_Margin__c ,
                            NSP_Part_Time_Reserve__c ,
                            NSP_Account__r.Name ,
                            NSP_Account_Status__c ,
                            NSP_Client__c ,
                            NSP_Sub_Client__c ,
                            NSP_Renewal_Date__c ,
                            NSP_Benefit_Package_Name__c ,
                            NSP_Asset__c ,
                            NSP_Asset__r.NSP_Sales_Office__c ,
                            NSP_Asset__r.NSP_Service_Package__c ,
                            NSP_Asset__r.NSP_Multi_Year_Client_Service_Agreement__c ,
                            NSP_Asset__r.Status ,
                            NSP_Account__c ,
                            NSP_Margin__c ,
                            NSP_Reserve__c ,
                            NSP_Actual_Full_Time_EE_Count__c ,
                            NSP_Actual_Part_Time_EE_Count__c ,
                            NSP_Actual_Seasonal_Time_EE_Count__c ,
                            NSP_Asset__r.NSP_Client_Retained_Workers_Comp__c ,
                            Renewal_Created__c
                        FROM NSP_Sub_Client__c
                        WHERE (
                            ( NSP_Account_Status__c = 'Active' )
                            AND ( NSP_Renewal_Date__c >= :this.eligibleStart )
                            AND ( NSP_Renewal_Date__c <= :this.eligibleEnd )
                            AND ( NSP_Renewal_Date__c != null )
                            AND ( Renewal_Created__c != :this.renewalCreated )
                        )
                        ORDER BY NSP_Client__c , NSP_Sub_Client__c ASC
                    ]
                );
        } else {
            // batch requires non-null query locator even when the inputs are null...
            queryLocator = Database.getQueryLocator(
                [
                    SELECT
                        Id ,
                        Name ,
                        NSP_Part_Time_Margin__c ,
                        NSP_Part_Time_Reserve__c ,
                        NSP_Account__r.Name ,
                        NSP_Account_Status__c ,
                        NSP_Client__c ,
                        NSP_Sub_Client__c ,
                        NSP_Renewal_Date__c ,
                        NSP_Benefit_Package_Name__c ,
                        NSP_Asset__c ,
                        NSP_Asset__r.NSP_Sales_Office__c ,
                        NSP_Asset__r.NSP_Service_Package__c ,
                        NSP_Asset__r.NSP_Multi_Year_Client_Service_Agreement__c ,
                        NSP_Asset__r.Status ,
                        NSP_Account__c ,
                        NSP_Margin__c ,
                        NSP_Reserve__c ,
                        NSP_Actual_Full_Time_EE_Count__c ,
                        NSP_Actual_Part_Time_EE_Count__c ,
                        NSP_Actual_Seasonal_Time_EE_Count__c ,
                        NSP_Asset__r.NSP_Client_Retained_Workers_Comp__c ,
                        Renewal_Created__c
                    FROM NSP_Sub_Client__c
                    LIMIT 0
                ]
            );
        }
        return queryLocator;
    }

    public void execute( Database.BatchableContext bc, List<NSP_Sub_Client__c> records ) {
        if ( GenerateRenewalOpportunitiesJob.isEnabled
            && records != null
            && !records.isEmpty()
            )
        {
            try {
                records = this.getSelectedClientRecords( records );
                if ( !records.isEmpty() ) {
                    this.buildSalesOfficeToRenewalManagerMap( records );
                    this.buildWSEEMaps( records );
                    this.processEntries( records );
                    this.processOpportunities( records );
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    GenerateRenewalOpportunitiesJob.class.getName() ,
                    'execute' ,
                    e
                );
                if ( this.executeExceptions != null ) {
                    this.executeExceptions.add( e );
                }
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
        if ( GenerateRenewalOpportunitiesJob.isEnabled ) {
            try {
                List<String> toUsers = new List<String>();
                toUsers.add( UserInfo.getUserEmail() );
                if ( ( GenerateRenewalOpportunitiesJob.monitorEmailAddresses != null )
                    && !GenerateRenewalOpportunitiesJob.monitorEmailAddresses.isEmpty()
                    )
                {
                    toUsers.addAll( GenerateRenewalOpportunitiesJob.monitorEmailAddresses );
                }
                GenerateRenewalOpportunitiesJob.sendEmail(
                    toUsers ,
                    'Generate Renewal Opportunities Job Complete' ,
                    this.constructEmailBody( bc.getJobId() )
                );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    GenerateRenewalOpportunitiesJob.class.getName() ,
                    'finish' ,
                    e
                );
            }
        }
    }

    private String constructEmailBody( Id jobId ) {
        String jobIdValue = 'N/A';
        if ( jobId != null ) {
            jobIdValue = String.valueOf( jobId );
        }
        Set<Id> oppsId = this.collectOpportunitiesModified();
        List<AggregateResult> aggregatedOpportunities = [
            SELECT
                NSP_Parent_Opportunity__c parentId ,
                COUNT(Id) cnt
            FROM Opportunity
            WHERE ( Id IN :oppsId )
            GROUP BY NSP_Parent_Opportunity__c
        ];
        Integer parentOpportunitiesCreated = this.countParentOpportunities( aggregatedOpportunities );
        Integer childOpportunitiesCreated = this.countChildOpportunities( aggregatedOpportunities );
        Integer subClientsModified = this.countSubClientsModified();
        Integer errorsEncountered = this.countDmlErrors();
        Integer totalExecuteExceptions = 0;
        if ( this.executeExceptions != null ) {
            totalExecuteExceptions = this.executeExceptions.size();
        }
        String body =
            'Job Id: ' + jobIdValue + '<br/>'
            + 'Parent Opportunities Created: ' + parentOpportunitiesCreated + '<br/>'
            + 'Child Opportunities Created: ' + childOpportunitiesCreated + '<br/>'
            + 'Sub Clients Modified: ' + subClientsModified + '<br/>'
            + 'Errors Encountered: ' + errorsEncountered + '<br/>'
            + 'Execute Exceptions: ' + totalExecuteExceptions + '<br/>';

        return body;
    }

    private Set<Id> collectOpportunitiesModified() {
        Set<Id> oppsId = new Set<Id>();
        if ( ( this.dmlSaveResults != null ) && !this.dmlSaveResults.isEmpty() ) {
            for ( Database.SaveResult result : this.dmlSaveResults ) {
                if ( result != null && result.isSuccess() ) {
                    Id recordId = result.getId();
                    if ( ( recordId != null )
                        && ( recordId.getSObjectType() == Opportunity.getSObjectType() )
                        )
                    {
                        oppsId.add( recordId );
                    }
                }
            }
        }
        return oppsId;
    }

    private Integer countSubClientsModified() {
        Integer subClientsModified = 0;
        if ( ( this.dmlSaveResults != null ) && !this.dmlSaveResults.isEmpty() ) {
            for ( Database.SaveResult result : this.dmlSaveResults ) {
                if ( result != null && result.isSuccess() ) {
                    Id recordId = result.getId();
                    if ( ( recordId != null )
                        && ( recordId.getSObjectType() == NSP_Sub_Client__c.getSObjectType() )
                        )
                    {
                        subClientsModified++;
                    }
                }
            }
        }
        return subClientsModified;
    }

    private Integer countDmlErrors() {
        Integer errorsEncountered = 0;
        if ( ( this.dmlSaveResults != null ) && !this.dmlSaveResults.isEmpty() ) {
            for ( Database.SaveResult result : this.dmlSaveResults ) {
                if ( ( result == null ) || !result.isSuccess() ) {
                    errorsEncountered++;
                }
            }
        }
        return errorsEncountered;
    }

    private Integer countParentOpportunities( List<AggregateResult> aggregatedOpportunities ) {
        Integer parentOpportunitiesCreated = 0;
        if ( ( aggregatedOpportunities != null ) && !aggregatedOpportunities.isEmpty() ) {
            for ( AggregateResult ar : aggregatedOpportunities ) {
                if ( ar.get( 'parentId' ) == null ) {
                    parentOpportunitiesCreated = Integer.valueOf( ar.get( 'cnt' ) );
                }
            }
        }
        return parentOpportunitiesCreated;
    }

    private Integer countChildOpportunities( List<AggregateResult> aggregatedOpportunities ) {
        Integer childOpportunitiesCreated = 0;
        if ( ( aggregatedOpportunities != null ) && !aggregatedOpportunities.isEmpty() ) {
            for ( AggregateResult ar : aggregatedOpportunities ) {
                if ( ar.get( 'parentId' ) != null ) {
                    childOpportunitiesCreated += Integer.valueOf( ar.get( 'cnt' ) );
                }
            }
        }
        return childOpportunitiesCreated;
    }

    private static void sendEmail(
        List<String> recipients ,
        String subject ,
        String body
        )
    {
        if ( ( recipients != null )
            && !recipients.isEmpty()
            && String.isNotBlank( subject )
            && String.isNotBlank( body )
            )
        {
            Map<String,Object> inputs = new Map<String,Object>();
            inputs.put( 'toEmailAddresses' , recipients );
            inputs.put( 'emailSubject' , subject );
            inputs.put( 'emailBody', body );
            Flow.Interview.Send_Email sendEmailFlow = new Flow.Interview.Send_Email( inputs );
            sendEmailFlow.start();
        }
    }

    //
    //
    //

    private List<NSP_Sub_Client__c> getSelectedClientRecords( List<NSP_Sub_Client__c> records ) {
        List<NSP_Sub_Client__c> selectedClientRecords = new List<NSP_Sub_Client__c>();
        if ( this.clientNumbers != null && !this.clientNumbers.isEmpty() ) {
            for ( NSP_Sub_Client__c record : records ) {
                if ( this.clientNumbers.contains( record.NSP_Client__c ) ) {
                    selectedClientRecords.add( record ) ;
                }
            }
        } else{
            selectedClientRecords = records ;
        }
        return selectedClientRecords ;
    }

    private void processOpportunities( List<NSP_Sub_Client__c> records ) {
        List<Opportunity> parentOpportunities = new List<Opportunity>();
        List<Opportunity> childOpportunities = new List<Opportunity>();
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( NSP_Sub_Client__c subClient : records ) {
                Opportunity opportunity = this.buildOpportunity( subClient );
                if ( opportunity != null ) {
                    if ( subClient.NSP_Sub_Client__c == subClient.NSP_Client__c ) {
                        parentOpportunities.add( opportunity );
                    } else {
                        childOpportunities.add( opportunity );
                    }
                }
            }
        }
        this.performDml(
            'insert' ,
            parentOpportunities ,
            'Opportunity' ,
            true
        );
        this.performDml(
            'insert' ,
            this.mapChildToParentOpportunities( childOpportunities ) ,
            'Opportunity' ,
            false
        );
        this.performDml(
            'update' ,
            this.prepareSubClients( records ) ,
            'NSP_Sub_Client__c' ,
            false
        );
    }

    private void performDml(
        String operation ,
        List<SObject> records ,
        String methodHelper ,
        Boolean isParent
        )
    {
        if ( ( records != null )
            && !records.isEmpty()
            && String.isNotBlank( operation )
            )
        {
            List<Database.SaveResult> results = new List<Database.SaveResult>();
            if ( operation == 'insert' ) {
                results = Database.insert( records , false );
            } else if ( operation == 'update' ) {
                results = Database.update( records , false );
            }
            methodHelper = ( String.isNotBlank( methodHelper ) ? methodHelper : '' );
            if ( isParent ) {
                methodHelper = methodHelper + ':parent';
            }
            String methodName = 'performDml:' + operation + ':' + methodHelper;
            NSP_ErrorLogHandler.logResults(
                GenerateRenewalOpportunitiesJob.class.getName() ,
                methodName ,
                results
            );
            if ( this.dmlSaveResults != null ) {
                this.dmlSaveResults.addAll( results );
            }
            if ( records.getSObjectType() == Opportunity.getSObjectType() ) {
                this.processOpportunitiesPostDml( records , isParent );
            }
        }
    }

    private void processOpportunitiesPostDml( List<Opportunity> records , Boolean isParent ) {
        if ( isParent && ( records != null ) && !records.isEmpty() ) {
            for ( Opportunity record : records ) {
                if ( ( record != null )
                    && ( record.AccountId != null )
                    )
                {
                    this.accountParentOpportunityMap.put( record.AccountId, record.Id );
                }
            }
        }
        this.populateOpportunityBenefitPackageKeys(records);
    }

    private void populateOpportunityBenefitPackageKeys( List<Opportunity> records ) {
        if ( records != null
            && !records.isEmpty()
            )
        {
            for ( Opportunity record : records ) {
                String key = this.buildKey( record );
                if ( String.isNotBlank( key ) ) {
                    this.opportunityBenefitPackageKeys.add( key );
                }
            }
        }
    }

    private Opportunity buildOpportunity( NSP_Sub_Client__c subClient ) {
        Opportunity opp = null;
        if ( ( subClient != null )
            && this.checkEligibility( subClient )
            )
        {
            opp = new Opportunity();
            opp.AccountId = subClient.NSP_Account__c;
            opp.RecordTypeId = GenerateRenewalOpportunitiesJob.renewalRecordTypeId;
            opp.Name = this.buildOpportunityName( subClient );
            opp.OwnerId = this.getOpportunityOwner( subClient );
            opp.NSP_PrimaryProduct__c = this.getPrimaryProduct(  subClient );
            opp.NSP_Client_For_Life__c = 'WO/WS';
            if ( subClient.NSP_Renewal_Date__c != null ) {
                opp.CloseDate = subClient.NSP_Renewal_Date__c.addYears( 1 );
            }
            opp.StageName = 'Preparation';
            opp.Type = 'Renewal';
            opp.Asset__c = subClient.NSP_Asset__c;
            if ( subClient.NSP_Asset__r != null ) {
                opp.Service_Package__c = subClient.NSP_Asset__r.NSP_Service_Package__c;
                opp.NSP_Sales_Office__c = subClient.NSP_Asset__r.NSP_Sales_Office__c;
                opp.Client_Retained_WC__c = 'No';
                if ( subClient.NSP_Asset__r.NSP_Client_Retained_Workers_Comp__c != null ) {
                    opp.Client_Retained_WC__c = 'Yes';
                }
            }
            opp.Current_Renewal_Date__c = subClient.NSP_Renewal_Date__c;
            if ( subClient.NSP_Renewal_Date__c != null ) {
                opp.Next_Renewal_Date__c = subClient.NSP_Renewal_Date__c.addYears( 1 );
            }
            opp.Current_Benefits_Package__c = subClient.NSP_Benefit_Package_Name__c;
            opp.Renewal_Benefits_Package__c = this.buildBenefitPackage( subClient.NSP_Benefit_Package_Name__c );
            opp.Current_Multi_Year_Contract__c = this.isCurrentMultiYearContract( subClient );
            opp.Current_Margin__c = subClient.NSP_Margin__c;
            opp.Current_Reserve__c = subClient.NSP_Reserve__c;
            opp.Current_Part_Time_Margin__c = subClient.NSP_Part_Time_Margin__c;
            opp.Current_Part_Time_Reserve__c = subClient.NSP_Part_Time_Reserve__c;
            opp.Renewal_Status__c = 'Not Started';
            opp.Renewal_Name__c = this.fetchRenewalName( subClient );
            opp.Renewal_Team__c = this.getRenewalTeam( subClient );
            opp.Full_Time_WSEEs__c = this.getMapValue(
                this.fullTimeWSEEMap ,
                subClient.NSP_Client__c
            );
            opp.Part_Time_WSEEs__c = this.getMapValue(
                this.partTimeWSEEMap ,
                subClient.NSP_Client__c
            );
            opp.Seasonal_Time_WSEEs__c = this.getMapValue(
                this.seasonalTimeWSEEMap ,
                subClient.NSP_Client__c
            );
        }
        return opp;
    }

    private void processEntries( List<NSP_Sub_Client__c> subClients ) {
        if ( ( subClients != null ) && !subClients.isEmpty() ) {
            for ( NSP_Sub_Client__c subClient : subClients ) {
                this.buildEntries( subClient );
                this.buildAccountSubClientMap( subClient );
            }
        }
    }

    private void buildEntries( NSP_Sub_Client__c subClient ) {
        String key = this.buildKey( subClient );
        if ( String.isNotBlank( key )
            && ( subClient != null )
            )
        {
            if ( String.isNotBlank( subClient.NSP_Sub_Client__c )
                && this.entryOpportunityMap != null
                && !this.entryOpportunityMap.isEmpty()
                && this.entryOpportunityMap.containsKey( key )
                )
            {
                NSP_Sub_Client__c mapValue = this.entryOpportunityMap.get( key );
                if ( ( subClient.NSP_Sub_Client__c == subClient.NSP_Client__c )
                    && ( mapValue != null )
                    && ( mapValue.NSP_Sub_Client__c != mapValue.NSP_Client__c )
                    )
                {
                    this.entryOpportunityMap.put( key , subClient );
                }
            } else {
                this.entryOpportunityMap.put( key , subClient );
            }
        }
    }

    private Boolean checkEligibility( NSP_Sub_Client__c subClient ) {
        Boolean flag = false;
        String key = this.buildKey( subClient );
        if ( ( subClient != null )
            && String.isNotBlank( subClient.NSP_Sub_Client__c )
            && String.isNotBlank( key )
            && this.entryOpportunityMap.containsKey( key )
            )
        {
            NSP_Sub_Client__c scRec = this.entryOpportunityMap.get( key );
            if ( ( scRec != null )
                && ( scRec.NSP_Client__c == subClient.NSP_Client__c )
                && ( scRec.NSP_Sub_Client__c == subClient.NSP_Sub_Client__c )
                )
            {
                flag = true;
            }
        }
        return flag;
    }

    private String buildKey( NSP_Sub_Client__c subClient ) {
        String key = null;
        if ( ( subClient != null )
            && String.isNotBlank( subClient.NSP_Client__c )
            && String.isNotBlank( subClient.NSP_Benefit_Package_Name__c )
            )
        {
            key = subClient.NSP_Client__c + subClient.NSP_Benefit_Package_Name__c;
        }
        return key;
    }

    private String buildKey( Opportunity record ) {
        String key = null;
        if ( ( record != null )
            && String.isNotBlank( record.Current_Benefits_Package__c )
            && String.isNotBlank( record.AccountId )
            && ( this.accountSubClientMap != null )
            && this.accountSubClientMap.containsKey( record.AccountId )
            && ( this.accountSubClientMap.get( record.AccountId ) != null )
            )
        {
            key = this.accountSubClientMap.get( record.AccountId ) + record.Current_Benefits_Package__c;
        }
        return key;
    }

    private List<Opportunity> mapChildToParentOpportunities( List<Opportunity> childOpportunities ) {
        if ( ( childOpportunities != null )
            && !childOpportunities.isEmpty()
            && ( this.accountParentOpportunityMap != null )
            && !this.accountParentOpportunityMap.isEmpty()
            )
        {
            for( Opportunity record : childOpportunities ) {
                if ( ( record != null )
                    && String.isNotBlank( record.AccountId )
                    && this.accountParentOpportunityMap.containsKey( record.AccountId )
                    && ( this.accountParentOpportunityMap.get( record.AccountId ) != null )
                    )
                {
                    record.NSP_Parent_Opportunity__c = this.accountParentOpportunityMap.get( record.AccountId );
                }
            }
        }
        return childOpportunities;
    }

    // Account.Id -> NSP_Client__c.Id Mapping
    private void buildAccountSubClientMap( NSP_Sub_Client__c subClient ) {
        if ( ( subClient != null )
            && String.isNotBlank( subClient.NSP_Client__c )
            && String.isNotBlank( subClient.NSP_Account__c )
            )
        {
            this.accountSubClientMap.put( subClient.NSP_Account__c , subClient.NSP_Client__c );
        }
    }

    private List<NSP_Sub_Client__c> prepareSubClients( List<NSP_Sub_Client__c> records ) {
        List<NSP_Sub_Client__c> subClientsToUpdate = new List<NSP_Sub_Client__c>();
        if ( ( records != null )
            && !records.isEmpty()
            && ( this.opportunityBenefitPackageKeys != null )
            && !this.opportunityBenefitPackageKeys.isEmpty()
            )
        {
            for ( NSP_Sub_Client__c subClient : records ) {
                String key = this.buildKey( subClient );
                if ( String.isNotBlank( key )
                    && this.opportunityBenefitPackageKeys.contains( key )
                    )
                {
                    subClient.Renewal_Created__c = this.renewalCreated;
                    subClientsToUpdate.add( subClient );
                }
            }
        }
        return subClientsToUpdate;
    }

    private String getPrimaryProduct( NSP_Sub_Client__c subClient ) {
        String primaryProduct = null;
        if ( ( subClient != null )
            && ( subClient.NSP_Asset__r != null )
            && String.isNotBlank( subClient.NSP_Asset__r.NSP_Service_Package__c )
            && ( GenerateRenewalOpportunitiesJob.primaryProductMap != null )
            && !GenerateRenewalOpportunitiesJob.primaryProductMap.isEmpty()
            && GenerateRenewalOpportunitiesJob.primaryProductMap.containsKey( subClient.NSP_Asset__r.NSP_Service_Package__c )
            && ( GenerateRenewalOpportunitiesJob.primaryProductMap.get( subClient.NSP_Asset__r.NSP_Service_Package__c ) != null )
            )
        {
            primaryProduct = GenerateRenewalOpportunitiesJob.primaryProductMap.get( subClient.NSP_Asset__r.NSP_Service_Package__c );
        }
        return primaryProduct;
    }

    private Id getOpportunityOwner( NSP_Sub_Client__c subClient ) {
        Id owner = userInfo.getUserId();
        if ( ( subClient != null )
            && ( subClient.NSP_Asset__r != null )
            && String.isNotBlank( subClient.NSP_Asset__r.NSP_Sales_Office__c )
            && ( this.salesOfficeMap != null )
            && !this.salesOfficeMap.isEmpty()
            && this.salesOfficeMap.containsKey( subClient.NSP_Asset__r.NSP_Sales_Office__c )
            )
        {
            NSP_Sales_Office_Mapping__c som = this.salesOfficeMap.get( subClient.NSP_Asset__r.NSP_Sales_Office__c );
            if ( ( som != null )
                && String.isNotBlank( som.Renewal_Manager__c )
                )
            {
                owner = som.Renewal_Manager__c;
            }
        }
        return owner;
    }

    private String buildOpportunityName( NSP_Sub_Client__c subClient ) {
        String name = null;
        if ( ( subClient != null )
            && ( subClient.NSP_Account__r != null )
            && String.isNotBlank( subClient.NSP_Account__r.Name )
            )
        {
            name = SchemaController.safeText(
                subClient.NSP_Account__r.Name ,
                sObjectType.Opportunity.Fields.Name
            );
            String suffix = ' - ' + DateTime.now().format();
            String truncator = '...';
            Integer maxLength = ( sObjectType.Opportunity.Fields.Name.getLength() - suffix.length() );
            if ( name.length() >= maxLength ) {
                name = ( name.left( maxLength - truncator.length() ) + truncator );
            }
            name = name + suffix;
        }
        return name;
    }

    private String isCurrentMultiYearContract( NSP_Sub_Client__c subClient ){
        String value = 'No';
        if ( subClient != null
            && subClient.NSP_Asset__r != null
            && subClient.NSP_Asset__r.Status == 'Active'
            && subClient.NSP_Asset__r.NSP_Multi_Year_Client_Service_Agreement__c
           )
        {
            value = 'Yes';
        }
        return value;
    }

    private String buildBenefitPackage( String benefitPackage ){
        String local = '';
        if ( String.isNotBlank( benefitPackage )
            && GenerateRenewalOpportunitiesJob.validRenewalBenefitPackageValues != null
            && !GenerateRenewalOpportunitiesJob.validRenewalBenefitPackageValues.isEmpty()
            && GenerateRenewalOpportunitiesJob.validRenewalBenefitPackageValues.containsKey( benefitPackage )
            && String.isNotBlank( GenerateRenewalOpportunitiesJob.validRenewalBenefitPackageValues.get( benefitPackage ) )
           )
        {
            local = GenerateRenewalOpportunitiesJob.validRenewalBenefitPackageValues.get( benefitPackage );
        }
        return local;
    }

    // Sales office -> Renewal Manager mapping
    private void buildSalesOfficeToRenewalManagerMap( List<NSP_Sub_Client__c> subClients ){
        List<String> salesOfficeKeys = new List<String>();
        if ( ( subClients != null ) && !subClients.isEmpty() ){
            for ( NSP_Sub_Client__c record : subClients ) {
                if ( ( record != null )
                    && ( record.NSP_Asset__r != null )
                    && String.isNotBlank( record.NSP_Asset__r.NSP_Sales_Office__c )
                    )
                {
                    salesOfficeKeys.add( record.NSP_Asset__r.NSP_Sales_Office__c );
                }
            }
        }
        this.buildSalesOfficeMap( salesOfficeKeys );
    }

    private void buildSalesOfficeMap( List<String> salesOfficeKeys ) {
        Map<String,NSP_Sales_Office_Mapping__c> local = new Map<String,NSP_Sales_Office_Mapping__c>();
        if ( ( salesOfficeKeys != null ) && !salesOfficeKeys.isEmpty() ) {
            for ( NSP_Sales_Office_Mapping__c record : [
                        SELECT
                            Id ,
                            NSP_Sales_Office__c ,
                            Renewal_Manager__c ,
                            Renewal_Team__c
                        FROM NSP_Sales_Office_Mapping__c
                        WHERE ( NSP_Sales_Office__c IN :salesOfficeKeys )
                    ]
                )
            {
                if ( ( record != null ) && ( record.NSP_Sales_Office__c != null ) ) {
                    local.put( record.NSP_Sales_Office__c , record );
                }
            }
        }
        this.salesOfficeMap = local;
    }

    //
    // Custom Permissions
    //

    private static Boolean hasPermissions {
        private get {
            if ( hasPermissions == null ) {
                hasPermissions = (
                    GenerateRenewalOpportunitiesJob.hasPermissionGenerateRenewalOpportunities
                    && GenerateRenewalOpportunitiesJob.hasPermissionBypassRestrictRenewalOpportunities
                );
            }
            return hasPermissions;
        }
        private set;
    }

    private static Boolean hasPermissionGenerateRenewalOpportunities {
        private get {
            if ( hasPermissionGenerateRenewalOpportunities == null ) {
                hasPermissionGenerateRenewalOpportunities = CustomPermissionController.checkUserPermission(
                    'Generate_Renewal_Opportunities' ,
                    UserInfo.getUserId()
                );
            }
            return hasPermissionGenerateRenewalOpportunities;
        }
        private set;
    }

    private static Boolean hasPermissionBypassRestrictRenewalOpportunities {
        private get {
            if ( hasPermissionBypassRestrictRenewalOpportunities == null ) {
                hasPermissionBypassRestrictRenewalOpportunities = CustomPermissionController.checkUserPermission(
                    'Bypass_Restrict_Renewal_Opportunities' ,
                    UserInfo.getUserId()
                );
            }
            return hasPermissionBypassRestrictRenewalOpportunities;
        }
        private set;
    }

    //
    // attributes controlled by Custom Settings...
    // ~ intentionally static to allow Custom Settings to modify the attributes a running job...
    //

    private static Renewal_Opportunity_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Renewal_Opportunity_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( GenerateRenewalOpportunitiesJob.settings != null )
                    && ( GenerateRenewalOpportunitiesJob.settings.BatchSize__c != null )
                   )
                {
                    local = GenerateRenewalOpportunitiesJob.settings.BatchSize__c.intValue();
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

    private static Boolean isEnabled {
        private get {
            if ( isEnabled == null ) {
                Boolean local = false;
                if ( GenerateRenewalOpportunitiesJob.settings != null ) {
                    local = GenerateRenewalOpportunitiesJob.settings.IsEnabled__c;
                }
                // "Renewal" Opportunity Record Type Id must be defined...
                if ( String.isBlank( GenerateRenewalOpportunitiesJob.renewalRecordTypeId ) ) {
                    local = false;
                }
                // required custom permissions...
                local = ( local && GenerateRenewalOpportunitiesJob.hasPermissions );
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static String renewalRecordTypeId  {
        private get {
            if ( renewalRecordTypeId == null ) {
                String local = null;
                if ( GenerateRenewalOpportunitiesJob.settings != null ) {
                    local = GenerateRenewalOpportunitiesJob.settings.RenewalRecordTypeId__c;
                }
                renewalRecordTypeId  = local;
            }
            return renewalRecordTypeId;
        }
        private set;
    }

    private static Map<String, String> validRenewalBenefitPackageValues {
        private get {
            if ( validRenewalBenefitPackageValues == null && !Test.isRunningTest() ) {
                Map<String,String> local = new Map<String,String>();
                ConnectApi.PicklistValuesCollection picklistValues =
                    ConnectApi.recordUi.getPicklistValuesByRecordType(
                        'Opportunity',
                        GenerateRenewalOpportunitiesJob.renewalRecordTypeId
                    );
                if ( picklistValues != null ) {
                    for ( ConnectApi.PicklistValue p : picklistValues.picklistFieldValues.get('Renewal_Benefits_Package__c').values) {
                        if ( p != null && p.label != null && p.value != null ){
                            local.put(p.label,p.value);
                        }
                    }
                }
                validRenewalBenefitPackageValues = local;
            }
            return validRenewalBenefitPackageValues;
        }
        private set;
    }

    private static List<String> monitorEmailAddresses  {
        private get {
            if ( monitorEmailAddresses == null ) {
                List<String> local = new List<String>();
                if ( GenerateRenewalOpportunitiesJob.settings != null ) {
                    String rawMonitorEmailAddresses = GenerateRenewalOpportunitiesJob.settings.MonitorEmailAddresses__c;
                    if ( String.isNotBlank( rawMonitorEmailAddresses ) ) {
                        List<String> splitMonitorEmailAddresses = rawMonitorEmailAddresses.split( '\r\n' );
                        if ( ( splitMonitorEmailAddresses != null )
                            && !splitMonitorEmailAddresses.isEmpty()
                            )
                        {
                            local = splitMonitorEmailAddresses;
                        }
                    }
                }
                monitorEmailAddresses = local;
            }
            return monitorEmailAddresses;
        }
        private set;
    }

    // Selection of all active Service_Package_Mappping__mdt records...
    private static List<Service_Package_Mapping__mdt> activeServicePackageMappings {
        private get {
            if ( activeServicePackageMappings == null ) {
                List<Service_Package_Mapping__mdt> local = new List<Service_Package_Mapping__mdt>();
                List<Service_Package_Mapping__mdt> activeServicePackages = [
                    SELECT
                        DeveloperName ,
                        MasterLabel ,
                        Active__c ,
                        Primary_Product__c ,
                        Service_Package__c
                    FROM Service_Package_Mapping__mdt
                    WHERE ( Active__c = true )
                ];
                if ( ( activeServicePackages != null )
                    && !activeServicePackages.isEmpty()
                    )
                {
                    local = activeServicePackages;
                }
                activeServicePackageMappings = local;
            }
            return activeServicePackageMappings;
        }
        private set;
    }

    // Map from Service pakage to Primary product
    private static Map<String,String> primaryProductMap {
        private get {
            if ( primaryProductMap == null ) {
                Map<String,String> local = new Map<String,String>();
                if ( ( GenerateRenewalOpportunitiesJob.activeServicePackageMappings != null )
                    && !GenerateRenewalOpportunitiesJob.activeServicePackageMappings.isEmpty()
                    )
                {
                    for ( Service_Package_Mapping__mdt record : GenerateRenewalOpportunitiesJob.activeServicePackageMappings ) {
                        if ( String.isNotBlank( record.Primary_Product__c )
                            && String.isNotBlank( record.Service_Package__c )
                            )
                        {
                            local.put( record.Service_Package__c , record.Primary_Product__c );
                        }
                    }
                }
                primaryProductMap = local;
            }
            return primaryProductMap;
        }
        private set;
    }

    private void buildWSEEMaps( List<NSP_Sub_Client__c> records ) {
        if ( ( records != null ) && !records.isEmpty() ) {
            for ( NSP_Sub_Client__c rec : records ) {
                if ( ( rec != null )
                    && ( rec.NSP_Account_Status__c == 'Active' )
                    && String.isNotBlank( rec.NSP_Client__c )
                    )
                {
                    if ( !this.fullTimeWSEEMap.containsKey( rec.NSP_Client__c ) ) {
                        this.fullTimeWSEEMap.put( rec.NSP_Client__c , 0 );
                        this.partTimeWSEEMap.put( rec.NSP_Client__c , 0 );
                        this.seasonalTimeWSEEMap.put( rec.NSP_Client__c , 0 );
                    }
                    Decimal fulltime = this.getDecimalValue( rec.NSP_Actual_Full_Time_EE_Count__c );
                    Decimal parttime = this.getDecimalValue( rec.NSP_Actual_Part_Time_EE_Count__c );
                    Decimal seasonal = this.getDecimalValue( rec.NSP_Actual_Seasonal_Time_EE_Count__c );
                    this.fullTimeWSEEMap.put(
                        rec.NSP_Client__c ,
                        ( this.fullTimeWSEEMap.get(rec.NSP_Client__c) + fulltime )
                    );
                    this.partTimeWSEEMap.put(
                        rec.NSP_Client__c ,
                        ( this.partTimeWSEEMap.get(rec.NSP_Client__c) + parttime )
                    );
                    this.seasonalTimeWSEEMap.put(
                        rec.NSP_Client__c ,
                        ( this.seasonalTimeWSEEMap.get(rec.NSP_Client__c) + seasonal )
                    );
                }
            }
        }
    }

    private Decimal getDecimalValue( Decimal value ) {
        return ( ( value == null ) ? 0 : value );
    }

    private Decimal getMapValue( Map<String,Decimal> valueMap , String key ) {
        Decimal value = 0;
        if ( String.isNotBlank( key )
            && ( valueMap != null )
            && valueMap.containsKey( key )
            )
        {
            value = valueMap.get( key );
        }
        return value;
    }

    private String fetchRenewalName( NSP_Sub_Client__c subClient ) {
        List<String> renewalNameParts = new List<String>();
        String renewalName = '';
        if ( subClient != null ) {
            if ( String.isNotBlank( subClient.NSP_Client__c )
                && ( subClient.NSP_Client__c != null )
                )
            {
                renewalNameParts.add( subClient.NSP_Client__c );
            }
            if ( subClient.NSP_Renewal_Date__c != null ) {
                renewalNameParts.add(
                    String.valueOf( subClient.NSP_Renewal_Date__c.addYears( 1 ).year() )
                );
            }
            if ( ( subClient.NSP_Account__r != null )
                && String.isNotBlank( subClient.NSP_Account__r.Name )
                )
            {
                renewalNameParts.add( subClient.NSP_Account__r.Name );
            }
        }
        renewalName = String.join( renewalNameParts , ' : ' );
        return renewalName;
    }

    private String getRenewalTeam( NSP_Sub_Client__c subClient ) {
        String renewalTeam = '';
        if ( ( subClient != null )
            && ( subClient.NSP_Asset__r != null )
            && ( subClient.NSP_Asset__r.NSP_Sales_Office__c != null )
            && ( this.salesOfficeMap != null )
            && this.salesOfficeMap.containsKey( subClient.NSP_Asset__r.NSP_Sales_Office__c )
            && ( this.salesOfficeMap.get( subClient.NSP_Asset__r.NSP_Sales_Office__c ) != null )
            )
        {
            renewalTeam = this.salesOfficeMap.get( subClient.NSP_Asset__r.NSP_Sales_Office__c ).Renewal_Team__c;
        }
        return renewalTeam;
    }

}
//