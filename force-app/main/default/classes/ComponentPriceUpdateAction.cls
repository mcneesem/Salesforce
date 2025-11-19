public with sharing class ComponentPriceUpdateAction {
    // test w/ ComponentPriceUpdateBatchTest (87%)

    @InvocableMethod(label='Component Price Update Action')
    public static void componentBatchExecute( List<ComponentPriceInput> inputs ) {
        if ( ( inputs != null ) || !inputs.isEmpty() ) {
            ComponentPriceInput inParam = inputs[0];
            if ( inParam != null ) {
                ComponentPriceUpdateBatch.executeBatch(
                    inParam.pricingModel ,
                    inParam.seasonalPricing ,
                    inParam.productId ,
                    inParam.lstPricingTable
                );
            }
        }
    }

    public class ComponentPriceInput {
        @InvocableVariable(label='Pricing Model')
        public String pricingModel;
        @InvocableVariable(label='Seasonal Pricing')
        public String seasonalPricing;
        @InvocableVariable(label='Product Id')
        public String productId;
        @InvocableVariable(label='Pricing Records')
        public List<NSP_Pricing_Table__c> lstPricingTable;
    }

}
//