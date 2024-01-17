/**
Apex Class Name      :  NSP_RegulatedAreaBatch
Version              :  1.0 
Author               :  Jatin                                                                          
Created Date         :  06/01/22 
Function             :  Creates AccountRegulatedArea and Cases when it matches with Regulated Area State/ZipCode.
Story                :  As part of STY-03789                                                                    
Modification Log     :                                                                              
*--------------------------------------------------------------------------------------------------  
* Developer                   Date                   Description                                    
* -------------------------------------------------------------------------------------------------  
* Anil                      8/19/2022               First Iteration
*/
public class NSP_RegulatedAreaBatch implements Database.Batchable<sObject>, Database.Stateful {
    // test w/ NSP_RegulatedAreaBatch_Test (95%)

    private  Set<String> setRegulatedStates = new Set<String>();
    private  Map<String, NSP_Regulated_Area__c> stateWithRegulatedArea = new Map<String, NSP_Regulated_Area__c>();
    private  Map<String, NSP_Regulated_Area__c> zipCodesWithRegArea = new Map<String, NSP_Regulated_Area__c>();
    private static final List<String> REGULATED_AREA_FIELDS = new List<String>{
        'Id',
        'Name',
        'NSP_Regulation_Type__c',
        'NSP_State__c',
        'NSP_Zip_Code__c',
        'NSP_City__c',
        'NSP_Start_Date__c',
        'NSP_End_Date__c'
    };
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String sickLeave = 'Sick Leave';
        String query = new NSP_QueryBuilder(
                'NSP_Regulated_Area__c',
                REGULATED_AREA_FIELDS
            ) 
            .addFilter('NSP_Regulation_Type__c', sickLeave)
            .setSecurityEnforce(false)
            .build();
        query += ' AND (NSP_Start_Date__c <= Today OR NSP_Start_Date__c = NULL) AND (NSP_End_Date__c = null OR NSP_End_Date__c > Today) ';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<NSP_Regulated_Area__c> regulatedAreaList) {
        try {

            for (NSP_Regulated_Area__c regulatedArea : regulatedAreaList) {
                if (regulatedArea.NSP_State__c != null) {
                    setRegulatedStates.add(regulatedArea.NSP_State__c);
                    stateWithRegulatedArea.put(
                        regulatedArea.NSP_State__c,
                        regulatedArea
                    );
                } else if (regulatedArea.NSP_City__c != null && regulatedArea.NSP_Zip_Code__c != null) {
                    List<String> listZipCodes = regulatedArea.NSP_Zip_Code__c?.deleteWhiteSpace()?.split(',');
                    for (String zipCode : listZipCodes) {
                        zipCodesWithRegArea.put(zipCode, regulatedArea);
                    }
                }
            }

       } catch (Exception ex) {
           NSP_ErrorLogHandler.logSaveException('NSP_AccountRegulatedArea_Scheduler', 'execute:getRegulatedAreas', ex.getMessage());
       }
   }


   public void finish(Database.BatchableContext bc) {

        Map<String, Object> data = new Map<String, Object>{
            'counter' => 0,
            'setRegulatedStates'=> setRegulatedStates,
            'stateWithRegulatedArea'=> stateWithRegulatedArea,
            'zipCodesWithRegArea'=> zipCodesWithRegArea
        };

        NSP_AccountRegulatedAreaBatch batchObject = new NSP_AccountRegulatedAreaBatch(data);
        Database.executeBatch(batchObject, 2000);
   }
}