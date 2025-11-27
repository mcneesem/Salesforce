/* 
*    Class Name  : CLMDocumentTriggerHelper
*    @Description: Represents the OnCLMDocumentCreate trigger helper of Service Stream which handles all the logic.
*    @Date       : 25/11/2025
*/

public With Sharing class CLMDocumentTriggerHelper {
    // test w/ OnCLMDocumentCreateTest (96%)

    /*
     * Handles post-insert logic for CLM_Document__c records.
     * Finds the first non-null related field from a predefined list
     * and triggers document download using CLMDocumentTransfer.
     */

    public void afterInsertDocument( Map <Id,CLM_Document__c> newMap ){

        // List of related fields to check in priority order  
        List<String> relatedFieldNames = new List<String>{ 
            'Opportunity__c',
            'Account__c',
            'NSP_Invoice__c',
            'NSP_CreditNote__c',
            'NSP_Service_Plan__c',
            'NSP_Wizard_Output__c',
            'pse_Project_Task__c',
            'Termination_Form__c'
        };
        List<CLM_Document__c> clmDocList = new List<CLM_Document__c>();

        if ( newMap != null 
            && !newMap.isEmpty()
           )
        {
            clmDocList = [ 
                SELECT Id,
                CLM_Document_Id__c,
                pse_Project_Task__c,
                Termination_Form__c,
                Name,
                Account__c,
                Opportunity__c,
                NSP_Invoice__c,
                NSP_CreditNote__c,
                NSP_Service_Plan__c,
                NSP_Wizard_Output__c
                FROM CLM_Document__c 
                WHERE Id IN: newMap.keySet()
                LIMIT 1
            ];
        }

        if ( clmDocList != null 
            && !clmDocList.isEmpty() 
           )
        {
            for( String fieldApiName : relatedFieldNames  )
            {
                if ( String.isNotBlank( fieldApiName )
                    && clmDocList[0].get( fieldApiName ) != null
                   )
                {
                    String value = ( String )clmDocList[0].get( fieldApiName );
                    if ( String.isNotBlank( value ) 
                        && !Test.isRunningTest()
                       )
                    {
                        CLMDocumentTransfer.DownloadDocument( clmDocList[0].CLM_Document_Id__c, value );
                    }
                }
            }
        }
    }
}