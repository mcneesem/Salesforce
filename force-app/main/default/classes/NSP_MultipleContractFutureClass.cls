/**
* @description  : Class for Multiple Contracts NSP_MultipleContractFutureClass
* @date 06/04/2021
* Name : NSP_MultipleContractFutureClass
* Author : Rakesh
*
*/
public class NSP_MultipleContractFutureClass {

	private NSP_MultipleContractFutureClass () {
        
    }
	
/**
* @Method  : createContractAndReparentSubscriptions
* @date 06/04/2021
* Name : NSP_MultipleContractFutureClass
*
*/
    //Declaration of Invocable Method. This function is triggered from flow.
  	@InvocableMethod(label='Multiple Contracts' description='Creates cloned contracts for different product types and reparents subscriptions')
    public static void createContractAndReparentSubscriptions(List<String> contractIds) { 

        if(contractIds!=null) {
            //querying contracts for required fields
            Map<Id, Contract> allContracts = new Map<Id,Contract>([SELECT Id, AccountId, BillingAddress, CurrencyIsoCode,EndDate,OwnerId,StartDate,ContractTerm,Pricebook2Id,ShippingAddress,SpecialTerms,Status,NSP_PrimaryProduct__c,
                                                                    SBQQ__AmendmentRenewalBehavior__c,SBQQ__AmendmentOpportunityRecordTypeId__c,SBQQ__AmendmentOpportunityStage__c,SBQQ__AmendmentOwner__c,SBQQ__AmendmentPricebookId__c,SBQQ__AmendmentStartDate__c,
                                                                    SBQQ__SubscriptionQuantitiesCombined__c,NSP_Customer_Signature_Required__c,SBQQ__DefaultRenewalContactRoles__c,SBQQ__DefaultRenewalPartners__c,SBQQ__DisableAmendmentCoTerm__c,SBQQ__Evergreen__c,SBQQ__ExpirationDate__c,SBQQ__MasterContract__c,SBQQ__MDQRenewalBehavior__c,NSP_Number_of_Employees__c,
                                                                    SBQQ__Opportunity__c,SBQQ__OpportunityPricebookId__c,SBQQ__Order__c,SBQQ__PreserveBundleStructureUponRenewals__c,NSP_Pricing_Model__c,NSP_Product_Type__c,SBQQ__Quote__c,SBQQ__RenewalForecast__c,
                                                                    SBQQ__RenewalOpportunityRecordTypeId__c,SBQQ__RenewalOpportunityStage__c,SBQQ__RenewalOwner__c,SBQQ__RenewalPricebookId__c,SBQQ__RenewalQuoted__c,SBQQ__RenewalTerm__c,SBQQ__RenewalUpliftRate__c,NSP_TransactionType__c
                                                                FROM Contract WHERE Id IN:contractIds ]);
            //declaring maps and lists
            Map<Id,List<SBQQ__Subscription__c>> subscriptionsByContractIdMap = new Map<Id,List<SBQQ__Subscription__c>>();
            Map<Id,Set<String>> subsPTypeByOrderIdMap = new Map<Id,Set<String>>();
            Map<Id,Set<String>> OrderIdsByContractMap = new Map<Id,Set<String>>();
            List <Contract> newClonedContracts = new List<Contract>();
            List <Contract> contractsToUpdate = new List<Contract>();
            List <SBQQ__Subscription__c> substoUpdate = new  List <SBQQ__Subscription__c>();
            
            // looping through subscriptions
            // preparing maps for use - subscriptionsByContractIdMap
            //  
            for(SBQQ__Subscription__c subs: [Select Id, SBQQ__RequiredById__c, SBQQ__Product__c, SBQQ__Product__r.NSP_Product_Category__c, SBQQ__Contract__c, SBQQ__Product__r.NSP_Product_Type__c, SBQQ__OrderProduct__c, SBQQ__OrderProduct__r.OrderId
                                            FROM SBQQ__Subscription__c WHERE SBQQ__Contract__c IN: contractIds]) {
               
                if(subscriptionsByContractIdMap.containskey(subs.SBQQ__Contract__c)) {
                    List<SBQQ__Subscription__c> conSubsList = subscriptionsByContractIdMap.get(subs.SBQQ__Contract__c);
                    conSubsList.add(subs);
                    subscriptionsByContractIdMap.put(subs.SBQQ__Contract__c,conSubsList);
                }
                else{
                    subscriptionsByContractIdMap.put(subs.SBQQ__Contract__c,new List<SBQQ__Subscription__c>{subs});
                }
                
                if(subs.SBQQ__OrderProduct__r.OrderId!=null){
                    //populating OrderIdsByContractMap to store OrderIds By Contract as Key
                    if(OrderIdsByContractMap.containskey(subs.SBQQ__Contract__c)) {
                        Set<String> conOrdersList = OrderIdsByContractMap.get(subs.SBQQ__Contract__c);     
                        conOrdersList.add(subs.SBQQ__OrderProduct__r.OrderId);
                        OrderIdsByContractMap.put(subs.SBQQ__Contract__c,conOrdersList);
                    }
                    else{
                        OrderIdsByContractMap.put(subs.SBQQ__Contract__c,new Set<String>{subs.SBQQ__OrderProduct__r.OrderId});
                    }
                    //populating subsPTypeByOrderIdMap to store PeoductType vales By Order as Key
                    if(subsPTypeByOrderIdMap.containskey(subs.SBQQ__OrderProduct__r.OrderId)) {
                        Set<String> conSubsPTypeList = subsPTypeByOrderIdMap.get(subs.SBQQ__OrderProduct__r.OrderId);     
                        conSubsPTypeList.add(subs.SBQQ__Product__r.NSP_Product_Category__c);
                        subsPTypeByOrderIdMap.put(subs.SBQQ__OrderProduct__r.OrderId,conSubsPTypeList);
                    }
                    else{
                        subsPTypeByOrderIdMap.put(subs.SBQQ__OrderProduct__r.OrderId,new Set<String>{subs.SBQQ__Product__r.NSP_Product_Category__c});
                    }
                }                           
            }

            //looping through contracts to check where multiple contracts are needed
            // populates cloned contract list and original contract update list
            for(Contract con : allContracts.values()) {

                if(subscriptionsByContractIdMap.containsKey(con.Id) && OrderIdsByContractMap.containsKey(con.Id)){
                    Set<String> conOrdersSet = OrderIdsByContractMap.get(con.Id);
                    List<String> conOrders = new List<String>(conOrdersSet);
                    
                    if(conOrders.size() > 1) {
                        //getting original contract in context
                        Contract origContract = allContracts.get(con.Id);
                        
                        for(Integer co=1;co<conOrders.size();co++){
                            // logic to check the number of unique orders asslciated with a contract
                            // add additional contracts to new list for INSERT
                            Contract clonedContract = origContract.clone(false, false, false, false);
                            if(subsPTypeByOrderIdMap.containsKey(conOrders[co])) {
                            Set<String> orderSubsPType = subsPTypeByOrderIdMap.get(conOrders[co]);
                            List<String> orderProductTypeList = new List<String>(orderSubsPType);
                            clonedContract.NSP_Product_Type__c = String.join(orderProductTypeList,';');
                            }
                            //setting values for cloned contracts
                            clonedContract.NSP_Created_From_Contract_Id__c = (String)con.Id;
                            clonedContract.SBQQ__Order__c = conOrders[co];
                            clonedContract.Status = 'Draft';
                            newClonedContracts.add(clonedContract);
                            
                        }
                        
                    }
                    //updating the product type on original contract
                    if(con.NSP_Product_Type__c != null) {
                        Set<String> origConProductTypeSet = new Set<String>(con.NSP_Product_Type__c.split(';'));
                        if(origConProductTypeSet.size() > 1 ) {
                    if(subsPTypeByOrderIdMap.containsKey(con.SBQQ__Order__c)) {
                        Set<String> orderSubsPType = subsPTypeByOrderIdMap.get(con.SBQQ__Order__c);
                        List<String> orderProductTypeList = new List<String>(orderSubsPType);
                        con.NSP_Product_Type__c = String.join(orderProductTypeList,';');
                        contractsToUpdate.add(con);
                    }
                    }
                    }
                }
            }

            // do cloned contract insert here   
            if(newClonedContracts.size()>0) {
                try {
                insert newClonedContracts;
                }
                catch(Exception ex){
                    NSP_CustomException.LogException(ex);
                } 
                //looping through new cloned contracts to associate subscription records categorized by orderid
                for(Contract ct : newClonedContracts) {
                    List <SBQQ__Subscription__c> currentContractSubscriptions = subscriptionsByContractIdMap.get(ct.NSP_Created_From_Contract_Id__c);
                    for(SBQQ__Subscription__c sub : currentContractSubscriptions ) {
                        //checking for same order number in subscriptions
                            if(sub.SBQQ__OrderProduct__r.OrderId==ct.SBQQ__Order__c){
                                sub.SBQQ__Contract__c = ct.id;
                                substoUpdate.add(sub);
                            }
                    }
                }
            
            }

            try {
            // do original contract update here
            if(contractsToUpdate.size()>0) {   
            update contractsToUpdate;
            }     
            // do subscription update here 
                if(substoUpdate.size()>0) {
                    //perform update
                    update substoUpdate;
                }
            }
            catch(Exception ex){
                NSP_CustomException.LogException(ex);
            } 

        }

    }
        
}