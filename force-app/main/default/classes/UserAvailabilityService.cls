//- Does NOT modify UserAvailability2. It delegates to it.
//- Windows are constructed in the running user's timezone via Date.today().
public with sharing class UserAvailabilityService {
   
	//Returns the 7 available days based on Business Hours
    @AuraEnabled(cacheable=true)
    public static List<Datetime> businessDays() {
        Date today = Date.today();
        Integer count = 0;
        List<Datetime> businessDaysLst = new List<Datetime>();
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        
        try {
            // Initialize next business start
            Datetime nextBusinessStart = BusinessHours.nextStartDate(bh.Id, System.now());
            
            // Collect next 7 business days at 8 AM
            while (count < 7 && nextBusinessStart != null) {
                Datetime businessDay = Datetime.newInstance(nextBusinessStart.year(), nextBusinessStart.month(), nextBusinessStart.day(), 8, 0, 0);
                businessDaysLst.add(businessDay);                
                nextBusinessStart = BusinessHours.nextStartDate(bh.Id, nextBusinessStart.addDays(1));
                count++;
            }
        } catch (Exception e) {
            NSP_ErrorLogHandler.logException(
                UserAvailabilityService.class.getName() ,
                'businessDays' ,
                e
            );    
        }
        
        return businessDaysLst;
    }
	
    //Creates the start and end dates that will be used as the windows 
    //for availability calculation
    @AuraEnabled(cacheable=true)
    public static Map<List<List<Datetime>>,List<List<Datetime>>> getBusinessDaysMatrix() {
        Map<List<List<Datetime>>,List<List<Datetime>>> daysMap = new Map<List<List<Datetime>>,List<List<Datetime>>>();
        List<List<Datetime>> startDaysList = new List<List<Datetime>>();
        List<List<Datetime>> endDaysList = new List<List<Datetime>>();
        //Get real days based on Business Hours
        List<Datetime> businessDays = businessDays();
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
            for (Datetime dayDatetime : businessDays) {
                Integer startTimeHour = startTimeSlots.get(j+1);
                Integer startTimeMinute = startTimeSlotsMinutes.get(j+1);
                Integer endTimeHour = endTimeSlots.get(j+1);
                Integer endTimeMinute = endTimeSlotsMinutes.get(j+1);

                // Add the calculated datetime to the startDays and endDays lists
                startDays.add(DateTime.newInstance(dayDatetime.year(), dayDatetime.month(), dayDatetime.day(), startTimeHour, startTimeMinute, 0));
                endDays.add(DateTime.newInstance(dayDatetime.year(), dayDatetime.month(), dayDatetime.day(), endTimeHour, endTimeMinute, 0));
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
        daysMap.put(startDaysList,endDaysList);
        return daysMap;
    }
	
    //Calculates how many available slots the user has by creating events and leveraging existing existing calculation
    @AuraEnabled(cacheable=true)
    public static List<List<Integer>> getCountsMatrix(Id userId, Integer bufferMinutes, Integer stepMinutes) {
        Id effectiveUserId = (userId == null) ? UserInfo.getUserId() : userId;
        Integer buffer = (bufferMinutes == null) ? 0 : bufferMinutes;
        Integer step = (stepMinutes == null) ? 30 : stepMinutes;

        // Get the business days matrix structure
        Map<List<List<Datetime>>,List<List<Datetime>>> daysOfWeek = getBusinessDaysMatrix();
        List<Datetime> startTimes = new List<Datetime>();
        List<Datetime> endTimes = new List<Datetime>();
		// Extract start and end times properly maintaining the pairing
        for(List<List<Datetime>> startTimeGroups : daysOfWeek.keySet()) {
            List<List<Datetime>> endTimeGroups = daysOfWeek.get(startTimeGroups);
            for(Integer i = 0; i < startTimeGroups.size(); i++) {
                if(i < endTimeGroups.size()) {
                    List<Datetime> startTimeGroup = startTimeGroups[i];
                    List<Datetime> endTimeGroup = endTimeGroups[i];

                    // Add all time slots from this group
                    startTimes.addAll(startTimeGroup);
                    endTimes.addAll(endTimeGroup);
                }
            }
        }
        // Query user events once for all windows
        List<Event> busy = [
            SELECT Id, StartDateTime, EndDateTime, Subject
            FROM Event
            WHERE OwnerId = :effectiveUserId
              AND StartDateTime < :endTimes[endTimes.size()-1]
              AND EndDateTime > :startTimes[0]
            WITH SECURITY_ENFORCED
        ];

        // Create windows for each time slot
        Integer n = Math.min(startTimes.size(), endTimes.size());
        List<Event> windows = new List<Event>();
        for (Integer i = 0; i < n; i++) {
            // Prepare windows
            windows.add(new Event(StartDateTime = startTimes[i], EndDateTime = endTimes[i]));
        }
        // Delegate to existing algorithm
        UserAvailability2 calc = new UserAvailability2();
        List<List<String>> availableSlotsList = new List<List<String>>();
        List<Integer> clearList = new List<Integer>();
        List<List<Integer>> listSizeMatrix = new List<List<Integer>>();

        for(Event slots: windows) {
            availableSlotsList.add(calc.getAvailableSlots(busy, slots, buffer, step));
        }

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