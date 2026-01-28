//- Does NOT modify UserAvailability. It delegates to it.
//- Windows are constructed in the running user's timezone via Date.today().

public with sharing class UserAvailabilityService {
    // test w/ UserAvailabilityServiceTest (96%)
    //Returns the 7 available days based on Business Hours
    @AuraEnabled(cacheable=true)
    public static List<Date> getBusinessDates(Id businessHoursId, Integer daysLimit) {
        List<Date> response = new List<Date>();
        List<BusinessHours> hours = [
            SELECT Id
            FROM BusinessHours
            WHERE ( Id = :businessHoursId )
        ];
        BusinessHours open = null;
        if ((hours != null) && !hours.isEmpty() ) {
            open = hours[0];
        }

        try {
            // Initialize next business start
            Datetime nextBusinessStart = BusinessHours.nextStartDate(open.Id, System.now());

            // Collect next 7 business days
            while((nextBusinessStart != null) && (response.size() < daysLimit)) {
                response.add(Date.newInstance(
                    nextBusinessStart.year() ,
                    nextBusinessStart.month() ,
                    nextBusinessStart.day()
                )
                            );
                nextBusinessStart = BusinessHours.nextStartDate(open.Id, nextBusinessStart.addDays(1));
            }
        } catch (Exception e) {
            NSP_ErrorLogHandler.logException( UserAvailabilityService.class.getName() , 'businessDays' , e );
        }
        return response;
    }

    //Creates the start and end dates that will be used as the windows
    //for availability calculation
    private class DaysMatrix{
        List<List<DateTime>> startDays;
        List<List<DateTime>> endDays;
    }
    private static DaysMatrix getBusinessDaysMatrix() {
        List<List<Datetime>> startDaysList = new List<List<Datetime>>();
        List<List<Datetime>> endDaysList = new List<List<Datetime>>();
        //Get real days based on Business Hours
        List<Date> businessDates = UserAvailabilityService.getBusinessDates('01m4x000001119T',7);
        //For now, hardcoding the start and end time slots
        Map<Integer, Integer> startTimeSlots = new Map<Integer, Integer>{1 => 8,2 => 8, 3 => 9, 4 => 9, 5 => 10, 6 => 11};
            Map<Integer, Integer> startTimeSlotsMinutes = new Map<Integer, Integer>{1 => 0, 2 => 30, 3 => 0, 4 => 30, 5 => 0, 6 => 30};
                Map<Integer, Integer> endTimeSlots = new Map<Integer, Integer>{1 => 9,2 => 9, 3 => 10, 4 => 10, 5 => 11, 6 => 12};
                    Map<Integer, Integer> endTimeSlotsMinutes = new Map<Integer, Integer>{1 => 0, 2 => 30, 3 => 0, 4 => 30, 5 => 0, 6 => 30};

                        //Loop matching the number of time slots
                        for (Integer j = 0; j < 6; j++) {
                            List<Datetime> startDays = new List<Datetime>();
                            List<Datetime> endDays = new List<Datetime>();
                            //Iterating through the 7 days to create the datetimes for each
                            for (Date businessDate : businessDates) {
                                Integer startTimeHour = startTimeSlots.get(j+1);
                                Integer startTimeMinute = startTimeSlotsMinutes.get(j+1);
                                Integer endTimeHour = endTimeSlots.get(j+1);
                                Integer endTimeMinute = endTimeSlotsMinutes.get(j+1);
                                Time startT = Time.newInstance(startTimeHour, startTimeMinute, 0, 0);
                                Time endT   = Time.newInstance(endTimeHour, endTimeMinute, 0, 0);
                                // Add the calculated datetime to the startDays and endDays lists
                                startDays.add(
                                    DateTime.newInstance(
                                        businessDate.year() ,
                                        businessDate.month() ,
                                        businessDate.day() ,
                                        startTimeHour ,
                                        startTimeMinute ,
                                        0
                                    )
                                );
                                endDays.add(
                                    DateTime.newInstance(
                                        businessDate.year() ,
                                        businessDate.month() ,
                                        businessDate.day() ,
                                        endTimeHour ,
                                        endTimeMinute ,
                                        0
                                    )
                                );
                            }
                            //Organizing days in a separate list to effectively group them by time slots
                            if (startDays.size() > 0) {
                                //startDaysList((2026-01-20 8:00),(2026-01-21 8:30),(2026-01-22 9:00)...)
                                startDaysList.add(startDays);
                            }
                            if (endDays.size() > 0) {
                                //endDaysList((2026-01-20 9:00),(2026-01-21 9:30),(2026-01-22 10:00)...)
                                endDaysList.add(endDays);
                            }
                        }
        //Matrix of start and end days grouped by time slots
        //[2026-01-20 8:00,2026-01-21 8:30,2026-01-22 9:00]
        //[2026-01-20 9:00,2026-01-21 9:30,2026-01-22 10:00]
        DaysMatrix response = new DaysMatrix();
        response.startDays = startDaysList;
        response.endDays = endDaysList;
        return response;
    }

    //Calculates how many available slots the user has by creating events and leveraging existing existing calculation
    @AuraEnabled(cacheable=true)
    public static List<List<Integer>> getCountsMatrix(Id userId, Integer stepMinutes) {
        Id effectiveUserId = (userId == null) ? UserInfo.getUserId() : userId;
        Integer step = (stepMinutes == null) ? 30 : stepMinutes;
        List<List<Integer>> listSizeMatrix = new List<List<Integer>>();
        // Get the business days matrix structure
        DaysMatrix daysOfWeek = UserAvailabilityService.getBusinessDaysMatrix();
        List<Datetime> startDays = new List<Datetime>();
        List<Datetime> endDays = new List<Datetime>();
        Integer groupCount = Math.min( daysOfWeek.startDays.size(), daysOfWeek.endDays.size() );
        // Extract start and end times properly maintaining the pairing
        for (Integer i = 0; i < groupCount; i++) {
            startDays.addAll(daysOfWeek.startDays[i]);
            endDays.addAll(daysOfWeek.endDays[i]);
        }
        if (startDays.isEmpty() || endDays.isEmpty()) {
            return listSizeMatrix;
        }

        Datetime windowStart = startDays[0];
        Datetime windowEnd   = endDays[endDays.size() - 1];
        // Query user events once for all windows
        List<Event> busy = [ SELECT Id, StartDateTime, EndDateTime
                            FROM Event
                            WHERE OwnerId = :effectiveUserId
                            AND StartDateTime < :windowEnd
                            AND EndDateTime > :windowStart
                            WITH SECURITY_ENFORCED ];

        // Create windows for each time slot
        Integer n = Math.min(startDays.size(), endDays.size());
        List<Event> windows = new List<Event>();
        for (Integer i = 0; i < n; i++) {
            // Prepare windows
            windows.add(new Event(StartDateTime = startDays[i], EndDateTime = endDays[i]));
        }
        // Delegate to existing algorithm
        UserAvailability calc = new UserAvailability();
        List<List<String>> availableSlotsList = new List<List<String>>();

        for(Event slots: windows) {
            availableSlotsList.add(calc.getAvailableSlots(busy, slots, step));
        }

        listSizeMatrix = getAvailabilityMatrix(availableSlotsList);
        return listSizeMatrix;
    }
    // Helper: convert a flat list of integer counts into a matrix of rows with up to 7 columns
    private static List<List<Integer>> convertToMatrix(List<Integer> counts) {
        List<List<Integer>> matrix = new List<List<Integer>>();
        if (counts != null && !counts.isEmpty()) {
            List<Integer> row = new List<Integer>();
            for (Integer c : counts) {
                row.add((c == null) ? 0 : c);
                if (row.size() == 7) {
                    matrix.add(new List<Integer>(row));
                    row.clear();
                }
            }
            if ( !row.isEmpty() ) {
                matrix.add(new List<Integer>(row));
            }
        }
        return matrix;
    }
    //Get total availability of users that are added to the Schedule Seller Permission Set
    @AuraEnabled(cacheable=true)
    public static List<List<Integer>> getAggregateCountsMatrix( Integer stepMinutes, String product ) {
        List<List<Integer>> listSizeMatrix = new List<List<Integer>>();
 		List<Integer> countsPerWindow = new List<Integer>();
        String typeOfProduct = null;
        if( product != null ) {
            typeOfProduct = 'Schedule_Seller_' + product;
        } else {
            typeOfProduct = 'Schedule_Seller_HR360';
        }
        // Build business day/time windows
        DaysMatrix daysOfWeek = UserAvailabilityService.getBusinessDaysMatrix();
        List<Datetime> startDays = new List<Datetime>();
        List<Datetime> endDays = new List<Datetime>();

        Integer groupCount = Math.min( daysOfWeek.startDays.size(), daysOfWeek.endDays.size() );
        for (Integer i = 0; i < groupCount; i++) {
            startDays.addAll(daysOfWeek.startDays[i]);
            endDays.addAll(daysOfWeek.endDays[i]);
        }
        Datetime windowStart = startDays[0];
        Datetime windowEnd   = endDays[endDays.size() - 1];
        // Identify users with Schedule Seller Permission Set
        Set<Id> userIds = new Set<Id>();
        List<PermissionSetAssignment> permSet = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = : typeOfProduct
        ];
        if( !permSet.isEmpty() ){
            for (PermissionSetAssignment psa : permSet) {
                userIds.add(psa.AssigneeId);
            }
        }
        // Query all events for those users within the union window (bulkified)
        Map<Id, List<Event>> busyByUser = new Map<Id, List<Event>>();
        List<Event> events = [
            SELECT Id, OwnerId, StartDateTime, EndDateTime
            FROM Event
            WHERE OwnerId IN :userIds
            AND StartDateTime < :windowEnd
            AND EndDateTime   > :windowStart
            WITH SECURITY_ENFORCED
        ];
        if( !events.isEmpty() ) {
            for (Event e : events) {
                if (!busyByUser.containsKey(e.OwnerId)) {
                    busyByUser.put(e.OwnerId, new List<Event>());
                }
                busyByUser.get(e.OwnerId).add(e);
            }
        }
        if( !userIds.isEmpty() ) {
            for (Id uid : userIds) {
                if (!busyByUser.containsKey(uid)) {
                    busyByUser.put(uid, new List<Event>());
                }
            }
        }
        // Build windows for each slot
        Integer n = Math.min(startDays.size(), endDays.size());
        List<Event> windows = new List<Event>();
        for (Integer i = 0; i < n; i++) {
            windows.add(new Event(StartDateTime = startDays[i], EndDateTime = endDays[i]));
        }
        countsPerWindow = getAggregateAvailableSlots( windows, userIds, busyByUser, stepMinutes );
        listSizeMatrix = convertToMatrix(countsPerWindow);
        return listSizeMatrix;
    }

    private static List<Integer> getAggregateAvailableSlots(
        List<Event> windows,
        Set<Id> userIds,
        Map<Id, List<Event>> busyByUser,
        Integer stepMinutes
    )
    {
        // Use existing availability algorithm, summing per-user counts per window
        UserAvailability calc = new UserAvailability();
        // Collect integer counts per window
        List<Integer> countsPerWindow = new List<Integer>();
        Integer step = (stepMinutes == null) ? 30 : stepMinutes;
        if( !windows.isEmpty() && !userIds.isEmpty() ) {
            for (Event windowEvt : windows) {
                Integer totalForWindow = 0;
                for (Id uid : userIds) {
                    if(busyByUser.containsKey(uid) && busyByUser.get(uid) != null) {
                        List<Event> userBusy = busyByUser.get(uid);
                        List<String> slots = calc.getAvailableSlots(userBusy, windowEvt, step);
                        totalForWindow += (slots == null) ? 0 : slots.size();
                    }
                }
                countsPerWindow.add(totalForWindow);
            }
        }
        return countsPerWindow;
    }
    //Returns availability Matrix for given time slots and 7 business days
    private static List<List<Integer>> getAvailabilityMatrix(List<List<String>> availableSlotsList) {
        List<List<Integer>> listSizeMatrix = new List<List<Integer>>();
        List<Integer> clearList = new List<Integer>();
        // Process results into matrix format (6 rows × 7 columns)
        // Rows will be dynamic once we get the values from a custom metadata
        for (List<String> slots : availableSlotsList) {
            Integer size = (slots == null) ? 0 : slots.size();
            clearList.add(size);

            // When we have 7 elements (one for each day), create a new row
            if (clearList.size() == 7) {
                listSizeMatrix.add(new List<Integer>(clearList)); // Clone to persist state
                clearList.clear(); // Reset for the next batch
            }
        }

        // Add any remaining elements if clearList is not empty
        if (!clearList.isEmpty()) {
            listSizeMatrix.add(new List<Integer>(clearList));
        }
        return listSizeMatrix;
    }
}