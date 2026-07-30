public with sharing class UserAvailabilityService {
    // test w/ UserAvailabilityServiceTest (90%)

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
        Map<Date,Set<Id>> cappedUsersByDay = UserAvailabilityService.usersLessFourDemosFilter(
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
            Map<Id,String> timeZoneByUser = UserAvailabilityService.getUserTimeZones( userIds );
            for ( Event windowEvt : windows ) {
                // Resolve which users are capped on this specific day
                Set<Id> cappedToday = UserAvailabilityService.buildCappedTodaySet( cappedUsersByDay , windowEvt );
                List<Id> availableForWindow = new List<Id>();
                for ( Id uid : userIds ) {
                    // Skip this user for this day if they are capped
                    if ( cappedToday.contains( uid ) ) {
                        continue;
                    }
                    if ( UserAvailabilityService.isUserAvailableForWindow( uid , busyByUser , windowEvt , skill , timeZoneByUser ) ) {
                        availableForWindow.add( uid );
                    }
                }
                idsPerWindow.add( availableForWindow );
            }
        }
        return idsPerWindow;
    }

    private static Boolean isUserAvailableForWindow(
        Id uid ,
        Map<Id,List<Event>> busyByUser ,
        Event windowEvt ,
        String skill ,
        Map<Id,String> timeZoneByUser
        )
    {
        Boolean response = false;
        if ( ( uid != null )
            && ( busyByUser != null )
            && busyByUser.containsKey( uid )
            && ( busyByUser.get( uid ) != null )
            && ( timeZoneByUser != null )
            && timeZoneByUser.containsKey( uid )
            && ( timeZoneByUser.get( uid ) != null )
            )
        {
            Id userBusinessHoursId = UserAvailabilityService.sellerBusinessHoursId( timeZoneByUser.get( uid ) );
            Integer slotCount = UserAvailabilityService.countAvailableSlots(
                busyByUser.get( uid ) ,
                windowEvt ,
                skill ,
                userBusinessHoursId
            );
            if ( slotCount != null && slotCount > 0 ) {
                response = true;
            }
        }
        return response;
    }

      private static Set<Id> buildCappedTodaySet( Map<Date,Set<Id>> cappedUsersByDay , Event window ) {
        // Determine the calendar date this window slot falls on
        Date windowDate = null;
        if ( ( window != null ) && ( window.StartDateTime != null ) ) {
            windowDate = window.StartDateTime.date();
        }
        // Resolve which users are capped on this specific day
        Set<Id> cappedToday = new Set<Id>();
        if ( ( cappedUsersByDay != null )
            && ( windowDate != null )
            && cappedUsersByDay.containsKey( windowDate )
            && ( cappedUsersByDay.get( windowDate ) != null )
            )
        {
            cappedToday = cappedUsersByDay.get( windowDate );
        }
        return cappedToday;
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
    private static Integer countAvailableSlots( List<Event> records , Event window , String skill, Id userBusinessHoursId ) {
        List<Event> available = UserAvailabilityService.getAvailableSlots(
            records ,
            window ,
            skill ,
            userBusinessHoursId
        );
        return ( ( available == null ) ? 0 : available.size() );
    }

    // helper method to defeat sonar cognitive complexity...
    private static List<Event> getAvailableSlots( List<Event> records , Event window , String skill , Id userBusinessHoursId ) {
        List<Event> businessHoursFilter = new List<Event>();
        Id orgBhId = UserAvailabilityService.defaultBusinessHoursId;
        //Checking default and time zone business hours
        if ( ( userBusinessHoursId != null ) && ( orgBhId != null ) ) {
            UserAvailability helper = new UserAvailability();
            List<Event> slots = helper.getAvailableSlots( records , window , UserAvailabilityService.getStepMinutes( skill ) );
            if ( ( slots != null ) && !slots.isEmpty() ) {
                for ( Event e : slots ) {
                    if ( UserAvailabilityService.isWithin( orgBhId , userBusinessHoursId , e ) ) {
                        businessHoursFilter.add( e );
                    }
                }
            }
        }
        return businessHoursFilter;
    }

    private static Boolean isWithin( Id businessHoursId , Event e , Long durationMs ) {
        Boolean response = false;
        if ( ( businessHoursId != null )
            && ( durationMs != null )
            && ( e != null )
            && ( e.StartDateTime != null )
            && ( e.EndDateTime != null )
            && BusinessHours.isWithin( businessHoursId , e.StartDateTime ) 
            && ( BusinessHours.add( businessHoursId , e.StartDateTime , durationMs ) == e.EndDateTime )
            )
        {
            response = true;
        }
        return response;
    }

    private static Boolean isWithin(
        Id orgBusinessHoursId ,
        Id userBusinessHoursId ,
        Event e
        )
    {
        Boolean response = false;
        if ( ( e != null )
            && ( e.StartDateTime != null )
            && ( e.EndDateTime != null )
            )
        {
            Long durationMs = (Long)( e.EndDateTime.getTime() - e.StartDateTime.getTime() );
            response = (
                UserAvailabilityService.isWithin( orgBusinessHoursId , e , durationMs )
                && UserAvailabilityService.isWithin( userBusinessHoursId , e , durationMs )
            );
        }
        return response;
    }

    private static Map<Date,Set<Id>> usersLessFourDemosFilter( Event window , Set<Id> userIds ) {
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

    private static Map<Id,User> getUsers( Set<Id> userIdSet ) {
        Map<Id,User> usersById = new Map<Id,User>();
        if ( ( userIdSet != null ) && !userIdSet.isEmpty() ) {
            usersById = new Map<Id,User>(
                [
                    SELECT
                        Id ,
                        Name ,
                        Email ,
                        Title
                    FROM User
                    WHERE ( Id IN :userIdSet )
                ]
            );
        }
        return usersById;
    }

    public static List<User> sortUsersByDailyLoad( List<Id> userIds , Date selectedDate ) {
        List<User> sorted = new List<User>();
        if ( ( userIds != null )
            && !userIds.isEmpty()
            && ( selectedDate != null )
            )
        {
            DateTime dayStart = DateTime.newInstanceGmt(
                selectedDate.year() ,
                selectedDate.month() ,
                selectedDate.day() ,
                0 ,
                0 ,
                0
            );
            DateTime dayEnd = dayStart.addDays( 1 );
            Event dayWindow = new Event(
                StartDateTime=dayStart ,
                EndDateTime=dayEnd
            );
            Set<Id> userIdSet = new Set<Id>( userIds );
            List<Event> events = UserAvailabilityService.getEventsForUser( userIdSet , dayWindow );
            events = UserAvailabilityService.addBufferToEvents( events );
            Map<Id,List<Event>> busyByUser = UserAvailabilityService.initializeBusyUserMap( userIdSet );
            if ( ( events != null ) && !events.isEmpty() ) {
                for ( Event e : events ) {
                    if ( ( busyByUser != null ) && busyByUser.containsKey( e.OwnerId ) ) {
                        busyByUser.get( e.OwnerId ).add( e );
                    }
                }
            }
            // Query User records for all IDs in one bulkified query
            Map<Id,User> usersById = UserAvailabilityService.getUsers( userIdSet );
            sorted = UserAvailabilityService.sortUsers(
                UserAvailabilityService.evaluateUserEventLoad( userIds , busyByUser ) ,
                usersById
            );
        }
        return sorted;
    }

    private static List<UserEventLoad> evaluateUserEventLoad( List<Id> userIds , Map<Id,List<Event>> busyByUser ) {
        List<UserEventLoad> evaluated = new List<UserEventLoad>();
        if( ( userIds != null ) && !userIds.isEmpty() ) {
            for ( Id uid : userIds ) {
                List<Event> userEvents = new List<Event>();
                if ( ( busyByUser != null ) && busyByUser.containsKey( uid ) ) {
                    userEvents = busyByUser.get( uid );
                }
                Integer load = ( ( userEvents != null ) ? userEvents.size() : 0 );
                evaluated.add( new UserEventLoad( uid , load ) );
            }
        }
        return evaluated;
    }

    private static List<User> sortUsers( List<UserEventLoad> prepared , Map<Id,User> usersById ) {
        List<User> sorted = new List<User>();
        if ( ( prepared != null ) && !prepared.isEmpty() ) {
            prepared.sort();
            for ( UserEventLoad u : prepared ) {
                if ( ( usersById != null ) && usersById.containsKey( u.userId ) ) {
                    sorted.add( usersById.get( u.userId ) );
                }
            }
        }
        return sorted;
    }

    // Rank users by event load, ascending
    private class UserEventLoad implements Comparable {
        private Id userId;
        private Integer eventCount;
        private UserEventLoad( Id userId, Integer eventCount ) {
            this.userId = userId;
            this.eventCount = eventCount;
        }
        public Integer compareTo( Object other ) {
            UserEventLoad o = (UserEventLoad) other;
            Integer local = 0;
            if ( this.eventCount < o.eventCount ) {
                local = -1;
            }
            if ( this.eventCount > o.eventCount ) {
                local = 1;
            }
            return local;
        }
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
    private static Map<String, Id> businessHoursByTimeZone {
        private get {
            if ( businessHoursByTimeZone == null ) {
                businessHoursByTimeZone = new Map<String, Id>();
                for ( BusinessHours bh : [
                    SELECT Id, TimeZoneSidKey
                    FROM BusinessHours
                    WHERE (
                        ( IsActive = true )
                        AND ( Name LIKE 'Schedule Seller: %' )
                    )
                ] ) {
                    businessHoursByTimeZone.put( bh.TimeZoneSidKey, bh.Id );
                }
            }
            return businessHoursByTimeZone;
        }
        private set;
    }

    private static Map<Id, String> getUserTimeZones( Set<Id> userIds ) {
        Map<Id, String> timeZoneByUser = new Map<Id, String>();
        if ( ( userIds != null ) && !userIds.isEmpty() ) {
            for ( User u : [SELECT Id, TimeZoneSidKey FROM User WHERE Id IN :userIds] ) {
                timeZoneByUser.put( u.Id, u.TimeZoneSidKey );
            }
        }
        return timeZoneByUser;
    }

    private static Id sellerBusinessHoursId( String userTimeZone ) {
        Id userBhId = UserAvailabilityService.defaultBusinessHoursId;
        if ( String.isNotBlank( userTimeZone ) ) {
            userBhId = UserAvailabilityService.businessHoursByTimeZone.get( userTimeZone );
        }
        return userBhId;
    }
}
//