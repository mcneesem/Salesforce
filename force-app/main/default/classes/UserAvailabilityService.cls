public with sharing class UserAvailabilityService {
    // test w/ UserAvailabilityServiceTest (85%)

    private static final Integer DAYS_LIMIT = 10;

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
                while ( (nextBusinessStart != null ) && ( response.size() < UserAvailabilityService.DAYS_LIMIT ) ) {
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
            'America/New_York'=> UserAvailabilityService.getTimeBlocksPrimary( 13 ) ,
            'America/Chicago' => UserAvailabilityService.getTimeBlocksPrimary( 14 ) ,
            'America/Denver'=> UserAvailabilityService.getTimeBlocksAlternate( 15 ) ,
            'America/Los_Angeles'=> UserAvailabilityService.getTimeBlocksPrimary( 16 )
        };
        Map<String,List<Event>> timeZoneBlocksMiddleMarket = new Map<String,List<Event>>{
            'America/New_York'=> UserAvailabilityService.getTimeBlocksPrimaryMiddleMarket( 13 ) ,
            'America/Chicago' => UserAvailabilityService.getTimeBlocksPrimaryMiddleMarket( 14 ) ,
            'America/Denver'=> UserAvailabilityService.getTimeBlocksAlternate( 15 ) ,
            'America/Los_Angeles'=> UserAvailabilityService.getTimeBlocksPrimaryMiddleMarket( 16 )
        };
        Map<String,Map<String,List<Event>>> skillTimeZoneMap = new Map<String,Map<String,List<Event>>>{
            'Schedule_Seller_HR360' => timeZoneBlocks ,
            'Schedule_Seller_HRCore' => timeZoneBlocks ,
            'Schedule_Seller_HRScale' => timeZoneBlocks ,
            'Schedule_Seller_HR360_Middle_Market' => timeZoneBlocksMiddleMarket ,
            'Schedule_Seller_HRCore_Middle_Market' => timeZoneBlocksMiddleMarket ,
            'Schedule_Seller_HRScale_Middle_Market' => timeZoneBlocksMiddleMarket
        };
        //
        if ( String.isNotBlank( skill )
            && String.isNotBlank( timeZone )
            && skillTimeZoneMap.containsKey( skill )
            && ( skillTimeZoneMap.get( skill ) != null )
            && skillTimeZoneMap.get( skill ).containsKey( timeZone )
            && ( skillTimeZoneMap.get( skill ).get( timeZone ) != null )
            )
        {
            timeBlocks = skillTimeZoneMap.get( skill ).get( timeZone );
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

    public static List<Event> getTimeBlocksPrimary( Integer offset ) {
        if ( offset == null ) {
            offset = 14; // 8 AM CST // 14 GMT
        }
        DateTime currentDate = System.now().dateGMT();
        Datetime startDateTime = Datetime.newInstanceGmt(
            currentDate.yearGmt() ,
            currentDate.monthGmt() ,
            currentDate.dayGmt() ,
            offset ,
            0 ,
            0
        );
        List<Event> timeBlocksPrimary = new List<Event>{
            new Event(
                Subject='X8:00 - Y9:00' ,
                StartDateTime=startDateTime ,
                EndDateTime=startDateTime.addHours( 1 )
            ) ,
            new Event(
                Subject='X8:30 - Y9:30' ,
                StartDateTime=startDateTime.addMinutes( 30 ) ,
                EndDateTime=startDateTime.addMinutes( 30 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X9:00 - Y10:00' ,
                StartDateTime=startDateTime.addMinutes( 60 ) ,
                EndDateTime=startDateTime.addMinutes( 60 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X9:30 - Y10:30' ,
                StartDateTime=startDateTime.addMinutes( 90 ) ,
                EndDateTime=startDateTime.addMinutes( 90 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X10:00 - Y11:00' ,
                StartDateTime=startDateTime.addMinutes( 120 ) ,
                EndDateTime=startDateTime.addMinutes( 120 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X10:30 - Y11:30' ,
                StartDateTime=startDateTime.addMinutes( 150 ) ,
                EndDateTime=startDateTime.addMinutes( 150 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X11:00 - Y12:00' ,
                StartDateTime=startDateTime.addMinutes( 180 ) ,
                EndDateTime=startDateTime.addMinutes( 180 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X11:30 - Y12:30' ,
                StartDateTime=startDateTime.addMinutes( 210 ) ,
                EndDateTime=startDateTime.addMinutes( 210 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X12:30 - Y1:30' ,
                StartDateTime=startDateTime.addMinutes( 270 ) ,
                EndDateTime=startDateTime.addMinutes( 270 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X1:00 - Y2:00' ,
                StartDateTime=startDateTime.addMinutes( 300 ) ,
                EndDateTime=startDateTime.addMinutes( 300 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X1:30 - Y2:30' ,
                StartDateTime=startDateTime.addMinutes( 330 ) ,
                EndDateTime=startDateTime.addMinutes( 330 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X2:00 - Y3:00' ,
                StartDateTime=startDateTime.addMinutes( 360 ) ,
                EndDateTime=startDateTime.addMinutes( 360 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X3:00 - Y4:00' ,
                StartDateTime=startDateTime.addMinutes( 420 ) ,
                EndDateTime=startDateTime.addMinutes( 420 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X3:30 - Y4:30' ,
                StartDateTime=startDateTime.addMinutes( 450 ) ,
                EndDateTime=startDateTime.addMinutes( 450 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X4:00 - Y5:00' ,
                StartDateTime=startDateTime.addMinutes( 480 ) ,
                EndDateTime=startDateTime.addMinutes( 480 ).addHours( 1 )
            )
        };
        return timeBlocksPrimary;
    }
    public static List<Event> getTimeBlocksPrimaryMiddleMarket( Integer offset ) {
        if ( offset == null ) {
            offset = 14; // 8 AM CST // 14 GMT
        }
        DateTime currentDate = System.now().dateGMT();
        Datetime startDateTime = Datetime.newInstanceGmt(
            currentDate.yearGmt() ,
            currentDate.monthGmt() ,
            currentDate.dayGmt() ,
            offset ,
            0 ,
            0
        );
        List<Event> timeBlocksPrimary = new List<Event>{
            new Event(
                Subject='X8:00 - Y9:30' ,
                StartDateTime=startDateTime ,
                EndDateTime=startDateTime.addMinutes( 30 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X8:30 - Y10:00' ,
                StartDateTime=startDateTime.addMinutes( 30 ) ,
                EndDateTime=startDateTime.addMinutes( 60 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X9:00 - Y10:30' ,
                StartDateTime=startDateTime.addMinutes( 60 ) ,
                EndDateTime=startDateTime.addMinutes( 90 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X9:30 - Y11:00' ,
                StartDateTime=startDateTime.addMinutes( 90 ) ,
                EndDateTime=startDateTime.addMinutes( 120 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X10:00 - Y11:30' ,
                StartDateTime=startDateTime.addMinutes( 120 ) ,
                EndDateTime=startDateTime.addMinutes( 150 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X10:30 - Y12:00' ,
                StartDateTime=startDateTime.addMinutes( 150 ) ,
                EndDateTime=startDateTime.addMinutes( 180 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X11:00 - Y12:30' ,
                StartDateTime=startDateTime.addMinutes( 180 ) ,
                EndDateTime=startDateTime.addMinutes( 210 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X11:30 - Y1:00' ,
                StartDateTime=startDateTime.addMinutes( 210 ) ,
                EndDateTime=startDateTime.addMinutes( 240 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X12:00 - Y1:30' ,
                StartDateTime=startDateTime.addMinutes( 240 ) ,
                EndDateTime=startDateTime.addMinutes( 270 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X12:30 - Y2:00' ,
                StartDateTime=startDateTime.addMinutes( 270 ) ,
                EndDateTime=startDateTime.addMinutes( 300 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X1:00 - Y2:30' ,
                StartDateTime=startDateTime.addMinutes( 300 ) ,
                EndDateTime=startDateTime.addMinutes( 330 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X1:30 - Y2:30' ,
                StartDateTime=startDateTime.addMinutes( 330 ) ,
                EndDateTime=startDateTime.addMinutes( 360 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X2:00 - Y3:30' ,
                StartDateTime=startDateTime.addMinutes( 360 ) ,
                EndDateTime=startDateTime.addMinutes( 390 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X2:30 - Y4:00' ,
                StartDateTime=startDateTime.addMinutes( 390 ) ,
                EndDateTime=startDateTime.addMinutes( 420 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X3:00 - Y4:30' ,
                StartDateTime=startDateTime.addMinutes( 420 ) ,
                EndDateTime=startDateTime.addMinutes( 450 ).addHours( 1 )
            )
        };
        return timeBlocksPrimary;
    }

    public static List<Event> getTimeBlocksAlternate( Integer offset ) {
        if ( offset == null ) {
            offset = 15; // 8 AM MST // 15 GMT
        }
        DateTime currentDate = System.now().dateGMT();
        Datetime startDateTime = Datetime.newInstanceGmt(
            currentDate.yearGmt() ,
            currentDate.monthGmt() ,
            currentDate.dayGmt() ,
            offset ,
            0 ,
            0
        );
        List<Event> timeBlocksAlternate = new List<Event>{
            new Event(
                Subject='X1:00 - Y2:00' ,
                StartDateTime=startDateTime.addMinutes( 300 ) ,
                EndDateTime=startDateTime.addMinutes( 300 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X2:00 - Y3:00' ,
                StartDateTime=startDateTime.addMinutes( 360 ) ,
                EndDateTime=startDateTime.addMinutes( 360 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X3:30 - Y4:30' ,
                StartDateTime=startDateTime.addMinutes( 450 ) ,
                EndDateTime=startDateTime.addMinutes( 450 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X4:00 - Y5:00' ,
                StartDateTime=startDateTime.addMinutes( 480 ) ,
                EndDateTime=startDateTime.addMinutes( 480 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X5:30 - Y6:30' ,
                StartDateTime=startDateTime.addMinutes( 570 ) ,
                EndDateTime=startDateTime.addMinutes( 570 ).addHours( 1 )
            ) ,
            new Event(
                Subject='X6:00 - Y7:00' ,
                StartDateTime=startDateTime.addMinutes( 600 ) ,
                EndDateTime=startDateTime.addMinutes( 600 ).addHours( 1 )
            )
        };
        return timeBlocksAlternate;
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

    @AuraEnabled(cacheable=true)
    public static List<String> getTimeBlocksString( String skill , String timeZone ) {
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
            'Schedule_Seller_HRScale' => 60 ,
            'Schedule_Seller_HR360_Middle_Market' => 90 ,
            'Schedule_Seller_HRCore_Middle_Market' => 90 ,
            'Schedule_Seller_HRScale_Middle_Market' => 90
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
                    WHERE ( IsDefault = true )
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

}
//