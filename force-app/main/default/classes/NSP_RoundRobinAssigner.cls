/**
* Represents the class which is responsible for round robin lead assignment.
*/
public class NSP_RoundRobinAssigner {
    
    /**
* Dummy private constructor             
*                
*/  
  private NSP_RoundRobinAssigner() {  }
  /**
* Identifies the leads office and the realted office assignemtns as well as the DA details.
* @param leadsforRR List of leads eligible for round robin.  
* @param zipBasedLocationList List of location that leads are from
* @return void             
*                
*/
  public static void getOfficeAssignmentDetails(List<Lead> leadsforRR,List<String> zipBasedLocationList, Boolean isOwnerAssignment){
      //Map of location name and office records
      Map<String,NSP_Office__c> locationNameAndOfficeMap = new Map<String,NSP_Office__c>();
      //Map of office record ids and office records- used for finding the related records from the office 
      //assignment object
      Map<ID,NSP_Office__c> locationIdAndOfficeMap = new Map<ID,NSP_Office__c>();
      
      //Map to store location name and all the sales office DA's from the location
      Map<String,List<NSP_Office_Assignment__c>> locationNameAndDAMap  = new Map<String,List<NSP_Office_Assignment__c>>();
      
      Map<String,String> salesOfficeDAMap = new  Map<String,String>();
      //Iterate over office records to get offices related to the lead location
      for(NSP_Office__c officeObj : [SELECT id,NSP_Last_Index_Used__c,NSP_Number_Of_Offices__c,Name FROM 
                                     NSP_Office__c WHERE Name in :zipBasedLocationList]){
                                         // Populating the map                                
                                         locationNameAndOfficeMap.put(officeObj.Name,officeObj);
                                         locationIdAndOfficeMap.put(officeObj.id,officeObj);
                                     }        
      
      
      // Iterating over the office assignment records to get all offices and there DA related to the leads location
      // in a sequence that will be used for round robin assignment
      for(NSP_Office_Assignment__c officeAssignmntObj : [SELECT id,Name,NSP_District_Administrator__c,NSP_Location_Name__c,NSP_Sales_Office__c FROM NSP_Office_Assignment__c
                                                         WHERE NSP_Location_Name__c in :locationIdAndOfficeMap.keyset() AND NSP_District_Administrator__c != null AND NSP_isActive__c = TRUE ORDER BY NSP_Office_Number__c]){
                                                            salesOfficeDAMap.put(officeAssignmntObj.NSP_Sales_Office__c,officeAssignmntObj.NSP_District_Administrator__c);
                                                             //Checking wether the location already exist in the map or not                                             
                                                             if(locationNameAndDAMap.containsKey(officeAssignmntObj.NSP_Location_Name__c)){
                                                                 locationNameAndDAMap.get(officeAssignmntObj.NSP_Location_Name__c).add(officeAssignmntObj);                                                                   
                                                             }else{
                                                                 //List to hold DA's
                                                                 List<NSP_Office_Assignment__c> DAList = new List<NSP_Office_Assignment__c> ();
                                                                 //Adding the location and list of DA's from the offices of that location
                                                                 DAList.add(officeAssignmntObj);
                                                                 locationNameAndDAMap.put(officeAssignmntObj.NSP_Location_Name__c,DAList);                                                            
                                                             }
                                                         }          
      
      
      // Calling the round robin method
      // As part of DF-DF-01618 added if condition.
      if(!locationNameAndOfficeMap.isEmpty() && !locationNameAndDAMap.isEmpty()){
      doRoundRobin(locationNameAndOfficeMap,locationNameAndDAMap,leadsforRR, isOwnerAssignment, salesOfficeDAMap);
      }
  }
  
