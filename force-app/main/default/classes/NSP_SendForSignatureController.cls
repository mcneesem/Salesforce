/**
* The class is used as apex controller for vf page NSP_sendForSignature
* @Author Harsha
* @defect   DF-01025
*/
public class NSP_SendForSignatureController {

    public Account account { public get; private set; }

    public NSP_SendForSignatureController(ApexPages.StandardController controller) {
        this.account = (account)controller.getRecord();
    }
    

    /*
    updates nsp_partner lifecycle value to Onboarding on page load
    @param none
    @return void
    */
    public static void updatePartnerLifeCycleValue() {
        List<Account> accountRecord = [SELECT Id, NSP_Partner_Lifecycle__c FROM Account WHERE Id = :ApexPages.currentPage().getParameters().get('Id')];
        if(!accountRecord.isEmpty() && accountRecord[0].NSP_Partner_Lifecycle__c == NSP_SalesConstants.EVALUATION){
            accountRecord[0].NSP_Partner_Lifecycle__c = NSP_SalesConstants.ONBOARDING;
            update accountRecord[0];   
        } 
    }

}