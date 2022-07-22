/**
* Represents the Order trigger helper which handles all the logic.
*/
public class NSP_OrderTriggerHelper {
	
	 /**
	* Iterates throught the list of new Order and passes the required attributes to other methods.
	* @param newList List of New Order.  
	* @return void              
	*                
	*/
	public void beforeInsertDirector(List<Order> newList){  
        copyQuoteDateOnOrder(newList);
	}
	
	/**
* Iterates throught the Order map and identifies the records that needs to worked based on various criterias.
* @param OrderNewMap Map of New Order. 
* @param OrderOldMap Map of Old Order. 
* @return void             
*                
*/
	public void beforeUpdateDirector(Map<Id, Order> OrderNewMap,Map<Id, Order> OrderOldMap){
        updateBillingShippingAddress(OrderNewMap.values(),OrderOldMap);
	}
	
	/**
* Iterates throught the list of new Orders and passes the required attributes to other methods.
* @param OrderNewMap Map of New Order. 
* @param OrderOldMap Map of Old Order.   
* @return void             
*                
*/
    
    public void afterUpdateDirector(Map<Id,Order> OrderNewMap,Map<Id, Order> OrderOldMap){        
        
        
    }  
	
	 /**
* Method added for STY-00397 to copy data from quote to Order
* @param newList List of New Order.  
* @return void   
*/
	public static void copyQuoteDateOnOrder(List<Order> newList){
		set<Id> quoteIdSet = new set<Id>();
		
		for(Order newOrder : newList){
			if(newOrder.SBQQ__Quote__c != null){
				quoteIdSet.add(newOrder.SBQQ__Quote__c);
			}
		}
		
		if(quoteIdSet.Size() > 0){
			Map<Id,SBQQ__Quote__c> quoteMap = new Map<Id,SBQQ__Quote__c>([SELECT 	id,
																					NSP_Invoice_To_Email__c,NSP_Billing_Account__c,
																					NSP_Billing_Address__c,NSP_Shipping_Address__c
																					from SBQQ__Quote__c WHERE Id In : quoteIdSet]);
			
			for(Order newOrder : newList){
				if(newOrder.SBQQ__Quote__c != null && quoteMap.ContainsKey(newOrder.SBQQ__Quote__c)){
					SBQQ__Quote__c objQuote = quoteMap.get(newOrder.SBQQ__Quote__c);
					newOrder.BillToContactId = objQuote.NSP_Invoice_To_Email__c;
					
				}
			}
		}
	}
	    /**
* Method Name : updateBillingShippingAddress 
* Description : Method to set custom address fields on Order
* Author : Sales Team       Date : 28/10/2021
* @param OrderNewMap Map of New Order. 
* @param OrderOldMap Map of Old Order.   
* @return void  
*/
	public static void updateBillingShippingAddress(List<Order> newList,Map<Id, Order> OrderOldMap){
		Set<Id> addressIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
		set<Id> processOrderIdSet = new set<Id>();
        Map<Id,NSP_Address__c> addressMap; 
        Map<Id,Account> accountMap;
        String addressParam = 'Address';
        String accountParam = 'Account';
		
		for(Order newOrder : newList){
			Order oldOrder = OrderOldMap != null ? OrderOldMap.get(newOrder.Id):null;
			
			if(newOrder.NSP_Billing_Address__c !=  oldOrder.NSP_Billing_Address__c
			|| newOrder.NSP_Shipping_Address__c !=  oldOrder.NSP_Shipping_Address__c
			|| newOrder.NSP_Billing_Account__c !=  oldOrder.NSP_Billing_Account__c){
				processOrderIdSet.add(newOrder.Id);
				if(newOrder.NSP_Billing_Address__c != null){
                    addressIdSet.add(newOrder.NSP_Billing_Address__c);
                }

                if(newOrder.NSP_Shipping_Address__c != null){
                    addressIdSet.add(newOrder.NSP_Shipping_Address__c);
                }

                if(newOrder.NSP_Billing_Account__c != null){
                    accountIdSet.add(newOrder.NSP_Billing_Account__c);
                }
                accountIdSet.add(newOrder.AccountId);
			}
		}
		
		if(addressIdSet.Size() > 0){
            addressMap  = new Map<Id,NSP_Address__c>([SELECT    Id,NSP_Street__c,NSP_Street_Address_2__c,Name,
                                                                NSP_City__c,NSP_State__c,NSP_Country__c,
                                                                NSP_Postal_Code__c FROM NSP_Address__c
                                                                WHERE Id IN : addressIdSet]);
        }

        if(accountIdSet.Size() > 0){
            accountMap = new Map<Id,Account>([SELECT Id,BillingStreet,BillingCity,BillingState,BillingCountry,BillingPostalCode,
                                                        ShippingStreet,ShippingCity,ShippingState,ShippingCountry,ShippingPostalCode
                                                        FROM Account WHERE Id IN: accountIdSet]);
        }
		
		for(Order newOrder : newList){
			if(processOrderIdSet.contains(newOrder.Id)){
				boolean hasBillingAddress = false;
                boolean hasShippingAddress = false;
                boolean hasBillinAccount = false;
				
				if( newOrder.NSP_Billing_Address__c != null && addressMap != null && addressMap.containsKey(newOrder.NSP_Billing_Address__c)){
                    hasBillingAddress = true;
                    NSP_Address__c billingaddress       = addressMap.get(newOrder.NSP_Billing_Address__c);
                    copyBillingAddress(newOrder,null,billingaddress,addressParam);
                }

                if( newOrder.NSP_Shipping_Address__c != null && addressMap != null && addressMap.containsKey(newOrder.NSP_Shipping_Address__c)){
                    hasShippingAddress = true;
                    NSP_Address__c shippingaddress       = addressMap.get(newOrder.NSP_Shipping_Address__c);
                    copyShippingAddress(newOrder,null,shippingaddress,addressParam);
                }

                if(newOrder.NSP_Billing_Account__c != null && accountMap != null && accountMap.containsKey(newOrder.NSP_Billing_Account__c)){
                    Account billingAccount = accountMap.get(newOrder.NSP_Billing_Account__c);
                    hasBillinAccount = true;
                    if(!hasBillingAddress){
                        copyBillingAddress(newOrder,billingAccount,null,accountParam);
                    }

                    if(!hasShippingAddress){
                        copyShippingAddress(newOrder,billingAccount,null,accountParam);
                    }
                }

                if(newOrder.AccountId != null && accountMap != null && accountMap.containsKey(newOrder.AccountId )){
                    Account objAccount = accountMap.get(newOrder.AccountId);
                    if(!hasBillingAddress && !hasBillinAccount){
                        copyBillingAddress(newOrder,objAccount,null,accountParam);
                    }

                    if(!hasShippingAddress && !hasBillinAccount){
                        copyShippingAddress(newOrder,objAccount,null,accountParam);
                    }
				}
			}
		}
	}
	
/**
* Method Name : copyBillingAddress 
* Description : Method to update billing address fields on Order
* Author : Sales Team       Date : 28/10/2021
* @param Order New Order data. 
* @param Account Account data.   
* @param NSP_Address__c Custom Address data.
* @param String Indicates the copy from which object
* @return void  
*/
	public static void copyBillingAddress(Order newOrder,Account objAccount,NSP_Address__c objAddress,string copyFrom){
        if(copyFrom =='Account' && objAccount != null){
            newOrder.BillingStreet     = objAccount.BillingStreet;
            newOrder.BillingState      = objAccount.BillingState;
            newOrder.BillingCity       = objAccount.BillingCity;
            newOrder.BillingPostalCode = objAccount.BillingPostalCode;
            newOrder.BillingCountry    = objAccount.BillingCountry;
            
        }
        else{
            newOrder.BillingStreet     = objAddress.NSP_Street__c;
            newOrder.BillingState      = objAddress.NSP_State__c;
            newOrder.BillingCity       = objAddress.NSP_City__c;
            newOrder.BillingPostalCode = objAddress.NSP_Postal_Code__c;
            newOrder.BillingCountry    = objAddress.NSP_Country__c;
                       
        }
    }
/**
* Method Name : copyShippingAddress 
* Description : Method to update Shipping address fields on Order
* Author : Sales Team       Date : 28/10/2021
* @param Order New Order data. 
* @param Account Account data.   
* @param NSP_Address__c Custom Address data.
* @param String Indicates the copy from which object
* @return void  
*/
    public static void copyShippingAddress(Order newOrder,Account objAccount,NSP_Address__c objAddress,string copyFrom){
        if(copyFrom =='Account' && objAccount != null){
            newOrder.ShippingStreet     = objAccount.ShippingStreet;
            newOrder.ShippingState      = objAccount.ShippingState;
            newOrder.ShippingCity       = objAccount.ShippingCity;
            newOrder.ShippingPostalCode = objAccount.ShippingPostalCode;
            newOrder.ShippingCountry    = objAccount.ShippingCountry;
            
        }
        else{
            newOrder.ShippingStreet     = objAddress.NSP_Street__c;
            newOrder.ShippingState      = objAddress.NSP_State__c;
            newOrder.ShippingCity       = objAddress.NSP_City__c;
            newOrder.ShippingPostalCode = objAddress.NSP_Postal_Code__c;
            newOrder.ShippingCountry    = objAddress.NSP_Country__c;
                        
        }    
    }

}