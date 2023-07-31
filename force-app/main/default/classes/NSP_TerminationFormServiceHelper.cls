/**
 * className: NSP_TerminationFormServiceHelper
* Represents the Termination Form Service helper which handles the logic for Termination Form Object
*
*/
public class NSP_TerminationFormServiceHelper {

    public static final Id WO_ASSET = NSP_GenericRecordType.getRecordTypeId('Asset',NSP_ServiceConstants.WO_ASSET_RECORDTYPE );
    public static final Id CLIENT_REINSTATE = NSP_GenericRecordType.getRecordTypeId('NSP_Termination_Form__c',NSP_ServiceConstants.CLIENT_REINSTATE );


    /***********************************************************************************************
    * MethodName: updateAssetTerminationForm
    * Description :  This method will update asset termination form section
    * Params:   List<NSP_Termination_Form__c> terminationFormList  
    * Added as part of STY-03259  
    * Author: Bindushree R
    * ********************************************************************************************/
    
    public void updateAssetTerminationForm(Map<Id, NSP_Termination_Form__c> newMapTermination,Map<Id, NSP_Termination_Form__c> oldMapTermination ){
        
        
        Set<String> clientNumbers = new Set<String>();
        List<Asset> updateAssetList = new List<Asset>();
        
        try{
                for(NSP_Termination_Form__c terminationForm : newMapTermination.values()){
                    //get client reinstate termination form successful records
                    if (terminationForm.recordTypeId==CLIENT_REINSTATE && 
                        terminationForm.NSP_Status__c==NSP_ServiceConstants.TERM_TEAM_APPROVED && oldMapTermination.get(terminationForm.Id).NSP_Status__c!=NSP_ServiceConstants.TERM_TEAM_APPROVED
                        && terminationForm.NSP_Client__c!=null) {
                            
                            clientNumbers.add(terminationForm.NSP_Client__c);
                    }
                }
                
                //get asset records whose aims client match with client reinstate form aims number
                for(Asset asset: [SELECT Id,NSP_Client__c, NSP_Verbal_Term_recd__c,NSP_Verbal_Term_Date__c,NSP_Verbal_Term_Updatedby__c,
                                NSP_Written_Term_recd__c,NSP_Written_Term_Date__c,NSP_Written_Termination_Updated_By__c,
                                NSP_Anticipated_Date_Of_Termination__c,NSP_Reason_for_Term__c,NSP_Pending_Termination__c from Asset WHERE RecordTypeId=:WO_ASSET AND NSP_Client__c!=null 
                                AND NSP_Client__c IN:clientNumbers]){
                                    
                                //clear asset termination form section values
                                if(asset.NSP_Verbal_Term_recd__c==true){
                                    asset.NSP_Verbal_Term_recd__c =false;
                                    asset.NSP_Verbal_Term_Date__c=null;
                                    asset.NSP_Verbal_Term_Updatedby__c=Label.NSP_Deployment_Manager;
                                    asset.NSP_Anticipated_Date_Of_Termination__c=null;
                                    asset.NSP_Reason_for_Term__c=null;
                                    asset.NSP_Pending_Termination__c=false;
                                }
                                if(asset.NSP_Written_Term_recd__c==true){
                                    asset.NSP_Written_Term_recd__c =false;
                                    asset.NSP_Written_Term_Date__c=null;
                                    asset.NSP_Written_Termination_Updated_By__c=Label.NSP_Deployment_Manager;
                                    asset.NSP_Anticipated_Date_Of_Termination__c=null;
                                    asset.NSP_Reason_for_Term__c=null;
                                    asset.NSP_Pending_Termination__c=false;
                                }
                                
                                
                                updateAssetList.add(asset);
                                    
                }
                
                if(!updateAssetList.isEmpty()){
                    database.update(updateAssetList);
                }
        } catch (Exception ex) {
                NSP_ErrorLogHandler.logSaveException('NSP_TerminationFormServiceHelper', 'updateAssetTerminationForm', ex.getMessage());
        }
        
        
        
    }


}