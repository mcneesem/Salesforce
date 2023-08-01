/**************************************************************************************************   
Version              :  1.0                                                                          
Created Date         :  July 19, 2022                                                             
Function             :   This class describes about fetch related files from FSO/MM form
Test class           :  NSP_FileUploadMultiControllerTest
Story                :  STY-01450                                                                            
Modification Log     :                                                                               
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                     
* -------------------------------------------------------------------------------------------------  
***************************************************************************************************/
public class NSP_FileUploadMultiController {
    
    /**
* @MethodName: releatedFiles
* @Description: To disp;ay files of Imp Profile record from FSO/MM form
* @param String ipRecordId.
* @Defect : STY-01450
* @return void                          
*/
@AuraEnabled
public static list<contentversion> releatedFiles(String ipRecordId){
Set<id> conDocList = new Set<id>();
try {       
    if(String.isNotBlank(ipRecordId)){
        for(ContentDocumentLink conDocLiknk : [SELECT Id, 
                                           ContentDocumentId 
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId =: ipRecordId]) {
            conDocList.add(conDocLiknk.ContentDocumentId);
        }
    }
    if(!conDocList.isEmpty()) {
        return [SELECT Id, Title, 
                ContentDocumentId ,
                PathOnClient,
                CreatedDate,
                FileExtension 
                FROM ContentVersion 
                WHERE ContentDocumentId IN: conDocList 
                WITH SECURITY_ENFORCED 
                LIMIT 100 ];
    }
    else {
        return new List<contentversion>();
    }
} catch (Exception excep) {
    throw new AuraHandledException(excep.getMessage());
}
}

}