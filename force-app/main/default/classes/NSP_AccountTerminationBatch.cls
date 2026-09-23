// Batch Class to update Account's status to terminated if all assets are terminated and their termination date is in previous month
public without sharing class NSP_AccountTerminationBatch implements ISelfSchedulable , Schedulable , Callable , IJobRunnable , Database.Batchable<SObject> , Database.Stateful {
    // test w/ NSP_AccountTerminationBatch_Test (86%)

    private static final String OBJ_AST = 'Asset';
    private static final String OBJ_OPP = 'Opportunity';
    private static final List<String> CPQ_HARDWARE = new List<String>{
        'Hardware_Asset' ,
        'NSP_CPQ_Asset'
    };

    //
    // argument-free constructor is required to be "runnable"...
    //
    public NSP_AccountTerminationBatch() {
        this.objectAPI = NSP_AccountTerminationBatch.OBJ_AST;
    }

    //
    // ISelfSchedulable
    //
    public static String schedule() {
        String suffix = '';
        if ( Test.isRunningTest() ) {
            suffix = ' ~ TEST';
        }
        return System.schedule(
            'NSP_AccountTerminationBatch ~ Auto set the value on account based on associated assets or opportunities ~ Scheduled to Run monthly on the first day of every month at 11 pm' + suffix ,
            '0 0 23 1 * ? *' , // first day of every month at 11 PM
            new NSP_AccountTerminationBatch()
        );
    }

    //
    // Schedulable
    //
    public void execute( SchedulableContext sc ) {
        this.call( 'run' , null );
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
        Id response = null;
        if ( NSP_AccountTerminationBatch.isEnabled ) {
            response = Database.executeBatch(
                new NSP_AccountTerminationBatch() ,
                NSP_AccountTerminationBatch.batchSize
            );
        }
        return response;
    }

    //
    // Batchable
    //

    private String objectAPI = null;

    //constructor with objectAPI
    public NSP_AccountTerminationBatch ( String objectAPI ) {
        this.objectAPI = objectAPI;
    }

    //fetch recently closed records where the Parent Account is still Open
    public Database.QueryLocator start( Database.BatchableContext bc ) {
        Database.queryLocator queryLocator = null;
        if ( this.objectAPI == NSP_AccountTerminationBatch.OBJ_OPP ) {
            //fetch closed Opportunities
            queryLocator = Database.getQueryLocator(
                [
                    SELECT Id , AccountId
                    FROM Opportunity
                    WHERE (
                        ( LastStageChangeDate != null )
                        AND ( LastStageChangeDate = LAST_N_MONTHS:1 )
                        AND ( IsClosed = true )
                        AND ( Account.NSP_Sales_Service_Account_Status__c != :NSP_ServiceConstants.TERMINATED_STATUS )
                    )
                ]
            );
        } else if ( this.objectAPI == NSP_AccountTerminationBatch.OBJ_AST ) {
            //fetch non-CPQ and non-hardware, closed assets
            queryLocator =  Database.getQueryLocator(
                [
                    SELECT Id , AccountId
                    FROM Asset
                    WHERE (
                        ( Termination_Date__c != null )
                        AND ( Termination_Date__c = LAST_N_MONTHS:1 )
                        AND ( Status IN ( 'Terminated' , 'Backout' ) )
                        AND ( RecordType.DeveloperName NOT IN :NSP_AccountTerminationBatch.CPQ_HARDWARE )
                        AND ( Account.NSP_Sales_Service_Account_Status__c != :NSP_ServiceConstants.TERMINATED_STATUS )
                    )
                ]
            );
        }
        return queryLocator;
    }

    //Execute Method of Batch Class.
    public void execute( Database.BatchableContext bc , List<sObject> scope ) {
        if ( NSP_AccountTerminationBatch.isEnabled
            && ( scope != null )
            && !scope.isEmpty()
            )
        {
            try {
                List<Account> accountsToUpdate = this.processAccounts(
                    NSP_AccountTerminationBatch.getAccountSet( scope )
                );
                if ( ( accountsToUpdate != null ) && !accountsToUpdate.isEmpty() ) {
                    Database.SaveResult[] accountSaveResults = Database.update( accountsToUpdate , true );
                    NSP_ErrorLogHandler.logResults(
                        'NSP_AccountTerminationBatch' ,
                        'execute:update:' + objectAPI ,
                        accountSaveResults
                    );
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    NSP_AccountTerminationBatch.class.getName() ,
                    'execute:' + objectAPI ,
                    e
                );
            }
        }
    }

    public void finish( Database.BatchableContext bc ) {
        //call this batch again but use recently closed Opportunity records as a Trigger point for batch
        if ( NSP_AccountTerminationBatch.isEnabled
            && ( this.objectAPI == NSP_AccountTerminationBatch.OBJ_AST )
            )
        {
            //chained batch job
            Database.executeBatch(
                new NSP_AccountTerminationBatch( NSP_AccountTerminationBatch.OBJ_OPP ) ,
                NSP_AccountTerminationBatch.batchSize
            );
        }
    }

    //
    //
    //

    //method to get AccountId Set from sObejcts
    private static Set<Id> getAccountSet( List<sObject> scope ) {
        String accField = 'AccountId';
        Set<Id> accSet = new Set<Id>();
        if ( ( scope != null ) && !scope.isEmpty() ) {
            for ( sObject rec : scope ) {
                if ( rec.get( accField ) != null ) {
                    accSet.add( (String)rec.get( accField ) );
                }
            }
        }
        return accSet;
    }

    //method to fetch all related Opportunities and Assets from Accounts(CPQ and Hardware excluded)
    private List<Account> processAccounts( Set<Id> accountIdSet ) {
        List<Account> accountsToUpdate = new List<Account>();
        if ( ( accountIdSet != null ) && !accountIdSet.isEmpty() ) {
            List<Account> listofAccts=[
                SELECT
                    Id ,
                    NSP_Sales_Service_Account_Status__c ,
                    (
                        SELECT
                            Id ,
                            Status ,
                            Termination_Date__c ,
                            RecordType.Name ,
                            RecordTypeId
                        FROM Assets
                        WHERE ( RecordType.DeveloperName NOT IN :NSP_AccountTerminationBatch.CPQ_HARDWARE )
                    ) ,
                    (
                        SELECT
                            Id ,
                            StageName ,
                            IsClosed
                        FROM Opportunities
                    )
                FROM Account
                WHERE ( Id IN :accountIdSet )
            ];
            for ( Account acc : listofAccts ) {
                List<Asset> filteredAssets = NSP_AssetServiceTriggerHelper.filterOnAssetRecordTypes( acc.Assets );
                Boolean allAssetsTerminated = this.scanAssets( filteredAssets );
                Boolean allOpportunitiesClosed = scanOpportunities( acc.Opportunities );
                if ( this.prospectingCheck( filteredAssets , acc.Opportunities ) ) {
                    acc.NSP_Sales_Service_Account_Status__c = NSP_SalesConstants.PROSPECTING;
                    accountsToUpdate.add( acc );
                } else if ( allAssetsTerminated && allOpportunitiesClosed ) {
                    //terminate Account if no open Asset/Opportunity found
                    acc.NSP_Sales_Service_Account_Status__c = NSP_ServiceConstants.TERMINATED;
                    accountsToUpdate.add( acc );
                } else if ( ( this.objectAPI == NSP_AccountTerminationBatch.OBJ_OPP )
                    && this.lostAccountCheck( filteredAssets , acc.Opportunities )
                    )
                {
                    acc.NSP_Sales_Service_Account_Status__c = 'Lost';
                    accountsToUpdate.add( acc );
                }
            }
        }
        return accountsToUpdate;
    }

    //method to scan for any open Assets on Account
    private Boolean scanAssets( List<Asset> assets ) {
        Boolean allAssetsTerminated = true;
        if ( ( assets != null ) && !assets.isEmpty() ) {
            for ( Asset asobj : assets ) {
                //check for any open Assets
                if ( ( asobj.Termination_Date__c == null )
                    || ( ( asobj.Status != NSP_ServiceConstants.BACKOUT ) && ( asobj.Status != NSP_ServiceConstants.TERMINATED ) )
                    )
                {
                    allAssetsTerminated = false;
                    break;
                }
            }
        }
        return allAssetsTerminated;
    }

    //method to scan for any open opportunities on Account
    private static Boolean scanOpportunities( List<Opportunity> opps ) {
        Boolean allOpportunitiesClosed = true;
        if ( ( opps != null ) && !opps.isEmpty() ) {
            for ( Opportunity opp : opps ) {
                //check for any open Opportunities
                if ( ( opp.StageName != NSP_ServiceConstants.CLOSED_WON )
                    && ( opp.StageName != NSP_ServiceConstants.CLOSED_LOST )
                    )
                {
                    allOpportunitiesClosed = false;
                    break;
                }
            }
        }
        return allOpportunitiesClosed;
    }

    private Boolean prospectingCheck( List<Asset> assetList , List<Opportunity> oppList ){
        //should have open opp
        Boolean hasOpenOpp = false;
        if ( !oppList?.isEmpty() ) {
            for ( Opportunity opp : oppList ) {
                if ( opp.IsClosed == false ) {
                    hasOpenOpp = true;
                    break;
                }
            }
        }
        //Asset should not be Open
        Boolean hasOpenAsset = false;
        if ( !assetList?.isEmpty() ) {
            for ( Asset ast : assetList ) {
                if ( ( ast.Status == NSP_SalesConstants.ONBOARDING )
                    || ( ast.Status == NSP_ServiceConstants.AssetStatusOnDemand )
                    || ( ast.Status == NSP_SalesConstants.ACTIVE )
                    )
                {
                    hasOpenAsset = true;
                    break;
                }
            }
        }
        return ( hasOpenOpp && !hasOpenAsset );
    }

    @TestVisible
    //method to check if account should be marked lost
    private Boolean lostAccountCheck( List<Asset> assetList , List<Opportunity> oppList ) {
        //No Asset should be present
        Boolean noAssetPresent = true;
        if ( ( assetList != null ) && !assetList.isEmpty() ) {
            noAssetPresent = false;
        }
        //All opportunities should be closed lost
        Boolean allOppClosedLost = true;
        if ( ( oppList != null ) && !oppList.isEmpty() ) {
            for ( Opportunity opp : oppList ) {
                if ( ( opp.StageName != NSP_ServiceConstants.CLOSED_LOST )
                    || ( opp.Stagename != 'Closed Lost - Outgoing' )
                    )
                {
                    allOppClosedLost = false;
                }
            }
        }
        return ( noAssetPresent && allOppClosedLost );
    }

    //
    //
    //

    private static AccountTerminationBatchSettings__c settings {
        private get {
            if ( settings == null ) {
                settings = AccountTerminationBatchSettings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }

    private static Boolean isEnabled {
        private  get {
            if ( isEnabled == null ) {
                Boolean local = false;
                if ( NSP_AccountTerminationBatch.settings != null ) {
                    local = NSP_AccountTerminationBatch.settings.IsEnabled__c;
                }
                isEnabled = local;
            }
            return isEnabled;
        }
        private set;
    }

    private static Integer batchSize {
        private get {
            if ( batchSize == null ) {
                Integer local = 200;
                if ( ( NSP_AccountTerminationBatch.settings != null )
                    && ( NSP_AccountTerminationBatch.settings.BatchSize__c != null )
                   )
                {
                    local = NSP_AccountTerminationBatch.settings.BatchSize__c.intValue();
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

}
//
