global with sharing class CLMTokenRequest {
    // test w/ NSP_DocuSignInvoiceDocumentBatchTest (100%)
    // test w/ SpringCMTests (40%)

    global string Access_Token { get; set; }
    global string Token_Type { get; set; }
    global string Expires_In { get; set; }
    global string ApiBase_Url { get; set; }
    global string Scope { get; set; }
}
//