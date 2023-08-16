    /**
    Apex Class Name      :  NSP_TerminateHardwateAssetBatch
    Version              :  1.0                                                                          
    Created Date         :  01/25/2023                                                                      
    Description    :        This batch class gets all the subscriptions that are not renewed and terminates it's corresponding Hardware assets                                                                      
    *--------------------------------------------------------------------------------------------------  
    *  Developer                   Date                   Description                                    
    * -------------------------------------------------------------------------------------------------  
    */
    Public class NSP_TerminateHardwateAssetBatch implements Database.Batchable<sObject>,Schedulable {
        Public Database.QueryLocator start(Database.BatchableContext bc) {
            return Database.getqueryLocator([SELECT Id,NSP_Covered_Asset__c,NSP_Supported_Subscription__c  FROM NSP_Support_Entitlement__c WHERE NSP_Supported_Subscription__c IN (SELECT Id FROM SBQQ__Subscription__c WHERE SBQQ__EndDate__c !=null AND SBQQ__EndDate__c < TODAY AND SBQQ__RenewedDate__c=null)]);
        }
        Public void execute(Database.BatchableContext bc, List<NSP_Support_Entitlement__c> existingSupports){
            List<Id> hadrwareIds= new List<Id>();
            for(NSP_Support_Entitlement__c support:existingSupports){
                hadrwareIds.add(support.NSP_Covered_Asset__c);
            }
            if(hadrwareIds.size()>0){
                List<Asset> assetsToTerminate=[SELECT Id,Status FROM Asset WHERE Id IN :hadrwareIds];
                for(Asset eachAsset:assetsToTerminate){
                    eachAsset.Status=NSP_CPQConstants.TERMINATED;
                }
                if(assetsToTerminate.size()>0){
                    List<Database.SaveResult> results = Database.update(assetsToTerminate,false);
                    NSP_ErrorLogHandler.logSaveResultsException('NSP_TerminateHardwateAssetBatch','execute', results); 
                }
            }
        }
        Public void finish(Database.BatchableContext bc){
            
        } 
            //schedule a batch
        public void execute(SchedulableContext ctx) {
            NSP_TerminateHardwateAssetBatch batchObject = new NSP_TerminateHardwateAssetBatch();
            Database.executeBatch(batchObject); 
        }
        
    }