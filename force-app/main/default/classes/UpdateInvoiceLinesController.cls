public class UpdateInvoiceLinesController {
    // test w/ UpdateInvoiceLinesControllerTest (100%)

    @InvocableMethod(label='Process Invoice Lines')
    public static void processInvoiceLines( List<Id> invoiceRunIds ) {
        UpdateInvoiceLinesBatch.executeBatch( invoiceRunIds );
    }

}
//