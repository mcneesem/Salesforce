/**
 * Represents the NSP_Sales_Office_Mapping__c trigger helper which handles the logic with all objects.

 * Date : 04/08/2022
 */
public class NSP_SalesOfficeMappingTriggerHelper {
    
    /**
* Iterates throught the list of new NSP_Sales_Office_Mapping__c  and passes the required attributes to other methods.
* @param newList List of New NSP_Sales_Office_Mapping__c .
*
* @return void
*                
*/
    
    public void beforeInsertDirector(List<NSP_Sales_Office_Mapping__c > newList) {
        validateSalesOfficeMappingDates(newList,null);
    }
    
    
    
    
    /**
     * Iterates throught the list of new NSP_Sales_Office_Mapping__c  and passes the required attributes to other methods.
     * @param newList List of New NSP_Sales_Office_Mapping__c .
     * @param newMap List of New NSP_Sales_Office_Mapping__c .
     * @return void
     *                
     */

    public void afterInsertDirector(List<NSP_Sales_Office_Mapping__c > newList, Map<Id, NSP_Sales_Office_Mapping__c > newMap) {
       
    }
    
       
    /**
     * Iterates throught the list of new NSP_Sales_Office_Mapping__c  and passes the required attributes to other methods.
     * @param newMap Map of NSP_Sales_Office_Mapping__c .
     * @param oldMap Map of NSP_Sales_Office_Mapping__c .
     * @return void
     *                
     */

    public void beforeUpdateDirector(Map<Id, NSP_Sales_Office_Mapping__c> newMap,Map<Id, NSP_Sales_Office_Mapping__c > oldMap) {
        validateSalesOfficeMappingDates(newMap.values(),oldMap);
    }
    
    public void validateSalesOfficeMappingDates(List<NSP_Sales_Office_Mapping__c > newList,Map<Id, NSP_Sales_Office_Mapping__c > oldMap)
    {
        set<String> officeSet = new set<String>();
        
        for(NSP_Sales_Office_Mapping__c newMapping : newList)
        {
            
            NSP_Sales_Office_Mapping__c oldMapping = oldMap != null ? oldMap.get(newMapping.Id):null;
            if( (Trigger.isInsert  || newMapping.NSP_Start_Date__c != oldMapping.NSP_Start_Date__c || newMapping.NSP_End_Date__c != oldMapping.NSP_End_Date__c)
            &&  newMapping.NSP_Start_Date__c != null && newMapping.NSP_End_Date__c != null && String.isNotBlank(newMapping.NSP_Sales_Office__c))
            {   
                officeSet.add(newMapping.NSP_Sales_Office__c);
            }
        }
        
        if(officeSet.size() > 0)
        {
            Map<String,List<NSP_Sales_Office_Mapping__c>> salesOfficeToListMap = new Map<String,List<NSP_Sales_Office_Mapping__c>>();
            for(NSP_Sales_Office_Mapping__c eachMapping :   [SELECT Id,NSP_Sales_Office__c,NSP_End_Date__c,NSP_Start_Date__c FROM NSP_Sales_Office_Mapping__c 
                                                            WHERE NSP_Sales_Office__c IN : officeSet   ])
            {
                if(salesOfficeToListMap.containsKey(eachMapping.NSP_Sales_Office__c))
                {
                    salesOfficeToListMap.get(eachMapping.NSP_Sales_Office__c).add(eachMapping);
                }
                else
                {
                    salesOfficeToListMap.put(eachMapping.NSP_Sales_Office__c,new List<NSP_Sales_Office_Mapping__c>{eachMapping});
                }
            }
            
            if(salesOfficeToListMap.Size() > 0)
            {
                for(NSP_Sales_Office_Mapping__c newMapping : newList)
                {
                    if(String.isNotBlank(newMapping.NSP_Sales_Office__c) && officeSet.contains(newMapping.NSP_Sales_Office__c) && salesOfficeToListMap.containsKey(newMapping.NSP_Sales_Office__c))
                    {
                        for(NSP_Sales_Office_Mapping__c eachMapping : salesOfficeToListMap.get(newMapping.NSP_Sales_Office__c))
                        {
                                if( (Trigger.isInsert || newMapping.Id != eachMapping.Id) && 
                                    ((newMapping.NSP_Start_Date__c >= eachMapping.NSP_Start_Date__c && newMapping.NSP_End_Date__c <= eachMapping.NSP_End_Date__c) 
                                ||  (newMapping.NSP_Start_Date__c >= eachMapping.NSP_Start_Date__c && newMapping.NSP_Start_Date__c <= eachMapping.NSP_End_Date__c)
                                ||  (newMapping.NSP_End_Date__c >= eachMapping.NSP_Start_Date__c && newMapping.NSP_End_Date__c <= eachMapping.NSP_End_Date__c)
                                ||  (newMapping.NSP_Start_Date__c <= eachMapping.NSP_Start_Date__c && newMapping.NSP_End_Date__c >= eachMapping.NSP_End_Date__c)    ))
                                {
                                    newMapping.addError(system.label.NSP_Sales_Office_Mapping_Overlap_Error+' '+eachMapping.Id);
                                }
                        }
                    }
                }
            }
        }
    }
    
}