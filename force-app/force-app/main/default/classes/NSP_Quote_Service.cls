/**
* The class is used to construct Docusign CLM URL for generating the documents
* @Author Raksha
* Called from NSP_Docusign js
* @strory   STY-00336
*/
public class NSP_Quote_Service {
    public NSP_Quote_Service() {
    }
 
/**
* Method for constructing Docusign CLM URL
* @param  OpportunityId,templateId,name,accountName
*/ 
    @AuraEnabled(cacheable=true)
    public static string getDocuSignUrl(String recordId,String templateId,String name,String accountName){
    try {
        String queryParam;
        queryParam = 'https://uatna11.springcm.com/atlas/doclauncher/OneClickDocGen'+'?'+
        'aid='+'50202'+'&'+
        'config='+templateId+'&'+
        'eos[0].Id='+recordId+'&'+
        'eos[0].System='+'Salesforce'+'&'+
        'eos[0].Type='+'Opportunity'+'&'+
        'eos[0].Name='+name+'&'+
        'eos[0].ScmPath='+'/Salesforce/Account/'+accountName+'/Opportunity';
        return queryParam;
    }Catch(Exception Ex){
        throw new AuraHandledException(ex.getMessage());
    }
    }
/**
* Method for querying the contacts related to Billing account
* @param  BillingAccount Id,customerSigner Id
*/                                                                          
    @AuraEnabled(cacheable=true)    
    public static Boolean validateCustomerSigner(Id billingAccount,Id customerSigner)
   {
       Boolean isValid = false;
       try {
       Set<String> contactSet = new Set<String>(); 
       List<Contact> contactList=[SELECT Id, Name FROM Contact WHERE Id IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId = :billingAccount)];
        
          for(Contact contactObj :contactList){ 
              contactSet.add(contactObj.Id); 
          } 
          if(contactSet.contains(customerSigner)) {
              isValid = true;
          }
        }Catch(Exception Ex){
            throw new AuraHandledException(ex.getMessage());
            }
   return isValid;
    
}	
}