public with sharing class UserAvailabilityService {
    // test w/ UserAvailabilityServiceTest (89%)

    //Returns the available days based on Business Hours for the given skill...
    @AuraEnabled(cacheable=true)
    public static List<Date> getBusinessDates( String skill ) {
        List<BusinessHours> hours = [
            SELECT Id
            FROM BusinessHours
            WHERE ( Id = :UserAvailabilityService.defaultBusinessHoursId )
            LIMIT 1
        ];
        BusinessHours open = null;
        if ( ( hours != null ) && !hours.isEmpty() ) {
            open = hours[0];
        }
        List<Date> response = new List<Date>();
        if ( open != null ) {
            try {
                // Initialize next business start
                Datetime nextBusinessStart = BusinessHours.nextStartDate(
                    open.Id ,
                    System.now()
                );
                // Collect next business days
                while ( (nextBusinessStart != null ) && ( response.size() < UserAvailabilityService.daysLimit.Days_Limit__c ) ) {
                    Date days = Date.newInstance(
                        nextBusinessStart.year() ,
                        nextBusinessStart.month() ,
                        nextBusinessStart.day()
                    );
                    // If user is not admin, skip today; otherwise include as-is
                    if ( UserAvailabilityService.isScheduleSellerAdmin() || ( days != Date.today() ) ) {
                        response.add( days );
                    }
                    // Advance to the next business start (next business day)
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
        // Single source of truth: events per slot across business days
        List<List<Event>> slots;
    }
    private static List<Event> getTimeZoneBlocks( String skill, String timeZone ) {
        List<Event> timeBlocks = new List<Event>();
        Map<String,List<Event>> timeZoneBlocks = new Map<String,List<Event>>{
            //For Daylight saving time modify first parameter
            'America/New_York'=> UserAvailabilityService.getTimeBlocksPrimary( 4, skill, timeZone) ,
            'America/Chicago' => UserAvailabilityService.getTimeBlocksPrimary( 5, skill, timeZone ) ,
            'America/Denver'=> UserAvailabilityService.getTimeBlocksPrimary( 6, skill, timeZone ) ,
            'America/Los_Angeles'=> UserAvailabilityService.getTimeBlocksPrimary( 7, skill, timeZone )
        };
        //
        if ( String.isNotBlank( timeZone )
            && timeZoneBlocks.containsKey( timeZone )
            && ( timeZoneBlocks.get( timeZone ) != null )
            )
        {
            timeBlocks = timeZoneBlocks.get( timeZone );
        }
        return timeBlocks;
    }
    private static DaysMatrix getBusinessDaysMatrix( String skill, String timeZone ) {
        List<Event> template = UserAvailabilityService.getTimeZoneBlocks( skill, timeZone );

        List<List<Event>> slotsList = new List<List<Event>>();
        //Get real days based on Business Hours
        List<Date> businessDates = UserAvailabilityService.getBusinessDates( skill );
        // For each slot index in the template, build that slot across all business days
        if ( ( template != null ) && ( businessDates != null ) && !businessDates.isEmpty() ) {
            for ( Event ev : template ) {
                Integer startHour = 0;
                Integer startMinute = 0;
                Integer endHour = 0;
                Integer endMinute = 0;
                if( ev.StartDateTime != null ) {
                    startHour = ev.StartDateTime.hour();
                    startMinute = ev.StartDateTime.minute();
                }
                if( ev.EndDateTime != null ) {
                    endHour = ev.EndDateTime.hour();
                    endMinute = ev.EndDateTime.minute();
                }
                List<Event> slotEventsPerDay = new List<Event>();
                for ( Date businessDate : businessDates ) {
                    DateTime startDt = DateTime.newInstance(
                        businessDate.year(),
                        businessDate.month(),
                        businessDate.day(),
                        startHour,
                        startMinute,
                        0
                    );
                    DateTime endDt = DateTime.newInstance(
                        businessDate.year(),
                        businessDate.month(),
                        businessDate.day(),
                        endHour,
                        endMinute,
                        0
                    );
                    slotEventsPerDay.add(
                        new Event(
                            StartDateTime = startDt,
                            EndDateTime = endDt
                        )
                    );
                }
                if ( !slotEventsPerDay.isEmpty() ) {
                    slotsList.add( slotEventsPerDay );
                }
            }
        }
        DaysMatrix response = new DaysMatrix();
        response.slots = slotsList;
        return response;
    }

    public static List<Event> getTimeBlocksPrimary( Integer offset, String skill, String timeZone ) {
        // Base day = today's date in GMT at 00:00 to construct template Events
        Date currentDate = System.now().dateGMT();
        Datetime baseDateTime = Datetime.newInstanceGmt(
            currentDate.year(),
            currentDate.month(),
            currentDate.day(),
            offset, 0, 0
        );

        List<Event> timeBlocksPrimary = new List<Event>();
        for (Schedule_Seller_Time_Slot__mdt rows : UserAvailabilityService.getTimeSlots(skill, timezone)) {
            // Convert decimal hour fields (8.0, 8.5) to minutes
            Integer startMinutes = (rows.Start_Time__c == null) ? null : Integer.valueOf(Math.round((Double)rows.Start_Time__c * 60));
            Integer endMinutes   = (rows.End_Time__c   == null) ? null : Integer.valueOf(Math.round((Double)rows.End_Time__c   * 60));

            // Build Event using base GMT date + offset minutes
            Datetime startDateTime = baseDateTime.addMinutes(startMinutes);
            Datetime endDateTime   = baseDateTime.addMinutes(endMinutes);

            timeBlocksPrimary.add(new Event(
                Subject = 'Demo',
                StartDateTime = startDateTime,
                EndDateTime = endDateTime
            ));
        }
        return timeBlocksPrimary;
    }



    @AuraEnabled(cacheable=true)
    public static List<Event> getTimeBlocks( String skill , String timeZone ) {
        return UserAvailabilityService.getTimeZoneBlocks( skill , timeZone );
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isScheduleSellerAdmin() {
        return CustomPermissionController.checkUserPermission(
            'Schedule_Seller_Admin' ,
            UserInfo.getUserId()
        );
    }

    // Helper: convert a flat list of integer counts into a matrix of rows with up to N columns
    private static List<List<Integer>> convertToMatrix( List<Integer> counts ) {
        List<List<Integer>> matrix = new List<List<Integer>>();
        if ( ( counts != null ) && !counts.isEmpty() ) {
            List<Integer> row = new List<Integer>();
            for ( Integer c : counts ) {
                row.add( ( c == null ) ? 0 : c );
                if ( row.size() == UserAvailabilityService.daysLimit.Days_Limit__c ) {
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
    public static List<List<Integer>> getAggregateCountsMatrix( String skill, String timeZone ) {
        // Build business day/time windows
        DaysMatrix daysOfWeek = UserAvailabilityService.getBusinessDaysMatrix( skill, timeZone );
        // Build windows directly from events-only matrix
        List<Event> windows = UserAvailabilityService.getMatrixWindows(daysOfWeek);
        // Union window: derive from earliest start and latest end among windows
        Event window = UserAvailabilityService.getBoundingWindow(windows);
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
        return UserAvailabilityService.convertToMatrix(
            UserAvailabilityService.getAggregateAvailableSlots(
                windows ,
                userIds ,
                busyByUser ,
                skill
            )
        );
    }

    private static Event getBoundingWindow( List<Event> windows ) {
        Event window = null;
        if ( !windows.isEmpty() ) {
            Datetime earliest = null;
            Datetime latest = null;
            for ( Event e : windows ) {
                if ( e != null ) {
                if ( e.StartDateTime != null && (earliest == null || e.StartDateTime < earliest) ) {
                    earliest = e.StartDateTime;
                }
                if ( e.EndDateTime != null && (latest == null || e.EndDateTime > latest) ) {
                    latest = e.EndDateTime;
                }}
            }
            if ( earliest != null && latest != null ) {
                window = new Event(StartDateTime = earliest, EndDateTime = latest);
            }
        }
        return window;
    }
    private static List<Event> getMatrixWindows( DaysMatrix daysOfWeek ) {
        List<Event> windows = new List<Event>();
        if ( daysOfWeek != null && daysOfWeek.slots != null && !daysOfWeek.slots.isEmpty() ) {
            for ( List<Event> slotPerDay : daysOfWeek.slots ) {
                if ( slotPerDay != null && !slotPerDay.isEmpty() ) {
                    windows.addAll(slotPerDay);
                }
            }
        }
        return windows;
    }

    private static List<Integer> getAggregateAvailableSlots(
        List<Event> windows ,
        Set<Id> userIds ,
        Map<Id,List<Event>> busyByUser ,
        String skill
        )
    {
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
                            windowEvt ,
                            skill
                        );
                    }
                }
                countsPerWindow.add( totalForWindow );
            }
        }
        return countsPerWindow;
    }

    // helper method to defeat sonar cognitive complexity...
    private static Integer countAvailableSlots( List<Event> records , Event window , String skill ) {
        List<String> available = UserAvailabilityService.getAvailableSlots(
            records ,
            window ,
            skill
        );
        return ( ( available == null ) ? 0 : available.size() );
    }

    // helper method to defeat sonar cognitive complexity...
    private static List<String> getAvailableSlots( List<Event> records , Event window , String skill ) {
        // Use existing availability algorithm, summing per-user counts per window
        UserAvailability helper = new UserAvailability();
        return helper.getAvailableSlots(
            records ,
            window ,
            UserAvailabilityService.getStepMinutes( skill )
        );
    }

    private static Integer getStepMinutes( String skill ) {
        Map<String,Integer> skillStepMinutesMap = new Map<String,Integer>{
            'Schedule_Seller_HR360' => 60 ,
            'Schedule_Seller_HRCore' => 60 ,
            'Schedule_Seller_HRScale' => 120 ,
            'Schedule_Seller_Time_Attendance' => 30 ,
            'Schedule_Seller_Performance' => 30 ,
            'Schedule_Seller_HR360_MidMarket' => 90 ,
            'Schedule_Seller_HRCore_MidMarket' => 90 ,
            'Schedule_Seller_HRScale_MidMarket' => 120 ,
            'Schedule_Seller_HR360_Enterprise' => 90 ,
            'Schedule_Seller_HRCore_Enterprise' => 90
        };
        //
        Integer stepMinutes = 60;
        if ( String.isNotBlank( skill )
            && skillStepMinutesMap.containsKey( skill )
            && ( skillStepMinutesMap.get( skill ) != null )
            )
        {
            stepMinutes = skillStepMinutesMap.get( skill );
        }
        return stepMinutes;
    }

    public static List<Id> getAvailableUsersForWindow(
        Datetime startDateTime ,
        Datetime endDateTime ,
        String skill
        )
    {
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
        Event window = new Event(
            StartDateTime=startDateTime ,
            EndDateTime=endDateTime
        );
        List<Event> overlapping = UserAvailabilityService.getEventsForUser(
            userIds ,
            window
        );
        // Ensure every user exists in the map (so busyByUser.get(uid) isn't null)
        Map<Id,List<Event>> busyByUser = UserAvailabilityService.initializeBusyUserMap( userIds );
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
        // Only compute availability if we have a valid window and eligible users
        List<Id> availableUsers = new List<Id>();
        if ( validWindow ) {
            availableUsers = UserAvailabilityService.getAvailableUsersForWindowHelper(
                busyByUser ,
                userIds ,
                window ,
                skill
            );
        }
        return availableUsers;
    }

    // Ensure every user exists in the map (so busyByUser.get(uid) isn't null)
    private static Map<Id,List<Event>> initializeBusyUserMap( Set<Id> userIds ) {
        Map<Id,List<Event>> busyByUser = new Map<Id,List<Event>>();
        if ( ( userIds != null ) && !userIds.isEmpty() ) {
            for ( Id uid : userIds ) {
                if ( ( uid != null ) && !busyByUser.containsKey( uid ) ) {
                    busyByUser.put( uid , new List<Event>() );
                }
            }
        }
        return busyByUser;
    }

    // helper method to defeat sonar cognitive complexity...
    private static List<Id> getAvailableUsersForWindowHelper(
        Map<Id,List<Event>> busyByUser ,
        Set<Id> userIds ,
        Event window ,
        String skill
        )
    {
        List<Id> availableUsers = new List<Id>();
        if ( ( busyByUser != null )
            && ( userIds != null )
            && !userIds.isEmpty()
            && ( window != null )
            )
        {
            for ( Id uid : userIds ) {
                List<Event> userBusy = new List<Event>();
                if ( busyByUser.containsKey( uid )
                    && ( busyByUser.get( uid ) != null )
                    )
                {
                    userBusy = busyByUser.get( uid );
                }
                List<String> slots = UserAvailabilityService.getAvailableSlots(
                    userBusy ,
                    window ,
                    skill
                );
                if ( ( slots != null ) && !slots.isEmpty() ) {
                    availableUsers.add( uid );
                }
            }
        }
        return availableUsers;
    }

    private static List<Event> getEventsForUser( Set<Id> userIds , Event window ) {
        UserAvailability helper = new UserAvailability();
        return helper.selectEvents(
            userIds ,
            window
        );
    }

    //
    //
    //

    // identify the default Business Hours for current Org...
    private static Id defaultBusinessHoursId {
        private get {
            if ( defaultBusinessHoursId == null ) {
                List<BusinessHours> defaultBusinessHours = [
                    SELECT Id
                    FROM BusinessHours
                    WHERE ( Name = 'Schedule Seller' )
                    ORDER BY CreatedDate ASC
                    LIMIT 1
                ];
                if ( ( defaultBusinessHours != null ) && ( defaultBusinessHours.size() > 0 ) ) {
                    defaultBusinessHoursId = defaultBusinessHours[0].Id;
                }
            }
            return defaultBusinessHoursId;
        }
        private set;
    }

    private static Schedule_Seller_Settings__c daysLimit {
        private get {
            if ( daysLimit == null ) {
                daysLimit = Schedule_Seller_Settings__c.getOrgDefaults();
            }
            return daysLimit;
        }
        private set;
    }

    // Load time slot definitions from Custom Metadata for the given product (skill) and time zone
    public static List<Schedule_Seller_Time_Slot__mdt> getTimeSlots(String skill, String timeZone){
        List<Schedule_Seller_Time_Slot__mdt> timeSlots = new List<Schedule_Seller_Time_Slot__mdt>();
        if( String.isNotBlank(skill) && String.isNotBlank(timeZone) ) {
            timeSlots = [
                SELECT Start_Time__c, End_Time__c
                FROM Schedule_Seller_Time_Slot__mdt
                WHERE Active__c = true
                AND Product__c = :skill
                AND Time_Zone__c = :timeZone
                WITH SECURITY_ENFORCED
                ORDER BY Start_Time__c ASC
            ];
        }
        return timeSlots;
    }

}
//