  /**
* Responsible for assigning the leads in round robin to all the offices that are present in a specific location
* @param locationNameAndOfficeMap Map of location name adn Office records
* @param locationNameAndDAMap Map of location name and list of DA's from each salesoffice of that location
* @param leadsforRR List of leads eligible for round robin. 
* @return void             
*                
*/
  public static void doRoundRobin(Map<String,NSP_Office__c> locationNameAndOfficeMap, Map<String,List<NSP_Office_Assignment__c>> locationNameAndDAMap,List<Lead> leadsforRR, Boolean isOwnerAssignment, Map<String,String> salesOfficeDAMAP){
      
          //Iterating over the lead that needs to be assigned in round robin manner
          for(Lead leadObj : leadsforRR){           
              
              //Checking the last index used so that we can start assignment from the next index
              if(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c)?.NSP_Last_Index_Used__c > locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c)?.NSP_Number_Of_Offices__c -1){
                  /*Reassinging the last index to zero as the the index value has gotten greater than the number of office
present in that location*/                
                  // assigning owner to the lead record     
                  if(locationNameAndDAMap.get(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).id) != null){
                    if(leadObj.NSP_Is_Sales_Office_Assigned__c == true && leadObj.NSP_Lead_Routing__c == true){
                        leadObj.ownerid = salesOfficeDAMAP.get(leadObj.NSP_Sales_Office__c);
                        leadObj.NSP_Is_Sales_Office_Assigned__c = false;
                    }else{
                          locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).NSP_Last_Index_Used__c =0;
                        leadObj.NSP_Sales_Office__c = locationNameAndDAMap.get(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).id)[Integer.valueOf(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).NSP_Last_Index_Used__c)].NSP_Sales_Office__c;
                        //Incerementing the index after every assignment so that the lead is assigned to the next DA in the list
                        
                        if(leadObj.NSP_Zip_Based_Location__c != NSP_SalesConstants.MIDMARKETREGION && isOwnerAssignment){
                            leadObj.ownerid = locationNameAndDAMap.get(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).id)[Integer.valueOf(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).NSP_Last_Index_Used__c)].NSP_District_Administrator__c; 
                            leadObj.NSP_Lead_Routing__c=FALSE; 
                        }
                        
                        locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).NSP_Last_Index_Used__c = locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).NSP_Last_Index_Used__c +1;
                    }
                }
                if(leadObj.NSP_Lead_Routing__c){
                    leadObj.NSP_Lead_Routing__c=FALSE;
                }
                  
                  
              }else{                       
                 
                  // assigning owner to the lead record     
                  if(locationNameAndDAMap.get(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).id) != null){
                    if(leadObj.NSP_Is_Sales_Office_Assigned__c == true && leadObj.NSP_Lead_Routing__c == true){
                        leadObj.ownerid = salesOfficeDAMAP.get(leadObj.NSP_Sales_Office__c);
                        leadObj.NSP_Is_Sales_Office_Assigned__c = false;
                    }else{
                        leadObj.NSP_Sales_Office__c = locationNameAndDAMap.get(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).id)[Integer.valueOf(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).NSP_Last_Index_Used__c)].NSP_Sales_Office__c;
                        if(leadObj.NSP_Zip_Based_Location__c != NSP_SalesConstants.MIDMARKETREGION && isOwnerAssignment){
                            leadObj.ownerid = locationNameAndDAMap.get(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).id)[Integer.valueOf(locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).NSP_Last_Index_Used__c)].NSP_District_Administrator__c;
                            leadObj.NSP_Lead_Routing__c=FALSE;
                            
                        } 
                        //Incerementing the index after every assignment so that the lead is assigned to the next DA in the list
                        locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).NSP_Last_Index_Used__c = locationNameAndOfficeMap.get(leadObj.NSP_Zip_Based_Location__c).NSP_Last_Index_Used__c +1;
                    }
                    if(leadObj.NSP_Lead_Routing__c){
                        leadObj.NSP_Lead_Routing__c=FALSE;
                    }
                  }
              }
              
          }
          
          update locationNameAndOfficeMap.values();
      
      
  } 
}