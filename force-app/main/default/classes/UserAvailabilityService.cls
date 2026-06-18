public with sharing class UserAvailabilityService {
    // test w/ UserAvailabilityServiceTest (85%)

    //Returns the available days based on Business Hours for the given skill...
    @AuraEnabled(cacheable=true)
    public static List<Date> getBusinessDates( String skill ) {
        List<BusinessHours> hours = [
            SELECT Id
            FROM BusinessHours
            WHERE (
                ( Id = :UserAvailabilityService.defaultBusinessHoursId )
                AND ( IsActive = true )
            )
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
                while ( (nextBusinessStart != null ) && ( response.size() < UserAvailabilityService.daysLimit ) ) {
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
        return UserAvailabilityService.getTimeBlocksPrimary( skill , timeZone );
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

    // Convert decimal hour fields (8.0, 8.5) to minutes
    private static Integer getMinutes( Decimal hours ) {
        return ( ( hours != null ) ? Integer.valueOf( Math.round( hours * 60 ) ) : null );
    }

    private static DateTime getBaseDateTime( String timeZone ) {
        Map<String,Integer> timeZoneOffsets = new Map<String,Integer>{
            'America/New_York'=> 4 ,
            'America/Chicago' => 5 ,
            'America/Denver'=> 6 ,
            'America/Los_Angeles'=> 7
        };
        Integer daylightSavingTimeOffset = 0; // Roberto/PMCC ~ for daylight saving time modifications...
        Integer offset = 0;
        if ( String.isNotBlank( timeZone )
            && timeZoneOffsets.containsKey( timeZone )
            && ( timeZoneOffsets.get( timeZone ) != null )
            )
        {
            offset = ( daylightSavingTimeOffset + timeZoneOffsets.get( timeZone ) );
        }
        // Base day = today's date in GMT at 00:00 to construct template Events
        Date currentDate = System.now().dateGMT();
        DateTime baseDateTime = DateTime.newInstanceGmt(
            currentDate.year() ,
            currentDate.month() ,
            currentDate.day() ,
            offset ,
            0 ,
            0
        );
        return baseDateTime;
    }

    private static List<Event> getTimeBlocksPrimary( String skill , String timeZone ) {
        // Base day = today's date in GMT at 00:00 to construct template Events
        Datetime baseDateTime = UserAvailabilityService.getBaseDateTime( timeZone );

        List<Event> timeBlocksPrimary = new List<Event>();
        if( baseDateTime != null ) {
            for (Schedule_Seller_Time_Slot__mdt row : UserAvailabilityService.getTimeSlots(skill, timezone)) {
                // Convert decimal hour fields (8.0, 8.5) to minutes
                Integer startMinutes = UserAvailabilityService.getMinutes( row.Start_Time__c );
                Integer endMinutes = UserAvailabilityService.getMinutes( row.End_Time__c );
                if ( ( startMinutes != null ) && ( endMinutes != null ) ) {
                    // Build Event using base GMT date + offset minutes
                    timeBlocksPrimary.add(
                        new Event(
                            Subject='Demo' ,
                            StartDateTime=baseDateTime.addMinutes( startMinutes ) ,
                            EndDateTime=baseDateTime.addMinutes( endMinutes )
                        )
                    );
                }
            }
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

    // Add 30-minute buffer to Demo events with NSP_Event_Subtype__c
    private static List<Event> addBufferToEvents( List<Event> events ) {
        List<Event> processedEvents = new List<Event>();
        if ( ( events != null ) && !events.isEmpty() ) {
            for ( Event e : events ) {
                Event processedEvent = e;
                // Check if this is a Demo event with HR360 Solution subtype
                // Check if this is a Demo event with any subtype value
                if ( ( processedEvent.NSP_Event_Type__c == 'Demo' )
                    && String.isNotBlank( processedEvent.NSP_Event_Subtype__c )
                    && ( processedEvent.EndDateTime != null )
                    )
                {
                    // Extend 30 minutes before start and 30 minutes after end
                    processedEvent.StartDateTime = processedEvent.StartDateTime.addMinutes( -1 * UserAvailabilityService.bufferMinutes );
                    processedEvent.EndDateTime = processedEvent.EndDateTime.addMinutes( UserAvailabilityService.bufferMinutes );
                }
                processedEvents.add( processedEvent );
            }
        }
        return processedEvents;
    }

    //Get total availability of users that are added to the Schedule Seller Permission Set
    @AuraEnabled
    public static List<List<List<Id>>> getAggregateUserIdsMatrix( String skill, String timeZone ) {
        // Build business day/time windows
        DaysMatrix daysOfWeek = UserAvailabilityService.getBusinessDaysMatrix( skill, timeZone );
        // Build windows directly from events-only matrix
        List<Event> windows = UserAvailabilityService.getMatrixWindows( daysOfWeek );
        // Union window: derive from earliest start and latest end among windows
        Event window = UserAvailabilityService.getBoundingWindow( windows );
        // Identify users with Schedule Seller Custom Permission
        Map<Id,User> skilledUsers = CustomPermissionController.getPermittedUsersMap( skill );
        Set<Id> userIds = ( ( skilledUsers != null ) ? skilledUsers.keySet() : new Set<Id>() );
        // Exclude users who already have >= 4 Schedule Seller Demo events in the current day
        Map<Date, Set<Id>> cappedUsersByDay = UserAvailabilityService.usersLessFourDemosFilter(
            window ,
            userIds
        );
        // Query all events for those users within the union window (bulkified)
        Map<Id,List<Event>> busyByUser = new Map<Id,List<Event>>();
        List<Event> events = UserAvailabilityService.getEventsForUser(
            userIds ,
            window
        );
        // Single source of truth for the 30-minute Demo buffer
        events = UserAvailabilityService.addBufferToEvents( events );
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
        // Build ID lists for each slot and wrap into the daysLimit wide matrix
        return UserAvailabilityService.convertToMatrix(
            UserAvailabilityService.getAggregateAvailableSlots(
                windows ,
                userIds ,
                busyByUser ,
                skill ,
                cappedUsersByDay
            )
        );
    }

    private static List<List<Id>> getAggregateAvailableSlots(
        List<Event> windows ,
        Set<Id> userIds ,
        Map<Id,List<Event>> busyByUser ,
        String skill ,
        Map<Date,Set<Id>> cappedUsersByDay
        )
    {
        // Collect available user ID lists per window
        List<List<Id>> idsPerWindow = new List<List<Id>>();
        if ( ( windows != null )
            && ( userIds != null )
            && ( busyByUser != null )
            && !windows.isEmpty()
            && !userIds.isEmpty()
            )
        {
            for ( Event windowEvt : windows ) {
                // Determine the calendar date this window slot falls on
                Date windowDate = null;
                if ( windowEvt.StartDateTime != null ) {
                    windowDate = windowEvt.StartDateTime.date();
                }
                // Resolve which users are capped on this specific day
                Set<Id> cappedToday = new Set<Id>();
                if ( ( cappedUsersByDay != null )
                    && ( windowDate != null )
                    && ( cappedUsersByDay.get( windowDate ) != null )
                    && cappedUsersByDay.containsKey( windowDate )
                    )
                {
                    cappedToday = cappedUsersByDay.get( windowDate );
                }
                List<Id> availableForWindow = new List<Id>();
                for ( Id uid : userIds ) {
                    // Skip this user for this day if they are capped
                    if ( cappedToday.contains( uid ) ) {
                        continue;
                    }
                    if ( busyByUser.containsKey( uid )
                        && ( busyByUser.get( uid ) != null )
                        )
                    {
                        Integer slotCount = UserAvailabilityService.countAvailableSlots(
                            busyByUser.get( uid ) ,
                            windowEvt ,
                            skill
                        );
                        if ( slotCount > 0 ) {
                            availableForWindow.add( uid );
                        }
                    }
                }
                idsPerWindow.add( availableForWindow );
            }
        }
        return idsPerWindow;
    }

    // Helper: convert a flat list of user-ID lists into a matrix of rows with up to N columns
    private static List<List<List<Id>>> convertToMatrix( List<List<Id>> userLists ) {
        List<List<List<Id>>> matrix = new List<List<List<Id>>>();
        if ( ( userLists != null ) && !userLists.isEmpty() ) {
            List<List<Id>> row = new List<List<Id>>();
            for ( List<Id> ids : userLists ) {
                row.add( ( ids == null ) ? new List<Id>() : ids );
                if ( row.size() == UserAvailabilityService.daysLimit ) {
                    matrix.add( new List<List<Id>>( row ) );
                    row.clear();
                }
            }
            if ( !row.isEmpty() ) {
                matrix.add( new List<List<Id>>( row ) );
            }
        }
        return matrix;
    }

    // helper method to defeat sonar cognitive complexity...
    private static Integer countAvailableSlots( List<Event> records , Event window , String skill ) {
        List<Event> available = UserAvailabilityService.getAvailableSlots(
            records ,
            window ,
            skill
        );
        return ( ( available == null ) ? 0 : available.size() );
    }

    // helper method to defeat sonar cognitive complexity...
    private static List<Event> getAvailableSlots( List<Event> records , Event window , String skill ) {
        // Use existing availability algorithm, summing per-user counts per window
        UserAvailability helper = new UserAvailability();
        List<Event> businessHoursFilter = new List<Event>();
        List<Event> slots = helper.getAvailableSlots(
            records ,
            window ,
            UserAvailabilityService.getStepMinutes( skill )
        );
        if ( ( slots != null ) && !slots.isEmpty() ) {
            for(Event e : slots) {
                //If time slot falls between Business Hours, include it
                if ( ( e.StartDateTime != null )
                    && ( e.EndDateTime != null )
                    && ( UserAvailabilityService.defaultBusinessHoursId != null )
                    && BusinessHours.isWithin( UserAvailabilityService.defaultBusinessHoursId , e.StartDateTime ) )
                {
                    Long durationMs = (Long)( e.EndDateTime.getTime() - e.StartDateTime.getTime() );
                    Datetime completesAt = BusinessHours.add(
                        UserAvailabilityService.defaultBusinessHoursId ,
                        e.StartDateTime ,
                        durationMs
                    );
                    if ( completesAt == e.EndDateTime ) {
                        businessHoursFilter.add( e );
                    }
                }
            }
        }
        return businessHoursFilter;
    }

    private static Map<Date, Set<Id>> usersLessFourDemosFilter( Event window , Set<Id> userIds ) {
        Map<Date,Set<Id>> cappedUsersByDay = new Map<Date,Set<Id>>();
        if ( ( window != null )
            && ( userIds != null )
            && !userIds.isEmpty()
            && ( window.StartDateTime != null )
            && ( window.EndDateTime != null )
            && ( UserAvailabilityService.eventRecordTypeId != null )
            )
        {
            for ( AggregateResult ar : [
                        SELECT
                            OwnerId ,
                            DAY_ONLY(StartDateTime) eventDay ,
                            COUNT(Id) cnt
                        FROM Event
                        WHERE (
                            ( OwnerId IN :userIds )
                            AND ( RecordTypeId = :UserAvailabilityService.eventRecordTypeId )
                            AND ( NSP_Event_Subtype__c != null )
                            AND ( StartDateTime >= :window.StartDateTime )
                            AND ( StartDateTime < :window.EndDateTime )
                        )
                        GROUP BY OwnerId , DAY_ONLY(StartDateTime)
                        HAVING ( COUNT(Id) >= 4 )
                    ]
                )
            {
                Date eventDay = (Date) ar.get( 'eventDay' );
                Id ownerId = (Id)ar.get( 'OwnerId' );
                if ( !cappedUsersByDay.containsKey( eventDay ) ) {
                    cappedUsersByDay.put( eventDay , new Set<Id>() );
                }
                cappedUsersByDay.get( eventDay ).add( ownerId );
            }
        }
        return cappedUsersByDay;
    }

    private static Event getBoundingWindow( List<Event> windows ) {
        Event window = null;
        if ( ( windows != null ) && !windows.isEmpty() ) {
            Datetime earliest = null;
            Datetime latest = null;
            for ( Event e : windows ) {
                if ( e != null ) {
                    if ( ( e.StartDateTime != null )
                        && ( ( earliest == null ) || ( e.StartDateTime < earliest ) )
                        )
                    {
                        earliest = e.StartDateTime;
                    }
                    if ( ( e.EndDateTime != null )
                        && ( ( latest == null ) || ( e.EndDateTime > latest ) )
                        )
                    {
                        latest = e.EndDateTime;
                    }
                }
            }
            if ( ( earliest != null ) && ( latest != null ) ) {
                window = new Event(
                    StartDateTime=earliest ,
                    EndDateTime=latest
                );
            }
        }
        return window;
    }

    private static List<Event> getMatrixWindows( DaysMatrix daysOfWeek ) {
        List<Event> windows = new List<Event>();
        if ( ( daysOfWeek != null )
            && ( daysOfWeek.slots != null )
            && !daysOfWeek.slots.isEmpty()
            )
        {
            for ( List<Event> slotPerDay : daysOfWeek.slots ) {
                if ( ( slotPerDay != null ) && !slotPerDay.isEmpty() ) {
                    windows.addAll( slotPerDay );
                }
            }
        }
        return windows;
    }

    private static Integer getStepMinutes( String skill ) {
        Map<String,Integer> skillStepMinutesMap = new Map<String,Integer>{
            'Schedule_Seller_HR360' => 60 ,
            'Schedule_Seller_HRCore' => 60 ,
            'Schedule_Seller_HRScale' => 120 ,
            'Schedule_Seller_Time_Attendance' => 30 ,
            'Schedule_Seller_Performance_Management' => 30 ,
            'Schedule_Seller_HR360_MidMarket' => 90 ,
            'Schedule_Seller_HRCore_MidMarket' => 90 ,
            'Schedule_Seller_HRScale_MidMarket' => 120 ,
            'Schedule_Seller_HR360_Enterprise' => 90 ,
            'Schedule_Seller_HRCore_Enterprise' => 90 ,
            'Schedule_Seller_Applicant_Tracking' => 30 ,
            'Schedule_Seller_Organizational_Planning' => 30 ,
            'Schedule_Seller_Multiple_Products' => 60
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
        // Expand query window backwards by 30 minutes to catch events whose buffer extends into requested slot
        Event queryWindow = new Event(
            StartDateTime=startDateTime.addMinutes( -30 ) ,
            EndDateTime=endDateTime
        );
        List<Event> overlapping = UserAvailabilityService.getEventsForUser(
            userIds ,
            queryWindow
        );
        // Apply 30-min buffer to Demo events
        overlapping = UserAvailabilityService.addBufferToEvents( overlapping );
        // Use original requested window for availability calculation
        Event window = new Event(
            StartDateTime=startDateTime ,
            EndDateTime=endDateTime
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
                List<Event> slots = UserAvailabilityService.getAvailableSlots(
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
            if ( ( defaultBusinessHoursId == null )
                && ( UserAvailabilityService.settings != null )
                )
            {
                String settingId = UserAvailabilityService.settings.BusinessHoursId__c;
                if ( String.isNotBlank( settingId ) && ( settingId InstanceOf Id ) ) {
                    Id checkId = Id.valueOf( settingId );
                    if ( checkId != null && checkId.getSObjectType() == Schema.BusinessHours.SObjectType ) {
                        defaultBusinessHoursId = checkId;
                    }
                }
            }
            return defaultBusinessHoursId;
        }
        private set;
    }

    private static Id eventRecordTypeId {
        private get {
            if ( ( eventRecordTypeId == null )
                && ( UserAvailabilityService.settings != null )
                )
            {
                String settingId = UserAvailabilityService.settings.EventRecordTypeId__c;
                if ( String.isNotBlank( settingId ) && ( settingId InstanceOf Id ) ) {
                    Id checkId = Id.valueOf( settingId );
                    if ( ( checkId != null )
                        && ( checkId.getSObjectType() == RecordType.getSObjectType() )
                        )
                    {
                        eventRecordTypeId = checkId;
                    }
                }
            }
            return eventRecordTypeId;
        }
        private set;
    }

    private static Integer daysLimit {
        private get {
            if ( daysLimit == null ) {
                Integer local = 1;
                if ( ( UserAvailabilityService.settings != null )
                    && ( UserAvailabilityService.settings.DaysLimit__c != null )
                   )
                {
                    local = UserAvailabilityService.settings.DaysLimit__c.intValue();
                }
                // days limit must be greater than zero...
                if ( local < 1 ) {
                    local = 1;
                }
                daysLimit = local;
            }
            return daysLimit;
        }
        private set;
    }

    private static Integer bufferMinutes {
        private get {
            if ( bufferMinutes == null ) {
                Integer local = 0;
                if ( ( UserAvailabilityService.settings != null )
                    && ( UserAvailabilityService.settings.BufferMinutes__c != null )
                   )
                {
                    local = UserAvailabilityService.settings.BufferMinutes__c.intValue();
                }
                if ( local < 0 ) {
                    local = 0;
                }
                bufferMinutes = local;
            }
            return bufferMinutes;
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
                WHERE Is_Active__c = true
                AND Product__c = :skill
                AND Time_Zone__c = :timeZone
                ORDER BY Start_Time__c ASC
            ];
        }
        return timeSlots;
    }

    private static Schedule_Seller_Settings__c settings {
        private get {
            if ( settings == null ) {
                settings = Schedule_Seller_Settings__c.getInstance( UserInfo.getUserId() );
            }
            return settings;
        }
        private set;
    }
}
//