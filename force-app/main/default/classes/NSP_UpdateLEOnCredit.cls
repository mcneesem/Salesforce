/**
* This class is used to stamp Legal Entity on Credit Note
* Class Type: Invocable
* Constructor : Public 
* Description: Stamp Legal Entity on Credit Note
*/
public class NSP_UpdateLEOnCredit {
    private NSP_UpdateLEOnCredit(){
        //private constructor
    }
    @InvocableMethod(label='Update Legal Entity' description='Update Legal Entity on Credit Note')
    public static void updateLegalEntity(List<String> records){
        List<blng__CreditNote__c> creditList = new List<blng__CreditNote__c>();
        Map<String,blng__CreditNoteLine__c> credToFirstLineMap = new Map<String,blng__CreditNoteLine__c>();
        for ( blng__CreditNoteLine__c credLine : [SELECT Id, blng__LegalEntity__c, blng__LegalEntity__r.NSP_Company_Name__c,blng__CreditNote__c
                                            FROM blng__CreditNoteLine__c WHERE blng__CreditNote__c IN : records ]) {
        
        if(!credToFirstLineMap.containsKey(credLine.blng__CreditNote__c)) {
            credToFirstLineMap.put(credLine.blng__CreditNote__c,credLine);
        }     
    }
        for (blng__CreditNoteLine__c cred : credToFirstLineMap.values() ){
            blng__CreditNote__c credNoteObj = new blng__CreditNote__c(Id=cred.blng__CreditNote__c);
                if(cred.blng__LegalEntity__c != null) {
                    credNoteObj.NSP_LegalEntity__c = cred.blng__LegalEntity__r.NSP_Company_Name__c;
                    creditList.add(credNoteObj);
                }
            
        }    
        try{
            if(creditList !=null && creditList.size()>0){
                database.update(creditList);
            }
        } catch(Exception ex){
            NSP_CustomException.LogException(ex);
        }
        
    }
}

