// This class is used to set the Ship To Contact on the order when the "Sync Ship To Contact" on the order is clicked
public class ShipToContactHandler {

    @InvocableMethod(label='Create and Stamp Sales Tax Contact')
    public static void createAndStampSalesTaxContactFromButton(List<Id> orderIds) {
        if (orderIds != null && !orderIds.isEmpty()) {
            try {
                List<Order> ordersToProcess = [SELECT Id, Status, AccountId, blng__BillingAccount__c, ShipToContactId, 
                                                   ShippingStreet, ShippingCity, ShippingState, ShippingCountry,
                                                   ShippingCountryCode, ShippingStateCode, ShippingPostalCode 
                                              FROM Order 
                                              WHERE Id IN :orderIds];

                Set<Id> reviewedOrdersAccountSet = new Set<Id>();
                Map<String, Order> uniqueAddressKeyMap = new Map<String, Order>();
				List<Order> ordersToUpdate = new List<Order>();

                for (Order orderToProcess : ordersToProcess) {
					if((orderToProcess.Status == 'Reviewed' || orderToProcess.Status == 'Activated') && orderToProcess.ShipToContactId == null){
						String accIdstr;
						if (orderToProcess.blng__BillingAccount__c != null) {
							reviewedOrdersAccountSet.add(orderToProcess.blng__BillingAccount__c);
							accIdstr = orderToProcess.blng__BillingAccount__c;
						} else {
							reviewedOrdersAccountSet.add(orderToProcess.AccountId);
							accIdstr = orderToProcess.AccountId;
						}
                        ordersToUpdate.add(orderToProcess);
						String ordUniqAddressKey = accIdstr + '-' + orderToProcess.ShippingCity + '-' 
													+ orderToProcess.ShippingStateCode + '-' + orderToProcess.ShippingCountryCode 
													+ '-' + orderToProcess.ShippingPostalCode;
						uniqueAddressKeyMap.put(ordUniqAddressKey, orderToProcess);
                    }
                }
				
                if (reviewedOrdersAccountSet.size() > 0) {
                    NSP_OrderTriggerHelper.createAndStampSalesTaxContact(reviewedOrdersAccountSet, ordersToProcess, uniqueAddressKeyMap);
					
					if (!ordersToUpdate.isEmpty()) {
						update ordersToUpdate; // Update the orders
					}
                }

            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
            }
        }
    }
}