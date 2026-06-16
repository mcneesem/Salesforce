public class GenerateRenewalOpportunitiesJob implements  Callable,IJobRunnable,Database.Stateful,Database.Batchable<SObject> {
    // test w/ GenerateRenewalOpportunitiesJobTest (87%)

    // Inputs from Flow/Invocable (selected month & year)
    private Integer runMonth;
    private Integer runYear;

    // Derived eligibility: one year prior selected month
    private Date eligibleStart;
    private Date eligibleEnd;

    Map<String, NSP_Sales_Office_Mapping__c> salesOfficeMap = new Map<String, NSP_Sales_Office_Mapping__c>();
    Map<Id,Id> accountParentOpportunityMap = new Map<Id,Id>();
    Map<String,NSP_Sub_Client__c> entryOpportunityMap = new Map<String,NSP_Sub_Client__c>();
    private Map<String, Decimal> fullTimeWSEEMap = new Map<String, Decimal>();
    private Map<String, Decimal> partTimeWSEEMap = new Map<String, Decimal>();
    private Map<String, Decimal> seasonalTimeWSEEMap = new Map<String, Decimal>();

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
        return GenerateRenewalOpportunitiesJob.executeBatch( null , null );
    }

    public static Id executeBatch( Integer monthNum, Integer yearNum ) {
        Id response = null;
        if ( GenerateRenewalOpportunitiesJob.isEnabled ) {
            response = Database.executeBatch(
                new GenerateRenewalOpportunitiesJob( monthNum , yearNum ) ,
                GenerateRenewalOpportunitiesJob.batchSize
            );
        }
        return response;
    }

    public GenerateRenewalOpportunitiesJob( Integer monthNum, Integer yearNum ) {

        if ( monthNum != null && yearNum != null ){

            this.runMonth = monthNum;
            this.runYear  = yearNum;

            // Example: user selects Dec 2026 => eligible window is Dec 2025
            Integer eligibleYear = yearNum - 1;
            this.eligibleStart = Date.newInstance( eligibleYear, monthNum, 1 );
            this.eligibleEnd   = this.eligibleStart.addMonths(1).addDays(-1);
        }

    }
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        return Database.getQueryLocator([
            SELECT Id,
            Name,
            NSP_Account__r.Name,
            NSP_Account_Status__c,
            NSP_Client__c,
            NSP_Sub_Client__c,
            NSP_Renewal_Date__c,
            NSP_Benefit_Package_Name__c,
            NSP_Asset__c,
            NSP_Asset__r.NSP_Sales_Office__c,
            NSP_Asset__r.NSP_Service_Package__c,
            NSP_Account__c,
            NSP_Margin__c,
            NSP_Reserve__c,
            NSP_Actual_Full_Time_EE_Count__c,
            NSP_Actual_Part_Time_EE_Count__c,
            NSP_Actual_Seasonal_Time_EE_Count__c,
            NSP_Asset__r.NSP_Client_Retained_Workers_Comp__c
            FROM NSP_Sub_Client__c
            WHERE NSP_Account_Status__c = 'Active'
            AND NSP_Renewal_Date__c >= :this.eligibleStart
            AND NSP_Renewal_Date__c <= :this.eligibleEnd
            AND NSP_Renewal_Date__c != null
            ORDER BY NSP_Client__c,NSP_Sub_Client__c ASC
        ]);
    }

    public void execute( Database.BatchableContext bc, List<NSP_Sub_Client__c> records ) {
        if ( records != null
            && !records.isEmpty()
            && GenerateRenewalOpportunitiesJob.isEnabled
           )
        {
            try {
                this.buildSalesOfficeToRenewalManagerMap( records );
                this.buildWSEEMaps( records );
                this.processEntries( records );
                this.processOpportunities( records );
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    GenerateRenewalOpportunitiesJob.class.getName() ,
                    'execute' ,
                    e
                );
            }
        }
    }

    public void finish(Database.BatchableContext bc) {}

    private void processOpportunities(List<NSP_Sub_Client__c> records){
        List<Opportunity> parentOpportunities = new List<Opportunity>();
        List<Opportunity> childOpportunities = new List<Opportunity>();
        if ( records != null && !records.isEmpty() ){
            for ( NSP_Sub_Client__c subClient : records ){
                if ( this.checkEligibility( subClient )){
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
        }
        this.performDml( parentOpportunities, true );
        this.mapChildToParentOpportunities( childOpportunities );
        this.performDml( childOpportunities, false );
    }

    private Opportunity buildOpportunity( NSP_Sub_Client__c subClient ) {
        Opportunity opp = null;
        if ( subClient != null ) {
            opp = new Opportunity();
            opp.AccountId = subClient.NSP_Account__c;
            opp.RecordTypeId = GenerateRenewalOpportunitiesJob.renewalRecordTypeId;
            opp.Name = this.buildOpportunityName( subClient );
            opp.OwnerId = this.getOpportunityOwner( subClient );
            opp.NSP_PrimaryProduct__c = this.getPrimaryProduct(  subClient );
            opp.NSP_Client_For_Life__c = 'WO/WS';
            opp.CloseDate = subclient.NSP_Renewal_Date__c;
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
            opp.Current_Margin__c = subClient.NSP_Margin__c;
            opp.Current_Reserve__c = subClient.NSP_Reserve__c;
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

    private void processEntries( List<NSP_Sub_Client__c> subClients ){
        if ( subClients != null && !subClients.isEmpty() ){
            for( NSP_Sub_Client__c subClient : subClients ){
                this.buildEntries( subClient );
            }
        }
    }

    private void buildEntries( NSP_Sub_Client__c subClient ){

        String key = this.buildKey( subClient );
        if ( String.isNotBlank( key ) && subClient != null ){
            if ( String.isNotBlank( subClient.NSP_Sub_Client__c )
                && this.entryOpportunityMap != null
                && !this.entryOpportunityMap.isEmpty()
                && this.entryOpportunityMap.containsKey( key )
               )
            {
                NSP_Sub_Client__c mapValue = this.entryOpportunityMap.get( key );
                if ( subClient.NSP_Sub_Client__c == subClient.NSP_Client__c
                    && mapValue != null
                    && mapValue.NSP_Sub_Client__c != mapValue.NSP_Client__c
                   )
                {
                    this.entryOpportunityMap.put( key,subClient );
                }
            }else{
                this.entryOpportunityMap.put( key,subClient );
            }
        }
    }

    private Boolean checkEligibility(NSP_Sub_Client__c subClient){
        Boolean flag = false;
        String key = this.buildKey( subClient );
        if ( subClient != null
            && String.isNotBlank( subClient.NSP_Sub_Client__c )
            && String.isNotBlank( key )
            && this.entryOpportunityMap.containsKey( key )
           )
        {
            NSP_Sub_Client__c scRec = this.entryOpportunityMap.get( key );
            if ( scRec != null
                && scRec.NSP_Client__c == subClient.NSP_Client__c
                && scRec.NSP_Sub_Client__c == subClient.NSP_Sub_Client__c
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

    private List<Opportunity> mapChildToParentOpportunities( List<Opportunity> childOpportunities ){
        if ( childOpportunities != null
            && !childOpportunities.isEmpty()
            && this.accountParentOpportunityMap != null
            && !this.accountParentOpportunityMap.isEmpty()
           )
        {
            for( Opportunity opp: childOpportunities ){
                if ( opp != null
                    && String.isNotBlank( opp.AccountId )
                    && this.accountParentOpportunityMap.containsKey( opp.AccountId )
                    && this.accountParentOpportunityMap.get( opp.AccountId ) != null
                   )
                {
                    opp.NSP_Parent_Opportunity__c = this.accountParentOpportunityMap.get( opp.AccountId );
                }
            }
        }
        return childOpportunities;
    }

    private void performDml( List<Opportunity> records , Boolean isParentOpportunities ) {
        if ( ( records != null )
            && !records.isEmpty()
            )
        {
            List<Database.SaveResult> results = Database.insert( records , false );
            NSP_ErrorLogHandler.logResults(
                GenerateRenewalOpportunitiesJob.class.getName() ,
                'performDml:insert' + ( isParentOpportunities ? ':parent' : ':child' ) ,
                results
            );
            if ( isParentOpportunities ) {
                for ( Opportunity record : records ) {
                    if ( ( record != null )
                        && ( record.AccountId != null )
                        )
                    {
                        this.accountParentOpportunityMap.put( record.AccountId, record.Id );
                    }
                }
            }
        }
    }

    private String getPrimaryProduct( NSP_Sub_Client__c subClient ){
        String primaryProduct = null;
        if ( subClient != null
            && subClient.NSP_Asset__r != null
            && String.isNotBlank( subClient.NSP_Asset__r.NSP_Service_Package__c )
            && GenerateRenewalOpportunitiesJob.primaryProductMap != null
            && !GenerateRenewalOpportunitiesJob.primaryProductMap.isEmpty()
            && GenerateRenewalOpportunitiesJob.primaryProductMap.containsKey( subClient.NSP_Asset__r.NSP_Service_Package__c )
            && GenerateRenewalOpportunitiesJob.primaryProductMap.get( subClient.NSP_Asset__r.NSP_Service_Package__c ) != null
           )
        {
            primaryProduct = GenerateRenewalOpportunitiesJob.primaryProductMap.get( subClient.NSP_Asset__r.NSP_Service_Package__c );
        }
        return primaryProduct;
    }

    private Id getOpportunityOwner( NSP_Sub_Client__c subClient ){
        Id owner = userInfo.getUserId();
        if ( subClient != null
            && subClient.NSP_Asset__r != null
            && String.isNotBlank( subClient.NSP_Asset__r.NSP_Sales_Office__c )
            && this.salesOfficeMap != null
            && !this.salesOfficeMap.isEmpty()
            && this.salesOfficeMap.containsKey( subClient.NSP_Asset__r.NSP_Sales_Office__c )
           )
        {
            NSP_Sales_Office_Mapping__c som = this.salesOfficeMap.get( subClient.NSP_Asset__r.NSP_Sales_Office__c );
            if ( som != null && String.isNotBlank( som.Renewal_Manager__c ) ){
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

    // Sales office -> Renewal Manager mapping
    private void buildSalesOfficeToRenewalManagerMap( List<NSP_Sub_Client__c> subClients ){
        List<String> salesOfficeKeys = new List<String>();
        if ( subClients != null && !subClients.isEmpty() ){
            for ( NSP_Sub_Client__c record : subClients ) {
                if ( record != null && record.NSP_Asset__r != null && String.isNotBlank( record.NSP_Asset__r.NSP_Sales_Office__c ) ){
                    salesOfficeKeys.add( record.NSP_Asset__r.NSP_Sales_Office__c );
                }
            }
        }
        this.buildSalesOfficeMap(salesOfficeKeys);
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
                Boolean local = False;
                if ( GenerateRenewalOpportunitiesJob.settings != null ) {
                    local = GenerateRenewalOpportunitiesJob.settings.IsEnabled__c;
                }
                // "Renewal" Opportunity Record Type Id must be defined...
                if ( String.isBlank( GenerateRenewalOpportunitiesJob.renewalRecordTypeId ) ) {
                    local = false;
                }
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

    // Selection of all active Service_Package_Mappping__mdt records...
    private static List<Service_Package_Mapping__mdt> activeServicePackageMappings {
        private get {
            if ( activeServicePackageMappings == null ) {
                List<Service_Package_Mapping__mdt> local = new List<Service_Package_Mapping__mdt>();
                List<Service_Package_Mapping__mdt>  activeServicePackages = [
                    SELECT
                    DeveloperName ,
                    MasterLabel ,
                    Active__c ,
                    Primary_Product__c ,
                    Service_Package__c
                    FROM Service_Package_Mapping__mdt
                    WHERE Active__c = true
                ];
                if ( activeServicePackages != null && !activeServicePackages.isEmpty() ){
                    local = activeServicePackages;
                }
                activeServicePackageMappings = local;
            }
            return activeServicePackageMappings;
        }
        private set;
    }

    // Map from Service pakage to Primary product
    private static Map<String, String > primaryProductMap {
        private get {
            if ( primaryProductMap == null ) {
                Map<String, String > local = new Map<String, String >();
                if ( ( GenerateRenewalOpportunitiesJob.activeServicePackageMappings != null )
                    && !GenerateRenewalOpportunitiesJob.activeServicePackageMappings.isEmpty()
                   )
                {
                    for ( Service_Package_Mapping__mdt record : GenerateRenewalOpportunitiesJob.activeServicePackageMappings ) {
                        if ( String.isNotBlank( record.Primary_Product__c )
                            && String.isNotBlank( record.Service_Package__c )
                           )
                        {
                            local.put( record.Service_Package__c, record.Primary_Product__c );
                        }
                    }
                }
                primaryProductMap = local;
            }
            return primaryProductMap;
        }
        private set;
    }

    private void buildWSEEMaps(List<NSP_Sub_Client__c> records){
        if ( records != null
            && !records.isEmpty() ){
            for (NSP_Sub_Client__c rec : records){
                if ( rec != null
                    && rec.NSP_Account_Status__c == 'Active'
                    && String.isNotBlank(rec.NSP_Client__c)
                   )
                {
                    if ( !this.fullTimeWSEEMap.containsKey(rec.NSP_Client__c)){
                        this.fullTimeWSEEMap.put(rec.NSP_Client__c, 0);
                        this.partTimeWSEEMap.put(rec.NSP_Client__c, 0);
                        this.seasonalTimeWSEEMap.put(rec.NSP_Client__c, 0);
                    }
                    Decimal ft = this.getDecimalValue(rec.NSP_Actual_Full_Time_EE_Count__c);
                    Decimal pt = this.getDecimalValue(rec.NSP_Actual_Part_Time_EE_Count__c );
                    Decimal seasonal = this.getDecimalValue(rec.NSP_Actual_Seasonal_Time_EE_Count__c);

                    this.fullTimeWSEEMap.put(rec.NSP_Client__c, this.fullTimeWSEEMap.get(rec.NSP_Client__c) + ft);
                    this.partTimeWSEEMap.put(rec.NSP_Client__c, this.partTimeWSEEMap.get(rec.NSP_Client__c) + pt);
                    this.seasonalTimeWSEEMap.put(rec.NSP_Client__c, this.seasonalTimeWSEEMap.get(rec.NSP_Client__c) + seasonal);
                }
            }
        }

    }

    private Decimal getDecimalValue(Decimal value) {
        return value == null ? 0 : value;
    }

    private Decimal getMapValue(Map<String, Decimal> valueMap, String key) {
        Decimal value = 0;
        if ( String.isNotBlank(key)
            && valueMap != null
            && valueMap.containsKey(key)
           )
        {
            value = valueMap.get(key);
        }
        return value;
    }

    private String fetchRenewalName(NSP_Sub_Client__c subClient){
        List<String> renewalNameParts = new List<String>();
        String renewalName = '';
        if ( subClient != null ){
            if ( String.isNotBlank(subClient.NSP_Client__c) && subClient.NSP_Client__c != null) {
                renewalNameParts.add(subClient.NSP_Client__c);
            }
            if ( subClient.NSP_Renewal_Date__c != null){
                renewalNameParts.add(String.valueOf(subClient.NSP_Renewal_Date__c.addYears(1).year()));
            }
            if ( subClient.NSP_Account__r != null && String.isNotBlank(subClient.NSP_Account__r.Name)){
                renewalNameParts.add(subClient.NSP_Account__r.Name);
            }
        }
        renewalName = String.join(renewalNameParts, ' : ');
        return renewalName;
    }

    private String getRenewalTeam(NSP_Sub_Client__c subClient) {
        String renewalTeam = '';
        if ( subClient != null
            && subClient.NSP_Asset__r != null
            && subClient.NSP_Asset__r.NSP_Sales_Office__c != null
            && this.salesOfficeMap != null
            && this.salesOfficeMap.containsKey(subClient.NSP_Asset__r.NSP_Sales_Office__c)
            && this.salesOfficeMap.get( subClient.NSP_Asset__r.NSP_Sales_Office__c ) != null
           )
        {
            renewalTeam = this.salesOfficeMap.get(subClient.NSP_Asset__r.NSP_Sales_Office__c).Renewal_Team__c;
        }
        return renewalTeam;
    }
}