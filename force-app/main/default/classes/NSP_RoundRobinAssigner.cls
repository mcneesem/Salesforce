// Represents the class which is responsible for round robin lead assignment.
public class NSP_RoundRobinAssigner {
    // test w/ NSP_RoundRobinAssignerTest (92%)

    //
    // Identifies the leads office and the realted office assignemtns as well as the DA details.
    // @param leadsforRR List of leads eligible for round robin.
    // @param zipBasedLocationList List of location that leads are from
    // @return void
    //
    public static void getOfficeAssignmentDetails(
        List<Lead> leadsforRR,
        List<String> zipBasedLocationList ,
        Boolean isOwnerAssignment
        )
    {
        //Map of location name and office records
        Map<String,NSP_Office__c> locationNameAndOfficeMap = new Map<String,NSP_Office__c>();
        //Map of office record ids and office records- used for finding the related records from the office
        //assignment object
        Map<ID,NSP_Office__c> locationIdAndOfficeMap = new Map<ID,NSP_Office__c>();

        //Map to store location name and all the sales office DA's from the location
        Map<String,List<NSP_Office_Assignment__c>> locationNameAndDAMap = new Map<String,List<NSP_Office_Assignment__c>>();

        Map<String,String> salesOfficeDAMap = new Map<String,String>();
        //Iterate over office records to get offices related to the lead location
        for ( NSP_Office__c officeObj : [
                    SELECT Id , NSP_Last_Index_Used__c , NSP_Number_Of_Offices__c , Name
                    FROM NSP_Office__c
                    WHERE ( Name IN :zipBasedLocationList )
                ]
            )
        {
            // Populating the map
            locationNameAndOfficeMap.put( officeObj.Name , officeObj );
            locationIdAndOfficeMap.put( officeObj.Id , officeObj );
        }

        // Iterating over the office assignment records to get all offices and there DA related to the leads location
        // in a sequence that will be used for round robin assignment
        for ( NSP_Office_Assignment__c officeAssignmntObj : [
                    SELECT Id , Name , NSP_District_Administrator__c , NSP_Location_Name__c , NSP_Sales_Office__c
                    FROM NSP_Office_Assignment__c
                    WHERE (
                        ( NSP_Location_Name__c IN :locationIdAndOfficeMap.keyset() )
                        AND ( NSP_District_Administrator__c != null )
                        AND ( NSP_isActive__c = true )
                    )
                    ORDER BY NSP_Office_Number__c
                ]
            )
        {
            salesOfficeDAMap.put(
                officeAssignmntObj.NSP_Sales_Office__c ,
                officeAssignmntObj.NSP_District_Administrator__c
            );
            //Checking wether the location already exist in the map or not
            if ( !locationNameAndDAMap.containsKey( officeAssignmntObj.NSP_Location_Name__c ) ) {
                locationNameAndDAMap.put(
                    officeAssignmntObj.NSP_Location_Name__c ,
                    new List<NSP_Office_Assignment__c>()
                );
            }
            //Adding the location and list of DA's from the offices of that location
            locationNameAndDAMap.get( officeAssignmntObj.NSP_Location_Name__c ).add( officeAssignmntObj );
        }
        // Calling the round robin method
        // As part of DF-DF-01618 added if condition.
        if ( !locationNameAndOfficeMap.isEmpty()
            && !locationNameAndDAMap.isEmpty()
            )
        {
            doRoundRobin(
                locationNameAndOfficeMap ,
                locationNameAndDAMap ,
                leadsforRR ,
                isOwnerAssignment ,
                salesOfficeDAMap
            );
        }
    }

    //
    // Responsible for assigning the leads in round robin to all the offices that are present in a specific location
    // @param locationNameAndOfficeMap Map of location name adn Office records
    // @param locationNameAndDAMap Map of location name and list of DA's from each salesoffice of that location
    // @param leadsforRR List of leads eligible for round robin.
    // @return void
    //
    private static void doRoundRobin(
        Map<String,NSP_Office__c> locationNameAndOfficeMap ,
        Map<String,List<NSP_Office_Assignment__c>> locationNameAndDAMap ,
        List<Lead> leadsforRR ,
        Boolean isOwnerAssignment ,
        Map<String,String> salesOfficeDAMAP
        )
    {
        //Iterating over the lead that needs to be assigned in round robin manner
        for ( Lead leadObj : leadsforRR ) {
            Integer lastIndexUsed = 0;
            Integer numberOfOffices = 0;
            List<NSP_Office_Assignment__c> officeAssignments = null;
            NSP_Office__c office = locationNameAndOfficeMap.get( leadObj.NSP_Zip_Based_Location__c );
            if ( office != null ) {
                if ( office.NSP_Last_Index_Used__c != null ) {
                    lastIndexUsed = office.NSP_Last_Index_Used__c.intValue();
                }
                if ( office.NSP_Number_Of_Offices__c != null ) {
                    numberOfOffices = office.NSP_Number_Of_Offices__c.intValue();
                }
                if ( locationNameAndDAMap.containsKey( office.Id ) ) {
                    officeAssignments = locationNameAndDAMap.get( office.Id );
                }
            }
            if ( officeAssignments != null ) {
                //Checking the last index used so that we can start assignment from the next index
                if ( lastIndexUsed > ( numberOfOffices - 1 ) ) {
                    // Reassinging the last index to zero as the the index value has gotten greater than the number of office present in that location
                    lastIndexUsed = 0;
                }
                NSP_Office_Assignment__c officeAssignment = officeAssignments[lastIndexUsed];
                // assigning owner to the lead record
                if ( ( leadObj.NSP_Is_Sales_Office_Assigned__c == true )
                    && ( leadObj.NSP_Lead_Routing__c == true )
                    && salesOfficeDAMAP.containsKey( leadObj.NSP_Sales_Office__c )
                    && String.isNotBlank( salesOfficeDAMAP.get( leadObj.NSP_Sales_Office__c ) )
                    )
                {
                    leadObj.OwnerId = salesOfficeDAMAP.get( leadObj.NSP_Sales_Office__c ); // owner cannot be blank
                    leadObj.NSP_Is_Sales_Office_Assigned__c = false;
                } else if ( officeAssignment != null ) {
                    leadObj.NSP_Sales_Office__c = officeAssignment.NSP_Sales_Office__c;
                    if ( ( leadObj.NSP_Zip_Based_Location__c != 'MidMarket' )
                        && isOwnerAssignment
                        && String.isNotBlank( officeAssignment.NSP_District_Administrator__c )
                        )
                    {
                        leadObj.OwnerId = officeAssignment.NSP_District_Administrator__c; // owner cannot be blank
                    }
                    // Incrementing the last index used after every assignment so that the lead is assigned to the next DA in the list
                    lastIndexUsed++;
                    locationNameAndOfficeMap.get( leadObj.NSP_Zip_Based_Location__c ).NSP_Last_Index_Used__c = lastIndexUsed;
                }
                if ( leadObj.NSP_Lead_Routing__c ) {
                    leadObj.NSP_Lead_Routing__c = false;
                }
            }
        }
        update locationNameAndOfficeMap.values();
    }

}
//