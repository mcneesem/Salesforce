@isTest(SeeAllData=false)
    public class NSP_SrcToTargetObjectDataMoverTest {
        
    /**
    * Does test data setup
    * @param N/A. 
    * @return void                          
    */
         
    public static final String OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES = 'Retirement Services'; // Added as part of Code Fix
    public static final String OPP_STAGENAME_CLOSED_WON = 'Closed Won'; // Added as part of Code Fix
    public static final String CONTRACT_PRODUCT_TYPE = 'Organizational Planning;Performance Management'; // Added as part of test class coverage
    public static final String CONTRACT_STATUS = 'Draft'; // Added as part of test class coverage
    public static final String CURRENCY_USD = 'USD'; // Added as part of test class coverage
        
    @testSetup
    static void testData() {
        
        //Account creation
        Account accoutObject = new Account();
        accoutObject.Name = 'Test Account';
        //inserting account object
        insert accoutObject;
        
        Account accoutObject1 = new Account();
        accoutObject1.Name = 'Test Account1';
        //inserting account object
        insert accoutObject1;
        
        //Create Opportunity
        Opportunity opportuniytObject4 = new Opportunity();
        opportuniytObject4.Name = 'Test Oppty Email';
        opportuniytObject4.AccountId = accoutObject1.id;
        opportuniytObject4.stagename = NSP_SalesConstants.ANALYSIS_STAGE;
        opportuniytObject4.CloseDate = date.today();
        opportuniytObject4.CurrencyIsoCode = CURRENCY_USD;
        opportuniytObject4.NSP_PrimaryProduct__c = 'WA';
        opportuniytObject4.NSP_Client_For_Life__c='WA';
        opportuniytObject4.NSP_Number_of_Employees__c = 151; //!do not change. Test might fail
        opportuniytObject4.Type ='CAMS';
        opportuniytObject4.NSP_Upsell_Product_add_ons__c = OPP_NSP_UPSELL_PRODUCT_ADD_ONS_RETIREMENT_SERVICES;
        //Inserting Opportunity Object
        insert opportuniytObject4;
        
    }

    /**
    * Checks the update protion of the trigger
    * @param N/A. 
    * @return void                          
    */
    @isTest
    static void checkUpdatefoeWOOpptys() {
        List<String> fieldsToQueryList=New List<String> {'Name','Opportunity.accountId',
                                                        'Product2Id','Product2.Name','Quantity','UnitPrice'};
        String objectToQuery= 'OpportunityLineItem';
        Map<String, String> filterMap=new Map<String,String>{ 'Id' => '00k1100000BRZSzAAP,00k1100000BRr4kAAD',
                'Product2.NSP_Convert_to_Asset__c' => 'TRUE'
            };
        New NSP_SrcToTargetObjectDataMover(null,'OppAsset')	;	
        String query=NSP_SrcToTargetObjectDataMover.constructSourceQuery(null, filterMap);
        List< OpportunityLineItem> sourceOpportunityRecord = Database.query(query);

        List<SObject> retrned= NSP_SrcToTargetObjectDataMover.getSourceDatainTarget( sourceOpportunityRecord);

    }
}