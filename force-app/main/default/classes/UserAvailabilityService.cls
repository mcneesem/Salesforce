public with sharing class UserAvailabilityService {
    // test w/ UserAvailabilityServiceTest (80%)

    private static final Id BUSINESS_HOURS_ID = '01m4x000001119TAAQ';
    private static final Integer DAYS_LIMIT = 10;
    private static final Integer STEP_MINUTES = 30;

    //Returns the available days based on Business Hours for the given skill...
    @AuraEnabled(cacheable=true)
    public static List<Date> getBusinessDates( String skill ) {
        Id businessHoursId = UserAvailabilityService.BUSINESS_HOURS_ID;
        Integer daysLimit = UserAvailabilityService.DAYS_LIMIT;
        List<Date> response = new List<Date>();
        List<BusinessHours> hours = [
            SELECT Id
            FROM BusinessHours
            WHERE ( Id = :businessHoursId )
        ];
        BusinessHours open = null;
        if ( ( hours != null ) && !hours.isEmpty() ) {
            open = hours[0];
        }
        if ( open != null ) {
            try {
                // Initialize next business start
                Datetime nextBusinessStart = BusinessHours.nextStartDate(
                    open.Id ,
                    System.now()
                );
                // Collect next business days
                while( (nextBusinessStart != null ) && ( response.size() < daysLimit ) ) {
                    response.add(
                        Date.newInstance(
                            nextBusinessStart.year() ,
                            nextBusinessStart.month() ,
                            nextBusinessStart.day()
                        )
                    );
                    nextBusinessStart = BusinessHours.nextStartDate(
                        open.Id ,
                        nextBusinessStart.addDays( 1 )
                    );
                }
            } catch ( Exception e ) {
                NSP_ErrorLogHandler.logException(
                    UserAvailabilityService.class.getName() ,
                    'businessDays' ,
                    e
                );
            }
        }
        return response;
    }

    //Creates the start and end dates that will be used as the windows
    //for availability calculation
    private class DaysMatrix{
        List<List<DateTime>> startDays;
        List<List<DateTime>> endDays;
        List<List<Event>> slots;
    }
    private static DaysMatrix getBusinessDaysMatrix( String skill ) {
        List<List<Datetime>> startDaysList = new List<List<Datetime>>();
        List<List<Datetime>> endDaysList = new List<List<Datetime>>();
        List<List<Event>> slotsList = new List<List<Event>>();
        //Get real days based on Business Hours
        List<Date> businessDates = UserAvailabilityService.getBusinessDates( skill );
        //For now, hardcoding the start and end time slots
        Map<Integer,Integer> startTimeSlots = new Map<Integer,Integer>{
            1 => 8 ,
            2 => 8 ,
            3 => 9 ,
            4 => 9 ,
            5 => 10 ,
            6 => 10 ,
            7 => 11 ,
            8 => 11 ,
            9 => 12 ,
            10 => 13 ,
            11 => 13 ,
            12 => 14 ,
            13 => 15 ,
            14 => 15 ,
            15 => 16
        };
        Map<Integer,Integer> startTimeSlotsMinutes = new Map<Integer,Integer>{
            1 => 00 ,
            2 => 30 ,
            3 => 00 ,
            4 => 30 ,
            5 => 00 ,
            6 => 30 ,
            7 => 00 ,
            8 => 30 ,
            9 => 30 ,
            10 => 00 ,
            11 => 30 ,
            12 => 00 ,
            13 => 00 ,
            14 => 30 ,
            15 => 00
        };
        Map<Integer,Integer> endTimeSlots = new Map<Integer,Integer>{
            1 => 9 ,
            2 => 9 ,
            3 => 10 ,
            4 => 10 ,
            5 => 11 ,
            6 => 11 ,
            7 => 12 ,
            8 => 12 ,
            9 => 13 ,
            10 => 14 ,
            11 => 14 ,
            12 => 15 ,
            13 => 16 ,
            14 => 16 ,
            15 => 17
        };
        Map<Integer,Integer> endTimeSlotsMinutes = new Map<Integer,Integer>{
            1 => 00 ,
            2 => 30 ,
            3 => 00 ,
            4 => 30 ,
            5 => 00 ,
            6 => 30 ,
            7 => 00 ,
            8 => 30 ,
            9 => 30 ,
            10 =>00 ,
            11 => 30 ,
            12 => 00 ,
            13 => 00 ,
            14 => 30 ,
            15 => 00
        };
        //Loop matching the number of time slots
        for ( Integer j = 0 ; j < startTimeSlots.size() ; j++ ) {
            List<Datetime> startDays = new List<Datetime>();
            List<Datetime> endDays = new List<Datetime>();
            List<Event> slots = new List<Event>();
            //Iterating through the N days to create the datetimes for each
            for ( Date businessDate : businessDates ) {
                Integer startTimeHour = startTimeSlots.get( j + 1 );
                Integer startTimeMinute = startTimeSlotsMinutes.get( j + 1 );
                Integer endTimeHour = endTimeSlots.get( j + 1 );
                Integer endTimeMinute = endTimeSlotsMinutes.get( j + 1 );
                // Add the calculated datetime to the startDays and endDays lists
                DateTime startDay = DateTime.newInstance(
                    businessDate.year() ,
                    businessDate.month() ,
                    businessDate.day() ,
                    startTimeHour ,
                    startTimeMinute ,
                    0
                );
                startDays.add( startDay );
                DateTime endDay = DateTime.newInstance(
                    businessDate.year() ,
                    businessDate.month() ,
                    businessDate.day() ,
                    endTimeHour ,
                    endTimeMinute ,
                    0
                );
                endDays.add( endDay );
                slots.add(
                    new Event(
                        StartDateTime=startDay ,
                        EndDateTime=endDay
                    )
                );
            }
            //Organizing days in a separate list to effectively group them by time slots
            if ( !startDays.isEmpty() ) {
                //startDaysList((2026-01-20 8:00),(2026-01-21 8:30),(2026-01-22 9:00)...)
                startDaysList.add( startDays );
            }
            if ( !endDays.isEmpty() ) {
                //endDaysList((2026-01-20 9:00),(2026-01-21 9:30),(2026-01-22 10:00)...)
                endDaysList.add( endDays );
            }
            if ( !slots.isEmpty() ) {
                slotsList.add( slots );
            }
        }
        //Matrix of start and end days grouped by time slots
        //[2026-01-20 8:00,2026-01-21 8:30,2026-01-22 9:00]
        //[2026-01-20 9:00,2026-01-21 9:30,2026-01-22 10:00]
        DaysMatrix response = new DaysMatrix();
        response.startDays = startDaysList;
        response.endDays = endDaysList;
        response.slots = slotsList;
        return response;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getTimeBlocks( String skill , String timeZone ) {
        List<String> value = new List<String>();
        List<String> timeBlocksPrimary = new List<String>{
            '8:00 - 9:00' ,
            '8:30 - 9:30' ,
            '9:00 - 10:00' ,
            '9:30 - 10:30' ,
            '10:00 - 11:00' ,
            '10:30 - 11:30' ,
            '11:00 - 12:00' ,
            '11:30 - 12:30' ,
            '12:30 - 1:30' ,
            '1:00 - 2:00' ,
            '1:30 - 2:30' ,
            '2:00 - 3:00' ,
            '3:00 - 4:00' ,
            '3:30 - 4:30' ,
            '4:00 - 5:00'
        };
        List<String> timeBlocksAlternate = new List<String>{
            '1:00 - 2:00' ,
            '2:00 - 3:00' ,
            '3:30 - 4:30' ,
            '4:00 - 5:00' ,
            '5:30 - 6:30' ,
            '6:00 - 7:00'
        };
        Map<String,List<String>> timeZoneBlocks = new Map<String,List<String>>{
            'Central' => timeBlocksPrimary ,
            'Mountain'=> timeBlocksAlternate ,
            'Pacific'=> timeBlocksPrimary ,
            'Eastern'=> timeBlocksPrimary
        };
        if ( String.isNotBlank( timeZone )
            && timeZoneBlocks.containsKey( timeZone )
            && timeZoneBlocks.get( timeZone ) != null
            )
        {
            value = timeZoneBlocks.get( timeZone );
        }
        return value;
    }

    // Helper: convert a flat list of integer counts into a matrix of rows with up to N columns
    private static List<List<Integer>> convertToMatrix( List<Integer> counts ) {
        List<List<Integer>> matrix = new List<List<Integer>>();
        if ( ( counts != null ) && !counts.isEmpty() ) {
            List<Integer> row = new List<Integer>();
            for ( Integer c : counts ) {
                row.add( ( c == null ) ? 0 : c );
                if ( row.size() == UserAvailabilityService.DAYS_LIMIT ) {
                    matrix.add( new List<Integer>( row ) );
                    row.clear();
                }
            }
            if ( !row.isEmpty() ) {
                matrix.add( new List<Integer>( row ) );
            }
        }
        return matrix;
    }

    //Get total availability of users that are added to the Schedule Seller Permission Set
    @AuraEnabled(cacheable=true)
    public static List<List<Integer>> getAggregateCountsMatrix( String skill ) {
        // Build business day/time windows
        DaysMatrix daysOfWeek = UserAvailabilityService.getBusinessDaysMatrix( skill );
        List<Datetime> startDays = new List<Datetime>();
        List<Datetime> endDays = new List<Datetime>();
        Event window = null;
        if ( ( daysOfWeek != null )
            && ( daysOfWeek.startDays != null )
            && ( daysOfWeek.endDays != null )
            && ( daysOfWeek.startDays.size() == daysOfWeek.endDays.size() )
           )
        {
            for ( Integer i = 0 ; i < daysOfWeek.startDays.size() ; i++ ) {
                startDays.addAll( daysOfWeek.startDays[i] );
                endDays.addAll( daysOfWeek.endDays[i] );
            }
            window = new Event(
                StartDateTime=startDays[0] ,
                EndDateTime=endDays[endDays.size() - 1]
            );
        }
        // Identify users with Schedule Seller Custom Permission
        Map<Id,User> skilledUsers = CustomPermissionController.getPermittedUsersMap( skill );
        Set<Id> userIds = ( ( skilledUsers != null ) ? skilledUsers.keySet() : new Set<Id>() );
        // Query all events for those users within the union window (bulkified)
        Map<Id,List<Event>> busyByUser = new Map<Id,List<Event>>();
        List<Event> events = UserAvailabilityService.getEventsForUser(
            userIds ,
            window
        );
        if ( ( events != null ) && !events.isEmpty() ) {
            for ( Event e : events ) {
                if ( !busyByUser.containsKey( e.OwnerId ) ) {
                    busyByUser.put( e.OwnerId , new List<Event>() );
                }
                busyByUser.get( e.OwnerId ).add( e );
            }
        }
        if ( !userIds.isEmpty() ) {
            for ( Id uid : userIds ) {
                if ( !busyByUser.containsKey( uid ) ) {
                    busyByUser.put( uid , new List<Event>() );
                }
            }
        }
        // Build windows for each slot
        List<Event> windows = new List<Event>();
        if ( startDays.size() == endDays.size() ) {
            for ( Integer i = 0 ; i < startDays.size() ; i++ ) {
                windows.add(
                    new Event(
                        StartDateTime=startDays[i] ,
                        EndDateTime=endDays[i]
                    )
                );
            }
        }
        return UserAvailabilityService.convertToMatrix(
            UserAvailabilityService.getAggregateAvailableSlots(
                windows ,
                userIds ,
                busyByUser
            )
        );
    }

    private static List<Integer> getAggregateAvailableSlots(
        List<Event> windows ,
        Set<Id> userIds ,
        Map<Id,List<Event>> busyByUser
        )
    {
        // Use existing availability algorithm, summing per-user counts per window
        UserAvailability calc = new UserAvailability();
        // Collect integer counts per window
        List<Integer> countsPerWindow = new List<Integer>();
        if ( ( windows != null )
            && ( userIds != null )
            && ( busyByUser != null )
            && !windows.isEmpty()
            && !userIds.isEmpty()
            )
        {
            for ( Event windowEvt : windows ) {
                Integer totalForWindow = 0;
                for ( Id uid : userIds ) {
                    if ( busyByUser.containsKey( uid )
                        && ( busyByUser.get( uid ) != null )
                        )
                    {
                        totalForWindow += UserAvailabilityService.countAvailableSlots(
                            busyByUser.get( uid ) ,
                            windowEvt
                        );
                    }
                }
                countsPerWindow.add( totalForWindow );
            }
        }
        return countsPerWindow;
    }

    // helper method to defeat sonar cognitive complexity...
    private static Integer countAvailableSlots( List<Event> records , Event window ) {
        List<String> available = calc.getAvailableSlots(
            records ,
            window ,
            UserAvailabilityService.STEP_MINUTES
        );
        return ( ( available == null ) ? 0 : available.size() );
    }

    //Returns availability Matrix for given time slots and N business days
    private static List<List<Integer>> getAvailabilityMatrix( List<List<String>> availableSlotsList ) {
        List<List<Integer>> listSizeMatrix = new List<List<Integer>>();
        List<Integer> clearList = new List<Integer>();
        // Process results into matrix format (M rows × N columns)
        // Rows will be dynamic once we get the values from a custom metadata
        for ( List<String> slots : availableSlotsList ) {
            Integer size = ( ( slots == null ) ? 0 : slots.size() );
            clearList.add( size );
            // When we have N elements (one for each day), create a new row
            if ( clearList.size() == UserAvailabilityService.DAYS_LIMIT ) {
                listSizeMatrix.add( new List<Integer>( clearList ) ); // Clone to persist state
                clearList.clear(); // Reset for the next batch
            }
        }
        // Add any remaining elements if clearList is not empty
        if ( !clearList.isEmpty() ) {
            listSizeMatrix.add( new List<Integer>( clearList ) );
        }
        return listSizeMatrix;
    }

    @AuraEnabled(cacheable=true)
    public static List<Id> getAvailableUsersForWindow(
        Datetime startDateTime ,
        Datetime endDateTime ,
        String skill
        )
    {
        List<Id> availableUsers = new List<Id>();
        Map<Id,List<Event>> busyByUser = new Map<Id,List<Event>>();
        // Basic input validation (single return rule: just avoid doing work if invalid)
        Boolean validWindow = (
            ( startDateTime != null )
            && ( endDateTime != null )
            && ( endDateTime > startDateTime )
        );
        // Resolve permission set name
        Map<Id,User> skilledUsers = CustomPermissionController.getPermittedUsersMap( skill );
        Set<Id> userIds = ( ( skilledUsers != null ) ? skilledUsers.keySet() : new Set<Id>() );
        // Load overlapping events once for all eligible users (only if inputs are valid)
        List<Event> overlapping = UserAvailabilityService.getEventsForUser(
            userIds ,
            startDateTime ,
            endDateTime
        );
        if ( ( overlapping != null ) && !overlapping.isEmpty() ) {
            for ( Event e : overlapping ) {
                if ( !busyByUser.containsKey( e.OwnerId ) ) {
                    busyByUser.put(
                        e.OwnerId ,
                        new List<Event>()
                    );
                }
                busyByUser.get( e.OwnerId ).add( e );
            }
        }
        // Ensure every user exists in the map (so busyByUser.get(uid) isn't null)
        if ( ( userIds != null ) && !userIds.isEmpty() ) {
            for ( Id uid : userIds ) {
                if ( ( uid != null ) && !busyByUser.containsKey( uid ) ) {
                    busyByUser.put( uid , new List<Event>() );
                }
            }
        }
        // Only compute availability if we have a valid window and eligible users
        if ( validWindow
            && ( userIds != null )
            && !userIds.isEmpty()
            )
        {
            UserAvailability calc = new UserAvailability();
            Event windowEvt = new Event(
                StartDateTime=startDateTime ,
                EndDateTime=endDateTime
            );
            for ( Id uid : userIds ) {
                List<Event> userBusy = new List<Event>();
                if ( busyByUser.containsKey( uid )
                    && ( busyByUser.get( uid ) != null )
                    )
                {
                    userBusy = busyByUser.get( uid );
                }
                List<String> slots = calc.getAvailableSlots(
                    userBusy ,
                    windowEvt ,
                    UserAvailabilityService.STEP_MINUTES
                );
                if ( ( slots != null ) && !slots.isEmpty() ) {
                    availableUsers.add( uid );
                }
            }
        }
        return availableUsers;
    }

    private static List<Event> getEventsForUser(
        Set<Id> userIds ,
        Datetime startDateTime ,
        Datetime endDateTime
        )
    {
        List<Event> events = new List<Event>();
        if ( ( userIds != null )
            && ( startDateTime != null )
            && ( endDateTime != null )
            )
        {
            events = [
                SELECT
                    Id ,
                    OwnerId ,
                    StartDateTime ,
                    EndDateTime
                FROM Event
                WHERE (
                    ( OwnerId IN :userIds )
                    AND ( StartDateTime < :endDateTime )
                    AND ( EndDateTime > :startDateTime )
                )
            ];
        }
        return events;
    }

    private static List<Event> getEventsForUser( Set<Id> userIds , Event window ) {
        List<Event> records = new List<Event>();
        if ( window != null ) {
            records = UserAvailabilityService.getEventsForUser(
                userIds ,
                window.StartDateTime ,
                window.EndDateTime
            );
        }
        return records;
    }

}
//