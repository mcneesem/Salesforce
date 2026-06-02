public class GenerateRenewalOpportunitiesJob implements  Database.Stateful,Database.Batchable<SObject> {
    // test w/ GenerateRenewalOpportunitiesJobTest (89%)
    
    // Inputs from Flow/Invocable (selected month & year)
    private Integer runMonth;
    private Integer runYear;
    
    // Derived eligibility: one year prior selected month
    private Date eligibleStart;
    private Date eligibleEnd;
    
    Map<String, NSP_Sales_Office_Mapping__c> salesOfficeToManagerMap = new Map<String, NSP_Sales_Office_Mapping__c>();
    Map<Id,Id> clientIdWithOpportunityIdMap = new Map<Id,Id>();
    Map<String,NSP_Sub_Client__c> finalOpprtunitySet = new Map<String,NSP_Sub_Client__c>();
    private Map<String, Decimal> fullTimeWSEEMap = new Map<String, Decimal>();
    private Map<String, Decimal> partTimeWSEEMap = new Map<String, Decimal>();
    private Map<String, Decimal> seasonalTimeWSEEMap = new Map<String, Decimal>();
    
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
            Order by NSP_Client__c,NSP_Sub_Client__c ASC
        ]); 
    }
    public void execute( Database.BatchableContext bc, List<NSP_Sub_Client__c> records ) {
        if ( records != null 
            && !records.isEmpty()
            && GenerateRenewalOpportunitiesJob.isEnabled
            && String.isNotBlank( GenerateRenewalOpportunitiesJob.RenewalRecordTypeId )
           )
        {
            this.buildSalesOfficeToRenewalManagerMap( records );
            this.buildWSEEMaps(records);
            this.processOpportunities(records);
        }
        
    }
    public void finish(Database.BatchableContext bc) {}
    
    private void buildEntries( NSP_Sub_Client__c subClient ){
        if ( subClient != null  
            && String.isNotBlank( subClient.NSP_Client__c ) 
            && String.isNotBlank( subClient.NSP_Benefit_Package_Name__c)
           )
        {
            String key = subClient.NSP_Client__c+subClient.NSP_Benefit_Package_Name__c;
            if (  String.isNotBlank( subClient.NSP_Sub_Client__c ) 
                && this.finalOpprtunitySet != null 
                && !this.finalOpprtunitySet.isEmpty()
                && this.finalOpprtunitySet.containsKey( key )
               )
            {
                NSP_Sub_Client__c mapValue = this.finalOpprtunitySet.get( key );
                if ( subClient.NSP_Sub_Client__c == subClient.NSP_Client__c 
                    && mapValue != null 
                    && mapValue.NSP_Sub_Client__c != mapValue.NSP_Client__c )
                {
                    this.finalOpprtunitySet.put( key,subClient );
                }
                
            }else{
                this.finalOpprtunitySet.put( key,subClient );
            }    
        }      
    }
    
    private void processOpportunities(List<NSP_Sub_Client__c> records){
        List<Opportunity> parentOpportunities = new List<Opportunity>();
        List<Opportunity> childOpportunities = new List<Opportunity>();
        if ( records != null && !records.isEmpty() ){
            for ( NSP_Sub_Client__c record : records ){
                this.buildEntries( record );
            }
            for ( NSP_Sub_Client__c subClient : records ){
                if ( this.checkEligibility( subClient )){
                    if ( subClient.NSP_Sub_Client__c == subClient.NSP_Client__c ){
                        this.buildOpportunity( subClient, parentOpportunities);
                    } else {
                        this.buildOpportunity( subClient, childOpportunities );
                    }
                    
                }
            } 
        }
        this.performDMLToParentOpportunities( parentOpportunities );
        this.mapChildToParentOpportunities( childOpportunities );
        this.performDML(childOpportunities);
    }
    private Boolean checkEligibility(NSP_Sub_Client__c subClient){
        Boolean flag = false;
        if ( subClient != null 
            && String.isNotBlank( subClient.NSP_Sub_Client__c ) 
            && String.isNotBlank( subClient.NSP_Client__c )
            && String.isNotBlank( subClient.NSP_Benefit_Package_Name__c )
           )
        {
            String key = subClient.NSP_Client__c + subClient.NSP_Benefit_Package_Name__c;
            if ( this.finalOpprtunitySet.containsKey( key ) ){
                NSP_Sub_Client__c scRec = this.finalOpprtunitySet.get( key );
                if( scRec != null 
                   && scRec.NSP_Client__c == subClient.NSP_Client__c 
                   && scRec.NSP_Sub_Client__c == subClient.NSP_Sub_Client__c                    
                  )
                {
                    flag = true;   
                }
            }
            
        }
        return flag;
    }
    
    private void buildOpportunity( NSP_Sub_Client__c subClient, List<Opportunity> opportunities ){
        Opportunity opp = new Opportunity();
        if ( subClient != null ){
            opp.AccountId = subClient.NSP_Account__c;
            opp.RecordTypeId = GenerateRenewalOpportunitiesJob.RenewalRecordTypeId;
            opp.Name = this.buildOpportunityName( subClient );
            opp.OwnerId = this.getOpportunityOwner( subClient ); 
            opp.NSP_PrimaryProduct__c = this.getPrimaryProduct(  subClient );
            opp.NSP_Client_For_Life__c = 'WO/WS';
            opp.CloseDate = subclient.NSP_Renewal_Date__c;
            opp.StageName = 'Preparation';
            opp.Type = 'Renewal';
            opp.Asset__c = subClient.NSP_Asset__c;
            opp.Service_Package__c = subClient.NSP_Asset__r != null ? subClient.NSP_Asset__r.NSP_Service_Package__c : null;
            opp.NSP_Sales_Office__c = subClient.NSP_Asset__r != null ? subClient.NSP_Asset__r.NSP_Sales_Office__c : null;
            opp.Current_Renewal_Date__c = subClient.NSP_Renewal_Date__c;
            opp.Next_Renewal_Date__c = subClient.NSP_Renewal_Date__c != null ? subClient.NSP_Renewal_Date__c.addYears(1): null;
            opp.Current_Benefits_Package__c = subClient.NSP_Benefit_Package_Name__c;
            opp.Current_Margin__c = subClient.NSP_Margin__c;
            opp.Current_Reserve__c = subClient.NSP_Reserve__c;
            opp.Client_Retained_WC__c = (subClient.NSP_Asset__r != null && subClient.NSP_Asset__r.NSP_Client_Retained_Workers_Comp__c != null) ? 'Yes': 'No';
            opp.Renewal_Status__c = 'Not Started';
            opp.Renewal_Name__c = this.fetchRenewalName(subClient);
            opp.Renewal_Team__c = this.getRenewalTeam(subClient);
            opp.Full_Time_WSEEs__c = getMapValue(fullTimeWSEEMap, subClient.NSP_Client__c);
            opp.Part_Time_WSEEs__c = getMapValue(partTimeWSEEMap, subClient.NSP_Client__c);
            opp.Seasonal_Time_WSEEs__c = getMapValue(seasonalTimeWSEEMap, subClient.NSP_Client__c);
        }
        if( opp != null ){
            opportunities.add( opp );
        }
    }
    
    private void performDML( List<Opportunity> records ) {
        if ( ( records != null )
            && !records.isEmpty()
           )
        {
            try {
                List<Database.SaveResult> results = Database.Insert( records , false );
                NSP_ErrorLogHandler.logResults(
                    GenerateRenewalOpportunitiesJob.class.getName() ,
                    'performDML:Insert' ,
                    results
                );
            } catch( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    GenerateRenewalOpportunitiesJob.class.getName() ,
                    'performDML' ,
                    e
                );
            }
        }
    }
    
    private List<Opportunity> mapChildToParentOpportunities( List<Opportunity> childOpportunities ){
        if ( childOpportunities != null 
            && (!childOpportunities.isEmpty())
            && this.clientIdWithOpportunityIdMap != null 
            && !this.clientIdWithOpportunityIdMap.isEmpty()
           )
        {
            for( Opportunity opp: childOpportunities ){
                if ( opp != null 
                    && String.isNotBlank( Opp.AccountId ) 
                    && this.clientIdWithOpportunityIdMap.containsKey( Opp.AccountId ) 
                    && this.clientIdWithOpportunityIdMap.get( Opp.AccountId ) != null
                   )
                {
                    opp.NSP_Parent_Opportunity__c = this.clientIdWithOpportunityIdMap.get( Opp.AccountId ); 
                }
            }  
        }
        return childOpportunities;
    }
    
    private Map<Id,Id> performDMLToParentOpportunities( List<Opportunity> parentOpportunities ) {
        if ( ( parentOpportunities != null )
            && !parentOpportunities.isEmpty()
           )
        {
            try {
                Insert parentOpportunities;
                for( Opportunity opp : parentOpportunities ){
                    if ( opp != null 
                        && opp.AccountId != null
                       )
                    {
                        this.clientIdWithOpportunityIdMap.put( opp.AccountId, opp.Id );  
                    }
                }
            } catch( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    GenerateRenewalOpportunitiesJob.class.getName() ,
                    'performDMLToParentOpportunities' ,
                    e
                );
            }
        }
        return clientIdWithOpportunityIdMap;
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
            && this.salesOfficeToManagerMap != null 
            && !this.salesOfficeToManagerMap.isEmpty()
            && this.salesOfficeToManagerMap.containsKey( subClient.NSP_Asset__r.NSP_Sales_Office__c )
           )
        {
            NSP_Sales_Office_Mapping__c som = this.salesOfficeToManagerMap.get( subClient.NSP_Asset__r.NSP_Sales_Office__c );
            if ( som != null && String.isNotBlank( som.Renewal_Manager__c ) ){
                owner = som.Renewal_Manager__c;
            }
        }
        return owner;
    }
    
    private String buildOpportunityName(  NSP_Sub_Client__c subClient ){
        String name = null;
        if ( subClient != null 
            && subClient.NSP_Account__r != null 
            && String.isNotBlank( subClient.NSP_Account__r.Name )
           )
        { 
            name = subClient.NSP_Account__r.Name +' - '+System.Now();
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
        this.salesOfficeToManagerMap = buildSalesOfficeMap(salesOfficeKeys);
    }
    
    private Map<String, NSP_Sales_Office_Mapping__c> buildSalesOfficeMap(List<String> salesOfficeKeys) {
        Map<String, NSP_Sales_Office_Mapping__c> salesOfficeToOwnerId = new Map<String, NSP_Sales_Office_Mapping__c>();
        if ( salesOfficeKeys != null && !salesOfficeKeys.isEmpty() ) {
            for ( NSP_Sales_Office_Mapping__c som : [
                SELECT Id, NSP_Sales_Office__c, Renewal_Manager__c, Renewal_Team__c
                FROM NSP_Sales_Office_Mapping__c
                WHERE NSP_Sales_Office__c IN :salesOfficeKeys
            ]){
                if ( som != null && som.NSP_Sales_Office__c != null ) {
                    salesOfficeToOwnerId.put( som.NSP_Sales_Office__c, som);
                }
            }
        }
        return salesOfficeToOwnerId;
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
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }
    
    private static String RenewalRecordTypeId {
        private get {
            if ( RenewalRecordTypeId == null ) {
                String local = null;
                if ( GenerateRenewalOpportunitiesJob.settings != null ) {
                    local = GenerateRenewalOpportunitiesJob.settings.RenewalRecordTypeId__c;
                }
                RenewalRecordTypeId = local;
            }
            return RenewalRecordTypeId;
        }
        private set;
    }
    
    // Selection of all active Service_Package_Mappping__mdt records...
    private static List<Service_Package_Mapping__mdt> activeServicePackageMappings {
        private get {
            if ( activeServicePackageMappings == null ) {
                activeServicePackageMappings = [
                    SELECT
                    DeveloperName ,
                    MasterLabel ,
                    Active__c ,
                    Primary_Product__c ,
                    Service_Package__c 
                    FROM Service_Package_Mapping__mdt 
                    WHERE Active__c = true 
                ];
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
        for (NSP_Sub_Client__c rec : records){
            if (rec != null && rec.NSP_Account_Status__c == 'Active' && String.isNotBlank(rec.NSP_Client__c)){
                if (!fullTimeWSEEMap.containsKey(rec.NSP_Client__c)){
                    fullTimeWSEEMap.put(rec.NSP_Client__c, 0);
                    partTimeWSEEMap.put(rec.NSP_Client__c, 0);
                    seasonalTimeWSEEMap.put(rec.NSP_Client__c, 0);
                }
                Decimal ft = getDecimalValue(rec.NSP_Actual_Full_Time_EE_Count__c);
                Decimal pt = getDecimalValue(rec.NSP_Actual_Part_Time_EE_Count__c );
                Decimal seasonal = getDecimalValue(rec.NSP_Actual_Seasonal_Time_EE_Count__c);
                
                fullTimeWSEEMap.put(rec.NSP_Client__c, fullTimeWSEEMap.get(rec.NSP_Client__c) + ft);
                partTimeWSEEMap.put(rec.NSP_Client__c, partTimeWSEEMap.get(rec.NSP_Client__c) + pt);
                seasonalTimeWSEEMap.put(rec.NSP_Client__c, seasonalTimeWSEEMap.get(rec.NSP_Client__c) + seasonal);
            }
        }
    }
    
    private Decimal getDecimalValue(Decimal value) {
        return value == null ? 0 : value;
    }
    
    private Decimal getMapValue(Map<String, Decimal> valueMap, String key) {
        if (valueMap.containsKey(key)) {
            return valueMap.get(key);
        } else {
            return 0;
        }
    }
    
    private String fetchRenewalName(NSP_Sub_Client__c subClient){
        List<String> renewalNameParts = new List<String>();
        String renewalName = '';
        if (String.isNotBlank(subClient.NSP_Client__c) && subClient.NSP_Client__c != null) {
            renewalNameParts.add(subClient.NSP_Client__c); 
        }
        if (subClient.NSP_Renewal_Date__c != null){
            renewalNameParts.add(String.valueOf(subClient.NSP_Renewal_Date__c.addYears(1).year()));
        }
        if (subClient.NSP_Account__r != null && String.isNotBlank(subClient.NSP_Account__r.Name)){
            renewalNameParts.add(subClient.NSP_Account__r.Name);
        }
        renewalName = String.join(renewalNameParts, ' : ');
        return renewalName;
    }
    
    private String getRenewalTeam(NSP_Sub_Client__c subClient) {
        if (subClient.NSP_Asset__r != null && subClient.NSP_Asset__r.NSP_Sales_Office__c != null && salesOfficeToManagerMap.containsKey(subClient.NSP_Asset__r.NSP_Sales_Office__c)) {
            return salesOfficeToManagerMap.get(subClient.NSP_Asset__r.NSP_Sales_Office__c).Renewal_Team__c;
        }
        return null;
    }
}