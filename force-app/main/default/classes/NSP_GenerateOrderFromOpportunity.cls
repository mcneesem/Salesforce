/**
 * @description  : Class to generate order from Opportunity
 * @author Utpal Utkalit
 * @date 07/27/2021
 * Name : NSP_GenerateOrderFromOpportunity
 * Test Class:
 * STY-00427 Order Creation
 */

public class NSP_GenerateOrderFromOpportunity {
  private static final String CLOSED_LOST_STAGE = 'Closed Lost';
  private static final String CLOSED_WON_STAGE = 'Closed Won';
  private static final String SUBMITTED_TO_ORDER = 'Submitted To Order';
  private static final String ORDER_CREATION = 'NSP_OrderCreation';
  /**
   * Method for Checking if Opportunit is moving to closed won
   * Called from Trigger After Update context
   * Moves the Quote to Submitted to order state and enables ordered flag
   * @param  Trigger.New and Trigger.oldMap 
   */
  public static void updateQuotetoOrderWhenOppWON(List < Opportunity > newOpportunities, Map < Id, Opportunity > oldOpportunitiesWithId) {

    List < Opportunity > opportunities = new List < Opportunity > ();
    Set < Id > opportunityIds = new Set < id > ();
    boolean createOrder = true;
    Map<String,NSP_AutomationSetting__mdt> autoMationSettingMap = NSP_AutomationSetting__mdt.getAll();
    if (null != newOpportunities && null != oldOpportunitiesWithId)  {
        // logic to bypass order creation
        if(autoMationSettingMap.containsKey(ORDER_CREATION) && autoMationSettingMap.get(ORDER_CREATION).NSP_Disable__c){
            createOrder = false;
        }
        
        if(createOrder){
            for (Opportunity opp: newOpportunities) {
                if (CLOSED_WON_STAGE.equalsIgnoreCase(opp.StageName) &&
                  opp.StageName != oldOpportunitiesWithId.get(opp.id).StageName // && rtByName.getRecordTypeId() == opp.RecordTypeId
                ) {
                  opportunities.add(opp);
                  opportunityIds.add(opp.Id);
                }
            }
        }
    }

    //Fetch all associated quote that needs update
    List < SBQQ__Quote__c > quoteListtoBeOrdered = new List < SBQQ__Quote__c > ();
    List < SBQQ__Quote__c > quoteList = [Select SBQQ__Ordered__c, SBQQ__Status__c, SBQQ__Primary__c from SBQQ__Quote__c WHERE
                                         SBQQ__Opportunity2__c in: opportunityIds AND SBQQ__Status__c !=: SUBMITTED_TO_ORDER AND SBQQ__Primary__c = true
                                         AND SBQQ__Ordered__c != true ];
    for (SBQQ__Quote__c quote: quoteList)  {
      quote.SBQQ__Ordered__c = true;
      quote.SBQQ__Status__c = SUBMITTED_TO_ORDER;
      quoteListtoBeOrdered.add(quote);
    }
    Savepoint orderSP = Database.setSavepoint(); //in case of exception the order cretaion should roll back
    try {
      Database.update(quoteListtoBeOrdered);
    } catch (Exception ex){
      Database.rollback(orderSP);
      NSP_CustomException.LogException(ex);
    }
  }

}